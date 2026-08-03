# Applying the Atlas to real data: what worked, what didn't

**Date:** 2026-08-03 · **Slice:** `/tmp/mathlib-algebra.jsonl`, 131,062 declarations from
`Mathlib.Algebra.Order.Field.Basic`'s closure · **Oracle:** Lean's kernel via
`#fh_home_refute`

Every number below was measured in this session. Where something was not run, it says so.

---

## 1. The one result worth keeping

Two detectors for "this theorem assumes more than it needs", built from **disjoint**
evidence:

* **Citation detector (L).** Reads the proof's cited constants and asks what *they*
  require, then walks down the typeclass hierarchy. Never looks at other theorems.
* **Shape detector (S).** Finds theorems whose statements normalize to the same thing, and
  flags the one declaring the stronger class. Never looks at proofs.

Each candidate was then forced in front of the kernel. `CONFIRMED` means the declaration's
own proof term typechecks with the weaker hypothesis — sound and final. `REFUTED` is
explicitly **inconclusive** (`Home.lean` says why: instance projections were baked into the
value at first elaboration), so every rate here is a **lower bound on precision** and says
nothing about recall.

| stratum | confirmed | refuted | precision ≥ |
|---|---|---|---|
| flagged by **both** | 12 | 16 | **42.9 %** |
| citation detector only | 29 | 91 | 24.2 % |
| shape detector only | 11 | 109 | 9.2 % |

**The conjunction outperforms both halves**, which is the claim worth industrialising: not
"we found generalizations" but "we can *measure* which combinations of signals are worth
trusting, because this task has a ground truth."

**The caveat that keeps this honest.** All twelve `BOTH` confirmations are the
`max`/`min`→lattice family. The crossing's advantage may therefore be "it selects a family
that happens to be confirmable" rather than a general property, and this experiment cannot
tell those apart. The `L_ONLY` confirmations are much more varied (`Mul`, `Pure`, `LE`,
`NatCast`, `NSMul`, `Add`, `MulPosReflectLT`, `IsOrderedRing`), which is weak evidence
against the pessimistic reading, not a refutation of it. Repeating this on a slice with
different mathematics is the obvious next control.

**A scoring correction that mattered.** `#fh_home_refute` forces its class onto *every*
instance binder, so `div_le_one` (three binders) yields two verdicts nobody asked for —
"can a partial order be replaced by a group with zero" is not a claim any detector made.
113 such lines were discarded. Counting them would have depressed every rate.

### Bound minimization is an instrument, not a product

Worth saying plainly, because the framing was wrong for most of this session: the confirmed
weakenings are not a discovery. Mathlib ships generalization linters and runs them; the
`max`/`sup` and `min`/`inf` pairs are *deliberate* duplication kept for use-site ergonomics;
and a confirmed hit yields a marginally stronger version of an existing theorem — library
maintenance.

What makes it valuable is that it is **the only task here with a ground truth.** Analogy,
frontier and transport have no oracle; nothing can tell you a proposed analogy is correct.
Bound minimization can be settled by the kernel, so it is where detector trustworthiness
gets calibrated before being applied where it cannot be checked.

---

## 2. The relationship layer, measured

atlas.md's differentiator claim is that retrieval answers "find me a lemma" and nothing
answers "find me a relationship." Here is what the relationship layer actually contains.

### Proved edges — thin, with a large unexamined blind spot

| | |
|---|---|
| theorems scanned | 66,700 |
| edges extracted | 10,322 (15.5 % yield) |
| distinct heads | 382 |
| **sides skipped, head is a bound variable** | **18,130** |

The skipped count is nearly twice the edge count. Those sides need higher-order matching
and were never looked at, so "the reformulation layer is thin" and "we did not look" are
currently indistinguishable for most of it. The `LogicalStats` surface deserves credit for
reporting this rather than hiding it.

### Every layer is dominated by Lean, not mathematics

| query | what leads the ranking |
|---|---|
| `busiest_heads` | `Eq` (6,671), `And` (2,639), `LE.le`, `LT.lt`, `Exists`, `Not` |
| `walls --lens proof` | `Eq`, `Nat`, `OfNat.ofNat`, `congrArg`, `Eq.refl`, `id`, `of_eq_true`, `Eq.mpr` |
| `similar` cross-theory | `Lean.Constructor.mk.inj ~ Aesop.ElabRuleTerm.term.inj`, `Lean.Lsp.RenameOptions.mk.injEq ~ Aesop.Script.DynStructureM.State.mk.injEq` — auto-generated structure lemmas, identical because *every* structure gets them |
| `classes --level instances` | `CommGroup.mul_comm, CommMagma.mul_comm, CommMonoid.mul_comm, …` — one field re-exported at every level of the hierarchy |
| `classes --level carriers` | `Bool.le_trans, Char.le_trans, Int.le_trans, ISize.le_trans, …` (18 members) — one lemma restated per concrete type for bootstrapping |

