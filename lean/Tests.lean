import Tests.Atlas
import Tests.Smoke
import Tests.M0

/-!
# Fixture index

Every fixture is reachable from here. The lakefile also globs the fixture directories, so
a file missing from an index still gets compiled — the indices are for readability, the
globs are the coverage guarantee (which is why this package needs no `mk_all --check`).

Archived feasibility spikes live in `lean/spikes/`, outside this lib: several fail on
purpose. Run them by hand with `lake env lean spikes/<file>.lean`.
-/
