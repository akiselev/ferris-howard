//! The skeleton index and `atlas similar` (B4, atlas.md §1c).
//!
//! # Why a prefilter, and what it does *not* guarantee
//!
//! Comparing a query against 131,000 statements is 131,000 anti-unifications — about half
//! a second, which sounds affordable until it is done per query in a loop. The index cuts
//! it to a few hundred candidates.
//!
//! There is a tempting theorem here and it is worth being explicit that it does not do the
//! job people want it to. If `lgg(x,y)` contains a hole-free subterm `s` with `|s| ≥ K`,
//! then `x` and `y` each literally contain `s` — so an inverted index over subterms has no
//! false negatives *with respect to that predicate*. True, and nearly useless: the query
//! is "top-k by retention", not "shares a big subterm". Measured recall against brute
//! force tells the real story, and the gate is a recall floor rather than an equality.
//!
//! # Three sources, all of them needed
//!
//! * **A — whole-statement `Shape` bucket.** Exact structural twins. Cheap and precise;
//!   skipped when the bucket is enormous, since a 7,000-member bucket is a tautology
//!   rather than a lead.
//! * **B — concrete subterms at `Presentation`.** Closed subterms of size ≥ 3, plus
//!   *open* ones (carrying loose de Bruijn indices) of size ≥ 5. Open subterms are sound
//!   keys because de Bruijn indices are preserved along common structure.
//! * **C — `Shape` subterms of size ≥ 8.** Partial structural overlap. This is the source
//!   that carries the design: it is what lets `le_trans` reach `dvd_trans`, where no
//!   concrete subterm is shared at all.
//!
//! Rarity, not frequency, is what the ranking rewards — a shared subterm occurring in two
//! declarations is a discovery, one occurring in four thousand is punctuation. That is the
//! opposite of what a compression-driven library-learner optimises, and it is why this is
//! an inverted index with IDF rather than an e-graph.

use std::collections::{BTreeSet, HashMap};

use super::erase::{EraseCache, Level, Signatures, erase};
use super::lgg::{Generalization, generalize};
use super::term::{Arena, Node, TermId};
use crate::graph::GraphError;

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Debug)]
pub struct DeclId(pub u32);

/// Which of the three sources produced a candidate. Reported, so a surprising hit can be
/// traced to the reason it was considered.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct Sources(pub u8);

impl Sources {
    pub const SHAPE: u8 = 1;
    pub const SUBTERM: u8 = 2;
    pub const SHAPE_SUBTERM: u8 = 4;

    pub fn add(&mut self, s: u8) {
        self.0 |= s;
    }
    pub fn has(self, s: u8) -> bool {
        self.0 & s != 0
    }
    pub fn describe(self) -> String {
        let mut v = Vec::new();
        if self.has(Sources::SHAPE) {
            v.push("shape");
        }
        if self.has(Sources::SUBTERM) {
            v.push("subterm");
        }
        if self.has(Sources::SHAPE_SUBTERM) {
            v.push("shape-subterm");
        }
        v.join("+")
    }
}

/// Compressed-sparse-row posting lists, with each key's inverse document frequency.
pub struct Postings {
    keys: Vec<TermId>,
    starts: Vec<u32>,
    decls: Vec<DeclId>,
    idf: Vec<f32>,
}

impl Postings {
    fn build(mut pairs: Vec<(TermId, DeclId)>, n_docs: usize, max_len: usize) -> Postings {
        pairs.sort_unstable();
        pairs.dedup();
        let (mut keys, mut starts, mut decls, mut idf) =
            (Vec::new(), Vec::new(), Vec::new(), Vec::new());
        let mut i = 0;
        while i < pairs.len() {
            let key = pairs[i].0;
            let mut j = i;
            while j < pairs.len() && pairs[j].0 == key {
                j += 1;
            }
            // A key held by a large fraction of the corpus carries no information and
            // would dominate every candidate set it appears in. Dropped, not down-weighted:
            // down-weighting still pays the cost of walking it.
            if j - i <= max_len {
                keys.push(key);
                starts.push(decls.len() as u32);
                idf.push((n_docs as f32 / (j - i) as f32).ln());
                for p in &pairs[i..j] {
                    decls.push(p.1);
                }
            }
            i = j;
        }
        starts.push(decls.len() as u32);
        Postings {
            keys,
            starts,
            decls,
            idf,
        }
    }

    pub fn get(&self, key: TermId) -> Option<(&[DeclId], f32)> {
        let i = self.keys.binary_search(&key).ok()?;
        let (a, b) = (self.starts[i] as usize, self.starts[i + 1] as usize);
        Some((&self.decls[a..b], self.idf[i]))
    }

