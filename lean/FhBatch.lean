/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean

/-!
# `fh_batch` — elaborate many files against one imported environment

```
lake exe fh_batch --import Mathlib --import FerrisHoward.Atlas.Home \
  --out-dir /tmp --log-prefix fh-attempt- Scratch/AttemptPlan01.lean ...
```

The refuter lane's shards each spend ~2–4 minutes and ~8.5 GB importing Mathlib before
answering anything — `lake env lean` pays the full import per *file*, so a 23-shard census
pays it 23 times. This driver pays it once per worker: import the named modules, then run
each file's commands against that shared environment. PLAN.md C7 calls this "warm daemon
per worker"; this is the batch half, pulled forward because the census made the cost
measurable.

Per file it writes `<out-dir>/<log-prefix><stem>.log` containing every non-silent message
and a final `EXIT=0`/`EXIT=1` line — the same contract as the shell-worker convention, so
`score-attempts.py` reads either runner's logs unchanged.

Files must not carry their own `import` header: the environment is this driver's contract,
and a file that states different imports would elaborate against something other than what
it says. Such a file is refused (an error line and `EXIT=1` in its log), never silently
reinterpreted.

Mechanics inherited from `fh_check`, for reasons that cost real time to learn there: drain
messages after **every** command (`eoi` resets the log), and `enableInitializersExecution`
plus `unsafe main`, or every imported parser is absent and files truncate at their first
`#`-command. `Command.mkState env` is fresh per file, so one file's declarations (the
planted controls redefine the same names in every shard) never leak into the next.
-/

open Lean Elab Command

def severityString : MessageSeverity → String
  | .information => "info"
  | .warning => "warning"
  | .error => "error"

/-- Elaborate one headerless file against `env`, returning its rendered messages and
whether any was an error. -/
partial def runFile (env : Environment) (path : System.FilePath) :
    IO (Array String × Bool) := do
  let input ← IO.FS.readFile path
  let inputCtx := Parser.mkInputContext input path.toString
  let (header, parserState, headerMessages) ← Parser.parseHeader inputCtx
  -- `headerToImports` adds the implicit `import Init` even when the file writes no header
  -- at all, so the guard must ask for imports *beyond* it — refusing on `size > 0` refused
  -- every file, including the headerless ones this driver exists for.
  if (headerToImports header).any (·.module != `Init) then
    return (#["error: file has its own import header; fh_batch supplies the environment"],
            true)
  let mut rendered : Array String := #[]
  let mut hadError := false
  for msg in headerMessages.toList do
    rendered := rendered.push s!"{severityString msg.severity}: {← msg.data.toString}"
    hadError := hadError || msg.severity matches .error
  let mut cmdState := Command.mkState env {} {}
  let mut ps := parserState
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
      -- Drained per command, exactly as `fh_check` does: waiting for the end loses the
      -- whole file's diagnostics when `eoi` resets the log.
      for msg in st.messages.reportedPlusUnreported.toList do
        if msg.isSilent then continue
        let pos := msg.pos
        rendered := rendered.push
          s!"{path}:{pos.line}:{pos.column}: {severityString msg.severity}: \
             {(← msg.data.toString).trimAscii}"
        hadError := hadError || msg.severity matches .error
      cmdState := { st with messages := {} }
    | .error e =>
      -- A monad-level failure is this file's problem, not the worker's: record it, mark
      -- the file failed, and let the driver move on to the next shard.
      rendered := rendered.push s!"error: {← e.toMessageData.toString}"
      hadError := true
      break
    if Parser.isTerminalCommand stx then break
  return (rendered, hadError)

def usage : String :=
  "usage: fh_batch --import <Module> [--import <Module>]* [--out-dir <dir>] "
    ++ "[--log-prefix <prefix>] <file.lean>...\n\n"
    ++ "Imports the named modules once, then elaborates each (headerless) file against\n"
    ++ "that environment, writing <out-dir>/<prefix><stem>.log with the file's messages\n"
    ++ "and a final EXIT=<status> line."

private def parseArgs : List String → List Name → Option String → String → List String →
    Option (List Name × Option String × String × List String)
  | [], ms, od, lp, fs => some (ms, od, lp, fs)
  | "--import" :: m :: rest, ms, od, lp, fs => parseArgs rest (ms ++ [m.toName]) od lp fs
  | "--out-dir" :: d :: rest, ms, _, lp, fs => parseArgs rest ms (some d) lp fs
  | "--log-prefix" :: p :: rest, ms, od, _, fs => parseArgs rest ms od p fs
  | f :: rest, ms, od, lp, fs =>
    if f.startsWith "--" then none else parseArgs rest ms od lp (fs ++ [f])

unsafe def main (args : List String) : IO UInt32 := do
  let some (modules, outDir?, logPrefix, files) := parseArgs args [] none "" []
    | do IO.eprintln usage; return 1
  if modules.isEmpty || files.isEmpty then
    IO.eprintln usage
    return 1
  let outDir := outDir?.getD "/tmp"
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let t0 ← IO.monoMsNow
  -- `loadExts := true`, or the import is an environment without its *extensions* — no
  -- token table, no parser, no elab attributes from the imported modules, so the first
  -- `#fh_home_attempt` is an unknown token the parser skips clean past. `processHeader`
  -- passes it (Elab/Import.lean), which is why `lake env lean` never shows the problem;
  -- `importModules`'s own default is `false`. `leakEnv` matches the CLI: this environment
  -- lives exactly as long as the process, so tracking it for GC buys nothing.
  let env ← importModules (modules.toArray.map fun m => { module := m : Import }) {}
    (leakEnv := true) (loadExts := true)
  IO.println s!"[import] {modules} in {(← IO.monoMsNow) - t0} ms"
  (← IO.getStdout).flush
  for f in files do
    let path : System.FilePath := f
    let stem := path.fileStem.getD f
    let logPath : System.FilePath := s!"{outDir}/{logPrefix}{stem}.log"
    let t1 ← IO.monoMsNow
    let (lines, hadError) ←
      try runFile env path
      catch e => pure (#[s!"error: driver: {e.toString}"], true)
    let status := if hadError then 1 else 0
    IO.FS.writeFile logPath (("\n".intercalate lines.toList) ++ s!"\nEXIT={status}\n")
    IO.println s!"[file] {stem}: {lines.size} messages, exit {status}, {(← IO.monoMsNow) - t1} ms -> {logPath}"
    (← IO.getStdout).flush
  return 0
