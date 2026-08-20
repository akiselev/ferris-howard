/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 1 — Peano arithmetic

`corpus-review.md` Group 1, as written there, made executable. Ruling E: the twelve groups
*are* the specification, and this is the first of them to go green.

What it stresses: structural recursion inference with no attribute, `::` paths mapping to
Lean namespaces, `==` as propositional equality in return position, plain (unindexed)
enums. The group carries no F-findings — it is the one that had to Just Work.

* **Stage: one** throughout.
* **Sorry count: zero.**

One deviation from the corpus text, and it is the corpus's own: `add_comm`'s proof there
is marked "sketch; real proof in tests", and `induction b <;> simp [add, *]` genuinely
does not close it — `add` recurses on its second argument, so the reversed cases need
`zero_add` and `succ_add` first. Those two lemmas are the real proof, and they belong
here rather than in the corpus document, which is about syntax.
-/

enum N { Zero, Succ(pred: N) }

fn add(a: N, b: N) -> N {
    match b {
        N::Zero => a,
        N::Succ(b2) => N::Succ(add(a, b2)),
    }
}

theorem add_zero(a: N) -> add(a, N::Zero) == a {
    lean! { rfl }
}

theorem zero_add(a: N) -> add(N::Zero, a) == a {
    lean! { induction a <;> simp [add, *] }
}

theorem succ_add(a: N, b: N) -> add(N::Succ(a), b) == N::Succ(add(a, b)) {
    lean! { induction b <;> simp [add, *] }
}

theorem add_comm(a: N, b: N) -> add(a, b) == add(b, a) {
    lean! { induction b <;> simp [add, zero_add, succ_add, *] }
}

/-! ## Tier 1 — golden expansion

The group's two shapes: recursion over a plain enum, and a theorem whose conclusion is an
equation. `==` is `Eq` (Ruling A) and `::` has become a Lean name.
-/

/--
info: set_option autoImplicit false in
def add2 (a : N) (b : N) : N :=
  match b with
  | N.Zero => a
  | N.Succ b2 => N.Succ (add a b2)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn add2(a: N, b: N) -> N {
    match b {
        N::Zero => a,
        N::Succ(b2) => N::Succ(add(a, b2)),
    }
}

/--
info: set_option autoImplicit false in
theorem add_zero2 (a : N) : Eq (add a N.Zero) a := by rfl
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem add_zero2(a: N) -> add(a, N::Zero) == a { lean! { rfl } }

/-! ## Tier 2 — elaboration

The declarations above are the test; these pin what they mean. `add` computes, the
theorems are axiom-free apart from what `simp` uses, and the recursion needed no
termination attribute.
-/

example : add (N.Succ N.Zero) (N.Succ N.Zero) = N.Succ (N.Succ N.Zero) := rfl

/-- info: 'add_zero' does not depend on any axioms -/
#guard_msgs in
#print axioms add_zero

/-- info: 'add_comm' depends on axioms: [propext] -/
#guard_msgs in
#print axioms add_comm

/-- info: FH sorry report: no declarations depend on `sorryAx` -/
#guard_msgs in
#fh_sorry_report

/-! ## Tier 3 — negative

The group has no F-findings to encode, so the negative here guards the reading itself:
`==` is propositional equality, not a `Bool` test, so a `Bool`-valued position rejects it.
That is Ruling A's cost, paid where a Rust reader would first meet it.
-/

/--
error: Application type mismatch: The argument
  a = b
has type
  Prop
but is expected to have type
  Bool
in the application
  cond (a = b)
-/
#guard_msgs in
fn as_bool(a: N, b: N) -> N { cond(a == b, a, b) }

/-! ## Tier 4 — span

An error inside a match arm points at the arm, in FH source.
-/

/-- info: error @ +2:19-20 «b» -/
#guard_msgs in
#fh_spans in
fn bad_arm(a: N, b: Nat) -> N {
    match a {
        N::Zero => b,
        N::Succ(p) => p,
    }
}
