//! Dictionaries, transport and the frontier (B6, atlas.md §2).
//!
//! atlas.md calls these "query-layer compositions once the indexes exist", and they are:
//! every one is B4's skeletons and B2's citation graph asked a different question.
//!
//! * **`dictionary A B`** — the maximal partial functor between two theory fragments:
//!   every skeleton-matched row, tagged with its epistemic status, plus the report that
//!   matters most, the **missing entries** — concepts on one side with no partner on the
//!   other. atlas.md's canonical example is the number-field/function-field dictionary's
//!   missing Frobenius row.
//! * **`transport row stmt`** — apply a row's substitution and hand the image on. All
//!   three outcomes are signal: it already exists (the dictionary is strengthened), it is
//!   refuted (**the analogy's boundary is located**, which is itself structural knowledge),
//!   or it is open (a directed target).
//! * **`frontier`** — theory pairs with high skeleton similarity and near-zero
//!   cross-citation. Similarity without traffic is an unexplored interface, and the ranked
//!   list is a research agenda.
//!
//! # A theory is a module prefix
//!
//! Crude and honest. `Mathlib.Algebra` and `Mathlib.Analysis` are different theories;
//! `Mathlib.Algebra.Order.Field.Basic` and `Mathlib.Algebra.Group.Defs` are the same one.
//! Depth 2 for Mathlib, depth 1 elsewhere, which is the same rule `similar`'s cross-theory
//! boost uses so the two agree about what "cross-theory" means.

use std::collections::{BTreeMap, BTreeSet, HashMap};

use crate::graph::Graph;
use crate::skel::erase::Level;
use crate::skel::index::{IndexConfig, SkeletonIndex};
use crate::skel::lgg::matches;
use crate::skel::term::{Arena, Node, TermId};

/// A declaration's theory: the module prefix at the depth that distinguishes subjects.
pub fn theory_of(module: &str) -> &str {
    let depth = if module.starts_with("Mathlib.") { 2 } else { 1 };
    let mut end = module.len();
    let mut seen = 0;
    for (i, c) in module.char_indices() {
        if c == '.' {
            seen += 1;
            if seen == depth {
                end = i;
                break;
            }
        }
    }
    &module[..end]
}

/// Whether both halves of a row are established, one, or neither.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Status {
    BothProven,
    OneProven,
    NeitherProven,
}

impl Status {
    pub fn name(self) -> &'static str {
        match self {
            Status::BothProven => "both-proven",
            Status::OneProven => "one-proven",
            Status::NeitherProven => "neither-proven",
        }
    }
}

/// One candidate dictionary row.
#[derive(Clone, Debug)]
pub struct Row {
    pub left: String,
    pub right: String,
    pub skeleton: String,
    pub retention: f32,
    pub status: Status,
    /// True when no variable abstracts a locally bound thing. `transport` refuses the
    /// rest: a row whose hole stands for something under a binder cannot be instantiated
    /// independently of that binder.
    pub transportable: bool,
}

/// A dictionary between two theory fragments.
pub struct Dictionary {
    pub left_theory: String,
    pub right_theory: String,
    pub rows: Vec<Row>,
    /// Declarations on the left with no partner on the right. **The point of the
    /// exercise**: a missing entry is where the analogy has not been made, which is where
    /// the research is.
    pub missing_left: Vec<String>,
    pub missing_right: Vec<String>,
}

