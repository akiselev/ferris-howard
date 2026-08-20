/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 3 — order theory, and Prop-valued operators

`corpus-review.md` Group 3, made executable. What it stresses: F3 (implication as the
function arrow), F4 (`<->`), F5 (comparisons are Props), F6 (a bare `<` must be
parenthesised), F2 (distributed ascription in `for<a, b: Self>`), and `+`-free multi-bound
`where` clauses.

* **Stage: one.**
* **Ruling D:** *confined* — a `trait` body carrying laws has no Rust counterpart.
  Everything else is Ruling A's operators, which the differences page already headlines.
* **Sorry count: zero.**

## The corpus finding: `fn le` and `<=` are not the same thing

The corpus text declares the relation as a method and then uses the operator:

```rust
trait POrder<Self> {
    fn le(a: Self, b: Self) -> Prop;
    refl: for<a: Self> a <= a;
}
```

Under Ruling A, `a <= b` is `LE.le a b` **unconditionally** — that is the whole point of
Ruling A, and it is why the differences page headlines it. So a `POrder` that declares its
own `le` field and then writes `a <= a` is stating a law about a *different* relation than
the one it declared.

The fix is one token and it is the one Mathlib uses: `trait POrder<Self>: LE`. The trait
*extends* `LE`, so `le` is inherited rather than redeclared and `<=` means it. That is
faithful to the corpus's intent, honest about Ruling A, and shorter than the original.

Recorded here rather than silently patched, because it is exactly the class of thing the
corpus exists to surface: an FH construct that reads fine and means something else.
-/

/-! ## The corpus, as it elaborates -/

trait POrder<Self>: LE {
    refl:     for<a: Self> a <= a;
    antisymm: for<a, b: Self> (a <= b) -> (b <= a) -> a == b;
    trans:    for<a, b, c: Self> (a <= b) -> (b <= c) -> (a <= c);
}

/-! A Galois connection between two ordered types. -/

fn galois_connection<A, B>(f: A -> B, g: B -> A) -> Prop
where A: POrder, B: POrder
{
    for<a: A, b: B> (f(a) <= b) <-> (a <= g(b))
}

/-! ## Tier 1 — golden expansion

A trait with a parent is a class that `extends` it, and the laws are ordinary fields whose
types happen to be quantified Props.
-/

/--
info: set_option autoImplicit false in
class POrderGolden (Self : Type _) extends LE Self where
  refl : ∀ (a : Self), LE.le a a
  antisymm : ∀ (a : Self) (b : Self), (LE.le a b) → (LE.le b a) → Eq a b
-/
#guard_msgs (whitespace := lax) in
#fh_expand trait POrderGolden<Self>: LE {
    refl:     for<a: Self> a <= a;
    antisymm: for<a, b: Self> (a <= b) -> (b <= a) -> a == b;
}

/-! F3 and F4 in one line: `->` is the function arrow made available everywhere, `<->` is
`Iff`, and the quantifier scope runs as far right as it can (F7 iv). -/

/--
info: set_option autoImplicit false in
def gc {A : Type _} {B : Type _} [POrder A] [POrder B] (f : A → B) (g : B → A) : Prop :=
  ∀ (a : A) (b : B), Iff (LE.le (f a) b) (LE.le a (g b))
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn gc<A, B>(f: A -> B, g: B -> A) -> Prop
where A: POrder, B: POrder
{
    for<a: A, b: B> (f(a) <= b) <-> (a <= g(b))
}

/-! ## Tier 2 — elaboration -/

/--
info: def galois_connection.{u_1, u_2} : {A : Type u_1} → {B : Type u_2} → [POrder A] → [POrder B] → (A → B) → (B → A) → Prop
-/
#guard_msgs in
#print sig galois_connection

/-- info: 'galois_connection' does not depend on any axioms -/
#guard_msgs in
#print axioms galois_connection

/-! An `impl` discharges the three laws. `Nat`'s `LE` is already there, so the instance
supplies only what `POrder` adds — which is what `extends` buys. -/

impl POrder for Nat {
    refl:     lean! { intro a; omega };
    antisymm: lean! { intro a b h1 h2; omega };
    trans:    lean! { intro a b c h1 h2; omega };
}

/-- info: 'instPOrderNat' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms instPOrderNat

/-! And the connection is inhabited: the identity between `Nat` and itself is one. -/

fn idf(n: Nat) -> Nat { n }

theorem id_gc_holds() -> galois_connection(idf, idf) {
  lean! { intro a b; exact Iff.rfl }
}

/-- info: 'id_gc_holds' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms id_gc_holds

/-! ## Tier 3 — negative

F6: a bare `<` could open a generic argument list, so it must be parenthesised. The message
is fixed and the span is exact, per the F6 amendment — the parser cannot word it, so the
expander does.
-/

/--
error: FH: parenthesise this comparison — `(a < b)`. A bare `<` could open a generic argument list
-/
#guard_msgs in
fn bare_lt(a: Nat, b: Nat) -> Prop { a < b }

/-! F7 as amended: comparisons are non-associative, and so is `<->`. Chaining either is a
parse error rather than a surprising reading — the classic maths-notation trap, closed. -/

/-- info: does not parse: <input>:1:51: expected ')', ',' or ':' -/
#guard_msgs in
#fh_parse "fn chain(a: Nat, b: Nat, c: Nat) -> Prop { (a <= b <= c) }"

/-! ## Tier 4 — span -/

/-- info: error @ +0:38-43 «a < b» -/
#guard_msgs in
#fh_spans in
fn bare_lt2(a: Nat, b: Nat) -> Prop { a < b }
