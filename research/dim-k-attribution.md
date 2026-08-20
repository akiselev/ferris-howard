# k-attribution: is a recovered dimensional relation stated by one declaration, or entailed jointly?

*The single decisive measurement the external audit demanded (`research/corpus-atlas-findings.md`
§65): for each recovered dimensional relation, is it implied by the dimensional rows of a
**single** declaration (k=1), of two (k=2), or of k>2 declarations jointly?*

---

## 0. Pre-registration — written before any attribution was computed

Stated in full before the first run, so the verdict cannot be fitted to the numbers.

**The two readings, fixed in advance (from §65):**

* If most relations are k=1, the method is a per-statement dimensional type checker with the
  constraint printed instead of discarded — transcription, not discovery ("Osprey with the
  output kept").
* If a meaningful fraction needs k≥2, the corpus jointly entails dimensional facts no single
  statement states — §65's "genuinely new claim about formalized libraries".

**Primary criterion, with its numeric threshold committed now:** over the **powered**
relations of the headline configuration (`--cap 200000`, all rule families,
`--bvar type-nonscalar`; expected 24 of 154 per `research/physlib-calculus.md` §3), the
fraction that is **not** implied by any single declaration's rows (k≥2, decided by the exact
k=1 test) must be **≥ 20%** for the "discovery" verdict. Below 20%: transcription. The
powered subset is the primary population because a coefficient outside ±1 is the
pre-existing discriminator separating recovered physics from rearrangement bookkeeping
(`physlib-dimensional.md` §3, `physlib-calculus.md` §7), and 20% is the suggested threshold,
adopted unchanged.

**Secondary, descriptive (no verdict weight, reported regardless):**

* the full k∈{1, 2, ≥3} distribution over all 154 calculus-config relations, over the 24
  powered ones, and over the 21 baseline relations (`--rules none --bvar local`, same cap)
  with their 4 powered ones — §65 asked for the 154 explicitly;
* the k>2 fraction separately, since §65's second sentence literally says k>2;
* the "most are k=1" reading is affirmed descriptively if >50% of relations are k=1. Note
  both readings can hold at once (majority k=1 and a meaningful k≥2 minority); the primary
  criterion above decides the §65 discovery-or-transcription verdict, because §65's
  discovery arm turns on the existence of a meaningful jointly-entailed fraction, not on a
  majority.

**Method, fixed in advance:**

* A relation (RREF pivot row with ≥3 atoms) is *k≤n-implied* if some n-subset of
  declarations' post-elimination global rows entails it in the rational vector space
  (row-space membership over ℚ). Per-declaration global rows are an exact projection of
  that declaration's raw constraints (local atoms are declaration-keyed, so the blockwise
  Schur complement in `eliminate_locals` is exact); therefore subset entailment computed on
  global rows equals entailment from the declarations' own statements.
* **k=1 is exact and cheap:** for each relation, every declaration whose atom set covers the
  relation's support is tested by per-declaration echelon; support coverage is a necessary
  condition for row-space membership, so the candidate filter loses nothing.
* **k=2 is exact by covering-pair enumeration:** any pair implying the relation must jointly
  cover its support, and (when one member already covers it alone) the second member must
  share an atom with the first's atom set union the relation's support — both necessary
  conditions proved from support arithmetic, so enumeration over pairs passing them is
  complete. A per-relation work budget applies; if any relation exhausts it, that relation
  is reported as "k=2 enumeration incomplete" and its k∈{2,≥3} split is **biased upward**
  (toward ≥3). The k=1/k≥2 split — the one the primary criterion uses — carries no such
  bias.
* **Exact minimal k above 2 is not computed** (it is a set-cover-shaped problem). Relations
  failing both exact tests are exactly k≥3; a greedy upper bound on their minimal k is
  reported and is biased **upward** by construction.
* **Reproduction gate:** the harness must first reproduce the published counts on
  `/tmp/fh-physlib.jsonl` at `--cap 200000` — 21 relations / 4 powered at
  `rules none, bvar local`, and 154 / 24 at `calculus, type-nonscalar`
  (`physlib-calculus.md` §3). If either count fails to reproduce, stop and report; nothing
  else is interpretable.
* The witness lists printed by `scripts/phys-calculus.py --witness` are a labelled
  over-approximation (share-≥2-atoms attribution) and are **not used** here.

Everything below this line was written after the runs.

---

## 1. What ran

Everything is measured by `scripts/dim-k-attribution.py` against `/tmp/fh-physlib.jsonl`
(14,576 rows; 14,147 kept at `--cap 200000`, 429 over cap, 0 parse failures) and written to
`research/data/dim-k-attribution.json`. Reproduce:

```sh
uv run --no-sync scripts/dim-k-attribution.py     # ~3.5 min end to end
```

**Both reproduction gates passed exactly.** Baseline (`rules none, bvar local`): 6,840
declarations contributing rows, 5,002 global rows, |C| 2,050, rank 1,670, dim 380, **21
relations, 4 powered** — `physlib-calculus.md` §3's cell to the row. Calculus
(`all families, type-nonscalar`): 6,478 declarations, 5,584 global rows, |C| 2,392, rank
1,930, dim 462, **154 relations, 24 powered**. The pipeline is deterministic: three
independent builds this session produced identical relation sets (pivot keys and
coefficient multisets asserted equal across builds), so the attribution is over exactly the
published relations.

**The pre-registered k=2 budget never engaged.** Maximum covering pairs actually tested for
any relation: 13 (baseline), 50 (calculus), against a budget of 60,000. So the k∈{1, 2, ≥3}
classification below is **exact everywhere** — the upward bias reserved for budget
exhaustion never materialized, and no relation is reported as "enumeration incomplete".

The only inexact number is the witness-set **size** for k≥3 relations: a
coefficient-tracking elimination expresses each pivot row as an explicit rational
combination of source rows, its provenance declarations are checked to entail the relation,
and greedy inclusion-pruning (drop a declaration iff the rest still entails) leaves an
inclusion-minimal witness set. Inclusion-minimal is not minimum-cardinality, so these sizes
are **upper bounds on minimal k, biased upward**; the lower bound k≥3 is exact.

## 2. The measured distribution

| population | n | k=1 | k=2 | k≥3 | k≥2 | k>2 |
|---|---:|---:|---:|---:|---:|---:|
| baseline, all relations | 21 | 6 (28.6%) | 5 (23.8%) | 10 (47.6%) | **71.4%** | 47.6% |
| baseline, powered | 4 | 1 | 0 | 3 | 75.0% | 75.0% |
| calculus, all relations | 154 | 49 (31.8%) | 24 (15.6%) | 81 (52.6%) | **68.2%** | 52.6% |
| **calculus, powered** | **24** | **2 (8.3%)** | **2 (8.3%)** | **20 (83.3%)** | **91.7%** | 83.3% |

Three readings of the same table, each measured:

* **Coverage fails before entailment does.** For 99 of 154 calculus relations (10 of 21
  baseline), **no single declaration's statement even mentions all the relation's atoms** —
  the k=1 test fails at support coverage, before any linear algebra runs. Where one
  declaration does cover the support (55 relations), it usually also entails (49) — so the
  k=1 class is essentially "there exists one statement that says the whole thing", which is
  precisely §65's transcription reading, and it holds for a third of the relations.
* **k=1 witnesses are almost always unique.** 46 of the 49 calculus k=1 relations have
  exactly one entailing declaration; 3 have two (independent restatements). All 6 baseline
  k=1 witnesses are unique.
* **The k≥3 witness sets are small but not tiny.** Inclusion-minimal sizes: baseline
  {3: 3 relations, 4: 3, 6: 1, 14: 3}; calculus {3: 11, 4: 10, 5: 13, 6: 16, 7: 13, 8: 5,
  9: 4, 10: 6, 11: 2, 12: 1} — median 6, maximum 12. These are upper bounds (§1).

## 3. What the classes look like, named

Names attached afterwards, by a human; the witness sets are in the JSON and each was
machine-checked to entail its relation.

**k=1 — the transcription class contains most of the showcase relations.** The audit's
suspicion is *confirmed for exactly the relations a reader would quote*:

* the **vis-viva** row (`r = G + M − 2·v`, powered) is entailed by the single theorem
  `ClassicalMechanics.VisViva.speedCircular_sq` — it is that statement's own dimensional
  balance, printed;
* **B = ∇×A** ← `ElectromagneticPotential.magneticField_curl_eq_magneticFieldMatrix`, alone;
* the **moment of inertia** ← `RigidBody.inertiaTensorAbout_eq_centerOfMass_add_pointMass`
  (and independently its `inertiaTensor_` twin — one of the three double-witness cases);
* the **SI dimension decomposition** rows ← `UnitChoices.dimScale_SI_SIPrimed` / `_SIPrimed_SI`;
* the unit-conversion rows (`furlongs = yards + …`) ← their own `_div_yards` lemmas.

