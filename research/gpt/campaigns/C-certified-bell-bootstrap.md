# Campaign C — Certified Bell and Bootstrap Bounds

**Status:** Research and implementation plan, draft 0.1  
**Primary engine:** [Certified Positivity](../engines/02-certified-positivity.md)  
**Supporting engine:** [Theory Cartography](../engines/01-theory-cartography.md)

## 1. Scientific ambition

Turn high-impact floating-point positivity bounds in quantum foundations and bootstrap physics into exact, reproducible theorems—and then use the resulting engine to search for sharper bounds and new exclusion statements.

The campaign begins with nonlocality:

> **Produce kernel-checked NPA upper bounds for Bell inequalities beyond CHSH, beginning with I3322, and use exact certificate reconstruction to explore improvements, symmetry reductions, and neighboring nonlocal games.**

The second deployment transfers the same positivity machinery to finite quantum-mechanical moment bootstrap problems. The long-term destination is a shared verified-bound infrastructure for increasingly ambitious bootstrap settings.

## 2. Why this is frontier research

Bell and bootstrap bounds are often established by floating-point semidefinite optimization. The mathematical implication from a feasible dual certificate is rigorous, but published numerical pipelines rarely ship a small theorem-checkable object.

Scientific contributions include:

- the first kernel-checked bound at a given scenario or hierarchy level;
- a quantitatively improved certified bound;
- a certified exclusion region;
- a symmetry reduction proven sound and measurably stronger or cheaper;
- a reconstruction obstruction exposing a numerically fragile claim;
- a reusable certificate format adopted by other fields.

## 3. Scope

### Stage-one scope

- finite Bell scenarios;
- explicit probability/correlator conventions;
- CHSH as the analytic and pipeline anchor;
- I3322 at a stated NPA level;
- rational or outward-interval dual certificates;
- one-sided upper bounds unless lower constructions are separately certified;
- selected small nonlocal games.

### Stage-two scope

- higher NPA levels where certificate size permits;
- symmetry-reduced formulations;
- finite-dimensional ansatz lower bounds;
- quantum-mechanical moment bootstrap for simple Hamiltonians;
- Atlas comparison of positivity problem shapes.

### Deferred

- claims of exact quantum value without matching certified lower and upper arguments;
- large conformal-bootstrap production runs;
- unbounded hierarchy convergence formalization beyond what a result requires;
- experimental conclusions not encoded through an explicit statistical/model layer.

## 4. Frozen convention record

Before any solver comparison, freeze:

- parties, settings, and outcomes;
- probability versus correlator representation;
- coefficient normalization and local bound;
- tensor-product, commuting-operator, or other model;
- real/complex moment representation;
- NPA word set and hierarchy-level naming;
- primal/dual sign and objective conventions;
- handling of normalization and no-signalling constraints;
- exact statement direction;
- relationship between reported decimal and exact enclosure.

The theorem name and type should expose scenario and level so a relaxation bound cannot be cited as an exact physical optimum.

## 5. Scientific questions

### C-Q1 — Exact reconstruction

Which Bell SDP solutions admit compact rational dual certificates at scientifically useful precision, and what conditioning or facial structure controls success?

### C-Q2 — I3322 certified bounds

What are the strongest practical kernel-checked upper bounds obtainable at selected NPA levels, and can the certified gap to known lower constructions be narrowed?

### C-Q3 — Symmetry and representation

Which problem symmetries or basis choices reduce certificate size without weakening the bound? Can Atlas identify the shared reduction skeleton across nonlocal games?

### C-Q4 — Neighbor search

Can small perturbations or families of Bell coefficients reveal inequalities whose certified quantum/classical gap or hierarchy behavior is especially interesting?

### C-Q5 — Positivity transfer

Which certificate and problem abstractions transfer unchanged from NPA moment matrices to quantum-mechanical bootstrap moment matrices?

## 6. Mathematical pipeline

### Problem generation

- Enumerate NPA words for the frozen level.
- Quotient by algebraic relations with a checkable normalization trace.
- Construct moment matrix and linear constraints.
- Construct Bell objective.
- Emit solver-independent problem representation.

### Numerical exploration

- Solve at increasing precision.
- Record primal/dual residuals, spectra, objective, and status.
- Compare at least two formulations or solvers on anchor problems where practical.
- Diagnose near-boundary/facial structure.

### Reconstruction

- Rationalize dual variables.
- Project exactly onto affine constraints.
- Recover PSD slack through exact or interval methods.
- Block-diagonalize only with a proved symmetry map.
- Produce exact objective enclosure.

### Certification

- Independent Rust/Python certificate pre-check.
- Lean verification of linear constraints and positivity.
- Lean weak-duality theorem specialized to the Bell problem.
- Clean theorem statement and axiom audit.

### Lower-bound route

When claiming a bracket rather than only an upper bound:

- supply explicit finite-dimensional state and measurements;
- calculate the achieved Bell value exactly or by outward interval;
- prove validity of the state/measurement objects;
- keep model dimension and numerical error explicit.

## 7. Work packages

### WP0 — Literature and problem lock

- Domain reviewer confirms current best values and convention translations.
- Freeze CHSH and I3322 formulations.
- Archive source references and numerical answer ranges as external oracles.
- Define what would count as a new scientific improvement.

### WP1 — Generic certificate kernel

