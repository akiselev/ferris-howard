/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item

/-!
# Ferris–Howard

Rust surface syntax for Lean 4 mathematics, elaborating in-process against Mathlib.
`design.md` is the specification, `corpus-review.md` holds the binding rulings, and
`PLAN.md` sequences the work.

Layout (design §2):

* `FerrisHoward/Syntax/` — parser declarations (the categories and productions);
* `FerrisHoward/Expand/` — stage-one macros (FH surface → Lean surface);
* `FerrisHoward/Elab/` — stage-two elaborators (none yet; each one must be justified);
* `FerrisHoward/Bridge/` — the Mathlib name/notation bridge (M2);
* `FerrisHoward/Test/` — the four-tier harness, imported by fixtures under `Tests/`.

Importing this module reserves FH's keywords as tokens in the importing file — an
accepted, documented platform cost (`differences.md`).
-/
