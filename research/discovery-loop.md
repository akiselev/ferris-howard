# The discovery loop, applied: this project has the stages and not the loop

**Status:** analysis and work order, 2026-08-06. Written against the pipeline state as of
`corpus-atlas-findings.md` §67, the C4 confirmation instrument, and the Kuna replay lane
(`kuna-math-loop.md` §18). Every number in this document is a measured one quoted from the
section cited next to it; nothing here was re-run. This document makes no discovery claim.

External frame: <https://www.discoveryloop.com/> describes mechanizing the experimental
cycle itself — propose experiments, implement them, examine results, iterate — so that
thousands of loop iterations run in parallel instead of one per human session, starting
with the company's own technology as its first customer. The claim worth importing is not
any one stage; it is that **the loop is the product**. A pipeline whose stages are excellent
but whose arrows are all human runs at human cadence, and cadence is the resource that was
actually exhausted here: 67 findings sections, each one a hand-driven iteration.

The external audit reached the same diagnosis from the other side
(`corpus-atlas-findings.md` §65, verbatim):

> You have built the best-tested generator half of a discovery loop and none of the refuter
> half. That is why 63 sections of careful work produced no discoveries. It is not an effort
> problem and not a rigor problem.

## 1. The map, stage by stage

| stage | what exists | mechanization |
|---|---|---|
| **propose** | census-complete candidate generation, measured precision | unattended within a run |
| **implement** | kernel re-elaboration (C4); a prover command with no lane | the single weakest stage |
| **examine** | controls, verdict taxonomy, audits | strongest stage; partly agent labor |
| **iterate** | the Kuna method, working | a discipline, not a mechanism — 100% human |

### Propose — built, and census-complete over its askable space

The generalization detector proposed 2,704 whole-Mathlib weakening candidates and the probe
runs are a census, not a sample: 2,305 probed (85%), the remaining 399 unaskable by
construction (§42). Transport proposes 17,510 stated open targets against a 0.0%
frequency-matched null (§51). The dimensional solver proposes 154 relations with both
negative controls at zero (§63). Where proposal fails, the failure is measured rather than
suspected: the posting-fraction prefilter deletes the low-specificity keys cross-domain
analogy lives in (0/4 pre-registered correspondences at the shipped cutoff, 4/4 at
`max_len` 1,600, matched-N refutation arm separating document frequency from corpus size,
§66), and 143,613 multi-carrier declarations are refused before judgment (§37).

### Implement — one real instrument, and no prover behind it

`#fh_home_refute` is a genuine run-the-experiment stage: rebuild the binder at the weaker
class, re-synthesize instances in type and value, submit the declaration's own proof term
to the kernel via `addDeclCore`'s `Except` (`Home.lean`; the first version read `addDecl`'s
logged error as success — commit `bc7e45b`). 2,399 probes produced 431 unique
kernel-confirmed weakenings at 19.4% decisive precision, 387 after the prior-art screen
(§42, §45). The raw kernel call is ~1–2 ms, which refuted the design premise that
confirmation would be too expensive to run at scale.

Everything past that instrument is missing, and §65 verified it in source rather than
inferring it: **no prover appears anywhere in the loop** — zero hits for `aesop`, `exact?`
or `duper` outside vendored Mathlib. The 1,858 REFUTED verdicts mean "this proof term does
not survive the weakening", never "the statement is false", and not one has been offered to
a proof search. `#fh_home_attempt` exists precisely for this — the wrong-binder interface
was fixed (`8f6bd3b`), the polymorphic-universe kernel bug was fixed
(`kuna-math-loop.md` §14) — but its only run is a hand-assembled scratch file with no
generator and no scorer for its `PROVED` output. The 17,510 transport targets, 76 prose
physics claims and 18 `sorry`-backed physlib declarations have likewise never been
attempted (§65). The physics kernel arm is additionally blocked on a build fact:
`Home.lean` lives in `lean/` (v4.32.2) and physlib is pinned to v4.32.0, so the emitted
probe file builds in neither workspace until the command moves into `atlas-extract`, which
imports only `Lean` and compiles under both (`physlib-hypothesis-min.md` §8.1).

### Examine — the strongest stage in the pipeline, with one named blind spot

The verdict taxonomy is honest by construction (CONFIRMED sound and final; REFUTED ≠ false;
INCONCLUSIVE when re-elaboration itself failed, after §34 caught that mislabel shipping).
Every positive has a control that could have killed it: the forced-target refutation, the
40/40 injection sensitivity of the novelty screen (§40), the matched-N prefilter arm (§66),
`foundation-control.py`'s abort-rather-than-report. §65 rated this discipline above the
venue norm. The named blind spot is prior art, not statistics: three novelty claims were
wrong because no literature step exists anywhere in the loop, across 11,745 lines of
research docs with zero citations (§65). An examine stage that only checks internal
validity approves externally false claims.

### Iterate — a working method with no machine under it

The Kuna lane *is* the iterate stage and it demonstrably works as a discipline: E0's
audited event miner, four replays that each rejected the tempting detector change for a
measured reason, and MC0/MC1's narrow option-gated acceptances (`kuna-math-loop.md`
§11–§18). It is also the project being its own first customer, in exactly the
discoveryloop.com sense — replay losses drive instrument repairs. But every arrow is a
human: each tranche was a newly written script, probe files are compiled by hand, state
crosses rounds as `/tmp` filename conventions, and the single automated feedback edge in
the entire repository is `probe-plan.py --scored/--exclude-probed`.

## 2. The missing arrows, enumerated

These are the places a human currently stands between two scripted stages. Closing the loop
means mechanizing these arrows, not inventing new stages.

