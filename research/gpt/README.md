# Ferris–Howard Frontier Research Program

**Status:** Research charter, draft 0.1  
**Scope:** A Lean-native laboratory for doing frontier physics and mathematical physics  
**Activation condition:** Begin execution only after the current in-flight repository work is complete, reviewed, and frozen into a reproducible baseline.

## North star

Ferris–Howard exists to make Lean an active medium for scientific discovery, not merely a place where finished mathematics is transcribed after the fact.

The program's ambition is:

> **Produce new mathematical physics with machine-checkable consequences: new theorems, certified bounds, no-go results, structural correspondences, effective models, corrected claims, and research-grade computational instruments.**

Atlas is the cartographic and conjectural instrument inside that laboratory. Ferris–Howard supplies readable formal statements and publication artifacts. Lean supplies the trust floor. Rust, Python, SAT/SMT, numerical optimization, and scientific computing supply the exploratory power. Agents operate the loop, but nothing becomes a scientific result until it has the appropriate proof, exact certificate, validated enclosure, or explicitly named physical assumption.

This is not a program whose ultimate deliverable is evidence that Atlas is clever. Atlas earns its place by directing research that creates durable scientific knowledge.

## The scientific thesis

Physics repeatedly advances through the same structure:

1. A difficult theory is related to a better-understood theory.
2. A shared mathematical shape suggests a bound, duality, approximation, invariant, or equation.
3. Symbolic or numerical exploration produces a candidate.
4. Counterexamples, limiting cases, and computation refine or kill it.
5. A survivor becomes a theorem, certificate, controlled approximation, or conditional physical claim.

Ferris–Howard mechanizes that cycle:

```text
formal theory corpora
        │
        ▼
Atlas maps structures, correspondences, and missing rows
        │
        ▼
agents generate conjectures and bounded search problems
        │
        ▼
enumeration · SAT/SMT · SDP/SOS · symbolic algebra · validated numerics
        │
        ▼
Lean checks proofs, witnesses, bounds, no-gos, and assumption-dependent deductions
        │
        ▼
the result enters the corpus and changes the next search
```

The loop is scientific because every stage leaves inspectable evidence and because negative outcomes remain useful. A refuted transport locates the boundary of an analogy. A failed rational reconstruction exposes numerical fragility. An obstruction theorem maps a region no search should revisit. A discrepancy with a paper or reference table becomes a precise audit target.

## What counts as a frontier result

The program recognizes several equally legitimate scientific products.

### New theorem

A statement proposed through cartography, transport, synthesis, or scientific reasoning and proved in Lean under an explicit assumption set.

### New certified bound

A quantitatively improved or first machine-checked enclosure for a physical or mathematical quantity: a Bell value, stability threshold, eigenvalue, energy, convergence radius, simulation error, response bound, or exclusion region.

### New no-go

A certified obstruction excluding a family of models, operators, dualities, approximations, transformations, or parameter regions.

### New structural map

A coherent correspondence between theories, including the rows that exist, the hypotheses that make them work, and the places where the analogy fails.

### New effective model

A tractable model connected to a harder model by a machine-checkable regime and observable-indexed error theorem.

### New referee result

A disputed, ambiguous, or numerically trusted scientific claim reconstructed with explicit definitions, assumptions, convention choices, error budgets, and machine-checkable consequences. A corrected theorem or localized specification error is a research result.

### New scientific instrument

A reusable verified engine—positivity certification, interval spectral analysis, exhaustive finite search, proof-carrying simulation monitoring—that makes previously inaccessible questions routinely answerable.

## The laboratory architecture

The system has five scientific engines. They are designed as reusable research capabilities rather than one-off support for individual papers.

| Engine | Scientific purpose | Implementation plan |
|---|---|---|
| 1. Theory Cartography | Map theories, relationships, missing structures, and transported conjectures | [Engine 1](engines/01-theory-cartography.md) |
| 2. Certified Positivity | Turn SDP/SOS, moment, spectral, and quadratic-form evidence into theorems | [Engine 2](engines/02-certified-positivity.md) |
| 3. Certified Finite Search | Search finite scientific spaces aggressively and certify witnesses or exhaustion | [Engine 3](engines/03-certified-finite-search.md) |
| 4. Validated Spectra and Dynamics | Enclose spectra, roots, trajectories, invariant structures, and continuum tails | [Engine 4](engines/04-validated-spectra-dynamics.md) |
| 5. Effective-Theory Synthesis | Compose models with explicit regimes, errors, costs, and proof pedigrees | [Engine 5](engines/05-effective-theory-synthesis.md) |

