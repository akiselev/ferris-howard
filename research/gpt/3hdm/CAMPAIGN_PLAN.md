# 3HDM agent-directed research campaign

> Status: plan only, 2026-08-02. Do not start these experiments until the
> in-flight Atlas/cartography implementation is complete, reviewed, and frozen.

## 1. Mission

Build a reusable formal and computational laboratory for multi-Higgs vacuum
stability, calibrate it on the new $\Delta(54)$ eight-vertex result, use it to
resolve the full-potential boundary exactly, and then direct Atlas toward a real
open stability problem in the $\mathbb Z_2\times\mathbb Z_2$ 3HDM.

The campaign is designed to answer two different questions:

1. **Can FH/Atlas conduct reliable formal physics research?** The calibration
   target measures statement control, theory mapping, counterexample behavior,
   certificate generation, and Lean replay.
2. **Can that machinery produce a new scientific result?** The transfer target
   asks it to find exact obstructions or conditions not supplied by the source
   literature.

The campaign does not begin with a claim to validate. It begins with an intent
and competing hypotheses. A failed candidate, a corrected definition, or a
minimal counterexample is a successful experiment if it reduces uncertainty.

## 2. Scientific questions

### Calibration questions

- Are the six published orbit inequalities valid for all three Higgs doublets?
- Do they define exactly the claimed eight-vertex convex hull?
- Is every claimed vertex physically realizable?
- Do the eight coupling forms give necessary and sufficient conditions for
  quartic non-negativity and strict positivity?
- Which vertices are neutral and which are charge-breaking?

### Refinement questions

- With $V=\mu N+V_4$, does $h_i\ge0$ characterize full boundedness when
  $\mu<0$, or only non-negativity of $V_4$?
- Is the proposed full classification
  $(\mu\ge0\land\forall i,h_i\ge0)\lor(\forall i,h_i>0)$ exact?
- Can the global infimum and minimizing orbit faces be certified exactly?
- Does the source’s terminology require a mathematical correction, a wording
  clarification, or no change after convention is taken into account?

### Transfer questions

- Which part of the $\Delta(54)$ proof survives when its symmetry is relaxed?
- Which missing Gram/orbit constraints explain false positives in existing
  necessary-condition levels for the $\mathbb Z_2\times\mathbb Z_2$ model?
- Can Atlas turn numerical counterexamples into rational/algebraic witnesses?
- Can those witnesses suggest a new facet, sum-of-squares identity, copositivity
  condition, or exact decomposition?
- Can any proposed condition be proved in Lean and shown independent of or
  stronger than the existing condition set?

## 3. Research protocol

Every run follows the same loop:

$$
\text{intent}
\to\text{frozen statement variants}
\to\text{candidate map}
\to\text{adversarial search}
\to\text{small exact witness/certificate}
\to\text{Lean replay}
\to\text{scientific adjudication}.
$$

FH is the experiment registry. Atlas is the theory and analogy instrument.
Numerical/symbolic engines propose and attack candidates. Lean/Physlib is the
mathematical source of record. No numerical optimizer, language model, SMT
solver, SDP solver, or polytope package is trusted merely because it reports
success.

For each candidate record:

- an exact statement and its named domain;
- source and transformation provenance;
- assumptions and symmetry slice;
- positive, negative, boundary, and mutation controls;
- search configuration and random seeds;
- exact witnesses or certificate payloads;
- Lean theorem name, imports, statement digest, and axiom audit;
- status: proposed, numerically supported, refuted, proved, independently
  replayed, domain-reviewed, or publication-ready;
- novelty and significance assessments, stored separately from truth status.

## 4. Workspace and ownership boundary

Implementation should live in the repository’s separate [`physics/`](../../../physics)
Lean workspace, which already imports Physlib. The main Ferris–Howard workspace
and the physics workspace deliberately use different Lean/Mathlib patch
versions. They share the `atlas-extract` source and emit the same statement
JSONL, but cross-version Atlas merging is safe for analogy, not statement
identity. The campaign must preserve this boundary.

The proposed ownership split is:

- **Physlib/physics workspace:** definitions and mathematical theorems;
- **FH:** immutable questions, hypothesis variants, experiment manifests,
  result provenance, and adjudication;
