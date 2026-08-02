/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Atlas.Statement
import FerrisHoward.Expand.Item

/-!
# Metadata over Mathlib without a fork (B8, atlas.md §6)

Mathlib is upstream and stays untouched: never rewritten, never annotated at source,
overlaid. Two of atlas.md's three channels live here.

**Channel 1 — retroactive attributes.** Lean lets a *downstream* file apply an attribute to
an upstream declaration, so `attribute [fh_role index] Nat.Prime.dvd_mul` in an FH file
attaches our metadata at import time and persists it into *our* olean. Anything importing
FH sees Mathlib-with-metadata; Mathlib sees nothing. This is the channel for metadata
Lean-side elaboration has to see.

**Channel 3 — asserted annotations.** `annotate Nat::Prime::dvd_mul { … }` emits no Lean
code at all, only a metadata row. These are *opinions* about upstream declarations,
versioned like patches against a moving target.

(Channel 2, the computed sidecar, is the Rust store — it needs nothing here, because
derived data is rebuildable and staleness is a performance question rather than a
correctness one.)

## The keying problem is the design

Mathlib changes daily. Names move and statements get strengthened, and those two need
opposite responses.

Every row is keyed by `(Name, statement encoding)`. The encoding is I3's, normalized up to
alpha-equivalence and universe renaming, so it is content addressing: metadata survives a
**rename** (the same statement under a new name rebinds), and a **strengthened statement**
is detected rather than silently reattached.

The asymmetry is deliberate and is the whole discipline. A Channel 3 annotation **hard-fails**
on mismatch pending re-review, because it is an assertion someone made about a statement
that no longer exists. Channel 2 data just recomputes. This is how debug symbols work: the
sidecar is trustworthy exactly because it can tell when the binary underneath it changed.
-/

namespace FerrisHoward.Overlay

open Lean Elab Command

/-- One overlay row: what was said, about which declaration, against which statement. -/
structure Row where
  /-- The declaration this is about. -/
  decl : Name
  /-- The I3 statement encoding at the time the row was written. The staleness check. -/
  stmt : String
  /-- `role` for Channel 1, or the annotation key for Channel 3. -/
  key : String
  value : String
  /-- Channel 1 rows come from an attribute; Channel 3 rows from an `annotate` item, and
  only Channel 3 hard-fails on a stale key. -/
  asserted : Bool
  deriving Inhabited, Repr

/-- The overlay store, persisted into FH's own olean.

A *persistent* extension rather than a scoped one: the point of Channel 1 is that anything
importing FH sees Mathlib-with-metadata, which a scoped extension would not deliver. -/
initialize overlayExt : SimplePersistentEnvExtension Row (Array Row) ←
  registerSimplePersistentEnvExtension {
    addEntryFn := Array.push
    addImportedFn := fun arrays => arrays.foldl (fun acc a => acc ++ a) #[]
  }

/-- The statement encoding of a declaration, or `none` if it cannot be encoded.

An unencodable statement is a row that cannot be keyed, which is a refusal rather than a
row with a blank key: a key that is always equal matches everything. -/
def encodingOf (env : Environment) (n : Name) : Option String :=
  match Atlas.encodeConst env n with
  | .ok s => some s
  | .error _ => none

/-- Record a row, keyed against the declaration's current statement. -/
def record (decl : Name) (key value : String) (asserted : Bool) : CommandElabM Unit := do
  let env ← getEnv
  unless env.contains decl do
    throwError s!"FH overlay: `{decl}` is not in the environment — an overlay row about a \
                  declaration that does not exist cannot be checked against anything"
  let some stmt := encodingOf env decl
    | throwError s!"FH overlay: `{decl}`'s statement cannot be encoded, so a row about it \
                    could never be told from a stale one"
  modifyEnv (overlayExt.addEntry · { decl, stmt, key, value, asserted })

/-- Every overlay row visible here — this module's and every imported module's.
`getState` covers the current module; the imported entries come from the extension's own
import merge, which `addImportedFn` above concatenates. -/
def rows (env : Environment) : Array Row :=
  overlayExt.getState env

/-! ## Channel 1 — the retroactive attribute

`attribute [fh_role index] Nat.Prime.dvd_mul` from a downstream file. Design §4.9's object
roles, which `fh check` reports and the falsification battery steers with.
-/

syntax (name := fhRoleAttr) "fh_role" ident : attr

initialize registerBuiltinAttribute {
  name := `fhRoleAttr
  descr := "an FH object role (design §4.9), attachable to any declaration including \
            upstream ones"
  -- `.global` rather than `.local`: the row has to survive into the olean or Channel 1
  -- delivers nothing.
  applicationTime := .afterCompilation
  add := fun decl stx _ => do
    let `(attr| fh_role $r:ident) := stx
      | throwError "FH: `@[fh_role r]` takes one role name"
    let env ← getEnv
    let some stmt := encodingOf env decl
      | throwError s!"FH overlay: `{decl}`'s statement cannot be encoded"
    modifyEnv (overlayExt.addEntry ·
      { decl, stmt, key := "role", value := toString r.getId, asserted := false })
}

