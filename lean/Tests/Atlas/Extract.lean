/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Atlas.Extract

/-!
# B1 · the extractor

A small module extracted whole, so the row shape is pinned: name, kind, module, canonical
statement encoding, and the two used-constant lists.

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
info: {"kind":"def","module":"Tests.Atlas.Extract","name":"double","stmt":"fh-stmt-v1;pd(c(3:Nat,0),c(3:Nat,0))","uses_proof":["Nat","Nat.add"],"uses_statement":["Nat"]}
---
info: {"kind":"theorem","module":"Tests.Atlas.Extract","name":"two_eq_two","stmt":"fh-stmt-v1;a(a(a(c(2:Eq,1,+(0)),c(3:Nat,0)),a(a(a(c(11:OfNat.ofNat,1,0),c(3:Nat,0)),n2),a(c(12:instOfNatNat,0),n2))),a(a(a(c(11:OfNat.ofNat,1,0),c(3:Nat,0)),n2),a(c(12:instOfNatNat,0),n2)))","uses_proof":["Eq.refl","Nat","OfNat.ofNat","instOfNatNat"],"uses_statement":["Eq","Nat","OfNat.ofNat","instOfNatNat"]}
---
info: {"kind":"def","module":"Tests.Atlas.Extract","name":"unfinished","stmt":"fh-stmt-v1;pd(c(3:Nat,0),c(3:Nat,0))","uses_proof":["Bool.false","Lean.Name","Lean.Name.anonymous","Lean.Name.num","Lean.Name.str","Nat","OfNat.ofNat","instOfNatNat","sorryAx"],"uses_statement":["Nat"]}
-/
#guard_msgs in
#fh_extract