- **Atlas:** corpus neighborhood, proof-shape maps, analogy edges, candidate
  transports, and dependency deltas;
- **Engine 2 (certified positivity):** SOS/Gram candidates and exact
  certificate checking;
- **Engine 3 (certified finite search):** facet/vertex enumeration, finite
  cases, witness shrinking, and exhaustive certificate replay.

The $\Delta(54)$ proof should not wait for a universal positivity or polytope
framework. Build the smallest checked certificate first, then generalize only
after a second model supplies real requirements.

## 5. Proposed formal modules and APIs

Names are provisional and must be reconciled with Physlib conventions before
implementation.

### 5.1 Domain layer

`ThreeHDM/Basic`

- `ThreeHiggsDoublet := Fin 3 → HiggsVec`
- component and scaling operations;
- electroweak gauge action, reusing the 2HDM pattern;
- nonzero and normalized field predicates.

`ThreeHDM/GramMatrix`

- `gram : ThreeHiggsDoublet → Matrix (Fin 3) (Fin 3) ℂ`;
- `smallGram : ThreeHiggsDoublet → Matrix (Fin 2) (Fin 2) ℂ`;
- Hermitian, positive-semidefinite, trace, determinant, and rank lemmas;
- gauge invariance and, later, orbit-surjectivity;
- neutral/rank-one and charge-breaking/rank-two predicates.

The generic theorem “PSD Hermitian $3\times3$ plus rank $\le2$ is realizable” is
valuable, but it is not on the shortest path to the first stability theorem.
Explicit vertices are enough initially.

### 5.2 $\Delta(54)$ layer

`ThreeHDM/Delta54/Invariants`

- $A_{ij}$, $N,Q,R,P$ and their reality/conjugation properties;
- the two $\Delta(54)$ generators and invariant proofs;
- an exact algebraic cube root `omega` with its minimal identities;
- normalized coordinates guarded by $N>0$.

`ThreeHDM/Delta54/Potential`

- parameter structures for $\mu$ and $\lambda_{1\ldots5}$;
- `massTerm`, `quarticTerm`, and `potential`;
- scaling/homogeneity lemmas;
- `QuarticNonnegative`, `QuarticPositive`, and `FullBFB`;
- the eight forms $h_i$ and their finite minimum.

`ThreeHDM/Delta54/OrbitPolytope`

- the six unnormalized facet slacks;
- sum-of-squares proofs and normalized inequalities;
- the eight rational vertices;
- an exact H-to-V/Farkas certificate checker;
- eight field witnesses and coordinate evaluation;
- neutral/charge-breaking classification;
- `linear_min_on_orbit_eq_vertex_min`.

`ThreeHDM/Delta54/Stability`

- non-negative and strict quartic equivalences;
- full-potential boundary theorem;
- exact global lower bound/infimum;
- CP and higher-symmetry slices;
- exposed-face/minimizer statements with degeneracy handled explicitly.

### 5.3 Atlas/FH records

The campaign needs machine-readable records for:

- predicate variants and implication/non-implication edges;
- domain transformations: fields $\leftrightarrow$ Gram data $\to$ invariants
  $\to$ polytope $\to$ vertex values;
- facet provenance: source equation, SOS identity, dependencies, equality cases;
- vertex provenance: exact coordinate, active facets, field witness, rank class;
- candidate condition sets and exact counterexamples;
- proof-route alternatives and measured proof/search cost;
- literature snapshot and novelty-refresh timestamp.

Do not add these records until the current Atlas schema lands. At launch, map
them to the actual schema rather than inventing a competing format in this
dossier.

## 6. Planned experiments

No experiment below has been run. Each has a question, protocol, falsifier, and
exit criterion.

### E0 — Statement adjudication

**Question:** Which stability proposition is actually being asserted?

Freeze the three predicates in [DELTA54.md](DELTA54.md), plus the source-language
rendering. Generate a small implication table across signs of $\mu$ and
$m=\min h_i$. Ask Atlas to search the Physlib and paper corpus for uses of
“stable,” “strongly stable,” “BFB,” “positive,” and “non-negative.”

