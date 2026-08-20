# Over-strong hypotheses in physlib, and whether Mathlib's family rates transfer

`scripts/phys-hypothesis-min.py`. Companion to §30–§45 of `corpus-atlas-findings.md`, which
built the generalization pipeline on Mathlib and ended at 387 kernel-verified hypothesis
weakenings.

The number worth porting is not 387. It is §42's claim that confirmation rate is **bimodal
by weakening family** — 68% of families at exactly 0% or exactly 100% — because that is the
shape of a law rather than of a detector's noise floor. A law transfers to a new domain. A
Mathlib artifact does not. Physics is the test: physlib's classes are
`NormedAddCommGroup`, `InnerProductSpace`, `MeasurableSpace`, `Module`, `Algebra`, not
`Monoid` and `Preorder`.

**Nothing in this document is kernel-confirmed.** This session could not run `lake` or
`lean`. Every physics number below is a *candidate* count or a *prediction*; the probe file
and its index are emitted for an orchestrator that can run the kernel, and §7 states what
would falsify the prediction before it is measured.

---

## 1. The pipeline reproduces every published Mathlib number first

A ported pipeline that disagrees with the original is indistinguishable from a domain
difference, so the port was run against the algebra slice before it was pointed at physics.

| stage | this script on `/tmp/mathlib-algebra.jsonl` | published |
|---|---|---|
| candidates | **727** | 727 (§31) |
| at-home / unused | 17,025 / 1,044 | 17,025 / 1,044 (§31) |
| closure coverage | **99.25%** | 99.25% (§32) |
| novelty screen | 727 → **674 novel, 53 prior art** | 674 / 53 (§30, §39) |
| arity-unaskable families | `Zero→OfNat` 63, `One→OfNat` 57, `HasDistribNeg→Neg` 6, `AddMonoid→SMul` 5, `OrderBot→Bot` 4 | the same five families (§38) |
| Mathlib family map | 326 families, 2,305 decisive probes, 447 confirmed, **431 unique** | 431 (§42) |

Only the storage differs — the arity table is read off the sweep's own binders instead of a
second stream of the slice, which on a multi-gigabyte physics closure is a pass saved.

---

## 2. Correction to §42: the bimodality is substantially small-sample

Before asking whether the family map transfers to physics, it has to be shown to predict at
all. The three Mathlib runs make that measurable with no new kernel time: fit the map on
runs 1+2 (1,310 decisive probes) and score run 3 (995 decisive probes, 146 confirmed), which
`--all-remaining` drew from candidates the first two had not touched.

`--stage selftest`:

