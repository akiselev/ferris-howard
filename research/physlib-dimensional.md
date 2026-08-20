# Dimensional analysis as latent structure in statement shape

**What was asked.** Can the Atlas recover a dimensional signature for a declaration purely
from the shape of its statement, without reading unit annotations by name? And does
dimensional agreement predict analogy better than the retention score?

**What came back.** Six experiments. Three work, one works and says the opposite of what was
hoped, one has a confound that its own control exposed, and one is a clean negative. The
failures are the more useful half.

| | result |
|---|---|
| **E1 — discover the dimension type structurally, then decode exponent vectors** | works, and is exact — over 0.27% of the library |
| **E2 — recover a grading from equations alone** | works, and is *thin*: 21 laws from 6,840 declarations, against **0** on both controls |
| **E3 — held-out prediction** | the metric as designed is confounded; reported anyway, with the reason |
| **E4 — dimensional-error detection** | the injection control passes 20/20; the corpus is *not* thereby certified |
| **E5 — dimensional agreement as an analogy signal** | decisively no: undefined on 190/190 analogue pairs where retention scores AUC 0.999 |
| **E6 — clustering by quantity constants** | works: 119x enrichment over a shuffled control, and it is mostly module structure |

Everything below is measured by `scripts/phys-dimensional.py`. Numbers name the slice and
the statement-size cap they were taken at. To reproduce:

```sh
uv run --no-sync scripts/phys-dimensional.py --selftest        # the synthetic gate, 1 s
uv run --no-sync scripts/phys-dimensional.py --slice <slice> --experiments 1,2,3,4,5,6 \
    --cap 20000 --control /tmp/mathlib-algebra.jsonl
# add --skip-closure only to prototype; the run then prints that it was skipped
```

The runs behind this document used `--skip-closure` on `/tmp/fh-physlib.jsonl` for the
experiments §0 shows do not need a closure, and are marked as such.

The single most useful line: **physlib recovers 21 multi-atom dimensional relations and both
negative controls recover zero** — a Mathlib slice twenty times larger, and physlib's own
equations with the atoms rewired at random. That is the result. Everything else is either
what it cost to get there or what it does not entitle anyone to say.

---

## 0. The corpora, and the one gate that had to run first

`/tmp/fh-physlib.jsonl` — 14,576 declarations, 553 MB of I3 encoding, extracted from
physlib with the extractor's output filter. An independent Python implementation of the
closure check (`python_closure`, written against the parsed trees rather than against the
Rust index) puts it at:

```
heads     known 143,882  unknown 607,881
coverage  19.14%   floor 95%
worst     Fin (68,112 statements)   OfNat.ofNat (58,495)   instOfNatNat (49,628)
          Matrix (12,367)   Eq (9,106)   NormedField.toField (9,180)
```

That is §31's failure mode reproduced from scratch on a second corpus: the slice does not
contain `Eq`, `Fin` or `OfNat.ofNat`, so every erasure over it degrades silently toward
"no information". The script exits non-zero on it unless `--skip-closure` is passed, and
`--skip-closure` prints that it was passed.

**Which experiments this constrains, and which it does not.** The distinction matters
because it decides what is reportable from an unclosed corpus:

* **E1 needs one.** It reads each constant's own type row to decide what is `Dimension`-valued
  and what is a type former, and a missing row is invisible to it. Its ranking on an unclosed
  slice is therefore *under*-inclusive: a closure could add candidate carriers, never remove
  the one it found.
* **E2, E3, E4 and E6 do not.** They read statement trees and nothing else — no constant
  signature is looked up, no citation is followed. Their answer over a given set of
  declarations is the same whether or not the slice also holds that set's foundation.
* **E5 was written not to need one.** The obvious design validates its ground truth with
  `Corpus.skeleton`, which erases; this one uses `phys_i3.shape_key`, a name-erased shape
  computed from the tree. Scoring uses `Corpus.generalize`, which anti-unifies the encodings
  as written and does not erase. See §7.

