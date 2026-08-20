# Engine 5 — Effective-Theory Synthesis

**Status:** Long-range implementation plan, draft 0.1  
**Scientific role:** Represent, compose, compare, and eventually discover controlled approximations between physical models  
**Activation gate:** Do not begin core implementation until at least three concrete certified approximation artifacts exist.

## 1. Objective

Build a calculus in which an effective theory is a machine-checkable morphism from a source model to a tractable model for named observables, valid in an explicit regime, with an explicit error and computational cost.

The ultimate operation is:

```text
atlas envelope(system, observables, regime, error_budget, cost_budget)
```

It should return a composition of certified model reductions reaching a tractable computation, together with the complete proof pedigree, composed error field, regime obligations, and cost.

## 2. Scientific questions enabled

- Which effective model is justified for this observable and parameter regime?
- How do errors compose across several approximations?
- Which discarded modes or terms dominate the final observable error?
- Can a derivation skeleton transfer to a new system class?
- Where is certified compression possible, and where is it obstructed?
- What minimal interface to an unresolved residual is actually required downstream?
- When should a recurring residual be promoted to a named mathematical object?

## 3. Required empirical foundation

The calculus must be induced from successful scientific artifacts rather than imposed in advance. Suitable founding examples include:

- a finite spectral truncation with tail theorem;
- a validated integration or averaging morphism;
- an NPA/SDP relaxation with a certified one-sided error or hierarchy relation;
- a TDVP projection-residual monitor;
- a finite Markov coarse-graining theorem;
- a Lieb–Robinson truncation bound;
- a Born–Oppenheimer or mean-field approximation with explicit regime and observable.

Before implementation, manually encode at least three examples and identify the genuinely shared fields and laws.

## 4. Non-goals

- Do not claim universal certified compression.
- Do not reduce physical validity to typechecking.
- Do not treat a scalar global error as sufficient when observables or sites have different sensitivity.
- Do not automate `resolve` through exotic mathematics before simple residual recognition and attribution work.
- Do not allow an empirical cost fit to masquerade as a proven asymptotic bound.
- Do not synthesize new “meta-axioms” before held-out reuse demonstrates compression.

## 5. Core objects

### System class

Describes a model family and admissible instances:

```text
SystemClass
state space
dynamics or equations
parameters
admissibility
symmetries/conventions
observables
solution/meaning relation
```

### Regime

A proposition or decidable certificate specifying where an effective map is valid. Regimes compose by conjunction and may include:

- scale separation;
- weak coupling;
- spectral gap;
- locality;
- time horizon;
- bounded energy or norm;
- truncation level;
- data/model assumptions.

### Observable map

Names what is preserved or approximated. Effective claims are observable-indexed because state-level approximation may be unnecessary or impossible.

### Error field

An error indexed by observables and optionally by sites, time, scale, modes, or certificate nodes:

```text
ErrorField Site Observable
bound(site, observable)
domain/regime
aggregation law
provenance
```

### Cost model

May contain both:

- proved upper bounds;
- measured campaign costs and empirical grades.

The two are never conflated.

### Effective morphism

```text
Effective Source Target
map_parameters
map_state_or_solution
map_observables
regime
error_field
cost_model
soundness theorem
pedigree
```

## 6. Algebra and laws

### Identity

Every system has an exact identity morphism with zero error and declared baseline cost.

### Composition

Given `A -> B` and `B -> C`, compose:

- parameter and state maps;
- observable maps;
- regime obligations;
- error propagation;
- cost.

Composition may require Lipschitz/sensitivity factors rather than simple error addition. The API therefore consumes an explicit error-composition theorem per morphism class.

### Refinement/order

Compare effective morphisms for the same source/question by:

- regime inclusion;
- pointwise error dominance;
- cost;
- assumption strength;
- evidence/rigor tier.

This creates a Pareto frontier, not necessarily one best model.

### Restriction and specialization

Specialize a morphism to a narrower regime, smaller observable set, or concrete system while preserving provenance.

### Uncertainty and model assumptions

Separate:

- certified numerical/discretization error;
- mathematical approximation error;
- uncertain physical parameters;
- model discrepancy;
- empirical/statistical uncertainty.

Only compatible error semantics may be composed automatically.

## 7. Engine components

### E1. Effective registry

A fingerprinted corpus of effective morphisms with:

- source/target system classes;
- regime predicates;
- observable coverage;
- error and cost forms;
- theorem/certificate references;
- dependencies and conventions;
- scientific review status.

### E2. Derivation cartography

Apply Theory Cartography to whole derivations:

- normalize proof and approximation steps;
- identify shared derivation skeletons;
- match scale separation, projection, residual control, and closure steps;
- find missing or stronger morphisms;
- propose reusable interfaces.

### E3. Envelope search

Model the registry as a constrained directed hypergraph. Search for paths satisfying:

- source/target compatibility;
- observable coverage;
- regime proof obligations;
- total error budget;
- cost budget;
- permitted assumption/rigor tier.

Return the Pareto set with complete composition derivations. Begin with exact enumeration/Dijkstra-like methods over a small registry; optimize only after real scale appears.

### E4. Residual interface analysis

When a derivation leaves an unresolved residual:

- represent it opaquely with certified properties;
- run minimal-home analysis on downstream uses;
- determine the minimal moments, signs, norms, asymptotics, or annihilator data required;
- avoid resolving details irrelevant to the target observable.

This is the first practical form of “adjoin the error early.”

### E5. Resolve

Implement in increasing ambition:

1. **Recognition:** match the residual to registered functions, operators, or certificate shapes.
2. **Attribution:** decompose observable error through adjoint/sensitivity weights or mode contributions.
3. **Spectrum:** expose singularity or modal content where a certified representation exists.
4. **Irreducibility/obstruction:** attach a proof that the residual cannot be represented in a declared basis or resource class.