| estimator | predicted confirmations | 95% interval | verdict | Brier |
|---|---|---|---|---|
| pooled rate (23.0%, one number for every family) | 228.6 | [202.6, 254.6] | **MISS** | 0.1321 |
| raw family map (§42's rates) | 106.9 | [92.4, 121.3] | **MISS** | 0.1142 |
| **family map shrunk toward pooled, α=4** | **145.6** | [125.5, 165.7] | **HIT** | **0.1084** |

Observed: **146**.

Three things follow, and the third is the correction.

**The map has real skill.** Shrunk, it beats the pooled rate by 18.0% on Brier, and 0 of
2,000 random permutations of the same rates across the same families scored as well
(p < 0.0005). Family identity carries information; family *size* alone does not explain it.

**The raw rates are biased low and the pooled rate is biased high**, in opposite directions
and by similar magnitude (−27% and +57% relative). Neither is usable as stated. A modest
shrinkage — four pseudo-probes at the pooled rate, roughly the median family's probe count —
lands within 0.3% of the observed count. α was selected on this held-out set, so its
*optimality* is mildly optimistic; the ordering (raw worse, pooled worse) is not, since both
endpoints miss their intervals by wide margins.

**§42's bimodality is partly an artifact of n = 3.** Of the 38 families with at least five
held-out probes:

| | |
|---|---|
| Spearman(fitted rate, held-out rate) | **0.315** |
| families fitted at exactly 0% | 24 — their held-out rate is **8.5%** over 649 probes |
| families fitted at exactly 100% | 1 — its held-out rate is 100% over 5 probes |

A family measured at 0% on three probes is not a 0% family. `Field → CommRing` was fitted at
0% and ran at 37.5% on 16 held-out probes; `LinearOrder → SemilatticeSup` at 0% and 35.3% on
17; `CommSemiring → Semiring` at 0% and 27.3% on 22. The Brier skill the map does have comes
mostly from the *large* near-zero families — `PartialOrder → Preorder` (fitted 0%, held-out
2.5% on 159 probes) and `LinearOrder → PartialOrder` (fitted 0%, held-out 0.0% on 104) —
which really are near-zero and really do dominate the budget.

So §42's operational advice survives and its statistical characterization does not. The map
is a good instrument for **deprioritizing** large families that keep failing. It is a poor
instrument for reading a rate off a small family, and "68% of families are exactly 0% or
100%" is mostly a statement about how many families were probed three or four times.

This is the baseline the physics transfer must be read against: a *within*-Mathlib,
out-of-sample transfer already loses most of the rank ordering and needs shrinkage to be
calibrated at all.

---

## 3. The closure constraint is not conservative here — it is total

§31 measured, on a Mathlib case, that dropping a corpus's foundation costs 34.5% of
candidates and fabricates 11.0%. On physics the failure is not partial.

`--stage sweep` over `/tmp/fh-physlib.jsonl`, the `--local` extraction (14,576 rows, 14,558
of them `Physlib.*`/`QuantumInfo.*`, measured at 12.39% closed):

| | unclosed physlib slice | algebra closure, for scale |
|---|---|---|
| classes in the lattice | 154 | 644 |
| **parent-projection edges** | **19** | 628 |
| at-home | 2,478 | 17,025 |
| unused | 345 | 1,044 |
| **over-hypothesis candidates** | **0** | 727 |

Zero. Not fewer — none, and no fabrications either, because the failure is upstream of the
verdict. The lattice is read off parent projections (`CommRing.toRing`), and every one of
those is a Mathlib declaration that `--local` filtered out of the output. With 19 edges there
are almost no ancestors, so `over-hypothesis` is unreachable by construction: the rule can
only ever report `at-home` or `unused`.

That is a worse failure mode than §31's and an easier one to miss. §31's unclosed corpus
produced a plausible-looking candidate set that was 11% invented. This one produces a clean,
confident, entirely empty answer — and "physics has no over-strong hypotheses" is exactly the
conclusion a reader would draw from it.

**Reported as the paired negative control it is**: the closed and unclosed corpora must
disagree, and here they disagree maximally.

---

## 4. What physics contributes: 23 candidates, and a yield 3.6x below Mathlib's

### The corpus, and its caveat

The `Physlib`+`QuantumInfo` import closure was still extracting when this ran (§9). What is
measured below is a **merged corpus**: §35's whole-Mathlib closure (470,435 rows, verified at
99.74%) concatenated with all 14,576 physics rows — 485,011 rows, 5.4 GB.

The merge is the case CLAUDE.md §7 flags: Mathlib rows extracted under `v4.32.2`, physics
rows under `v4.32.0`. It is **sound for the evidence rule**, which looks constants up by
name and reads their instance binders, and it is **weaker for the novelty screen**, which
compares statements for equality — a lemma whose encoding changed between the two patch
versions would compare unequal and read as novel when it is not. That bound is unmeasured
and stated rather than papered over.

### R1: the control passes

| | |
|---|---|
| §37 candidates | 2,704 |
| …whose declaration is present here | 2,704 |
| **recovered with the same target** | **2,704 (100.0%)** |
| recovered with a different target | 0 |

Pre-registered floor was 60%. Note what this does and does not show: the merged corpus
*contains* §35's rows verbatim, so this is not a cross-version replication. What it does
establish is that adding 14,576 physics declarations — with 19 new classes and 19 new
lattice edges — perturbs **no** Mathlib verdict, which is the property the physics numbers
depend on. A sweep whose Mathlib half moved when physics was added would make any physics
difference unattributable.

### The sweep

| verdict | whole corpus | physics rows only |
|---|---|---|
| multi-carrier (refused, not judged) | 145,635 | 2,020 |
| at-home | 93,735 | 2,726 |
| produces-a-class | 6,347 | 45 |
| projection-like | 4,852 | 62 |
| no-single-home | 3,154 | 13 |
| unused | 2,722 | 48 |
| **over-hypothesis** | **2,727** | **23** |

Lattice: 2,663 classes, 1,914 edges, 18,752 forgetful instances. 44 minutes, peak 1.5 GB.

### R2: yield, and why it is low

| | physics | Mathlib (§37) |
|---|---|---|
| declarations | 14,558 | 470,435 |
| candidates | **23** | 2,704 |
| **yield** | **0.158%** | 0.575% |

