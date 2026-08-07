/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item
import Lean.Linter.Basic

/-!
# The `var`-shadowing lint (A2.4, F17, design §4.8)

Design §4.8: "inline generics shadow ambient `var`s but must restate the annotation in
full, with a shadowing lint."

Both halves are already true without machinery. Shadowing works because Lean's `variable`
is only consulted for names a declaration does not bind itself, and the annotation is
restated in full because FH's generics always carry one — `<A>` means `{A : Type _}`
whatever the ambient `A` said. What is missing is the *warning*, which is this.

A lint, not an error: shadowing is legal and occasionally what you want. But an inline
`<A>` that happens to collide with an ambient `A: impl Group` silently drops the group
structure, and that is a long afternoon. FH says what it sees.

It covers **quantifier** binders too — `for<eps: Real> …` under an ambient `eps` — because
FH spells both with `fhGenericParam` and both carry the same hazard for the same reason.

Post-elaboration, like every FH diagnostic: not part of the translation, and turning it off
changes no meaning. `set_option linter.fh.varShadow false` in a file that means it.
-/

namespace FerrisHoward.Lint
open Lean Elab Command Linter

register_option linter.fh.varShadow : Bool := {
  defValue := true
  descr := "warn when an FH declaration's inline generic shadows an ambient `var`"
}

/-- The names a `variable` binder introduces. Instance binders are skipped: their names are
generated and shadowing one is not a thing anyone does by accident. -/
private def binderNames (b : Syntax) : Array Name :=
  let kind := b.getKind
  if kind == ``Lean.Parser.Term.explicitBinder
      || kind == ``Lean.Parser.Term.implicitBinder
      || kind == ``Lean.Parser.Term.strictImplicitBinder then
    b[1].getArgs.filterMap fun id =>
      if id.isIdent then some id.getId.eraseMacroScopes else none
  else
    #[]

/-- The generic parameters an FH item declares, with their source syntax for the span. -/
private partial def genericIdents (stx : Syntax) : Array Ident :=
  if stx.isOfKind ``FerrisHoward.fhGenericParam then
    -- `binderIdent` is a node wrapping the ident (or a `_`), not the ident itself
    let id := if stx[0].isIdent then stx[0] else stx[0][0]
    if id.isIdent then #[⟨id⟩] else #[]
  else
    stx.getArgs.foldl (fun acc a => acc ++ genericIdents a) #[]

/-- Report an inline generic that shadows an ambient `var`. -/
def varShadowLinter : Linter where
  run stx := do
    unless getLinterValue linter.fh.varShadow (← getLinterOptions) do
      return
    unless stx.isOfKind ``FerrisHoward.fhItemCommand do
      return
    let ambient := (← getScope).varDecls.foldl (fun acc b => acc ++ binderNames b.raw) #[]
    if ambient.isEmpty then return
    for g in genericIdents stx do
      if ambient.contains g.getId.eraseMacroScopes then
        logLint linter.fh.varShadow g
          m!"`{g.getId}` shadows an ambient `var` of the same name. That is legal, and the \
             inline annotation wins in full — including any structure the `var` carried, \
             which this declaration does not inherit."

initialize addLinter varShadowLinter

end FerrisHoward.Lint
