/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean.LabelAttribute

/-!
# Resolvent bridge labels

These are deliberately *labels*, not elaborators and not proof-producing magic. They mark
ordinary, already-elaborated Lean declarations as candidates for the scientific refinement
bridge. The declaration itself remains the semantic authority and the Lean kernel remains
the proof authority.

Lean label attributes are split into this module because a user attribute cannot be used in
the same module that registers it. `FerrisHoward.Bridge.Resolvent` imports these labels and
provides the manifest/reporting commands.
-/

register_label_attr resolvent_spec
  "kernel-visible declaration intended to be reified as a Resolvent ScientificSpec"
register_label_attr resolvent_observable
  "declaration describing a mathematical observable or measurement model for Resolvent"
register_label_attr resolvent_property
  "proved/asserted property intended to become a Resolvent validation contract"
register_label_attr resolvent_reification
  "candidate theorem/certificate declaration connecting Lean semantics to a Resolvent artifact"
