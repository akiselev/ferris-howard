/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item

/-!
# `emit-lean`: the publication artifact (ADR-006 / `research/codegen.md` §2)

FH constructs are **syntax → syntax** macros, so emitting publication-grade Lean is one
macro-expansion step plus a formatter. Faithfulness is by construction: there is no
`Expr`-level delaboration in the path, and so none of its lossiness.

That is why this module lives in the library rather than under `Test/`. The golden tier
and the publication path are the *same* expansion — a golden is a preview of the emitted
artifact, which is the strongest reason to keep the goldens honest.

## The emittable lint

The one property that makes the artifact FH-free: **no FH node kind may survive
expansion.** `assertEmittable` checks it and names the offending construct. A feature that
cannot expand to Lean surface syntax is therefore either given a real expander or kept out
of the publishable subset deliberately — never discovered at publication time.

FH itself is not in the emitted file's import closure, and nothing in the expansion
mentions an FH constant: every name FH emits is Lean's or Mathlib's.
-/

namespace FerrisHoward.Emit
open Lean Elab Command PrettyPrinter

/-- Was this node produced by an FH parser? All FH productions are declared in the
`FerrisHoward` namespace, so the kind prefix answers it. -/
def isFhKind (k : SyntaxNodeKind) : Bool :=
  (`FerrisHoward).isPrefixOf k

/-- Apply FH's stage-one macros to `stx`, stopping at the first node that is not FH's.

FH translation functions are eager — each translates its whole subtree — so this is a
complete expansion rather than a partial one, and it deliberately does *not* keep going
into Lean's own macros: the artifact should read as the Lean a person would have written,
not as its internal unfolding. -/
partial def expandFh (stx : Syntax) : CommandElabM Syntax := do
  let stx ←
    if isFhKind stx.getKind then
      match ← liftMacroM (Lean.Macro.expandMacro? stx) with
      | some stx' => expandFh stx'
      | none => pure stx
    else pure stx
  -- and then into the children: an item's expansion can leave FH nodes *inside* Lean
  -- surface syntax — `fh_dot%`, the method-spelling hook, is one by design — and those
  -- have to be resolved too, in the scope this command is elaborated in.
  match stx with
  | .node info k args => return .node info k (← args.mapM expandFh)
  | _ => return stx

/-- Flatten `(f x) y` into `f x y`.

Application is left-associative, so the two are the same term; but a bridged method
spelling arrives nested — `p.dvd(a)` becomes `Dvd.dvd p` applied to `a` — and an artifact
meant for a referee should read as the Lean a person would have written. This is the only
normalisation the printer performs, and it is why a golden shows `Dvd.dvd p a`. -/
partial def flattenApps : Syntax → Syntax
  | .node info k args =>
    let args := args.map flattenApps
    let stx := Syntax.node info k args
    if k == ``Lean.Parser.Term.app && args[0]!.isOfKind ``Lean.Parser.Term.app then
      let inner := args[0]!
      .node info k #[inner[0]!, mkNullNode (inner[1]!.getArgs ++ args[1]!.getArgs)]
    else stx
  | s => s

/-- The first surviving FH node, if any. -/
partial def firstFhNode? (stx : Syntax) : Option Syntax :=
  if isFhKind stx.getKind then
    some stx
  else
    stx.getArgs.findSome? firstFhNode?

/-- The emittable lint: fail if any FH syntax survived expansion, naming the construct. -/
def assertEmittable (stx : Syntax) : CommandElabM Unit := do
  if let some bad := firstFhNode? stx then
    throwErrorAt bad
      "FH: `{bad.getKind}` does not expand to Lean surface syntax, so it cannot be \
       emitted. Give it an expander, or keep it out of the publishable subset."

/-- Erase macro scopes from every identifier, so hygienic names print readably. Verified
deterministic on the pinned toolchain. -/
partial def sanitizeHygiene : Syntax → Syntax
  | .ident info _ val pre =>
    let val := val.eraseMacroScopes
    .ident info val.toString.toRawSubstring val pre
  | .node info k args => .node info k (args.map sanitizeHygiene)
  | s => s

/-- Pretty-print an expansion: one command, or the `null` node of several that an item
expanding to more than one declaration produces. -/
def ppExpansion (stx : Syntax) : CommandElabM Format := do
  let stx := flattenApps (sanitizeHygiene stx)
  if stx.getKind == nullKind then
    let fmts ← stx.getArgs.mapM fun c => liftCoreM <| ppCommand ⟨c⟩
    return Format.joinSep fmts.toList Format.line
  else
    liftCoreM <| ppCommand ⟨stx⟩

/-- Expand one command to Lean surface syntax, check it is emittable, and format it. -/
def emitCommand (stx : Syntax) : CommandElabM Format := do
  let expanded ← expandFh stx
  assertEmittable expanded
  ppExpansion expanded

end FerrisHoward.Emit

namespace FerrisHoward
open Lean Elab Command

/-- Print the publication-grade Lean for the following FH item: one expansion step, the
emittable lint, and a formatter. -/
elab "#fh_emit " c:command : command => do
  logInfo (← Emit.emitCommand c)

end FerrisHoward
