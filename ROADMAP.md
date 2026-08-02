# ROADMAP.md — The Unified Program

**Audience:** the agent (and the human), effective the day M0 (the FH skeleton per `design.md`) and the couette-re-e campaign (`CLAUDE-couette.md`, driven by `couette-research.workflow.js`) are complete. Until then, those two documents govern and this file waits.

**How to read identifiers.** Every letter-number identifier in this roadmap is written with its defining file, and you MUST resolve identifiers against those files — several letters collide across documents (bare `S1`–`S9` are substrate layers in `fh-substrate.md`; dotted `S1.2`, `S2.4` are solid-state targets in `fh-solidstate-tier*.md`; `D1`–`D6` in `fh-research-round5-lhc.md` are LHC targets while `D1`–`D3` in `fh-diagnostics.md` are diagnostics milestones). When in doubt, the parenthesized file wins. Glossary: `P#` → `fh-priority-list.md` · `T#`/quantum targets → `fh-quantum-research.md` · `A#` → `fh-physics-round2.md` · `B#` → `fh-research-round3.md` · `C#` → `fh-research-round4-sm.md` · `D#` (physics) → `fh-research-round5-lhc.md` · `V#` → `fh-statement-validity.md` · `E#` → `fh-codegen.md` · `L#` → `fh-latex.md` · `G#` → `CLAUDE-couette.md` · `G-A/B/C` → `fh-celestial-tiers.md` · `M0–M4` (meta ladder) → `fh-meta-effective.md` §6 · `H#` hard rules → `CLAUDE-couette.md` §2, enforced as compiler errors per `fh-diagnostics.md`.

**Standing law, all horizons:** every new statement passes the statement-tier vet battery (V1, V3, V7, V8, V10 — `fh-statement-validity.md`) before its freeze; every gate writes its ledger artifact; cost accounting (S5, `fh-substrate.md`) and the security posture (S4, `fh-substrate.md`) are active from the first commit of every horizon; the answer-key discipline (H6) applies to external benchmarks and oracle tables (`fh-benchmarks.md` §6, `fh-codegen.md` §4) exactly as to our own.

---

## Horizon 1 — The proving season (starts at couette G4-PASS)

Objective: convert the pipeline from "ran once" to "runs as a matter of course," via the Tier-1 priority targets (`fh-priority-list.md`) plus the toolchain that amortizes them.

1. **Finish P1** (`fh-priority-list.md`): couette G5–G7 per `CLAUDE-couette.md` — full battery, fidelity game (§16, `fh-statement-validity.md`), dispute adjudication from `statements-couette.fh` §6, artifact via emit-lean round-trip gate (E1, `fh-codegen.md`), equations via L0→L2 (`fh-latex.md`), paper per the Phase-7 structure. Exit: the referee pack exists; the dossier spec (`fh-statement-validity.md` §22) is drafted from it.
2. **P2** (`fh-priority-list.md`): the EuclideanDomain deletion demo (B1, `fh-research-round3.md`) — first meta-solution hunt, first data point for the discovered stratum (§7, `fh-meta-effective.md`). Run with answer-key discipline; ledger the synthesis trace as AbstractionBench seed data (`fh-benchmarks.md` §5).
3. **P3** (`fh-priority-list.md`): Jarzynski/Crooks per stat-mech Tier 2 (`fh-statmech-tiers.md`) — first external-community artifact; candidate lemmas upstreamed per the prelude-thinning strategy (`fh-codegen.md` §2, `fh-statement-validity.md` §10).
4. **P4** (`fh-priority-list.md`): NPA/I3322 rational certificate (`fh-quantum-research.md`) — founds the positivity engine (A5, `fh-physics-round2.md`); registers the engine's skeleton row in the Atlas (`fh-atlas.md`).
5. **P5** (`fh-priority-list.md`): the certified TDVP monitor — the Effective Calculus's Milestone 1 (`fh-meta-effective.md` §4/§9); package as the first `Effective` artifact with its (error, regime, cost) triple; its error field is the type's first shipped instance (§2.1, `fh-meta-effective.md`).
6. **Toolchain riders this horizon:** E2 checker extraction with Aeneas round-trip (`fh-codegen.md` §1) — unifies Rust/Lean validators; diagnostics D2 (`fh-diagnostics.md` §6) — agent payload + falsification triage wired to the V1/V9 generators (`fh-statement-validity.md`); the Wiedijk-100 FH stress suite (`fh-benchmarks.md` §1a) as M0's ongoing regression corpus; oracle harness v0 (`fh-codegen.md` §4) attached to every extracted kernel.

**Horizon-1 exit:** five referee packs (or four plus one ledgered honest failure), the positivity engine live, the Effective library non-empty, extraction round-trips green. Then choose Horizon 2's emphasis with the human, using cost data from S5 (`fh-substrate.md`).

## Horizon 2 — Amortization (the second consumers)

Objective: prove the machinery is a template. Each item deliberately reuses a Horizon-1 engine.