/// How a dictionary is assembled. A struct rather than five positional arguments,
/// because the review that produced `pool_width` and `exclude_subprefix` will not be the
/// last to add one.
#[derive(Clone, Debug, PartialEq)]
pub struct DictOptions {
    /// Rows kept per left declaration.
    pub per_decl: usize,
    pub theorems_only: bool,
    /// Candidates retrieved per left. Distinct from `per_decl` on purpose: the selection
    /// needs alternatives to choose between, and taking `per_decl * 4` globally left most
    /// lefts with exactly one right-theory candidate — a "choice" with one option.
    pub pool_width: usize,
    /// Right-hand sub-prefixes to drop. `theory_of` files `Mathlib.Algebra.Order.*` under
    /// `Mathlib.Algebra`, so 27.1% of an Order <-> Algebra dictionary was order theory
    /// matched against itself. Excluded here rather than by changing `theory_of`, which
    /// `frontier` shares and which C1 replaces with versioned cluster manifests anyway.
    pub exclude_subprefix: Vec<String>,
    /// Final name components treated as administrative rather than mathematical.
    ///
    /// The worst collision target on the first run was `instReflDvd_mathlib`, claimed by
    /// fourteen lefts — a typeclass instance whose extracted `kind` is `"theorem"`, so
    /// `theorems_only` cannot see it. B1 emits no `is_instance`, so this is a **name
    /// heuristic and is reported as one**: it caught 6.9% of rows on the first slice, and
    /// a principled fix needs a field the extractor does not yet have.
    pub exclude_roles: Vec<String>,
}

impl Default for DictOptions {
    fn default() -> DictOptions {
        DictOptions {
            per_decl: 1,
            theorems_only: true,
            pool_width: 64,
            exclude_subprefix: Vec::new(),
            exclude_roles: Vec::new(),
        }
    }
}

/// Is this name administrative under the given heuristics?
fn excluded_role(name: &str, roles: &[String]) -> bool {
    let last = name.rsplit('.').next().unwrap_or(name);
    roles.iter().any(|r| {
        if let Some(pre) = r.strip_suffix('*') {
            last.starts_with(pre)
        } else {
            last == r
        }
    })
}

/// Assemble the maximal partial functor between two theories.
/// `theorems_only` for the same reason [`frontier`] wants it: a dictionary row between two
/// *recursors* (`Compl.rec ~ Star.rec`) is a fact about how Lean compiles inductive types,
/// not a structure-preserving map between theories.
pub fn dictionary(
    idx: &mut SkeletonIndex,
    left: &str,
    right: &str,
    cfg: &IndexConfig,
    opts: &DictOptions,
) -> Dictionary {
    let (per_decl, theorems_only) = (opts.per_decl, opts.theorems_only);
    // Retrieval itself is restricted to the target theory, so the pool is candidates that
    // can become rows rather than a global top-N mostly discarded a line later.
    let cfg = &IndexConfig {
        restrict_prefix: Some(right.to_string()),
        theorems_only,
        ..cfg.clone()
    };
    let (mut rows, mut matched_left, mut matched_right) =
        (Vec::new(), BTreeSet::new(), BTreeSet::new());
    let names: Vec<String> = (0..idx.len())
        .map(|i| {
            idx.name_of(crate::skel::index::DeclId(i as u32))
                .to_string()
        })
        .collect();
    let lefts: Vec<String> = names
        .iter()
        .filter(|n| idx.module_of(n).is_some_and(|m| theory_of(m) == left))
        .filter(|n| !theorems_only || idx.is_theorem(n))
        .cloned()
        .collect();

    for name in &lefts {
        let Ok(neighbours) = idx.similar(name, opts.pool_width, cfg) else {
            continue;
        };
        let mut kept = 0;
        for n in neighbours {
            if theory_of(&n.module) != right || (theorems_only && !idx.is_theorem(&n.name)) {
                continue;
            }
            if opts
                .exclude_subprefix
                .iter()
                .any(|p| n.module == *p || n.module.starts_with(&format!("{p}.")))
            {
                continue;
            }
            if excluded_role(&n.name, &opts.exclude_roles) {
                continue;
            }
            let status = match (idx.is_theorem(name), idx.is_theorem(&n.name)) {
                (true, true) => Status::BothProven,
                (true, false) | (false, true) => Status::OneProven,
                (false, false) => Status::NeitherProven,
            };
            matched_left.insert(name.clone());
            matched_right.insert(n.name.clone());
            rows.push(Row {
                left: name.clone(),
                right: n.name.clone(),
                skeleton: n.skeleton,
                retention: n.retention,
                status,
                transportable: n.transportable,
            });
            kept += 1;
            if kept >= per_decl {
                break;
            }
        }
    }

    let rights: Vec<String> = names
        .iter()
        .filter(|n| idx.module_of(n).is_some_and(|m| theory_of(m) == right))
        .filter(|n| !theorems_only || idx.is_theorem(n))
        .cloned()
        .collect();
    rows.sort_by(|a, b| {
        b.retention
            .total_cmp(&a.retention)
            .then(a.left.cmp(&b.left))
    });
    Dictionary {
        left_theory: left.to_string(),
        right_theory: right.to_string(),
        missing_left: lefts
            .into_iter()
            .filter(|n| !matched_left.contains(n))
            .collect(),
        missing_right: rights
            .into_iter()
            .filter(|n| !matched_right.contains(n))
            .collect(),
        rows,
    }
}

