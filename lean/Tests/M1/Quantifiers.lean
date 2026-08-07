/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · quantifiers (A1.4)

`for<x: T> P` is `∀ x : T, P` and `exists<x: T> P` is `∃ x : T, P` — design §4.2's two
Rust-native gifts, the higher-ranked binder generalised and the closure shape reused for
its dual.

* **Stage: one.**
* **Ruling D:** F2's distributed ascription is *confined* and deliberately divergent —
  Rust's `for<>` takes only lifetimes, and its generic lists bind only the last parameter.
  Documented loudly on the differences page, and given a negative test below, which is
  what the corpus review asks for.
* **Sorry count: zero.**

Not yet: `exists` with a data-valued body electing `Sigma`/`Subtype` by expected type
(Ruling C item four) — that is stage-two work and this production always builds `Exists`.
-/

abbrev NatList := List Nat

fn is_true(b: Bool) -> Prop { Eq(b, true) }

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in def all_refl : Prop := ∀ (x : Nat), Eq x x -/
#guard_msgs (whitespace := lax) in
#fh_expand fn all_refl() -> Prop { for<x: Nat> x == x }

/-- info: set_option autoImplicit false in def some_zero : Prop := ∃ (x : Nat), Eq x 0 -/
#guard_msgs (whitespace := lax) in
#fh_expand fn some_zero() -> Prop { exists<x: Nat> x == 0 }

/-! F2: an ascription distributes over the **unascribed prefix**, so all three of `a b c`
are `Nat` here. Rust's generic lists bind only the last, which is the divergence. -/

/--
info: set_option autoImplicit false in
def distributed : Prop :=
  ∀ (a : Nat) (b : Nat) (c : Nat), Eq a b
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn distributed() -> Prop { for<a, b, c: Nat> a == b }

/-! Each ascription governs only the prefix since the last one. -/

/--
info: set_option autoImplicit false in
def mixed : Prop :=
  ∀ (a : Nat) (b : Bool), Eq b b
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn mixed() -> Prop { for<a: Nat, b: Bool> b == b }

/-! Trailing parameters with no ascription anywhere after them are inferred, which is what
a reader of `∀ a b, …` expects. -/

/--
info: set_option autoImplicit false in
def untyped : Prop :=
  ∀ (a : _) (b : _), Eq a b
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn untyped() -> Prop { for<a, b> a == b }

/-! F7 (iv): a quantifier's scope extends as far right as possible — it swallows every
operator, including `->`. Conjoining from outside means parenthesising the quantifier. -/

/--
info: set_option autoImplicit false in
def scope (p : Prop) (q : Prop) : Prop :=
  ∀ (x : Nat), And p q
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn scope(p: Prop, q: Prop) -> Prop { for<x: Nat> p && q }

/--
info: set_option autoImplicit false in
def scope_stopped (p : Prop) (q : Prop) : Prop :=
  And (∀ (x : Nat), p) q
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn scope_stopped(p: Prop, q: Prop) -> Prop { (for<x: Nat> p) && q }

/-! F12: a `for<>` header never captures `in`. The header is bracketed, so the `in` here is
unambiguously the membership operator in the body. -/

/--
info: set_option autoImplicit false in
def all_member (s : NatList) : Prop :=
  ∀ (x : Nat), Membership.mem s x
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn all_member(s: NatList) -> Prop { for<x: Nat> x in s }

/-! ## Tier 2 — elaboration

Corpus Group 8's two definitions, which are quantifiers and nothing else.
-/

fn injective(f: Nat -> Nat) -> Prop { for<a1, a2: Nat> (f(a1) == f(a2)) -> a1 == a2 }
fn surjective(f: Nat -> Nat) -> Prop { for<b: Nat> exists<a: Nat> f(a) == b }

theorem id_injective() -> injective(|x| x) { lean! { intro a1 a2 h; exact h } }
theorem id_surjective() -> surjective(|x| x) { lean! { intro b; exact ⟨b, rfl⟩ } }

/-- info: 'id_injective' does not depend on any axioms -/
#guard_msgs in
#print axioms id_injective

/-- info: 'id_surjective' does not depend on any axioms -/
#guard_msgs in
#print axioms id_surjective

/-! ## Tier 3 — negative

The Rust reading of `for<a, b: Nat>` binds only `b`, leaving `a`'s type free. FH binds
both, so a body that uses `a` at another type is an error — which is the observable
difference between the two readings, and the negative test F2 asks for.
-/

/--
error: Application type mismatch: The argument
  a
has type
  Nat
but is expected to have type
  Bool
in the application
  is_true a
-/
#guard_msgs in
fn rust_reading() -> Prop { for<a, _b: Nat> is_true(a) }

/-! ## Tier 4 — span

The error lands on the operand, in FH source.
-/

/-- info: error @ +0:53-54 «a» -/
#guard_msgs in
#fh_spans in
fn rust_reading2() -> Prop { for<a, _b: Nat> is_true(a) }
