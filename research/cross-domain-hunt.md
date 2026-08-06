# Cross-domain hunt: the repaired prefilter pointed at the unknown sky

**Date:** 2026-08-06. **Corpus:** `/tmp/pfx-base.jsonl`, 95,268 declarations — the 99.46%-closed
physics corpus of `physlib-prefilter.md`, with the `Physlib.`/`QuantumInfo.` roots stripped so
each subfield is its own theory. **Instrument:** `Corpus.dictionary` /
`Corpus.similar` with `posting_work_budget = 2000` (findings §72's repair, at the study's
reference W), conclusion anchor, shipped floors otherwise (`per_decl=1`, `theorems_only`,
`min_common=6`, `min_retention=0.30`, score `retention`). **Raw output:**
`research/data/cross-domain-hunt.json`. Every number below was measured in this session.

The prefilter repair recovered all four pre-registered classical↔quantum correspondences
(T1–T4) on the pair they were registered for. This run asks the next question: pointed at
**every** cross-theory pair at once, with nobody having named the targets in advance, does the
newly opened channel surface any correspondence worth a physicist's minute?

Short answer: **not through the assigned pipeline** — the top of the newly visible channel
grades no better than the nonsense controls. One A-caliber unregistered correspondence does
sit in the channel (§7: the canonical-ensemble ↔ von Neumann entropy bridge, budget-only at
the `similar` floors), but both surfaces above the channel — the ranking key and the
dictionary's `per_decl=1` assignment — deleted it, and it was recovered only by reading the
channel's row set directly. The hunt's verdict on the sky is therefore also a verdict on the
telescope mount.

## 1. Method

* **Theory partition.** Top-level module prefix, as `dict::theory_of` sees this corpus.
  Eligible: ≥ 50 declarations on both sides; `Mathlib`, `Init`, `Lean`, `Std`, `Batteries`,
  `Aesop` excluded as non-physlib infrastructure. That leaves **21 theories** (17 physics +
  `Meta`, `Units`, `ForMathlib`, `Mathematics` as physlib infrastructure), and **210 unordered
  pairs**, all covered in both arms — no truncation.
* **Direction.** One call per pair, left = the side with fewer theorems (tie alphabetical),
  identical in both arms. `dictionary` iterates left theorems, so this is the cheap direction;
  rows only found in the other direction are not measured here, and that is a stated limit
  rather than a hidden one.
* **Arms.** Identical calls with `posting_work_budget=2000` (on) and `None` (off — the shipped
  cutoff, `max_len` = 95). One process per arm, as `scripts/phys-budget-check.py` does.
  Off arm: 175.5 s wall. On arm: 201.0 s. Median per-pair dictionary: 0.2 s / 0.3 s.
* **Budget-only row** = `(left, right)` in the on-arm dictionary of a pair and not in the
  off-arm dictionary of the same pair. These are the newly visible channel and the hunting
  ground. Note the on arm is **not** a row-level superset: 315 off-arm rows disappear because
  a left with a newly admitted, better-scoring partner is re-assigned (`per_decl=1`). The
  candidate sets are supersets (findings §72); the assignments move.
* **Ranking, fixed by the task:** retention × support, support = `common` of
  `generalize(left, right, anchor="conclusion")` — shared concrete nodes of the
  conclusion-anchored anti-unification. (The engine exports no "support"; this definition is
  recorded here and in the JSON.)
* **Grading, per `physlib-classical-quantum.md` §2e + §8:** read both statements (Lean source,
  I3 where no source exists), grade **A** genuine correspondence / **B** shared mathematics /
  **C** artifact / **D** spurious (both contentful, unrelated). The grader is the implementing
  agent (Claude), grading alone and conservatively. Control rows were shuffled into the queue
  (seed 20260806) before any statement was read and unblinded after all 50 grades were
  written; this blinding is **procedural, not epistemic** — declaration names stay visible and
  names carry theories, so a human-blind protocol this is not.
