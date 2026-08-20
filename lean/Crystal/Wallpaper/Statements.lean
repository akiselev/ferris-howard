/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib

/-!
# The wallpaper census — frozen statements (W0)

This module *defines* the census's claims and proves nothing about them: the Phase-1
statement freeze of `research/physics/wallpaper-census.md`, following the Couette
protocol — the meaning of "there are exactly 17 wallpaper groups" lives in choices
(which equivalence relation, which definition of wallpaper group) that must be written
down and elaborated before any proof work begins, so that later milestones prove the
statements as frozen rather than statements drifted to fit the proofs.

Design decisions embodied here, argued in the design doc:

* The **plane** is `EuclideanSpace ℝ (Fin 2)` and the ambient group is its isometry
  group `E2 := Plane ≃ᵢ Plane` — no affine structure is presupposed; that isometries of
  Euclidean space are affine is Mazur–Ulam's business and enters at W6, not here.
* A **wallpaper group** is primarily defined in *lattice form*: its translations are
  exactly the ℤ-span of two ℝ-independent vectors, and it has finitely many cosets over
  its translations. The textbook geometric form (discrete + cocompact) is defined
  alongside; their equivalence is milestone W6 (Bieberbach I in dimension 2), a theorem
  to be proven, never an assumption.
* The **census is stated at abstract isomorphism** (`≃*`). Bieberbach rigidity (W7)
  upgrades its geometric meaning later without touching these definitions.

Zero `sorry`: nothing here is asserted, so there is nothing to be sorry about.
-/

namespace Crystal.Wallpaper

/-- The Euclidean plane. -/
abbrev Plane : Type := EuclideanSpace ℝ (Fin 2)

/-- The full isometry group of the plane, as self-isometry-equivalences under
composition. -/
abbrev E2 : Type := Plane ≃ᵢ Plane

/-- `e` is the translation by `v`. Stated pointwise so that no affine machinery is
presupposed at the statement layer. -/
def IsTranslationBy (e : E2) (v : Plane) : Prop :=
  ∀ x, e x = x + v

/-- `e` is a translation. -/
def IsTranslation (e : E2) : Prop :=
  ∃ v, IsTranslationBy e v

/-- The set of vectors by which some element of `G` translates — the raw material of
`G`'s translation lattice. -/
def transVecs (G : Subgroup E2) : Set Plane :=
  {v | ∃ g ∈ G, IsTranslationBy g v}

/-- **The primary definition.** `G` is a wallpaper group in *lattice form*:

* its translation vectors are exactly the ℤ-span of two ℝ-linearly-independent vectors
  (a rank-2 lattice, said with elementary vocabulary — `AddSubgroup.closure` of a
  two-element set — rather than through the `ZLattice` API, which enters with the
  proofs, not the statements); and
* finitely many elements of `G` represent every coset over its translations.

Chosen as primary because every quantity the census computes (point groups, vector
systems, invariants) reads off this data directly. Its equivalence with the geometric
definition below is W6's theorem. -/
def IsWallpaperGroup (G : Subgroup E2) : Prop :=
  (∃ v₁ v₂ : Plane, LinearIndependent ℝ ![v₁, v₂] ∧
      transVecs G = (AddSubgroup.closure {v₁, v₂} : AddSubgroup Plane)) ∧
  ∃ s : Finset E2, (↑s : Set E2) ⊆ G ∧
      ∀ g ∈ G, ∃ h ∈ s, IsTranslation (g * h⁻¹)

/-- **The geometric definition**, recorded so the design decision is visible in code:
`G` acts on the plane with discrete orbits and a bounded fundamental region (stated as:
some closed ball meets every orbit). Bieberbach I in dimension 2 — milestone W6 — is
precisely the statement `IsWallpaperGroup_geometric G ↔ IsWallpaperGroup G`, and until
it is proven the census claims nothing about this predicate. -/
def IsWallpaperGroup_geometric (G : Subgroup E2) : Prop :=
  (∀ x : Plane, ∀ ε > (0 : ℝ), ∃ δ > (0 : ℝ), δ ≤ ε ∧
      ∀ g ∈ G, (g : E2) x ∈ Metric.ball x δ → (g : E2) x = x) ∧
  ∃ R : ℝ, 0 < R ∧ ∀ x : Plane, ∃ g ∈ G, (g : E2) x ∈ Metric.closedBall (0 : Plane) R

/-- Seventeen explicit wallpaper groups exist. W1 discharges this by construction. -/
def census_existence (reps : Fin 17 → Subgroup E2) : Prop :=
  ∀ i, IsWallpaperGroup (reps i)

/-- The seventeen are pairwise non-isomorphic as abstract groups. W5's invariant
battery discharges this; the planted-duplicate control must be *caught* by whatever
discharges it. -/
def census_separation (reps : Fin 17 → Subgroup E2) : Prop :=
  ∀ i j, i ≠ j → IsEmpty ((reps i) ≃* (reps j))

/-- Every wallpaper group is isomorphic to one of the seventeen — the hard direction,
W2 + W3 + W4 + W6 assembled. -/
def census_completeness (reps : Fin 17 → Subgroup E2) : Prop :=
  ∀ G : Subgroup E2, IsWallpaperGroup G → ∃ i, Nonempty (G ≃* reps i)

/-- **The census.** There are exactly seventeen wallpaper groups up to abstract group
isomorphism — existence, separation, and completeness for one family of
representatives. This `Prop` is the artifact the whole program exists to prove; it is
frozen here, at W0, before any of it is true in the kernel's eyes. -/
def WallpaperCensus : Prop :=
  ∃ reps : Fin 17 → Subgroup E2,
    census_existence reps ∧ census_separation reps ∧ census_completeness reps

end Crystal.Wallpaper