    pub fn key_count(&self) -> usize {
        self.keys.len()
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct IndexConfig {
    pub min_concrete_closed: u32,
    pub min_concrete_open: u32,
    pub min_shape_sub: u32,
    /// A posting list longer than this fraction of the corpus is dropped as uninformative.
    pub max_posting_fraction: f32,
    pub max_bucket: usize,
    pub candidate_budget: usize,
    /// The level the *reported* skeleton is computed at — the row's fidelity.
    pub lgg_level: Level,
    pub min_common: u32,
    pub min_retention: f32,
    /// Ablation knob: query source B with the raw root instead of the `Presentation`
    /// erasure the postings are keyed at. `true` is the repaired behaviour; `false`
    /// reproduces the defect, which is the only honest way to measure what the repair was
    /// worth without reverting it.
    pub source_b_at_build_level: bool,
}

impl Default for IndexConfig {
    fn default() -> IndexConfig {
        IndexConfig {
            min_concrete_closed: 3,
            min_concrete_open: 5,
            min_shape_sub: 8,
            max_posting_fraction: 0.001,
            max_bucket: 600,
            candidate_budget: 600,
            lgg_level: Level::Carriers,
            min_common: 6,
            min_retention: 0.30,
            source_b_at_build_level: true,
        }
    }
}

/// One neighbour, with everything a reader needs to audit the rank rather than trust it.
#[derive(Clone, Debug)]
pub struct Neighbour {
    pub name: String,
    pub module: String,
    pub kind: String,
    pub retention: f32,
    pub common: u32,
    pub vars: u32,
    pub scoped_vars: u32,
    /// The rarest shared key's IDF — how surprising the overlap is.
    pub rarity: f32,
    pub sources: Sources,
    /// The rendered skeleton. This *is* the candidate dictionary row.
    pub skeleton: String,
    /// True when no variable abstracts a locally bound thing. B6 must refuse the rest.
    pub transportable: bool,
    pub score: f32,
}

pub struct SkeletonIndex {
    arena: Arena,
    sigs: Signatures,
    cache: EraseCache,
    names: Vec<String>,
    modules: Vec<String>,
    kinds: Vec<String>,
    by_name: HashMap<String, DeclId>,
    roots: Vec<TermId>,
    shape: Vec<TermId>,
    /// The `Presentation` erasure of each root — the level source B's postings are keyed
    /// at. Kept rather than recomputed because `candidates` takes `&self` and erasure
    /// needs `&mut Arena`; discarding it is what let the query drift to the raw root.
    pres: Vec<TermId>,
    shape_bucket: HashMap<TermId, Vec<DeclId>>,
    concrete: Postings,
    shape_sub: Postings,
    degraded_spines: u64,
    /// The config the postings were built with. Kept so a diagnostic can reproduce the
    /// size floors, and so a result can name the scorer that produced it.
    build_cfg: IndexConfig,
}

impl SkeletonIndex {
    pub fn build(jsonl: &str, cfg: &IndexConfig) -> Result<SkeletonIndex, GraphError> {
        let mut arena = Arena::new();
        let (mut names, mut modules, mut kinds, mut roots) =
            (Vec::new(), Vec::new(), Vec::new(), Vec::new());
        let mut sig_rows = Vec::new();

        for (i, line) in jsonl.lines().enumerate() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }
            let v = crate::json::parse(line).map_err(|reason| GraphError::BadRow {
                line: i + 1,
                reason,
            })?;
            let Some(name) = v.get("name").and_then(|s| s.as_str()) else {
                return Err(GraphError::BadRow {
                    line: i + 1,
                    reason: "row has no `name`".into(),
                });
            };
            // A row whose statement could not be encoded is kept by B1 and skipped here:
            // it has no term to index, and dropping it silently would be worse than
            // saying so.
            let Some(stmt) = v.get("stmt").and_then(|s| s.as_str()) else {
                continue;
            };
            let Ok(t) = arena.parse(stmt) else { continue };
            let sym = arena.intern_sym(name);
            sig_rows.push((sym, t));
            names.push(name.to_string());
            modules.push(
                v.get("module")
                    .and_then(|s| s.as_str())
                    .unwrap_or("")
                    .to_string(),
            );
            kinds.push(
                v.get("kind")
                    .and_then(|s| s.as_str())
                    .unwrap_or("")
                    .to_string(),
            );
            roots.push(t);
        }

        let sigs = Signatures::from_rows(&arena, sig_rows.into_iter());
        let n = roots.len();
        let mut cache = EraseCache::new();

        let mut shape = Vec::with_capacity(n);
        let mut pres_of = Vec::with_capacity(n);
        let mut shape_bucket: HashMap<TermId, Vec<DeclId>> = HashMap::new();
        let mut concrete_pairs = Vec::new();
        let mut shape_pairs = Vec::new();
        let mut degraded_spines = 0u64;

        for (i, &t) in roots.iter().enumerate() {
            let id = DeclId(i as u32);
            let pres = erase(&mut arena, &sigs, &mut cache, t, Level::Presentation);
            let sh = erase(&mut arena, &sigs, &mut cache, t, Level::Shape);
            shape.push(sh);
            pres_of.push(pres);
            shape_bucket.entry(sh).or_default().push(id);

            let mut subs = BTreeSet::new();
            arena.subterms(pres, &mut subs);
            for s in subs {
                let sz = arena.size(s);
                let floor = if arena.is_closed(s) {
                    cfg.min_concrete_closed
                } else {
                    cfg.min_concrete_open
                };
                if sz >= floor {
                    concrete_pairs.push((s, id));
                }
            }
            let mut ssubs = BTreeSet::new();
            arena.subterms(sh, &mut ssubs);
            for s in ssubs {
                if arena.size(s) >= cfg.min_shape_sub {
                    shape_pairs.push((s, id));
                }
            }
            if let Node::Const(sym, _) = arena.node(arena.spine(t).0)
                && !sigs.known(sym)
            {
                degraded_spines += 1;
            }
        }

        let max_len = ((n as f32 * cfg.max_posting_fraction) as usize).max(50);
        let concrete = Postings::build(concrete_pairs, n, max_len);
        let shape_sub = Postings::build(shape_pairs, n, max_len);

        let by_name = names
            .iter()
            .enumerate()
            .map(|(i, n)| (n.clone(), DeclId(i as u32)))
            .collect();

        arena.seal();
        Ok(SkeletonIndex {
            arena,
            sigs,
            cache,
            names,
            modules,
            kinds,
            by_name,
            roots,
            shape,
            pres: pres_of,
            shape_bucket,
            concrete,
            shape_sub,
            degraded_spines,
            build_cfg: cfg.clone(),
        })
    }

