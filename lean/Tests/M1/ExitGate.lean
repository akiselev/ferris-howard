/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# The M1 exit gate — `euclids_lemma`

PLAN §4's M1 gate: *`euclids_lemma` (design §3) and corpus Group 2 elaborate and check.*
Group 2 is `Tests/corpus/g02_group.lean`; this is the other half, and the theorem below is
design §3's text unchanged, down to the `||`.

Design §1 states the target precisely — "`euclids_lemma` checked against
`Nat.Prime.dvd_mul`" — so this checks the two statements against each other rather than
taking the proof's word for it.

* **Stage: one.**
* **Sorry count: zero.**
-/

/-! ## Tier 3 — negative, and it comes first

Before the import, `.dvd` is plain dot notation and the file does not compile. That is the
whole point of making the spelling explicit: nothing is silently rewritten, and a missing
`use` fails in the ordinary way, with Lean's own wording.
-/

/--
error: Invalid field `dvd`: The environment does not contain `Nat.dvd`, so it is not possible to project the field `dvd` from an expression
  p
of type `ℕ`
-/
#guard_msgs in
fn unimported(p: Nat, a: Nat) -> Prop { p.dvd(a) }

/-! ## The import

F16 says `.dvd()` is the canonical spelling; Rust says a trait's methods are callable once
the trait is imported. One line brings the two together, and everything below it changes
meaning because the file asked.
-/

use lean::Dvd;

theorem euclids_lemma<p: Nat, a: Nat, b: Nat>(hp: p.Prime, h: p.dvd(a * b))
    -> p.dvd(a) || p.dvd(b)
{
    lean! { exact (Nat.Prime.dvd_mul hp).mp h }
}

/-! ## Tier 1 — golden expansion

Generics are implicit binders, `p.dvd` is `Dvd.dvd p` because `Dvd` is in scope, and `||`
is `Or` — Ruling A, unconditionally.

(The two linter warnings are Lean's, not FH's: it rewrites `by exact e` to `e` and then
observes that the tactic it removed did nothing.)
-/

/--
info: set_option autoImplicit false in
theorem euclid2 {p : Nat} {a : Nat} {b : Nat} (hp : p.Prime) (h : Dvd.dvd p (HMul.hMul a b)) :
    Or (Dvd.dvd p a) (Dvd.dvd p b) := by exact (Nat.Prime.dvd_mul hp).mp h
---
warning: this tactic is never executed

Note: This linter can be disabled with `set_option linter.unreachableTactic false`
---
warning: 'exact (Nat.Prime.dvd_mul hp).mp h' tactic does nothing

Note: This linter can be disabled with `set_option linter.unusedTactic false`
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem euclid2<p: Nat, a: Nat, b: Nat>(hp: p.Prime, h: p.dvd(a * b))
    -> p.dvd(a) || p.dvd(b)
{
    lean! { exact (Nat.Prime.dvd_mul hp).mp h }
}

/-! ## Tier 2 — elaboration

The statement, and then the check design §1 asks for: the theorem FH produced is the one
Mathlib proves, not merely *a* true statement about divisibility.
-/

/-- info: theorem euclids_lemma : ∀ {p a b : ℕ}, Nat.Prime p → p ∣ a * b → p ∣ a ∨ p ∣ b -/
#guard_msgs in
#print sig euclids_lemma

/-- info: 'euclids_lemma' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms euclids_lemma

/-! Interderivable with Mathlib's, in both directions — which is what "checked against
`Nat.Prime.dvd_mul`" means. -/

example {p a b : ℕ} (hp : Nat.Prime p) : p ∣ a * b → p ∣ a ∨ p ∣ b :=
  euclids_lemma hp

example {p a b : ℕ} (hp : Nat.Prime p) (h : p ∣ a * b) : p ∣ a ∨ p ∣ b :=
  (Nat.Prime.dvd_mul hp).mp h

/-! ## Tier 4 — span

A mismatch inside a bridged call lands on the offending operand, in FH source.
-/

/-- info: error @ +0:44-45 «b» -/
#guard_msgs in
#fh_spans in
fn spanned(p: Nat, b: Bool) -> Prop { p.dvd(b) }