The engines share a common research substrate:

- frozen formal statements and canonical hashes;
- versioned corpus and environment fingerprints;
- exact and interval-valued certificate types;
- persistent Lean proof sessions and independent fresh-environment checks;
- campaign journals, deterministic seeds, and cost accounting;
- statement-validity dossiers and assumption ledgers;
- generated Lean and human-readable publication artifacts;
- external numerical and literature oracles that remain independent of the certifying kernel.

## The opening research campaigns

Three campaigns inaugurate the program. Together they exercise structural discovery, exact finite search, and certified continuous optimization.

| Campaign | Frontier question | Plan |
|---|---|---|
| A. Quantum Resource-Theory Cartography | Which theorems, obstructions, and minimal axiom systems transfer among entanglement, coherence, magic, asymmetry, and thermodynamics? | [Campaign A](campaigns/A-quantum-resource-theories.md) |
| B. Finite Fields and Stabilizer Quantum Mechanics | What quantum structure corresponds to Frobenius, Galois action, and other unmatched arithmetic structure over finite fields? | [Campaign B](campaigns/B-finite-fields-stabilizers.md) |
| C. Certified Bell and Bootstrap Bounds | Can rational certificates turn floating-point nonlocality and bootstrap bounds into theorems and then improve them? | [Campaign C](campaigns/C-certified-bell-bootstrap.md) |

Campaign A builds a multi-theory scientific map and seeks transferred results. Campaign B points Atlas at a prospective interface where exact exhaustive testing is possible. Campaign C establishes the universal positivity engine as a theorem-producing instrument with direct physics output.

## How research is conducted

Every campaign follows one laboratory cycle.

### 1. Cartograph

Formalize the theories, objects, maps, assumptions, conventions, regimes, and known results needed to state the question. Do not prematurely force distinct theories into one abstraction; their similarities and differences are data for Atlas.

### 2. Interrogate

Ask Atlas for:

- structurally related statements;
- coherent dictionary rows;
- minimal homes and hypothesis deltas;
- missing entries;
- logical reformulations and consequence paths;
- high-structure, low-traffic frontiers;
- transported statements;
- recurring proof, residual, and certificate shapes.

### 3. Generate

Convert findings into exact scientific objects:

- a conjectured theorem;
- a finite search space;
- an SDP or SOS problem;
- a candidate invariant or duality map;
- a trial field or witness;
- an explicit effective-model morphism;
- a bounded no-go question.

### 4. Attack

Use the strongest appropriate exploratory machinery. Search is allowed to be heuristic, approximate, massively parallel, or external to Lean. Candidate generation is not part of the trusted base.

### 5. Certify

Promote a surviving candidate through the appropriate route:

- a direct Lean proof;
- an exact finite witness checked by `decide` or a small kernel;
- a rational certificate;
- an interval enclosure;
- an exhaustive finite no-go;
- a theorem conditional on named physical postulates;
- an explicit, ledgered adequacy or model assumption when first-principles rigor is unavailable.

### 6. Publish and recurse

Ship the result with its formal source, clean Lean artifact, certificate, assumption ledger, independent checks, provenance, and scientific explanation. Upstream reusable mathematics to Mathlib or Physlib. Add the result and its failed neighbors to the corpus so that the next Atlas pass searches a genuinely richer world.

## Scientific controls are laboratory practice

Calibration, held-out targets, negative controls, independent implementations, mutation, and blinded review remain mandatory. Their role is the same as calibration standards and control samples in an experimental laboratory: they keep the instrument pointed at reality while the laboratory pursues larger questions.

They are not the program's north star. They are what lets the program make ambitious claims responsibly.

The standing controls are:

- freeze questions before expensive search;
- separate candidate generation from certification;
- compare Atlas-directed work with credible baselines and matched controls;
- record negative candidates and minimal counterexamples;
- prevent evaluated targets from returning to the held-out pool;
- distinguish mathematical truth, model-conditional truth, numerical evidence, and claims about nature;
- require independent scientific review of formal definitions and physical conventions;
- disclose agent involvement and preserve the complete research ledger.

## The common scientific object

Every serious result should eventually be representable as a record containing:

```text
claim
formal statement hash
theory and model
assumptions and conventions
validity regime
observables
proof or certificate
error or enclosure
computational cost
external oracle checks
provenance and campaign history
publication status
```