The Mathlib control is `/tmp/mathlib-algebra.jsonl` (131,062 declarations; 99.25% closed by
`scripts/slice-closure.py`, **99.52%** by the Python check here, whose residual misses are
the same harmless `_sizeOf_inst` family §32 reports). Two implementations agreeing to within
a third of a point on a closed corpus and disagreeing by 80 points on an unclosed one is the
differential working. The control runs through the identical pipeline with the identical
operator vocabulary.

**The statement-size cap is a filter, so here is what it drops.** Physlib's size
distribution is extreme — median 1.5 kB, but 674 of 14,576 rows hold 81% of the bytes, all
of them Lorentz-tensor contractions and distributional-electromagnetism computations (the
largest is `realLorentzTensor.leviCivita_contract_self` at 71 MB). At `--cap 200000` the run
keeps 14,147 rows; at `--cap 20000` it keeps 12,429 and the 2,147 dropped are led by
`Physlib.Particles.StandardModel.Basic` (69) and the QFT `SuperCommute` modules.

---

## 1. The one input that is by name, and why it is not a semantic oracle

The solver is told that `HMul.hMul` multiplies, `HAdd.hAdd` adds, `HDiv.hDiv` divides,
`HPow.hPow` raises to a power, and that `Nat.cast` and friends change the carrier without
changing the dimension. That is twenty-odd names out of **Lean's own algebraic hierarchy**,
identical for physlib and for the Mathlib control, containing no physics.

Everything else is learned. Which constants are quantities, what their exponents are, how
many independent dimensions the corpus supports, which equations pin which — none of that
consults a name. The word "velocity" appears nowhere in the decision path; it appears in
this document, and in the post-hoc check that the answer is right.

---

## 2. E1 — the dimension type is structurally discoverable, and its exponents decode exactly

### The signature

A dimension type has a property no other type in a library has: **it is a commutative group
whose elements appear as arguments to type constructors.** That is what a grading is — you
can multiply and invert dimensions, and a dimension indexes a type of quantities.

Both halves are read off statements. A type `T` carries group structure when some
declaration concludes `Mul (T …)` or `CommGroup (T …)`. Its elements index types when some
constant whose own type concludes in a *data* sort is applied to an argument headed by a
`T`-valued constant.

The Prop/Type split is load-bearing. Dropping the sort's universe level made `Eq`, `LE.le`
and `LT.lt` count as type constructors, and then every carrier in the library looked like a
grading — Mathlib produced eight candidates led by `Nat` at 32 formers. With the split, the
criterion returns **one candidate per corpus**:

| corpus | candidate | inverses | formers | uses | group structure | indexed by |
|---|---|---|---|---|---|---|
| physlib (cap 200 kB) | **`Dimension`** | yes | 1 | 139 | `CommGroup, Mul, One` | `WithDim` |
| mathlib-algebra (cap 50 kB) | `Nat` | **no** | 5 | 1,816 | `CommMonoid, Div, Monoid, Mul` | `Fin`, `BitVec`, … |

Mathlib's answer is not wrong — `Nat` really does grade `Fin n` and `BitVec n`. It is
separated from a dimension by the thing a dimension needs and a length does not: **inverses.**
`Dimension` is a `CommGroup`, `Nat` stops at `Monoid`. On the ranking key as written
(`formers`, then `uses`) Mathlib's candidate would outrank physlib's; on the pre-registered
criterion — a *CommGroup* whose elements index types — only `Dimension` qualifies.

### The decoder

Given the discovered carrier, a `Dimension`-valued subterm is evaluated in the free abelian
group over the `Dimension`-valued constants that survive as leaves: `*` adds exponents, `⁻¹`
negates, `/` subtracts, `^n` scales. No generator's meaning is known to the decoder.

38 declarations carry a decodable annotation; they yield **13 distinct signatures**. Here are
the top 12 by frequency, with the names attached afterwards by a human and by nothing in the
pipeline:

```
73  M𝓭                          mass
66  L𝓭 · T𝓭⁻¹                    velocity / speed
44  L𝓭² · M𝓭 · T𝓭⁻²              energy
32  T𝓭                          time
26  L𝓭²                         area
24  L𝓭                          length
23  C𝓭 · T𝓭⁻¹                    electric current
20  L𝓭 · T𝓭⁻²                    acceleration
18  L𝓭 · M𝓭 · T𝓭⁻²               force
15  C𝓭² · L𝓭 · T𝓭⁻³ · Θ𝓭⁻¹       (an electro-thermal compound)
10  Θ𝓭                          temperature
 9  T𝓭⁻¹                        frequency
```