/// What transporting a statement produced.
#[derive(Clone, Debug)]
pub enum Transported {
    /// The image is already a declaration in the slice: the dictionary is strengthened
    /// and this row is now verified rather than candidate.
    Exists { name: String, image: String },
    /// The image is well-formed and not present. This is the directed target — hand it to
    /// the falsification battery first (`#fh_falsify`) and to a prover second, because
    /// refutation is cheap and locates the analogy's boundary.
    Open { image: String },
}

/// Refusals, kept distinct from "nothing found".
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum TransportError {
    NotInSlice(String),
    /// The statement does not match the row's left pattern, so the row says nothing about
    /// it. Not a failure of transport — a failure of applicability.
    NoMatch,
    /// A variable stands for something under a binder, so it cannot be instantiated
    /// independently. Reported rather than transported wrongly.
    Scoped,
}

impl std::fmt::Display for TransportError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TransportError::NotInSlice(n) => write!(f, "`{n}` is not in this slice"),
            TransportError::NoMatch => {
                write!(
                    f,
                    "the statement does not match this row's left-hand pattern"
                )
            }
            TransportError::Scoped => write!(
                f,
                "this row has a variable standing for something under a binder, so it \
                 cannot be instantiated independently of that binder"
            ),
        }
    }
}

/// Apply a row to a statement: match the left, re-instantiate with the right.
///
/// The row is `lgg(left, right)`. Matching the subject against the skeleton gives the
/// subject's own instantiation; matching `right` against the same skeleton gives the
/// target's. Transport is composing the first with the second — which is exactly the
/// "partial structure-preserving map" a dictionary row *is*.
pub fn transport(
    idx: &mut SkeletonIndex,
    row_left: &str,
    row_right: &str,
    subject: &str,
    level: Level,
) -> Result<Transported, TransportError> {
    let (row, _) = idx
        .generalize_named(row_left, row_right, level)
        .map_err(TransportError::NotInSlice)?;
    if row.scoped_vars > 0 {
        return Err(TransportError::Scoped);
    }
    let skeleton = row.skeleton;
    let subj = idx
        .term_of(subject, level)
        .ok_or(TransportError::NotInSlice(subject.into()))?;
    let right = idx
        .term_of(row_right, level)
        .ok_or(TransportError::NotInSlice(row_right.into()))?;

    let arena = idx.arena_mut();
    let sub_subject = matches(arena, skeleton, subj).ok_or(TransportError::NoMatch)?;
    let sub_right = matches(arena, skeleton, right).ok_or(TransportError::NoMatch)?;

    // The image: the subject's structure, with each hole filled the way the row's *right*
    // side fills it. Where the subject and the row's left agree, nothing moves.
    let mut image_subst = HashMap::new();
    for (k, v) in &sub_subject {
        image_subst.insert(*k, sub_right.get(k).copied().unwrap_or(*v));
    }
    let image = substitute(arena, skeleton, &image_subst);
    let rendered = arena.render(image);
    match idx.name_with_term(image, level) {
        Some(name) => Ok(Transported::Exists {
            name,
            image: rendered,
        }),
        None => Ok(Transported::Open { image: rendered }),
    }
}

