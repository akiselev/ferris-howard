/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 9 — category theory: the stage-one acid test

`corpus-review.md` Group 9, made executable. The review is explicit about why this group
exists:

> Group 9 is deliberately the elaboration stress-maximum: if stage-one macros can expand
> this to Lean `class` syntax and Lean elaborates it, the architecture is validated.

It does, and it is. **The corpus text below is unchanged** — not one character was moved,
and no bridge, escape or ascription was needed.

* **Stage: one.**
* **Ruling D:** *confined* — a `trait` body carrying laws and dependent field types has no
  Rust counterpart.
* **Sorry count: zero.** The class elaborates and an instance discharges every law.

## What had to work at once

**A field whose type is computed by applying another field.** `Hom(a, b)` appears in
binder position (`f: Hom(a, b)`) and in return position (`-> Hom(a, c)`), referring to the
`Hom` field declared two lines earlier. That is full dependency *inside* a trait body, and
it works because design §4.1 gave FH one expression grammar: `Hom(a, b)` is a call, there
is no separate type grammar that would have had to learn about it.

**Explicit universes.** `Space<u>` and `Space<v>` under `#[universes(u, v)]`, which is
A2.4's attribute. `Cat.{u, v} (Self : Type u) : Type (max u (v + 1))` is what comes out —
FH names the levels and Lean computes the class's own.

**F1's hard case.** `comp(id(), f)`: `id()` has *no argument* from which to infer its
object, and the corpus review flags this as "F1 again, harder — needs the expected-type
machinery to thread through `comp`'s unification; this group is the acid test for it".
It threads. `id` is an implicit-argument field, `comp`'s first explicit argument fixes
`a`, and Lean's unifier does the rest. FH contributed nothing but the spelling, which is
the correct amount.

No findings. The group was written to break the architecture and did not.
-/

/-! ## The corpus, verbatim -/

#[universes(u, v)]
trait Cat<Self: Space<u> > {
    fn Hom(a: Self, b: Self) -> Space<v>;

    fn id<a: Self>() -> Hom(a, a);
    fn comp<a: Self, b: Self, c: Self>(f: Hom(a, b), g: Hom(b, c)) -> Hom(a, c);

    id_comp: for<a, b: Self> for<f: Hom(a, b)> comp(id(), f) == f;
    comp_id: for<a, b: Self> for<f: Hom(a, b)> comp(f, id()) == f;
    assoc:   for<a, b, c, d: Self>
             for<f: Hom(a, b), g: Hom(b, c), h: Hom(c, d)>
                 comp(comp(f, g), h) == comp(f, comp(g, h));
}

/-! ## Tier 1 — golden expansion

`#[universes(u, v)]` becomes a `universe … in` wrapper, `Space<u>` becomes `Type u`, and
each `fn` becomes a field whose type mentions the field above it.
-/

/--
info: set_option autoImplicit false in
universe u v in
class Cat2 (Self : Type u) where
  Hom (a : Self) (b : Self) : Type v
  id {a : Self} : Hom a a
  comp {a : Self} {b : Self} {c : Self} (f : Hom a b) (g : Hom b c) : Hom a c
  id_comp : ∀ (a : Self) (b : Self), ∀ (f : Hom a b), Eq (comp (id) f) f
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[universes(u, v)]
trait Cat2<Self: Space<u> > {
    fn Hom(a: Self, b: Self) -> Space<v>;
    fn id<a: Self>() -> Hom(a, a);
    fn comp<a: Self, b: Self, c: Self>(f: Hom(a, b), g: Hom(b, c)) -> Hom(a, c);
    id_comp: for<a, b: Self> for<f: Hom(a, b)> comp(id(), f) == f;
}

/-! ## Tier 2 — elaboration

The class Lean actually built. Note the universe it computes for itself,
`Type (max u (v + 1))` — FH named `u` and `v`; that is Lean's arithmetic.
-/

