# Ferris–Howard Frontier Research Development Plan

**Status:** Draft 0.1  
**Purpose:** Build the minimum complete laboratory needed to conduct, certify, and publish novel Lean-native physics research  
**Parent charter:** [README.md](README.md)

## 1. Program objective

The development objective is not to implement every API imagined in the repository. It is to construct a sequence of research capabilities in which each completed layer enables a concrete scientific campaign and each campaign determines what the next layer must become.

The program is successful when it repeatedly converts a frontier question into one of:

- a new Lean theorem;
- a new certified quantitative bound;
- a new exact witness or exhaustive no-go;
- a new theory correspondence or located analogy boundary;
- a new effective model with an explicit regime and error;
- a corrected or disambiguated scientific claim;
- a reusable scientific engine adopted by another campaign or community.

## 2. Starting point

The repository already contains a substantial authoring and extraction foundation:

- Ferris–Howard syntax-to-syntax macros;
- source-span-aware checking;
- clean Lean emission and round-trip comparison;
- canonical statement encoding and freeze hashes;
- statement/proof dependency extraction;
- a Rust graph and first-order structural index;
- prototype canonical equivalence, dictionary, transport, frontier, and home queries;
- small-model falsification;
- a basic MCP surface;
- a Python `Corpus` handle, currently under active expansion.

The following are not yet stable end-to-end research capabilities:

- versioned, reproducible campaign and corpus objects;
- environment deletion/overlay algebra;
- semantic relationship and consequence graphs;
- carrier-aware, re-elaborated minimal homes;
- Lean-elaborated transport with automatic falsification/proof routing;
- proof-shape retrieval and abstraction synthesis;
- exact rational/interval certificate kernels;
- persistent proof sessions, proof caching, and budgeted search;
- complete statement-validity dossiers;
- scientific campaign artifacts and publication manifests;
- `Effective`, `resolve`, or `envelope` implementations.

The current working tree is active. Phase 0 begins only after ongoing work is complete.

## 3. Development laws

### Research pull, not speculative push

Every new API or engine component must name the campaign question it unblocks. Infrastructure without a near-term scientific consumer remains a design note.

### Search dirty, certify clean

Candidate generation may use unverified Rust, Python, external solvers, GPUs, language models, or stochastic search. Accepted results must reduce to a small Lean proof or independently checkable certificate.

### One result, multiple evidence channels

Where practical, combine:

- kernel proof;
- exact or interval computation;
- independent numerical implementation;
- known special cases;
- mutation and negative controls;
- external scientific review.

### Names follow evidence

Prototype result types state exactly what was computed. “Logical equivalence,” “minimal home,” “functor,” “transport,” “certified,” and “effective” are enabled only when their documented obligations are met.

### Failed research remains data

Counterexamples, timeouts, non-reconstructable numerical solutions, failed transports, and no-go certificates enter the research corpus with provenance.

### The model/nature boundary is explicit

Every physics result declares whether it is:

- pure mathematics;
- a theorem about a formal physical model;
- conditional on named physical postulates;
- a certified inference from declared data and statistical assumptions;
- or an empirical claim outside the prover.

## 4. Target architecture

```text
                         ┌──────────────────────────┐
                         │ Campaign and publication │
                         │ journal · costs · dossier│
                         └────────────┬─────────────┘
                                      │
       ┌──────────────────────────────┼──────────────────────────────┐
       │                              │                              │
       ▼                              ▼                              ▼
┌───────────────┐             ┌────────────────┐             ┌────────────────┐
│ Theory corpus │             │ Search engines │             │ External oracles│
│ Lean + metadata│            │ Rust/Python/etc│             │ data/literature │
└───────┬───────┘             └────────┬───────┘             └────────┬───────┘
        │                              │                              │
        ▼                              ▼                              │
┌──────────────────────────────────────────────┐                      │
│ Atlas: graph · similarity · home · dictionary│                      │
│ transport · frontier · proof shape · synthesis│                     │
└───────────────────────┬──────────────────────┘                      │
                        │                                             │
                        ▼                                             │
              ┌─────────────────────┐                                 │
              │ Candidate lifecycle │                                 │
              │ elaborate/falsify/  │                                 │
              │ search/reconstruct  │                                 │
              └──────────┬──────────┘                                 │
                         │                                            │
                         ▼                                            ▼
              ┌────────────────────────────────────────────────────────┐
              │ Lean proof and certificate kernels                     │
              │ exact finite · positivity · interval · spectra · error │
              └──────────────────────────┬─────────────────────────────┘
                                         │
                                         ▼
                              clean artifact + corpus update
```

