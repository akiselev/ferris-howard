/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · mutual and nested inductives (A2.2, design §4.5)

`mutual { … }` maps to Lean's `mutual … end`: declarations that refer to one another.
Nested inductives — a constructor whose field mentions the type being defined under
another type constructor — need no syntax at all, because Lean supports them and FH's
`enum` already reaches them.

* **Stage: one.**
* **Ruling D:** *extension*. Rust has no `mutual` block; its enums may already refer to
  one another because Rust has no positivity or termination story to protect.
* **Sorry count: zero.**

## One wrinkle worth stating

Lean rejects `set_option … in` inside a `mutual` block — "either all elements of the block
must be inductive/structure declarations, or they must all be definitions" — and FH puts
`set_option autoImplicit false in` on every declaration it generates. So the block strips
those wrappers off its members and carries the options itself, which the golden below
shows: one `set_option` outside, bare `inductive`s within.
-/

/-! ## Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
mutual
  inductive Even where
    | Zero : Even
    | SuccOdd (pred : Odd) : Even
  inductive Odd where
    | SuccEven (pred : Even) : Odd
end
-/
#guard_msgs (whitespace := lax) in
#fh_expand mutual {
  enum Even { Zero, SuccOdd(pred: Odd) }
  enum Odd { SuccEven(pred: Even) }
}

/-! ## Tier 2 — elaboration

Each declaration sees the other, which is the point of the block.
-/

mutual {
  enum Even { Zero, SuccOdd(pred: Odd) }
  enum Odd { SuccEven(pred: Even) }
}

/-- info: inductive Even : Type -/
#guard_msgs (whitespace := lax, substring := true) in
#print Even

example : Even := .SuccOdd (.SuccEven .Zero)

/-! A **nested** inductive needs nothing new: `Tree` appears under `List` in its own
constructor, and Lean's nested-inductive support does the rest. -/

enum Tree { Node(children: List<Tree>) }

example : Tree := .Node [.Node []]

/-- info: 'Tree' does not depend on any axioms -/
#guard_msgs in
#print axioms Tree

/-! Mutual *definitions* work the same way — the block is about the declarations, not
about which kind they are. -/

mutual {
  fn is_even(n: Nat) -> Bool { match n { 0 => true, Nat::succ(m) => is_odd(m) } }
  fn is_odd(n: Nat) -> Bool { match n { 0 => false, Nat::succ(m) => is_even(m) } }
}

example : is_even 4 = true := rfl
example : is_odd 4 = false := rfl

/-! ## Tier 3 — negative

Lean's own rule: a block is all types or all definitions, never both.
-/

/--
error: invalid mutual block: either all elements of the block must be inductive/structure declarations, or they must all be definitions/theorems/abbrevs
-/
#guard_msgs in
mutual {
  enum Colour { Red, Green }
  fn pick() -> Colour { Colour::Red }
}

/-! Attributes belong on the declarations, not on the block — FH says so rather than
grafting them onto something that is not a declaration. -/

/--
error: FH: attributes belong on the declarations inside a `mutual`, not on the block
-/
#guard_msgs in
#[simp] mutual { enum A1 { X } }

/-! ## Tier 4 — span -/

/-- info: error @ +0:8-32 «mutual { enum A2 { X } }» -/
#guard_msgs in
#fh_spans in
#[simp] mutual { enum A2 { X } }
