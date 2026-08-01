/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · anonymous constructors (Ruling C item two)

Rust tuple syntax is Lean's anonymous constructor: `(a, b)` is `⟨a, b⟩`, and what it
*constructs* comes from the expected type — a `Prod`, an `Exists` witness, a `Subtype`'s
value-and-proof pair, any structure. Design §4.7 adopts that wholesale, and Ruling C item
two sanctions the implicitness because Rust already trained the intuition.

* **Stage: one.** The election is Lean's, which is the point: FH emits `⟨…⟩` and Lean's
  elaborator decides, so there is nothing here to keep in step with Mathlib.
* **Ruling D:** *extension*. `(a, b)` is legal Rust and means a tuple; here it means a
  tuple **or** whatever else is expected, which is strictly more. Nothing that is legal
  Rust changes meaning — a `Prod` is what you get when a tuple is what is expected.
* **Sorry count: zero.**
* **Escape:** name the constructor, as Ruling C requires.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in def pair : Prod Nat Nat := ⟨1, 2⟩ -/
#guard_msgs (whitespace := lax) in
#fh_expand fn pair() -> Prod<Nat, Nat> { (1, 2) }

/-! Nesting is Lean's too: `⟨1, 2, 3⟩` fills a right-nested pair without FH deciding
anything. -/

/-- info: set_option autoImplicit false in def triple : Prod Nat (Prod Nat Nat) := ⟨1, 2, 3⟩ -/
#guard_msgs (whitespace := lax) in
#fh_expand fn triple() -> Prod<Nat, Prod<Nat, Nat> > { (1, 2, 3) }

/-! One element is the parenthesised expression, not a one-tuple — same as Rust. -/

/-- info: set_option autoImplicit false in def parens : Nat := (1) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn parens() -> Nat { (1) }

/-! ## Tier 2 — elaboration

The same syntax, three expected types, three different constructors.
-/

fn pair() -> Prod<Nat, Nat> { (1, 2) }

example : pair = (1, 2) := rfl

/-! An `Exists` witness — the pair a `for<>`/`exists<>` proof needs (design §4.2's
"anonymous-constructor bridge provides `(w, h)` introduction"). -/

theorem exists_zero() -> exists<n: Nat> n == 0 { (0, lean! { rfl }) }

/-- info: 'exists_zero' does not depend on any axioms -/
#guard_msgs in
#print axioms exists_zero

/-! A `Subtype`'s value-and-proof pair, which is what corpus Group 12's `nat_sqrt` returns
once F13's comprehension braces land. -/

fn is_small(n: Nat) -> Prop { (n < 5) }

fn small() -> Subtype<is_small> { (0, lean! { unfold is_small; decide }) }

/-- info: 'small' does not depend on any axioms -/
#guard_msgs in
#print axioms small

/-! And the escape: naming the constructor says exactly which one, with no election. -/

fn named_pair() -> Prod<Nat, Nat> { Prod::mk(1, 2) }

example : named_pair = pair := rfl

/-! ## Tier 3 — negative

With nothing to elect from, the anonymous constructor has no meaning — Lean's own error,
since Lean is what does the electing.
-/

/--
error: Invalid `⟨...⟩` notation: The expected type `Nat → Nat` is not an inductive type

Note: This notation can only be used when the expected type is an inductive type with a single constructor
-/
#guard_msgs in
fn no_expectation() -> Nat -> Nat { (1, 2) }

/-! ## Tier 4 — span -/

/-- info: error @ +0:37-43 «(1, 2)» -/
#guard_msgs in
#fh_spans in
fn no_expectation2() -> Nat -> Nat { (1, 2) }
