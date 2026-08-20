/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Crystal.Wallpaper.Statements

/-!
# W1 shared machinery — translations, the square lattice, pointwise inverses

Every W1 witness is a set of maps `x ↦ A x + v` with `A` ranging over a finite point
group and `v` over explicit vector sets; the parts that do not depend on `A` live here.
The design choices are P1's, inherited by every later witness:

* Translations enter through `IsometryEquiv.addRight`, so `IsTranslationBy` holds
  definitionally — no affine machinery, matching the statement layer's choice.
* Witness carriers say "there exists a vector such that…", never "closure of two
  generators": membership then *carries* its vector, and each `transVecs` computation
  is uniqueness-of-the-vector plus nothing.
* Inverses are named pointwise (`inv_apply_eq`): a witness proof exhibits the candidate
  inverse map and checks `e ∘ f = id` by algebra, never unfolding `symm` of a
  construction.
-/

namespace Crystal.Wallpaper

/-- Translation by `v`, as an isometry of the plane. -/
noncomputable def translationIso (v : Plane) : E2 := IsometryEquiv.addRight v

theorem isTranslationBy_translationIso (v : Plane) :
    IsTranslationBy (translationIso v) v := fun _ => rfl

/-- The standard unit vector `eᵢ` of the plane. -/
noncomputable def stdVec (i : Fin 2) : Plane := EuclideanSpace.single i 1

/-- The square lattice ℤe₀ + ℤe₁, shared by the first several witnesses — said as
`AddSubgroup.closure` of the two unit vectors, exactly the vocabulary
`IsWallpaperGroup` uses. -/
def stdLattice : AddSubgroup Plane := AddSubgroup.closure {stdVec 0, stdVec 1}

theorem stdVec_zero_mem_stdLattice : stdVec 0 ∈ stdLattice :=
  AddSubgroup.subset_closure (Set.mem_insert _ _)

theorem stdVec_one_mem_stdLattice : stdVec 1 ∈ stdLattice :=
  AddSubgroup.subset_closure (Set.mem_insert_of_mem _ rfl)

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

/-- No standard unit vector is its own negation — the char-0 fact every "twisted element
is not a translation" argument bottoms out in, read off at coordinate `i`. -/
theorem stdVec_ne_neg_stdVec (i : Fin 2) : stdVec i ≠ -stdVec i := by
  intro h
  have hi := congrArg (fun z : Plane => z i) h
  simp [stdVec, PiLp.neg_apply] at hi
  norm_num at hi

/-- A translation determines its vector: evaluate at the origin. -/
theorem IsTranslationBy.unique {g : E2} {v w : Plane}
    (hv : IsTranslationBy g v) (hw : IsTranslationBy g w) : v = w := by
  have h := (hv 0).symm.trans (hw 0)
  simpa using h

/-- Isometries of translation form compose by adding their vectors — `b` acts first
under `*`, so its vector enters first. -/
theorem IsTranslationBy.mul {a b : E2} {v w : Plane}
    (ha : IsTranslationBy a v) (hb : IsTranslationBy b w) :
    IsTranslationBy (a * b) (w + v) := fun x =>
  calc (a * b) x = a (b x) := rfl
    _ = (x + w) + v := by rw [hb x, ha (x + w)]
    _ = x + (w + v) := add_assoc x w v

/-- An isometry's inverse, computed pointwise from a pointwise right inverse: exhibiting
`f` with `e ∘ f = id` names `e⁻¹` without ever unfolding the `symm` of a construction.
(`f` is automatically the two-sided inverse because `e` is a bijection.) -/
theorem inv_apply_eq {e : E2} {f : Plane → Plane} (hf : ∀ x, e (f x) = x) (x : Plane) :
    e⁻¹ x = f x := by
  conv_lhs => rw [← hf x]
  exact e.inv_apply_self (f x)

theorem IsTranslationBy.inv {g : E2} {v : Plane} (h : IsTranslationBy g v) :
    IsTranslationBy g⁻¹ (-v) := fun x =>
  inv_apply_eq (fun y => by rw [h (y + -v)]; abel) x

/-- Half of every `transVecs` computation: a subgroup containing all lattice
translations realizes every lattice vector. The other half is per-witness, because it
inspects the witness's twisted elements. -/
theorem stdLattice_subset_transVecs {G : Subgroup E2}
    (h : ∀ v ∈ stdLattice, translationIso v ∈ G) :
    (stdLattice : Set Plane) ⊆ transVecs G := fun u hu =>
  ⟨translationIso u, h u hu, isTranslationBy_translationIso u⟩

end Crystal.Wallpaper
