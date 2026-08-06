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

## 10. The full B7 run, and what the arity fix costs

Corpus expanded to **114 statements across ten clusters** (FF 27, Z 18, Spectral 13,
Positivity 11, Deformation 9, LFamily 9, RH 8, Counting 7, PairCorrelation 6,
ZeroDensity 6) plus 84 corpus-group controls. V4's F₁ hole is built in rather than written
around: the FF cluster states Frobenius and base-field facts that genuinely have no
number-field counterpart, and the Z cluster does not quietly acquire one.

| target | verdict | evidence |
|---|---|---|
| V1+V4 Z~FF dictionary | PASS* | 9 rows **under the simulated arity fix**; 0 rows shipped |
| V2 Hilbert–Pólya | **PASS** | spectrum-is-real at rank 3 (bar: top-5) |
| V3 Weil positivity | PARTIAL | FF-side pairing rank 1; Weil→FF link absent |
| V5 zeros control errors | **PASS** | rank 5 root, rank 4 conclusion |
| V6 reformulation cluster | PARTIAL | 2 `AssertedIff` edges; 52 sides unrepresentable |
| V7 GRH as lgg | PARTIAL | root lgg abstracts 14 positions incl. the L-function slot |
| V8 pair correlation | **PASS** | GUE density at rank 2 |
| V9 proof-shape retrieval | UNRUNNABLE | index does not exist |
| CONTROLS | **PASS** | 0/24 root, 0/48 conclusion |

**PASS=5 · PARTIAL=3 · UNRUNNABLE=1.** Nothing here is a cold run: the scorer, the
dictionary sort, the logical extractor and the anchor were all changed during the session
that produced it. Every change was driven by physlib or Mathlib measurements and no
held-out target was ever visible, but the run is not blinded and should not be scored as
though it were.

### V1's PASS is conditional, and the condition is instructive

Shipped, the Z~FF dictionary returns **0 rows at the root anchor and 1 at the conclusion
anchor** — and that single row, `norm_multiplicative ~ castelnuovo_severi`, is wrong. The
nine correct rows come from `drop_implicit.py`, the §8 arity specification simulated as a
slice transform:

| row | retention |
|---|---|
| `euclid_lemma ~ poly_euclid_lemma` | **1.00** |
| `crt ~ poly_crt` | 0.77 |
| `euclidean_division ~ poly_division_via_norm` | 0.51 |
| `int_unique_factorization ~ poly_unique_factorization` | 0.45 |
| `bezout ~ poly_bezout` | 0.31 |

That is most of V1's required row set. **And it damages V4.**
`zeta_functional_equation ~ frobenius_endomorphism` (0.47) is a false row, and
`frobenius_endomorphism` is one of the declarations V4 requires to remain unmatched as the
F₁ hole. Three of the four Frobenius statements survive unmatched so the check still
reports true, but by a narrower margin than the corpus intends.

**Two independent targets now demonstrate the same trade**: the arity transform repairs
alignment and costs discrimination. §9 saw it as a retrieval regression on corpus probes;
here it is a false dictionary row eating a deliberately-planted gap. That is a stronger
basis for the design decision than either alone, and it argues for shipping arity
normalisation as an **opt-in mode** — the way `Anchor` shipped — rather than as a default.

### Two scoring bugs found in the harness itself

* **V8 was scored FAIL while the evidence printed beside it showed a pass.** `rank_of`
  excluded same-cluster matches, and Montgomery and the GUE density are both in
  `PairCorrelation` because that target is deliberately a within-cluster pairing.
* **V7 conclusion-anchored is a degenerate success.** It reads `vars 0, retention 1.000` —
  a perfect match obtained by discarding the hypothesis, which is exactly where ζ differs
  from `LSeries`. That is the family parameter the target asks the engine to abstract, so
  the 1.000 must not be scored. V7 is therefore scored on the root anchor, and it is the
  one target where conclusion-anchoring is actively wrong.

The second is the more useful: **the anchors are not ordered.** Conclusion-anchoring wins
V2, V5 and V8, and is degenerate on V7. A default would have been wrong either way.

## 11. Correction: V1's PASS is withdrawn, and why the arity fix is inert

§10 scored V1+V4 as PASS on the strength of nine Z~FF dictionary rows. **That verdict is
wrong and is withdrawn.** The corrected verdict is PARTIAL: V4's F₁-hole check passes on
shipped behaviour, and V1's row set is 0 rows at the root anchor and 1 at the conclusion
anchor — and that single row, `norm_multiplicative ~ castelnuovo_severi`, is incorrect.

### What happened

`normalize_arity` is now implemented in the engine (`IndexConfig`, opt-in, default off) and
exposed through `similar` and `dictionary`, with the index cache keyed by
`(anchor, normalize_arity)`. It builds correctly, 83 tests pass, clippy is clean — **and it
changes nothing at all on the B7 slice.** Measured directly: identical neighbour lists with
the flag on and off, at both anchors.

The cause is a design constraint that only appears when the corpus is small:

> `implicit_positions` reads the drop map **off the slice it indexes**, because every
> constant's own row supplies its telescope. A statement-level validation corpus cites
> Mathlib constants — `EuclideanDomain.gcd`, `GCDMonoid.gcd` — whose rows are not in it. No
> row, no entry, nothing dropped.

That rule is the right one — dropping arguments of a constant whose binders the slice
cannot see would be guessing — but it means **arity normalisation is inert on any corpus
that is not closed under citation**, which is exactly what B7's corpus is.

The nine rows in §10 came from `drop_implicit.py` building its map from the merged 131k
Mathlib slice and applying it to the 198-row B7 slice. The engine cannot express that: it
has one slice and derives the map from it. So the simulation was not a preview of the
shipped fix; it was a different computation, and I reported it as though the two were the
same.

### And closing the citation gap does not rescue it either

Merging B7's clusters with the Mathlib algebra slice gives a citation-closed 131,257-row
corpus. The Z~FF dictionary then returns **0 rows in all four modes** — worse than the
198-row slice, which returned 1. So scale hurts the dictionary independently of arity, and
two separate effects were being conflated under one PASS.

### Corrected scorecard

| target | verdict |
|---|---|
| V1+V4 | **PARTIAL** (was PASS) — V4's F₁ hole named; V1's row set empty or wrong |
| V2 Hilbert–Pólya | PASS |
| V3 Weil positivity | PARTIAL |
| V5 zeros control errors | PASS |
| V6 reformulation cluster | PARTIAL |
| V7 GRH as lgg | PARTIAL |
| V8 pair correlation | PASS |
| V9 proof-shape retrieval | UNRUNNABLE |
| CONTROLS | PASS |

**PASS=4 · PARTIAL=4 · UNRUNNABLE=1.**

### The lesson worth keeping

§9 said simulating before implementing was the right discipline, and it was — but the
simulation has to be the *same computation* the implementation will perform. Mine was not,
and the difference was invisible until the Rust version ran and produced nothing. A
simulation that takes an input the engine cannot take is not a preview; it is a separate
experiment wearing the same name.

## 12. Arity normalisation: the diagnosis was right, the fix does not pay

The Rust implementation is validated against the simulation on physlib — identical
neighbour lists (`engine-on == python-sim: True`), and genuinely active
(`engine-on == off: False`). So the B7 inertness of §11 was purely citation closure, now
confirmed rather than inferred.

With that settled, the mode was measured on four corpora:

| corpus | effect |
|---|---|
| B7 validation clusters (198 rows) | **inert** — the slice is not closed under citation |
| B7 + Mathlib algebra (131,257 rows) | 0 dictionary rows in all four modes; scale breaks the dictionary independently of arity |
| corpus rediscovery, g01–g09 | 2/6 → 3/6, with regressions (`Grp.assoc` rank 1 → 3, `add_comm` neighbours degrade) |
| physlib quantum key (14,563 rows) | **neutral** — 3/5 hits either way; cross-field noise 9% → 7% at root, 10% → 10% at conclusion |

**So the §8 diagnosis was correct and the fix it implied does not pay.** Operator notation
really does halve retention across the seam — that measurement stands, and it is a genuine
property of the index worth knowing. But *repairing* the arity mismatch does not improve
retrieval on any corpus tested: it is inert where the corpus cannot supply the map, mixed
where it can, and neutral at scale.

The reason is the one §9 identified and did not take seriously enough: the arguments that
block alignment are the arguments that carry discrimination. Removing them helps the
pairwise number and leaves the ranking with less to work with, and those two effects very
nearly cancel.

`normalize_arity` therefore ships **off by default and stays a mode**, documented with these
numbers rather than with the retention table that motivated it. The retention table was
true and it was not sufficient: a pairwise metric improving is not a retrieval system
improving, and this is the second time in the session that distinction has mattered — the
first being §9's regression under the same change.

### What would be worth trying instead

Not more normalisation. The seam is real but closing it is a wash, so the ranking's problem
is elsewhere: on every corpus tried, the limiting factor was `min_retention` discarding true
pairs whose retention is genuinely low (0.04–0.15) because the *statements* are large
relative to what they share. A length-normalised or rank-based score would address that
directly, and unlike arity normalisation it has not been measured.

## 13. The scoring function, measured against ground truth

Every failure in this session shares a signature: a true pair exists, scores 0.04–0.24
retention, and is discarded by the floor. `euclid_lemma ~ poly_euclid_lemma` is a perfect
conceptual match at **0.04**. So the suspect is `retention` itself, which divides shared
structure by the **larger** side — penalising a pair for being verbose rather than for being
dissimilar.

The node counts show how extreme that is: `Z.euclid_lemma` is **65 nodes**,
`FF.poly_euclid_lemma` is **1,059** — sixteen times larger for the same mathematics, because
`Polynomial (ZMod p)` machinery bloats every FF statement. `gcd_comm` against
`poly_gcd_comm` is 39 against 391.

Six candidate scores were compared by ROC AUC at separating labelled-true pairs from random
ones, on two corpora with **independently sourced labels**: B7's deliberately-parallel Z/FF
statements (which I wrote, so they carry authorship bias) and Mathlib's own families —
`Nat.add_comm ~ Nat.mul_comm`, `Nat.le_trans ~ Int.le_trans` — which I did not.

| score | B7, conclusion-anchored | Mathlib, root | Mathlib, conclusion |
|---|---|---|---|
| **min-normalised `s/min(a,b)`** | **0.933** | **1.000** | 0.950 |
| retention (current) | **0.756** | **1.000** | 0.991 |
| common (raw) | 0.943 | 0.991 | **0.762** |
| `s/√(a·b)` | 0.901 | 1.000 | 0.985 |
| Dice `2s/(a+b)` | 0.850 | 1.000 | 0.990 |

### The finding, and the claim it replaces

A first pass on B7 alone showed raw `common` beating retention by 0.19 AUC, and that reading
is **withdrawn**: on Mathlib's labels raw `common` is the *worst* score (0.762). It won on B7
for a regime-specific reason and would have been a bad change.

What survives the control is sharper:

> **`retention` is perfect on size-symmetric pairs and collapses on asymmetric ones.**
> `Nat.add_comm ~ Nat.mul_comm` are the same size, so dividing by the larger side costs
> nothing — AUC 1.000. `euclid_lemma ~ poly_euclid_lemma` are 65 against 1,059 nodes, and the
> same division destroys the signal — 0.756.

Cross-theory analogy is *exactly* the asymmetric regime, because the same claim carries
different amounts of type and instance machinery in different theories. So the metric is
weakest precisely where the Atlas's differentiating query lives.

**`min-normalised` never drops below 0.933 in any regime.** That is the recommendation — not
because it wins everywhere (retention edges it 0.991 to 0.950 on Mathlib conclusion-anchored)
but because it is the only candidate that never fails. Retention loses 0.24 AUC in the hard
regime; min-normalisation loses 0.04 in the easy one.

Also worth recording: **root-anchored, every score sits at ~0.42 on B7 — below chance.** The
binder-prefix mismatch collapses true pairs to `common 0`, so no scoring function can
recover them. Anchoring and scoring are independent problems and the anchor has to be fixed
first for the score to matter at all.

### Caveats

21 and 20 labelled pairs respectively — small. The B7 labels are mine; the Mathlib ones are
not, which is why the disagreement between the two sets is the informative part. Neither set
was used to fit anything. Not yet measured on physlib, and not yet implemented: this is a
measurement recommending a change, not the change.

## 14. The scorer is pluggable now — and it is not where the leverage is

`SimilarityScore` ships in `IndexConfig` with six formulas (`retention`, `min_normalised`,
`dice`, `jaccard`, `geometric_mean`, `common`), exposed through `similar` and `dictionary`.
`Generalization` now carries `left_size`/`right_size` so any formula can be written; the
floor `min_retention` applies to whichever score is selected, because flooring on one and
ranking on another would discard exactly the pairs a different scorer exists to rescue.
`ScoreFactors` reports both `retention` (always the classic formula, so runs stay
comparable) and `base` (what actually multiplied into `total`).

### §13's recommendation is withdrawn

§13 compared formulas by ROC AUC over `generalize` on labelled pairs and recommended
`min_normalised` (AUC 0.933 against retention's 0.756). **Measured by retrieval instead —
rank of the true partner in `similar(query)` — it is the worst of the six:**

| scorer, conclusion-anchored | MRR on B7 |
|---|---|
| `common` | **0.256** |
| `dice` / `jaccard` / `geometric_mean` | 0.210 |
| `retention` | 0.191 |
| `min_normalised` | **0.164** |

The reason is visible once stated: dividing by the *smaller* side is generous to **all**
size-asymmetric pairs, not only true ones, so it promotes small irrelevant candidates into
the ranking. A pairwise-versus-random AUC cannot see that, because the random pairs are not
asymmetric in the same way the true ones are.

**That is the third time this session a pairwise improvement failed to survive contact with
retrieval** — after §9's arity transform and §12's null result. The lesson is now
overdetermined: a scorer's job is to rank candidates for a query, and only a ranking
measurement can tell whether it does.

### On independent labels the choice barely matters

Mathlib's own families (`Nat.add_comm ~ Nat.mul_comm`, `Nat.le_trans ~ Int.le_trans`, the
`g01_peano` cross-notation pairs), 18 pairs over the 131k slice:

| anchor | MRR across all six scorers | recall@5 |
|---|---|---|
| root | 0.217 – 0.264 | 0.39 |
| **conclusion** | 0.286 – 0.300 | **0.56** |

All six conclusion-anchored scorers return **identical recall@5**, and the MRR spread is
0.014 — noise at this sample size. The *anchor*, by contrast, moves recall@5 from 0.39 to
0.56 consistently and moves MRR by ~0.04.

**So the scoring formula is not the lever; the anchor is.** The pluggable infrastructure
earned its place by establishing that, which is worth more than a marginal default change
would have been — and it means the next question is recall, not ranking: even at the best
setting, 44% of known-true partners never appear in the top 20 at all.

## 15. Scoring may be the wrong interface entirely

Eight formulas were implemented and benchmarked by retrieval (`SimilarityScore` is now
pluggable: `retention`, `min_normalised`, `dice`, `jaccard`, `geometric_mean`, `common`,
`info_weighted`, `info_dice`). Every one lands between **MRR 0.16 and 0.30**, with the
spread on independent labels inside noise. Two further attempts to find better mathematics
both failed:

* **`min_normalised`**, §13's recommendation on pairwise AUC, is the *worst* by retrieval
  (MRR 0.164 on B7 against retention's 0.191) — dividing by the smaller side is generous to
  **all** asymmetric pairs, not only true ones, so it promotes small irrelevant candidates.
* **Information weighting** — `W(t) = Σ ln(N/df(sym))`, so a shared `Eq` counts for nothing
  and a shared `riemannZeta` counts for a lot, which is the principled answer to "why divide
  by node count at all" — scores 0.248 MRR at 131k against retention's 0.293. It does reach
  the **highest recall@10 of any configuration (0.72)** while having the lowest recall@5
  (0.39): it *finds* more true pairs and *ranks* them worse.

That last split is the tell. When retrieval and ranking disagree that sharply, the number is
what is in the way.

### The structural argument

Anti-unification computes a **pattern** — `?R a b → ?R b c → ?R a c` — plus the
substitutions specialising it to each side. That is the structural content. The pipeline
collapses it to one float and sorts, discarding *how* two statements are alike and keeping
*how much*, which is the weaker question. And every result in this session that survived
scrutiny came from exact structure rather than a score: statement identity
(`POrder.refl ≡ Preorder.le_refl`), proved `Iff` edges, aggregate frontier similarity.

### Grouping by shared pattern, measured

`scripts/structure-groups.py` partitions a query's candidates by the skeleton each shares
with it — no floor, no formula, no `k`.

`g01_peano.add_comm`, the query that failed under **all eight scorers**:

```
[7 members, 12 shared nodes]  lcm_comm, gcd_comm, gcd_comm, lcm_comm, or_comm, and_comm …
     pattern: a(a(a(c(Eq,*),?0), a(a(?1,b1),b0)), a(a(?1,b0),b1))
```

The pattern is `?1 a b = ?1 b a` — commutativity with the operation abstracted — and the
family is returned as one labelled group, with the six unrelated matches isolated as
singletons.

| query | candidates | groups |
|---|---|---|
| `Nat.add_comm` | 60 | **3** (add_comm family 13; mul_comm family 43; or/and/xor 4) |
| `g03_order.POrder.trans` | 60 | 12, led by `le_trans, trans, ge_trans'` |
| `g01_peano.add_comm` | 13 | 7, led by the commutativity family |
| `Nat.gcd_comm` | 43 | 23 — the fragmented case, so quality varies |

**Three things a score cannot give.** *Compression*: 60 candidates become 3–12 groups, a
5–20× cut in triage load, which is what an agent reading thousands of candidates needs.
*The reason*: each group carries its pattern, so a whole family can be accepted or discarded
at a glance. *No constants*: two statements either share a pattern or they do not.

The operator/function seam is unchanged — `Nat.add_comm` still does not reach
`g01_peano.add_comm` — but the structure is now visible rather than averaged into a float.

**This is the strongest candidate for the interface the Atlas should expose**, and it
inverts the design's assumption that `similar` returns a ranked list. It should return a
partition.

## 16. What actually produces structural insight — and it is not a score

`SkeletonIndex::motifs` now reads the posting lists as an inventory rather than a prefilter
(bound as `Corpus.motifs`). Each key is a subterm and its list is the family of declarations
containing it — a corpus-wide pattern inventory the ranking builds anyway and then throws
away.

Three attempts, and the third works.

**Whole-statement grouping, corpus-wide: dead.** Mean family size **1.00** at `exact`,
`presentation`, `instances` and `carriers`; 1.22 at `shape`, whose largest families are
same-subfield sibling lemmas with 17,000-node patterns. Real theorems are structurally
unique, which is why query-driven grouping (§15) worked — the lgg *with a query* is a
projection, far coarser than a statement's own skeleton.

**Raw motif mining: scaffolding.** Ranked by `size × log(family)`, the top motifs are
40,000-node tensor contractions from six-member single-subfield families, plus every nested
sub-motif of each. Re-ranked for cross-subfield reach, they become `noConfusionType`,
`sizeOf_spec`, `injEq`, `ext_iff` and bare application spines like
`a(a(a(a(_,b8),b7),b6),b5)`. **That is the sixth layer this session where shared structure
across theories turns out to be punctuation** — after `walls`, `busiest_heads`, `similar`,
`classes`, `dictionary` and `frontier`.

**Motifs filtered by structural derivativeness: real physics.** Applying §3b's measure
(AUC 0.899, no name matching) to the family members, then requiring ≥3 subfields and ≥60%
authored members:

| motif | members | subfields | purity | family |
|---|---|---|---|---|
| 35-node | 38 | 8 | 88% | `lagrangian_eq`, `trajectory_energy`, `twoState_probability_fst` |
| 37-node | 29 | 8 | 83% | `heatCapacity_eq_deriv_mean`, `meanEnergy_eq_neg_deriv_log` |
| 17-node | 27 | 7 | **93%** | `trajectory_acceleration`, `toInitialConditions_velocity` |
| 33-node | 35 | 6 | 85% | `fieldStrength_basis_repr`, `distTensorDeriv_basis_repr` |
| 13-node | 20 | 8 | 71% | `helmholtzFreeEnergy_congr`, `partitionFunction_congr`, `μBolt_congr` |

The second is **derivative-of-a-thermodynamic-potential**, spanning QuantumMechanics,
SpaceAndTime, Electromagnetism, StatisticalMechanics, ClassicalMechanics and
Thermodynamics. The fourth is the **basis-representation** family bridging Electromagnetism
(13 members) and Relativity (12).

### The recipe, and what it says about the design

1. partition by shared sub-pattern — the posting lists, no formula;
2. filter members by structural derivativeness — §3b, no names;
3. require reach across ≥3 subfields;
4. require family purity ≥60%.

**No similarity score anywhere.** Eight formulas were implemented, benchmarked and found to
sit within noise of each other (MRR 0.16–0.30); the one thing that consistently mattered was
the anchor, and the thing that finally produced legible structure was discarding ranking
altogether.

That is an argument about the interface, not about tuning: `similar` returning a ranked list
of neighbours is the wrong shape for this problem. It should return a **partition into
labelled families**, and the corpus-level query should return an **inventory of motifs**,
filtered for authored content. The scoring machinery is still needed — something must
shortlist candidates — but as a retrieval prefilter, not as the answer.

## 17. Correction to §16, and what the control says about the thesis

§16's motif recipe required families to span ≥3 subfields, and reported five that did as
evidence of cross-field structure. **A label-shuffle control refutes that reading.**

Permuting which subfield each declaration belongs to (preserving every subfield's size
exactly) and re-running the identical filter:

| labels | motifs passing |
|---|---|
| genuine | **813** |
| shuffled, 8 runs | 5,221 – 5,570 (mean **5,388**) |

Real labels pass **6.6× less often than chance**. The criterion was selecting *against* the
thing it was meant to find.

The reason is that cross-subfield reach is the null, not the signal. With 6,082 authored
physics theorems over 22 subfields, a family drawn at random spans:

| family size | expected distinct subfields |
|---|---|
| 5 | 4.04 |
| 10 | 6.47 |
| 20 | **9.23** |
| 40 | 11.89 |

So §16's "38 members across 8 subfields" is *below* expectation for its size. Every family
highlighted there was less cross-field than chance.

### Scored against a size-matched null instead

Ranking families by observed minus expected spread — filtering nothing, per the
recall-over-precision rule:

| direction | best deviation | family |
|---|---|---|
| most cross-field | **+1.58** | `deriv_meanEnergyBetaReal`, `mathematicalPartitionFunction`, `expectedValue_eq_inner` (Channels/States/Entropy/StatMech/SpaceAndTime) |
| most concentrated | **−11.62** | `rep_apply_basis`, `rep_toMatrix`, `rep_apply` — 49 members, *all* Relativity |
| | −11.32 | `HasDenseDomain`, `isUnbounded_iff_isClosable`, `closure` — 45 members, all QuantumMechanics |

**The asymmetry is the finding.** Excess cross-field spread tops out at +1.58 subfields,
barely above noise. Excess *concentration* reaches −11.6, an enormous deviation, and the
families it identifies are genuinely coherent mathematics: the Lorentz group's
representation lemmas; unbounded-operator domain theory.

### What this says about the premise

atlas.md's thesis is that the value lies in cross-theory structure — "same shape in two
theories, no traffic between them". Measured against a size-matched null on a real physics
corpus, **that signal is close to absent, while the opposite signal is very strong**:
mathematics clusters hard, and what structural analysis detects reliably is coherence
*within* a field.

This does not refute the thesis — a 22-subfield physics library is not the regime atlas.md
predicts novelty in ("a scale phenomenon, emerging over 400k+ declarations"), and B7's V2
did find Hilbert–Pólya once anchoring was fixed. But it is the first measurement in this
session to test the premise directly with a control, and it comes back negative. Any future
cross-field claim from this engine needs a size-matched null attached, because the naive
version of that claim is satisfied by chance more often than by structure.

### Method note

§16 stands as a worked example of the failure mode the recall rule warns about: a filter
that *narrows* output manufactured a false negative rate of 6.6×, and nothing in the output
itself revealed it. Only the shuffle did. Filters need controls; rankings mostly do not.

## 18. The concentration asymmetry holds on Mathlib too

The §17 measurement repeated on the 131k Mathlib slice — 13,720 authored theorems across
nine depth-2 theories, same null-corrected method:

| corpus | theories | expected spread at k=20 | max excess **spread** | max excess **concentration** |
|---|---|---|---|---|
| physlib | 22 | 9.23 | **+1.58** | **−11.62** |
| Mathlib | 9 | 3.81 | **+0.86** | **−3.17** |

Concentration deviates from chance 3.7× to 7.4× harder than cross-theory reach does, on both
corpora. So this is a property of formalized mathematics as organised, not an artifact of
physlib's subfield boundaries.

What the two ends contain is also consistent. Mathlib's most cross-theory motif (+0.86, four
theories against 3.14 expected) is a grab bag — `prodCongrLeft_symm`, `compl_singleton`,
`cast_abs`. Its most concentrated (−3.17) is **69 members sharing a 17-node motif, all in
`Mathlib.Algebra`**: `add_neg`, `neg_add_eq_iff_eq_add`, `add_eq_zero`,
`mul_eq_one_iff_eq_one` — Mathlib's `to_additive` correspondence, which CLAUDE.md already
records as what shape-identity finds.

