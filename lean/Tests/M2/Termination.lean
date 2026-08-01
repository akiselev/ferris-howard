/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · termination attributes (A2.2)

Lean demands totality evidence; Rust assumes divergence is fine. Recursive `fn`s inherit
Lean's automatic structural and well-founded inference, which handles textbook recursion
silently — corpus Group 1's `add` needed nothing. When inference fails, design §4.6 gives
the escape as attributes: `#[terminates_by(measure)]` → `termination_by`, and
`#[decreasing_by(lean! { … })]` → `decreasing_by`.

* **Stage: one.** They are suffixes on the generated declaration, not modifiers, so they
  need no `declModifiers` surgery.
* **Ruling D:** *extension* — Rust has no such attribute, because Rust does not ask.
* **Sorry count: zero**, and that is the whole point: a definition here is total, proved.

## A corpus finding

Group 12 writes `gcd2` with `#[terminates_by(b)]` alone. That is not enough on this
toolchain: `termination_by b` leaves the goal `a % b < b` with `¬b = 0` in context, and
Lean's default discharge does not close it — nor does `omega`, which cannot get `b > 0`
from an inaccessible hypothesis. The measure is right; the *proof* that it decreases has
to be supplied. Recorded here rather than papered over, the same way Group 1's `add_comm`
sketch was.
-/

/-! ## Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
def countdown (n : Nat) : Nat :=
  if Eq n 0 then 0 else countdown (Nat.sub n 1)
termination_by n
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[terminates_by(n)]
fn countdown(n: Nat) -> Nat { if n == 0 { 0 } else { countdown(Nat::sub(n, 1)) } }

/--
info: set_option autoImplicit false in
def gcd3 (a : Nat) (b : Nat) : Nat :=
  if Eq b 0 then a else gcd3 b (HMod.hMod a b)
termination_by b
decreasing_by exact Nat.mod_lt _ (Nat.pos_of_ne_zero (by assumption))
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[terminates_by(b)] #[decreasing_by(lean! { exact Nat.mod_lt _ (Nat.pos_of_ne_zero (by assumption)) })]
fn gcd3(a: Nat, b: Nat) -> Nat { if b == 0 { a } else { gcd3(b, a % b) } }

/-! ## Tier 2 — elaboration

Corpus Group 12's `gcd2`, with the decreasing proof the corpus omits.
-/

#[terminates_by(b)]
#[decreasing_by(lean! { exact Nat.mod_lt _ (Nat.pos_of_ne_zero (by assumption)) })]
fn gcd2(a: Nat, b: Nat) -> Nat {
    if b == 0 { a } else { gcd2(b, a % b) }
}

/-! Termination is *proved*, and the empty axiom list says so: no `sorryAx`, no escape
hatch left open. -/

/-- info: 'gcd2' does not depend on any axioms -/
#guard_msgs in
#print axioms gcd2

theorem gcd2_zero(a: Nat) -> gcd2(a, 0) == a {
  lean! { unfold gcd2; simp }
}

/-- info: 'gcd2_zero' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms gcd2_zero

/-! A measure alone is enough when the goal is one Lean can discharge itself. -/

#[terminates_by(n)]
fn countdown(n: Nat) -> Nat { if n == 0 { 0 } else { countdown(Nat::sub(n, 1)) } }

/-- info: 'countdown' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms countdown

/-! ## Tier 3 — negative

A measure that does not decrease is Lean's failure to report, with the goal it could not
close — which is the information the author needs.
-/

/--
error: failed to prove termination, possible solutions:
  - Use `have`-expressions to prove the remaining goals
  - Use `termination_by` to specify a different well-founded relation
  - Use `decreasing_by` to specify your own tactic for discharging this kind of goal
a b : Nat
h✝ : ¬b = 0
⊢ False
-/
#guard_msgs in
#[terminates_by(a)]
fn wrong_measure(a: Nat, b: Nat) -> Nat {
  if b == 0 { 0 } else { wrong_measure(a, Nat::sub(b, 1)) }
}

/-! And the attribute wants a tactic block, not an expression. -/

/--
error: FH: `#[decreasing_by(…)]` takes a tactic block, as in `#[decreasing_by(lean! { omega })]`
-/
#guard_msgs in
#[terminates_by(n)] #[decreasing_by(n)]
fn bad_attr(n: Nat) -> Nat { n }

/-! ## Tier 4 — span -/

/-- info: error @ +0:36-37 «n» -/
#guard_msgs in
#fh_spans in
#[terminates_by(n)] #[decreasing_by(n)]
fn bad_attr2(n: Nat) -> Nat { n }
