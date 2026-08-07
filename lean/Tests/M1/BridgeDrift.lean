/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward.Bridge.Methods

/-!
# What a bridge import shadows (F16)

`use lean::C;` brings a class's F16 method spellings into scope for the rest of the file.
Inside that scope the spelling wins, so the import has a blast radius, and this file is
where it is written down: for each bridged spelling, every declaration in Mathlib named
`T.<spelling>` that the import makes unreachable through `.`.

Scoping is what makes those numbers acceptable rather than alarming. A global table for
`comp` would have replaced bundled composition at 587 sites with no one asking; an import
replaces it only where a file said `use lean::Function;`, and `MonoidHom::comp(f, g)`
still reaches the real method by path. The counts are pinned so that growth is a decision
rather than a surprise — re-baselining is its own PR under ground rule 6.

The `dvd` list is the one worth reading: every entry is a lemma whose receiver is a
**proof** (`IsUnit.dvd : IsUnit u → u ∣ a`), plus `Dvd.dvd` itself. No *carrier* type
declares a `dvd` method, which is why `use lean::Dvd;` costs a file almost nothing.
-/

open Lean Elab Command

/-- List the declarations whose name ends in `.<spelling>` — what a bridge for that
spelling shadows inside its import's scope. -/
elab "#fh_bridge_shadows " s:str : command => do
  let spelling := s.getString
  let env ← getEnv
  let mut hits : Array Name := #[]
  for (n, _) in env.constants.toList do
    if n.isInternalDetail then continue
    match n with
    | .str p last => if last == spelling && p != .anonymous then hits := hits.push n
    | _ => pure ()
  let sorted := hits.qsort (fun a b => a.toString < b.toString)
  logInfo <| s!"{spelling}: {sorted.size}\n" ++
    String.intercalate "\n" (sorted.toList.map (s!"  {·}"))

/-! All proof receivers, plus `Dvd.dvd` itself. -/

/--
info: dvd: 15
  Associated.dvd
  DirichletCharacter.FactorsThrough.dvd
  Dvd.dvd
  Eq.dvd
  Equiv.dvd
  Int.ModEq.dvd
  IsPrimePow.dvd
  IsUnit.dvd
  Lean.Meta.Grind.Arith.Cutsat.FindIntValResult.dvd
  Lean.Meta.Grind.Arith.Cutsat.UnsatProof.dvd
  Nat.ModEq.dvd
  Polynomial.IsRoot.dvd
  PosNum.dvd
  minpoly.dvd
  ringChar.dvd
-/
#guard_msgs in
#fh_bridge_shadows "dvd"

/-! `comp` and `union` are the other end of the range: hundreds of real methods, every one
of them the right answer for its own receiver. They are bridgeable *because* the import is
opt-in, and a file that imports them is saying it means the plain function. -/

/-- info: comp: 587 -/
#guard_msgs (whitespace := lax, substring := true) in
#fh_bridge_shadows "comp"

/-- info: union: 157 -/
#guard_msgs (whitespace := lax, substring := true) in
#fh_bridge_shadows "union"