Controls:

- $\lambda_1=\cdots=\lambda_5=0$, $\mu<0$;
- $m=0$, $\mu=0$;
- $m=0$, $\mu>0$;
- $m>0$, $\mu<0$;
- the Physlib 2HDM counterexample as an out-of-model warning.

**Falsifier:** one of the proposed equivalences accepts the all-zero quartic with
$\mu<0$ as full-BFB, or rejects a manifestly non-negative $\mu N$ potential.

**Exit:** a reviewed statement ledger with no unnamed “BFB” proposition.

### E1 — Competing proof spines

**Question:** Is the matrix/SOS proof materially smaller and safer than the
paper’s angular route?

Route A formalizes enough gauge fixing and angular optimization to reproduce the
$x\ge-1/4$ bound. Route B proves Cauchy–Binet and the direct $2\times2$ SOS
identity. Use the same theorem statement and compare:

- new definitions and imported theories;
- lines/tactic steps and elaboration time;
- nonlinear automation dependence;
- mutation score under sign and factor changes;
- reuse in the next model.

The expectation is that Route B wins decisively. Route A is a bounded prototype,
not a commitment to finish two proofs.

**Falsifier:** the matrix identity fails to match the source normalization, or
formal overhead makes it less auditable than the coordinate proof.

**Exit:** one selected proof spine with the rejected route and reasons retained
in FH.

### E2 — Exact polytope certificate

**Question:** Do the six half-spaces have exactly the claimed eight vertices,
and can the result be checked by a tiny kernel-facing interface?

Independently enumerate the fifteen choices of four boundary hyperplanes using
exact rational arithmetic. Deduplicate, check all six inequalities, and emit
active-facet evidence. Produce either a V-representation certificate or eight
Farkas cases for a generic linear functional. Lean checks every rational
calculation and inequality.

Controls deliberately corrupt:

- one vertex coordinate;
- one facet orientation;
- the $1/4$ or $1/3$ normalization;
- a duplicate replacing a missing vertex;
- an extra infeasible intersection.

**Falsifier:** the independent vertex set differs from the paper or the Lean
checker accepts any corrupt certificate.

**Exit:** exact replay from the six facets to the eight-vertex linear-minimum
theorem, with no trust in the enumerator.

### E3 — Physical realizability and charge

**Question:** Are all eight mathematical vertices realized by Higgs fields, and
are their charge labels correct?

Encode the paper’s explicit field representatives. Evaluate $N,Q,R,P$ and the
four coordinates exactly. Prove rank $K=1$ for $v_1,v_2,v_6,v_8$ and rank $K=2$
for $v_3,v_4,v_5,v_7$ (with the zero special case excluded).

Controls:

- use only the four neutral witnesses;
- conjugate $\omega$ in one witness;
- swap $v_5$ and $v_7$;
- attempt coordinate normalization at the zero field.

**Falsifier:** any claimed vertex lacks a witness, or the rank criterion disagrees
with direct pairwise determinants.

**Exit:** all vertices certified physically attainable and charge-classified.

### E4 — End-to-end stability theorem

**Question:** Do the exact orbit certificate and radial argument prove the three
stability variants and global infimum?

Prove the quartic non-negative theorem first, then strict positivity, then the
full-potential classification. Replay from a clean physics workspace. Inspect
axioms and imports; reject `sorry`, unchecked native computation, or a theorem
whose domain is silently smaller than arbitrary Higgs fields.

Controls:

- the zero-quartic/$\mu<0$ boundary;
- a coupling vector with exactly one negative $h_i$, witnessed at $v_i$;
- random rational couplings in every sign cell of the eight $h_i$;
- the CP slice, where paired vertices must agree;
- a neutral-only mutant expected to misclassify a charge-breaking case.

**Falsifier:** numerical search finds a field below the certified lower bound,
or the proof requires an assumption absent from the frozen statement.

**Exit:** clean kernel replay plus independent statement review. Numerical tests
remain regression controls, not theorem evidence.

### E5 — Atlas discovery ablation

**Question:** Does Atlas contribute scientific search, or merely retrieve the
answer after we supply it?

