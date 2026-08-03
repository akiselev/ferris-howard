/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FhAtlas.Statement

/-!
# The extractor (B1)

One pass over an elaborated environment, emitting a JSONL row per declaration:
name, kind, module, the canonical statement encoding (I3), and the constants it uses.
That is `atlas.md` §6's Channel 2 in its first form — enough for the dependency graph
(B2) and for the keying scheme (B8), and deliberately short of a whole-`Expr` dump, which
only the skeleton index (B4) needs.

Two used-constant lists, not one. `uses_statement` is what the *claim* rests on and
`uses_proof` is what the *argument* rests on; conflating them would blur exactly the
distinction `atlas why` and the foundations/impact queries are about. Both are sorted, and
rows are emitted in name order, so a diff between two extractions is readable.

Declarations whose statement cannot be encoded (a metavariable, `sorryAx` in the type)
carry `stmt_error` instead of `stmt` rather than being dropped: an extractor that silently
omits rows is indistinguishable from one that missed them.
-/

namespace FerrisHoward.Atlas
open Lean

/-- One extracted declaration. -/
structure Row where
  /-- The declaration's name. -/
  name : Name
  /-- `theorem`, `def`, `axiom`, `inductive`, `constructor`, `recursor`, `opaque`, `quot`. -/
  kind : String
  /-- The module it was declared in. -/
  module : Name
  /-- The canonical statement encoding (I3), if it could be produced. -/
  stmt : Option String
  /-- Why the statement could not be encoded, if it could not. -/
  stmtError : Option String
  /-- Constants appearing in the statement. -/
  usesStatement : Array Name
  /-- Constants appearing in the proof or definition body. -/
  usesProof : Array Name
  deriving Inhabited

/-- The declaration kind, as a stable string. -/
def kindOf : ConstantInfo → String
  | .axiomInfo _ => "axiom"
  | .defnInfo _ => "def"
  | .thmInfo _ => "theorem"
  | .opaqueInfo _ => "opaque"
  | .quotInfo _ => "quot"
  | .inductInfo _ => "inductive"
  | .ctorInfo _ => "constructor"
  | .recInfo _ => "recursor"

/-- JSON for one row. Field order is fixed so that two extractions diff cleanly. -/
def Row.toJson (r : Row) : Json :=
  Json.mkObj <|
    [("name", toString r.name), ("kind", r.kind), ("module", toString r.module)].map
      (fun (k, v) => (k, Json.str v))
    ++ (match r.stmt with | some s => [("stmt", Json.str s)] | none => [])
    ++ (match r.stmtError with | some e => [("stmt_error", Json.str e)] | none => [])
    ++ [("uses_statement", Json.arr (r.usesStatement.map (Json.str <| toString ·))),
        ("uses_proof", Json.arr (r.usesProof.map (Json.str <| toString ·)))]

/-- Should this constant be extracted? Internal details — matcher equations, `_example`,
closed-term lifts — are noise for every downstream consumer. -/
def isExtractable (n : Name) : Bool :=
  !n.isInternalDetail

/-- Used constants, sorted by their printed form. `Name.lt` is deterministic but orders by
prefix depth, which reads as unsorted in a JSONL row; consumers and humans both want the
lexicographic order of the strings they actually see. -/
private def sortedConstants (e : Expr) : Array Name :=
  e.getUsedConstants.qsort (fun a b => a.toString < b.toString)

/-- The value a declaration was defined by, if it has one.

**Not `ConstantInfo.value?`**, which returns `none` for a theorem on this toolchain — Lean
does not hand out proof terms through that accessor. Using it made `uses_proof` empty for
every theorem in the environment, which is exactly backwards: a theorem's proof is where
the interesting dependencies are, and `atlas why --lens proof` is the query they exist for.
Found by B2, whose first real run over `Mathlib.Logic.Basic` reported 33,521 theorems and
not one proof edge.

`opaqueInfo` is deliberately excluded. An `opaque` declaration's whole content is that
nothing may look at its value, and the Atlas should not be the thing that does. -/
private def valueOf? : ConstantInfo → Option Expr
  | .defnInfo v => some v.value
  | .thmInfo v => some v.value
  | _ => none

/-- The module a declaration was compiled in. Absent from the module index means the
current file, which is the `#fh_extract` case. -/
def moduleOf (env : Environment) (n : Name) : Name :=
  (env.getModuleIdxFor? n).bind (env.header.moduleNames[·.toNat]?) |>.getD env.mainModule