/--
info: class Cat.{u, v} (Self : Type u) : Type (max u (v + 1))
number of parameters: 1
fields:
  Cat.Hom : Self → Self → Type v
  Cat.id : {a : Self} → Cat.Hom a a
  Cat.comp : {a b c : Self} → Cat.Hom a b → Cat.Hom b c → Cat.Hom a c
  Cat.id_comp : ∀ (a b : Self) (f : Cat.Hom a b), Cat.comp Cat.id f = f
  Cat.comp_id : ∀ (a b : Self) (f : Cat.Hom a b), Cat.comp f Cat.id = f
  Cat.assoc : ∀ (a b c d : Self) (f : Cat.Hom a b) (g : Cat.Hom b c) (h : Cat.Hom c d),
      Cat.comp (Cat.comp f g) h = Cat.comp f (Cat.comp g h)
constructor:
  Cat.mk.{u, v} {Self : Type u} (Hom : Self → Self → Type v) (id : {a : Self} → Hom a a)
    (comp : {a b c : Self} → Hom a b → Hom b c → Hom a c) (id_comp : ∀ (a b : Self) (f : Hom a b), comp id f = f)
    (comp_id : ∀ (a b : Self) (f : Hom a b), comp f id = f)
    (assoc : ∀ (a b c d : Self) (f : Hom a b) (g : Hom b c) (h : Hom c d), comp (comp f g) h = comp f (comp g h)) :
    Cat Self
-/
#guard_msgs (whitespace := lax) in
#print Cat

/-! ### The class is inhabited

A class that elaborates but has no instances proves less than it looks. Here is the
one-object category on `Unit`, with all three laws discharged — and no `sorry`, so the
laws are facts rather than assumptions.
-/

impl Cat for Unit {
    fn Hom(_a: Unit, _b: Unit) -> Space { PUnit }
    fn id<_a: Unit>() -> PUnit { PUnit::unit }
    fn comp<_a: Unit, _b: Unit, _c: Unit>(_f: PUnit, _g: PUnit) -> PUnit { PUnit::unit }

    id_comp: lean! { intro a b f; rfl };
    comp_id: lean! { intro a b f; rfl };
    assoc:   lean! { intro a b c d f g h; rfl };
}

/-- info: 'instCatUnit' does not depend on any axioms -/
#guard_msgs in
#print axioms instCatUnit

/-! And F1's hard case is usable from outside the class too: `Cat::id()` with the object
supplied by what it is composed with. -/

fn unit_id() -> Cat::Hom(Unit::unit, Unit::unit) { Cat::id() }

/-- info: 'unit_id' does not depend on any axioms -/
#guard_msgs in
#print axioms unit_id

/-! ## Tier 3 — negative

The laws are fields, so an `impl` that skips one is Lean's own missing-field error. A
category without associativity is not a category, and there is no way to be quiet about
it.
-/

/-- error: Fields missing: `assoc` -/
#guard_msgs in
impl Cat for Bool {
    fn Hom(_a: Bool, _b: Bool) -> Space { PUnit }
    fn id<_a: Bool>() -> PUnit { PUnit::unit }
    fn comp<_a: Bool, _b: Bool, _c: Bool>(_f: PUnit, _g: PUnit) -> PUnit { PUnit::unit }

    id_comp: lean! { intro a b f; rfl };
    comp_id: lean! { intro a b f; rfl };
}

/-! A universe name must be declared — `#[universes(…)]` is what declares it, and FH turns
`autoImplicit` off so there is nothing to auto-bind. -/

/-- error: unknown universe level `w` -/
#guard_msgs in
trait NoUniverse<Self: Space<w> > {
    fn Hom(a: Self, b: Self) -> Prop;
}

/-! ## Tier 4 — span -/

/-- info: error @ +0:30-31 «w» -/
#guard_msgs in
#fh_spans in
trait NoUniverse2<Self: Space<w> > {
    fn Hom(a: Self, b: Self) -> Prop;
}
