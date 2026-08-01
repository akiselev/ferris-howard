/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · the operator set and the F7 matrix (A1.5)

Ruling A: every operator has one meaning, everywhere. Ruling B: the F7 precedence table is
normative and frozen pre-M1. This fixture is that table, as goldens — the plan calls for
the matrix to be exhaustive, because a precedence change after users exist is the worst
kind of breaking change and a golden is what makes one visible.

* **Stage: one.**
* **Ruling D:** the operator reassignment is *the* sanctioned violation, the one entry
  under "The headline" in `differences.md`. `in` outside a loop header is an extension.
* **Sorry count: zero.**

## Why the expansions read `Eq a b` and not `a = b`

Lean's `=`, `≤`, `∧` notations are `binop%`/`binrel%` macros that insert coercions while
unifying. FH expands to the underlying constants instead, which is how I6 disables silent
coercion without wrapping every FH term in a stage-two elaborator
(`coercion-control.md`). It costs golden readability and buys the property that a coercion
in FH-authored code is one its author wrote.
-/

abbrev NatList := List Nat

/-! ## Tier 1 — the F7 matrix

Loosest to tightest: `->`, `<->`, `||`, `&&`, `!`, comparisons, `+ -`, `* / %`, unary `-`,
then the postfix chain. Each row below pins one adjacency in that table.
-/

/-- info: set_option autoImplicit false in def m1 (a : Prop) (b : Prop) (c : Prop) : Prop := a → b → c -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m1(a: Prop, b: Prop, c: Prop) -> Prop { a -> b -> c }

/-- info: set_option autoImplicit false in def m2 (a : Prop) (b : Prop) (c : Prop) : Prop := Iff a b → c -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m2(a: Prop, b: Prop, c: Prop) -> Prop { a <-> b -> c }

/-- info: set_option autoImplicit false in def m3 (a : Prop) (b : Prop) (c : Prop) : Prop := Iff (Or a b) c -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m3(a: Prop, b: Prop, c: Prop) -> Prop { a || b <-> c }

/-- info: set_option autoImplicit false in def m4 (a : Prop) (b : Prop) (c : Prop) : Prop := Or (And a b) c -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m4(a: Prop, b: Prop, c: Prop) -> Prop { a && b || c }

/-- info: set_option autoImplicit false in def m5 (a : Prop) (b : Prop) : Prop := And (Not a) b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m5(a: Prop, b: Prop) -> Prop { !a && b }

/-! The inversion worth reading twice: `!` binds *looser* than the comparisons, so
`!a == b` is `¬(a = b)` — the mathematical reading, and the opposite of Rust's table. -/

/-- info: set_option autoImplicit false in def m6 (a : Nat) (b : Nat) : Prop := Not (Eq a b) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m6(a: Nat, b: Nat) -> Prop { !a == b }

/-- info: set_option autoImplicit false in def m7 (a : Nat) (b : Nat) (c : Nat) : Prop := Eq (HAdd.hAdd a b) c -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m7(a: Nat, b: Nat, c: Nat) -> Prop { a + b == c }

/-- info: set_option autoImplicit false in def m8 (a : Nat) (b : Nat) (c : Nat) : Nat := HAdd.hAdd a (HMul.hMul b c) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m8(a: Nat, b: Nat, c: Nat) -> Nat { a + b * c }

/-- info: set_option autoImplicit false in def m9 (a : Int) (b : Int) : Int := HMul.hMul (Neg.neg a) b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m9(a: Int, b: Int) -> Int { -a * b }

/-- info: set_option autoImplicit false in def m10 (a : Nat) (b : Nat) (c : Nat) : Nat := HSub.hSub (HSub.hSub a b) c -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m10(a: Nat, b: Nat, c: Nat) -> Nat { a - b - c }

/-! `in` sits in the comparison band, so `x in s && y in t` groups the way a reader
expects. `Membership.mem` takes the container first — the operand order flips in the
expansion, which is exactly the sort of thing a golden should be showing. -/

/-- info: set_option autoImplicit false in def m11 (x : Nat) (s : NatList) : Prop := Membership.mem s x -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m11(x: Nat, s: NatList) -> Prop { x in s }

