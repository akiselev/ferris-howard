/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · the Mathlib object bridge (A2.5, design §6)

`Fp<P>` is `ZMod P`, `Poly<R>` is `Polynomial R`, `Fractions<R>` is `FractionRing R`,
`Quotient<R, I>` is `R ⧸ I` — and `where P: Prime` is `[Fact (Nat.Prime P)]`, which is the
one that matters.

* **Stage: one.**
* **Ruling D:** *confined* — every name here is FH's own; none of it is legal Rust with a
  meaning to preserve.
* **Sorry count: zero.**

## The flagship

Design §6 calls it out: "`Fp<P>` = `ZMod P`, with the crucial subtlety that Mathlib's
field-structure instance requires `[Fact p.Prime]`, so our `where P: Prime` bound expands
to exactly that `Fact` binder (this is precisely the 'dependent bound Rust couldn't
express' made real, and it should be the flagship example in the README)."

Two things are happening and both are worth naming. First, `where P: Prime` constrains a
**value**, not a type — Rust's `where` clauses cannot do that, and the whole reason FH
exists is that Lean's can. Second, the bound a mathematician writes ("let p be prime") and
the binder Mathlib's instance needs (`Fact p.Prime`, because instance search cannot look
inside a proposition) are *different things*, and the bridge is where that translation
lives rather than in the reader's head.

`inv_cancel` below is the payoff: it is a statement about a field, and the only thing
making `ZMod P` a field is the binder the bridge produced.

## Scoped, like every other bridge

`use lean::Fp;` opens `FerrisHoward.Bridge.Fp`. Outside that import, `Fp<P>` is an
ordinary application of whatever `Fp` you declared — the same rule F16 uses for method
spellings, and the same rule Rust uses for traits.

## The bridge does not import Mathlib

Stage one produces *syntax*: `Fp<P>` becomes the syntax `ZMod P`, and `ZMod` resolves in
the file that wrote `Fp<P>`. The names are built unhygienically for exactly that reason.
So FH's core carries no Mathlib dependency and neither does the emitted artifact, which
contains Mathlib's own name with no FH module behind it — which is what ADR-006 is for.
-/

/-! ## Tier 1 — golden expansion

### With no bridge in scope, nothing changes.
-/

/-- info: set_option autoImplicit false in def plain {A : Type _} (v : List A) : List A := v -/
#guard_msgs (whitespace := lax) in
#fh_expand fn plain<A>(v: List<A>) -> List<A> { v }

/-- info: set_option autoImplicit false in def bounded {R : Type _} [CommRing R] (r : R) : R := r -/
#guard_msgs (whitespace := lax) in
#fh_expand fn bounded<R>(r: R) -> R where R: CommRing { r }

/-! And `Fp` with no `use` is just an identifier — whatever the file called `Fp`. -/

/-- info: set_option autoImplicit false in def unbridged {P : Type _} (x : Fp P) : Fp P := x -/
#guard_msgs (whitespace := lax) in
#fh_expand fn unbridged<P>(x: Fp<P>) -> Fp<P> { x }

section
use lean::Fp;
use lean::Prime;

/-! ### With the bridge in scope -/

/-- info: set_option autoImplicit false in abbrev F5 := ZMod 5 -/
#guard_msgs (whitespace := lax) in
#fh_expand type F5 = Fp<5>;

/-- info: set_option autoImplicit false in def zero {P : Nat} [Fact (Nat.Prime P)] : ZMod P := 0 -/
#guard_msgs (whitespace := lax) in
#fh_expand fn zero<P: Nat>() -> Fp<P> where P: Prime { 0 }

/-! ## Tier 2 — elaboration -/

type F5 = Fp<5>;

/-- info: @[reducible] def F5 : Type := ZMod 5 -/
#guard_msgs (whitespace := lax) in
#print F5

example : (2 : F5) + 4 = 1 := by decide

/-! ### The flagship

A field fact about `ZMod P`, which holds only because `where P: Prime` produced the `Fact`
binder that carries the field instance. -/

theorem inv_cancel<P: Nat>(x: Fp<P>) -> !(x == 0) -> x * Inv::inv(x) == 1 where P: Prime {
  lean! { intro h; exact mul_inv_cancel₀ h }
}

/--
info: @inv_cancel : ∀ {P : ℕ} [inst : Fact (Nat.Prime P)] (x : ZMod P), ¬x = 0 → x * x⁻¹ = 1
-/
#guard_msgs in
#check @inv_cancel

/-- info: 'inv_cancel' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms inv_cancel

end

/-! ## The other three objects -/

section
use lean::Poly;
use lean::Fractions;
use lean::Quotient;

/-- info: set_option autoImplicit false in abbrev PolyQ := Polynomial Rat -/
#guard_msgs (whitespace := lax) in
#fh_expand type PolyQ = Poly<Rat>;

/-- info: set_option autoImplicit false in abbrev FracInt := FractionRing Int -/
#guard_msgs (whitespace := lax) in
#fh_expand type FracInt = Fractions<Int>;

/--
info: set_option autoImplicit false in
def quot_ty {R : Type _} {I : Type _} : Type _ := HasQuotient.Quotient R I
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn quot_ty<R, I>() -> Space { Quotient<R, I> }

type PolyQ = Poly<Rat>;

example : (Polynomial.X : PolyQ) ≠ 0 := Polynomial.X_ne_zero

end

/-! Outside the sections, all five names are ordinary identifiers again. -/

/-- info: set_option autoImplicit false in abbrev AfterEnd := Poly Rat -/
#guard_msgs (whitespace := lax) in
#fh_expand type AfterEnd = Poly<Rat>;

/-! ## Tier 3 — negative

### The bound without its bridge

`use lean::Fp;` alone leaves `where P: Prime` meaning what a bound has always meant, `[Prime P]`
— and Mathlib's `Prime` is a *predicate*, not a class, so Lean says so. This is the
clearest statement of what `use lean::Prime;` is for: the bound a mathematician writes and
the binder instance search needs are different objects.
-/

section
use lean::Fp;

/--
error: invalid binder annotation, type is not a class instance
  Prime P

Note: Use the command `set_option checkBinderAnnotations false` to disable the check
-/
#guard_msgs (whitespace := lax) in
fn zero_np<P: Nat>() -> Fp<P> where P: Prime { 0 }

/-! ### Arity is part of the alias

`Fp` takes one argument. Two means the bridge rule does not match, so the default rule
applies and Lean reports the identifier that is actually there — no invented diagnostic,
and no silent wrong answer. -/

/-- error: Unknown identifier `Fp` -/
#guard_msgs in
type TwoArgs = Fp<5, 7>;

/-! ## Tier 4 — span -/

/-- info: error @ +0:16-18 «Fp» -/
#guard_msgs in
#fh_spans in
type TwoArgs2 = Fp<5, 7>;

end