**Inside the pre-registered 5-60 range, and the direction was predicted.** But the *reason*
was predicted wrongly, and the decomposition is the more interesting number:

| | physics | Mathlib (§37) | ratio |
|---|---|---|---|
| declarations | 14,558 | 470,435 | |
| emit any verdict | 4,937 (**33.9%**) | 254,233 (**54.0%**) | 0.63 |
| …refused as multi-carrier | 2,020 (**40.9%** of emissions) | 143,613 (**56.5%**) | — |
| binder-level verdicts | 2,810 | 99,528 | |
| …**at-home** | 2,726 (**97.0%**) | 91,009 (**91.4%**) | |
| …**over-hypothesis** | 23 (**0.82%**) | 2,704 (**2.72%**) | **0.30** |

The pre-registration guessed that physics would lose candidates to the single-carrier
refusal. **It does not** — physics is refused *less* often than Mathlib (40.9% against 56.5%),
because a large share of physlib is stated over one concrete carrier rather than over three
abstract ones. That guess is withdrawn.

Three factors multiply to the 3.6x, and only two are about coverage:

* **0.63 — fewer declarations are judgeable at all.** Only a third of physlib declarations
  carry an instance binder, against half of Mathlib's, because physics is largely written
  over concrete carriers (`ℝ`, `EuclideanSpace ℝ (Fin 3)`, a fixed `Matrix (Fin 4) (Fin 4) ℂ`)
  with no typeclass polymorphism left to weaken.
* **1.45 — physics is refused as multi-carrier less often**, which pushes the other way.
* **0.30 — and this is the finding: among binders the rule actually judges, a physlib binder
  is over-strong 0.82% of the time against Mathlib's 2.72%.** physlib binders are *at home*
  97.0% of the time; Mathlib's, 91.4%.

So the honest reading of 0.158% is **not** that the detector cannot see physics. It is that
**physlib is genuinely less over-hypothesised than Mathlib, by a factor of about 3.3 on the
binders both are judged on.** That is a plausible result rather than a surprising one: physlib
is small, recent, written by few hands against an already-general Mathlib, and its authors
were choosing hypotheses with Mathlib's hierarchy already laid out in front of them. Mathlib
accumulated its hypotheses over a decade of refactors.

It is also, note, a *candidate*-level statement. Only the kernel can turn 0.82% into a
confirmed rate, and §7's prediction is that roughly 2 of the 18 askable ones survive it.

### The 23

Grouped by what they are, not by family:

**Unbounded operators in quantum mechanics** — `NormedAddCommGroup → SeminormedAddCommGroup`:

```
LinearPMap.inner_map_polarization         Physlib.QuantumMechanics.Operators.Unbounded
LinearPMap.inner_map_polarization'        ”
LinearPMap.inner_im_of_commutator_eq      Physlib.QuantumMechanics.Operators.Uncertainty
LinearPMap.sub_expectation_commutator_eq_raw   ”
```

The polarization identity and the commutator expectation, stated over a Hilbert space,
proposed as needing only a **semi**normed additive commutative group — i.e. not needing the
separation axiom that makes the norm a norm.

**Vector calculus** — `NormedSpace → Module` and `NormedAddCommGroup → SeminormedAddCommGroup`:

```
Space.curl_linear_map      Physlib.SpaceAndTime.Space.Derivatives.Curl
Space.div_linear_map       Physlib.SpaceAndTime.Space.Derivatives.Div
Space.deriv_const          Physlib.SpaceAndTime.Space.Derivatives.Basic
Time.deriv_const           Physlib.SpaceAndTime.Time.Derivatives
```

That curl and divergence are linear, and that the derivative of a constant vanishes,
proposed as facts about a module rather than about a normed space.

**Pseudo-Riemannian geometry** — the closest thing here to the topic's Lorentzian-metric case:

```
QuadraticForm.QuadraticMap.weightedSumSquares_basis_vector   [AddCommGroup] -> AddCommMonoid
    Physlib.Mathematics.Geometry.Metric.PseudoRiemannian.Defs
```

**Relativity tensors** — `CommRing → Semiring`:

```
TensorSpecies.basis_congr      Physlib.Relativity.Tensors.TensorSpecies.Basic
TensorSpecies.map_basis_eq     ”
```

**Quantum information** — `QuantumInfo.ForMathlib.*`, four candidates, three of them in
modules whose *name* says they are Mathlib contributions in waiting.

