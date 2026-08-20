# Calculus rules for the dimensional solver, and how much physics they buy

*Companion to `research/physlib-dimensional.md`, whose §8 named the bottleneck: 45% of the
subterms the dimensional walk looks at are opaque — 58% at the cap this work runs at — and
"the missing rules are not more physics knowledge; they are calculus". This is that work,
measured.*

| | result |
|---|---|
| **Coverage** | opacity over the solver's own walk **58.2% → 49.9%** at `--cap 20000`, and **45.1% → 39.9%** at `--cap 200000` — the second is the 45% `physlib-dimensional.md` §8 quotes |
| **Relations** | **17 → 66** at `--cap 20000`, **21 → 154** at `--cap 200000`. Powered ones 3 → 15 and 4 → 24 |
| **Attribution** | at `--cap 20000`: calculus rules alone 17 → 44; the keying they force, alone, 17 → 22; together 66 — the two interact, and §3 says why |
| **Shuffle control** | **0** relations at both caps, grading dimension 0 and 1 — collapses at least as hard as before |
| **`mathlib-algebra` control** | **0** relations, with every rule on and 40,860 bound variables merged by type |
| **Calculus control — 44,142 rows of `Mathlib.Analysis`/`MeasureTheory`/`Probability`** | **0.28** relations per 1,000 declarations against physlib's **10.40** on the same portable rules, and **0%** powered against 14.8% |
| **New physics** | Lagrangian/Hamiltonian/kinetic/potential energy on one signature, `B = ∇×A`, the moment of inertia, the SI dimension decomposition, the QM oscillator length with ½ coefficients |
| **Wild** | conservation laws are structurally distinguished and dimensionally **invisible**: 16 declarations, **3 global rows**; equations of motion, 142 declarations, **105 rows** |
| **Withdrawn** | the pre-registered collapse control for the new keying (§3). It does not collapse; the justification for the scalar guard is withdrawn and the guard kept on a weaker one |

Everything below is measured by `scripts/phys-calculus.py`. Reproduce:

```sh
uv run --no-sync scripts/phys-calculus.py --selftest        # the synthetic gate, 1 s
uv run --no-sync scripts/phys-calculus.py --arity-check     # every rule against its own type
uv run --no-sync scripts/phys-calculus.py --census --slice /tmp/fh-physlib.jsonl --cap 20000
uv run --no-sync scripts/phys-calculus.py --slice /tmp/fh-physlib.jsonl --cap 20000 \
    --wild --ablate --witness 8 --control /tmp/mathlib-algebra.jsonl \
    --calc-control /tmp/akc-mathlib-analysis.jsonl
```

**Closure.** Every number here is computed from statement trees only: no erasure, no
citation followed, no constant signature consulted during solving. That is
`physlib-dimensional.md` §0's E2/E3/E4/E6 case, which does not need a closed slice. The one
place a signature *is* read is `--arity-check`, which counts the `Pi` binders of each rule
head's own type row; that is a lookup, so it runs against `/tmp/pc-physclosed.jsonl`
(95,268 rows, 99.46% closed) and reports every head it could not find.

---

## 1. The rules, and why each one is a typing rule rather than a physics fact

`deriv f x` for `f : 𝕜 → F` and `x : 𝕜` is a limit of `(f y − f x)/(y − x)`. Whatever `F`
and `𝕜` mean, that quotient scales as `F/𝕜`, so `D(deriv f x) = D(f) − D(x)`. `∫ x, f x ∂μ`
is a limit of `Σ f(xᵢ)·μ(Aᵢ)`, so `D = D(f) + D(μ)`. Neither statement mentions a physical
quantity; both are consequences of the constant's *type*. That is the standard every rule
below is held to, and it is why attaching them by head-constant identity is a typed lookup
rather than a semantic guess.

**Which heads got rules was measured, not guessed.** `--census` instruments the exactly two
places the base solver gives up on an application and counts what it finds. On physlib at
`--cap 20000`, before any rule:

```
occurrences  decls  head                    occurrences  decls  head
      1,597  1,052  DFunLike.coe                    130     59  Space.deriv
      1,093    415  «bvar»                          123     81  Time.deriv
      1,015    183  SizeOf.sizeOf                    61     41  MeasureTheory.integral
        526    298  Finset.sum                       50     30  deriv
        408    125  Finset.card                      52     52  ite
        257    136  Inner.inner                      48     27  NNReal.toReal
        174     90  Norm.norm                        48     42  Subtype.mk
        145     64  Complex.ofReal                   89     52  WithLp.ofLp
```

Two things fall out of that table that a guess would have missed.

**Physlib has its own derivative operators, and they outrank Mathlib's.** `Space.deriv` (130
occurrences) and `Time.deriv` (123) together are five times `deriv` (50). Their signatures,
read off their own type rows, are a derivative's:

```
Time.deriv  {M} [AddCommGroup M] [Module ℝ M] [TopologicalSpace M]
            (f : Time → M) (x : Time) : M
Space.deriv {d} {M} [AddCommGroup M] [Module ℝ M] [TopologicalSpace M]
            (μ : Fin d) (f : Space d → M) (x : Space d) : M
```

They are in a **separate rule family** (`physlib`), and every cross-corpus comparison is
reported with it off as well as on. The rule is not unsound — it is the same typing rule as
`deriv`'s — but a vocabulary tuned on one corpus cannot be the vocabulary a comparison
against another corpus is run with, and the honest way to say that is to run both.

**The base solver has four casts its own dispatch can never reach.** `phys_dimlib.CAST`
lists `Complex.ofReal`, `NNReal.toReal`, `ENNReal.toReal` and `Real.toNNReal`, and the
branch that consumes `CAST` sits inside `if name in OPERATORS and len(args) >= 2`. Every one
of those casts is **unary** — measured, arity 1 — so all four fell through to the opaque
fallback. On physlib that cost 145 occurrences of `Complex.ofReal` over 64 declarations and
48 of `NNReal.toReal` over 27. Repaired here as a rule rather than as an edit to the file
the prior art measured.

### The table

Nine families, 42 heads. Every arity below was read off the head's own type row in the
closed slice and **`--arity-check` reports `agree 42  mismatch 0  not in slice 0`.** It did
not start there: the first check found 13 mismatches and 3 heads that do not exist, and two
of those would have produced silent garbage rather than silence — `HasSum`'s and `tsum`'s
last argument is an `optParam SummationFilter`, not the summand, so a rule pinned one
position short reads the filter as the function.

