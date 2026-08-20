# Engine 4 — Validated Spectra and Dynamics

**Status:** Implementation plan, draft 0.1  
**Scientific role:** Turn approximate spectral and dynamical computation into rigorous enclosures, stability statements, invariant structures, and continuum-aware bounds

## 1. Objective

Build a validated-numerics engine whose outputs are proof-carrying statements about continuous, spectral, and infinite-dimensional models.

The engine should certify:

- scalar and vector enclosures;
- roots and extrema;
- eigenvalues, singular values, and spectral gaps;
- parameter-dependent operator bounds;
- validated trajectories and flow maps;
- contraction and fixed-point arguments;
- periodic orbits and invariant tori;
- finite-discretization error and infinite tails;
- monitored regularity and stability criteria.

## 2. Scientific reach

- Couette, Poiseuille, and Orr–Sommerfeld stability;
- MHD energy principles and plasma spectra;
- photonic and solid-state band structures;
- quantum-chemistry basis and spectral brackets;
- celestial validated integration, periodic orbits, and KAM;
- certified transfer matrices and resonances;
- simulation regularity monitors;
- rigorous numerical components of computer-assisted PDE proofs.

## 3. Non-goals

- Do not infer a continuum theorem from a finite matrix without a proved bridge.
- Do not make Lean execute production-scale numerical search.
- Do not begin with a general PDE framework.
- Do not hide floating-point rounding mode or library assumptions.
- Do not claim global dynamics from a local integrator enclosure without a composition theorem.

## 4. Trust architecture

The search side computes approximations and proposes enclosures. A small checker verifies rational/interval inequalities and composes local certificates into a theorem.

```text
model and frozen claim
        │
        ▼
discretizer / numerical solver
        │
        ▼
approximation + residual + conditioning data
        │
        ▼
outward enclosure / a-posteriori theorem instance
        │
        ▼
independent interval pre-check
        │
        ▼
Lean checker + model/discretization adequacy theorem
```

The hard mathematical work is often the a-posteriori theorem connecting computable residuals to the desired continuum object. Those theorems are first-class library assets.

## 5. Shared numerical types

- exact rationals and dyadics;
- directed-rounding intervals;
- complex rectangles or discs;
- interval vectors and matrices;
- balls in normed spaces;
- polynomial, Chebyshev, and Fourier coefficient enclosures;
- parameter boxes;
- sparse linear operators;
- residual and condition-number records;
- truncation/tail certificates;
- validated time-step records.

All encodings are canonical, versioned, and content-addressed.

## 6. Components

### V1. Interval scalar kernel

- Outward-rounded arithmetic.
- Elementary functions needed by first campaigns.
- Inclusion monotonicity theorems.
- Empty/undefined/domain-error distinctions.
- Exact rational endpoints for the first checker.
- Independent comparison with a mature interval library.

### V2. Expression and polynomial evaluation

- Certified expression DAG evaluation.
- Horner and Bernstein forms.
- Derivative enclosures.
- Root isolation by interval Newton/Krawczyk methods.
- Global extrema over bounded boxes through subdivision certificates.

### V3. Matrix and spectral enclosure

- Gershgorin and norm bounds as simple baselines.
- Residual-based eigenpair enclosures.
- Verified symmetric/Hermitian eigenvalue intervals.
- Generalized eigenvalue problems.
- Singular-value and condition-number bounds.
- Block and symmetry reductions with reconstruction proofs.

### V4. Spectral discretization

- Exact Fourier/Chebyshev basis definitions.
- Certified assembly of finite matrices.
- Coefficient/integral verification.
- Projection and interpolation error bounds.
- A-posteriori residual estimates.
- Tail control for discarded modes.

### V5. Parameter-domain coverage

- Adaptive subdivision of wavenumber or physical-parameter boxes.
- Per-box certificate records.
- Proof that boxes cover the declared domain.
- Large-parameter asymptotic exclusion lemmas.
- Boundary and singular-regime handling.

This component is mandatory before converting pointwise numerical evidence into a global threshold claim.

### V6. Validated dynamics

- Interval Taylor or Taylor-model steps.
- Local truncation and rounding bounds.
- Flow-map composition.
- Invariant-region certificates.
- Contraction/fixed-point checkers.
- Event and crossing enclosures.
- Long-time wrapping diagnostics.

### V7. Invariant structures

Later adapters:

- periodic-orbit shooting plus Newton–Kantorovich;
- a-posteriori KAM torus certificates;
- stable/unstable manifold enclosures;
- Lyapunov and regularity-monitor certificates.

### V8. Adequacy and model bridge

Each domain supplies the theorem connecting numerical objects to scientific meaning:

- matrix discretization to operator spectrum;
- finite Fourier/polynomial field to admissible continuum field;
- local flow enclosures to the target differential equation;
- monitored norm bounds to a regularity criterion;
- parameter normalization to the literature convention.

Where absent, the engine returns `FiniteModelResult` or `ConditionalOnAdequacy`, never a continuum result.

## 7. Public API