---

## 5. Family comparison, and the transfer prediction

### R3: the family distribution is entirely Mathlib's

12 families over 23 candidates:

| n | family | Mathlib rate |
|---|---|---|
| 7 | `NormedAddCommGroup → SeminormedAddCommGroup` | 5/51 = 10% |
| 4 | `NormedSpace → Module` | 0/3 = 0% |
| 2 | `Zero → OfNat` | 0/56 = 0% — **arity-changing, unaskable** |
| 2 | `CommRing → Semiring` | 0/10 = 0% |
| 1 | `ConditionallyCompleteLinearOrder → ConditionallyCompleteLattice` | 2/24 = 8% |
| 1 | `AddCommGroup → AddCommMonoid` | 0/3 = 0% |
| 1 | `StarRing → StarMul` | 0/4 = 0% |
| 1 | `One → OfNat` | 0/50 = 0% — **unaskable** |
| 1 | `ConditionallyCompleteLattice → SemilatticeSup` | unmeasured |
| 1 | `Fintype → Ring` | unmeasured |
| 1 | `AddCommMonoid → OfNat` | unmeasured — **unaskable** |
| 1 | `MulAction → SMul` | unmeasured — **unaskable** |

**R3 confirmed, and more strongly than predicted.** Every one of the 12 families is a pair of
*Mathlib* classes. Eight carry a Mathlib-measured rate; the other four are unmeasured
combinations of Mathlib classes rather than physics ones.

### R5: zero candidates on physlib's own lattice

**0 of 23.** Not one candidate has a `Physlib.*` or `QuantumInfo.*` class as declared class
or as target, despite §6 showing the lattice for them exists — `InnerProductSpace'`,
`UnitalFreeStateTheory`, `CarriesDimension` and the rest contribute 19 edges to the 1,914 in
this corpus and none of them is walked.

**This null is "we didn't look", not "there's nothing there"** — and the distinction is
structural rather than a hedge.

physlib's own classes are inherently multi-carrier. `InnerProductSpace' 𝕜 E` binds a scalar
field *and* a space; `UnitalFreeStateTheory` and `CarriesDimension` are the same shape. The
row-based rule refuses every declaration whose binders span more than one carrier (§8.4), so
a theorem declaring `InnerProductSpace'` is refused **before any lattice walk happens**. Its
19 edges cannot be reached by this detector regardless of whether the theorems that use them
are over-hypothesised.

So R5's answer is: **not measurable with the current rule.** The prediction that physics
would contribute few physics-specific candidates may well be right, but this run is not
evidence for it — the instrument is blind in exactly that place. §8.4 is the spec that
would fix it, and it is the highest-value change this study identified.

### The novelty screen, run before probing

Per §43, screening *after* the kernel spends budget on rediscovery, so it runs first. Over
the merged corpus at 99.59% closure:

| | |
|---|---|
| physics candidates | 23 |
| **survive as novel** | **23** |
| prior art found | **0** |
| unscreenable | 0 |

A screen that finds nothing is the shape this repo distrusts, so: **this null is
uninformative, not reassuring.** Mathlib's prior-art rate over 431 confirmed weakenings was
10.2% (§45); at that rate the chance of seeing zero hits in 23 draws is about 8%, so 0 is an
ordinary outcome and no evidence that physics has less rediscovery in it. Two further
bounds, both unmeasured:

* §40 established the screen's sensitivity at 40/40 — **on Mathlib rows**. Nothing here shows
  it holds for a statement headed by `LinearPMap` over an `InnerProductSpace'`.
* the corpus is a cross-version merge (§4), and the screen is the consumer that cares.

### R4: the transfer prediction

Askability first, since it narrows: **18 askable, 5 arity-changing**
(`Zero→OfNat` ×2, `One→OfNat`, `AddCommMonoid→OfNat`, `MulAction(3)→SMul(2)`). The first
four are §38's known families; `MulAction → SMul` is a new instance of the same mechanism.

| stratum | families | candidates | predicted | 95% |
|---|---|---|---|---|
| (a) Mathlib-measured, ≥3 probes | 6 | 16 | 1.6 | [0.0, 3.9] |
| (a′) Mathlib-measured, 1-2 probes | 0 | 0 | — | — |
| (b) no Mathlib measurement | 2 | 2 | 0.4 | [0.0, 1.5] |
| **total** | **8** | **18** | **2.0** | **[0.0, 4.6]** |

