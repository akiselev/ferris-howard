# Campaign A — Quantum Resource-Theory Cartography

**Status:** Research and implementation plan, draft 0.1  
**Primary engine:** [Theory Cartography](../engines/01-theory-cartography.md)  
**Supporting engines:** [Certified Finite Search](../engines/03-certified-finite-search.md), later [Certified Positivity](../engines/02-certified-positivity.md)

## 1. Scientific ambition

Construct a machine-interrogable map of quantum resource theories and use it to discover new transfers, obstructions, and minimal axiom systems.

The initial theories are:

- bipartite entanglement;
- coherence;
- stabilizer magic;
- asymmetry;
- finite-dimensional quantum thermodynamics.

Each theory contains variants of the same visible architecture—free objects, free transformations, monotones, conversion orders, catalysts, asymptotic rates—but the detailed assumptions and theorem inventories differ. The campaign asks where the shared architecture is mathematically real, where it is only rhetoric, and which established theorem on one side should exist on another.

## 2. Frontier questions

1. Which conversion and catalysis results admit a common theorem over a minimal resource-theory interface?
2. Which monotone constructions transfer between theories, and what additional hypotheses do they require?
3. Which apparent analogies fail, and what smallest state or channel witnesses the failure?
4. Do several theory-specific proofs reveal a stronger reusable abstraction than the standard free-object/free-operation framework?
5. Which missing dictionary rows correspond to genuinely unstated or unresolved results?
6. Can the minimal axiom “home” of a phenomenon—catalysis, distillation, bound resources, asymptotic reversibility—be computed and proved?
7. Which proof strategies transfer even when the statements are not syntactically close?

## 3. Scope

### Included initially

- finite-dimensional state spaces;
- exact matrices over rationals, algebraic numbers, or a controlled complex representation where feasible;
- deterministic and stochastic resource conversions with explicit definitions;
- majorization and related finite orders;
- additive, convex, or asymptotic monotones where foundations permit;
- small exact examples and counterexamples;
- theorem statements and selected proofs sufficient for cartography.

### Deferred

- infinite-dimensional continuous-variable resource theories;
- unrestricted asymptotic analysis requiring large analytic foundations;
- operational claims depending on experimental implementation details;
- a universal category-theoretic resource theory before concrete dictionaries demand it;
- large numerical optimization not needed by the first transferred statements.

## 4. Scientific products

- A formal multi-theory atlas with evidence-typed rows.
- A minimal common resource-theory interface justified by reuse, if one exists.
- Transported conjectures with exact provenance.
- New transferred theorems or sharper hypothesis sets.
- Minimal counterexamples locating analogy boundaries.
- A map of phenomena to their weakest known axiom homes.
- Reusable Physlib/Mathlib definitions and theorems.
- A research paper presenting the map, new results, and negative structure.

## 5. Corpus design

The corpus is built as distinct clusters. Shared terminology is not forced into shared constants during the first pass; otherwise the corpus would encode the desired dictionary in advance.

### Cluster E — Entanglement

- separable and entangled states;
- LOCC or a tractable declared free-operation approximation;
- Schmidt coefficients and majorization;
- entanglement monotones;
- catalysis/trumping statements;
- distillation and bound-entanglement statements at the level supported by the formal foundation.

### Cluster C — Coherence

- incoherent states and one or more explicitly named operation classes;
- pure-state coherence conversion;
- coherence monotones;
- catalytic coherence statements;
- asymptotic rates where formally accessible.

### Cluster M — Magic

- stabilizer states and operations;
- magic monotones such as robustness/mana variants under exact declared definitions;
- state conversion and catalysis questions;
- finite qudit cases aligned with Campaign B.

### Cluster A — Asymmetry

- group actions and invariant/free states;
- covariant operations;
- asymmetry monotones;
- reference-frame resources;
- conversion statements for finite groups first.

### Cluster T — Thermodynamics

- finite Gibbs states;
- thermal or Gibbs-preserving operations, named separately;
- thermo-majorization;
- free energies and second-law families;
- catalytic and approximate conversion statements with explicit error semantics.