## 5. Shared data contracts

The following contracts should land before campaign-specific schemas proliferate.

### Environment fingerprint

Identifies:

- Lean and Lake versions;
- Mathlib and Physlib revisions;
- Ferris–Howard and extractor revisions;
- imported package manifests;
- overlay hashes;
- relevant options and attribute registries;
- canonical statement ABI.

No campaign result is comparable across environments without an explicit compatibility verdict.

### Statement identity

Each statement carries:

- canonical encoding and version;
- source and emitted-Lean locations;
- freeze status;
- declared rigor/model tier;
- conventions and units;
- assumption-ledger references;
- corpus and environment fingerprints.

### Candidate record

Every generated research candidate carries:

- stable candidate ID;
- generating engine and version;
- source statements and graph paths;
- score components and rank;
- substitutions or dictionary rows;
- experimental arm and frozen batch;
- elaboration, falsification, proof, certificate, and novelty states;
- resource cost;
- final disposition.

### Certificate envelope

Every external-search result promoted for checking carries:

- certificate kind and schema version;
- exact payload hash;
- generating solver and settings;
- claimed statement hash;
- independent pre-check result;
- Lean checker declaration;
- final axiom footprint.

### Campaign journal

Append-only events with:

- timestamp and epoch;
- code/corpus fingerprint;
- deterministic seed lineage;
- operation and input hashes;
- result and artifact hashes;
- cost measurements;
- human decisions and justifications;
- gate transitions.

## 6. Phase plan

### Phase 0 — Stabilize and freeze the laboratory baseline

**Purpose:** Begin from one quiet, reproducible state after the current agent work lands.

Deliverables:

- review all in-flight changes;
- reconcile documentation with the code that actually landed;
- run the complete Lean, Rust, Python, emission, MCP, and extraction gates from a quiet workspace;
- resolve or ledger every failure;
- tag a research-baseline commit;
- record toolchain and corpus fingerprints;
- archive a small vendored mini-corpus for fast research-API tests;
- publish a current capability matrix using `implemented`, `partial`, `in flight`, and `proposed`.

Exit gate:

- one clean reproducible command checks the baseline;
- all campaign work can cite the exact baseline fingerprint;
- no active agent is modifying the same files used by the first implementation tranche.

### Phase 1 — Research substrate

**Purpose:** Make scientific runs durable, comparable, and budgeted.

Implementation tranche:

- `Config`, `Budget`, and `Cost` value types;
- environment and corpus fingerprints;
- `Campaign` context and append-only journal;
- deterministic seed derivation;
- frozen target/candidate lists;
- replay of completed read-only operations;
- structured candidate records;
- Arrow/JSONL export for analysis;
- baseline experiment runner;
- exact separation of prospective, retrospective, development, and burned targets.

Minimal APIs:

```python
with fa.campaign("resource-theory-season-1") as c:
    corpus = fa.Corpus.load(pin)
    c.freeze("corpus", corpus.fingerprint)
    c.note("question", text=...)
    result = corpus.similar(..., budget=...)
    c.record(result)
```

Exit gate:

- interrupting and resuming a campaign does not duplicate or lose completed work;
- every result can be traced to code, corpus, inputs, seed, and cost;
- baseline and Atlas result tables can be generated without bespoke parsing.

### Phase 2 — Close the Atlas scientific loop

**Purpose:** Turn Atlas from a query collection into a conjecture-and-boundary instrument.

Implementation tranche:

1. Repair normalized candidate lookup and add index-level differential tests.
2. Introduce explicit relation kinds: exact statement, normalized shape, proved `Iff`, implication, definitional rewrite, type equivalence, and heuristic analogy.
3. Make `home` carrier-aware.
4. Confirm candidate homes through hypothesis removal and re-elaboration.
5. Add dictionary coherence constraints and distinguish absent from below-threshold.
6. Make transport produce a typed candidate source file and elaborate it in a clean environment.
7. Route elaborated candidates through bounded falsification.
8. Record `exists`, `refuted`, `candidate`, `proved`, `ill_typed`, and `unknown` as distinct outcomes.
9. Add union-graph explanations for every proposed relation.
10. Add the first proof-shape signatures needed by Campaign A.

Exit gate:

- one command or Python call takes a dictionary row and source theorem through typed transport, falsification, and candidate recording;
- every output includes an evidence path and epistemic status;
- shuffled dictionaries and ill-typed transports are rejected rather than rendered as open research questions.

### Phase 3 — Minimum scientific validity layer

**Purpose:** Ensure generated and hand-authored physics statements are fit to investigate.

Implement the first practical `vet` subset:

- positive and negative controls;
- habitability/witness checks;
- statement mutation for hypothesis deletion, quantifier changes, inequalities, constants, and indices;
- junk-value and elaboration audit;
- independent executable differential checks where available;
- explicit adequacy and model-assumption status;
- assumption ledger;
- compact dossier artifact.

Double formalization and formal-to-informal comparison remain campaign procedures initially; they need not block the program on a universal automation API.

Exit gate:

- every flagship candidate has a machine-readable dossier;
- vacuous and intentionally weakened fixtures fail the gate;
- a theorem cannot silently acquire `rigor(certified)` through a statement-level assumption.

### Phase 4 — Launch Campaign A

**Purpose:** Use Atlas as a working theory-cartography instrument in quantum resource theory.

Development driven by the campaign:

- formal metadata for resources, free objects, free operations, monotones, conversion relations, catalysts, and asymptotic rates;
- multi-theory dictionary support;
- coherent row constraints;
- minimal-home reporting over a resource-theory axiom lattice;
- candidate-batch generation and blinded expert review;
- fixed-budget proof/falsification routing;
- theory-map publication format.

Scientific exit:

- a reusable formal map of at least three resource theories;
- at least one transported theorem, one located analogy boundary, or one new shared-home theorem worthy of external review;
- a public negative-results ledger if no novel theorem survives.

### Phase 5 — Launch Campaign B and Engine 3

**Purpose:** Conduct the first prospective Atlas-directed expedition at the finite-field/stabilizer interface.

Implementation tranche:

- exact finite-space descriptions;
- deterministic parallel enumeration;
- SAT/SMT adapter with proof/witness import;
- finite witness and exhaustion certificates;
- minimal counterexample shrinking;
- prime-power finite-field and symplectic data adapters;
- stabilizer/Clifford exact representations;
- candidate novelty workflow separated from mathematical certification.

Scientific exit:

- complete known-row bridge for the bounded corpus;
- frozen prospective candidate batches;
- one new theorem, bounded no-go, or structurally informative counterexample submitted for domain review;
- exact accounting of useful-result yield and cost.

### Phase 6 — Engine 2 and Campaign C

**Purpose:** Establish certified positivity as a shared theorem-producing backend.

Implementation tranche:

- exact rational scalar and matrix interchange;
- Lean LDLᵀ/PSD checker;
- sparse certificate schema;
- floating-point SDP import and rational reconstruction;
- residual and duality-gap validation;
- symmetry reduction with reconstruction proof;
- NPA level-1 problem compiler;
- independent checker path;
- first verified I3322 bound;
- quantum-mechanical moment/bootstrap adapter.

Scientific exit:

- a kernel-checked nontrivial Bell bound beyond CHSH;
- reproducible solver-to-certificate-to-Lean pipeline;
- either an improved certified bound or a documented obstruction explaining why the targeted improvement is unavailable at the chosen level.

### Phase 7 — Engine 4: validated spectra and dynamics