### Consequence for two shipped queries

`frontier` and `dictionary` are both premised on cross-theory structure being the valuable
signal. Neither has a size-matched null, so neither can currently distinguish a real
cross-theory family from the chance level — and the chance level is high: a 20-member family
spans 9.23 of physlib's 22 subfields *by default*. §2 recorded `frontier` returning the
inverse of its design on Mathlib and §3c recorded it returning a units-API duplication on
physlib; this is the underlying reason, stated quantitatively for the first time.

Both should report observed-minus-expected rather than raw similarity. That is a small change
and it is the difference between a claim and a number.

### What is *not* claimed

That cross-theory analogy does not exist. B7's V2 found Hilbert–Pólya at rank 3 once
anchoring was fixed, and that is a genuine cross-cluster hit. The claim is narrower and
better supported: **at corpus scale, aggregate cross-theory structure is indistinguishable
from chance on both corpora tested, while within-theory coherence is a very strong signal.**
Individual cross-theory pairs can still be real; it is the *aggregate* queries built on the
assumption that need a null.

## 19. `frontier` now has a null, and it changes the answer

Under random assignment of shapes to theories, `E|A ∩ B| = |A||B|/M`, so `frontier`'s
`similarity = |A ∩ B| / min(|A|,|B|)` has expectation `max(|A|,|B|) / M`. A large theory
therefore has high expected similarity with **everything** — which is precisely why the
uncorrected query kept returning the biggest theory pairs. `Frontier` now carries
`expected_similarity` and `excess`, and ranks on excess.

| corpus | pair | sim | expected | excess | cites |
|---|---|---|---|---|---|
| physlib | `ClassicalMechanics ~ Thermodynamics` | 0.500 | 0.046 | **+0.454** | 0 |
| physlib | `SpaceAndTime ~ Thermodynamics` | 0.553 | 0.128 | **+0.425** | 0 |
| physlib | `Electromagnetism ~ Thermodynamics` | 0.447 | 0.065 | **+0.382** | 0 |
| Mathlib | `Mathlib.Algebra ~ Mathlib.Order` | 0.040 | 0.366 | **−0.326** | 1508 |
| Mathlib | `Mathlib.Algebra ~ Mathlib.Logic` | 0.011 | 0.366 | **−0.354** | 331 |

**physlib's top pairs are genuinely enriched — ten times chance, with zero cross-citation.**
(§3c established what they contain: one units API replicated per physical dimension. Real
duplication, correctly detected, and a library-design finding rather than a physics one.)

**On Mathlib every theory pair is *below* chance.** `Mathlib.Algebra ~ Mathlib.Order` was
the frontier's top result before this change and is now reported as 0.326 below what two
theories of those sizes share by accident. §2 recorded that ranking as "the inverse of its
design" without being able to say why; the null says why, and says it in the output rather
than in a footnote.

This is the §17–§18 finding made operational: the query no longer needs a reader to know
that cross-theory reach is the null. It reports the deviation, which can be negative, and
usually is.

## 20. Nulls help at the theory level and are useless at the row level

Two things about `dictionary_shuffle_control`.

**A reporting trap, not a bug.** It returns all zeros when `rights.len() < 2 || rows.is_empty()`,
so on B7's empty Z~FF dictionary it printed `genuine 0.000 vs shuffled 0.000, separation
0.000` — which reads exactly like "ran and found no separation" and actually means "did not
run". `pairs: 0` does signal it and my reporting scripts dropped that column, so the error
was mine; but this is the same "we did not look versus there is nothing there" confusion that
`flex_head_sides` and `same_head_sides` exist to prevent, and the control invites it.

**Where it does run, it works — and a much stronger null adds nothing.** On physlib's
`ClassicalMechanics ~ QuantumMechanics` (178 rows): shipped control `pairs=169,
genuine 0.763, shuffled 0.049, separation 0.976`. Replacing its single deterministic
alternative with a per-row null — each left scored against 60 random rights from the target
theory — gives z-scores of **+6.9 to +14.9, mean +13.59, and 12 of 12 rows beyond 2σ**.

Overwhelming, and worthless. The rows it certifies are:

```
mass_pos ~ ξ_pos    k_pos ~ ξ_pos    m_pos ~ ξ_pos    period_pos ~ ξ_pos
ω_pos ~ ξ_pos       property ~ ξ_pos val_pos ~ ξ_pos  inj ~ inj (retention 1.00)
```

Seven distinct lefts collapsing onto one right — "this positive constant is positive" — and
an auto-generated injectivity lemma. Every one is a 14-sigma outlier against random pairing.

### The asymmetry, which is the finding

* **At the theory level a null was decisive** (§19): it inverted `frontier`'s answer, turning
  Mathlib's top-ranked pair into a −0.326 deviation. The thing being tested there — "is this
  pair more alike than two theories of these sizes would be" — is genuinely a statistical
  question, and size was a real confound.
* **At the row level a null is uninformative.** "Is this pair more alike than a random pair"
  has answer *yes* for any two statements of the same shape, so every row passes. The
  question that matters — is this a meaningful mathematical correspondence — is not
  statistical, and no amount of sampling turns it into one.

So the shuffle control should be read as a *sanity check that the pipeline is not emitting
noise*, which is what it was designed for, and never as evidence that a row means something.
The 0.976 separation on a dictionary whose top rows are seven copies of "a positive constant
is positive" is the clearest possible statement of that limit.

What would discriminate at the row level is not a better null but the **derivativeness**
filter of §3b (which removes `inj ~ inj`) and a **collision** penalty (which removes six of
the seven `ξ_pos` rows) — both already exist and neither is applied inside `dictionary`.

## 21. A dictionary is 96% collisions, and the magnets are diagnosable

`dictionary_coherence` on physlib, default assembly:

| pair | rows | lefts | rights | contested | rows in collision |
|---|---|---|---|---|---|
| `ClassicalMechanics ~ QuantumMechanics` | 169 | 74 | 44 | 36 | **162 (95.9%)** |
| `Electromagnetism ~ Relativity` | 105 | 51 | 54 | 19 | 74 (70.5%) |

`dictionary_policies` shows what the trade costs: `unconstrained` 169 rows at collision
0.959; `injective` 39 rows at collision 0.051 with 35 lefts left unmatched.

**The collision magnets are the same two families that have dominated every layer:**

| target | lefts claiming it | what it is |
|---|---|---|
| `noConfusion` (×3 distinct) | 14 each | auto-generated |
| `ξ_pos`, `hm`, `hω` | 9, 7, 7 | content-free — "this constant is positive" |
| `CoVector`, `Vector` | 7 each | bare type definitions |
| `pos`, `val_pos`, `val_nonneg` | 6 each | content-free |

Neither family is hard to identify. §3b's derivativeness measure (AUC 0.899, no name
matching) removes the first; a per-right cap removes the second, and the policy machinery
for it **already exists** — `dictionary_policies` computes the `many_to_one_3`,
`many_to_one_2` and `injective` frontier, and the default assembly uses none of them.

So `dictionary`'s output quality is not blocked on a missing capability. It is blocked on two
existing capabilities not being connected to it — the same shape as §10's finding that
`dict.rs` sorted by `retention` while `Row::score` existed and went unread.

**And this is what the shuffle control cannot see.** §20 measured separation 0.976 on the
very dictionary that is 95.9% collisions and whose top rows are seven copies of "a positive
constant is positive". The control asks "is this better than random pairing" and the answer
is yes, overwhelmingly, for output nobody would want. Coherence and derivativeness are the
measurements that discriminate; the null is not.

## 22. `max_per_right`: a dictionary that is actually a map

`DictOptions::max_per_right` caps how many lefts may claim one right. Setting it switches
assembly from greedy-per-left to **global best-first**, because greedy hands a contested
right to whichever left the iteration reached first — alphabetical order, not a judgement.
Default `None` preserves historical behaviour.

Measured on physlib, `ClassicalMechanics ~ QuantumMechanics`, `per_decl=3`,
conclusion-anchored:

| cap | rows | distinct lefts | distinct rights |
|---|---|---|---|
| none | 178 | 81 | 43 |
| 3 | 101 | 56 | 43 |
| 2 | 78 | 45 | 43 |
| 1 | **43** | 26 | **43** |

**The right theory's coverage is untouched at every cap** — 43 distinct rights throughout —
so the cap removes redundant claims rather than content, and the top-scoring rows are
identical in every setting because the best claim wins each contest by construction.

That converts §21's finding into a switch: a 95.9%-collision "dictionary" becomes an
injective one at the cost of 135 duplicate rows, and `dictionary_policies` already reported
this frontier before the assembly could act on it.

## 23. `honesty` was blind to the genre B7 mandates

Found by a parallel probe. `honesty` reports, for each non-whitelisted axiom, the
declarations that **rest on** it — `impact(axiom, Proof)` — and `impact` excludes the seed.
On B7's validation clusters, 113 of 114 declarations are `axiom` and every one is a graph
leaf, so impact was empty and the scan reported **zero findings on a corpus consisting
entirely of unproved assertions**.

`atlas-validation.md` §2 mandates exactly that genre — "statement-level formalization only,
no proofs required, the Formal Conjectures genre" — so the scan was blind precisely where it
is most needed. It is the failure CLAUDE.md names for B3: *a tool that says everything is
fine is worse than no tool.*

The fix is one line of intent: an axiom outside the whitelist **is itself** the finding, and
its users are the propagation.

| slice | before | after |
|---|---|---|
| B7 (113 axioms) | **0** | **117** — 113 of them the `Validation.*` axioms |
| physlib | 18 | 18 — unchanged, no declared axioms, all `sorryAx` |
| Mathlib + corpus | 8 | 19 — the 11 new ones are Mathlib's own non-whitelisted axioms |

No false-positive inflation: the increase is exactly the axioms that were previously
invisible. The negative control remains healthy (104,791 findings on an empty whitelist over
Mathlib), so the scan was always live — it simply could not see a leaf.

**Why this matters beyond the bug.** C5's honesty scan is what the project points at when
asked whether a result is real. Every B7 run in this session reported its corpus as clean,
and every one of those reports was vacuous. Any anti-cheat claim made from a statement-level
corpus before this fix should be re-read as "not measured".

## 24. `transport` — the "active operation" — has never done anything

Found by a parallel probe and confirmed independently. atlas.md calls `transport` "the
active operation": apply a dictionary row's substitution to a new statement and dispatch the
image to search, falsification, or a prover. Measured on physlib before any change:

* **1,074 of 1,074** successful transports returned `.name == row.right`
* **32 of 32** rows produced exactly **one** image across hundreds of distinct subjects
* that image equalled `skeleton(row.right, "carriers")` in **32 of 32**
* `.exists=False` — the open target, the entire point — **0 times**

Verified by hand: six unrelated subjects (`ext`, `ext_iff`, `inj`, `injEq`, `sizeOf_spec`,
`acceleration_eq_of_equationOfMotion`) produce one identical image.

**The mechanism.** The image was built as `sub_right.get(k).unwrap_or(subject_value)`.
`sub_right` is obtained by matching the skeleton against the row's right, so it binds
*every* variable in that skeleton and the fallback is dead code. `image_subst` equalled
`sub_right` identically and the image was always `row_right`. The row's left was never
matched at all — used only to derive the skeleton — so the correspondence the row asserts
was never constructed.

Fixed: match the left too, and move a hole only where the subject fills it the way the left
does. Distinct images per row went **1.0 → 15.9**, and `image == row.right` fell from 100%
to 2%.

### And it still produces nothing

| | before | after |
|---|---|---|
| image == `row.right` (ignores the subject) | **100%** | 2% |
| image == subject (ignores the row) | 0% | **98%** |
| genuinely new image | **0%** | **0%** |
| open targets | 0 | 0 |

Zero open targets at every erasure level (`exact` through `shape`).

**The remaining problem is the design, not the code.** A row's correspondence is defined at
specific hole-fillings — "where the left had `L_k`, the right has `R_k`". An arbitrary
subject matching the same skeleton fills those holes with different values, so the mapping
never fires; it fires only when the subject *is* the left, which is the 2%.

For transport to do what atlas.md describes, a row has to be **lifted to a rewrite on
constants** — `ℤ ↦ Polynomial (ZMod p)`, `gcd ↦ EuclideanDomain.gcd` — and applied
throughout the subject. A hole-level substitution has no purchase on a statement it was not
derived from. That is a different object from what `dictionary` currently emits, and
building it is the prerequisite for every downstream claim atlas.md makes about transport:
the three-way dispatch, the located analogy boundary, the directed research target.

**Retroactively:** B7's V-targets that involve transport, and every `atlas transport`
invocation in this project's history, returned the row's right-hand side. None of them
were measurements.

## 25. Twelve parallel probes — four corrections and two large defects

Run as independent read-only measurements. Each reproduced the engine's own numbers as a
control before reporting anything.

### (a) "Flex head" is not higher-order, and I was wrong to say it was

§14 and every summary since treated the 18,139 unrepresentable sides as needing
higher-order matching. **They do not.** Of 18,943 unkeyable sides on Mathlib: **Pi 18,579
(98.1%)**, BVar 359 (1.9%), Let 5, and zero Lam/Proj/Sort. Physlib: Pi 1,820 of 1,824
(99.8%). A "flex head" side is overwhelmingly a side that is *itself* `∀`/`→`, which
`key_of` rejects only because `spine` unwraps `App` and stops.

The single most common shape is `Eq/3 ↔ ∀∀. Eq/3` — 319 statements, 25.9% — and with
`Eq/3 ↔ ∀. Eq/3` the `funext`/`ext_iff` family is **33.4%** of the bucket.

Two named extensions, measured:

| extension | Mathlib Iff recovered | physlib | B7 | edge change |
|---|---|---|---|---|
| **first-order descent** (key a quantified side as `(binder count, matrix head/arity)`) | **72.0%**, 79.2% with a `∀/2` fallback | **100%** | **4/4** incl. `rh_iff_all_zeros_real` | 4,330 → 5,306, **+22.5%** |
| higher-order matching (bound-variable head as `?F/n`) | 5.3% | **0** | **0** | +1.5% |

**Do not build higher-order matching.** The blocker is a first-order change to `key_of`.
323 statements do have a genuinely higher-order side, but 258 of those can only key to a
wildcard naming nothing, so they yield no traversable edge anyway.

### (b) The prefilter loses far more than recorded

CLAUDE.md records recall loss as "189 true neighbours missed, 63 (33.3%) never proposed by
the prefilter and 0 buried by the ranking". Re-measured at truth-depth 50 on the merged
slice, two seeded 30-query arms:

| | all theorems | Mathlib theorems |
|---|---|---|
| overlap of index vs brute top-50 | **26.2%** | 26.0% |
| lost by the **prefilter** (never proposed at any depth) | **64.1%** | **73.9%** |
| lost by the ranking (proposed, buried past 50) | 9.8% | 0.1% |

The direction of CLAUDE.md's claim survives — the ranking loses almost nothing — but the
prefilter loss is roughly double what is recorded, and **the missed candidates are not
marginal**: median retention 0.566, and 90 of them retain >80% of the query's structure.

### (c) The erasure levels are a real dial

An earlier one-query probe found all five levels identical and I flagged the dial as
possibly decorative. Over 40 Mathlib queries the mean top-10 Jaccard between adjacent levels
is 0.952 / 0.828 / 0.847 / 0.607, all five agree on the top-10 *set* for only **5/40**
queries and on the *order* for **1/40**, and mean distinct top-10 sets per query is 2.80.
The dial works; my earlier sample was one atypical query.

### (d) Equivalence classes are not mostly boilerplate

Applying the §3b derivativeness filter at a 45% budget leaves **87.3%** of `instances`
classes and **88.6%** of `carriers` classes with ≥2 authored survivors. The negative control
is the informative part: a *random* 45% drop leaves only 499 and 847 classes against the
targeted filter's 1,243 and 1,873 — the filter is **2.2–2.5× less destructive than chance**,
which is what a filter that removes boilerplate rather than content should look like.

### (e) Derivativeness transfers across corpora

Fitted on one corpus, evaluated on the other, with zero name overlap between them:

| direction | strict transfer AUC | in-corpus baseline | delta |
|---|---|---|---|
| physlib → Mathlib | 0.849 | 0.886 | −0.037 |
| Mathlib → physlib | 0.842 | 0.899 | −0.057 |

Permuted-label control transfers at 0.531 / 0.421, i.e. chance. Against a pre-registered
"general" bar of baseline − 0.05 in **both** directions it lands PARTIAL by 0.007 in one
direction — so the measure is close to a general property of formalized mathematics rather
than a per-library fit, and should be reported that way rather than as 0.899.

### (f) Kernel confirmation is barely predictable, and the best predictor is a name

Over the 268 kernel-adjudicated home candidates (52 CONFIRMED / 216 REFUTED): the strongest
feature is `name_dots` at |AUC| **0.683** — a *name* artifact — against a permutation null
whose 95th percentile is 0.607. The best structural feature is `n_instance_binders` at
0.642. So there is a weak real signal, and no structural feature beats counting dots in a
name. Confirmation cannot currently be predicted without calling the kernel.

### (g) A second transport defect

`dictionary` computes `row.transportable` at `anchor="conclusion"` while `transport`
re-generalizes at the root — `generalize_named` takes no anchor. **33% (CM~QM) and 11%
(EM~Rel) of rows labelled transportable raise `ScopedRow` for every subject.** The label and
the operation disagree about which term they are describing.

## 26. First-order descent shipped, and V6 completes

`key_of` now descends through a quantifier prefix and keys the matrix as
`(∀depth.head, arity)`. Measured across all three corpora:

| slice | flex sides | Iff edges |
|---|---|---|
| Mathlib | 18,130 → **900** (−95%) | 4,330 → **5,217** (+20.5%) |
| physlib | 1,758 → **31** (−98%) | 261 → **332** (+27%) |
| B7 | 3 → 1 | 4 → **8** |

The binder count stays in the key: `Eq/3` and `∀².Eq/3` are different claims, and merging
them would put a pointwise equation and an extensionality lemma on one node.

### V6's cluster now assembles

All six B7 reformulation edges resolve, including the two that were missing:

```
rh_iff_lambda_nonpos    RiemannHypothesis/0 ~ LE.le/4
weil_criterion          RiemannHypothesis/0 ~ ∀1.LE.le/4      (was absent)
rh_iff_all_zeros_real   RiemannHypothesis/0 ~ ∀2.Eq/3         (was absent)
symmetric_iff_inner     LinearMap.IsSymmetric/6 ~ ∀2.Eq/3
matrix_psd_iff          Matrix.PosSemidef/6 ~ ∀1.LE.le/4
```

RH, `Λ ≤ 0` and the Weil criterion all attach to `RiemannHypothesis/0` — V6's first half.

### And its second half is computable

V6 also requires `Λ ≥ 0` to surface as an *adjacent non-member*, sharpening `Λ ≤ 0` into
`Λ = 0`. That is not an edge — `lambda_nonneg : 0 ≤ Λ` is a fact, not a relation — so
`logical.rs` correctly emits nothing for it. But it is computable as: **declarations whose
conclusion heads a node in the cluster while contributing no edge.**

Run over B7: the RH cluster spans 6 nodes with 5 edge-contributing members, and the
adjacency query returns 10 non-members — with `Deformation.lambda_nonneg` heading `LE.le/4`
among them, which is exactly the item the target names.

The other nine mostly head `∀2.Eq/3` (`Z.gcd_comm`, `Z.euler_product`, `Succ.injEq`) — a
generic hub. Ranking adjacency by the *specificity* of the node headed (its IDF) would put
`lambda_nonneg` first, since `LE.le/4` is far rarer than `∀2.Eq/3`. That is the same
observation as §16's: shared structure at a generic node is punctuation, and the fix is to
rank rather than filter.

### Scoring correction

V6's verdict was emitted as `PARTIAL if any edge exists`, which can never be wrong and
therefore never meant anything. It now tests the two halves separately — cluster assembled
(RH~Λ **and** RH~Weil), and sharpening surfaced — so the PARTIAL it currently returns is
earned: the cluster assembles, and the sharpening is computable but not yet a shipped query.

## 27. Do we have anything? 29 generalizations Mathlib does not state

The session's only generative output is the 52 kernel-CONFIRMED weakenings. The question
that decides whether they are *anything* is whether Mathlib already contains the general
version. Checked with `equivalent(level="instances")` over the 131k algebra slice:

| | count |
|---|---|
| already has a statement-equivalent sibling — **rediscovery** | **23** |
| no equivalent in the slice — **candidate novel** | **29** |

**The split is causal, not incidental.** Every rediscovery came from the *shape* detector
(`BOTH` and `S_ONLY` strata): `max_eq_left_iff ~ sup_eq_left`, `inf_lt_sup ~ min_lt_max`,
`Field.isDomain ~ DivisionRing.isDomain`. That detector finds a weakening precisely *because*
the general version already exists to compare against, so it structurally cannot produce a
new one. All 29 candidates are `L_ONLY` — found by the citation detector alone, which is the
only one of the two that can see a generalization nobody has written down.

Sampled structure:

| declaration | declares | kernel accepts | proof citations |
|---|---|---|---|
| `even_iff_exists_two_mul` | `Semiring` | `NonAssocSemiring` | 39 |
| `div_le_iff₀'` | `CommGroupWithZero, PartialOrder, PosMulReflectLT` | `MulPosReflectLT` | 38 |
| `Additive.ofMul_le` | `Preorder` | `LE` | 11 |
| `WithTop.natCast_ne_top` | `AddMonoidWithOne` | `NatCast` | 5 |
| `isLeftRegular_toMul` | `Monoid` | `Mul` | 12 |