**k=2 — two statements compose.** The powered example is the Lagrangian energy signature:
`lagrangian = toCanonicalMomentum + 2·⟨EuclideanSpace⟩` is entailed by
`{gradient_lagrangian_velocity_eq, toCanonicalMomentum_eq}` and by no single declaration —
the first theorem relates the Lagrangian to a velocity gradient, the second names the
momentum, and only together do they fix the exponent vector.

**k≥3 — the corpus-level class, 52.6% of all relations and 20 of the 24 powered ones.**
The rest of the Hamiltonian-mechanics family lands here: the
`hamiltonian`/`kineticEnergy`/`potentialEnergy` rows each carry an inclusion-minimal
witness set of ~9 declarations (`toCanonicalMomentum_eq`, `gradient_hamiltonian_position_eq`,
`return_time`, `trajectories_unique`, the `AmplitudePhase` trajectory/velocity lemmas, and
three damped-oscillator relations) — no statement in physlib says "H is an energy"; nine
theorems jointly force it. The Gaussian-moment row (`x^n = −n! − ½·π`, powered) needs 11,
including all three `physHermite` integral lemmas and `physHermite_norm`. The
anomaly-cancellation family (`MSSMACC.*`, coefficients ½ and 3/2) is almost entirely k≥3.

One honest caveat on reading witness sets: the certificate chain is whatever the linear
algebra needs, not a curated derivation. The QM oscillator-length row (`ξ`, powered, k≥3)
has a 9-declaration witness set that includes `minkowskiMatrix.as_diagonal` and
`LorentzGroup.inv_eq_dual` — the entailment routes through shared bookkeeping atoms
(casts, matrix constructors), so "jointly entailed by 9 declarations" does not mean "9
physically related theorems". The k *count* is unaffected; the *reading* of a witness set
requires looking at it.

## 4. Verdict, per the pre-registered threshold

**The primary criterion fires, decisively: 22 of 24 powered calculus relations (91.7%) are
k≥2, against the committed 20% threshold.** By the pre-registration, the §65 verdict is the
**discovery** arm: the corpus jointly entails dimensional facts that no single statement
states — 68.2% of all 154 relations, 91.7% of the powered ones, and the split is exact, not
an approximation. §65's literal k>2 reading holds too: 52.6% of all relations and 83.3% of
powered ones need at least three declarations.

The secondary descriptive reading also resolves: "most relations are k=1" is **false**
(31.8% of 154; 28.6% of 21). The method is not Osprey-with-the-output-kept.

But the transcription arm is not empty, and where it holds is worth stating plainly: the
k=1 third *contains most of the individually-legible physics* — vis-viva, B = ∇×A, the
moment of inertia, the SI decomposition. Those rows are single statements' dimensional
balances, printed, exactly as the audit said. The joint majority lives in the families —
Hamiltonian mechanics as one exponent signature, anomaly cancellation, the Hermite/Gaussian
integrals — where the dimensional fact is distributed across the theory and no one
statement carries it. That is the precise shape of the answer: **the showcase singletons
are transcription; the families are corpus-level entailment; and the powered subset — the
pre-registered discriminator for "this is physics, not bookkeeping" — is 91.7% the latter.**

## 5. What was NOT verified

* **Basis dependence.** The 154 relations are the RREF pivot rows under the published
  atom-name ordering — exactly what §65 asked to classify, but a different pivot order
  would present the same row space as different rows, and individual rows could shift
  between k-classes. No basis-independent invariant was computed.
* **Minimal k above 2.** The class k≥3 is exact; the witness-set sizes are inclusion-minimal
  upper bounds, not minimum cardinalities, and no uniqueness or canonicity of witness sets
  is claimed.
* **The cap-20000 populations** (17/66 relations, 3/15 powered) were not attributed; every
  number here is at `--cap 200000`, the cap the audited counts come from.
* **No k-attribution control was possible.** The shuffle and `mathlib-algebra` controls
  produce zero multi-atom relations (`physlib-calculus.md` §7), so there is nothing to
  attribute on them; this measurement inherits those controls rather than adding one.
* **The physics of the 154 is still unread.** `physlib-calculus.md` §10's caveat stands:
  beyond the handful named here and there, the 154 have not been read by a human. This
  measurement classifies their *provenance structure*, not their correctness or interest.
* **A relation is still not a theorem.** The system is homogeneous (`x = 0` solves it);
  k≥3 says three-plus statements are needed to *entail the exponent row*, not that the
  entailed row is physically deep or that the corpus is dimensionally certified
  (`physlib-dimensional.md` §4's verdict is unchanged).
* **Determinism was verified within this session only** (three identical builds on one
  machine and toolchain), and the `--literals free` ablation inherited from the prior art
  remains unmeasured.
