/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Crystal.Wallpaper.Groups.Basic

/-!
# W1, second witness — p2, lattice translations and point inversions

`P2` adjoins to the p1 translations every *point inversion* `x ↦ -x + v` with `v` in the
lattice — inversion through the point `v/2`, said without division so the carrier stays
in the lattice's own vocabulary.  `p2_isWallpaperGroup` is the second component of
`census_existence`.

Specific to p2:

* The composition table has four cases, each a pointwise calculation: inversion twice is
  a translation by the *difference* of the vectors, so the twisted elements bring no new
  translation vectors and `transVecs P2 = stdLattice` still.
* An inversion-form element is never a translation (`inversion_form_not_isTranslationBy`):
  the two forms force `-x = x` for all `x`, false at `stdVec 0` in characteristic 0.
* The coset condition holds with `{1, pointInversion}` — index two over the translations.
-/

namespace Crystal.Wallpaper

/-- Point inversion through the origin, `x ↦ -x` — Mathlib's negation linear isometry,
forgotten down to a plain isometry so it can live in `E2`. -/
noncomputable def pointInversion : E2 := (LinearIsometryEquiv.neg ℝ).toIsometryEquiv

theorem pointInversion_apply (x : Plane) : pointInversion x = -x := rfl

/-- An inversion-form element is not a translation: matching the two forms at the origin
identifies the vectors, and then `-x = x` for every `x` — false at `stdVec 0`. -/
theorem inversion_form_not_isTranslationBy {g : E2} {v u : Plane}
    (hg : ∀ x, g x = -x + v) (hu : IsTranslationBy g u) : False := by
  have h0 : v = u := by
    have h := (hg 0).symm.trans (hu 0)
    simpa using h
  have h1 := (hg (stdVec 0)).symm.trans (hu (stdVec 0))
  rw [h0] at h1
  exact stdVec_ne_neg_stdVec 0 (add_right_cancel h1).symm

/-- **p2**: translations by lattice vectors together with inversion-form maps
`x ↦ -x + v`, `v` in the lattice. -/
def P2 : Subgroup E2 where
  carrier := {g | ∃ v ∈ stdLattice, IsTranslationBy g v ∨ ∀ x, g x = -x + v}
  one_mem' := ⟨0, zero_mem _, Or.inl fun x => (add_zero x).symm⟩
  mul_mem' := by
    rintro a b ⟨v, hv, hav | hav⟩ ⟨w, hw, hbw | hbw⟩
    · exact ⟨w + v, add_mem hw hv, Or.inl (hav.mul hbw)⟩
    · -- translation ∘ inversion: still inversion form, vectors add.
      refine ⟨w + v, add_mem hw hv, Or.inr fun x => ?_⟩
      calc (a * b) x = a (b x) := rfl
        _ = (-x + w) + v := by rw [hbw x, hav (-x + w)]
        _ = -x + (w + v) := add_assoc _ _ _
    · -- inversion ∘ translation: the translation's vector enters negated.
      refine ⟨v - w, sub_mem hv hw, Or.inr fun x => ?_⟩
      calc (a * b) x = a (b x) := rfl
        _ = -(x + w) + v := by rw [hbw x, hav (x + w)]
        _ = -x + (v - w) := by abel
    · -- inversion ∘ inversion: a translation, by the difference of the centers' vectors.
      refine ⟨v - w, sub_mem hv hw, Or.inl fun x => ?_⟩
      calc (a * b) x = a (b x) := rfl
        _ = -(-x + w) + v := by rw [hbw x, hav (-x + w)]
        _ = x + (v - w) := by abel
  inv_mem' := by
    rintro a ⟨v, hv, hav | hav⟩
    · exact ⟨-v, neg_mem hv, Or.inl hav.inv⟩
    · -- an inversion is its own inverse, with the same vector.
      exact ⟨v, hv, Or.inr fun x =>
        inv_apply_eq (fun y => by rw [hav (-y + v)]; abel) x⟩

theorem mem_P2 {g : E2} :
    g ∈ P2 ↔ ∃ v ∈ stdLattice, IsTranslationBy g v ∨ ∀ x, g x = -x + v := Iff.rfl

/-- The inversions contribute no translation vectors: `transVecs P2` is still the
lattice. -/
theorem transVecs_P2 : transVecs P2 = (stdLattice : Set Plane) := by
  refine Set.Subset.antisymm ?_ (stdLattice_subset_transVecs fun v hv =>
    mem_P2.mpr ⟨v, hv, Or.inl (isTranslationBy_translationIso v)⟩)
  rintro u ⟨g, hgP2, hgu⟩
  obtain ⟨v, hv, hgv | hgv⟩ := mem_P2.mp hgP2
  · rwa [hgu.unique hgv]
  · exact (inversion_form_not_isTranslationBy hgv hgu).elim

/-- **p2 is a wallpaper group** — the coset condition holds with `{1, pointInversion}`:
composing an inversion-form element with point inversion recovers a translation. -/
theorem p2_isWallpaperGroup : IsWallpaperGroup P2 := by
  classical
  refine ⟨⟨stdVec 0, stdVec 1, linearIndependent_stdVec, transVecs_P2⟩,
    {1, pointInversion}, ?_, ?_⟩
  · intro g hg
    simp only [Finset.coe_insert, Set.mem_insert_iff, Finset.coe_singleton,
      Set.mem_singleton_iff] at hg
    rcases hg with rfl | rfl
    · exact one_mem P2
    · exact mem_P2.mpr ⟨0, zero_mem _, Or.inr fun x => by
        rw [pointInversion_apply, add_zero]⟩
  · intro g hg
    obtain ⟨v, _, hgv | hgv⟩ := mem_P2.mp hg
    · exact ⟨1, Finset.mem_insert_self 1 _, by rw [inv_one, mul_one]; exact ⟨v, hgv⟩⟩
    · refine ⟨pointInversion, Finset.mem_insert_of_mem (Finset.mem_singleton_self _),
        v, fun x => ?_⟩
      have hinv : pointInversion⁻¹ x = -x :=
        inv_apply_eq (fun y => by rw [pointInversion_apply, neg_neg]) x
      calc (g * pointInversion⁻¹) x = g (pointInversion⁻¹ x) := rfl
        _ = g (-x) := by rw [hinv]
        _ = -(-x) + v := hgv (-x)
        _ = x + v := by rw [neg_neg]

end Crystal.Wallpaper
