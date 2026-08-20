# FH Quantum Corpus: Twelve Groups for the Physics Cluster

**Status:** Draft 0.1 · Sibling to the math stress corpus; seeds the physics-side Atlas clusters and the quantum contribution program.
**Bridge targets:** Mathlib (inner product spaces, spectral theory, matrix analysis, PMF, the CHSH inequality), physlib/Lean-QuantumInfo (states, channels, teleportation), LeanQuantum (gates, Pauli operators, stabilizer codes), Lean-QIT (operational QIT layer). Bridge aliases for all four go in `Bridge/quantum.rs`.
**Conventions fixed here:** inner products are conjugate-linear in the *first* argument (Mathlib's convention, which is also the physicist's ⟨ψ|φ⟩); adjoint is the ASCII method `.dag()` (F19); tensor product is `.tensor()` at term level, `Tensor<H1, H2>` at type level (F19); indexed operator families use `Fin`-indexed functions, not subscripts (F20): `pauli(i)` for σᵢ. Unicode remains a v2 opt-in per F16. `#[rigor(...)]` and `#[units(...)]` attributes are reserved for the physics metadata channel (F21) but unused in this finite-dimensional corpus — everything below is `rigor(rigorous)` by construction, which is precisely why quantum *information* is the right first physics cluster: it's the corner of physics that is secretly finite-dimensional linear algebra.

Ambient declarations shared by most groups (per-file in practice):

```rust
var H: HilbertSpace;              // trait annotation: (H : Type*) [complex inner product space, complete]
var K: HilbertSpace;
var d: Nat;                       // dimension where finiteness matters
```

---

## Q1 — Hilbert space basics (imports; pipeline calibration)

```rust
theorem cauchy_schwarz(x: H, y: H) -> (inner(x, y).abs().pow(2) <= inner(x, x).re * inner(y, y).re) {
    lean! { exact inner_mul_le_norm_sq ... }   // Mathlib import; exact name via Bridge
}

fn orthonormal<I: Space>(v: I -> H) -> Prop {
    for<i: I, j: I> inner(v(i), v(j)) == (if i == j { 1 } else { 0 } as Complex)
}
```

Stresses: complex inner products through the Bridge, `if` in term position under F14 (Decidable Eq on the index), coercion of numeric literals into ℂ (F9). Everything here exists in Mathlib; Q1 failing means the Bridge is broken, nothing deeper.

## Q2 — Observables and spectra (the Atlas V2 seed, physics side)

```rust
fn observable(A: H -> H) -> Prop { is_linear(A) && A.dag() == A }

theorem eigenvalues_real(A: H -> H, h: observable(A), c: Complex, v: H,
                         hv: v != 0, he: A.apply(v) == c * v)
    -> c.im == 0
{
    // the two-line proof: c⟨v,v⟩ = ⟨Av,v⟩ = ⟨v,Av⟩ = c̄⟨v,v⟩
    todo!()
}

theorem spectral_decomposition<const n: Nat>(A: Matrix<n, n, Complex>, h: A.dag() == A)
    -> exists<U: Matrix<n, n, Complex>, D: Matrix<n, n, Real>>
        (U.unitary() && A == U * (D.map(|r| r as Complex)) * U.dag())
{
    lean! { exact ... }   // Mathlib's spectral theorem, via Bridge
}
```

This group is deliberately the *same statements* the math corpus reaches via Group 2/5 — the physics-side anchor of the Hilbert–Pólya skeleton. The Atlas physics benchmark inherits it: `atlas similar` from here must reach the RH cluster.

## Q3 — Pauli algebra (finite, decidable, the `decide` showcase)

```rust
fn pauli(i: Fin<3>) -> Matrix<2, 2, Complex>;   // σ₁, σ₂, σ₃ by cases; F20 style

theorem pauli_involutive(i: Fin<3>) -> pauli(i) * pauli(i) == Matrix::id() {
    lean! { fin_cases i <;> decide }             // wait — ℂ isn't decidable...
}
```

...and that comment is the group's real payload, left in deliberately: naive `decide` fails over ℂ. The corpus must pin the working pattern (normalize entries over a decidable subring — Gaussian rationals `ℤ[i]`-with-halves suffice for Clifford-adjacent computation — or `native_decide` with its axiom cost flagged per the anti-cheat protocol, or `simp` with matrix-entry lemmas). Whichever pattern lands becomes the template for every finite verification below (Q7, Q11), which is why this group exists. Also stresses: commutator/anticommutator as Bridge notation (`comm(A, B)` = AB − BA).

## Q4 — Unitary dynamics