* **Controls:** the two NC3 precedent pairs, `ClassicalMechanics ~ Meta` and
  `Thermodynamics ~ Meta` (physics vs the library's HTML-note utility), run through the
  identical sweep; their top budget-only rows were graded inside the same queue.

## 2. The sweep, on vs off

Totals over all 210 pairs (per-pair table for all pairs in the JSON; 11 pairs return zero
rows in both arms, 199 return at least one row with the budget on):

| kind | pairs | rows off | rows on | budget-only |
|---|---:|---:|---:|---:|
| physics × physics | 136 | 2,028 | 4,848 | **3,029** |
| involving infra (incl. infra × infra) | 72 | 878 | 2,381 | 1,608 |
| **NC3 controls** | 2 | 33 | 47 | **15** |
| total | 210 | 2,939 | 7,276 | 4,652 |

Top pairs by newly visible rows:

| pair | off | on | budget-only |
|---|---:|---:|---:|
| Particles ~ QFT | 193 | 296 | 153 |
| Particles ~ Relativity | 107 | 235 | 138 |
| StatisticalMechanics ~ SpaceAndTime | 13 | 101 | 90 |
| StatisticalMechanics ~ ClassicalMechanics | 10 | 89 | 84 |
| SpaceAndTime ~ Particles | 57 | 133 | 82 |
| StatisticalMechanics ~ Particles | 8 | 89 | 81 |
| StatisticalMechanics ~ Electromagnetism | 5 | 84 | 79 |
| StatisticalMechanics ~ Relativity | 9 | 86 | 77 |
| Mathematics ~ Particles (infra) | 35 | 91 | 76 |
| QFT ~ Relativity | 35 | 111 | 76 |

The controls barely move, replicating prefilter §4c's direction of effect on a new protocol
(this sweep runs Meta as the left side, so the absolute counts differ from the study's
35 → 36): `Meta ~ ClassicalMechanics` 25 → 29 rows, `Meta ~ Thermodynamics` 8 → 18. The real
pairs grow 2.4× where the controls grow 1.4× — and `StatisticalMechanics`, whose off-arm
dictionaries were nearly empty (5–13 rows), is where the budget opens the most new sky.
That last fact matters in §7.

**The knowns replicate inside the sweep.** The on-arm `ClassicalInfo ~ Entropy` dictionary
(27 rows, vs 6 off) contains all four T1–T4 rows plus the fifth known
(`Hₛ_uniform ~ Sᵥₙ_le_log_d`, prefilter §4d); all five are budget-only here, and all are
excluded from the hunt's numerator below.

## 3. What the assigned ranking key does, measured before grading

Ranking the 3,029 physics budget-only rows by retention × common and asking where the
excluded knowns *would* have ranked:

| known row | rank under retention × common | rank under retention alone |
|---|---:|---:|
| Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero | 437 / 3,029 | 124 |
| Hₛ_nonneg ~ Sᵥₙ_nonneg | 438 | **17** |
| Hₛ_le_log_d ~ Sᵥₙ_le_log_d | 661 | 212 |
| Hₛ_uniform ~ Sᵥₙ_le_log_d | 855 | 413 |
| H₁_nonneg ~ Sᵥₙ_nonneg | 1,150 | 525 |

**The key buries exactly the kind of row the repair exists to recover.** A true cross-carrier
correspondence shares a *small* conclusion (T1–T4 carry `common` 20–27); what carries a large
`common` is shared apparatus — the distribution-space rows below share **43,774** concrete
nodes of `→d[ℝ]` instance plumbing while agreeing on nothing physical. Support-as-common is
the retention-denominator lesson (CLAUDE.md §5) in a new position: a size-flavored factor
rewards the erasure-resistant mass of a framework, which is anti-correlated with cross-domain
content. The grading below therefore runs twice: the assigned key (primary), and retention
alone (robustness).

## 4. The graded top-40, controls interleaved

40 top real rows (physics × physics, knowns excluded) + top 10 control budget-only rows,
shuffled, graded in queue order. Full statements and per-row notes in the JSON. Tallies:

| | A | B | C | D |
|---|---:|---:|---:|---:|
| real top-40 (assigned key) | **0** | 5 | 24 | 11 |
| NC3 controls (10) | 0 | 0 | 10 | 0 |

What the 40 real rows actually are, by family:

* **14 rows — one definitional field, worn 14 ways** (`Particles ~ QFT`). Every
  anomaly-cancellation lemma of every Standard-Model variant pairs with the same right,
  `ACCSystemLinear.LinSols.linearSol : ∀ i, χ.linearACCs i val = 0` — the *structure field*
  the lefts instantiate, e.g.

  ```
  lemma gravSol (S : (SM n).LinSols) : accGrav S.val = 0 := S.linearSol ⟨0, by simp⟩
  ```

  The left is proved *by* the right. A dictionary that pairs a framework with its own
  instantiations is reporting usage, not analogy — `frontier` excludes citation-linked pairs
  for exactly this reason, and `dictionary` has no such control. All C.
* **8 rows — `mk.sizeOf_spec` boilerplate** across physics structure types (harmonic
  oscillators ~ SUSY charge spectra, F-theory quanta ~ EM free space). Identical in kind to
  the control rows. All C. Plus **2 rows of `rfl`-trivia** (`x₀_zero`/`v₀_zero` against
  `EuclideanGroup.one_translation` — "the zero element's component is zero", definitional on
  both sides), also C.
* **11 rows — apparatus coincidences, graded D.** Two contentful statements sharing a large
  instance tree and no claim. Rank 1 under the assigned key is
  `infiniteWire_vectorPotential_distSpaceDeriv_0 ~ Space.constantTime_spaceCurlD`
  (key 0.3517 × 43,774 = 15,395); the emblem is the row that tops the retention ordering too
  (retention 0.885, common 1,567 — rank 5 under the assigned key):

  ```
  lemma lagrangian_add_const … : lagrangian 𝓕 ⟨fun x => A x + c⟩ J x
                                   = lagrangian 𝓕 A J x - ⟪c, J x⟫ₘ
  ~ lemma timeLike_iff_norm_sq_pos : causalCharacter p = .timeLike ↔ 0 < ⟪p, p⟫ₘ
  ```

  A gauge-shift identity for the EM lagrangian against a causal-character criterion; what
  they share is the Minkowski inner-product apparatus. Likewise the four
  `DistElectromagneticPotential` statics lemmas, each pairing a real magnetostatics fact with
  the same curl-interchange plumbing lemma through ~40k shared distribution-framework nodes.
* **5 rows — B, shared mathematics, honestly matched and physically empty.** The best of the
  top-40: `V_rho_isometry ~ standParamAsMatrix_unitary` (a quantum-info purification isometry
  and the CKM standard parametrization both satisfy `AᴴA = 1`); `Space.coordCLM_apply ~
  Lorentz.Vector.coordCLM_apply` (the same API lemma on Euclidean vs Lorentzian carriers); and
  the one row a physicist might linger on,

  ```
  lemma momentumTransport_eq_materialAcceleration_add_continuityResidual …
      ∂ₜ (momentumDensity …) + matrixDiv (momentumFlux …) = ρ • materialAcceleration + …
  ~ lemma time_deriv_electricField_of_isExtrema …
      ∂ₜ (E …) = 1/(μ₀ε₀) * ∑ⱼ ∂ⱼ (B-matrix …) - (1/ε₀) * J …
  ```

  the Cauchy momentum balance against the Ampère–Maxwell law — two genuine balance-law-shaped
  evolution equations. Conservatively B: the shared thing is the balance-law shape, not a
  correspondence between the two theories' content.

## 5. Robustness: the same hunt ordered by retention alone

Top-20 physics budget-only rows by retention (the ordering the study's own tables use):
**A 0, B 4, C 13, D 3.** The B rows are the positivity family
(`sandwichedTraceFunctional_nonneg ~ variance_nonneg`, `Sᵥₙ_nonneg ~ fidelity_ge_zero` …) —
real quantum quantities, same generic claim, no correspondence; the Cs are `sizeOf_spec`
pairs at retention 0.8254, `congr_simp` plumbing, and content-free positivity
(`0 ≤ |V_ij|` by `norm_nonneg`, `0 ≤ √x` by `sqrt_nonneg`); the Ds include
`TimeTransMan.diff_self ~ HiggsField.Potential.toFun_zero` — two ways to say "this evaluates
to zero". The conclusion does not move with the key: **no A surfaces either way.**

## 6. The blind-control comparison

All ten control rows graded C (constructor `sizeOf_spec`/`injEq` between note-taking
utilities and physics structures) — and so did 24 of the 40 real rows under the primary key,
13 of 20 under retention. The controls were never *better* than the real list (no control D
pretends to content, no control B), but the real list's margin over nonsense is five B rows
out of forty. By the pre-registered standard — a hunt that cannot out-grade its nonsense
controls has found nothing — **the pipeline as assigned found nothing.** The D rows are the
one qualitative feature unique to the real side, and they are a defect signature, not a
discovery: physics theories share big frameworks, so an apparatus-weighted key manufactures
confident cross-theory pairings out of instance plumbing.

## 7. A post-hoc finding the protocol deleted: the Gibbs ↔ von Neumann entropy bridge

Everything in this section is labeled what it is: found by scanning the 3,029-row budget-only
channel for named physics structures *after* the graded queues were fixed, then measured
directly. It is not a product of the assigned ranking — that is the point of reporting it.

`StatisticalMechanics` defines `CanonicalEnsemble.shannonEntropy = -kB ∑ pᵢ log pᵢ` of the
canonical distribution, and proves `entropy_nonneg : 0 ≤ 𝓒.shannonEntropy T`. QuantumInfo
proves `Sᵥₙ_nonneg : 0 ≤ Sᵥₙ ρ` and ClassicalInfo `Hₛ_nonneg : 0 ≤ Hₛ d`. The two
formalizations share no citation link in physlib — grep finds no reference from
`StatisticalMechanics/` to `Hₛ`/`Sᵥₙ`/`ClassicalInfo`'s or `Entropy`'s modules or back; the
sole cross-package import is `QuantumInfo.ForMathlib.ComplexLaplaceTransform`, math support
unrelated to entropy. This is E16's family on a theory pair nobody
pre-registered: thermodynamic entropy of the Gibbs ensemble against the information
entropies. Measured, per `similar` at the shipped floors, conclusion anchor:

| pair | budget = 2000 | shipped cutoff |
|---|---|---|
| `Sᵥₙ_nonneg ~ CanonicalEnsemble.entropy_nonneg` | **proposed, rank 92 of 379** (ret 0.684) | absent (3 candidates above floors) |
| `Hₛ_nonneg ~ CanonicalEnsemble.entropy_nonneg` | **proposed, rank 56 of 108** (ret 0.632) | absent (13 above floors) |

Budget-only in both incarnations — this is the repaired channel carrying an unregistered
A-grade correspondence (A by T1's own precedent: `Hₛ_nonneg ~ Sᵥₙ_nonneg` was scored genuine
E16, and this is the same claim across a different divide). Two adjacent budget-only
dictionary rows support the family: `Sᵥₙ_relabel ~ CanonicalEnsemble.phase_space_unit_congr`
(invariance under relabeling / unit choice, B) and `Sᵥₙ_unit_zero ~
partitionFunction_dof_zero` (trivial system is trivial, B). A third —
`Sᵥₙ_subadditivity ~ mathematicalPartitionFunction_add`, the extensivity family — was already
returned at the shipped cutoff, so it is not a repair finding.

And yet nothing above surfaced it:

* **The dictionary's assignment threw it away.** `per_decl=1` gives `Sᵥₙ_nonneg` one slot,
  and the budget-widened candidate set fills it with
  `CanonicalEnsemble.mathematicalPartitionFunction_nonneg` at retention 0.9412 — a
  content-free positivity lookalike (`0 ≤ Z` is `measureReal_nonneg`) that outscores the
  genuine partner (0.684). Widening candidate generation *changed the assignment for the
  worse* on exactly the row that mattered. A narrowing knob got its control in §4c of the
  prefilter study; the assignment step is a narrowing knob too, and this is its failure case.
* **The ranking key buried it.** Retention × common puts the row's family (common ≈ 22–23) in
  the mid-hundreds among 3,029, below every framework coincidence.

Honest deflation: this is the shallowest member of its family (nonnegativity), physlib holds
no `shannonEntropy ≤ log(states)` counterpart for the maximum-entropy bound, and one A-family
at the bottom of a 3,000-row channel is not a harvest. But it is a real, checkable,
previously unregistered correspondence — the canonical bridge between thermodynamic and
information entropy — sitting in the corpus, candidate-visible only through the repair.

## 8. Verdict

1. **Did the repaired channel, hunted as assigned, surface a correspondence worth a
   physicist's minute that was not already known?** No. Top-40 by retention × support:
   0 A, 5 B, and the nonsense controls grade indistinguishably from 60% of the real list.
   Same at the retention ordering. The channel's volume is framework instantiation
   (`linearSol` × 14), constructor boilerplate, positivity, and apparatus coincidence.
2. **Is the channel therefore empty?** No — §7's entropy bridge is in it, budget-only,
   A-caliber by the studies' own standard, and unregistered. It was recovered by reading the
   channel directly, not by the pipeline. False negatives were manufactured downstream of a
   recall repair, in the two places CLAUDE.md's corollary predicts: a ranking key with a
   size-flavored factor, and an assignment cap with no negative control.
3. **What this argues for, concretely.** (a) Cross-theory ranking should not multiply by
   apparatus mass; retention with a smallness-aware tie-break beat the assigned key on every
   measured known. (b) `per_decl` assignment needs the same treatment `max_per_right` got in
   NC6: report the uncapped alternates, or a crowding control that flags a left whose top
   partner changed when the budget opened. (c) `dictionary` should optionally exclude
   citation-linked pairs, as `frontier` already does — 14 of the top 40 were a framework
   paired with its own instantiations.

## 9. Limits

Single grader, and the grader is the agent that ran the pipeline; blinding was procedural
(shuffled queue, source field unread until all grades written), not epistemic — names reveal
theories. One direction per pair (smaller side left). W = 2,000 is the study's reference
point, not a shipped default. The token scan behind §7 looked for named physics structures
and can only find what physicists already have words for — which is what "pre-registered by
the culture" means; a correspondence with no name would need the graded-queue route, which is
exactly the route shown to be defective.

## 10. Reproducing this

The pipeline is archived as `scripts/cross-domain-hunt-{sweep,rank,stmts,final}.py`; the
work directory for the intermediate `hunt-*.json` files is `$HUNT_DIR` (default `.`).
Sweeping all 210 pairs costs ≈ 3.5 min per arm after the ~30 s load and ~100 s
conclusion-index build; one arm per process, as `scripts/phys-budget-check.py` does.

```sh
uv run scripts/cross-domain-hunt-sweep.py --arm off   # shipped cutoff
uv run scripts/cross-domain-hunt-sweep.py --arm on    # posting_work_budget = 2000
uv run scripts/cross-domain-hunt-rank.py              # budget-only diff, lgg support,
                                                      # blind queue (seed 20260806)
python3 scripts/cross-domain-hunt-stmts.py            # attach Lean source (physlib pkg)
python3 scripts/cross-domain-hunt-final.py            # grades -> research/data/cross-domain-hunt.json
```
