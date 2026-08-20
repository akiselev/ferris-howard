/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M0 · expression forms (A0.2)

`::` paths, field access and method calls, closures, `let`, and `match`, with all four
tiers (design §8 as amended by PLAN §9.3).

* **Stage: one.** Pure `macro_rules`.
* **Ruling D:** none of these diverge — they are design §3's core-mapping rows. The two
  entries this feature adds to `differences.md` are restrictions: no space before a call's
  `(`, and no zero-argument closure `|| e` (`||` is one token).
* **Sorry count: zero.**

The Lean helper `applyTwice` is ambient Lean, not FH: a closure has to be passed *to*
something, and function types need the `->` operator, which is A1.5. Calling a Lean
definition verbatim is design §6's no-mangling policy working as intended.
-/

def applyTwice (f : Nat → Nat) (n : Nat) : Nat := f (f n)

/-! ## Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
def two : Nat :=
  Nat.succ (Nat.succ Nat.zero)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn two() -> Nat { Nat::succ(Nat::succ(Nat::zero)) }

/--
info: set_option autoImplicit false in
def chain (s : String) : Nat :=
  (s.toList).length
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn chain(s: String) -> Nat { s.toList().length }

/--
info: set_option autoImplicit false in
def four : Nat :=
  applyTwice (fun x => Nat.succ x) 2
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn four() -> Nat { applyTwice(|x| Nat::succ(x), 2) }

/--
info: set_option autoImplicit false in
def seven : Nat :=
  let x := 3;
  let y : Nat := 4;
  Nat.add x y
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn seven() -> Nat { let x = 3; let y: Nat = 4; Nat::add(x, y) }

/--
info: set_option autoImplicit false in
def is_zero (n : Nat) : Bool :=
  match n with
  | 0 => true
  | _ => false
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn is_zero(n: Nat) -> Bool { match n { 0 => true, _ => false } }

/-! ## Tier 2 — elaboration

Each form elaborates, and `rfl` checks that it means what the golden says it means.
-/

fn two() -> Nat { Nat::succ(Nat::succ(Nat::zero)) }
fn chain(s: String) -> Nat { s.toList().length }
fn four() -> Nat { applyTwice(|x| Nat::succ(x), 2) }
fn seven() -> Nat { let x = 3; let y: Nat = 4; Nat::add(x, y) }
fn is_zero(n: Nat) -> Bool { match n { 0 => true, _ => false } }

example : two = 2 := rfl
example : chain "abc" = 3 := rfl
example : four = 4 := rfl
example : seven = 7 := rfl
example : is_zero 0 = true := rfl
example : is_zero 5 = false := rfl

/-- info: 'seven' does not depend on any axioms -/
#guard_msgs in
#print axioms seven

/-! ## Tier 3 — negative

`::` joins identifiers into a name; `.` reaches a value's field or method. Conflating
them would make `f(x)::g` silently mean field access, which resolves differently.
-/

/-- error: FH: `::` joins identifiers; for a value's field or method use `.` -/
#guard_msgs in
fn bad_path() -> Nat { two()::succ }

/-! ## Tier 4 — span

The error covers the whole path expression, in FH source.
-/

/-- info: error @ +0:24-35 «two()::succ» -/
#guard_msgs in
#fh_spans in
fn bad_path2() -> Nat { two()::succ }
