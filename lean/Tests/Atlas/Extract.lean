/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FhAtlas.Extract

/-!
# B1 · the extractor

A small module extracted whole, so the row shape is pinned: name, kind, module, explicit
instance-registry status, canonical statement encoding, and the two used-constant lists. A
later fixture pins the optional carrier-attached statement evidence without churning rows
that have none.

The declarations are FH's own, which is the point — the extractor sees FH definitions as
ordinary Lean declarations, because that is what stage-one expansion makes them.
-/

fn double(n: Nat) -> Nat { Nat::add(n, n) }

/-- warning: declaration uses `sorry` -/
#guard_msgs in
fn unfinished(n: Nat) -> Nat;

/-! `unfinished` is the row that earns its keep: `sorryAx` shows up in `uses_proof` and
nowhere else, so a consumer can tell an incomplete argument from a complete one without
trusting FH's own bookkeeping. -/

/-! ## A theorem's proof edges (regression, found by B2)

`double` and `unfinished` are `def`s, and for a while that was the whole of what this
fixture checked — which is how `uses_proof` came to be **empty for every theorem in
Mathlib** without anyone noticing. `ConstantInfo.value?` returns `none` for a theorem on
this toolchain; the extractor has to match `.thmInfo` directly.

B2's first real run is what surfaced it: 33,521 theorems in a `Mathlib.Logic.Basic` slice
and not one proof edge, which made `atlas why --lens proof` — the query the whole
distinction exists for — answer nothing for anything. So there is a theorem in this
fixture now, and its proof edges are pinned. -/

theorem two_eq_two() -> 2 == 2 { lean! { rfl } }

/-! Note what the row below shows: `Eq.refl` is in `uses_proof` and *not* in
`uses_statement`. The claim does not mention reflexivity; the argument is nothing but. That
is the separation the two lists exist for, and it is now checked rather than assumed. -/

/--
info: {"is_instance":false,"kind":"def","module":"Tests.Atlas.Extract","name":"double","stmt":"fh-stmt-v1;pd(c(3:Nat,0),c(3:Nat,0))","uses_proof":["Nat","Nat.add"],"uses_statement":["Nat"]}
---
info: {"is_instance":false,"kind":"theorem","module":"Tests.Atlas.Extract","name":"two_eq_two","stmt":"fh-stmt-v1;a(a(a(c(2:Eq,1,+(0)),c(3:Nat,0)),a(a(a(c(11:OfNat.ofNat,1,0),c(3:Nat,0)),n2),a(c(12:instOfNatNat,0),n2))),a(a(a(c(11:OfNat.ofNat,1,0),c(3:Nat,0)),n2),a(c(12:instOfNatNat,0),n2)))","uses_proof":["Eq.refl","Nat","OfNat.ofNat","instOfNatNat"],"uses_statement":["Eq","Nat","OfNat.ofNat","instOfNatNat"]}
---
info: {"is_instance":false,"kind":"def","module":"Tests.Atlas.Extract","name":"unfinished","stmt":"fh-stmt-v1;pd(c(3:Nat,0),c(3:Nat,0))","uses_proof":["Bool.false","Lean.Name","Lean.Name.anonymous","Lean.Name.num","Lean.Name.str","Nat","OfNat.ofNat","instOfNatNat","sorryAx"],"uses_statement":["Nat"]}
-/
#guard_msgs in
#fh_extract

/-! ## Carrier-attached use-site evidence

The class below deliberately places an instance parameter after its structural carrier.
The extracted requirement must still point to outer binder zero (`R`), and must retain its
source constant so a downstream detector can distinguish semantic evidence from instance
plumbing. The ordinary module-wide fixture above stays byte-for-byte stable because empty
requirement arrays are omitted. -/

class ExtractCarrierAfterInstance (R : Type) [Add R] : Prop where
  marker : True

theorem extractsCarrierUse {R : Type} [Add R] [ExtractCarrierAfterInstance R] : True :=
  ExtractCarrierAfterInstance.marker R

open Lean Elab Command in
elab "#fh_extract_one " n:ident : command => do
  let name ← liftCoreM <| realizeGlobalConstNoOverload n
  let env ← getEnv
  let some info := env.find? name | throwErrorAt n "unknown declaration"
  logInfo (FerrisHoward.Atlas.rowOf env name info).toJson.compress

/-- info: {"is_instance":false,"kind":"theorem","module":"Tests.Atlas.Extract","name":"extractsCarrierUse","requirements_statement":[{"carrier":0,"class":"Add","source":"ExtractCarrierAfterInstance"}],"stmt":"fh-stmt-v1;pi(s(+(0)),pt(a(c(3:Add,1,0),b0),pt(a(a(c(27:ExtractCarrierAfterInstance,0),b1),b0),c(4:True,0))))","uses_proof":["Add","ExtractCarrierAfterInstance","ExtractCarrierAfterInstance.marker"],"uses_statement":["Add","ExtractCarrierAfterInstance","True"]} -/
#guard_msgs in
#fh_extract_one extractsCarrierUse

/-! ## Registered instances versus class-valued theorem claims

Both declarations below have the same class-valued conclusion and the same theorem
constant kind. Only one is registered for typeclass synthesis. The row must preserve that
environment fact explicitly; inferring it from `kind` would conflate them. -/

theorem extractsClassValuedClaim : ExtractCarrierAfterInstance Nat := ⟨True.intro⟩

instance extractsRegisteredInstance : ExtractCarrierAfterInstance Nat := ⟨True.intro⟩

open Lean Elab Command in
elab "#fh_instance_status " n:ident : command => do
  let name ← liftCoreM <| realizeGlobalConstNoOverload n
  let env ← getEnv
  let some info := env.find? name | throwErrorAt n "unknown declaration"
  logInfo s!"{(FerrisHoward.Atlas.rowOf env name info).isInstance}"

/-- info: false -/
#guard_msgs in
#fh_instance_status extractsClassValuedClaim

/-- info: true -/
#guard_msgs in
#fh_instance_status extractsRegisteredInstance
