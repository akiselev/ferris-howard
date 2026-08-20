# Which of physlib's unproved assertions are provable from what is already formalized?

**Corpus:** `/tmp/pc-physclosed.jsonl` — 95,268 declarations, **closure 0.9946** over
51,394,099 application heads. Mathlib 80,146 · Physlib 12,027 · QuantumInfo 2,527 ·
Init 535 · Lean 19 · Batteries 13 · Aesop 1. This is the first physics corpus in this
project to clear the 95% floor, and therefore the first on which an erasure-dependent or
citation-following query is admissible at all (CLAUDE.md §7, findings §31).

**Script:** `scripts/phys-provable.py`. Every number here is printed by it. Where a run did
not happen, this file says so rather than guessing. "findings §N" means
`research/corpus-atlas-findings.md`.

```sh
uv run --no-sync python scripts/phys-provable.py --slice /tmp/pc-physclosed.jsonl \
    --json research/data/phys-provable-closed.json          # ~45 min
uv run --no-sync python scripts/phys-provable.py --slice /tmp/fh-physlib.jsonl \
    --min-closure 0.0 --no-deep --json research/data/phys-provable-unclosed.json
```

Both outputs are checked in under `research/data/`, because each run is a 40-minute pass
over 2.4 GB and every table below is a projection of them.

**Paired control corpus:** `/tmp/fh-physlib.jsonl` — the same two physics libraries,
14,563 declarations, **closure 0.1239**. Every arm below is run on both, because the
difference between them *is* the measurement in §6 and the agreement between them is what
makes §5 trustworthy.

**Instrument corpus:** `/tmp/mathlib-algebra.jsonl` — 131,062 declarations, closure 0.9925.
Used for the pipeline smoke and for the engine defect in §2; never for physics.

---

## The short version

1. **physlib declares no axioms.** One axiom row in 95,268 and it is `propext`. The premise
   this study was handed is false, reproduced here on a closed corpus six times the size of
   the one that first refuted it (§0).
2. **Eighteen declarations rest on `sorry` and no exact-structure route reaches any of
   them.** 0 of 18 at identity, conclusion identity, witnessed rewrite, erasure equivalence
   at four levels, `variants`, `adjacent` and subsumption (§4, §4b).
3. **The *ranked* surface does produce candidate routes, for eight of them.** Conclusion-
   anchored `similar` and `vocabulary_adjacent` return proved neighbours with real
   structural evidence — `MState.fidelity_channel_nondecreasing` against
   `sandwichedRenyiEntropy_DPI_eq_one` at retention 0.752 over 112 shared nodes,
   `CPTPMap.zero_le_quantumCapacity` against the proved `CPTPMap.achievesRate_0` at 0.676,
   `quantumCapacity_ge_log_dim_in` against the proved `id_achievesRate_log_dim` at 0.622.
   Candidates, not results: the warrant is a float and none has seen a kernel (§4b).
4. **The negative is a measurement, not a silence.** A planted provable target is routed
   **60/60 with its substitution named**; a decoy holding the same vocabulary in a different
   tree is routed **0/60**; a frequency-matched null lands **0 of 699** rewrites; and only
   2.5-5% of *proved* theorems have a route either, so "no route" is the ordinary condition
   of a declaration here (§5).
5. **The unproved sit measurably outside the proved frontier.** 0 of 18 have a proved
   declaration sharing their rigid skeleton, against 94 of 349 size-matched proved controls
   — one-sided binomial **p = 0.0035**. They are not overlooked corollaries; they are where
   the library ran out of neighbours (§7).
6. **Every one is about vocabulary the corpus barely mentions, and that is testable.** The
   rarest constant in each target's statement occurs 1 to 9 times in 95,268 declarations —
   `coherentInfo` twice, `RigidBody.solidSphere` three times, `Real.logb` four. Against the
   distribution over 70,113 proved claims, **all 14 measurable targets fall below the median**
   (sign test **p = 6.1e-5**). An unproved statement is the first thing said about its own
   vocabulary, and that is a one-pass screen (§7).
7. **Closure is worth exactly one measured thing here, and it is total.** Physics claims
   sharing a rigid skeleton with a mathematics claim: **190 (2.00%)** on the 99.46%-closed
   corpus, **0 (0.00%)** on the 12.39% one. Same query, same code (§6).
8. **`Corpus.equivalent` refuses every `axiom` and omits every `axiom` from every class** —
   so the shipped engine cannot answer "is this assertion already proved" even when the two
   statements are byte-identical. Demonstrated on `Lean.trustCompiler` and `trivial` (§2).
9. **The largest genre of unproved physics — 76 claims written in prose — is unreachable,
   and by one extractor field.** Their dependency lists are string literals in a value, and
   the extractor records constants (§3).

---

## 0. The premise was wrong, and the corrected question is smaller

The question handed to this session was "physlib is full of `axiom` declarations — for each,
can the Atlas find a proof route?" **It is not.** `research/physlib-frontier.md` §1 found 0
axioms in the 14,563-declaration unclosed extraction; this reproduces it on a different,
closed, six-times-larger corpus, read off the extractor's `kind` field and never off source
text:

| kind | rows |
|---|---|
| theorem | 70,254 |
| def | 21,329 |
| inductive | 2,596 |
| constructor | 889 |
| recursor | 180 |
| opaque | 16 |
| quot | 3 |
| **axiom** | **1** — `propext`, in `Init.Core` |

**One axiom row, and it is Lean's.** Zero non-kernel axioms; zero physics axioms. The
control that makes this a fact about the corpus rather than about the extractor is the same
one §1 used: the identical field on `/tmp/mathlib-algebra.jsonl` returns **15** axiom rows,
so the extractor emits the kind when the kind is there.

So the question has to be asked of the genres physlib *does* use to assert without proving:

| genre | count here | how it is found | can a proof route even be expressed? |
|---|---|---|---|
| `axiom` | 0 physics | `kind` | yes — but there are none |
| `sorry` | **18** | `honesty()`, transitively | **yes**: the claim is a formal proposition |
| prose | **76** | the statement is a single constant whose row is an `inductive` in the library's own `*.Meta.*` subtree | **no** — §3 |
| orphan def | 444 (§4 of the frontier study, not re-run) | reachability | not applicable: a definition asserts nothing |

Sixteen theorems and two definitions is the whole set on which "is this a corollary of
something already proved" is a well-formed question. That is the sample size and every
number below is read against it.

### A side result: the honesty negative control comes back to life on a closed slice

`physlib-frontier.md` §3 measured `honesty([])` — the whitelist that allows nothing, and
must therefore be strictly louder — returning the *identical* 18 findings as the default
whitelist on the 12.39%-closed slice, and diagnosed the cause as the absence of axiom rows
for the whitelist to act on. On this corpus:

| corpus | closure | `honesty(default)` | `honesty([])` | control |
|---|---|---|---|---|
| `/tmp/fh-physlib.jsonl` (frontier study) | 0.1239 | 18 | **18** | dead |
| `/tmp/pc-physclosed.jsonl` (here) | **0.9946** | 18 | **21,265** | **fires** |

