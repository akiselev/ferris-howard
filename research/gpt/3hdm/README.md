# Three-Higgs-doublet research campaign

> Status: planning dossier, draft 0.1, 2026-08-02. No campaign has been run.
> Execution is deliberately paused until the current Atlas work is complete and its
> baseline is frozen.

This dossier proposes a first serious physics campaign for Ferris–Howard (FH),
Atlas, Lean, and Physlib: formally investigate the vacuum stability of a
three-Higgs-doublet model (3HDM) with the discrete symmetry $\Delta(54)$, then
transfer the machinery to a less-solved 3HDM.

The short verdict is: **we can probably pull off the $\Delta(54)$ campaign with
the software architecture we already have.** The core mathematics is unusually
small and exact: six polynomial inequalities, eight rational vertices, and a
linear potential. It is a good calibration problem for agent-directed formal
research. The already-published quartic criterion is not itself a novel physics
discovery. The research opportunity is instead threefold:

1. produce what appears, subject to a final novelty check, to be the first
   kernel-checked account of the result;
2. resolve a real boundary ambiguity between quartic non-negativity and
   boundedness of the *full* potential; and
3. use the resulting 3HDM orbit-space library to attack the currently harder
   $\mathbb Z_2\times\mathbb Z_2$ (Weinberg) model, where exact necessary-and-
   sufficient conditions are still not known in the source reviewed here.

That sequence matters. $\Delta(54)$ is the wind tunnel; the next model is where
the apparatus can become a discovery instrument.

## What “three Higgs” means

The Standard Model has one Higgs *doublet*: two complex field components whose
values may vary together. A 3HDM has three such doublets,

$$
\Phi_1,\Phi_2,\Phi_3\in\mathbb C^2.
$$

This does **not** simply mean “three copies of the observed Higgs particle.”
Before gauge symmetry breaking the three doublets contain twelve real field
components. Three become gauge degrees of freedom, leaving nine physical scalar
degrees of freedom in a generic model: several neutral scalars and two charged
scalar pairs. Which states actually occur, and whether the model is viable,
requires substantially more than the stability problem studied here.

The potential $V(\Phi_1,\Phi_2,\Phi_3)$ is an energy landscape. A physically
usable classical model must not allow the energy to fall toward $-\infty$ as the
fields grow. That is the bounded-from-below problem. Because the fields are
complex vectors and gauge-equivalent configurations represent the same physics,
the raw problem looks like a difficult nonlinear search in many real variables.

The useful change of viewpoint is to keep only the inner products
$A_{ij}=\Phi_i^\dagger\Phi_j$. They form a $3\times3$ Gram matrix. Gauge rotations
disappear, positivity becomes matrix positivity, and the $\Delta(54)$ symmetry
compresses the quartic potential to a linear function of four normalized
invariants. The paper we are targeting shows that every possible invariant point
lies inside a polytope with eight physically realized vertices. A linear
function reaches its minimum at a vertex, so an infinite field search becomes
eight exact inequalities. See [DELTA54.md](DELTA54.md) for the equations.

## Why this is a good Atlas experiment

This target sits in a productive middle ground:

- It is real high-energy theory, not a toy theorem invented for a benchmark.
- The source result is new enough that formalization can still affect how the
  result is understood and stated.
- Its proof has several interchangeable representations: raw complex fields,
  Gram matrices, sums of squares, orbit-space facets, and a finite polytope.
  That is exactly the kind of theory-to-theory map Atlas is meant to expose.
- It has sharp negative controls. Omitting charge-breaking configurations,
  mishandling the zero field, confusing $\ge0$ with $>0$, or conjugating a cube
  root of unity incorrectly all produce falsifiable failures.
- It has a natural transfer target whose solution is not already known.

This is agent-directed research in the intended sense. A human chooses the broad
intent—“investigate stability and vacua in multi-Higgs models.” The agent maps
the literature and formal corpus, proposes exact statements, generates proof and
counterexample routes, chooses the next information-gaining computation, and
returns proof objects and candidate scientific claims for review. The human does
not have to know in advance that an eight-vertex theorem or a boundary issue is
waiting to be found.

## What the campaign can and cannot establish

A successful campaign can establish exact tree-level facts about this scalar
potential:

- which couplings make the quartic part non-negative or strictly positive;
- when the full quadratic-plus-quartic potential is bounded below;
- its exact global lower bound in the symmetric model;
- which exposed orbit-space vertices are neutral or charge-breaking; and
- whether the published boundary formulation needs clarification or correction.

It cannot, by itself, show that Nature has three Higgs doublets. It does not
establish collider compatibility, quantum or renormalization-group stability,
unitarity at all scales, a viable fermion/Yukawa sector, the observed vacuum, or
phenomenological superiority. Those are later campaigns with different engines
and data.

The “experiments” here are computational-mathematical experiments: we freeze a
hypothesis, expose it to exact counterexample search and numerical stress tests,
compile any surviving statement into a Lean proof, and replay it through the
kernel. Numerical agreement is evidence and a debugging tool; the kernel proof
is the certificate.

## Proposed research ladder

The campaign has three tiers.

1. **Reproduction:** independently reconstruct the six orbit inequalities, eight
   vertices, vertex witnesses, and quartic stability criterion from the
   [2026 $\Delta(54)$ paper](https://arxiv.org/abs/2605.07651).
2. **Refinement:** formally separate quartic non-negativity, strict quartic
   positivity, and full-potential boundedness. Prove or refute the proposed
   boundary classification in [DELTA54.md](DELTA54.md).
3. **Discovery transfer:** reuse the formal API and Atlas traces on the
   [2026 $\mathbb Z_2\times\mathbb Z_2$ study](https://arxiv.org/abs/2603.23590),
   where the reviewed work uses strict positivity, necessary conditions,
   numerical minimization, and machine learning rather than a complete exact
   criterion.

We should not advertise tier 1 as discovery. Tier 2 may yield a precise formal
correction or clarification. Tier 3 is the genuine open-ended frontier bet.

## Documents

- [DELTA54.md](DELTA54.md) gives the model, exact proof spine, theorem variants,
  and the boundary question.
- [PRECEDENT.md](PRECEDENT.md) maps the physics, orbit-space, and Lean precedent
  and labels what is known versus inferred.
- [CAMPAIGN_PLAN.md](CAMPAIGN_PLAN.md) specifies the staged experiments,
  falsifiers, proposed APIs, gates, outputs, and transfer campaign.

## Launch rule

Do not begin implementation or scientific runs merely because this plan exists.
At launch we first:

1. wait for and freeze the in-flight Atlas/cartography work;
2. refresh the literature and Physlib snapshots, because both are moving;
3. check for parallel 3HDM formalization and contact likely upstream owners;
4. assign exact statement names so “BFB” is never used ambiguously; and
5. register the frozen source, assumptions, controls, and novelty status in FH.

Only then does the campaign move from plan to experiment.