The mathematically interesting heads exist but are tiny: `Dvd.dvd` 166 edges,
`List.Perm` 114, `Function.Injective` 71, `Even` 48, `IsUnit` 47.

CLAUDE.md already records "restrict to claims, or you are measuring Lean rather than
mathematics" as having bitten three times (B5's classes, B6's rows, B6's frontier). It is
biting at **every** layer, which suggests the restriction belongs at the slice level as a
first-class filter rather than as a per-query flag each new query must remember.

### The frontier returns the opposite of its design

`frontier` is meant to find *high similarity, low cross-citation*. With infrastructure
excluded, all six surviving pairs are **low similarity, high citation**:

| pair | similarity | cross-citations |
|---|---|---|
| `Mathlib.Algebra ~ Mathlib.Order` | 0.040 | 1,508 |
| `Mathlib.Logic ~ Mathlib.Order` | 0.022 | 288 |
| `Mathlib.Data ~ Mathlib.Order` | 0.018 | 594 |

The ranking is selecting the largest theory pairs. This is an honest negative and matches
the one PLAN.md already records for B6. On a slice with only six mathematical theories at
depth 2, "unexplored interface between theories" may simply not be a well-posed question —
the granularity is wrong.

### Analogy: 35.5 % cross-theory hit rate, mostly boilerplate

Of 400 probed theorems: 3.8 % had no neighbour, 60.8 % only same-theory neighbours, 35.5 %
had a cross-theory hit. But the cross-theory hits are led by `.mk.inj` / `.injEq`
auto-generated lemmas. The genuine-looking ones exist — `sup_idem ~ beq_self_eq_true'`
(both are `f a a = a`) — and are a minority the ranking does not distinguish.

---

## 3. Defects found, with evidence

### `home` had never run at scale, and building a batch version found two false-positive families

B3's `#fh_home` is an `elab` command with no batch surface, no Rust implementation and no
Python binding. atlas.md leads with "every gap found is a free generalization … to my
knowledge nobody runs it systematically," and it had not been run systematically. A
slice-side implementation (`scripts/fh_home.py`) surfaced two systematic errors:

**(a) Class field projections.** `AddCommMagma.add_comm`'s entire proof cites one constant:
`AddCommMagma`. It *is* the class's field. The evidence rule finds nothing needing the
binder and reports it unused — true of the citations, false about the declaration. 314 of
1,777 `unused` verdicts. Stratified rather than filtered, per CLAUDE.md's rule about split
ground truths.

**(b) The instance exclusion severs notation→class paths. This is a defect in the Lean
implementation too.** `AddOpposite.op_add` writes `+`, elaborated as `HAdd.hAdd` needing
`[HAdd α α α]`, supplied by `instHAdd : [Add α] → HAdd α α α`. B3 excludes instances
wholesale as plumbing — necessary, or every declaration reports "at home" — but that
exclusion breaks the only path from the notation to the declared `Add` binder, so `Add`
reads as unused for a statement whose entire content is an addition. Fourteen
`AddOpposite.op_*` / `unop_*` declarations in this slice alone.

The fix is to exclude the *direction*, not the kind. A **forgetful** instance walks down the
lattice it is being asked about (its conclusion class is an ancestor of one of its own
binder classes) and re-states the hypothesis; `instHAdd` does not, because `HAdd` is not an
ancestor of `Add`. Measured on the algebra slice: 10,625 class-producing constants, of which
2,682 are forgetful and must be excluded; the other 7,943 should be traversed. Parent
projections fall out as the special case they always were. After the fix,
`AddOpposite.op_add` correctly reads "at home" and the candidate count drops from 1,689 to
1,044 `unused` and 806 to 727 `over-hypothesis`.

### Identity is a name string, everywhere

`graph.rs` keys its edge maps `HashMap<String, Vec<String>>`; the skeleton arena interns a
constant as `HashMap<Box<str>, SymId>`. Inside one Lean environment this is sound, because
Lean enforces uniqueness. **Across merged slices it is silently wrong** — two different
declarations sharing a name become one node, their edge sets union, and a `sorry` under one
propagates to the other through `honesty`. Nothing errors.