Run three blinded conditions against the now-known $\Delta(54)$ answer key:

1. **Retrieval:** source paper and exact vertices are visible.
2. **Derivation:** potential and general Gram identities are visible, but the
   six facets and vertices are held out.
3. **Repair:** a plausible but wrong neutral-only or non-strict full-BFB claim is
   supplied.

Measure whether the agent:

- proposes the Gram matrix and SOS identities;
- discovers charge-breaking counterexamples;
- recovers exact rational facets/vertices from approximate candidates;
- separates statement variants before proof search;
- produces small checker-compatible certificates;
- reports uncertainty rather than laundering numerics into proof.

Metrics include time to first falsifier, exact-candidate precision, fraction of
candidate lemmas reused in the final proof, certificate size, human
interventions, and mutation-test rejection rate.

**Falsifier:** success disappears when answer-containing documents are held out,
or Atlas repeatedly calls numerical agreement a proof.

**Exit:** an evidence-based capability profile and concrete Atlas/FH fixes before
claiming discovery competence.

### E6 — Frontier transfer to $\mathbb Z_2\times\mathbb Z_2$

**Question:** Can the calibrated machinery reduce a genuinely unresolved 3HDM
stability frontier?

Start from the exact potential and named condition levels in
[arXiv:2603.23590](https://arxiv.org/abs/2603.23590). Rebuild every published
necessary and sufficient implication in the statement ledger. Then iterate:

1. sample/search near the boundary of the strongest known condition set;
2. turn floating-point failures into rational or low-degree algebraic field and
   coupling witnesses;
3. minimize witness support and identify its Gram rank/equality pattern;
4. ask Atlas for the nearest $\Delta(54)$, $A_4$, $S_4$, 2HDM, copositivity, and
   SOS proof shapes;
5. infer a missing invariant inequality or coupling condition;
6. test independence against the existing condition set;
7. seek an exact SOS, Farkas, CAD, interval, or finite-case certificate;
8. compile the surviving result into Lean.

Possible valid frontier outputs, in increasing strength, are:

- a new exact counterexample to a proposed condition or classifier;
- a new necessary condition with an independent witness family;
- a stronger sufficient condition covering a previously unresolved region;
- an exact solution on a meaningful symmetry/coupling slice;
- a complete necessary-and-sufficient criterion.

The campaign succeeds scientifically even if it produces only the first two,
provided they are new, exact, relevant, and independently checked.

**Stop condition:** if the search only reproduces known conditions after a
predeclared budget, publish the negative capability result internally, improve
the engines, and choose a narrower slice. Do not manufacture novelty by changing
the question after seeing the output.

### E7 — Independent reproduction and domain review

**Question:** Is the result correct outside the originating agent’s context and
scientifically stated at the right strength?

A fresh agent or human reviewer receives the frozen statement and certificate,
not the exploratory transcript. They replay the Lean build, inspect the
assumption ledger, reconstruct at least one vertex/facet calculation, and review
the physics interpretation.

If the boundary refinement survives, privately contact the source authors with
the smallest explicit counterexample and formal theorem before public language
about an error. Give space for a convention or revised-version explanation.

**Exit:** independent replay, HEP-domain approval, and an explicit decision among
upstream contribution, formalization note, correction note, or continued private
research.

## 7. Milestones and gates

| gate | required evidence | decision |
|---|---|---|
| G0 Baseline | in-flight Atlas work landed; clean/frozen code and corpus fingerprints; refreshed literature/Physlib search | launch or wait |
| G1 Statements | three stability predicates, source rendering, assumptions, controls, novelty ledger | approve target |
| G2 Domain | fields, Gram data, invariants, symmetry and scaling checks | approve model encoding |
| G3 Facets | all six unnormalized inequalities with equality examples and mutations rejected | approve orbit containment |
| G4 Polytope | independent exact H-to-V/Farkas certificate plus eight field witnesses | approve finite reduction |
| G5 Quartic | non-negative and strict equivalences replay cleanly | calibration complete |
| G6 Full potential | boundary theorem and global infimum proved or precisely refuted | decide correction path |
| G7 Minima | exposed-face and neutral/charge classification, degeneracies explicit | approve physics interpretation |
| G8 Review | fresh replay, axiom audit, specification red team, HEP review, author courtesy window | approve release |
| G9 Transfer | at least one exact new result or a bounded negative capability report on the next model | assess discovery program |

No gate advances because a model “looks right,” a numerical optimizer agrees,
or an agent says the proof should be routine.

## 8. Positive, negative, and mutation controls

### Positive controls

- one-doublet radial potential, whose stability classification is elementary;
- the existing Physlib 2HDM strong-stability implication;
- the $\lambda_5=0$ CP slice with six projected vertices;
- the $U(3)$, $\Sigma(36)$, and
  $[U(1)\times U(1)]\rtimes S_3$ parameter slices inherited from $\Delta(54)$;
- exact evaluation of every source field witness.

### Negative controls

- all quartics zero with $\mu<0$;
- a negative vertex form with its corresponding scaled field witness;
- a potential passing all neutral vertices but failing a charge-breaking vertex;
- a field/coupling family approaching a quartic-flat boundary;
- an invariant tuple inside a relaxed box but outside the physical Gram domain.

### Mutation controls

- $1/4\leftrightarrow1/3$;
- reversed facet signs;
- $\omega\leftrightarrow\omega^2$ and $t\leftrightarrow-t$;
- $P$ term conjugation/order changes;
- dropping $N>0$ before normalization;
- changing $\ge$ to $>$ or the reverse;
- claiming a unique vertex when two $h_i$ tie;
- deleting one charge-breaking vertex.

Mutation rejection is a first-class metric. A proof that survives a semantic
mutation may be proving the wrong specification.

## 9. Risks and redirects

### Mathematical risks

- Complex-number normalization and `Real.sqrt 3` may create proof friction.
  Mitigation: isolate a small exact $\omega$ API and keep rational orbit
  coordinates downstream.
- Generic matrix-rank and PSD machinery may be expensive. Mitigation: use direct
  $2\times2$ identities and explicit witnesses on the first path.
- A full orbit-equality theorem may balloon. Mitigation: prove only containment,
  vertex realization, and a linear-minimum certificate.
- Flat directions may invalidate an overbroad full-potential theorem.
  Mitigation: freeze sign cases and actively search asymptotic paths, following
  the 2HDM warning.

### Research risks

- A parallel formalization or analytic correction may appear. Redirect to
  independent verification, reusable API work, or the transfer model.
- The boundary issue may be purely terminological. Record the exact predicate
  mapping and do not call it an error.
- The $\Delta(54)$ theorem may become routine once encoded. Treat that as a good
  calibration result and move the novelty claim to transfer.
- The transfer problem may be too broad. Narrow to a physically meaningful
  coupling slice chosen before inspecting results.
- Numerical counterexamples may resist exactification. Use interval validation
  only as a bounded intermediate status, never as a Lean theorem.

### Coordination risks

- Physlib maintainers may already have a preferred abstraction. Contact them
  before building a large parallel hierarchy.
- Toolchain patch versions differ. Keep source identities workspace-local and
  use Atlas cross-corpus links only as analogies.
- Multiple agents may edit overlapping campaign artifacts. Freeze ownership and
  result paths at G0.

## 10. Completion and publication standard

The calibration campaign is complete only when:

- all frozen statements have explicit proved/refuted status;
- the eight-vertex result replays from a clean checkout with no `sorry`;
- every external certificate is checked by small Lean definitions/theorems;
- the statement and axiom audits are clean;
- negative and mutation controls fail for the expected reason;
- an independent reviewer reproduces the result;
- a physics expert approves the domain and interpretation;
- novelty language has been refreshed and qualified.

A frontier result is publication-ready only when it additionally has a clear
comparison with the strongest known condition set, exact examples or proof
objects, a significance argument, and appropriate author/upstream coordination.

The desired output is not “the agent found something.” It is a chain that a
skeptical physicist can inspect:

$$
\text{question}\to\text{falsifiable statement}\to
\text{exact evidence}\to\text{kernel proof}\to
\text{independent physics review}.
$$

That is how Atlas moves from a hypothesis cartographer to a scientific
instrument.
