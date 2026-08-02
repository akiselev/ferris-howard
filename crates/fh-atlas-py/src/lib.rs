//! Python bindings for the Atlas core — the `fa.Corpus` namespace of
//! `research/python-api.md` §2, and nothing else yet.
//!
//! # What this buys
//!
//! Every `atlas` CLI invocation re-reads and re-parses the whole slice before answering
//! anything: measured at ~6 s for a 131,062-declaration Mathlib slice. A harness that asks
//! eight questions pays that eight times. Here the slice is parsed once into a [`Corpus`]
//! handle and every later query runs against the graph already in memory — §1's "handles,
//! not copies", which is the entire reason this crate exists.
//!
//! # The `&mut Arena` problem, solved behind the handle
//!
//! `skel::erase::erase` and `skel::lgg::generalize` both take `&mut Arena`: erasure interns
//! the holed nodes it produces and anti-unification interns its variables, so a "query"
//! grows the arena. Python has no `&mut`, and a handle that demanded exclusive access would
//! push that problem onto every caller.
//!
//! So the arena, its signature table and its erasure cache live inside the handle behind a
//! `Mutex`, and the pyclass is `frozen` — Python sees only shared references, Rust does the
//! locking. Two consequences worth stating rather than discovering:
//!
//! * Skeleton queries from several Python threads *serialize* on that lock. Graph queries
//!   (`why`, `foundations`, `impact`, `walls`, `honesty`) touch no arena, take no lock and
//!   run genuinely in parallel once the GIL is released.
//! * The arena grows monotonically across queries. Erasure caches, so repeated levels are
//!   free; `generalize` interns fresh variables per call and is the one operation whose
//!   memory grows with use.
//!
//! The arena is built on the *first* skeleton query, not at load: parsing 131k statement
//! encodings is work a graph-only session should not pay for.
//!
//! # `py.detach` is `py.allow_threads`
//!
//! Every operation that walks the graph or the arena runs inside `py.detach(…)`, which is
//! what PyO3 ≥0.26 calls the GIL release `python-api.md` §1 writes as `py.allow_threads`.
//! The old name is gone from the API, not merely deprecated.

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Mutex, MutexGuard};

use ::fh_atlas::graph::{Decl as CoreDecl, Graph, Lens};
use ::fh_atlas::skel::erase::{EraseCache, Level, Signatures, erase};
use ::fh_atlas::skel::lgg;
use ::fh_atlas::skel::term::{Arena, SymId, TermId};
use pyo3::create_exception;
use pyo3::exceptions::{PyException, PyFileNotFoundError, PyOSError, PyValueError};
use pyo3::prelude::*;

create_exception!(
    fh_atlas,
    AtlasError,
    PyException,
    "Base class for every error this module raises."
);
create_exception!(
    fh_atlas,
    SliceError,
    AtlasError,
    "A slice could not be read as B1 JSONL. Carries the offending line number."
);
create_exception!(
    fh_atlas,
    UnknownDeclaration,
    AtlasError,
    "No declaration by that name in this slice."
);
create_exception!(
    fh_atlas,
    NoStatement,
    AtlasError,
    "The declaration is in the slice but carries no usable I3 statement encoding."
);

/// The axioms an argument may rest on when the caller names none — Lean's own three, which
/// everything classical uses. Same default as `atlas honesty`.
const DEFAULT_WHITELIST: [&str; 3] = ["propext", "Classical.choice", "Quot.sound"];

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

/// One declaration, as B1's extractor emitted it.
#[pyclass(module = "fh_atlas", frozen, get_all)]
pub struct Decl {
    pub name: String,
    pub kind: String,
    pub module: String,
    /// The I3 canonical statement encoding, `None` when it could not be encoded.
    pub stmt: Option<String>,
    /// Why `stmt` is absent. Present exactly when `stmt` is — B1 keeps the row rather than
    /// dropping it, and the reason is what makes a `None` readable.
    pub stmt_error: Option<String>,
}

impl From<&CoreDecl> for Decl {
    fn from(d: &CoreDecl) -> Decl {
        Decl {
            name: d.name.clone(),
            kind: d.kind.clone(),
            module: d.module.clone(),
            stmt: d.stmt.clone(),
            stmt_error: d.stmt_error.clone(),
        }
    }
}

#[pymethods]
impl Decl {
    fn __repr__(&self) -> String {
        // The encoding runs to hundreds of bytes and is unreadable at a glance; its size
        // and the reason it is missing are the two things a caller acts on.
        let stmt = match (&self.stmt, &self.stmt_error) {
            (Some(s), _) => format!("stmt={} bytes", s.len()),
            (None, Some(why)) => format!("stmt=None ({why})"),
            (None, None) => "stmt=None".to_string(),
        };
        format!(
            "Decl(name={:?}, kind={:?}, module={:?}, {stmt})",
            self.name, self.kind, self.module
        )
    }
}