| family | heads | rule |
|---|---|---|
| `deriv` | `deriv`, `derivWithin`, `fderiv`, `fderivWithin`, `iteratedDeriv`, `iteratedFDeriv`, `gradient`, `HasDerivAt`, `HasDerivWithinAt`, `HasFDerivAt` | `D(f) − k·D(x)` |
| `integral` | `MeasureTheory.integral`, `lintegral`, `intervalIntegral` | `D(f) + D(μ)`; for an interval, `D(f) + D(a)` and `D(a) = D(b)` |
| `physlib` | `Time.deriv`, `Space.deriv` | `D(f) − D(x)` |
| `sum` | `Finset.sum`, `tsum`, `Matrix.trace`, `HasSum` | `D(f)` |
| `norm` | `Norm.norm`, `NNNorm.nnnorm`, `ENorm.enorm`, `abs`, `Dist.dist`, `EDist.edist` | `D(x)`, and `D(x) = D(y)` for a distance |
| `power` | `Real.sqrt`, `Real.rpow`, `HPow.hPow` at a rational exponent | `q·D(x)` |
| `bilinear` | `Inner.inner`, `Matrix.mulVec`, `DFunLike.coe` | `D(a) + D(b)` |
| `cast` | `Complex.ofReal`, `NNReal.toReal`, `ENNReal.toReal`, `Real.toNNReal`, `ENNReal.ofReal`, `WithLp.ofLp`, `WithLp.toLp`, `Subtype.mk` | `D(x)` |
| `branch` | `ite`, `Max.max`, `Min.min` | `D(a)`, and `D(a) = D(b)` |

Three design decisions inside that table are worth stating, because each is a place where a
rule could have invented a constraint and does not.

**A rule that cannot fire soundly returns nothing.** A symbolic exponent, an under-applied
spine, an unrecognised function bundle — each leaves the subterm opaque exactly as before.
Losing an atom costs recall; merging two costs the lattice.

**`DFunLike.coe` is split by the bundle, which is an argument of the spine.** It is the
corpus's largest opaque head, and what is sound to say about `f x` depends on what `f` is:
a `LinearMap` scales, so `D(f x) = D(f) + D(x)`; a `Module.Basis` or an `Equiv` or a
`SchwartzMap` is an indexed family, so `D(f x) = D(f)`; a `MonoidHom` is multiplicative and
has no dimensional reading at all, so it stays opaque. The split is read off the term, not
assumed — `bundle = const_name(spine(args[-6])[0])`.

**A lambda is descended into, never substituted into.** `deriv (fun s => pos s) t` needs the
body's arithmetic, so `fun_dim` walks into it at `depth + 1` and emits a row identifying the
lambda's binder with the argument. That row is what substitution would have done, and doing
it as a row means **no tree node is ever synthesized** — which matters, because
`phys_dimlib._open` falls back to `has_loose_bvar` for a node `phys_i3.annotate` has never
seen, and that fallback is precisely the defect §3 of the prior art documents. The selftest
asserts it directly: no global atom key may begin with `?`.

---

## 2. The gate that fixes the answer before the corpus is seen

`--selftest` is a synthetic mechanics corpus written as I3 trees: nine independent statements
over twelve quantities plus three deliberately redundant ones. `Time` is a non-scalar
carrier; every value lives in `Real`, which is a scalar and is therefore never keyed by type
— the same asymmetry the physics corpus has.

```
selftest[bvar=type-nonscalar]: columns 12  rank 9  grading dim 3 (want 3)
    rows violating truth 0 (want 0)   redundant implied {ftc: True, acc_alt: True, hyp: True}
    local atoms leaked 0 (want 0)   unkeyed [] (want [])   ->  PASS
    acc(_)    = vel(_) - ⟨Time()⟩          pos(_)  = vel(_) + ⟨Time()⟩
    energy(_) = mom(_) + vel(_)            spd(_)  = vel(_)
    force(_)  = mom(_) - ⟨Time()⟩          spd2(_) = 2*vel(_)
    mass()    = mom(_) - vel(_)            volume() = ⟨Time()⟩
```

The assertions are properties. The grading space must have dimension exactly **3**, one per
base dimension: a `deriv` rule with the wrong sign ties two together and gives 2; one that
lost the point's dimension leaves `Time` unconnected and gives 4. The intended exponent
assignment must satisfy every row and no row may mention an atom outside the intended
vocabulary. The three redundant statements — the FTC, the second derivative, and a
`HasDerivAt` *hypothesis* — must be **implied** by the nine that precede them, which is what
says the rules compose rather than merely fire.

`volume() = ⟨Time()⟩` is the line worth reading twice. Nothing told the solver that the
measure in `∫ s, force s ∂volume` measures time; it inferred it from the impulse statement
and the definition of force.

---

## 3. The keying the calculus rules force, and its own collapse control

A derivative rule spends the point it differentiates at. In real statements that point is a
**bound variable**, and the base solver keys a bound variable per declaration, so `−D(x)` is
eliminated as a local and the row it was in disappears entirely. The selftest shows it
directly — with `--bvar local` the same corpus gives grading dimension 4, none of the three
redundant statements is implied, `acc` appears in no relation at all, and `Time` is not even
a column:

```
selftest[bvar=local]: columns 10  rank 6  grading dim 4  rows violating truth 0
    redundant implied {ftc: False, acc_alt: False, hyp: False}
    energy(_) = mom(_) + pos(_) - volume()      mass()  = mom(_) - vel(_)
    force(_)  = mom(_) - volume()               spd2(_) = 2*vel(_)
```

Six relations instead of nine, and the three that vanished are exactly the three that a
derivative produced. What survives does so through `volume()` — a *global* constant, because
the integral rule's measure is not a bound variable — which is the same mechanism working in
the one place the base keying leaves it room.

The fix is structural: **a bound variable is keyed by its binder's domain**, so `∀ t : Time`
in one theorem and `∀ t : Time` in another are one atom. The key is written with `_` for an
open argument, which is the convention `_spine_atom` already uses — `∀ x : Space d` under a
theorem that quantified over `d` keys as `Space(_)`, and every position variable in the
corpus is one atom. Requiring a closed domain instead would key almost nothing, because
physlib quantifies over the dimension.