That is the textbook table, recovered from statement structure with no unit name read. It is
the strongest result here.

**And it covers 38 of 14,147 declarations — 0.27%.** Physlib's `WithDim` machinery is 96
statements out of 14,576; the other 99.7% of the library types its quantities as bare `ℝ`,
`Time`, `Space d` or a tensor space, and carries no dimensional annotation at all. So the
annotation route answers the question exactly and answers it for almost nothing, which is
the entire reason the next experiment exists.

One structural limitation worth recording: a `abbrev DimSpeed : Type := Dimensionful (WithDim
(L𝓭 * T𝓭⁻¹) ℝ≥0)` hides its dimension from this decoder, because the extractor encodes a
declaration's *type* and `oneMeterPerSecond : DimSpeed` has `DimSpeed` as its type, not the
unfolding. Constants declared against an abbreviation are invisible here and the 38 is a
lower bound for that reason.

---

## 3. E2 — a grading recovered from equations alone

### The construction

Every `Eq` in the corpus, and every `+` anywhere inside one (including inside hypotheses), is
a linear constraint on unknown exponent vectors:

* `a * b` → `D(a) + D(b)`, `a / b` → `D(a) − D(b)`, `a ^ n` → `n · D(a)`, `a⁻¹` → `−D(a)`;
* `a + b` emits the row `D(a) − D(b) = 0`, because a sum only typechecks at one dimension;
* `lhs = rhs` emits `D(lhs) − D(rhs) = 0`;
* a numeral is dimensionless, except `0` and `1`, which typecheck at every dimension and get
  a fresh free variable instead — reading them as dimensionless invents constraints the
  mathematics does not contain.

Leaves are **atoms**. A bound variable is an atom local to its declaration, keyed by
*absolute* binder index so that two occurrences of one binder are one atom. Anything else is
keyed by its head constant together with its **closed** arguments, with open arguments
written `_`.

The system is homogeneous, so it is solved as a Schur complement: each declaration's local
atoms are eliminated against its own rows first — valid blockwise, because a local atom
occurs in exactly one declaration — and what survives is a system over global constants
only. Reduced row echelon form over ℚ; the pivot rows *are* the result, each one reading
`atom = Σ qᵢ · atomᵢ`.

### The self-test, which fixes the answer before the corpus is seen

`--selftest` runs a synthetic corpus with three base dimensions, three defined quantities,
one redundant restatement and one statement of pure algebra. Its assertions are properties:

```
selftest: columns 7  rank 4  grading dim 3 (want 3)  redundant-implied True (want True)
          rows violating truth 0 (want 0)  ->  PASS
    energy() = mom() + speed()
    len() = speed() + time()
    mass() = mom() - speed()
    two() = 0
```

The grading dimension equals the number of base dimensions; `energy = mass · speed²` comes
out **implied** by the three definitions that precede it; and `∀x, x + x = 2x` correctly
infers that `two` is dimensionless rather than contributing noise. A solver that identified
two base dimensions would fail the first assertion; one that did not propagate through `^`
would fail the second.

### physlib, measured

`/tmp/fh-physlib.jsonl`, fine keying, literals dimensionless, at two caps:

| | `--cap 20000` | `--cap 200000` |
|---|---|---|
| declarations kept | 12,429 | 14,147 |
| declarations contributing rows | 5,615 | 6,840 |
| raw rows | 13,912 | 28,439 |
| rows after local elimination | 3,213 | 5,002 |
| arithmetic nodes decomposed | 10,743 | 27,974 |
| subterms left opaque | 14,952 | 23,022 |
| connected global atoms \|C\| | 1,704 | 2,050 |
| rank | 1,363 | 1,670 |
| grading space dim | 341 | 380 |
| forced dimensionless | 699 | 839 |
| forced equal to one other atom | 647 | 810 |
| **genuine multi-atom relations** | **17** | **21** |
| …with a coefficient outside ±1 | 3 (17.6%) | **4 (19.0%)** |
| forced-equal classes / atoms in them | 305 / 940 | 341 / 1,133 |