/// Replace each `Var(k)` with its binding.
pub fn substitute(a: &mut Arena, t: TermId, subst: &HashMap<u32, TermId>) -> TermId {
    let node = match a.node(t) {
        Node::Var(k) => return subst.get(&k).copied().unwrap_or(t),
        Node::App(x, y) => Node::App(substitute(a, x, subst), substitute(a, y, subst)),
        Node::Lam(b, d, y) => Node::Lam(b, substitute(a, d, subst), substitute(a, y, subst)),
        Node::Pi(b, d, y) => Node::Pi(b, substitute(a, d, subst), substitute(a, y, subst)),
        Node::Let(x, y, z) => Node::Let(
            substitute(a, x, subst),
            substitute(a, y, subst),
            substitute(a, z, subst),
        ),
        Node::Proj(s, i, e) => Node::Proj(s, i, substitute(a, e, subst)),
        _ => return t,
    };
    a.intern(node)
}

/// One theory pair's frontier reading.
#[derive(Clone, Debug)]
pub struct Frontier {
    pub left: String,
    pub right: String,
    /// Shape buckets both theories occupy, as a fraction of the smaller theory's buckets.
    pub similarity: f32,
    /// Declarations in one theory whose statement or proof cites the other.
    pub cross_citations: usize,
    pub left_size: usize,
    pub right_size: usize,
    /// High similarity, low traffic. The ranked list is the research agenda.
    pub score: f32,
}

/// Theory pairs that look alike and do not talk to each other.
/// `theorems_only` is the useful default, and the reason is worth stating: without it the
/// top of the ranking is `Aesop ~ ProofWidgets`, `Aesop ~ Qq`, `Batteries ~ Mathlib.Lean`
/// — metaprogramming libraries that share shapes because they are all Lean code doing
/// monadic work over syntax trees, and that do not cite each other because they are
/// siblings. Structurally that is a correct answer to the question as posed. It is also
/// not mathematics, and a research agenda made of it would be a list of places to go
/// refactor.
///
/// This is the third place the same lesson has applied — B5's classes and dictionaries
/// need it too. In a corpus that is half infrastructure, "restrict to claims" is not a
/// filter, it is the difference between measuring mathematics and measuring Lean.
pub fn frontier(
    idx: &mut SkeletonIndex,
    graph: &Graph,
    min_theory_size: usize,
    top: usize,
    theorems_only: bool,
    exclude: &[String],
) -> Vec<Frontier> {
    // Which shape buckets each theory occupies, and which theory each declaration is in.
    let mut theory_shapes: BTreeMap<String, BTreeSet<TermId>> = BTreeMap::new();
    let mut theory_of_decl: HashMap<String, String> = HashMap::new();
    let mut sizes: BTreeMap<String, usize> = BTreeMap::new();
    for i in 0..idx.len() {
        let d = crate::skel::index::DeclId(i as u32);
        let name = idx.name_of(d).to_string();
        if theorems_only && !idx.is_theorem(&name) {
            continue;
        }
        let Some(m) = idx.module_of(&name) else {
            continue;
        };
        let th = theory_of(m).to_string();
        theory_of_decl.insert(name, th.clone());
        *sizes.entry(th.clone()).or_insert(0) += 1;
        let sh = idx.shape_of(d);
        theory_shapes.entry(th).or_default().insert(sh);
    }

    let theories: Vec<String> = sizes
        .iter()
        .filter(|&(_, &n)| n >= min_theory_size)
        .map(|(t, _)| t.clone())
        // Excluding infrastructure is not cheating, it is asking the question you meant.
        // On a corpus that is two-thirds `Init`/`Std`/`Lean`, the highest-scoring pairs
        // are metaprogramming siblings — correct, and not a mathematical agenda.
        .filter(|t| !exclude.iter().any(|e| t == e))
        .collect();

    // Cross-citation counts, from B2's graph rather than from imports: what a proof
    // actually uses, not what a file happens to import.
    let mut cites: HashMap<(String, String), usize> = HashMap::new();
    for name in graph.names() {
        let Some(from) = theory_of_decl.get(name.as_str()) else {
            continue;
        };
        let Some(decl) = graph.get(name) else {
            continue;
        };
        for used in decl.uses_statement.iter().chain(decl.uses_proof.iter()) {
            if let Some(to) = theory_of_decl.get(used.as_str())
                && to != from
            {
                let key = if from < to {
                    (from.clone(), to.clone())
                } else {
                    (to.clone(), from.clone())
                };
                *cites.entry(key).or_insert(0) += 1;
            }
        }
    }

    let mut out = Vec::new();
    for (i, a) in theories.iter().enumerate() {
        for b in &theories[i + 1..] {
            let (sa, sb) = (&theory_shapes[a], &theory_shapes[b]);
            let shared = sa.intersection(sb).count();
            let denom = sa.len().min(sb.len()).max(1);
            let similarity = shared as f32 / denom as f32;
            let cross = cites.get(&(a.clone(), b.clone())).copied().unwrap_or(0);
            // Similarity buys, traffic discounts. A theory pair that already cites each
            // other heavily is explored, whatever it looks like.
            let score = similarity / (1.0 + (cross as f32).sqrt());
            out.push(Frontier {
                left: a.clone(),
                right: b.clone(),
                similarity,
                cross_citations: cross,
                left_size: sizes[a],
                right_size: sizes[b],
                score,
            });
        }
    }
    out.sort_by(|x, y| y.score.total_cmp(&x.score).then(x.left.cmp(&y.left)));
    out.truncate(top);
    out
}

