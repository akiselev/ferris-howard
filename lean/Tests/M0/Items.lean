/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M0 · items (A0.3)

`struct` (with `extends`), plain `enum`, `mod`, `use`, `type` with its `#[def]` opt-out,
and attribute pass-through, with all four tiers.

* **Stage: one.**
* **Ruling D:** design §3's core-mapping rows again, so no divergence. `struct S: B { … }`
  reuses the trait row's `+`-separated bound spelling (design §3, §4.5), which is a
  construct Rust does not have — *confined*.
* **Sorry count: zero.**
-/

/-! ## Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
structure Point where
  x : Nat
  y : Nat
-/
#guard_msgs (whitespace := lax) in
#fh_expand struct Point { x: Nat, y: Nat }

/--
info: set_option autoImplicit false in
structure Point3 extends Point where
  z : Nat
-/
#guard_msgs (whitespace := lax) in
#fh_expand struct Point3: Point { z: Nat }

/-! Named variant fields become binders, so the name stays visible in goals and available
to named arguments (F11); unnamed ones become an arrow chain. A variant may not mix the
two, exactly as in Rust, where those are different variant shapes. -/

/--
info: set_option autoImplicit false in
inductive N where
  | Zero : N
  | Succ (pred : N) : N
-/
#guard_msgs (whitespace := lax) in
#fh_expand enum N { Zero, Succ(pred: N) }

/--
info: set_option autoImplicit false in
inductive Pair where
  | Both : Nat → Nat → Pair
  | None : Pair
-/
#guard_msgs (whitespace := lax) in
#fh_expand enum Pair { Both(Nat, Nat), None }

/--
info: set_option autoImplicit false in
abbrev Count :=
  Nat
-/
#guard_msgs (whitespace := lax) in
#fh_expand type Count = Nat;

/-- info: set_option autoImplicit false in def Opaque := Nat -/
#guard_msgs (whitespace := lax) in
#fh_expand #[def] type Opaque = Nat;

/-- info: set_option autoImplicit false in @[simp] def one : Nat := 1 -/
#guard_msgs (whitespace := lax) in
#fh_expand #[simp] fn one() -> Nat { 1 }

/-! `mod` is the one item that expands to *several* commands. -/

/--
info: namespace inner
set_option autoImplicit false in
def two : Nat :=
  2
end inner
-/
#guard_msgs (whitespace := lax) in
#fh_expand mod inner { fn two() -> Nat { 2 } }

/-- info: open Nat -/
#guard_msgs (whitespace := lax) in
#fh_expand use Nat;

/-! ## Tier 2 — elaboration -/

struct Point { x: Nat, y: Nat }
struct Point3: Point { z: Nat }
enum N { Zero, Succ(pred: N) }
type Count = Nat;
#[def] type Opaque = Nat;
#[simp] fn one() -> Nat { 1 }
mod inner { fn two() -> Nat { 2 } }
use inner;

example : (Point.mk 1 2).x = 1 := rfl
example : (Point3.mk (Point.mk 1 2) 3).z = 3 := rfl
example (c : Count) : Nat := c
example : one = 1 := rfl
example : two = 2 := rfl                -- reached unqualified: `use inner;` opened it

/-! `type` is an `abbrev` — reducible, so a `Count` is a `Nat` without further ado — while
`#[def]` opts out of that transparency. `rfl` still sees through a `def` here; what
changes is unification, which is the point of the opt-out. -/

example : Count = Nat := rfl
example : Opaque = Nat := rfl

/-! Structural recursion over an FH `enum`, inferred with no attribute: corpus Group 1's
`add`. The theorems that go with it need `theorem` (A1.1), so `Tests/corpus/g01_*` lands
at M1; this is the M0 half. -/

fn peano_add(a: N, b: N) -> N {
  match b {
    N::Zero => a,
    N::Succ(b2) => N::Succ(peano_add(a, b2)),
  }
}

example : peano_add N.Zero (N.Succ N.Zero) = N.Succ N.Zero := rfl

/-- info: 'peano_add' does not depend on any axioms -/
#guard_msgs in
#print axioms peano_add

/-! ## Tier 3 — negative -/

/-- error: FH: an enum variant's fields must be either all named or all unnamed -/
#guard_msgs in
enum Mixed { Bad(x: Nat, Nat) }

/-- error: FH: attributes are not supported on `mod` -/
#guard_msgs in
#[simp] mod attributed { }

/-! ## Tier 4 — span -/

/-- info: error @ +0:14-30 «Bad(x: Nat, Nat)» -/
#guard_msgs in
#fh_spans in
enum Mixed2 { Bad(x: Nat, Nat) }

/-- info: error @ +0:8-27 «mod attributed2 { }» -/
#guard_msgs in
#fh_spans in
#[simp] mod attributed2 { }
