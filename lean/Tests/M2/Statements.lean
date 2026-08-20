/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · imperative statements (A2.3, design §4.7 and §5)

Design §4.7: "`for`/`while`/`if` inside such blocks map to Lean's do-notation control
flow, which was itself designed to imperative-language expectations." And §5, on what FH
drops: "`mut` (no mutation outside do-notation's `let mut`, which Lean's do-notation
supports natively and we map directly)".

So there is no new semantics here at all. Each statement is one of Lean's own `doElem`s,
reached by the spelling a Rust programmer would use, and the work is entirely in deciding
*when* a block is a `do` block and *which monad* it runs in.

* **Stage: one.**
* **Ruling D:** *confined* — the spellings are Rust's and the meanings are Rust's.
* **Sorry count: zero.** Axioms are not zero for `while`; see the note below, which is
  exactly the kind of thing the axiom discipline exists to surface.

## Which monad — the rule, and why it is decidable at stage one

`?` **is** Rust's monadic operator. So:

* a block containing `?` runs in the return type's monad → plain `do`;
* a block with statements but no `?` is pure imperative code → `Id.run do`, which is how
  Lean writes exactly that.

The distinction is Rust's own, not an invention, and it is a syntactic property — which
matters, because the alternative (elaborate against the expected type and see whether it
is a monad) is stage two, and ADR-006 makes stage one load-bearing. `Id.run` is an
ordinary Lean constant, so the emitted artifact needs no FH prelude.

## The continuation is optional

`for i in xs { acc = acc + i; }` — the trailing `;` with nothing after it is Rust's way of
saying the block has no value, and it is what every loop body looks like. A `fn` body that
ends this way has no value either, and Lean says so.

## `break`, `continue` and `return` are tails

They end the block they are in, so there is nothing to continue with. `if found { return x
} rest` is the shape that wants this, and it works because the `if` supplies the
continuation.

## Two restrictions

Assignment's left side is an identifier. Rust also assigns through a field or an index
(`p.x = e`, `v[i] = e`); both are on the differences page, and the meanwhile-form is to
rebuild — `p = Point{ x: e, ..p };`, which the structure-literal fixture covers.

