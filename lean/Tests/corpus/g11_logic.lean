/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 11 — logic, and the price of Prop-first

`corpus-review.md` Group 11, made executable. The review calls F14 "the review's biggest
hidden semantic shift", and this is where it is paid.

* **Stage: one.**
* **Ruling D:** `if h @ (cond)` is an *extension* (F15); the rest is Ruling A's operators,
  which the differences page headlines.
* **Sorry count: zero.**

## F14 — `if` on a Prop is Lean's decidable-`if`

Because `a <= b` is a Prop and not a Bool (F5), `if a <= b { … }` cannot be Bool-tested. It
elaborates to Lean's decidable-`if`, which needs a `Decidable (a ≤ b)` instance. For `Nat`,
for `Real` classically, and for everything Mathlib-standard, the instance exists and the
code reads exactly like Rust — `min2` below is character-for-character what a Rust
programmer would write, and it means the mathematically right thing.

For an *undecidable* Prop it fails, and the amendment is explicit about the wording: "the
raw elaboration error is Lean's own 'failed to synthesize Decidable …' — stage one cannot
reword it; negative tests pin Lean's actual message, and the required 'no Decidable
instance' wording is delivered by the FH diagnostic layer, `fh check`'s error taxonomy."
The negative tier below pins Lean's message, as instructed.

Where a genuine `Bool` is wanted — a higher-order interface like `find` — `decide(p)`
converts explicitly. That is F5's companion and it is written, never inferred.

## F15 — `if h @ (cond)`

Proofs need the hypothesis in scope, so FH reuses Rust's `@` pattern-binding for it:
`if h @ (a <= b) { … } else { … }` is `if h : a ≤ b then … else …`, with `h : a ≤ b` in the
first branch and `h : ¬(a ≤ b)` in the second.

## Two corpus findings

**`.find()` is `List.find?`, which FH cannot type.** A0.6 rejects identifiers ending in
`?` or `!`, because Lean's lexer takes `x?` as one identifier and `?`-as-do needs the
character back. The differences page recorded the cost — `List.find?` and `Option.get!`
unreachable — and left the escape open. This is the escape: a bridge names the method FH
cannot spell, `use lean::Find;` brings it into scope, and the rule is the one F16 already
had. Nothing new was invented; the list grew.

**`Finset::range(bound).toList()` is noncomputable** on this toolchain, so the corpus's
`find_root` needs `#[noncomputable]` — and then it cannot be run, which defeats the point
of the example. `List::range(bound)` is the same list, computable, and `decide` proves
things about it. Both are below: the corpus's spelling with the marker design §4.6
requires, and the runnable one.
-/

/-! ## The corpus, as it elaborates -/

theorem demorgan<p: Prop, q: Prop>() -> !(p || q) <-> (!p && !q) {
    lean! { tauto }
}

fn min2(a: Nat, b: Nat) -> Nat {
    if a <= b { a } else { b }
}

section
use lean::Find;

/-! The corpus's spelling, with the marker its `Finset::toList` requires. -/

#[noncomputable] fn find_root_corpus(f: Nat -> Nat, bound: Nat) -> Option<Nat> {
  Finset::range(bound).toList().find(|n| decide(f(n) == 0))
}

/-! And the runnable one, which is the same list. -/

fn find_root(f: Nat -> Nat, bound: Nat) -> Option<Nat> {
  List::range(bound).find(|n| decide(f(n) == 0))
}

end

/-! ## Tier 1 — golden expansion

`!`, `||`, `&&` and `<->` are `Not`, `Or`, `And` and `Iff` — Props unconditionally, which
is Ruling A.
-/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem demorgan_g {p : Prop} {q : Prop} : Iff (Not (Or p q)) (And (Not p) (Not q)) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem demorgan_g<p: Prop, q: Prop>() -> !(p || q) <-> (!p && !q) { todo!() }

/-! F14: the `if` is Lean's, and the condition is `LE.le` rather than a Bool test. -/

/-- info: set_option autoImplicit false in def min2_g (a : Nat) (b : Nat) : Nat := if LE.le a b then a else b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn min2_g(a: Nat, b: Nat) -> Nat { if a <= b { a } else { b } }

/-! F15: `@` becomes Lean's `:`, and that is the entire translation. -/

/--
info: set_option autoImplicit false in
def dep_if_g (a : Nat) (b : Nat) : Nat := if h : (LE.le a b) then a else b
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn dep_if_g(a: Nat, b: Nat) -> Nat { if h @ (a <= b) { a } else { b } }

/-! The bridge renames the method; `decide` is written, per F5. -/

section
use lean::Find;

/--
info: set_option autoImplicit false in
def fr (f : Nat → Nat) (bound : Nat) : Option Nat :=
  (List.range bound).find? fun n => decide (Eq (f n) 0)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn fr(f: Nat -> Nat, bound: Nat) -> Option<Nat> {
  List::range(bound).find(|n| decide(f(n) == 0))
}

end

/-! ## Tier 2 — elaboration -/

/-- info: theorem demorgan : ∀ {p q : Prop}, ¬(p ∨ q) ↔ ¬p ∧ ¬q -/
#guard_msgs in
#print sig demorgan

/-- info: 'demorgan' does not depend on any axioms -/
#guard_msgs in
#print axioms demorgan

/-! `min2` reads like Rust and computes like Rust, and its condition is a Prop. -/

/-- info: def min2 : ℕ → ℕ → ℕ := fun a b => if a ≤ b then a else b -/
#guard_msgs (whitespace := lax) in
#print min2

example : min2 3 5 = 3 := rfl
example : min2 5 3 = 3 := rfl

/-- info: 'min2' does not depend on any axioms -/
#guard_msgs in
#print axioms min2

/-! `find_root` runs, which is what the noncomputable corpus spelling could not do. -/

example : find_root (fun n => n - 3) 10 = some 0 := by decide
example : find_root (fun n => n + 1) 10 = none := by decide

/-- info: 'find_root' does not depend on any axioms -/
#guard_msgs in
#print axioms find_root

/-! F15's payoff: the hypothesis is in scope, so the branch can prove something with it. -/

fn clamp(a: Nat, b: Nat) -> Nat { if _h @ (a <= b) { a } else { b } }

theorem clamp_le(a: Nat, b: Nat) -> clamp(a, b) <= b {
  lean! {
    unfold clamp
    split
    · assumption
    · exact Nat.le_refl b
  }
}

/-- info: 'clamp_le' does not depend on any axioms -/
#guard_msgs in
#print axioms clamp_le

/-! ## Tier 3 — negative

F14's price, in Lean's own words. The amendment says to pin exactly this rather than
reword it at stage one; `fh check`'s taxonomy is where the "no Decidable instance" phrasing
is owed.
-/

/--
error: failed to synthesize instance of type class
  Decidable p

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs (whitespace := lax) in
fn exotic(p: Prop, a: Nat, b: Nat) -> Nat { if p { a } else { b } }

/-! And without the bridge, `find` is what Lean says it is — no silent rename. -/

/--
error: Invalid field `find`: The environment does not contain `List.find`, so it is not possible to project the field `find` from an expression
  List.range bound
of type `List ℕ`
-/
#guard_msgs (whitespace := lax) in
fn unbridged(f: Nat -> Nat, bound: Nat) -> Option<Nat> {
  List::range(bound).find(|n| decide(f(n) == 0))
}

/-! ## Tier 4 — span -/

/-- info: error @ +0:45-66 «if p { a } else { b }» -/
#guard_msgs in
#fh_spans in
fn exotic2(p: Prop, a: Nat, b: Nat) -> Nat { if p { a } else { b } }