That is `--keying coarse`'s trap one level up, and it is dangerous in one place: the ambient
scalars. `∀ x : ℝ` is a length in one theorem and a time in the next, and identifying them
forces `L = T`. So `type-nonscalar` leaves Lean's own number types local — `Real`, `Complex`,
`NNReal`, `ENNReal`, `Nat`, `Int`, `Fin`, … , the same ambient vocabulary as `HMul.hMul` and
containing no physics — and `--bvar type` drops the guard on demand. A sort domain
(`{α : Type}`) is always local: a type variable has no dimension, and merging every
declaration's type arguments wires the corpus together through nothing.

### The pre-registered collapse control did not collapse, and that is reported as a failure

C6 predicted that `--bvar type` would drive the grading dimension down the way
`--keying coarse` does (341 → 95), demonstrating that the scalar guard was load-bearing.
**It does not.** Measured, same rules, same cap:

| cap | | \|C\| | rank | grading dim | relations | typed bvars |
|---|---|---|---|---|---|---|
| 20,000 | `type-nonscalar` | 1,932 | 1,551 | **381** | 66 | 4,448 |
| 20,000 | `type` (guard dropped) | 2,010 | 1,634 | **376** | 60 | 9,905 |
| 200,000 | `type-nonscalar` | 2,392 | 1,930 | **462** | 154 | — |
| 200,000 | `type` (guard dropped) | — | — | **455** | 139 | 22,432 |

Dropping the guard doubles or quadruples the number of type-keyed bound variables and moves
the grading dimension by five points at one cap and seven at the other, where the
spine-keying ablation it was modelled on moves it by 246. So the registered justification for
the guard is **withdrawn**: on this corpus, identifying every real-valued bound variable does
not collapse the lattice.

The guard is kept anyway, for the weaker reason the same table gives at both caps — 66
against 60 and 154 against 139 — and recall is the thing to take.

Why the predicted collapse does not happen is worth one sentence, because it bounds the
finding: physlib states most of its scalar-valued theorems about *named* quantities applied
to bound points (`velocity q t`), not about bare bound reals, so the ℝ-typed binders that get
merged are mostly integration and quantification variables that were never going to carry a
distinguishing dimension. On a corpus that reasons about bare reals more, the guard may well
be doing what it was written to do; here it is insurance whose premium is six relations.

### The 2×2, so that neither change is credited with the other's gain

physlib, `--cap 20000`, fine keying, literals dimensionless:

| rules | bvar | opaque % of walk | \|C\| | rank | grading dim | **relations** | powered |
|---|---|---|---|---|---|---|---|
| none | local | 58.2% | 1,704 | 1,363 | 341 | **17** | 3 |
| none | type-nonscalar | 57.2% | 1,914 | 1,537 | 377 | **22** | 4 |
| calculus | local | 50.8% | 1,638 | 1,306 | 332 | **44** | 9 |
| calculus | type-nonscalar | 49.9% | 1,932 | 1,551 | 381 | **66** | 15 |

and the same 2×2 at `--cap 200000`, the cap the prior art's headline was taken at (14,147
rows kept rather than 12,429):

| rules | bvar | opaque % of walk | \|C\| | rank | grading dim | **relations** | powered |
|---|---|---|---|---|---|---|---|
| none | local | **45.1%** | 2,050 | 1,670 | 380 | **21** | 4 |
| none | type-nonscalar | 44.3% | 2,285 | 1,875 | 410 | **28** | 4 |
| calculus | local | 40.6% | 2,030 | 1,633 | 397 | **127** | 20 |
| calculus | type-nonscalar | **39.9%** | 2,392 | 1,930 | 462 | **154** | 24 |

**45.1% is `physlib-dimensional.md` §8's "45% of subterms are opaque", to the tenth**, and
21 is its headline relation count with 4 powered — both cells reproduce. At this cap the
rules are worth considerably more than at the smaller one: **21 → 154 relations, 4 → 24
powered, and the opacity §8 named drops to 39.9%.** The larger statements are the tensor and
distributional-electromagnetism ones, which is where the calculus lives.

The top-left cell of the first table is `phys-dimensional.py`'s E2 at `--cap 20000`,
reproduced to the row:
5,615 declarations contributing rows, 13,912 raw rows, 3,213 after local elimination, 10,743
decomposed, 14,952 opaque, |C| 1,704, rank 1,363, dimension 341, 699 forced dimensionless,
647 forced equal, **17 multi-atom relations of which 3 (17.6%) powered**. That is C0, and it
is what makes every other cell a measurement rather than a comparison between two harnesses.

**The two changes interact, and the interaction is the point.** At `--cap 20000`: rules
alone +27, keying alone +5, both +49. At `--cap 200000`: +106, +7, **+133**. Both are more
than the sum of the parts, because a derivative rule that cannot keep its point produces a
row that dies in local elimination. The keying is not an independent
improvement that happens to be reported here; it is the half of the derivative rule that
makes the other half survive.

Note also that `raw rows` *falls* when the keying changes (13,912 → 12,878 with no rules).
That is correct: two bound variables of the same type now cancel, and a row that says
`⟨Time()⟩ − ⟨Time()⟩ = 0` carries no information and is not emitted.

---

## 4. Coverage, measured two ways

**Dynamically**, over the subterms the solver's own walk looks at — the number
`physlib-dimensional.md` §8 quotes:

```
rules none      opaque 14,952   decomposed 10,743   58.2%
calculus        opaque 14,504   decomposed 14,562   49.9%
```

The denominator moves, because a rule lets the walk descend into a lambda body it previously
collapsed to one atom. Both halves are reported for that reason: opacity fell by 448
subterms *and* the walk decomposed 3,819 more.

**Statically**, over every maximal application spine in the kept statements — a number that
does not move when the rule set changes what the walk reaches:

```
spines 769,805   bound-headed 18,042
baseline:  arithmetic 71,743   opaque 680,020   88.3%
+calculus: arithmetic 71,743   calculus 5,680   opaque 674,340   87.6%
```

Read that second block honestly: **it is a weak metric**, because 87% of a statement's
spines are type arguments, instance arguments and `Prop` structure that the dimensional walk
never visits and never should. It is reported because it cannot be gamed by the rule set,
and the useful line in it is the absolute one — 5,680 spines in the corpus are
calculus-headed, against 71,743 arithmetic ones.