21,265 is 22.3% of the corpus, against the 22.67% the frontier study reached by summing
`impact` over out-of-slice axiom names. `physlib-frontier.md` §8.1's diagnosis is confirmed: the scan was blind
because the slice was, not because the code was wrong about physlib. The engine change it
specifies is still worth making — a corpus should not have to be closed for a negative
control to work — but it is now a robustness fix rather than a correction.

---

## 1. What a proof route is, and how one is looked for

A **route** is a named, checkable claim of the form "this unproved statement follows from
these proved declarations". Five kinds, strongest first. All five are exact structure: none
computes a similarity score and none matches on a name.

| | route | what it means | strength |
|---|---|---|---|
| **R1** | identity | the target's statement encoding **equals** a proved declaration's | a *result*: `theorem T := D`, decided by the corpus alone |
| **R5** | conclusion | a proved theorem's **conclusion** equals the target's, hypotheses discarded | one thing left to check — are its hypotheses available |
| **R3** | rewrite | applying a substitution the corpus **witnesses elsewhere** turns the target into a proved declaration's statement | port `D`'s proof along σ |
| **R2** | equivalence | the target and a proved declaration erase to the same thing at `exact`/`presentation`/`instances`/`carriers` | candidate: erasure equality is not provable equality |
| **R4** | adjacency | same rigid skeleton, k constants apart (`variants`, `adjacent`), or the class's distinguished vocabulary shared (`vocabulary_adjacent`) | a place to look |

plus **subsumption**, which is the relation the question actually wants and which
`physlib-newqueries.md` §8 records as *not attempted*: `D` subsumes `T` when
`skeleton(D, level)` one-way matches `skeleton(T, "presentation")`, i.e. `T` is an instance
of `D`. Attempted here in the only affordable direction — eighteen subjects rather than
§8's 4.4 billion pairs — behind a prefilter that can only produce false positives:
`sig(D) & ~sig(T) == 0` over a 64-bit signature of each declaration's constant set is
implied by "every constant of D occurs in T", so dropping the rest of the corpus cannot
lose a subsumer. CLAUDE.md's rule is that false negatives are the expensive kind, and a
one-sided prefilter is the only kind admissible.

The rigid-skeleton primitive, the one-way matcher and the plumbing exclusion are
`scripts/phys-newqueries.py`'s and are **imported**, not rewritten. Two implementations of
`split_constants` would be two places for the blank-then-refill identity to break, and that
identity is what every route rests on.

### R5 needed a new primitive, and why

Anti-unification and every exact key here align two terms **from the root**, so a claim
carrying a hypothesis prefix cannot match one without. `fh_atlas.pyi`'s `Anchor` records
the measured cost on B7: two statements that are literally `S ⊆ {x | P x}` anti-unify to
`common 0, retention 0.0`. The rigid skeleton inherits the problem exactly.

So the script extracts the **conclusion** as a standalone term — walk off the `Pi` prefix,
then find the body's end with `skip_expr`, because `enc[i:]` after k binders carries k
trailing `)` and is not a term — and keys on it separately. Gated: a statement with no
binder must be its own conclusion, and a conclusion is never longer than its statement.

### Stated before running

*Pass.* (a) A planted provable target — a proved theorem rewritten by a witnessed
substitution whose image is a real declaration — gets an R3 route **with the substitution
named**, at ≥ 90%. (b) A planted decoy — the same vocabulary poured into a different tree —
gets a route in **0** cases. (c) The frequency-matched substitution null lands far below
the witnessed inventory. (d) The calibration arm — proved theorems run unmodified as
pseudo-targets — gives a base rate, so a route found on a real target can be read against
something.

*Fail.* Decoys route at the genuine rate; or the null matches the inventory; or calibration
routes ~100% of proved theorems, in which case a route means "the corpus is redundant" and
says nothing about the target.

*Refuse.* Below 95% closure the script stops rather than reporting a number.

### One precondition, checked rather than assumed

R1 and R5 compare statement encodings for **equality**, and CLAUDE.md §7 records that a
corpus merged across workspaces is sound for analogy and not for identity: two Mathlib
patch versions can encode the same lemma differently. So the corpus was checked:
**95,268 rows, 95,268 distinct names, 0 duplicates.** One encoding per constant.

That does not prove a single extraction, and the residual risk is worth stating in the
right direction: if two halves were encoded against different Mathlib patch versions, a
statement embedding a definition that changed between them would fail to compare equal with
its counterpart. That is a **false negative** — it can lose a route, never invent one. Every
route reported below is therefore sound with respect to this; the count of routes *not*
found is a lower bound.

---

## 2. The shipped Atlas cannot ask this question of an assertion, and here is the proof

Before any physics: `Corpus.equivalent` — the query "does the corpus already state this?" —
**refuses every `axiom`, whatever it states, and omits every `axiom` from every class.**

On `/tmp/mathlib-algebra.jsonl`:

```
axiom   Lean.trustCompiler  axiom    'fh-stmt-v1;c(4:True,0)'
theorem trivial             theorem  'fh-stmt-v1;c(4:True,0)'
statements byte-equal: True

equivalent(Lean.trustCompiler, 'exact')  RAISED NotAProposition
equivalent(trivial,            'exact')  -> []
equivalent(Lean.ofReduceBool)            RAISED NotAProposition
equivalent(propext)                      RAISED NotAProposition
equivalent(Classical.choice)             RAISED NotAProposition

axiom rows: 15 | axioms appearing in any exact-level class: 0
```

Two declarations with **byte-identical statements**, and the query says nothing in both
directions: asked of the axiom it raises, asked of the theorem it returns the empty class.
`Lean.trustCompiler : True` is provable — `trivial` proves it — and the engine built to
find exactly that relation is structurally unable to report it.

### The cause, read off the source

`crates/fh-atlas/src/equiv.rs:124`

```rust
let is_prop: Vec<bool> = stmts.iter().zip(&kinds)
    .map(|(&t, k)| k == "theorem" || concludes_in_prop(&arena, t))
    .collect();
```

and `concludes_in_prop` (`equiv.rs:274`) walks off the `Pi` prefix and returns true only
when what remains is `Sort 0`. That is true of a *definition of* a proposition
(`def Foo : Prop`) and **false of a claim**, whose statement *is* the proposition and whose
conclusion is an application, not a sort. So for anything whose kind is not `theorem` the
disjunct does no work and the flag reduces to `kind == "theorem"`. `check_prop`
(`equiv.rs:196`) then rejects the query, and the class-member filter at `equiv.rs:214`
(`j != i && self.is_prop[j] && …`) drops axioms out of everyone else's class as well —
which is why `trivial`'s class is empty rather than `["Lean.trustCompiler"]`.

### And downstream it degrades toward output rather than erroring

