/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Syntax.Basic

/-!
# The Mathlib object bridge (A2.5, design §6)

Design §6: "the bridge module ships pre-built aliases for the objects from our
conversation — `Fp<P>` = `ZMod P`, with the crucial subtlety that Mathlib's
field-structure instance requires `[Fact p.Prime]`, so our `where P: Prime` bound expands
to exactly that `Fact` binder (this is precisely the 'dependent bound Rust couldn't
express' made real…); `Poly<R>` = `Polynomial R`; `Fractions<R>` = `FractionRing R`;
`Quotient<R, I>` = `R ⧸ I`."

Two hooks, both following the F16 pattern exactly: `use lean::Fp;` opens
`FerrisHoward.Bridge.Fp`, whose `scoped macro_rules` gives the name meaning, and outside
that import `Fp<P>` is an ordinary application of whatever `Fp` you declared.

## This module does not import Mathlib, and could not need to

Stage one produces *syntax*. `Fp<P>` becomes the syntax `ZMod P`, and `ZMod` resolves in
the file that wrote `Fp<P>` — which imports Mathlib, because it is doing mathematics.
Nothing here needs the constant to exist at macro-definition time.

That is not a trick; it is the property ADR-006 is buying. The bridge adds no dependency
to FH's core, and the emitted artifact contains `ZMod P` — Mathlib's own name, with no FH
module behind it.

The names are built with `mkIdent` and are therefore **unhygienic**, which is the point:
they must resolve where the user wrote the alias, not where the bridge was defined. The
F16 method bridge does the same thing for the same reason.

## What needs no bridge

**Morphisms.** Design §6's no-mangling policy already makes `RingHom<A, B>`,
`MonoidHom<A, B>` and `LinearMap<R, M, N>` reachable verbatim; the arrow notations
(`→+*`, `→*`) are spellings of exactly those names. An alias would add a second way to
write the same thing.

**Operators.** Design §4.7 notes that "Rust's `Add/Mul/Neg/Index` trait vocabulary
coincides with Lean's `HAdd/HMul/Neg/GetElem` almost name-for-name". FH's operator
expansion already emits those constants directly (A1.5), so `a + b` works on Mathlib types
without anything here.
-/

namespace FerrisHoward
open Lean

/-! ## The hooks

`fh_ty%` carries a generic application whose callee is an identifier, `fh_bound%` carries
a `where` bound. Each has a default rule rebuilding what FH produced before any bridge
existed, so a file with no `use lean::…` behaves exactly as it always did — the same
discipline `fh_dot%` follows.
-/

/-- The default meaning of `F<a, b>`: application, unchanged. -/
macro_rules
  | `(fh_ty% $f $args*) => `($f $args*)

/-- The default meaning of a `where` bound: the class applied to the carrier, which is
what `where R: CommRing` meant before this hook existed. -/
macro_rules
  | `(fh_bound% $c $x) => `($c $x)

/-! ## The object aliases

One namespace per name, so `use lean::Fp;` brings in exactly `Fp` and nothing else.
-/

namespace Bridge.Fp

/-- `Fp<P>` is `ZMod P` — the integers mod `P`, which is a *field* exactly when `P` is
prime. Pair it with `use lean::Prime;`, which supplies the binder that makes it one. -/
scoped macro_rules
  | `(fh_ty% Fp $p) => do let c := mkIdent `ZMod; `($c $p)

end Bridge.Fp

namespace Bridge.Prime

/-- `where P: Prime` is `[Fact (Nat.Prime P)]`.

This is design §6's flagship, and the reason it is a *bridge* rather than an alias: the
bound a mathematician writes ("let p be prime") and the binder Mathlib's instance needs
(`Fact p.Prime`, because instance search cannot look inside a proposition) are different
things, and FH is where the translation lives. It is also the dependent bound Rust cannot
express — `where P: Prime` constrains a *value*, not a type. -/
scoped macro_rules
  | `(fh_bound% Prime $p) => do
      let fact := mkIdent `Fact
      let prime := mkIdent `Nat.Prime
      `($fact ($prime $p))

end Bridge.Prime

namespace Bridge.LinearMap

/-- `LinearMap<K, V, W>` is `V →ₗ[K] W`.

The one morphism alias that needs a bridge. `RingHom<A, B>` and `MonoidHom<A, B>` are
already reachable verbatim under design §6's no-mangling policy, but Mathlib's
`LinearMap` is *semilinear* — its first argument is a ring homomorphism, and the ordinary
linear case supplies `RingHom.id`. The arrow notation hides that; so does this. -/
scoped macro_rules
  | `(fh_ty% LinearMap $k $v $w) => do
      let c := mkIdent `LinearMap
      let idh := mkIdent `RingHom.id
      `($c ($idh $k) $v $w)

end Bridge.LinearMap

namespace Bridge.Poly

/-- `Poly<R>` is `Polynomial R`.

Nested, as in `Poly<Fp<P> >`, needs the space until I5's `>`-splitting lexer lands. -/
scoped macro_rules
  | `(fh_ty% Poly $r) => do let c := mkIdent `Polynomial; `($c $r)

end Bridge.Poly

namespace Bridge.Fractions

/-- `Fractions<R>` is `FractionRing R`. -/
scoped macro_rules
  | `(fh_ty% Fractions $r) => do let c := mkIdent `FractionRing; `($c $r)

end Bridge.Fractions

namespace Bridge.Quotient

/-- `Quotient<R, I>` is `R ⧸ I`.

The expansion names `HasQuotient.Quotient` rather than the notation, because that is what
the notation means and FH has no reason to route through a second elaborator to get
there. -/
scoped macro_rules
  | `(fh_ty% Quotient $r $i) => do let c := mkIdent `HasQuotient.Quotient; `($c $r $i)

end Bridge.Quotient

end FerrisHoward
