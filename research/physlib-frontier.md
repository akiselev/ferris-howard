# What physlib asserts but does not prove

**Corpus:** `/tmp/fh-physlib.jsonl` — 14,576 rows, 14,563 distinct declarations (13 names
appear twice), extracted from the `physics/` workspace, which pins
`leanprover/lean4:v4.32.0`. **Closure 12.39%.**

**Script:** `scripts/phys-frontier.py`. Every number below is printed by it; nothing here is
estimated. Where a run did not happen, this file says so rather than guessing what it would
have said.

**Control corpus:** `/tmp/mathlib-algebra.jsonl` — 131,062 declarations, closure 99.25%.
Used for the instrument controls, not for physics.

---

## The short version

1. **physlib has no axioms at all** — 0 of 14,563 declarations, against 15 in a Mathlib
   slice extracted by the same tool. The premise that a physics library axiomatizes what it
   cannot prove is false for this one.
2. **18 declarations rest on `sorry`, 0.12%, and they are leaves.** The largest transitive
   impact of any of them is 4 declarations; ten of the twelve direct users carry nothing at
   all. `QuantumInfo.Capacity` is 39% unproved and is one identifiable place where
   formalized physics stops.
3. **The honesty scan's negative control is dead on this corpus.** `honesty([])`, which
   allows no axiom whatsoever, returns the same 18 findings as the default whitelist,
   because an unclosed slice contains no axiom rows for the whitelist to act on. At least
   3,301 declarations (22.67%) rest on `propext` alone. On the Mathlib control the same call
   returns 104,797. §8.1 specifies the fix.
