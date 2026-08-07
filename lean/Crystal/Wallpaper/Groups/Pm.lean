/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Crystal.Wallpaper.Groups.Basic

/-!
# W1, third witness — pm, lattice translations and mirror reflections

`Pm` adjoins to the p1 translations every *mirror-form* map `x ↦ reflect x + v`, `v` in
the lattice, where `reflect` fixes coordinate 0 and negates coordinate 1 — the mirror in
the horizontal axis and all its lattice translates (including the glide reflections with
*integer* glide, which pm contains; the half-integer glides are pg's, next door).
`pm_isWallpaperGroup` is the third component of `census_existence`.

Design notes specific to pm:

* `reflect` is assembled from Mathlib parts — `LinearIsometryEquiv.piLpCongrRight` over
  the family (identity, negation) — rather than built by hand, so norm-preservation is
  inherited and never proven here.
* The composition table is P2's with `reflect` in place of negation; the one new
  ingredient is that `reflect` preserves the lattice (`reflect_mem_stdLattice`), which
  inversion got for free from `neg_mem`.
* This file's `reflect` API (additivity, involution, lattice stability, "mirror-form is
  never a translation") is deliberately self-contained: pg reuses all of it.
-/

namespace Crystal.Wallpaper

/-- The mirror in the horizontal axis as a *linear* isometry: identity in coordinate 0,
negation in coordinate 1, glued with `piLpCongrRight` so the `ℓ²` norm data comes from
Mathlib. -/
noncomputable def reflectL : Plane ≃ₗᵢ[ℝ] Plane :=
  LinearIsometryEquiv.piLpCongrRight 2
    ![LinearIsometryEquiv.refl ℝ ℝ, LinearIsometryEquiv.neg ℝ]

/-- The mirror, forgotten down to a plain isometry so it can live in `E2`. -/
noncomputable def reflect : E2 := reflectL.toIsometryEquiv

theorem reflect_apply (x : Plane) : reflect x = reflectL x := rfl

theorem reflect_apply_zero (x : Plane) : reflect x 0 = x 0 := rfl

theorem reflect_apply_one (x : Plane) : reflect x 1 = -x 1 := rfl

theorem reflect_add (x y : Plane) : reflect (x + y) = reflect x + reflect y :=
  map_add reflectL x y

theorem reflect_zero : reflect 0 = 0 := map_zero reflectL

theorem reflect_neg (x : Plane) : reflect (-x) = -reflect x := map_neg reflectL x

theorem reflect_sub (x y : Plane) : reflect (x - y) = reflect x - reflect y :=
  map_sub reflectL x y

theorem reflect_smul (c : ℝ) (x : Plane) : reflect (c • x) = c • reflect x :=
  map_smul reflectL c x

theorem reflect_reflect (x : Plane) : reflect (reflect x) = x := by
  refine PiLp.ext (Fin.forall_fin_two.mpr ⟨?_, ?_⟩)
  · rw [reflect_apply_zero, reflect_apply_zero]
  · rw [reflect_apply_one, reflect_apply_one, neg_neg]

theorem reflect_stdVec_zero : reflect (stdVec 0) = stdVec 0 := by
  refine PiLp.ext (Fin.forall_fin_two.mpr ⟨?_, ?_⟩)
  · rw [reflect_apply_zero]
  · rw [reflect_apply_one]
    simp [stdVec]

theorem reflect_stdVec_one : reflect (stdVec 1) = -stdVec 1 := by
  refine PiLp.ext (Fin.forall_fin_two.mpr ⟨?_, ?_⟩)
  · rw [reflect_apply_zero]
    simp [stdVec, PiLp.neg_apply]
  · rw [reflect_apply_one]
    simp [PiLp.neg_apply]

/-- The mirror maps the lattice to itself: it fixes `e₀` and negates `e₁`. -/
theorem reflect_mem_stdLattice {v : Plane} (hv : v ∈ stdLattice) :
    reflect v ∈ stdLattice := by
  refine AddSubgroup.closure_induction ?_ ?_ ?_ ?_ hv
  · rintro x (rfl | rfl)
    · rw [reflect_stdVec_zero]; exact stdVec_zero_mem_stdLattice
    · rw [reflect_stdVec_one]; exact neg_mem stdVec_one_mem_stdLattice
  · rw [reflect_zero]; exact zero_mem _
  · intro x y _ _ hx hy
    rw [reflect_add]; exact add_mem hx hy
  · intro x _ hx
    rw [reflect_neg]; exact neg_mem hx

/-- A mirror-form element is not a translation: matching the two forms at the origin
identifies the vectors, and then `reflect` would fix `stdVec 1`, which it negates. -/
theorem reflect_form_not_isTranslationBy {g : E2} {v u : Plane}
    (hg : ∀ x, g x = reflect x + v) (hu : IsTranslationBy g u) : False := by
  have h0 : v = u := by
    have h := (hg 0).symm.trans (hu 0)
    simpa [reflect_zero] using h
  have h1 := (hg (stdVec 1)).symm.trans (hu (stdVec 1))
  rw [h0, reflect_stdVec_one] at h1
  exact stdVec_ne_neg_stdVec 1 (add_right_cancel h1).symm

/-- **pm**: translations by lattice vectors together with mirror-form maps
`x ↦ reflect x + v`, `v` in the lattice. -/
def Pm : Subgroup E2 where
  carrier := {g | ∃ v ∈ stdLattice, IsTranslationBy g v ∨ ∀ x, g x = reflect x + v}
  one_mem' := ⟨0, zero_mem _, Or.inl fun x => (add_zero x).symm⟩
  mul_mem' := by
    rintro a b ⟨v, hv, hav | hav⟩ ⟨w, hw, hbw | hbw⟩
    · exact ⟨w + v, add_mem hw hv, Or.inl (hav.mul hbw)⟩
    · -- translation ∘ mirror-form: vectors add.
      refine ⟨w + v, add_mem hw hv, Or.inr fun x => ?_⟩
      calc (a * b) x = a (b x) := rfl
        _ = (reflect x + w) + v := by rw [hbw x, hav (reflect x + w)]
        _ = reflect x + (w + v) := add_assoc _ _ _
    · -- mirror-form ∘ translation: the translation's vector enters mirrored.
      refine ⟨reflect w + v, add_mem (reflect_mem_stdLattice hw) hv, Or.inr fun x => ?_⟩
      calc (a * b) x = a (b x) := rfl
        _ = reflect (x + w) + v := by rw [hbw x, hav (x + w)]
        _ = reflect x + (reflect w + v) := by rw [reflect_add, add_assoc]
    · -- mirror-form ∘ mirror-form: a translation, because the mirror is an involution.
      refine ⟨reflect w + v, add_mem (reflect_mem_stdLattice hw) hv, Or.inl fun x => ?_⟩
      calc (a * b) x = a (b x) := rfl
        _ = reflect (reflect x + w) + v := by rw [hbw x, hav (reflect x + w)]
        _ = x + (reflect w + v) := by rw [reflect_add, reflect_reflect, add_assoc]
  inv_mem' := by
    rintro a ⟨v, hv, hav | hav⟩
    · exact ⟨-v, neg_mem hv, Or.inl hav.inv⟩
    · -- the inverse of x ↦ reflect x + v is x ↦ reflect x + (-reflect v).
      refine ⟨-reflect v, neg_mem (reflect_mem_stdLattice hv), Or.inr fun x =>
        inv_apply_eq (f := fun y => reflect y + -reflect v) (fun y => ?_) x⟩
      rw [hav (reflect y + -reflect v), reflect_add, reflect_reflect, reflect_neg,
        reflect_reflect]
      abel

theorem mem_Pm {g : E2} :
    g ∈ Pm ↔ ∃ v ∈ stdLattice, IsTranslationBy g v ∨ ∀ x, g x = reflect x + v := Iff.rfl

/-- The mirrors contribute no translation vectors: `transVecs Pm` is still the
lattice. -/
theorem transVecs_Pm : transVecs Pm = (stdLattice : Set Plane) := by
  refine Set.Subset.antisymm ?_ (stdLattice_subset_transVecs fun v hv =>
    mem_Pm.mpr ⟨v, hv, Or.inl (isTranslationBy_translationIso v)⟩)
  rintro u ⟨g, hgPm, hgu⟩
  obtain ⟨v, hv, hgv | hgv⟩ := mem_Pm.mp hgPm
  · rwa [hgu.unique hgv]
  · exact (reflect_form_not_isTranslationBy hgv hgu).elim

/-- **pm is a wallpaper group** — the coset condition holds with `{1, reflect}`:
composing a mirror-form element with the mirror recovers a translation. -/
theorem pm_isWallpaperGroup : IsWallpaperGroup Pm := by
  classical
  refine ⟨⟨stdVec 0, stdVec 1, linearIndependent_stdVec, transVecs_Pm⟩,
    {1, reflect}, ?_, ?_⟩
  · intro g hg
    simp only [Finset.coe_insert, Set.mem_insert_iff, Finset.coe_singleton,
      Set.mem_singleton_iff] at hg
    rcases hg with rfl | rfl
    · exact one_mem Pm
    · exact mem_Pm.mpr ⟨0, zero_mem _, Or.inr fun x => (add_zero _).symm⟩
  · intro g hg
    obtain ⟨v, _, hgv | hgv⟩ := mem_Pm.mp hg
    · exact ⟨1, Finset.mem_insert_self 1 _, by rw [inv_one, mul_one]; exact ⟨v, hgv⟩⟩
    · refine ⟨reflect, Finset.mem_insert_of_mem (Finset.mem_singleton_self _),
        v, fun x => ?_⟩
      have hinv : reflect⁻¹ x = reflect x := inv_apply_eq reflect_reflect x
      calc (g * reflect⁻¹) x = g (reflect⁻¹ x) := rfl
        _ = g (reflect x) := by rw [hinv]
        _ = reflect (reflect x) + v := hgv (reflect x)
        _ = x + v := by rw [reflect_reflect]

end Crystal.Wallpaper