And conditions are **Props**, per Ruling A: `while (0 < i)`, not `while Nat::blt(0, i)`.
A `Bool` condition is a coercion site and A2.0's audit says so — which is the F9 promise
working, not a limitation. (The parentheses are F6's rule for a bare `<`.)
-/

/-! ## Tier 1 — golden expansion

The accumulator loop, which is the shape all of this exists for.
-/

/--
info: set_option autoImplicit false in
def sum_to (n : Nat) : Nat :=
  Id.run do
    let mut acc := 0
    for i in List.range n do
      acc := HAdd.hAdd acc i
    acc
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn sum_to(n: Nat) -> Nat {
  let mut acc = 0;
  for i in List::range(n) { acc = acc + i; }
  acc
}

/-! `while` and multiple statements in one body. -/

/--
info: set_option autoImplicit false in
def count_down (n : Nat) : Nat :=
  Id.run do
    let mut i := n
    let mut steps := 0
    while (LT.lt 0 i) do
      i := HSub.hSub i 1
      steps := HAdd.hAdd steps 1
    steps
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn count_down(n: Nat) -> Nat {
  let mut i = n;
  let mut steps = 0;
  while (0 < i) { i = i - 1; steps = steps + 1; }
  steps
}

/-! The statement `if` — no `else`, and a `return` tail inside it. Note the monad: the
return type is `Option<Nat>` but there is no `?`, so this is pure imperative code that
happens to produce an `Option`, and `Id.run` is right. -/

/--
info: set_option autoImplicit false in
def first_even (xs : List Nat) : Option Nat :=
  Id.run
    (do
      for x in xs do
        if Eq (HMod.hMod x 2) 0 then
          return Option.some x
      Option.none)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn first_even(xs: List<Nat>) -> Option<Nat> {
  for x in xs { if x % 2 == 0 { return Option::some(x) } }
  Option::none
}

/-! And `break`. -/

/--
info: set_option autoImplicit false in
def upto (n : Nat) : Nat :=
  Id.run do
    let mut acc := 0
    for i in List.range n do
      if Eq i 3 then
        break
      acc := HAdd.hAdd acc i
    acc
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn upto(n: Nat) -> Nat {
  let mut acc = 0;
  for i in List::range(n) {
    if i == 3 { break }
    acc = acc + i;
  }
  acc
}

/-! Now the other side of the monad rule: the *same* loop, in a block that also uses `?`.
No `Id.run`, and the `for` runs in `Option`. -/

/--
info: set_option autoImplicit false in
def both (a : Nat) : Option Nat := do
  let x ← Option.some a
  let mut acc := 0
  for i in List.range x do
    acc := HAdd.hAdd acc i
  Option.some acc
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn both(a: Nat) -> Option<Nat> {
  let x = Option::some(a)?;
  let mut acc = 0;
  for i in List::range(x) { acc = acc + i; }
  Option::some(acc)
}

/-! ## Tier 2 — elaboration -/

fn sum_to(n: Nat) -> Nat {
  let mut acc = 0;
  for i in List::range(n) { acc = acc + i; }
  acc
}

example : sum_to 5 = 10 := rfl

/-- info: 'sum_to' depends on axioms: [propext] -/
#guard_msgs in
#print axioms sum_to

fn first_even(xs: List<Nat>) -> Option<Nat> {
  for x in xs { if x % 2 == 0 { return Option::some(x) } }
  Option::none
}

example : first_even [1, 3, 4, 5] = some 4 := rfl
example : first_even [1, 3, 5] = none := rfl

fn upto(n: Nat) -> Nat {
  let mut acc = 0;
  for i in List::range(n) {
    if i == 3 { break }
    acc = acc + i;
  }
  acc
}

example : upto 10 = 3 := rfl

fn skip_odd(xs: List<Nat>) -> Nat {
  let mut acc = 0;
  for x in xs {
    if x % 2 == 1 { continue }
    acc = acc + x;
  }
  acc
}

example : skip_odd [1, 2, 3, 4] = 6 := rfl

/-! The `?`-carrying version really is in `Option`, not in `Id`. -/

fn both(a: Nat) -> Option<Nat> {
  let x = Option::some(a)?;
  let mut acc = 0;
  for i in List::range(x) { acc = acc + i; }
  Option::some(acc)
}

example : both 5 = some 10 := rfl

/-! ### `while` costs what `for` does not

A `for` over a list is structural, so it reduces and `rfl` proves things about it — every
example above is a `rfl`. Lean's `while` goes through `Loop.forIn`, which is not, so a
`while`-based function runs but does not compute in the kernel: `#eval` sees the answer,
`rfl` does not, and `#print axioms` shows the price. That is a Lean fact rather than an FH
one, and it is worth having in front of anyone reaching for `while` when `for` would do. -/

fn count_down(n: Nat) -> Nat {
  let mut i = n;
  let mut steps = 0;
  while (0 < i) { i = i - 1; steps = steps + 1; }
  steps
}

/-- info: 4 -/
#guard_msgs in
#eval count_down 4

/-- info: 'count_down' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms count_down

/-! ## Tier 3 — negative

A statement is not an expression, and FH says which rather than letting Lean explain a
node it has never heard of.
-/

/--
error: FH: `for`, `while`, `let mut`, assignment, `break`, `continue` and `return` are statements — they belong in a block, not inside an expression
-/
#guard_msgs in
fn stmt_in_expr(n: Nat) -> Nat { let x = (for i in List::range(n) { n } 0); x }

/-- error: FH: `let mut` needs a name — there is nothing to assign to -/
#guard_msgs in
fn nameless(n: Nat) -> Nat { let mut _ = n; 0 }

/-! The remaining two are Lean's own, at FH's spans — F9's "no invented diagnostics". A
plain `let` is not assignable, and Rust draws the same line in the same place. -/

/--
error: Variable `acc` cannot be mutated. Only variables declared using `let mut` can be mutated.
      If you did not intend to mutate but define `acc`, consider using `let acc` instead
-/
#guard_msgs (whitespace := lax) in
fn no_mut(n: Nat) -> Nat { let acc = 0; acc = n; acc }

/-- error: `break` must be nested inside a loop -/
#guard_msgs in
fn loose_break() -> Nat { break }

/-! ## Tier 4 — span -/

/-- info: error @ +0:38-39 «_» -/
#guard_msgs in
#fh_spans in
fn nameless2(n: Nat) -> Nat { let mut _ = n; 0 }