The relations are the answer to the question, and several of them are physics (at cap 200 kB,
lightly abbreviated):

```
ClassicalMechanics.VisViva.ConfigurationSpace.r = VisViva.G + VisViva.M − 2·VisViva.speedCircular
QuantumMechanics.HarmonicOscillator.m = −…ω + …ξ − …ξ − 2·… − …
Constants.ℏ = …HarmonicOscillator… − …HarmonicOscillator… − deriv(ℝ,…)
HPow.hPow(ℝ,ℕ,…) = −Nat.factorial(_) − Real.sqrt(Real.pi)
ACCSystemLinear.LinSols.val(…) = MSSMACC.Y₃AsCharge + 1/2·MSSMACCs.cubeTriLinToFun(_)
LengthUnit.furlongs = LengthUnit.yards + Subtype.mk(ℝ,…)
Lorentz.ContrMod.toFin1dℝ(3,…) = Lorentz.ContrMod.toFin1dℝ(…) − PauliMatrix.pauliMatrix(…)
```

The first is the vis-viva law read in exponent space: `v² = GM/r` gives
`dim r = dim G + dim M − 2·dim v`, and the solver produced it from the statement of a theorem
about circular orbits with no knowledge that `G` is a gravitational constant. The fourth is
the Gaussian-moment identity. The fifth carries a coefficient of ½ — an anomaly-cancellation
relation. None was looked for.

Forced-equal classes at cap 200 kB: **341 classes over 1,133 atoms**, largest 66. Reading
the largest three is instructive about what the method finds when it is not finding physics:
66 flavours of `SizeOf.sizeOf` (auto-generated), 59 propositions (`Eq`, `And`, …, correctly
all one class and uselessly so), and 29 `complexLorentzTensor` unit morphisms — that last one
being a real structural family.

### The two controls, which are where the result is actually decided

Same pipeline, same operator vocabulary, all three at `--cap 20000`. The **Mathlib control**
is a corpus of pure mathematics twenty times larger. The **shuffle control** is physlib's own
rows with every atom replaced by a uniformly random one from the same pool — same rows, same
shapes, wiring destroyed.

| | physlib | mathlib-algebra | physlib, atoms shuffled |
|---|---|---|---|
| declarations contributing rows | 5,615 | 55,965 | (same rows) |
| rows after local elimination | 3,213 | 55,421 | 3,213 |
| connected global atoms \|C\| | 1,704 | 9,619 | 1,661 |
| rank | 1,363 | 8,931 | 1,660 |
| grading space dim | **341** | 688 | **1** |
| forced dimensionless | 699 | 6,088 | — |
| forced equal to one other atom | 647 | 2,843 | — |
| **genuine multi-atom relations** | **17** | **0** | **0** |
| …with a coefficient outside ±1 | 3 of 17 (17.6%) | 0 of 0 | 0 of 0 |

**Both controls return zero multi-atom relations, and they fail in opposite ways.**

Mathlib recovers only "these two things carry the same grading" (2,843 pairs) and "this thing
is dimensionless" (6,088) — which is what a corpus of pure algebra should say, because moving
terms across an `=` produces coefficients of ±1 and nothing else, while a dimensional law
carries powers. Its largest forced-equal class is 1,375 atoms led by `Eq(_,_,_)` and
`And(_,_)`: every proposition in one class, correctly and uselessly.

The shuffled corpus fails the other way: rank 1,660 over 1,661 atoms, **grading dimension 1**.
Random rows saturate the system, so the only surviving grading is the trivial one — the
collapse that a corpus with no dimensional wiring produces.

Physlib resembles neither: 341 dimensions of grading survive *and* 17 relations of the form
`a = b + c − 2d` come out. That form does not arise from moving terms across an equals sign,
and it does not survive rewiring. Note that the discriminator is the relation count, not the
grading dimension — Mathlib's grading dimension is twice physlib's and means nothing, because
its rank is spent on identifications rather than on laws.

