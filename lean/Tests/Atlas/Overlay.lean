/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Overlay

/-!
# Metadata over Mathlib without a fork (B8, atlas.md §6)

Mathlib is upstream and stays untouched. Two of the three channels are here; the third,
the computed sidecar, is the Rust store and needs nothing in Lean because derived data is
rebuildable by construction.

* **Stage: not applicable.** These are tooling commands, like `#fh_check` — not language
  constructs, so `emit-lean` has nothing to expand and an artifact carries none of it.
* **Sorry count: zero.**

## The keying is the design

Every row is keyed by `(Name, statement encoding)`. That is content addressing, and it
gives the two behaviours a moving upstream needs, which are opposites:

* a **rename** moves the name and keeps the statement, so the row can be rebound;
* a **strengthened statement** keeps the name and changes the statement, so the row is
  stale and must not be reattached.

And the asymmetry between channels: an *asserted* row is an opinion someone recorded about
a statement, so a mismatch is an **error** pending re-review. A *derived* row just
recomputes, so a mismatch is a warning. This is the debug-symbols discipline — the sidecar
is trustworthy exactly because it can tell when the binary underneath it changed.
-/

open Lean Elab Command FerrisHoward.Overlay

/-! ## The two channels

Channel 1 is an attribute, so it can be applied to a declaration from *downstream* — which
is the whole point, since Mathlib is never edited. Channel 3 emits no Lean code at all.
-/

theorem upstream_lemma (n : Nat) : n + 0 = n := Nat.add_zero n

attribute [fh_role index] upstream_lemma

annotate upstream_lemma { shape: "certificate_deployment", note: "Bezout through by b" };

/-! Both channels land in one store, and an asserted row is marked as one. -/

/--
info: FH overlay: 3 row(s)
  upstream_lemma  role=index
  upstream_lemma  shape=certificate_deployment  (asserted)
  upstream_lemma  note=Bezout through by b  (asserted)
-/
#guard_msgs (whitespace := lax) in
#fh_overlay

/-- info: FH overlay: all 3 row(s) still match their statements -/
#guard_msgs in
#fh_overlay_check

/-! ## The staleness check

A row written against a statement that no longer exists. Both kinds are constructed
directly rather than by editing a declaration, because the thing under test is the
*response* to drift and there is no way to strengthen a lemma mid-file.
-/

theorem drifted (n : Nat) : n * 1 = n := Nat.mul_one n

run_cmd do
  modifyEnv (overlayExt.addEntry ·
    { decl := `drifted, stmt := "fh-stmt-v1;c(3:Nat,0)", key := "note",
      value := "an opinion about a statement that changed", asserted := true })

run_cmd do
  modifyEnv (overlayExt.addEntry ·
    { decl := `drifted, stmt := "fh-stmt-v1;c(3:Nat,0)", key := "role",
      value := "derived", asserted := false })

/-! Asserted drift is an error; derived drift is a warning. The two channels differ in
exactly this, and it is the only place they differ. -/

/--
error: FH overlay: `drifted`'s row `note=an opinion about a statement that changed` is stale — the statement changed. Re-review it; it will not be reattached silently.
---
warning: FH overlay: `drifted`'s row `role=derived` is stale — the statement changed. Re-review it; it will not be reattached silently.
-/
#guard_msgs in
#fh_overlay_check

/-! ## Rename survival

A row whose *name* is gone but whose statement is present under another name. Content
addressing's other half: the row is not discarded, it is offered a rebind — and still not
reattached silently, because "looks like a rename" is a judgement a reader makes.
-/

theorem renamed_to (n : Nat) : n + 0 + 0 = n := by simp

run_cmd do
  let env ← getEnv
  let some enc := encodingOf env `renamed_to | throwError "no encoding"
  modifyEnv (overlayExt.addEntry ·
    { decl := `gone_name, stmt := enc, key := "note", value := "written before the rename",
      asserted := true })

/--
error: FH overlay: `drifted`'s row `note=an opinion about a statement that changed` is stale — the statement changed. Re-review it; it will not be reattached silently.
---
warning: FH overlay: `drifted`'s row `role=derived` is stale — the statement changed. Re-review it; it will not be reattached silently.
---
error: FH overlay: `gone_name`'s row `note=written before the rename` is stale — the declaration is gone. The same statement is now `renamed_to`, so this looks like a rename. Re-review it; it will not be reattached silently.
-/
#guard_msgs in
#fh_overlay_check

/-! ## Negative

A row about a declaration that does not exist cannot be checked against anything, so it is
refused rather than stored.
-/

/--
error: FH overlay: `No.Such.Decl` is not in the environment — an overlay row about a declaration that does not exist cannot be checked against anything
-/
#guard_msgs in
run_cmd record `No.Such.Decl "note" "about nothing" true

/-! And an annotation with no fields records nothing, which is a typo rather than an
intention. -/

/-- error: FH: an `annotate` with no fields records nothing -/
#guard_msgs in
annotate upstream_lemma { };