**The prediction is 2 confirmations from 18 probes.** Written to
`/tmp/phys-probe-index.json` under `prediction` before any kernel ran.

**The shuffle control fires.** Permuting the Mathlib rates across the six stratum-(a)
families gives a median prediction of 0.4 with a 95% spread of [0.2, 1.0]; the real
prediction of 1.6 is **outside** it. So the map is not merely reproducing family sizes here
— it knows that physics' largest family (`NormedAddCommGroup → SeminormedAddCommGroup`, 7
candidates) is the one with the highest measured rate among them.

**And the power is inadequate, which the run says itself.** The interval [0.0, 4.6] over 18
probes spans an observed rate of 0%-25.4%, and the pooled Mathlib rate of 19.4% sits inside
it. **This run cannot separate "the family map transfers" from "only the overall rate
transfers".** It can falsify both at once — an observation of 5 or more confirmations would
be outside the interval — and it cannot do better than that at n = 18. Reporting a
distinction the sample size cannot support would be the error §42 made in the other
direction.

---

## 6. Physics-specific over-hypotheses: the lattice exists

Question 3 was whether physics has weakenings Mathlib cannot express — a theorem stated for
a Hilbert space that needs only an inner-product space, or for a bundled structure that
needs only its underlying bilinear form. That depends on whether physlib *defines classes
with parent projections of its own*, since the lattice is read off those projections and a
library that only consumes Mathlib's hierarchy can only produce Mathlib's families.

It does. Measured over the physics rows (`Physlib.*` + `QuantumInfo.*`): **154 classes appear
as instance-binder heads, 19 of which physlib defines**, and those 19 carry **19 parent
projections** — every lattice edge in the physics-only slice is physlib's own.

The physics-defined edges, in full:

| edge | where | what a weakening along it would mean |
|---|---|---|
| `InnerProductSpace' → InnerProductSpace` | `Physlib.Mathematics.InnerProductSpace.Basic` | **this is the question, exactly**: physlib's own bundled L2 inner-product-space class, weakened to Mathlib's |
| `InnerProductSpace' → NormedSpace` | ” | stated for an inner-product space, needs only the norm |
| `InnerProductSpace' → NormedAddCommGroup` | ” | ” , needs only the additive normed group |
| `InnerProductSpace' → Norm₂` | ” | needs only the L2 norm itself |
| `UnitalFreeStateTheory → FreeStateTheory` | `QuantumInfo.ResourceTheory.FreeState` | a resource-theory fact stated with a unit that does not need one |
| `UnitalFreeStateTheory → UnitalPretheory` / `→ One` / `→ Unique` | ” | ” |
| `UnitalPretheory → ResourcePretheory` / `→ One` / `→ Unique` | ” | ” |
| `FreeStateTheory → ResourcePretheory` | ” | ” |
| `ResourcePretheory → Semigroup` | ” | a resource-theory fact that is really a semigroup fact |
| `CarriesDimension → HasDim` | `Physlib.Units.UnitDependent` | dimensional analysis: needs the dimension, not the action |
| `CarriesDimension → MulAction` | ” | ” |
| `ContinuousLinearUnitDependent → LinearUnitDependent` | ” | a unit-dependence fact that does not need continuity |
| `LinearUnitDependent → UnitDependent` | ” | ” , does not need linearity |
| `MulUnitDependent → UnitDependent` | ” | ” |
| `DMul → HMul` | ” | dimensionful multiplication → heterogeneous multiplication |

The three physics-specific hierarchies are **bundled inner-product spaces**, **quantum
resource theories**, and **dimensional analysis / units**. None of them exists in Mathlib, so
none of their families can carry a Mathlib-measured rate — they are stratum (b) by
construction, and they are where a physics finding would be genuinely new rather than a
transported Mathlib one.

So the *lattice* for a physics-specific over-hypothesis exists and is in the corpus — 19 of
the 1,914 edges the merged corpus carries. No candidate landed on any of them (§5, R5), and
§8.4 explains why that null says nothing: every one of these classes binds two carriers at
once, and the row-based rule refuses a multi-carrier declaration before it walks any lattice.
The edges are reachable in principle and unreachable by this detector.

---

## 7. The prediction, stated before the kernel runs

The transfer question is not "does the pipeline find candidates in physics" — it is whether
a rate measured on Mathlib **predicts** a physics outcome it has never seen. That is only a
test if the prediction is fixed before the measurement, so the numbers below are written
into `/tmp/phys-probe-index.json` under `prediction` and the orchestrator scores against
them with `scripts/score-probes.py`.

