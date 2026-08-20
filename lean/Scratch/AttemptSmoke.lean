import Mathlib
import FerrisHoward.Atlas.Home
set_option maxHeartbeats 400000
set_option linter.unusedTactic false
set_option linter.unreachableTactic false

/-- Provable after weakening: `add_comm` is exactly an `AddCommMagma` fact. -/
theorem easy {R : Type} [CommRing R] (a b : R) : a + b = b + a := add_comm a b

/-- Well-formed but not true after weakening: cancellation is not an `AddCommMagma` law. -/
theorem hard {R : Type} [CommRing R] (a b c : R) (h : a + b = a + c) : b = c :=
  add_left_cancel h

/-- This is not a proposition over `AddCommMagma`: multiplication has no instance. -/
theorem notStatement {R : Type} [CommRing R] (a b : R) : a * b = b * a := mul_comm a b

#fh_home_attempt easy CommRing => AddCommMagma by rfl, simp, aesop, exact?
#fh_home_attempt hard CommRing => AddCommMagma by rfl
#fh_home_attempt notStatement CommRing => AddCommMagma by rfl