```python
x = fa.Interval(Fraction(1, 3), Fraction(2, 5))
y = fa.certs.interval_eval(expr, {"x": x})

problem = fa.spectra.hermitian(matrix_or_operator)
enclosure = problem.enclose(k=0, method="residual")
enclosure.certify(session)

cover = fa.validated.cover(parameter_box, predicate, splitter=...)
cover.certify_complete(session)

trajectory = fa.validated.integrate(system, initial_box, t_span, tolerance=...)
trajectory.certify(session)
```

Result types include:

- `CertifiedEnclosure`
- `ConditionalEnclosure`
- `FiniteDiscretizationResult`
- `CoverageComplete`
- `CoverageGap`
- `ContractionCertified`
- `ValidationFailed`

## 8. Milestones

### M1 — Interval arithmetic spine

- Rational endpoint intervals.
- Arithmetic and containment theorems.
- Expression evaluator.
- Corrupted-rounding and domain-error fixtures.

### M2 — Root and matrix enclosures

- Polynomial root isolation.
- Symmetric/Hermitian eigenvalue bounds.
- Comparison with exact small examples and independent libraries.

### M3 — First scientific spectrum

Choose one bounded target with a mature reference value:

- a finite Orr–Sommerfeld discretization;
- a simple photonic transfer/band problem;
- a small quantum Hamiltonian.

Produce a complete frozen certificate and Lean theorem about the finite problem.

### M4 — Parameter coverage

- Certified box subdivision.
- Complete domain manifest.
- Large-parameter exclusion.
- One global finite-model bound.

### M5 — Continuum tail bridge

- Formal basis and projection.
- A-posteriori residual/tail theorem.
- Full statement distinguishing finite and continuum quantities.
- First continuum-aware spectral or stability enclosure.

### M6 — Validated dynamics

- Validated integration kernel.
- One known periodic orbit, contraction, or invariant-region theorem.
- Artifact replay and trace diagnostics.

### M7 — Advanced invariant structure

- A-posteriori KAM or comparable contraction-based certificate.
- Second-domain transplant.

## 9. First deployment options

### Couette as a ladder, not a leap

1. Exact trial field giving a one-sided finite result.
2. Fixed finite matrix positivity certificate.
3. One wavenumber-box enclosure.
4. Complete bounded wavenumber cover.
5. Large-wavenumber tail.
6. Continuum adequacy theorem.

Each rung is publishable and explicitly named. Only the final rung supports a continuum threshold claim.

### Photonic/solid-state alternative

A low-dimensional transfer-matrix or band-gap enclosure may reach a complete continuum statement sooner and can establish the engine before the PDE-heavy Couette bridge.

### Celestial alternative

A small contraction or periodic-orbit certificate offers mature validated-numerics precedents but requires ODE and interval infrastructure earlier.

Selection occurs after Phase 6 measures available Mathlib/Physlib foundations.

## 10. Verification and adversarial tests

- Every interval result must contain random exact samples on generated fixtures.
- Compare two interval libraries or algorithms.
- Inject an inward-rounded endpoint and require detection through known counterexamples.
- Remove one parameter box from a coverage manifest.
- Corrupt a tail coefficient or residual bound.
- Compare finite matrices assembled by two independent implementations.
- Exercise nearly multiple eigenvalues and ill-conditioned problems.
- Track convention and nondimensionalization transforms explicitly.
- Prove finite/continuum result types cannot be confused at the API layer.

## 11. Performance and extraction

- Search and adaptive subdivision remain in Rust/Python.
- Certificate checkers use simple bounded loops and exact arithmetic.
- Hot checkers are first customers for verified Rust extraction and round-trip validation.
- Store large certificates in chunked, content-addressed blocks.
- Measure interval dependency blowup and basis conditioning as scientific diagnostics.

## 12. Acceptance criteria

- Every enclosure is outward and independently replayable.
- Coverage claims include a machine-checked complete domain decomposition.
- Continuum conclusions cite an explicit adequacy/tail theorem.
- Finite and continuum results have distinct types and publication wording.
- At least one nontrivial spectrum or dynamics result is reproduced from an offline artifact.
- A second domain reuses the interval and spectral kernels.

## 13. Risks and responses

| Risk | Response |
|---|---|
| Interval bounds are too loose | Better coordinates, Taylor models, adaptive subdivision, a-posteriori methods |
| Mathlib analysis foundations are missing | Prove narrow reusable lemmas; upstream; keep first target finite |
| Kernel checking is too slow | Chunking, sparse forms, extracted pre-checkers, theorem factoring |
| Continuum tail dominates project | Publish finite and partial parameter results honestly; select alternate first deployment |
| Convention errors shift reference values | Transformation theorems, dual implementations, statement dossier |
| Long-time dynamics wraps catastrophically | Coordinate changes, shadowing/contraction methods, honest horizon limits |

## 14. Scientific deliverables

- Certified spectral reference values.
- Kernel-checked stability or instability statements.
- Reusable interval and parameter-coverage certificates.
- A continuum-aware truncation and tail discipline.
- Validated dynamics artifacts for later KAM, plasma, photonics, and simulation-monitor campaigns.