/// What a dictionary's row set actually is, as opposed to what it is called.
///
/// A dictionary is meant to be a *partial structure-preserving map*. Greedy
/// per-declaration selection cannot produce one — it returns each left's nearest
/// right-theory neighbour and nothing looks across rows — so the first thing M3a needs is
/// a way to say how far the output is from a map, before anything tries to fix it.
///
/// # Rights are counted by statement, not by name
///
/// `dvd_trans` and `Dvd.dvd.trans` are one theorem under two names, and a left displaced
/// onto the alias of its old partner would otherwise score as a coherence *improvement*.
/// So the collision count keys on the `Exact` skeleton — statement identity — and the
/// name-keyed count is reported beside it, because the gap between them is itself worth
/// seeing.
#[derive(Clone, Debug, PartialEq)]
pub struct Coherence {
    pub rows: usize,
    pub distinct_lefts: usize,
    /// Distinct right-hand *names*.
    pub distinct_rights: usize,
    /// Distinct right-hand *statements*. Lower than `distinct_rights` exactly when the
    /// dictionary points at two names for one theorem.
    pub distinct_right_statements: usize,
    /// Right statements claimed by more than one left.
    pub contested: usize,
    /// Rows whose right statement is contested — the fraction of the dictionary that is
    /// not a map.
    pub rows_in_collision: usize,
    /// The worst offenders: `(right name, number of lefts claiming its statement)`.
    pub worst: Vec<(String, usize)>,
}

impl Coherence {
    pub fn collision_rate(&self) -> f32 {
        self.rows_in_collision as f32 / self.rows.max(1) as f32
    }
}

/// Measure a dictionary against the map it claims to be.
pub fn coherence(idx: &mut SkeletonIndex, d: &Dictionary, worst: usize) -> Coherence {
    // Statement identity, so two names for one theorem count once. A name with no
    // encodable statement falls back to its own name, which cannot collide with anything.
    let mut key_of: HashMap<&str, String> = HashMap::new();
    for r in &d.rows {
        if !key_of.contains_key(r.right.as_str()) {
            let k = idx
                .skeleton_of(&r.right, Level::Exact)
                .unwrap_or_else(|| format!("\u{0}name:{}", r.right));
            key_of.insert(r.right.as_str(), k);
        }
    }

    let mut lefts_per_statement: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for r in &d.rows {
        lefts_per_statement
            .entry(key_of[r.right.as_str()].as_str())
            .or_default()
            .insert(&r.left);
    }

    let contested: BTreeSet<&str> = lefts_per_statement
        .iter()
        .filter(|(_, ls)| ls.len() > 1)
        .map(|(k, _)| *k)
        .collect();

    let rows_in_collision = d
        .rows
        .iter()
        .filter(|r| contested.contains(key_of[r.right.as_str()].as_str()))
        .count();

    // Reported by a representative name rather than by the encoding, which is unreadable.
    let mut by_name: BTreeMap<&str, usize> = BTreeMap::new();
    for r in &d.rows {
        let n = lefts_per_statement[key_of[r.right.as_str()].as_str()].len();
        by_name.insert(&r.right, n);
    }
    let mut worst_v: Vec<(String, usize)> = by_name
        .into_iter()
        .filter(|(_, n)| *n > 1)
        .map(|(n, c)| (n.to_string(), c))
        .collect();
    worst_v.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(&b.0)));
    worst_v.truncate(worst);

    Coherence {
        rows: d.rows.len(),
        distinct_lefts: d
            .rows
            .iter()
            .map(|r| &r.left)
            .collect::<BTreeSet<_>>()
            .len(),
        distinct_rights: d
            .rows
            .iter()
            .map(|r| &r.right)
            .collect::<BTreeSet<_>>()
            .len(),
        distinct_right_statements: lefts_per_statement.len(),
        contested: contested.len(),
        rows_in_collision,
        worst: worst_v,
    }
}

