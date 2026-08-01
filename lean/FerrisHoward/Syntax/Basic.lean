/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean

/-!
# FH syntax categories and the M0 core productions (A0.1)

Three categories, per `design.md` §4.1 and PLAN A0.1:

* `fh_item` — Rust *items* (`fn`, later `struct`/`enum`/`trait`/`mod`/…);
* `fh_pat` — Rust *patterns* (binding positions);
* `fh_expr` — a **single** expression category serving both term and type positions.
  There is deliberately no separate types category: dependency (`Vector<T, n>`) is
  what forces the unification, and maintaining two grammars that must later be
  merged is the mistake design §4.1 exists to prevent.

**FH slots always use FH categories, never Lean's `term`.** A malformed FH construct
must fail inside FH's grammar rather than silently falling through to Lean's, which is
what keeps command coexistence (PLAN §2) honest.

The categories are declared at the root so that quotations read `` `(fh_expr| …) ``;
the *productions* live in the `FerrisHoward` namespace so every FH node kind is
prefixed `FerrisHoward.*` — the golden printer relies on that to know where FH's own
expansion stops (`FerrisHoward/Test/Golden.lean`).
-/

declare_syntax_cat fh_expr
declare_syntax_cat fh_pat
declare_syntax_cat fh_item

namespace FerrisHoward

/-! ## Expressions -/

/-- An identifier. Dotted names (`Nat.succ`) are single identifier tokens; the FH `::`
path spelling arrives with A0.2. -/
syntax (name := fhExprIdent) ident : fh_expr

/-- A numeric literal. FH introduces no literal syntax of its own: elaboration is
Lean's `OfNat` (Ruling C item five, the landed §9.5 amendment). -/
syntax (name := fhExprNum) num : fh_expr

/-- Parenthesised expression. Also the escape hatch Ruling B keeps insisting on. -/
syntax (name := fhExprParen) "(" fh_expr ")" : fh_expr

/-- Call. `noWs` requires the callee and `(` to be adjacent: FH rejects `f (x)`, which
Rust accepts. Restriction, not divergence — relaxing it later is non-breaking, the
reverse is not (Ruling B). Recorded on the differences page. -/
syntax (name := fhExprCall) fh_expr noWs "(" fh_expr,* ")" : fh_expr

/-! ## Patterns -/

/-- A binding pattern. -/
syntax (name := fhPatIdent) ident : fh_pat

/-- The wildcard pattern: `fn f(_: Nat)`. -/
syntax (name := fhPatHole) "_" : fh_pat

/-! ## Items -/

/-- `fn name(p: T, …) -> R { e }` → `def name (p : T) … : R := e`.

The body is a single expression (design §3, "body is an expression"); statement
bodies, bodyless `fn …;`, `match`, `let` and closures arrive with A0.2. -/
syntax (name := fhFn) "fn " ident "(" (fh_pat ": " fh_expr),* ")" " -> " fh_expr " { " fh_expr " }" : fh_item

/-! ## The command entry point

Per-declaration commands, not a monolithic `rust { }` block (design §2). Lifting the
whole item category to `command` in one production keeps a single dispatch point for
stage one; verified on-toolchain that plain Lean commands in the same file are
unaffected (PLAN §2's longest-match dispatch fact). -/
syntax (name := fhItemCommand) fh_item : command

end FerrisHoward
