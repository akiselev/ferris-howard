# Engine 1 — Theory Cartography

**Status:** Implementation plan, draft 0.1  
**Scientific role:** Map formal theory space and turn structural relationships into precise research questions  
**First consumer:** [Campaign A](../campaigns/A-quantum-resource-theories.md)  
**Prospective consumer:** [Campaign B](../campaigns/B-finite-fields-stabilizers.md)

## 1. Objective

Build Atlas into a scientific cartography engine that can represent and interrogate several distinct kinds of relationship without conflating them:

- exact statement identity;
- definitional or presentation equivalence;
- proved logical equivalence or implication;
- shared abstraction or minimal theory;
- structural analogy;
- proof-strategy analogy;
- partially coherent theory dictionaries;
- failed transports and analogy boundaries;
- underexplored interfaces.

The engine should generate inspectable candidate theorems and research gaps, then follow each candidate through elaboration, falsification, proof, certification, novelty review, and corpus ingestion.

## 2. Scientific questions enabled

- Which apparently different theories instantiate the same mathematical architecture?
- Which theorem in one theory has no known counterpart in another?
- Which hypotheses are truly responsible for a phenomenon?
- Which reformulations of a claim are connected by proofs rather than resemblance?
- Where does a correspondence fail, and what minimal counterexample explains the failure?
- Which disconnected theory pairs share enough structure to justify a research campaign?
- Which repeated theorem and proof patterns deserve promotion to a new abstraction?

## 3. Current foundation

Reusable code already exists for:

- canonical statement encodings;
- dependency extraction with statement/proof lenses;
- normalized syntactic term DAGs;
- first-order anti-unification;
- structural postings and similarity ranking;
- canonical-form equivalence buckets;
- prototype dictionary, transport, frontier, and home queries;
- Python `Corpus` access, with additional query bindings currently in flight.

The existing implementation is the seed, not the final semantics. In particular:

- similarity lookup needs symmetric normalization and measured recall;
- equivalence does not yet follow proof-carrying `Iff`/implication edges;
- home is a static candidate and loses carrier identity;
- dictionary rows are selected independently rather than globally;
- transport is syntactic and does not establish Lean well-typedness;
- frontier is an uncalibrated heuristic;
- proof-shape and abstraction-synthesis indexes do not exist.

## 4. Non-goals

- Do not claim semantic equivalence from an embedding score.
- Do not build a universal ontology of mathematics before campaign data demands it.
- Do not require a learned model for the first complete engine.
- Do not attempt unrestricted automatic theorem proving inside the cartography engine.
- Do not hide uncertain or heuristic edges in the same result type as proved edges.

## 5. Core data model

### Declaration

```text
DeclId
name
kind
module/theory/cluster
statement hash and term
statement dependencies
proof dependencies
attributes: rigor, units, regime, roles, conventions
environment fingerprint
```

### Relation

```text
RelationId
left and right objects
kind
direction
evidence
normalization level
score components
proof/certificate references
generator/version
campaign and epoch
status
```

`kind` is closed and versioned:

- `ExactStatement`
- `PresentationEqual`
- `DefinitionalRewrite`
- `ProvedIff`
- `ProvedImplies`
- `TypeEquiv`
- `SharedInstance`
- `SharedHomeCandidate`
- `SharedHomeConfirmed`
- `StructuralAnalogy`
- `ProofShapeAnalogy`
- `DictionaryRowCandidate`
- `DictionaryRowConfirmed`
- `TransportRefuted`
- `TransportProved`

### Evidence

Evidence is a sum type rather than prose:

- declaration or proof-term locator;
- canonical equality witness;
- normalization trace;
- anti-unification skeleton and substitutions;
- dependency path;
- re-elaboration report;
- Lean theorem proving an edge;
- falsification witness;
- ranking feature vector;
- external-review annotation.

### Theory and cluster

Theory membership cannot remain only “the first two module path components.” Provide explicit, versioned cluster manifests with:

- included declarations or predicates;
- exclusions;
- theory roles;
- corpus fingerprint;
- provenance;
- whether membership is scientific, organizational, or automatically inferred.

## 6. Components

### C1. Corpus and environment algebra

- Fingerprinted `Corpus.load(pin)`.
- Copy-on-write `without`, `overlay`, and `diff`.
- Cluster manifests.
- Temporal and domain splits.
- Fast downstream re-elaboration after a deletion or overlay.
- Stable declaration handles across compatible corpus layers.

This supports counterfactual questions such as “what breaks if this abstraction is removed?” and “does adding this candidate reduce downstream proof cost?”

### C2. Multi-index retrieval

Maintain distinct indexes and expose their evidence separately:

1. Exact canonical statements.
2. Presentation-normalized statements.
3. Instance-erased statements.
4. Carrier-erased structural shapes.
5. Concrete and normalized subterms.
6. Dependency neighborhoods.
7. Proved rewrite/reformulation rules.
8. Proof-shape signatures.
9. Optional semantic embeddings as a baseline and candidate source, never as proof.

Ranking must accept custom scorers through the Python API, while every production result records the scorer code/version and complete feature vector.

### C3. Logical relationship graph

Extract and index:

- closed and parameterized `Iff` theorems;
- directional implication theorems;
- `Equiv` between types;
- named definitional rewrites;
- theorem specializations and instantiations;
- proof-carrying paths.

Parameterized rules require typed matching. When higher-order matching is unavailable, return an explicit unsupported/flex-head status rather than silently dropping the edge.

### C4. Minimal-home engine

Two stages:

1. **Candidate generation:** inspect proof/statement dependencies and the instance hierarchy while retaining the carrier each constraint applies to.
2. **Confirmation:** construct weakened declarations, re-elaborate them in isolated environments, and identify minimal successful assumption sets.

Output may be:

- a unique minimal home;
- several incomparable minimal homes;
- an unused hypothesis;
- a failed weakening with exact diagnostics;
- unknown because the search budget was exhausted.

The engine must support general axiom lattices, not only Lean typeclasses, so Campaign A can ask for a phenomenon's home in a resource-theory or GPT axiom space.

### C5. Coherent dictionary assembly

Dictionary construction is a constrained selection problem over candidate rows.

Constraints may include:

- type and role compatibility;
- object/morphism direction;
- relation preservation;
- shared substitutions;
- injectivity or many-to-one policy;
- composition consistency;
- compatibility with confirmed rows;
- penalties for scoped anti-unification variables;
- explicit unmatched and below-threshold states.

Return several Pareto-optimal dictionaries where ambiguity is real. Never manufacture uniqueness.

### C6. Typed transport

Transport stages:

1. Select a confirmed or candidate dictionary row.
2. Match the source statement with typed substitutions.
3. Construct the target syntax and structural term.
4. Emit a fresh candidate declaration with provenance.
5. Elaborate in a clean Lean environment.
6. Search for an existing equivalent or stronger result.
7. Run bounded falsification and exact finite models.
8. Route survivors to proof/certificate engines.
9. Record result as existing, refuted, proved, open, ill-typed, or unknown.

The transport result includes the minimal counterexample when refuted and the proof/certificate when confirmed. Both enrich the dictionary.

### C7. Frontier and agenda engine

Replace a single heuristic score with an explicit model:

- structural similarity distribution;
- relation and citation traffic;
- corpus size and formalization depth;
- shared-object and shared-proof-shape counts;
- known-contact density;
- score uncertainty;
- matched control pairs;
- historical or prospective yield.

`frontier` should rank research interfaces and explain which structures create the score. Campaigns allocate equal budgets to selected pairs and matched controls; verified yield updates future calibration.

### C8. Proof-shape and abstraction synthesis

Proof-shape signatures should capture features such as:

- induction/recursion structure;
- contradiction and minimal-counterexample patterns;
- exceptional-set bounding;
- positivity/certificate use;
- compactness or choice principles;
- normalization and rewriting pipelines;
- theorem dependencies after administrative constants are erased.

