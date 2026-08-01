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

/-- The value of an `fn`: its body, or `sorry` for a bodyless declaration.

Design §3: `fn f(…) -> U;` is `def f … : U := sorry`. The `sorry` is deliberately Lean's
own, so the declaration carries `sorryAx` and every downstream honesty check —
`#print axioms`, the transitive-sorry scan in C5 — sees it without FH having to be
trusted. A0.4 adds the tracking report on top.

The `Bool` reports whether the body is `sorry`-valued, which `fhDecl` uses to decide
whether the unused-variable linter should be silenced for this declaration. -/
private def expandFnBody (b : TSyntax `fh_fn_body) : MacroM (TSyntax `term × Bool) :=
  withRef b do
    match b with
    | `(fh_fn_body| { $e }) => return (← expandExpr e, false)
    | `(fh_fn_body| ;) => return (← `(sorry), true)
    | _ => Macro.throwErrorAt b "FH: no expansion for this function body"

/-- Stage-one expansion of a single FH item into Lean surface syntax. -/
def expandItem (it : TSyntax `fh_item) : MacroM (TSyntax `command) :=
  withRef it do
    match it with
    | `(fh_item| fn $n:ident($[$ps : $ts],*) -> $ret $body:fh_fn_body) => do
        let binders ← ps.zip ts |>.mapM fun (p, t) => expandParam p t
        let ret ← expandExpr ret
        let (body, sorryValued) ← expandFnBody body
        fhDecl (← `(command| def $n $binders* : $ret := $body)) sorryValued
    | _ => Macro.throwErrorAt it "FH: no expansion for this item"

macro_rules
  | `(command| $it:fh_item) => expandItem it

end FerrisHoward