1. **Plasma δW transplant** (`fh-plasma-tiers.md` Tier 2): the couette workflow re-run with the physics renamed — the flagship's second customer; measure and ledger the transplant cost (this number is the program's economics headline).
2. **P6/P11** (`fh-priority-list.md`): the wallpaper census (S1.2, `fh-solidstate-tier1.md`; oracles: Bilbao/OEIS per `fh-codegen.md` §4) and helium brackets (`fh-qchem-tiers.md` Tier 2 + `fh-amo-tiers.md` Tier 2; oracle: Drake tables) — both riding P1's interval infrastructure.
3. **P7 + the benchmark audit** (`fh-priority-list.md`; `fh-benchmarks.md` §2): the W-mass certified combination (D1, `fh-research-round5-lhc.md`) and the vet-battery audit of an AI-prover benchmark — the referee genre's two debuts, one physics, one meta.
4. **P10** (`fh-priority-list.md`): the physlib quantum bundle (shortlist in `fh-quantum-corpus.md`) — ecosystem citizenship.
5. **Atlas goes live:** run the rediscovery-benchmark Tier-1 must-pass targets (`fh-atlas-validation.md` — note its `V#` are validation targets, not vet probes; the file disambiguates) against the now-populated corpus; the calibration campaign (§17, `fh-statement-validity.md`) runs its first blinded seeded-fault round using Horizon-1 statements as substrate.
6. **P8, P9, P12** (`fh-priority-list.md`) as capacity allows; P8's differential-geometry spike (`fh-gr-tiers.md` Tier 1) gates its own continuation.

**Horizon-2 exit:** transplant cost measured and small; Atlas validation must-passes green; calibration curve v1 published in dossiers.

## Horizon 3 — The research programs open

Objective: from targets to tracks. Enter each subfield at Tier 1–2 per its tier doc, ordered by engine-fit and measured cost: solid state (S2.1 mesh-sufficiency + S2.2 bulk–boundary first, `fh-solidstate-tier2.md`), celestial T1–T2 → the a-posteriori KAM spine (`fh-celestial-tiers.md`), fluids Tier 3 SOS bounds (`fh-fluids-tiers.md`), qchem Tier 3 RDM engine (`fh-qchem-tiers.md`), stat-mech Peierls (`fh-statmech-tiers.md` Tier 3). Meta program M2: the `Effective` type lands in FH with a couette/C3-style composed budget re-derived inside it (`fh-meta-effective.md` §9, `fh-research-round4-sm.md`), and the double-direction method (§8.1, `fh-meta-effective.md`) gets its first live `atlas resolve` on a recurring tail-lemma residual. Discovered-stratum experiment 1: B1's engine (`fh-research-round3.md`) pointed at Mathlib refactor history, released as AbstractionBench v1 (`fh-benchmarks.md` §5); FaithfulBench-Physics published from the calibration corpus. Begin the quantum-gravity interface corpus (Tier 1, `fh-qgravity-tiers.md`) — QEI/ANEC statements — as the analysis-muscle companion to whichever heavy-analysis track is live.

**Horizon-3 exit:** three tracks producing at Tier-2 cadence; two benchmarks released; the envelope operation (§3, `fh-meta-effective.md`) executable against the real library.

## Horizon 4 — Flagships (each requires an explicit human green-light + a written proposal)

The summits, attempted only with a track record behind them: the Hubbard bracket program (S4.1, `fh-solidstate-tier4.md`); the holographic entropy cone census (Tier 3, `fh-qgravity-tiers.md`); N-body M3–M4 and the Le Verrier gates G-A→G-C (`fh-celestial-tiers.md` Tier 4+, `fh-meta-effective.md` §6); the end-to-end certified Schwinger simulation (C3, `fh-research-round4-sm.md`); the Frauchiger–Renner adjudication at full depth (B4, `fh-research-round3.md`); and the φ⁴₂ *proposal* — written as a blueprint-plus-funding case, not attempted solo (B5, `fh-research-round3.md`). Selection rule: at most two concurrent flagships, chosen by S5 cost curves (`fh-substrate.md`) and Horizon-3 engine maturity, each proposed to the human with its own CLAUDE-couette-style operational contract (`CLAUDE-couette.md` is the template: clone its structure, never its physics).

---

## Kill criteria (merged from the parallel draft — honesty switches, checked at every horizon exit)

A program this ambitious needs pre-registered ways to be wrong. **(K1)** If the deletion demo (P2/B1) fails after honest effort, the *Atlas-synthesis* thesis is weakened — the certification pipeline is not; scope Atlas claims down, continue the proving tracks. **(K2)** If the calibration campaign (§17, `fh-statement-validity.md`) measures battery recall below the literature's ~19%-error baseline detection needs, halt all "validity-forward" publication claims until the battery is fixed — never publish a dossier the calibration data doesn't back. **(K3)** If S5 cost-per-theorem (`fh-substrate.md`) trends show a track's brackets tightening slower than compute prices fall, that track gets an off-ramp review rather than more agents. **(K4)** Any confirmed silent-meaning-change escaping the vet battery post-publication triggers the full §21 erratum protocol on our own work first, before any further external adjudication work. Kill criteria are ledgered at horizon exits with verdicts, like gates.

## The loop that never closes

Every horizon feeds the permanent systems: dossiers into the trust graph (§20, `fh-statement-validity.md`), failures into the error-fingerprint corpus (§5, `fh-diagnostics.md`), stubborn residuals into promotion candidates (§8, `fh-meta-effective.md`), costs into the priority re-ranking, and everything into the ledger. Maintenance rule for this file: re-rank at every horizon exit using measured costs, retire its predictions against actuals in the ledger, and remember the one-sentence constitution that outranks it as it outranks every other document — *search dirty, certify clean, state precisely, ledger everything, and let the kernel be the only judge.*