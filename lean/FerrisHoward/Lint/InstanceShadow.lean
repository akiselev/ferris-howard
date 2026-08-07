/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item
import Lean.Linter.Basic

/-!
# The instance-shadowing lint (A1.6, design §4.4)

Rust's coherence and orphan rules do **not** carry over: Lean has none and Mathlib depends
on that. Design §4.4 chooses the diagnostic answer instead — "a lint when an `impl` would
shadow an existing instance … addresses the real Mathlib pain point diagnostically rather
than prohibitively" — and this is it.

A lint, deliberately, not an error. Two instances for the same class and carrier are
sometimes exactly what you want (a `Fintype` you can compute with beside one you can
reason about), and sometimes a mistake that costs an afternoon. FH cannot tell which, so
it says what it sees and gets out of the way.

Post-elaboration, like every FH diagnostic: it is not part of the translation, and turning
it off changes no meaning. `set_option linter.fh.instanceShadow false` in a file that
means it.
-/

namespace FerrisHoward.Lint
open Lean Elab Command Linter Meta

register_option linter.fh.instanceShadow : Bool := {
  defValue := true
  descr := "warn when an FH `impl` adds an instance for a class and carrier that already had one"
}

/-- The `impl` items in a command, in source order. -/
private partial def implNodes (stx : Syntax) : Array Syntax :=
  if stx.isOfKind ``FerrisHoward.fhImpl then
    #[stx]
  else
    stx.getArgs.foldl (fun acc a => acc ++ implNodes a) #[]

/-- Report an `impl` whose class-and-carrier already had an instance. -/
def instanceShadowLinter : Linter where
  run stx := do
    unless getLinterValue linter.fh.instanceShadow (← getLinterOptions) do
      return
    unless stx.isOfKind ``FerrisHoward.fhItemCommand do
      return
    for node in implNodes stx do
      match node with
      | `(fh_item| impl $cls for $carrier $[$_wh]? { $_ms* }) =>
        -- Elaborate just the goal `C T`, then ask what could have solved it. Our own
        -- instance is in the environment by now, so *more than one* candidate means one
        -- was already there.
        try
          liftTermElabM do
            let clsStx ← liftMacroM (expandExpr cls)
            let carrierStx ← liftMacroM (expandExpr carrier)
            let goal ← Term.elabType (← `($clsStx $carrierStx))
            let insts ← SynthInstance.getInstances goal
            if insts.size > 1 then
              let names := insts.map (·.val.getAppFn) |>.filterMap fun
                | .const n _ => some n
                | _ => none
              let others := names.qsort (fun a b => a.toString < b.toString) |>.toList
              logLint linter.fh.instanceShadow node
                m!"this class and carrier already had an instance: {others}. Lean has no \
                   orphan rule, so two are legal — but if it was not intended, instance \
                   search will pick one and not tell you which."
        catch _ =>
          -- An `impl` that did not elaborate has already reported a real error; a lint on
          -- top of it is noise.
          pure ()
      | _ => pure ()

initialize addLinter instanceShadowLinter

end FerrisHoward.Lint