> An earlier run of the Mathlib control reported **251** multi-atom relations and made the
> comparison look inconclusive. That run predates the closedness fix below; atom keys were
> carrying raw de Bruijn indices, which manufactured spurious cross-declaration structure on
> the larger corpus. The 251 is withdrawn.

### The keying ablation, which is the collapse this design exists to prevent

An atom keyed on its head constant alone identifies `single .length` with `single .time` —
both are headed by `single` — and one such row forces `L𝓭 = T𝓭`, collapsing the whole
lattice silently. `--keying coarse` reproduces it on demand:

| keying | cap | atoms \|C\| | rank | grading dim |
|---|---|---|---|---|
| fine (default) | 20 kB | 1,704 | 1,363 | **341** |
| coarse (ablation) | 20 kB | 942 | 847 | **95** |
| fine (default) | 200 kB | 2,050 | 1,670 | **380** |
| coarse (ablation) | 200 kB | 1,035 | 944 | **91** |

Coarse keying loses half the atoms and **72-76% of the grading dimension**, at both caps. The
lost dimension is not noise being cleaned up; it is distinct quantities being merged.

### A defect found while building this, and what it cost

The closedness test was originally `has_loose_bvar(a, depth)`, which asks whether a subterm
escapes the *whole statement* — and for any subterm of a well-formed statement the answer is
always no. Under that reading a bound argument rendered as `#0` rather than `_`, so
`velocity q t` keyed differently depending on how many binders happened to precede it and no
two declarations ever shared an atom. The constraint system was nearly empty and the failure
presented as "physics has no recoverable structure". The fix is `needs(e) > 0` computed by a
single bottom-up annotation pass, which is also what made the pass linear rather than
quadratic on physlib's 200 kB statements.

---

## 4. E4 — the error detector fires, and what it can and cannot certify

A tool that says everything is fine is worse than no tool, so the detector is calibrated by
injection: pick pairs of atoms the solver kept *independent*, assert they are equal, and
require the rank to rise.

```
injected false identities   20
detected as new constraints 20
```

20/20. An injection that does not raise the rank is a claim the corpus already made, and is
excluded from the set by construction.

**What this does not license.** The system is homogeneous, so it is always consistent — `x =
0` solves it — and **"physlib contains no dimensional error" is not a statement this method
can make.** What it can say is narrower and still useful: the corpus's own equations admit a
380-dimensional space of gradings over 2,050 connected constants (cap 200 kB), so no equation
in the measured set forces the grading to collapse to a point, which a grossly inhomogeneous
equation would. A *specific* inhomogeneity would show up as two atoms with known-different
dimensions being forced equal, and that is checkable only where the E1 annotations reach —
0.27% of the library. The honest verdict is that the detector is calibrated and the corpus is
not certified.

---

## 5. E3 — the held-out prediction test, and the confound that nearly ate it

The design was: hold out a tenth of the global rows, fit on the rest, count how many held-out
rows the fit already implies. A dimensionally redundant corpus should predict its own
equations; a shuffled one should not. Measured (cap 20 kB):

| | fit rank / atoms | fit grading dim | covered | implied | multi-atom implied |
|---|---|---|---|---|---|
| physlib | 1,292 / 1,624 | **332** | 256 | **97.7%** | **21 / 22** |
| shuffled atoms (control) | 1,639 / 1,642 | **3** | 301 | **98.7%** | 34 / 34 |

**On the rate alone the experiment is refuted: 97.7% against 98.7%, the control winning.**
It is not refuted, and the reason is in the metric rather than in the corpus. A fitted system
whose rank equals its atom count has only the zero grading left, and then *every* row is
implied vacuously. Random rewiring is precisely what saturates a system — the shuffled fit
has **3** dimensions of freedom left out of 1,642 atoms — so its 98.7% is a collapse wearing
a high score, and its 34/34 doubly so.

The physlib fit keeps **332** dimensions, nowhere near saturation, and still implies 97.7% of
covered held-out rows and 21 of 22 held-out *multi-atom* rows. Read with the grading dimension
beside it, that is the redundancy claim the experiment wanted: nine tenths of physlib's
equations determine the dimensional content of the tenth that was hidden.