**Purpose:** Extend exact certificate work into continuous and infinite-dimensional problems.

Sequence:

1. interval scalar arithmetic and expression evaluation;
2. polynomial/root enclosures;
3. matrix eigenvalue and singular-value enclosures;
4. spectral discretization certificates;
5. parameter-box coverage;
6. tail and truncation theorems;
7. validated trajectories, contraction maps, and invariant structures.

First consumers should be selected from actual readiness:

- a finite Couette or Orr–Sommerfeld spectral certificate;
- a photonic or solid-state band enclosure;
- a small validated orbit or contraction theorem.

Do not claim a continuum threshold until parameter coverage and adequacy are proven.

### Phase 8 — Persistent proving and discovery algorithms

**Purpose:** Improve throughput in response to real campaign bottlenecks.

Prioritized algorithms:

1. canonical proof cache;
2. persistent `Session`/`GoalState` and budgeted portfolios;
3. X1 stuck-goal clustering and missing-lemma synthesis;
4. X3 proof-shape retrieve-and-replay;
5. X2 equality saturation where normalization is the measured bottleneck;
6. X4/X5/X7/X8 only when campaign traces identify their intended failure mode.

Exit gate:

- each promoted algorithm beats the pre-registered baseline on the campaign workload that motivated it;
- algorithms that do not improve scientific throughput remain experimental rather than entering the trusted workflow.

### Phase 9 — Engine 5: Effective-Theory Synthesis

**Purpose:** Generalize from real certified approximations into a compositional calculus.

Prerequisites:

- at least three independently useful approximation artifacts;
- explicit regime and observable-indexed error theorems;
- measured cost functions;
- at least one multi-stage composition performed manually and checked in Lean.

Implementation sequence:

- `SystemClass`, `Observable`, `Regime`, `ErrorField`, `CostModel`, and `Effective`;
- identity and composition with error/cost laws;
- registry of certified morphisms;
- manual envelope search;
- automated constrained path search;
- residual records and minimal-interface analysis;
- `resolve` recognition and attribution adapters;
- promotion and obstruction certificates only after concrete examples exist.

Scientific exit:

- a composed certified effective model that answers a real scientific question more cheaply than direct analysis;
- a published error/regime/cost artifact consumed by an external simulation or formalization workflow.

## 7. API rollout

### Research-critical first surface

- `Corpus.load(pin)` and fingerprints;
- `Campaign`, `Budget`, `Cost`;
- current graph and structural queries;
- typed `Candidate`, `Relation`, `Dictionary`, `TransportResult`;
- `without`, `overlay`, `diff`;
- bounded `falsify` and exact finite enumeration;
- compact `vet` and dossier;
- exact matrix and certificate types.

### Proving surface

- `Session`, `GoalState`, `SessionPool`;
- `prove`, `prove_many`, progress, cancellation;
- proof cache;
- MCP `try` and `minimize`.

### Numerical surface

- `RatMatrix`, `Interval`;
- `certs.ldlt`, `certs.exhaust`, `certs.interval_eval`;
- spectral and validated-dynamics certificates;
- external solver adapters.

### Long-range surface

- `mine`, `grade`, `converge`;
- `Trace` and certified blame;
- `Effective`, `resolve`, `envelope`;
- `emit-rust`, `emit-latex`, `publish`.

## 8. Verification strategy

Every engine should maintain four test layers.

### Unit and algebraic properties

Parser and certificate round-trips, structural laws, interval containment, matrix identities, deterministic enumeration, and schema-version rejection.

### Differential tests

Compare optimized engines with deliberately simple references on small inputs. Keep the reference implementation independent enough to catch shared assumptions.

### Adversarial negatives

Corrupted certificates, shuffled dictionaries, wrong dimensions, incompatible conventions, inadequate truncations, false inequalities, and changed frozen statements must fail for the intended reason.

### Scientific reproductions

Reproduce known published values and theorems before moving to unknown territory. These are instrument calibrations embedded in a research campaign, not the campaign's final objective.

## 9. Publication artifact

