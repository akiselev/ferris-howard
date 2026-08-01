/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward

/-!
# `fh check` v0 (A1.9 / C1)

```
lake exe fh_check Tests/corpus/g01_peano.lean
```

Elaborates an FH file and reports, as JSON on stdout: status, diagnostics with **FH-source
spans**, the declarations that depend on `sorryAx`, and each declaration's axioms. That is
`agent-interface.md`'s `elaborate`, and the format is the contract the MCP layer (C3) will
serve verbatim.

Two decisions worth stating.

**Spans are FH's, not the expansion's.** They come out of the same discipline the span
tier has been checking since M0 — user syntax passes through untouched, synthesized nodes
inherit their source node's position — so a diagnostic's `line`/`column` point into the
file the agent wrote. Nothing here re-derives them.

**Sorries are derived, not bookkept.** The report asks the environment which declarations
depend on `sorryAx` rather than trusting FH's own account of what it expanded, so it also
catches `sorry`s written inside `lean! { }` and anything else that arrives another way.
The same choice `#fh_sorry_report` makes, for the same reason.

Not yet, and named rather than implied: the error taxonomy with branch hints, the friendly
wording layer over Lean's raw messages (F14's "no Decidable instance" belongs there), and
`simp?` feedback. Those are C1's v1 at M2.
-/

open Lean Elab Command FerrisHoward

/-- One diagnostic, with the position in the FH source it points at. -/
structure Diagnostic where
  severity : String
  line : Nat
  column : Nat
  endLine : Nat
  endColumn : Nat
  message : String

def Diagnostic.toJson (d : Diagnostic) : Json :=
  Json.mkObj [
    ("severity", Json.str d.severity),
    ("line", Json.num d.line), ("column", Json.num d.column),
    ("endLine", Json.num d.endLine), ("endColumn", Json.num d.endColumn),
    ("message", Json.str d.message)]

def severityString : MessageSeverity → String
  | .information => "info"
  | .warning => "warning"
  | .error => "error"

/-- Elaborate a file and collect its diagnostics and final environment. -/
partial def checkFile (path : System.FilePath) : IO (Array Diagnostic × Environment) := do
  let input ← IO.FS.readFile path
  let inputCtx := Parser.mkInputContext input path.toString
  let (header, parserState, messages) ← Parser.parseHeader inputCtx
  let (env, messages) ← processHeader header {} messages inputCtx
  let mut cmdState := Command.mkState env messages {}
  let mut ps := parserState
  -- Messages are drained after every command rather than read at the end: elaborating the
  -- terminal `eoi` command resets the log, so a whole file's diagnostics vanish if you
  -- wait for it.
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
    match ← (((Command.elabCommandTopLevel stx).run ctx).run cmdState).toIO' with
    | .ok (_, st) =>
      collected := collected ++ st.messages.reportedPlusUnreported.toArray
      cmdState := { st with messages := {} }
    | .error e => throw (IO.userError (← e.toMessageData.toString))
    if Parser.isTerminalCommand stx then break
  let mut diags := #[]
  for msg in collected do
    if msg.isSilent then continue
    let endPos := msg.endPos.getD msg.pos
    diags := diags.push {
      severity := severityString msg.severity
      line := msg.pos.line, column := msg.pos.column
      endLine := endPos.line, endColumn := endPos.column
      message := (← msg.data.toString).trimAscii.copy }
  return (diags, cmdState.env)

/-- The declarations this file introduced, with their axioms — so an agent can tell a
complete argument from an incomplete one without taking FH's word for it. -/
def declReport (env : Environment) : CommandElabM (Array Json) := do
  let mut out := #[]
  let mut names := #[]
  for (n, _) in env.constants.map₂.toList do
    if n.isInternalDetail then continue
    names := names.push n
  for n in names.qsort (fun a b => a.toString < b.toString) do
    let axioms ← collectAxioms n
    out := out.push <| Json.mkObj [
      ("name", Json.str (toString n)),
      ("sorry", Json.bool (axioms.contains `sorryAx)),
      ("axioms", Json.arr (axioms.qsort (fun a b => a.toString < b.toString)
        |>.map (Json.str <| toString ·)))]
  return out

def usage : String :=
  "usage: fh_check <file.lean>\n\
   \n\
   Elaborates an FH file and writes a JSON report to stdout: status, diagnostics with FH\n\
   source spans, and per-declaration axioms including whether it depends on `sorryAx`.\n\
   Exit status is 1 if the file has errors."

unsafe def main (args : List String) : IO UInt32 := do
  match args with
  | [pathStr] =>
    enableInitializersExecution
    initSearchPath (← findSysroot)
    let path : System.FilePath := pathStr
    let (diags, env) ← checkFile path
    let errors := diags.filter (·.severity == "error")
    let sorries ← do
      let act : CommandElabM (Array Json) := declReport env
      let ctx : Command.Context :=
        { fileName := pathStr, fileMap := default, snap? := none, cancelTk? := none }
      match ← (((act).run ctx).run (Command.mkState env)).toIO' with
      | .ok (r, _) => pure r
      | .error _ => pure #[]
    let report := Json.mkObj [
      ("file", Json.str pathStr),
      ("status", Json.str (if errors.isEmpty then "ok" else "error")),
      ("diagnostics", Json.arr (diags.map Diagnostic.toJson)),
      ("declarations", Json.arr sorries)]
    IO.println report.pretty
    return (if errors.isEmpty then 0 else 1)
  | _ =>
    IO.eprintln usage
    return 1
