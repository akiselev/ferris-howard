/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward

/-!
Regression fixture for the Lean-first scientific bridge. These are ordinary Lean
 declarations: the labels add discovery metadata without changing their semantics.
-/

namespace Tests.ResolventBridge

@[resolvent_spec]
def heatSpec : Prop := True

@[resolvent_observable]
def thermocoupleReading : Nat := 0

@[resolvent_property]
theorem heatInvariant : True := by
  trivial

@[resolvent_reification]
theorem heatSpecReificationCandidate : heatSpec := by
  trivial

#fh_resolvent_require_spec
#fh_resolvent_manifest

end Tests.ResolventBridge