    pub fn len(&self) -> usize {
        self.roots.len()
    }
    pub fn is_empty(&self) -> bool {
        self.roots.is_empty()
    }
    pub fn degraded_spines(&self) -> u64 {
        self.degraded_spines
    }
    pub fn id_of(&self, name: &str) -> Option<DeclId> {
        self.by_name.get(name).copied()
    }
    pub fn name_of(&self, d: DeclId) -> &str {
        &self.names[d.0 as usize]
    }
    /// Positional kind and module, so a caller can restrict a sample to *claims* before
    /// measuring anything over it. A uniform sample of a working slice is two-thirds
    /// `Init`/`Std`/`Lean` and half non-theorems, which is how a recall figure ends up
    /// describing Lean's metaprogramming API rather than mathematics.
    pub fn kind_of_at(&self, i: usize) -> &str {
        &self.kinds[i]
    }
    pub fn module_of_at(&self, i: usize) -> &str {
        &self.modules[i]
    }
    pub fn signature_count(&self) -> usize {
        self.sigs.len()
    }
    pub fn module_of(&self, name: &str) -> Option<&str> {
        self.by_name
            .get(name)
            .map(|d| self.modules[d.0 as usize].as_str())
    }
    pub fn is_theorem(&self, name: &str) -> bool {
        self.by_name
            .get(name)
            .is_some_and(|d| self.kinds[d.0 as usize] == "theorem")
    }
    pub fn shape_of(&self, d: DeclId) -> TermId {
        self.shape[d.0 as usize]
    }
    pub fn arena_mut(&mut self) -> &mut Arena {
        &mut self.arena
    }
    /// A declaration's statement at a level, by name.
    pub fn term_of(&mut self, name: &str, level: Level) -> Option<TermId> {
        let d = self.id_of(name)?;
        Some(self.level_term(d, level))
    }
    /// Which declaration, if any, has exactly this statement at this level. Used by
    /// `transport` to tell "already a theorem" from "a directed target".
    pub fn name_with_term(&mut self, t: TermId, level: Level) -> Option<String> {
        (0..self.len()).find_map(|i| {
            let d = DeclId(i as u32);
            (self.level_term(d, level) == t).then(|| self.names[i].clone())
        })
    }
    pub fn key_counts(&self) -> (usize, usize) {
        (self.concrete.key_count(), self.shape_sub.key_count())
    }

