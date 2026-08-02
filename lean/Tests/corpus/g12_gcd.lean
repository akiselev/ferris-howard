/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 12 — gcd with a specification: termination, subtypes, divisibility

`corpus-review.md` Group 12, made executable. It is the group where a *program* and its
*specification* sit in the same file in the same language, which is the whole pitch.

What it stresses: `#[terminates_by]` with a well-founded measure; `if b == 0` exercising
F14 (decidable equality on `Nat` — fine); divisibility as a method, `d.dvd(a)` → `d ∣ a`
(F16); and a subtype in return position through F13's comprehension braces, with the
value–proof pair introduced by tuple syntax.

* **Stage: one.**
* **Ruling D:** `#[terminates_by]` and `#[decreasing_by]` are *confined* (Rust has no
  termination story); the subtype return is *confined*; `.dvd()` is an F16 spelling.
* **Sorry count: three, all the corpus's** — `gcd2_dvd`, `gcd2_greatest` and `nat_sqrt`
  are `todo!()` in Group 12's text. The program is complete and runs; the specification is
  stated and not yet discharged, which is exactly the state the corpus is describing.

## The corpus finding: the measure is not the proof

`#[terminates_by(b)]` is right — `b` does decrease — but it is not enough on its own. Lean
still has to be shown `a % b < b`, which needs `b ≠ 0`, and that fact comes from the `if`.
Lean puts it in scope as an inaccessible hypothesis, so `#[decreasing_by]` closes the goal
with `assumption`; the corpus text omits it and does not compile without.

Worth stating plainly because it is the general shape: the *measure* is a design decision
the author makes, and the *proof that it decreases* is a separate obligation. Design §4.6
gives them separate attributes for that reason.

## A Lean fact worth knowing: well-founded definitions do not reduce

`gcd2` compiles by well-founded recursion, so Lean marks it `@[irreducible]` and `decide`
cannot evaluate it — `#eval` can, and `simp [gcd2]` unfolds it in a proof. The same trade
`Tests/M2/Statements.lean` records for `while`, arriving from the other direction.
-/

section
use lean::Dvd;
use lean::Subtype;

/-! ## The corpus, as it elaborates -/

#[terminates_by(b)]
#[decreasing_by(lean! { exact Nat.mod_lt _ (Nat.pos_of_ne_zero (by assumption)) })]
fn gcd2(a: Nat, b: Nat) -> Nat {
    if b == 0 { a } else { gcd2(b, a % b) }
}

/--
warning: declaration uses `sorry`
---
info: FH todo
-/
#guard_msgs in
theorem gcd2_dvd(a: Nat, b: Nat) -> gcd2(a, b).dvd(a) && gcd2(a, b).dvd(b) {
    todo!()
}

/--
warning: declaration uses `sorry`
---
info: FH todo
-/
#guard_msgs in
theorem gcd2_greatest(a: Nat, b: Nat, d: Nat, ha: d.dvd(a), hb: d.dvd(b))
    -> d.dvd(gcd2(a, b))
{
    todo!()
}

/--
warning: declaration uses `sorry`
---
info: FH todo
-/
#guard_msgs in
fn nat_sqrt(n: Nat) -> {r: Nat | (r * r <= n) && (n < (r + 1) * (r + 1))} {
    todo!()
}

/-! ## Tier 1 — golden expansion

The measure becomes Lean's `termination_by`, which is where it belongs — beside the
definition, not inside it.
-/

/--
info: set_option autoImplicit false in
def gcd3 (a : Nat) (b : Nat) : Nat :=
  if Eq b 0 then a else gcd3 b (HMod.hMod a b)
termination_by b
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[terminates_by(b)] fn gcd3(a: Nat, b: Nat) -> Nat {
  if b == 0 { a } else { gcd3(b, a % b) }
}

/-! F16's `.dvd()`, which is why this file writes `use lean::Dvd;`. Nothing else could give
`dvd` a meaning: divisibility is `Dvd.dvd`, and no carrier declares a `dvd` method. -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem gcd_dvd_g (a : Nat) (b : Nat) : And (Dvd.dvd (gcd2 a b) a) (Dvd.dvd (gcd2 a b) b) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem gcd_dvd_g(a: Nat, b: Nat) -> gcd2(a, b).dvd(a) && gcd2(a, b).dvd(b) {
  todo!()
}

