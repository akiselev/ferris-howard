/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 7 — number theory, and the flagship bound

`corpus-review.md` Group 7, made executable. The review calls it "our home turf", and it
is where three separate pieces of the design meet in three theorems: the `Fact` bridge
(design §6), generalized dot notation on a Prop-valued family (F16, design §6's
no-mangling policy), and named arguments (F11).

* **Stage: one.**
* **Ruling D:** *confined* — `where P: Prime` constrains a value, which Rust's `where`
  cannot do, so there is no Rust reading to preserve. F11 is an *extension*.
* **Sorry count: one, and it is the corpus's** — Group 7's text writes `todo!()` for
  `crt`. The other two are proved.

## `where P: Prime`, and why it is the flagship

```rust
theorem fermat_little<P: Nat>(a: Fp<P>) -> a.pow(P) == a where P: Prime
```

elaborates to

```lean
∀ {P : ℕ} [Fact (Nat.Prime P)] (a : ZMod P), a ^ P = a
```

Three things had to line up. `<P: Nat>` binds a **value**, not a type — FH's angle-bracket
generics are implicit binders over values as well as types (design §4.1), which is why the
corpus notes there is no `const` marker to add: Rust needs one, FH does not. `Fp<P>` is
`ZMod P` through the object bridge. And `where P: Prime` becomes `[Fact (Nat.Prime P)]`,
which is not what it says — instance search cannot look inside a proposition, so Mathlib
wraps it — and the translation living in a scoped bridge rather than in the reader's head
is the point.

## `p.Prime` needs nothing

Generalized dot notation reaches `Nat.Prime p` from `p : Nat` on its own, and it is
*case-sensitive*: the spelling is `p.Prime`, never `p.prime`. FH inherits both facts
rather than mangling names, per design §6.

## The corpus finding: `.pow()` needed a bridge

`a.pow(P)` did not resolve. Rust's `^` is exclusive-or, so exponentiation has no operator
to borrow and the ASCII method spelling is exactly what F16 is for — but there is no
carrier method either, because `Fp<P>`'s carrier is a `match` on `P` and has no namespace
at all. So `pow` joined `dvd`, `comp` and `abs` in the method bridge, and this file writes
`use lean::Pow;`.
-/

section
use lean::Fp;
use lean::Prime;
use lean::Pow;

/-! ## The corpus, as it elaborates -/

theorem fermat_little<P: Nat>(a: Fp<P>) -> a.pow(P) == a
where P: Prime
{
    lean! { exact ZMod.pow_card a }
}

theorem primes_infinite() -> for<n: Nat> exists<p: Nat> (p > n) && p.Prime {
    lean! { exact fun n => (Nat.exists_infinite_primes (n + 1)).imp fun _ h => ⟨h.1, h.2⟩ }
}

fn congruent(x: Nat, a: Nat, modulus: Nat) -> Prop { x % modulus == a % modulus }

fn coprime(m: Nat, n: Nat) -> Prop { Nat::gcd(m, n) == 1 }

/--
warning: declaration uses `sorry`
---
info: FH todo
-/
#guard_msgs in
theorem crt(a: Nat, b: Nat, m: Nat, n: Nat, h: coprime(m, n))
    -> exists<x: Nat> congruent(x, a, modulus: m) && congruent(x, b, modulus: n)
{
    todo!()
}

/-! ## Tier 1 — golden expansion

The value-generic, the object alias and the bound bridge, in one signature.
-/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem fermat_g {P : Nat} [Fact (Nat.Prime P)] (a : ZMod P) : Eq (HPow.hPow a P) a :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem fermat_g<P: Nat>(a: Fp<P>) -> a.pow(P) == a where P: Prime { todo!() }

/-! `p.Prime` passes through untouched — it is Lean's dot notation and FH has nothing to
add. -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem primes_g : ∀ (n : Nat), ∃ (p : Nat), And (GT.gt p n) p.Prime :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem primes_g() -> for<n: Nat> exists<p: Nat> (p > n) && p.Prime { todo!() }

/-! F11: the named argument becomes Lean's. -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem crt_g (a : Nat) (m : Nat) : ∃ (x : Nat), congruent x a (modulus := m) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem crt_g(a: Nat, m: Nat) -> exists<x: Nat> congruent(x, a, modulus: m) { todo!() }

/-! ## Tier 2 — elaboration

The three statements, which are the corpus's word for word.
-/

/--
info: theorem fermat_little : ∀ {P : ℕ} [inst : Fact (Nat.Prime P)] (a : ZMod P), a ^ P = a
-/
#guard_msgs in
#print sig fermat_little

/-- info: 'fermat_little' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms fermat_little

/-- info: theorem primes_infinite : ∀ (n : ℕ), ∃ p > n, Nat.Prime p -/
#guard_msgs in
#print sig primes_infinite

/-- info: 'primes_infinite' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms primes_infinite

/--
info: theorem crt : ∀ (a b m n : ℕ), coprime m n → ∃ x, congruent x a m ∧ congruent x b n
-/
#guard_msgs in
#print sig crt

/-- info: 'crt' depends on axioms: [sorryAx] -/
#guard_msgs in
#print axioms crt

/-! Fermat's little theorem is not vacuous — here it is at `P = 5`. -/

example : ∀ a : ZMod 5, a ^ 5 = a := by
  haveI : Fact (Nat.Prime 5) := ⟨by norm_num⟩
  exact fun a => fermat_little a

/-! ## Tier 3 — negative

Drop `where P: Prime` and the theorem is false, so Mathlib's lemma is unavailable — the
bound is load-bearing rather than decorative, which is the claim this fixture is making.
-/

/--
error: failed to synthesize instance of type class
  Fact (Nat.Prime P)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs (whitespace := lax) in
theorem fermat_unbounded<P: Nat>(a: Fp<P>) -> a.pow(P) == a {
    lean! { exact ZMod.pow_card a }
}

/-! And the spelling is case-sensitive, inherited from Lean: `p.prime` is not `p.Prime`. -/

/--
error: Invalid field `prime`: The environment does not contain `Nat.prime`, so it is not possible to project the field `prime` from an expression
  p
of type `ℕ`
-/
#guard_msgs (whitespace := lax) in
fn lowercase(p: Nat) -> Prop { p.prime }

/-! ## Tier 4 — span -/

/--
info: warning @ +0:8-10 «sp»
info @ +0:63-70 «todo!()»
-/
#guard_msgs in
#fh_spans in
theorem sp<P: Nat>(a: Fp<P>) -> a.pow(P) == a where P: Prime { todo!() }

end