    /// Candidates for a query, with the sources each arrived through and the rarest key
    /// that produced it.
    pub fn candidates(&self, q: DeclId, cfg: &IndexConfig) -> Vec<(DeclId, Sources, f32)> {
        let mut hits: HashMap<DeclId, (Sources, f32)> = HashMap::new();
        let note = |hits: &mut HashMap<DeclId, (Sources, f32)>, d: DeclId, src: u8, idf: f32| {
            if d == q {
                return;
            }
            let e = hits.entry(d).or_insert((Sources::default(), 0.0));
            e.0.add(src);
            if idf > e.1 {
                e.1 = idf;
            }
        };

        // A — structural twins.
        let sh = self.shape[q.0 as usize];
        if let Some(bucket) = self.shape_bucket.get(&sh)
            && bucket.len() <= cfg.max_bucket
        {
            let idf = (self.len() as f32 / bucket.len() as f32).ln();
            for &d in bucket {
                note(&mut hits, d, Sources::SHAPE, idf);
            }
        }

        // B and C — subterm overlap. Rarest keys first, so the budget is spent on the
        // most informative overlaps rather than on whatever came first.
        // Source B is keyed on subterms of the *presentation erasure* (see `build`), so
        // it must be queried with the same. Querying with the raw root instead made the
        // lookup miss almost always — the arena is hash-consed, so a term that differs at
        // all differs in its `TermId`. Measured on the 131k algebra slice: 6.7% of a
        // query's subterms hit a posting, and 60.6% of declarations got no source-B
        // candidate whatsoever. At the level the postings were actually built at, 88.2%
        // and 6.9%.
        let pres = if cfg.source_b_at_build_level {
            self.pres[q.0 as usize]
        } else {
            self.roots[q.0 as usize]
        };
        let mut keyed: Vec<(f32, &[DeclId], u8)> = Vec::new();
        for (post, src, term) in [
            (&self.concrete, Sources::SUBTERM, pres),
            (&self.shape_sub, Sources::SHAPE_SUBTERM, sh),
        ] {
            let mut subs = BTreeSet::new();
            self.arena.subterms(term, &mut subs);
            for s in subs {
                if let Some((ds, idf)) = post.get(s) {
                    keyed.push((idf, ds, src));
                }
            }
        }
        keyed.sort_by(|a, b| b.0.total_cmp(&a.0));
        for (idf, ds, src) in keyed {
            if hits.len() >= cfg.candidate_budget {
                break;
            }
            for &d in ds {
                note(&mut hits, d, src, idf);
            }
        }

        let mut out: Vec<_> = hits.into_iter().map(|(d, (s, r))| (d, s, r)).collect();
        out.sort_by_key(|&(d, _, _)| d);
        out
    }

    /// The neighbours of a declaration, ranked.
    pub fn similar(
        &mut self,
        name: &str,
        top: usize,
        cfg: &IndexConfig,
    ) -> Result<Vec<Neighbour>, String> {
        let q = self
            .id_of(name)
            .ok_or_else(|| format!("`{name}` is not in this slice"))?;
        let cands = self.candidates(q, cfg);
        let qt = self.level_term(q, cfg.lgg_level);
        let ln_n = (self.len() as f32).ln();
        let q_root = module_root(&self.modules[q.0 as usize]).to_string();

        let mut out = Vec::new();
        for (d, sources, rarity) in cands {
            let ct = self.level_term(d, cfg.lgg_level);
            let g: Generalization = generalize(&mut self.arena, qt, ct);
            if g.common < cfg.min_common || g.retention < cfg.min_retention {
                continue;
            }
            let cross = module_root(&self.modules[d.0 as usize]) != q_root;
            let (name, module, kind) = (
                self.names[d.0 as usize].clone(),
                self.modules[d.0 as usize].clone(),
                self.kinds[d.0 as usize].clone(),
            );
            let scoped_penalty = 1.0 - 0.30 * g.scoped_vars as f32 / g.vars.max(1) as f32;
            let score = g.retention
                * (1.0 + 0.5 * (rarity / ln_n).min(1.0))
                * (1.0 + if cross { 0.15 } else { 0.0 })
                * scoped_penalty;
            out.push(Neighbour {
                name,
                module,
                kind,
                retention: g.retention,
                common: g.common,
                vars: g.vars,
                scoped_vars: g.scoped_vars,
                rarity,
                sources,
                skeleton: self.arena.render(g.skeleton),
                transportable: g.scoped_vars == 0,
                score,
            });
        }
        // Ties are the normal case, not the exception — the score is a product of a few
        // coarse factors, so whole families land on the same value. Breaking straight to
        // the name meant ASCII decided the top of the list: `dvd_trans` sits in a
        // four-way tie for `le_trans` and lowercase sorts after every capitalised name,
        // so the flagship pair fell out of the top five and took a gate with it.
        //
        // So spend the content-bearing signals first. `common` prefers the candidate
        // sharing more actual structure; `vars` prefers the one that needed fewer
        // abstractions to get there. The name remains last, because a total order has to
        // end somewhere and a deterministic one is worth more than a prettier tie-break.
        out.sort_by(|a, b| {
            b.score
                .total_cmp(&a.score)
                .then(b.common.cmp(&a.common))
                .then(a.vars.cmp(&b.vars))
                .then(a.name.cmp(&b.name))
        });
        out.truncate(top);
        Ok(out)
    }

