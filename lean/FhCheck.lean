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
partial def checkFile (path : System.FilePath) :
    IO (Array Diagnostic × Environment × Array InfoTree) := do
  let input ← IO.FS.readFile path
  let inputCtx := Parser.mkInputContext input path.toString
  let (header, parserState, messages) ← Parser.parseHeader inputCtx
  let (env, headerMessages) ← processHeader header {} messages inputCtx
  -- The header's own messages are taken here rather than left in the command state to be
  -- picked up later. `processHeader` reports a failed import by returning an *empty*
  -- environment plus a message, and if that message is not read out the tool goes on to
  -- elaborate the whole file against a environment with no `OfNat` in it — emitting a
  -- screen of "unknown constant" errors that name everything except the one thing that
  -- actually went wrong.
  let mut collected : Array Message := headerMessages.toArray
  -- And when the header did fail there is nothing to learn from elaborating on: every
  -- later message would be a consequence of the missing environment, not of the file.
  if headerMessages.hasErrors then
    let mut diags := #[]
    for msg in collected do
      let endPos := msg.endPos.getD msg.pos
      diags := diags.push {
        severity := severityString msg.severity
        line := msg.pos.line, column := msg.pos.column
        endLine := endPos.line, endColumn := endPos.column
        message := (← msg.data.toString).trimAscii.copy }
    return (diags, env, #[])
  let mut cmdState := Command.mkState env {} {}
  let mut ps := parserState
  -- Messages are drained after every command rather than read at the end: elaborating the
  -- terminal `eoi` command resets the log, so a whole file's diagnostics vanish if you
  -- wait for it.
  let mut trees : Array InfoTree := #[]
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
      trees := trees ++ st.infoState.trees.toArray
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
  return (diags, cmdState.env, trees)

/-- Every `sorry` site in the file, with its goal and local context.

`agent-interface.md` §1 asks for "the goal state at every `sorry`/`todo!()`", and calls the
edit → check → read goals → edit loop "90% of an agent's loop". This is that.

Read from the **info tree** rather than by hunting `sorryAx` in elaborated terms, because
the tree is what carries a position and a local context — an agent needs to know *where*
the hole is in the file it wrote, and what is in scope there. FH's span discipline is what
makes the position the FH one. -/
def sorryGoals (trees : Array InfoTree) : CommandElabM (Array Json) := do
  let mut out := #[]
  let mut seen : Std.HashSet (Nat × Nat) := {}
  for tree in trees do
    let infos := tree.foldInfo (init := #[]) fun ctx i acc =>
      match i with
      -- User-written holes only. A *synthetic* sorry is Lean recovering from an
      -- elaboration error, and the diagnostics already report that; an agent wants the
      -- holes it left, whose goals it can actually work on.
      | .ofTermInfo ti =>
        if ti.expr.isSorry && !ti.expr.isSyntheticSorry then acc.push (ctx, ti) else acc
      | _ => acc
    for (ctx, ti) in infos do
      let some pos := ti.stx.getPos? | continue
      let p := (← getFileMap).toPosition pos
      let endP := (← getFileMap).toPosition (ti.stx.getTailPos?.getD pos)
      let goal ← ctx.runMetaM ti.lctx do
        let ty ← Meta.inferType ti.expr
        pure (toString (← Meta.ppExpr ty))
      let hyps ← ctx.runMetaM ti.lctx do
        let mut hs := #[]
        for d in (← getLCtx) do
          if d.isImplementationDetail then continue
          hs := hs.push <| Json.mkObj [
            ("name", Json.str (toString d.userName.eraseMacroScopes)),
            ("type", Json.str (toString (← Meta.ppExpr d.type)))]
        pure hs
      -- One entry per position: the elaborator can visit a hole more than once, and a
      -- duplicate is noise rather than a second thing to do.
      unless seen.contains (p.line, p.column) do
        seen := seen.insert (p.line, p.column)
        out := out.push <| Json.mkObj [
          ("line", Json.num p.line), ("column", Json.num p.column),
          ("endLine", Json.num endP.line), ("endColumn", Json.num endP.column),
          ("goal", Json.str goal),
          ("context", Json.arr hyps)]
  return out

/-- How a name binds, computed rather than annotated.

Design §4.9 separates two layers on principle: *what an object is* (space, claim,
structured carrier — user-written, and `#[role(…)]`'s business) from *how a name binds*
(parameter, implicit, instance, …), which is "**derivable**, so the tooling computes and
reports it rather than asking the user to annotate it". This is the derivation.

What it does not yet distinguish is *ambient* from *inline* — a `var` and an inline generic
produce the same binder by construction (that identity is `Tests/M2/Var.lean`'s
obligation), so telling them apart needs the FH syntax rather than the elaborated type.
Named here rather than implied. -/
def bindingRole : BinderInfo → String
  | .default => "parameter"
  | .implicit => "implicit"
  | .strictImplicit => "strict-implicit"
  | .instImplicit => "instance"

def bindersOf (env : Environment) (n : Name) : CommandElabM (Array Json) := do
  let some ci := env.find? n | return #[]
  let act : MetaM (Array Json) := Meta.forallTelescopeReducing ci.type fun xs _ => do
    let mut out := #[]
    for x in xs do
      let d ← x.fvarId!.getDecl
      if d.isImplementationDetail then continue
      out := out.push <| Json.mkObj [
        ("name", Json.str (toString d.userName.eraseMacroScopes)),
        ("role", Json.str (bindingRole d.binderInfo)),
        ("type", Json.str (toString (← Meta.ppExpr d.type)))]
    return out
  liftTermElabM (Meta.MetaM.run' act)

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
      ("binders", Json.arr (← bindersOf env n)),
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
    let (diags, env, trees) ← checkFile path
    let errors := diags.filter (·.severity == "error")
    let fileMap := (← IO.FS.readFile path).toFileMap
    let run {α} (act : CommandElabM α) (dflt : α) : IO α := do
      let ctx : Command.Context :=
        { fileName := pathStr, fileMap := fileMap, snap? := none, cancelTk? := none }
      match ← (((act).run ctx).run (Command.mkState env)).toIO' with
      | .ok (r, _) => pure r
      | .error _ => pure dflt
    let sorries ← run (declReport env) #[]
    let goals ← run (sorryGoals trees) #[]
    let report := Json.mkObj [
      ("file", Json.str pathStr),
      ("status", Json.str (if errors.isEmpty then "ok" else "error")),
      ("diagnostics", Json.arr (diags.map Diagnostic.toJson)),
      ("goals", Json.arr goals),
      ("declarations", Json.arr sorries)]
    IO.println report.pretty
    return (if errors.isEmpty then 0 else 1)
  | _ =>
    IO.eprintln usage
    return 1