Abstraction synthesis consumes repeated statement/proof clusters or deletion failures and proposes:

- a parameterized theorem;
- a trait/class with laws;
- a reusable helper lemma;
- a new dictionary row;
- a residual interface.

Candidates are accepted only after held-out reuse and compression measurements.

## 7. Public API

```python
corpus = fa.Corpus.load(pin)

corpus.similar(query, indexes=[...], scorer=..., k=...)
corpus.relations(query, kinds=[...])
corpus.why(a, b, evidence="all")
corpus.home(stmt, lattice=..., confirm=True, budget=...)
corpus.dictionary(a, b, constraints=..., alternatives=...)
corpus.transport(stmt, dictionary=row, falsify=True, budget=...)
corpus.frontier(clusters=..., model=..., controls=...)
corpus.without(...).elaborate_downstream(of=...)
corpus.synthesize(cluster, objective="compression", budget=...)
```

Every returned object carries `.cost`, `.evidence`, `.environment`, and `.status`.

## 8. Milestones

### M1 — Honest structural retrieval

- Repair candidate normalization.
- Add index-specific unit and differential tests.
- Record full score vectors.
- Bind stable results in Python.
- Establish simple lexical, structural, and embedding baselines.

### M2 — Relationship algebra

- Versioned relation kinds.
- Proof-carrying `Iff` and implication edges.
- Union-graph `why`.
- Explicit heuristic/proved boundary.

### M3 — Home and dictionary

- Carrier-aware home candidates.
- Re-elaboration confirmation.
- Coherent dictionary solver.
- Missing-versus-low-score classification.

### M4 — Closed transport loop

- Candidate source generation.
- Clean elaboration.
- Existing-result search.
- Falsification route.
- Proof/certificate handoff.
- Candidate ledger integration.

### M5 — Physics cartography

- Campaign A multi-theory support.
- Campaign B finite-field/stabilizer bridge.
- Scientific map artifact and expert annotation workflow.

### M6 — Proof shapes and discovered abstractions

- Proof-shape index.
- Deletion experiments.
- Abstraction proposals.
- Held-out reuse and compression accounting.

## 9. Acceptance criteria

The engine is research-ready when:

- every edge is typed by evidence class;
- every candidate is reproducible from a frozen corpus and scorer;
- transport outputs elaborate or fail with actionable diagnostics;
- false shuffled mappings are rejected at a substantially earlier rate than genuine mappings;
- minimal-home claims are confirmed by re-elaboration;
- dictionary reports distinguish absent, unsupported, low-ranked, and contradicted;
- a campaign can proceed from an Atlas finding to a theorem or minimal counterexample without an ad hoc data path;
- a second campaign reuses the same relation and candidate schemas unchanged.

## 10. Risks and responses

| Risk | Response |
|---|---|
| Lexical leakage dominates | Neutral-name copies, renaming metamorphics, explicit lexical baselines |
| Coarse erasure creates nonsense | Evidence-separated levels, type/role constraints, false-neighbor controls |
| Higher-order rules explode | Restricted typed patterns first; report unsupported cases |
| Home search is combinatorial | Lattice-guided pruning, cached re-elaboration, return incomparable minima |
| Dictionary solver memorizes known rows | Frozen epochs, unseen theories, prospective candidate batches |
| Frontier favors large clusters | Size-matched controls and normalized uncertainty-aware scores |
| Agent explanations exceed evidence | Generate explanations from stored paths/substitutions, not free prose |

## 11. Scientific deliverables

- A reusable, versioned theory-map format.
- Resource-theory and finite-field/stabilizer atlases.
- Published analogy boundaries with minimal counterexamples.
- Transport-generated theorem candidates with complete provenance.
- At least one new or newly unified theorem resulting from cartographic interrogation.
- A growing corpus of failed and successful relationships suitable for future learned ranking without compromising the symbolic evidence layer.
