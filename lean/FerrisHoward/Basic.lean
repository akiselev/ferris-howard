import Mathlib

/-!
Smoke test: Mathlib elaborates against the pinned toolchain and the anchors
named in the design docs are present.
-/

#check @Nat.Prime.dvd_mul      -- design.md §1: the euclids_lemma target
#check @ZMod.pow_card          -- corpus Group 7: fermat_little's proof
#check @EuclideanDomain        -- design.md §1: the bridge anchor
#check @RiemannHypothesis      -- atlas-validation.md §2: the statement anchor
