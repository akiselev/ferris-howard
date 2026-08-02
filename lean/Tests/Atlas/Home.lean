/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward.Atlas.Home

/-!
# `atlas home` — where a theorem actually lives (B3)

A statement written for `CommRing` whose argument only ever adds is not a theorem about
commutative rings. It is a theorem about additive commutative magmas that was written down
in the wrong place. Mathlib's generalization linter exists because this happens constantly,
and finding it is one of the two things atlas.md claims the Atlas is for.

## The evidence, and why it is evidence

Every constant carries its own instance binders, and those binders are that constant's
written statement of what it requires. So the classes a declaration needs at a carrier are
the union of the instance-binder classes of the constants its statement and proof use. No
guessing, no name matching.

Two exclusions took three tries to get right, and both are recorded in the module because
each one, omitted, breaks the tool in a *quiet* way:

* **Parent projections** (`CommRing.toRing`) are instances taking the child as a binder,
  so counting them reintroduces the very chain being measured.
* **Instances generally** are plumbing. `instCommSemiringOfCommRing` takes `[CommRing R]`
  and records only that the elaborator threaded the declared binder somewhere — not that
  the argument needed it. A *lemma*'s binder is a real requirement, and lemmas are not
  instances. Without this exclusion every declaration reported "at home", which is worse
  than no tool: it is a tool that says everything is fine.

## The gate

PLAN B3 asks for "a seeded over-hypothesized suite incl. ≥ 2 carrier-abstraction cases".
Both are below, each with its **confirmation** — the weaker declaration actually compiled,
so the finding was real and not a plausible-looking guess. The negative control matters as
much: a theorem that genuinely needs its ring is reported at home.

The ≥ 5 historical Mathlib-linter hits the gate also asks for are *not* here. They need
mining Mathlib's git history for lemmas the generalization linter caught, and the pinned
snapshot has already fixed them — that is scheduled work, and this fixture does not
pretend to it.
-/

/-! ## Carrier-abstraction case 1: additive

Stated for `CommRing`, argued by `add_comm`, which needs `AddCommMagma`.
-/

theorem overh {R : Type} [CommRing R] (a b : R) : a + b = b + a := add_comm a b

/--
info: FH home: `overh` has 1 over-hypothesis candidate(s) — a candidate is confirmed by moving the declaration and re-checking it
  [CommRing] — CANDIDATE: reaches only AddCommMagma; weaken and re-check
-/
#guard_msgs (whitespace := lax) in
#fh_home overh

/-! The confirmation. This compiling is what makes the finding above a fact rather than a
suggestion — and running the tool on it reports the binder at home, which is the loop
closing. -/

theorem overh_confirmed {R : Type} [AddCommMagma R] (a b : R) : a + b = b + a := add_comm a b

/--
info: FH home: `overh_confirmed` is at home
  [AddCommMagma] — at home
-/
#guard_msgs (whitespace := lax) in
#fh_home overh_confirmed

/-! ## Carrier-abstraction case 2: multiplicative, plus a binder nothing uses

`Fintype` is not mentioned by the statement or reached by the proof. An unused binder is
the strongest finding the walk makes, because there is nothing to weaken to — it simply
goes.
-/

theorem unusedbinder {R : Type} [CommRing R] [Fintype R] (a b : R) : a * b = b * a :=
  mul_comm a b

/--
info: FH home: `unusedbinder` has 2 over-hypothesis candidate(s) — a candidate is confirmed by moving the declaration and re-checking it
  [CommRing] — CANDIDATE: reaches only CommMagma; weaken and re-check
  [Fintype] — CANDIDATE: unused; nothing in the statement or proof needs it
-/
#guard_msgs (whitespace := lax) in
#fh_home unusedbinder

/-! Both findings confirmed at once. -/

theorem unusedbinder_confirmed {R : Type} [CommMagma R] (a b : R) : a * b = b * a :=
  mul_comm a b

/--
info: FH home: `unusedbinder_confirmed` is at home
  [CommMagma] — at home
-/
#guard_msgs (whitespace := lax) in
#fh_home unusedbinder_confirmed

/-! ## The negative control

A tool that flags everything is not a tool. This theorem uses subtraction, so its argument
genuinely reaches `CommRing`, and the walk says so.
-/

theorem genuinely {R : Type} [CommRing R] (a b : R) : (a + b) * (a - b) = a * a - b * b := by
  ring

/--
info: FH home: `genuinely` is at home
  [CommRing] — at home
-/
#guard_msgs (whitespace := lax) in
#fh_home genuinely

/-! And a declaration with no instance binders at all has nothing to report, rather than
something to report vacuously. -/

theorem nobinders (a b : Nat) : a + b = b + a := Nat.add_comm a b

/-- info: FH home: `nobinders` is at home -/
#guard_msgs (whitespace := lax) in
#fh_home nobinders

/-! ## Tier 3 — negative -/

/-- error: Unknown constant `no_such_thing` -/
#guard_msgs in
#fh_home no_such_thing
