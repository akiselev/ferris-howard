/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · the kind vocabulary (A2.4, F18, design §4.8)

Design §4.8: "The kind of a domain-of-discourse variable is written `Space`, not `Type` —
'let A be a space of things' rather than a prover-internals term — elaborating to `Type*`
(universe-polymorphic) with `Space<u>` for explicit universes and `Sort<u>` retained as the
full-generality escape. `Prop` is kept as-is: it already says what it means."

* **Stage: one.**
* **Ruling D:** *confined* — `Space` is not a Rust word and `Sort` in type position is not
  Rust syntax, so neither can change the meaning of anything that is also legal Rust.
* **Sorry count: zero.**

## Words, not keywords

`Space` is recognised by *name* at expansion time rather than given a production, so FH
reserves no token for it and nothing in Lean's or Mathlib's namespace is shadowed. The
price is that a declaration actually named `Space` is unreachable from FH — the same trade
`Prop` already makes, and it is on the differences page.

`Sort` needs a production anyway, because Lean's lexer makes it a keyword and so it never
arrives as an identifier. Same reason `Prop` has one.

## Why a hole and not `Type*`

Design says `Type*`, which is Mathlib's. FH emits `Type _`, which is Lean's, and the two
elaborate identically — Lean binds a universe parameter for the declaration, which is what
"universe-polymorphic" means in practice. Using the hole keeps the core library free of a
Mathlib dependency, and it keeps the emitted artifact free of one too (ADR-006).

## `#[universes(u, v)]`

FH turns `autoImplicit` off, and that turns universe auto-binding off with it, so a
*named* level has to be declared. The attribute is that declaration, and it becomes a
`universe … in` wrapper. Most code never needs it: the unapplied `Space` takes a hole and
Lean does the binding.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in def id1 {A : Type _} (a : A) : A := a -/
#guard_msgs (whitespace := lax) in
#fh_expand fn id1<A: Space>(a: A) -> A { a }

/-- info: set_option autoImplicit false in def id2 {A : Sort _} (a : A) : A := a -/
#guard_msgs (whitespace := lax) in
#fh_expand fn id2<A: Sort>(a: A) -> A { a }

/-! The applied forms, and the attribute that makes the name legal.

The space in `Space<u> >` is the nested-generics restriction: `>>` is one token until I5's
`>`-splitting lexer lands. -/

/--
info: set_option autoImplicit false in
universe u in
def id3 {A : Type u} (a : A) : A := a
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[universes(u)] fn id3<A: Space<u> >(a: A) -> A { a }

/--
info: set_option autoImplicit false in
universe u v in
def konst {A : Type u} {B : Type v} (a : A) (_b : B) : A := a
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[universes(u, v)] fn konst<A: Space<u>, B: Space<v> >(a: A, _b: B) -> A { a }

/-! `Space` is an ordinary annotation, so it works wherever one does. -/

/-- info: set_option autoImplicit false in structure Wrap (T : Type _) where get : T -/
#guard_msgs (whitespace := lax) in
#fh_expand struct Wrap<T: Space> { get: T }

/-! ## Tier 2 — elaboration

The claim being tested is *polymorphism*, not that the word parses: one declaration, used
at two different universes.
-/

fn id1<A: Space>(a: A) -> A { a }

/-- info: @id1 : {A : Type u_1} → A → A -/
#guard_msgs in
#check @id1

example : Nat := id1 3
example : Type := id1 Nat

/-- info: 'id1' does not depend on any axioms -/
#guard_msgs in
#print axioms id1

/-! `Sort` reaches further than `Space` does — down to `Prop`, which `Type _` cannot
express. That is the whole reason design §4.8 keeps it. -/

fn id2<A: Sort>(a: A) -> A { a }

/-- info: @id2 : {A : Sort u_1} → A → A -/
#guard_msgs in
#check @id2

example : True := id2 trivial

/-! A named universe gives the same signature — the name is for when a declaration needs
to *relate* two levels, not for the common case. -/

#[universes(u)] fn id3<A: Space<u> >(a: A) -> A { a }

/-- info: @id3 : {A : Type u_1} → A → A -/
#guard_msgs in
#check @id3

/-! ## Tier 3 — negative -/

/-- error: FH: `Space<…>` takes a universe name, which `#[universes(…)]` declares -/
#guard_msgs in
fn lit_universe<A: Space<3> >(a: A) -> A { a }

/-- error: FH: `Space<…>` takes one universe name -/
#guard_msgs in
fn two_universes<A: Space<u, v> >(a: A) -> A { a }

/-! And the attribute is not optional: an undeclared level is Lean's own error, because
`autoImplicit false` means there is nothing to auto-bind. -/

/-- error: unknown universe level `w` -/
#guard_msgs in
fn undeclared<A: Space<w> >(a: A) -> A { a }

/-- error: FH: `#[universes(…)]` takes universe names -/
#guard_msgs in
#[universes(3)] fn bad_attr(n: Nat) -> Nat { n }

/-! ## Tier 4 — span -/

/-- info: error @ +0:26-27 «3» -/
#guard_msgs in
#fh_spans in
fn lit_universe2<A: Space<3> >(a: A) -> A { a }
