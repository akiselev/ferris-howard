# The classical ↔ quantum dictionary, found structurally

**Corpora** (two, paired on purpose — see §5 and §5a):

* `/tmp/fh-physlib.jsonl` — 14,576 physlib + QuantumInfo declarations, **12.39% closed**.
  The defective arm, run only under `--allow-unclosed`, which stamps the report.
* `/tmp/pc-physclosed.jsonl` — 95,268 declarations: the same physics plus the Mathlib
  constants its statements reach, **99.46% closed**, residual misses all auto-generated
  `_proof_N` internals. The closed arm.

**Engine**: `fh-atlas` through the Python binding — **and the build is not pinned**. Other
sessions were editing `crates/fh-atlas/src/{dict,skel/index,skel/lgg,logical}.rs` and the
binding while this ran, and `.venv`'s extension was rebuilt at 19:14 during the session. Every
measurement below was taken by a process that imported the extension *before* that rebuild,
so the numbers are internally consistent; the source line references (`index.rs`'s `max_len`,
`dict::theory_of`, `IndexConfig::default`) were read at the same time and should be checked
against the commit a reader is on rather than trusted. This is a limitation of measuring a
codebase that several agents are changing at once, and it is stated rather than hidden.

**Script**: `scripts/phys-classical-quantum.py`.

This section is the pre-registration. Everything under §1 and §2 was written **before any
query was run**, and is not edited afterwards; corrections appear as later sections that say
what they correct. Measured results begin at §3.

---

## 1. What is being asked

Mathlib's cross-theory analogies are near-identical by construction: `to_additive` pairs
differ in one operator symbol, so the anti-unifier sees two statements of the same *shape*.
Physics is the harder case. The classical ↔ quantum correspondences below are the canonical
examples of an analogy that is real, load-bearing and **not shape-preserving**: a Poisson
bracket is a bilinear form on functions over a symplectic manifold, a commutator is a
difference of operator products on a Hilbert space, and no erasure short of "both are
antisymmetric bilinear maps" makes them the same term.

So this is the strongest available test of the cross-theory thesis. If B4/B6 recover any of
these from structure alone, the thesis has evidence that does not come from a corpus whose
analogies were mechanically generated. If it recovers none, that is a clean negative and it
localises where the engine stops: at shape identity.

## 2. Pre-registered expectations

### 2a. The ground truth: correspondences a physicist would name

Written from physics knowledge, before looking at what physlib contains. Each entry names
the classical object, the quantum object, and — the part that matters — **what the two
statements would have to share for the anti-unifier to see them**.

| # | classical | quantum | shared structure a structural engine could see |
|---|---|---|---|
| E1 | Poisson bracket `{f,g}` | commutator `[A,B]/iħ` | antisymmetry, bilinearity, Jacobi, Leibniz — same *algebraic laws*, different carrier and different operation |
| E2 | observable = real function on phase space | observable = self-adjoint operator | "is real-valued" vs "is self-adjoint / has real spectrum" |
| E3 | Hamiltonian `H(q,p)` | Hamiltonian operator `Ĥ` | both appear as the distinguished argument of an evolution law |
| E4 | Hamiltonian flow / Hamilton's equations | Schrödinger / Heisenberg equation | `d/dt X = {H,X}` vs `iħ d/dt A = [A,H]` — same first-order evolution shape |
| E5 | Liouville measure on phase space | density matrix | normalised, non-negative, "state" |
| E6 | Liouville equation `∂ρ/∂t = {H,ρ}` | von Neumann equation `iħ∂ρ/∂t = [H,ρ]` | identical up to E1 |
| E7 | expectation `∫ f ρ dμ` | `Tr(ρ A)` | linear functional of an observable against a state, positive and normalised |
| E8 | classical harmonic oscillator `H = p²/2m + ½mω²x²` | quantum HO, spectrum `(n+½)ħω` | same Hamiltonian written in the same shape; the *spectra* differ |
| E9 | `{x,p} = 1` | `[x̂,p̂] = iħ` | canonical (anti)commutation relation |
| E10 | conserved quantity `{H,f} = 0` | `[H,A] = 0` | same conservation shape under E1 |
| E11 | free particle `E = p²/2m` | free Schrödinger evolution | same kinetic term |
| E12 | angular momentum `L = r×p`, rotation group action | `Ĵ`, su(2)/spin representation | same Lie-algebra relations |
| E13 | Newton/Ehrenfest: `m d²⟨x⟩/dt² = -⟨∇V⟩` | Ehrenfest theorem | the classical equation *stated about* quantum expectations |
| E14 | action `S`, Lagrangian | path-integral phase `e^{iS/ħ}` | same action functional |
| E15 | symplectic form ω | commutator / imaginary part of the inner product | antisymmetric non-degenerate form |

A second, independent axis inside the same corpus — classical vs quantum **information**:

| # | classical | quantum | shared structure |
|---|---|---|---|
| E16 | Shannon entropy `H(p) = -Σ p log p` | von Neumann entropy `S(ρ) = -Tr ρ log ρ` | same functional, sum against trace |
| E17 | KL divergence `D(p‖q)` | relative entropy `D(ρ‖σ)` | same non-negativity, same data-processing law |
| E18 | classical channel = stochastic map | quantum channel = CPTP map | composition, identity, data processing |
| E19 | classical mutual information | quantum mutual information | `I(A;B) = H(A)+H(B)-H(AB)` on both sides |
| E20 | probability distribution / simplex | density matrix / state space | convexity, normalisation, extreme points = pure states |

E16–E20 are the *easier* half on purpose: `QuantumInfo.ClassicalInfo` and the quantum
`Entropy`/`States`/`Channels` modules are written by the same authors in the same style, so
if the engine cannot find these it cannot find anything, and if it finds only these the
result is "same author, same shape" rather than "same idea".

### 2b. Predictions

* **P1 (the headline).** The `ClassicalMechanics ~ QuantumMechanics` dictionary contains at
  least one row a physicist would score as genuine — i.e. matching some E1–E15 — among its
  top 20 by score, at some (anchor, level, score) setting in the sweep.
* **P2 (anchor replication).** Conclusion-anchored assembly produces strictly more genuine
  rows than root-anchored, replicating §46's RH finding on an independent corpus. If root
  ≥ conclusion, §46's "cross-theory analogy needs the conclusion anchor" does not generalise
  and that is reported as a failure to replicate.
* **P3 (informativeness of the null).** `dictionary_shuffle_control` is reported *with* an
  informativeness verdict: genuine ≈ shuffled ≈ 0 is a **dead control**, not a pass. §46
  found exactly that on RH.
* **P4 (the harder half is harder).** The E16–E20 information dictionaries yield a higher
  genuine-row fraction than E1–E15 mechanics. If mechanics beats information, something is
  wrong with my expectation, not with the engine, and I say so.
* **P5 (missing entries are the point).** `missing_left` on the mechanics dictionary will
  contain the E1/E4/E6/E9 family — the bracket/evolution correspondences — because those
  statements share laws rather than shapes. Their presence in `missing_*` is the *expected*
  outcome and is scored as a correct negative, not as a miss.

### 2c. What would show the engine does **not** work

Named before the run so it cannot be rationalised afterwards:

* Every row in every dictionary is a library artifact — units API, `noConfusion`,
  `sizeOf_spec`, `.injEq`, or "this constant is positive". §3c and §21 of
  `corpus-atlas-findings.md` found exactly this on the earlier physlib slice.
* The negative-control theory pairs (§2d) produce dictionaries indistinguishable in score
  and character from `ClassicalMechanics ~ QuantumMechanics`.
* The engine returns rows only where the two statements are *already* the same shape (the
  `to_additive` regime), i.e. every genuine row is a near-duplicate rather than a
  correspondence.