```rust
theorem evolution_unitary<const n: Nat>(Hm: Matrix<n, n, Complex>, h: Hm.dag() == Hm, t: Real)
    -> (Complex::I * (t as Complex) * Hm).neg().exp().unitary()
{
    todo!()
}

theorem heisenberg_equivalent<const n: Nat>(Hm: ..., A: ..., psi: ..., t: Real)
    -> expectation(schrodinger_evolve(Hm, t, psi), A)
        == expectation(psi, heisenberg_evolve(Hm, t, A))
{
    todo!()
}
```

Schrödinger ↔ Heisenberg picture equivalence is a tiny *duality* — a warm-up dictionary row inside one theory (state-evolution ↔ operator-evolution), and a deliberately easy `atlas dictionary` test case. Matrix exponential exists in Mathlib; this group stresses the Bridge's analysis edge.

## Q5 — Uncertainty (CONTRIBUTION TARGET: Robertson)

```rust
theorem robertson<const n: Nat>(A: ..., B: ..., ha: observable(A), hb: observable(B), psi: unit_vector)
    -> stddev(psi, A) * stddev(psi, B) >= (expectation(psi, comm(A, B)).abs()) / 2
{
    todo!()   // Cauchy-Schwarz + a decomposition into commutator and anticommutator parts
}
```

The Robertson uncertainty relation is a page of inner-product algebra sitting directly on Mathlib's Cauchy–Schwarz — short, famous, and (to be verified at step 0) apparently unformalized in Lean. Prime first-contribution material: self-contained, reviewable, and every quantum library would want to import it.

## Q6 — Tensor products and entanglement

```rust
fn product_state(psi: Tensor<H, K>) -> Prop {
    exists<a: H, b: K> psi == a.tensor(b)
}
fn entangled(psi: Tensor<H, K>) -> Prop { !product_state(psi) }

theorem bell_state_entangled() -> entangled(bell00()) {
    todo!()   // rank argument on the coefficient matrix
}

theorem schmidt_decomposition(...) -> exists<...> ... { todo!() }   // statement-level; SVD via Bridge
```

Stresses: `Tensor<H, K>` as a Bridge alias for Mathlib's tensor product of Hilbert spaces (the genuinely fiddly Bridge entry in this corpus — finite-dimensional instances only at first), negated existentials, and Schmidt-as-SVD.

## Q7 — Nonlocality (import + CONTRIBUTION TARGET: Mermin–GHZ)

```rust
theorem tsirelson(...) -> ... { lean! { exact ... } }   // Mathlib has CHSH/Tsirelson in C*-algebra form; Bridge import

theorem mermin_ghz() ->
    // the four GHZ correlation constraints admit no deterministic local assignment
    !exists<a: Bool, a2: Bool, b: Bool, b2: Bool, c: Bool, c2: Bool> (ghz_constraints(...))
{
    lean! { decide }   // 64 cases; the parity contradiction is a finite check
}
```

The GHZ/Mermin paradox is nonlocality *without inequalities* — a finite parity contradiction, hence a pure `decide` (over `Bool`, no Q3 caveats). If unformalized (verify at step 0), it's a two-afternoon contribution and the corpus's cleanest showcase of the falsification arm's machinery running in *proof* direction.

## Q8 — The no-go pair (CONTRIBUTION TARGETS: no-cloning, no-communication)

```rust
theorem no_cloning<const n: Nat> where (n >= 2)
    -> !exists<U: Matrix<..>> (U.unitary() &&
        for<psi: unit_vector> U.apply(psi.tensor(blank())) == psi.tensor(psi))
{
    todo!()   // linearity vs. the quadratic map ψ ↦ ψ⊗ψ; inner-product two-liner
}

theorem no_communication(...)
    -> partial_trace_b(apply_local_b(rho, U)) == partial_trace_b(rho)
{
    todo!()   // trace cyclicity + locality of U
}
```

Both proofs are short once density-operator plumbing exists (Lean-QuantumInfo/physlib supply it); both are *famous*; neither surfaced in any current library's advertised contents. The pair also matters for the Atlas: no-cloning's skeleton ("no structure-preserving map duplicates arbitrary elements") is a genuinely interesting cross-theory probe — its rhymes and non-rhymes with classical copying and with comonoid structures are exactly the kind of output `atlas similar` should be judged on.

## Q9 — States and channels (the Lean-QIT bridge)

```rust
fn density_op<const n: Nat>(rho: Matrix<n, n, Complex>) -> Prop {
    rho.dag() == rho && rho.pos_semidef() && rho.trace() == 1
}

fn cptp(E: ...) -> Prop { ... }
theorem kraus_representation(...) -> (cptp(E) <-> exists<...> ...) { todo!() }   // statement; Stinespring finite-dim
```

