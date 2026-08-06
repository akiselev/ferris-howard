/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Crystal.Wallpaper.Statements

/-!
# W1, first witness — p1, the group of lattice translations

The simplest of the seventeen: `P1` consists of *all* translations by vectors of the
square lattice ℤe₀ + ℤe₁, and nothing else.  `p1_isWallpaperGroup` discharges the first
component of `census_existence` for the eventual representative family.

Design notes:

* Translations enter through `IsometryEquiv.addRight`, so `IsTranslationBy` holds
  definitionally — no affine machinery, matching the statement layer's choice.
* `P1` is defined as "translates by *some lattice vector*", not as the closure of two
  generating translations: this makes every membership proof carry its vector, and
  `transVecs P1 = p1Lattice` is then uniqueness-of-the-vector plus nothing.
* The coset condition holds with the singleton `{1}`: every element *is* a translation.
* The negative-control shape `not_isWallpaperGroup_bot` pins that `IsWallpaperGroup` can
  say no: the trivial subgroup translates only by `0`, and a lattice basis vector would
  have to be `0`, contradicting linear independence.
-/

namespace Crystal.Wallpaper

/-- Translation by `v`, as an isometry of the plane. -/
noncomputable def translationIso (v : Plane) : E2 := IsometryEquiv.addRight v

theorem isTranslationBy_translationIso (v : Plane) :
    IsTranslationBy (translationIso v) v := fun _ => rfl

/-- The standard unit vector `eᵢ` of the plane. -/
noncomputable def stdVec (i : Fin 2) : Plane := EuclideanSpace.single i 1

/-- The p1 translation lattice ℤe₀ + ℤe₁ — said as `AddSubgroup.closure` of the two unit
vectors, exactly the vocabulary `IsWallpaperGroup` uses. -/
def p1Lattice : AddSubgroup Plane := AddSubgroup.closure {stdVec 0, stdVec 1}

/-- **p1**: all translations by lattice vectors, the first of the seventeen. -/
def P1 : Subgroup E2 where
  carrier := {g | ∃ v ∈ p1Lattice, IsTranslationBy g v}
  one_mem' := ⟨0, zero_mem _, fun x => (add_zero x).symm⟩
  mul_mem' := by
    rintro a b ⟨v, hv, hav⟩ ⟨w, hw, hbw⟩
    refine ⟨w + v, add_mem hw hv, fun x => ?_⟩
    calc (a * b) x = a (b x) := rfl
      _ = (x + w) + v := by rw [hbw x, hav (x + w)]
      _ = x + (w + v) := add_assoc x w v
  inv_mem' := by
    rintro a ⟨v, hv, hav⟩
    refine ⟨-v, neg_mem hv, fun x => ?_⟩
    have hx : a (x + -v) = x := by rw [hav (x + -v)]; abel
    calc a⁻¹ x = a⁻¹ (a (x + -v)) := by rw [hx]
      _ = x + -v := a.inv_apply_self (x + -v)

theorem mem_P1 {g : E2} : g ∈ P1 ↔ ∃ v ∈ p1Lattice, IsTranslationBy g v := Iff.rfl

/-- A translation determines its vector: evaluate at the origin. -/
theorem IsTranslationBy.unique {g : E2} {v w : Plane}
    (hv : IsTranslationBy g v) (hw : IsTranslationBy g w) : v = w := by
  have h := (hv 0).symm.trans (hw 0)
  simpa using h

/-- The translation vectors of `P1` are exactly the lattice — both inclusions are direct,
because membership in `P1` already carries the lattice vector. -/
theorem transVecs_P1 : transVecs P1 = (p1Lattice : Set Plane) := by
  ext u
  constructor
  · rintro ⟨g, hgP1, hgu⟩
    obtain ⟨v, hv, hgv⟩ := mem_P1.mp hgP1
    rwa [hgu.unique hgv]
  · intro hu
    exact ⟨translationIso u, mem_P1.mpr ⟨u, hu, isTranslationBy_translationIso u⟩,
      isTranslationBy_translationIso u⟩

theorem linearIndependent_stdVec : LinearIndependent ℝ ![stdVec 0, stdVec 1] := by
  rw [linearIndependent_fin2]
  simp only [Matrix.cons_val_one, Matrix.cons_val_zero]
  refine ⟨fun h => ?_, fun a h => ?_⟩
  · -- `stdVec 1 = 0` fails at coordinate 1, where the left side is 1.
    have h1 := congrArg (fun z : Plane => z 1) h
    simp [stdVec] at h1
  · -- `a • stdVec 1 = stdVec 0` fails at coordinate 0: the left side is 0, the right 1.
    have h0 := congrArg (fun z : Plane => z 0) h
    simp [stdVec] at h0

/-- **p1 is a wallpaper group** — the coset condition holds with the single representative
`1`, because every element of `P1` is itself a translation. -/
theorem p1_isWallpaperGroup : IsWallpaperGroup P1 := by
  refine ⟨⟨stdVec 0, stdVec 1, linearIndependent_stdVec, transVecs_P1⟩, {1}, ?_, ?_⟩
  · intro g hg
    simp only [Finset.coe_singleton, Set.mem_singleton_iff] at hg
    subst hg
    exact one_mem P1
  · intro g hg
    refine ⟨1, Finset.mem_singleton_self 1, ?_⟩
    rw [inv_one, mul_one]
    obtain ⟨v, _, hv⟩ := mem_P1.mp hg
    exact ⟨v, hv⟩

/-- Negative control: the census's predicate can say *no*.  The trivial subgroup only
translates by `0`, so a putative lattice basis vector must be `0` — contradicting the
linear independence `IsWallpaperGroup` demands. -/
theorem not_isWallpaperGroup_bot : ¬ IsWallpaperGroup (⊥ : Subgroup E2) := by
  rintro ⟨⟨v₁, v₂, hind, heq⟩, -⟩
  have hv₁ : v₁ ∈ transVecs (⊥ : Subgroup E2) := by
    rw [heq]
    exact AddSubgroup.subset_closure (Set.mem_insert _ _)
  obtain ⟨g, hg, hgv⟩ := hv₁
  rw [Subgroup.mem_bot] at hg
  subst hg
  have h0 : v₁ = 0 := by
    have h := hgv 0
    simpa using h.symm
  exact hind.ne_zero 0 (by simp [h0])

end Crystal.Wallpaper
