# Campaign B — Finite Fields and Stabilizer Quantum Mechanics

**Status:** Prospective frontier-research plan, draft 0.1  
**Primary engines:** [Theory Cartography](../engines/01-theory-cartography.md), [Certified Finite Search](../engines/03-certified-finite-search.md)  
**Scientific character:** Exact finite mathematical physics with prospective Atlas-directed conjecture generation

## 1. Scientific ambition

Determine what the arithmetic structure of finite fields and their extensions means inside prime-power-dimensional stabilizer quantum mechanics.

The known bridge is already deep:

- phase space is symplectic over finite fields;
- Weyl/Pauli commutation is controlled by a symplectic form and field trace;
- Clifford transformations act through affine or projective symplectic structure;
- stabilizer states and codes correspond to isotropic/Lagrangian data;
- discrete Wigner constructions depend on finite-field geometry.

The campaign asks what lies beyond the familiar rows. In particular:

> **What quantum operations, invariants, decompositions, codes, or no-go structures correspond to Frobenius, Galois action, trace/norm maps, subfields, and extension arithmetic?**

This is an unusually favorable frontier: the mathematics is exact, small dimensions can be exhausted, and both a new theorem and a minimal counterexample can be certified completely.

## 2. Scope and claim boundary

### Included

- qudits of prime and prime-power dimension;
- finite-field and finite-module formulations, kept distinct;
- exact Weyl/Pauli and Clifford representations;
- symplectic, isotropic, and Lagrangian subspaces;
- stabilizer states and codes;
- finite Galois groups, Frobenius, trace, norm, and subfields;
- exact finite search in bounded `p`, extension degree, and qudit count;
- dictionary and transport questions stated as finite algebra.

### Deferred

- fault-tolerance performance claims requiring detailed noise models;
- unrestricted Clifford hierarchy classifications;
- SIC/MUB number-field moonshots beyond reusable finite-field foundations;
- continuum or experimental hardware conclusions;
- asymptotic statements not supported by a proved family theorem.

Every computational result states its exact bounds. Pattern extrapolation may motivate a conjecture but is not a theorem.

## 3. Known bridge rows

The initial corpus includes enough known structure to orient Atlas without encoding every desired connection as one shared definition.

| Finite geometry/arithmetic | Stabilizer quantum structure |
|---|---|
| vector in phase space | Weyl/Pauli label |
| alternating symplectic form | commutation phase |
| isotropic subspace | commuting Pauli subgroup |
| Lagrangian subspace | maximal stabilizer / pure stabilizer state |
| symplectic transformation | Clifford action modulo phases |
| affine symplectic action | displacement plus Clifford action |
| field trace to the prime field | additive character/phase construction |
| symplectic orthogonal | commutant/logical operator relation |
| subspace quotient | logical phase space of a stabilizer code |

Each row must be represented by a theorem or precise candidate relation, not only a prose analogy.

## 4. Frontier question families

### B-Q1 — Frobenius action

- How does Frobenius act on field-labeled Weyl operators and stabilizer data?
- Is the induced action Clifford, semilinear-Clifford, antiunitary, or outside the chosen operation class?
- Which invariants and orbit decompositions does it preserve?
- Does the answer depend on phase convention or field/module realization?

### B-Q2 — Fixed fields and subtheories

- Do Frobenius-fixed or subfield-defined phase-space objects correspond to distinguished stabilizer subtheories, code families, or symmetry sectors?
- Can fixed-point counts or orbit lengths classify quantum objects that are otherwise presented ad hoc?

### B-Q3 — Trace and norm transport

- Which quantum constructions naturally realize field trace and norm?
- Do restriction/extension of scalars correspond to qudit composition, embedding, coarse-graining, or code concatenation?
- Where do dimension and tensor-factorization choices obstruct a clean correspondence?

### B-Q4 — Extension towers

- Can towers `F_p ⊆ F_{p^m} ⊆ F_{p^{mn}}` organize stabilizer embeddings or decompositions functorially?
- Which properties survive changes of field basis?
- Can tower structure produce new code constructions or no-go results?

### B-Q5 — Unmatched arithmetic theorems

Run Atlas over finite-field arithmetic and stabilizer corpora without restricting it to the named questions. Treat highly ranked unmatched rows as a prospective research batch.

## 5. Formal corpus

### Arithmetic cluster

- finite-field construction and cardinality;
- Frobenius automorphism and iterates;
- fixed fields;
- trace and norm;
- extension towers and scalar restriction;
- linearized polynomials where needed;
- symplectic vector spaces;
- isotropic/Lagrangian subspaces;
- orbit and invariant theorems;
- selected function-field rows when genuinely relevant.

### Quantum cluster

- exact qudit Hilbert/state representation suitable for finite stabilizer work;
- Weyl/Pauli operators;
- Clifford normalizer relation;
- stabilizer groups, states, and codes;
- logical operators and symplectic quotients;
- discrete Wigner phase-space objects;
- exact small examples;
- known prime-versus-prime-power caveats.

### Decoy/control cluster

- type-compatible linear maps that do not preserve the symplectic structure;
- alternative phase conventions;
- arbitrary field automorphisms represented incorrectly as linear maps;
- module formulations that coincide only after a basis choice;
- scrambled dictionary rows.

## 6. Representation decisions to freeze

Before candidate generation, freeze:

- finite-field implementation and basis policy;
- characteristic-two treatment;
- additive character and phase convention;
- whether phase space is field-linear or prime-field-linear;
- projective versus phase-sensitive Clifford equality;
- tensor-product versus field-extension realization of dimension `p^m`;
- stabilizer code equivalence relation;
- allowed semilinear or antiunitary operations;
- bounded search ranges.