The confound is left in the script rather than edited out, with the explanation printed above
the table, because the lesson generalises: an implication rate is uninterpretable without the
fitted model's remaining freedom, and a control that agrees with the treatment is sometimes
agreeing for an unrelated reason. Had this been reported as "the corpus predicts its own
equations at 98%" with the control quietly dropped for agreeing, it would have read as a
success and been worth nothing.

---

## 6. E6 — declarations do cluster by the constants they mention, and it is mostly modules

The unit is the global atom the solver already built. Atoms occurring in one declaration
carry no information and atoms occurring in almost all of them carry none either, so the band
is `[2, n/20]` and reported: 719 of 1,704 atoms are informative.

```
                          pairs   same-subfield   label-shuffled
share >= 1 atoms         18,073          12.0%             0.5%
share >= 2 atoms          3,228          19.1%             0.7%
share >= 3 atoms            369          64.0%             1.6%
random pairs             18,073           0.5%                —
```

Sharing three informative atoms raises the same-subfield rate from a 0.5% random-pair base to
**64.0%** — a 119x enrichment — and the label shuffle puts the same 369 pairs at 1.6%, so it
is not an artifact of subfield sizes.

But read what that says. The clustering is *very largely* module structure: the strongest
signal is "these two declarations are in the same physlib subfield". The cross-subfield pairs
with the highest overlap are dominated by `WickContraction` combinatorics and
`CanonicalEnsemble` thermodynamics — the former being the same finding as §3c's, that the
strongest structural families in physlib are library architecture rather than physics.

So: yes, declarations cluster by the physical-quantity constants they mention; no, that
clustering is not meaningfully *different* from module structure at the level this measures.

---

## 7. E5 — dimensional agreement does not predict analogy, and the reason is coverage

The ground truth is physlib's units API replicated across `LengthUnit`, `TimeUnit`,
`MassUnit`, `ChargeUnit` and `TemperatureUnit` (findings §3c): the same lemma suffix under
two different unit types is a genuine analogue whose two sides have *different* dimensions by
construction. Proposed by name, then validated structurally by `phys_i3.shape_key` — the two
statements must be identical once every constant name is replaced by one token.

Not `Corpus.skeleton`: at `carriers` the five unit types are concrete constants rather than
bound carriers, so that erasure would reject the family it is being asked to confirm, and any
erasure level needs a closed slice. Not retention either, since retention is under test.
`Corpus.generalize` is safe on an unclosed slice — it anti-unifies the encodings and does not
erase — so E5 runs where E1 would be under-inclusive.

```
proposed by suffix 310   both sides theorems 190
confirmed by identical name-erased shape 190   rejected 0

retention           analogues n=190 mean 0.915   non-analogues n=190 mean 0.054   AUC 0.999
dimension agreement analogues n=0     non-analogues n=0                           AUC undefined
atom-set Jaccard    analogues n=30  mean 0.611   non-analogues n=82  mean 0.000   AUC 1.000
```

190 of 190 proposed pairs survive structural validation, which makes this an unusually clean
label set. Against it, **retention scores AUC 0.999** and **dimensional agreement cannot be
computed at all**: not one of the 190 pairs has a decodable dimension on either side.

That is not an artifact of the experiment. Checked independently over the whole slice: of the
**220** declarations under those five unit types — 108 of them theorems — **zero** mention
`Dimension` or `WithDim` anywhere in their statements. The library's clearest analogue family
carries no dimensional annotation whatsoever.

The registered prediction was that dimensional agreement would be *anti*-predictive. The
measured answer is stronger and less interesting: it is **undefined**. Coverage, not
discrimination, is what stops it. An AUC near 0.5 would have meant the signal exists and is
orthogonal; n = 0 means the signal is absent where the question is asked.

The atom-set Jaccard — the solver's own atoms rather than E1's annotations — separates
perfectly (AUC 1.000) but on 30 of 190 pairs, so it is a strong signal with weak coverage,
and on this family it is close to a restatement of "the two theorems mention the same
functions".

---

## 8. What this is worth, and the honest summary

**Recovering a dimension from an annotation works and is exact.** E1 discovers the grading
carrier from structure alone and decodes the SI-style exponent table without reading a unit
name. It reaches 0.27% of physlib.