Most are type-synonym transfer lemmas over-assuming structure — real, correct and minor.
Two look substantive: dropping associativity from `even_iff_exists_two_mul`, and the
covariant/contravariant swap in `div_le_iff₀'` across a 38-citation proof.

### Three caveats that bound the claim

1. The slice is 131k of Mathlib's ~420k declarations; a general version may exist outside it.
2. `equivalent` is exact-match after instance erasure, so a general version *phrased*
   differently would not be detected.
3. **These are exactly what Mathlib's `#lint` generalization linter targets, and whether it
   already flags them has not been tested.** That single test decides novelty and it has not
   been run.

### What this is and is not

It is the first output of this session that is generative rather than rediscovery:
kernel-verified, absent from the corpus, produced by a detector with a measured precision
(24.2% for the `L_ONLY` stratum). It is not mathematics anyone will care about — 29 minor
hypothesis weakenings in a library that runs linters for exactly this.

The honest read: **the machinery can generate verified novel statements, at a rate and
significance far below the ambition.** That is a floor, not a ceiling — but the floor is now
measured instead of assumed, and caveat 3 is the next thing to close.

## 28. Correction: Mathlib has no generalization linter, and the 29 are not reachable by its tooling

Caveat 3 of §27 was the one that decided novelty: are these already flagged by Mathlib's own
linters? I had asserted repeatedly through this session that *"Mathlib ships generalization
linters and runs them, so the obvious fruit is picked"*, and used that to talk the result
down. **That assertion is false.** The complete shipped set:

| linter | source | what it detects |
|---|---|---|
| `unusedArguments` | Batteries | arguments **entirely unused** in value *and* type |
| `unusedHavesSuffices`, `docBlame`, `checkType`, `synTaut` | Batteries | unrelated |
| `impossibleInstance`, `nonClassInstance` | Batteries | instance *inferability*, not strength |
| `unusedDecidableInType` | Mathlib | **off by default**, `Decidable`-only, and checks the *type* |

**None performs typeclass weakening.** `unusedArguments` fires only when a binder is used
nowhere. The detector here fires when a binder *is* used but only through operations a
weaker class already supplies — a different predicate, and the one that matters.

`Additive.ofMul_le` is the clean demonstration: its `Preorder` binder is genuinely used, for
`≤` in the statement, so `unusedArguments` is silent by construction; it is not a
`Decidable`, so `unusedDecidableInType` is silent too. The proof needs only `LE`. No shipped
linter can reach it.

Mathlib's `UnusedInstancesInType` is the nearest thing and asks a statement-level question —
"is this instance unused in the remainder of the *type*" — where this asks a proof-level one.

### What §27 therefore amounts to

**29 kernel-verified hypothesis weakenings that Mathlib does not state and whose own tooling
cannot detect.** atlas.md §1b's claim — "every gap found is a free generalization … to my
knowledge nobody runs it systematically" — is the one that survives; my scepticism about it
was based on tooling I had not checked.

They remain minor mathematics: mostly type-synonym transfer lemmas over-assuming structure.
Two are more than that (`even_iff_exists_two_mul` dropping associativity;
`div_le_iff₀'` swapping `PosMulReflectLT` for `MulPosReflectLT` across a 38-citation proof).
The two remaining caveats from §27 still stand — the slice is 131k of ~420k, and `equivalent`
is exact-match so a differently-phrased general version would be missed.

**Method note.** This is the third time this session that a confidently-repeated background
assumption turned out false on inspection (after "flex head means higher-order" and "the
scorer is where the leverage is"). Each was load-bearing for a decision, and each cost less
than ten minutes to check.

## 29. The full Mathlib slice, and the generalization pipeline at scale

> **Corrected by §31.** The slice this section reports is **not** a whole-Mathlib corpus.
> `--local` filters the output rather than the import, so it contains Mathlib's own 348,793
> declarations and none of the `Init`/`Std`/`Lean` foundation their statements are built
> from. It is unusable for erasure or evidence work, and the control in §31 measures the
> damage: 34.5% of candidates lost, 11.0% fabricated. The extractor timings below stand —
> they are what made a closure extraction feasible at all — but the corpus does not.

**348,810 declarations, 4.7 GB** — the whole-Mathlib slice this project has never had. Every
previous attempt was abandoned; §4 of CLAUDE.md records one that "did not finish in 24
minutes at 9.4 GB". The instrumentation shows why it is obtainable now:

```
[import]  766,559 constants in 45.7 s
[select]  348,810 selected in  1.5 s     <- was 30+ min and never finished
[encode]  348,810 rows      in  1.2 s
```

48 seconds of computation. The remaining ~28 minutes is the write loop —
`row.toJson.compress` per row at 21 KB/row — which is now the only expensive part and is
pure serialisation. Two of this session's extractor fixes are what moved it: filtering by
module *before* encoding, and reading the module index instead of asking `moduleOf` per
declaration.

### Pipeline at scale, on the 131k algebra slice

`scripts/generalization-run.py` runs candidates → two-way novelty screen → kernel probes:

| stage | count |
|---|---|
| theorems judged | 15,648 |
| skipped: multi-carrier | 15,387 |
| skipped: projection-like | 928 |
| `unused` verdicts (no target to force) | 1,044 |
| **over-hypothesis candidates with a target** | **727** |
| of those, rediscovery (general version already stated) | 53 |
| **novel candidates** | **674** |

So §27's 29 came from probing 120 of these. **674 novel candidates exist on the algebra
slice alone**, and at the `L_ONLY` stratum's measured precision (24.2%, a lower bound since
`REFUTED` is inconclusive) that projects to roughly 160 confirmable generalizations from
this slice — against 348,810 declarations in the full corpus, of which this slice is 38%.

The 53:674 rediscovery-to-novel ratio is itself informative: **92.7% of the candidates have
no general version already stated.** That is the opposite of what "the obvious fruit is
picked" would predict, and consistent with §28's finding that no shipped linter performs
this check.

## 30. 140 kernel-verified generalizations

Six hundred probes emitted from the novelty-screened candidate set, scored on the proposed
`(declared class -> target)` pair only — 522 spurious lines discarded, since
`#fh_home_refute` forces its class onto every instance binder and only the proposed one was
ever claimed.

| | |
|---|---|
| probes scored | 566 |
| **CONFIRMED** | **140** |
| REFUTED (inconclusive) | 426 |
| no verdict | 0 |
| **precision, lower bound** | **24.7%** |

The rate replicates §1's 24.2% on an independent and five-times-larger sample, which is the
first time any number in this session has been measured twice and agreed.

`CONFIRMED` is sound and final: the declaration's own proof term typechecks against the
weaker hypothesis. `REFUTED` is inconclusive by construction, so 24.7% is a floor on
precision and says nothing about recall.

### The confirmed set has structure

* **The order type-synonym family** — `Additive.ofMul_le`, `Additive.ofMul_lt`,
  `Additive.toMul_le/lt`, `Multiplicative.ofAdd_le/lt`, `Multiplicative.toAdd_le/lt`:
  eight lemmas declaring `Preorder` where the proof needs only `LE` or `LT`.
* **Std's monadic iterator lemmas** — `Array.step_iterM`, `Array.step_iterFromIdxM`,
  `Array.iterM_eq_iterFromIdxM`, `List.step_iterM_cons/nil`: `Monad -> Pure`. These are Lean
  core, not Mathlib.
* **`ExceptCpsT.throw_bind`** — `Monad -> Bind`.
* **`Lean.Grind.CommRing.intCast_eq_denoteInt`** — `Lean.Grind.Field -> Lean.Grind.Ring`,
  inside Lean's own `grind` ring normaliser.
* **`Odd.pow_add_pow_eq_zero`** — `IsCancelAdd -> IsRightCancelAdd`.
* **`AddMonoid.End.one_apply`** — `AddZeroClass -> AddZero`.

That the families cluster is itself evidence the detector is tracking something real rather
than sampling noise: it found all eight members of the order-synonym family and all five of
the iterator family, not scattered singletons.

### What the number means

140 statements that (a) Lean's kernel accepts under a strictly weaker typeclass hypothesis,
(b) have no general version stated anywhere in the 131k slice, and (c) no shipped linter can
detect, because every shipped linter tests whether a binder is used *at all* and this tests
whether it is used *at its declared strength* (§28).

From a slice that is 38% of Mathlib. The candidate pool it was drawn from is 674, so the
600-probe budget covered 89% of it — the remaining headroom on *this* slice is small, and
the scaling question is now the other 62% of the corpus, for which the 348,810-declaration
slice of §29 now exists.

**This is the session's result.** Not novel mathematics in any deep sense — 140 minor
hypothesis weakenings — but generative rather than rediscovered, kernel-verified rather than
plausible, novelty-screened two ways, at a precision measured twice on independent samples.

---

## 31. The full Mathlib slice has no foundation, and both consumers fail silently on it

§29's 348,810-declaration slice was extracted with `--local` over Mathlib's own module list.
`--local` filters the **output**, not the import: the foundation was loaded into the
environment and then not written. What the file actually contains:

| slice | rows | top-level modules | `Eq` | `Iff` | `LE.le` | `Monad` |
|---|---|---|---|---|---|---|
| algebra (import closure) | 131,062 | Init 39,590 · Lean 36,671 · Mathlib 24,323 · Std 22,853 | ✓ | ✓ | ✓ | ✓ |
| "full Mathlib" | 348,810 | **Mathlib 348,793** · Std 15 · Batteries 2 | ✗ | ✗ | ✗ | ✗ |

It is not a larger corpus. It is Mathlib with its foundation removed — and every statement
in it is headed by constants that are not in it.

Both consumers read those rows, and neither reports a miss:

* **the erasure** asks the corpus for a head constant's signature to learn which argument
  positions are `InstImplicit` (`erase.rs:334`); on a miss it holes nothing and degrades to
  `Presentation` behaviour for that spine;
* **the evidence rule** asks a cited constant's row for the classes it requires; on a miss
  it reaches nothing, and a hypothesis justified only through that citation reads as unused.

Both degrade toward "no information", silently, in the direction that produces output.

### The control: how wrong does it get?

The algebra slice is a genuine closure, so restricting it to `Mathlib.*` (24,323 rows)
reproduces the defect on a corpus where the correct answer is also available.
`scripts/foundation-control.py` asserts first that the restriction really does change the
erasure — otherwise it would be measuring something else — then compares candidate sets.

| | closure (correct) | Mathlib-only (defective) |
|---|---|---|
| theorems judged `at-home` | 17,025 | 7,664 |
| `unused` | 1,044 | 838 |
| **over-hypothesis candidates** | **727** | **535** |

| candidate `(declaration, class)` pairs | |
|---|---|
| present in both | 476 |
| …agreeing on the proposed target | 475 |
| **lost by removing the foundation** | **251 (34.5% of the correct set)** |
| **fabricated by removing it** | **59 (11.0% of its own output)** |

**65.3%** of the correct candidates survive restriction with their target intact.

The fabrications are the serious half, because they are not noise — they are confident and
wrong in a specific way:

```
Commute.mul_pow           [Monoid]     -> Mul          (needs Monoid: `pow` is a Monoid field)
Commute.pow_pow           [Monoid]     -> Mul
IsLeftRegular.pow         [Monoid]     -> Mul
AddCommute.add_nsmul      [AddMonoid]  -> Add
Equivalence.of_isEquiv    [IsEquiv]    -> IsTrans
```

Each says a lemma about powers needs only multiplication. The evidence rule reached `Mul`
and stopped, because the row for the constant that would have supplied `Monoid` was not in
the file. Had the scaled run gone ahead, roughly one probe in nine would have been an
artifact of the extraction command.

Losses run the other way and are equally mechanical — `AddOpposite.op_one [One] -> OfNat`
disappears because `OfNat`'s own row is gone, so `One`'s ancestor is unreachable.

### Consequences

* **§29's headline is wrong as stated.** "The whole-Mathlib slice this project has never
  had" is a Mathlib-only slice, not a closure. The extractor timings it reports stand; the
  corpus it produced is not usable for skeleton or evidence work. Re-extracting without
  `--local` writes all 766,559 constants.
* **§30's 140 are unaffected.** They were generated, screened and kernel-probed entirely on
  the algebra slice, which is a genuine closure. Nothing in that result touched this file.
* **The scaling caveat is still open**, and now for a measured reason rather than an
  unexamined one.
* A slice is only sound for these queries if it is **closed under the constants its
  statements mention**. That is a checkable property, and nothing checked it.

> **Partly withdrawn by §40.** The coercion blind spot predicted below does not exist: that
> constant sits in an `InstImplicit` position and is holed at `instances` either way, and a
> positive control finds the coercion-free general version 40 times out of 40. The rest of
> this section — the unclosed slice, the measured cost, the sibling-matching defect — stands.

### The related screen defect, found on the way

Independently: the near-duplicate novelty screen at retention >= 0.85 matches **siblings**,
not generalizations — `div_le_iff₀'` against `div_lt_iff₀` (the `<` version), `npow_eq_pow`
against `zpow_eq_pow` (natural against integer power), `nsmul_eq_smul` against
`zsmul_eq_smul`. A `<=`/`<` pair differs in one constant out of dozens, which sits well
above any workable floor. Retention thresholding is the wrong instrument here.

The right screen is exact, and the pipeline already used it: a general version differs from
its candidate **only** in binder domains, and `Level::Instances` holes exactly those, so
`equivalent(level="instances")` is correct in kind. Its error runs the other way and is
real — a general version stated with the weaker class's operation applied directly, rather
than through the coercion the stronger class supplies, keeps a different constant in the
body and will not compare equal. Both directions are now named; neither is estimated.

---

## 32. The check that would have caught it existed, was documented, and was dead

`Signatures` carries a field for exactly this:

```rust
/// Constants with no row in the slice. Reported by the index rather than swallowed —
/// a spine whose head is unknown degrades to `Presentation` behaviour, and knowing how
/// often that happens is the difference between a measurement and a guess.
pub missing: HashSet<SymId>,
```

It is initialised to `HashSet::new()` in two places, never inserted into, and never read.
The measurement its own comment calls "the difference between a measurement and a guess"
was never taken.

There was also a live counter, and it was worse than absent — it was wrong in a way that
made it read clean:

```rust
if let Node::Const(sym, _) = arena.node(arena.spine(t).0)
    && !sigs.known(sym) { degraded_spines += 1; }
```

`arena.spine(t).0` is the **root's** head. A theorem's root is a `Pi`, so the `Const` arm
never matches, and `degraded_spines` read **0 on every corpus this project has ever built** —
including the one that is 61% unknown. It is precisely the defect `logical.rs`'s `key_of`
had earlier this session: a spine test that forgets statements begin with binders.

### The fix

`collect_app_heads` walks every application head in the statement, and the index now records
`known_heads`, `degraded_spines` and a per-statement frequency for each unknown head, so the
diagnostic names the constants worth extracting rather than only counting misses.
`SkeletonIndex::closure(top)` and `Corpus.closure(top=20)` expose it; the CLI is skipped
deliberately, since it is being retired.

### The gate, with its control

`scripts/slice-closure.py` asserts opposite verdicts on two corpora, because a threshold no
corpus can miss is not a check:

| corpus | declarations | application heads | missing | coverage |
|---|---|---|---|---|
| algebra slice (import closure) | 131,062 | 2,028,671 | 15,298 | **99.25%** |
| same, restricted to `Mathlib.*` | 24,323 | 430,096 | 165,954 | **61.41%** |

The diagnostic separates the two cleanly without being told which is which. The closure's
entire miss list is auto-generated size instances — `Array._sizeOf_inst` (425 statements),
`Option._sizeOf_inst` (333), `Bool._sizeOf_inst` (326) — which appear in no statement the
erasure cares about. The restricted slice is missing **the language**:

```
Eq (9,601 statements)   OfNat.ofNat (3,986)   Iff (3,808)   LE.le (3,293)
Nat (2,821)             HMul.hMul (2,264)     instHMul (2,264)   Zero.toOfNat0 (2,132)
```

99.25% against 61.41% is a 38-point separation on corpora one of which is a strict subset of
the other, so the floor at 95% is not a tuned constant — there is nothing between them to
tune.

### What this is worth

Nothing in §30 changes: it ran on the closure. What changes is that "is this corpus usable"
is now answerable in 23 seconds instead of being discovered four sections later by noticing
that a skeleton looked wrong. Every prior result at `instances` or above was computed on a
corpus whose closure was never checked; the algebra slice passes at 99.25%, so those results
stand, but they stood on luck rather than on a check.

---

## 33. The ranking golden has been red at HEAD, and the tie test was going quiet

Running the full Rust gate after §32's change turned the ranking golden red. It is not
§32's doing: checked out clean at `70e0766` in a separate worktree, the golden fails there
too. **A named gate has been red at HEAD since that commit.**

The cause is in the commit itself. It introduced a derivativeness penalty as a new
multiplicative score factor —

```rust
derivative_weight: 0.45,
derivative_penalty: 1.0 - cfg.derivative_weight * self.derivative[d.0 as usize],
    * factors.scoped_penalty
+   * factors.derivative_penalty,
```

— and did not re-pin `tests/golden/similar-algebra.txt`. That explains both halves of the
diff exactly: every score is scaled by `1 - 0.45 * d` (`le_trans`'s top neighbour
1.4534 -> 1.2109), and previously-tied families split because derivativeness differs within
them. CLAUDE.md's own rule is that a ranking change needs a golden pinned *before* it; the
pin existed and the re-pin did not happen.

Reviewed rather than re-recorded to make it quiet, which is what the test's panic message
asks for. The new ordering is defensible and in places better: `Rat.mul_comm` separates from
the machine-integer family it was alphabetically tied with, and prime-suffixed variants like
`ge_trans'` fall behind `Setoid.trans` and `Lean.Order.PartialOrder.rel_trans`. One
regression is worth naming — `dvd_trans` is now 7th in `le_trans`'s neighbours, and
CLAUDE.md records that keeping it in the **top five** is what the tie-break fix was for.
That property is documented in prose and asserted nowhere.

Re-pinned, both golden tests green.

### The second-order effect: a property test almost stopped testing

`ties_are_broken_by_content_before_the_alphabet` iterates neighbour pairs and `continue`s
whenever two scores differ, so it only asserts anything on genuine ties. The score used to
be a product of coarse factors and whole families landed on one value — CLAUDE.md: "Ties are
the normal case, so tie-breaks carry information." The derivativeness penalty is
near-continuous and splits nearly all of them:

| query | adjacent equal-score pairs in the top 20 |
|---|---|
| `le_trans` (the test's only query) | **1** |
| `And.comm` | 0 |
| `Nat.mul_comm` | 13 |

The test was one score change away from asserting nothing while still reporting green — the
same failure mode as §32's dead counter and §5's identity-normalization, arrived at by a
third route. It now runs both queries and asserts it examined at least five tied pairs,
failing with an instruction to pick a better query rather than delete the assertion.

`Nat.mul_comm` keeps its ties because the machine-integer family (`Int8`, `Int16`, `UInt64`,
…) is structurally identical member to member, so no continuous factor can separate them.
That is a durable source of ties rather than an accident, which is what a tie-break test
needs.

---

## 34. `REFUTED` was claiming work the code had skipped

D1b re-elaborates before the kernel sees the weakened declaration: it opens the weakened
telescope and re-synthesises every instance argument in it, so `synthInstance?` is asked the
question that matters rather than handed projections that assume the answer. That is what
makes a rejection mean anything.

It is wrapped in a `try`, and the fallback is right —

```lean
catch _ => pure (ty', value)          -- the *original* type and value
```

— because a failed re-synthesis should still put something in front of the kernel.
`resynthInstances` calls `inferType` on an application whose instance chain the weakening
may just have broken, so it genuinely can throw.

What was wrong is what the fallback then *reports*. Both paths printed:

> `REFUTED — even with every instance argument re-synthesised in the weakened context, the term does not typecheck`

On the fallback path nothing was re-synthesised. The kernel saw the pre-D1b term with its
projections baked in, which is the exact situation D1b exists to escape, and the message
asserted the opposite. The overstatement landed on the *rejection* — the verdict that was
already the weak one — and it is invisible from the outside, because a rejection is what
both paths produce.

### The fix

The `try` now carries out whether it ran, and there are three verdicts:

| verdict | meaning |
|---|---|
| `CONFIRMED` | the term typechecks against the weaker hypothesis. Sound and final. |
| `REFUTED` | it does not, **and** re-elaboration ran first. Evidence, not proof — this proof term fails, which is not "no proof exists". |
| `INCONCLUSIVE` | re-elaboration threw; the kernel saw the original term. Says nothing either way. |

All three existing fixture cases in `Tests/Atlas/Home.lean` still report `REFUTED`
unchanged, so the fixtures exercise the re-elaborated path and the split does not disturb
them.

### What it does to the headline, and why that is not yet known

§30's 24.7% divided 140 confirmations by 566 scored probes. If some of those 566 were the
fallback path, they were never a test of anything, and the denominator is too large — the
real precision over *decisive* probes would be higher.

That is a measurement, not an inference, and it needs the 600-probe Mathlib run repeated
with the new verdicts. `scripts/score-probes.py` keeps the three apart and reports both
numbers. Two outcomes, both worth having:

* **INCONCLUSIVE never fires** — re-elaboration always succeeded on real Mathlib input, the
  old two-verdict reading was correct, 24.7% stands, and the branch cost nothing.
* **INCONCLUSIVE fires often** — 24.7% was diluted by probes that never asked the question,
  and precision over decisive probes is the number that means something.

Predicting which is not the same as measuring it, and this section will not claim one until
the run has happened.

---

## 35. A whole-Mathlib slice that is actually closed

Re-extracted without `--local`, so the import closure is written rather than filtered away:

```sh
cd lean && lake exe atlas_extract Mathlib > /tmp/mathlib-closure.jsonl
[import]     766,559 constants in 6.9 s
[encode-all] 470,435 rows                  <- `isExtractable` drops the rest
             4.83 GB
```

`scripts/slice-closure.py` on it:

| | `--local` slice (§31) | closure slice |
|---|---|---|
| declarations | 348,810 | **470,435** |
| application heads | 430,096 (restricted control) | **89,807,045** |
| missing | — | 234,713 |
| **coverage** | 61.41% (control) / foundation absent | **99.74%** |

It passes the 95% floor with more margin than the algebra slice (99.25%), and its residual
misses are the same harmless family — auto-generated internals, now including elaborator
by-products:

```
LinearMap.mk₂._proof_1 (536)   Array._sizeOf_inst (486)   Lean.Expr._sizeOf_inst (391)
PiLp.innerProductSpace._proof_1 (283)   ContinuousLinearMap.addCommGroup._proof_7 (266)
```

None of them heads a statement the erasure needs to normalise, which is exactly the profile
the algebra slice shows and the `--local` slice did not.

So the corpus §29 claimed now exists: 470,435 declarations, closed under the constants its
statements mention, and checked rather than assumed. Note it is **larger** than the
`--local` slice despite that one being described as whole-Mathlib — 470,435 against 348,810 —
because the missing 121,625 are the foundation the statements are written in.

---

## 36. Measured: `INCONCLUSIVE` fires, and the result survives it — 144 at 24.9%

The 600 probes re-run against §34's three-verdict command, scored by
`scripts/score-probes.py` on the proposed `(declared -> target)` pair only:

| | |
|---|---|
| proposed pairs with a verdict | **600 / 600** |
| CONFIRMED | **144** |
| REFUTED (re-elaboration ran) | 434 |
| INCONCLUSIVE (re-elaboration threw) | **22** |
| precision over all verdicts | 24.0% |
| **precision over decisive probes** | **24.9%** (144 of 578) |

`INCONCLUSIVE` fires, so the branch is reachable and §34's concern was real rather than
theoretical — 22 probes were being reported as `REFUTED` while the kernel had seen the
original term. But it fires on **3.7%** of probes, so the correction is small: 24.7%
becomes 24.9%. The old reading was very nearly right, and is now right for a reason that was
checked instead of assumed.

Where it fires is not random. All 22 are order or ring classes —

```
LinearOrder 9    PartialOrder 6    Lean.Grind.CommRing 3
IsOrderedMonoid 2    IsOrderedAddMonoid 2
```

— which are exactly the classes with the deepest projection chains, so weakening a binder
breaks the longest instance path and `inferType` inside `resynthInstances` has the most
opportunity to fail. The failure mode is structural, not incidental.

### The confirmed set grew, and the earlier scoring was the reason

| | |
|---|---|
| confirmed in both runs | **140** |
| lost | **0** |
| newly confirmed | **4** |

Every one of §30's 140 reproduces. The four additions are not new kernel behaviour — the
first pass scored 566 of 600 probes and silently dropped 34, and four confirmations were in
the dropped set. `score-probes.py` now accounts for all 600 and reports the count of lines
it discards (484, from binders `refute` forced but nobody proposed) rather than leaving the
difference between the raw file and the scored set implicit.

The four are, again, a **complete family**:

```
WithZero.le_log_iff_exp_le    [Preorder] -> LE
WithZero.log_le_iff_le_exp    [Preorder] -> LE
WithZero.log_lt_iff_lt_exp    [Preorder] -> LT
WithZero.lt_log_iff_exp_lt    [Preorder] -> LT
```

That is the fourth complete family in the confirmed set — after the eight order type-synonym
lemmas, the five Std iterator lemmas, and the `WithZero` four. A detector sampling noise
does not keep returning families with no members missing.

**The result, restated: 144 hypothesis weakenings that Lean's kernel accepts, at 24.9%
precision over probes that actually asked the question.** Still a lower bound on precision,
since `REFUTED` means "this proof term fails", not "no proof exists".

---

## 37. Whole Mathlib: 2,704 candidates — and precision is family-structured, not flat

`scripts/generalization-full.py` over the 470,435-declaration closure (§35). The streaming
rule is verified identical to the in-memory one on the algebra slice first — 727 candidates
both ways, same set — so the rewrite is not the variable.

| verdict | count |
|---|---|
| multi-carrier (refused, not judged) | 143,613 |
| at-home | 91,009 |
| produces-a-class | 6,302 |
| projection-like | 4,790 |
| no-single-home | 3,141 |
| unused (no target to force) | 2,674 |
| **over-hypothesis with a target** | **2,704** |

2,645 in `Mathlib`, 38 `Init`, 14 `Std`, 7 `Batteries`. 30 minutes, peak 1.5 GB — the scan
dominates; judging all 470k takes 32 seconds.

### The finding: a flat precision was hiding a bimodal one

Per-family confirmation rates, measured on the 600 probes:

| declared -> target | probed | confirmed | rate |
|---|---|---|---|
| `AddMonoidWithOne -> NatCast` | 14 | 14 | **100%** |
| `PosMulReflectLT -> MulPosReflectLT` | 12 | 12 | **100%** |
| `AddMonoid -> Add` | 26 | 23 | 88% |
| `Monoid -> Mul` | 25 | 22 | 88% |
| `AddGroup -> AddMonoid` | 9 | 7 | 78% |
| `Monad -> Pure` | 18 | 10 | 56% |
| `Preorder -> LT` | 14 | 7 | 50% |
| `Preorder -> LE` | 78 | 23 | 30% |
| `LinearOrder -> Lattice` | 20 | 2 | 10% |
| `Zero -> OfNat` | 56 | 0 | **0%** |
| `One -> OfNat` | 50 | 0 | **0%** |
| `PartialOrder -> Preorder` | 24 | 0 | **0%** |
| `LinearOrder -> Preorder` | 16 | 0 | **0%** |

24.9% is not a property of the detector. It is a mixture of families at 100% and families
at 0%, and applying the measured rates to the 2,704 rather than the aggregate moves the
projection by **-45%** on the subset where rates are known (182 expected against 329).

**51% of the 2,704 are in families with fewer than 4 probes.** That is where new probes buy
information; more probes into `Preorder -> LE` buy almost none.

## 38. One of the zero families was not mathematics, it was a malformed probe

`Zero -> OfNat` and `One -> OfNat` are 336 candidates and 106 probes with no confirmation.
Splitting *all* 578 decisive probes by whether the weakening changes the class's arity:

| | families | probed | confirmed | rate |
|---|---|---|---|---|
| arity-preserving | 27 | **444** | **144** | **32.4%** |
| arity-changing | 5 | **134** | **0** | **0.0%** |

Perfect separation across five unrelated families (`Zero`/`One -> OfNat`,
`HasDistribNeg -> Neg`, `AddMonoid -> SMul`, `OrderBot -> Bot`). The mechanism is in the
code, not the mathematics:

```lean
| .const _ ls => some (.forallE n (mkAppN (.const repl ls) d.getAppArgs) b bi)
```

The replacement class is applied to the **source** class's arguments. `Zero R` supplies
`[R]`; `OfNat` needs `[R, 0]`, its second argument being the literal denoted. The rebuilt
binder is under-applied, so the kernel rejects a term nobody proposed and the command called
it REFUTED. The comment immediately above that line records the identical mismatch for
universe *levels* and fixes it there — this is that bug's twin in the argument list, and it
survived for the reason given there: ancestors of a class almost always match, so the cases
that do not are rare enough to look like ordinary rejections.

### Consequences

* **Precision is 32.4%, not 24.9%.** The 600 probes account as 22 inconclusive (§36), **134
  malformed**, 444 well-formed — of which 144 confirmed. The malformed probes never asked a
  question, so excluding them from the denominator is correct; calling them false is not.
* **529 of the 2,704 whole-Mathlib candidates (19.6%) are currently unaskable.** Not
  disproved — unaskable. Supplying the missing argument is not generically possible, since
  nothing recovers `0` from `Zero`.
* `weakenBinder` now takes the target's arity, read off its own type, and **refuses** on a
  mismatch. The caller already had a refusal branch; it now says NO VERDICT explicitly and
  states that this is not evidence the weakening is false.

`Tests/Atlas/Home.lean` pins both halves: `#fh_home_refute zeroish OfNat` must refuse, and
`#fh_home_refute zeroish2 AddCommMagma` must still reach the kernel and CONFIRM — otherwise
the refusal would be indistinguishable from the command having gone quiet.

### What this does *not* license

`REFUTED` still means "this proof term does not typecheck", never "no proof exists". A 0%
family is a place to stop spending probes, not a family of settled negatives, and per
CLAUDE.md's rule the arity check flags rather than deletes: false positives are cheap here
and false negatives are not.

---

## 39. The whole-corpus novelty re-screen: 144/144 survive

> **Corrected by §40.** This section reads the 6.0% prevalence figure as the screen's
> detection rate and calls the screen weak. That is wrong — a positive control puts
> sensitivity to an identically-stated general version at 40/40. The counts below stand;
> the interpretation under "Why that is weaker evidence than it looks" does not.

The last open caveat on §36's result was coverage: the 144 were screened for prior art
against the 131k algebra slice, a genuine closure but the closure of *one module*. Re-run
against §35's 470,435-declaration whole-Mathlib closure — loaded whole, since §31 showed
restricting a corpus silently degrades the erasure, and with `Corpus.closure()` asserted at
99.74% before anything is screened:

| | |
|---|---|
| kernel-confirmed weakenings | 144 |
| **survive as novel** | **144** |
| prior art found | **0** |
| unscreenable | 0 |

Adding 339,373 declarations — 3.6x the corpus — surfaces no general version of any of them.

### Why that is weaker evidence than it looks

A screen that finds nothing is the shape this repo distrusts, so the question is whether it
*can* fire. It can, and the rate is the point:

| population | n | non-empty equivalence class at `instances` |
|---|---|---|
| the 144 confirmed | 144 | **0 (0.0%)** |
| random theorems from the slice | 400 | 24 (**6.0%**) |
| pipeline candidates (§29's rediscovery count) | 727 | 53 (**7.3%**) |

So the screen is not vacuous — within this very pipeline it rejected 53 candidates as
already-stated. But **only 6-7% of theorems have any equivalent at all** at this level, and
a screen that would catch prior art in at most ~7% of cases cannot turn "found none" into
"there is none".

Two further things keep the number honest rather than impressive:

* **The 144 were pre-screened.** They descend from the 674 that already passed
  `equivalent` on the algebra slice, so 0 there is true by construction. The only new
  information is that the *additional* 339,373 declarations contribute nothing — which is
  real, and is all this run establishes.
* **The blind spot from §31 is unmeasured.** A general version stated with the weaker
  class's operation applied directly, rather than through the coercion the stronger class
  supplies, keeps a different constant in its body and never compares equal. Nothing here
  bounds how often that happens.

The 0/144 against a 6.0% base rate is a real deficit (expected ~9 under the random rate),
but the confirmed set is selected for being single-carrier, non-projection and
over-hypothesised, and no control here separates "genuinely unstated" from "structurally
unusual in a way that correlates with having no equivalent".

### Where the result actually stands

**144 hypothesis weakenings that Lean's kernel accepts, at 32.4% precision over well-formed
probes (§38), with no general version discoverable in 470,435 declarations by a screen whose
sensitivity is about 7%.**

The kernel confirmations are the strong part and are not in doubt — the declaration's own
proof term typechecks against the weaker hypothesis, checked by `addDeclCore`. The novelty
claim is the weak part, and it is weak for a measured reason rather than an unexamined one.
Strengthening it needs a screen with a sensitivity figure attached, which is the next piece
of work and is not done.

---

## 40. Correction: the novelty screen is not weak, and §31's blind spot does not exist

§39 read "6.0% of random theorems have a non-empty equivalence class at `instances`" as the
screen's detection rate and concluded it "cannot turn 'found none' into 'there is none'".
That was wrong. 6.0% is the **prevalence** of equivalents — how often Mathlib states the
same thing twice — and says nothing about what the screen does when prior art exists.

`scripts/screen-sensitivity.py` constructs the case instead of counting around it. For each
confirmed weakening `decl [C] -> T` it synthesizes the row a general version *would* have
and injects it under a fresh name:

* **variant A** — the same statement with the binder domain weakened (`Preorder α` becomes
  `LE α`), i.e. a general version stated the obvious way;
* **variant B** — variant A with the coercion the stronger class supplied also collapsed
  (`Preorder.toLE α inst` becomes `inst`), i.e. §31's claimed blind spot written out.

| injection | found by `equivalent(level="instances")` |
|---|---|
| variant A | **40 / 40** |
| variant B | **40 / 40** |
| control — nothing injected | **0** spurious hits |

The control is the point: on the unmodified corpus the same 40 queries return nothing, so a
hit means the injection was found and not that the query matches anything.

### Two corrections

1. **§39's characterisation of the screen is withdrawn.** Sensitivity to an
   identically-stated general version is 100%, not 7%. The screen is not the weak leg.
2. **§31's blind spot is withdrawn.** It predicted that a general version phrased with the
   weaker class's operation applied directly would keep a different constant and fail to
   compare equal. It does not, because that constant sits in an `InstImplicit` argument
   position and `Level::Instances` holes it either way. Variant B differed from variant A in
   26 of the 40 cases and was found in all of them.

### What remains genuinely unscreened

* **A general version stated in a structurally different form** — different variable order,
  an `Iff` where the candidate is an implication, a formulation equivalent but not equal.
  Nothing here bounds that, and it is a different blind spot from the one withdrawn above.
* **104 of the 144 were not injectable.** The construction needs the declared class as the
  first instance binder, so this measures 40. It is a sensitivity figure for a sample, not
  for the set.

### Net effect on the result

§39 concluded "no general version discoverable by a screen whose sensitivity is about 7%".
The correct statement is: **no general version exists among 470,435 declarations that is the
same statement under a weaker hypothesis** — which is exactly what "a generalization Mathlib
does not state" should mean, and is now backed by a positive control rather than by a base
rate misread as a detection rate.

---

## 41. Stratified probing: 285 confirmed, and allocation by family beats allocation by size

§37 found confirmation rates bimodal, which changes what a probe is worth: a 79th probe into
`Preorder -> LE` sharpens an estimate already built on 78, while a first probe into an
unmeasured family tells you something no other probe can. `scripts/probe-plan.py` allocates
accordingly — **per family, round-robin**, not per candidate.

The plan over the whole-Mathlib candidates (§37):

| | |
|---|---|
| candidates | 2,704 |
| askable | 2,113 |
| arity-changing, refused by §38 | **591** |
| probes emitted | **739** |
| families covered | **317 of 317 askable** |
| families with no prior rate | **236** |
| median probes per family | 2 |

### Result

| | first run (600) | stratified (739) |
|---|---|---|
| CONFIRMED | 144 | **157** |
| REFUTED | 434 | 575 |
| INCONCLUSIVE | 22 | 6 |
| UNASKABLE among proposed | 134 | **0** |
| precision over decisive | 32.4%¹ | **21.4%** |

¹ over arity-preserving probes only; 24.9% over all decisive.

`UNASKABLE` is 0 among proposed pairs — the plan spent no budget on weakenings the command
now refuses. The 310 "could not rebuild" lines in the log are all on binders `refute` forces
onto declarations but nobody proposed, and are discarded like the other 426 spurious lines.

| | |
|---|---|
| confirmed by the first run | 144 |
| confirmed by the stratified run | 157 |
| overlap | **16** |
| **union — unique confirmed weakenings** | **285** |

Only 16 of 157 were already known, so stratification bought **141 new confirmations from
739 probes** rather than re-confirming what was already measured.

### The honest reading of 21.4% against 32.4%

The stratified rate is *lower*, and that is expected rather than a regression. The first
600 probes were drawn from the largest families, which are large partly because they are
productive; the stratified run deliberately spends most of its budget on families nobody had
touched. **23.0% (301 of 1,310 decisive) over 326 families is the least biased estimate this
project has**, and it is lower than the number a size-weighted sample produces. Reporting the
32.4% as the headline would have been sampling bias with a decimal point.

### What the family map now shows

**12 families confirm at 100% with at least 3 probes** — these are not scattered hits:

```
15/15  AddMonoidWithOne -> NatCast          4/4  ConditionallyCompleteLattice -> …PartialOrderSup
13/13  PosMulReflectLT -> MulPosReflectLT   4/4  IsCancelAdd -> IsLeftCancelAdd
 4/4   AddCommSemigroup -> AddCommMagma     4/4  IsOrderedAddMonoid -> IsOrderedCancelAddMonoid
 4/4   Lean.Order.CompleteLattice -> …PartialOrder   4/4  LinearOrder -> DistribLattice
 4/4   SeminormedCommGroup -> SeminormedGroup        4/4  NormedAddCommGroup -> SeminormedAddGroup
 3/3   IsCancelAdd -> IsRightCancelAdd      3/3  ConditionallyCompleteLattice -> …PartialOrderInf
```

**25 families sit at 0% with at least 6 probes each — 332 probes, no confirmations.** That
is where the remaining budget should not go. Per CLAUDE.md's rule the map *deprioritises*
rather than deletes: `REFUTED` means this proof term fails, not that no proof exists, and a
surprise in a 0% family would be the most informative result available.

---

## 42. Complete coverage: every askable candidate in Mathlib, 431 confirmed

`probe-plan.py --all-remaining` emits every remaining askable candidate rather than a
sample, which replaces a rate estimate with a census. Reading class arities from the
131k algebra closure instead of the 470k one costs 39 s instead of 30 min — arity is a
property of the class, not of the corpus — at the price of a smaller arity table (644
classes against 2,644), so some arity-changing candidates slip through and are caught by
§38's runtime refusal instead. 61 were, and they are reported as `UNASKABLE`.

### Three runs, and the whole candidate set

| | first (600) | stratified (739) | remainder (1,065) | **total** |
|---|---|---|---|---|
| CONFIRMED | 144 | 157 | 146 | **447** |
| REFUTED | 434 | 575 | 849 | 1,858 |
| INCONCLUSIVE | 22 | 6 | 5 | 33 |
| UNASKABLE | 134 | 0 | 61 | 61¹ |
| precision over decisive | 24.9% | 21.4% | 14.7% | **19.4%** |

¹ the first run's 134 predate the refusal and were counted as REFUTED at the time; §38
re-classified them.

| | |
|---|---|
| whole-Mathlib candidates | 2,704 |
| **probed** | **2,305 (85%)** |
| never probed — arity-changing, refused by construction | 399 |
| total probes spent | 2,399 |
| **unique kernel-confirmed weakenings** | **431** |

Every candidate the command can state a question about has been put in front of the kernel.
The 399 remaining are not unexplored; they are unaskable, and §38 says why.

### Precision falls with each tranche, and that is the bias unwinding

24.9% -> 21.4% -> 14.7% is not degradation. The first 600 probes came from the largest
families, which are large partly because they are productive; the stratified run spent its
budget on families nobody had touched; the remainder is the tail. **19.4% over 2,305 probes
is the unbiased figure**, and the earlier 32.4% was a size-weighted sample reported as a
population rate.

### The rates are bimodal, and that is the usable structure

Over the 158 families with at least 3 decisive probes:

| family confirmation rate | families |
|---|---|
| 0–20% | 99 |
| 20–40% | 20 |
| 40–60% | 16 |
| 60–80% | 8 |
| 80–100% | 15 |

**68% of families are exactly 0% or exactly 100%.** Confirmability is a property of the
*weakening* — of which class you are dropping to — far more than of the individual lemma.
That is what makes the family map worth carrying: it predicts, and a flat rate does not.

### Where the 431 live

```
Mathlib 265   Std 13   Init 7

Mathlib.Algebra 154   Mathlib.Order 41   Mathlib.Tactic 19   Mathlib.Analysis 11
Mathlib.Combinatorics 9   Mathlib.Data 6   Mathlib.MeasureTheory 6   Std.Data 9
```

Concentrated in algebra and order, which is where the typeclass hierarchy is deepest and so
where there is most room to fall down it — the distribution the mechanism predicts.

### `atlas_closure` reaches agents

Per CLAUDE.md the new query lands in the engine, the binding, the MCP tool list and a gate
(the CLI is skipped deliberately — it is being retired). The MCP description leads with
"RUN THIS FIRST on any slice you did not extract yourself", since §31's failure is invisible
from inside a query.

`tests::atlas_closure_separates_a_closed_slice_from_an_unclosed_one` pairs a slice carrying
its head constant's row against the same slice without it, and asserts opposite verdicts.
The first version of that fixture used hand-written encodings with `s(*)` — which is
*erased-output* syntax, not input — so both slices parsed to zero declarations and the
closed half passed because 0/0 defaults to 100%. The test caught its own fixture; real
encodings lifted from the corpus replaced it.

---

## 43. The screen fires on real Mathlib, and confirmation rate partly measures rediscovery

§40 established the novelty screen's sensitivity with a synthetic injection: 40/40, control
clean. Real data was still outstanding, because §39's run found 0 prior art among 144 and a
screen that has never fired on anything real is a screen on probation.

Re-screened over the 285 confirmed after the stratified run, against all 470,435
declarations at 99.74% coverage:

| | |
|---|---|
| kernel-confirmed weakenings | 285 |
| survive as novel | **265** |
| **prior art found** | **20 (7.0%)** |
| unscreenable | 0 |

It fires, and on genuine cases — the general version really is stated:

```
max_min_distrib_left  [LinearOrder -> DistribLattice]        already: sup_inf_left
min_sup_distrib_left  [LinearOrder -> DistribLattice]        already: inf_sup_left
csSup_one             [CondCompleteLattice -> …PartialOrderSup]  already: sSup_one
csInf_zero            [CondCompleteLattice -> …PartialOrderInf]  already: sInf_zero
Tactic.Ring.Common.pow_one  [CommSemiring -> Monoid]         already: pow_one
FiniteField.cast_card_eq_zero [Field -> AddGroupWithOne]     already: Nat.cast_card_eq_zero
```

`max_min_distrib_left` is `LinearOrder`'s version of a `DistribLattice` fact; `sup_inf_left`
is that fact. This is exactly what the screen is for.

### Where the hits came from validates the earlier null

| prior-art hits | |
|---|---|
| from the first 144 (already screened on the algebra slice) | **0** |
| from the 141 newly probed and never screened | **20** |

§39 reported 0 of 144 and said the number was true by construction because those descend
from candidates the pipeline had already screened. That reading is now confirmed rather
than argued: the moment unscreened candidates entered the set, the screen started firing.

### The finding that changes how to read §42's family map

Splitting families by whether the screen found prior art in them:

| families | confirmed / decisive | rate |
|---|---|---|
| prior art found (10) | 32 / 69 | **46.4%** |
| none found (148) | 355 / 2,001 | **17.7%** |

**2.6x.** A high kernel-confirmation rate partly measures *rediscovery*, and the mechanism
is obvious once stated: if `sup_inf_left` is already in Mathlib for `DistribLattice`, then
`max_min_distrib_left` is a thin specialization of it, and of course its proof term
typechecks under the weaker hypothesis. The kernel is answering "can this be weakened",
which for an already-general fact is trivially yes.

So §42's claim that the family map "predicts" needs qualifying: it predicts
*confirmability*, which is a mixture of genuine over-hypothesis and already-stated
generality. Those separate only after screening, not before.

### The methodological consequence

**Screen before probing, not after.** The original pipeline did — 727 candidates screened to
674, then probed. The scaled runs dropped that step because a whole-corpus screen costs 35
minutes of corpus load, and paid for it by spending kernel budget on 20 rediscoveries and by
reporting a family map whose top rates are partly artefacts. The load is per *run*, not per
query, so the correct order costs one screen and saves the probes.

---

## 44. `Corpus.requires`, and the cost that caused the wrong pipeline order

§43's conclusion — screen before probing — was blocked by cost, not by principle. The
novelty screen took 35 minutes, and almost all of it was Python telescoping **all 470,435
statements** to build a table of "which classes does each declaration require", on a corpus
already fully parsed in the arena a few feet away. The screen needs that answer for the
handful of declarations `equivalent` returns per query, not for the whole slice.

`SkeletonIndex::requires(name)` walks the unerased root's `Pi` prefix and returns the class
heading each `InstImplicit` binder's domain. Exposed as `Corpus.requires(name)`.

It must read the **unerased** root: `Instances` and above hole binder domains, which is
exactly the information being asked for. Reading the erased term would return nothing and
look like "this declaration requires no classes" — the silent-degradation shape this
document has now recorded four times.

### Gate

`requires_reports_instance_binders_and_only_those` pairs a declaration whose telescope is
`Implicit -> InstImplicit -> Default` against one with no instance binder at all. The mixed
telescope catches a walk that counts the wrong binder kind; putting the `Implicit` binder
*first* catches one that stops at the first non-instance binder, which is the shape Lean
actually produces (`{α : Type} [Preorder α]`). The empty case catches a walk that reports
something for everything.

And a differential, per house style — the two implementations share no code, one walking the
arena in Rust and one parsing the byte encoding in Python:

| | |
|---|---|
| declarations compared | 4,000 |
| agree | **4,000** |
| disagree | **0** |

### Effect

The lattice still needs a conclusion head per parent projection, but only for names carrying
`.to` — a few thousand rather than 470,435. The screen becomes corpus-load-bound rather than
scan-bound, which is what makes "screen before probing" affordable on every future run.

---

## 45. The result: 387 kernel-verified generalizations Mathlib does not state

All 431 confirmed weakenings, screened against the whole 470,435-declaration closure at
99.74% coverage, with the rewritten screen (§44) — 10 minutes rather than 40:

| | |
|---|---|
| kernel-confirmed weakenings | 431 |
| **survive as novel** | **387** |
| prior art found | 44 (10.2%) |
| unscreenable | **0** |

The prior-art rate rose from §43's 7.0% because that run screened 285; these 431 include the
146 from the complete-coverage run, which had never been screened at all.

### What each half is

**Prior art** concentrates exactly where the lattice is a genuine generalization already
carried out — `LinearOrder` facts that Mathlib states for `SemilatticeSup`, `Lattice` or
`DistribLattice`:

```
max_le_iff        [LinearOrder -> SemilatticeSup]  already: sup_le_iff
max_min_distrib_left [LinearOrder -> DistribLattice] already: sup_inf_left
min_lt_max        [LinearOrder -> Lattice]        already: inf_lt_sup
csSup_one         [CondCompleteLattice -> …Sup]   already: sSup_one
div_le_one        [PosMulReflectLT -> MulPosReflectLT] already: div_le_one₀
```

These are the screen working, and each is a case where the kernel said "yes, weaker
hypothesis suffices" for the uninteresting reason that the weaker statement is already a
theorem.

**387 novel** are the ones where it is not.

### The claim, with every qualification attached

**387 statements in Mathlib whose own proof terms Lean's kernel accepts under a strictly
weaker typeclass hypothesis, and for which no version at that weaker hypothesis exists
anywhere in 470,435 declarations.**

* The kernel confirmations are sound and final — `addDeclCore` on the declaration's own
  proof term against the rebuilt binder.
* Novelty is screened by statement *equality* at `instances`, a screen measured at 40/40
  sensitivity on injected positives with a clean control (§40), and observed firing on 44
  real cases here. It cannot see a general version stated in a structurally different form
  — different variable order, an `Iff` against an implication — and that bound is unmeasured.
* Coverage is complete over the askable space: 2,305 of 2,704 candidates probed, the other
  399 unaskable by construction (§38), from a corpus verified closed at 99.74% (§35).
* Precision of the *detector* is 19.4% (§42), which is the number that matters for how much
  kernel time a future run costs — not for whether these 387 are real. They are checked
  individually.
* These are minor hypothesis weakenings, not new mathematics. What is new is that they were
  generated rather than rediscovered, verified rather than plausible, and found by a check
  no shipped linter performs (§28).

---

## 46. B7 — the full RH run, scoreable against the held-out key

The answer key was not read, located, or searched for. This is what the Atlas found, target
by target, with each target's stated pass condition beside it.

**Corpus**: 198 declarations — 114 statement-level `axiom`s across ten RH clusters plus 84
FH corpus-group controls.

```
CorpusControl 84   FF 27   Z 18   Spectral 13   Positivity 11   Deformation 9
LFamily 9   RH 8   Counting 7   PairCorrelation 6   ZeroDensity 6
```

### Scorecard

| target | verdict | evidence |
|---|---|---|
| **V1** Z~FF dictionary row set | **FAIL** | 1 row shipped against a 5-row requirement |
| **V4** missing-entry report names the F1 hole | **PASS** | Frobenius ×4 and base-field ×3 correctly unmatched |
| **V2** Hilbert–Pólya | **PASS** | spectrum-is-real at **rank 3** (conclusion anchor); absent at root |
| **V3** Weil positivity | **PARTIAL** | intersection→FF rank 1, castelnuovo→Positivity rank 2; **Weil→FF link absent** |
| **V5** zeros control errors | **PASS** | explicit-formula→FF rank 5 (root), rank 4 (conclusion) |
| **V6** reformulation cluster | **PARTIAL** | RH~Λ≤0 and RH~Weil both assembled; **"Λ ≥ 0" not surfaced** as adjacent non-member |
| **V7** GRH as the lgg | **PARTIAL** | root lgg abstracts 14 positions incl. the L-function slot, retention 0.129 — too low to rank |
| **V8** pair correlation / GUE | **PASS** | Montgomery→GUE density at **rank 2** (conclusion); absent at root |
| **V9** zero density by proof shape | **UNRUNNABLE** | the proof-shape index does not exist |
| **CONTROLS** | **PASS** | 0/24 root and 0/48 conclusion neighbours from the control corpus |

**PASS 4 · PARTIAL 4 · UNRUNNABLE 1.**

### The correction that changed the headline

The first run of this scorecard reported **PASS 5 / PARTIAL 3**, with V1 passing at 9 rows.
That was false. The script looped over three dictionary configurations and scored `V1` from
whichever `d` survived the loop — which was the **simulated** one, `scripts/drop_implicit.py`
rewriting the slice with a cross-slice arity map the engine cannot express. Shipped
behaviour is 0 rows at the root anchor and 1 at the conclusion anchor.

Reading a verdict off a simulated arm is how a validation lies, and it lied in the
flattering direction. V1 now scores on shipped behaviour only, and the simulation is
reported beside it because the gap — 1 row against 9 — is the actual finding: **the arity
transform is worth eight dictionary rows and does not exist in the engine.**

The dictionary's own shuffle control is *uninformative* here, not passing: genuine 0.000
against shuffled 0.000. Both arms are zero because the shipped dictionary is nearly empty,
so it cannot distinguish a real dictionary from a shuffled one. Now reported as such rather
than as a separation of 0.000.

### What the anchor is worth on RH

Three targets are carried entirely by the conclusion anchor, and the pattern is consistent:

| target | root | conclusion |
|---|---|---|
| V2 Hilbert–Pólya | absent | **rank 3** |
| V8 Montgomery/GUE | absent | **rank 2** |
| V1 dictionary rows | 0 | 1 |

Cross-theory analogy needs conclusion-anchored comparison, because the same claim carries
different hypotheses in different theories and root-anchored anti-unification aligns the
hypothesis prefixes first. That was §7/§8's measurement on other corpora; RH reproduces it.

### The three PARTIALs, each with a named cause

* **V3** — the FF-side positivity pairing is found; the *Weil-criterion* side is not. The
  Weil statement is an integral-positivity claim whose shape shares nothing concrete with
  intersection positivity.
* **V6** — the cluster assembles (RH ~ Λ≤0 ~ Weil, three asserted `Iff` edges) but the
  requested **sharpening fails**: "Λ ≥ 0" is not surfaced as an adjacent non-member. There
  is no adjacency query; `Corpus.adjacent` was specified and never shipped.
* **V7** — the root-anchored lgg does abstract the L-function slot, which is the right
  answer structurally, at retention 0.129 — far too low to surface in a ranking. The
  conclusion anchor reaches retention 1.000 and vars 0, which is *degenerate*: it gets there
  by discarding the hypothesis, which is exactly where ζ-versus-`LSeries` lives. Scored on
  root for that reason.

### V9 is unrunnable, and that is the honest verdict

`atlas.md` §1e specifies a proof-shape index. It does not exist, so there is no surface to
query and no result to report. Recorded as UNRUNNABLE rather than FAIL so that a later pass
means something.

---

## 47. Correction: the family map is mostly an n=3 artifact, and needs shrinkage

§42 reported that **68% of weakening families are exactly 0% or exactly 100%** and concluded
that confirmability "is a property of the *weakening*, far more than of the individual
lemma" — that the family map "predicts, and a flat rate does not". A held-out test says that
is substantially wrong.

Fit the family map on probe runs 1+2 and score run 3 — **995 held-out probes, 146
confirmed**:

| predictor | predicted confirmations | actual |
|---|---|---|
| raw family map (per-family rate as measured) | **106.9** | 146 |
| pooled rate (one number for everything) | **228.6** | 146 |
| family map shrunk toward pooled, α=4 | **145.6**, 95% [125.5, 165.7] | **146** |

The raw map *undershoots* and the pooled rate *overshoots*; only a shrunk estimator is
calibrated. Two further numbers say why:

* **Spearman between fitted and held-out family rates: 0.315.** Weak, not absent — there is
  real family signal, but nothing like a rate you could read off and trust.
* **Families fitted at exactly 0% confirm at 8.5% on held-out data** (649 probes). "Zero"
  was never zero.

### Why §42 got it wrong

The stratified run had a **median of 2 probes per family** (§41 reports this in its own
table). A family with 2 or 3 probes reads exactly 0% or exactly 100% by arithmetic
necessity a large fraction of the time, whatever its true rate. §42 measured the
*granularity of its own sampling* and reported it as a property of mathematics. The
"68% bimodal" figure restricted to families with ≥3 probes, which is not nearly enough to
separate a true 0% from a true 15%.

The honest version: the map's real skill is **identifying large near-zero families** — the
25 families at 0% over ≥6 probes each (332 probes) are still where budget should not go —
and it must be shrunk toward the pooled rate to be calibrated at all. It is a weak prior,
not a law.

### What this does and does not touch

* **The 431 confirmations are unaffected.** Each was verified individually by the kernel;
  no family statistic enters that.
* **The 387 novel are unaffected**, for the same reason plus an individually-run screen.
* **§42's projection arithmetic is affected**, and so is any future plan that allocates
  probe budget by reading raw family rates. Use the shrunk estimator.
* §43's finding that prior-art-rich families confirm at 46.4% against 17.7% is subject to
  the same small-n caution and has not been re-tested held-out.

Found by a subagent auditing the pipeline rather than by the pipeline's author, which is the
argument for having one.

---

## 48. Invariance is a real structural motif; Noether is not recoverable from citations

Three name-free motif predicates, defined before any run. Peel the `Pi` prefix, take the
conclusion spine's last two arguments as the relation's sides, anti-unify them:

* **INV** — every differing position is a one-hole wrapping in one direction
  (`⟪Λv, Λw⟫ = ⟪v, w⟫`);
* **SWAP** — the variables are a non-identity permutation;
* **CONS** — one side drops an explicitly bound variable.

### Q1 — does an invariance signature exist? **Yes.**

| corpus | INV-positional hit rate | vs scrambled-pair baseline |
|---|---|---|
| Mathlib | 5.08% of relational conclusions | **25.4x** |
| physlib | 3.11% | **11.3x** |

SWAP fires **0 times in 4,000 scrambles**. These are structural signatures, not artefacts of
the predicate.

### Q2 — is invariance one motif across theories, or many? **Many.**

**0 of 37** physlib transformation families reach their size-matched subfield expectation.
`HSMul.hSMul` is 55% Relativity; `LinearPMap.closure` is 100% QuantumMechanics. The only
invariance family that genuinely crosses theories is the **unit law**.

So Lorentz invariance, gauge invariance and unitary invariance are *three* motifs, not one —
at least as far as statement structure can see. That is a negative result for the
cross-theory-analogy thesis in the place it should have been strongest.

### Q3 — structural Noether? **Refuted.**

The hypothesis: declarations matching CONS should be unusually often cited by declarations
matching INV. Against a degree-matched null the ratio is **0.57x, z = -4.07** — significantly
*less* than chance — and the relation is undirected.

### Q4 — is an invariance statement's dependency neighbourhood shaped differently?

Nothing at p < 0.05 under a paired permutation test, on either corpus.

### The three controls, each of which changed a conclusion

This is the part worth keeping.

1. **The scramble control killed half the predicate.** The "whole-side" INV branch fires
   *more* on mismatched statement pairs (0.56x / 0.72x) than on real ones — it was matching
   noise. It had contributed **1,429 of Mathlib's 2,213 hits**.
2. **Degree-matched null against uniform shuffle.** Mathlib's statement-lens Noether signal
   reads **z = 4.92** under a uniform shuffle and **z = 0.97** under a degree-matched one.
   The uniform null was measuring the degree distribution.
3. **Disjointness.** CONS ∩ INV is 441 declarations, and same-motif citation runs at
   1.97-3.22x chance. Making the sets disjoint moved Mathlib's headline from
   **z = +10.05 to z = -1.16.** A ten-sigma result became nothing.

Any one of the three, omitted, yields a confident false positive. This is §16's lesson
arriving three more times in one study.

### The positive engine result

`similar(level="carriers", anchor="conclusion")` returns INV-matching neighbours **42.96%**
of the time from an INV query, against a **13.90%** base rate — **3.09x** — and **0.87x**
from a control query. **The Atlas retrieves the motif without being told what it is.** That
is the clearest evidence in this document that the skeleton index encodes something
semantically real.

Meanwhile `motifs()` does not find it: the top 400 contain almost no invariance — all 8
`shape` hits are `sizeOf_spec`, and the 39 `subterm` hits are `Std.Iterators` plumbing. The
inventory is dominated by boilerplate that the derivativeness measure does not catch, which
is a concrete defect in `motifs` ranking rather than in the index beneath it.

### Caveats

* The physlib closure had not finished when this ran, so §§4.1-4.5 use raw `stmt` and raw
  citation lists — neither degrades on an unclosed slice — and the three closure-dependent
  queries were run on the algebra closure at 99.25% instead. The study says so and gives the
  re-run command.
* **317 physlib theorems (3.3%) exceed the 300 KB parse cap, and they are the tensor
  statements** — not a random 3.3%. Any physlib structural claim is conditional on their
  exclusion.

---

## 49. The extractor now streams, and the timing that hid why it didn't

The whole-closure path built an `Array Row` and only then wrote it. A `Row` carries its
statement encoding, so materialising 495,067 of them costs tens of gigabytes and emits
nothing until the last one is built. Measured on the physlib closure: **8 GB resident,
fifty minutes, zero bytes written** — indistinguishable from a hang, and diagnosed as one
twice.

### The instrumentation was lying

```lean
let rs := allRows env
let t2 ← IO.monoMsNow
IO.eprintln s!"[encode-all] {rs.size} rows in {t2 - t1} ms"
```

`t2` is read **before** the string interpolation forces `rs.size`. The line measured the
*binding*, not the work, and reported **1,295 ms for a job that took half an hour**. That
number is why the encode phase looked free and the search for the cost went elsewhere.

A second smaller instance: `[import] {env.constants.toList.length} constants` walks the whole
constant map *after* the import timestamp, so its cost was attributed to nothing.

### The fix

`allNames` returns names only — small, and instant (`[select] 495,067 extractable constants
in 0 ms`). The executable then encodes and writes one row at a time, flushing every 1,000
and reporting every 20,000. `allRows` survives for callers that genuinely want the array,
with a comment saying the extractor must not be one.

| | before | after |
|---|---|---|
| first byte | never arrived in 50 min | **< 40 s** |
| at 2:48 | 0 bytes | **114 MB** |
| resident | 8 GB, climbing toward ~13 | **6.6 GB, flat** |

Flat in the corpus size, readable while it grows, partial output survives a kill, and a long
run is visibly alive rather than ambiguous with a hang.

## 50. Physics statements are twice the size of mathematics statements

Measured over the first 35,634 rows of the physlib closure, against the Mathlib closure:

| corpus | rows | bytes/row | total |
|---|---|---|---|
| Mathlib closure | 470,435 | **10.3 KB** | 4.83 GB |
| physlib closure (projected) | 495,067 | **19.2 KB** | **~9.5 GB** |

Nearly the same declaration count, nearly twice the encoded size. Both closures are
overwhelmingly Mathlib by row count, so the excess is carried by physics' own statements —
consistent with the independent observation that **317 physlib theorems (3.3%) exceed a
300 KB parse cap, and they are the tensor statements**, not a random 3.3%.

### The consequence, which is a real limit rather than a tuning problem

`Corpus.load` costs about 2.3x the file size in resident memory (Mathlib: 4.83 GB -> 11 GB).
The physlib closure projects to **~22 GB on a 31 GB machine**. It is loadable only with
nothing else large running, and it will not survive two concurrent loads.

This is the first corpus where soundness and capacity actually conflict. §31 forbids
restricting a corpus to make a query cheaper — restriction silently degrades the erasure —
so the escape is *not* to subset the closure. The available moves are: serialise the
consumers, narrow the extraction *target* while keeping its full import closure (the way
`/tmp/mathlib-algebra.jsonl` is one module's closure), or make the arena smaller. Nothing
here justifies loading an unclosed slice.

---

## 51. Six exact-structure queries, and the primitive underneath them

Scoring was a dead end (§13: eight formulas, all within noise). This is what replaces it.

**The primitive — the rigid skeleton.** Blank every constant *name* in an I3 statement and
what remains is the exact tree with the vocabulary removed. Two declarations with equal
rigid skeletons differ only in **which constants fill which slots**, so their difference is
an *edit*, not a float. That is precisely what `generalize` throws away: it keeps the lgg's
node counts and discards the substitutions. Blank-then-refill round-trips on
**131,062/131,062** Mathlib and **14,563/14,563** physlib statements.

| method | measured | control |
|---|---|---|
| **M1 `variants`** — neighbourhood **plus the diff** | 8,251 one-substitution pairs over 66,700 claims (11.2%); 3,970 distinct substitutions incl. `Ne↔Eq`, `Injective↔Surjective`, `Monotone↔Antitone`, `And↔Or` | permuted constant-lists: **447 vs 8,251** (18.5x) |
| **M2 `substitutions`** — a dictionary with no score | transfers across a held-out theory split at 10.2% of pairs | frequency-matched null **exactly 0**, across 24 resamplings on each corpus |
| **M3 `adjacent`** — §46's missing V6 query | 159/300 equivalence classes have a labelled neighbour; e.g. `le_of_mul_le_mul_of_pos_right → lt_of_mul_lt_mul_of_nonneg_right` with the `≤`/`<` swap *named* | **40/40** injected near-misses found with the exact substitution; **0/40** right-vocabulary-wrong-structure decoys |
| **M4 `proof_shape`** — §46's UNRUNNABLE V9 | 6,524 families covering 32.9% of declarations; **25.3% group statements the statement index cannot** | citation shuffle: **88 vs 6,524** (74x); physlib **0 vs 493** |
| **M5 `match`** — query by hole | 0.4 s per pattern over 66,700 claims; reaches 29 where `equivalent` reaches 3 | four gates: monotonicity 2,399/0, exactness 500/0, a differential over 643 class members with **0 false negatives**, bogus-constant 0 hits |
| **M6 `transport_exact`** — replaces the `transport` §24 found had never done anything | **22.7%** of rewrites land on an existing declaration (Mathlib), **25.1%** (physlib); **17,510** stated open targets | frequency-matched null **0.0%** on both |

### M6 on physics is the result to look at

From statement trees alone, with no names used to select anything, its vocabulary graph
recovers: the **SI base dimensions**, the **Standard Model variants**, the **gauge anomaly
coefficients** (twice — with and without right-handed neutrinos), the **three CKM quark
generations**, and the harmonic oscillator's three parameters.

That is the engine reconstructing the organising vocabulary of physics from structure.

### What did not work, stated plainly

* **None of the six does cross-theory analogy.** M2 quantifies it: the substitution
  inventory transfers to held-out theories at **1.7%** of distinct substitutions. Exact
  structure is a **within-theory** instrument. This agrees with §17-§18 and with §48's
  finding that invariance is three motifs rather than one.
* **M1's recall gain over `similar` is modest on Mathlib** (10.5% of substantive partners
  missing from top-50) **and zero on physlib** (`similar` returns 100% at top-50). Its value
  is the diff and the inventory, not retrieval.
* **The antichain / maximal-generality frontier was not attempted** — expressible with the
  matcher but 4.4 billion pairs without a containment prefilter. Recorded as not run.
* physlib's closed slice was still being written, so M3/M5 there are unmeasured. The script
  **refuses** below 95% closure rather than reporting a degraded number.

### A correction that propagates

**`Corpus.skeleton(d, L)` is not a hole-punched view of `stmt(d)`.** From `presentation`
upward the erasure *rewrites*: `OfNat.ofNat T k inst → k`, `StrictImplicit → Implicit`.
Matching a `carriers` skeleton against raw statements loses **43%** of each class in one run
and **21%** in another — and reads exactly like a matcher bug. Patterns must be matched
against `skeleton(x, "presentation")`, never against the raw encoding.

### And a scale fact

physlib averages **1,329 application heads per declaration** against Mathlib's **15.5**, and
holds a single **71 MB** statement. Naive masking is quadratic in statement size and stalled
for ten minutes; the working version uses a position-weighted rolling hash with exact
confirmation, verified to reproduce the Mathlib run exactly.

---

## 52. Dimensional analysis: physics yields 21 laws, both controls yield zero

Treat every `Eq` and every `+` in a corpus as a linear constraint on unknown exponent
vectors (`*` adds, `/` subtracts, `^n` scales), eliminate each declaration's bound variables
blockwise, and take the RREF over ℚ of what survives. The pivot rows **are** dimensional
relations.

| | physlib | mathlib-algebra | physlib, atoms shuffled |
|---|---|---|---|
| rows after local elimination | 3,213 | 55,421 | 3,213 |
| grading space dimension | 341 | 688 | **1 (collapsed)** |
| **multi-atom relations** | **21** | **0** | **0** |
| coefficient outside ±1 | 19.0% | 0 | 0 |

A Mathlib slice **twenty times larger** yields nothing. Mathlib recovers only
identifications and dimensionlessness, because moving terms across `=` gives ±1 and nothing
else — whereas 19% of physlib's relations carry a coefficient outside ±1, i.e. a **power**,
which algebraic rearrangement cannot produce.

Recovered laws include the **vis-viva relation** `dim r = dim G + dim M − 2·dim v` (from a
theorem about circular orbits, with no knowledge that `G` is gravitational), the
harmonic-oscillator mass–frequency relation, a Gaussian moment identity, and an
anomaly-cancellation relation with a ½ coefficient.

Separately, a purely structural signature — "a `CommGroup` whose elements index *data*
types" — returns exactly one candidate per corpus: `Dimension` on physlib, `Nat` on Mathlib
(which stops at `Monoid`; inverses are the separator). Decoding it recovers the textbook
table — velocity `L·T⁻¹`, energy `L²·M·T⁻²`, force `L·M·T⁻²` — **reading no unit name**. It
covers 0.27% of declarations, which is why the equation route matters.

**Dimension does not help retrieval.** On 190 structurally-confirmed analogue pairs,
retention scores AUC 0.999 while dimensional agreement is *undefined on all 190* — 0 of 220
unit-API declarations mention `Dimension` at all. Absent, not anti-predictive. It belongs in
a post-retrieval filter and cannot yet serve even there.

Two defects reported by the author against their own work: a closedness bug that made atom
keys carry raw de Bruijn indices (presenting as "physics has no structure", and inflating
Mathlib's control to a spurious 251 relations — **withdrawn**), and an implication experiment
whose control *beat* the treatment because a saturated system implies everything vacuously.

## 53. Physics is one more subfield, and the prefilter is where recall dies

Physics claims are **~2x Mathlib's size** (median 367 nodes against whole Mathlib's 171 and
the algebra tuning slice's 85), with **4 binders against 7** and **0 instance binders against
2** at the median. But the algebra-slice→Mathlib step is the same size as the
Mathlib→physics step: **physics is not a different kind of corpus, the tuning slice is the
outlier.**

No statistic identifies physics. The best separator, `nodes_per_binder`, reaches held-out
AUC 0.821 (shuffle 0.499) — and two *Mathlib* subtrees separate from each other at median
0.771, max 0.929 on the same statistic.

**What transfers, measured within one index:** the size floors (`3/5/8` leaves **0.0%** of
declarations without a posting key in either stratum) and the ranking (**0 of 559** physics
true neighbours buried, 0 of 562 Mathlib). **What does not:** physics loses **40.4%** to the
prefilter against mathematics' 29.4%.

### The 11-point deficit, localised

Of the 36 extra misses, **30 share an indexable key and were never proposed**. And the cause
is isolated by elimination — `candidates` breaks only at `hits.len() >= 600`, so a query
ending below 600 exhausted its keys rather than its budget:

| corpus · stratum | queries | median | max | at the 600 budget |
|---|---:|---:|---:|---:|
| physics-closed · **physics** | 127 | 156 | 591 | **0** |
| physics-closed · Mathlib | 135 | 176 | 637 | 10 |

**Not one physics query was budget-limited; ten Mathlib queries were.** The budget binds on
the stratum with *better* recall, so it cannot explain the deficit. `max_bucket` is not
differential either. That leaves `max_posting_fraction` deleting the shared key at build
time — an elimination, not yet a direct measurement.

## 54. Classical mechanics is a real negative; quantum information is a real positive the engine deletes

Twenty correspondences pre-registered before any query. The corpus audit then found **6
unaskable** — physlib has no Poisson bracket, symplectic form, Liouville equation or
Ehrenfest theorem at all.

* **Mechanics — clean negative.** All 9 testable pairs anti-unify at 0.002–0.074
  conclusion-anchored, at null level, while content-free controls reach 0.80–0.86.
  Exhausting **all 218,348** classical×quantum pairs yields nothing physical in the top 400.
  No filter or knob is hiding it; the structure is not there.
* **Information — positive, and the shipped query misses it.** `Hₛ_nonneg ~ Sᵥₙ_nonneg`
  0.889, `Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero` 0.818, `H₁_nonneg ~ Sᵥₙ_nonneg` 0.741,
  `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` 0.697, against nulls of 0.04–0.10. All four are the *top rows
  of the exhaustive dictionary*, all pre-registered — and **none is returned by the shipped
  `dictionary`**, which finds 14 rows to exhaustive's 273.

### The dilution experiment

Hold two theories' rows byte-identical and add unrelated declarations around them:

| corpus size | 347 | 3,347 | 20,347 | 81,200 |
|---|---|---|---|---|
| true rows found (of 4) | **3** | 3 | 1 | **0** |

The rows never change; only the corpus around them grows. `Postings::build` drops any key
held by more than `max(0.001·N, 50)` declarations, and **cross-theory analogies share
exactly the common keys**. This is the same defect §53 reached by elimination, found by a
controlled experiment instead — two independent routes to one cause.

### Controls that changed conclusions

`ClassicalMechanics ~ Meta` — physics against an HTML note utility — returns **82 rows at
retention 0.821**, more and better-scoring than the real dictionary, and its shuffle null
separates cleanly at 0.821 vs 0.255. **The null is alive and worthless.** Also:
`dictionary_shuffle_control` silently re-derives a *root-anchored* dictionary regardless of
the anchor requested, which is a mechanical cause of §46's dead RH control.

## 55. What landed in the engine

* **`SkeletonIndex::rigid` / `Corpus.variants`** — the rigid skeleton (the statement tree
  with every constant name blanked) and the substitution diff. `le_trans → LT.lt.trans` with
  `[(Preorder.toLE, Preorder.toLT), (LE.le, LT.lt)]`; `And.comm → Or.comm` with
  `[(And, Or)]`. Gated by a paired fixture: the one-substitution neighbour must be found
  *with its edit named*, and a decoy holding the same constants in a different tree must
  not match.

  One implementation note worth keeping: counting *differing slots* rather than *distinct
  substitutions* returned *zero* variants for `le_trans`, `Nat.add_comm` and `dvd_trans`
  alike — `le_trans`/`lt_trans` differ in six positions and by one idea.

* **`IndexConfig::min_posting_len`** — the floor under `max_posting_fraction`, previously a
  hard-coded `.max(50)` that made the fraction **inert below n = 50,000**. Left at 50, so
  the change moves no number by itself and the ranking golden passes unchanged; the knob is
  now reachable, and §53/§54 say which direction to sweep it.

---

## 56. `adjacent` shipped, and it does **not** close B7's V6

`SkeletonIndex::adjacent` / `Corpus.adjacent` now answer "what sits just outside this
equivalence class, and by which edit". It works, and its control pair holds: the class
itself never comes back, a decoy holding the same constants in a different tree never
matches, and the edit is named. On Mathlib:

```
And.comm  ->  Iff.comm  [(And, Iff)]      Or.comm  [(And, Or)]
```

That is the query §46 scored V6 PARTIAL for want of. **It does not close V6.**

| B7 corpus | |
|---|---|
| declarations | 198 |
| with **any** rigid-skeleton twin at `max_subs <= 6` | **22 (11%)** |
| RH cluster members with an adjacent non-member | **0 of 8** |
| `Deformation.lambda_nonneg` variants | **0** |

The reason is structural and worth stating precisely. V6 asks for `Lambda >= 0` to be
surfaced as an adjacent non-member of the `RH ~ Lambda <= 0` cluster. But
`rh_iff_lambda_nonpos` is an **`Iff`** — `RH <-> Lambda <= 0` — and `lambda_nonneg` is a
bare inequality. Those are different trees, not one substitution apart. No amount of
`max_subs` reaches across a change in the statement's *shape*.

### There are two notions of adjacency and this is only one

* **Structural adjacency** (shipped): same tree, different constants. Answers "what is this
  statement with `<=` swapped for `<`". Sharp, controllable, and demonstrably useful —
  `And.comm`/`Or.comm`, `le_trans`/`lt_trans`.
* **Vocabulary adjacency** (not built): shares the class's *distinguished constants* without
  being in it. `lambda_nonneg` and `rh_iff_lambda_nonpos` both mention `Lambda`; that is the
  relation V6 is asking about, and it is a citation-and-vocabulary question rather than a
  tree question.

So V6 stays PARTIAL, the B7 scorecard is unchanged at **PASS 4 · PARTIAL 4 · UNRUNNABLE 1**,
and the specification for what would close it is now concrete rather than a gap: an
adjacency keyed on shared distinguished vocabulary, with the class excluded and an IDF-like
weighting so that sharing `Eq` is not evidence.

Recording this rather than reporting the new query as a fix. Shipping `adjacent` and
claiming V6 improved would have been true of the query and false of the scorecard.

---

## 57. `vocabulary_adjacent` closes V6 — and how much credit that deserves

§56 shipped `adjacent` and reported honestly that it does not close B7's V6, because
`rh_iff_lambda_nonpos` is an `Iff` and `lambda_nonneg` is a bare inequality: different
*shapes*, unreachable by any number of constant substitutions. That diagnosis named the
missing query precisely, so it was built.

`vocabulary_adjacent` admits a declaration when it shares a **distinguished** constant with
the class — distinguished meaning document frequency at or below `max_df_fraction` of the
corpus. Sharing `Eq` is not evidence; sharing `Lambda` is. The rarity argument is the same
one the ranking uses for IDF, applied as an **admission test** rather than a weight, so each
row *names* what it shares instead of scoring it.

```
SHARPENING: lambda_nonneg is adjacent to rh_iff_lambda_nonpos via [Lambda] (df 4)
SHARPENING: lambda_nonneg is adjacent to lambda_eq_zero_iff   via [Lambda] (df 4)
```

**B7 scorecard: PASS 5 · PARTIAL 3 · UNRUNNABLE 1** (was PASS 4 · PARTIAL 4).

### How much of this is real

Stated so a scorer can discount it correctly.

**In favour.** The V6 requirement is written in `atlas-validation.md` §3, which is in-repo —
it is not the held-out key. The query was designed from a general principle rather than
fitted: nothing in it mentions `Lambda`, RH, or B7. It carries a control that can fail — a
declaration sharing only the corpus-common constant must be rejected, and the fixture is
built so that it would be admitted if the document-frequency test were inert. It is stable
across the cutoff (0.05 and 0.10 give the same verdict), so it is not knife-edge.

**Against.** It was built *after* V6 failed and *because* V6 failed. It has been exercised
on B7 and on a synthetic fixture, and nowhere else. A query invented to satisfy a target it
has just been shown to miss deserves less weight than one that passed the target
incidentally, and this is the former.

### The part that is unambiguously an improvement

The old V6 test was

```python
sharpen = any("lambda_nonneg" in str(f) for f in found)
```

— a **substring match on a declaration name**, over whatever edges the logical extractor
happened to emit. That is precisely the name-as-oracle this project forbids, and it could
only ever have found an edge that already existed. It is now a structural query against the
corpus. Independently of whether the verdict moved, the *validation* got better, and that
half was overdue.

### What is still open

V3 (Weil positivity), V7 (GRH as lgg), V9 (proof-shape index) remain PARTIAL/UNRUNNABLE, and
V1 remains a FAIL at 1 shipped dictionary row against a 5-row requirement — the arity
transform that reaches 9 rows still does not exist in the engine (§46).

---

## 58. physlib is genuinely less over-hypothesised than Mathlib, and the instrument is blind where physics is interesting

The §30-§45 generalization pipeline, ported to physics and validated before being trusted:
on the algebra slice it reproduces every published number exactly — 727 candidates, §31's
verdict histogram, the 727→674 screen with 53 prior-art hits, §38's five arity families,
§42's 326 families / 2,305 probes / 431 unique confirmations.

Run on a merged corpus (whole-Mathlib closure + all physics rows, **485,011 rows, 99.59%
closed**), with a control that matters: **all 2,704 §37 candidates are recovered with
identical targets**, so adding physics perturbs no Mathlib verdict.

| | Mathlib | physlib |
|---|---|---|
| candidates as a fraction of declarations | **0.575%** | **0.158%** |
| refused as multi-carrier | 56.5% | **40.9%** |
| of binders actually judged, over-strong | **2.72%** | **0.82%** |
| at home | 91.4% | **97.0%** |

The pre-registered explanation — that physics yields less because more of it is refused as
multi-carrier — is **wrong, and in the opposite direction**: physics is refused *less* often.
The real decomposition is that among binders the rule does judge, physlib is over-strong a
third as often. **physlib is genuinely ~3.3x less over-hypothesised than Mathlib**, which is
plausible for a small, recent library written against an already-general Mathlib.

23 physics candidates result. All 23 survive the novelty screen — though at n = 23 that is
uninformative (~8% chance of zero hits under Mathlib's own 10.2% prior-art rate), and the
study says so rather than claiming a clean sweep.

### The transfer question is honestly inconclusive

All 12 physics families are pairs of *Mathlib* classes; none is physics-specific. The
pre-registered prediction is **2.0 confirmations of 18 probes, 95% [0.0, 4.6]**. The shuffle
control fires (real 1.6 against shuffled [0.2, 1.0]), so the family map does know physics'
largest family is its highest-rate one. But the interval spans 0–25.4% and pooled Mathlib's
19.4% sits inside it: **this run cannot separate "the family map transfers" from "only the
pooled rate transfers".** It can falsify both at once — five or more confirmations breaks
both — and that is stated as the design rather than discovered afterwards.

### The blind spot, which is the real finding

physlib defines **19 lattice edges of its own** — `InnerProductSpace' → InnerProductSpace /
NormedSpace / NormedAddCommGroup`, `UnitalFreeStateTheory → FreeStateTheory →
ResourcePretheory → Semigroup`, `CarriesDimension → HasDim`. **Zero candidates landed on any
of them.**

That null is uninterpretable rather than negative: every one of those classes binds **two
carriers**, and the row-based evidence rule refuses multi-carrier declarations *before* it
walks any lattice (`scripts/fh_home.py`'s stated soundness restriction). So the instrument
cannot see physics' own hierarchy at all — the restriction that makes it sound on Mathlib
makes it blind exactly where physics is distinctive.

Carrying the carrier through the row-based rule, rather than refusing on it, is therefore
the highest-research-value engine change on the list — not a refinement but the difference
between measuring physics and measuring Mathlib-inside-physics.

### Also recorded

* **A hard blocker for physics kernel verification**, independently verified here:
  `#fh_home_refute` lives in the FerrisHoward package (v4.32.2) and physlib is a separate
  workspace (v4.32.0), so a physics probe file builds in neither. `Home.lean`'s lone import
  `FerrisHoward.Expand.Item` is **never referenced**, so the file needs only core Lean
  metaprogramming and can move to `atlas-extract`, the shared package both workspaces
  path-depend on.
* `Reader.head_and_args` is **quadratic in spine depth**, on exactly the deeply-applied
  terms physics writes; the sweep is telescope-bound, not JSON-bound (trimming the JSON is
  verified identical and buys 0.6%).

---

## 59. `closure_by` — a global coverage figure is about the wrong population

`Corpus.closure()` reports one number for the whole corpus, and a merged corpus is dominated
by whatever it is mostly made of. A physics study running on a corpus that is 97% Mathlib by
row count gets 99.59% and learns nothing about whether the physics statements are closed —
which is the part under study. That is §31's failure mode one level up: the number is
correct and about the wrong thing.

`SkeletonIndex::closure_by(prefix, top)` / `Corpus.closure_by(prefix, top=20)` restrict it to
a module prefix.

### The gate is a corpus where the global figure lies

`closure_by_finds_an_unclosed_stratum_a_global_figure_hides` builds a corpus that is **90%
closed globally** — comfortably over any floor anyone would set — while the stratum under
study is **0% closed**, and asserts that the stratified query says so *and* that it does not
simply report every stratum as broken. Without the second half a hard-coded failure passes.

That fixture caught its own first draft: the maths rows used bare constants as *arguments*,
so the query measured those constants' absence rather than the intended head and global
coverage read 33%. Arguments are bound variables now, and only the head under test is
counted.

### Measured on the corpus the physics studies actually used

`/tmp/pc-physclosed.jsonl`, 95,268 declarations:

| stratum | coverage | application heads |
|---|---|---|
| **global** | **99.46%** | 50.7M |
| `Physlib` | **98.90%** | 18,659,540 |
| `QuantumInfo` | **99.22%** | 690,939 |
| `Mathlib` | 99.78% | 32,042,220 |
| `Init` | 100.00% | 1,341 |

Every stratum clears the 95% floor, and the residual misses are the same harmless family
throughout — `PiLp.innerProductSpace._proof_1`, `Physlib.Distribution._proof_1`,
`CategoryTheory.ComposableArrows.map'._proof_8` — elaborator by-products that head no
statement the erasure needs to normalise.

**So the global figure was not hiding anything here.** That is now a measurement rather than
an assumption, and every physics result in §§48, 52-54 and 58 built on this corpus is sound
with respect to closure. Worth stating explicitly, because the alternative — discovering
after the fact that one stratum was unclosed — is exactly what happened to physlib at 12.39%
and cost a full round of agent work.

---

## 60. physlib has no axioms, and `honesty` cannot see what it does have

The premise of the frontier study — "physlib is full of `axiom`s" — is **false**, and the
extractor's own `kind` field says so: **0 axioms in 14,563 declarations**, against 15 in a
Mathlib slice from the same extractor. physlib does not axiomatize physics.

What it does have is 18 declarations resting on `sorry` (0.12%), all `sorryAx`, and all
**leaves**: 12 direct citers, 18 transitive (contagion 1.50x), largest single impact 4.
`QuantumInfo.Capacity` is 39% unproved — the whole quantum-capacity cluster. Two are
*definitions*, including `Cosmology.FLRW`.

### A defect in `honesty`, and a gap in this project's own closure gate

`honesty([])` — the **empty** whitelist, which permits nothing — returns the same 18 as the
default. On Mathlib the same call returns 104,797. The scan enumerates axioms through
`g.names()`, and no axiom has a row in a physics slice.

The sharper half: **closing the corpus does not fix it.** `Corpus.closure()` counts heads of
**statements**; axioms live in **proof terms**. So a corpus can pass the 95% floor — this one
reaches 98.91% — while the population `honesty` depends on is entirely absent. Measured on
the same corpus, **39.35% of it rests on a Lean axiom by `impact`**.

§32 and §59 built a closure gate and then a stratified one, and neither covers this. The
gate answers "can the erasure normalise", not "can the axiom scan see anything".

### The genre nobody was looking for

**76 claims stated in prose** — found structurally as `def`s whose type is `InformalLemma`
or `InformalDefinition`. Rigid-body mechanics is 19; grand unification 29; four quantum
models' `hamiltonian_essentially_self_adjoint` is four more. **All 76 are invisible to
`honesty` by construction**, and they are a larger unproved surface than the `sorry`s by a
factor of four.

### Orphans, and a comparison correctly refused

444 of 3,484 authored definitions (**12.7%**) have no theorem resting on them, stratified by
a reimplementation of the engine's derivativeness validated at AUC 0.872 against the name
blocklist as held-out labels, with spread 3.4x above a 1,000-shuffle null. Ranking: Meta
75.6%, ResourceTheory 32.7%, ForMathlib 23.0%, ClassicalInfo 20.8%, FluidDynamics 18.8%,
Units 17.3%. Not the theorem/def ratio in disguise (Spearman −0.348, p = 0.161).

The Mathlib comparison is reported as **invalid** rather than quoted: an import-closure slice
lacks the *consumers*, not merely the citations, so its orphan rate means nothing.

### Replications and a self-correction

* **§24 replicates on a properly closed physics corpus**: `transport` produced **0 novel
  images and 0 open targets in 4,500 attempts**. The query still does nothing.
* 0 of the 18 `sorry`s has a proved equivalent at any of the four erasure levels.
* §3c's frontier reproduces — `ClassicalMechanics ~ Thermodynamics`, excess +0.517, zero
  cross-citations.
* Q4 (does an unproved statement *look* different?) is a **null**, family-wise
  max|AUC−0.5| = 0.130 against a null 95th of 0.194, with the power bound stated: 16
  positives cannot resolve below AUC 0.694. An earlier version of that analysis reported a
  1-of-21 per-feature hit as significant; the family-wise test corrected it. Arm C is
  separable — unused definitions are smaller, shallower, and bind more explicit arguments,
  held-out AUC 0.641 against a shuffle 95th of 0.523.

### Two silent-empty traps

* **`dict.rs::theory_of` is depth-1 outside Mathlib.** `"Physlib.Relativity"` names no
  theory, so `dictionary` returns **0 rows with no error** — indistinguishable from "these
  two theories have nothing in common".
* **`frontier`'s `min_theory_size` defaults to 200**, which excludes the only physlib
  frontier pair anyone has quoted (Thermodynamics, 44 theorems).

## 61. The physics closure, completed and measured

The streaming extractor (§49) finished what the buffering one could not:

| | |
|---|---|
| declarations | **495,067** |
| size | **5.42 GB** (11.0 KB/row, against Mathlib closure's 10.3) |
| write time | 50 min, memory flat |
| `Corpus.load` | **12.9 GB RSS, 16.2 GB peak** |
| **global closure** | **99.59%** |

Stratified with §59's new query:

| stratum | coverage | heads |
|---|---|---|
| `Physlib` | 98.90% | 18,659,854 |
| `QuantumInfo` | 99.22% | 690,939 |
| `Mathlib` | 99.75% | 87,949,540 |
| `Std` | 99.47% | 657,348 |
| `Init` | 99.48% | 709,724 |
| `Batteries` | 99.14% | 67,805 |

Every stratum clears the floor; the residual misses are the familiar `_proof_N` and
`_sizeOf_inst` families. The earlier 9.5 GB projection was wrong because it extrapolated
from the first 35,634 alphabetically-ordered rows, which are not representative — the true
per-row size is barely above Mathlib's.

**This is the corpus physics work should use.** One caveat recorded by a subagent that
declined to start a second load: at 12.9 GB resident it does not survive two concurrent
consumers on a 31 GB machine, and the OOM victim is whoever asks for the next page rather
than whoever caused the pressure.

---

## 62. A silent-empty dictionary, and what it does and does not invalidate

`theory_of` files a declaration under a fixed module depth — 2 inside `Mathlib`, 1
elsewhere — and `dictionary` tested membership by **string equality** against it. So
`theory_of("Physlib.Relativity")` is `"Physlib"`, a caller asking for the theory
`"Physlib.Relativity"` matched nothing, and the query returned **0 rows with no error**.

Zero rows is indistinguishable from "these two theories share no structure", which is
precisely the conclusion such a query is used to draw.

Membership is now a **component-wise prefix** test, so a caller may name a theory at
whatever depth their library organises it. The component boundary is the half a naive
`starts_with` gets wrong, and the gate pins it: `Mathlib.Algebra` must not swallow
`Mathlib.AlgebraicGeometry`.

Measured on the 99.46%-closed physics corpus, conclusion-anchored:

| dictionary | before | after |
|---|---|---|
| `Physlib.ClassicalMechanics ~ Physlib.QuantumMechanics` | **0 (silent)** | **179 rows** |
| `Physlib.QuantumMechanics ~ QuantumInfo` | **0 (silent)** | **107 rows** |
| `Physlib ~ QuantumInfo` | worked (depth 1) | 1,032 rows |

### What this does not invalidate

**§54's classical-mechanics negative stands.** It was established by *exhaustive*
anti-unification over all 218,348 classical x quantum pairs with the prefilter off, which
never consults `theory_of` — nothing physical appeared in the top 400 and that is unchanged.
The same applies to §54's four quantum-information positives, which were read off the
exhaustive dictionary.

**What is affected is every shipped-`dictionary` row count quoted at sub-theory depth**, and
the comparison "14 rows shipped against 273 exhaustive" needs re-running now that the
shipped side can return anything at all.

### The pattern, for the third time today

§31 (unclosed slice), §32 (a dead coverage counter), §60 (`honesty([])` returning the same
answer as the default), and now this: **four separate queries that answered confidently
while being unable to see their input.** None raised an error, none returned an empty result
in a way that looked like failure, and each was found by pointing the tool at a corpus it
had never been aimed at before. Changing corpus is the cheapest defect detector this project
has.

---

## 63. Calculus rules: 21 -> 154 dimensional laws, with a third control that separates 37x

§52 recovered 21 multi-atom dimensional relations from physlib and named the bottleneck:
45% of subterms opaque, the missing vocabulary being calculus rather than physics. Adding
those rules:

| | `--cap 20000` | `--cap 200000` |
|---|---|---|
| base solver (§52) | 17 | **21** |
| with calculus rules | **66** | **154** |

Both original negative controls stay at **zero**, and a third — new, and required by the
change — separates by 37x.

### Every delta is attributable, because C0 was run first

With `--rules none --bvar local` the new harness reproduces §52's numbers **to the row** at
both caps: 3,213 global rows, rank 1,363, grading dimension 341, 17 relations at 20k; 21
with 4 powered at 200k; and the `mathlib-algebra` control's 55,421 rows / dim 688 / 0
relations. Nothing below is a comparison across two different programs.

### The rules came from measuring opacity, not from guessing

Two things a designer would not have written down:

* **physlib has its own derivative operators.** `Space.deriv` (130 uses) and `Time.deriv`
  (123) outrank Mathlib's `deriv` (50) five to one. Rules keyed only on Mathlib's calculus
  vocabulary would have missed the majority of physics' derivatives.
* **The base solver lists four casts its own dispatch can never reach** — `Complex.ofReal`,
  `NNReal.toReal` and two more — because the `CAST` branch requires >= 2 arguments and all
  four are unary. Dead configuration, invisible until something counted.

9 rule families over 42 heads, every arity read off the constant's own type row.
`--arity-check` reports **agree 42, mismatch 0**, having started at 13 mismatches — two of
which (`HasSum`, `tsum`, both carrying a trailing `optParam SummationFilter`) would have
emitted **wrong rows rather than none**, which is the dangerous kind.

### One change the rules forced, and its 2x2

`D(deriv f x) = D(f) - D(x)` spends the point, and the point is a bound variable the base
solver keys *per declaration* — so the row dies in local elimination. Keying a bound variable
by its **binder domain** fixes it. Ablating both axes separately:

| | relations gained |
|---|---|
| rules alone | +27 |
| keying alone | +5 |
| **both** | **+49** |

Super-additive, and the mechanism explains why: neither is useful without the other.

### The third control, and why it had to exist

Adding calculus rules invites an obvious objection — that the solver now recovers *calculus*
identities and calls them physics. So: 44,142 rows of `Mathlib.Analysis` / `MeasureTheory` /
`Probability`, pure calculus, identical portable rules.

| | physlib | Mathlib calculus |
|---|---|---|
| relations per 1,000 declarations | **10.40** | **0.28** |
| carrying a coefficient outside ±1 | **14.8%** | **0%** |

**37x**, and the zero-powers figure is the sharper half. Its five relations are
`iteratedDeriv n f = deriv^[n] f` and Taylor bookkeeping — real, and necessarily all ±1,
because *an identity between two spellings of one operator cannot carry a power*. Physics
carries powers; calculus notation does not.

Shuffle control: 0 relations at both caps. `mathlib-algebra` with every rule enabled and
40,860 bound variables merged by type: **0**.

### The physics recovered

Lagrangian, Hamiltonian, kinetic and potential energy landing on **one exponent vector**,
with the two forces exactly one power of length below it; `B = ∇×A`; the moment of inertia;
the SI dimension decomposition as a five-term power sum; the QM oscillator length with ½
coefficients; anomaly cancellation with coefficient 2.

### The wild question has an answer, and it is not the obvious one

Is there a structural signature of an evolution equation? Yes — and it is **the shape of the
other side of the `Eq`**, not "contains a derivative":

| | declarations | global rows contributed |
|---|---|---|
| conservation laws (`Eq(deriv …, 0)`) | 16 | **3** |
| equations of motion | 161 | **108** |

The conservation set is byte-identical at both caps. **The grading is blind to conservation
by construction** — a quantity being constant says nothing about its dimensions — and the
report argues it should stay that way rather than being patched to notice.

### Withdrawn, loudly

The pre-registered collapse control for the new bound-variable keying **failed**:
`--bvar type` moves the grading dimension by 5 (20k) and 7 (200k), not the 246 that the
spine-keying ablation moves. The justification for excluding scalars is withdrawn, the guard
is kept only on a 66-vs-60 relation count, and the spec says explicitly *do not turn this
into a gate*. A control that fails and is reported as failing is worth more than the finding
it was meant to support.

---

## 64. `equivalent` was blind to axioms — the §23 defect, in a second query

`EquivIndex::build` set

```rust
is_prop = k == "theorem" || concludes_in_prop(&arena, t)
```

and `concludes_in_prop` is true of a **definition of** a proposition (`def RH : Prop := …`),
never of a statement **asserting** one. So the flag collapsed to `kind == "theorem"`, and
**every axiom was invisible to `equivalent` and `classes`**.

Demonstrated by a subagent: `Lean.trustCompiler` and `trivial` have byte-identical statements
(`c(4:True,0)`); `equivalent` *raised* on one and returned `[]` for the other, and **0 of 15
axiom rows appeared in any equivalence class**.

This is §23's defect — `honesty` blind to the genre B7 mandates — surviving in a second
query. **B7's validation corpus is 113 axioms to 21 theorems**, so the blindness covered
nearly the entire corpus the project uses to validate itself.

Fixed, with a fixture pairing an axiom against a statement-identical theorem and asserting
the relation holds in both directions.

### And a defect in code shipped an hour earlier — mine

`adjacent` and `vocabulary_adjacent` obtained the class with

```rust
idx.equivalent(name, lvl).unwrap_or_default()
```

which turns **"this is not a proposition"** into **"this class is empty"**. The queries then
answered about a one-member class they had silently invented, and could return a declaration
as a non-member of *its own* class. Now propagated as `NotAProposition`.

### What that does to §57's V6 verdict

**The verdict survives, and the reason it survives has changed.**

| | before the fix | after |
|---|---|---|
| `equivalent(rh_iff_lambda_nonpos)` | **raised** (axiom refused) | succeeds, returns 0 equivalents |
| class used by `vocabulary_adjacent` | `[seed]`, **by accident** | `[seed]`, **legitimately** |
| `lambda_nonneg` surfaced | yes | yes |
| B7 scorecard | PASS 5 · PARTIAL 3 · UNRUNNABLE 1 | **unchanged** |

The axiom genuinely has no statement-identical twin in B7, so a singleton class is the
correct answer. But before the fix that singleton came from an error being swallowed, not
from a computation — the right answer for the wrong reason. §57 claimed the verdict rested
on a class; it rested on a default. It now rests on a class.

This is the fifth query in this document found answering confidently while unable to see its
input (§31 unclosed slices, §32 a dead counter, §60 `honesty([])`, §62 silent-empty
dictionaries, and now this). Every one was found by pointing the tool at a corpus or a genre
it had not been aimed at before.

---

## 65. External audit: nothing is publishable, B7 must be withdrawn, and three claims were wrong

A five-agent adversarial audit with literature search. **Verdict: nothing here is publishable
as a research contribution today.** The findings below are conceded, not argued with.

### B7 is not evidence and must be withdrawn from every claim

`atlas-validation.md` §1 states **verbatim** that the agents who build the corpus and indexes
read this repository, "so V1-V9 are **development targets**: legitimate for building against
and for regression, incapable of supporting a cold-rediscovery claim."

Worse, `lean/Validation/Clusters.lean` line 30 claims "No attempt is made to align two
clusters so an analogy will be found — that would be building the answer into the corpus",
and then line 121 documents an axiom "written so V2's skeleton can exist at all", line 62
writes a set-level restatement because "V2's pass condition names the expected shared…", and
line 202 marks a statement "Deliberately the same shape as" its intended partner.

**V2's PASS is a pass on statements written to make V2 pass.** §46 and §57 reported
PASS 5 / PARTIAL 3 / UNRUNNABLE 1 as though it were a held-out result. It is not, the
protocol said so in writing, and the scorecard is withdrawn.

### Three specific claims made in this document are wrong

1. **§28: "no shipped linter performs this check" was promoted to novelty, and is not.**
   Alex Best, *Automatically Generalizing Theorems Using Typeclasses* (FMM/CICM **2021**,
   ceur-ws.org/Vol-3377/fmm12.pdf) is a Lean metaprogram reading elaborated proof terms to
   detect over-strong typeclass assumptions, run over ~80,000 mathlib declarations. §28
   checked Mathlib's *shipped linters*, correctly found none, and generalised that to
   "nobody does this" — the exact error this document warns about elsewhere, committed where
   it mattered. Gandhi–Tadipatri–Gowers (ITP 2025, LIPIcs 352:12) is the current bar and
   cites Best.

2. **§52/§63: the dimensional method is 35 years old.** Wand & O'Keefe (1991), Kennedy
   (ESOP 1994, shipped in F#), Guo & McCamant (2005), Osprey (ICSE 2006), **Phriky-Units
   (ISSTA 2017 — annotation-free unit inference over 5.9 MLOC)**. "It needs no dimension
   dictionary" is *Phriky-Units' own selling point*, not a differentiator. And Bobbin et al.
   (arXiv:2509.13142, 2025) formalises the `Dimension` abelian-group machinery in Lean 4 —
   the thing E1 "structurally discovers". The algorithm is not ours; the substrate, the
   reading and the controls are.

3. **§54's cross-theory negative is uninterpretable, not negative.** It was measured with an
   instrument this document itself proves broken at that scale (the dilution curve deletes
   four known-true correspondences monotonically as the corpus grows), and 6 of 20
   pre-registered targets were unaskable because PhysLean has no Poisson bracket, symplectic
   form, Liouville equation or Ehrenfest theorem. The honest reading is **"PhysLean has not
   formalised Hamiltonian mechanics as of 2026"**, not "the analogy is absent from physics".

Also: `M5` is Loogle, `M1` is MathWebSearch's variants operator, `M2`/`M6` are
Gauthier–Kaliszyk concept matching and conjecture transport (CICM 2014, 2016).

**And 11,745 lines of research documents contain zero citations.** That is a process problem,
not a formatting one.

### What survived adversarial review

* **The posting-cutoff / document-frequency result** — the only finding with a named
  mechanism, a monotone dose-response, a pre-registration containing a refutation arm, and a
  control that could have killed it and didn't (matched-N: 985 declarations return 4/4, and
  95,268 return 0/4 at the *same* cutoff, separating df from corpus size). The phenomenon of
  static index pruning is known (Carmel et al. 2001); the **direction** is not — standard
  pruning worries about dropping *rare* terms, and this says dropping *common* keys is what
  deletes cross-domain analogy, because cross-domain overlap lives in low-specificity keys.
* **§43** — kernel-confirmable ≠ general. 10.2% of confirmations duplicate a stated lemma and
  prior-art-rich families confirm at 46.4% against 17.7%. **Best does not screen. Nobody
  screens.** Every prior tool in this line has reported a mixture of generalization and
  rediscovery without separating them.
* **The kernel-verification loop as an instrument.** Best explicitly did not verify; each of
  the 431 is *true*. The contribution is "a verified ground truth against which cheap
  structural detectors can be scored" — not the 387.
* **The negative-control discipline**, which is above the norm of the venue: *The Network
  Structure of Mathlib* (arXiv:2604.24797, 308k declarations) does this genre with no null
  models at all.

### What is architecturally missing — verified in the source, not inferred

1. **Proof terms are never encoded.** `atlas-extract/FhAtlas/Extract.lean:111` computes the
   proof term and reduces it to a *sorted set of constant names*. The entire arena,
   hash-consing, erasure and anti-unification engine only ever sees **types**. `proof_shape`
   is a bag of premise shapes, not proof structure.
2. **There is no prover anywhere in the loop.** Zero hits for `aesop`, `exact?` or `duper`
   outside vendored Mathlib. 17,510 open targets, 387 confirmed weakenings, 76 prose physics
   claims and 18 `sorry`-backed declarations exist, and **not one has been attempted**.
   LeanConjecturer's *minimum* filter is "not provable by aesop".
3. **Every query is retrieval-shaped** — "what looks like x" — never question-shaped.
4. **Every oracle is the kernel or the author.** Not one of the 387 has been offered to
   Mathlib, a free external oracle sitting unused.

> **You have built the best-tested generator half of a discovery loop and none of the refuter
> half.** That is why 63 sections of careful work produced no discoveries. It is not an
> effort problem and not a rigor problem.

### The test that decides whether the dimensional work is discovery or transcription

For each of the 154 pivot rows, report whether it is implied by the rows of a **single**
declaration, of two, or of k > 2. If most are k = 1, this is a per-statement dimensional type
checker with the constraint printed instead of discarded — Osprey with the output kept. If a
meaningful fraction needs k > 2, then **the corpus jointly entails dimensional facts no
single statement states**, which no unit-inference tool does and which is a genuinely new
claim about formalized libraries. This single number should be measured before anything is
written up.

---

## 66. The posting cutoff is the cause, demonstrated — and a length cutoff is the wrong shape

§54 found four pre-registered classical<->quantum information correspondences that the
exhaustive dictionary ranks at the top and the shipped `dictionary` returns none of. §53
localised the cause to `max_posting_fraction` by elimination. This closes it causally.

On the 99.46%-closed physics corpus, `ClassicalInfo ~ Entropy`, conclusion-anchored:

| `max_len` | dictionary rows | pre-registered correspondences returned |
|---:|---:|---|
| **95 (shipped)** | 6 | **none — and none is even a candidate** |
| 400 | 16 | T1, T3, T4 |
| **1,600** | 24 | **all four, as the dictionary's top five rows** |

Nothing else changed: not the scorer, floors, anchor, erasure or anti-unifier.

### The instrument, and its control

`min_posting_len` is not in the binding and Rust edits were out of scope, so the cutoff was
moved **from outside**: `max_len = max(floor(0.001*n), 50)` reads the corpus only through
`n`, so appending rows that parse and carry **no key** (`fh-stmt-v1;s(0)` — one `Sort` node,
below every size floor, no application head) raises it without touching content.

The NC-pad control passed exactly: +100 rows leaves `max_len` at 95 and every number
identical — coverage to 16 digits, all four retentions, all candidate counts, all five
dictionaries row for row.

### The refutation arm separated

Same n = 200,000, same `max_len` = 200: **985 real declarations give 4/4** (ranks 1,1,2,1);
**95,268 give 0/4**, with identical `generalize` retentions. The mechanism is document
frequency against a corpus-wide cutoff, and nothing else `n` does.

### Which keys — the whole dictionary hangs on three

Inverting `motifs(min_family=2)` recovers the input to candidate generation. The entire
classical<->quantum information dictionary rests on:

```
0 <= (·:ℝ)        df   359   (T1, T3)
(· = · : ℝ)       df 1,761   (T2)
((·:ℕ):ℝ)         df   243   (T4)
```

3-7 nodes each, **all source B, zero source C** — and their document frequencies predict the
sweep's ordering exactly (T4/T1/T3 at 400, T2 at 1,600).

### A length cutoff is the wrong shape, and scale makes it worse

**At full scale no flat cutoff reaches 4/4** — admitting every key still gives 3/4, because
`candidate_budget` fills first (queries at or over the 600 budget go 2/40 -> 37/40 across the
sweep). On the full 495,067-row physlib closure the shipped fraction gives `max_len` = 495
and **still 0/4**, with `ClassicalInfo ~ Entropy` falling **6 -> 1** rows. **A bigger constant
of the same shape is not the fix.**

Three alternatives reach 4/4: a per-source cap (source B open, C capped), a theory-scoped
budget, and a **work budget** (keep every key, stop after 2,000 postings walked) at median
475 candidates against 605.5 for the weakest flat cutoff that manages only 3/4. Keeping
everything costs **+0.47% keys and +26.9% postings**. Size-conditioned admission recovers
nothing at any scale — the keys sit at the size floor.

Precision holds: across a 16.8x sweep the two nonsense dictionaries move 35 -> 36 and 7 -> 7
rows, because their rows are shape-*equal* pairs retrieved through source A, which the cutoff
never touches.

### Cost

8.3 -> 36.9 ms median `similar`; candidate median 126.5 -> 700.5; index build +35%, RSS +32%.
And exhaustive is affordable after all: `similar_brute` runs ~866,000 anti-unifications/s, so
all 81,582,112 cross-theory physics pairs cost **94 s**. Raising the cutoff is still the
better trade, because exhaustive buys artifacts and the cutoff demonstrably does not.

---

## 67. We have been reading 2.5% of the formal record

Every index in this project is built from `ConstantInfo.type`. The proof term is computed by
the extractor and then discarded — `atlas-extract/FhAtlas/Extract.lean:111` reduces it to a
sorted list of constant *names*.

So before asking "is the formal corpus too sparse to mine", there is a prior question: **what
fraction of it have we read?** Measured over the whole algebra closure, every theorem, exact
structural node counts, no sampling (`lean/Scratch/MapSize.lean`):

| | |
|---|---|
| theorems | 66,700 |
| statement nodes | 7,563,651 |
| **proof-term nodes** | **298,047,922** |
| **ratio** | **39x** |
| theorems whose proof is >= 10x its statement | 19,794 (**29%**) |
| largest single ratio | **63,359x** |

**97.5% of the structure in this corpus is in proof terms the pipeline throws away one line
in.** That is not missing territory. It is territory already extracted, already in memory,
and discarded before anything indexes it.

### What this does to the sparsity diagnosis

The sparsity is real *for physics*: PhysLean has no Poisson bracket, symplectic form,
Liouville equation or Ehrenfest theorem (6 of 20 pre-registered targets unaskable, §54); 76
claims are stated in prose (§60); `QuantumInfo.ForMathlib` — 978 claims staged for upstreaming
— has **zero** structural overlap with Mathlib; and an unproved statement is provably the
first thing said about its own vocabulary (sign test p = 6.1e-5, §60).

But sparsity does **not** explain the Mathlib results. Mathlib is dense — 470,435
declarations, comprehensive through graduate mathematics — and it also yielded nothing deep:
1.7% cross-theory substitution transfer (§51), eight scoring formulas within noise (§13), 387
minor generalizations (§45). If coverage were the binding constraint, the dense corpus would
have produced more than the sparse one. It did not.

The measured explanation is better: **the instrument reads a thin projection of a rich
record.** 39x.

### Is this a limitation of Lean?

Mostly no, and the distinctions matter:

* **Expressiveness** — no. Lean states essentially all of mathematics; nothing this project
  wanted to ask was blocked by the logic.
* **Coverage** — a labour problem, not a Lean problem. Formalization is human-hours.
* **Physics specifically** — here something real bites, and it is not fixable by effort. Path
  integrals, renormalization and asymptotic matching are not rigorous mathematics yet, so
  that part of the territory cannot be mapped by *any* proof assistant until the mathematics
  exists. Physics is partly unmappable in principle, not merely unmapped.
* **One genuine Lean-shaped tax** — proof terms are enormous because instances are expanded.
  39x on aggregate and 63,359x at the worst single theorem is why nobody reads them. That is
  an engineering cost, not an expressiveness limit, and it is exactly why an erasure that
  holes instance arguments and elaboration plumbing (`Eq.mpr`, `congrArg`, motive lambdas)
  has to exist before a proof index is affordable.

### The order of operations this implies

1. **Read the 97.5% already held.** Encode proof terms; measure the byte cost first as a
   go/no-go, since 298M nodes for one slice is a real scale problem.
2. **Add refuters, not data.** Every result in this document got its teeth from an oracle
   outside the similarity machinery — the kernel, linear algebra over Q, document frequency.
   A prover in the loop is a week's work and the cheapest missing piece.
3. **For physics, measure the boundary rather than pretending it is not there.** The 76 prose
   claims, the 18 `sorry`s and the zero-overlap staging area are a measurable object in their
   own right, and nobody has measured them.

---

## 68. The refuter lane exists: 142 novel kernel-proved generalizations from statements whose own proofs failed

§65 said it plainly: no prover anywhere in the loop, 1,858 REFUTED verdicts never followed
up, "a week's work and the cheapest missing piece". This section closes it, in one night
rather than a week, and the lane's own control caught a real defect before the first
hundred verdicts — both halves of that sentence matter.

### The lane

`scripts/attempt-plan.py` turns the REFUTED ledger into shards of
`#fh_home_attempt <decl> <Source> => <Target> by rfl, simp, aesop, exact?` — the census's
three scored runs contain 1,858 REFUTED verdicts, which deduplicate to **1,783 unique
triples** (75 were re-probed across tranches). Census ordering follows `probe-plan.py`:
whole families first, deterministic throughout, 273 families over 23 shards of ≤ 80.
`scripts/score-attempts.py` reads the shard logs back into a ledger keyed to the proposed
triples, refuses shard logs whose planted controls answered wrongly, and treats a log with
no `EXIT` line as in-flight rather than judging it.

**Every shard carries three plants** — the `AttemptSmoke.lean` trio under collision-proof
names, attempted with the same ladder as the data lines: `fh_plant_easy` must read PROVED,
`fh_plant_hard` must read `not proved`, `fh_plant_no_statement` must read NO STATEMENT. A
control that ran once in a fixture is not a control over an unattended run; these run 23
times a round, and the scorer discards a shard whose plants lie.

### The plant caught a bug in the first eight minutes

On the first launch, `fh_plant_hard`'s verdict line simply never appeared: its `exact?`
exceeded the heartbeat budget, and a deterministic timeout is a **runtime** exception,
which ordinary `catch` deliberately rethrows (`Core.tryCatch` in the toolchain source). The
timeout escaped `tryTactic`, errored the command, and ate the verdict — a prover lane whose
expensive failures silently vanish is precisely the §34 failure mode, on the other verdict.

The repair is `tryCatchRuntimeEx` at three sites in the attempt path (ladder, instance
re-synthesis, type-correctness check): a within-budget failure is the command's ordinary
data path, so a timeout converts to `not proved` / NO STATEMENT; interrupts still
propagate, which is what distinguishes a budget from a hang. Reproduced both ways against
the same artifact — at `maxHeartbeats 2000` the pre-fix build errors with
`(deterministic) timeout at whnf` and exits 1, the post-fix build prints
`not proved by the ladder` and exits 0 — and pinned as a `#guard_msgs` regression in
`Tests/Atlas/Home.lean` at exactly that budget.

### The census

Three workers, 23 shards, 00:30–03:31 (≈ 3.0 h wall), `maxHeartbeats 1000000`, plants
23/23 correct, every shard `EXIT=0`, zero verdict lines missing:

| | |
|---|---:|
| unique REFUTED triples attempted | **1,783** |
| statements posed to the ladder | 1,157 |
| **PROVED** (kernel-accepted, new argument) | **155 (13.4% of posed)** |
| not proved by the ladder | 1,002 |
| NO STATEMENT (refusals) | 626 |

The refusals split three ways, and the split is the useful part: 490 rewritten statements
ill-typed after instance re-synthesis, 134 source binders absent or target inapplicable,
2 re-synthesis failures. A refusal is evidence about the lane, not about the claim — the
626 never reached a prover and must not be read as failures.

**Which tactic won: `aesop` 84, `simp` 42, `exact?` 29, `rfl` 0.** By the lane's own depth
rule — a `rfl` win is bookkeeping, an `aesop` win is an argument — these are
overwhelmingly arguments. Each of the 155 is a statement whose *own proof term fails*
under the weaker hypothesis (that is what put it in this population) now kernel-certified
by a proof the original declaration did not use.

58 of 273 families produced at least one proof. The largest: `PartialOrder → Preorder`
(26), `CategoryTheory.Category → CategoryStruct` (12 — object-property lemmas that never
use associativity), `Preorder → LE` (9, the order-dual family: `IsLUB.dual`,
`BddAbove.dual` need only the relation), `LinearOrder → Preorder` (8), `Field → CommRing`
(6, including `NumberField.RingOfIntegers` constructor lemmas). Also present:
`Mathlib.Tactic.Linarith`'s own support lemmas, over-hypothesised at `Semiring` when
`AddZeroClass` suffices.

### Novelty: 142 of 155 survive the whole-corpus screen

The §40-validated screen (`equivalent` at the `Instances` erasure, whole 470,435-row
closure loaded at 99.74% coverage, prior art = an equal statement whose requirements sit
at or below the target) finds **13 rediscoveries (8.4%)** — in line with the 7.0–10.2%
measured on the confirmation sets, and the hits are credible: `min_le_min_left` is
`inf_le_inf_left`, `bot_eq_one'` is `bot_eq_one`, two `Mathlib.Tactic` internals are each
other. Zero unscreenable. The screen's known blindness to structurally different
formulations (`Iff` against implication) is inherited and still unmeasured.

**Net: 142 kernel-verified generalizations Mathlib does not state, from statements the
re-elaboration census had marked REFUTED.** Added to §45's 387 (a disjoint population by
construction — those are statements whose own proofs *survived*), the pipeline's verified
ground truth now stands at **529**.

What PROVED does and does not claim, stated once: it is sound and final as a theorem —
the kernel accepted the term. It does not claim depth (`aesop` closing it means standard
automation suffices once the statement is *posed*; the contribution is the proposal and
the certificate), and `not proved` claims nothing beyond this ladder and this budget.

### The runner, and the cost that was paid 23 times

Each shard paid a full Mathlib import (~8.5 GB resident) before its first verdict.
`lean/FhBatch.lean` (`lake exe fh_batch`) now imports the environment **once per worker**
and elaborates headerless shards against it — `importModules` at runtime like
`atlas_extract`, so compile-time it links only core Lean. Two traps found by its smoke,
recorded because both fail silent: `importModules` defaults `loadExts := false`, which
imports an environment without its parser extensions, so `#fh_home_attempt` is an unknown
token the parser skips clean past (`processHeader` passes `loadExts := true`, which is why
the CLI never shows this); and `headerToImports` injects the implicit `import Init` even
for a headerless file, so a header guard must ask for imports *beyond* it.

Validated by differential, not by inspection: shard 02 rerun headerless through the
driver produces **83 of 83 verdict lines byte-identical** to the shell-worker log. Import
cost measured hot: 11.8 s in the driver against minutes per `lake env lean` shard.
`attempt-plan.py --batch` emits driver-form shards; the next round runs on it.

### Artifacts

`research/data/refuter-round1-plan.json` (the emitted census),
`refuter-round1-scored.json` (every verdict keyed to its triple),
`refuter-round1-novelty.json` (the 142/13 split with prior-art names). Scripts:
`scripts/attempt-plan.py`, `scripts/score-attempts.py` (self-testing; the selftest proves
the scorer can reject a lying plant). Engine: `#fh_home_attempt`'s runtime-exception
repair in `FerrisHoward/Atlas/Home.lean` with its regression in `Tests/Atlas/Home.lean`;
`lean/FhBatch.lean`.

### What this round proves about the loop, and what it does not

One round of propose → attempt → examine → screen now runs with no human between the
arrows except launching workers and reading the result. The 1,002 `not proved` are the
next round's population — a deeper ladder (`nlinarith`, `positivity`, `omega`,
`polyrith`), a bigger budget, or C2's proof-state machinery decide whether they are hard
or merely unattempted. The 490 ill-typed refusals are a statement-construction seam
(§13's recovery ladder is the template). What the round does not prove: that any of the
142 is *interesting* — that judgement belongs to the external oracle (§65's unused one),
and offering a vetted subset upstream remains the only test of it.

---

## 69. Round 2: the deep ladder wins five, all by `grind` — and the 997 left are now a measured boundary

Round 1 left 1,002 statements `not proved by the ladder`, a verdict that claimed nothing
beyond that ladder and that budget. Round 2 re-asked all 1,002 with a specialist ladder —
`norm_num, omega, positivity, order, nlinarith, grind`, heartbeats 400,000 — as the first
production run of `fh_batch`, and with the plants kept on the round-1 ladder, because a
plant's required verdict is a *known fact* about a specific ladder and the plants exist to
validate the machinery, not the tactics.

| | |
|---|---:|
| attempted (round-1 `not_proved`, complete) | 1,002 |
| **PROVED** | **5 — every one by `grind`** |
| not proved | 997 |
| NO STATEMENT | 0 |
| plants | 13/13 correct |
| novelty screen (coverage 99.74%) | **5 novel, 0 prior art** |

The zero refusals are a consistency check, not luck: this population is by construction
statements that posed successfully in round 1, so a nonzero refusal count would have
indicted the rebuild path.

Three readings, in decreasing confidence:

1. **Round 1's ladder had already exhausted cheap automation.** Five specialist tactics —
   `norm_num`, `omega`, `positivity`, `order`, `nlinarith` — contributed zero wins across
   1,002 statements. The general-purpose search (`aesop`, `exact?`) had already taken
   everything in their reach.
2. **`grind` reaches past `aesop`, rarely but genuinely.** Its five: three of
   `Mathlib.Tactic.Ring`'s own support lemmas
   (`add_pf_add_gt`/`add_pf_add_overlap`/`add_pf_add_lt`, stated at `CommSemiring`,
   true at `AddCommSemigroup`/`AddSemigroup` — the `ring` tactic's plumbing is
   over-hypothesised by five typeclass levels), and
   `CauSeq.rat_inf_continuous_lemma`/`rat_sup_continuous_lemma`
   (`IsStrictOrderedRing → IsOrderedAddMonoid`). All five survive the whole-corpus
   novelty screen.
3. **The 997 are now a boundary, not a backlog.** Ten tactics across two budgets have
   failed on each of them. What remains is C2's proof-state machinery, external provers,
   or the honest conclusion that a REFUTED weakening usually fails because the weaker
   statement is false or needs the dropped structure — which no census here can decide.

**Cumulative verified ground truth: 534** — §45's 387 (own proof survives) + §68's 142 +
this round's 5 (own proof fails, new argument found), every one kernel-checked and
novelty-screened against the same 470,435-declaration closure.

### The runner and the orchestrator

`fh_batch`'s first production round: three workers, **three Mathlib imports totalling
41 s** (12.3/13.0/16.0 s hot) against round 1's twenty-three imports of minutes each;
43.8 min of shard elaboration; ~20 min wall for the round. The specialist ladder fails
fast (~2.4 s/case median against round 1's ~7 s).

`scripts/discovery-round.py` (the L2 orchestrator) landed alongside: plan → run → score →
screen out of one round directory, each child's exit status recorded in a manifest, one
serialized `lake build` before any worker (a stale binary silently running old code is
how the pre-fix olean bit once), and a failed stage stops the round rather than feeding
the next stage a partial artifact. Acceptance measured, not assumed: `--from score` over
round 1's frozen logs reproduces §68 exactly — counts, tactic wins, and the proved list
in order. Its `run` stage has not yet driven a live round; round 3 should go through it
end to end and say so.

Artifacts: `research/data/refuter-round2-{plan,scored,novelty}.json`.

---

## 70. Round 3: the recovery lattice pointed backwards, the family table caught it, and the clean round recovered 23

The §68 refusals were the target: 626 attempts that could not even be *stated* at their
evidence-proposed level. The recovery design brackets each refusal with lattice levels
strictly between the failed target and the declared class (`kuna-math-loop.md` §13's
ladder, mechanized). Two failures preceded the result, and both are worth more than the
result.

**The first launch mis-scoped itself.** Full enumeration of intermediates produced 81,499
attempts over 1,019 shards — deep hierarchies contribute ~130 levels per refusal, and a
census over chain *interiors* is weeks of kernel time that the endpoints already answer.
Killed at launch; the replacement brackets each refusal with its two weakest and two
strongest intermediates (1,554 attempts), and the interior is binary search for the few
that ever earn it.

**The second failure produced 54 kernel-proved wrong answers.** The bracketed round ran
clean — plants 23/23, orchestrator end-to-end, 54 PROVED, 54/54 "novel" — and the family
table read `PseudoEMetricSpace -> PseudoMetricSpace`, `AddMonoid -> AddCancelCommMonoid`,
`Semifield -> Field`. Those are *strengthenings*. The recovery had reused
`novelty-rescreen.py`'s lattice, which keys on `.to` in **names** — and a `.to`-named
declaration is not always a forgetful projection. Conditional constructions (build the
stronger structure from the weaker plus a hypothesis) enter as parent edges, one fake
edge contaminates every transitive chain through it, and "strictly between" quietly
includes classes on the wrong side. No control in the lane could catch it: the plants
validate machinery, the kernel checks exactly the statement it is given, and the novelty
screen cannot flag a strengthening whose prior art is the original declaration itself.
The catch was a human reading the family table — which is the §16 lesson again, in the
other direction: every narrowing *and every enumeration* needs a control aimed at its own
failure mode.

**The repair, measured.** `recovery-triples.py` now builds a strict lattice: an edge is
kept only if its declaration's telescope is implicit carriers plus exactly one instance
binder headed by the owner and **no explicit binder** — a projection forgets and asks
nothing. On the 470k closure this keeps **1,325 edges and rejects 15,722** `.to`-named
declarations: the crude relation was 92% junk by edge count. The direction control is now
an assertion that refuses to emit if the exemplar inversion is representable, and the
audit mode classifies any proved set under the strict lattice. Round 3's 54: **47
inverted, 3 incomparable, 4 genuinely weaker.** The scorecard is withdrawn
(`research/data/refuter-round3-*-INVALID-inverted-lattice.json` keeps the evidence), and
the two §68/§69 novelty verdicts survive with a footnote: they used the polluted relation
in the *conservative* direction (over-matching prior art), so 142 and 5 are lower bounds.

**Round 3b, clean.** 421 bracketed triples over 102 families (420 of 626 refusals have no
strict-lattice intermediate at all), through `discovery-round.py` end to end:

| | |
|---|---:|
| attempted | 421 |
| statable (posed to the ladder) | 63 |
| **PROVED** | **35 rows / 27 distinct declarations** |
| not proved | 28 |
| NO STATEMENT | 358 |
| novelty screen | **27 rows novel / 8 prior art / 0 unscreenable** |

The 8 prior-art hits are one family and they are the screen working: `WithBot.coe_max`
at `Lattice` *is* `WithBot.coe_sup`, stated. Counting one theorem per declaration at its
weakest novel level: **23 recovered generalizations** — statements the census could not
even pose at the evidence level, now kernel-proved at an honest intermediate
(`PartialOrder -> Preorder` 16, `LinearOrder -> Lattice/SemilatticeSup/SemilatticeInf`,
`CompleteLattice -> ConditionallyCompleteLattice`). `rfl` wins 16 of 35, which is what
recovery levels look like: near the statable frontier, the general fact is often
definitionally the stated one.

**Cumulative verified ground truth: 557** (§45's 387 + §68's 142 + §69's 5 + 23), with
the standing caveat that the three novelty screens before this section ran on the crude
lattice and should be re-run on the strict one — a change that can only move
rediscoveries toward novel.

Artifacts: `research/data/refuter-round3b-{plan,scored,novelty}.json`; the invalidated
round-3 files retained under their `-INVALID-` names.

---

## 71. The confirmation instrument crosses the toolchain boundary, and physics answers its pre-registration

`physlib-hypothesis-min.md` §8.1 named the hard blocker: the kernel-probe commands lived
in `lean/` (v4.32.2) and physlib is pinned to v4.32.0, so the emitted physics probe file
built in neither workspace. The move is done: `FhAtlas/Home.lean` now lives in
`atlas-extract` — its `FerrisHoward.Expand.Item` import turned out to be vestigial, so
the module genuinely imports only `Lean` — with a one-line re-export shim at the old
path. Both sides verified by build, not by assertion: the lean workspace's full
`Tests.Atlas.Home` tier is green through the shim (8,661 jobs), and the physics workspace
compiles `FhAtlas.Home` under its own toolchain (`Built FhAtlas.Home (11s)`, Lean
4.32.0). The probe file the physlib session left at `/tmp/phys-probe-plan.lean` already
said `import FhAtlas.Home`; it was written for exactly this move.

**The first physics kernel round ever run.** 18 pre-registered probes
(`/tmp/phys-probe-index.json`, prediction frozen 2.0 confirmations, 95% interval
[0.0, 4.6]), scored against the proposed pairs by `score-probes.py`:

| | |
|---|---:|
| proposed pairs, all with a verdict line | 18 |
| CONFIRMED | 1 |
| REFUTED (re-elaborated) | 17 |
| INCONCLUSIVE / UNASKABLE / missing | 0 |

**Measured 1 against predicted 2.0 [0.0, 4.6] — the pre-registration is scored and
passes.** And then §70's lesson applies to the one success: the confirmation is
`Matrix.PosDef.zero_lt`, `Fintype -> Ring`, and `Ring` is not an ancestor of `Fintype`
under the strict lattice (Fintype's only `.to`-named declaration is
`Fintype.toLocallyFiniteOrder`, hypothesis-taking, concluding elsewhere). The sweep that
proposed it predates the strict-lattice repair, so its candidate inherits the crude
relation. CONFIRMED remains a kernel fact — the proof term typechecks with `[Ring _]` in
that binder's place, which almost certainly means the binder was not doing class-specific
work — but it is a lateral substitution, not a hierarchy weakening. **The honest count of
confirmed physics weakenings is 0 of 18**, which the pre-registered interval also
contains. Consistent with `physlib-hypothesis-min.md`'s headline that physics is several
times less over-hypothesised than Mathlib; the follow-up it forces is mechanical: re-run
the physics sweep on the strict lattice before the next probe round.

Artifacts: `/tmp/fh-phys-probe.log` (EXIT=0), scored at `/tmp/fh-phys-probe-scored.json`;
this round is deliberately not added to any ground-truth count.

---

## 72. The work-budget prefilter lands: 0/4 -> 4/4, option-gated, with the controls that earn it

§66 proved the flat `max_posting_fraction` cutoff deletes the low-specificity keys
cross-domain analogy lives in, and that no flat cutoff reaches 4/4 at scale. The repair
specified there is now in the engine: `IndexConfig.posting_work_budget: Option<usize>`,
default `None` — build admits every key, each query walks a bounded number of postings,
walk order unchanged and deterministic. Wired per CLAUDE.md §6: engine, Python binding +
stubs, and a new `atlas_similar` MCP tool (the CLI skipped per the §42 retirement
precedent); the knob participates in the index digest with a presence byte, so
`None ≠ Some(0)`.

Built so it can fail, twice over: the crowded-key fixture's positive is paired with the
ablation that must silence it, and with a `Some(0)` case proving the walk bound is a real
bound rather than admission renamed; a real-slice test asserts budget-on candidates are a
superset of the shipped walk and keep-all strictly grows concrete keys. One deviation
recorded rather than hidden: while the budget is on it replaces `candidate_budget` as the
walk bound, because §66's own sweep shows the 600-slot cap reproduces the 3/4 loss on its
own.

Verified in this session, not reported from elsewhere: `cargo fmt --check` and
`clippy --all-targets` clean; `FH_SLICE` golden green (pinned top-k byte-identical with
the knob off) and all 12 sources tests green (201 s); and the paired physics gate
(`scripts/phys-budget-check.py`, 95,268-row corpus) run first-hand both arms —
**off: 0/4 pre-registered classical↔quantum correspondences (PASS as the shipped
baseline); on (W = 2,000): 4/4, all four in the `ClassicalInfo ~ Entropy` dictionary
(PASS)** — with the implementing agent's fuller sweep additionally measuring the NC3
nonsense-dictionary controls at 35 → 36 and 7 → 7 rows. The cross-domain channel the
cutoff deleted is recoverable behind a default-off knob, and turning it on costs the
noise dictionaries at most one row.

---

## 73. The k-attribution verdict: the dimensional corpus entails what no single statement states

§65 named the single measurement that decides whether the dimensional work is discovery
or transcription: for each recovered relation, is it implied by the rows of one
declaration, two, or k > 2? Measured exactly (`research/dim-k-attribution.md` — the
pre-registration was written before computation, threshold ≥20% of powered relations at
k≥2; k=1 and k=2 are exact over ℚ, k≥3 exact as a class with witness *sizes* the only
upper bound; the labelled `--witness` over-approximation was not used; the 21/4 and
154/24 reproduction gates hit exactly):

| population | n | k=1 | k=2 | k≥3 | k≥2 |
|---|--:|--:|--:|--:|--:|
| baseline all | 21 | 6 (28.6%) | 5 | 10 | 71.4% |
| calculus all | 154 | 49 (31.8%) | 24 | 81 | 68.2% |
| **calculus powered** | **24** | **2 (8.3%)** | **2** | **20** | **91.7%** |

**Discovery, by the pre-registered bar: 91.7% ≥ 20%.** And the split lands exactly where
honesty wants it: the *showcase singletons* — vis-viva, B = ∇×A, the moment of inertia —
are k=1, one statement's dimensional balance printed, which is the Osprey-with-output-kept
reading §65 suspected. The *families* are corpus-level facts: the
Hamiltonian/kinetic/potential-energy signature needs ~9 theorems jointly, the Gaussian
moment 11, anomaly cancellation is almost entirely k≥3, and for 99 of 154 relations no
single declaration so much as mentions all the relation's atoms. That is the claim §65
pre-certified as "genuinely new … about formalized libraries", now with a number under it.

Caveats carried, not buried: witness chains can route through shared bookkeeping atoms
(a witness set is not a curated derivation); minimal k above 2 is only bounded; the
cap-20000 populations are unattributed; and the 154 remain humanly unread. Raw
per-relation data: `research/data/dim-k-attribution.json`; reproducing script
`scripts/dim-k-attribution.py` gates non-zero if the published populations fail to
reproduce.