For exact mathematics, the error field is zero. For effective physics, the assumptions, regime, and error are first-class. For experimentally inferred claims, Lean verifies the conditional inference from declared data and statistical model; it does not pretend to prove nature.

## Relationship to the existing repository

This program builds on, but does not silently inherit the claims of, the existing design documents:

- [Atlas design](../../atlas.md)
- [Atlas validation protocol](../../atlas-validation.md)
- [Agent interface](../../agent-interface.md)
- [Program roadmap](../../ROADMAP.md)
- [Statement validity](../fh-statement-validity.md)
- [Effective Calculus](../fh-meta-effective.md)
- [Physics research round 2](../physics/fh-physics-round2.md)
- [Quantum research program](../physics/fh-quantum-research.md)
- [Python research API](../python-api-reference.md)

Where those documents use names such as “equivalence,” “home,” “dictionary,” “transport,” “frontier,” or “Effective,” the implementation plans in this directory specify the evidence required before the semantic reading of the name is enabled. Prototypes may expose narrower operations, but their result types must say exactly what was computed.

## Program sequence

The full dependency-ordered execution plan is [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md). Its high-level sequence is:

1. Stabilize the current implementation and freeze a reproducible research baseline.
2. Build campaign journaling, corpus fingerprints, exact result schemas, and the minimum validity layer.
3. Close the Atlas loop from relationship proposal through elaboration, falsification, proof/certification, and corpus ingestion.
4. Launch Campaign A and build a real theory dictionary under active scientific use.
5. Launch Campaign B as the first prospective Atlas-directed frontier expedition.
6. Build the rational positivity kernel and launch Campaign C.
7. Generalize successful certificate machinery into Engines 3 and 4.
8. Construct Engine 5 from real approximation artifacts, not speculative interfaces.
9. Expand into plasma, fluids, quantum chemistry, photonics, condensed matter, celestial mechanics, and lattice gauge theory as engine reuse makes each new campaign cheaper.

## What we deliberately do not do

- We do not start every field named in the roadmap.
- We do not call syntactic similarity a physical correspondence.
- We do not call a generated statement a discovery before checking novelty and correctness.
- We do not hide continuum, model, convention, or adequacy gaps behind successful finite computation.
- We do not require search code itself to be verified when a small independent checker can certify its outputs.
- We do not weaken a frozen scientific question to manufacture success.
- We do not confuse a theorem about a model with an unconditional fact about nature.
- We do not build the Effective Calculus in the abstract before concrete effective-model certificates exist.

## The intended destination

A physicist should eventually be able to bring Ferris–Howard:

- an analogy between theories;
- an uncertain numerical bound;
- two papers that appear to disagree;
- an approximation with folklore error bars;
- an unexplained structural coincidence;
- a table of candidates nobody has certified;
- a simulation whose trustworthy regime is unclear;
- or a theory whose neighboring mathematics has never been systematically searched.

The laboratory should return a research path ending in something that can survive scrutiny:

- a theorem;
- a certificate;
- a counterexample;
- an obstruction;
- a theory dictionary;
- a formal dependency map;
- a certified effective model;
- or an explicitly bounded statement about a declared physical model.

The overarching ambition is therefore:

> **Lean as an active medium for frontier physics, Atlas as the intelligence that maps and interrogates theory space, and proof-carrying computation as the bridge from speculative search to durable scientific knowledge.**

## Document map

- [Full development plan](DEVELOPMENT_PLAN.md)
- [Engine 1: Theory Cartography](engines/01-theory-cartography.md)
- [Engine 2: Certified Positivity](engines/02-certified-positivity.md)
- [Engine 3: Certified Finite Search](engines/03-certified-finite-search.md)
- [Engine 4: Validated Spectra and Dynamics](engines/04-validated-spectra-dynamics.md)
- [Engine 5: Effective-Theory Synthesis](engines/05-effective-theory-synthesis.md)
- [Campaign A: Quantum Resource-Theory Cartography](campaigns/A-quantum-resource-theories.md)
- [Campaign B: Finite Fields and Stabilizer Quantum Mechanics](campaigns/B-finite-fields-stabilizers.md)
- [Campaign C: Certified Bell and Bootstrap Bounds](campaigns/C-certified-bell-bootstrap.md)

## Revision rule

This charter should change when scientific experience changes it. Each engine and campaign records actual costs, failures, and reusable artifacts. At the end of every campaign season, revise priorities from those measurements. Preserve superseded predictions in history; do not rewrite them into apparent foresight.
