/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M0 · `fn` → `def`: the vertical slice (PLAN §7, week 1)

The first FH feature, with all four tiers (design §8 as amended by PLAN §9.3).

* **Stage: one.** Pure `macro_rules`, no `elab_rules` — ground rule 2. The item expands to
  Lean surface syntax and Lean's own elaborator does every piece of type checking.
* **Ruling D:** the `fn` → `def` row is design §3's uncontroversial spine, so the item form
  itself is not a divergence. The one entry this feature adds to `differences.md` is the
  call-spacing restriction (`f(x)`, not `f (x)`), recorded there.
* **Sorry count: zero**, asserted per declaration by `#print axioms` — a declaration that
  depends on no axioms depends on no `sorryAx`.

Scope is deliberately the minimum that exercises the whole pipeline: identifiers, numeric
literals, calls, parentheses, explicit parameters, an expression body. `match`, `let`,
closures, `::` paths, dot syntax and bodyless `fn …;` are A0.2.
-/

/-! ## Tier 1 — golden expansion

The living syntax specification: FH surface on the left of the `#fh_expand`, the Lean
surface syntax FH commits to producing on the right. `set_option autoImplicit false in`
is part of the commitment, not decoration — no-auto-bind from day one (F17's hard rule).
-/

/--
info: set_option autoImplicit false in
def const_nat (a : Nat) (_ : Nat) : Nat :=
  a
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn const_nat(a: Nat, _: Nat) -> Nat { a }

/--
info: set_option autoImplicit false in
def zero : Nat :=
  0
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn zero() -> Nat { 0 }

/--
info: set_option autoImplicit false in
def apply_const : Nat :=
  const_nat 1 (0)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn apply_const() -> Nat { const_nat(1, (0)) }

/-! ## Tier 2 — elaboration

Zero errors, zero sorries, and the translation means what it says: the `example`s check
the elaborated definitions against plain Lean by `rfl`.
-/

fn id_nat(n: Nat) -> Nat { n }
fn const_nat(a: Nat, _: Nat) -> Nat { a }
fn apply_const() -> Nat { const_nat(1, (0)) }

example : id_nat 3 = 3 := rfl
example : const_nat 1 0 = 1 := rfl
example : apply_const = 1 := rfl

/-- info: 'id_nat' does not depend on any axioms -/
#guard_msgs in
#print axioms id_nat

/-- info: 'apply_const' does not depend on any axioms -/
#guard_msgs in
#print axioms apply_const

/-! ## Tier 3 — negative

The M0-native negative test: no-auto-bind. Under Lean's default options `T` would be
silently auto-bound as a universe-polymorphic implicit and this declaration would be
accepted; FH makes it an error, which is the whole of F17's hard rule.
-/

/--
error: Unknown identifier `T`

Note: It is not possible to treat `T` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
-/
#guard_msgs in
fn unbound(x: T) -> Nat { x }

/-! ## Tier 4 — span

Diagnostics point at the FH source — not at the whole command, and not at a position
inside the generated Lean. Positions are relative to the wrapped command.

Two assertions: one in a *signature* (the type annotation) and one in a *body*, which are
the two places A0.2 will start moving syntax around.
-/

/-- info: error @ +0:15-16 «T» -/
#guard_msgs in
#fh_spans in
fn unbound2(x: T) -> Nat { x }

/-- info: error @ +0:31-35 «Bool» -/
#guard_msgs in
#fh_spans in
fn wrong_body(_: Nat) -> Nat { Bool }
