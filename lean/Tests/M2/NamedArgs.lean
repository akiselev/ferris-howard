/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · named arguments (F11) and types in term position (F8) — A2.5

Two of the corpus review's smaller findings, and they belong together because both are
about the *argument list* being a place where FH says more than Rust can.

* **Stage: one.**
* **Ruling D:** *extension*, both — each makes ill-formed Rust well-formed FH, and neither
  changes the meaning of anything that is also legal Rust.
* **Sorry count: zero.**

## F11 — named arguments

`congruent(x, a, modulus: m)` is `congruent x a (modulus := m)`.

Rust has no named arguments, so `ident: expr` inside a call is currently ill-formed there
and the syntax was free. `corpus-review.md` line 145 checks the neighbours: no collision
with structure literals, which are brace-delimited, and none with ascription (F10), which
is paren-delimited but has no callee in front of it. It also "retroactively blesses the
keyword-argument idiom from our notation discussions".

The identifier reaches Lean **unhygienically**, because Lean resolves it against the
callee's parameter names rather than binding it — the same reason the F16 bridge builds
its method names with `mkIdent`. Here the name comes straight from source, so passing the
user's node through is both correct and span-preserving.

## F8 — types in term position

`Module::finrank(K, V)`. There is nothing to build: design §4.1 has *one* expression
grammar serving both term and type positions, so a type is already an expression and
passing one to a function is an ordinary call. The test exists to pin that, since the
alternative design (two grammars) would have made it a feature.
-/

/-! ## Tier 1 — golden expansion -/

fn scaled(x: Nat, factor: Nat) -> Nat { x * factor }

/-- info: set_option autoImplicit false in def a1 : Nat := scaled 3 (factor := 4) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn a1() -> Nat { scaled(3, factor: 4) }

/-! Naming every argument means the order is yours, which is the point of the feature. -/

/--
info: set_option autoImplicit false in def a2 : Nat := scaled (factor := 4) (x := 3)
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn a2() -> Nat { scaled(factor: 4, x: 3) }

/-! A positional argument that happens to *start* with an identifier is still positional —
the grammar commits to the named reading only on seeing the colon. -/

/-- info: set_option autoImplicit false in def a3 (n : Nat) : Nat := scaled n 4 -/
#guard_msgs (whitespace := lax) in
#fh_expand fn a3(n: Nat) -> Nat { scaled(n, 4) }

/-! F8: the type arguments are ordinary arguments. -/

/--
info: set_option autoImplicit false in
def dim {K : Type _} {V : Type _} (_k : K) (_v : V) : Nat := Module.finrank K V
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn dim<K, V>(_k: K, _v: V) -> Nat { Module::finrank(K, V) }

/-! ## Tier 2 — elaboration

Reordering is real: the two spellings produce the same value, and `rfl` says so.
-/

fn a1() -> Nat { scaled(3, factor: 4) }
fn a2() -> Nat { scaled(factor: 4, x: 3) }

example : a1 = 12 := rfl
example : a2 = 12 := rfl
example : a1 = a2 := rfl

/-- info: 'a2' does not depend on any axioms -/
#guard_msgs in
#print axioms a2

/-! F8 elaborating: a type passed to a function, and the function is Mathlib's.

`Nat::card` is noncomputable, which is a fact about cardinality rather than about FH —
design §4.6's `#[noncomputable]` is how a specification says so. -/

#[noncomputable] fn card_of<A>(_a: A) -> Nat { Nat::card(A) }

/--
info: def card_of.{u_1} : {A : Type u_1} → A → ℕ :=
fun {A} _a => Nat.card A
-/
#guard_msgs (whitespace := lax) in
#print card_of

example : card_of (3 : Fin 5) = 5 := by simp [card_of]

/-! ## Tier 3 — negative

A name that is not a parameter is Lean's own error, listing the ones that are — better
than anything FH could word, which is why F9 says not to try.
-/

/--
error: Invalid argument name `factr` for function `scaled`

Hint: Perhaps you meant one of the following parameter names:
  • `x`: f̵a̵c̵t̵r̵x̲
  • `factor`: facto̲r
-/
#guard_msgs (whitespace := lax) in
fn misnamed() -> Nat { scaled(3, factr: 4) }

/-! A0.6's identifier rule reaches argument names too. -/

/--
error: FH: `factor!` — an identifier may not end in `?` or `!`; Lean's lexer would swallow the operator into the name
-/
#guard_msgs in
fn bang_name() -> Nat { scaled(3, factor!: 4) }

/-! ## Tier 4 — span

The span covers the whole argument, which is what a reader wants to see underlined when
the name is wrong.
-/

/-- info: error @ +0:34-42 «factr: 4» -/
#guard_msgs in
#fh_spans in
fn misnamed2() -> Nat { scaled(3, factr: 4) }