**Recovering a dimension from equations works, is thin, and is real.** E2 produces 21
multi-atom dimensional laws from 6,840 declarations at cap 200 kB, of which a handful are
physics (vis-viva, the harmonic oscillator's mass–frequency relation, a Gaussian moment, an
anomaly-cancellation relation with a coefficient of ½). Both negative controls produce zero.
The bulk of the recovered structure is pairwise identification (810 forced-equal atoms, 341
classes) and dimensionlessness (839 atoms) — real information about the corpus, and not
dimensional analysis.

**The reason it is thin is worth stating precisely.** 23,022 subterms were left opaque
against 27,974 arithmetic nodes decomposed — 45% of what the walk looks at is a function
application the solver cannot see through (58% at the smaller cap). Physics statements are
dominated by `deriv`, `MeasureTheory.integral`, `DFunLike.coe`, tensor contraction and
`Subtype.val`, none of which are in the operator vocabulary, and each of which becomes one
opaque atom. `deriv(ℝ, …)` appears *inside* three of the recovered relations as an atom whose
dimension the solver had to leave free.

The missing rules are not more physics knowledge; they are *calculus*: a derivative divides
by its variable's dimension, an integral multiplies by its measure's. Adding `deriv` and
`MeasureTheory.integral` to the vocabulary is the single highest-value next step and is a
bounded amount of work.

**Dimensional signature and analogy are different questions, and E5 settles which.** E1's
signatures partition quantities by *what they are*; retention and the anti-unifier rank pairs
by *how they are said*. On 190 structurally-confirmed analogue pairs retention scores AUC
0.999 and the dimensional signature is undefined on every one of them, because none of the
220 unit-API declarations carries an annotation. Dimension belongs in a **filter** an agent
applies after retrieval — "of these 500 candidates, which concern a quantity of my
dimension" — and not in the ranking. On this library it cannot even do that yet, for want of
coverage.

**What was not run, stated so nobody has to infer it.**

* **The physlib import closure.** `lake exe atlas_extract Physlib QuantumInfo` imported
  818,835 constants and was killed during encoding (`EXIT=143`) after about two hours, having
  written nothing. So E1's discovery ran against a slice missing every Mathlib row, which can
  only make it *under*-inclusive — a closure could add candidate carriers to the ranking,
  never remove `Dimension` from it — and **no number in this document was computed at an
  erasure level.** E2, E3, E4 and E6 read statement trees only and are unaffected; E5 uses
  `generalize`, which does not erase, with a ground truth validated by `phys_i3.shape_key`
  rather than by `Corpus.skeleton`, for exactly this reason.
* **The `--literals free` ablation.** The knob exists and defaults to treating numerals other
  than `0` and `1` as dimensionless. Whether that choice moves the relation count is
  unmeasured. It is the obvious next control and it is cheap.
* **`Corpus.closure()` itself, on physlib.** Only the Python implementation ran there, because
  the closed slice never existed. On `mathlib-algebra` the two agree (99.25% / 99.52%).
* **E1 and E5 at `--cap 200000` together in one run.** Each has been run at that cap
  separately; the combined run was killed by the environment three times and the numbers are
  reported per-run with their cap named.

---

## 9. Spec: `Corpus.grading` — what to build if this is worth encoding

Not implemented here on purpose (concurrent work in `crates/fh-atlas`). This is the precise
shape.

### Query

