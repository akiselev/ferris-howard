/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 8 — Cantor's theorem, membership, and set-builder braces

`corpus-review.md` Group 8, made executable, **verbatim**: `injective`, `surjective` and
`cantor` are the corpus's text unchanged, including the `let d: Set<A> = …;` binding whose
tail is a `lean!` block.

What it stresses: F12 (`in` as a binary Prop operator), F13 (comprehension braces), and
the negation of a defined predicate in a theorem statement.

* **Stage: one.**
* **Ruling D:** `in` outside a loop is an *extension* (Rust reserves the word but uses it
  only in `for` headers); comprehension braces are *confined*.
* **Sorry count: zero.** Cantor's theorem is proved.

## F12 — `in` collides with nothing

Rust reserves `in` and uses it in exactly one place, the `for` loop header. FH's
quantifier is bracketed (`for<x: T>`), so there is nothing to collide with there; and in a
do-block loop header (`for x in xs { … }`, A2.3) `in` is a positional keyword of the
header rather than the operator, per F7's amendment clause (iii). Both readings appear
below, and each means the one thing.

## F13 — elected by import, not by position

The review's amendment rules `{x: A | P}` by *expected type* — `Set` in term position,
`Subtype` in type position. Stage one has no expected type and, under the unified grammar
(design §4.1), no syntactic position either. So FH elects by **import**: this file writes
`use lean::Set;` and means sets.

The whole decision is one `macro_rules` on `fh_comprehension%`; moving to a stage-two
elaborator or an `outParam` class changes that rule and nothing else. `Tests/M2/Comprehension.lean`
carries the argument and the `Subtype` side; this file is the corpus consumer.
-/

section
use lean::Set;

/-! ## The corpus, verbatim -/

fn injective<A, B>(f: A -> B) -> Prop {
    for<a1, a2: A> (f(a1) == f(a2)) -> a1 == a2
}

fn surjective<A, B>(f: A -> B) -> Prop {
    for<b: B> exists<a: A> f(a) == b
}

theorem cantor<A>(f: A -> Set<A>) -> !surjective(f) {
    -- diagonal set: those x not members of their own image
    let d: Set<A> = {x: A | !(x in f(x))};
    lean! {
      intro hsurj
      obtain ⟨a, ha⟩ := hsurj d
      have : a ∈ d ↔ a ∉ f a := Iff.rfl
      rw [ha] at this
      tauto
    }
}

/-! ## Tier 1 — golden expansion

F2's distributed ascription is doing quiet work in `injective`: `for<a1, a2: A>` binds
*both* at `A`, where Rust's generic lists would have bound only `a2`.
-/

/--
info: set_option autoImplicit false in
def injective_g {A : Type _} {B : Type _} (f : A → B) : Prop :=
  ∀ (a1 : A) (a2 : A), (Eq (f a1) (f a2)) → Eq a1 a2
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn injective_g<A, B>(f: A -> B) -> Prop {
    for<a1, a2: A> (f(a1) == f(a2)) -> a1 == a2
}

/--
info: set_option autoImplicit false in
def surjective_g {A : Type _} {B : Type _} (f : A → B) : Prop :=
  ∀ (b : B), ∃ (a : A), Eq (f a) b
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn surjective_g<A, B>(f: A -> B) -> Prop { for<b: B> exists<a: A> f(a) == b }

/-! The diagonal set, which is the whole content of the theorem: `setOf` from the import,
`Membership.mem` from F12, and `Not` from Ruling A's `!`. -/

/--
info: set_option autoImplicit false in
def diag {A : Type _} (f : A → Set A) : Set A :=
  setOf (fun (x : A) => Not (Membership.mem (f x) x))
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn diag<A>(f: A -> Set<A>) -> Set<A> { {x: A | !(x in f(x))} }

/-! F12 on its own: `x in s` is `Membership.mem`, a Prop, with no loop anywhere. -/

/--
info: set_option autoImplicit false in
def memb {A : Type _} (x : A) (s : Set A) : Prop := Membership.mem s x
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn memb<A>(x: A, s: Set<A>) -> Prop { x in s }

/-! ## Tier 2 — elaboration -/

/--
info: def injective.{u_1, u_2} : {A : Type u_1} → {B : Type u_2} → (A → B) → Prop
-/
#guard_msgs in
#print sig injective

/--
info: theorem cantor.{u_1} : ∀ {A : Type u_1} (f : A → Set A), ¬surjective f
-/
#guard_msgs in
#print sig cantor

/-- info: 'cantor' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms cantor

/-! Not vacuous: the theorem applies, and gives what Cantor gives. -/

example : ¬ surjective (fun n : Nat => ({n} : Set Nat)) := cantor _

/-! ## F12's negative obligation

The review asks for a test "to confirm `for` headers never capture it". There are two
headers to check and they resolve opposite ways, which is the point.

The **quantifier** is bracketed, so `in` inside its body is the operator: -/

/--
info: set_option autoImplicit false in
def quantified_in {A : Type _} (s : Set A) : Prop := ∀ (x : A), Membership.mem s x
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn quantified_in<A>(s: Set<A>) -> Prop { for<x: A> x in s }

end

/-! And the **loop** header takes `in` positionally — F7's amendment, clause (iii). Same
word, two readings, neither ambiguous, because the two headers do not look alike. -/

/--
info: set_option autoImplicit false in
def loop_in (xs : List Nat) : Nat :=
  Id.run do
    let mut a := 0
    for x in xs do
      a := HAdd.hAdd a x
    a
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn loop_in(xs: List<Nat>) -> Nat { let mut a = 0; for x in xs { a = a + x; } a }

/-! ## Tier 3 — negative

Outside the import the braces have no meaning, and the error names both ways to give them
one rather than picking silently. That is F13's election made visible.
-/

/--
error: FH: no comprehension is in scope, so `{x: A | P}` has no meaning here. `use lean::Set;` makes it a set; `use lean::Subtype;` makes it a subtype.
-/
#guard_msgs in
fn no_election<A>(_s: Set<A>) -> Prop { {x: A | x == x} }

/-! F7 (ii) as amended: `in` sits in the comparison band and is non-associative, so
chaining is a parse error rather than a surprising grouping. -/

/-- info: does not parse: <input>:1:59: expected ')', ',' or ':' -/
#guard_msgs in
#fh_parse "fn chain<A>(x: A, s: Set<A>, t: Set<A> ) -> Prop { (x in s in t) }"

/-! ## Tier 4 — span -/

/-- info: error @ +0:41-57 «{x: A | x in _s}» -/
#guard_msgs in
#fh_spans in
fn no_election2<A>(_s: Set<A>) -> Prop { {x: A | x in _s} }