**The residual opacity is no longer calculus**, and the census says so directly. Re-run with
the final rule set, the table has completely changed shape:

```
before                                    after
 1,597  1,052  DFunLike.coe                1,478    583  «bvar»
 1,093    415  «bvar»                      1,015    183  SizeOf.sizeOf
 1,015    183  SizeOf.sizeOf                 683    461  DFunLike.coe
   526    298  Finset.sum                    408    125  Finset.card
   408    125  Finset.card                   215    103  ACCSystemLinear.LinSols.val
   257    136  Inner.inner                   178     89  Space.val
   174     90  Norm.norm                     129     68  HermitianMat.mat
   145     64  Complex.ofReal                110     35  PauliMatrix.pauliMatrix
   130     59  Space.deriv                   109     58  TensorProduct.tmul
   123     81  Time.deriv                    103     59  Time.val
```

`Finset.sum`, `Inner.inner`, `Norm.norm`, `Complex.ofReal`, `Time.deriv` and
`MeasureTheory.integral` are gone from the table entirely, and `DFunLike.coe` is down 57%.
What is left divides into three:

* **irreducible**: `SizeOf.sizeOf` (auto-generated), `Finset.card`, `«bvar»` — a spine headed
  by a bound function, which has no head to attach a rule to;
* **deliberately declined**: `DFunLike.coe` over `MonoidHom` and `Equiv`-likes, where there is
  nothing sound to say;
* **the next increment, and the census names it**: physlib's own single-field projections —
  `ACCSystemLinear.LinSols.val` (215), `Space.val` (178), `HermitianMat.mat` (129),
  `Time.val` (103), `SpeedOfLight.val` (100) — plus **`SpaceTime.deriv` (47 occurrences over
  21 declarations)**, a *third* physlib derivative operator that this rule set misses, and 46
  residual `Space.deriv` occurrences that are partial applications below the pinned arity.

That last bullet is the method working. The rules in §1 were chosen off the first census;
`SpaceTime.deriv` is what the second one says to do next, and it was not visible before the
first round of rules cleared the traffic above it.

---

## 5. What came out — the relations, with their physics names

Names are attached afterwards, by a human, and by nothing in the pipeline. 66 relations at
`--cap 20000`; these are the ones that read as physics.

```
ClassicalMechanics.VisViva.ConfigurationSpace.r = VisViva.G + VisViva.M − 2·VisViva.speedCircular
```
**The vis-viva relation**, `v² = GM/r`, recovered by the prior art and still here.

```
Matrix.vecMulVec(_,_,ℝ,…) = RigidBody.inertiaTensorAbout(…) − RigidBody.mass(…)
```
**The moment of inertia.** `I = Σ m (r⊗r)`, so the dimension of the outer product `r⊗r` is
`dim I − dim m` — length squared. New; it needs `Matrix.vecMulVec` to be reachable, which it
is only once the surrounding `Finset.sum` and casts decompose.

```
ClassicalMechanics.HarmonicOscillator.lagrangian(…)     = HarmonicOscillator.toCanonicalMomentum(…) + 2·⟨EuclideanSpace(ℝ, Fin 1, …)⟩
ClassicalMechanics.HarmonicOscillator.hamiltonian(…)    = HarmonicOscillator.toCanonicalMomentum(…) + 2·⟨EuclideanSpace(…)⟩
ClassicalMechanics.HarmonicOscillator.kineticEnergy(…)  = HarmonicOscillator.toCanonicalMomentum(…) + 2·⟨EuclideanSpace(…)⟩
ClassicalMechanics.HarmonicOscillator.potentialEnergy(…)= HarmonicOscillator.toCanonicalMomentum(…) + 2·⟨EuclideanSpace(…)⟩
ClassicalMechanics.HarmonicOscillator.force(…)          = HarmonicOscillator.toCanonicalMomentum(…) +   ⟨EuclideanSpace(…)⟩
ClassicalMechanics.DampedHarmonicOscillator.lagrangian(…) = HarmonicOscillator.toCanonicalMomentum(…) + 2·⟨EuclideanSpace(…)⟩
ClassicalMechanics.DampedHarmonicOscillator.force(…)      = HarmonicOscillator.toCanonicalMomentum(…) +   ⟨EuclideanSpace(…)⟩
```

**Lagrangian and Hamiltonian dimensional consistency, recovered as a single signature.**
Nine of the 66 relations are these. Seven of them — the Lagrangian at two arities, the
Hamiltonian, the kinetic energy, the potential energy, and the damped oscillator's Lagrangian
at two arities — land on *the same* exponent vector, `canonical momentum + 2·(configuration
space)`; the two forces land one power of length lower. That is exactly the statement that
`L`, `H`, `T` and `V` are all energies and that a force is an energy per unit length, and it
comes out as an equality of exponent vectors rather than as a claim anybody wrote down. The
coefficient **2** is a square, which rearranging an equation cannot produce.

```
CondensedMatter.TightBindingChain.E0(_) = TightBindingChain.hamiltonian(…) + 2·TightBindingChain.localizedState(…)
```
**The tight-binding chain's on-site energy** against its Hamiltonian and the square of a
localized state — the normalization `⟨ψ|H|ψ⟩`, in exponent space.

```
Electromagnetism.ElectromagneticPotential.magneticFieldMatrix(…) = Space.curl(_,_) + ⟨Space(3, …)⟩
```
**`B = ∇ × A`.** The magnetic field's dimension is the curl's plus a length — read off
statements about the electromagnetic potential, with `Space.deriv` supplying the curl's
derivative and the type-keyed `Space 3` supplying the length.

```
DFunLike.coe(MonoidHom (Dimension LTMCTDimensionBase) …) = HPow.hPow(ℝ≥0,ℝ,…) + HPow.hPow(…) + HPow.hPow(…) + HPow.hPow(…) … (+1)
```
**The SI dimension decomposition itself**, twice: a homomorphism out of physlib's `Dimension`
group equals a sum of **five** power terms — L, M, T, C, Θ. The solver has rediscovered, in
its own exponent space, the structure that `physlib-dimensional.md` §2 decoded from
annotations by a different route entirely.