/-! F13's braces in return position, elected to `Subtype` by `use lean::Subtype;`. -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
def nat_sqrt_g (n : Nat) :
    Subtype (fun (r : Nat) => And (LE.le (HMul.hMul r r) n) (LT.lt n (HMul.hMul (HAdd.hAdd r 1) (HAdd.hAdd r 1)))) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn nat_sqrt_g(n: Nat) -> {r: Nat | (r * r <= n) && (n < (r + 1) * (r + 1))} {
  todo!()
}

/-! ## Tier 2 — elaboration

### The program runs
-/

/-- info: 6 -/
#guard_msgs in
#eval gcd2 12 18

/-- info: 0 -/
#guard_msgs in
#eval gcd2 0 0

example : gcd2 12 18 = 6 := by simp [gcd2]

/-- info: 'gcd2' does not depend on any axioms -/
#guard_msgs in
#print axioms gcd2

/-! ### The specifications say what they should

Both statements are about `∣`, not about a Prop-shaped parameter, which is what makes them
specifications of *this* program. -/

/-- info: theorem gcd2_dvd : ∀ (a b : ℕ), gcd2 a b ∣ a ∧ gcd2 a b ∣ b -/
#guard_msgs in
#print sig gcd2_dvd

/-- info: theorem gcd2_greatest : ∀ (a b d : ℕ), d ∣ a → d ∣ b → d ∣ gcd2 a b -/
#guard_msgs in
#print sig gcd2_greatest

/-- info: 'gcd2_dvd' depends on axioms: [sorryAx] -/
#guard_msgs in
#print axioms gcd2_dvd

/-! ### The subtype is inhabitable

`nat_sqrt` is a `todo!()` in the corpus, so here is the obligation actually discharged at
`n = 0` — a value–proof pair introduced by tuple syntax, which is Ruling C item two. -/

fn zero_sqrt() -> {r: Nat | (r * r <= 0) && (0 < (r + 1) * (r + 1))} {
  (0, lean! { decide })
}

/--
info: def zero_sqrt : { r // r * r ≤ 0 ∧ 0 < (r + 1) * (r + 1) } :=
⟨0, zero_sqrt._proof_1⟩
-/
#guard_msgs (whitespace := lax) in
#print zero_sqrt

/-- info: 'zero_sqrt' does not depend on any axioms -/
#guard_msgs in
#print axioms zero_sqrt

/-! ## Tier 3 — negative

The corpus finding, made into a test: the measure alone does not compile, because the
proof that it decreases is a separate obligation.
-/

/--
error: failed to prove termination, possible solutions:
  - Use `have`-expressions to prove the remaining goals
  - Use `termination_by` to specify a different well-founded relation
  - Use `decreasing_by` to specify your own tactic for discharging this kind of goal
a b : ℕ
h✝ : ¬b = 0
⊢ a % b < b
-/
#guard_msgs (whitespace := lax) in
#[terminates_by(b)] fn gcd_nodec(a: Nat, b: Nat) -> Nat {
  if b == 0 { a } else { gcd_nodec(b, a % b) }
}

/-! And without `use lean::Dvd;` the spelling has no meaning — the bridge is what supplies
it, and outside the import `.dvd` is plain dot notation looking for `Nat.dvd`. -/

end

/--
error: Invalid field `dvd`: The environment does not contain `Nat.dvd`, so it is not possible to project the field `dvd` from an expression
  a
of type `ℕ`
-/
#guard_msgs (whitespace := lax) in
fn unbridged(a: Nat, b: Nat) -> Prop { a.dvd(b) }

/-! ## Tier 4 — span -/

section
use lean::Dvd;

/--
info: warning @ +0:8-10 «sp»
info @ +0:50-57 «todo!()»
-/
#guard_msgs in
#fh_spans in
theorem sp(a: Nat, b: Nat) -> gcd2(a, b).dvd(a) { todo!() }

end
