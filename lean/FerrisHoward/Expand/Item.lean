/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Basic

/-!
# Item expansion (stage one)

Every FH item routes through `expandItem`, and the only `macro_rules` in the language
dispatches the command wrapper to it. One dispatch point means the golden printer, the
future `.fh` driver, and nested items (`mod { … }`, A0.3) all share the same translation
rather than re-deriving it.
-/

namespace FerrisHoward
open Lean

/-- Stage-one expansion of a single FH item into Lean surface syntax. -/
def expandItem (it : TSyntax `fh_item) : MacroM (TSyntax `command) :=
  withRef it do
    match it with
    | `(fh_item| fn $n:ident($[$ps : $ts],*) -> $ret { $body }) => do
        let binders ← ps.zip ts |>.mapM fun (p, t) => expandParam p t
        let ret ← expandExpr ret
        let body ← expandExpr body
        fhDecl (← `(command| def $n $binders* : $ret := $body))
    | _ => Macro.throwErrorAt it "FH: no expansion for this item"

macro_rules
  | `(command| $it:fh_item) => expandItem it

end FerrisHoward
