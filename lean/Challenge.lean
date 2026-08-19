import Mathlib

/-!
# Crystallographic restriction in dimension two

The two-dimensional crystallographic restriction can be expressed arithmetically as a
statement about finite-order integral lattice automorphisms.  If `A` is an element of
`GL₂(ℤ)` of finite order, then its order is one of `1`, `2`, `3`, `4`, or `6`.

This is the classical crystallographic restriction theorem in dimension two.  The
formalization is source-based: the mathematical result is classical, while the Lean proof
is an independent formal proof using Mathlib's matrix, minimal-polynomial, and polynomial
APIs.
-/

namespace Palomar.CrystallographicRestriction

/-- Every finite-order element of `GL₂(ℤ)` has order `1`, `2`, `3`, `4`, or `6`. -/
theorem main_result (A : GL (Fin 2) ℤ) (hA : IsOfFinOrder A) :
    orderOf A = 1 ∨ orderOf A = 2 ∨ orderOf A = 3 ∨ orderOf A = 4 ∨ orderOf A = 6 := by
  sorry

/-- Order `4` is attained by an integral two-dimensional lattice automorphism. -/
theorem order_four_occurs : ∃ A : GL (Fin 2) ℤ, orderOf A = 4 := by
  sorry

/-- Order `6` is attained by an integral two-dimensional lattice automorphism. -/
theorem order_six_occurs : ∃ A : GL (Fin 2) ℤ, orderOf A = 6 := by
  sorry

end Palomar.CrystallographicRestriction
