/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 4 — ε–δ limits, and the precedence table under load

`corpus-review.md` Group 4, made executable. This is the group that pins F7: five operator
bands and two quantifiers in one definition, with the reading decided entirely by the
frozen precedence table rather than by parentheses the author had to guess at.

What it stresses: function types as parameter types (`Real -> Real` — F3's arrow in type
position); quantifier alternation four deep; and method-call chains inside Props.

* **Stage: one.**
* **Ruling D:** *confined* — nothing here is legal Rust with a meaning to preserve.
* **Sorry count: one, and it is the corpus's.** Group 4's text writes `todo!()` for
  `limit_unique`, so the port does too, and the tracking report says so. A concrete limit
  *is* proved below, which is what shows the definition is usable rather than merely
  well-formed.

## The corpus finding: `.abs()` needed a bridge

`(x - a).abs()` appears three times in the definition, and it did not work. `|x|` is
`abs x` — a function on any `Lattice` with a `Neg`, not a method on `Real` — so
generalized dot notation looked for `Real.abs` and correctly did not find it.

That is precisely F16's case: a Mathlib notation with no Rust operator and no carrier
method to hang the spelling on. So `abs` joined `dvd` and `comp` in the method bridge, and
this file writes `use lean::Abs;`. The rule has not changed — a spelling comes from an
import — only the list has grown, which is what the list is for.

## The reading the table produces

```
∀ eps > 0, ∃ delta > 0, ∀ (x : ℝ), 0 < |x - a| ∧ |x - a| < delta → |f x - L| < eps
```

Every grouping in that line is F7's doing. `->` is loosest so it separates the hypothesis
from the conclusion; `&&` binds tighter than `->` so the two-part hypothesis holds
together; comparisons bind tighter than `&&`; arithmetic tighter still; and each
quantifier's scope runs as far right as it can, which is why `exists<delta: Real>` covers
the entire rest of the formula without a parenthesis.
-/

section
use lean::Abs;

/-! ## The corpus, as it elaborates -/

fn tends_to(f: Real -> Real, a: Real, L: Real) -> Prop {
    for<eps: Real> (eps > 0) ->
        exists<delta: Real> (delta > 0) &&
            for<x: Real>
                ((0 < (x - a).abs()) && ((x - a).abs() < delta)) ->
                    ((f(x) - L).abs() < eps)
}

/--
warning: declaration uses `sorry`
---
info: FH todo
-/
#guard_msgs in
theorem limit_unique(f: Real -> Real, a: Real, L1: Real, L2: Real,
                     h1: tends_to(f, a, L1), h2: tends_to(f, a, L2))
    -> L1 == L2
{
    todo!()
}

/-! ## Tier 1 — golden expansion

The whole point of this fixture: no parentheses appear in the output that the author did
not write, and the nesting is the table's.
-/

/--
info: set_option autoImplicit false in
def tends_to_g (f : Real → Real) (a : Real) (L : Real) : Prop :=
  ∀ (eps : Real),
    (GT.gt eps 0) →
      ∃ (delta : Real),
        And (GT.gt delta 0)
          (∀ (x : Real),
            (And (LT.lt 0 (abs (HSub.hSub x a))) (LT.lt (abs (HSub.hSub x a)) delta)) →
              (LT.lt (abs (HSub.hSub (f x) L)) eps))
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn tends_to_g(f: Real -> Real, a: Real, L: Real) -> Prop {
    for<eps: Real> (eps > 0) ->
        exists<delta: Real> (delta > 0) &&
            for<x: Real>
                ((0 < (x - a).abs()) && ((x - a).abs() < delta)) ->
                    ((f(x) - L).abs() < eps)
}

/-! ## Tier 2 — elaboration

Printed back, it is the ε–δ definition a textbook writes.
-/

/--
info: def tends_to : (ℝ → ℝ) → ℝ → ℝ → Prop :=
fun f a L => ∀ eps > 0, ∃ delta > 0, ∀ (x : ℝ), 0 < |x - a| ∧ |x - a| < delta → |f x - L| < eps
-/
#guard_msgs (whitespace := lax) in
#print tends_to

/-- info: 'tends_to' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms tends_to

/-! The theorem's *statement* is right even though its proof is the corpus's `todo!()` —
the hypotheses are `tends_to` applications, which is what makes this a statement about
limits rather than about a Prop-shaped parameter. -/

/--
info: theorem limit_unique : ∀ (f : ℝ → ℝ) (a L1 L2 : ℝ), tends_to f a L1 → tends_to f a L2 → L1 = L2
-/
#guard_msgs in
#print sig limit_unique

/-! And the `sorry` is *visible*, which is the whole discipline: FH does not hide an
incomplete proof, Lean's own axiom tracking finds it, and nothing downstream can use it
without inheriting the mark. -/

/--
info: 'limit_unique' depends on axioms: [propext, sorryAx, Classical.choice, Quot.sound]
-/
#guard_msgs in
#print axioms limit_unique

/-! ### The definition is usable

A `todo!()` in the hard theorem proves nothing about the definition, so here is a limit
that is actually established: the identity function tends to `a` at `a`, with `delta` taken
to be `eps`.
-/

fn idr(x: Real) -> Real { x }

theorem id_tends_to(a: Real) -> tends_to(idr, a, a) {
  lean! {
    intro eps he
    refine ⟨eps, he, ?_⟩
    intro x ⟨_, h2⟩
    simpa [idr] using h2
  }
}

/-- info: 'id_tends_to' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms id_tends_to

/-! ## Tier 3 — negative

F7 (i) and (ii) as amended: comparisons are non-associative and so is `<->`. Both traps
are closed at the parser, which is where a trap should be closed.
-/

/-- info: does not parse: <input>:1:53: expected ')', ',' or ':' -/
#guard_msgs in
#fh_parse "fn chain(a: Real, b: Real, c: Real) -> Prop { (a < b < c) }"

/-! F7 (iv): a quantifier's scope swallows everything to its right, so conjoining from
outside means parenthesising the quantifier. Without the parentheses the `&&` lands
*inside*, which is a different statement — and this is why the rule is normative rather
than a matter of taste. -/

/--
info: set_option autoImplicit false in
def inside (P : Prop) : Prop := ∀ (x : Real), And (LT.lt 0 x) P
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn inside(P: Prop) -> Prop { for<x: Real> (0 < x) && P }

/--
info: set_option autoImplicit false in
def outside (P : Prop) : Prop := And (∀ (x : Real), (LT.lt 0 x)) P
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn outside(P: Prop) -> Prop { (for<x: Real> (0 < x)) && P }

/-! ## Tier 4 — span

The `todo!()` reports at its own position, not the declaration's — what is missing, and
where.
-/

/--
info: warning @ +0:3-13 «unfinished»
info @ +0:42-49 «todo!()»
-/
#guard_msgs in
#fh_spans in
fn unfinished(a: Real, b: Real) -> Prop { todo!() }

end
