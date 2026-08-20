/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Validation.Clusters
import Validation.Extra

/-!
# B7 validation clusters

The root module. `Validation.+` does not include `Validation`, and without a root Lake does
not treat the library as a workspace module at all — it reports "some modules have bad
imports" and fails the build while still producing the oleans, which is how this went
unnoticed for a run. The same note is on `FerrisHoward` in the lakefile for the same reason.
-/