Every frontier result ships a self-contained pack containing:

- research question and preregistered scope;
- FH and emitted Lean statements;
- statement hashes and environment lock;
- proof or certificate;
- axiom and assumption ledger;
- validity dossier;
- external oracle comparisons;
- candidate-generation and search provenance;
- negative and failed neighboring candidates;
- exact and human-readable quantitative outputs;
- cost report;
- domain-expert review notes;
- reproducibility instructions requiring no network access where licensing permits.

## 10. Collaboration model

Each campaign needs distinct responsibilities, even when one person or agent fills several roles:

- **scientific lead:** owns the physical question and scope;
- **statement lead:** owns definitions, conventions, and adequacy;
- **cartography lead:** owns corpus structure and Atlas interrogation;
- **search lead:** owns heuristic computation;
- **certificate lead:** owns the small checker and reconstruction boundary;
- **adversarial reviewer:** attacks statements and certificates;
- **artifact lead:** owns reproducibility and publication packaging;
- **external domain reviewer:** assesses whether the formal question and novelty claim matter to the field.

The answer-key or blinded-target custodian must not implement the ranking method being evaluated in the same epoch.

## 11. Risk register

| Risk | Consequence | Response |
|---|---|---|
| Formal corpus too thin | Atlas sees syntax artifacts instead of physics | Expand only load-bearing clusters; measure representation sensitivity |
| Dictionary rows are incoherent | Attractive but meaningless transports | Global constraints, typechecking, shuffled controls, expert review |
| Proof automation dominates time | Candidates accumulate without closure | Exact finite/certificate routes first; proof cache and sessions later |
| Floating-point certificate cannot be rationalized | Numerical result cannot become theorem | Better conditioning, facial reduction, interval fallback, honest obstruction |
| Finite proxy does not represent continuum | Overclaimed physics | Named adequacy theorem; keep finite result as finite result |
| Agent silently changes a claim | Invalid research artifact | Frozen statements, hash checks, mutation, fresh recheck |
| Results are true but already known | No novelty | Separate mathematical verification from literature review; publish map/service value honestly |
| Toolchain drift breaks artifacts | Results become unreproducible | Environment lock, hermetic archive, external checker path |
| Grand roadmap diffuses effort | No engine reaches scientific maturity | One active engine-building campaign plus one bounded campaign at a time |
| Domain interpretation is wrong | Kernel certifies irrelevant mathematics | Independent statement construction and external scientific review |

## 12. Portfolio governance

At any time, permit:

- one primary frontier campaign;
- one engine-building campaign directly supporting it;
- one small upstream/formalization contribution;
- no more than one speculative long-range spike.

Open a new campaign only when it reuses an existing engine or explicitly funds a missing shared engine. Close or pause campaigns that cannot state a monotone sequence of publishable intermediate results.

## 13. Immediate post-agent action list

Do not execute this list until current work is complete.

1. Inspect and test the agent's final changes.
2. Reconcile the Python API documentation with the implemented surface.
3. Freeze the research baseline.
4. Create the capability matrix and environment manifest.
5. Specify the shared `Candidate`, `Relation`, `Campaign`, `Budget`, and `Cost` schemas.
6. Repair normalized candidate retrieval.
7. Design typed transport output and the candidate lifecycle.
8. Select the exact Resource-Theory Campaign A corpus boundary with a domain reviewer.
9. Freeze the initial scientific questions and known-anchor list.
10. Begin implementation with the smallest complete cartography-to-candidate loop.

## 14. Program-level completion criterion

The program has become a working frontier-research laboratory when all of the following have occurred:

1. Atlas has directed at least one prospectively chosen scientific question.
2. Search produced a nontrivial candidate or obstruction.
3. Lean accepted the resulting theorem or certificate under a published assumption set.
4. An independent domain expert judged the question and result scientifically meaningful.
5. The artifact was reproduced from its frozen package.
6. The result improved a second campaign by becoming reusable corpus or engine infrastructure.

The sixth condition is the decisive one. A single result is a project. A result that changes the productivity of the next result is a laboratory.
