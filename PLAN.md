# Ferris–Howard Implementation Plan

**Status:** Draft 0.3 · 2026-08-01 · Derived from `design.md`, `corpus-review.md`, `agent-interface.md`, `atlas.md`, `atlas-validation.md`. Revised after two adversarial-review rounds: round 1 (completeness audit, execution premortem, Lean-feasibility experiments on the pinned toolchain, prior-art research) and round 2 (50-point fix verification + cold re-read of the revision).
**Decisions in force:** FH-in-`.lean` per-declaration commands through M2 (standalone `.fh` at M3); monorepo `lean/` + `crates/`; Lean `leanprover/lean4:v4.32.2` + Mathlib `v4.32.2`, bumps only at milestone boundaries; Apache-2.0; corpus Rulings A–E and F1–F18 binding; authority order per `design.md` §8. Where this plan deviates from binding doc text, the deviation is queued in §9 and lands as a doc PR **before** its dependent code.

## 0. Ground rules (non-negotiable, from the docs)

1. **Corpus as spec (Ruling E).** Every feature lands with all **four** test tiers: golden expansion, elaboration, negative, **span** (the fourth tier is plan-introduced; doc PR §9.3). The golden tier is the living syntax specification.
2. **Stage one relentlessly (design §2).** Every feature PR states macro-expansion vs `elab_rules` and justifies stage two. Known stage-two items, flagged in advance: F9 coercion control (mechanism one-pager I6 — its blast radius vs this very rule is the open question), F10 ascription, F1 expected-type inference, `where P: Prime`→`Fact` bridge resolution, F13 (pending §9.2).
3. **Span preservation.** Discipline (verified experimentally): user syntax passes through antiquotes untouched; every synthesized node is wrapped in `withRef` of its FH source node; never re-parse strings. Mechanized from M0 via the span tier.
4. **Ruling D governance.** Every grammar change classified extension/confined/violation; violations amend `corpus-review.md` first. The classification label is **human-applied**; automation is advisory.
5. **Doc-first.** Ambiguities become PRs against the design docs before dependent code. The standing amendment queue is §9.
6. **Golden re-baselines are dedicated PRs**, separate from logic changes, human-reviewed — bulk-accepted golden churn silently rewrites the spec.

## 1. Done (as of 2026-08-01)

Doc reconciliation (`bf857ba`); Apache-2.0; scaffold (`5775190`): Lake package pinned to Mathlib v4.32.2, olean cache pulled, build green — smoke test verifies `Nat.Prime.dvd_mul`, `ZMod.pow_card` (with its `[Fact (Nat.Prime p)]` binder), `EuclideanDomain`, `RiemannHypothesis`; warm check ≈ 10 s; `crates/fh-atlas` stub compiles. Feasibility experiments archived at `lean/Tests/feasibility/e*.lean` (run via `lake env lean <file>`); I2 promotes them to proper fixtures.

## 2. Verified platform facts this plan relies on (feasibility round, pinned toolchain)