/// The least general generalization of two statements, with the numbers that rank it.
#[pyclass(module = "fh_atlas", frozen, get_all)]
pub struct Generalization {
    /// The skeleton, rendered in the I3 grammar: `_` is a hole, `?k` an anti-unification
    /// variable.
    pub skeleton: String,
    /// Non-hole, non-variable nodes — how much structure the two actually share.
    pub common: u32,
    pub vars: u32,
    /// Variables standing for something with loose de Bruijn indices. Such a row reads fine
    /// and is **not** transportable; reported, never hidden.
    pub scoped_vars: u32,
    /// `common / max(|x|,|y|)`, in `[0,1]`; exactly 1 when the statements are equal.
    pub retention: f32,
}

#[pymethods]
impl Generalization {
    fn __repr__(&self) -> String {
        format!(
            "Generalization(common={}, vars={}, scoped_vars={}, retention={:.3}, skeleton={:?})",
            self.common,
            self.vars,
            self.scoped_vars,
            self.retention,
            truncate(&self.skeleton, 60)
        )
    }
}

fn truncate(s: &str, n: usize) -> String {
    match s.char_indices().nth(n) {
        Some((i, _)) => format!("{}…", &s[..i]),
        None => s.to_string(),
    }
}

// ---------------------------------------------------------------------------
// The handle
// ---------------------------------------------------------------------------

/// A parsed slice. One load, many queries.
#[pyclass(module = "fh_atlas", frozen)]
pub struct Corpus {
    path: String,
    graph: Graph,
    skel: Mutex<Option<Skel>>,
}

/// The statement layer: built lazily, mutated by every erasure and every generalization.
struct Skel {
    arena: Arena,
    sigs: Signatures,
    cache: EraseCache,
    terms: HashMap<String, TermId>,
    /// Names whose `stmt` field the arena's parser rejected, with its own message. Kept
    /// rather than counted, so the query that asks about one of them can say why.
    unparsable: HashMap<String, String>,
}

impl Skel {
    fn build(graph: &Graph) -> Skel {
        let mut arena = Arena::new();
        let mut terms = HashMap::new();
        let mut unparsable = HashMap::new();
        let mut sig_rows: Vec<(SymId, TermId)> = Vec::new();
        for name in graph.names() {
            let Some(stmt) = graph.get(name).and_then(|d| d.stmt.as_deref()) else {
                continue;
            };
            match arena.parse(stmt) {
                Ok(t) => {
                    // A declaration's own statement *is* its argument interface, so the
                    // signature table needs no extraction beyond this loop.
                    let sym = arena.intern_sym(name);
                    sig_rows.push((sym, t));
                    terms.insert(name.clone(), t);
                }
                Err(e) => {
                    unparsable.insert(name.clone(), e.to_string());
                }
            }
        }
        let sigs = Signatures::from_rows(&arena, sig_rows.into_iter());
        Skel {
            arena,
            sigs,
            cache: EraseCache::new(),
            terms,
            unparsable,
        }
    }
}

/// Failures from the statement layer, raised after the GIL is reacquired.
enum SkelFail {
    NoStatement { name: String, reason: String },
    Unparsable { name: String, reason: String },
    Poisoned,
}

impl From<SkelFail> for PyErr {
    fn from(f: SkelFail) -> PyErr {
        match f {
            SkelFail::NoStatement { name, reason } => NoStatement::new_err(format!(
                "`{name}` has no encoded statement in this slice: {reason}"
            )),
            SkelFail::Unparsable { name, reason } => NoStatement::new_err(format!(
                "`{name}`'s statement encoding could not be parsed: {reason}"
            )),
            SkelFail::Poisoned => AtlasError::new_err(
                "this corpus's statement arena was left inconsistent by an earlier panic; \
                 reload the slice",
            ),
        }
    }
}

/// Failures from reading a slice, raised after the GIL is reacquired.
enum LoadFail {
    Missing(String),
    Io(String),
    Row(String),
}

impl From<LoadFail> for PyErr {
    fn from(f: LoadFail) -> PyErr {
        match f {
            LoadFail::Missing(m) => PyFileNotFoundError::new_err(m),
            LoadFail::Io(m) => PyOSError::new_err(m),
            LoadFail::Row(m) => SliceError::new_err(m),
        }
    }
}