**How each stratum is predicted.**

* **(a) families with ≥3 Mathlib decisive probes.** Rate = the family's Mathlib rate shrunk
  toward the pooled rate with α = 4, which is the only estimator of the three in §2 that
  hits its own held-out interval.
* **(a′) families with 1–2 Mathlib probes.** Same estimator; with α = 4 dominating a
  denominator of 1 or 2, these are effectively predicted near pooled, which is the honest
  thing to do with a family measured once.
* **(b) physlib-only families.** No Mathlib measurement exists, so the pooled Mathlib rate
  is the only available prior. §6's three physics hierarchies are all here by construction.

**What falsifies what.**

| observation | reading |
|---|---|
| total confirmations outside the stratum-(a)+(a′)+(b) interval | the Mathlib rate does **not** transfer to physics at all — neither by family nor in aggregate |
| inside the interval, and stratum (b) rate ≈ stratum (a) rate | the *pooled* rate transfers; family identity adds nothing here |
| inside, and (a) tracks its per-family prediction better than a permutation of it | the **family map** transfers — the strong result |
| stratum (b) confirms far above pooled | physics-specific hierarchies are more over-hypothesised than Mathlib's, which would be the interesting finding |

**Two things that would make this test weak, named now rather than after.**

1. **Power.** The physics candidate set is small compared to Mathlib's 2,305 probes. The
   plan stage prints the observed-rate span its interval corresponds to; if that span
   contains the pooled Mathlib rate, the run cannot separate "the family map transfers"
   from "only the overall rate transfers", and it says so in its own output.
2. **Rediscovery (§43).** A high confirmation rate partly measures that the general version
   was already stated. Physics is *more* exposed to this than Mathlib, because a physlib
   theorem stated over `NormedAddCommGroup` may be a thin specialization of a Mathlib lemma
   that is already fully general. Screening before probing (§5) is what keeps the two apart,
   and the screen's sensitivity on physics rows is **unmeasured** — §40's 40/40 was measured
   on Mathlib rows only, and re-running that control needs three copies of a multi-gigabyte
   corpus.

---

## 8. Engine changes this needs

### 8.1 `Atlas/Home.lean` must move into `atlas-extract` — this is a hard blocker

**The emitted probe file cannot be built today, in either workspace.**

`#fh_home_refute` is defined in `lean/FerrisHoward/Atlas/Home.lean`, inside the FerrisHoward
package, pinned to `leanprover/lean4:v4.32.2`. physlib lives in `physics/`, pinned to
`v4.32.0`, whose `lakefile.toml` requires only `atlasExtract` and `physlib`. So:

* from `physics/`, `FerrisHoward.Atlas.Home` does not exist;
* from `lean/`, `Physlib` does not exist, and adding it would force the toolchains to unify
  — which CLAUDE.md §7 says is load-bearing for the corpus, the round-trip gate and B7's
  frozen answer key.

The fix is the pattern `atlas-extract` already is. `Home.lean` is self-contained Lean
metaprogramming: it `open`s `Lean Meta Elab Command` and nothing else, and its body uses
only `forallTelescope`, `whnf`, `mkForallFVars`, `instantiateLambda`, `env.find?`,
`Declaration.thmDecl` and `NameSet`. Its single `import FerrisHoward.Expand.Item` is
**unreferenced** — no `FerrisHoward.Expand.*` identifier occurs anywhere in the file.

**Spec.**

1. Move `lean/FerrisHoward/Atlas/Home.lean` to `atlas-extract/FhAtlas/Home.lean`, dropping
   the `FerrisHoward.Expand.Item` import. Keep the Lean *namespace* `FerrisHoward.Atlas`
   while the module path becomes `FhAtlas.Home` — CLAUDE.md §7's module-vs-namespace rule,
   for the same reason it applies to `FhAtlas.Statement`: the main package globs
   `FerrisHoward.+` and would otherwise claim the module.
2. Re-point `lean/`'s existing importer at `FhAtlas.Home` and confirm
   `Tests/Atlas/Home.lean` is still green — it pins §38's refusal case and a CONFIRMED case,
   which is exactly the pair that must survive a move.
3. Verify the dropped import really was dead by building without it first. If it turns out
   to be load-bearing (an attribute or `macro_rules` extension that grep cannot see), the
   move is still possible but needs whatever it supplied lifted alongside.
