//! The equivalence graph (B5, atlas.md §1d) — when do two declarations say the same thing?
//!
//! # §1d as written describes the validation corpus, not Mathlib
//!
//! atlas.md says "nodes: propositions; edges: proven `Iff`s". Measured over a
//! 131,062-declaration Mathlib slice: 4,459 theorems conclude in an `Iff`, and **four** of
//! them have both sides closed. `And.comm : a ∧ b ↔ b ∧ a` is not an edge between two
//! propositions; it is a rewrite rule over patterns.
//!
//! So equivalence here is **equality of a canonical form**, with the ground `Iff` case
//! degenerate rather than central. That choice is also what makes reflexivity, symmetry
//! and transitivity hold *by construction* rather than by a closure that has to be checked.
//!
//! # E0 must be Prop-restricted or it is a type index
//!
//! Statement identity over all kinds gives 4,482 classes covering 16,840 declarations —
//! and its largest class has **1,166 members**, every declaration whose type is literally
//! `Type`. That is not an equivalence class of propositions; it is the set of things that
//! happen to be types. Restricted to Prop-valued declarations the same relation gives a
//! useful index, and the restriction is decidable from the row alone.
//!
//! # What deliberately stays out
//!
//! **`Eq` at data.** Those are the rewrite *system* a normalizer would use, not statements
//! being equivalent. Admitting them makes "equivalent" mean "rewritable".
//!
//! **`Equiv` (`α ≃ β`).** A type equivalence with different transport semantics —
//! `Equiv.cast`, not `Iff.mp`. It belongs in its own edge kind, never merged into the
//! proposition graph.

use std::collections::{BTreeMap, BTreeSet, HashMap};

use crate::graph::GraphError;
use crate::skel::erase::{EraseCache, Level, Signatures, erase};
use crate::skel::term::{Arena, LevelNode, Node, TermId};

pub use crate::skel::erase::Level as NormLevel;

/// Why a question could not be answered. Distinguished from "no", because an agent does
/// very different things with the two.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Unknown {
    NotInSlice(String),
    /// The declaration's statement is not a proposition, so asking whether it is
    /// *equivalent* to something is a category error. Without this guard the query
    /// returns every declaration whose type is `Type`.
    NotProp(String),
}

impl std::fmt::Display for Unknown {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Unknown::NotInSlice(n) => write!(f, "`{n}` is not in this slice"),
            Unknown::NotProp(n) => write!(
                f,
                "`{n}` is not a proposition — equivalence is a relation between claims, \
                 and asking it of a definition would return every declaration of the same kind"
            ),
        }
    }
}

pub struct EquivIndex {
    arena: Arena,
    sigs: Signatures,
    cache: EraseCache,
    names: Vec<String>,
    modules: Vec<String>,
    kinds: Vec<String>,
    stmts: Vec<TermId>,
    is_prop: Vec<bool>,
    by_name: HashMap<String, usize>,
    /// Theorems concluding in an `Iff`, split by whether both sides are ground. The split
    /// is the measurement that decided this design and is worth keeping visible.
    pub iff_total: usize,
    pub iff_ground: usize,
}

impl EquivIndex {
    pub fn build(jsonl: &str) -> Result<EquivIndex, GraphError> {
        let mut arena = Arena::new();
        let (mut names, mut modules, mut kinds, mut stmts) =
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
            stmts.push(t);
        }

        let sigs = Signatures::from_rows(&arena, sig_rows.into_iter());
        let is_prop: Vec<bool> = stmts
            .iter()
            .zip(&kinds)
            .map(|(&t, k)| k == "theorem" || concludes_in_prop(&arena, t))
            .collect();

        let (mut iff_total, mut iff_ground) = (0, 0);
        for &t in &stmts {
            if let Some((l, r)) = iff_sides(&arena, t) {
                iff_total += 1;
                if arena.is_closed(l) && arena.is_closed(r) {
                    iff_ground += 1;
                }
            }
        }