```
QuantumMechanics.HarmonicOscillator.ξ(…) = ω(…) − ½·ω(…) + ½·(…) − (…) … (+2)
QuantumMechanics.OneDimension.HarmonicOscillator.m(_) = (…) − 4·(…) − 2·(…) − deriv(ℝ,…)
Constants.ℏ() = HarmonicOscillator(…) − 2·(…) − (…) − deriv(ℝ,…)
```
**The QM oscillator length** `ξ = √(ℏ/mω)` — the ½ coefficients are the square root — and
the mass–frequency relations the prior art found, now with the ℏ row still standing.

```
HPow.hPow(ℝ,ℕ,…) = MeasureTheory.MeasureSpace.volume(ℝ,…) − Nat.factorial(_) − ½·Real.pi()
```
**The Gaussian moment identity.** The prior art recovered this one without the measure in
it; with the integral rule, `volume(ℝ)` now appears explicitly and carries the `dx`.

```
FourierTransform.fourier(SchwartzMap ℝ ℂ …) = QuantumMechanics.OneDimension.HilbertSpace.plane… + ⟨SchwartzMap(ℝ,ℂ,…)⟩
```
**A Fourier-transform relation**: the transform's dimension is the plane wave's plus the
Schwartz function's, which is the `∫ f(x) e^{ikx} dx` bookkeeping read in exponent space.

```
GalileanGroup.actSpace(…) = TimeAndSpace.space(_) + ⟨TimeAndSpace(_)⟩
Prod.snd(Time,_,_)        = TimeAndSpace.space(_) + ⟨TimeAndSpace(_)⟩
```
**The Galilean action on space**, and the spacetime split as its second projection.

```
MSSMACC.B₃AsCharge() = −MSSMACC.α₂(_) + MSSMACC.α₃(_) + ⟨ACCSystemCharges.Charges(…)⟩
SMRHN.PlusU1.BL.addQuad(…) = −QuadSol.α₂(…) + 2·QuadSolToSol.α₁(…) + ⟨ACCSystemLinear.LinSols(_)⟩
DFunLike.coe(TriLinearSymm (ACCSystemCharges.Charges MSSM…)) = MSSMACCs.cubeTriLinToFun(_) − 2·⟨ACCSystemCharges.Charges(MSSMCharges)⟩
```
**Anomaly cancellation.** The prior art found one of these with a ½; there are now several,
with coefficients 2, and the third says a *trilinear* form on charges is quadratically
related to the charge space — which is what a cubic anomaly condition is.

```
Fermion.LeftHandedWeyl.basis()          = −Fermion.LeftHandedWeyl.val(_,_) + ⟨Fermion.LeftHandedWeyl()⟩
Lorentz.CoMod.stdBasis(_)               = −Lorentz.CoMod.toFin1dℝ(_,_,_) + ⟨Lorentz.CoMod(_)⟩
Lorentz.ContrℂModule.toFin13ℂEquiv()    = Lorentz.ContrℂModule.toFin13ℂFun() − ⟨Lorentz.ContrℂModule()⟩
```
And a large family that is **not** physics: about twenty of the 66 are basis/coordinate rows
saying "a basis vector times a component is a vector", over the Weyl-fermion and Lorentz
modules. They are real information about the corpus and they are bookkeeping — the same
finding as `physlib-dimensional.md` §3c and §6, that physlib's strongest structural families
are library architecture. The powered fraction (15 of 66, **22.7%**, against 3 of 17 = 17.6%
before) is the number that separates the two, and it went up.

---

## 6. The ablation, and the fact that relation count is not monotone

Each family removed in turn, from the 66-relation configuration at `--cap 20000`:

| family removed | relations | Δ | opaque % | grading dim |
|---|---|---|---|---|
| `bilinear` | 46 | **−20** | 52.3% | 368 |
| `physlib` | 54 | **−12** | 50.5% | 373 |
| `power` | 58 | −8 | 50.0% | 382 |
| `deriv` | 62 | −4 | 50.1% | 385 |
| `sum` | 64 | −2 | 51.9% | 368 |
| `norm` | 65 | −1 | 50.6% | 382 |
| *(none removed)* | **66** | — | 49.9% | 381 |
| `cast` | 67 | **+1** | 51.1% | 391 |
| `integral` | 68 | **+2** | 50.0% | 388 |
| `branch` | 69 | **+3** | 50.1% | 381 |

Three families make the count go **up** when removed, and that is worth stating rather than
hiding, because it means the headline number is not a monotone score. A rule adds rows; rows
raise the rank; and a higher rank can turn a surviving three-atom pivot into two two-atom
ones. `integral` is the clearest case: removing it gains two relations and loses the one that
has `MeasureTheory.MeasureSpace.volume(ℝ)` in it, which is the only place in the whole run
where the `dx` of an integral appears as a dimensional term. **Counting relations is a
coarse instrument, and the ablation is what shows it is coarse.**

The two families doing the most work are the two the census pointed at and a designer would
not have: `bilinear` (which is `DFunLike.coe` split by bundle, plus `Inner.inner` and
`Matrix.mulVec`) at −20, and physlib's own `Time.deriv`/`Space.deriv` at −12 — three times
what Mathlib's `deriv` family contributes on this corpus.

---

## 7. The controls

### The shuffle — physlib's own rows with the atoms rewired at random

```
--cap  20000, rules none, bvar local    |C| 1,704  rank 1,703  grading dim 1  relations 0
--cap  20000, calculus, type-nonscalar  |C| 1,886  rank 1,886  grading dim 0  relations 0
--cap 200000, calculus, type-nonscalar  |C| 2,376  rank 2,375  grading dim 1  relations 0
```

Zero relations at both caps, and at the smaller one the grading **collapses harder than
before** — dimension 0 rather than 1.
Random rewiring saturates the system, which is the failure mode a corpus with no dimensional
wiring produces; adding rules adds rows, so it saturates sooner. Nothing here is
manufactured out of arithmetic density.

### C3 — `mathlib-algebra`, 131,002 declarations of pure algebra

|  | rules none, bvar local | calculus, type-nonscalar |
|---|---|---|
| declarations contributing rows | 55,965 | 50,324 |
| rows after local elimination | 55,421 | 58,661 |
| opaque | 72.6% | 70.1% |
| connected atoms \|C\| | 9,619 | 9,996 |
| rank | 8,931 | 9,276 |
| grading dim | 688 | 720 |
| forced dimensionless | 6,088 | 6,344 |
| forced equal | 2,843 | 2,932 |
| bound variables keyed by type | 0 | **40,860** |
| **multi-atom relations** | **0** | **0** |