`crates/fh-atlas-py/src/lib.rs`'s `adjacent` and `vocabulary_adjacent` fetch the class with
`idx.equivalent(name, lvl).unwrap_or_default()`. For an axiom that swallows `NotProp` into an
**empty class**, so the query then computes the neighbourhood of a singleton and reports
genuine class members as non-members. Measured:

```
vocabulary_adjacent('Lean.trustCompiler') -> 330 rows, and 'trivial' is one of them
```

`trivial` has a byte-identical statement, so it is in the class by definition, and the query
whose contract is "shares the vocabulary **without being in the class**" returns it. That is
the silent-degradation shape CLAUDE.md §7 names: no error, no empty result, an answer that
is weaker than the name promises and still produces output.

Not everything is affected, which is worth pinning so the fix is scoped: `variants`,
`requires` and `similar` read the skeleton index and handle axioms correctly —
`variants('Lean.ofReduceBool')` returns `Lean.ofReduceNat` with
`[(Bool, Nat), (Lean.reduceBool, Lean.reduceNat)]`, which is right. The defect is
`EquivIndex` and the two queries that consult it.

This is findings §23's defect surviving one query over. §23 fixed `logical.rs` skipping
anything whose kind was not `theorem`, which "made a statement-level corpus invisible:
B7's validation clusters produced zero edges". The same assumption is still in `equiv.rs`,
and it is fatal to precisely the question this study asks. Spec in §8.

**Scope of the damage here:** none, and that is worth saying plainly. This corpus has one
axiom row and it is `propext`, so no physics result below is affected. The defect matters
for B7's genre — a statement-level formalization is *all* axioms — and it is reported
because it was found, not because it changed a number.

---

## 3. The 76 prose claims are unreachable, and the reason is in the extractor

The largest genre of unproved physics assertion is the one `physlib-frontier.md` §5 found:
claims written in English and registered as data. Reproduced here structurally — a
declaration whose *type* is a marker `inductive` living in the library's own `*.Meta.*`
subtree, outside that marker's own module — at **76**, split 44 `InformalLemma` / 32
`InformalDefinition`, across Particles 29 · ClassicalMechanics 26 · QuantumMechanics 14 ·
Relativity 5 · StatisticalMechanics 1 · SpaceAndTime 1. The same criterion on
`/tmp/mathlib-algebra.jsonl` returns 3, all of them Lean's own elaborator config records
(`Lean.Meta.Config`, `Lean.Meta.Context`, `Lean.Meta.ConfigWithKey`) — so the criterion is
not physlib-specific and its false-positive genre is legible.

**Every one of the 76 carries the same statement**, and it is not a proposition:

```
"stmt": "fh-stmt-v1;c(13:InformalLemma,0)"
"uses_statement": ["InformalLemma"]
"uses_proof": ["InformalLemma.mk", "Lean.Name", "Lean.Name.mkStr2",
               "List.cons", "List.nil"]
```

Measured rather than asserted: the 76 carry **exactly two distinct statement encodings**
between them — 44 rows on one hash and 32 on the other, one per marker type. There is no
tree to rewrite, no conclusion to key on, and no vocabulary to substitute. Every route in §1
is undefined on them by construction, not by a failure of retrieval.

### And the dependency list that would make them reachable is dropped

An `InformalLemma` value carries `deps : List Name`, and physlib fills it — that is the
library's own record of which formal constants a prose claim is about. It does not survive
extraction. `atlas-extract/FhAtlas/Extract.lean`'s `rowOf` sets
`usesProof := sortedConstants(value)` and `sortedConstants` is `Expr.getUsedConstants`; the
dep names are built by `Lean.Name.mkStr2 "RigidBody" "euler_equations"` from **string
literals**, which are `Expr.lit` and not constants. So `uses_proof` names the *builder*
(`Lean.Name.mkStr2`, `List.cons`, `List.nil`) and never the physics. Measured: 76 prose
claims, **0 recoverable dependencies**, and the same five citations on all of them.

That is one field in the extractor away from being the most actionable list in the library,
and the spec is §8.4.

---

## 4. The answer: eighteen targets, zero routes, and the list anyway

