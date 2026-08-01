/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Bridge.Comprehension
import FerrisHoward.Emit
import FerrisHoward.Lint.Coercion
import FerrisHoward.Bridge.Mathlib
import FerrisHoward.Lint.InstanceShadow
import FerrisHoward.Lint.VarShadow
import FerrisHoward.Lint.Todo
import FerrisHoward.Report.Sorry

/-!
# Ferris–Howard

Rust surface syntax for Lean 4 mathematics, elaborating in-process against Mathlib.
`design.md` is the specification, `corpus-review.md` holds the binding rulings, and
`PLAN.md` sequences the work.

Layout (design §2):

* `FerrisHoward/Syntax/` — parser declarations (the categories and productions);
* `FerrisHoward/Expand/` — stage-one macros (FH surface → Lean surface);
* `FerrisHoward/Emit/` — `emit-lean`, the publication path (ADR-006);
* `FerrisHoward/Lint/` — post-elaboration diagnostics, which are *not* part of the
  translation and can be switched off without changing what FH means;
* `FerrisHoward/Report/` — tooling commands over the elaborated environment;
* `FerrisHoward/Bridge/` — the Mathlib name/notation bridge (M2);
* `FerrisHoward/Test/` — the four-tier harness, imported by fixtures under `Tests/`.

Importing this module reserves FH's keywords as tokens in the importing file — an
accepted, documented platform cost (`differences.md`).
-/
