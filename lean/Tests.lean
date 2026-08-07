/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

/-!
# Fixtures

This module is deliberately **empty of imports**.

The lakefile globs `Tests.+`, so every fixture is built whether or not anything imports
it — coverage is structural. Pulling them all into one environment here would add a
constraint the suite does not want: two fixtures could not both declare an `enum N`, and
`Tests/M0/Items.lean` and `Tests/M1/Theorem.lean` both do, because each is written to read
like the corpus rather than to avoid its neighbours.

Fixture layout:

* `Tests/M0/` — the skeleton milestone (A0.1–A0.6);
* `Tests/M1/` — statements (A1.x);
* `Tests/Atlas/` — Track B (I3's encoding, B1's extractor);
* `Tests/Smoke.lean` — the Mathlib anchors from the scaffolding round.

Archived feasibility spikes live in `lean/spikes/`, outside this lib: several fail on
purpose. Run them by hand with `lake env lean spikes/<file>.lean`.
-/