        let by_name = names
            .iter()
            .enumerate()
            .map(|(i, n)| (n.clone(), i))
            .collect();
        Ok(EquivIndex {
            arena,
            sigs,
            cache: EraseCache::new(),
            names,
            modules,
            kinds,
            stmts,
            is_prop,
            by_name,
            iff_total,
            iff_ground,
        })
    }

    pub fn len(&self) -> usize {
        self.stmts.len()
    }
    pub fn is_empty(&self) -> bool {
        self.stmts.is_empty()
    }
    pub fn prop_count(&self) -> usize {
        self.is_prop.iter().filter(|&&p| p).count()
    }

    fn id_of(&self, name: &str) -> Result<usize, Unknown> {
        self.by_name
            .get(name)
            .copied()
            .ok_or_else(|| Unknown::NotInSlice(name.to_string()))
    }

    fn check_prop(&self, i: usize, name: &str) -> Result<(), Unknown> {
        if self.is_prop[i] {
            Ok(())
        } else {
            Err(Unknown::NotProp(name.to_string()))
        }
    }

    /// The class of declarations equivalent to this one at a normalization level.
    ///
    /// Reflexive, symmetric and transitive by construction: the relation *is* equality of
    /// `erase(stmt, level)`, so there is no closure to compute and none to get wrong.
    pub fn equivalent(&mut self, name: &str, level: NormLevel) -> Result<Vec<String>, Unknown> {
        let i = self.id_of(name)?;
        self.check_prop(i, name)?;
        let key = self.normal(i, level);
        let mut out = Vec::new();
        for j in 0..self.len() {
            if j != i && self.is_prop[j] && self.normal(j, level) == key {
                out.push(self.names[j].clone());
            }
        }
        out.sort();
        Ok(out)
    }

    fn normal(&mut self, i: usize, level: NormLevel) -> TermId {
        let t = self.stmts[i];
        erase(&mut self.arena, &self.sigs, &mut self.cache, t, level)
    }

    /// Every class of size > 1 at a level, largest first.
    ///
    /// `theorems_only` is the useful default. A *class definition* like `AddLeftMono` is a
    /// proposition by the conclusion test — it is `∀ α [inst], Prop` — and the corpus has
    /// dozens with literally identical statements. They are structurally identical and
    /// that is all: a reformulation family is a family of **claims**, and mixing the two
    /// buries the claims under an alphabetised list of typeclass names.
    pub fn classes(
        &mut self,
        level: NormLevel,
        prop_only: bool,
        theorems_only: bool,
    ) -> Vec<(usize, Vec<String>)> {
        let mut buckets: BTreeMap<TermId, Vec<usize>> = BTreeMap::new();
        for i in 0..self.len() {
            if prop_only && !self.is_prop[i] {
                continue;
            }
            if theorems_only && self.kinds[i] != "theorem" {
                continue;
            }
            let k = self.normal(i, level);
            buckets.entry(k).or_default().push(i);
        }
        let mut out: Vec<(usize, Vec<String>)> = buckets
            .into_values()
            .filter(|v| v.len() > 1)
            .map(|v| (v.len(), v.iter().map(|&i| self.names[i].clone()).collect()))
            .collect();
        out.sort_by(|a, b| b.0.cmp(&a.0).then(a.1[0].cmp(&b.1[0])));
        out
    }

    /// A declaration's module, for reporting a cluster's spread.
    pub fn module_of(&self, name: &str) -> Option<&str> {
        self.by_name.get(name).map(|&i| self.modules[i].as_str())
    }

    pub fn kind_of(&self, name: &str) -> Option<&str> {
        self.by_name.get(name).map(|&i| self.kinds[i].as_str())
    }
}

/// Does this statement's conclusion, after stripping the Π-telescope, land in `Prop`?
///
/// A theorem's type always does, which is why `kind == "theorem"` short-circuits it. This
/// catches the Prop-valued `def`s that a kind check alone would miss.
fn concludes_in_prop(a: &Arena, t: TermId) -> bool {
    let mut cur = t;
    while let Node::Pi(_, _, body) = a.node(cur) {
        cur = body;
    }
    matches!(a.node(cur), Node::Sort(l) if matches!(a.level(l), LevelNode::Zero))
}