This is not hypothetical: CLAUDE.md §7 explicitly licenses merging ("slices from different
workspaces concatenate"), which is exactly the operation that breaks the assumption. And
the corpus provokes it — `g01_peano` declares a root-level `add_comm`, `g07` and `g10` both
declare `sp`.

The three places a name carries identity are the `name` field, the `uses_*` edge lists, and
**the I3 statement encoding's `c(...)` nodes** — the last being the easy one to miss,
because a slice merged without rewriting it looks fine and quietly interns two different
constants to one `SymId`. `scripts/fh_encoding.py` rewrites all three (round-tripped over
84 real statements, length prefixes recomputed in bytes).

A qualified identity in the row schema is the real fix.

### `--local` cost a full extraction

`moduleRows` filtered `allRows`, so asking for one module's declarations encoded every
statement in the closure and discarded all but a handful. Fixed: the module test now runs
before `rowOf`. Importing the closure still costs what it costs.

### The corpus groups cannot be co-imported

Lean's `importModules` refuses two modules defining the same root name. `g01_peano.add_comm`
collides with Mathlib's; `sp` collides between `g07` and `g10`. This is a Lean constraint,
not an Atlas one — the merge is fine to do on the backend — but it means corpus extraction
is per-group, and the four Mathlib-free groups (`g01`, `g02`, `g03`, `g09`, 84 rows) are the
only ones that co-extract cheaply.

### Full-Mathlib extraction remains impractical

A full-closure walk ran 27+ minutes at 12.4 GB without emitting a row, matching the
previously abandoned attempt. `allRows` builds the entire array before writing, so there is
no partial output to salvage. **Consequence: every claim in this document is scoped to the
algebra slice**, which is roughly two-thirds `Init`/`Std`/`Lean` — see §2 on what that does
to every ranking.

---

## 3a. The corpus rediscovery benchmark — the result, and its one cause

Run against the four Mathlib-free corpus groups (40 authored declarations) merged with the
131k algebra slice as background. The eight Mathlib-importing groups are not included; their
extraction is per-group and did not finish.

**What passed.**

* **ADR-006 verified on the citation graph, not by inspection.** 0 of 40 corpus
  declarations rest on any `FerrisHoward.*` constant transitively. The emitted artifact's
  FH-freedom is a measured property of the dependency graph.
* **Four statement-identity hits, found by normalization rather than by name**:
  `g03_order.POrder.refl ≡ Preorder.le_refl`, `POrder.trans ≡ Preorder.le_trans`,
  `POrder.antisymm ≡ PartialOrder.le_antisymm`, `galois_connection ≡ GaloisConnection`.
* **Noise floor healthy**: 40 subjects produced 778 *distinct* Mathlib candidates, and the
  most-repeated neighbour appears for only 8% of subjects. The sweep discriminates rather
  than answering the same thing for everything.
* **Honesty found exactly the tracked holes** — four `sorryAx` dependants — with the
  empty-whitelist control firing at 104,791.

**The rediscovery scores, and the confound that had to be checked.**

| group | expected targets surfaced | reading |
|---|---|---|
| `g03_order` | **6/6** | reuses Mathlib's `LE` |
| `g02_group` | 3/8 | custom `op`; matched on structure, not on laws |
| `g01_peano` | **0/7** | custom `add` — **and the targets are in the slice** |
| `g09_category` | 0/5 | **unscoreable**: 0 CategoryTheory declarations in the background |

The confound was checked rather than assumed. `Nat.add_comm` and 107 `Nat.add*` names are
present, so `g01`'s miss is a real engine miss. `CategoryTheory` has **zero** declarations
in this background, so `g09`'s miss says nothing about the engine and must not be scored.

**The cause is a single mechanism: the skeleton index cannot see through operator-class
indirection.** `g01_peano` writes `add(a, b)`, a plain function application. Mathlib writes
`a + b`, which elaborates to `HAdd.hAdd` resolved through `instHAdd` to `Nat.add`. The two
statements are mathematically identical and structurally different trees, and no erasure
level closes the gap, because erasure removes *carriers* and this is an *operator* layer.

`g03_order` succeeds for exactly the complementary reason, and the repo's own history
confirms it: PLAN A2.6 records that Group 3 first declared its own `le` and the repair was
one token, `trait POrder<Self>: LE`. That made it share Mathlib's `LE.le` constant, and the
engine then finds all six targets — with X2's statement-identity hits confirming the same
four independently.

This is the same mechanism, seen from the other side, as the `instHAdd` defect in §3: a
class reached only through an instance is invisible to a rule that does not traverse
instances. Here it makes two identical statements fail to rhyme; there it made an addition
report its `Add` binder unused. **One missing capability — following the operator-class
indirection — accounts for both.** That makes it the highest-value single repair found in
this session, and it is a question about erasure levels, which is a dial the design already
has.

## 3b. Derivativeness — a structural replacement for the boilerplate blocklist

Every layer of the Atlas, on every corpus tried, is led by auto-generated declarations:
Mathlib cross-theory analogy returns `.mk.inj` pairs, and physlib's `Relativity ~ QFT`
dictionary opens with `CausalCharacter.lightLike ~ annihilate.sizeOf_spec`. The standing
workaround is a hand-written list of name suffixes, which is brittle, library-specific, and
name matching — the thing the Atlas exists to replace.

**Round one failed, informatively.** The hypothesis was that generated lemmas are
*templates*: one skeleton instantiated across the library. Measured, skeleton **spread
across subfields scored AUC 0.509** — no information whatever, and multiplicity only 0.585.
The reason is worth keeping: `.injEq` gets a *distinct* skeleton per structure because the
field types differ, so it never accumulates multiplicity; meanwhile genuine definition
families do — `CKMMatrix.{c_row, cb_element, cd_element}` share one skeleton (multiplicity
150) because they are all `CKMMatrix → ℂ` accessors. Under that metric a real family is
indistinguishable from a template.

**Round two works.** Fifteen features off the row data, fitted jointly:

| corpus | declarations | AUC |
|---|---|---|
| physlib | 14,563 | **0.899** |
| Mathlib algebra | 131,062 | **0.886** |

Precision at the head of the ranking, which is what a downweighting prior actually needs:
physlib **1.000 @100**, 0.950 @500, 0.857 @1000; Mathlib 0.870 @1000, **0.912 @2000**.

Standardized weights, largest first (physlib / Mathlib):

```
proof_size          -1.111 / -0.673    a longer proof means a real theorem
in_degree           -1.089 / -0.373    something cites it
proof_frac_recursor +1.015 / +0.628    the proof cites recursors, not lemmas
frac_inst_binders   -0.887 / -1.489    typeclass binders mean a real claim
n_binders           +0.843 / +0.821
```

The signal that mattered most was the one round one never tested: **`kind` is on every row,
so the *kinds of thing a proof cites* are free.** A human proof cites theorems; a generated
one is discharged by the type's recursor. Alone it scores only 0.579 — it is complementary,
not independently strong, which is exactly why testing features one at a time missed it.

**Use it as a ranking penalty, never as a filter.** At a hard threshold the metric is
precision 0.62–0.67, which would delete one genuine declaration per piece of boilerplate
caught — unacceptable when false negatives are the unrecoverable error. As a fourth term in
`ScoreFactors` alongside `rarity_boost`, `cross_boost` and `scoped_penalty`, it costs no
recall and sinks `sizeOf_spec` rows below real ones.

Caveat stated rather than buried: the labels are still the name-based blocklist, so the AUC
measures agreement with a name heuristic. What makes it useful is that the *predictor* is
structural — it transfers to corpora whose naming conventions differ, and it flags
boilerplate nobody thought to add to a list.

## 3c. physlib — the engine on a real physics corpus

14,576 declarations across 27 subfields (Relativity 2,144, Particles 1,887, QFT 1,755,
QuantumMechanics 998, ClassicalMechanics 631, Electromagnetism 531, FluidDynamics 90).

**Reformulation layer, measured by a differential oracle.** An independent Python walk of
the I3 encodings finds **516** theorems whose conclusion head is `Iff`; the Rust engine
reports **261** `Iff` edges. So roughly **51% recall**, with 1,758 sides skipped as
flex-headed. The label set is derived from the statement tree, never from names — a
declaration is an equivalence because of its conclusion, not because it is spelled
`_iff_`.

**The frontier works here, and did not on Mathlib.** On the algebra slice it returned the
inverse of its design (similarity 0.010–0.040 against 288–1,508 cross-citations). On
physlib: `SpaceAndTime ~ Thermodynamics` at **0.673 with zero cross-citations**,
`ClassicalMechanics ~ Thermodynamics` 0.636, `Electromagnetism ~ Thermodynamics` 0.527.
The query only becomes well-posed when theories are comparable in size and the corpus is
not two-thirds compiler metaprogramming.

**But the frontier's answer is about code, not physics.** Every top pair is the same units
API replicated per dimension — `TemperatureUnit` against `TimeUnit`, `LengthUnit`,
`MassUnit`, `ChargeUnit`, sharing `scale_div_scale`, `self_div_scale`, `div_eq_val` and
friends at retention 0.85–0.97, never citing one another because they are independent
copies. A genuine finding (those five want one parameterised construction) and a library
one. Notably it is *not* addressable by the derivativeness penalty — these are authored
theorems — but it is exactly what **skeleton multiplicity × spread** measures, the signal
that failed as a boilerplate detector in §3b. Same metric, different job.

**Correspondence principle, found mechanically.** The `ClassicalMechanics ~
QuantumMechanics` dictionary pairs `ClassicalMechanics.HarmonicOscillator` with
`QuantumMechanics.OneDimension.HarmonicOscillator` at retention 0.92–0.95, both-proven,
with the shuffle control separating cleanly (genuine 0.736 against shuffled 0.192).

## 3d. Two ranking defects, and what fixing them was worth

**The dictionary never consulted the scorer.** `dict.rs` sorted presented rows by
`retention`, while `Row::score`'s own doc comment says retention "omits `scoped_penalty`,
so weighting a solver by retention alone would systematically prefer rows that cannot be
transported". Every ranking factor — rarity, cross-theory, scoped, and the new
derivativeness penalty — was therefore invisible in the output a reader sees. Adding a
factor to the score changed the presented rows *not at all* until the sort was fixed, which
is how the defect surfaced.

**Measured effect of both changes together**, over the presented top-6 rows of every
dictionary in the physlib run: boilerplate fell from **55% (36/66) to 32% (21/66)**. Names
in the transcript are truncated at 38 characters so suffix matching undercounts in both
columns; the comparison is like-for-like and both figures are floors.

The qualitative change is larger than the number suggests. `Relativity ~ QFT` previously
opened with six `sizeOf_spec` rows; it now opens with

> `Lorentz.Vector.causallyPrecedes_refl ~ FieldSpecification.crAnTimeOrderRel_refl`

— reflexivity of causal precedence against reflexivity of the creation/annihilation
time-ordering relation, which is the same physical concept in two subfields.

## 4. What was not run

* **The corpus rediscovery benchmark.** `scripts/corpus-atlas-experiment.py` is written with
  a pre-registered answer key for all twelve groups (what Mathlib declaration each group's
  claims should surface), and did not run: it needs the background extraction that did not
  finish. This was the original ask and it is unfinished.
* **Transport × falsification.** Generating a conjecture by analogy and running C4's
  battery on it — atlas.md's actual pipeline — has still never been run end to end.
* **A second slice.** Every rate here comes from one slice, so the family-confounding
  caveat in §1 stands unresolved.

## 5. Recommendations

1. **Make the claims restriction a slice-level primitive.** It has now bitten at five
   layers. Every query re-deriving it is how it keeps getting forgotten.
2. **Keep the oracle-calibration loop and extend it.** It is the only place in the system
   with ground truth, and it just produced the session's one defensible number.
3. **Fix the forgetful-instance rule in `Home.lean`,** not only in the script. The Lean
   implementation has the same defect.
4. **Give rows a qualified identity** before any further slice merging.
5. **Treat `frontier` as unproven** until a slice exists where "theory" is a meaningful
   granularity.

## 5. B7 — the validation clusters, and the defect they found

Built `lean/Validation/Clusters.lean`: 54 statement-level declarations across the nine
clusters `atlas-validation.md` §2 names. Plain Lean, `axiom` rather than `def … : Prop`
because the Atlas indexes a declaration's **type** and a Prop-valued definition has type
`Prop`. The private held-out key was not read, located, or searched for; the run's output
is emitted for its owner to score.

### Two engine defects, both found by building the corpus

**1. The reformulation layer read only `theorem`s.** `logical.rs` opened with
`if idx.kind_at(i) != "theorem" { continue; }`, so a statement-level corpus produced
**zero** edges — including `RiemannHypothesis ↔ Λ ≤ 0`, present in the corpus and walked
past on a `kind` check. Since §2 *mandates* the Formal-Conjectures genre, the document and
the implementation were in direct conflict.

Fixed properly rather than by widening the filter: an axiom's `Iff` is *asserted*, not
proved, so reporting it as `ProvedIff` would claim a warrant the engine has not got. Added
`Warrant::Asserted`, `RelationKind::{AssertedIff, AssertedImplies}` and
`Evidence::LeanAxiom`, with `Warrant` still derived from the kind so a caller cannot lie
about the grade. The de Bruijn–Newman edge now appears as
`AssertedIff · warrant=asserted · RiemannHypothesis/0 ~ LE.le/4`.

**2. Anti-unification is anchored at the statement root.** This is the larger finding.
`RH.zeros_subset_critical_line` and `Spectral.spectrum_subset_real` are both literally
`S ⊆ {x | P x}`, and their lgg is `common 0, vars 1, retention 0.0000` — they share
nothing. The skeletons show why: RH's set form has no binders and roots at `LE.le`, while
the spectral form is wrapped in five (`{E}`, two instance binders, `(T)`, `(h)`) and roots
at a `Pi` chain. Root-anchored matching cannot align them.

Measured fix, by transforming the slice so each statement *is* its conclusion:

| query | root-anchored | conclusion-anchored |
|---|---|---|
| `RH.zeros_on_critical_line` → spectrum-is-real | absent from top 8 | **rank 3** (0.24), plus ranks 7 and 8 |
| `RH.zeros_subset_critical_line` → `FF.eigenvalues_subset_circle` | absent | **rank 1** (0.30) |
| `Positivity.weil_criterion` → `rh_iff_lambda_nonpos` | no neighbours at all | **rank 1** (0.21) |

**V2's pass condition is "the match in top-5". Conclusion-anchored, it passes.**

This is the single best explanation for the day's analogy failures across every corpus:
`g01_peano`'s miss, physlib's boilerplate-led rankings, and V2 alike. Every cross-theory
analogy in mathematics differs in its hypothesis prefix, because the same claim carries
different hypotheses in different theories — and the root anchor makes that difference
fatal before the conclusions are ever compared.

**Not yet adopted as the default, and deliberately.** Stripping binders costs precision:
in the conclusion-anchored run a corpus *control* (`N.Succ.sizeOf_spec`) reached rank 4 on
one query, where the root-anchored controls were silent on all three. The trade needs
measuring across a real slice before this becomes a mode rather than an experiment.

### Scorecard, first run

| target | result |
|---|---|
| V1/V4 Z~FF dictionary | FAIL (0 rows) — two corpus statements were instance-typed, since fixed |
| V2 Hilbert–Pólya | FAIL root-anchored · **PASS conclusion-anchored (rank 3)** |
| V3 Weil positivity | PARTIAL — `intersection_positivity ~ castelnuovo_severi` rank 1 both ways |
| V6 reformulation cluster | PARTIAL — RH↔Λ recovered; Weil edge is flex-headed |
| V7 GRH as lgg | PARTIAL — family parameter abstracted, retention 0.129 |
| V8 pair correlation | FAIL |
| V9 proof-shape retrieval | UNRUNNABLE — no proof-shape index |
| controls | PASS root-anchored; one control fires conclusion-anchored |

## 6. Quantum physics — a second answer key, on a corpus we did not write

The RH run's weakness was that its corpus and its answer key were authored by the same hand
in the same hour. physlib removes that: 2,287 quantum declarations already exist, so the key
names **real declarations** and the run is a genuine test.

Every query was issued twice — root-anchored (shipped) and conclusion-anchored (§5's fix) —
so the run doubles as the independent-corpus check the fix needed.

| target | root-anchored | conclusion-anchored |
|---|---|---|
| Q1 correspondence principle | MISS (harness: key named a declaration that does not exist) | MISS (same) |
| Q2 self-adjoint ⇒ real spectrum | **PASS** rank 1 | **PASS** rank 1 |
| Q3 data processing | partial, rank 10 | partial, rank 9 |
| Q4 positivity family | **PASS** rank 1 | **PASS** rank 1 |
| Q5 Stein's lemma | MISS | MISS |
| Q6 ℏ attaches to operators | **PASS** rank 1 | **PASS** rank 1 |

Three passes, one partial, two misses. Q1's miss is **mine** — the key named
`ClassicalMechanics.HarmonicOscillator.equationOfMotion`, which is not a declaration in the
slice, so nothing was queried. Q5 is the honest failure: Stein's lemma (the optimal
hypothesis-testing exponent *is* a relative entropy) is the deepest target in the key, and
`OptimalHypothesisRate` returned only same-namespace neighbours in both modes.

### What this settles about conclusion-anchoring

**The precision cost is one percentage point.**

| | cross-subfield noise |
|---|---|
| root-anchored | 6/65 = 9% |
| conclusion-anchored | 9/89 = 10% |

That is the measurement §5 said was needed before this becomes a mode rather than an
experiment. On B7 it converted V2 from *absent from the top 8* to *rank 3*; here it costs
1pp of noise and changes no verdict. It also improved Q4's content: root-anchored,
`HermitianMat.PosDef_kronecker` matched its own namespace sibling `PosDef_reindex`;
conclusion-anchored it reached `MState.PosDef.kron` (0.456) — an actual Entropy↔States
positivity link rather than a neighbour from next door.

Recommendation: ship it as an explicit level or query mode, not as a silent default, and
keep the root-anchored ranking available. The two answer different questions — "what has
the same overall shape" and "what concludes the same thing" — and the second is the one
cross-theory analogy needs.

## 7. Total coverage of RH is not possible, and the failures sort into three kinds

`Anchor::{Root, Conclusion}` now ships in `IndexConfig` and through the binding
(`similar(..., anchor="conclusion")`), with two lazily-built indexes because the anchor is a
build-time property of the postings rather than a query flag. Comparative scorecard over
nine RH targets:

| | in top-5 |
|---|---|
| root-anchored (shipped default) | 3/9 |
| conclusion-anchored | **5/9** |

Recovered by the anchor alone: **V2 Hilbert–Pólya** (miss → rank 3) and **V8 Montgomery ~
GUE** (miss → rank 1). Nothing regressed.

### The three kinds of failure

**(A) Anchor mismatch — fixed.** Two statements conclude the same thing but carry different
hypothesis prefixes. This was V2 and V8, and it was the dominant cause across every corpus
tried today.

**(B) Missing abstraction — fixable by corpus work, and proved so.** The Z↔FF Euclidean row
never matched, because Euclidean division in ℤ says `|r| < |b|` and in `k[X]` says
`deg r < deg g`. Those are genuinely different statements. Adding a norm-shaped pair
(`r.natAbs < b.natAbs` against `r.natDegree < g.natDegree`) moved the row from never-found
to **rank 4**:

| | root | conclusion |
|---|---|---|
| natural forms | miss | miss |
| norm-shaped forms | miss | **rank 4** |

So anti-unification finds shared structure; it does **not** invent the abstraction that
makes two forms instances of one pattern. Where the unifying concept is absent from the
corpus, the row is unreachable — and adding the concept is ordinary formalization work.

**(C) The connection is a theorem, not a resemblance — out of reach in principle.** V3's
Weil half (`RiemannHypothesis ↔ ∀ f, 0 ≤ W f` against `∀ x, inter x x ≤ 2 · deg x`) and
Q5's Stein's lemma (measured on physlib: 2/12 root, 1/12 conclusion) both fail because the
two sides *do not look alike*. The mathematical content is precisely that two dissimilar
objects are nonetheless equal. No amount of structural matching reaches that; it needs the
proved-edge layer, which requires someone to have proved it first.

**This is the answer to "can we get total coverage".** No — and now the boundary is drawn
rather than guessed. (A) is an engine fix and is done. (B) is formalization work with a
demonstrated method. (C) is outside what structural analogy can do at all, and a benchmark
target of that kind measures the corpus's proof content, not the index.

### Loose ends found on the way

* `generalize()` is root-anchored only and takes no `anchor` argument, while `similar()`
  now does. Both norm-shaped statements anti-unify to `common 0` through `generalize` while
  `similar` finds them at rank 4 — the same pair, two answers, because one API saw the
  conclusion and the other did not.
* `lake build Validation` failed with "some modules have bad imports" while still emitting
  oleans, so an extraction silently used a stale one for a full run. `Validation.+` does not
  include `Validation`; the library needed a root module, exactly as the lakefile's own note
  on `FerrisHoward` warns.

## 8. Operator notation halves similarity, corpus-wide

Conclusion-anchoring (§7) did **not** rescue `g01_peano` — 2/6 in both modes — which
confirms operator indirection as a genuinely separate cause rather than a symptom. The
evidence is sharper than the earlier §3a account.

At `carriers` level, side by side:

```
g01_peano.add_comm:  a(a(c(g01_peano.add), b1), b0)                          2-arg spine
Nat.add_comm:        a(a(a(a(a(a(c(HAdd.hAdd,3,*,*,*),_),_),_),_),b1),b0)    6-arg spine
```

`add(a,b)` is a two-argument application; `a + b` elaborates to
`HAdd.hAdd α β γ inst a b`, six. Anti-unification aligns application spines positionally,
so the two cannot align — and **no erasure level repairs it.** All five levels return
identical neighbours, because erasure *holes* an argument (`*`) and never *removes* it, so
arity is preserved by construction. Holing preserves arity; only dropping changes it.

### The measured cost, and that it is not an FH artifact

| pair | retention |
|---|---|
| operator ~ operator (`Nat.add_comm` ~ `Nat.mul_comm`) | 0.860 |
| function ~ function (`Nat.lcm_comm` ~ `Nat.gcd_comm`) | 0.895 |
| function ~ function, corpus → Mathlib | 0.737 |
| **function ~ operator** (`g01_peano.add_comm` ~ `Nat.add_comm`) | **0.326** |
| **operator ~ function, both inside Mathlib** (`Nat.add_comm` ~ `Nat.gcd_comm`) | **0.395** |

Arity mismatch roughly **halves** retention — enough to drop a true match below
`min_retention` and out of top-k. The last row is the one that matters: both sides are
Mathlib declarations, so this is not about how the FH corpus was written. Commutativity of
`+` and commutativity of `gcd` are the same theorem shape, and the index scores them as
half-alike. The engine is not failing to find these pairs; it is systematically
under-ranking every one of them.

What the engine *does* find is correct and instructive: `g01_peano.add_comm`'s neighbours
are `Nat.lcm_comm`, `Nat.gcd_comm`, `Int.gcd_comm` — the commutativity family, restricted to
the members stated as plain function application. It has cleanly partitioned one
mathematical family along a notational seam.

### The fix, specified

An erasure that **drops** implicit and instance-implicit arguments from an application
spine rather than holing them, using each constant's own telescope — available in the slice,
since every constant has a row — to know which positions those are. That turns
`HAdd.hAdd α β γ inst a b` into a two-spine and aligns it with `gcd a b`.

Not implemented here. `erase.rs` carries several of CLAUDE.md's recorded traps (`outParam`
hides a sort; `Prop` is not a carrier; erasure must replace binders, never delete them), and
a new level that changes *arity* is exactly the kind of change that wants its own session
and its own ablation. The diagnosis and its cost are recorded so the change can be measured
against them.

