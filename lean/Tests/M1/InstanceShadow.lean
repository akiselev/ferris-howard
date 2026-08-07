/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · the instance-shadowing lint (A1.6, design §4.4)

Rust's coherence and orphan rules do not carry over — Lean has none and Mathlib depends on
that. Design §4.4 takes the diagnostic route instead of the prohibitive one, and this is
the diagnostic.

* **Stage:** neither. It is a post-elaboration linter, so it is not part of the
  translation and switching it off changes no meaning.
* **Ruling D:** none. FH adopts Lean's permissiveness; the divergence from Rust is the
  *absence* of a rule, which `differences.md` records under §4.4's heading.
* **Sorry count: zero.**

A lint rather than an error, deliberately: two instances for one class and carrier are
sometimes exactly what is wanted and sometimes an afternoon lost. FH cannot tell which, so
it reports and gets out of the way.
-/

trait Pointed<Self> { fn base() -> Self; }

/-! ## The first instance is silent -/

impl Pointed for Nat { fn base() -> Nat { 0 } }

/-! ## The second is not

It names what was already there, because "there is another one" is useless without
"which".
-/

/--
warning: this class and carrier already had an instance: [altNat,
 instPointedNat]. Lean has no orphan rule, so two are legal — but if it was not intended, instance search will pick one and not tell you which.

Note: This linter can be disabled with `set_option linter.fh.instanceShadow false`
-/
#guard_msgs in
#[name(altNat)] impl Pointed for Nat { fn base() -> Nat { 1 } }

/-! ## A different carrier is not shadowing -/

impl Pointed for Bool { fn base() -> Bool { true } }

/-! ## And it can be switched off

Two `Fintype`s — one to compute with, one to reason about — is a real pattern, and a file
that means it says so.
-/

set_option linter.fh.instanceShadow false in
#[name(thirdNat)] impl Pointed for Nat { fn base() -> Nat { 2 } }

/-! ## Nothing else changed

The lint reports; it does not alter what the instances are.
-/

example : (Pointed.base : Bool) = true := rfl

/-- info: 'instPointedBool' does not depend on any axioms -/
#guard_msgs in
#print axioms instPointedBool