/// The two sides of an `Iff`-concluding statement, if it is one.
fn iff_sides(a: &Arena, t: TermId) -> Option<(TermId, TermId)> {
    let mut cur = t;
    while let Node::Pi(_, _, body) = a.node(cur) {
        cur = body;
    }
    let (head, args) = a.spine(cur);
    if let (Node::Const(s, _), 2) = (a.node(head), args.len())
        && a.sym(s) == "Iff"
    {
        return Some((args[0], args[1]));
    }
    None
}

/// The rule-index key for a rewrite side: head symbol, arity, and the heads of its
/// immediate arguments.
///
/// Depth-2 discrimination is not an optimisation. Keying on head and arity alone gives 86
/// distinct keys with a largest bucket of 3,137; adding the argument heads gives 3,138
/// keys with a largest bucket of 206. The difference is between a usable index and a
/// linear scan wearing a hat.
pub fn rule_key(a: &Arena, t: TermId) -> Option<(String, usize, Vec<String>)> {
    let (head, args) = a.spine(t);
    let Node::Const(s, _) = a.node(head) else {
        // A bound variable at the head needs higher-order matching. Reported by the
        // caller as a recall loss rather than silently dropped.
        return None;
    };
    let arg_heads = args
        .iter()
        .map(|&x| match a.node(a.spine(x).0) {
            Node::Const(hs, _) => a.sym(hs).to_string(),
            Node::BVar(k) => format!("#{k}"),
            _ => "_".to_string(),
        })
        .collect();
    Some((a.sym(s).to_string(), args.len(), arg_heads))
}

/// How many `Iff` sides have a bound variable at the head — the flex-head rules a
/// first-order rule index cannot key, reported rather than hidden.
pub fn flex_head_count(idx: &EquivIndex) -> (usize, usize) {
    let (mut flex, mut total) = (0, 0);
    for &t in &idx.stmts {
        if let Some((l, r)) = iff_sides(&idx.arena, t) {
            for side in [l, r] {
                total += 1;
                if rule_key(&idx.arena, side).is_none() {
                    flex += 1;
                }
            }
        }
    }
    (flex, total)
}

/// Distinct rule keys and the largest bucket, at head-only and depth-2 discrimination.
pub fn rule_index_stats(idx: &EquivIndex) -> ((usize, usize), (usize, usize)) {
    let mut shallow: HashMap<(String, usize), usize> = HashMap::new();
    let mut deep: HashMap<(String, usize, Vec<String>), usize> = HashMap::new();
    for &t in &idx.stmts {
        if let Some((l, r)) = iff_sides(&idx.arena, t) {
            for side in [l, r] {
                if let Some((h, n, heads)) = rule_key(&idx.arena, side) {
                    *shallow.entry((h.clone(), n)).or_insert(0) += 1;
                    *deep.entry((h, n, heads)).or_insert(0) += 1;
                }
            }
        }
    }
    let s = (shallow.len(), shallow.values().copied().max().unwrap_or(0));
    let d = (deep.len(), deep.values().copied().max().unwrap_or(0));
    (s, d)
}