/-! ## Channel 3 — asserted annotations

`annotate Nat::Prime::dvd_mul { shape: certificate_deployment, note: "…" };`

Emits no Lean code. The `#[…]`-free form is deliberate: this is not a modifier on a
declaration, it is a statement *about* one.
-/

/-- One field of an annotation: `key: "value"`. -/
syntax fhAnnotField := ident ": " str

/-- `annotate Nat::Prime::dvd_mul { shape: "…", note: "…" };`

A **command**, not an `fh_item`, and the distinction is not cosmetic. An `fh_item` is part
of the language `emit-lean` must expand; `annotate` emits no Lean code at all, so there is
nothing to expand and nothing for an artifact to carry — an opinion about an upstream
declaration is not part of a publication. It belongs with `#fh_check` and
`#fh_sorry_report` as tooling, which is also why an `elab` here does not stretch ADR-006's
stage-one rule: that rule governs the language, and every FH *tool* command is already an
elaborator.

Recording a row needs the environment — to resolve the path, and to read the statement it
is being keyed against — which stage one deliberately cannot reach. -/
syntax (name := fhAnnotate) "annotate " ident " { " fhAnnotField,*,? " } " ";" : command

elab_rules : command
  | `(annotate $target:ident { $[$keys : $vals],* } ;) => do
    let decl ← liftCoreM <| realizeGlobalConstNoOverload target
    if keys.isEmpty then
      throwErrorAt target "FH: an `annotate` with no fields records nothing"
    for (k, v) in keys.zip vals do
      record decl (toString k.getId) v.getString true

/-! ## Reporting, and the staleness check

The check is the reason the overlay is trustworthy, so it is a command rather than a
library function nobody calls.
-/

/-- A row whose declaration's statement no longer matches the one it was written against. -/
structure Stale where
  row : Row
  /-- `none` when the declaration is gone entirely, which is a different problem. -/
  now : Option String
  /-- A declaration that *does* still have the row's statement. Content addressing's other
  half: a rename moves the name and keeps the statement, so the row can be rebound rather
  than discarded. Present only when exactly one candidate exists — two would be a guess. -/
  rebind : Option Name

/-- Declarations whose statement encodes to exactly this, excluding one name.

The search is over the *local* module's declarations only. Scanning all of Mathlib per
stale row would be minutes, and a rename that crosses into upstream is not something an
overlay can fix by itself. -/
private def withEncoding (env : Environment) (stmt : String) (except : Name) : Array Name :=
  Id.run do
    let mut out := #[]
    for (n, _) in env.constants.map₂.toList do
      if n == except || n.isInternalDetail then continue
      if encodingOf env n == some stmt then out := out.push n
    return out

/-- Every stale row, with what the statement says now and where it may have moved to. -/
def stale (env : Environment) : Array Stale := Id.run do
  let mut out := #[]
  for r in rows env do
    let now := if env.contains r.decl then encodingOf env r.decl else none
    if now != some r.stmt then
      -- Exactly one candidate is a rename; several is a coincidence, and guessing between
      -- them would be the silent reattachment this scheme exists to prevent.
      let candidates := withEncoding env r.stmt r.decl
      let rebind := if candidates.size == 1 then candidates[0]? else none
      out := out.push { row := r, now, rebind }
  return out

/-- `#fh_overlay` — every row visible here. -/
elab "#fh_overlay" : command => do
  let rs := rows (← getEnv)
  if rs.isEmpty then
    logInfo "FH overlay: no rows"
  else
    let lines := rs.toList.map fun r =>
      s!"  {r.decl}  {r.key}={r.value}{if r.asserted then "  (asserted)" else ""}"
    logInfo (s!"FH overlay: {rs.size} row(s)\n" ++ String.intercalate "\n" lines)

/-- `#fh_overlay_check` — report rows whose statement has drifted.

Asserted rows (Channel 3) are an **error**: an opinion about a statement that changed is
not an opinion about the current statement, and reattaching it silently is exactly the
failure this keying scheme exists to prevent. Derived rows are a warning, because Channel
2 recomputes. -/
elab "#fh_overlay_check" : command => do
  let bad := stale (← getEnv)
  if bad.isEmpty then
    logInfo s!"FH overlay: all {(rows (← getEnv)).size} row(s) still match their statements"
  else
    for s in bad do
      let what := match s.now with
        | none => "the declaration is gone"
        | some _ => "the statement changed"
      let where_ := match s.rebind with
        | some n => s!" The same statement is now `{n}`, so this looks like a rename."
        | none => ""
      let msg := s!"FH overlay: `{s.row.decl}`'s row `{s.row.key}={s.row.value}` is stale — \
                    {what}.{where_} Re-review it; it will not be reattached silently."
      if s.row.asserted then logError msg else logWarning msg

end FerrisHoward.Overlay