The left column is the prior art's Mathlib control, reproduced to the row. The right column
is the same corpus with every rule on *and* 40,860 bound variables merged by type — the
change that on physlib is worth +49 relations — and it produces **zero**. The machinery that
recovers 66 dimensional laws from physics recovers none at all from algebra, and it is not
because it declined to run.

### C4 — the control the calculus rules themselves require

`mathlib-algebra` cannot test a calculus rule, because it barely contains one. The control
that can is **pure mathematics that is nothing but calculus**: every `Mathlib.Analysis`,
`Mathlib.MeasureTheory` and `Mathlib.Probability` row from the `Mathlib`-only extraction —
48,268 declarations, 44,142 under the cap. That corpus states the chain rule, the product
rule, the FTC and Taylor's theorem. If these rules manufacture dimensional laws out of
calculus identities, it is where it shows.

Both sides run the **portable** vocabulary — physlib's `Time.deriv`/`Space.deriv` family off,
because a comparison run with one corpus's private constants is not a comparison.

| | analysis, rules none | analysis, calculus | physlib, calculus (portable) |
|---|---|---|---|
| declarations contributing rows | 17,449 | 17,669 | 5,191 |
| rows after local elimination | 8,461 | 8,322 | 3,662 |
| opaque | 64.6% | **51.3%** | 50.5% |
| connected atoms \|C\| | 2,572 | 2,676 | 1,931 |
| grading dim | 350 | 380 | 373 |
| multi-atom relations | 2 | **5** | **54** |
| **per 1,000 declarations** | 0.11 | **0.28** | **10.40** |
| **powered (coefficient outside ±1)** | 0 (0.0%) | **0 (0.0%)** | 8 (14.8%) |

**A 37-fold separation on the pre-registered discriminator, and a clean split on the
second.** The rules fire hard on the analysis corpus — opacity drops 13.3 points there,
more than the 8.3 they drop on physics — so this is not a control that passed by staying
switched off. It produces five relations, and here they all are:

```
HPow.hPow(ℝ→ℝ, ℕ, …)         = −deriv(ℝ, …)              + iteratedDeriv(ℝ, …)
HPow.hPow(ℂ→ℂ, ℕ, …)         = −deriv(ℂ, …)              + iteratedDeriv(ℂ, …)
PolynomialModule.comp(ℝ, …)   = −PolynomialModule.single(ℝ, …) + taylorWithin(…)
FourierTransform.fourier(SchwartzMap ℝ ℂ …) = −fourier(1, …) + ⟨SchwartzMap(ℝ,ℂ,…)⟩
LinearEquiv.symm(ℤ, ℤ, …)     = PeriodPair.ω₂(_) + Prod.snd(ℤ,ℤ,_) − ⟨Prod(ℤ,ℤ)⟩
```

The first two are `iteratedDeriv n f = deriv^[n] f` — the *definition* of iterated
differentiation, read in exponent space. The third is Taylor's theorem's bookkeeping. They
are exactly what a corpus of pure calculus should yield, they are real, and **not one of
them carries a coefficient outside ±1**, because an identity between two ways of writing the
same operator cannot: moving terms across an `=` produces ±1 and nothing else. That is the
prior art's own criterion — `physlib-dimensional.md` §3 — and it separates the two corpora
completely at the level of what the relations *are*, not only how many there are.

So the claim survives in the form it was registered: the calculus rules recover dimensional
*laws* from physics and calculus *identities* from calculus, and the two are distinguishable
by whether a power appears.

---

## 8. W — is an evolution equation structurally distinguished?

Registered before looking: the solver should be **blind to conservation laws** and should
**see equations of motion**. A conservation law is `deriv Q t = 0`, and `0` typechecks at
every dimension — the design deliberately gives it a fresh free variable rather than scoring
it dimensionless, because reading `0` as dimensionless invents constraints. So a
conservation law contributes a row that says nothing. An equation of motion is
`deriv Q t = (something else)`, and the right-hand side pins the derivative's dimension.

The classification is structural throughout: the two sides of every `Eq` node, by spine head,
with `rat_literal` deciding whether the other side is a zero. Measured on physlib at
`--cap 20000`:

```
--cap 20000
Eq nodes with a derivative on one side and a literal zero on the other   17   (16 declarations)
Eq nodes with a derivative on one side and anything else                155   (152 declarations)
global rows contributed:  conservation-law declarations     3 rows from  16 decls  (0.19/decl)
                          equation-of-motion declarations 105 rows from 142 decls  (0.74/decl)

--cap 200000
Eq nodes with a derivative and a literal zero                            17   (16 declarations)
Eq nodes with a derivative and anything else                            174   (171 declarations)
global rows contributed:  conservation-law declarations     3 rows from  16 decls  (0.19/decl)
                          equation-of-motion declarations 108 rows from 161 decls  (0.67/decl)
```

The conservation set does not grow at all between the two caps — **the same 17 equations and
the same 16 declarations** — while the evolution set grows by 19. Conservation laws are
short statements; they were never the ones the cap was dropping.

**Four times the dimensional yield per declaration, and the prediction holds.** The
conservation set is 16 declarations and produces three usable rows in total.

The two sets read as physics. Conservation laws:

```
ClassicalMechanics.HarmonicOscillator.energy_conservation_of_equationOfMotion
ClassicalMechanics.FreeParticle.accel_zero
ClassicalMechanics.FreeParticle.velocity_const_of_zero_acc
Electromagnetism.ElectromagneticPotential.constantEB_vectorPotential_time_deriv
Electromagnetism.ElectromagneticPotential.harmonicWaveX_electricField_space_deriv_same
Electromagnetism.ElectromagneticPotential.harmonicWaveX_magneticFieldMatrix_space_deriv_succ
Space.const_of_time_deriv_space_deriv_eq_zero
Space.time_fun_of_space_deriv_eq_zero    Space.space_fun_of_time_deriv_eq_zero
```

Equations of motion:

```
ClassicalMechanics.hamiltonEqOp_eq_zero_iff_hamiltons_equations      Hamilton's equations
ClassicalMechanics.DampedHarmonicOscillator.acceleration_eq_of_equationOfMotion
ClassicalMechanics.DampedHarmonicOscillator.energy_dissipation_rate
ClassicalMechanics.HarmonicOscillator.InitialConditions.trajectory_acceleration
ClassicalMechanics.HarmonicOscillator.kineticEnergy_deriv / potentialEnergy_deriv
CanonicalEnsemble.derivWithin_meanEnergy_Beta_eq_neg_variance        ⟨E⟩′(β) = −Var(E)
CanonicalEnsemble.deriv_mathematicalPartitionFunctionBetaReal
```