Bridge group for the operational layer: density operators, partial trace, CPTP, Kraus/Stinespring (finite-dimensional). Mostly imports-or-statements; its role is aligning FH names with Lean-QIT's interfaces so the capacity-theorem target (see contributions) has a surface to land on.

## Q10 — Measurement as a PMF (the Born rule, closing the loop with math Group 10)

```rust
fn measure<const n: Nat>(psi: unit_vector, basis: OrthonormalBasis<n>) -> PMF<Fin<n>>;
// Born rule: (measure(psi, basis)).prob(i) == inner(basis(i), psi).abs().pow(2)

fn two_measurements(psi: ...) -> PMF<(Fin<n>, Fin<n>)> {
    let i = measure(psi, basis)?;
    let j = measure(collapse(psi, basis, i), basis)?;
    PMF::pure((i, j))
}

theorem repeat_measurement(psi: ..., i: Fin<n>) -> // second outcome equals first w.p. 1
    ... { todo!() }
```

Quantum measurement in the `?`-monad: the Born rule lands in the same `PMF` the math corpus's probability group used, so measurement protocols read as Rust and elaborate as distributions. Stresses do-notation with dependent intermediate states (`collapse` needs the outcome — a genuine dependency inside a do-block, the hardest `?` case in either corpus).

## Q11 — Stabilizers and error correction (LeanQuantum bridge + CONTRIBUTION TARGET: general Knill–Laflamme)

```rust
theorem bitflip_corrects(...) -> ... { lean! { ... } }   // exists in LeanQuantum; Bridge import

theorem knill_laflamme<const n: Nat, const k: Nat>(C: Subspace<...>, E: ErrorSet<...>)
    -> (correctable(C, E) <-> for<a, b: E.ops> (project(C) * a.dag() * b * project(C)
                                                == (kl_coeff(a, b) as Complex) * project(C)))
{
    todo!()
}
```

Specific codes are formalized (bit-flip, Shor-9 in LeanQuantum; industrial distance certificates in Lean-QEC); the *general* Knill–Laflamme error-correction conditions — the iff characterizing correctability — appear (verify at step 0) not to be, and they're the theorem every one of those libraries would retroactively want under their specific instances. Medium effort, foundational payoff, and a perfect `atlas home` demo once done: every concrete code-correctness proof should be rediscoverable as an instance.

## Q12 — The harmonic oscillator (statement-level; the most-reused skeleton in science)

```rust
#[rigor(rigorous)]  // in the ℓ² model; the differential-operator model would be conditional
mod oscillator {
    fn a() -> LadderOp;     fn adag() -> LadderOp;
    theorem ccr() -> comm(a(), adag()) == LadderOp::id() { todo!() }
    theorem spectrum_shape(n: Nat) -> ... // eigenvalues n + 1/2, statement-level
}
```

Infinite-dimensional, so this group is statements-first (the ℓ² ladder model keeps it honest). It's here for the Atlas: the oscillator skeleton is the one that must later match across QFT modes, phonons, coherent states — the ubiquity benchmark of the physics validation suite.

---

## Findings ledger (additions)

**F19:** `.dag()` (adjoint) and `.tensor()` / `Tensor<,>` as ASCII-canonical quantum notation; inner-product convention pinned to Mathlib's conjugate-linear-first (= physics ⟨·|·⟩). **F20:** indexed operator families via `Fin`-indexed functions, never subscript sugar. **F21:** `#[rigor(...)]` and `#[units(...)]` reserved as physics metadata attributes feeding the Atlas channels; unused in this corpus (all-finite, all-rigorous) by design. **F22 (from Q3):** `decide` over ℂ is not a thing; the corpus must establish and pin the decidable-subring / `native_decide` / `simp`-normal-form pattern for finite matrix verification, and that pattern is a deliverable, not a footnote.

## Contribution shortlist embedded above

Q5 Robertson uncertainty (short, Mathlib-ready, famous). Q7 Mermin–GHZ (finite parity `decide`, two afternoons). Q8 no-cloning + no-communication (short proofs, glaring absences, high import value). Q11 general Knill–Laflamme (medium, foundational — the theorem under everyone's instances). Q9-adjacent stretch: a first *complete coding theorem* on Lean-QIT's fresh operational layer — the quantum erasure channel's capacity is the cleanest candidate (exactly computable, finite-dimensional techniques). Every target carries the standing caveat: re-verify absence at step 0 — four libraries in this space shipped or merged within the last year, and one of them is three weeks old.
