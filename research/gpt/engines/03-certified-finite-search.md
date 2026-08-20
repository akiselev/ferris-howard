# Engine 3 — Certified Finite Search

**Status:** Implementation plan, draft 0.1  
**Scientific role:** Search finite scientific spaces at high speed while producing exact witnesses, exhaustive no-gos, and independently checkable classifications  
**First consumer:** [Campaign B](../campaigns/B-finite-fields-stabilizers.md)

## 1. Objective

Build a general search-and-certificate engine for scientific questions that become finite after an explicit bound, discretization, or algebraic restriction.

The search layer may use enumeration, SAT, SMT, constraint programming, graph isomorphism, evolutionary search, or custom high-performance Rust. The trusted result is one of:

- an exact witness with a small Lean checker;
- a counterexample with a minimality certificate;
- an exhaustive classification with coverage proof;
- an unsatisfiability/no-go certificate;
- a bounded optimum with witness and exhaustion of better values.

## 2. Scientific reach

- finite-field and stabilizer structures;
- quantum codes and exact distance certification;
- contextuality and nonlocal-game assignments;
- bounded entropy-inequality counterexamples;
- anomaly-free charge and particle-content censuses;
- finite dualities and partition-function collisions;
- stoquasticity transformations and restricted no-gos;
- small Hamiltonian, circuit, and tensor-network classifications;
- crystallographic and symmetry censuses;
- finite model search for transported conjectures;
- exact combinatorial designs, SIC/MUB subproblems, and code tables.

## 3. Non-goals

- Do not call a bounded no-go an unrestricted theorem.
- Do not trust a search program's “complete” flag without a coverage certificate.
- Do not require Lean to perform large discovery searches.
- Do not standardize every solver before one campaign demonstrates the common interface.
- Do not conflate isomorphism reduction with complete coverage unless orbit representatives and reconstruction are proved.

## 4. Search problem model

```text
FiniteProblem
  parameters and declared bounds
  object encoding
  predicate or objective
  symmetries/equivalence relation
  candidate decoder
  witness checker
  coverage strategy
  statement hash
```

Every problem declares whether it seeks:

- `Exists`
- `ForAll`
- `Classify`
- `Optimize`
- `NoGo`
- `Counterexample`

The bound and equivalence relation are part of the theorem statement, not run configuration hidden in a log.

## 5. Certificate families

### Witness certificate

An exact finite object plus a checker theorem proving it satisfies the predicate.

### Counterexample certificate

A witness to the negation, optionally with a shrink/minimality trace.

### Exhaustion certificate

A canonical enumeration description and proof that every bounded object is generated or equivalent to a generated representative.

### SAT/SMT certificate

An accepted proof format such as a resolution/DRAT/LRAT-style trace, or a smaller domain-specific certificate derived from the solver output and checked independently.

### Classification certificate

A list of representatives, per-representative property proofs, pairwise inequivalence evidence, and coverage proof.

### Bounded optimum certificate

A feasible witness at value `v` plus an exhaustion/no-go certificate for all strictly better values.

## 6. Architecture

```text
formal bounded problem
        │
        ├──► deterministic enumerator
        ├──► SAT/SMT/CSP compiler
        ├──► stochastic/evolutionary generator
        └──► domain-specific search
                    │
                    ▼
             candidate/trace stream
                    │
                    ▼
        exact decoder and independent checker
                    │
                    ▼
          Lean witness/coverage/no-go checker
                    │
                    ▼
              certified finite theorem
```

Candidate generation and coverage certification are separate. A stochastic search can find witnesses but cannot certify absence. A deterministic or proof-producing backend is required for no-go claims.

## 7. Components

### F1. Exact finite object schemas

Initial schemas:

- finite sets, functions, relations, and permutations;
- vectors and matrices over `ZMod p` and finite extensions;
- symplectic vector spaces and subspaces;
- Pauli/stabilizer tableaux;
- graphs and hypergraphs;
- bounded integer tuples;
- truth assignments and clauses;
- finite quantum state families with exact amplitudes.

Schemas require canonical serialization, validation, hashes, and Lean decoders.

### F2. Deterministic parallel enumeration

- Stable partitioning by prefix/rank.
- Exactly-once shard identifiers.
- Resumable checkpoints.
- Deterministic output ordering independent of worker count.
- Per-shard coverage records.
- Duplicate and isomorphism accounting.
- Early stopping for witness search without corrupting later completeness claims.

### F3. Symmetry and canonicalization

- Group actions on candidate spaces.
- Canonical representative function.
- Orbit/stabilizer calculations.
- Proof that every object maps to an equivalent representative.
- Pairwise representative inequivalence checks.
- Explicit record of symmetry assumptions and possible incomplete reductions.

Symmetry code is a frequent source of silent missing cases, so reduced and unreduced enumeration must agree on small fixtures.

### F4. Solver adapters

Provide a narrow interface:

```text
encode(problem) -> solver instance + decoder
solve(instance, budget) -> model | proof | unknown
decode(model) -> exact candidate
verify(candidate or proof) -> independent result
```