and what sits on their other side, by head:

```
HMul.hMul 21   HSMul.hSMul 20   (bound variable) 18   HAdd.hAdd 12   HSub.hSub 9
Time.deriv 6   Space.deriv 6   deriv 6   Neg.neg 5
```

**So there is a structural signature of an evolution equation, and it is not the one you
would write down first.** It is not "contains a derivative" — both classes do, and a handful
of declarations are in both. It is the *shape of the other side*: a product or a scalar
multiple for a force law (41 of the 155), another derivative for a wave or a diffusion
equation (18), a sum or difference (21), and a literal zero for a conservation law. The
grading sees the first three and is blind to the fourth by construction.

That blindness is worth stating precisely, because it is not a defect to be fixed. Reading
`0` as dimensionless would make `deriv Q t = 0` assert that `Q`'s rate is dimensionless, and
that is false for every conserved quantity in physics. The right reading of the measurement
is: **a dimensional grading is the wrong instrument for conservation laws, and the corpus
tells you which declarations they are for free.** `Eq(deriv …, 0)` is a query an agent can
run, and on this slice it returns 16 declarations of which the top hit is
`energy_conservation_of_equationOfMotion`.

What it does *not* do is single out conserved quantities as a distinguished set *inside the
grading*. The atoms under those 16 declarations' derivatives are not enriched in the
relations — they cannot be, since their declarations contribute three rows between them.

---

## 9. Spec: `Corpus.grading`, refined by what this measured

`physlib-dimensional.md` §9 wrote the first version and closed with: *"the `deriv`/`integral`
rules should land first, and `opaque`/`decomposed` must be reported on every `Grading`."*
Both are now measured, and four things in that spec need changing.

### What changed, and why

**1. `calculus: bool` is wrong; it must be a set of families.** The ablation is per family
and the families are not equally load-bearing (§6). A boolean cannot express "run the
portable vocabulary only", which is the configuration every cross-corpus comparison has to
be run in — physlib's `Time.deriv`/`Space.deriv` rules cannot fire on Mathlib, and a
comparison that leaves them on is comparing two vocabularies rather than two corpora.

**2. Bound-variable keying is a second axis and it belongs in the config.** It was not in the
first spec at all, and without it the derivative rules are worth `+27` instead of `+49`
(§3): `D(deriv f x) = D(f) − D(x)` spends the point, the point is a bound variable, and the
base keying makes every bound variable local so the row dies in elimination. Any
implementation that ships the rules without the keying will measure the rules as half of
what they are.

**3. Rule arities must be validated against the constant's own type row, as a gate.** Not a
comment, not a test fixture — a gate that fails the build. The first arity check on this
work found **13 mismatches and 3 heads that do not exist**, and two of those would have
produced *wrong rows* rather than no rows: `HasSum` and `tsum` end in an `optParam
SummationFilter`, so a rule pinned one position short reads the filter as the summand and
emits a constraint about the wrong term. A rule pinned too *long* is silent, which is
recoverable; a rule pinned too short is a fabrication.

**4. The opacity census is not a diagnostic, it is the input to rule selection.** Every rule
in §1 exists because `--census` put its head near the top of the table. Two of the highest
were things a designer would not have written down: physlib's own `Space.deriv`/`Time.deriv`,
which outrank Mathlib's `deriv` five to one, and `Complex.ofReal`, which was already in the
base solver's cast set and unreachable from its dispatch. `opaque_by_head` must therefore be
part of the returned value, not something a script recomputes.

### Query

```rust
pub struct GradingConfig {
    /// Atom identity for a *spine*. Unchanged from the first spec.
    pub keying: Keying,                    // Spine (default) | Head
    /// Atom identity for a *bound variable*. New, and load-bearing: see §3.
    ///   Local            — per declaration. The prior art, and the C0 baseline.
    ///   Type             — the binder's domain, written with `_` for open arguments.
    ///   TypeNonScalar    — as Type, except that a domain headed by one of Lean's number
    ///                      types stays local. The default, on a 66-against-60 relation
    ///                      count and *not* on the collapse argument, which §3 withdraws.
    pub bvar: BvarKeying,
    pub literals: LiteralPolicy,
    /// Which rule families run. Replaces `calculus: bool`. `RuleFamily::PORTABLE` is every
    /// family whose heads are Lean/Mathlib constants; a corpus-specific family (physlib's
    /// `Time.deriv`) must be named explicitly, so that a cross-corpus comparison cannot
    /// silently be run with one corpus's vocabulary.
    pub rules: RuleFamilySet,
}
```

`Grading` keeps its first-spec fields and gains three:

```rust
pub struct Grading {
    // … atoms, connected, rank, dim, opaque, decomposed, relations, classes, dimensionless
    /// The census. Which heads the walk could not see through, most frequent first, with
    /// the number of declarations each appears in. This is what the next rule is chosen
    /// from; a `Grading` that does not carry it cannot be improved except by guessing.
    pub opaque_by_head: Vec<(SymId, u32, u32)>,      // head, occurrences, declarations
    /// Which rules fired, per head. The other half of the census: a rule with zero hits is
    /// either pinned at the wrong arity or aimed at a constant the corpus does not use, and
    /// those two failures look identical from the relation count.
    pub rule_hits: Vec<(SymId, u32)>,
    /// Bound variables keyed by type against left local. The knob's own coverage number.
    pub typed_bvars: (u32, u32),
}
```

`Relation` is unchanged, including `witnesses: Vec<DeclId>` — **still required, still not
implemented here.** `scripts/phys-calculus.py --witness N` prints an *attribution* instead:
every declaration whose own global row shares two or more atoms with the relation. That is a
superset of the true witnesses and it is labelled as such everywhere it appears. It is in the
script so that the Rust implementation has something concrete to beat: real witnesses mean
carrying a coefficient vector over the source rows through the elimination, and the test is
that the reported set is a strict subset of the attribution and still implies the row.

### One new query the wild experiment justifies

