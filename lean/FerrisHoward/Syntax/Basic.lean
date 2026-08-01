/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean

/-!
# FH syntax categories and the M0 core productions (A0.1, A0.2)

Three categories, per `design.md` §4.1 and PLAN A0.1:

* `fh_item` — Rust *items* (`fn`, later `struct`/`enum`/`trait`/`mod`/…);
* `fh_pat` — Rust *patterns* (binding and match positions);
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

## Precedence

The F7 table (`corpus-review.md`, frozen pre-M1) runs loosest to tightest:
`->`, `<->`, `||`, `&&`, `!`, comparisons, arithmetic, then the tight postfix forms.
M0 has no operators yet — A1.5 fills the middle — so only the two ends exist here:

* **`max`**: identifiers, literals, parentheses, `match`, and the postfix chain
  (call, field, `::` path), which is left-associative and binds tightest;
* **unannotated (loosest)**: `let … ; …` and closures, whose bodies extend as far right
  as possible. `(let x = 1; x).f` therefore needs its parentheses, which is the
  reading Ruling B asks for anyway.
-/

declare_syntax_cat fh_expr
declare_syntax_cat fh_pat
declare_syntax_cat fh_item
declare_syntax_cat fh_fn_body

namespace FerrisHoward

/-! ## Expressions -/

/-- An identifier. -/
syntax:max (name := fhExprIdent) ident : fh_expr

/-- A numeric literal. FH introduces no literal syntax of its own: elaboration is
Lean's `OfNat` (Ruling C item five, the landed §9.5 amendment). -/
syntax:max (name := fhExprNum) num : fh_expr

/-- Parenthesised expression. Also the escape hatch Ruling B keeps insisting on. -/
syntax:max (name := fhExprParen) "(" fh_expr ")" : fh_expr

/-- Call. `noWs` requires the callee and `(` to be adjacent: FH rejects `f (x)`, which
Rust accepts. Restriction, not divergence — relaxing it later is non-breaking, the
reverse is not (Ruling B). Recorded on the differences page. -/
syntax:max (name := fhExprCall) fh_expr:max noWs "(" fh_expr,* ")" : fh_expr

/-- Field access and method receivers: `p.x`, `x.f(a)`. Maps to Lean's *generalized*
dot notation, which is namespace-directed and so strictly more powerful than Rust's
(design §4.7) — the mechanism lands here at A0.2, the canonical-ASCII-spelling policy
for Mathlib notations (F16) is recorded at A2.1. -/
syntax:max (name := fhExprField) fh_expr:max noWs "." noWs ident : fh_expr

/-- Path: `Nat::succ`, `N::Zero`. `::` joins identifiers into one Lean name — design §6's
no-mangling policy means Mathlib names are reachable verbatim as `Nat::Prime::dvd_mul`. -/
syntax:max (name := fhExprPath) fh_expr:max "::" ident : fh_expr

/-- `match e { p => e, … }`. Trailing comma allowed, as in Rust. -/
syntax fhMatchArm := fh_pat " => " fh_expr

@[inherit_doc fhMatchArm]
syntax:max (name := fhExprMatch) "match " fh_expr " { " fhMatchArm,*,? " }" : fh_expr

/-- Closure. Closures *are* lambdas (design §3), which is load-bearing for §4.2's
quantifiers and for big operators (`Finset::range(n).sum(|k| …)`).

Zero-argument closures (`|| e`) are not FH syntax: `||` is a single token. Restriction,
recorded on the differences page. -/
syntax (name := fhExprClosure) "|" fh_pat,+ "|" fh_expr : fh_expr

/-- `let x = e; rest`, with an optional annotation. Plain `let` stays pure — the
`?`-flavoured monadic form is A2.3. -/
syntax (name := fhExprLet) "let " fh_pat (": " fh_expr)? " = " fh_expr "; " fh_expr : fh_expr

/-! ## Patterns -/

/-- A binding pattern (in match position, a lowercase name binds; a resolvable one is a
constructor — Lean's rule, inherited). -/
syntax:max (name := fhPatIdent) ident : fh_pat

/-- The wildcard pattern: `fn f(_: Nat)`, `_ => …`. -/
syntax:max (name := fhPatHole) "_" : fh_pat

/-- A literal pattern. -/
syntax:max (name := fhPatNum) num : fh_pat

/-- A constructor path in pattern position: `N::Zero`. -/
syntax:max (name := fhPatPath) fh_pat:max "::" ident : fh_pat

/-- A constructor application in pattern position: `N::Succ(k)`. -/
syntax:max (name := fhPatCtor) fh_pat:max noWs "(" fh_pat,* ")" : fh_pat

/-! ## Items -/

/-- The body of an `fn`: an expression block. -/
syntax (name := fhFnBodyExpr) " { " fh_expr " }" : fh_fn_body

/-- A bodyless `fn`, ending in `;`: elaborates to a `sorry`-backed definition
(design §3). Axioms are `extern "axiom"` (§4.6), not this. -/
syntax (name := fhFnBodyNone) ";" : fh_fn_body

/-- `fn name(p: T, …) -> R { e }` → `def name (p : T) … : R := e`, and
`fn name(…) -> R;` → the same with `:= sorry`.

Two bodies rather than two `fn` productions: distinct leading tokens (`{` vs `;`) keep
the grammar backtrack-free, which is Ruling B's scope note. -/
syntax (name := fhFn) "fn " ident "(" (fh_pat ": " fh_expr),* ")" " -> " fh_expr fh_fn_body : fh_item

/-! ## The command entry point

Per-declaration commands, not a monolithic `rust { }` block (design §2). Lifting the
whole item category to `command` in one production keeps a single dispatch point for
stage one; verified on-toolchain that plain Lean commands in the same file are
unaffected (PLAN §2's longest-match dispatch fact). -/
syntax (name := fhItemCommand) fh_item : command

end FerrisHoward