#[pymethods]
impl Corpus {
    /// Read and parse a B1 JSONL slice. The one expensive call in the API.
    #[staticmethod]
    fn load(py: Python<'_>, path: PathBuf) -> PyResult<Corpus> {
        let shown = path.display().to_string();
        let graph = py.detach(|| -> Result<Graph, LoadFail> {
            let text = std::fs::read_to_string(&path).map_err(|e| match e.kind() {
                std::io::ErrorKind::NotFound => LoadFail::Missing(format!(
                    "no slice at {shown} — produce one with \
                     `cd lean && lake exe atlas_extract <Module> > {shown}`"
                )),
                _ => LoadFail::Io(format!("{shown}: {e}")),
            })?;
            Graph::from_jsonl(&text).map_err(|e| LoadFail::Row(format!("{shown}: {e}")))
        })?;
        Ok(Corpus {
            path: path.display().to_string(),
            graph,
            skel: Mutex::new(None),
        })
    }

    fn __len__(&self) -> usize {
        self.graph.len()
    }

    fn __repr__(&self) -> String {
        format!("<Corpus {} — {} declarations>", self.path, self.graph.len())
    }

    /// Every declaration name in the slice, sorted.
    fn names(&self, py: Python<'_>) -> Vec<String> {
        py.detach(|| self.graph.names().cloned().collect())
    }

    /// One declaration, or `None` if the slice does not have it.
    fn get(&self, name: &str) -> Option<Decl> {
        self.graph.get(name).map(Decl::from)
    }

    /// A shortest dependency chain from `source` down to `target`, or `None` if there is
    /// none under this lens.
    #[pyo3(signature = (source, target, lens = "both"))]
    fn why(
        &self,
        py: Python<'_>,
        source: &str,
        target: &str,
        lens: &str,
    ) -> PyResult<Option<Vec<String>>> {
        let lens = parse_lens(lens)?;
        self.known(source)?;
        Ok(py.detach(|| self.graph.why(source, target, lens)))
    }

    /// Everything `name` transitively rests on.
    #[pyo3(signature = (name, lens = "both"))]
    fn foundations(&self, py: Python<'_>, name: &str, lens: &str) -> PyResult<Vec<String>> {
        let lens = parse_lens(lens)?;
        self.known(name)?;
        Ok(py.detach(|| self.graph.foundations(name, lens).into_iter().collect()))
    }

    /// Everything that transitively rests on `name`.
    ///
    /// Unlike the other queries this does not require `name` to be in the slice: asking
    /// what rests on something outside it is a fair question, and the answer is the part of
    /// the slice that cites it.
    #[pyo3(signature = (name, lens = "both"))]
    fn impact(&self, py: Python<'_>, name: &str, lens: &str) -> PyResult<Vec<String>> {
        let lens = parse_lens(lens)?;
        Ok(py.detach(|| self.graph.impact(name, lens).into_iter().collect()))
    }

    /// Declarations ranked by how many others cite them *directly*, most-cited first.
    ///
    /// Direct, not transitive: ranking a whole slice transitively is one BFS per node.
    /// Declarations nothing cites are omitted rather than padding the list with zeros.
    #[pyo3(signature = (lens = "both", top = 20))]
    fn walls(&self, py: Python<'_>, lens: &str, top: usize) -> PyResult<Vec<(String, usize)>> {
        let lens = parse_lens(lens)?;
        Ok(py.detach(|| {
            self.graph
                .ranked_by_citations(lens)
                .into_iter()
                .take_while(|&(_, n)| n > 0)
                .take(top)
                .collect()
        }))
    }

    /// Declarations resting on `sorryAx` or on an axiom outside the whitelist, as
    /// `(who, why)` pairs.
    ///
    /// Transitive on purpose: a complete-looking theorem one step above a hole is not
    /// complete, and that is the case anti-cheat exists to catch. `whitelist=None` means
    /// Lean's own three axioms; an explicit list is used exactly as given, so `[]` allows
    /// nothing.
    #[pyo3(signature = (whitelist = None))]
    fn honesty(
        &self,
        py: Python<'_>,
        whitelist: Option<Vec<String>>,
    ) -> PyResult<Vec<(String, String)>> {
        let allowed: Vec<String> =
            whitelist.unwrap_or_else(|| DEFAULT_WHITELIST.iter().map(|s| s.to_string()).collect());
        Ok(py.detach(|| {
            let mut findings: Vec<(String, String)> = self
                .graph
                .impact("sorryAx", Lens::Proof)
                .into_iter()
                .map(|n| (n, "sorryAx".to_string()))
                .collect();
            for name in self.graph.names() {
                if self.graph.get(name).is_some_and(|d| d.kind == "axiom")
                    && !allowed.contains(name)
                    && name != "sorryAx"
                {
                    for user in self.graph.impact(name, Lens::Proof) {
                        findings.push((user, name.clone()));
                    }
                }
            }
            findings.sort();
            findings.dedup();
            findings
        }))
    }

