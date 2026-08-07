# Engine 2 — Certified Positivity

**Status:** Implementation plan, draft 0.1  
**Scientific role:** Convert floating-point optimization and quadratic-form evidence into exact, kernel-checked bounds and exclusions  
**First consumer:** [Campaign C](../campaigns/C-certified-bell-bootstrap.md)

## 1. Objective

Build a reusable proof-producing pipeline for scientific problems whose final claim follows from positivity:

- positive semidefinite matrices;
- sums of squares;
- moment and Gram matrices;
- dual feasible points of convex programs;
- nonnegative quadratic or integral forms;
- operator inequalities;
- spectral positivity.

The exploratory solver remains untrusted. The scientific artifact is a compact exact or interval certificate checked by a small Lean kernel.

## 2. Scientific reach

Initial and future consumers include:

- NPA bounds for Bell inequalities and nonlocal games;
- quantum-mechanical and conformal bootstrap exclusions;
- hydrodynamic and MHD energy stability;
- background-method and SOS turbulence bounds;
- RDM/N-representability lower bounds in quantum chemistry;
- photonic passivity and causality bounds;
- Cohn–Elkies packing bounds;
- EFT and scattering-amplitude positivity constraints;
- finite moment problems and polynomial nonnegativity.

The engine's research value comes from amortization: the same checker and reconstruction discipline supports fields that currently use unrelated floating-point codes.

## 3. Non-goals

- Do not verify an entire SDP solver.
- Do not claim exact optimality when only feasibility and a one-sided bound are certified.
- Do not force rational reconstruction where an interval certificate is the honest representation.
- Do not begin with full conformal-bootstrap scale.
- Do not hide conditioning, facial reduction, or truncation assumptions.

## 4. Mathematical certificate forms

### Exact PSD by LDLᵀ

For a rational symmetric matrix `M`, provide `L`, diagonal `D`, and a permutation `P` such that:

```text
P M Pᵀ = L D Lᵀ
D_ii ≥ 0
```

The Lean checker verifies dimensions, exact equality, and nonnegative diagonal entries.

### Gram and SOS certificate

Represent a polynomial or quadratic expression as:

```text
p(x) = v(x)ᵀ Q v(x) + constraint combinations
Q ⪧0 0
```

The checker verifies the polynomial identity and the PSD certificate for `Q`.

### Convex dual certificate

For a primal bound, import a dual feasible point and verify:

- exact linear constraints;
- cone membership;
- objective value;
- weak duality theorem connecting feasibility to the claimed bound.

Strong duality is unnecessary for a certified one-sided result unless exact optimality is claimed.

### Interval PSD certificate

When coefficients are irrational or reconstruction is unstable, use interval matrices plus a theorem such as:

- verified lower eigenvalue bound;
- interval Cholesky with positive pivots;
- diagonal dominance after an exact basis transformation;
- residual norm bounded below the spectral margin.

### Symmetry-reduced certificate

The search problem may be block-diagonalized using group symmetry. The artifact must include or cite a proof that reconstruction from blocks implies positivity of the original object.

## 5. Architecture

```text
domain problem
    │
    ▼
problem compiler ──► floating solver
    │                     │
    │                     ▼
    │              approximate primal/dual
    │                     │
    ▼                     ▼
exact schema ◄── rational/interval reconstruction
    │
    ▼
independent Rust/Python pre-check
    │
    ▼
Lean certificate checker
    │
    ▼
domain theorem: feasibility implies scientific bound
```

The domain compiler, numerical solver, and reconstruction algorithm are outside the trusted base. The schema, Lean checker, and domain soundness theorem are inside it.

## 6. Shared types

### Scalars

- arbitrary-precision integers and rationals;
- algebraic numbers where a minimal polynomial and isolating interval are supplied;
- outward-rounded intervals;
- explicit conversion records from decimal/solver formats.

### Matrices

- dense rational matrix for prototypes;
- sparse coordinate matrix for real problems;
- block matrix with symmetry labels;
- interval matrix;
- exact dimension and index types in Lean;
- canonical serialization and content hash.

### Certificate envelope

```text
schema version
problem kind
statement hash
matrix/polynomial hashes
solver provenance
reconstruction settings
exact or interval payload
claimed objective enclosure
pre-check report
Lean checker and theorem names
```

## 7. Components

### P1. Exact arithmetic bridge

- Python `Fraction` and Rust rational interoperability.
- Canonical sparse/dense matrix serialization.
- Strict refusal of silent float conversion.
- Lossy `to_numpy` explicitly marked visualization-only.
- Hash-stable ordering and normalization.

### P2. Small Lean checker library

- rational matrix operations;
- symmetric/Hermitian predicates;
- exact matrix multiplication checks;
- LDLᵀ certificate theorem;
- block-diagonal composition;
- weak-duality lemmas;
- polynomial identity normalization;
- finite sum/index helpers.

Keep checker definitions computational and extraction-friendly.

### P3. Reconstruction toolkit

- entrywise continued fractions;
- common-denominator recovery;
- affine-constraint projection;
- nullspace-aware reconstruction;
- PSD-margin estimation;
- exact repair of linear residuals;
- interval fallback;
- diagnostic classification for failed reconstruction.

Reconstruction outputs a report identifying:

- constraint residuals before and after repair;
- smallest numerical eigenvalue;
- denominator growth;
- exact PSD result;
- reason for rejection.

### P4. Solver adapters

Begin with one open solver and a plain interchange format. Adapters normalize:

- primal/dual variable ordering;
- constraint signs;
- cone block layout;
- objective convention;
- solver tolerances and status.

Never parse human log text as the scientific interface.

### P5. Domain compilers

First compilers:

1. NPA level-1/level-1+AB moment problems.
2. Finite quantum-mechanical moment bootstrap.
3. Generic rational quadratic-form positivity.

Later:

- polynomial SOS;
- RDM constraints;
- background-method turbulence;
- photonic dual bounds;
- conformal bootstrap blocks with interval-controlled transcendental data.

### P6. Artifact and oracle path

- Independent numerical reevaluation of the objective.
- Known analytic cases such as CHSH.
- Corrupted-certificate fixtures.
- Solver-independent certificate replay.
- Lean-emitted theorem and exact bound.
- Human-readable matrix/problem summary.

## 8. Public API

```python
M = fa.RatMatrix.from_fractions(rows)
cert = fa.certs.ldlt(M)
cert.precheck()
checked = cert.check(session)

problem = fa.positivity.npa(scenario, inequality, level="1+ab")
approx = problem.solve(solver="...")
candidate = approx.reconstruct(strategy="affine-rational")
result = candidate.certify(session, statement=frozen_stmt)
```

Important result distinctions:

- `NumericallyFeasible`
- `ExactFeasible`
- `IntervalFeasible`
- `CertifiedBound`
- `ReconstructionFailed`
- `CertificateRejected`
- `OptimalityUnproved`

## 9. Milestones

### M1 — Rational matrix spine

- Exact scalar/matrix schemas.
- Rust/Python pre-check.
- Lean matrix equality and LDLᵀ checker.
- Positive, semidefinite, singular, indefinite, and corrupted fixtures.

### M2 — First solver round-trip

- Solve a tiny SDP externally.
- Reconstruct a rational dual feasible point.
- Verify the same payload independently and in Lean.
- Freeze the complete artifact.

### M3 — CHSH calibration

- Encode a standard CHSH relaxation.
- Reproduce a known bound.
- Exercise symmetry and exact/irrational endpoint handling honestly.

### M4 — I3322 research artifact

- NPA level-1 or level-1+AB compiler.
- Rational or interval dual certificate.
- Kernel-checked bound beyond CHSH.
- Comparison with published numerical values and conventions.

### M5 — Search for improvement

- Increase level, precision, or exploit symmetry.
- Search neighboring inequalities/nonlocal games.
- Publish every certified improvement or reconstruction obstruction.

### M6 — Second-field transplant

- Apply the engine to a finite quantum-mechanical bootstrap problem.
- Measure new domain-specific code versus reused core.
- Refactor only abstractions proven useful by both consumers.

## 10. Verification and adversarial tests

- Flip one certificate entry and require rejection.
- Permute variable ordering without updating metadata and require rejection.
- Supply a numerically PSD but exactly indefinite matrix.
- Supply a dual point violating one equality below solver tolerance.
- Exercise singular PSD matrices and zero pivots.
- Compare dense and sparse checkers.
- Compare direct quadratic evaluation with matrix form on generated exact vectors.
- Rebuild certificates with two numerical solvers where possible.
- Confirm all inequality and objective conventions against hand-derived toy cases.

## 11. Performance strategy

The Lean checker should verify, not discover. Performance work proceeds in this order:

1. sparse certificate representation;
2. block decomposition;
3. reflection/native computation only under an explicitly accepted trust policy;
4. extracted verified checker for fast pre-validation;
5. chunked certificate lemmas if kernel term size dominates.

Record generation time, reconstruction time, pre-check time, elaboration time, and kernel time separately.

## 12. Acceptance criteria

The engine is ready for scientific reuse when:

- a solver-independent certificate schema exists;
- a corrupt payload cannot pass either checker;
- a complete I3322 bound is reproducible from a frozen artifact;
- the theorem states direction, scenario, relaxation level, conventions, and exact enclosure explicitly;
- no floating-point value is trusted by the Lean proof;
- the second domain reuses the checker without copying it;
- failed reconstruction produces an actionable mathematical/conditioning report rather than a generic error.

## 13. Risks and responses

| Risk | Response |
|---|---|
| Denominators explode | Symmetry, affine repair, basis changes, interval fallback |
| Solution lies on a cone face | Facial reduction and nullspace-aware reconstruction |
| Kernel terms become enormous | Sparse/block certificates, extracted pre-checker, chunked proofs |
| Domain compiler has a sign error | Hand toy cases, independent compiler, mutation tests |
| Certified relaxation is mistaken for physical optimum | Encode level and one-sidedness in theorem and result type |
| Irrational coefficients resist exact form | Algebraic-number certificates or outward intervals |
| Solver result is fragile | Report margins and reconstruction stability as scientific data |

## 14. Scientific deliverables

- First kernel-checked nontrivial NPA/Bell bounds beyond CHSH.
- A reusable exact positivity certificate format.
- A public corpus of accepted and rejected SDP reconstructions.
- A second-field quantum bootstrap artifact demonstrating engine reuse.
- A platform for future certified bounds in fluids, chemistry, photonics, packing, and amplitudes.
