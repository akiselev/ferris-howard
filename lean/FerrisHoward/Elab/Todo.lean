/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Syntax.Basic

/-!
# `todo!` and the sorry report (A0.4)

**Stage: two, and the first of it.** The justification, per ground rule 2: `todo!("msg")`
must put its message in the message log, and `MacroM` cannot log — it can only throw. So
FH's stage-one expansion emits `fh_todo%`, a term whose elaborator logs and then
elaborates as `sorry`. The stage-two surface is one term elaborator; how `todo!` is
*translated* stays entirely in stage one.

The report is deliberately **derived, not bookkept**: `#fh_sorry_report` asks the
environment which declarations depend on `sorryAx` rather than trusting a list FH
maintained while expanding. So it also catches bodyless `fn`s, `sorry`s written inside
`lean! { }`, and anything else that arrives by another route — and it cannot drift from
reality, which a bookkept list can. C5's transitive-sorry scan is this question asked in
earnest.
-/

namespace FerrisHoward
open Lean Elab Command Term

/-- Log the todo, then elaborate as `sorry`. -/
@[term_elab fhTodoTerm]
def elabFhTodo : TermElab := fun stx expectedType? => do
  match stx with
  | `(fh_todo% $msg:str) => logInfo m!"FH todo: {msg.getString}"
  | _ => logInfo "FH todo"
  elabTerm (← `(sorry)) expectedType?

/-- Which declarations *in this module* depend on `sorryAx`, sorted.

Module-local (`constants.map₂`) so the report is about your file rather than about
Mathlib, and sorted so that it is stable enough to assert on. -/
def sorryingDecls : CommandElabM (Array Name) := do
  let env ← getEnv
  let mut out := #[]
  for (n, _) in env.constants.map₂.toList do
    if n.isInternalDetail then continue
    if (← collectAxioms n).contains `sorryAx then out := out.push n
  return out.qsort Name.lt

/-- Report every declaration in this module that depends on `sorryAx` — design §3's
project-wide sorry report, in its M0 form. -/
elab "#fh_sorry_report" : command => do
  let decls ← sorryingDecls
  if decls.isEmpty then
    logInfo "FH sorry report: no declarations depend on `sorryAx`"
  else
    let lines := decls.map (fun n => s!"  {n}") |>.toList
    logInfo <| s!"FH sorry report: {decls.size} declaration(s) depend on `sorryAx`\n"
      ++ String.intercalate "\n" lines

end FerrisHoward