/// §9's acceptance criterion, as a runnable control: *"false shuffled mappings are
/// rejected at a substantially earlier rate than genuine mappings."*
///
/// Every gate M3a's first draft proposed measured the dictionary against itself —
/// injectivity, total score, row counts — and a perfectly injective, high-scoring,
/// entirely fabricated dictionary passes all of them. This is the one that a fabricated
/// dictionary fails: re-pair each left with a *different* right drawn from the same
/// theory, and compare the retention the anti-unifier assigns.
///
/// If genuine pairs do not separate from shuffled ones, the floors are admitting
/// coincidence and no number computed downstream is about analogy.
#[derive(Clone, Debug, PartialEq)]
pub struct ShuffleControl {
    pub pairs: usize,
    pub genuine_mean: f32,
    pub shuffled_mean: f32,
    /// Shuffled pairs that would clear the same floors the real rows cleared. The rate a
    /// coincidence survives the admission test.
    pub shuffled_admitted: usize,
    /// Fraction of (genuine, shuffled) comparisons where the genuine pair scores higher.
    /// 1.0 is perfect separation, 0.5 is chance.
    pub separation: f32,
}

/// Deterministic: the shuffle is a fixed stride through the right-hand pool, not a random
/// permutation, so a failure is reproducible and a reviewer can re-derive the pairing.
/// `stride` must be coprime with the pool size to be a permutation; 7919 is prime and
/// larger than any right-hand pool here.
pub fn shuffle_control(
    idx: &mut SkeletonIndex,
    d: &Dictionary,
    cfg: &IndexConfig,
) -> ShuffleControl {
    let rights: Vec<String> = d
        .rows
        .iter()
        .map(|r| r.right.clone())
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect();
    if rights.len() < 2 || d.rows.is_empty() {
        return ShuffleControl {
            pairs: 0,
            genuine_mean: 0.0,
            shuffled_mean: 0.0,
            shuffled_admitted: 0,
            separation: 0.0,
        };
    }

    let (mut gsum, mut ssum, mut admitted, mut wins, mut n) =
        (0.0f32, 0.0f32, 0usize, 0usize, 0usize);
    for (i, r) in d.rows.iter().enumerate() {
        // A different right, chosen deterministically and never the true partner.
        let mut j = (i * 7919 + 13) % rights.len();
        if rights[j] == r.right {
            j = (j + 1) % rights.len();
        }
        let Ok((g, _)) = idx.generalize_named(&r.left, &rights[j], cfg.lgg_level) else {
            continue;
        };
        let shuffled = g.retention;
        if g.common >= cfg.min_common && shuffled >= cfg.min_retention {
            admitted += 1;
        }
        if r.retention > shuffled {
            wins += 1;
        }
        gsum += r.retention;
        ssum += shuffled;
        n += 1;
    }

    ShuffleControl {
        pairs: n,
        genuine_mean: gsum / n.max(1) as f32,
        shuffled_mean: ssum / n.max(1) as f32,
        shuffled_admitted: admitted,
        separation: wins as f32 / n.max(1) as f32,
    }
}
