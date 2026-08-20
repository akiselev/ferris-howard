/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · ambient variables (A2.4, F17, design §4.8)

`var eps: Real;` is Lean's `variable`, and that is the whole implementation. Lean's
`variable` **is** F17's mention-based inclusion — a declaration gets an ambient variable
exactly when it mentions it — and Lean's `include` is F17's escape for a hypothesis that
is needed but unmentioned. Both are commands, so both are stage one and free.

* **Stage: one.**
* **Ruling D:** *confined* — Rust has no ambient-declaration form for these to disagree
  with.
* **Sorry count: zero.**

## Each declaration generalizes independently

Design §4.8 fixes this deliberately: the module is not a functor parameterized once.
`twice` binds its own `∀ A`, and a second declaration in the same scope binds its own. The
`Ambient` / `Inline` pair below is the test — the same two declarations written both ways,
with signatures and bodies asserted *identical*.

## The annotation decides the binder

A **carrier** — a kind (`Space`, `Sort`, `Prop`) or a structure (`impl Grp`) — is
implicit, which is the binder `fn f<G>(…)` already produces and the one Mathlib writes.
Anything else is an explicit value or hypothesis. That rule is what makes design §4.8's
"inline generics shadow ambient `var`s" mean one thing rather than two: shadowing an
ambient `A: Space` with an inline `<A: Space>` changes nothing about the resulting
signature, which the pair below demonstrates.

## One deviation from design §4.8, and it is reversible

Design writes the structure form as `var G: Grp;` and disambiguates it from
`var eps: Real;` "by what the name resolves to". Name resolution needs the environment,
which is stage two, and ADR-006 makes stage one load-bearing — so FH asks for a marker
instead: `var G: impl Grp;`.

`impl Trait` is Rust's own vocabulary with its actual Rust meaning, "some type implementing
`Grp`", and design §5 had already dropped it from return position, so the spelling was
free. When a resolution mechanism exists the marker becomes *optional* rather than
required, which is a non-breaking change — Ruling B's test, and the reason to require it
now rather than guess.
-/

/-! ## Tier 1 — golden expansion

Four annotation forms, four binder shapes.
-/

/-- info: variable (eps : Real) -/
#guard_msgs (whitespace := lax) in
#fh_expand var eps: Real;

/-- info: variable {A : Type _} -/
#guard_msgs (whitespace := lax) in
#fh_expand var A: Space;

/-- info: variable {P : Prop} -/
#guard_msgs (whitespace := lax) in
#fh_expand var P: Prop;

/-- info: variable {G : Type _} [Grp G] -/
#guard_msgs (whitespace := lax) in
#fh_expand var G: impl Grp;

/-! A trait *sum* is one carrier and several instances — "let R be a finite commutative
ring". -/

/-- info: variable {R : Type _} [CommRing R] [Finite R] -/
#guard_msgs (whitespace := lax) in
#fh_expand var R: impl CommRing + Finite;

/-- info: include h -/
#guard_msgs (whitespace := lax) in
#fh_expand include h;

/-! ## Tier 2 — elaboration

### The identical-elaboration obligation (F17)

The same declaration written twice — inline generics, then ambient `var`s — and the
elaborated results asserted equal. This is the property that makes `var` a *notation* for
what FH could already say, rather than a second semantics.
-/

mod Inline {
  fn twice<A: Space>(f: A -> A, a: A) -> A { f(f(a)) }
}

mod Ambient {
  var A: Space;
  var f: A -> A;

  fn twice(a: A) -> A { f(f(a)) }
}

/-- info: @Inline.twice : {A : Type u_1} → (A → A) → A → A -/
#guard_msgs in
#check @Inline.twice

/-- info: @Ambient.twice : {A : Type u_1} → (A → A) → A → A -/
#guard_msgs in
#check @Ambient.twice

/-! Not just the signature — the body too. -/

/--
info: def Inline.twice.{u_1} : {A : Type u_1} → (A → A) → A → A :=
fun {A} f a => f (f a)
-/
#guard_msgs (whitespace := lax) in
#print Inline.twice

/--
info: def Ambient.twice.{u_1} : {A : Type u_1} → (A → A) → A → A :=
fun {A} f a => f (f a)
-/
#guard_msgs (whitespace := lax) in
#print Ambient.twice

/-! ### The structured form

