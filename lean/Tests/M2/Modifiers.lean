/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · definition modifiers (A2.2)

Design §4.6's opt-outs, with Rust-flavoured spellings: `#[partial]` → `partial def` (no
induction principle — "teach this loudly"), `#[noncomputable]` → `noncomputable def`, the
specification-not-program marker.

* **Stage: one.**
* **Ruling D:** *extension*. Rust's `partial` and `noncomputable` do not exist because
  Rust never asks for totality or computability evidence.
* **Sorry count: zero.** A `partial def` is not a hole: it is a definition Lean will not
  reason with, which is a different thing and shows up differently.

These are the fixtures that pin the `declModifiers` layout. FH grafts modifier fields onto
a generated declaration because Lean has no way to attach them to an already-built
command; the graft depends on the node's shape, and these goldens are what make that
dependency safe to hold — if the layout moves, they fail here rather than somewhere
subtle.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in partial def loop (n : Nat) : Nat := loop n -/
#guard_msgs (whitespace := lax) in
#fh_expand #[partial] fn loop(n: Nat) -> Nat { loop(n) }

/-- info: set_option autoImplicit false in noncomputable def spec (n : Nat) : Nat := n -/
#guard_msgs (whitespace := lax) in
#fh_expand #[noncomputable] fn spec(n: Nat) -> Nat { n }

/-! All three together, in the order `declModifiers` requires — attributes, then
`noncomputable`, then `partial`. -/

/--
info: set_option autoImplicit false in
@[simp]
noncomputable partial def both (n : Nat) : Nat :=
  both n
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[simp] #[noncomputable] #[partial] fn both(n: Nat) -> Nat { both(n) }

/-! ## Tier 2 — elaboration

A `partial def` needs no termination evidence, which is exactly what it trades away:
`#print` shows an `opaque` constant, because Lean will not unfold it.
-/

#[partial] fn loop(n: Nat) -> Nat { loop(n) }

/-- info: opaque loop : Nat → Nat -/
#guard_msgs in
#print loop

/-- info: 'loop' does not depend on any axioms -/
#guard_msgs in
#print axioms loop

/-! `noncomputable` is the other direction: Lean reasons with it happily and refuses to
run it. -/

#[noncomputable] fn spec(n: Nat) -> Nat { n }

example : spec 3 = 3 := rfl

/-- info: 'spec' does not depend on any axioms -/
#guard_msgs in
#print axioms spec

/-! ## Tier 3 — negative

Without `#[partial]`, an unfounded recursion is Lean's failure to report — the modifier is
an opt-out, and not taking it means the evidence is required.
-/

/--
error: fail to show termination for
  diverges
with errors
failed to infer structural recursion:
Not considering parameter n of diverges:
  it is unchanged in the recursive calls
no parameters suitable for structural recursion

well-founded recursion cannot be used, `diverges` does not take any (non-fixed) arguments
-/
#guard_msgs in
fn diverges(n: Nat) -> Nat { diverges(n) }

/-! ## Tier 4 — span -/

/-- info: error @ +0:3-12 «diverges2» -/
#guard_msgs in
#fh_spans in
fn diverges2(n: Nat) -> Nat { diverges2(n) }