### Conclusion-anchoring is not uniformly better

Recorded against the temptation to make it the default. `g03_order.POrder.trans` improved
(`Preorder.le_trans` alone → `le_trans`, `LE.le.trans`, `lt_of_lt_of_le`), but
`g02_group.Grp.assoc` got *worse*: root-anchored it found `inf_assoc`, `sup_assoc` — the
real associativity family — and conclusion-anchored it found `Lean.Grind.Ring.OfSemiring`
metaprogramming. Two settings, two questions, and the caller should say which.

## 9. The arity fix, simulated before building — and why it must not ship as-is

§8 specified the repair: drop implicit and instance arguments from an application spine
rather than holing them. `scripts/drop_implicit.py` simulates it as a slice transform, so it
could be measured before `erase.rs` was touched. Every constant's own row supplies its
telescope, so the positions to drop are read off the corpus rather than guessed; a constant
with no row is left alone. 131,146 statements rewritten, **0 failures**, and the two
statements at the centre of the diagnosis become structurally identical up to the
operation's name:

```
Nat.add_comm        pd(N,pd(N, a(a(c(Eq), a(a(c(HAdd.hAdd),b1),b0)), a(a(c(HAdd.hAdd),b0),b1))))
g01_peano.add_comm  pd(N,pd(N, a(a(c(Eq), a(a(c(g01.add), b1),b0)), a(a(c(g01.add), b0),b1))))
```

