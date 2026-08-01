# Ferris–Howard Implementation Plan

**Status:** Draft 0.4 · 2026-08-01 · Derived from `design.md`, `corpus-review.md`, `agent-interface.md`, `atlas.md`, `atlas-validation.md`; mini-designs at `statement-hash.md` (I3) and `coercion-control.md` (I6). Revised after two adversarial-review rounds: round 1 (completeness audit, execution premortem, Lean-feasibility experiments on the pinned toolchain, prior-art research) and round 2 (50-point fix verification + cold re-read of the revision). **§9 amendment queue fully landed and answer key v1 frozen 2026-08-01 — the next session starts at §7 week 1 (the vertical slice).** **Week 1 landed 2026-08-01 — §7 week 2 (A0.2–A0.6, I3 implementation) is next.**
**Decisions in force:** FH-in-`.lean` per-declaration commands through M2 (standalone `.fh` at M3); monorepo `lean/` + `crates/`; Lean `leanprover/lean4:v4.32.2` + Mathlib `v4.32.2`, bumps only at milestone boundaries; Apache-2.0; corpus Rulings A–E and F1–F18 binding; authority order per `design.md` §8. Where this plan deviates from binding doc text, the deviation is queued in §9 and lands as a doc PR **before** its dependent code.

## 0. Ground rules (non-negotiable, from the docs)

1. **Corpus as spec (Ruling E).** Every feature lands with all **four** test tiers: golden expansion, elaboration, negative, **span** (the fourth tier is plan-introduced; doc PR §9.3). The golden tier is the living syntax specification.
2. **Syntax → syntax, and it is load-bearing (design §2; ADR-006, `research/codegen.md` §2).** Every FH construct expands to Lean *surface* syntax via `macro_rules`; `elab_rules` is reserved for constructs that genuinely need elaborator access, and each one is a decision to defend. ADR-006 turns this from a preference into a requirement: `emit-lean` is then one macro-expansion step plus a formatter, and faithfulness is by construction rather than by delaboration heroics. **The printable middle stage is the publication artifact**, which is also why the golden tier doubles as a preview of it. The **emittable lint** enforces the invariant mechanically: no FH node kind may survive expansion. Every feature PR states its stage. Known pressure points, flagged in advance: F9 coercion control (I6 — resolved as a *post-elaboration diagnostic*, so stage one survives), F10 ascription, F1 expected-type inference, `where P: Prime`→`Fact` bridge resolution, F13 expected-type election (landed §9.2). **As of 2026-08-01 the language contains no `elab_rules` at all**: `todo!`'s message moved to a linter for exactly this reason.
3. **Span preservation.** Discipline (verified experimentally): user syntax passes through antiquotes untouched; every synthesized node is wrapped in `withRef` of its FH source node; never re-parse strings. Mechanized from M0 via the span tier.
4. **Ruling D governance.** Every grammar change classified extension/confined/violation; violations amend `corpus-review.md` first. The classification label is **human-applied**; automation is advisory.
5. **Doc-first.** Ambiguities become PRs against the design docs before dependent code. The standing amendment queue is §9.
6. **Golden re-baselines are dedicated PRs**, separate from logic changes, human-reviewed — bulk-accepted golden churn silently rewrites the spec.

## 1. Done (as of 2026-08-01)

Doc reconciliation (`bf857ba`); Apache-2.0; scaffold (`5775190`): Lake package pinned to Mathlib v4.32.2, olean cache pulled, build green — smoke test verifies `Nat.Prime.dvd_mul`, `ZMod.pow_card` (with its `[Fact (Nat.Prime p)]` binder), `EuclideanDomain`, `RiemannHypothesis`; warm check ≈ 10 s; `crates/fh-atlas` stub compiles. Feasibility experiments archived at `lean/spikes/e*.lean` (run via `lake env lean spikes/<file>.lean`); I2 promotes them to proper fixtures.

**Week 1 (2026-08-01).** A0.1 categories + the `fn`→`def` slice + the four-tier harness (`882bd84`); CI (`4fc8c38`); the I3 and I6 one-pagers (`statement-hash.md`, `coercion-control.md`). I5 was not started — the spacing stopgap is the plan of record through M1.

**Week 2 (2026-08-01).** A0.2 expressions (`ec970c8`), A0.3 items (`97fb285`), A0.4 `todo!` + derived sorry report (`b7d97e9`), A0.5/A0.6 lexing (`9537453`), I3 implementation. Corpus Group 1's `add` elaborates with structural recursion inferred. Every M0 feature carries all four tiers; full `lake build` green.

