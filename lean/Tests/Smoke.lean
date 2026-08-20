import Mathlib

/-!
Scaffold smoke test (was `FerrisHoward/Basic.lean`): Mathlib elaborates against the
pinned toolchain and the anchors named in the design docs are present. It lives under
`Tests/` rather than in the library so that the language modules import `Lean` only and
stay fast to rebuild.
-/

/-- info: @Nat.Prime.dvd_mul : ∀ {p m n : ℕ}, Nat.Prime p → (p ∣ m * n ↔ p ∣ m ∨ p ∣ n) -/
#guard_msgs in
#check @Nat.Prime.dvd_mul      -- design.md §1: the euclids_lemma target

/-- info: @ZMod.pow_card : ∀ {p : ℕ} [inst : Fact (Nat.Prime p)] (x : ZMod p), x ^ p = x -/
#guard_msgs in
#check @ZMod.pow_card          -- corpus Group 7: fermat_little's proof

/-- info: EuclideanDomain : Type u_1 → Type u_1 -/
#guard_msgs in
#check @EuclideanDomain        -- design.md §1: the bridge anchor

/-- info: RiemannHypothesis : Prop -/
#guard_msgs in
#check @RiemannHypothesis      -- atlas-validation.md §2: the statement anchor