/// The declarations reachable from `name` through classes at successively coarser levels
/// — a reformulation *neighbourhood*, reported per level so a reader can see how much
/// squinting each member cost.
pub fn ladder(idx: &mut EquivIndex, name: &str) -> Result<Vec<(NormLevel, Vec<String>)>, Unknown> {
    let mut seen: BTreeSet<String> = BTreeSet::new();
    let mut out = Vec::new();
    for &level in &[
        Level::Exact,
        Level::Presentation,
        Level::Instances,
        Level::Carriers,
    ] {
        let members = idx.equivalent(name, level)?;
        let fresh: Vec<String> = members
            .into_iter()
            .filter(|m| seen.insert(m.clone()))
            .collect();
        if !fresh.is_empty() {
            out.push((level, fresh));
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Two theorems with the same statement, one class definition, one plain definition.
    const SLICE: &str = concat!(
        r#"{"name":"a_thm","kind":"theorem","module":"M","stmt":"fh-stmt-v1;pd(s(0),b0)","uses_statement":[],"uses_proof":[]}"#,
        "\n",
        r#"{"name":"b_thm","kind":"theorem","module":"N","stmt":"fh-stmt-v1;pd(s(0),b0)","uses_statement":[],"uses_proof":[]}"#,
        "\n",
        r#"{"name":"a_class","kind":"def","module":"M","stmt":"fh-stmt-v1;pd(s(0),s(0))","uses_statement":[],"uses_proof":[]}"#,
        "\n",
        r#"{"name":"a_def","kind":"def","module":"M","stmt":"fh-stmt-v1;c(3:Nat,0)","uses_statement":[],"uses_proof":[]}"#,
        "\n",
    );

    fn idx() -> EquivIndex {
        EquivIndex::build(SLICE).expect("build")
    }

    #[test]
    fn theorems_with_the_same_statement_are_equivalent() {
        let mut i = idx();
        assert_eq!(
            i.equivalent("a_thm", NormLevel::Exact).unwrap(),
            vec!["b_thm".to_string()]
        );
    }

    #[test]
    fn equivalence_is_symmetric_and_reflexive_by_construction() {
        // The relation *is* equality of a canonical form, so there is no closure to
        // compute and none to get wrong. Asserted anyway, because "by construction" is a
        // claim about the code that the code should be made to demonstrate.
        let mut i = idx();
        let a = i.equivalent("a_thm", NormLevel::Exact).unwrap();
        let b = i.equivalent("b_thm", NormLevel::Exact).unwrap();
        assert!(a.contains(&"b_thm".to_string()) && b.contains(&"a_thm".to_string()));
        assert!(
            !a.contains(&"a_thm".to_string()),
            "a class excludes its own member"
        );
    }

    #[test]
    fn a_non_proposition_is_refused_rather_than_answered() {
        // Without this guard the query returns every declaration whose type is `Type` —
        // 1,859 of them in a real Mathlib slice.
        let mut i = idx();
        assert_eq!(
            i.equivalent("a_def", NormLevel::Exact),
            Err(Unknown::NotProp("a_def".into()))
        );
    }

    #[test]
    fn a_missing_declaration_is_distinguished_from_a_non_proposition() {
        // An agent does very different things with "not here" and "wrong kind".
        let mut i = idx();
        assert_eq!(
            i.equivalent("nope", NormLevel::Exact),
            Err(Unknown::NotInSlice("nope".into()))
        );
    }

    #[test]
    fn a_prop_valued_definition_counts_as_a_proposition() {
        // `a_class : Prop → Prop` concludes in `Sort 0`, so it is a proposition even
        // though its kind is `def`. A kind check alone would miss it.
        let i = idx();
        assert_eq!(i.prop_count(), 3);
    }

    #[test]
    fn classes_can_exclude_definitions() {
        let mut i = idx();
        let with_defs = i.classes(NormLevel::Exact, true, false);
        let theorems = i.classes(NormLevel::Exact, true, true);
        assert_eq!(theorems.len(), 1, "one class: the two theorems");
        assert!(with_defs.len() >= theorems.len());
    }

    #[test]
    fn the_rule_key_discriminates_on_argument_heads() {
        // Head-and-arity alone puts every binary `Iff` in one bucket. Depth-2 is what
        // makes a rule index an index.
        let mut a = Arena::new();
        let f = a
            .parse("fh-stmt-v1;a(a(c(1:F,0),c(1:X,0)),c(1:Y,0))")
            .unwrap();
        let g = a
            .parse("fh-stmt-v1;a(a(c(1:F,0),c(1:Z,0)),c(1:Y,0))")
            .unwrap();
        let (kf, kg) = (rule_key(&a, f).unwrap(), rule_key(&a, g).unwrap());
        assert_eq!((&kf.0, kf.1), (&kg.0, kg.1), "same head and arity");
        assert_ne!(kf.2, kg.2, "different argument heads");
    }

    #[test]
    fn a_flex_head_has_no_rule_key() {
        // A bound variable at the head needs higher-order matching. Returning `None` is
        // what lets the caller count the recall loss instead of hiding it.
        let mut a = Arena::new();
        let t = a.parse("fh-stmt-v1;a(b0,c(1:X,0))").unwrap();
        assert!(rule_key(&a, t).is_none());
    }
}