1. **emit → compile.** No script builds the emitted probe file; `generalization-run.py`
   ends at `write_text`. CLAUDE.md §2 documents this exact step as the one where a red
   gate has been read as green before (piped exit status).
2. **sweep → plan.** `generalization-full.py` writes `/tmp/fh-gen-full-candidates.json`;
   `probe-plan.py` defaults to `/tmp/fh-gen-closure-candidates.json`. The chain breaks on a
   filename every round.
3. **REFUTED → attempt.** No generator turns the scored REFUTED ledger into an
   `#fh_home_attempt` file; no scorer parses `PROVED` lines. The first attempt run was
   assembled by hand and discarded for probing the wrong binder (`kuna-math-loop.md` §1).
4. **attempt → escalation.** The ladder is fixed (`rfl, simp, aesop, exact?`, supplied by
   the probe file since `Home.lean` imports only core); there is no budget policy and no
   binder-index syntax for the duplicate-source refusal.
5. **confirmed → external oracle.** None of the 387 has been offered to Mathlib — "a free
   external oracle sitting unused" (§65), and the only oracle available that can say
   *not interesting*, which no internal control can.
6. **claim → literature.** No search step guards novelty language; that is how §28, §52 and
   §54 went wrong.

## 3. The work order

§67 already fixed the order of operations; this section makes each item a bounded lane with
its controls named before it runs, per the Kuna rules (`kuna-math-loop.md` §2).

**L1 — the refuter lane** (§67 item 2: "a prover in the loop is a week's work and the
cheapest missing piece"). ✅ **Landed 2026-08-06, first round complete**
(`corpus-atlas-findings.md` §68). `scripts/attempt-plan.py` +
`scripts/score-attempts.py`, three plants per shard rather than two — provable, false,
and unstatable — attempted with the same ladder as the data lines. Round 1: **1,783
unique REFUTED triples attempted, 155 kernel-proved by arguments their original proofs
did not use (13.4% of the 1,157 posable), 142 surviving the whole-corpus novelty screen.**
Tactic depth `aesop` 84 / `simp` 42 / `exact?` 29 / `rfl` 0. The plants earned their
keep on launch day: `fh_plant_hard` caught heartbeat timeouts erasing verdicts inside the
first eight minutes, and the `tryCatchRuntimeEx` repair carries a pinned regression.
Remaining in this lane: the 18 physlib sorries (still gated on the `Home.lean` →
`atlas-extract` move) and the transport targets (statement synthesis, a different
instrument).

**L2 — the loop driver.** ◐ mostly landed. `lean/FhBatch.lean` (`fh_batch`) imports the
environment once per worker (83/83 byte-identical differential, §68; first production
round §69: three imports totalling 41 s against round 1's twenty-three of minutes each).
`scripts/discovery-round.py` chains plan → run → score → screen out of one round
directory with per-child exit statuses in a manifest and one serialized `lake build`
before any worker; its score-stage acceptance reproduces round 1's frozen totals exactly
(§69). Still open, stated rather than implied: the `run` stage has not yet driven a live
round (rounds 1–2 were launched by hand; round 3 goes through the orchestrator end to
end), and probe-lane stages (sweep → screen → probe) are not yet under it.

**L3 — standing gates every round, not once.** `foundation-control.py` on any new slice;
the injection control on every screen run; a forced `#fh_home_refute` that must say no in
every probe file. An unattended loop without per-round negative controls is the tool that
says everything is fine, at machine speed. **Amended by round 3 (findings §70): every
lane that enumerates over a relation needs a control aimed at that relation's own failure
mode.** The plants validated the machinery while an inverted lattice fed it strengthenings
labeled as weakenings — 54 kernel-proved wrong answers with green controls end to end.
The strict lattice (projection-shaped edges only, 1,325 kept / 15,722 name-matched
impostors rejected) plus a refuse-to-emit direction assertion is now the recovery lane's
own gate; the crude relation survives only where its errors are conservative (the novelty
screen, where pollution over-matches prior art).

**L4 — what the loop then consumes.** ◐ The prefilter repair is landed and measured
(findings §72): `posting_work_budget`, option-gated and default-off, golden byte-identical
with the knob off, and the pre-registered classical↔quantum correspondences recovered
0/4 → 4/4 on the physics corpus while the nonsense-dictionary controls moved by at most
one row. Still open, in measured-cost order: carrier-attached requirements corpus-wide
(`kuna-math-loop.md` §16, MC1 — the highest-value representation change, §58); the
proof-term encoding go/no-go, byte cost measured first (§67 — 97.5% of the extracted
record is currently discarded one line in); and re-running the physics hypothesis sweep
plus the three novelty screens on §70's strict lattice.

**L5 — the external oracle.** ◐ prepared, not yet offered: `research/upstream-batch1.md`
(2026-08-06) holds 16 vetted entries covering 46 declarations with source locations,
binder diffs, per-candidate risk notes — including the RingOfIntegers catch, where the
weakened lemmas cannot be *stated* at source level because `𝓞 K`'s definition itself
requires `Field K` — and a PR template. Submission is deliberately a human act. This
remains the only arrow that lets the world refute the pipeline rather than the pipeline
refuting itself.

## 4. What this does not claim

Mechanizing the loop compresses iteration time; it does not manufacture discoveries. §67's
own evidence is that the dense corpus yielded 387 minor generalizations, so the object-level
yield question — is there anything deep to find with these instruments — stays open. The
loop is how that question gets answered per unit of machine time instead of per human
session, and how a negative answer, if that is the answer, becomes a measured result
rather than fatigue.
