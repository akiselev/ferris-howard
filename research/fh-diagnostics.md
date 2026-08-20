# FH Diagnostics: Rust-Grade Errors, Agent-Grade Payloads

**Status:** Draft 0.1 · The error system: rustc's human ergonomics on the surface, a structured agent payload underneath, Lean's elaborator wrapped in the middle. Design principle: **an error is not a complaint, it is a routing decision** — every diagnostic must tell a human what went wrong and tell an agent what to do next.

## 1. Foundation: span fidelity through expansion

Everything depends on errors pointing at *FH source*, not expanded Lean. The syntax→syntax macro discipline pays its fifth dividend: every FH macro propagates source spans (Lean's `SourceInfo`/`withRef` machinery), so elaborator and kernel errors map back through the expansion — the sourcemap contract, TypeScript-style. Diagnostics carry **both** spans (FH primary, elaborated-Lean secondary) because the two consumers differ: humans read FH; agents sometimes need to operate at the Lean layer (a tactic error is *about* Lean syntax). A golden-test suite (`guard_msgs`-style) pins every diagnostic's rendering — error UX under regression test, because a diagnostic that drifts is a lie with a line number.

## 2. Rust-grade surface: codes, labels, applicable fixes

The rustc trinity, imported whole. **Error codes** (`FH0xxx`) classifying both wrapped Lean families (type mismatch, unification, instance-resolution failure, universe, termination, unknown identifier, timeout) and FH-native errors that Lean cannot know about: Ruling-A boundary violations ("Bool-world operator in a Prop position — did you mean `decide(...)`?"), Ruling-B parse traps (comparison/generics ambiguity), junk-value lint hits (V10 as a compile diagnostic), and the H-rules as *compiler-enforced* errors — frozen-statement edits, whitelist-violating axioms, `native_decide` in a certificate path all fail with the CLAUDE.md rule cited. `fh explain FH0421` gives the rustc `--explain` treatment with math-aware prose and Rosetta cross-references, so the error index doubles as a teaching layer. **Labeled multi-span rendering**: primary span plus secondary labels ("this instance was selected here", "expected `Prop` because of this theorem signature"), notes, and `help:` lines. **Machine-applicable suggestions** with rustc's exact applicability taxonomy — `machine-applicable` / `maybe-incorrect` / `has-placeholders` — as structured edits, so `fh fix` exists on day one and agents apply the safe tier without deliberation.

## 3. The agent payload: what no compiler has shipped

`fh check --format=agent` emits versioned JSON (rustc-JSON/SARIF-adjacent) where each diagnostic carries, beyond the human rendering:

**Goal-state attachment.** On any proof failure: the pretty goal *and* its structural form, the typed local context, outstanding metavariables — the agent starts its next attempt already holding what a human would spend a tool call retrieving.

**Retrieval baked into the error.** Unknown identifier or a dead-ended goal auto-runs the retrieval stack (`exact?`-shape search, Loogle, LeanSearch) and attaches the top-k candidates *inside the diagnostic*. The error arrives carrying its own likeliest fixes from Mathlib — errors as pre-executed queries, converting the stuck-state→search loop from two agent turns into zero.

**Instance-resolution autopsies.** The most opaque failure in the Lean experience — typeclass synthesis dying silently — auto-elevates its trace into a structured tree: which chains were tried, where each failed, which near-miss instances exist. The #1 "senior formalizer required" error becomes legible to a first-week agent.

**Falsification triage — the flag that changes everything.** On repeated proof failure, the diagnostic pipeline auto-runs the falsification arm (`plausible`, `decide` on small instances, the V1/V9 generators) against the goal and attaches the verdict: `goal_status: likely_true | FALSIFIED(witness) | undecided`. This is the distinction agents burn the most compute failing to make — *hard versus wrong* — and a `FALSIFIED` payload converts hours of doomed proof search into an immediate H2 escalation ("the statement may be wrong: stop, ledger, human") with the witness as evidence. No compiler ships this because no compiler has our controls machinery; it may be the single highest-value item in the design.

**A closed repair-action vocabulary.** Every error code maps to `suggested_actions` drawn from a fixed ontology — `search_mathlib`, `add_side_condition`, `case_split_on`, `unfold_definition`, `escalate_h2` (statement suspicion), `escalate_h3` (axiom/anti-cheat), `budget_restructure` (kernel-time blowups: shrink the certificate, per couette Phase 4 doctrine) — so orchestrators route mechanically instead of re-deriving policy from prose. Notably present: `weaken_statement` exists in the ontology *only* as a forbidden action that renders the H2 citation — the vocabulary encodes the rules by what it refuses to suggest.

**Telemetry for budget errors.** Timeouts and heartbeat exhaustion attribute themselves ("this `simp` call consumed 78% of the budget at this span"), because "too slow" without a culprit is not actionable and agents will otherwise retry the identical divergence.

## 4. Pre-elaboration lints: fail at the right layer

A class of errors should never reach Lean at all. The FH front end lints at parse time — Ruling B ambiguities, Prop/Bool boundary uses, junk-value operations without guards, emittable-subset violations (the emit-lean lint), missing `#[latex]` on public flagship declarations — so the diagnostic speaks FH vocabulary (`Space`, not `Type`; the user's operator, not its expansion) and the expensive elaborator only ever sees code that deserves elaboration.

## 5. The loop closes: errors as corpus

Every diagnostic lands in the ledger with a **shape fingerprint** (anti-unification over goal/error structure — the Atlas skeleton machinery pointed at failure). Recurring fingerprints cluster into the tactic-gap and missing-lemma reports that the formalization experience literature documents as the ecosystem's real tax — except ours are generated continuously, ranked by frequency, and each cluster is a concrete upstream contribution or FH-tooling task. The error system thereby joins the discovered stratum: the failure log is a corpus, the corpus compresses into patterns, and the patterns are the roadmap. Same trick as everywhere else in this project — nothing is merely an error; everything is data with a pedigree.

## 6. Milestones

**D1** (with M0): span propagation + the FH-native parse lints + human rendering for ten most common errors, golden-tested. **D2** (with first proof campaigns): agent JSON with goal attachment + retrieval baking; falsification triage wired to the controls generators. **D3**: instance autopsies, action ontology, telemetry, fingerprint clustering. Acceptance test for the whole system, stated as one sentence: an agent receiving an FH diagnostic should never need to ask "what do I do now?" — and a human receiving one should occasionally smile, which is the rustc bar and the right one.
