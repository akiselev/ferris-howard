/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · type ascription (A1.8, F10)

`(e: T)` is an elaboration hint. `e as T` is a coercion. They are different operators
because they are different operations: Lean spells them `(e : T)` and `(↑e : T)`, Rust
conflates both into `as`, and Mathlib proofs need ascription-without-coercion constantly.

* **Stage: one.**
* **Ruling D:** *extension* — `(e: T)` inside an expression is not legal Rust, where `:`
  in that position is a type annotation on a `let` or a parameter.
* **Sorry count: zero.**

**What is not enforced yet.** F10's promise is that ascription inserts *no* coercion, and
this expansion is Lean's ascription, which can. The enforcement arrives with A2.0: the
audit licenses a coercion whose syntax ref lies inside an `as` node and flags every other
one (`coercion-control.md`), so an ascription that induces a coercion becomes an error
there rather than here. Saying so is better than implying a guarantee that is one
milestone away.

Ascription is also the escape hatch named by four of Ruling C's six sanctioned
implicitnesses, which is why it lands before the features that need escaping from.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in def lit_nat : Prop := Eq (1 : Nat) 1 -/
#guard_msgs (whitespace := lax) in
#fh_expand fn lit_nat() -> Prop { Eq((1: Nat), 1) }

/-! A comparison may sit directly inside an ascription's parentheses, as it may inside
ordinary ones: the F6 rule is about the parentheses, not about what encloses them. -/

/-- info: set_option autoImplicit false in def cmp_inside (n : Nat) : Prop := (LT.lt n 5 : Prop) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn cmp_inside(n: Nat) -> Prop { (n < 5: Prop) }

/-! ## Tier 2 — elaboration

Ruling C item five: numeric literals are polymorphic through Lean's `OfNat`, and
ascription is the escape. These two are different declarations, and the ascription is what
makes them different.
-/

fn as_nat() -> Nat { (1: Nat) }
fn as_int() -> Int { (1: Int) }

example : as_nat = (1 : Nat) := rfl
example : as_int = (1 : Int) := rfl

/-- info: 'as_nat' does not depend on any axioms -/
#guard_msgs in
#print axioms as_nat

/-! Ascription is a hint, not a cast: it constrains elaboration and disappears. -/

fn ascribed_lt(n: Nat) -> Prop { ((n: Nat) < 5) }

theorem ascribed_lt_zero() -> ascribed_lt(0) { lean! { unfold ascribed_lt; decide } }

/-- info: 'ascribed_lt_zero' does not depend on any axioms -/
#guard_msgs in
#print axioms ascribed_lt_zero

/-! ## Tier 3 — negative

An ascription that cannot hold is an error at the ascription, not somewhere downstream.
-/

/--
error: Type mismatch
  true
has type
  Bool
but is expected to have type
  Nat
-/
#guard_msgs in
fn bad_ascription() -> Prop { Eq((true: Nat), 1) }

/-! ## Tier 4 — span -/

/-- info: error @ +0:34-45 «(true: Nat)» -/
#guard_msgs in
#fh_spans in
fn bad_ascription2() -> Prop { Eq((true: Nat), 1) }