First adapters should be chosen from campaign needs rather than breadth. SAT plus custom Rust enumeration is enough for Campaign B.

### F5. Finite falsification service

Transport and statement-vetting need a low-latency API:

- identify finite binders and bounded instances;
- instantiate with configured model families;
- enumerate or solve for counterexamples;
- shrink witnesses;
- return exact Lean-readable terms;
- record what was tried so “no counterexample found” is never mistaken for proof.

### F6. Coverage and no-go checking

Coverage strategies include:

- direct cardinality equality;
- rank/unrank bijection;
- recursive partition proofs;
- symmetry-orbit coverage;
- proof-producing SAT unsatisfiability;
- branch-and-bound certificates;
- interval/rational upper bounds composed with finite search.

Each strategy has a small checker and an explicit trusted-base statement.

### F7. Candidate lifecycle integration

Search results enter the common campaign schema with:

- problem and statement hashes;
- bounds;
- shard and seed provenance;
- candidate encoding;
- independent check;
- Lean result;
- novelty and literature status;
- cost;
- final scientific interpretation.

## 8. Public API

```python
space = fa.finite.symplectic_spaces(p=3, m=2)
problem = fa.FiniteProblem.exists(space, predicate)

run = fa.search.enumerate(problem, workers=16, budget=...)
candidate = run.first_witness()
cert = candidate.certify(session)

nogood = fa.search.sat(problem.negate()).prove_unsat(format="lrat")
checked = nogood.certify(session)

classification = fa.search.classify(space, equivalence=group_action)
classification.certify(session)
```

Result types distinguish `Found`, `Exhausted`, `UnsatCertified`, `Unknown`, `BudgetExceeded`, and `CoverageUnproved`.

## 9. Milestones

### M1 — Tiny exact witness path

- One finite object schema.
- Rust/Python candidate generator.
- Independent decoder/checker.
- Lean witness theorem.
- Corrupted and malformed witness tests.

### M2 — Deterministic exhaustive enumeration

- Stable shards and resumption.
- Coverage count proof.
- Positive and negative bounded predicates.
- Reproducibility across worker counts.

### M3 — SAT/no-go path

- Domain compiler.
- Model decoding.
- Proof-producing unsat or domain no-go certificate.
- Independent and Lean verification.

### M4 — Symmetry-reduced classification

- Canonical representatives.
- Reduced/unreduced agreement on small cases.
- Coverage and inequivalence artifacts.

### M5 — Campaign B integration

- Finite-field and stabilizer types.
- Known correspondence checks.
- Atlas transport to exact predicates.
- Candidate batches with equal-budget controls.
- Minimal counterexample output.

### M6 — Second-domain reuse

Choose one:

- a small quantum-code table gap;
- a bounded anomaly-free charge census;
- a finite duality classification.

Measure reused engine code versus new domain encoding.

## 10. Verification and controls

- Compare enumeration counts with direct brute force on tiny spaces.
- Run reduced and unreduced searches and compare orbit expansion.
- Inject known missing shards.
- Corrupt a SAT proof and require rejection.
- Seed known witnesses at last enumeration positions.
- Verify deterministic results across worker counts and interruption points.
- Cross-check finite-field arithmetic with a second implementation.
- Check candidate predicates in Rust/Python and Lean.
- Label all bounded theorems with exact bounds and equivalence policies.

## 11. Performance and scaling

- Search workers operate on immutable problem fingerprints.
- Shards write append-only result records.
- A coordinator may stop witness searches but cannot mark exhaustion until every shard has a certified terminal state.
- Hot candidate predicates can be generated from verified definitions once `emit-rust` matures; until then differential tests guard the two implementations.
- Symmetry reduction is introduced only after plain enumeration establishes small-case truth.

## 12. Acceptance criteria

- A bounded witness can travel from Atlas candidate to Lean theorem without manual transcription.
- An interrupted multiworker exhaustion run resumes exactly.
- Coverage gaps and unsupported symmetry reductions cannot produce a no-go theorem.
- Minimal counterexamples are exact and replayable.
- Campaign B can compare Atlas-directed and control candidate arms under identical finite-search budgets.
- A second scientific domain reuses the engine's schemas, shard protocol, and certificate envelope.

## 13. Risks and responses

| Risk | Response |
|---|---|
| State space explodes | Symmetry, SAT/SMT, branch bounds, partial-results publication |
| Symmetry drops cases | Reduced/unreduced differential tests and coverage proofs |
| Solver does not emit proofs | Treat as witness-only or derive a smaller domain certificate |
| Search and Lean encodings disagree | Canonical schema, two decoders, differential generated cases |
| Bounded result is overgeneralized | Bounds embedded in theorem names, types, and publication prose |
| Parallel run loses provenance | Immutable shards, exactly-once journal, content-addressed outputs |

## 14. Scientific deliverables

- Exact finite-field/stabilizer correspondence and counterexample artifacts.
- Certified small quantum-structure classifications.
- A reusable bounded no-go pipeline.
- An open corpus of finite scientific candidates with exact verdicts.
- Follow-on applications to codes, anomaly censuses, dualities, and finite model boundaries.
