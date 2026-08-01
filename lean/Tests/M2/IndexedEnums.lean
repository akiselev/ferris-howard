/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · indexed enums (A2.2, design §4.5)

Rust enums already cover plain and recursive inductives. Lean's indexed families need one
extension, and design §4.5 picks the smallest one: **per-variant return types**.

```rust
enum Vec<T, _: Nat> {
    Nil -> Vec<T, 0>,
    Cons<n: Nat>(head: T, tail: Vec<T, n>) -> Vec<T, n + 1>,
}
```

Two pieces of syntax carry it. The `_` in the header marks an **index** position — varying
per constructor — against `T`, which is a uniform parameter. And an arrow on a variant
declares what that variant targets; absent one, the variant targets the uniform type,
which is an ordinary Rust enum and stays exactly as it was.

* **Stage: one.**
* **Ruling D:** *extension* — per-variant return types are ill-formed Rust made
  meaningful, and `_` in a generic list is too.
* **Sorry count: zero.**
-/

/-! ## Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
inductive Vec (T : Type _) : Nat → Type _ where
  | Nil : Vec T 0
  | Cons {n : Nat} (head : T) (tail : Vec T n) : Vec T (HAdd.hAdd n 1)
-/
#guard_msgs (whitespace := lax) in
#fh_expand enum Vec<T, _: Nat> {
    Nil -> Vec<T, 0>,
    Cons<n: Nat>(head: T, tail: Vec<T, n>) -> Vec<T, n + 1>,
}

/-! No `_` in the header means no indices, and the declaration keeps the shape it had
before this feature existed. -/

/-- info: set_option autoImplicit false in inductive N where | Zero : N | Succ (pred : N) : N -/
#guard_msgs (whitespace := lax) in
#fh_expand enum N { Zero, Succ(pred: N) }

/-- info: set_option autoImplicit false in inductive Opt (T : Type _) where | None : Opt T | Some (value : T) : Opt T -/
#guard_msgs (whitespace := lax) in
#fh_expand enum Opt<T> { None -> Opt<T>, Some(value: T) -> Opt<T> }

/-! ## Tier 2 — elaboration -/

enum Vec<T, _: Nat> {
    Nil -> Vec<T, 0>,
    Cons<n: Nat>(head: T, tail: Vec<T, n>) -> Vec<T, n + 1>,
}

/--
info: inductive Vec.{u_1} : Type u_1 → Nat → Type u_1
number of parameters: 1
constructors:
Vec.Nil : {T : Type u_1} → Vec T 0
Vec.Cons : {T : Type u_1} → {n : Nat} → T → Vec T n → Vec T (n + 1)
-/
#guard_msgs in
#print Vec

/-! The index is real: a two-element vector has type `Vec T 2`, and nothing else does. -/

example : Vec Nat 2 := .Cons 1 (.Cons 2 .Nil)

/-! The length is in the type, so a function may depend on it — design §4.1's payoff,
arriving through §4.5's syntax. The `Nil` case is *impossible* here and Lean knows it, so
the match needs only one arm. -/

fn vhead<T, n: Nat>(v: Vec<T, n + 1>) -> T {
  match v {
    Vec::Cons(h, _t) => h,
  }
}

example : vhead (T := Nat) (.Cons 7 .Nil) = 7 := rfl

/-- info: 'vhead' depends on axioms: [propext] -/
#guard_msgs in
#print axioms vhead

/-! ## Tier 3 — negative

An index that does not match is a type error at the constructor, which is the entire point
of putting it in the type.
-/

/--
error: Application type mismatch: The argument
  Vec.Nil
has type
  Vec ?m.7 0
but is expected to have type
  Vec Nat 2
in the application
  Vec.Cons 1 Vec.Nil
-/
#guard_msgs in
fn wrong_length() -> Vec<Nat, 3> { Vec::Cons(1, Vec::Nil) }

/-! ## Tier 4 — span -/

/-- info: error @ +0:49-57 «Vec::Nil» -/
#guard_msgs in
#fh_spans in
fn wrong_length2() -> Vec<Nat, 3> { Vec::Cons(1, Vec::Nil) }
