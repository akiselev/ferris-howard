/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Syntax.Basic
import Lean.Linter.Basic

/-!
# The `todo!` linter (A0.4, under ADR-006)

Design §3 asks for `todo!("msg")` to put its message in a log. The first implementation
did that with a term elaborator, and ADR-006 rules that out twice over: it was
`elab_rules` where a macro would do, and — worse — the expansion contained `fh_todo%`, an
FH-only syntax, so the emitted Lean would not have been FH-free.

So `todo!(…)` now expands to plain `sorry`, and the message arrives here instead. A linter
is the right home for it on the merits, not just for purity: it reads the *FH source*
syntax after elaboration, it can be switched off per file without changing what anything
means, and it is the same shape the I6 coercion audit will take
(`coercion-control.md`). Diagnostics are not part of the translation.
-/

namespace FerrisHoward.Lint
open Lean Elab Command Linter

register_option linter.fh.todo : Bool := {
  defValue := true
  descr := "log the message carried by each `todo!(…)` in FH source"
}

/-- Every `todo!` node in a command, in source order. -/
private partial def todoNodes (stx : Syntax) : Array Syntax :=
  if stx.isOfKind ``FerrisHoward.fhExprTodo then
    #[stx]
  else
    stx.getArgs.foldl (fun acc a => acc ++ todoNodes a) #[]

/-- Report each `todo!(…)`, with its message, at its own position. -/
def fhTodoLinter : Linter where
  run stx := do
    unless getLinterValue linter.fh.todo (← getLinterOptions) do
      return
    -- Only FH *declaration* commands: the report says "this declaration is incomplete",
    -- and `#fh_expand`/`#fh_emit` declare nothing — they inspect syntax, and a todo
    -- inside one is an example, not a hole in the development.
    unless stx.isOfKind ``FerrisHoward.fhItemCommand do
      return
    for node in todoNodes stx do
      -- `todo!` `(` (str)? `)` — the message slot is optional
      let msg? := node[2].getOptional?.bind fun s =>
        if s.isOfKind strLitKind then s.isStrLit? else none
      match msg? with
      | some m => logInfoAt node m!"FH todo: {m}"
      | none => logInfoAt node "FH todo"

initialize addLinter fhTodoLinter

end FerrisHoward.Lint