### 2d. Controls, each pre-registered

* **NC1 — closure.** `Corpus.closure()` must report ≥ 95% before any query at `instances`
  or above. Below that the run is abandoned, not caveated (§31, §32).
* **NC2 — erasure liveness.** A positive control that the erasure is doing something on
  *this* corpus: at least one declaration whose `skeleton(carriers)` differs from
  `skeleton(presentation)`. An inert erasure passes every downstream check by returning the
  unerased term (§5's source-B trap).
* **NC3 — negative theory pairs.** The same pipeline on pairs where no classical/quantum
  correspondence exists: `ClassicalMechanics ~ Units`, `ClassicalMechanics ~ Meta`,
  `Thermodynamics ~ Meta`. These bound what "a dictionary between two arbitrary physics
  modules" looks like.
* **NC4 — shuffle.** `dictionary_shuffle_control` on every pair, reported with P3's
  informativeness verdict.
* **NC5 — coherence.** `dictionary_coherence` and `dictionary_policies` on every pair, so a
  95.9%-collision dictionary is not reported as 169 findings (§21).
* **NC6 — any filter gets a control.** Every narrowing knob used (`max_per_right`,
  `theorems_only`, floors) is reported with the unfiltered count beside it, because
  narrowing is where false negatives are manufactured.

### 2e. Scoring protocol, fixed in advance

Each presented row is classified by reading **the two statements** (I3 skeletons, and the
Lean source where it is ambiguous), never the names alone:

* **A — genuine correspondence**: the two sides express the same physical idea across the
  classical/quantum divide. The E-number is named, or "unlisted-genuine" with a reason.
* **B — shared mathematics**: both sides instantiate the same generic mathematics
  (linearity, continuity, an algebraic law) with no classical/quantum content of their own.
  A *real* structural match and not a correspondence.
* **C — artifact**: auto-generated, units boilerplate, content-free positivity, or a
  definitional unfolding.

Every row of every presented list is classified; nothing is dropped for being embarrassing,
and the raw JSON of every run is written beside the report.

---

## 3. Corpus audit: which of E1–E20 physlib can even be asked about

Done **after** the pre-registration and before scoring anything, by reading the library's
source. A correspondence whose classical half is not in the corpus cannot be found, missed,
or reported missing — and calling that a failure of the engine would be a category error.

| # | classical side | quantum side | testable? |
|---|---|---|---|
| E1 Poisson ↔ commutator | **absent** — no `Poisson`, no bracket on functions | `Operators/Commutation.lean`, 33 theorems | **no** |
| E2 observable ↔ self-adjoint | symmetric inertia tensors | `momentumOperator_isSymmetric`, `potentialOperator_isSelfAdjoint` | yes (weakly) |
| E3 Hamiltonian | `HarmonicOscillator.hamiltonian_eq_energy` | `HarmonicOscillator.hamiltonain_eq` | yes |
| E4 Hamilton's equations ↔ Schrödinger | `HamiltonsEquations.lean`, 4 theorems | `TISE`, `schrodingerOperator_eigenfunction` | yes |
| E5/E20 distribution ↔ density matrix | `ProbDistribution` | `MState`, `Ket` | yes |
| E6 Liouville ↔ von Neumann | **absent** | `MState` evolution | **no** |
| E7 expectation ↔ trace | `ProbDistribution.expect_val` | `MState.exp_val` | yes |
| E8 harmonic oscillator | 43 theorems | 25 theorems (+ `OneDimension`) | yes |
| E9 `{x,p}=1` ↔ `[x̂,p̂]=iħ` | **absent** | `positionOperatorSchwartz_commutation_momentumOperatorSchwartz` | **no** |
| E10 conserved quantity | `energy_conservation_of_equationOfMotion` | no conservation law stated | partial |
| E11 free particle | `FreeParticle/Basic.lean` | `FreeParticle/Basic.lean` | yes |
| E12 angular momentum | `RigidBody/AngularMomentum` | `Operators/AngularMomentum` | yes |
| E13 Ehrenfest | **absent** | **absent** | **no** |
| E14 action ↔ path integral | Lagrangians present | **absent** | **no** |
| E15 symplectic form | **absent** | — | **no** |
| E16–E19 entropy / channels | `ClassicalInfo.{Entropy,Channel,Distribution}` | `Entropy.*`, `Channels.*` | yes |

**Six of the twenty are not askable of this corpus**, all of them on the classical side and
all for the same reason: physlib has no symplectic geometry. The half of the ground truth
that survives is E2–E5, E7, E8, E10–E12 and E16–E20 — thirteen entries, and the report
below is scored against those.

That is itself a finding about the thesis's reach. The correspondences a physicist reaches
for first — Poisson bracket to commutator, Liouville to von Neumann — are unavailable not
because the engine is weak but because nobody has formalised the classical side.

## 4. The dictionary cannot name a physics theory, and says so by returning nothing

`dict::theory_of` takes the module prefix at **depth 2 under `Mathlib` and depth 1
everywhere else**. Every physlib module is `Physlib.*` or `QuantumInfo.*`, so the whole
library is two theories — `Physlib` (12,039 declarations) and `QuantumInfo` (2,529).

`c.dictionary("ClassicalMechanics", "QuantumMechanics")` therefore selects zero lefts and
returns a `Dictionary` with **no rows, no error and no warning**. Passing the full prefix
does not help either: retrieval would be restricted correctly by `restrict_prefix`, and then
`theory_of(n.module) != right` would reject every candidate, because `theory_of` of
`Physlib.QuantumMechanics.X` is `Physlib`, not `Physlib.QuantumMechanics`.

Both failure modes produce the empty dictionary, which is indistinguishable from "these two
theories have nothing in common" — the answer a reader would take at face value. Measured on
the un-rewritten physlib slice:

```
dictionary('Physlib.ClassicalMechanics', 'Physlib.QuantumMechanics') -> 0 rows, missing_left 0, missing_right 0
dictionary('ClassicalMechanics',         'QuantumMechanics')         -> 0 rows, missing_left 0, missing_right 0
```

`missing_left` is empty too, so even the report that exists to say "here is what has no
partner" says nothing. Every field of the result is consistent with a well-posed query that
found no analogy.

The fix used here is the one `scripts/physlib-experiment.py` established: rewrite the module
root out, so `Physlib.QuantumMechanics.X` files under theory `QuantumMechanics`. It is a
copy of the slice, never an edit in place, and it produces **27 theories** of comparable
size (Relativity 2,144 … ClassicalMechanics 631 … Capacity 18). Every physlib result in
`corpus-atlas-findings.md` §3c, §21 and §22 must have gone through the same rewrite; nothing
in the engine or its documentation says so.

## 5. What closure changes, and what it provably does not

`Corpus.generalize` anti-unifies the **encoded statements**: it parses two rows into the
arena and calls `lgg` on them, with no erasure and no signature lookup (`lib.rs:1118-1127`).
It therefore cannot be degraded by an unclosed slice — there is nothing in its path that
looks a constant up by name.

`similar`, `dictionary`, `skeleton`, `equivalent`, `classes` and `motifs` all run over
`erase(stmt, level)`, and the erasure asks the corpus for a head constant's signature to
find its `InstImplicit` positions. Those are the queries §31 measured degrading silently.

So the results below split cleanly:

* **closure-independent** — §6's targeted oracle and §7's exhaustive dictionary, both built
  from `generalize`;
* **closure-dependent** — the shipped `dictionary`, `similar`, `classes`, `motifs`,
  `frontier`.

**Measured rather than argued.** The same four `generalize` calls, on the 14,563-row slice
at 12.39% closure and on a 347-row slice restricted to `ClassicalInfo` and `Entropy` at
**0.85%** closure:

| pair | 14,563 rows / 12.39% | 347 rows / 0.85% |
|---|---|---|
| `Hₛ_nonneg ~ Sᵥₙ_nonneg` | 0.8889 / common 24 | 0.8889 / common 24 |
| `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` | 0.6970 / 23 | 0.6970 / 23 |
| `Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero` | 0.8182 / 27 | 0.8182 / 27 |
| `H₁_nonneg ~ Sᵥₙ_nonneg` | 0.7407 / 20 | 0.7407 / 20 |

Identical to four decimal places across a 42× change in corpus size and a 15× change in
closure. A quantity that moves with the corpus cannot do that.

This is not an excuse for running the closure-dependent half on a bad corpus. It is the
reason the two halves are reported separately, and the reason the closure-independent half
is the one the headline rests on.

### 5a. Which corpus the numbers below were taken on

**Sections 6–10 ran on `/tmp/fh-physlib.jsonl`, whose closure is 12.39%** — the defective arm
of the pairing, run under `--allow-unclosed`, which stamps `"defective_arm": true` into every
report it writes. It is quoted here because the two results the argument rests on — §6's
targeted oracle and §7's exhaustive dictionary — are computed by `generalize`, which §5 shows
cannot read a corpus's closure at all.

The closure-dependent half (§8's shipped dictionary, §9's classes, motifs and frontier) is
quoted as the defective arm's answer and is not a claim about a closed corpus until §11 says
so. That is the whole point of running both.

## 6. The targeted oracle: eighteen named pairs, one at a time

Retrieval is taken out of the loop. Each pair from §2a is resolved to two declaration names
(disclosed input — the names choose the *question*), and `generalize` is asked directly. The
null is the same left against eight random theorems of the right's own theory, so a
retention can be read as high or low rather than admired in isolation.

`rank` is where `similar` puts the true partner, with the floors dropped to
`min_retention=0.02`, `min_common=2` and `top=200`, over the six combinations of
{carriers, shape, presentation} × {root, conclusion}; `—` means it was **never returned at
any of them**.

| pair | E | root | concl | null(root) | null(concl) | rank |
|---|---|---|---|---|---|---|
| `Hₛ_nonneg ~ Sᵥₙ_nonneg` | E16 | 0.133 | **0.889** | 0.034 | 0.100 | — |
| `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` | E16 | 0.118 | **0.697** | 0.006 | 0.046 | — |
| `Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero` | E16/E20 | 0.122 | **0.818** | 0.005 | 0.104 | — |
| `H₁_nonneg ~ Sᵥₙ_nonneg` | E16 | 0.000 | **0.741** | — | 0.043 | — |
| `Prob.coe_le_one ~ MState.eigenvalue_le_one` | E20 | 0.014 | 0.328 | 0.011 | 0.070 | — |
| `Prob.zero_le ~ MState.eigenvalue_nonneg` | E20 | 0.014 | 0.194 | 0.008 | 0.073 | — |
| `ProbDistribution.normalized ~ Ket.normalized` | E5/E20 | **0.574** | **0.534** | 0.017 | 0.074 | **1** |
| `ProbDistribution.zero_le_expect_val ~ MState.exp_val_nonneg` | E7 | 0.013 | 0.390 | 0.050 | 0.122 | — |
| `ProbDistribution.expect_val_constant ~ MState.exp_val_one` | E7 | 0.045 | 0.122 | 0.037 | 0.128 | — |
| `HarmonicOscillator.energy_eq ~ HarmonicOscillator.hamiltonain_eq` | E3/E8 | 0.000 | 0.003 | 0.003 | 0.015 | — |
| `hamiltonian_eq_energy ~ hamiltonain_eq` | E3 | 0.000 | 0.002 | 0.001 | 0.002 | — |
| `potentialEnergy_eq ~ potentialFunction_eq` | E8 | 0.000 | 0.047 | 0.003 | 0.016 | — |
| `angularMomentum_eq_inertiaTensor_mulVec ~ angularMomentumOperator_apply` | E12 | 0.000 | 0.002 | 0.000 | 0.052 | — |
| `inertiaTensorAbout_symmetric ~ momentumOperator_isSymmetric` | E2 | 0.006 | 0.012 | 0.001 | 0.063 | — |
| `hamiltonEqOp_eq_zero_iff_hamiltons_equations ~ schrodingerOperator_eigenfunction` | E4 | 0.000 | 0.026 | 0.003 | 0.010 | — |
| `energy_conservation_of_equationOfMotion ~ QuantumSystem.ℋ_self_adjoint` | E10 | 0.003 | 0.074 | 0.001 | 0.077 | — |
| *control* `HO.ω_pos ~ HO.ω_pos` | — | 0.000 | 0.800 | — | 0.121 | — |
| *control* `HO.m_ne_zero ~ HO.m_ne_zero` | — | 0.000 | 0.857 | 0.002 | 0.072 | **25** |

Four things are measured here and none of them is what P1 predicted.

**The root anchor is dead for cross-theory physics.** Sixteen of eighteen pairs anti-unify to
retention ≤ 0.13 at the root, and eight of them to exactly 0. That is §46's RH finding
reproduced on an independent corpus and a different subject: the hypothesis prefixes differ,
so root-anchored anti-unification aligns the wrong thing first. **P2 replicates.**

**The conclusion anchor recovers the information correspondences.** E16's four entries land
at 0.70–0.89 against nulls of 0.04–0.10 — an order of magnitude above the null, on
statements that a physicist named in advance. `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` is the classical
and quantum maximum-entropy bounds, and the engine sees them as 23 shared nodes out of 33.

**The mechanics correspondences are invisible, and the trivial ones are not.** Every E2–E12
pair sits at 0.002–0.074, indistinguishable from its own null, while the two content-free
controls — the *same* lemma name on both sides, "this constant is positive" — reach 0.80 and
0.86. The engine's view of `ClassicalMechanics ~ QuantumMechanics` is dominated by exactly
what §21 said it was. **P4 holds, and in the strong form: the hard half is not merely
harder, it is absent.**

**Retrieval never proposes the partner.** Sixteen of the eighteen pairs are absent from
`similar`'s output at every level and both anchors, with the floors on the floor — including
the four that anti-unify at 0.70–0.89. The one pair `similar` does rank at 1 is
`normalized ~ normalized`, and the only other ranked pair is a content-free control at 25.

`similar_brute`, which switches the prefilter off entirely, does not rescue them either: it
takes no `anchor` and is therefore root-anchored, where there is nothing to rank. That is the
diagnosis, not an excuse — the brute reference cannot answer a conclusion-anchored question.

## 7. The prefilter is the loss, and it costs the whole dictionary

`similar` returns **13 to 50 candidates** for these queries even asked for 200 with floors at
0.02/2. Candidate generation, not the floors and not the scorer, decides what a dictionary
can contain.

The mechanism is in `index.rs`: a posting list longer than `max(0.001·N, 50)` is **dropped**
at build time, and a shape bucket above `max_bucket = 600` contributes nothing. Both are the
right call for "what looks like this declaration" over a whole corpus — and both are exactly
wrong for a cross-theory dictionary, because two theories that state the same idea in generic
mathematics (`0 ≤ f x`, `∑ = 1`) share only *common* keys. The keys that carry the analogy are
the keys the index discards as uninformative.

`ProbDistribution.normalized ~ Ket.normalized` is the exception that shows the rule: it shares
a large, rare subterm (66 common nodes of `Finset.sum` machinery), so source B proposes it and
it ranks 1. `Hₛ_nonneg ~ Sᵥₙ_nonneg` shares 24 nodes of `0 ≤ …`, which is everywhere, so it is
proposed by nothing.

### The ablation: the same floors with no prefilter

`exhaustive_dictionary` anti-unifies every left against every right and keeps what clears the
engine's own floors (`retention ≥ 0.30`, `common ≥ 6`). It is affordable exactly where it
matters: 218,348 pairs in 20 s.

| dictionary | anchor | engine rows | exhaustive rows | overlap | engine lefts | exhaustive lefts |
|---|---|---|---|---|---|---|
| ClassicalInfo ~ Entropy | root | 0 | 1 | 0 | 0 | 1 |
| ClassicalInfo ~ Entropy | conclusion | 14 | **273** | 10 | 8 | **37** |
| ClassicalInfo ~ States | root | 17 | 37 | 16 | 7 | 12 |
| ClassicalInfo ~ States | conclusion | 39 | **540** | 23 | 16 | **55** |
| ClassicalInfo ~ Channels | root | 0 | 1 | 0 | 0 | 1 |
| ClassicalInfo ~ Channels | conclusion | 1 | **123** | 1 | 1 | **30** |

And the rows the prefilter loses are not the tail. These are the **top twelve** exhaustive
rows of `ClassicalInfo ~ Entropy` at the conclusion anchor, with whether the shipped
dictionary contains them:

```
0.889 no   Hₛ_nonneg            ~ Sᵥₙ_nonneg                      <- E16
0.818 no   Hₛ_constant_eq_zero  ~ Sᵥₙ_of_pure_zero                <- E16/E20
0.774 no   Hₛ_nonneg            ~ sandwichedTraceFunctional_nonneg
0.741 no   H₁_nonneg            ~ Sᵥₙ_nonneg                      <- E16
0.697 no   Hₛ_le_log_d          ~ Sᵥₙ_le_log_d                    <- E16
0.655 no   Hₛ_constant_eq_zero  ~ Sᵥₙ_unit_zero
0.645 no   H₁_nonneg            ~ sandwichedTraceFunctional_nonneg
0.629 no   Hₛ_uniform           ~ Sᵥₙ_le_log_d                    <- E16, uniform ⇒ max
0.615 no   Hₛ_nonneg            ~ qcmi_nonneg
0.613 no   Hₛ_nonneg            ~ sandwichedTraceFunctional_pos
0.606 no   H₁_zero_eq_zero      ~ Sᵥₙ_of_pure_zero
0.606 no   H₁_one_eq_zero       ~ Sᵥₙ_of_pure_zero
0.586 YES  Prob.negLog_one      ~ sandwichedRelRentropy_self
```

**The classical ↔ quantum information dictionary is recoverable from structure alone, and
the shipped query does not return it.** The first row the engine agrees with is the
thirteenth, and every row above it was pre-registered in §2a before any of this ran.

### The same ablation on mechanics finds nothing, which is also a result

`ClassicalMechanics ~ QuantumMechanics` exhaustively at the conclusion anchor: **2,629 rows
over 218,348 pairs, 133 lefts, 161 rights** — and of the top 400 by retention, 363 are
"this constant is positive / non-zero", 18 are `mk.inj`/`sizeOf_spec`, and the remaining 19
are the same positivity family under names the census pattern missed
(`angularFrequency_pos_of_underdamped`). Nothing in the top 400 is a physical
correspondence.

So the negative is not an artifact of retrieval. For E2–E12, **the structure is not there to
find**: a classical Hamiltonian is a real-valued function on a Euclidean configuration space
and a quantum one is an unbounded operator on an L² space, and after erasure to carriers they
still share almost nothing. This is the boundary of the thesis, located rather than argued.

### Dilution: unrelated declarations delete true rows, monotonically

The smoke test on a 347-row slice holding only `ClassicalInfo` and `Entropy` returned
`Hₛ_le_log_d ~ Sᵥₙ_le_log_d` as its **top row** — from the shipped `dictionary`, no
ablation. The same query on the 14,563-row slice containing those same 347 rows returns
none of the pre-registered targets. So the loss is not a property of the two theories.

The controlled version: hold the two theories' rows fixed, add a random sample of unrelated
physlib declarations around them, and re-run the same query.

| declarations | `max_len` | dictionary rows | pre-registered targets found | top row |
|---|---|---|---|---|
| 347 | 50 | 37 | **3 / 4** | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 497 | 50 | 37 | **3 / 4** | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 747 | 50 | 37 | **3 / 4** | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 1,247 | 50 | 23 | 1 / 4 | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 2,347 | 50 | 21 | 1 / 4 | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 5,347 | 50 | 19 | 1 / 4 | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 14,563 | 50 | 14 | **0 / 4** | `Prob.negLog_ne_top ~ sandwichedRelEntropy_ne_top` |

Nothing about `ClassicalInfo` or `Entropy` differs between the first row of that table and
the last. The declarations added are physics from other subfields, none of which can be a
candidate — `restrict_prefix` excludes them from retrieval. They delete rows anyway, because
`max_len` is a cap on *how many declarations may hold a key corpus-wide*, and a key held by
`0 ≤ f x` crosses 50 holders somewhere between 747 and 1,247 declarations. Above that the
key is dropped from the index and every pair that depended on it becomes unreachable, in
both theories at once.

The crossing point is an inference, not a measurement: what is measured is that rows
disappear monotonically as unrelated declarations are added, and that the only quantity in
the retrieval path which depends on the rest of the corpus is a key's document frequency
against `max_len`. Instrumenting `Postings::build` to report which keys it dropped would
turn the inference into a measurement, and that instrumentation does not exist.

This is the sharpest result in this report, because it is a controlled experiment rather
than a comparison: **one variable, monotone response, and a mechanism named in the source
that no other quantity in the path could produce.**

**And the same curve on mechanics separates the two failures.** `ClassicalMechanics ~
QuantumMechanics`, same protocol, nine pre-registered target rows connecting those two
theories:

| declarations | rows | targets found |
|---|---|---|
| 1,629 (the two theories alone) | 174 | **0 / 9** |
| 1,929 | 169 | 0 / 9 |
| 2,629 | 169 | 0 / 9 |
| 4,629 | 133 | 0 / 9 |
| 9,629 | 130 | 0 / 9 |
| 14,576 | 126 | 0 / 9 |

Dilution costs rows here too — 174 down to 126 — but it costs no *targets*, because there
were none to lose at any size. The information failure is a retrieval defect that shrinking
the corpus repairs; the mechanics failure is not, and no corpus size repairs it. Two
different negatives that would have been indistinguishable without this control.

**P6, registered before the closed corpus finished extracting.** On a slice of roughly half a
million declarations (physlib's full import closure), `max_len` rises to ~500 while the number
of declarations holding `0 ≤ f x` rises with Mathlib's whole order library — far faster. The
prediction is therefore **0 / 4 targets and no more rows than the 14,563-row arm**, and the
information dictionary should be *worse* on the closed corpus than on the unclosed one. If
instead the closed corpus recovers targets, this mechanism is wrong and the section is
withdrawn.

### The exhaustive path's own control: it buys recall, not precision

Run the same ablation on the pre-registered nonsense pairs and on the mechanics pair. The
column `auto@25` counts, among the top 25 rows by retention, how many involve a
constructor-injectivity or size lemma; `triv@25` counts "this constant is positive / non-zero".
Both are **name censuses of an artifact family**, disclosed as such — they describe what the
rows are, they do not decide whether a row is right.

| pair (conclusion anchor) | pairs evaluated | rows above floor | rate | auto@25 | triv@25 |
|---|---|---|---|---|---|
| ClassicalInfo ~ Entropy | 15,655 | 273 | 1.74% | 0 | 7 |
| ClassicalInfo ~ States | 22,321 | 540 | 2.42% | 0 | 5 |
| ClassicalInfo ~ Channels | 26,765 | 123 | 0.46% | 16 | 0 |
| ClassicalMechanics ~ QuantumMechanics | 218,348 | 2,629 | 1.20% | 4 | 21 |
| **NC3** ClassicalInfo ~ Meta | 3,333 | 105 | 3.15% | **25** | 2 |
| **NC3** Thermodynamics ~ Meta | 1,452 | 72 | 4.96% | **25** | 0 |
| **NC3** ClassicalMechanics ~ Meta | 10,659 | 549 | 5.15% | **25** | 0 |

The nonsense pairs have the **highest** above-floor density of all — 5.15% against 1.74% for
the one dictionary that contains real correspondences. So removing the prefilter does not
improve precision and must not be sold as if it did: it recovers the rows the index dropped,
and it recovers the artifacts too.

What separates them is the *composition of the top*, not the count: 25 of 25 for every
nonsense pair and for mechanics, against 7 of 25 for `ClassicalInfo ~ Entropy` whose top
twelve are the pre-registered correspondences. The engine already owns a structural version
of this census — the derivativeness measure, AUC 0.899 on physlib with no name matching — and
this ranking did not use it: rows here are ordered by retention alone, because `generalize`
returns no score. That is a fact about this instrument and a requirement on S1.

## 8. The shipped dictionary, hand-scored — and the control that ends the argument

Every dictionary was run at both anchors, under `retention` and `min_normalised`, with and
without `max_per_right=1` (NC6: the unfiltered count is beside the capped one). Rows are
classified by reading both statements, per §2e: **A** genuine correspondence, **B** shared
mathematics with no classical/quantum content, **C** artifact.

| dictionary | anchor | rows | lefts | rights | collision | genuine mean | shuffled (broad) |
|---|---|---|---|---|---|---|---|
| ClassicalMechanics ~ QuantumMechanics | root | 69 | 34 | 18 | 1.000 | 0.912 | 0.013 |
| ClassicalMechanics ~ QuantumMechanics | conclusion | 126 | 61 | 35 | 0.920 | 0.953 | 0.079 |
| QuantumMechanics ~ ClassicalMechanics | conclusion | 157 | 59 | 46 | 0.960 | 0.953 | 0.098 |
| ClassicalInfo ~ Entropy | root | **0** | 0 | 0 | — | — | — |
| ClassicalInfo ~ Entropy | conclusion | 14 | 8 | 8 | 0.714 | 0.422 | 0.068 |
| ClassicalInfo ~ States | root | 17 | 7 | 16 | 0.118 | 0.537 | 0.053 |
| ClassicalInfo ~ States | conclusion | 39 | 21 | 23 | 0.680 | 0.515 | 0.107 |
| ClassicalInfo ~ Channels | root | **0** | 0 | 0 | — | — | — |
| ClassicalInfo ~ Channels | conclusion | 1 | 1 | 1 | 0.000 | 0.322 | 0.195 |
| ClassicalFieldTheory ~ QFT | conclusion | 2 | 2 | 1 | 1.000 | 0.323 | 0.049 |
| **NC3** ClassicalMechanics ~ Units | conclusion | 14 | 12 | 6 | 0.786 | 0.553 | 0.084 |
| **NC3** ClassicalMechanics ~ Meta | root | 83 | 35 | 25 | 0.560 | 0.733 | 0.020 |
| **NC3** ClassicalMechanics ~ Meta | conclusion | 82 | 35 | 25 | 0.640 | 0.821 | 0.255 |
| **NC3** Thermodynamics ~ Meta | conclusion | 10 | 7 | 8 | 0.400 | 0.632 | 0.293 |

### The scoring

**A correction to §2e's protocol, made after seeing rows and flagged as such.** Three classes
were not enough: A, B and C have no bucket for a row whose two sides are both contentful and
simply unrelated — `ProbDistribution.uniform_def ~ MState.pure_inner`. Those are scored **D —
spurious**, and the count is reported separately rather than folded into B, which would have
flattered the engine, or into C, which would have blamed the library.

| dictionary (conclusion anchor) | rows scored | A | B | C | D |
|---|---|---|---|---|---|
| ClassicalMechanics ~ QuantumMechanics | 25 | **0** | 0 | 25 | 0 |
| ClassicalInfo ~ States | 25 | **2** | 8 | 6 | 9 |
| ClassicalInfo ~ Entropy | 14 (all) | **0** | 11 | 2 | 1 |

`ClassicalMechanics ~ QuantumMechanics`: fourteen rows are
`ClassicalMechanics.<constant>_pos ~ QuantumMechanics.OneDimension.HarmonicOscillator.{ξ_pos, hm, hω}`
— five different classical constants and `MassUnit` all claiming the same three quantum
rights — four are `mk.inj`, and three pair `DampedHarmonicOscillator.angularFrequency_*`
against `LinearPMap.IsSymmetric.im_eq_zero_of_mem_numericalRange`. This is §21's
collision-magnet finding reproduced exactly, on a different slice and after the scorer was
connected to the presentation.

`ClassicalInfo ~ States`: the two A rows are
`ProbDistribution.normalized ~ Ket.normalized` and its `Bra` twin — probabilities summing to
1 against amplitudes square-summing to 1, E5/E20, and *not* the same statement: one is a
`Finset.sum` of `Prob`s coerced into `ℝ`, the other a `Finset.sum` of `Complex.normSq`. The
Bs are the `ext`/`ext_iff` pairs and four `ℝ≥0∞`-finiteness pairs — real structural analogies
with no physics in them.

`ClassicalInfo ~ Entropy`: no A at all. Eleven rows pair `Prob.negLog_*` against
`qRelativeEnt_*`/`sandwichedRelEntropy_*` — "an `ℝ≥0∞`-valued information quantity is finite,
or vanishes at its trivial argument". A physicist would grant surprisal ~ relative entropy as
a family resemblance; it is not one of E16–E19, and §7 showed that the entries which *are*
E16–E19 exist, anti-unify at 0.70–0.89, and are absent from this list.

### NC3 is the finding

**`ClassicalMechanics ~ Meta` — physics against the library's own metaprogramming, a pair
with no possible correspondence — returns 82 rows at genuine mean retention 0.821, against
`ClassicalInfo ~ Entropy`'s 14 rows at 0.422.** Its rows are
`ClassicalMechanics.VisViva.mk.sizeOf_spec ~ Physlib.HTMLNote.mk.sizeOf_spec` and eleven
siblings: constructor injectivity and size lemmas, which are identical in shape for any two
structures in any two theories.

Its shuffle control separates cleanly too — 0.821 genuine against 0.255 shuffled. So the
null answers "is this better than random pairing" with a confident yes for a dictionary
between mechanics and an HTML note-taking utility.

That is the pre-registered §2c failure condition, met: the negative-control theory pairs are
not distinguishable from the real one by any number the engine reports. **P1 fails.** The
`ClassicalMechanics ~ QuantumMechanics` dictionary contains no genuine correspondence at any
setting in the sweep, and the settings that produce the most rows produce the most artifacts.

### P3: the null, and whether it is informative

`Corpus.dictionary_shuffle_control` takes neither `anchor` nor `score`, so it silently
reports on a *root-anchored retention* dictionary whatever was asked for. On
`ClassicalInfo ~ Entropy` that dictionary has zero rows, and the engine's control duly
returns genuine 0.000 against shuffled 0.000 — §46's dead control, reproduced here for a
mechanical reason that §46 did not name.

This script's own null runs at the reported configuration and separates on every non-empty
dictionary, including the nonsense ones. Both arms behave as designed:

* **matched** (alternates drawn from rights that already matched) is the conservative arm and
  still separates 0.4–1.0;
* **broad** (any theorem of the right theory) separates 0.84–1.0 everywhere.

So the null is informative in the narrow sense — genuine pairs beat shuffled ones — and
useless in the sense that matters, because it says the same thing about
`ClassicalMechanics ~ Meta`. **P3's verdict: the shuffle control is alive here and it is not
evidence of anything a reader wants to know.** §21 said this; NC3 makes it quantitative.

## 9. The other surfaces, and what they say

**Equivalence classes spanning two theories: one, and it is a restatement.** At
`presentation`, `instances` and `carriers`, exactly one class straddles any two of the named
theories — `Sᵥₙ_eq_trace_cfc` (States) with `Sᵥₙ_eq_trace_cfc_negMulLog` (Entropy), two
spellings of the same lemma about the same object. No classical statement is *equal after
erasure* to a quantum one, at any level. That is the expected answer and worth recording:
erasure-equality is the wrong instrument for this question, which is why B4 exists.

**Motifs spanning two theories: zero.** Of the **top 400** motifs by `size × log(family)` at
`min_family=2`, `min_size=4`, on both sources, none has a member list containing declarations
from two of the ten named theories. (`motifs` ranks and truncates, so this is a statement
about its top 400 and not about every motif in the corpus.) The inventory of shared structure that the corpus *contains* is,
by this surface, empty across the classical/quantum divide — while §7 shows 273 pairs above
the engine's own floors in one theory pair alone. `motifs` reports what the posting lists
already indexed, so it inherits §7's blind spot exactly.

**The frontier ranks the corpus's own copies, not physics.** Best excess-over-chance pairs
(theorems only, min size 60): `ClassicalMechanics ~ Electromagnetism` 0.085 (excess +0.019,
2 cross-citations), then everything else negative. `ClassicalInfo ~ Entropy` sits at
similarity **0.000**, excess −0.026, with 11 cross-citations — the frontier says the two
theories where §7 finds 273 structural pairs have *nothing* in common, because its
similarity is "shape buckets both theories occupy" and the buckets in question were dropped
from the index at build time.

**Transport does something now, and what it does is trivial.** 908 attempts along the top
rows: 186 images already exist, 12 are open, 710 refused (`ScopedRow`/`NoMatch`). Every
existing image is a positivity lemma — the row `mass_pos ~ ξ_pos` transports `k_pos` to
`k_pos`. The operation is alive (§24 reported it never producing anything, and §5's `seal`
fix is visibly in effect) and it is being fed rows with no content.

**`normalize_arity` is inert on this corpus** (exploratory, not pre-registered). §46 records
that the arity transform was worth eight dictionary rows on B7's Z~FF pair *in simulation*
and that the shipped knob is not that transform. Measured here at the conclusion anchor:
`ClassicalInfo ~ Entropy` gives 14 rows with the knob off and 14 with it on, with the same
three rows on top; `ClassicalMechanics ~ QuantumMechanics` gives 126 either way, likewise
identical. In `similar` it only ever *reduces* the candidate set — `Hₛ_nonneg` goes from 15
root-anchored candidates to 1 — and it promotes no true partner at any setting. It is not
the knob that rescues a physics correspondence.

**Cross-theory `similar` hit rates, floors at the bottom, 60 queries per theory.** The
conclusion anchor beats the root in 9 of the 10 theory pairs — 20/60 against 12/60 for
`ClassicalMechanics → QuantumMechanics`, 15/60 against 4/60 for `ClassicalInfo → Entropy`.
The negative control `ClassicalMechanics → Meta` scores 10/60, i.e. within noise of the real
pairs, which is §8's NC3 finding at the level of the retrieval layer rather than the
dictionary.

## 10. Verdicts against the pre-registration

Each verdict names the arm it rests on. P1, P2 and P4 rest on `generalize`, which §5 shows
and §5's table measures to be independent of the corpus around it, so they hold on both arms
by construction; P3 and the dictionary counts are closure-dependent and are re-run on the
closed arm in §11.

| prediction | verdict |
|---|---|
| **P1** — a genuine E1–E15 row in the mechanics dictionary's top 20 | **FAIL.** 0 of 25 rows at any of six settings; the exhaustive ablation's top 400 is also 100% artifacts. |
| **P2** — conclusion anchor beats root for cross-theory | **PASS, strongly.** 16/18 targeted pairs are ≤ 0.13 at root; four reach 0.70–0.89 at conclusion. Dictionary rows: 0 → 14 (ClassicalInfo~Entropy), 0 → 1 (~Channels), 69 → 126 (CM~QM). Cross-theory `similar` hit rates rise in 9 of 10 pairs. Independent replication of §46 on a corpus that shares nothing with RH. |
| **P3** — the null, with an informativeness verdict | **Reported.** The *engine's* null is dead where the dictionary it silently re-derives is empty (0.000 vs 0.000). This script's null is alive everywhere and worthless as a quality signal: it separates `ClassicalMechanics ~ Meta` at 0.821 vs 0.255. |
| **P4** — information easier than mechanics | **PASS, in the strong form.** Information: retention 0.70–0.89 against nulls 0.04–0.10, and the top exhaustive rows are the pre-registered ones. Mechanics: every genuine pair ≤ 0.074, indistinguishable from its null. |
| **P5** — the bracket/evolution family appears in `missing_*` | **UNTESTABLE.** §3: physlib has no Poisson bracket, no symplectic form and no Liouville equation, so E1/E6/E9/E13/E15 have no classical side to be missing. |
| **P6** — registered mid-run in §7; the dilution curve reaches 0/4 on a closed half-corpus | **PASS.** §11: 3, 3, 1, 0, 0 targets at 347 / 1,347 / 5,347 / 20,347 / 81,200 declarations, on a 99.46%-closed corpus. |

**The headline.** On the mechanics axis the answer is no: the Atlas does not recover the
classical ↔ quantum dictionary, and the exhaustive control shows this is not a retrieval
failure but an absence of shared structure after erasure. On the information axis the answer
is yes and the engine does not deliver it: `Hₛ_nonneg ~ Sᵥₙ_nonneg`, `Hₛ_le_log_d ~
Sᵥₙ_le_log_d`, `Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero` and `Hₛ_uniform ~ Sᵥₙ_le_log_d` are
all above 0.62 retention conclusion-anchored, all pre-registered before the run, and all
missing from the shipped dictionary because the prefilter drops the postings that carry them.

One row survives end to end — `ProbDistribution.normalized ~ Ket.normalized`, rank 1 in
`similar`, row 5 in the dictionary, E5/E20 — which is the existence proof that the pipeline
*can* deliver a genuine cross-theory correspondence, and the measure of how rarely it does.

## 11. The closed arm

The extraction this run was waiting on — `lake exe atlas_extract Physlib QuantumInfo`, the
full import closure — **did not finish**: killed at 51 minutes with 818,835 constants
imported, `EXIT=143`, and zero bytes written, because the extractor buffers its rows and
emits them at the end. That is worth recording on its own: a 51-minute extraction that is
terminated produces nothing at all, so the natural unit of work is "extract once, keep the
file", and any harness that time-boxes it should expect no partial output.

What was available instead is `/tmp/pc-physclosed.jsonl` — physlib plus the Mathlib
declarations its statements reach, 95,268 rows, built by a parallel session. It clears the
gate:

| | defective arm | closed arm |
|---|---|---|
| declarations | 14,563 | **95,268** |
| application heads | 19,354,368 | 51,394,099 |
| missing heads | 16,957,114 | 279,958 |
| **closure** | **12.39%** | **99.46%** |
| worst missing | `Eq` (7,639), `Nat` (7,119), `OfNat.ofNat` (6,739) | `PiLp.innerProductSpace._proof_1` (826), `Physlib.Distribution._proof_1` (208) |

The two miss-profiles are the ones §32 uses to tell a closure from a `--local` slice: the
defective arm is missing *the language*, the closed arm is missing auto-generated proof
terms that head no statement.

**NC2 confirms the closure is doing work.** Erasure liveness over 400 statements:

| | defective arm | closed arm |
|---|---|---|
| `carriers` ≠ `presentation` | 386 / 400 | 390 / 400 |
| `instances` ≠ `presentation` | **255 / 400** | **325 / 400** |

`carriers` barely moves, because holing type binders needs no signature lookup. `instances`
moves by 70 statements — 27% more — because that erasure asks the corpus for a head
constant's `InstImplicit` positions and on the defective arm the constant is usually absent.
This is §31's silent degradation, visible as a number rather than as an argument, and it is
also why NC2 alone is *not* a closure check: it fires happily on a 12.39%-closed corpus.

### What the closed arm changes about the conclusions, and what it cannot

**Nothing in §6 or §7's headline moves, and this is provable rather than hopeful.**
`generalize` reads two parsed statements and calls `lgg`; no signature lookup, no erasure,
no corpus. §5's table measures it: the same four pre-registered pairs return identical
retentions to four decimals on a 347-row 0.85%-closed slice and on the 14,563-row
12.39%-closed one. The closed arm is a third point on that line, not a new experiment.

So the two claims the report rests on — *the classical ↔ quantum information
correspondences are visible to the anti-unifier at the conclusion anchor*, and *the
mechanics ones are not* — are closure-independent facts about physlib's statements.

Measured rather than asserted: §7's exhaustive ablation, re-run on the 99.46%-closed corpus,
reproduces the defective arm exactly.

| exhaustive, conclusion anchor | defective arm (12.39%) | closed arm (99.46%) |
|---|---|---|
| ClassicalInfo ~ Entropy | 273 rows, 37L / 44R | **273 rows, 37L / 44R** |
| ClassicalInfo ~ States | 540 rows, 56L / 101R | **540 rows, 56L / 101R** |
| ClassicalMechanics ~ QuantumMechanics | 2,629 rows, 133L / 161R | **2,629 rows, 133L / 161R** |

Same counts, same top rows, same retentions to three decimals — `Hₛ_nonneg ~ Sᵥₙ_nonneg` at
0.889, `Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero` at 0.818, `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` at
0.697. The only thing that changed is the wall clock: 59.9 s against 0.2 s, because the
arena now holds Mathlib as well.

### P6: the dilution curve, re-run on the closed corpus — **confirmed**

Same protocol as §7, same two theories, but the declarations added around them are now
physics *and Mathlib*, drawn from the 99.46%-closed slice:

| declarations | `max_len` | dictionary rows | targets found | top row |
|---|---|---|---|---|
| 347 | 50 | 37 | **3 / 4** | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 1,347 | 50 | 31 | **3 / 4** | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 5,347 | 50 | 18 | 1 / 4 | `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` |
| 20,347 | 50 | 12 | **0 / 4** | `Prob.negLog_ne_top ~ sandwichedRelEntropy_ne_top` |
| 81,200 | 81 | 12 | **0 / 4** | `Prob.negLog_ne_top ~ qRelativeEnt_ne_top` |

P6 said 0 / 4 above the first arm and gave a reason. The measured curve is 3, 3, 1, 0, 0 —
the prediction holds from 20,347 declarations on, and the approach to it is monotone. Two
further details are worth the ink:

* the 347-declaration arm cut from the **closed** corpus returns the same 37 rows and the
  same 3 / 4 targets as the arm cut from the defective one, which is closure-independence
  showing up in a closure-*dependent* query, because at that size no key is over the cap;
* `max_len` rises to 81 at the largest arm and buys nothing, because the holders of a
  common key grow with the corpus far faster than 0.1% of it does. The cap is not
  mis-tuned; it is the wrong shape of rule for this query.

So the defect is not an artifact of the unclosed slice, and it does not soften on a real
corpus. Laid side by side, the two curves are the same curve:

| declarations | physlib-only (12.39% closed) | physics + Mathlib (99.46% closed) |
|---|---|---|
| ~350 | 3 / 4 | 3 / 4 |
| ~1,300 | 1 / 4 | 3 / 4 |
| ~5,300 | 1 / 4 | 1 / 4 |
| 14,563 / 20,347 | 0 / 4 | 0 / 4 |
| — / 81,200 | — | 0 / 4 |

The response tracks **size**, not composition — the closed arm even holds 3 / 4 a little
longer at ~1,300, because a random sample of Mathlib contains proportionally fewer
`0 ≤ …`-shaped statements than physlib's positivity-heavy rows do. Whatever a reader wants
to conclude about closure, this defect is not about it.

**And the closed arm is where §8's dictionary numbers should be re-taken.** They are not:
§8 is the defective arm, labelled as such. The reason to expect them to get *worse* rather
than better is the same mechanism — a bigger corpus drops more keys — which is a prediction,
not a result, and is written here so that whoever runs it can score it.

## 12. Specification for the engine changes this run argues for

Specs, not implementations. Each names the defect it repairs, the measurement that
demonstrates it, and the gate that must ship with it. Ordered by measured payoff.

### S1. An exhaustive path for small theory pairs — `DictOptions::exhaustive`

**Defect.** `SkeletonIndex::build` drops a posting list longer than `max(0.001·N, 50)`
(`index.rs`, `max_len`), and `candidates` skips a shape bucket above `max_bucket = 600`.
Both are correct for "what looks like this declaration" over a whole corpus and both remove
exactly the keys a cross-theory dictionary needs: two theories stating the same idea in
generic mathematics share *common* structure, not rare structure.

**Measured.** `ClassicalInfo ~ Entropy`, conclusion anchor, engine floors: shipped
dictionary 14 rows over 8 lefts; exhaustive 273 rows over 37 lefts; the top twelve
exhaustive rows include four pre-registered correspondences and the shipped dictionary
contains none of them. Cost: 218,348 anti-unifications in 20 s **through the Python
binding**, single-threaded.

**And the controlled version.** §7's dilution table: the same query on the same two theories
returns 3 of 4 pre-registered rows in a 347-declaration corpus and 0 of 4 in a 14,563-
declaration one, monotonically, with the two theories byte-identical throughout. The cap is
corpus-wide while the query is theory-restricted, so declarations that cannot be candidates
still delete rows. Whatever else changes, **`max_len` must be computed over the retrieval
scope, not over the corpus** — when `restrict_prefix` is set, a key's document frequency
should be counted inside the restriction.

**Spec.**

```rust
pub enum Exhaustive { Never, WhenSmall { max_pairs: usize }, Always }
// DictOptions::exhaustive, default WhenSmall { max_pairs: 250_000 }
```

When the mode fires, `dictionary` skips `idx.similar` entirely and anti-unifies every
`(left, right)` at `cfg.lgg_level`, keeping rows that clear `min_common` and
`min_retention` — the same floors, the same scorer, the same `per_decl`/`max_per_right`
selection afterwards. Parallelise over lefts; the arena is read-only in this path except for
interning, which is why this is a spec and not a patch.

`Dictionary` gains `generation: "prefilter" | "exhaustive"`, because a row count that can
come from two candidate generators is not comparable to itself across versions.

**Rows from this path must go through `Row::score`, not through retention.** The ablation
above ranked by retention because `generalize` returns no score, and its own control shows
what that costs: the pre-registered nonsense pairs have a *higher* above-floor density than
the real one (5.15% against 1.74%) and their top 25 rows are 25/25 constructor-injectivity
lemmas. The exhaustive path buys recall and buys artifacts with it; the derivativeness
penalty already in the scorer is what tells them apart, and it must be applied here or S1
ships a worse dictionary that is merely larger.

**Gate.** A differential on a physlib slice that asserts *both* halves: the exhaustive path
returns `Hₛ_nonneg ~ Sᵥₙ_nonneg`, and the prefiltered path does not. It fails if either
changes, which is what makes it a measurement rather than a smoke test.

### S2. A theory must be nameable, and an empty one must raise

**Defect.** `dict::theory_of` is `depth 2 under Mathlib, depth 1 elsewhere`. Every physlib
declaration is therefore in theory `Physlib`, and `dictionary("ClassicalMechanics", …)`
returns an empty `Dictionary` — no rows, no error. So does the apparently-correct
`dictionary("Physlib.ClassicalMechanics", "Physlib.QuantumMechanics")`, because the
candidate filter compares `theory_of(module)` to the full prefix. Both read as "these
theories have nothing in common".

**Spec.**

```rust
pub enum TheorySpec { Depth(usize), Prefix }   // Prefix: m == p || m.starts_with(&(p + "."))
```

threaded through `dictionary`, `frontier` and `similar`'s cross-theory boost so all three
agree on what "cross-theory" means, as the current comment already promises. Default
`Depth`-as-today. In Python: `theory: Literal["depth", "prefix"] = "depth"`.

**And the loud failure**: `dictionary` raises `UnknownTheory(name)` when a side selects zero
declarations, `frontier` likewise for an `exclude` entry matching nothing. A query that
cannot be satisfied must not return the same value as a query that was satisfied and found
nothing — that distinction is the entire content of `missing_left`.

**Gate.** On a physlib slice: `dictionary("Physlib.ClassicalMechanics", …)` raises under
`Depth`, returns rows under `Prefix`, and the row set equals the one obtained from the
module-root rewrite this script performs.

### S3. The diagnostics must describe the dictionary that was asked for

**Defect.** `dictionary_coherence`, `dictionary_policies` and `dictionary_shuffle_control`
each rebuild a dictionary with `IndexConfig::default()` — root anchor, retention scorer, no
cap — and report on *that*, whatever the caller asked `dictionary` for.

**Measured.** `Mathlib.Control ~ Mathlib.Logic`, conclusion anchor: `dictionary` returns 20
rows; `dictionary_coherence` reports 0 rows and `dictionary_shuffle_control` reports genuine
0.000 against shuffled 0.000. §46 recorded that dead control on RH without naming this as a
cause.

**Spec.** `Corpus.dictionary(...)` returns a handle carrying its own `DictOptions` and
`IndexConfig`, with `.coherence(worst=6)`, `.policies()` and `.shuffle_control()` on it. The
free functions stay for the CLI, taking the full option set. It must not be possible to
describe a dictionary other than the one in hand.

### S4. A null that can say it learned nothing

**Defect.** `ShuffleControl` reports four numbers and no verdict, so "genuine 0.000 against
shuffled 0.000" and "genuine 0.95 against shuffled 0.08" are the same shape of answer.
Worse, the single arm draws alternates from the matched rights, which is the conservative
pool; on this corpus the two pools differ by up to 0.5 in mean.

**Spec.** `ShuffleControl` gains: `matched` and `broad` arms, each with mean/separation;
`verdict: Dead | Uninformative | Informative`, where `Dead` is both means below a stated
epsilon and `Uninformative` is the arms within it of each other; and `anchor`/`scorer` fields
so a stored control cannot be read against a different configuration.

**And a warning in its own doc comment**, because this run measured the limit of the
instrument: `ClassicalMechanics ~ Meta` — physics against an HTML note utility — separates
0.821 against 0.255. A live null is not evidence of a good dictionary. `dictionary_coherence`
plus a negative *theory pair* is what discriminates; the null only rejects the hypothesis
that the pairing is random.

### S5. `similar_brute` must take an anchor

**Defect.** It is the differential reference for `similar`, and `similar` takes an anchor it
does not. Every cross-theory result in this project rides on the conclusion anchor (§46, and
§6 here), so the reference cannot check the configuration that matters.

**Measured.** For all 18 targeted pairs the brute reference is uninformative: root-anchored,
where 16 of 18 pairs anti-unify below 0.13 and there is nothing to rank.

**Spec.** `similar_brute(name, top, level, anchor="root")`, and the recall-loss split it
underwrites (§5 of `CLAUDE.md`) re-measured at both anchors.

### S6. `similar` should expose `restrict_prefix`

`dictionary` already uses it internally and its own comment explains why filtering after
retrieval loses rows the budget never reached. A research script cannot ask "the nearest
neighbours of X inside theory Y" and must over-fetch and filter — the exact recall loss the
field exists to prevent. Add `restrict_prefix: str | None = None` to `Corpus.similar`,
`fh mcp`'s tool list and the `.pyi`.

### S7. `motifs` and `frontier` inherit S1's blind spot and should say so

**Measured.** `frontier` puts `ClassicalInfo ~ Entropy` at similarity **0.000** with excess
−0.026, and `motifs` finds **zero** sub-patterns spanning any two of the ten named theories —
on a corpus where the exhaustive path finds 273 above-floor pairs in that one theory pair.
Both read their answer off the posting lists S1 shows are pruned.

Minimum: a sentence in each doc comment saying the answer is bounded by what the index
retained. Better: `frontier` computes similarity from the exhaustive path when both theories
are under the `WhenSmall` bound, which is the regime physics corpora live in.

### What this run does **not** argue for changing

The erasure and the anti-unifier are not implicated. The mechanics negative survives the
removal of every filter: 218,348 pairs anti-unified exhaustively at the conclusion anchor
produce 2,629 rows above the floors and not one physical correspondence among the top 400.
A classical Hamiltonian is a function on a Euclidean configuration space and a quantum one is
an unbounded operator on `L²`; after erasure to carriers they still share nothing but
punctuation. No knob in this engine reaches that, and the honest form of the result is that
**the classical ↔ quantum correspondence is not a structural fact about these two
formalisations** — it is a fact about the limit ħ → 0, which no anti-unifier can see.

## 13. Reproducing this

```sh
# the defective arm (12.39% closed) — every number in §6–§10
uv run scripts/phys-classical-quantum.py --slice /tmp/fh-physlib.jsonl \
    --prepared /tmp/phys-cq-theories-unclosed.jsonl --allow-unclosed \
    --stages gates,targeted,dict,similar,classes,motifs,transport,frontier \
    --out /tmp/phys-cq-unclosed-full.json

# the two results that do not depend on closure (§5 proves this, §5's table measures it)
uv run scripts/phys-classical-quantum.py --slice /tmp/fh-physlib.jsonl \
    --prepared /tmp/phys-cq-theories-unclosed.jsonl --allow-unclosed \
    --stages exhaustive --exh-anchors conclusion \
    --pair ClassicalInfo:Entropy --pair ClassicalInfo:States

# the dilution curve (§7) — one variable, the surrounding corpus
uv run scripts/phys-classical-quantum.py --slice /tmp/fh-physlib.jsonl \
    --prepared /tmp/phys-cq-theories-unclosed.jsonl --allow-unclosed --stages dilution \
    --dilute-sizes 0,150,400,900,2000,5000,14216 --pair ClassicalInfo:Entropy

# a closed corpus (§11): any physlib slice that clears `Corpus.closure()` at 95%.
# Without --allow-unclosed the script aborts rather than reporting, which is the point.
uv run scripts/phys-classical-quantum.py --slice <closed physlib slice> \
    --stages census,gates,targeted,exhaustive,dilution,dict
```

Raw output for every run quoted above is in `/tmp/phys-cq-*.json`, each stamped with the
slice it came from and, where applicable, `"defective_arm": true`.
