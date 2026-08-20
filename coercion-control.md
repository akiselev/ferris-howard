# F9 coercion control — mechanism one-pager (I6)

**Status:** Decided 2026-08-01 · gates A2.0 · resolves risk R13 · companion to `design.md` §4.7,
`corpus-review.md` F9/F10

## The question

F9 says coercions are always written: `expr as T`, and *silent unification-driven coercion is
disabled in FH-elaborated code*. Ground rule 2 says favour stage one relentlessly. The obvious
implementation of F9 — elaborate every FH term through a bespoke elaborator that refuses to insert
coercions — contradicts the second rule at maximum blast radius: it would put `elab_rules` under
every expression in the language. R13 exists because if no scoped mechanism existed, F9 would have
to be renegotiated rather than implemented.

A scoped mechanism does exist. **No FH term needs a stage-two wrapper.**

## Where coercions actually come from (v4.32.2, verified)

1. **Expected-type boundaries.** `Lean.Elab.Term.ensureHasType` calls `mkCoe` whenever the inferred
   type is not defeq to the expected type. This is the main source: function arguments, definition
   bodies against their declared return type, ascriptions.
2. **`binop%` trees.** The arithmetic elaborator (`Lean/Elab/Extra.lean`) computes a maximum type
   over the whole operator tree and injects coercions at the *leaves* — this is why `n + i` with
   `n : Nat`, `i : Int` silently becomes `↑n + i`.
3. **Explicit `↑` / `CoeFun` / `CoeSort`.** User-written, and in FH the only licensed form.

`OfNat`/`OfScientific` literal elaboration is **not** a coercion and is out of scope here: it is
sanctioned separately as Ruling C item five.

There is no option gating `mkCoe` in this toolchain — grepped, none exists. Option (a) from PLAN
I6, "elaborator option/attribute scoping", would therefore require a core patch, and is rejected.

## The decision

**Two mechanisms, neither of which touches term elaboration.**

### 1. FH's operator expansion does not use `binop%` (stage one, free)

FH owns its operator grammar (Ruling A), so `a + b` expands to `HAdd.hAdd a b`, not to
`binop% HAdd.hAdd a b`. Source (2) then never runs: mixed-type arithmetic fails as an ordinary type
mismatch at the operand, which is both the earlier error and the better one. This costs nothing and
is pure macro expansion.

### 2. A declaration-scoped post-elaboration audit (the residual)

`mkCoe` pushes a `CoeExpansionTrace` custom-info leaf into the InfoTree at **every** insertion,
carrying the syntax ref it was inserted at. So after an FH declaration elaborates, FH walks that
declaration's InfoTree, collects the coercion insertions, and errors on any whose ref does not lie
inside an FH `as` node.

Verified on the pinned toolchain (`lean/Tests/feasibility/e11_coe_audit.lean`):

| input | insertions seen | ref |
|---|---|---|
| `def x : Int := (5 : Nat)` | 1 | the ascription node |
| `def y (n : Nat) (i : Int) : Int := n + i` | 1 | `n` — the `binop%` leaf |
| `def z (n : Nat) : Nat := n + 1` | 0 | — (no false positives) |
| `def w (n : Nat) : Int := (↑n : Int)` | 1 | the `↑` node |

The last two rows are the load-bearing ones: clean code produces nothing to report, and a licensed
coercion is distinguishable from a silent one *by syntax position alone* — no marker constants, no
`Expr` walking, no unfolding heuristics.

Note that row 2 means the audit also catches `binop%` insertions. Mechanism 1 is therefore
belt-and-braces rather than strictly necessary; it is still adopted, because a type mismatch at the
operand is a better diagnostic than an audit failure after the fact.

**Licensing.** `e as T` expands to Lean's real coercion under `withRef` of the `as` node. The audit
collects the source ranges of every `as` node in the FH item and licenses exactly the insertions
whose ref falls inside one. Keeping `as` on Lean's real coercion (rather than an FH marker
constant) is deliberate: a `FerrisHoward.coe` wrapper in the elaborated term would break `simp`
lemma matching against Mathlib's `Nat.cast` family, which is a far worse cost than walking ranges.

## What this costs, stated plainly

- **The coercion is inserted, then flagged.** The audit runs after elaboration, so a silently
  coerced declaration briefly exists before the error is reported. FH's contract is "silent
  coercion is an error", and an error-level report satisfies it, but the environment is not
  pristine at the moment of failure. This is the same shape as `#guard_msgs`-style checking and is
  accepted.
- **`lean! { }` interiors are out of scope.** Inside the escape hatch, Lean's rules apply, including
  its coercions. That is what an escape hatch is; it goes on the differences page when A1.7 lands.
- **The audit is FH-authored code only.** It inspects insertions whose ref lies in FH source. A
  Mathlib lemma whose *statement* contains `↑` is not an FH insertion and is not flagged.
- **One more piece of machinery that tracks a Lean internal.** `CoeExpansionTrace` is not a
  stability-guaranteed API. The mitigation is that the audit is a diagnostic: if it breaks on a
  toolchain bump, FH loses an error message, not its semantics — and bumps are already scheduled
  milestone-boundary events that re-run every tier (R6).

## Options rejected

| Option | Verdict |
|---|---|
| Stage-two elaborator wrapping every FH term | Rejected. Maximum blast radius against ground rule 2; this is the outcome R13 was written to avoid. |
| Elaborator option/attribute that disables coercion | Rejected. No such option exists in v4.32.2; it would need a core patch. |
| Targeted `elab_rules` at coercion-prone positions only | Rejected. Coercion-prone positions are every application argument and every ascription — the "targeted" set is the whole grammar. |
| FH marker constant around licensed coercions | Rejected. Pollutes the elaborated term and breaks Mathlib `simp`/`norm_cast` matching. |

## Before A2.0 (spike list)

1. Attach the audit to FH's declaration expansion — as a linter, so it can be disabled per file
   without touching semantics, and so it composes with `fh check`'s error taxonomy (C1).
2. Range-containment check against `as` nodes, including nested `as` and `as!`.
3. `as!` semantics (lossy coercions, design §4.7): same licensing, different reported category.
4. Negative golden per the A2.0 gate: a silently-coercing expression must error, with its span on
   the coerced leaf rather than the whole declaration.
5. Confirm the audit sees insertions inside FH bodies that expand to `do` blocks (A2.3) — the
   InfoTree is per-declaration, so this is expected to be free, but it is untested.

## Verdict on R13

Resolved. Coercion control is one stage-one expansion choice plus one declaration-scoped
diagnostic. A2.0 may be scheduled as planned work; F9 does not need renegotiating.
