/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item

/-!
# The golden tier: `#fh_expand` (I2)

`#fh_expand <fh item>` logs the hygiene-sanitized pretty-printed **Lean surface syntax**
that FH's stage-one macros produce, so a golden test is

```
/-- info: <expected Lean> -/
#guard_msgs (whitespace := lax) in
#fh_expand fn f(n: Nat) -> Nat { n }
```

Two deliberate properties:

* **FH's own expansion only.** Expansion stops as soon as the node is no longer an FH
  node kind, so goldens record *FH's* translation and never Lean's internal macro
  unfolding (`set_option … in` is itself a macro — recursively expanding it yields a
  bare `null` node of commands that cannot even be pretty-printed). This also keeps
  goldens stable across toolchain bumps, which R6 cares about.
* **Hygiene sanitized.** Macro scopes are erased before printing, so generated binders
  print as `x` rather than `x✝`. Verified deterministic on the pinned toolchain.

The command does not elaborate its argument: that is the elaboration tier's job.
-/

namespace FerrisHoward.Test
open Lean Elab Command PrettyPrinter

/-- Was this node produced by an FH parser? All FH productions are declared in the
`FerrisHoward` namespace, so the kind prefix answers it. -/
def isFhKind (k : SyntaxNodeKind) : Bool :=
  (`FerrisHoward).isPrefixOf k

/-- Apply FH's stage-one macros to `stx`, and stop at the first node that is not FH's.
FH translation functions are eager (they translate their whole subtree), so this is a
complete expansion, not a partial one. -/
partial def expandFhCommand (stx : Syntax) : CommandElabM Syntax := do
  if isFhKind stx.getKind then
    if let some stx' ← liftMacroM (Lean.Macro.expandMacro? stx) then
      return ← expandFhCommand stx'
  return stx

/-- Erase macro scopes from every identifier, so hygienic names print readably. -/
partial def sanitizeHygiene : Syntax → Syntax
  | .ident info _ val pre =>
    let val := val.eraseMacroScopes
    .ident info val.toString.toRawSubstring val pre
  | .node info k args => .node info k (args.map sanitizeHygiene)
  | s => s

/-- Pretty-print an expansion: a single command, or a `null` node of several (an FH item
may expand to more than one Lean declaration — A0.3 onwards). -/
def ppExpansion (stx : Syntax) : CommandElabM Format := do
  let stx := sanitizeHygiene stx
  if stx.getKind == nullKind then
    let fmts ← stx.getArgs.mapM fun c => liftCoreM <| ppCommand ⟨c⟩
    return Format.joinSep fmts.toList Format.line
  else
    liftCoreM <| ppCommand ⟨stx⟩

/-- Log the hygiene-sanitized Lean surface syntax that FH's stage-one macros produce for
the following FH item. The golden tier; see the module header. -/
elab "#fh_expand " c:command : command => do
  logInfo (← ppExpansion (← expandFhCommand c))

end FerrisHoward.Test
