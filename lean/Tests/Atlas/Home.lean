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
  [CommRing R] — CANDIDATE: reaches only AddCommMagma; weaken and re-check
-/
#guard_msgs (whitespace := lax) in
#fh_home overh

/-! The confirmation. This compiling is what makes the finding above a fact rather than a
suggestion — and running the tool on it reports the binder at home, which is the loop
closing. -/

theorem overh_confirmed {R : Type} [AddCommMagma R] (a b : R) : a + b = b + a := add_comm a b

/--
info: FH home: `overh_confirmed` is at home
  [AddCommMagma R] — at home
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
  [CommRing R] — CANDIDATE: reaches only CommMagma; weaken and re-check
  [Fintype R] — CANDIDATE: unused; nothing in the statement or proof needs it
-/
#guard_msgs (whitespace := lax) in
#fh_home unusedbinder

/-! Both findings confirmed at once. -/

theorem unusedbinder_confirmed {R : Type} [CommMagma R] (a b : R) : a * b = b * a :=
  mul_comm a b

/--
info: FH home: `unusedbinder_confirmed` is at home
  [CommMagma R] — at home
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
  [CommRing R] — at home
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

/-! ## Carrier-aware evidence (C4 D3)

`#fh_home` names the carrier each binder constrains **and judges each binder only on the
evidence found at that carrier**. The second half is what makes the first worth having.

This fixture pinned the gap while it existed. `R` is used only additively and `S` only
multiplicatively, so each binder has a clean home. With the evidence flattened to a set of
class names, both classes were attributed to both binders, neither resolved to a single
weakest ancestor, and **two genuine findings were lost** — a false negative, which is the
safe direction, but a loss.

The evidence is now read where it lives: an instance argument's type is exactly
`SomeClass carrier`, so every argument whose type is a class application is one piece of
carrier-attached evidence. Two exclusions carry over from `reachedClasses` and both are
load-bearing — an argument handed to another *instance* or to a *parent projection* is
plumbing, and recording it makes a binder evidence for itself, at which point everything
reads "at home".
-/

theorem twocarrier {R S : Type} [CommRing R] [CommRing S] (a b : R) (x y : S) :
    a + b = b + a ∧ x * y = y * x := ⟨add_comm a b, mul_comm x y⟩

/--
info: FH home: `twocarrier` has 2 over-hypothesis candidate(s) — a candidate is confirmed by moving the declaration and re-checking it
  [CommRing R] — CANDIDATE: reaches only AddCommMagma; weaken and re-check
  [CommRing S] — CANDIDATE: reaches only CommMagma; weaken and re-check
  (binders span 2 carriers ([R, S]); each verdict uses only its own carrier's evidence)
-/
#guard_msgs (whitespace := lax) in
#fh_home twocarrier

/-! ## Confirmation, by re-elaboration (C4 D1b)

`#fh_home` proposes; the kernel disposes. `#fh_home_confirm` rebuilds the declaration with
the candidate binder weakened and hands it back — which is what B3 did by hand, above, and
what §9's "minimal-home claims are confirmed by re-elaboration" asks for.

Retyping the binder is not enough and the first version of this was wrong because of it.
When a declaration is elaborated its instance arguments are resolved against the binders it
was written with and **baked into the term**: `add_comm a b` under `[CommRing R]` carries
`CommRing.toAddCommMagma inst`. Weakening the binder breaks that projection whether or not
the proof needed the strength, so the kernel rejected even `overh` — a declaration this file
proves is a genuine over-hypothesis two sections up.

So the projections are discarded and re-derived by `synthInstance?` at every instance
position, in **both the type and the value**. The type matters as much: its body carries
baked projections too, and rebuilding only the value leaves a weakened type that is itself
ill-formed.
-/

/--
info: FH home confirm: `overh`
  [CommRing] -> AddCommMagma: CONFIRMED — the term typechecks without CommRing
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_confirm overh

/-! And the negative control, which the confirmer needs more than the positive one. Every
candidate `#fh_home_confirm` tries came from the evidence, so it confirms nearly always —
and a tool that only ever says yes is indistinguishable from one that cannot say no.
`#fh_home_refute` forces a target the proof cannot possibly be built from. `genuinely` needs
distributivity and subtraction; an additive magma has neither. -/

/--
info: FH home confirm: `genuinely`
  [CommRing] -> AddCommMagma: REFUTED — even with every instance argument re-synthesised in the weakened context, the term does not typecheck
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_refute genuinely AddCommMagma
