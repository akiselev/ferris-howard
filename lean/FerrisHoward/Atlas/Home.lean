/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FhAtlas.Home

/-!
# Re-export shim — the module moved to `atlas-extract/FhAtlas/Home.lean`

`#fh_home` / `#fh_home_confirm` / `#fh_home_refute` / `#fh_home_attempt` now live in the
shared package, because the physics workspace is pinned to a different toolchain and can
only reach them through a path dependency (physlib-hypothesis-min.md §8.1 named this move
the hard blocker for the 18-sorry kernel probes). Imports are transitive, so every
existing `import FerrisHoward.Atlas.Home` — the test tier, the generated probe shards,
`fh_batch --import` — keeps working through this file unchanged.
-/