**No unproved assertion in this corpus is a corollary of anything already in it, at any
route kind that was run.** 0 of 18 at R1 (identity), 0 at R5 (conclusion identity and
conclusion-tree adjacency), 0 at R3 (witnessed rewrite). The `R3_null` arm shows the rewrite
machinery ran on each of them — 7 to 14 substitutions attempted per target, not zero — so
this is a measured negative and not an arm that failed to start (findings §20's trap).

R2 (erasure equivalence), R4 (`variants`/`adjacent`/`vocabulary_adjacent`) and subsumption
go through Rust-side indexes built over the whole 2.4 GB corpus and are reported in §4b,
from a second pass. Wherever this document has not run something it says so.

That is the headline and it is a null result. What follows is the list anyway, because the
question "which of these is the best prospect" is still answerable from structure, and
because a negative with no list is not actionable.

| # | declaration | subfield | kind | bytes | slots | binders | conclusion head | rarest constant (df) | vocab in a proved thm |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `CPTPMap.coherentInfo_le_quantumCapacity` | QuantumInfo.Capacity | theorem | 509 | 13 | 8 | `LE.le` | `coherentInfo` (**2**) | 9/11 |
| 2 | `CPTPMap.quantumCapacity_eq_piProd_coherentInfo` | QuantumInfo.Capacity | theorem | 2,639 | 92 | 7 | `Eq` | `coherentInfo` (**2**) | 19/21 |
| 3 | `RigidBody.solidSphere_inertiaTensor` | Physlib.ClassicalMechanics | theorem | 4,394 | 196 | 3 | `Eq` | `RigidBody.solidSphere` (**3**) | 41/41 |
| 4 | `CPTPMap.zero_le_quantumCapacity` | QuantumInfo.Capacity | theorem | 537 | 17 | 8 | `LE.le` | `CPTPMap.quantumCapacity` (**4**) | 12/13 |
| 5 | `CPTPMap.quantumCapacity_ge_log_dim_in` | QuantumInfo.Capacity | theorem | 862 | 29 | 7 | `LE.le` | `Real.logb` (4) | 18/19 |
| 6 | `CPTPMap.not_achievesRate_gt_log_dim_in` | QuantumInfo.Capacity | theorem | 902 | 31 | 9 | `Not` | `Real.logb` (4) | 20/20 |
| 7 | `CPTPMap.not_achievesRate_gt_log_dim_out` | QuantumInfo.Capacity | theorem | 902 | 31 | 9 | `Not` | `Real.logb` (4) | 20/20 |
| 8 | `CPTPMap.bddAbove_achievesRate` | QuantumInfo.Capacity | theorem | 447 | 14 | 7 | `BddAbove` | `CPTPMap.AchievesRate` (**5**) | 10/10 |
| 9 | `WickContraction.Perm.isFull_of_isFull` | Physlib.QFT | theorem | 709 | 18 | 8 | `WickContraction.IsFull` | `WickContraction.Perm` (**5**) | 8/8 |
| 10 | `WickContraction.Perm.perm_uncontractedList` | Physlib.QFT | theorem | 674 | 16 | 7 | `List.Perm` | `WickContraction.Perm` (**5**) | 9/9 |
| 11 | `MState.fidelity_channel_nondecreasing` | QuantumInfo.States | theorem | 1,203 | 30 | 9 | `GE.ge` | `MState.fidelity` (**7**) | 12/12 |
| 12 | `QuantumMechanics.HydrogenAtom.angularMomentumSqr_commutation_lrlSqr` | Physlib.QuantumMechanics | theorem | 297,506 | 7,594 | 2 | `Eq` | `angularMomentumOperatorSqr` (**8**) | 60/60 |
| 13 | `QuantumMechanics.HydrogenAtom.angularMomentum_commutation_lrlSqr` | Physlib.QuantumMechanics | theorem | 297,783 | 7,600 | 4 | `Eq` | `HydrogenAtom.lrlOperator` (**9**) | 60/60 |
| 14 | `QuantumMechanics.HydrogenAtom.angularMomentum_commutation_lrl` | Physlib.QuantumMechanics | theorem | 625,030 | 15,959 | 5 | `Eq` | `HydrogenAtom.lrlOperator` (**9**) | 97/97 |
| 15 | `realLorentzTensor.leviCivita_contract_self` | Physlib.Relativity | theorem | **71,036,165** | **2,829,071** | 0 | `Eq` | `…_self._proof_1` (**1**) | 83/87 |
| 16 | `realLorentzTensor.leviCivita_contract_three` | Physlib.Relativity | theorem | 64,015,764 | 2,546,289 | 0 | `Eq` | `…_three._proof_1` (**1**) | 90/94 |
| 17 | `Cosmology.FLRW` | Physlib.Cosmology | **def** | 7 | 0 | 0 | — | — | — |
| 18 | `ClassicalMechanics.CoplanarDoublePendulum.ConfigurationSpace` | Physlib.ClassicalMechanics | **def** | 7 | 0 | 0 | — | — | — |

Sorted by the rarest constant the statement mentions, which is the ranking §7 justifies.

### Reading the list

* **Rows 17-18 are not missing proofs, they are missing objects.** Both are `def`s whose
  entire type is 7 bytes and holds **no constant at all** — `Cosmology.FLRW`, the standard
  cosmological spacetime, and the double pendulum's configuration space, are `sorry`-stubbed
  definitions of a `Type`. There is no proposition, so there is no route, and asking for one
  is a category error rather than a search failure. The Atlas is right to return nothing.
* **Rows 15-16 defeat the exact-structure approach by construction.** Their statements are
  **71 MB and 64 MB**, with 2.8 million and 2.5 million constant slots, and among the
  constants they mention are their *own* elaborator-generated proof obligations
  (`realLorentzTensor.leviCivita_contract_self._proof_1`, document frequency **1**). A
  statement that names a constant nothing else in the corpus names can have no structural
  neighbour — the rigid-skeleton bucket has one member by definition. This is not a defect
  of the method; it is a fact about the statement.
* **The quantum-capacity cluster is the strongest prospect, and it is seven of the
  eighteen.** Rows 1, 2, 4, 5, 6, 7 and 8 are all `QuantumInfo.Capacity`, the module
  `physlib-frontier.md` §2 measured at 39% unproved — the LSD theorem and its corollaries,
  stated in Lean and proved nowhere. Their vocabulary is nearly all in use elsewhere (9/11
  to 20/20), their statements are small (447-2,639 bytes) and shallow (7-9 binders), and
  they are the rows on this list an exact-structure route had the best chance of reaching.
  None was reached.
* **`Real.logb` at df 4 is the finding under rows 5-7.** Three of the unproved capacity
  bounds are statements about a base-2 logarithm, and `Real.logb` occurs in exactly **four**
  declarations across a 95,268-row corpus that contains all of Mathlib's closure for this
  library. The bound is not unprovable because quantum capacity is hard; it is unreachable
  because the corpus barely has `logb`.

### What the list is for

Every row names, structurally, the one thing that would have to be developed first: the
constant with the lowest document frequency. `coherentInfo` (2), `RigidBody.solidSphere`
(3), `CPTPMap.quantumCapacity` (4), `CPTPMap.AchievesRate` (5), `WickContraction.Perm` (5),
`MState.fidelity` (7), `HydrogenAtom.lrlOperator` (9). **A proof route to any of these
eighteen requires proving something about a concept the library has mentioned fewer than ten
times.** That is a to-do list, and it is the actionable output this study has.

---

## 4b. The index-backed half: exact structure still finds nothing, and the *ranked* surface finds something

The second pass built the Rust-side equivalence and skeleton indexes over the 2.4 GB corpus
— 244 s for the first query, ~2 s per target after — and ran the remaining route kinds.

| route kind | result over 18 targets |
|---|---|
| **R2** `equivalent` at `exact` / `presentation` / `instances` / `carriers` | **0 / 18** — every class empty at every level, for the 16 that are propositions |
| **R4** `variants(max_subs=3)` | **0 / 18** |
| **R4** `adjacent(level="instances", max_subs=3)` | **0 / 18** |
| **subsumption** | **0 / 18**, with three caveats reported by the run rather than hidden: the two 60-70 MB statements were skipped for size, and `angularMomentum_commutation_lrl` was capped at `<budget 2000 of 4037>` candidates |
| **R4** `vocabulary_adjacent` | **16 / 18 non-empty** — the only index query that returns anything |

So all five exact-structure route kinds are empty and the two erasure-dependent ones now
have their answer on a corpus that can support them. Note what R2's silence costs to
establish: this is the arm `physlib-frontier.md` §7 could run only at `exact` and
`presentation`, on an unclosed slice, and had to report `instances` and `carriers` as unrun.
They are run now, and they are empty.

### But `similar` and `vocabulary_adjacent` do produce candidate routes

Both were included as a reference point — "does the shipped ranked surface reach these at
all" — and the answer is that it does. These are **candidates from a ranking, not routes**:
the warrant is a retention float and a shared-vocabulary list, both weaker than an exact
rewrite, and none has been near a kernel. Ranked by the structural evidence, best first.

| # | unproved target | proved neighbour the engine returns | evidence | the route it suggests |
|---|---|---|---|---|
| 1 | `MState.fidelity_channel_nondecreasing` | `sandwichedRenyiEntropy_DPI_eq_one` | conclusion-anchored retention **0.752**, `common` **112** — the highest of any target; and `vocabulary_adjacent` returns `sandwichedRenyiEntropy_DPI` and `OptimalHypothesisRate.optimalHypothesisRate_antitone`, each sharing **8** distinguished constants (rarest df 40) | the corpus already proves data-processing monotonicity under a `CPTPMap` for two other quantities. Fidelity's is the third instance of a theorem it has twice |
| 2 | `CPTPMap.zero_le_quantumCapacity` | `CPTPMap.achievesRate_0` | root-anchored retention **0.676**, `common` 23 — the **top** neighbour at either anchor; shares 7 distinguished constants | capacity is a supremum over achievable rates and rate 0 is proved achievable |
| 3 | `CPTPMap.quantumCapacity_ge_log_dim_in` | `CPTPMap.id_achievesRate_log_dim` | conclusion-anchored retention **0.622**, `common` 23 — the **top** conclusion neighbour; third in `vocabulary_adjacent` at 9 shared constants including `Real.logb` (df 4) and `CPTPMap.quantumCapacity` (df 4) | same shape: the identity channel's achievable rate is proved, and the bound is that supremum |
| 4-6 | the three `HydrogenAtom` LRL commutators | `QuantumMechanics.angularMomentum_commutation_momentumSqr`, `angularMomentumSqr_commutation_momentumSqr`, `angularMomentum_commutation_momentum`, `angularMomentum_commutation_position`, `position_commutation_momentumSqr` | conclusion-anchored retention **0.688-0.695** with `common` **9,941-25,266** shared nodes; `vocabulary_adjacent` adds `lrlOperatorSqr_eq`, `lrlOperator_eq'`, `lrl_commutation_lrl`, `hamiltonianReg_commutation_lrl` at 46-79 shared constants | the corpus proves the commutator algebra of position, momentum and angular momentum, and proves the LRL operator's expansion. The LRL commutators are the same computation with that expansion substituted |
| 7-8 | `WickContraction.Perm.isFull_of_isFull`, `…perm_uncontractedList` | `WickContraction.Perm.symm`, `.refl`, `.trans` | root retention **0.484**/0.477, `common` 31; `vocabulary_adjacent` returns the three groupoid laws, each sharing 6-7 constants with `WickContraction.Perm` (df **5**) at the head | `Perm` has its equivalence-relation laws proved and its *invariants* asserted |
| 9 | `CPTPMap.bddAbove_achievesRate` | `CPTPMap.achievesRate_0`, and — unproved — `not_achievesRate_gt_log_dim_in/out` | `vocabulary_adjacent` 6 shared constants, rarest `CPTPMap.AchievesRate` (df 5) | boundedness above needs the log-dim upper bound, **which is itself on this list** |
| 10 | `RigidBody.solidSphere_inertiaTensor` | `RigidBodyMotion.kineticEnergy_eq_translational_add_bodyAngularVelocity` (0.373), then unit-scale lemmas at 0.292 | nothing shares `RigidBody.inertiaTensor` (df 5) or `RigidBody.solidSphere` (df 3); `vocabulary_adjacent`'s top row shares 23 constants but its rarest is df 73 — i.e. only generic matrix vocabulary | genuinely isolated: the corpus has one other theorem about rigid-body dynamics and nothing about inertia tensors |
| 11-12 | the two `leviCivita` contractions | `PauliMatrix.*`, `Electromagnetism.*` | retention **0.005-0.021**; `vocabulary_adjacent` pairs them with each other at 62 shared constants | nothing usable — see §4 on why a 71 MB statement has no neighbours |

### Two structural facts the ranking surfaced that no route kind would have

* **The capacity cluster's routes point at each other.** `bddAbove_achievesRate` needs
  `not_achievesRate_gt_log_dim_*`; `coherentInfo_le_quantumCapacity`'s top conclusion
  neighbour is `zero_le_quantumCapacity`. Of the whole `AchievesRate`/`quantumCapacity`
  neighbourhood only **two** declarations are proved — `achievesRate_0` and
  `id_achievesRate_log_dim` — and every unproved member's best neighbour is either one of
  those two or another unproved member. That is what a module at 39% unproved looks like
  from the inside, and it says the cluster has to be attacked from `achievesRate_0` outward.
* **`not_achievesRate_gt_log_dim_in` and `…_out` are the same claim mirrored, and R5 could
  not see it.** Conclusion-anchored `similar` scores them **retention 1.000** against each
  other — carriers-identical conclusions — while R5's conclusion *identity* test returns 0,
  because their raw encodings differ in the `Fintype` instances that `carriers` erases. Two
  of the eighteen are one theorem, and proving either gives the other by the in/out swap.
  This is the case §8.3's conclusion anchor exists for, at the wrong fidelity: exact
  conclusion equality is too strict and the erased comparison is not exposed anywhere except
  through a similarity float.

---

## 5. The controls, and why the negative is a measurement

A search that finds nothing is worthless unless it can be shown to find something. Four
arms, all pre-registered in §1, run on both the closed corpus and the 12.39%-closed one:

| control | closed (0.9946) | unclosed (0.1239) | pass condition |
|---|---|---|---|
| **planted provable** — a proved theorem rewritten by a witnessed substitution whose image exists, handed back as a target | **60/60 (100%)** routed, **60/60** with the substitution named | 59/60 (98.3%), 59 named | ≥ 90% |
| **planted decoy** — the same vocabulary poured into a different rigid skeleton | **0/60** routed | 0/60 | 0 |
| **frequency-matched null** — the same left-hand constants, right-hand side resampled from the corpus's own constant distribution | **0/699 (0.00%)** | 0/94 (0.00%) | far below genuine |
| **calibration** — 120 proved theorems run unmodified as pseudo-targets | R1 3 (2.5%), R3 6 (5.0%), R5 6 (5.0%) | R1 2, R3 7, R5 6 | not ~100% |

The decoy arm is the one that matters. A method keyed on a *bag of constants* passes the
planted arm and fails this one; keying on the tree is what makes it 0/60. And the
calibration arm is what makes the null result mean something: a route is rare among proved
theorems too — 2.5% have an identical twin, 5% rewrite onto an existing declaration — so
"no route" is the ordinary condition of a declaration in this corpus and not a verdict on
the eighteen. It also rules out the failure mode where the search is trivially generous.

**Both corpora agree on all four arms**, which is worth stating because the two corpora
differ by 80,705 rows. R1/R3/R5 read the raw statement encoding and never erase, so they are
sound on an unclosed slice by the same argument `physlib-newqueries.md` §9 makes; the
agreement is evidence that argument is right.

---

## 6. Closure buys one thing, and it is measurable: 2.00% against 0.00%

The one arm with a sample size worth stratifying is not the targets. For every physics
claim, ask whether **any** mathematics claim shares its rigid skeleton, and how many
constant substitutions separate them. Same query, same code, two corpora:

| corpus | closure | physics claims | sharing a rigid skeleton with a mathematics claim |
|---|---|---|---|
| `/tmp/fh-physlib.jsonl` | 0.1239 | 9,484 | **0 (0.00%)** |
| `/tmp/pc-physclosed.jsonl` | **0.9946** | 9,480 | **190 (2.00%)** |

That is the measured cost of an unclosed slice for this question, and it is total: without
the mathematics half in the corpus the query returns zero and reports it as a finding. The
same trap CLAUDE.md §7 and findings §31 describe for erasure, in an arm that does not erase
at all — the constants are simply not there to compare against.

By substitution distance, on the closed corpus:

```
k=1: 1     k=2: 14    k=3: 111   k=4: 46    k=5: 16    k=7: 2
```

**Exactly one physics declaration in 9,480 is a single constant swap from a mathematics
declaration**, and it is `Prob.instNontrivial ← Bool.instNontrivial` — an instance, not a
theorem. Whatever physlib restates from Mathlib, it does not restate it at k=1.

By subfield, with the label-permutation control the corollary in CLAUDE.md §3 requires
(narrowing manufactures false negatives, so a filter needs its own control):

| subfield | reaching | claims | rate |
|---|---|---|---|
| Physlib.Meta | 8 | 33 | **24.24%** |
| Physlib.CondensedMatter | 5 | 30 | 16.67% |
| Physlib.Thermodynamics | 6 | 44 | 13.64% |
| Physlib.Units | 18 | 220 | 8.18% |
| QuantumInfo.ClassicalInfo | 8 | 101 | 7.92% |
| Physlib.Particles | 53 | 1,124 | 4.72% |
| Physlib.ClassicalMechanics | 14 | 323 | 4.33% |
| Physlib.StringTheory | 6 | 206 | 2.91% |
| Physlib.QuantumMechanics | 18 | 676 | 2.66% |
| QuantumInfo.States | 4 | 221 | 1.81% |
| Physlib.SpaceAndTime | 14 | 838 | 1.67% |
| Physlib.Electromagnetism | 6 | 407 | 1.47% |
| Physlib.Relativity | 17 | 1,412 | 1.20% |
| Physlib.QFT | 11 | 1,292 | 0.85% |
| Physlib.Mathematics | 1 | 832 | 0.12% |
| **QuantumInfo.ForMathlib** | **0** | **978** | **0.00%** |

**Control:** the reach label permuted across physics claims, 1,000 shuffles. Observed
spread of per-subfield rates **0.0649** against a permuted 95th percentile of **0.0209** —
**structured, 3.1x**. So the concentration is not "the biggest subfield has the most
reaching claims".

Two rows are worth reading. `Physlib.Meta` at 24.2% is the library's own metaprogramming
resembling Lean's, which is the same "you are measuring Lean rather than mathematics"
signature CLAUDE.md §5 records four times over — it is left in the table rather than
filtered, because removing the largest row of a distribution is how a control gets quietly
disabled. And **`QuantumInfo.ForMathlib` — 978 claims explicitly staged for upstreaming into
Mathlib — has structural overlap with Mathlib of exactly zero.** Whatever makes a result
"for Mathlib" in that module's judgment, it is not that the statement already has a Mathlib
shape.

---

## 7. Distance to the proved frontier is measurable, and the unproved sit outside it

The brief's fourth direction: is an assertion's distance to the proved frontier measurable,
and does it predict anything? Define `d(x)` as the fewest distinct constant substitutions
separating `x` from a **proved** declaration sharing its rigid skeleton, undefined when no
proved declaration does. The control is size-matched — proved claims within ±20% of the
target's statement size — because statement size is the one feature that separates physics
from mathematics (findings §50, §53) and would otherwise be the whole result.

| corpus | targets reaching a proved bucket-mate | size-matched proved controls | one-sided binomial |
|---|---|---|---|
| closed (0.9946) | **0 / 18** | 94 / 349 (26.9%) | **p = 0.0035** |
| unclosed (0.1239) | **0 / 18** | 83 / 336 (24.7%) | p = 0.0061 |

*(The binomial is computed from the run's JSON by
`scripts/phys-provable.py`'s companion arithmetic, not by the script; it is
`P(X ≤ 0 | n = 18, p = control rate)`.)*

**An unproved declaration in physlib is significantly further from the proved frontier than
a proved declaration of the same size.** Roughly a quarter of size-matched proved claims
have a proved bucket-mate; none of the eighteen does.

### The obvious confound, and why the paired corpus disposes of it

Size-matching is not library-matching. On the closed corpus the control pool is drawn from
all 70,254 proved claims, 84% of which are Mathlib — so "the targets are further out" could
be "physics is further out", which §6 shows is true in a different sense (2.00% cross-library
reach).

The unclosed corpus settles it. `/tmp/fh-physlib.jsonl` holds **only** Physlib and
QuantumInfo — 9,489 claims, no Mathlib at all — so its 336 size-matched controls are 100%
physics, and the same 18 targets still score **0/18 against 83/336, p = 0.0061**. The effect
is provedness, not library.

That is a real answer to "does distance predict anything", and the direction is the
uncomfortable one for the premise of this study: **the assertions physlib has not proved are
precisely the ones with no structural neighbour**. They are not low-hanging fruit that the
library overlooked; they are where it stopped because there was nothing nearby to stand on.

### Why: an unproved claim is the first thing said about its own vocabulary

The bucket measure is undefined for a declaration in a singleton bucket, which is most of
them, so here is the same question with a measure that is always defined: the **document
frequency of the rarest constant a statement mentions**, as a percentile against every
proved claim in the corpus. Over 70,113 proved claims the first quartile is **4** and the
median is **10**.

| target | rarest constant df | percentile among proved claims |
|---|---|---|
| `CPTPMap.coherentInfo_le_quantumCapacity` | 2 | 7.3 |
| `CPTPMap.quantumCapacity_eq_piProd_coherentInfo` | 2 | 7.3 |
| `RigidBody.solidSphere_inertiaTensor` | 3 | 16.0 |
| `CPTPMap.not_achievesRate_gt_log_dim_in` | 4 | 22.5 |
| `CPTPMap.not_achievesRate_gt_log_dim_out` | 4 | 22.5 |
| `CPTPMap.quantumCapacity_ge_log_dim_in` | 4 | 22.5 |
| `CPTPMap.zero_le_quantumCapacity` | 4 | 22.5 |
| `CPTPMap.bddAbove_achievesRate` | 5 | 29.5 |
| `WickContraction.Perm.isFull_of_isFull` | 5 | 29.5 |
| `WickContraction.Perm.perm_uncontractedList` | 5 | 29.5 |
| `MState.fidelity_channel_nondecreasing` | 7 | 38.7 |
| `HydrogenAtom.angularMomentumSqr_commutation_lrlSqr` | 8 | 42.7 |
| `HydrogenAtom.angularMomentum_commutation_lrl` | 9 | 46.1 |
| `HydrogenAtom.angularMomentum_commutation_lrlSqr` | 9 | 46.1 |

**Every one of the fourteen sits below the median of the proved distribution** — the largest
is 46.1 — which is a sign test at **p = 6.1e-5**. Seven of fourteen are in the bottom
quartile against an expected 3.5, binomial p = 0.038.

Fourteen, not eighteen: the two `def`s hold no constant and the two 60-70 MB statements
exceed the 2 MB scan cap. Excluding those two is **conservative** — their rarest constants
have document frequency **1**, so they would sit at percentile ≈ 0 and strengthen the result.

This is the mechanism behind §7's bucket result and behind §4's null, and it is the one
finding here that generalises past physlib: **a formal library's unproved statements are
identifiable in advance by the rarity of the vocabulary they use.** That is a screen an
engine can compute in one pass and it needs no proof state.

---

## 8. Engine specs

Five, in the order they are worth doing. Each names the five places CLAUDE.md §6 requires:
engine, CLI, Python binding + `.pyi`, `fh mcp`'s tool list, and a gate against a real slice.

### 8.1 `equivalent` and `classes` must not be blind to an assertion

**Defect.** `crates/fh-atlas/src/equiv.rs:124` computes
`is_prop = kind == "theorem" || concludes_in_prop(stmt)`, and `concludes_in_prop`
(`equiv.rs:274`) is true only when the statement's own conclusion is `Sort 0` — a property
of a *definition of* a proposition, never of a claim. So the flag reduces to
`kind == "theorem"`, `check_prop` (`equiv.rs:196`) refuses every `axiom`, and the member
filter (`equiv.rs:214`) drops axioms out of every other declaration's class. Measured (§2):
`Lean.trustCompiler` and `trivial` are byte-identical and the query answers nothing in
either direction; **0 of 15 axiom rows appear in any exact-level class**.

**Change.** `k == "theorem" || k == "axiom" || concludes_in_prop(...)`. `axiom` is exactly
the genre where the statement *is* the claim, which is the case the second disjunct cannot
see. Leave `opaque` and `def` alone — `concludes_in_prop` is the right test for them.

**Gate**, `crates/fh-atlas/tests/equiv.rs`, paired so it can fail in both directions:

| test | what fails it |
|---|---|
| `an_axiom_and_a_theorem_with_one_statement_are_equivalent` | fixture with `axiom A : True` and `theorem t : True`; `equivalent("A")` must return `["t"]` |
| `and_the_theorem_reports_the_axiom_back` | the member-filter half; this is the one that is currently wrong *and* silent |
| `a_definition_that_is_not_a_proposition_is_still_refused` | the guard's original purpose — without it the class is every declaration whose type is `Type` |
| `axioms_appear_in_classes_on_a_real_slice` (`FH_SLICE`) | on `/tmp/mathlib-algebra.jsonl`, `classes(level="exact", theorems_only=False)` must contain at least one class holding a `kind == "axiom"` member. Currently **0 of 15**; a green run here means the fix reached the class query and not only the point query |
| `vocabulary_adjacent_never_returns_a_class_member` (`FH_SLICE`) | the downstream half: `vocabulary_adjacent("Lean.trustCompiler")` currently returns `trivial`, whose statement is byte-identical. The `unwrap_or_default()` at `crates/fh-atlas-py/src/lib.rs` should propagate `NotProp` rather than substitute an empty class — a class the query could not compute is not a class of size one |

### 8.2 `Corpus.proof_routes(name)` — the query this study is

Nothing in the shipped surface answers "what would prove this". `honesty` says a
declaration is unproved and stops; `similar` returns floats; `transport` has never produced
anything (`corpus-atlas-findings.md` §24). The five route kinds of §1 are one query with a
discriminated result, and
the warrant differs per kind, so — Engine 1's fifth non-goal — they must not share a type
that lets a caller ignore which one fired.

```rust
pub enum Route {
    /// The image is byte-identical to a proved declaration. `theorem T := D`.
    Identity   { by: String },
    /// A proved theorem concludes exactly this, under its own hypotheses.
    Conclusion { by: String, hypotheses: Vec<String> },
    /// A witnessed substitution carries the target onto a proved declaration.
    Rewrite    { by: String, sub: (String, String), witnesses: u32 },
    /// Equal after erasure at `level` to a proved declaration.
    Equivalence{ by: String, level: Level },
    /// `skeleton(by, level)` one-way matches this statement: T is an instance of D.
    Subsumption{ by: String, level: Level },
}

pub struct Routes {
    pub subject: String,
    pub routes: Vec<Route>,
    /// Constants of the subject that occur in no proved theorem's statement — the part of
    /// the vocabulary nothing has been proved about. Empty is the good case.
    pub unproved_vocabulary: Vec<String>,
    /// Skipped for size, counted rather than dropped.
    pub skipped: u32,
}

pub fn proof_routes(&self, name: &str, min_witnesses: u32) -> Result<Routes, GraphError>;
```

Binding `Corpus.proof_routes(name, min_witnesses=1) -> Routes`, and `fh mcp` gains it: an
agent handed an unproved statement wants this before it wants a similarity ranking.

**Gate**, `crates/fh-atlas/tests/routes.rs` — the three arms measured in §7, each able to
fail:

| test | what fails it |
|---|---|
| `a_planted_provable_target_is_routed_with_its_substitution_named` (`FH_SLICE`) | rewrite a proved theorem by a witnessed substitution whose image exists, hand back the image; red below 90% recovery |
| `a_decoy_holding_the_right_vocabulary_in_the_wrong_tree_is_not_routed` (`FH_SLICE`) | **the specificity control**; a bag-of-constants implementation passes the first test and fails this |
| `the_route_rate_exceeds_a_frequency_matched_null` (`FH_SLICE`) | red if the null scores within 10x, **and red if the null arm did not run** (findings §20's trap) |
| `a_calibration_arm_does_not_route_everything` (`FH_SLICE`) | red if proved theorems route at > 50%; a query that says "provable" about everything is worse than no query |

### 8.3 Exact structure needs a conclusion anchor

`Anchor` exists for `similar` and `dictionary` and for nothing else. `equivalent`,
`variants`, `adjacent` and the rigid index all align from the root, so a claim with a
hypothesis prefix cannot match one without — the failure `fh_atlas.pyi` documents at
`common 0, retention 0.0` for two statements that are literally the same. §7 measures what
that costs on the targets here.

`RigidIndex::build` already takes a `Level`; it should take an `Anchor` too and key on the
conclusion when asked, and `equivalent`/`variants`/`adjacent` should carry the parameter
through. **The conclusion has to be extracted, not sliced**: after walking off k binders the
remaining bytes carry k trailing `)` and are not a term, so the end must be found by walking
it. Gate: a statement with no binder is its own conclusion; a conclusion is never longer
than its statement; and — the one that can fail — two theorems differing only in a
hypothesis prefix must be conclusion-equivalent and root-inequivalent.

### 8.4 The extractor drops what a prose claim says it is about

**Defect.** `atlas-extract/FhAtlas/Extract.lean`'s `rowOf` records
`usesProof := sortedConstants(value)`, i.e. `Expr.getUsedConstants`. physlib's 76 prose
claims carry their dependency list as `List Name` built from **string literals**, which are
`Expr.lit` and therefore invisible: all 76 report the identical five citations
(`InformalLemma.mk`, `Lean.Name`, `Lean.Name.mkStr2`, `List.cons`, `List.nil`) and not one
physics constant. The largest genre of unproved assertion in the library is therefore
unreachable by every query in the Atlas, and it is unreachable by one field.

**Change.** A `literals` field on `Row`: the `Expr.lit` string payloads occurring in a
declaration's value, sorted and deduplicated. Not an interpretation of them — the Atlas
should not know what `InformalLemma` is — just the data, so a consumer can reassemble a
`Name` and look it up. Consumers gain "which formal constants does this prose claim name",
which is `deps` recovered without the extractor knowing the field exists.

**Gate**, paired: on a fixture whose value contains `Lean.Name.mkStr2 "A" "b"`, `literals`
must contain `"A"` and `"b"`; on a fixture with no literal it must be present and empty,
never absent. And on `FH_SLICE=/tmp/pc-physclosed.jsonl`, the 76 declarations whose type is
an `InformalLemma`/`InformalDefinition` must yield **more than zero** distinct literals —
currently exactly zero, which is the number that makes this worth doing.

### 8.5 `Corpus.vocabulary_rarity(name)` — the one screen that generalises

§7's result is that an unproved statement is the first thing said about its own vocabulary:
all 14 measurable targets below the median of 70,113 proved claims, sign test p = 6.1e-5.
That is a one-pass, always-defined measure with no proof state in it, and it is the cheapest
thing in this study to compute and the only thing that transferred to a prediction.

```rust
pub struct Rarity {
    /// Document frequency of the statement's rarest constant.
    pub min_df: u32,
    pub rarest: String,
    /// Its percentile among the corpus's claims, so a caller need not carry the
    /// distribution. Corpus-relative by construction — a raw count is not comparable
    /// between slices and this is the number that is.
    pub percentile: f32,
    /// Constants of this statement occurring in no other claim at all.
    pub unique: Vec<String>,
}

pub fn vocabulary_rarity(&self, name: &str) -> Result<Rarity, GraphError>;
```

The `df` table already exists — `vocabulary_adjacent` computes exactly this to decide what
"distinguished" means (`max_df_fraction`) and then throws the number away except as the
`rarest_df` column of a row. Surfacing it directly is a few lines and turns a byproduct into
a screen.

**Gate**, `crates/fh-atlas/tests/rarity.rs`, and the only one here whose failure would be
interesting: on `FH_SLICE=/tmp/pc-physclosed.jsonl` the 14 measurable `honesty()` findings
must have a **median percentile below 50**, against a size-matched sample of proved claims
that does not. Red if the separation disappears — that is the claim, and it should be a
test rather than a paragraph.

---

## 9. Costs, measured on the 95,268-row closed corpus

| step | time |
|---|---|
| `Corpus.load` (2.4 GB) | 31-36 s, ~5.5 GB resident |
| `Corpus.closure` | 106 s over 51,394,099 application heads |
| `honesty()` + `honesty([])` + the kind and prose census | ~40 s |
| build the lean view: fetch, blank and hash all 95,268 statements **including** the blank-then-refill gate | **1,363 s** |
| the same with `--skip-selftest` | **1,126 s** — the gate is 237 s of 1,363, i.e. **17%**. The flag was added on a guess that it was the bottleneck; it is not, and the gate should stay on |
| the witnessed substitution inventory, bucket by bucket | 73 s |
| route search over 18 targets, R1/R3/R5 | < 1 s each, except the two 60-70 MB statements at 15-17 s |
| cross-library reach + the 1,000-shuffle permutation control | ~30 s |
| distance to the proved frontier | ~20 s |
| the four control arms | ~120 s |
| **the engine's lazy indexes** — the first `equivalent`/`variants`/`similar` call on this corpus | **244 s**, and ~2 s per target afterwards; peak resident 8.8 GB |
| rarest-constant percentiles over all 70,113 proved claims | a further full scan, ~20 min |

Two things dominate and both are Python-side. Fetching and blanking 2.4 GB of statement
encodings is 23 minutes because it allocates one `bytes` object per constant slot and there
are tens of millions of them; that is what `RigidIndex` in Rust exists to avoid
(`physlib-newqueries.md` §10 S1). The round-trip gate is 17% of it — less than the flag that
skips it was added expecting — and it passed **95,268 / 95,268**, extending findings §51's
131,062/131,062 on Mathlib and 14,563/14,563 on physlib to a corpus holding a **71 MB**
statement.

The lean view is deliberately not `phys-newqueries.py`'s `View`: keeping every statement and
every constant list in Python is affordable at 146 MB and is not at 2.4 GB. What the route
search needs per declaration is four hashes, a size, a conclusion head and a 64-bit
signature of its constant set; statements are re-fetched for the few thousand declarations
that turn out to matter.

---

## 10. What is not claimed

**No route below is a proof.** Nothing here was handed to the kernel: `lake` and `lean` were
off-limits for this session because other workspaces were building, and every route is
therefore a **candidate** except R1 and R5-identical, which are decided by encoding equality
and need no kernel. Anywhere this document says "provable" without saying "candidate", it
means the encodings are equal.

**Eighteen is a small sample and the power is stated, not hidden.** `physlib-frontier.md` §6
already measured that 16 unproved theorems cannot resolve an AUC difference below 0.194;
the same limit applies to every rate reported per target here. A route rate of 1/18 and a
route rate of 3/18 are not distinguishable, and this document does not distinguish them.

**The cross-library arm is the only stratified result, and it is a structural claim, not a
mathematical one.** "This physics claim is a mathematics claim with the vocabulary swapped"
says the trees are equal. Whether the physics one *follows* from the mathematics one is a
question for the kernel.

**The prose genre is refused, not searched.** 76 of the corpus's unproved assertions carry
no proposition (§3), so every route is undefined on them. That is the largest genre and it
is the one this study cannot reach.

**The single-toolchain closure was not used.** `/tmp/fh-physlib-closure.jsonl` was still
being written throughout this session — 3.67 GB when it was first checked, 5.42 GB when this
was written, against a projected ~9.5 GB — and the machine reported **0 GB available** at
that point with other work resident. A slice being read while it is being written is not a
slice, and loading it was not attempted. Recorded as not run. Everything here is on
`/tmp/pc-physclosed.jsonl`, whose one relevant property — one encoding per constant, 95,268
rows, 95,268 distinct names — was checked directly (§1).

**The `variants` / `adjacent` / `vocabulary_adjacent` / `requires` / `similar` half was run
as a separate pass** (§4b), because those queries build Rust-side indexes over the whole
2.4 GB corpus and an out-of-memory death there would have taken the rest of the study with
it. It completed: 244 s for the first query, 8.8 GB peak resident. §4's counts are from the
pass that does not need the indexes, and the two passes agree on everything they share.

**Subsumption is 0/18 with three reported gaps.** Two targets were skipped for statement
size (60-70 MB) and one was capped at 2,000 of 4,037 candidates. The script prints each
rather than folding them into the zero, because a skipped candidate is a false negative and
those are the expensive kind.

**§4b's candidate routes are the shipped ranking's output and are not verified.** They are
listed because a null result with no candidates is not actionable, and they are marked
`candidate` everywhere. Reading a retention of 0.752 as "this follows from that" is an
inference this document does not make; what it reports is that the engine put a *proved*
declaration there, with a named count of shared structure.


