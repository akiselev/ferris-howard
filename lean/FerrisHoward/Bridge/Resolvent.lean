/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean.Elab.Command
import FerrisHoward.Bridge.ResolventAttrs

/-!
# Ferris–Howard / Resolvent bridge

Ferris–Howard does not export its surface AST to Resolvent. This module only discovers
**ordinary Lean declarations** that have already survived FH expansion/elaboration and were
explicitly labelled for the scientific stack.

The labels have deliberately weak semantics:

* `@[resolvent_spec]` — candidate scientific specification declaration;
* `@[resolvent_observable]` — candidate observable / measurement-model declaration;
* `@[resolvent_property]` — candidate theorem/property for generated validation;
* `@[resolvent_reification]` — candidate theorem/certificate connecting a declaration to a
  Resolvent deep-IR artifact.

In particular, tagging a theorem with `@[resolvent_reification]` **does not** make an export
`KernelProved`. The external exporter/verification step must still freeze the source
statement, audit axioms, identify the exact reified artifact, and name a theorem whose type
actually proves the required semantic relation. This module is discovery metadata, not a
trusted compiler.
-/

namespace FerrisHoward.ResolventBridge

open Lean Elab Command

/-- The four declaration sets visible to the Resolvent exporter in the current environment. -/
structure Manifest where
  specs : NameSet
  observables : NameSet
  properties : NameSet
  reifications : NameSet
  deriving Inhabited

/-- Read bridge labels from the elaborated Lean environment. `NameSet` is an ordered set, so
iterating the result gives deterministic output without depending on registration order. -/
def getManifest : CoreM Manifest := do
  return {
    specs := ← Lean.labelled `resolvent_spec
    observables := ← Lean.labelled `resolvent_observable
    properties := ← Lean.labelled `resolvent_property
    reifications := ← Lean.labelled `resolvent_reification
  }

private def emitRows (kind : String) (names : NameSet) : CommandElabM Unit := do
  for name in names do
    -- Stable tab-separated protocol intended to be trivial to ingest without parsing Lean
    -- pretty-printer output. The declaration name is environment-resolved; surface FH
    -- syntax and source spelling never enter the semantic payload.
    logInfo m!"FH_RESOLVENT\tv1\t{kind}\t{name}"

/-- Emit a deterministic, machine-readable inventory of Lean declarations selected for
Resolvent integration. This is a discovery manifest only; it makes no proof-strength claim.

Output rows are:

`FH_RESOLVENT<TAB>v1<TAB><kind><TAB><fully-qualified-name>`
-/
elab "#fh_resolvent_manifest" : command => do
  let manifest ← liftCoreM getManifest
  emitRows "spec" manifest.specs
  emitRows "observable" manifest.observables
  emitRows "property" manifest.properties
  emitRows "reification" manifest.reifications

/-- Fail when no scientific specification declarations are labelled in the environment.
Useful as a campaign/CI guard before attempting a Resolvent export. -/
elab "#fh_resolvent_require_spec" : command => do
  let manifest ← liftCoreM getManifest
  if manifest.specs.isEmpty then
    throwError "FH/Resolvent: no declarations are labelled `@[resolvent_spec]`"

end FerrisHoward.ResolventBridge
