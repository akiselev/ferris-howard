/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean

/-!
# The sorry report (A0.4)

`#fh_sorry_report` lists the declarations in this module that depend on `sorryAx` —
design §3's project-wide sorry report, in its M0 form.

Deliberately **derived, not bookkept**: it asks the environment rather than trusting a list
FH maintained while expanding. So it also catches bodyless `fn`s, `sorry`s written inside
`lean! { }`, and anything that arrives by another route — and it cannot drift from
reality, which a bookkept list can. C5's transitive-sorry scan is this question asked in
earnest.
-/

namespace FerrisHoward
open Lean Elab Command

/-- Which declarations *in this module* depend on `sorryAx`, sorted.

Module-local (`constants.map₂`) so the report is about your file rather than about Mathlib,
and sorted so that it is stable enough to assert on. -/
def sorryingDecls : CommandElabM (Array Name) := do
  let env ← getEnv
  let mut out := #[]
  for (n, _) in env.constants.map₂.toList do
    if n.isInternalDetail then continue
    if (← collectAxioms n).contains `sorryAx then out := out.push n
  return out.qsort Name.lt

@[inherit_doc sorryingDecls]
elab "#fh_sorry_report" : command => do
  let decls ← sorryingDecls
  if decls.isEmpty then
    logInfo "FH sorry report: no declarations depend on `sorryAx`"
  else
    let lines := decls.map (fun n => s!"  {n}") |>.toList
    logInfo <| s!"FH sorry report: {decls.size} declaration(s) depend on `sorryAx`\n"
      ++ String.intercalate "\n" lines

end FerrisHoward