Many apparent discoveries in this area are convention changes. The campaign treats convention translations as explicit theorems.

## 7. Work packages

### WP0 — Domain review and literature map

- Recruit a finite-geometry/stabilizer expert.
- Survey existing use of Galois/Frobenius actions in discrete Wigner and Clifford literature.
- Freeze claims already known, partially known, or genuinely open.
- Separate “not found” from “novel.”

### WP1 — Exact shared foundations

- Reuse Mathlib finite fields and linear algebra.
- Integrate Physlib/QuantumInfo where representations fit.
- Prove conversion theorems between field and module presentations.
- Implement canonical finite serialization.
- Establish exact arithmetic cross-checks.

### WP2 — Known bridge certification

- Formalize the known rows as theorems.
- Verify small cases exhaustively.
- Make Atlas recover the bridge from separately organized clusters.
- Generate complete evidence paths.

The known bridge is the launchpad, not the final result.

### WP3 — Prospective Atlas batch

- Freeze code, corpus, scorer, and budgets.
- Generate top unmatched transports.
- Generate matched control arms from lower ranks, random type-compatible rows, and the strongest baseline.
- Blind source/rank during initial mathematical assessment.
- Investigate every candidate in the frozen batch.

### WP4 — Exact finite attack

For each viable candidate:

- translate to an exact finite predicate;
- exhaust small `p`, `m`, and qudit counts;
- shrink counterexamples;
- infer possible missing hypotheses from failure patterns;
- formulate a family theorem only after exact data supports it;
- attempt proof using finite-field and symplectic algebra.

### WP5 — Theorem/no-go promotion

- Direct Lean proof where structural.
- Certified exhaustive theorem for bounded families.
- SAT/no-go certificate where appropriate.
- Explicit distinction between bounded evidence and general result.
- Domain novelty review after mathematical verification.

### WP6 — Scientific synthesis

- Publish the confirmed dictionary and its broken rows.
- Explain what Frobenius/Galois structure does and does not mean quantum mechanically.
- Release exact search artifacts and counterexample corpus.
- Propose follow-up code, Wigner, SIC/MUB, or resource-theory questions supported by the map.

## 8. Candidate-batch design

Each epoch contains:

- 20 top unmatched Atlas candidates;
- 20 next-ranked candidates;
- 20 random type-compatible controls;
- 20 candidates from the best non-Atlas baseline.

The exact batch size may change before the first freeze based on formalization cost, but it is fixed before outputs are inspected.

Every candidate receives equal initial effort:

- elaboration/type assessment;
- bounded exact search;
- literature query budget;
- proof-attempt budget for survivors.

Promising candidates may receive a second-stage budget only under a recorded rule based on first-stage evidence.

## 9. Candidate outcomes

- convention identity;
- known theorem under different language;
- existing but previously unformalized relation;
- false at smallest dimension;
- true only in odd characteristic;
- true only for selected extension degrees;
- true after expanding the operation class to semilinear/antiunitary maps;
- bounded pattern with open generalization;
- general theorem proved;
- bounded no-go certified;
- unresolved after budget.

Each outcome changes the map. Characteristic- or convention-dependent failures are particularly valuable structural results.

## 10. Milestones

### B0 — Frozen scientific interface

- Representation and convention document signed off.
- Known-literature map and novelty categories frozen.
- Search bounds chosen.

### B1 — Known bridge in Lean

- Phase-space, Pauli, Clifford, and stabilizer rows proved.
- Exact small examples and cross-implementation checks green.
- Corpus manifests frozen.

### B2 — Atlas expedition launch

- Prospective candidate and control batches frozen.
- No ranking changes during the epoch.
- Candidate lifecycle dashboard active.

### B3 — Exact cartography

- Full first-stage finite disposition of the batch.
- Minimal counterexamples and characteristic splits recorded.
- Surviving family conjectures frozen.

### B4 — Theorem season

- Fixed-budget and then evidence-triggered proof campaigns.
- At least one result promoted to theorem or certified bounded no-go.

### B5 — Publication

- Formal theory map.
- New result or negative cartography.
- Search/certificate artifacts.
- Domain-expert assessment.
- Follow-up questions selected from evidence.

## 11. Success criteria

Strong success:

- a new general theorem, construction, or no-go about Galois/Frobenius structure in stabilizer quantum mechanics.

Substantial success:

- a new bounded classification or characteristic-dependent boundary;
- a known but scattered relation unified and formalized in a way that generates new corollaries;
- a previously assumed correspondence refuted by a minimal exact counterexample.

Infrastructure success:

- a reusable exact finite-field/stabilizer corpus and certified finite-search path that immediately supports quantum-code or SIC/MUB work.

## 12. Risks

| Risk | Response |
|---|---|
| Frobenius/Galois connections are already known | Map and formalize precisely; seek missing hypotheses/corollaries; adjust novelty claims |
| Tensor and field-extension pictures are confused | Formal conversion/equivalence theorems and basis-dependence metadata |
| Characteristic two breaks standard phase conventions | Separate cluster and theorem families from the start |
| Search discovers only tiny-dimension accidents | Require family proof or label bounded result; vary `p,m` systematically |
| Atlas output is driven by shared notation | Neutral names, baseline arms, evidence paths, exact coherence constraints |
| State space grows too quickly | Symmetry reduction only after small unreduced checks; SAT/domain-specific bounds |

## 13. Dependencies

- Engine 1 typed dictionary and transport.
- Engine 3 finite schemas, enumeration, and counterexample shrinking.
- Campaign journal and prospective batch controls.
- Mathlib finite fields and symplectic linear algebra.
- Physlib/QuantumInfo integration or explicitly scoped local bridge.

The campaign does not require the positivity, validated-dynamics, or Effective engines.