"Let G be a group" — one declaration folding the carrier and its structure, which is both
the mathematician's phrasing and Mathlib's house style. This is corpus Group 2's
`id_unique`, restated with the group ambient rather than inline. -/

mod Structured {
  var G: impl Group;

  theorem id_unique() -> for<e: G> (for<a: G> e * a == a) -> e == 1 {
    lean! { intro e h; simpa using h 1 }
  }
}

/--
info: @Structured.id_unique : ∀ {G : Type u_1} [inst : Group G] (e : G), (∀ (a : G), e * a = a) → e = 1
-/
#guard_msgs in
#check @Structured.id_unique

/-- info: 'Structured.id_unique' depends on axioms: [propext] -/
#guard_msgs in
#print axioms Structured.id_unique

/-! ### The ambient-hypothesis pair (F17)

Design §4.8 calls for this test explicitly, because it surprises even Lean users: a `var`
whose type is a *Prop* is a hypothesis, and it follows the same mention rule as everything
else. The rule bites where the hypothesis is needed but not named in the statement.
-/

section
var eps: Real;
var h: eps > 0;

/-! `h` is mentioned in the proof but not the statement, so the mention rule does not pick
it up and `include` is what says otherwise. Both declarations below are in scope of both
`var`s; only the second gets `h`. -/

theorem eps_le_self() -> eps <= eps { lean! { exact le_refl eps } }

include h;

theorem eps_nonneg() -> eps >= 0 { lean! { exact le_of_lt h } }
end

/-- info: eps_le_self : ∀ (eps : ℝ), eps ≤ eps -/
#guard_msgs in
#check @eps_le_self

/-- info: eps_nonneg : ∀ eps > 0, eps ≥ 0 -/
#guard_msgs in
#check @eps_nonneg

/-! And the scope closes at `end`, so neither variable reaches here. -/

theorem outside() -> (0: Real) <= 1 { lean! { norm_num } }

/-- info: outside : 0 ≤ 1 -/
#guard_msgs in
#check @outside

/-! ### Shadowing, and the lint that says so

Design §4.8: "inline generics shadow ambient `var`s but must restate the annotation in
full, with a shadowing lint."

Both halves come free. Shadowing works because Lean's `variable` is consulted only for
names a declaration does not bind itself, and the annotation is restated in full because
FH's generics always carry one — `<A>` means `{A : Type _}` whatever the ambient `A` said.
The warning is the part that had to be built, and it is a warning rather than an error
because shadowing is sometimes what you want.
-/

section
var A: Space;

/--
warning: `A` shadows an ambient `var` of the same name. That is legal, and the inline annotation wins in full — including any structure the `var` carried, which this declaration does not inherit.

Note: This linter can be disabled with `set_option linter.fh.varShadow false`
-/
#guard_msgs in
fn shadowed<A: Space>(a: A) -> A { a }

/-! A different name is silent, which is the point of naming the one that collides. -/

#guard_msgs in
fn unshadowed<B: Space>(b: B) -> B { b }

/-! And it is a lint, so a file that means it can say so. -/

#guard_msgs in
set_option linter.fh.varShadow false in
fn quiet<A: Space>(a: A) -> A { a }

/-! Quantifier binders are the same shape and the same hazard, so they are covered too. -/

/--
warning: `A` shadows an ambient `var` of the same name. That is legal, and the inline annotation wins in full — including any structure the `var` carried, which this declaration does not inherit.

Note: This linter can be disabled with `set_option linter.fh.varShadow false`
-/
#guard_msgs in
theorem quantified() -> for<A: Space> for<a: A> a == a { lean! { intro A a; rfl } }
end

/-! ## Tier 3 — negative -/

/-- error: FH: attributes are not supported on `var` -/
#guard_msgs in
#[simp] var bad: Real;

/-- error: FH: attributes are not supported on `include` -/
#guard_msgs in
#[simp] include bad;

/-! A0.6's identifier rule reaches here too: an ambient variable is a binding site like
any other. -/

/--
error: FH: `eps!` — an identifier may not end in `?` or `!`; Lean's lexer would swallow the operator into the name
-/
#guard_msgs in
var eps!: Real;

/-! ## Tier 4 — span -/

/-- info: error @ +0:4-8 «bad!» -/
#guard_msgs in
#fh_spans in
var bad!: Real;
