/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward

/-!
# `fh_emit` — publication-grade Lean out (ADR-006 / `research/codegen.md` §2, E1)

```
lake exe fh_emit Tests/corpus/g01_peano.lean > g01.lean
```

Reads an FH-in-`.lean` file and writes Lean with **no FH dependency**: FH commands are
expanded one step to Lean surface syntax and formatted; everything else is copied
verbatim, so ordinary Lean, its comments and its formatting survive untouched.

Three properties, in the order they matter:

1. **Faithfulness by construction.** FH constructs are syntax → syntax macros, so this is
   one macro-expansion step plus a formatter — no `Expr`-level delaboration and none of its
   lossiness. That is why ADR-006 makes the discipline binding rather than preferred.
2. **The emittable lint.** If any FH syntax survives expansion, emission fails and names
   the construct, so a feature that cannot be published is found when it is written rather
   than when a referee asks for the file.
3. **Imports.** FH's own imports are dropped and everything else is kept. ADR-006 §2's
   prelude policy — Mathlib-only, with FH's support library inlined, vendored or
   upstreamed — needs no implementation yet, because FH has no support library: nothing it
   emits mentions an FH constant.

Commands are elaborated as they are emitted: expanding command *n+1* needs the environment
command *n* produced.
-/

open Lean Elab Command FerrisHoward

/-- Is this FH item a bridge import — `use lean::C;`?

Checked on the *source* item rather than on its expansion, so no string is inspected and
no syntax is re-parsed. `use lean::…` is exactly the bridge form: `Expand/Item.lean`'s
`usePath?` maps a `lean`-rooted path to `FerrisHoward.Bridge.…` and leaves every other
path alone. -/
def isBridgeUse (stx : Syntax) : Bool :=
  (stx.find? fun s =>
    s.isOfKind ``FerrisHoward.fhUse
      && (s.find? fun t => t.isIdent && (`lean).isPrefixOf t.getId).isSome).isSome

/-- The header of the emitted file: the original imports, minus FH's. -/
def emitHeader (header : Syntax) : String := Id.run do
  let mut out := ""
  for imp in header[1].getArgs do
    let name := imp[2].getId
    if name == `FerrisHoward || (`FerrisHoward).isPrefixOf name then continue
    out := out ++ s!"import {name}\n"
  return out

/-- Emit one command.

Four cases, and the interesting ones are the middle two:

* `#guard_msgs … in cmd` is **dropped**, guard and contents together. It is a test
  assertion, and an assertion about FH's diagnostics is meaningless in an FH-free
  artifact — worse, a *negative* fixture's contents are deliberately ill-typed, so
  unwrapping them produces an artifact that cannot elaborate. The round-trip gate found
  this the first time it ran;
* an FH *declaration* is expanded, linted and formatted;
* any other FH command is authoring scaffolding (`#fh_expand`, `#fh_spans`,
  `#fh_sorry_report`, …) and is **dropped** — a publication artifact does not carry the
  tool that wrote it. The count is reported on stderr rather than passed over in silence;
* everything else is copied verbatim, comments and formatting included.

`assertEmittable` still runs on the expansion, so an FH construct hiding inside an
ordinary Lean command is an error rather than a surprise in the output. -/
partial def emitOne (src : String) (stx : Syntax) : CommandElabM (String × Nat) := do
  if stx.isOfKind ``Lean.guardMsgsCmd then
    return ("", 1)
  if stx.isOfKind ``FerrisHoward.fhItemCommand then
    -- `use lean::Dvd;` becomes `open FerrisHoward.Bridge.Dvd`, which is *scaffolding*: the
    -- bridge has already done its work by the time anything is emitted (`p.dvd(a)` is
    -- `Dvd.dvd p a` in the output), and carrying the `open` would put an FH module in the
    -- artifact's import graph — exactly what ADR-006 forbids. A non-`lean` `use` is kept,
    -- because an ordinary `open` can still be load-bearing for the names FH emitted.
    if isBridgeUse stx then
      return ("", 1)
    return ((← Emit.emitCommand stx).pretty ++ "\n", 0)
  if Emit.isFhKind stx.getKind then
    return ("", 1)
  Emit.assertEmittable stx
  match stx.getPos?, stx.getTailPos? with
  | some b, some e => return ((String.Pos.Raw.extract src b e).trimAscii.copy ++ "\n", 0)
  | _, _ => return ("", 0)

/-- Emit one command and elaborate it, carrying the command state forward. -/
def stepFile (src : String) (stx : Syntax) (ctx : Command.Context) (st : Command.State) :
    IO ((String × Nat) × Command.State) := do
  let act : CommandElabM (String × Nat) := do
    let out ← emitOne src stx
    elabCommandTopLevel stx
    return out
  match ← ((act.run ctx).run st).toIO' with
  | .ok (out, st') => return (out, st')
  | .error e => throw (IO.userError (← e.toMessageData.toString))

/-- Process a file command by command. -/
partial def emitFile (path : System.FilePath) : IO String := do
  let input ← IO.FS.readFile path
  let inputCtx := Parser.mkInputContext input path.toString
  let (header, parserState, messages) ← Parser.parseHeader inputCtx
  let (env, messages) ← processHeader header {} messages inputCtx
  let mut cmdState := Command.mkState env messages {}
  let mut ps := parserState
  let mut out := emitHeader header
  let mut dropped := 0
  -- Drained per command: the terminal `eoi` resets the log, so a file's errors vanish if
  -- you wait for the end to look.
  let mut collected : Array Message := #[]
  repeat
    let scope := cmdState.scopes.head!
    let pmctx : Parser.ParserModuleContext :=
      { env := cmdState.env, options := scope.opts,
        currNamespace := scope.currNamespace, openDecls := scope.openDecls }
    let (stx, ps', messages') := Parser.parseCommand inputCtx pmctx ps cmdState.messages
    ps := ps'
    cmdState := { cmdState with messages := messages' }
    let ctx : Command.Context :=
      { fileName := path.toString, fileMap := inputCtx.fileMap, snap? := none,
        cancelTk? := none }
    let ((emitted, dropped'), st) ← stepFile input stx ctx cmdState
    collected := collected ++ st.messages.reportedPlusUnreported.toArray
    cmdState := { st with messages := {} }
    out := out ++ emitted
    dropped := dropped + dropped'
    if Parser.isTerminalCommand stx then break
  -- An input that does not elaborate has no publication artifact; say so rather than
  -- writing a file that only looks finished.
  for msg in collected do
    if msg.severity matches .error then
      throw (IO.userError (← msg.toString))
  if dropped > 0 then
    IO.eprintln s!"fh_emit: dropped {dropped} FH authoring command(s) — scaffolding is not \
                   part of the artifact"
  return out

def usage : String :=
  "usage: fh_emit <file.lean>\n\
   \n\
   Writes publication-grade Lean to stdout: FH commands expanded to Lean surface syntax,\n\
   everything else verbatim, FH imports dropped. Fails if any FH construct does not\n\
   expand (the emittable lint), or if the input does not elaborate."

unsafe def main (args : List String) : IO UInt32 := do
  match args with
  | [path] =>
    -- Module initializers must run, or no *imported* parser survives the import and only
    -- Lean's builtin syntax parses — which silently truncates every command at its first
    -- notation (`+`, `=`, and every FH construct).
    enableInitializersExecution
    initSearchPath (← findSysroot)
    IO.print (← emitFile path)
    return 0
  | _ =>
    IO.eprintln usage
    return 1