### Abstract-control cluster

A small generic resource-theory library may be used as an answer/control corpus but is excluded from the first discovery index. It becomes an implementation target only after concrete clusters reveal which abstraction actually pays rent.

## 6. Statement and convention discipline

Each theory manifest records:

- objects and morphisms;
- exact free-operation class;
- deterministic/probabilistic/approximate conversion semantics;
- distance or approximation metric;
- catalysts and whether correlations are permitted;
- single-shot versus asymptotic regime;
- finite-dimensional assumptions;
- logarithm and entropy conventions;
- normalization and tensor-product conventions.

Apparent theorem disagreement is not repaired by silently choosing one convention. Competing definitions become named theory variants and their relationships become part of the map.

## 7. Research hypotheses

These are scientific hypotheses guiding interrogation, not assumptions built into the corpus.

### A-H1 — Conversion-order transfer

Majorization-based pure-state conversion theorems across entanglement, coherence, and thermodynamics share a formal core whose minimal assumptions are weaker than any one physical theory.

### A-H2 — Catalysis dictionary

Catalytic conversion results organize into a coherent cross-theory dictionary, with missing rows that yield meaningful new conjectures rather than only terminological gaps.

### A-H3 — Monotone construction transfer

At least one nontrivial monotone construction or completeness argument transfers to a theory where it is not currently standard under an explicitly identified hypothesis delta.

### A-H4 — Physical-home cartography

Phenomena commonly attributed to “quantumness” occupy distinct, computable homes in a lattice of convexity, symmetry, tensor, and operational axioms.

### A-H5 — Boundary structure

Failed transfers cluster around a small number of structural differences—operation closure, tensor behavior, catalysis correlations, approximation semantics—rather than arbitrary theorem-specific accidents.

## 8. Work packages

### WP0 — Scientific board and corpus boundary

- Recruit at least one quantum-resource-theory domain reviewer.
- Freeze operation-class and approximation conventions.
- Select 40–80 load-bearing statements per initial theory rather than encyclopedic coverage.
- Identify known correspondences, known failures, and deliberately ambiguous definitions.
- Assign separate corpus and cartography responsibilities.

### WP1 — Formal foundations

- Finite density matrices and channels via Physlib/QuantumInfo where possible.
- Majorization and finite probability vectors.
- Group actions and covariance.
- Exact stabilizer representation shared with Campaign B.
- Tensor and composition lemmas.
- Role metadata for state, operation, monotone, catalyst, rate, and obstruction.

Upstream reusable results early.

### WP2 — Independent cluster construction

- Build each cluster from its own source literature and definitions.
- Add positive and negative examples.
- Freeze statement hashes and cluster manifests.
- Run statement-validity dossiers.
- Produce neutral-name evaluation overlays without altering scientific source names.

### WP3 — First map

- Run structural, logical, dependency, and proof-shape indexes.
- Assemble pairwise and multiway dictionaries.
- Produce several alternative dictionaries where mappings are ambiguous.
- Have domain reviewers label rows as known, plausible, false, ill-posed, or novel candidate.
- Preserve the blind candidate origin during initial scientific assessment.

### WP4 — Common-home research

- Define an explicit axiom lattice for the shared finite resource fragment.
- Generate candidate homes from dependencies and theorem shapes.
- Re-elaborate/prove theorems under weakened axiom sets.
- Record unique and incomparable minimal homes.
- Promote only abstractions that simplify held-out theorems.

### WP5 — Transport campaigns

For selected coherent rows:

1. Generate target statements.
2. Elaborate them in the target theory.
3. Search for existing equivalents.
4. Run small exact counterexample search.
5. Attempt proof under a frozen budget.
6. If refuted, shrink the counterexample and classify the structural cause.
7. If proved, complete literature review and external novelty assessment.

### WP6 — Publication map and theorem package

- Interactive/static theory atlas.
- Lean source and clean emitted artifacts.
- Table of confirmed, refuted, open, and ambiguous rows.
- New theorem and counterexample sections.
- Common-home theorem package.
- Methods section describing agent and Atlas involvement.

