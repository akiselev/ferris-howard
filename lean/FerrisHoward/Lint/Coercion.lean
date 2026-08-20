/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item
import Lean.Linter.Basic

/-!
# F9: coercions are written (A2.0)

F9 rules that coercions are always written, as `e as T`, and that silent
unification-driven coercion is disabled in FH-elaborated code. This is the mechanism I6
chose (`coercion-control.md`), and it is deliberately *not* an elaborator under every FH
term — that was the blast radius R13 existed to avoid.

Instead: `Lean.Elab.Term.mkCoe` pushes a `CoeExpansionTrace` info leaf at every insertion,
carrying the syntax it was inserted at. After an FH item elaborates, this walks that
declaration's info trees and reports any insertion whose position does not lie inside an
`as` node. Licensing by *position* keeps `as` on Lean's real coercion — a marker constant
in the elaborated term would break `simp` and `norm_cast` matching against Mathlib's
`Nat.cast` family, which is a far worse price than comparing ranges.

## What this costs, stated

The coercion is inserted and *then* flagged, so the declaration exists at the moment the
error is reported. FH's contract is that a silent coercion is an error, and an error-level
report satisfies it, but the environment is not pristine at that instant.

`lean! { }` interiors are out of scope: inside the escape hatch Lean's rules apply,
coercions included. That is what an escape hatch is.

`OfNat` literal elaboration is not a coercion and never appears here — it is sanctioned
separately as Ruling C item five.
-/

namespace FerrisHoward.Lint
open Lean Elab Command Linter

register_option linter.fh.silentCoercion : Bool := {
  defValue := true
  descr := "report coercions FH did not write (F9); `e as T` is how you write one"
}

/-- Source ranges of the `as` nodes in a command: the coercions its author asked for. -/
private partial def asRanges (stx : Syntax) : Array Lean.Syntax.Range :=
  let here : Array Lean.Syntax.Range :=
    if stx.isOfKind ``FerrisHoward.fhExprAs then
      match stx.getRange? with
      | some r => #[r]
      | none => #[]
    else #[]
  stx.getArgs.foldl (fun acc a => acc ++ asRanges a) here

/-- Every coercion insertion recorded in an info tree, with where it happened. -/
private def coercionSites (t : InfoTree) : Array Syntax :=
  t.foldInfo (init := #[]) fun _ctx i acc =>
    match i with
    | .ofCustomInfo ci =>
      if (ci.value.get? Term.CoeExpansionTrace).isSome then acc.push ci.stx else acc
    | _ => acc

/-- Is this insertion inside an `as` the author wrote? -/
private def licensed (ranges : Array Lean.Syntax.Range) (site : Syntax) : Bool :=
  match site.getRange? with
  | none => true   -- no position to judge; do not invent a complaint
  | some r => ranges.any fun a => a.start ≤ r.start && r.stop ≤ a.stop

/-- Report coercions FH did not write. -/
def silentCoercionLinter : Linter where
  run stx := do
    unless getLinterValue linter.fh.silentCoercion (← getLinterOptions) do
      return
    unless stx.isOfKind ``FerrisHoward.fhItemCommand do
      return
    let ranges := asRanges stx
    for tree in (← get).infoState.trees do
      for site in coercionSites tree do
        unless licensed ranges site do
          -- An *error*, not a warning: F9 is a rule about what FH-elaborated code means,
          -- and the A2.0 gate asks for a silently-coercing expression to fail. The option
          -- above switches the rule off for a file that means to opt out.
          logErrorAt site
            m!"FH: this coercion is Lean's, not yours. F9 says coercions are written — \
               spell it `… as T`, or change the types so none is needed.\n\n\
               Note: this check can be disabled with \
               `set_option linter.fh.silentCoercion false`."

initialize addLinter silentCoercionLinter

end FerrisHoward.Lint