```rust
pub enum LawShape { Conservation, Evolution, Neither }

/// Classify a declaration by the shape of its equations: `Eq(deriv …, 0)` is a conservation
/// law, `Eq(deriv …, anything else)` an equation of motion. Purely structural — the two
/// sides' spine heads and a literal test — and it costs one walk.
pub fn law_shape(&self, decl: DeclId) -> LawShape;
```

§8 is the reason. The two classes behave completely differently under the grading —
0.19 rows per declaration against 0.76 — and the classifier is three lines. An agent asking
"what does this library prove about time evolution" wants the second set; an agent asking
"what is conserved" wants the first, and must be told that the grading has nothing to add
about it.

### The gate, amended

The first spec's seven checks stand, with three corrections and two additions.

1. **The synthetic property test** — now the mechanics corpus of §2 rather than the algebraic
   one: grading dimension exactly 3, every row satisfied by the intended assignment, the FTC
   and the second-derivative restatement and a `HasDerivAt` *hypothesis* all implied by the
   nine statements that precede them, and **no global atom key beginning with `?`**. That
   last is the guard against the prior art's `has_loose_bvar` defect and it is cheap.
2. **The differential** against `scripts/phys-calculus.py`, unchanged in kind.
3. **The keying ablation, asserted to collapse** — `Keying::Head` against `Keying::Spine`.
   Unchanged: measured 95 against 341 by the prior art, and it is still the ablation that
   works.
4. **~~The bvar ablation, asserted to collapse~~** — **do not write this check.** It was
   registered here and it failed: `BvarKeying::Type` against `TypeNonScalar` moves the
   grading dimension by 5 (376 against 381), not by the 70% the spine-keying ablation moves
   it. A gate asserting a collapse that does not happen would have to be quietly weakened
   later, which is how gates go quiet. Report the number; assert nothing.
5. **The shuffle control, asserted to collapse** — measured at grading dimension **0** and
   0 relations with the calculus rules on, against 1 and 0 before. Tighten the assertion
   from `dim ≤ 3` to `dim ≤ 1`.
6. **The injection control** — unchanged.
7. **The corpus separator** — now three corpora, not two, and this is the substantive
   change. `mathlib-algebra` alone cannot test a calculus rule because it contains almost no
   calculus. The gate must include a **calculus-only** mathematics corpus (§7) and compare
   *relations per thousand declarations*, both sides running the portable vocabulary.
8. **The arity gate**, new: every rule head's pinned arity equals the `Pi`-binder count of
   its own type row in a closed slice, except for an explicitly listed set of function-valued
   heads. Currently `agree 42  mismatch 0  not in slice 0`.
9. **The C0 gate**, new: with every rule family off and `BvarKeying::Local`, the engine must
   reproduce the prior art's E2 numbers on the named slice at the named cap — 3,213 global
   rows, rank 1,363, dimension 341, 17 relations. Without it, no delta in this document is
   attributable to anything.

### What must be true before this is worth building

The first spec said: coverage, then the query. Coverage moved 58.2% → 49.9%, and the
relation count moved 17 → 66, so that condition is met in the direction it was set. The new
condition was §7's — the separator has to hold on a *calculus* corpus and not just an
algebra one — and it does, at 10.40 against 0.28 relations per thousand declarations with 0%
of the control's relations powered. Both preconditions are now met.

---

## 10. What was not run, and what is still wrong

Stated so nobody has to infer it.

* **The controls and the ablation are at `--cap 20000` only.** The 2×2 was run at both caps
  (§3) and both baseline cells reproduce the prior art, but `mathlib-algebra` (131,002 rows),
  the calculus control (44,142) and the nine ablation passes were run at the smaller cap so
  that one process could hold them. There is no reason to expect the controls to behave
  differently at the larger cap and no measurement saying they do not.
* **The 154 relations at `--cap 200000` have not been read.** The run finished; `--show 0`
  was passed to keep it inside the memory budget, so only the six that `--witness 6` prints
  have been looked at. §5's named relations are all at `--cap 20000`. Treat the 154 as a
  count and nothing more until somebody reads them.
* **Real witnesses.** `--witness` prints an over-approximation (§9), and it is useful enough
  to show what the real thing would be worth: on the `--cap 200000` run it attributes
  `ACCSystemQuad.QuadSols.toLinSols = −QuadSol.α₂ + QuadSolToSol.α₁ + ⟨ACCSystemLinear.LinSols(_)⟩`
  to `SMRHN.PlusU1.QuadSol.accQuad_α₁_α₂`, which shares three of its atoms — a named theorem
  a reader can go and check. But it is a superset by construction. A relation without exact
  provenance cannot be audited, and the vis-viva row is believable only because its atoms
  carry the theorem's name in them; a row over `Prod.fst` and `⟨ACCSystemLinear.LinSols(_)⟩`
  is not auditable at all from what is printed.
* **The `--literals free` ablation**, still. The prior art listed it as the obvious cheap
  control and it is still unmeasured; the new rules do not change that.
* **Physlib's own wrapper projections and its third derivative operator** —
  `ACCSystemLinear.LinSols.val` (215 occurrences), `Space.val` (178), `HermitianMat.mat`
  (129), `Time.val` (103), `SpeedOfLight.val` (100), and `SpaceTime.deriv` (47). The second
  census (§4) names all of them. Not done here: the projections are corpus-specific
  vocabulary and this document already carries one such family, and `SpaceTime.deriv` was
  found after the measured runs, so adding it would mean re-running everything to report a
  number nobody has yet checked.
* **`DFunLike.coe` over unrecognised bundles.** `MonoidHom` (146 occurrences) and
  `Equiv`-likes are left opaque on purpose, because a multiplicative hom has no dimensional
  reading. That is a real ceiling on coverage and not a to-do.
* **The static coverage metric is weak** (§4) and is reported anyway, with the reason.
* **A relation is not a theorem.** Everything here says two exponent vectors are equal. It
  does not say the physics is right, and — the system being homogeneous — it cannot: `x = 0`
  solves every one of these systems. `physlib-dimensional.md` §4's verdict stands unchanged:
  the detector is calibrated and the corpus is not certified.
* **One rule is asserted rather than measured**: `D(f x) = D(f)` for a *value* bundle
  (`Module.Basis`, `Equiv`, `Finsupp`, `SchwartzMap`). It is right for those four and it is a
  claim about each, not a consequence of a shared signature. If one of them is secretly
  linear, the rule merges two atoms that should differ, which is the one direction this work
  is meant never to go.