### The seam closes

| pair | before | after |
|---|---|---|
| function ~ operator (`g01_peano.add_comm` ~ `Nat.add_comm`) | 0.326 | **0.765** |
| operator ~ function, both Mathlib (`Nat.add_comm` ~ `Nat.gcd_comm`) | 0.395 | **0.882** |
| operator ~ operator | 0.860 | 0.882 |
| function ~ function | 0.895 | 0.882 |

Cross-notation pairs now score like same-notation pairs. The §8 diagnosis is confirmed and
the specified fix does exactly what it was specified to do.

### And retrieval gets worse in places

Rediscovery over six corpus probes went 2/6 → 3/6, but the movement is not uniform:

| probe | before | after |
|---|---|---|
| `g01_peano.add_zero` | miss | **rank 1** |
| `g03_order.POrder.trans` | rank 1 | rank 1 |
| `g02_group.Grp.assoc` | rank 1 (`inf_assoc`, `sup_assoc`) | **rank 3** (`add_div`, `div_mul_eq_mul_div`) |
| `g01_peano.add_comm` | miss (`Nat.lcm_comm`, `Nat.gcd_comm`) | miss (`Lean.Omega.LinearCombo`) |

**The cost is inherent, not a tuning artifact.** The arguments that block alignment are the
same arguments that carry discrimination: `HAdd.hAdd ℕ ℕ ℕ inst a b` drops to
`HAdd.hAdd a b`, and `Eq (f a b) (f b a)` then matches thousands of statements. Pairwise
similarity is repaired; the ranked list is noisier, because alignment and discrimination
were riding on the same four arguments.

**So the naive fix must not ship.** What it needs is a form that equalises *arity* without
discarding *identity* — normalising `HAdd.hAdd α β γ inst a b` to a two-argument
application of a symbol derived from the instance, rather than dropping to a bare
`HAdd.hAdd`. That preserves "which operation this is" while making the spine align.
Specified here, not built: it is a design with a real choice in it, and the measurement
above is what a candidate design has to beat.

This is the case for simulating before implementing. Had the drop gone straight into
`erase.rs` on the strength of the §8 diagnosis — which was correct — the retention numbers
would have looked like a clean win and the retrieval regression would have shipped with it.
