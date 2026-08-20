/-
Copyright (c) 2026 Ferris-Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward.Atlas.Home

/-!
# Candidate generalizations, kernel-verified

Twenty-nine Mathlib declarations whose proof term typechecks under a **strictly weaker**
typeclass hypothesis than the one they declare, found by B3's citation-based evidence rule
and confirmed by Lean's kernel.

Each line below re-derives the result: `#fh_home_refute <decl> <class>` rebuilds the
declaration with the named weaker binder, re-synthesises every instance argument in the
weakened context, and reports the kernel's verdict. `CONFIRMED` means the term typechecks —
sound and final. (`REFUTED` is inconclusive; see `FerrisHoward/Atlas/Home.lean`.)

## Why these are not reachable by Mathlib's own linters

The shipped set is `unusedArguments` (Batteries), which fires only when a binder is used
*nowhere*; `impossibleInstance` / `nonClassInstance`, which concern inferability rather than
strength; and Mathlib's `unusedDecidableInType`, which is off by default, `Decidable`-only,
and asks a question about the *type*. None performs typeclass weakening.

`Additive.ofMul_le` is the clean case: its `Preorder` binder genuinely *is* used, for the
`≤` in its statement, so `unusedArguments` is silent by construction — while the proof needs
only `LE`.

## Provenance and limits

Found on a 131,062-declaration slice (`Mathlib.Algebra.Order.Field.Basic`'s closure) out of
Mathlib's ~348,810. Checked against that slice for an existing general version two ways —
`equivalent` at `instances` level (exact) and near-duplicate search at retention >= 0.85 with
strictly weaker binders — and all 29 survived both. A general version elsewhere in Mathlib
would not have been seen; re-running the same two checks against the full slice is what
closes that.

Most are type-synonym transfer lemmas over-assuming structure. Two are more than that:
`even_iff_exists_two_mul` (drops associativity) and `div_le_iff₀'` (swaps
`PosMulReflectLT` for `MulPosReflectLT` across a 38-citation proof).
-/

set_option maxHeartbeats 1000000

#fh_home_refute Additive.ofMul_le LE
#fh_home_refute Array.step_iterM Pure
#fh_home_refute List.step_iterM_nil Pure
#fh_home_refute Multiplicative.toAdd_lt LT
#fh_home_refute Std.Iterators.Vector.isPlausibleStep_iterFromIdxM_of_lt Pure
#fh_home_refute WithBot.bot_ne_natCast NatCast
#fh_home_refute WithTop.exists_le_coe LE
#fh_home_refute WithTop.natCast_lt_top NatCast
#fh_home_refute WithTop.natCast_ne_top NatCast
#fh_home_refute bddBelow_preimage_ofDual LE
#fh_home_refute div_le_iff₀' MulPosReflectLT
#fh_home_refute even_iff_exists_two_mul NonAssocSemiring
#fh_home_refute isAddLeftRegular_ofMul Mul
#fh_home_refute isAddLeftRegular_toAdd Add
#fh_home_refute isAddLeftRegular_toColex Add
#fh_home_refute isAddLeftRegular_toLex Add
#fh_home_refute isAddRightRegular_toDual Add
#fh_home_refute isLeftRegular_ofColex Mul
#fh_home_refute isLeftRegular_toMul Mul
#fh_home_refute isRightRegular_ofDual Mul
#fh_home_refute isRightRegular_toDual Mul
#fh_home_refute isRightRegular_toLex Mul
#fh_home_refute le_min_iff SemilatticeInf
#fh_home_refute lowerBounds_union LE
#fh_home_refute mem_upperBounds LE
#fh_home_refute nsmul_eq_smul NSMul
#fh_home_refute subset_lowerBounds_upperBounds LE
#fh_home_refute uniform_continuous_npow_on_bounded IsOrderedRing
#fh_home_refute upperBounds_mono_set LE