- Exact rational matrix schema.
- LDLᵀ/PSD Lean checker.
- Sparse/block support as needed.
- Weak-duality theorem.
- Corrupted-certificate suite.

### WP2 — NPA compiler

- Word generation and normalization.
- Constraint matrix.
- Moment matrix block structure.
- Solver interchange.
- Independent small-case compiler comparison.

### WP3 — CHSH end-to-end anchor

- Numerical solve.
- Exact or algebraic/interval certificate.
- Kernel theorem.
- Comparison with analytic Tsirelson bound.
- Complete offline artifact.

### WP4 — I3322 certificate

- Selected hierarchy level.
- Precision/conditioning study.
- Rational or interval reconstruction.
- Kernel-checked upper bound.
- Optional certified lower construction.
- Publication-quality exact and decimal report.

### WP5 — Frontier search

- Explore higher levels, symmetry reductions, or neighboring inequalities under frozen budgets.
- Rank candidates by scientific interest, certificate margin, and tractability.
- Certify all claimed improvements.
- Preserve failed reconstruction and no-improvement results.

### WP6 — Bootstrap transplant

- Select a finite quantum-mechanical Hamiltonian/moment problem with known reference spectrum.
- Express positivity constraints in the shared schema.
- Certify an energy enclosure.
- Measure reused versus domain-specific implementation.
- Use Atlas to identify common problem and proof shapes.

## 8. Atlas role

Atlas is not the numerical optimizer. It contributes:

- retrieving structurally similar positivity theorems and certificates;
- mapping NPA, moment-bootstrap, SOS, and spectral-positivity problem shapes;
- suggesting symmetry/reduction lemmas from neighboring domains;
- identifying missing domain-compiler rows;
- transporting certificate-checking theorems;
- building the research frontier of high-similarity positivity problems without shared infrastructure.

Confirmed correspondences become Engine 2 abstractions only after at least two domains use them.

## 9. Controls and independent checks

- CHSH analytic value and tiny hand-derived SDP.
- Classical/local bound computed independently.
- Random exact feasible points.
- Numerically feasible but exactly invalid dual points.
- Coefficient sign and normalization mutations.
- Constraint deletion mutations.
- Word-order permutation tests.
- Dense versus sparse certificate agreement.
- Two independent Bell-expression evaluators.
- Solver logs are never accepted as certificates.

## 10. Result taxonomy

- numerical bound only;
- exact dual feasible certificate;
- interval dual feasible certificate;
- kernel-checked upper bound;
- certified lower construction;
- certified bracket;
- exact value proved;
- reconstruction failed;
- hierarchy/level insufficient;
- convention mismatch found;
- improved certified bound;
- no improvement within frozen search budget.

The publication layer uses these exact terms.

## 11. Milestones

### C0 — Scientific and convention freeze

- CHSH/I3322 statements and hierarchy levels frozen.
- Domain reviewer approves interpretation.
- Oracle values archived.

### C1 — Positivity kernel

- Exact matrix and LDLᵀ checker complete.
- Independent pre-check and adversarial fixtures complete.

### C2 — CHSH theorem

- Complete solver-to-Lean artifact.
- Analytic and certificate routes agree.
- Offline reproduction succeeds.

### C3 — I3322 theorem

- First nontrivial kernel-checked upper bound.
- Exact level and convention in theorem.
- Reconstruction report published.

### C4 — Certified research search

- Frozen improvement/search batch executed.
- At least one stronger bound, new certified inequality result, or mathematically informative reconstruction obstruction.

### C5 — Bootstrap reuse

- Quantum-mechanical moment problem certified.
- Shared positivity core demonstrated.
- Next-domain priority selected from measured reuse.

## 12. Publication strategy

Possible paper sequence:

1. **Methods/infrastructure:** exact NPA certificate format and first Lean-checked bounds.
2. **Physics result:** improved I3322 or neighboring nonlocal-game certified bound/bracket.
3. **Cross-domain result:** one positivity engine for Bell and quantum bootstrap bounds.

Artifacts include problem files, solver settings, certificates, Lean theorems, independent checker, convention map, and failed reconstruction examples.

## 13. Success criteria

Strong success:

- a quantitatively improved certified Bell or bootstrap bound.

Substantial success:

- the first kernel-checked nontrivial bound beyond CHSH with a reusable certificate pipeline;
- a certified lower/upper bracket;
- a new symmetry reduction or reconstruction technique.

Scientific-instrument success:

- a second physics domain reuses the checker and schema with little new trusted code.

## 14. Risks

| Risk | Response |
|---|---|
| Rational reconstruction fails near the cone boundary | Facial reduction, exact affine repair, interval PSD certificate |
| Certificate is too large for Lean | Blocks, sparsity, chunking, verified extracted checker |
| Best result already has an exact proof | Use it as anchor; target neighboring scenarios or reusable method novelty |
| NPA convention mismatch invalidates comparison | Frozen problem manifest and hand-derived cases |
| Higher levels become computationally prohibitive | Publish lower-level certified result; select symmetry or nearby scenario |
| One-sided bound is overstated | Result type and theorem expose relaxation and direction |

## 15. Dependencies

- Engine 2 exact matrix, reconstruction, and certificate spine.
- Campaign journal, frozen statements, and environment lock.
- Minimal Physlib/Mathlib finite-dimensional operator foundations.
- External SDP solver and independent pre-checker.
- Theory Cartography only for cross-domain discovery; not required for the first CHSH/I3322 certificate.
