/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · `?` as monadic bind (A2.3, design §4.7)

Rust's `?` *is* monadic bind, and the mapping is the one design §4.7 calls delightful: a
block containing `?` elaborates as a `do` block, `let x = f()?;` becomes `let x ← f`, and
a plain `let` stays pure. The monad comes from the block's expected type, which a declared
return type always supplies — Ruling C item three, escape: ascribe.

* **Stage: one.**
* **Ruling D:** *extension*. Rust's `?` works on `Result`/`Option` by trait; FH's works in
  any monad, which is strictly more, and nothing legal in Rust changes meaning.
* **Sorry count: zero.**

The plan asks for four monads, because the value of this test is confirming `?` behaves
*identically* across them rather than that it works once.

## Two restrictions, both deliberate

`?` goes at the end of a `let` value. Rust allows `f(g()?)`; expressing that here means
naming the intermediate, and refusing beats inventing a binding the author did not write.

And there is no silent return-lift: the tail is whatever the block ends with, which is why
Group 10 writes `PMF::pure(…)` explicitly. Ruling C's list is closed, and this is not on
it.

`?` can only follow a delimiter — `f()?`, `(e)?` — because Lean's lexer takes `x?` as a
single identifier. A0.6 recorded that; every use in Group 10 is written that way anyway.
-/

/-! ## Tier 1 — golden expansion

`let … ?` becomes `let … ←`, a plain `let` becomes `let … :=`, and the tail is left alone.
-/

/--
info: set_option autoImplicit false in
def pair_option (a : Nat) (b : Nat) : Option Nat := do
  let x ← Option.some a
  let doubled := Nat.add x x
  let y ← Option.some b
  Option.some (Nat.add doubled y)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn pair_option(a: Nat, b: Nat) -> Option<Nat> {
  let x = Option::some(a)?;
  let doubled = Nat::add(x, x);
  let y = Option::some(b)?;
  Option::some(Nat::add(doubled, y))
}

/-! ## Tier 2 — elaboration: the same block, four monads

Identical shape each time. That is the property under test.
-/

fn opt(a: Nat, b: Nat) -> Option<Nat> {
  let x = Option::some(a)?;
  let y = Option::some(b)?;
  Option::some(Nat::add(x, y))
}

example : opt 2 3 = some 5 := rfl
example : (do let x ← none; opt x 3) = (none : Option Nat) := rfl

fn exc(a: Nat, b: Nat) -> Except<String, Nat> {
  let x = Except::ok(a)?;
  let y = Except::ok(b)?;
  Except::ok(Nat::add(x, y))
}

example : exc 2 3 = Except.ok 5 := rfl

fn stateful(a: Nat) -> StateM<Nat, Nat> {
  let s = StateT::get()?;
  let _u = StateT::set(Nat::add(s, a))?;
  Pure::pure(s)
}

example : (stateful 3).run 10 = (10, 13) := rfl

/-! The fourth is corpus Group 10's monad, chosen there to prove the point that `?` is not
a `Result` feature.

**Corpus finding:** Group 10 writes `PMF::bernoulli(half)`, and `PMF.bernoulli` is
*deprecated* on this toolchain in favour of `ProbabilityTheory.bernoulliMeasure`, which has
a different type and is not a `PMF`. The group's `?` content survives the substitution —
what is under test is the bind, not the distribution — but the corpus text needs a pass
when Group 10 gets its own fixture. -/

#[noncomputable]
fn two_flips() -> PMF<Bool> {
  let x = PMF::pure(true)?;
  let y = PMF::pure(false)?;
  Pure::pure(Bool::xor(x, y))
}

/-- info: 'two_flips' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms two_flips

/-! ## Tier 3 — negative

A `?` that is not at the end of a `let` value is refused, with the fix named.
-/

/--
error: FH: one `?` per `let`, at the end of the value
-/
#guard_msgs in
fn nested(a: Nat) -> Option<Nat> {
  let x = Option::some(Option::some(a)?)?;
  Option::some(x)
}

/-! And the tail is the block's result, not a bind. -/

/--
error: FH: `?` belongs at the end of a `let` value — a tail expression is the block's result, and Group 10 writes its `pure` explicitly
-/
#guard_msgs in
fn tail_try(a: Nat) -> Option<Nat> {
  let x = Option::some(a)?;
  Option::some(x)?
}

/-! ## Tier 4 — span -/

/-- info: error @ +1:10-41 «Option::some(Option::some(a)?)?» -/
#guard_msgs in
#fh_spans in
fn nested2(a: Nat) -> Option<Nat> {
  let x = Option::some(Option::some(a)?)?;
  Option::some(x)
}