    /// Diagnostic for the normalization-symmetry question: how many of a declaration's
    /// subterms actually hit a posting, computed both the way `candidates` asks today
    /// (subterms of the raw root) and the way the postings were built (subterms of the
    /// presentation erasure). Returns `((keys, hits), (keys, hits))`.
    ///
    /// Exists because "the query and the index disagree about normalization" is a claim
    /// that should be measured before it is repaired.
    pub fn subterm_key_hits(&mut self, i: usize) -> ((usize, usize), (usize, usize)) {
        let root = self.roots[i];
        let pres = erase(
            &mut self.arena,
            &self.sigs,
            &mut self.cache,
            root,
            Level::Presentation,
        );
        let count = |term: TermId| {
            let mut subs = BTreeSet::new();
            self.arena.subterms(term, &mut subs);
            let (mut keys, mut hits) = (0, 0);
            for s in subs {
                let floor = if self.arena.is_closed(s) {
                    self.build_cfg.min_concrete_closed
                } else {
                    self.build_cfg.min_concrete_open
                };
                if self.arena.size(s) < floor {
                    continue;
                }
                keys += 1;
                if self.concrete.get(s).is_some() {
                    hits += 1;
                }
            }
            (keys, hits)
        };
        (count(root), count(pres))
    }

    fn level_term(&mut self, d: DeclId, level: Level) -> TermId {
        let t = self.roots[d.0 as usize];
        erase(&mut self.arena, &self.sigs, &mut self.cache, t, level)
    }

    /// The rendered erasure of one declaration.
    pub fn skeleton_of(&mut self, name: &str, level: Level) -> Option<String> {
        let d = self.id_of(name)?;
        let t = self.level_term(d, level);
        Some(self.arena.render(t))
    }

    /// The skeleton of two named declarations — `atlas similar`'s row, on demand.
    pub fn generalize_named(
        &mut self,
        a: &str,
        b: &str,
        level: Level,
    ) -> Result<(Generalization, String), String> {
        let (x, y) = (
            self.id_of(a)
                .ok_or_else(|| format!("`{a}` is not in this slice"))?,
            self.id_of(b)
                .ok_or_else(|| format!("`{b}` is not in this slice"))?,
        );
        let (tx, ty) = (self.level_term(x, level), self.level_term(y, level));
        let g = generalize(&mut self.arena, tx, ty);
        let rendered = self.arena.render(g.skeleton);
        Ok((g, rendered))
    }

    /// Brute force, for the differential gate. Every declaration, no prefilter.
    pub fn similar_brute(
        &mut self,
        name: &str,
        top: usize,
        cfg: &IndexConfig,
    ) -> Result<Vec<(String, f32)>, String> {
        let q = self
            .id_of(name)
            .ok_or_else(|| format!("`{name}` is not in this slice"))?;
        let qt = self.level_term(q, cfg.lgg_level);
        let mut out = Vec::new();
        for i in 0..self.len() {
            let d = DeclId(i as u32);
            if d == q {
                continue;
            }
            let ct = self.level_term(d, cfg.lgg_level);
            let g = generalize(&mut self.arena, qt, ct);
            if g.common >= cfg.min_common && g.retention >= cfg.min_retention {
                out.push((self.names[i].clone(), g.retention));
            }
        }
        out.sort_by(|a, b| b.1.total_cmp(&a.1).then(a.0.cmp(&b.0)));
        out.truncate(top);
        Ok(out)
    }
}

/// The first component of a module path — `Mathlib` vs `Init` vs `Std` — and the second
/// within Mathlib, so `Mathlib.Algebra` and `Mathlib.Analysis` count as different theories.
fn module_root(m: &str) -> &str {
    let mut it = m.match_indices('.');
    let first = it.next();
    match (m.starts_with("Mathlib."), first, it.next()) {
        (true, _, Some((i, _))) => &m[..i],
        (_, Some((i, _)), _) => &m[..i],
        _ => m,
    }
}