/-- Extract one declaration. -/
def rowOf (env : Environment) (n : Name) (info : ConstantInfo) : Row :=
  let (stmt, stmtError) :=
    match encodeType info.type with
    | .ok s => (some s, none)
    | .error e => (none, some e)
  { name := n
    kind := kindOf info
    module := moduleOf env n
    stmt, stmtError
    usesStatement := sortedConstants info.type
    usesProof := ((valueOf? info).map sortedConstants).getD #[] }

/-- Sort names by their printed form, computing each string **once**.

`qsort (fun a b => a.toString < b.toString)` calls `Name.toString` inside the comparator, so
it allocates a fresh string on every one of the O(n log n) comparisons rather than O(n)
times. On a whole-library extraction that is the dominant cost and it looks exactly like a
hang: the process sits at 100% CPU with a flat resident set, because it is allocating and
freeing short-lived strings instead of building rows. Decorate–sort–undecorate instead. -/
def sortedByString (names : Array Name) : Array Name :=
  let decorated := names.map fun n => (n.toString, n)
  (decorated.qsort (fun a b => a.1 < b.1)).map (·.2)

/-- Extract every extractable declaration of the *current module*, in name order. Used by
`#fh_extract`, where "current module" is the file being elaborated. -/
def localRows (env : Environment) : Array Row := Id.run do
  let mut names := #[]
  for (n, _) in env.constants.map₂.toList do
    if isExtractable n then names := names.push n
  return (sortedByString names).filterMap fun n => (env.find? n).map (rowOf env n)

/-- Extract every extractable declaration in the environment, in name order. This is the
whole-Mathlib pass; `localRows` is the per-file one the fixtures use. -/
def allRows (env : Environment) : Array Row := Id.run do
  let mut names := #[]
  for (n, _) in env.constants.toList do
    if isExtractable n then names := names.push n
  return (sortedByString names).filterMap fun n => (env.find? n).map (rowOf env n)

/-- Extract the declarations belonging to any of the named modules of the import closure,
in name order.

The module test runs **before** `rowOf`, and that is the whole point. The previous spelling
filtered `allRows`, so asking for one file's declarations encoded every statement in the
closure and discarded all but a handful — a `--local` on a Mathlib-importing module cost a
full Mathlib extraction, which is tens of minutes. Importing the closure still costs what
it costs; only the encoding is now proportional to what was asked for.

Split from the encoding so a caller can time the two separately. They have completely
different cost models — selection is linear in the *imported environment*, encoding is
linear in what was *selected* — and when an extraction sits at 100% CPU for twenty minutes,
which of the two is running is the whole diagnosis. -/
def selectNames (env : Environment) (ms : Array Name) : Array Name := Id.run do
  -- Iterate the **modules asked for**, not every constant in the environment.
  --
  -- The obvious spelling walks `env.constants` and asks `moduleOf` per declaration. That
  -- is linear in the closure rather than in the request, and the closure here is 818,835
  -- constants — physlib pulls Mathlib, Batteries, Qq, Aesop, ProofWidgets and doc-gen4.
  -- Measured: **30 minutes and still running**, against an 8.3 s import. The environment
  -- walk, not the import and not the encoding, was the whole cost.
  --
  -- Lean already stores the inverse relation. `moduleData[i].constNames` is exactly the
  -- declarations compiled in module `i`, so selecting 608 modules touches only their own
  -- names and never the 810k belonging to something else.
  let wanted : NameSet := ms.foldl (·.insert ·) {}
  let mut names := #[]
  for i in [0 : env.header.moduleNames.size] do
    if wanted.contains env.header.moduleNames[i]! then
      for n in env.header.moduleData[i]!.constNames do
        if isExtractable n then names := names.push n
  -- Declarations elaborated in *this* process rather than loaded from an olean carry no
  -- module index. `atlas_extract` imports everything, so this is empty for it, but
  -- `#fh_extract` runs inside a file being elaborated and its declarations live only here.
  if wanted.contains env.mainModule then
    for (n, _) in env.constants.map₂.toList do
      if isExtractable n then names := names.push n
  return sortedByString names

/-- Encode a chosen set of names. -/
def rowsOfNames (env : Environment) (names : Array Name) : Array Row :=
  names.filterMap fun n => (env.find? n).map (rowOf env n)

/-- Extract the declarations belonging to any of the named modules. -/
def modulesRows (env : Environment) (ms : Array Name) : Array Row :=
  rowsOfNames env (selectNames env ms)

/-- Extract the declarations belonging to one named module of the import closure. -/
def moduleRows (env : Environment) (m : Name) : Array Row :=
  modulesRows env #[m]

end FerrisHoward.Atlas

namespace FerrisHoward
open Lean Elab Command

/-- Emit the extractor's JSONL rows for the declarations of the current module. -/
elab "#fh_extract" : command => do
  for row in Atlas.localRows (← getEnv) do
    logInfo row.toJson.compress

end FerrisHoward