- FH `theorem` **coexists with core `theorem` out of the box** — longest-match dispatch across command parsers sharing a leading token; no priority/lookahead machinery. Cost: malformed input may get the wrong grammar's error (R3); FH slots must use FH categories, never Lean's `term`.
- **Nested generics cannot lex naively**: `>>` is a maximal-munch core token (`Poly<Fp<P>>` fails), and generic arguments must parse above comparison precedence or `>` steals the closing bracket. I5 spike; stopgap `Poly<Fp<P> >`.
- **FH keywords globally reserve tokens** in importing files; non-reserved leading keywords don't work off-the-shelf. Accepted, documented cost (differences page, from M0); R3 battery.
- `?`/`!` are identifier-rest characters (`maybe_val?` is one identifier): FH identifier lexing must split/reject trailing `?`/`!` (A0.6).
- Rust `//` comments can't lex in `.lean`; fixtures use `--`/`/- -/` until M3 (doc PR §9.4).
- Pretty-printed expansions carry hygiene daggers; the golden printer sanitizes via `Name.eraseMacroScopes` (verified deterministic).
- `#guard_msgs` is exact-match with lax-whitespace mode and a re-baseline code action; it strips positions — the span tier is a small position-checking variant.
- Laws-as-fields, `outParam`, `Monad PMF`, `?`-as-do (bodies have declared return types, so the monad is inferable; `?` inside *unascribed closures* fails — documented at A2.3, matches Rust's closure-boundary rule), `in` as an FH binary operator, and the `fh check` Frontend-driver architecture all verified workable. `leanchecker` ships in the toolchain.

## 3. Phase I — Infrastructure

- **I1. CI.** Pinned `leanprover/lean-action` + `use-mathlib-cache: true` + `actions/cache` on `.lake/build` (LeanProject template); `lake exe mk_all --check`; toolchain-match assertion; rust job; governance job = PR-template Ruling-D field + human-applied label (automation advisory).
- **I2. Test harness on `#guard_msgs`.** Golden tier: `#fh_expand` logs hygiene-sanitized expansion under `#guard_msgs (whitespace := lax)`. Elaboration tier: zero errors + asserted `sorry` count. Negative tier: **exact pinned messages** (deviation from design §8's "substrings" — doc PR §9.3; exact-match is what the mechanism supports and re-baselining is cheap under rule 6). Span tier: position-asserting `#guard_msgs` variant; one span assertion per feature from M0. First negative test is M0-native (unresolved identifier under A0.1's no-auto-bind rule).
- **I3. Statement-hash mini-design → implement.** Explicit normalization decisions (alpha, universes, `mdata`, literals, binder-info, reducibility); **algorithm-version tag in every hash**. Consumers: C5 freeze, B1/B8 keying. Hash equality substitutes for anti-cheat's "definitionally identical" — stricter, decidable; recorded (doc PR §9.6).
- **I4. Numeric-literals mini-design (gates M1).** Inherit `OfNat`/`OfScientific`; Ruling C item five; settle `half` (doc PR §9.5).
- **I5. Angle-bracket lexing spike (timeboxed, week 1).** `ParserFn` splitting `>>`/`>=`/`>>=` at generic-close + precedence floor above comparisons, fuzzed against a **standalone prototype grammar** (the F6 rule doesn't exist until A1.5). If the timebox expires, **the spacing stopgap is the plan of record** through M1 and the spike resumes before A2.5 (its hard consumer).
- **I6. F9-mechanism one-pager (new).** How to disable silent unification-driven coercion in FH-elaborated code *without* wrapping every FH term in a stage-two elaborator — the tension with ground rule 2 is real and must be resolved on paper before A2.0 is scheduled work. Options to evaluate: elaborator option/attribute scoping, post-elaboration coercion audit, targeted `elab_rules` at coercion-prone positions only.

## 4. Track A — the language (M0 → M3)

### M0 — Skeleton (corpus Group 1 minus theorems)
- A0.1 Syntax categories: rust-items, rust-patterns, single rust-expression category. FH slots always use FH categories. **No-auto-bind from day one**: unresolved identifiers are errors (F17's hard rule; `autoImplicit` semantics never enter FH expansion).
- A0.2 `fn` → `def`; expression bodies, `match`, `let`, closures, `::` paths, **method-call and field-access dot syntax** (the generalized-dot *mechanism* lives here; F16's canonical-ASCII-spelling *policy* is recorded at A2.1 but every milestone uses the mechanism); bodyless `fn ...;` → `sorry`-backed `def`.
- A0.3 `struct` (incl. `extends`) / plain `enum` / `mod` / `use` / `type` (`#[def]` opt-out).
- A0.4 `todo!()` → tracked `sorry` + report; attribute pass-through; `#[name(...)]`.
- A0.5 Command coexistence (longest-match, verified): reserved-keyword battery negative test (each FH keyword as ambient-Lean identifier; plain Lean `theorem` still parses).
- A0.6 Identifier lexing: split/reject trailing `?`/`!`; negative test for bare `x?`.
- The **differences page starts here** (keyword reservation, `?`/`!` policy are M0 divergences) and grows per feature.
- **Exit gate:** vertical slice green in CI — FH definitions elaborate, `#print` clean, all four tiers exercised (incl. one span assertion, one M0-native negative).

### M1 — Statements (Groups 1, 3, 4 complete + Group 2 pulled into the gate)
- A1.1 `theorem` keyword form.
- A1.2 Dependent signatures; `{n*2}` brace escape (verified: longest-match suffices).
- A1.3 Binder classes; turbofish; F1 expected-type nullary inference (stage two, flagged) — Ruling C item one.
- A1.4 Quantifiers `for<>`/`exists<>` (F2 ascription + F2 negative test); anonymous constructors (Ruling C item two); `exists`-body `Sigma`/`Subtype` election (Ruling C item four).
- A1.5 Ruling A operator set incl. `in`; `decide()`; Bool methods; F6 error **at expansion time** with exact span (parser can't produce fixed wording — verified; corpus deviation, doc PR §9.3); frozen F7 matrix as exhaustive goldens — **blocked on §9.1**; F12 negative test (`for<>` headers never capture `in`) lives here with the operator.
- A1.6 Traits-with-laws; multi-parameter classes; instance-shadowing lint.
- A1.7 `lean! { }` with InfoView.
- A1.8 **F10 ascription only**: `(e: T)` elaboration-hint-without-coercion. (The rest of the F9/F10 cluster — `as` coercion + disabling silent coercion — moves to A2.0: its consumers are all M2, and it needs I6 first.)
- A1.9 `fh check` v0 (=C1): Frontend driver, JSON status/errors+FH spans/sorry goals/axioms.
- Pre-M1 gates: I4; §9.1 doc PR; `!`-on-Bool decision (default: hard-error).
- **Exit gate:** `euclids_lemma` (design §3) **and** corpus Group 2 (`id_unique`, quantified hypothesis) elaborate and check; full F7 matrix green; **one F10 ascription golden**.

### M2 — The conversation file (Ruling E order: Groups 8, 11, 12 → 9 → 5, 6, 7, 10; Group 2 was pulled into M1)
- A2.0 **F9 coercion control** (per I6's mechanism): `as` coercion, `as!`, silent-coercion disable. Lands before A2.1/A2.5 (Group 6's `choose(n,k) as R` and Group 12's subtype introduction consume it). Gate: F9 negative golden — a silently-coercing expression must error.
- A2.1 Prop-first consequences: set-builder/subtype (**F13 per §9.2** — position-dispatch is impossible under the unified grammar; the doc PR picks the mechanism); decidable-`if` (negative tests pin Lean's real wording; friendly F14 wording in `fh check` — corpus deviation, doc PR §9.3); `if h @ (cond)` (F15); F16 canonical-spelling policy recorded (mechanism since A0.2).
- A2.2 Indexed enums; nested + `mutual` inductives; termination attributes; `#[partial]`, `#[noncomputable]`, `#[opaque]`, `extern "axiom"`.
- A2.3 `?`-do (four-monad golden set; the unascribed-closure boundary documented on the differences page), explicit `pure`, structure literals, do-block `for`/`while`/`if`/`let mut` — **loop-header `in` needs a token-position decision** (`for pat in e` vs `in` the Prop operator; folded into §9.1) before this lands.
- A2.4 Ambient `var` + `include` (F17) with the F17 corpus obligations (Groups 3/8/9 `var` rewrites + identical-elaboration goldens + ambient-hypothesis pair); `var`-shadowing lint; `Space` + trait-in-annotation + explicit universes (`Space<u>`, `#[universes(u,v)]`); role metadata.
- A2.5 Mathlib bridge: `Fp<P>` (stage-two/bridge special-case — resolution must know `Prime` is a predicate), `Poly<R>` (**consumes I5's real fix**), `Fractions<R>`, `Quotient<R, I>`, morphism aliases, operator classes, `use lean::…`; F11 named arguments; F8 term-position-types tests.
- A2.6 Groups 5/6/7/10 fixtures, completing Ruling E's twelve.
- A2.7 `fh repl` + `fh mcp` v0 (C2/C3).
- **Intra-M2 checkpoint:** Group 9 elaborates (the stage-one acid test; needs A2.4 + F1). **M2 exit gate:** all twelve corpus groups green (incl. A2.6); `riemann_as_traits.rs` port end-to-end with exactly one `sorry`; MCP round-trip smoke (elaborate → goals → try).

### M3 — Ergonomics
`notation!` (above the floor); sorry-report tooling; full span audit; error-taxonomy polish; standalone `.fh` (Lake facet + preprocessor + LSP forwarding — Alloy's history says this is the hard part); the tutorial; differences page completeness review (it has been growing since M0).

## 5. Track B — the Atlas (parallel; needs only I3 + pinned Mathlib)

- B1. Extractor v0 (Lean metaprogram): JSONL (name, kind, versioned statement-hash, used-constants, module). Blocked only on I3.
- B2. Dependency graph (petgraph) + `atlas why` + foundations/impact + bridge centrality; Mathlib slice, then full.
- B3. **`atlas home`**: carrier abstraction + lattice walk. Gate: seeded over-hypothesized suite incl. ≥ 2 carrier-abstraction cases **plus ≥ 5 historical linter hits mined from Mathlib git history** (scheduled work — the pinned snapshot has fixed them).
- B4. Skeleton index + `atlas similar`: evaluate babble/Stitch before bespoke AU; higher-order-pattern LGG is linear-time; Gauthier–Kaliszyk normalization-level knob as the precision/recall parameter; property tests (subsumption, idempotence, commutativity) + differential vs a naive reference — correctness oracle independent of the V-suite.
- B5. Equivalence graph + proof shapes (same extraction pass).
- B6. `dictionary`/`transport`/`frontier`; `transport`'s three-check dispatch is a Track C integration.
- B7. **Validation benchmark, blinding repaired:** §9.7's protocol amendment lands **first** (it defines what the key must contain), then the answer key is written and hash-frozen by the human owner before any cluster file exists (in-repo: hash only). V1–V9 are **development targets** (atlas-validation §3 already publishes their substance); the private key holds **held-out targets — the actual validation set — with their own T1/T2 tiering, pass bar, and negative controls defined in §9.7**. Sanitized cluster briefs; neutral naming scrub; corpus hash-frozen before any index runs against it; corpus-group negative controls as plain-Lean ports until M2; frontier-baseline computation is a deliverable; per-target results incl. failures published in-repo.
- B8. Overlay channels 1 & 3 (atlas §6): retroactive `fh_role` attributes + persistent env extension (builtin-attribute and module-system caveats as compat tests); `annotate` form; keying semantics (rebind-by-hash, `@[deprecated]` chains, Ch3 hard-fail / Ch2 recompute).

Order: B1→B2 after I3; B3 gate before B4; B8 after B1.

## 6. Track C — the agent layer

- C1. `fh check` v0 with M1 → v1 at M2: role metadata, error taxonomy with branch hints, friendly-wording layer over Lean's raw messages, `simp?` feedback on simp success.
- C2. REPL wrapper (fork/try/keep; proof-state snapshotting literature); Pantograph fallback; Kimina-style pooling for scale-out. Nothing counts until re-elaboration from source.
- C3. `fh mcp` **composes with `lean-lsp-mcp`** for generic tooling (goals/diagnostics/search); FH-specific tools only: `fh check` JSON, span mapping, statement-hash/anti-cheat, `minimize`, Atlas queries. (Deviation from agent-interface §1's tool list — doc PR §9.6.)
- C4. Falsification battery: `plausible`, `decide`/`native_decide`, Rust-side enumeration/SAT with in-Lean verification; auto-run on whole-proof failure; role-metadata steering arrives at M2 — unsteered before that, accepted. No B-track dependency.
- C5. Anti-cheat pipeline: fresh-env check, transitive-sorry scan, axiom whitelist, versioned hash freeze/verify, `leanchecker`; honesty-clause reports; rehearsal fixture (weakened statement must fail the hash check) before first real use; `lean4export` + external checker as the kernel-independence escalation.
- C6. Open-problem runbook (agent-interface §5): openness re-verification, statement import (Formal Conjectures) + human review before freeze, falsification first, lemma-DAG farming via C3, writeup + wiki etiquette.
- C7. Environment engineering: warm daemon per worker, per-tactic (20 s) / per-file timeouts, isolated worktrees + shared read-only cache. Rides C2/C3.

## 7. Sequencing — first three weeks (single implementer assumed; contention is real)

**Week 1 — the vertical slice, serialized:** A0.1 → minimal `fn`→`def` → `#fh_expand` + sanitizer → four tiers on that feature → CI green (I1). Docs in parallel (human-review-sized, not implementation): §9.1/§9.4/§9.7 PRs, I3 + I6 one-pagers, B7 answer key (human, after §9.7). I5 runs as a strictly timeboxed spike only if slack exists — the stopgap is already the plan of record through M1.
**Week 2:** A0.2–A0.6; I3 implementation.
**Week 3:** M0 exit gate; B1 extractor; A1.5 matrix begins (§9.1 landed).
Contention honestly stated: A-items serialize on one grammar and one implementer; B1 contends on the same person (it is Lean-side), hence week 3; C1 is embedded in M1 by design.

## 8. Risks

- R1 Spans: span tier from M0; discipline in §0.3.
- R2 Precedence freeze: §9.1 completes the table *before* the matrix; exhaustive goldens; rustc differential spot-check. (Ruling B scope note: longest-match token dispatch at the command boundary is platform behavior, accepted; FH's own grammar stays backtrack-free.)
- R3 Keyword UX: reservation battery; cross-grammar error confusion revisited at M3.
- R4 AU scale: bucket-first validated by prior art; B4 behind B3; prefilter budgeted on the validation corpus first.
- R5 REPL fragility: re-elaborate rule; Pantograph/Kimina pre-scoped.
- R6 Toolchain bumps: milestone-boundary policy; exact-message negatives make bumps costlier — accepted, re-baselining is one PR with the code action.
- R7 Doc drift: governance job; §9 queue is standing.
- R8 Cross-track coupling: I3 and C1-in-M1 are the hard edges; B-track is independently publishable.
- R9 Golden churn (agent-specific): rule 6; batched expansion changes.
- R10 B4 oracle sculpting/bus factor: property + differential tests; babble/Stitch first.
- R11 Benchmark credibility: B7 repairs; without held-out targets the "cold" claim is unfalsifiable.
- R12 `>>` lexing: I5 spike + stopgap-as-plan-of-record; hard consumer is A2.5, not M0/M1.
- R13 **F9 blast radius** (new): if I6 finds no scoped mechanism, coercion control could force stage-two wrapping of all FH terms, colliding with ground rule 2 — surfacing this is exactly why I6 exists and why A2.0 doesn't start until it lands.

## 9. Doc-amendment queue (each lands before its dependent code)

1. **corpus-review F7 completion:** `in` precedence slot (binary operator *and* the do-`for` loop-header token-position rule), `<->` associativity, quantifier-scope × operator interactions. Before A1.5 (loop-header clause before A2.3).
2. **corpus-review F13 re-spec:** position-dispatch impossible under unified grammar; choose stage-two expected-type elaboration (sixth Ruling C item) vs always-`setOf`+`CoeSort` (F9 tension). Before A2.1.
3. **corpus-review Ruling E + F6 + F14 + design §8 (one mechanics PR):** fourth (span) test tier; F6 enforcement at expansion time rather than "by the parser"; F14 friendly wording delivered via `fh check` while negative tests pin Lean's real message; negative tier = exact messages, not substrings. Before I2 fixture import.
4. **corpus fixtures:** `//` → `--` until M3. Before I2 fixture import.
5. **corpus-review Ruling C item five:** numeric literals (I4). Before M1.
6. **agent-interface:** C3's lean-lsp-mcp composition (tool-list change); hash-equality as the §4(d) "definitionally identical" check. Before C3/C5.
7. **atlas-validation §1/§3/§5:** dev-targets vs held-out validation set (incl. held-out tiering, pass bar, negative controls, publication rule), sanitized briefs, key custody, coverage-without-leakage mechanism for cluster briefs. Before the answer key is written (week 1).
8. **design.md:** related-work paragraph (hax/Aeneas/Alloy/Verso); reserved-keyword + `?`/`!` costs on the differences page. Anytime; cheap.

## 10. New decisions this plan introduces (surfaced deliberately)

Harness on `#guard_msgs` with **exact-message** negatives (§9.3); **span tier as a mandatory fourth tier** (§9.3); F6 moved to expansion time (§9.3); F14 wording split between pinned-Lean-message tests and `fh check` (§9.3); Group 2 pulled into the M1 exit gate (order deviation from Ruling E, justified by design §4.4's "payoff feature… milestone 1"); A1.8/A2.0 split of the F9/F10 cluster (F10 at M1, F9 at M2 behind I6); hash algorithm-version tag and hash-for-defeq substitution (I3, §9.6); human-applied governance label (I1); B3 gate redefinition (seeded + ≥5 mined historical hits); B7: held-out validation targets, sanitized briefs, plain-Lean control ports (genuinely new; key-first ordering, out-of-repo custody, and freeze-before-any-run were already decided in the docs — this plan operationalizes them); C4 runs unsteered pre-M2; `fh mcp` composes with `lean-lsp-mcp` (§9.6); I5 `>`-splitting spike with stopgap-as-plan-of-record; identifier `?`/`!` splitting (A0.6); no-auto-bind wired into A0.1; method-call mechanism at A0.2 with F16 policy at A2.1; loop-header `in` token-position decision delegated to §9.1.

## 11. Deferred-decisions ledger

| Decision | Default | Due |
|---|---|---|
| `!` on Bool | hard-error, fixed wording | pre-M1 |
| F13 mechanism | §9.2 decides | pre-A2.1 |
| F9 mechanism | §I6 one-pager decides | pre-A2.0 |
| `<explicit T>` override | not needed | M2, if friction |
| `notation!` floor | adopted | M3 |
| Unicode input | v2 opt-in | post-M3 |
| Tactic sugar | v2, after usage data | post-M3 |
| `native_decide` | per-result opt-in | per use (C5) |
| Crate naming | repo `ferris-howard`; rest deferred | first public release |
