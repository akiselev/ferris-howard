# Precedent and research map

> Literature snapshot: 2026-08-02. This is a targeted research map, not a
> systematic-review claim. “Not found” means not found in the sources and code
> searches performed for this plan; it does not prove nonexistence.

## 1. What is already established

The 3HDM campaign is not beginning from an empty field. The underlying ideas—
Gram/bilinear orbit spaces, symmetry-restricted scalar potentials, convex-hull
minimization, exact positivity criteria, and formal stability proofs—each have
substantial precedent. The opportunity is to connect them in a reusable,
machine-checked discovery loop.

### Orbit-space and bilinear foundations

- [Ivanov and Nishi, “Properties of the general NHDM. I. The orbit
  space”](https://arxiv.org/abs/1004.1799) describes gauge orbits through
  positive-semidefinite Gram matrices with rank at most two and treats the
  three-doublet case in detail. This is the right conceptual foundation for the
  formal data model.
- [Maniatis and Nachtmann, “Stability and symmetry breaking in the general
  three-Higgs-doublet model”](https://arxiv.org/abs/1408.6833) develops bilinear
  stability machinery for the general 3HDM.
- [Maniatis and Nachtmann, “Bilinear formalism for the n-Higgs-doublet
  model”](https://arxiv.org/abs/1504.01736) gives a general $n$-doublet
  treatment. Its marginal/weak-stability reasoning should not be imported as an
  opaque theorem: the 2026 Lean 2HDM result below shows that an older standard
  boundary argument can fail.

The lesson for Atlas is that the Gram matrix is not merely convenient notation.
It is the orbit object: positive semidefiniteness and the rank bound encode the
field realizability constraints that naive optimization over invariants can
otherwise forget.

### Geometric minimization and symmetry

- [Degee, Ivanov, and Keus, “Geometric minimization of highly symmetric
  potentials”](https://arxiv.org/abs/1211.4989) established the geometric
  orbit-space approach and showed why global rather than local minimization
  matters. It also identified failures in earlier phenomenological analyses of
  $A_4$-symmetric models.
- [Ivanov and Vdovin, “Classification of finite reparametrization symmetry
  groups in the three-Higgs-doublet model”](https://arxiv.org/abs/1310.8253)
  catalogs realizable finite symmetry groups in 3HDM scalar sectors.
- [Ivanov and Nishi, “Symmetry breaking patterns in 3HDM”](https://arxiv.org/abs/1410.6139)
  maps allowed symmetry-breaking patterns and helps interpret orbit stabilizers.
- [de Medeiros Varzielas and Emmanuel-Costa, “Geometrical CP violation”](https://arxiv.org/abs/1106.5477)
  is precedent for calculable complex phases in discrete-symmetry scalar
  potentials related to $\Delta(27)/\Delta(54)$.

This makes $\Delta(54)$ physically motivated, but “has a mathematically
interesting symmetry” is not the same as “is experimentally realized.”

### Exact and incomplete 3HDM stability results

- [Faro and Ivanov, “Boundedness from below in the $U(1)\times U(1)$
  three-Higgs-doublet model”](https://arxiv.org/abs/1907.01963) derives exact
  conditions and emphasizes that charge-breaking directions are essential. A
  neutral-only analysis is not a safe approximation to global stability.
- [Carrolo, Romão, Silva, and Vazão, “Symmetry and boundedness from below in
  the two-Higgs-doublet model and three-Higgs-doublet model”](https://arxiv.org/abs/2006.00036)
  shows that exact conditions from a symmetric potential can cease to be
  sufficient after soft symmetry breaking. Transported theorems therefore need
  explicit assumption ledgers.
- [Buskin and Ivanov, “Bounded-from-below conditions for A4-symmetric 3HDM”](https://arxiv.org/abs/2104.11428)
  turns a numerical conjecture into an analytic proof, but explicitly focuses
  on the neutral orbit space. It is precedent for analytic recovery from
  computational evidence and a warning about domain qualifiers.
- [Boto, Romão, and Silva, “BFB conditions on a class of symmetry-constrained
  3HDM”](https://arxiv.org/abs/2207.02928) gives complete neutral conditions and
  a safe sufficient condition for the full charge-breaking space, with the
  remaining boundary supported numerically. This is an example of a theorem
  frontier that must not be blurred into a completed result.
- [Jurčiukonis and Lavoura, $\Delta(54)$ 3HDM](https://arxiv.org/abs/2605.07651)
  supplies the immediate target: six orbit half-spaces, eight vertices, explicit
  field representatives, coupling inequalities, and a million-sample numerical
  comparison. The associated
  [`4D-polytope` notebook](https://github.com/jurciukonis/4D-polytope) uses exact
  rational linear algebra to enumerate vertices.
- [Jurčiukonis and Lavoura, $\mathbb Z_2\times\mathbb Z_2$ 3HDM](https://arxiv.org/abs/2603.23590)
  treats the more general Weinberg-type model with strict quartic positivity,
  analytic necessary conditions, numerical minimization, and machine-learning
  classification. In the reviewed version, it does not give a necessary-and-
  sufficient exact full criterion. This is the proposed transfer frontier.

### Model-building context

- [$\Delta(27)$ 3HDM phenomenology](https://arxiv.org/abs/2112.12699) illustrates
  how related discrete symmetries constrain scalar spectra and phenomenology.
- [$\Delta(54)$ flavor and string motivation](https://arxiv.org/abs/1607.06812)
  provides broader motivation for the group in flavor-model construction.

These references motivate why theorists care about the model. They do not turn a
tree-level scalar stability proof into a full phenomenological analysis.

## 2. Formal-methods precedent

The strongest direct precedent is Joseph Tooby-Smith’s
[Lean formalization of two-Higgs-doublet stability](https://arxiv.org/abs/2603.08139).
The current open Physlib source contains:

- a `TwoHiggsDoublet` field type and gauge action;
- a $2\times2$ Gram matrix and real Gram-vector representation;
- surjectivity/orbit lemmas;
- the quadratic, quartic, and full potential;
- `PotentialIsStable P := ∃ c : ℝ, ∀ H, c ≤ potential P H`;
- a theorem that sufficiently strong quartic positivity implies stability; and
- a formal counterexample to a stability step inherited from older 2HDM
  literature.

The relevant modules are in
[`Physlib/Particles/BeyondTheStandardModel/TwoHDM`](https://github.com/leanprover-community/physlib/tree/master/Physlib/Particles/BeyondTheStandardModel/TwoHDM).
At the repository snapshot inspected for this plan
(`715e94d1b094cde4c263facfa775302ade26fdc9`, 2026-08-02), a targeted file and
identifier search found no corresponding `ThreeHDM` development. That is a
current negative search result, not a priority or novelty guarantee.

The 2HDM counterexample is especially important. Non-negative quartic behavior
and checks restricted to exact quartic-zero rays need not control paths that
*approach* a flat direction as the norm grows. The $\Delta(54)$ model’s quadratic
term is unusually simple ($\mu N$), so its complete boundary theorem should be
easier than the general 2HDM case; nevertheless, the predicates must be stated
exactly.

The separate 2026 $\mathbb Z_2\times\mathbb Z_2$ paper explicitly notes the
strict-versus-zero issue and cites the Lean counterexample. This is unusually
strong evidence that formal proof is already feeding back into active
multi-Higgs research.

## 3. Precedent for theorem discovery with proof assistants

The campaign is also backed by a broader research pattern:

- numerical or symbolic exploration proposes a compact statement;
- exact counterexamples and boundary cases repair the statement;
- a proof assistant forces every domain and hypothesis to be explicit;
- the finished formal object becomes a reusable basis for nearby conjectures.

In this specific subfield, the $A_4$ history shows numerical evidence later
receiving an analytic proof, while the Lean 2HDM work shows formalization finding
a counterexample to a literature argument. The proposed Atlas loop combines
both roles: conjecture formation and adversarial statement repair.

This does not mean Lean autonomously invents physics. Lean is the trusted
checker and a precise experimental surface. Atlas and the agent perform the
theory mapping, candidate generation, transport, and experiment selection. The
human supplies scientific intent and adjudicates significance.

## 4. What appears new, and how cautiously to say it

Subject to a launch-time literature refresh and expert contact, the following
outputs may be new:

1. a public, kernel-checked 3HDM Gram/orbit-space library;
2. a formal proof of the full eight-vertex $\Delta(54)$ criterion;
3. an exact separation of quartic non-negativity, strict positivity, and full
   boundedness for the symmetric $\mu N$ mass term;
4. a checked global-infimum and neutral/charge-breaking vertex classification;
5. exact counterexamples or new sufficient/necessary conditions transferred to
   the $\mathbb Z_2\times\mathbb Z_2$ model.

Items 1–4 can still be worthwhile if the underlying pen-and-paper fact is
known: the scientific contribution is reproducibility, statement precision,
and reusable infrastructure. Item 5 is the most plausible route to a genuinely
new model result.

Before any novelty claim, search INSPIRE, arXiv, GitHub, and Physlib again;
contact relevant formalization maintainers; and ask a multi-Higgs expert to
review the exact predicate. “First formal proof” is a claim requiring the same
care as a mathematical theorem.

## 5. Lessons encoded into the campaign

1. **Never erase the physical domain.** A polynomial condition over arbitrary
   invariants is not automatically a condition over realizable Higgs fields.
2. **Include charge-breaking directions.** They are not phenomenologically
   desired vacua, but they are mandatory for a global lower-bound proof.
3. **Name the stability predicate.** Quartic non-negative, quartic positive, and
   full-potential lower-bounded are different propositions.
4. **Treat numerics as an oracle, not an authority.** A million agreements can
   miss a measure-zero boundary; exact witnesses and kernel replay decide.
5. **Track symmetry assumptions.** Results can fail after soft breaking or when
   transported to a less symmetric potential.
6. **Prefer exact algebra over coordinates.** Gram identities and sums of
   squares are smaller and more auditable than gauge fixing and trigonometric
   global optimization.
7. **Separate reproduction from discovery.** The $\Delta(54)$ result calibrates
   the machinery; transfer to an unresolved model tests scientific creativity.
