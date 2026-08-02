/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Atlas.Statement

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

/-- Extract one declaration. -/
def rowOf (env : Environment) (n : Name) (info : ConstantInfo) : Row :=
  let (stmt, stmtError) :=
    match encodeType info.type with
    | .ok s => (some s, none)
    | .error e => (none, some e)
  { name := n
    kind := kindOf info
    module := (env.getModuleIdxFor? n).bind (env.header.moduleNames[·.toNat]?) |>.getD env.mainModule
    stmt, stmtError
    usesStatement := sortedConstants info.type
    usesProof := ((valueOf? info).map sortedConstants).getD #[] }

/-- Extract every extractable declaration of the *current module*, in name order. Used by
`#fh_extract`, where "current module" is the file being elaborated. -/
def localRows (env : Environment) : Array Row := Id.run do
  let mut names := #[]
  for (n, _) in env.constants.map₂.toList do
    if isExtractable n then names := names.push n
  let sorted := names.qsort (fun a b => a.toString < b.toString)
  return sorted.filterMap fun n => (env.find? n).map (rowOf env n)

/-- Extract every extractable declaration in the environment, in name order. This is the
whole-Mathlib pass; `localRows` is the per-file one the fixtures use. -/
def allRows (env : Environment) : Array Row := Id.run do
  let mut names := #[]
  for (n, _) in env.constants.toList do
    if isExtractable n then names := names.push n
  let sorted := names.qsort (fun a b => a.toString < b.toString)
  return sorted.filterMap fun n => (env.find? n).map (rowOf env n)

/-- Extract the declarations belonging to one named module of the import closure. This is
the extractor program's `--local` form: after `importModules` everything lives in the
imported map, so "just this module" is a filter rather than a different traversal. -/
def moduleRows (env : Environment) (m : Name) : Array Row :=
  (allRows env).filter (·.module == m)

end FerrisHoward.Atlas

namespace FerrisHoward
open Lean Elab Command

/-- Emit the extractor's JSONL rows for the declarations of the current module. -/
elab "#fh_extract" : command => do
  for row in Atlas.localRows (← getEnv) do
    logInfo row.toJson.compress

end FerrisHoward
