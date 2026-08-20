# FH Debug: Term-Level Debugging of Verified Computation

**Status:** Draft 0.1 · The debugger for the extracted layer — where the agent steps through *terms, not Rust*, and where debugging artifacts are themselves small proofs. Extends `fh-codegen.md` (the mapping), `fh-diagnostics.md` (the payload), and quietly instantiates `fh-meta-effective.md` §2.1 one more time.

## 0. Why term-level stepping is even possible

The extraction architecture already maintains the correspondence a debugger needs: R1's projection is per-definition structure-preserving, spans survive (the diagnostics sourcemap contract), and R3's Aeneas round-trip *certifies* that the emitted Rust computes the Lean function — so a Rust call tree lifts to a term tree soundly, frame for frame, name for name. The FH `fn` / Lean `def` / Rust `fn` triple is one object in three costumes; a trace recorded in one costume is legible in all three. Purity completes the gift: extracted checker-fragment code is deterministic, so any failure replays exactly, and replay is the whole game.

## 1. Where a "huge error" can even come from — the triage ladder

Proven code that produces a wildly wrong number failed *outside* what the proof covers, and the debugger's step zero is locating which envelope broke, cheapest first: **(0) Regime check** — evaluate the artifact's regime predicate (its where-clause, its error field's domain) on the failing input; if false, this is not a bug but an out-of-envelope use, and the error field already predicted unreliability here. **(1) Unverified glue** — I/O, parsing, the oracle-comparison harness itself: the code around the certified core. **(2) Refinement violations** — an input outside a bounds-proof's hypotheses (the proof-carrying `Fin→u64` layer says exactly which hypothesis to re-check). **(3) Spec adequacy** — the deep case: the code *correctly computes the wrong thing*, i.e., a definition diverges from intent (a V12/statement-validity finding wearing a numeric costume). The debugger below is built to distinguish (3) from (1)–(2) mechanically.

## 2. The debug-proof vocabulary

Four attributes, each dual-compiled — one predicate, two enforcement modes:

```rust
#[watch(0 <= disc && disc <= dBound(t))]   // assertion at a binding
#[bound(lo, hi)]                            // sugar for the interval watch
#[break]                                    // promote this subterm to a named def
#[trace]                                    // record this fn's frames
let disc = dissipation(t, u);
```

A `#[watch]` compiles **down** to a `debug_assert!` in the extracted Rust (checked dynamically on the failing input) and **up** to a Lean lemma obligation (the same predicate as a theorem about the definition). The workflow this enables is the whole point: *assert dynamically until you find the invariant that breaks, then prove the fixed version* — the failing watch names the culprit frame; the repaired watch, once proven, is promoted from debug scaffolding to a permanent regression theorem. Debug-proofs live in a `debug/` namespace with their own sorry budget (they are not in the targets' closure, so H4 is untouched); promotion moves them into the artifact properly. `#[break]` is refactoring-for-observability: naming a subterm makes it addressable in traces *and* in proofs — and breakpoints that earn their keep become lemma boundaries, so debugging permanently improves the proof's factoring. Watches that recur across campaigns are, per §8 of the meta doc, promotion candidates like any recurring residual.

## 3. The REPL is the debugger

No interactive stepper is built, because a better one exists: extracted code under `#[trace]` emits a structured trace — frames keyed by FH span, with argument and intermediate values as exact rationals — and **each frame loads into the Lean REPL as a context**: values become hypotheses, and the agent "steps" by moving between frames, evaluating watch predicates with `decide`/`norm_num`, and attempting concrete-instance lemmas (`example : P (37/12) := by norm_num`) right there in the frame. Time-travel debugging where every snapshot is a proof state. Bisection rides the existing machinery: the PBT shrinker (`fh-statement-validity.md` Part III) first minimizes the failing input, so the trace being stepped is the *smallest* failing trace; ddmin over the call tree then localizes the first bad frame; the diagnostics falsification-triage machinery runs on any watch that fails, stamping it hard-vs-wrong.

## 4. Certified blame: the interval trace

The feature that turns debugging into forensics. Alongside the concrete trace, replay the computation through the certified **interval evaluator** (the same extracted kernel, interval-typed), producing per-frame certified enclosures. A "huge error" then has a visible birthplace: the frame where the enclosure blows up — and unlike a hunch, the blow-up frame comes with a certificate ("through frame k, the result was provably within ε; at k+1 the enclosure exploded"). Enclosure-explosion archaeology assigns numerical blame with proofs, and the whole certified trace is — pleasingly — an **error field over the call tree** (site = the tree; sections = per-frame enclosure theorems; §2.1 of the meta doc collecting yet another instance it retroactively unifies). For spec-adequacy hunting (triage case 3), the same trace mechanism runs *differentially*: our trace against an independent implementation (CAS, reference code) frame-aligned by span — the first diverging frame names the definition whose *meaning*, not code, is under suspicion, and that finding routes to the vet battery, not to a code fix.

## 5. Integration and milestones

The trace format extends the diagnostics agent-payload schema (frames are goal-states with values); watches feed the oracle harness (a table disagreement auto-triggers a traced replay with the triage ladder); `#[break]`-induced definitions are hash-tracked like everything else so debugging never silently changes frozen meaning (H2 applies — watches on frozen statements' definitions are additive only). Milestones: **DB1** — `#[watch]`/`#[bound]` dual compilation + `debug_assert` emission, with the couette LDLᵀ checker as first patient; **DB2** — trace emission + REPL frame-loading; **DB3** — the interval trace and blame certificates. Acceptance test, one line: given an artificially corrupted certificate producing a wrong bracket, the agent must localize the corrupt entry *by frame*, with a certificate for the blame, and exit with one new promoted regression theorem — the debugging session itself leaving the library stronger, which is the standard this project holds even its bugs to.