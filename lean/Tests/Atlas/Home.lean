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

/-! ## A carrier followed by an instance parameter

The carrier is not necessarily the final argument in an elaborated class application.
`CarrierAfterInstance R` also contains the synthesized `[Add R]` argument, so a last-arg
rule keys its evidence to that instance fvar and incorrectly calls the declared binder
unused. Telescope-aligned carrier selection keeps both requirements attached to `R`. -/

class CarrierAfterInstance (R : Type) [Add R] : Prop where
  marker : True

theorem trailingInstanceCarrier {R : Type} [Add R] [CarrierAfterInstance R] : True :=
  CarrierAfterInstance.marker R

/--
info: FH home: `trailingInstanceCarrier` is at home
  [Add R] — at home
  [CarrierAfterInstance R] — at home
-/
#guard_msgs (whitespace := lax) in
#fh_home trailingInstanceCarrier

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

/-! ## The skewed-index regression

Found by an agent asked to break the confirmer rather than to exercise it, and it landed in
the negative control — the one command whose job is to show the tool can say no.

A binder whose domain head is not a plain constant (`DecidableEq`, `DecidablePred`, any
`[∀ i, C (f i)]`) is skipped when candidates are collected, but `weakenBinder` counts every
`instImplicit` forall in the raw type. A counter that advanced only on kept binders drifted
by one per skipped binder, so the kernel was asked about a binder the report did not name —
and answered about *that* one. Roughly 10% of Mathlib theorems have two or more instance
binders.

`skew2` is the repro: `a - b` cannot be stated without `Sub R`, so a CONFIRMED here is
itself proof that the wrong binder was replaced. The second theorem is the same statement
with nothing to skip, and the two must now agree.
-/

theorem skew2 {R : Type} [DecidableEq R] [CommRing R] (a b : R) : a - b = a - b := rfl

/--
info: FH home confirm: `skew2`
  [CommRing] -> Nonempty: REFUTED — even with every instance argument re-synthesised in the weakened context, the term does not typecheck
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_refute skew2 Nonempty

theorem noskew {R : Type} [CommRing R] (a b : R) : a - b = a - b := rfl

/--
info: FH home confirm: `noskew`
  [CommRing] -> Nonempty: REFUTED — even with every instance argument re-synthesised in the weakened context, the term does not typecheck
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_refute noskew Nonempty

/-! ## A weakening that cannot be *stated* is not a weakening that is false

`weakenBinder` rebuilds the binder by applying the target class to the **source** class's
arguments. That is right when the two take the same number — `CommRing R` becomes
`AddCommMagma R` — and produces an ill-typed binder when they do not: `Zero R` becomes
`OfNat R`, but `OfNat` is indexed by the literal being denoted and needs `OfNat R 0`.

The kernel duly rejected it and the command reported REFUTED, which is a verdict about a
term nobody proposed. Measured over 578 real probes: **all 134 arity-changing ones were
"refuted", none could have been anything else**, and the 444 arity-preserving ones confirmed
at 32.4% — so the headline 24.9% was that dilution and nothing more.

This pins the refusal. `Zero`/`OfNat` is the pair that produced the largest false family
(336 candidates on whole Mathlib); the target's arity is read off its own type, so nothing
here is specific to it.
-/

theorem zeroish {R : Type} [Zero R] (a : R) : a = a := rfl

/--
info: FH home confirm: `zeroish`
  [Zero] -> OfNat: could not rebuild the binder — OfNat takes 2 argument(s) and the binder supplies a different number, or the domain is not a constant application. NO VERDICT: this weakening cannot be stated, which is not evidence that it is false.
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_refute zeroish OfNat

/-- The same command on an arity-*preserving* target still reaches the kernel and answers,
so the refusal above is the arity check firing and not the command having gone quiet. -/
theorem zeroish2 {R : Type} [CommRing R] (a : R) : a = a := rfl

/--
info: FH home confirm: `zeroish2`
  [CommRing] -> AddCommMagma: CONFIRMED — the term typechecks without CommRing
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_refute zeroish2 AddCommMagma

/-! ## A proof search must state which binder it weakens

Naming only the target class is ambiguous: several instance binders can have the same arity,
and the first implementation silently rewrote the first such binder. The command now names
the source class and refuses when that still identifies more than one binder. Failed tactics
are ordinary search outcomes, so their internal unsolved-goal messages must not escape and
turn the containing file red.
-/

theorem attemptEasy {R : Type} [CommRing R] (a b : R) : a + b = b + a := add_comm a b
theorem attemptUniverse {R : Type*} [CommRing R] (a b : R) : a + b = b + a := add_comm a b
theorem attemptHard {R : Type} [CommRing R] (a b c : R) (h : a + b = a + c) : b = c :=
  add_left_cancel h
theorem attemptNotStatement {R : Type} [CommRing R] (a b : R) : a * b = b * a := mul_comm a b
set_option linter.overlappingInstances false in
theorem attemptAmbiguous {R : Type} [CommRing R] [CommRing R] (a : R) : a = a := rfl

set_option linter.unusedTactic false
set_option linter.unreachableTactic false

/--
info: FH attempt `attemptEasy`: CommRing -> AddCommMagma: PROVED by exact?
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_attempt attemptEasy CommRing => AddCommMagma by rfl, simp, aesop, exact?

/--
info: FH attempt `attemptUniverse`: CommRing -> AddCommMagma: PROVED by exact?
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_attempt attemptUniverse CommRing => AddCommMagma by rfl, simp, aesop, exact?

/--
info: FH attempt `attemptHard`: CommRing -> AddCommMagma: not proved by the ladder
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_attempt attemptHard CommRing => AddCommMagma by rfl

-- A ladder tactic that exceeds its heartbeat budget is a bounded miss, not a file error.
-- A runtime exception passes through ordinary `catch`, so without `tryCatchRuntimeEx` in
-- `tryTactic` this command died with `(deterministic) timeout at whnf` and the verdict
-- line vanished — found by the census shards' `fh_plant_hard` control on their first run,
-- and reproduced at exactly this budget before the fix.
/--
info: FH attempt `attemptHard`: CommRing -> AddCommMagma: not proved by the ladder
-/
#guard_msgs (whitespace := lax, ordering := exact) in
set_option maxHeartbeats 2000 in
#fh_home_attempt attemptHard CommRing => AddCommMagma by exact?

/--
info: FH attempt `attemptNotStatement`: CommRing -> AddCommMagma: the rewritten statement is not type-correct after instance re-synthesis — NO STATEMENT
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_attempt attemptNotStatement CommRing => AddCommMagma by rfl

/--
info: FH attempt `attemptAmbiguous`: CommRing -> AddCommMagma: 2 source binders match; name a binder index before asking for a verdict — NO STATEMENT
-/
#guard_msgs (whitespace := lax, ordering := exact) in
#fh_home_attempt attemptAmbiguous CommRing => AddCommMagma by rfl

set_option linter.unusedTactic true
set_option linter.unreachableTactic true
