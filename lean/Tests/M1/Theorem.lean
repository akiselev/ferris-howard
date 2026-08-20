/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · `theorem` and the `lean!` escape hatch (A1.1, A1.7)

* **Stage: one.**
* **Ruling D:** `theorem` as an item keyword is *confined* — Rust has no such item — and
  it is the corpus review's standing decision: mandatory keyword, no Prop-detection of
  `fn`s. `lean! { … }` is confined too.
* **Sorry count: one**, the bodyless conjecture at the end.

Conclusions here are spelled `Eq(a, b)` rather than `a == b`: the operator set is A1.5.
When it lands, corpus Group 1 gets its own fixture written the way the corpus writes it.
-/

enum N { Zero, Succ(pred: N) }

fn add(a: N, b: N) -> N {
  match b {
    N::Zero => a,
    N::Succ(b2) => N::Succ(add(a, b2)),
  }
}

/-! ## Tier 1 — golden expansion

`lean! { … }` is `by …`: the interior is parsed by Lean's own tactic parser, so the whole
of Mathlib's tactic vocabulary is available and the InfoView works inside it with no work
from FH. It is the one place an FH slot is not an FH category.
-/

/--
info: set_option autoImplicit false in
theorem add_zero (a : N) : Eq (add a N.Zero) a := by rfl
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem add_zero(a: N) -> Eq(add(a, N::Zero), a) { lean! { rfl } }

/-- info: set_option autoImplicit false in set_option linter.unusedVariables false in theorem conj (a : N) : Eq a a := sorry -/
#guard_msgs (whitespace := lax) in
#fh_expand theorem conj(a: N) -> Eq(a, a);

/-! ## Tier 2 — elaboration

Structural recursion on `add` is inferred, `rfl` closes the base case, and induction
carries the rest. This is corpus Group 1's mathematics, one notation away.
-/

theorem add_zero(a: N) -> Eq(add(a, N::Zero), a) { lean! { rfl } }
theorem zero_add(a: N) -> Eq(add(N::Zero, a), a) { lean! { induction a <;> simp [add, *] } }

theorem succ_add(a: N, b: N) -> Eq(add(N::Succ(a), b), N::Succ(add(a, b))) {
  lean! { induction b <;> simp [add, *] }
}

theorem add_comm(a: N, b: N) -> Eq(add(a, b), add(b, a)) {
  lean! { induction b <;> simp [add, zero_add, succ_add, *] }
}

/-! `simp` uses `propext`, which is one of Lean's three standard axioms — not a hole. The
assertion that matters for honesty is that `sorryAx` is absent, and `#print axioms` is
where you see it. -/

/-- info: 'add_comm' depends on axioms: [propext] -/
#guard_msgs in
#print axioms add_comm

/-! Plain Lean `theorem` still parses and elaborates in the same file — the coexistence
fact A0.5's battery covers for the other keywords, checked here for the one that shares
its spelling with a core command. -/

theorem lean_side : True := trivial

/-- info: 'lean_side' does not depend on any axioms -/
#guard_msgs in
#print axioms lean_side

/-! A bodyless `theorem` is a conjecture: `sorry`-backed, and honest about it. -/

/-- warning: declaration uses `sorry` -/
#guard_msgs in
theorem conj(a: N) -> Eq(a, a);

/--
info: FH sorry report: 1 declaration(s) depend on `sorryAx`
  conj
-/
#guard_msgs in
#fh_sorry_report

/-! ## Tier 3 — negative

A failing proof reports Lean's own error, from inside the escape hatch. The message is
pinned exactly (design §8 as amended): a DSL's error behaviour is API.
-/

/--
error: Tactic `rfl` failed: The left-hand side
  a
is not definitionally equal to the right-hand side
  N.Zero

a : N
⊢ a = N.Zero
-/
#guard_msgs in
theorem wrong(a: N) -> Eq(a, N::Zero) { lean! { rfl } }

/-! ## Tier 4 — span

The diagnostic lands on the tactic inside `lean! { … }`, in FH source — not on the
enclosing declaration.
-/

/-- info: error @ +1:10-13 «rfl» -/
#guard_msgs in
#fh_spans in
theorem wrong2(a: N) -> Eq(a, N::Zero) {
  lean! { rfl }
}
