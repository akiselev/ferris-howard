/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 6 — the binomial theorem: big operators and written coercions

`corpus-review.md` Group 6, made executable. Two claims are under test and both are about
things FH decided *not* to build.

**Big operators need no syntax.** `Finset::range(n + 1).sum(|k| …)` is a method call whose
argument is a closure, and it maps straight onto `Finset.sum`. No `Σ` notation, no binder
form, nothing new in the grammar — the closure is the binder. The review says so and this
fixture is the evidence.

**Coercions are written.** `choose(n, k)` is a `Nat` being multiplied into `R`, and Mathlib
would insert `↑` semi-silently. F9 rules the opposite: `expr as T` elaborates to
`(↑expr : T)` and nothing else coerces. F10 keeps ascription separate — `(e: T)` is an
elaboration hint that inserts no coercion, which Mathlib proofs need constantly.

* **Stage: one.**
* **Ruling D:** `as` is *confined* (Rust's primitive cast has no meaning to preserve here);
  the rest is design §3's spine.
* **Sorry count: zero.**

## The corpus finding: the corpus's proof does not close its own statement

`lean! { exact Commute.add_pow (Commute.all x y) n }` is the right lemma and the wrong
shape. Mathlib states the sum as `x ^ m * y ^ (n - m) * ↑(n.choose m)`; the corpus writes
the binomial coefficient first, `↑(n.choose k) * x ^ k * y ^ (n - k)`. Both are the
binomial theorem, and in a commutative ring they are equal — but `exact` does not reorder
factors.

The statement is the corpus's, unchanged, because that is the thing under test. The proof
gains two lines: rewrite by Mathlib's form, then `ring` under the sum. Worth recording as
the ordinary shape of porting work — the FH translation was exact and the *proof* needed
adjusting, which is the failure mode a corpus port should have.
-/

section
use lean::Pow;

/-! ## The corpus, as it elaborates -/

theorem binomial<R>(x: R, y: R, n: Nat)
    -> (x + y).pow(n)
        == Finset::range(n + 1).sum(|k| (Nat::choose(n, k) as R) * x.pow(k) * y.pow(n - k))
where R: CommRing
{
    lean! {
      rw [Commute.add_pow (Commute.all x y) n]
      exact Finset.sum_congr rfl fun k _ => by ring
    }
}

/-! ## Tier 1 — golden expansion

The whole statement. `Finset.sum` with a `fun`, `HPow.hPow` from the F16 spelling, and
exactly one `↑` — the one the author wrote.
-/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem binom_g {R : Type _} [CommRing R] (x : R) (y : R) (n : Nat) :
    Eq (HPow.hPow (HAdd.hAdd x y) n)
      ((Finset.range (HAdd.hAdd n 1)).sum fun k =>
        HMul.hMul (HMul.hMul ((↑(Nat.choose n k) : R)) (HPow.hPow x k)) (HPow.hPow y (HSub.hSub n k))) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem binom_g<R>(x: R, y: R, n: Nat)
    -> (x + y).pow(n)
        == Finset::range(n + 1).sum(|k| (Nat::choose(n, k) as R) * x.pow(k) * y.pow(n - k))
where R: CommRing
{ todo!() }

/-! F9 and F10 side by side, which is the distinction the review insists on: `as` inserts
the arrow, `(e: T)` does not. -/

/-- info: set_option autoImplicit false in def coerced {R : Type _} [CommRing R] (n : Nat) : R := (↑n : R) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn coerced<R>(n: Nat) -> R where R: CommRing { n as R }

/-- info: set_option autoImplicit false in def ascribed (n : Nat) : Nat := (n : Nat) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn ascribed(n: Nat) -> Nat { (n: Nat) }

/-! ## Tier 2 — elaboration -/

/--
info: theorem binomial.{u_1} : ∀ {R : Type u_1} [inst : CommRing R] (x y : R) (n : ℕ),
  (x + y) ^ n = ∑ k ∈ Finset.range (n + 1), ↑(n.choose k) * x ^ k * y ^ (n - k)
-/
#guard_msgs in
#print sig binomial

/-- info: 'binomial' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms binomial

/-! The `∑` in that signature is Mathlib's own notation for what FH wrote as a method call
— which is the point: no syntax was added, and the pretty-printer shows the reader the
notation they know. -/

example : ∀ x y : ℤ, (x + y) ^ 2 = 1 * x ^ 2 + 2 * x * y + 1 * y ^ 2 := by
  intro x y; ring

example (x y : ℤ) : (x + y) ^ 3 = ∑ k ∈ Finset.range 4, (Nat.choose 3 k : ℤ) * x ^ k * y ^ (3 - k) :=
  binomial x y 3

/-! ## Tier 3 — negative

F9's promise, enforced. FH's operator expansion emits `HMul.hMul` directly rather than
going through Lean's `binop%` elaborator, so there is no unification-driven coercion to
insert — a `Nat` times an `R` simply has no instance, and the fix is to write the `as`.
That is `coercion-control.md`'s mechanism doing its job at the point of use.
-/

/--
error: failed to synthesize instance of type class
  HMul ℕ R ?m.3

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs (whitespace := lax) in
fn silent<R>(n: Nat, x: R) -> R where R: CommRing { n * x }

/-! Written, it works — and the difference between the two is one `as`. -/

fn written<R>(n: Nat, x: R) -> R where R: CommRing { (n as R) * x }

/-- info: 'written' does not depend on any axioms -/
#guard_msgs in
#print axioms written

/-! ## Tier 4 — span -/

/-- info: error @ +0:53-58 «n * x» -/
#guard_msgs in
#fh_spans in
fn silent2<R>(n: Nat, x: R) -> R where R: CommRing { n * x }

end
