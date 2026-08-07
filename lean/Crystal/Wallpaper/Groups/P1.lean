/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Crystal.Wallpaper.Groups.Basic

/-!
# W1, first witness — p1, the group of lattice translations

The simplest of the seventeen: `P1` consists of *all* translations by vectors of the
square lattice ℤe₀ + ℤe₁, and nothing else.  `p1_isWallpaperGroup` discharges the first
component of `census_existence` for the eventual representative family.

The shared design notes live in `Groups/Basic.lean`; specific to p1:

* The coset condition holds with the singleton `{1}`: every element *is* a translation.
* The negative-control shape `not_isWallpaperGroup_bot` pins that `IsWallpaperGroup` can
  say no: the trivial subgroup translates only by `0`, and a lattice basis vector would
  have to be `0`, contradicting linear independence.
-/

namespace Crystal.Wallpaper

/-- **p1**: all translations by lattice vectors, the first of the seventeen. -/
def P1 : Subgroup E2 where
  carrier := {g | ∃ v ∈ stdLattice, IsTranslationBy g v}
  one_mem' := ⟨0, zero_mem _, fun x => (add_zero x).symm⟩
  mul_mem' := by
    rintro a b ⟨v, hv, hav⟩ ⟨w, hw, hbw⟩
    exact ⟨w + v, add_mem hw hv, hav.mul hbw⟩
  inv_mem' := by
    rintro a ⟨v, hv, hav⟩
    exact ⟨-v, neg_mem hv, hav.inv⟩

theorem mem_P1 {g : E2} : g ∈ P1 ↔ ∃ v ∈ stdLattice, IsTranslationBy g v := Iff.rfl

/-- The translation vectors of `P1` are exactly the lattice — both inclusions are direct,
because membership in `P1` already carries the lattice vector. -/
theorem transVecs_P1 : transVecs P1 = (stdLattice : Set Plane) := by
  refine Set.Subset.antisymm ?_ (stdLattice_subset_transVecs fun v hv =>
    mem_P1.mpr ⟨v, hv, isTranslationBy_translationIso v⟩)
  rintro u ⟨g, hgP1, hgu⟩
  obtain ⟨v, hv, hgv⟩ := mem_P1.mp hgP1
  rwa [hgu.unique hgv]

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