    /// The declaration's statement erased to `level`, rendered in the I3 grammar.
    ///
    /// Two statements are analogous at a level exactly when this string is the same for
    /// both — erasure interns, so equality of skeletons is equality of these renderings.
    #[pyo3(signature = (name, level = "carriers"))]
    fn skeleton(&self, py: Python<'_>, name: &str, level: &str) -> PyResult<String> {
        let level = parse_level(level)?;
        self.known(name)?;
        Ok(py.detach(|| -> Result<String, SkelFail> {
            let mut guard = self.statements()?;
            let s = guard.as_mut().expect("statements() builds it");
            let t = self.term_of(s, name)?;
            let e = erase(&mut s.arena, &s.sigs, &mut s.cache, t, level);
            Ok(s.arena.render(e))
        })?)
    }

    /// Anti-unify two statements: the most specific term that matches both.
    ///
    /// Over the statements as encoded, not as erased — the concrete part is what the two
    /// theorems genuinely share and each variable is a place where they differ.
    fn generalize(&self, py: Python<'_>, left: &str, right: &str) -> PyResult<Generalization> {
        self.known(left)?;
        self.known(right)?;
        Ok(py.detach(|| -> Result<Generalization, SkelFail> {
            let mut guard = self.statements()?;
            let s = guard.as_mut().expect("statements() builds it");
            let (x, y) = (self.term_of(s, left)?, self.term_of(s, right)?);
            let g = lgg::generalize(&mut s.arena, x, y);
            Ok(Generalization {
                skeleton: s.arena.render(g.skeleton),
                common: g.common,
                vars: g.vars,
                scoped_vars: g.scoped_vars,
                retention: g.retention,
            })
        })?)
    }
}

impl Corpus {
    fn known(&self, name: &str) -> PyResult<()> {
        if self.graph.get(name).is_some() {
            Ok(())
        } else {
            Err(UnknownDeclaration::new_err(format!(
                "`{name}` is not in this slice ({} declarations from {})",
                self.graph.len(),
                self.path
            )))
        }
    }

    fn statements(&self) -> Result<MutexGuard<'_, Option<Skel>>, SkelFail> {
        let mut guard = self.skel.lock().map_err(|_| SkelFail::Poisoned)?;
        if guard.is_none() {
            *guard = Some(Skel::build(&self.graph));
        }
        Ok(guard)
    }

    fn term_of(&self, s: &Skel, name: &str) -> Result<TermId, SkelFail> {
        if let Some(&t) = s.terms.get(name) {
            return Ok(t);
        }
        if let Some(reason) = s.unparsable.get(name) {
            return Err(SkelFail::Unparsable {
                name: name.to_string(),
                reason: reason.clone(),
            });
        }
        let reason = self
            .graph
            .get(name)
            .and_then(|d| d.stmt_error.clone())
            .unwrap_or_else(|| "the row carries no `stmt` field".to_string());
        Err(SkelFail::NoStatement {
            name: name.to_string(),
            reason,
        })
    }
}

fn parse_lens(s: &str) -> PyResult<Lens> {
    Ok(match s {
        "statement" => Lens::Statement,
        "proof" => Lens::Proof,
        "both" => Lens::Both,
        other => {
            return Err(PyValueError::new_err(format!(
                "unknown lens `{other}` — expected `statement` (what the claim rests on), \
                 `proof` (what the argument rests on) or `both`"
            )));
        }
    })
}

fn parse_level(s: &str) -> PyResult<Level> {
    Level::parse(s).ok_or_else(|| {
        PyValueError::new_err(format!(
            "unknown erasure level `{s}` — expected one of: {}",
            Level::ALL.map(Level::name).join(", ")
        ))
    })
}

#[pymodule]
fn fh_atlas(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_class::<Corpus>()?;
    m.add_class::<Decl>()?;
    m.add_class::<Generalization>()?;
    m.add("AtlasError", m.py().get_type::<AtlasError>())?;
    m.add("SliceError", m.py().get_type::<SliceError>())?;
    m.add(
        "UnknownDeclaration",
        m.py().get_type::<UnknownDeclaration>(),
    )?;
    m.add("NoStatement", m.py().get_type::<NoStatement>())?;
    Ok(())
}
