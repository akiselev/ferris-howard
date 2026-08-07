/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · the method-spelling bridge (F16)

F16: ASCII method spellings are canonical for Mathlib notations with no Rust operator, and
Unicode operator input is a v2 opt-in that is never required. `p.dvd(a)` is `p ∣ a`.

* **Stage: one** — a name table, applied during expansion.
* **Ruling D:** *confined*. The spelling exists because the notation does; Rust has no
  divisibility operator to disagree with.
* **Sorry count: zero.**

## A spelling comes from an import

FH's `.` is Lean's generalized dot notation, which resolves by the receiver's head symbol.
Class notations have no such home, so the spelling has to come from somewhere — and it
comes from `use lean::C;`, exactly as a Rust programmer expects: a trait's methods are
callable once the trait is imported.

That scoping is what makes the mechanism safe. Mathlib has 587 declarations named `T.comp`
and 156 named `T.union`; a *global* table for those spellings would silently replace
bundled composition and union everywhere. Scoped, they are a local choice made by a file
that said what it meant.
-/

/-! ## Tier 1 — golden expansion

Without an import, `.` is plain dot notation and nothing has changed.
-/

/-- info: set_option autoImplicit false in def is_prime (p : Nat) : Prop := p.Prime -/
#guard_msgs (whitespace := lax) in
#fh_expand fn is_prime(p: Nat) -> Prop { p.Prime }

/-- info: set_option autoImplicit false in def unbridged (p : Nat) (a : Nat) : Prop := p.dvd a -/
#guard_msgs (whitespace := lax) in
#fh_expand fn unbridged(p: Nat, a: Nat) -> Prop { p.dvd(a) }

/-! With the import, the spelling resolves. Lean's lexer takes `p.dvd` as a *single*
identifier, so the hook applies to dotted identifiers as well as to the `.` production. -/

use lean::Dvd;

/-- info: set_option autoImplicit false in def divides (p : Nat) (a : Nat) : Prop := Dvd.dvd p a -/
#guard_msgs (whitespace := lax) in
#fh_expand fn divides(p: Nat, a: Nat) -> Prop { p.dvd(a) }

/-! A compound receiver reaches the same table through the `.` production. -/

/-- info: set_option autoImplicit false in def sum_divides (p : Nat) (a : Nat) (b : Nat) : Prop := Dvd.dvd (HAdd.hAdd a b) p -/
#guard_msgs (whitespace := lax) in
#fh_expand fn sum_divides(p: Nat, a: Nat, b: Nat) -> Prop { (a + b).dvd(p) }

/-! An unbridged spelling is still dot notation, even inside the import's scope: `use`
brings in one class's spellings, not a free-for-all. -/

/-- info: set_option autoImplicit false in def still_prime (p : Nat) : Prop := p.Prime -/
#guard_msgs (whitespace := lax) in
#fh_expand fn still_prime(p: Nat) -> Prop { p.Prime }

/-! ## Tier 2 — elaboration -/

fn divides(p: Nat, a: Nat) -> Prop { p.dvd(a) }

example : divides 3 12 := by unfold divides; decide

theorem two_dvd_four() -> divides(2, 4) { lean! { unfold divides; decide } }

/-- info: 'two_dvd_four' depends on axioms: [propext] -/
#guard_msgs in
#print axioms two_dvd_four

/-- The bridged spelling really is Mathlib's `∣`, not a lookalike. -/
example (p a : Nat) : divides p a ↔ p ∣ a := Iff.rfl

/-! ## Tier 3 — negative

The cost of an unconditional table, pinned rather than hidden. Mathlib has 13 lemmas whose
*receiver is a proof* and whose last component is `dvd` — `IsUnit.dvd` among them. Written
with `.`, FH reads the notation and the lemma is out of reach.
-/

/--
error: Application type mismatch: The argument
  h
has type
  IsUnit a
of sort `Prop` but is expected to have type
  ℕ
of sort `Type` in the application
  Dvd.dvd h
-/
#guard_msgs in
fn unit_dvd(a: Nat, h: IsUnit(a), b: Nat) -> Prop { h.dvd(b) }

/-! The escape is the other operator, and it is the one FH's own rules already ask for:
`::` composes a name, `.` reaches a value's method. -/

theorem unit_dvd_ok(a: Nat, b: Nat, h: IsUnit(a)) -> a.dvd(b) { IsUnit::dvd(h) }

/-- info: 'unit_dvd_ok' depends on axioms: [propext] -/
#guard_msgs in
#print axioms unit_dvd_ok

/-! ## Tier 4 — span -/

/-- info: error @ +0:54-56 «_h» -/
#guard_msgs in
#fh_spans in
fn unit_dvd2(a: Nat, _h: IsUnit(a), b: Nat) -> Prop { _h.dvd(b) }
