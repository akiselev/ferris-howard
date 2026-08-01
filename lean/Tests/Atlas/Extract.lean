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

/--
info: {"kind":"def","module":"Tests.Atlas.Extract","name":"double","stmt":"fh-stmt-v1;pd(c(3:Nat,0),c(3:Nat,0))","uses_proof":["Nat","Nat.add"],"uses_statement":["Nat"]}
---
info: {"kind":"def","module":"Tests.Atlas.Extract","name":"unfinished","stmt":"fh-stmt-v1;pd(c(3:Nat,0),c(3:Nat,0))","uses_proof":["Bool.false","Lean.Name","Lean.Name.anonymous","Lean.Name.num","Lean.Name.str","Nat","OfNat.ofNat","instOfNatNat","sorryAx"],"uses_statement":["Nat"]}
-/
#guard_msgs in
#fh_extract