## 9. Experimental design inside the campaign

Calibration is embedded in the campaign so that discovery outputs remain interpretable.

### Known-row recovery

Freeze known cross-theory rows outside the ranking implementation. Use them to tune only development epochs; burn evaluated targets.

### Baselines

- exact/canonical statement equality;
- token and identifier similarity;
- tree/subterm similarity;
- semantic embeddings;
- random type-compatible rows.

### Ablations

Remove carrier erasure, dependency features, proof shape, home, and coherence constraints separately. The resulting changes identify which instrument components produce scientifically useful rows.

### Prospective batches

Once an epoch is frozen, generate a bounded batch of new unmatched rows. Evaluate the entire batch under equal budgets, not only the most attractive examples.

## 10. Candidate triage

Every transported candidate receives one status:

- existing-known;
- existing-obscure;
- equivalent after convention translation;
- ill-posed in the target theory;
- false with minimal counterexample;
- true in bounded models only;
- proved under the transported assumptions;
- proved under stronger assumptions;
- open after budget;
- novel pending expert review;
- novel and submission-ready.

The map presents all statuses. Negative structure is not hidden from the headline result.

## 11. Certification routes

- Direct Lean proof for structural theorems.
- Exact finite enumeration for small states/groups.
- Majorization decision procedures and witnesses.
- Rational positivity certificates for monotone/convexity claims.
- Explicit counterexample matrices or channels.
- Assumption-conditional theorem where operational closure or asymptotic limits remain unformalized.

## 12. Milestones

### A0 — Charter and conventions

- Scientific scope and operation classes frozen.
- Domain reviewer signs the statement glossary.
- Corpus and answer/control custody assigned.

### A1 — Three-theory finite corpus

- Entanglement, coherence, and magic clusters elaborate.
- Known examples and false neighbors included.
- Theory manifests and dossiers complete.

### A2 — First multiway atlas

- Dictionaries, relationship paths, and missing entries generated.
- Reviewers complete blinded row assessments.
- Common-home candidates identified.

### A3 — First transport season

- Frozen candidate batch fully dispositioned.
- At least one proof attempt and one exact counterexample completed.
- Instrument changes deferred to the next epoch.

### A4 — Five-theory expansion

- Add asymmetry and thermodynamics.
- Re-test abstractions and homes on unseen theories.
- Deprecate abstractions that fail to pay rent.

### A5 — Frontier result package

- Submit a theorem, obstruction, or common-home result.
- Release the full atlas and negative-results ledger.
- Upstream reusable foundations.

## 13. Success criteria

The campaign succeeds scientifically if it produces any of:

- a nontrivial new transferred theorem;
- a new minimal axiom/home result;
- a minimal counterexample explaining a previously assumed analogy;
- a coherent map that reorganizes known results and is adopted by domain researchers;
- a reusable abstraction whose value is demonstrated on held-out theory clusters.

It is also successful as honest cartography if the map demonstrates that expected transfers systematically fail for a clear structural reason.

## 14. Risks

| Risk | Response |
|---|---|
| Operation classes differ subtly | Treat variants as separate theories; prove comparison theorems |
| Corpus merely restates generic resource theory | Exclude shared abstraction from first discovery index |
| Results are known under different terminology | Dedicated literature review after mathematical verdict |
| Asymptotic results require heavy analysis | Begin finite/single-shot; label statement-only edges |
| Atlas matches formula shape without operational meaning | Role constraints, coherent dictionaries, exact counterexamples |
| Common abstraction becomes vacuous | Nontriviality, held-out reuse, compression and theorem-yield tests |

## 15. Dependencies

- Engine 1 through typed transport and re-elaborated home.
- Campaign journal and candidate schema.
- Practical statement-validity dossiers.
- Exact finite matrices and finite search for counterexamples.
- Physlib/QuantumInfo collaboration.

The campaign does not wait for full automated proving, `Effective`, or validated continuum numerics.