```rust
pub struct GradingConfig {
    /// Atom identity. `Spine` keys a head constant together with its closed arguments;
    /// `Head` keys the constant alone and exists only so the collapse can be reproduced.
    pub keying: Keying,               // Spine (default) | Head
    /// What a numeral contributes. `0` and `1` are free under either setting — they are the
    /// units of the two operations and typecheck at every dimension, so scoring them 0
    /// invents constraints. This chooses whether *other* numerals are dimensionless
    /// (default) or free.
    pub literals: LiteralPolicy,
    /// Whether `deriv`/`integral` participate. Off until §8's rules land.
    pub calculus: bool,
}

impl Corpus {
    pub fn grading(&self, cfg: GradingConfig) -> Grading;
}

pub struct Grading {
    pub atoms: usize,            // global atoms seen
    pub connected: usize,        // atoms in at least one surviving row  (|C|)
    pub rank: usize,
    pub dim: usize,              // connected - rank: independent gradings the corpus admits
    pub opaque: usize,           // subterms the walk could not decompose — the coverage number
    pub decomposed: usize,
    pub relations: Vec<Relation>,     // the RREF pivot rows
    pub classes: Vec<Vec<SymId>>,     // forced-equal atoms, transitively closed
    pub dimensionless: Vec<SymId>,
}

pub struct Relation {
    pub subject: AtomKey,
    /// `subject = Σ coefficient · atom`, coefficients rational.
    pub terms: Vec<(AtomKey, Rational)>,
    /// Declarations whose equations this row was derived from. Required, not optional: a
    /// relation with no provenance cannot be audited, and §3's `VisViva` row is only
    /// believable because it names the theorem it came from.
    pub witnesses: Vec<DeclId>,
}
```

Plus the query an agent actually wants:

```rust
/// Every declaration whose statement mentions an atom in `class_of(name)` — the
/// dimensional-filter query. Recall-first: a declaration with no recovered class is
/// *included* with `certainty: Unknown` rather than dropped, because the consumer can
/// reject and cannot recover.
pub fn same_dimension(&self, name: &str, cfg: GradingConfig) -> Vec<(String, Certainty)>;
```

### Binding and surface

Per CLAUDE.md §6 this lands in one change across the engine, `bin/atlas.rs`, the Python
binding and its `.pyi`, `fh-mcp`'s tool list, and a gate. `Grading` maps to a Python class
with the same fields; `relations` is a list of `(subject, [(atom, Fraction)], [witness])`.

### The gate, and why each half of it is needed

`scripts/grading-gate.py`, exiting non-zero on any of:

1. **The synthetic property test** — the `--selftest` corpus of §3, asserting
   `dim == 3` (the number of base dimensions), that the redundant restatement is implied by
   the definitions, and that the intended exponent assignment satisfies every row. Pins a
   property, not an output.
2. **The differential** — `Grading` from Rust against `scripts/phys-dimensional.py`'s Python
   solver on the same slice, requiring equal `connected`, `rank` and `dim` and an identical
   set of relations up to row-space equality. Two implementations written from different
   sides; a shared bug cannot make both pass.
3. **The keying ablation, asserted to collapse** — `Keying::Head` must produce a strictly
   smaller `dim` than `Keying::Spine` on a physics slice. Measured here at 91 against 380
   (cap 200 kB) and 95 against 341 (cap 20 kB). If the ablation stops collapsing, the atom
   key has stopped distinguishing and the gate has gone quiet.
4. **The shuffle control, asserted to collapse** — atoms rewired at random must drive `dim`
   to ≤ 3 and multi-atom relations to 0. Measured at dim 1 and 0 relations. This is the half
   that separates "the corpus has dimensional wiring" from "the arithmetic is dense".
5. **The injection control** — 20 pairs the solver kept independent, asserted equal, all 20
   required to raise the rank. Makes a clean report mean something.
6. **The corpus separator** — on `mathlib-algebra` the multi-atom relation count must be 0
   (measured: 0 from 55,421 rows) and on a physics slice strictly positive with a measurable
   fraction carrying a coefficient outside ±1 (measured: 21, 19.0% powered). "We recovered
   dimensions" then cannot be satisfied by recovering bookkeeping.
7. **The closure precondition** — refuse to answer below 95%, for the reason §0 gives, and
   compute it twice: the existing `SkeletonIndex::closure` plus a second implementation over
   the parsed trees. The two agreed to 0.27 points on a closed corpus here and disagreed by
   80 on an unclosed one, which is what a differential is for.

### What must be true before this is worth building

The coverage number in §8. At 45% of subterms opaque, `dim` is measuring the corpus's
calculus vocabulary as much as its physics. The `deriv`/`integral` rules should land first,
and `opaque`/`decomposed` must be reported on every `Grading` so that a future reader can
tell which they are looking at. Twenty-one relations is a result; it is not yet a tool, and
the honest order is coverage, then the query.