4. `physics/lakefile.toml` needs no change: it already path-depends on `atlasExtract`.

Cost estimate: a file move, one import line, two builds. Everything else about the pipeline
is already toolchain-neutral because the Atlas consumes JSONL.

### 8.2 `Corpus.closure()` should be reportable per module prefix

The physics closure is overwhelmingly Mathlib by row count, so a single global coverage
figure is dominated by Mathlib's rows and says nothing about whether the *physics*
statements' application heads are present. A corpus can read 99.7% closed while every
`Physlib.*` statement is degraded, and §31's whole lesson is that this degrades silently.

**Spec.** `SkeletonIndex::closure` already walks every application head per statement.
Add `closure_by(prefix: &str)` restricting the *statements* iterated (not the corpus) to
declarations whose module starts with `prefix`, returning the same
`(heads, missing, coverage, top)` tuple. Land it in the engine, the Python binding and its
`.pyi`, `fh mcp`'s tool list, and extend `scripts/slice-closure.py` with a case that asserts
a prefix-restricted verdict differs from the global one on a corpus where it should — per
CLAUDE.md §6, a query that exists only in the CLI is a query validation cannot afford to
call.

### 8.3 Expose the class-arity table

`scripts/probe-plan.py` re-streams the whole slice purely to learn how many arguments each
class takes (§42 works around it by reading arities off a smaller closure). Arity is a
property of the class, and the arena already holds every instance-binder domain.

**Spec.** `SkeletonIndex::class_arity() -> HashMap<String, usize>`, the modal argument count
over instance-binder domains headed by that constant, exposed as `Corpus.class_arity()`.
`phys-hypothesis-min.py` computes it during its own sweep for exactly this reason; that
should not be a per-script workaround. On a multi-gigabyte physics closure it is a whole
pass saved.

### 8.4 The single-carrier restriction is what hides physlib's own hierarchy

Not, as this document first guessed, the biggest lever on overall physics recall — §4 shows
physics is refused as multi-carrier *less* often than Mathlib (40.9% against 56.5%). But it
is almost certainly what produces §5's R5 null, and that is the more interesting loss. It is
not a bug: it is `fh_home`'s deliberate refusal, documented in its own module docstring.

`HomeIndex.home` judges only declarations all of whose instance binders constrain the **same
carrier**, because the evidence rule recovered from rows is flat: "a class reached at `S`" is
indistinguishable from "a class reached at `R`", so a binder can be told it is over-strong on
its neighbour's evidence. `#fh_home`'s D3 revision solved this *inside Lean* by attaching each
piece of evidence to the carrier it was found at.

The refusal costs physics 2,020 of 4,937 verdict emissions. What matters is **which** 2,020:
`[RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]` is three binders over two
carriers and is refused outright — and that shape is exactly how physlib's own classes are
used. `InnerProductSpace'` heads 342 instance binders and is *by construction* multi-carrier;
so is `UnitalFreeStateTheory`, so is `CarriesDimension`. Their 19 lattice edges therefore
cannot be walked by the row-based rule **no matter how over-hypothesised the theorems are**,
which makes §5's R5 null uninterpretable as stated: it does not distinguish "physlib's own
hierarchy is at home" from "the rule never looked".

Lifting the restriction is the only way to tell those apart, and it is the single change that
would turn the physics-specific question from unanswerable into answerable.

**Spec.** Carry the carrier through the evidence rule rather than refusing on it. The row
already carries what is needed in principle — `uses_statement`/`uses_proof` name the cited
constants, and `Corpus.requires` gives each one's classes — but not *which argument* of the
citation each class constrained. Two options, in increasing cost:

1. **Extend the row.** Have `atlas_extract` emit, per cited constant, the argument positions
   at which the citing declaration's own binders appear. That makes the flat set
   carrier-aware without changing the verdict rule, and it is the change that would let the
   whole physics hierarchy be judged.
2. **Move the walk into the arena.** `SkeletonIndex` already holds the unerased root and
   `requires` already walks its `Pi` prefix; a `home(name)` on top of that would have the
   real term and could do what D3 does in Lean.

Either way, **land the ablation with it**: report the candidate count with and without the
restriction on the same corpus, because a restriction that is lifted without a control is
indistinguishable from a rule that got looser. And the direction matters — per CLAUDE.md,
false negatives are the expensive ones here, and this restriction manufactures 2,020 of them
on a corpus of 14,558.

