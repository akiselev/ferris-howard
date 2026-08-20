/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · comprehension braces (A2.1, F13)

`{x: A | P(x)}` is one syntax for two things — a `Set A` and a `Subtype` — and F13's
amendment elects between them by **expected type**. Stage one cannot see an expected type,
so FH elects by **import** instead: `use lean::Set;` or `use lean::Subtype;`, in the file
that means it.

* **Stage: one.**
* **Ruling D:** *confined* — Rust has no comprehension braces to disagree with.
* **Sorry count: zero.**

## This deviates from F13, deliberately and reversibly

Election by expected type is the better reading experience, and this is not it: a
comprehension in a return type ought to mean the obvious thing without an import. What it
buys is that nothing is elected invisibly, the file says which it means, and the artifact
contains `setOf` or `Subtype` — ordinary Lean, no FH prelude.

The choice lives in *one* `macro_rules` on `fh_comprehension%`. Moving to a stage-two
elaborator, or to a class with an `outParam` and a `@[default_instance]`, changes that rule
and nothing else — not the grammar, not the expander, not any fixture below except the two
that test the decision itself. That is why the hook exists rather than the expander
emitting `setOf` directly. Queued as an amendment for whoever owns ADR-006's prelude
policy.
-/

/-! ## Tier 3 — negative, first

With nothing imported the brace has no meaning, and the error says what would give it one.
-/

/--
error: FH: no comprehension is in scope, so `{x: A | P}` has no meaning here. `use lean::Set;` makes it a set; `use lean::Subtype;` makes it a subtype.
-/
#guard_msgs in
fn no_election(f: Nat -> Prop) -> Set<Nat> { {x: Nat | f(x)} }

/-! ## Tier 4 — span -/

/-- info: error @ +0:47-62 «{x: Nat | f(x)}» -/
#guard_msgs in
#fh_spans in
fn no_election2(_f: Nat -> Prop) -> Set<Nat> { {x: Nat | f(x)} }

/-! ## Sets -/

section
use lean::Set;

/-! ### Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
def diagonal {A : Type _} (f : A → Set A) : Set A :=
  setOf (fun (x : A) => Not (Membership.mem (f x) x))
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn diagonal<A>(f: A -> Set<A>) -> Set<A> { {x: A | !(x in f(x))} }

/-! ### Tier 2 — elaboration

Corpus Group 8's diagonal set — "those x not members of their own image" — which is the
whole content of Cantor's theorem.
-/

fn diagonal<A>(f: A -> Set<A>) -> Set<A> { {x: A | !(x in f(x))} }

/-- info: def diagonal.{u_1} : {A : Type u_1} → (A → Set A) → Set A := fun {A} f => {x | x ∉ f x} -/
#guard_msgs (whitespace := lax) in
#print diagonal

fn surjective<A, B>(f: A -> B) -> Prop { for<b: B> exists<a: A> f(a) == b }

theorem cantor<A>(f: A -> Set<A>) -> !surjective(f) {
  lean! {
    intro hsurj
    obtain ⟨a, ha⟩ := hsurj (diagonal f)
    have : a ∈ diagonal f ↔ a ∉ f a := Iff.rfl
    rw [ha] at this
    tauto
  }
}

/-- info: 'cantor' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms cantor

end

/-! ## Subtypes

A second `use` in a second scope, and the same braces mean the other thing. The imports
are not additive: whichever is in scope decides, and if both are, the later one wins —
which is why these live in separate sections.
-/

section
use lean::Subtype;

/-! ### Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in abbrev tiny := Subtype (fun (r : Nat) => (LT.lt r 5)) -/
#guard_msgs (whitespace := lax) in
#fh_expand type tiny = {r: Nat | (r < 5)};

/-! ### Tier 2 — elaboration

Corpus Group 12's `nat_sqrt` shape: a subtype in return position, its obligation
discharged by the anonymous constructor.
-/

-- `Small` is Mathlib's, so this one is `Tiny`.
type Tiny = {r: Nat | (r < 5)};

fn two() -> Tiny { (2, lean! { decide }) }

example : two.val = 2 := rfl

/-- info: 'two' does not depend on any axioms -/
#guard_msgs in
#print axioms two

end

/-! Outside both sections the brace is meaningless again — the import is scoped, like every
other `use`. -/

/--
error: FH: no comprehension is in scope, so `{x: A | P}` has no meaning here. `use lean::Set;` makes it a set; `use lean::Subtype;` makes it a subtype.
-/
#guard_msgs in
fn after_sections(f: Nat -> Prop) -> Set<Nat> { {x: Nat | f(x)} }
