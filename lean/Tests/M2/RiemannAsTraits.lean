/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# The M2 exit criterion — `riemann_as_traits.rs`, ported

Design §7 states the criterion with teeth:

> A Ferris–Howard port of our `riemann_as_traits.rs` elaborates end-to-end — real
> `EuclideanDomain`, real `ZMod`, laws as fields, and `impl RiemannHypothesis for
> IntegerWorld` reporting exactly one `sorry`.

All four, and the `sorry` count is asserted below rather than claimed.

* **Stage: one**, throughout. No `elab_rules` anywhere in the language (ADR-006).
* **Ruling D:** *confined* — trait bodies carrying laws, `where` bounds that constrain
  values, and ambient `var` declarations have no Rust readings to preserve.
* **Sorry count: exactly one**, and it is the Riemann hypothesis.

## Why this file is the exit criterion rather than a thirteenth corpus group

The twelve groups each stress one thing. This one stresses *composition*: every M0–M2
feature is here at once, in a single file that reads as mathematics rather than as a test
suite. Traits with laws (§4.4), dependent bounds through the Mathlib bridge (§6), ambient
`var` declarations (F17), the kind vocabulary (F18), written coercions (F9), the `Fp<P>`
alias, generalized dot notation, `lean!` escapes, and `todo!()` tracking — and the only
`sorry` is the one nobody has.
-/

section
use lean::Fp;
use lean::Prime;
use lean::Dvd;
use lean::Pow;

/-! ## The arithmetic world

"Let `R` be a Euclidean domain" — one `var`, folding the carrier and its structure the way
a mathematician says it, and the way Mathlib's `variable {R : Type*} [EuclideanDomain R]`
writes it (design §4.8).

Divisibility is a spelling, not a method: `Dvd.dvd` has no carrier to hang `dvd` on, so
the `Dvd` import above is what gives `a.dvd(b)` its meaning (F16).
-/

mod Arithmetic {
  var R: impl EuclideanDomain;

  fn divides(a: R, b: R) -> Prop { a.dvd(b) }

  theorem divides_refl(a: R) -> divides(a, a) { lean! { unfold divides; exact dvd_refl a } }

  theorem divides_trans(a: R, b: R, c: R, hab: divides(a, b), hbc: divides(b, c))
      -> divides(a, c)
  { lean! { unfold divides at *; exact dvd_trans hab hbc } }
}

/-! ## The residue worlds

`Fp<P>` is `ZMod P` and `where P: Prime` is `[Fact (Nat.Prime P)]` — the dependent bound
Rust cannot express, because it constrains a *value*. Without it `ZMod P` is a ring; with
it, a field.
-/

mod Residues {
  theorem frobenius<P: Nat>(a: Fp<P>) -> a.pow(P) == a
  where P: Prime
  { lean! { exact ZMod.pow_card a } }

  theorem inv_cancel<P: Nat>(x: Fp<P>) -> !(x == 0) -> x * Inv::inv(x) == 1
  where P: Prime
  { lean! { intro h; exact mul_inv_cancel₀ h } }
}

/-! ## The hypothesis, as a trait with a law

Design §4.4 calls laws-as-fields "the payoff feature of the whole project". Here the law
*is* the open problem: a `World` is a structure that claims the Riemann hypothesis, and the
only way to have one is to prove it.

`RiemannHypothesis` is Mathlib's own — `∀ s, riemannZeta s = 0 → (¬∃ n, s = -2 * (n + 1))
→ s ≠ 1 → s.re = 1 / 2` — not a restatement, so there is nothing to get subtly wrong.
-/

trait RiemannWorld<Self> {
    fn zeros(w: Self) -> Set<Complex>;

    rh: RiemannHypothesis;
}

/-! `IntegerWorld` is the carrier: the ordinary integers, whose zeta function is the one in
the statement. A `struct` with no fields is the honest shape — the world carries no data,
only the claim. -/

struct IntegerWorld { tag: Unit }

/-! ## The one `sorry`

Everything above elaborates and proves. This does not, and says so at its own span.

The law is a field, so the `todo!()` goes where the obligation is. Nothing routes around
it: `sorryAx` is kernel-visible, and every honesty check downstream — `#print axioms`,
`#fh_sorry_report`, C5's transitive scan — finds it without taking FH's word for anything.
-/

/--
warning: declaration uses `sorry`
---
info: FH todo: the Riemann hypothesis
-/
#guard_msgs in
impl RiemannWorld for IntegerWorld {
    fn zeros(_w: IntegerWorld) -> Set<Complex> { Set::univ }

    rh: todo!("the Riemann hypothesis");
}

end

/-! ## The assertion the criterion actually asks for

"Reporting exactly one `sorry`." Not "few", not "the ones we meant" — one, and Lean's own
axiom tracking is what says so, since `sorryAx` is kernel-visible and FH is not trusted to
self-report.
-/

/-- info: 'Arithmetic.divides_trans' does not depend on any axioms -/
#guard_msgs in
#print axioms Arithmetic.divides_trans

/-- info: 'Residues.frobenius' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Residues.frobenius

/-- info: 'Residues.inv_cancel' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Residues.inv_cancel

/-! And the instance, which is where the `sorry` lives. -/

/-- info: 'instRiemannWorldIntegerWorld' depends on axioms: [propext, sorryAx, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instRiemannWorldIntegerWorld

/-! **Exactly one**, and this is the assertion that says so. `#fh_sorry_report` is derived
rather than bookkept — it asks the environment which declarations depend on `sorryAx`
rather than trusting a list FH maintained while expanding — so it cannot drift from
reality, and it would catch a `sorry` arriving by any other route. -/

/--
info: FH sorry report: 1 declaration(s) depend on `sorryAx`
  instRiemannWorldIntegerWorld
-/
#guard_msgs in
#fh_sorry_report

/-! ## The statements, printed back

The point of the whole exercise: what FH wrote is what Lean holds.
-/

/--
info: theorem Arithmetic.divides_trans.{u_1} : ∀ {R : Type u_1} [inst : EuclideanDomain R] (a b c : R),
  Arithmetic.divides a b → Arithmetic.divides b c → Arithmetic.divides a c
-/
#guard_msgs (whitespace := lax) in
#print sig Arithmetic.divides_trans

/--
info: theorem Residues.frobenius : ∀ {P : ℕ} [inst : Fact (Nat.Prime P)] (a : ZMod P), a ^ P = a
-/
#guard_msgs in
#print sig Residues.frobenius

/-- info: class RiemannWorld.{u_1} (Self : Type u_1) : Type u_1 -/
#guard_msgs (whitespace := lax, substring := true) in
#print RiemannWorld

/-! The law's type is Mathlib's `RiemannHypothesis`, verbatim — which is the claim this
file is making about itself. -/

/-- info: RiemannWorld.rh : ∀ (Self : Type u_1) [self : RiemannWorld Self], RiemannHypothesis -/
#guard_msgs in
#check @RiemannWorld.rh