### 8.5 The sweep is `telescope`-bound, and the obvious fix is the wrong one

Recorded because the wrong optimisation was tried and measured. Reasoning: a physics row is
10-40 KB, both sweep passes `json.loads` it whole, and each reads only half the fields — so
trim the other half. `FastStreamHomeIndex` does that, is verified to produce an identical
candidate set (`--stage verify-fast`, 727 both ways, same arity table, same histogram), and
buys **0.6%**:

```
untrimmed  scan 292.2s  judge  5.5s      (30,000 large rows)
trimmed    scan 290.5s  judge  4.6s
```

The scan is not JSON-bound: pass two parses the *same* 664 MB in 5.5 s. Essentially all 292 s
is `fh_home.telescope` walking the encoding in Python, and `Reader.head_and_args` re-reads
the function half of every application spine through a fresh sub-`Reader` — quadratic in
spine depth, on exactly the deeply-applied terms physics writes.

**Spec.** Either a head-only spine walk for the conclusion (`produces_class` needs only the
head; the carrier rule is the one that needs arguments), or move the telescope into the arena
beside `Corpus.requires` — which §44 already did for the novelty screen, for the same reason,
and measured at 35 minutes to 10.

### 8.6 Not blocking, but the next real cost

`#fh_home_refute` is one `elab` command per line, so a file of *n* probes pays *n* separate
environment round-trips after a single `import Physlib`. The Mathlib runs absorbed this at
2,399 probes. If physics probing scales, a batch command taking a list — or a `--probes
file.json` mode on a small executable in `atlas-extract` — is the shape to build, and it
would remove the `Scratch/*.lean` staging files entirely.

---

## 9. What was run, what was not, and how to run the rest

### Run

```sh
uv run scripts/phys-hypothesis-min.py --stage selftest          # §2, seconds
uv run scripts/phys-hypothesis-min.py --stage verify-fast \
    --slice /tmp/mathlib-algebra.jsonl                          # reader differential, 2 min
uv run scripts/phys-hypothesis-min.py --stage sweep \
    --slice /tmp/fh-physlib.jsonl --out /tmp/phys-candidates-unclosed.json   # §3, 4 min
uv run scripts/phys-hypothesis-min.py --stage sweep \
    --slice /tmp/fh-physlib-merged.jsonl --out /tmp/phys-candidates-merged.json  # §4, 44 min
uv run scripts/phys-hypothesis-min.py --stage screen \
    --slice /tmp/fh-physlib-merged.jsonl --out /tmp/phys-candidates-merged.json \
    --screened /tmp/phys-screened.json                          # closure gate + §5, 8 min
uv run scripts/phys-hypothesis-min.py --stage plan \
    --out /tmp/phys-candidates-merged.json --screened /tmp/phys-screened.json \
    --probe-out /tmp/phys-probe-plan.lean --index /tmp/phys-probe-index.json \
    --all-remaining                                             # §5, seconds
```

### Not run, and why

* **The kernel.** This session could not run `lake`/`lean` — and even with permission it
  could not, because of §8.1. Nothing here is confirmed.
* **The true `Physlib`+`QuantumInfo` import closure.** Extraction was still running at the
  end of the session (495,067 extractable constants, writing at ~146 rows/s toward a
  projected ~9.4 GB). §4 uses the merged corpus instead, with the caveat stated. When the
  real closure lands, re-run `--stage sweep --slice /tmp/fh-physlib-closure.jsonl`; the
  numbers to compare are the 23 and the 12 families. A 9.4 GB corpus may not load for
  `--stage screen` — 5.4 GB took 12.8 GB resident — which is a second reason §8.2's
  prefix-restricted closure query matters.
* **§40's injection control on physics rows.** `screen-sensitivity.py` writes three copies
  of the corpus; at this size that is 16 GB of temporary files and three loads.

### For the orchestrator

```sh
# 1. land §8.1, then from physics/:
lake env lean /tmp/phys-probe-plan.lean > /tmp/phys-probe.log 2>&1; echo "EXIT=$?"
# 2. score it — the index is already in score-probes.py's format, verified round-trip:
uv run scripts/score-probes.py --log /tmp/phys-probe.log \
    --index /tmp/phys-probe-index.json --out /tmp/phys-scored.json
```

The prediction to score against is in `/tmp/phys-probe-index.json` under `prediction`:
**2.0 confirmations of 18 probes, 95% [0.0, 4.6]**. Five or more falsifies it.