/-- info: set_option autoImplicit false in def m12 (x : Nat) (s : NatList) (t : NatList) : Prop := And (Membership.mem s x) (Membership.mem t x) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn m12(x: Nat, s: NatList, t: NatList) -> Prop { x in s && x in t }

/-! ## Tier 2 — elaboration

The operators mean what Ruling A says: these are proofs, not evaluations.
-/

fn implies_trans(a: Nat, b: Nat, c: Nat) -> Prop { a == b -> b == c -> a == c }
fn distinct(a: Nat, b: Nat) -> Prop { !a == b }
fn between(a: Nat, b: Nat, c: Nat) -> Prop { (a < b) && (b < c) }
fn member(x: Nat, s: NatList) -> Prop { x in s }

theorem implies_trans_holds(a: Nat, b: Nat, c: Nat) -> implies_trans(a, b, c) {
  lean! { intro h1 h2; exact h1.trans h2 }
}

theorem one_ne_two() -> distinct(1, 2) { lean! { unfold distinct; decide } }

theorem zero_in(s: NatList) -> member(0, List::cons(0, s)) {
  lean! { exact List.mem_cons_self }
}

/-- info: 'implies_trans_holds' does not depend on any axioms -/
#guard_msgs in
#print axioms implies_trans_holds

/-! ## `!` on a `Bool`, pinned rather than fixed

The deferred-decisions ledger wants `!` on a `Bool` to be a hard error, forcing `.bnot()`.
It currently is not — and the reason is worth seeing, because it is F9 in miniature:

Lean coerces `b : Bool` to the Prop `b = true`, applies `¬`, then coerces *back* with
`decide` to meet the declared `Bool`. Two silent coercions, no diagnostic, and a
`decide ¬b = true` where the author wrote `!b`.

Stage one cannot catch this: `!` expands before any type is known. But I6's audit does,
exactly and without a bespoke check — both insertions go through `mkCoe`, neither has a
syntax ref inside an `as` node, so both are unlicensed (`coercion-control.md`). The ledger
item therefore resolves as "A2.0 delivers it", and the golden below is what changes when
it does.
-/

/-- info: set_option autoImplicit false in def bool_not (b : Bool) : Bool := Not b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn bool_not(b: Bool) -> Bool { !b }

fn bool_not(b: Bool) -> Bool { !b }

/-- info: def bool_not : Bool → Bool := fun b => decide ¬b = true -/
#guard_msgs (whitespace := lax) in
#print bool_not

/-! ## Tier 3 — negative

Non-associativity by decree (F7 as amended): chained comparison, chained iff, and chained
`in` are parse errors. They are *parse* errors, so `#fh_parse` is the instrument
(`#guard_msgs` cannot see them). The wording is Lean's own and is not friendly; the
friendly version belongs in `fh check`'s taxonomy (C1), which is where agents read errors.
-/

/-- info: does not parse: <input>:1:46: expected '}' -/
#guard_msgs in
#fh_parse "fn c1(a: Nat, b: Nat, c: Nat) -> Prop { a < b < c }"

/-- info: does not parse: <input>:1:51: expected '}' -/
#guard_msgs in
#fh_parse "fn c2(p: Prop, q: Prop, r: Prop) -> Prop { p <-> q <-> r }"

/-- info: does not parse: <input>:1:55: expected '}' -/
#guard_msgs in
#fh_parse "fn c3(x: Nat, s: NatList, t: NatList) -> Prop { x in s in t }"

/-- info: parses -/
#guard_msgs in
#fh_parse "fn ok(a: Nat, b: Nat, c: Nat) -> Prop { (a < b) && (b < c) }"

/-! And a mismatch inside an operand is Lean's own type error, unchanged. -/

/--
error: Application type mismatch: The argument
  b
has type
  Bool
but is expected to have type
  Nat
in the application
  a = b
-/
#guard_msgs in
fn mixed(a: Nat, b: Bool) -> Prop { a == b }

/-! ## Tier 4 — span

The diagnostic lands on the offending *operand*, not on the whole expression.
-/

/-- info: error @ +0:42-43 «b» -/
#guard_msgs in
#fh_spans in
fn mixed2(a: Nat, b: Bool) -> Prop { a == b }