4. **No theorem anywhere rests on 444 of physlib's 3,484 authored definitions — 12.7%**
   (1,350 of all 4,681, before separating out the elaborator's own). The distribution across
   subfields is 3.4x more concentrated than a label permutation allows, so it is a to-do
   list and not noise; and it is not the theorem/definition ratio in disguise (Spearman
   −0.348, p = 0.161).
5. **The largest genre of unproved assertion is one nothing was looking for: 76 physics
   claims stated in prose**, carried as `def`s whose type is `InformalLemma` or
   `InformalDefinition`. Rigid-body mechanics is 19 of them; four quantum models'
   `hamiltonian_essentially_self_adjoint` is four more; grand unification is 29. All 76 are
   invisible to `honesty`, correctly, because they rest on nothing.
6. **A `sorry` has no measurable shape** (family-wise max |AUC−0.5| = 0.130 against a null
   95th percentile of 0.194 — and 16 positives cannot resolve anything smaller). **An orphan
   definition does**: held-out AUC 0.641 against a label-shuffle 95th percentile of 0.523.
   Unused definitions are smaller, shallower, and bind more explicit and fewer implicit
   arguments than used ones.
7. **The erasure half ran on a corpus built for it.** The full closure extraction finished
   (495,067 rows, 5.4 GB, 1h50m) and reducing it to physlib plus the statement closure of
   its citations gives **17,067 declarations at 98.91% closure**. On that corpus: **no
   physlib `sorry` has a proved equivalent at any of the four levels**; **`transport`
   produces 0 novel images and 0 open targets in 4,500 attempts**, replicating §24 on a
   properly closed physics corpus; and §3c's frontier finding **reproduces**
   (`ClassicalMechanics ~ Thermodynamics`, excess +0.517, zero cross-citations) — though the
   query's own size floor excludes it at any setting above 44.
8. **Two silent-empty traps found on the way.** `dict.rs::theory_of` is depth 1 outside
   `Mathlib`, so `"Physlib.Relativity"` names no theory and `dictionary` returns 0 rows with
   no error; and `frontier`'s `min_theory_size` default of 200 removes the only physlib
   frontier result anyone has quoted.

---

## 0. Which results survive an unclosed slice

`/tmp/fh-physlib.jsonl` is `--local`-shaped: it holds the two physics libraries and none of
the constants their statements are headed by. §31 and §32 say what that costs, and
`Corpus.closure()` says how much of it applies here — **12.39%**, against the gate's 95%
floor and the algebra slice's 99.25%. The eight constants most often missing are the
language itself:

```
Eq 7,639   Nat 7,119   OfNat.ofNat 6,739   Real 5,343
Fin 4,577  instOfNatNat 4,215   Complex 3,371   DFunLike.coe 3,140
```

So this study is split down the middle, and each result below is labelled:

| | valid here | why |
|---|---|---|
| **graph-only** | yes | reads `kind`, `uses_statement`, `uses_proof` and the I3 encoding *as extracted*. A citation to a constant with no row is still a citation, and the encoding is in the row. |
| **erasure** | **no** | `skeleton`, `similar`, `dictionary`, `transport`, `frontier`, and `equivalent` at `instances`/`carriers` all ask the corpus for a head constant's signature. A missing head holes nothing and degrades to `Presentation` silently. |

`equivalent` at `exact` and `presentation` consults no signature, so those two levels are
graph-only and are reported here; `instances` and `carriers` are not. That is checkable
rather than asserted: in `crates/fh-atlas/src/skel/erase.rs`, every use of `Signatures` is
behind `level >= Level::Instances` (`arg_kind`, the `InstImplicit` hole) or
`level >= Level::Carriers` (`is_carrier`, `is_concrete_carrier`). The one unguarded *call*,
`is_concrete_carrier` at line 288, has its result used only under the `Carriers` arm.

### The closed corpus, and what it cost

A full closure extraction (`lake exe atlas_extract Physlib QuantumInfo`, no `--local`) ran
for this study and completed: 818,835 constants imported in 49.8 s, 495,067 rows written in
2,999 s, **5.4 GB**, about 1h50m wall. Loading that whole file for every query is not
sensible, so `phys-frontier.py --reduce-from` cuts it to the two libraries **plus the
transitive closure of what their statements cite** — two string-scanning passes, 57 s:

| corpus | declarations | closure | erasure results |
|---|---|---|---|
| `/tmp/fh-physlib.jsonl` | 14,563 | **12.39%** | invalid |
| `+ /tmp/mathlib-algebra.jsonl` (concatenated) | 145,625 | **68.52%** | invalid |
| `/tmp/fh-phys-frontier-closed.jsonl` (statement closure) | **17,067** | **98.91%** | **valid** |
| full extraction | 495,067 | not measured | — |

The statement closure is *shallow* — physlib's 14,558 rows pull in only 3,230 more — because
a type constant's own statement cites almost nothing. That is what makes this affordable: a
corpus that clears the 95% floor is 3.4% the size of the full extraction. Its residual
misses are all elaborator debris (`PiLp.innerProductSpace._proof_1` in 826 statements,
`Physlib.Distribution._proof_1` in 208, three `match_` auxiliaries), the same genre as the
algebra slice's `_sizeOf_inst` misses.

The concatenation fallback CLAUDE.md §7 permits — both workspaces emit `fh-stmt-v1` — was
measured before the extraction finished and **does not reach the floor**: 68.52%. Its
residue names what a physics closure needs that an algebra closure has not got: `Real`
(5,343 statements), `Complex` (3,371), `Fintype` (2,304),
`NormedAddCommGroup.toSeminormedAddCommGroup` (2,209), `PseudoMetricSpace.toUniformSpace`
(2,056), `Matrix` (1,742), `LinearMap` (1,728). Physics sits on analysis; the algebra slice
does not import analysis. It was not used for any result here.

**Each section says which corpus it ran on.** The graph-only results are from the 14,563-row
slice and reproduce on the closed one where re-run; the erasure results are from the
17,067-row closed one only.

---

## 1. The premise is wrong: physlib contains no axioms

The study was set up to census `axiom`s and `sorry`s. There are no axioms.

```
theorem 9,489   def 4,493   constructor 221   inductive 172   recursor 172   opaque 16
axiom 0
```

*[graph-only]* Read off the extractor's `kind` field, never off source text. The control
that makes this a fact about physlib rather than about the extractor: the same field on
`/tmp/mathlib-algebra.jsonl` returns **15** declarations of kind `axiom` — `propext`,
`Classical.choice`, `Quot.sound`, `sorryAx` and eleven compiler axioms — so the extractor
emits the kind when the kind is there.

This matters for how the rest of the question has to be asked. §23's `honesty` fix exists
because B7's corpus is 113 axioms and every one is a graph leaf; the genre it was fixed for
is *statement-level formalization*, and physlib is not in that genre. physlib does not
axiomatize physics. It defines and proves, and where it cannot prove, it writes `sorry`.

So "what does physlib assert but not prove" has four answers, and they are different sizes:

| genre | count | what it is | found by |
|---|---|---|---|
| `sorry` | **18** | a claim stated formally, proof missing | `honesty` (§2) |
| `opaque` | **16** | a constant whose value is sealed — and all 16 are metaprogramming, none physics | `kind` census (§4) |
| **prose** | **76** | a claim stated in natural language and registered as data | marker types (§5) |
| **orphan** | **444** | a concept defined and never used in any theorem | reachability (§4) |

Only the first is what the honesty scan is built to find, and it is the smallest.

---

## 2. The honesty census: 18 declarations, 0.12%, and every one a leaf

*[graph-only]* `Corpus.honesty()` with the default whitelist:

```
18 findings (0.12% of 14,563), all `sorryAx`, none an axiom
16 theorems + 2 definitions
```

By subfield, against that subfield's size:

| subfield | unproved | of | rate |
|---|---|---|---|
| **QuantumInfo.Capacity** | **7** | 18 | **38.89%** |
| Physlib.Cosmology | 1 | 42 | 2.38% |
| Physlib.QuantumMechanics | 3 | 998 | 0.30% |
| QuantumInfo.States | 1 | 347 | 0.29% |
| Physlib.ClassicalMechanics | 2 | 631 | 0.32% |
| Physlib.QFT | 2 | 1,755 | 0.11% |
| Physlib.Relativity | 2 | 2,143 | 0.09% |

**`QuantumInfo.Capacity` is 39% unproved and it is the whole module.** All seven of its
`sorry`s are the quantum-capacity cluster —
`quantumCapacity_eq_piProd_coherentInfo`, `coherentInfo_le_quantumCapacity`,
`zero_le_quantumCapacity`, `quantumCapacity_ge_log_dim_in`, `bddAbove_achievesRate`,
`not_achievesRate_gt_log_dim_in/out`. That is one identifiable place where formalized
physics stops: the LSD theorem and its corollaries are *stated* in Lean and proved nowhere.

### And nothing rests on them

| | |
|---|---|
| declarations citing `sorryAx` directly | 12 |
| declarations resting on it transitively | 18 |
| **contagion** | **1.50x** |
| largest transitive impact of any one of them | **4** |

The load ranking is almost flat: `CPTPMap.not_achievesRate_gt_log_dim_in` carries 4
dependents, `QuantumMechanics.HydrogenAtom.angularMomentum_commutation_lrl` carries 2, and
the **other ten carry zero**. physlib does not build on what it has not proved. That is a
stronger property than "few sorries" and it is the one worth reporting: there is no
declaration in this corpus whose retraction would collapse a subfield.

The two definitions in the list are worth naming separately, because a `sorry` inside a
*definition* is not a missing proof but a missing object: `Cosmology.FLRW` and
`ClassicalMechanics.CoplanarDoublePendulum.ConfigurationSpace`. The FLRW metric — the
standard cosmological spacetime — is a stub.

---

## 3. The instrument is blind on exactly this corpus, and it was measured, not assumed

*[graph-only]* CLAUDE.md's rule for B3 is that a tool which says everything is fine is worse
than no tool, so `honesty` is run with its negative control: the empty whitelist, which
allows nothing and must therefore be strictly louder.

| corpus | `honesty(default)` | `honesty([])` | control |
|---|---|---|---|
| `/tmp/mathlib-algebra.jsonl` (99.25% closed) | 15 | **104,797** | fires |
| `/tmp/fh-physlib.jsonl` (12.39% closed) | 18 | **18** | **does not fire** |
| `/tmp/fh-phys-frontier-closed.jsonl` (**98.91%** closed) | 18 | **18** | **still does not fire** |

The three runs are the same call in the same script; only the corpus differs. On physlib the
empty whitelist reports **exactly the same 18 findings** as the whitelist that permits
classical logic — which cannot be right for a library built on Mathlib.

**And the third row is the one that matters.** Closing the corpus to 98.91%, which passes the
project's own `slice-closure.py` gate, does **not** fix it. The reason is exact and general:
`Corpus.closure()` measures **application heads in statements**, and Lean's axioms appear
only in **proof terms**. No statement in any library mentions `Classical.choice`, so no
statement closure contains its row, so the honesty scan cannot enumerate it however closed
the corpus is by the measure the project checks. **The gate that exists does not cover the
property this query depends on.**

### The cause

`atlas.rs`'s honesty scan, as §23 left it:

```rust
for name in g.names() {
    if g.get(name).is_some_and(|d| d.kind == "axiom") && !allowed.contains(name) && ...
```

It enumerates axioms **that have a row in the slice**. An unclosed slice has none: physlib
contains no row for `propext`, `Classical.choice`, `Quot.sound` or `sorryAx`. The whitelist
therefore has nothing to exclude and nothing to include, and the control goes quiet. Only
`sorryAx` survives, because it is seeded by name a few lines earlier and `impact` accepts a
seed that is not in the slice.

### What it should have found

`impact` takes an out-of-slice name, so the number the scan could not reach is directly
measurable:

| axiom | in slice | resting on it, 14,563-row slice | resting on it, 17,067-row closure |
|---|---|---|---|
| `propext` | no | **3,263 (22.41%)** | **3,662 (21.46%)** |
| `Classical.choice` | no | 113 (0.78%) | **5,681 (33.29%)** |
| `sorryAx` | no | 18 (0.12%) | 18 (0.11%) |
| the other 12 Lean/compiler axioms | no | 0 | 0 |
| **union** | | **3,301 — 22.67%** | **6,716 — 39.35%** |

`honesty([])` reported **18** on both. The negative control is **99.5% dead** on the small
slice and **99.7% dead** on the closed one.

The two columns also confirm that the unclosed figure was an underestimate in exactly the
predicted way: `Classical.choice` goes from 113 to 5,681 once the Mathlib lemmas that reach
it are present, because a physlib theorem that uses choice through a Mathlib lemma has no
path to it inside a physlib-only slice. **39.35% of this corpus rests on a Lean axiom, and
the scan whose job is to say so reports 0.11%.**

This is §23's finding one level up. §23 fixed "an axiom is a graph leaf, so its impact is
empty"; the fix reads the axiom off a row, and an unclosed corpus has no rows to read. §32
is the same shape again — a diagnostic that read 0 on every corpus ever built. The engine
change this calls for is specified in §8.1.

**Consequence for §23's own table.** It records physlib as `18 → 18 — unchanged, no declared
axioms, all sorryAx`. That reading is correct about the count and wrong about what it means:
the count is unchanged because the corpus contains no axiom rows, not because physlib rests
on nothing but `sorry`. 22.67% of it rests on `propext`.

---

## 4. The orphans: 444 definitions no theorem rests on

*[graph-only]* This is the large answer to the question, and it is a to-do list rather than
a soundness report. A definition nothing has been proved about is a concept the library has
*named* and not yet *used*.

**Method.** "Does any theorem rest on `d`" is the forward reachability of the theorem set,
so it is one multi-source DFS from all 9,489 theorems, not 4,681 separate traversals. The
complement, among the 4,681 declarations of kind `def`/`inductive`/`opaque`, is the orphan
set. Two lenses, because they are different claims:

* `statement` — no theorem *states* anything involving it;
* `both` — no theorem mentions it even inside a proof. The strictest reading, and the one
  the headline uses.

**Stratification, not filtering.** Lean emits `X.recOn`, `X.noConfusion` and `X.ctorIdx` for
every inductive, and those are orphans in bulk without being anybody's to-do list. They are
separated by the *structural* derivativeness measure of `skel/index.rs` — short proof, small
in-degree, cites recursors and constructors — reimplemented here over the same three graph
signals, and **validated against the name blocklist used as held-out labels, never as an
input**: **AUC 0.872**, against a permutation null whose 95th percentile is 0.515. (The
engine reports 0.899 for its own on physlib; the gap is that this reimplementation is a
percentile-rank average with no arena behind it.) The cut is placed at the blocklist's own
prevalence, 25.5%, so the strata are comparable in size to the labelled classes without the
blocklist choosing who goes where.

| lens | orphans | of 4,681 definitions | authored stratum | of 3,484 authored |
|---|---|---|---|---|
| `statement` | 2,163 | 46.2% | 1,023 | **29.4%** |
| `both` | 1,350 | 28.8% | **444** | **12.7%** |

So: **12.7% of physlib's authored definitions have never appeared in any theorem, and 29.4%
appear in no theorem's statement.**

### It is not spread evenly, and that is tested

Orphan rate among authored definitions, `both` lens:

| subfield | orphans | authored defs | rate |
|---|---|---|---|
| Physlib.Meta | 102 | 135 | **75.6%** |
| QuantumInfo.ResourceTheory | 17 | 52 | **32.7%** |
| Physlib.Cosmology | 3 | 11 | 27.3% |
| QuantumInfo.ForMathlib | 48 | 209 | 23.0% |
| QuantumInfo.ClassicalInfo | 10 | 48 | 20.8% |
| Physlib.FluidDynamics | 9 | 48 | 18.8% |
| Physlib.Units | 26 | 150 | 17.3% |
| Physlib.ClassicalFieldTheory | 1 | 7 | 14.3% |
| Physlib.QuantumMechanics | 28 | 211 | 13.3% |
| Physlib.Relativity | 65 | 535 | 12.1% |
| Physlib.SpaceAndTime | 32 | 264 | 12.1% |
| Physlib.Mathematics | 27 | 252 | 10.7% |

**The negative control.** "Subfield X has the most orphans" is worth nothing if it just
means "X has the most definitions", so the orphan label is permuted across definitions 1,000
times and the spread of per-subfield rates re-measured (subfields with at least 20 authored
definitions):

| lens | observed spread | permuted 95th pct | verdict |
|---|---|---|---|
| `both` | **0.1672** | 0.0498 | structured, 3.4x |
| `statement` | **0.1670** | 0.0678 | structured, 2.5x |

`Physlib.Meta` at 75.6% is the library's own metaprogramming and not physics; it is left in
the table rather than filtered out, because removing the largest row of a distribution is
how a control gets quietly disabled. The physics reading is the rest of the ranking:
**resource theory, cosmology, classical information, fluid dynamics and the units API are
where physlib has defined most and proved least.**

Two subfields sit above the ranking's midpoint but below the null's inclusion threshold of
20 authored definitions, so they are reported and not tested: `Physlib.Cosmology` (3 of 11,
27.3%) and `Physlib.ClassicalFieldTheory` (1 of 7, 14.3%). Cosmology is the subfield that
also holds one of the two `sorry`-stubbed definitions.

### Is 12.7% high? The comparison does not exist, and that is worth knowing

The obvious next question is what a mature library scores. Run on
`/tmp/mathlib-algebra.jsonl`, the same query returns **64.7%** of 57,678 definitions
orphaned at the `both` lens, and 60.2% restricted to `Mathlib.*` — apparently five times
physlib's rate. **That comparison is invalid, in a way that matters for anyone reusing this
query.**

The algebra slice is the *import closure of one Mathlib file*. Its 2,502 `Mathlib.Algebra`
definitions are the ones that file transitively imports; the theorems that use them mostly
live in Mathlib modules the slice does not contain. A definition therefore reads as orphaned
whenever its consumers are downstream of the slice boundary, and 50.0% of `Mathlib.Algebra`
scoring orphaned is mostly that artifact.

physlib has no such boundary: the slice holds all of `Physlib` and all of `QuantumInfo`, so
every consumer that exists is in it. **The orphan query is only meaningful on a corpus
closed under *consumers*, which is a different and stronger condition than being closed
under citations (§0), and only physlib satisfies it here.** So 12.7% stands on its own and
is not compared.

Two things do transfer. The spread test fires on the Mathlib slice too (0.1903 against a
permuted 95th percentile of 0.0662), so the concentration finding is not a physlib
peculiarity. And the derivativeness stratification **fails its own validation there** — AUC
0.703 against the name blocklist, below the 0.75 bar fixed in advance — so the script reports
Mathlib unstratified, as it is required to. The bar did its job on the first corpus that
missed it.

### The 16 `opaque` constants are not physics

The third assertion genre after `axiom` and `sorry` is `opaque`: a constant whose type is
checked and whose value is sealed, so nothing can be proved about it by unfolding. physlib
has 16, and **all 16 are metaprogramming** — `Physlib.noteExtension`,
`Physlib.todoExtension`, `pseudoExtension`, `sorryfulExtension`, `wantedExtension`,
`Physlib.CollectSorry.collect`, `transverseTactics.processCommands`,
`HermitianMat.findMatrixPSDInExpr` and friends. Environment extensions and tactic
machinery. Nothing in this genre is a physical assertion, which is worth stating precisely
because it is the genre most likely to be assumed guilty.

### It is not the theorem/definition ratio wearing a hat

The cheap proxy for the same question is a subfield's theorem-to-definition ratio, which the
census prints (`QuantumInfo.Entropy` 5.96, `Physlib.QFT` 3.08 … `Physlib.FluidDynamics`
0.35, `Physlib.Meta` 0.18). Over the 18 subfields with at least 20 authored definitions,
Spearman between orphan rate and that ratio is **−0.348** (two-sided permutation p = 0.161,
10,000 shuffles), and **−0.226** excluding `Physlib.Meta` (p = 0.384). The sign is the
expected one and the correlation is not significant, so the orphan measure is **not** a
restatement of "few theorems per definition" — `QuantumInfo.ForMathlib` has the second-best
theorem ratio in the library (4.35) and the third-worst orphan rate (23.0%).

---

## 5. The genre nothing was looking for: 76 claims stated in prose

*[graph-only]* This is the sharpest answer to the question and no existing query returns it.

**How it was found, structurally.** Ask the graph which constants declarations *instantiate
in their types* and which of those constants are declared in the library's own
metaprogramming layer. A type that lives in `Physlib.Meta.*` and appears in the type of a
declaration in `Physlib.ClassicalMechanics` is a marker: the declaration carrying it asserts
something the kernel is not checking. Citers inside the marker's own module are excluded —
they are the elaborator's accessors for the type itself.

Two markers come back, both `inductive` in `Physlib.Meta.Informal.Basic`:

| marker | declarations carrying it | of which outside the marker's module |
|---|---|---|
| `InformalLemma` | 58 | **44** physics + 1 `Meta` |
| `InformalDefinition` | 46 | **32** physics + 1 `Meta` |

**76 physics declarations are stated in prose and registered as data.** Their type is a
record with a `tag` and a `deps` list; they are `def`s, they carry no proposition, and the
kernel checks nothing about the claim. By subfield:

| subfield | informal lemmas | informal definitions | total |
|---|---|---|---|
| Physlib.Particles | 11 | 18 | **29** |
| Physlib.ClassicalMechanics | 19 | 7 | **26** |
| Physlib.QuantumMechanics | 8 | 6 | 14 |
| Physlib.Relativity | 4 | 1 | 5 |
| Physlib.StatisticalMechanics | 1 | 0 | 1 |
| Physlib.SpaceAndTime | 1 | 0 | 1 |

And, as with the `sorry`s: **0 of the 76 are cited by anything.** (Two of the 78 raw hits are
cited, and both are `Informal.constantInfoToInformal*` — the elaborator's own machinery,
which is why the physics count is 76.)

### What this says about where physics stops

The list is legible, and three clusters carry it:

* **Rigid-body mechanics is almost entirely prose.** 19 of the 44 informal lemmas are
  `RigidBody.*` — `euler_equations`, `intermediate_axis_instability`,
  `transport_law_for_angular_momentum`, `decomposition_of_motion`,
  `small_oscillations_about_equilibrium`, `rigid_body_dof`. `Physlib.ClassicalMechanics`
  looks healthy by every other measure in this document (3.4% orphan rate, 2 `sorry`s) and
  its rigid-body chapter is a table of contents.
* **The analytic core of quantum mechanics is prose.** Four models in
  `Physlib.QuantumMechanics` state `hamiltonian_essentially_self_adjoint` informally —
  free particle, harmonic oscillator, infinite square well, rectangular barrier — plus
  `potentialOperator_isSelfAdjoint` and `potentialFunction_aestronglyMeasurable`. The
  Hamiltonians are defined formally; that they are self-adjoint, which is what makes the
  dynamics exist, is not.
* **Grand unification is prose on both sides.** `Physlib.Particles` carries 18 informal
  *definitions* — `GeorgiGlashow.inclSM`, `PatiSalam.embedSMℤ₆Toℤ₂`,
  `Spin10Model.inclPatiSalam`, `StandardModel.gaugeBundleI` — and 11 informal lemmas about
  them, including `Spin10Model.inclSM_eq_inclSMThruGeorgiGlashow` and
  `StandardModel.HiggsField.gauge_orbit_surject`. The embeddings *and* their coherence are
  both unformalized.

### And every honesty query in this project is blind to all 76

`honesty` asks a kernel-trust question — what does this rest on that is not proved — and a
prose claim rests on nothing, so it is invisible by construction rather than by bug. That is
the right behaviour for `honesty` and the wrong answer for "what does this library assert
but not prove". 76 against 18 is the size of the gap.

A limitation worth recording with it: physlib also carries `@[sorryful]` and `@[pseudo]`
attributes and a `todoExtension`, and **attributes are not extracted** — `atlas_extract`
reads `ConstantInfo`. The library's own record of what it has not done is therefore partly
outside the Atlas's reach, and the 76 are only the part of it that took the form of a
constant.

---

## 6. Does an assertion have a shape? Three arms, one answer

*[graph-only — every feature is read out of the I3 encoding stored in the row; nothing is
looked up, so the unclosed slice does not affect this.]*

The features are 21 counts plus three ratios taken off the statement encoding: node count,
byte length, maximum nesting depth, constants total and distinct, applications, sorts,
bound variables, literals, projections, lets, `Pi`s and `lam`s by binder info, and the
binder profile of the root spine. **The scanner they come from is differentially checked
against `scripts/fh_encoding.py`** — a reader written for a different purpose by different
code — and agrees on 2,000 of 2,000 sampled statements. Without that check a bug in the
scanner would be invisible to every control below, since all of them ride on it.

### Arm A — axioms vs theorems: UNRUNNABLE

0 positives (§1). Recorded as unrunnable rather than as a null result, with the Mathlib
control that shows the extractor emits the kind.

### Arm B — `sorry`-carrying vs proved theorems: no signal, and the bound on that

16 unproved theorems against 9,473 proved.

| test | result |
|---|---|
| per-feature tests significant at 95% | **0 of 21** (chance alone gives 1.1) |
| family-wise `max\|AUC−0.5\|` | **0.130** (`sorts`) |
| null 95th percentile / null max | 0.194 / 0.310 |
| verdict | **no signal** |

The family-wise null shuffles the label once and takes the maximum deviation across all 21
features, which preserves their correlation — `nodes`, `bytes` and `apps` all measure size
and a per-feature null pretends they are independent tests.

**This corrected an earlier version of this run.** With per-feature nulls only, `sorts` came
back at AUC 0.630 against a null interval of [0.372, 0.622] and was printed as SIGNIFICANT —
one hit in twenty-one, which is exactly the false-positive count 21 tests at α = 0.05
produce. Under the family-wise statistic it is not significant, and the number of hits is
now printed beside the number chance predicts so the comparison cannot be skipped.

**With the power stated:** at 16 positives this test cannot see a true |AUC − 0.5| below
**0.194** (AUC 0.694). A real but smaller shape difference between a `sorry` and a proof is
not excluded — it is unmeasurable at this sample size, and the honest statement is that
physlib does not contain enough unproved theorems to answer the question.

### Arm C — orphan vs cited definitions: separable, with the control that says so

444 orphans against 3,040 cited definitions, in the authored stratum. Fitted on half,
scored on the other half, split by md5 of the name so it does not move between runs.
**Statement-shape features only** — a graph feature such as in-degree would be the label
wearing a hat, since the label *is* a graph property.

| | |
|---|---|
| held-out AUC, real labels | **0.641** |
| label-shuffle control, 20 refits: mean / 95th pct | 0.501 / **0.523** |
| verdict | **separable** |

The shuffle control is a refit, not a rescoring: labels are permuted, the model is trained
again on the permuted training half and evaluated on the permuted test half, so anything the
pipeline could learn from the split rather than the data shows up in it. It lands on chance.

**The signal is multivariate.** The strongest single feature reaches |AUC − 0.5| = 0.069
(`root_implicit`, 0.431), so no one count separates the classes and the 0.641 is a
combination. The directions are consistent and readable:

| feature | AUC | reading |
|---|---|---|
| `root_implicit` | 0.431 | orphans bind fewer implicit arguments |
| `maxdepth` | 0.437 | orphans are shallower |
| `nodes` / `bytes` | 0.442 / 0.445 | orphans are smaller |
| `apps` | 0.447 | orphans apply fewer things |
| `root_default` | 0.558 | orphans bind more *explicit* arguments |

**An unused definition in physlib is small, shallow, and concrete.** A definition that gets
used is larger, more deeply nested, and more polymorphic — more of its arguments are
implicit, which is what a definition looks like once it has been generalized to serve
several theorems. That is a plausible causal story in both directions (a definition may be
unused *because* it is over-specific, or under-generalized *because* nobody has needed it
yet) and nothing here distinguishes them.

---

## 7. Asserted here, proved there — on the closed corpus

*[erasure — `/tmp/fh-phys-frontier-closed.jsonl`, 17,067 declarations, closure 98.91%]*

The question: is something asserted in one part of the corpus proved in another?

### The direct answer: no, at any level

For each of the 18 declarations resting on `sorry`, is there a declaration elsewhere in the
corpus whose statement erases to the same thing and which is *not* itself unproved?

| level | valid on | unproved declarations with a proved equivalent |
|---|---|---|
| `exact` | either corpus | **0 of 18** |
| `presentation` | either corpus | **0 of 18** |
| `instances` | closed only | **0 of 18** |
| `carriers` | closed only | **0 of 18** |

**No physlib `sorry` is a restatement of something the corpus already proves**, at any of
the four levels the engine offers, up to and including erasing every carrier. If a
transportable proof exists for one of these 18, it is not an equal statement — it would have
to come through analogy, which is what the next two queries are for.

### `transport` still produces nothing — replicated on a closed physics corpus

§24 measured `transport` as inert and this study repeats the measurement rather than citing
it. Over the 15 pairs of the six largest physics subfields, taking up to 8 transportable
rows per dictionary against 60 theorem subjects each:

| | |
|---|---|
| transportable rows tried | 75 |
| transport attempts | 4,500 |
| `NoMatch` (subject does not match the row's left pattern) | **4,472 (99.4%)** |
| `ScopedRow` | 0 |
| successful | **28** |
| …image equals the row's right-hand side | 12 |
| …image equals the subject | 16 |
| …**genuinely new image** | **0** |
| …**open targets** (`exists == False`) | **0** |

Every successful transport lands on either the row it came from or the statement it started
from. **§24's verdict holds on a properly closed physics corpus with the current engine**,
and its diagnosis — that a hole-level substitution has no purchase on a statement it was not
derived from, and a row must be lifted to a rewrite on *constants* before transport can mean
anything — is unaffected by corpus quality. It was never a corpus problem.

The dictionaries themselves are not empty, which is what makes the null informative:
`Particles ~ QFT` has 128 rows (66 transportable), `Relativity ~ SpaceAndTime` 171 rows (61
transportable), `Particles ~ SpaceAndTime` 112 rows (91 transportable). The rows exist and
transport does nothing with them.

### A silent-empty trap worth recording

The first run of this returned **0 rows from every dictionary and no error**.
`dict.rs::theory_of` is depth 2 under `Mathlib` and **depth 1 everywhere else**, so
`"Physlib.Relativity"` names no theory at all and `dictionary` returns an empty result
rather than raising. All of physlib is one theory to `dictionary` and `frontier`; the
physics subfields are invisible to both. This study re-roots the modules
(`Physlib.Relativity.X` → `Relativity.X`) into `/tmp/fh-phys-frontier-theories.jsonl` before
calling them, and `phys-frontier.py` now prints the row count per pair so an empty
dictionary cannot be read as a null result again. **Any earlier physlib `dictionary` or
`frontier` result should be checked for which of these two shapes its theory names had.**

### The frontier replicates — and its size floor nearly hid it

§3c's physlib frontier result was computed on the 12.39%-closed slice, so it needed
re-checking. Re-run on the closed corpus, it **reproduces**:

| pair | §3c (unclosed) | here (98.91% closed) | expected | excess | cross-citations |
|---|---|---|---|---|---|
| `SpaceAndTime ~ Thermodynamics` | 0.673 | **0.579** | 0.098 | **+0.481** | **0** |
| `ClassicalMechanics ~ Thermodynamics` | 0.636 | **0.553** | 0.035 | **+0.517** | **0** |
| `Electromagnetism ~ Thermodynamics` | 0.527 | **0.447** | 0.050 | **+0.397** | **0** |

Three theories share half their shape buckets with thermodynamics and never cite it. The
values drop a little — `theorems_only` leaves Thermodynamics at 44 theorems — and the
ranking, the magnitudes and the zero cross-citations all survive closure.

**But the first attempt here missed all three, and the reason is a filter.** At
`min_theory_size=100` — below the query's own default of 200 — Thermodynamics (44 theorems)
is excluded, and the ranking that comes back instead is led by `StringTheory ~ Units` at
excess +0.036, an order of magnitude smaller, with most pairs *negative*. The finding and
the noise floor are separated by one parameter that silently drops small theories.

That is CLAUDE.md's rule about narrowing filters, in a query that ships one by default: the
size floor exists because expected similarity is `max(|A|,|B|)/M` and small theories are
noisy, and it removes the corpus's strongest signal to get there. **`min_theory_size`
deserves a sweep rather than a value**, and `frontier`'s docstring should say that its
default of 200 would have excluded the only physlib result anybody has quoted.

---

## 8. Engine changes, specified

Three, in the order they are worth doing. Each names the five places CLAUDE.md §6 requires:
engine, CLI, binding and `.pyi`, `fh mcp`, and a gate that exercises it against a real slice.

### 8.1 `honesty` must not go quiet on an unclosed slice

**Defect.** `crates/fh-atlas/src/bin/atlas.rs` (honesty arm) and its twin in
`crates/fh-atlas-py/src/lib.rs:1008` enumerate candidate axioms with
`for name in g.names() { if kind == "axiom" && !allowed.contains(name) … }`. A slice that is
not closed under its citations contains **no axiom rows at all**, so the whitelist has
nothing to allow and nothing to reject. Measured above: `honesty([])` and `honesty(None)`
return the identical 18 findings on physlib, where the union of `impact` over Lean's axioms
is at least 3,301. §23 fixed "an axiom is a graph leaf so its impact is empty"; this is the
same failure one level up, and §32's dead `degraded_spines` counter is the same failure
again.

**Change.**

1. *Seed the kernel axioms by name, unconditionally.* `propext`, `Classical.choice`,
   `Quot.sound` and `sorryAx` are reserved names in Lean core; no other constant can bear
   them. Treat them as axioms whether or not the slice holds their rows — exactly as
   `sorryAx` is already treated three lines earlier. This alone restores the negative
   control.
2. *Make blindness a distinct verdict from cleanliness.* Count the distinct constants that
   appear in some `uses_statement`/`uses_proof` and have no row (`closure()` already does
   the analogous count over application heads; this one is over citation targets). The
   verdict becomes one of three:
   `k finding(s)` · `clean — N declarations, all citations resolved` ·
   `clean, but M cited constants have no row in this slice: this is a lower bound`.
   `Report.clean` must be **false** in the third case, so a gate reading the exit status
   cannot pass on a corpus the scan could not see.
3. *Surface it.* `Corpus.honesty` returns `list[tuple[str, str]]` and changing that breaks
   callers, so add `Corpus.honesty_report() -> HonestyReport` with `findings`,
   `unresolved_citations`, `resident_axioms` and `verdict`, keep `honesty()` as the
   shorthand, and stub both in `fh_atlas.pyi`.
4. *`fh mcp`* gains `honesty_report` beside `honesty`; an agent asking "is this corpus
   trustworthy" needs the blindness count more than the finding list.
5. *The gate*, paired the way `scripts/slice-closure.py` is, because a threshold no corpus
   can miss is not a check: on `/tmp/mathlib-algebra.jsonl`, `honesty([])` must exceed
   10,000 findings; on the same slice restricted to `Mathlib.*`, it must return the **blind**
   verdict rather than a clean one. Both arms must be asserted — the current failure mode is
   exactly that the second looks like the first.

### 8.2 `Corpus.orphans(lens, kinds, from_kinds)`

**Why it is not already expressible.** "Does any theorem rest on `d`" is `impact(d)`
filtered by kind, and asking it for every definition is one BFS per node — 4,681 traversals
of the same graph on physlib, 53,593 on a Mathlib slice. The whole question is a *single*
multi-source DFS from the theorem set, and the complement of what it reaches is the answer.
The query in this study is 20 lines and runs in 0.8 s on physlib; as `impact` in a loop it
is not affordable, which is why nobody has drawn this map.

```python
def orphans(self, lens: Lens = "both",
            kinds: Sequence[str] = ("def", "inductive", "opaque", "structure"),
            from_kinds: Sequence[str] = ("theorem",)) -> list[str]:
    """Declarations of `kinds` that no declaration of `from_kinds` transitively cites."""
```

`from_kinds` is a parameter rather than fixed to `theorem` because `from_kinds=("def",)`
answers the stricter "defined and not used even in another definition". Belongs in
`graph.rs` beside `impact`; O(V+E).

**The gate**, with the property that makes it able to fail: the `both`-lens orphan set must
be a **subset** of the `statement`-lens one for every corpus, since `both` has strictly more
edges. It is a superset relation by construction, so a violation means the lens plumbing is
wrong rather than that the corpus changed. Measured here: 2,163 → 1,350, and the smaller is
contained in the larger.

### 8.3 An erasure-dependent query should say when its corpus cannot support it

**Why.** `skeleton`, `similar`, `dictionary`, `transport`, `frontier` and `equivalent` above
`presentation` all degrade *toward output* on an unclosed slice (§31). `Corpus.closure()`
exists and answers in 22 s, and nothing calls it. This study had to build its own guard —
`mode_census` prints the coverage and the erasure modes refuse to run below 0.95 — because
nothing in the engine distinguishes a `skeleton` computed against known signatures from one
computed against none. Every erasure number in §7 was produced only after the corpus was
rebuilt to clear the floor, and no engine surface would have objected had it not been.

**Change.** In `crates/fh-atlas-py`, compute closure coverage lazily on the first
erasure-dependent call and emit a Python `RuntimeWarning` naming the coverage and the three
worst missing heads when it is below 0.95. A warning rather than an error: §31's own
guidance is that restriction is sometimes necessary, and `warnings.simplefilter("error")`
turns it into a hard stop for a caller who wants one. The cost is one `closure()` per
`Corpus`, paid once, and only by sessions that ask an erasure question.

**The gate:** loading `/tmp/fh-physlib.jsonl` and calling `skeleton` must raise under
`warnings.simplefilter("error")`; the same call on `/tmp/mathlib-algebra.jsonl` must not.

**Not sufficient on its own.** §3 measured that a 98.91%-closed corpus still cannot see a
single axiom, because `closure()` counts statement heads and axioms live in proof terms. So
8.3 protects the erasure queries and does nothing for `honesty`; 8.1's blindness count must
be over citation targets under **both** lenses, and the two checks are not
interchangeable.

### 8.4 `theory_of` needs a parameter, and `frontier` needs a sweep

Two defects found by using them, both of the silent-empty kind (§7):

* `dict.rs::theory_of` hardcodes depth 2 under `Mathlib` and depth 1 elsewhere. Every
  physics subfield is therefore invisible to `dictionary` and `frontier`, and asking for one
  by name returns an empty dictionary rather than an error. It should take a depth (or a
  prefix→depth map) as an `IndexConfig` field, and `dictionary` should **raise** on a theory
  name that matches no module rather than return zero rows — "no such theory" and "no rows
  between these theories" are different answers and currently print the same.
* `frontier(min_theory_size=200)` excludes the only physlib pair anybody has quoted.
  Return the floor as a swept curve, or at minimum have the docstring record that the
  default silently removes small theories and that physlib's strongest pair is at 44.
