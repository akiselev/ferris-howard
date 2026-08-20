/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · `if`, decidability, and hypothesis binding (A2.1: F14, F15)

`if cond { a } else { b }` is Lean's `if`. Because Ruling A makes `a <= b` a *Prop*, that
is the **decidable** `if` — F14, "the price of Prop-first, paid here". For `Nat`, `Real`
classically, and everything Mathlib-standard the instances exist and the code reads
exactly like Rust; for an exotic Prop it does not, and that is the correct semantics
rather than a limitation, since it is where the classical/computable distinction genuinely
lives.

`if h @ (cond) { … } else { … }` binds the hypothesis (F15), reusing Rust's `@`
pattern-binding: `h : cond` in one branch, `h : ¬cond` in the other.

* **Stage: one.**
* **Ruling D:** `if` on a Prop condition is a consequence of Ruling A, the one sanctioned
  violation. `if h @ (…)` is an *extension* — ill-formed Rust made meaningful.
* **Sorry count: zero.**

## No brace restriction, and why

Rust forbids struct literals in an `if` condition because they are postfix: `if x Foo {}`
would be ambiguous. FH's braces — the const-generic escape `{n*2}` and F13's comprehension
— can only *start* an expression, never extend one, so a condition that has already parsed
cannot swallow the block. The restriction Rust needs is not needed here, and the parser
says so: no `withForbidden`, no lookahead.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in def min2 (a : Nat) (b : Nat) : Nat := if LE.le a b then a else b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn min2(a: Nat, b: Nat) -> Nat { if a <= b { a } else { b } }

/-- info: set_option autoImplicit false in def guarded (a : Nat) (b : Nat) : Nat := if h : (LE.le a b) then a else b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn guarded(a: Nat, b: Nat) -> Nat { if h @ (a <= b) { a } else { b } }

/-! ## Tier 2 — elaboration

Corpus Group 11's `min2`, unchanged from the corpus text.
-/

fn min2(a: Nat, b: Nat) -> Nat { if a <= b { a } else { b } }

example : min2 2 5 = 2 := rfl
example : min2 5 2 = 2 := rfl

/-- info: 'min2' does not depend on any axioms -/
#guard_msgs in
#print axioms min2

/-! A branch that does not mention the hypothesis leaves it unused, and Lean says so — its
own linter, inherited, and the answer is Lean's too: name it `_h`. -/

fn safe_sub(a: Nat, b: Nat) -> Nat { if _h @ (b <= a) { Nat::sub(a, b) } else { 0 } }

example : safe_sub 5 2 = 3 := rfl
example : safe_sub 2 5 = 0 := rfl

/-! Where F15 earns its keep is a branch that *needs* the proof. Here the hypothesis
discharges a subtype's obligation directly — F15 and the anonymous constructor together,
which is how corpus Group 12's `nat_sqrt` will read. -/

fn at_most(a: Nat, x: Nat) -> Prop { x <= a }

fn clamp(a: Nat, b: Nat) -> Subtype<at_most(a)> {
  if h @ (b <= a) { (b, h) } else { (a, lean! { unfold at_most; omega }) }
}

example : (clamp 5 2).val = 2 := rfl
example : (clamp 2 5).val = 2 := rfl

fn checked_sub(a: Nat, b: Nat) -> Nat {
  if _h @ (b <= a) { Nat::sub(a, b) } else { 0 }
}

theorem checked_sub_le(a: Nat, b: Nat) -> checked_sub(a, b) <= a {
  lean! {
    unfold checked_sub
    split
    · exact Nat.sub_le a b
    · exact Nat.zero_le a
  }
}

/-- info: 'checked_sub_le' does not depend on any axioms -/
#guard_msgs in
#print axioms checked_sub_le

/-! ## Tier 3 — negative

F14's cost, and the corpus says to pin it: an exotic Prop has no `Decidable` instance and
Lean says so in its own words. The *friendly* wording — "no Decidable instance" — belongs
to `fh check`'s error taxonomy (C1 v1), which is where agents read errors; stage one
cannot reword a message it never sees (the landed §9.3 amendment).
-/

/--
error: failed to synthesize instance of type class
  Decidable (f = g)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
fn undecidable(f: Nat -> Nat, g: Nat -> Nat) -> Nat { if Eq(f, g) { 1 } else { 0 } }

/-! Where a genuine `Bool` is wanted, `decide` converts explicitly — F5's companion, and
no syntax of its own, because it is a call. -/

fn as_bool(a: Nat, b: Nat) -> Bool { decide(a <= b) }

example : as_bool 2 5 = true := rfl

/-! ## Tier 4 — span

The report covers the whole `if`, since it is the `if` that needs the instance — the
condition is a perfectly good `Prop` on its own.
-/

/-- info: error @ +0:55-83 «if Eq(f, g) { 1 } else { 0 }» -/
#guard_msgs in
#fh_spans in
fn undecidable2(f: Nat -> Nat, g: Nat -> Nat) -> Nat { if Eq(f, g) { 1 } else { 0 } }