Only the first two are initial engineering targets.

### E6. Refinement and promotion

A refinement operator carries a contraction theorem and modulus. Repeated application yields an anytime evaluator with certified stopping condition.

Promotion creates a named object only when:

- the residual recurs across independent derivations;
- the interface is stable across corpus growth;
- a characterizing theorem exists;
- held-out derivations gain measurable compression;
- the new object does not merely memorize the training corpus.

### E7. Compressibility cartography

Register positive and negative theorems about when effective descriptions exist:

- locality/gap/area-law implications;
- hardness and undecidability obstructions;
- required cost/error tradeoffs;
- regime boundaries.

These theorems prune impossible envelope requests and form a scientific “phase diagram of compressibility.”

## 8. Public API

```python
effective = fa.Effective(
    source=full_model,
    target=reduced_model,
    observables=[...],
    regime=...,
    error=...,
    cost=...,
    theorem=...,
)

result = corpus.envelope(
    system,
    observables,
    regime=regime,
    error_budget=epsilon,
    cost_budget=budget,
    permitted_rigor={"certified", "conditional"},
)

resolution = corpus.resolve(residual, methods=["recognize", "attribute"])
```

Results include explicit unresolved obligations and never silently widen regimes.

## 9. Milestones

### M0 — Artifact audit

- Select three concrete approximation artifacts.
- Encode their source, target, regime, observables, errors, costs, and assumptions manually.
- Identify common and incompatible semantics.
- Publish the schema decision record before implementation.

### M1 — Core type and identity/composition

- Lean definitions for the smallest shared structure.
- Identity.
- Two-stage composition.
- Error and regime composition theorems for the founding artifacts.
- L-RIGOR and L-REGIME enforcement.

### M2 — Registry and manual envelope

- Fingerprinted registry.
- Query by source, target, observable, and regime.
- Manually selected composition returned with a checked aggregate theorem.

### M3 — Automated envelope search

- Constrained path/Pareto search.
- Proof reconstruction for selected paths.
- Comparison against human-selected compositions.
- Explicit no-path and unproved-obligation results.

### M4 — Residual interface and recognition

- Opaque residual type.
- Minimal downstream interface analysis.
- Registry recognition.
- One example where full residual resolution is avoided because only a moment/sign is needed.

### M5 — Attribution and monitoring

- Observable-weighted residual decomposition.
- TDVP, discretization, or simulation-monitor consumer.
- Error field visualization and exact aggregate bound.

### M6 — Refinement and promotion

- One contraction-certified refinement process.
- Anytime evaluator extraction.
- One recurring residual promotion candidate evaluated on held-out derivations.

### M7 — Cross-domain envelope

- Compose artifacts originating in two different physics tracks.
- Demonstrate that the common calculus reduces new scientific implementation cost.

## 10. Founding application candidates

### TDVP error monitor

Source: exact many-body dynamics.  
Target: dynamics projected onto an MPS/variational manifold.  
Error: integrated norm of the projected-out residual under a proved stability theorem.  
Observables: selected state or local-observable distances.  
Cost: contraction and bond-dimension dependent.

### Spectral truncation

Source: continuum operator/problem.  
Target: finite spectral matrix.  
Error: residual plus tail enclosure.  
Observables: selected eigenvalues or stability form.  
Cost: basis size and parameter-cover complexity.

### Finite Markov coarse-graining

Source: detailed chain.  
Target: coarse chain.  
Error: observable or distribution-distance bound.  
Regime: lumpability/mixing assumptions.  
Cost: reduced state count.

These examples differ enough to prevent the core type from overfitting one numerical idiom.

## 11. Verification and controls

- Identity and associativity properties where semantics support them.
- Two independently derived error compositions.
- Regime narrowing/widening adversarial cases.
- Observable omitted from a morphism must block composition.
- Deliberately incompatible error semantics must not combine automatically.
- Manual and automated envelope outputs must prove the same aggregate theorem.
- Removing one registry edge must alter paths predictably.
- Cost predictions are compared with actual campaign measurements.
- Promotion candidates are evaluated on temporal and cross-domain held-out derivations.

## 12. Acceptance criteria

- The core type is induced from at least three real artifacts.
- A multi-stage effective model carries a Lean-checked composed regime and error.
- Envelope search returns a proof-producing Pareto set rather than an unexplained recommendation.
- The same source model receives different valid envelopes for different observables or budgets.
- An unavailable approximation returns a precise missing obligation or obstruction.
- At least one external simulation/formalization workflow consumes an exported effective artifact.

## 13. Risks and responses

| Risk | Response |
|---|---|
| Error semantics are not compositional | Typed error kinds and explicit composition theorems |
| Regimes become unreadable conjunctions | Named regime objects, minimization, implication graph |
| Search returns technically valid but useless models | Cost axis, empirical grade, Pareto output, user budgets |
| Registry becomes a museum | Envelope consumers, reuse metrics, active deprecation |
| Meta-abstractions memorize examples | Temporal/cross-domain held-out rent and compression tests |
| Physical model discrepancy is unquantified | Separate named field; never add it to certified numerical error silently |
| `resolve` scope becomes unbounded | Recognition and attribution first; advanced methods gated by real residuals |

## 14. Scientific deliverables

- A formal library of proof-carrying effective models.
- A certified TDVP, spectral, or coarse-graining error monitor.
- Composed model-reduction statements with inspectable error budgets.
- A queryable map of where approximations are justified or obstructed.
- A first `atlas envelope` result answering a real scientific question under stated resources.
- A foundation for novel work on certified compression and the boundary of tractable physical description.
