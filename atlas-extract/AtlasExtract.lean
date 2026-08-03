/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FhAtlas.Extract

/-!
# `atlas_extract` — the B1 extractor as a program

```
lake exe atlas_extract Mathlib.Data.Nat.Prime.Basic > rows.jsonl
lake exe atlas_extract --local Tests.M0.Fn          # only that module's own declarations
```

Imports the named modules and writes one JSONL row per declaration to stdout. Whole-Mathlib
runs are the point (`lake exe atlas_extract Mathlib`), but they take as long as importing
Mathlib does, so the `--local` form exists for looking at one module in isolation.

Rows are in name order and their fields are in a fixed order, so two extractions diff.
-/

open Lean FerrisHoward.Atlas

def usage : String :=
  "usage: atlas_extract [--local] <module>...\n\
   \n\
   Writes one JSONL row per declaration to stdout: name, kind, module, canonical\n\
   statement encoding (statement-hash.md), and used constants.\n\
   \n\
     --local   only declarations of the modules named, not of their imports"

def main (args : List String) : IO UInt32 := do
  let localOnly := args.contains "--local"
  let moduleArgs := args.filter (!·.startsWith "--")
  if moduleArgs.isEmpty then
    IO.eprintln usage
    return 1
  let imports := moduleArgs.toArray.map fun m => ({ module := m.toName } : Import)
  initSearchPath (← findSysroot)
  -- Phase timings on stderr. An extraction that sits at 100% CPU for twenty minutes is
  -- indistinguishable from a hung one without them, and the two phases below have entirely
  -- different cost models: selection is linear in the imported environment, encoding is
  -- linear in what was selected. Diagnosing this by guessing cost three rebuild cycles.
  let t0 ← IO.monoMsNow
  let env ← importModules imports {}
  let t1 ← IO.monoMsNow
  IO.eprintln s!"[import] {env.constants.toList.length} constants in {t1 - t0} ms"
  let rows ←
    if localOnly then do
      let names := selectNames env (moduleArgs.toArray.map (·.toName))
      let t2 ← IO.monoMsNow
      IO.eprintln s!"[select] {names.size} selected in {t2 - t1} ms"
      let rs := rowsOfNames env names
      let t3 ← IO.monoMsNow
      IO.eprintln s!"[encode] {rs.size} rows in {t3 - t2} ms"
      pure rs
    else do
      let rs := allRows env
      let t2 ← IO.monoMsNow
      IO.eprintln s!"[encode-all] {rs.size} rows in {t2 - t1} ms"
      pure rs
  let out ← IO.getStdout
  -- Flushed periodically rather than at exit. A full-Mathlib extraction takes tens of
  -- minutes, and with the default buffering its output file reads zero bytes throughout —
  -- which is indistinguishable from a hung process, and was diagnosed as one.
  let mut written := 0
  for row in rows do
    out.putStrLn row.toJson.compress
    written := written + 1
    if written % 1000 == 0 then out.flush
  out.flush
  return 0