## 2. Verified platform facts this plan relies on (feasibility round, pinned toolchain)

- FH `theorem` **coexists with core `theorem` out of the box** — longest-match dispatch across command parsers sharing a leading token; no priority/lookahead machinery. Cost: malformed input may get the wrong grammar's error (R3); FH slots must use FH categories, never Lean's `term`.
- **Nested generics cannot lex naively**: `>>` is a maximal-munch core token (`Poly<Fp<P>>` fails), and generic arguments must parse above comparison precedence or `>` steals the closing bracket. I5 spike; stopgap `Poly<Fp<P> >`.
- **FH keywords globally reserve tokens** in importing files; non-reserved leading keywords don't work off-the-shelf. Accepted, documented cost (differences page, from M0); R3 battery.
- `?`/`!` are identifier-rest characters (`maybe_val?` is one identifier): FH identifier lexing must split/reject trailing `?`/`!` (A0.6).
- Rust `//` comments can't lex in `.lean`; fixtures use `--`/`/- -/` until M3 (doc PR §9.4).
- Pretty-printed expansions carry hygiene daggers; the golden printer sanitizes via `Name.eraseMacroScopes` (verified deterministic).
- `#guard_msgs` is exact-match with lax-whitespace mode and a re-baseline code action. **Corrected 2026-08-01:** it does *not* strip positions — v4.32.2 has a `positions := true` spec option that reports each message's position relative to the `#guard_msgs` token. It reports them *with* the message text, so FH's span tier (`#fh_spans`) is a variant that reports position and underlined source text *without* the message, keeping span assertions decoupled from message wording (R6). Stock `positions := true` is the fallback if `#fh_spans` ever becomes a liability.
- `mkCoe` pushes a `CoeExpansionTrace` InfoTree leaf at every coercion insertion, carrying the syntax ref — the mechanism I6 is built on (`coercion-control.md`; fixture `e11`).
- No cryptographic hash exists in the toolchain (no SHA-256 in core or Lake), which is why I3 splits encoding (Lean) from digest (Rust).
- Laws-as-fields, `outParam`, `Monad PMF`, `?`-as-do (bodies have declared return types, so the monad is inferable; `?` inside *unascribed closures* fails — documented at A2.3, matches Rust's closure-boundary rule), `in` as an FH binary operator, and the `fh check` Frontend-driver architecture all verified workable. `leanchecker` ships in the toolchain.

## 3. Phase I — Infrastructure

- ✅ **I1. CI** (`4fc8c38`). Pinned `leanprover/lean-action` + `use-mathlib-cache: true` + `actions/cache` on `.lake/build`; toolchain-match assertion (`scripts/check-toolchain.sh`, plus a manifest-unchanged check); rust job; governance job = PR-template Ruling-D + Stage fields, warnings only (human-applied label). **Deviation:** no `lake exe mk_all --check` — both libs are globbed, so compilation coverage is structural, and `lake exe mk_all` would build Mathlib's executables from source (the olean cache does not cover them). `--wfail` is on, so an uncaptured warning fails the build. Not yet exercised on GitHub.
- ✅ **I2. Test harness on `#guard_msgs`** (`882bd84`) — `#fh_expand` (golden, hygiene-sanitized, stops at the first non-FH node kind) and `#fh_spans` (span, position + underlined source, no message text). Elaboration tier asserts sorry-freeness via `#print axioms`. First fixture: `lean/Tests/M0/Fn.lean`, all four tiers.
  Original scope, all met: golden tier: `#fh_expand` logs hygiene-sanitized expansion under `#guard_msgs (whitespace := lax)`. Elaboration tier: zero errors + asserted `sorry` count. Negative tier: **exact pinned messages** (design §8 as amended via §9.3; exact-match is what the mechanism supports and re-baselining is cheap under rule 6). Span tier: position-asserting `#guard_msgs` variant; one span assertion per feature from M0. First negative test is M0-native (unresolved identifier under A0.1's no-auto-bind rule).
- ✅ **I3. Statement-hash mini-design → implemented.** Mini-design and implementation both landed 2026-08-01: `statement-hash.md`, `FerrisHoward/Atlas/Statement.lean` (canonical encoding + `#fh_statement`/`#fh_statement_eq`), `crates/fh-atlas/src/statement.rs` (SHA-256 digest, freeze verification, version-skew as a distinct verdict). Fixtures: `Tests/Atlas/Statement.lean` (invariance and sensitivity as properties, one pinned differential anchor) and six Rust tests. Normalization decided (alpha erased, binder info kept, universes normalized then renamed by first occurrence, `mdata` stripped, literals uncanonicalized, no unfolding); version tag lives *inside* the encoding; **Lean emits a canonical encoding, Rust digests it** (no cryptographic hash exists in the toolchain), so B8 keys on the encoding and never needs SHA-256 in Lean. Hash equality substitutes for anti-cheat's "definitionally identical" — stricter, decidable; recorded (doc PR §9.6). 
- **I4. Numeric-literals mini-design (gates M1).** Inherit `OfNat`/`OfScientific`; Ruling C item five; settle `half` (doc PR §9.5).
- **I5. Angle-bracket lexing spike (timeboxed, week 1).** `ParserFn` splitting `>>`/`>=`/`>>=` at generic-close + precedence floor above comparisons, fuzzed against a **standalone prototype grammar** (the F6 rule doesn't exist until A1.5). If the timebox expires, **the spacing stopgap is the plan of record** through M1 and the spike resumes before A2.5 (its hard consumer).
- ✅ **I6. F9-mechanism one-pager** — `coercion-control.md`. **No FH term needs a stage-two wrapper.** Two mechanisms: FH's operator expansion does not use `binop%` (stage one, free), and a declaration-scoped post-elaboration audit reads the `CoeExpansionTrace` InfoTree leaves `mkCoe` already pushes, licensing exactly the insertions whose syntax ref lies inside an FH `as` node. Verified on-toolchain (`e11`): clean code yields no hits, `binop%` insertions *are* visible, and an explicit `↑` is distinguishable by ref. The option-scoping route was checked and does not exist in v4.32.2. R13 resolved; A2.0 is schedulable.

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
- ✅ **A1.1 `theorem` keyword form** (`636d51d`).
- ✅ **A1.2 Dependent signatures; `{n*2}` brace escape** (2026-08-01). Dependency costs nothing once generics bind values: `Vector<T, n>`, `Fin<n + 1>`, `Vector<T, {n * 2} >` all elaborate. Generic *arguments* parse above the comparison band, which is what keeps `>` from being stolen; anything at or below a comparison uses the braces.
- ◐ **A1.3**: binder classes landed (2026-08-01) — angle-bracket generics → implicit binders, `where` bounds → instance binders, in Mathlib's order; F6 enforced at expansion time with fixed wording and an exact span. **Remaining:** turbofish and F1 expected-type nullary inference (stage two, flagged) — Ruling C item one. Turbofish is deliberately deferred to the feature that forces its shape (`@f T x` vs Lean's named-argument form): F1's escape in Group 2.
- ◐ **A1.4** (2026-08-01): quantifiers `for<>`/`exists<>` with F2's distributed ascription and its negative test, F7 (iv) scope, F12's non-capture. **Remaining:** anonymous constructors (Ruling C item two) and the `exists`-body `Sigma`/`Subtype` election (Ruling C item four, stage two).
- ◐ **A1.5** (`65f7509`): Ruling A operator set incl. `in` landed with the F7 matrix as exhaustive goldens; `decide()` needs no syntax (it is a call); Bool methods come with the M2 bridge. Operators expand to constants (`Eq a b`), never to Lean's `binrel%`/`binop%` notations — that is I6's coercion control at its point of use. Remaining here: F6 error **at expansion time** with exact span (parser can't produce fixed wording — verified; corpus F6 amended accordingly, §9.3); F7 matrix as exhaustive goldens (§9.1 landed 2026-08-01 — the table is complete); F12 negative test (`for<>` headers never capture `in`) lives here with the operator.
- ◐ **A1.6 Traits-with-laws** (2026-08-01) — design §4.4's payoff feature, working: `trait C<Self> { … }` → `class C (Self : Type _) where …` with methods as function-typed fields and laws as fields like any other, so an `impl` that omits one gets Lean's own missing-field error. Bodies in a trait are default values; `impl C for T { … }` → `instance : C T := { … }`, named by `#[name(…)]`; supertraits become `extends` with each parent applied to the carrier; multi-parameter classes fall out of extra generics. Corpus **Group 2 green** (`Tests/corpus/g02_group.lean`), including F1's nullary inference — `Grp::e()` resolves its carrier from the expected type, natively. **Remaining:** the instance-shadowing lint.
- ✅ **A1.7 `lean! { }`** (`636d51d`) — the interior is Lean's own tactic parser, the one FH slot that is not an FH category.
- ◐ **A1.8 F10 ascription** (2026-08-01): `(e: T)` lands as an elaboration hint. The *without-coercion* half is not enforced yet and the fixture says so: it arrives with A2.0's audit, which licenses coercions whose ref lies in an `as` node and flags every other. Ascription is the escape named by four of Ruling C's six sanctioned implicitnesses, which is why it lands before the features that need escaping from. (The rest of the F9/F10 cluster — `as` coercion + disabling silent coercion — moves to A2.0: its consumers are all M2, and it needs I6 first.)
- A1.9 `fh check` v0 (=C1): Frontend driver, JSON status/errors+FH spans/sorry goals/axioms.
- Pre-M1 gate remaining: the `!`-on-Bool decision (default: hard-error). (I4 and the §9.1 doc PR landed 2026-08-01.)
- **Exit-gate ordering note (2026-08-01):** `euclids_lemma` as design §3 writes it needs `p.dvd(a)`, and `.dvd()` is an F16 canonical-ASCII spelling that resolves through the Mathlib bridge — scheduled at A2.5, i.e. *after* this gate. Either the bridge's `Dvd`/`Membership`-style method table is pulled forward into M1, or the gate's fixture spells divisibility another way. Flagged rather than silently resolved.
- **Exit gate:** `euclids_lemma` (design §3) **and** corpus Group 2 (`id_unique`, quantified hypothesis) elaborate and check; full F7 matrix green; **one F10 ascription golden**.

### M2 — The conversation file (Ruling E order: Groups 8, 11, 12 → 9 → 5, 6, 7, 10; Group 2 was pulled into M1)
- A2.0 **F9 coercion control** (per I6's mechanism): `as` coercion, `as!`, silent-coercion disable. Lands before A2.1/A2.5 (Group 6's `choose(n,k) as R` and Group 12's subtype introduction consume it). Gate: F9 negative golden — a silently-coercing expression must error.
- A2.1 Prop-first consequences: set-builder/subtype (F13 as amended: expected-type election, stage two, Ruling C item six, default `Set<A>`); decidable-`if` (negative tests pin Lean's real wording; friendly F14 wording in `fh check`, per the landed §9.3 amendment); `if h @ (cond)` (F15); F16 canonical-spelling policy recorded (mechanism since A0.2).
- A2.2 Indexed enums; nested + `mutual` inductives; termination attributes; `#[partial]`, `#[noncomputable]`, `#[opaque]`, `extern "axiom"`.
- A2.3 `?`-do (four-monad golden set; the unascribed-closure boundary documented on the differences page), explicit `pure`, structure literals, do-block `for`/`while`/`if`/`let mut` — loop-header `in` is a positional keyword per the landed §9.1 amendment (top-level membership in the iteree parenthesized).
- A2.4 Ambient `var` + `include` (F17) with the F17 corpus obligations (Groups 3/8/9 `var` rewrites + identical-elaboration goldens + ambient-hypothesis pair); `var`-shadowing lint; `Space` + trait-in-annotation + explicit universes (`Space<u>`, `#[universes(u,v)]`); role metadata.
- A2.5 Mathlib bridge: `Fp<P>` (stage-two/bridge special-case — resolution must know `Prime` is a predicate), `Poly<R>` (**consumes I5's real fix**), `Fractions<R>`, `Quotient<R, I>`, morphism aliases, operator classes, `use lean::…`; F11 named arguments; F8 term-position-types tests.
- A2.6 Groups 5/6/7/10 fixtures, completing Ruling E's twelve.
- A2.7 `fh repl` + `fh mcp` v0 (C2/C3).
- **Intra-M2 checkpoint:** Group 9 elaborates (the stage-one acid test; needs A2.4 + F1). **M2 exit gate:** all twelve corpus groups green (incl. A2.6); `riemann_as_traits.rs` port end-to-end with exactly one `sorry`; MCP round-trip smoke (elaborate → goals → try).

### M3 — Ergonomics
`notation!` (above the floor); sorry-report tooling; full span audit; error-taxonomy polish; standalone `.fh` (Lake facet + preprocessor + LSP forwarding — Alloy's history says this is the hard part); the tutorial; differences page completeness review (it has been growing since M0).

**Corpus:** Groups 1 and 2 green (`Tests/corpus/g01_peano.lean`, `g02_group.lean`, 2026-08-01), all four tiers each. Group 2 is half the M1 exit gate; the other half, `euclids_lemma`, is blocked on `.dvd()` — see the exit-gate ordering note above.

## 5. Track B — the Atlas (parallel; needs only I3 + pinned Mathlib)

- ✅ **B1. Extractor v0** (2026-08-01): `FerrisHoward/Atlas/Extract.lean` + `lake exe atlas_extract`. JSONL rows carry name, kind, module, the versioned statement *encoding* (I3 — the digest is computed Rust-side), and **two** used-constant lists: `uses_statement` (what the claim rests on) and `uses_proof` (what the argument rests on), which `atlas why` and foundations/impact need kept apart. Declarations whose statement cannot be encoded carry `stmt_error` rather than being dropped. Verified over `Mathlib.Logic.Basic` (268 rows). Fixture: `Tests/Atlas/Extract.lean`.
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
- C3. `fh mcp` **composes with `lean-lsp-mcp`** for generic tooling (goals/diagnostics/search); FH-specific tools only (per agent-interface §1 as amended via §9.6): `elaborate` (= `fh check` JSON with FH spans), `try`, `minimize`, statement-hash/anti-cheat, Atlas queries, `status`.
- C4. Falsification battery: `plausible`, `decide`/`native_decide`, Rust-side enumeration/SAT with in-Lean verification; auto-run on whole-proof failure; role-metadata steering arrives at M2 — unsteered before that, accepted. No B-track dependency.
- C5. Anti-cheat pipeline: fresh-env check, transitive-sorry scan, axiom whitelist, versioned hash freeze/verify, `leanchecker`; honesty-clause reports; rehearsal fixture (weakened statement must fail the hash check) before first real use; `lean4export` + external checker as the kernel-independence escalation.
- C6. Open-problem runbook (agent-interface §5): openness re-verification, statement import (Formal Conjectures) + human review before freeze, falsification first, lemma-DAG farming via C3, writeup + wiki etiquette.
- C7. Environment engineering: warm daemon per worker, per-tactic (20 s) / per-file timeouts, isolated worktrees + shared read-only cache. Rides C2/C3.

## 7. Sequencing — first three weeks (single implementer assumed; contention is real)

**Week 1 — the vertical slice, serialized: ✅ done 2026-08-01.** A0.1 → minimal `fn`→`def` → `#fh_expand` + sanitizer → four tiers on that feature → CI (I1), plus the I3 and I6 one-pagers. I5 was not started; the spacing stopgap remains the plan of record through M1, and the spike resumes before A2.5.
**Week 2:** A0.2–A0.6; I3 implementation.
**Week 3:** M0 exit gate; ✅ B1 extractor (2026-08-01); A1.5 matrix begins (§9.1 landed).
Contention honestly stated: A-items serialize on one grammar and one implementer; B1 contends on the same person (it is Lean-side), hence week 3; C1 is embedded in M1 by design.

## 7a. Track E — codegen (ADR-006, `research/codegen.md`)

- ✅ **E1 (with M0), 2026-08-01.** Syntax→syntax discipline adopted and now mechanically enforced; `emit-lean` on the statement layer (`FerrisHoward/Emit.lean`, `lake exe fh_emit`); round-trip gate in CI (`scripts/round-trip.py`). The gate emits, checks the artifact is FH-free by inspection, elaborates it from scratch, and compares it to the FH original declaration by declaration using I3's canonical statement encoding. Corpus Group 1 round-trips green: 28 declarations, statements byte-identical. Scaffolding policy: FH authoring commands and `#guard_msgs` assertions are dropped (a negative fixture's contents are deliberately ill-typed — the gate caught that on its first run), and declarations depending on `sorryAx` are omitted as unpublishable, reported rather than silent.
- **E1 remainder.** Proof-term comparison (the gate checks statements, not terms) and `lean4checker` on the artifact alone. Prelude policy (ADR-006 §2: Mathlib-only, inline/vendor/upstream) needs no work yet — FH emits no FH constants, so the artifact's only imports are the source's own minus FH's.
- **E2, E3** (emit-rust lanes R1–R3, Peregrine) — unscheduled here; `research/codegen.md` §1 holds the design. The user's instruction of 2026-08-01 was to leave Lean→Rust alone for now.

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
- R14 **Emittability drift** (new, ADR-006): a construct that cannot expand to Lean surface syntax makes its file unpublishable. Mitigated by the emittable lint firing at authoring time, the round-trip gate in CI, and the standing rule that a stage-two construct is a decision to defend rather than a convenience.
- R13 **F9 blast radius** — **closed 2026-08-01.** I6 found the scoped mechanism (`coercion-control.md`): no stage-two wrapping of FH terms is needed. Residual risk is narrow and named there: the audit reads `CoeExpansionTrace`, which is not a stability-guaranteed API, and a bump that breaks it costs an error message rather than semantics.

## 9. Doc-amendment queue — **ALL LANDED 2026-08-01** (retained for audit)

1. ✅ **corpus-review F7 completion:** `<->` non-associative; `in` in the comparison band, non-associative, no chaining; do-`for` loop-header `in` is a positional keyword (top-level membership in the iteree parenthesized); quantifier-scope interaction rows normative.
2. ✅ **corpus-review F13 re-spec:** expected-type-driven election (stage two), default `Set<A>` when unconstrained; sanctioned as Ruling C item six, escape F10.
3. ✅ **Mechanics (corpus-review F6/F14 + design §8):** four test tiers incl. span tier; exact-message negatives; F6 at expansion time; F14 raw-Lean wording pinned, friendly wording in `fh check`.
4. ✅ **corpus fixtures:** `--`/`/- -/` comment rule recorded; in-doc `//` and `/* */` occurrences migrated.
5. ✅ **corpus-review Ruling C item five:** numeric literals via `OfNat`/`OfScientific` (the I4 mini-design, decided in-doc); `half` spelled explicitly at use site.
6. ✅ **agent-interface:** `fh mcp` composes with `lean-lsp-mcp` (FH-specific tools only); §4(d) implemented as versioned-hash equality.
7. ✅ **atlas-validation §1/§3/§5:** dev vs held-out targets, coverage-without-leakage rule, burn rule, procedural-blinding caveat, held-out suite required for validation claims. **Answer key v1 frozen** — sha256 committed in atlas-validation.md §1; key stored out-of-repo (location deliberately unrecorded here); held-out targets, their tiering, and the suite pass bar are written inside the key.
8. ✅ **design.md:** related-work paragraph; `differences.md` created (Ruling D page, M0 entries seeded).

## 10. New decisions this plan introduces (surfaced deliberately)

Harness on `#guard_msgs` with **exact-message** negatives (§9.3); **span tier as a mandatory fourth tier** (§9.3); F6 moved to expansion time (§9.3); F14 wording split between pinned-Lean-message tests and `fh check` (§9.3); Group 2 pulled into the M1 exit gate (order deviation from Ruling E, justified by design §4.4's "payoff feature… milestone 1"); A1.8/A2.0 split of the F9/F10 cluster (F10 at M1, F9 at M2 behind I6); hash algorithm-version tag and hash-for-defeq substitution (I3, §9.6); human-applied governance label (I1); B3 gate redefinition (seeded + ≥5 mined historical hits); B7: held-out validation targets, sanitized briefs, plain-Lean control ports (genuinely new; key-first ordering, out-of-repo custody, and freeze-before-any-run were already decided in the docs — this plan operationalizes them); C4 runs unsteered pre-M2; `fh mcp` composes with `lean-lsp-mcp` (§9.6); I5 `>`-splitting spike with stopgap-as-plan-of-record; identifier `?`/`!` splitting (A0.6); no-auto-bind wired into A0.1; method-call mechanism at A0.2 with F16 policy at A2.1; loop-header `in` token-position decision delegated to §9.1.

## 11. Deferred-decisions ledger

| Decision | Default | Due |
|---|---|---|
| `!` on Bool | hard-error, fixed wording | pre-M1 |
| F9 mechanism | I6 one-pager decides | pre-A2.0 |
| `<explicit T>` override | not needed | M2, if friction |
| `notation!` floor | adopted | M3 |
| Unicode input | v2 opt-in | post-M3 |
| Tactic sugar | v2, after usage data | post-M3 |
| `native_decide` | per-result opt-in | per use (C5) |
| Crate naming | repo `ferris-howard`; rest deferred | first public release |
