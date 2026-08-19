import Crystal.Wallpaper.Restriction

/-!
# Proved solution for the two-dimensional crystallographic restriction

Comparator checks that the declarations below have exactly the statements advertised in
`Challenge.lean`.  The proof development itself lives in
`Crystal.Wallpaper.Restriction`.
-/

namespace Palomar.CrystallographicRestriction

/-- The classical two-dimensional crystallographic restriction. -/
theorem main_result (A : GL (Fin 2) ℤ) (hA : IsOfFinOrder A) :
    orderOf A = 1 ∨ orderOf A = 2 ∨ orderOf A = 3 ∨ orderOf A = 4 ∨ orderOf A = 6 := by
  exact Crystal.Wallpaper.crystallographic_restriction A hA

/-- The restriction is sharp at order `4`. -/
theorem order_four_occurs : ∃ A : GL (Fin 2) ℤ, orderOf A = 4 := by
  exact ⟨Crystal.Wallpaper.rot4, Crystal.Wallpaper.orderOf_rot4⟩

/-- The restriction is sharp at order `6`. -/
theorem order_six_occurs : ∃ A : GL (Fin 2) ℤ, orderOf A = 6 := by
  exact ⟨Crystal.Wallpaper.rot6, Crystal.Wallpaper.orderOf_rot6⟩

end Palomar.CrystallographicRestriction
