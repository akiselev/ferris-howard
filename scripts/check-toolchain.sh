#!/usr/bin/env bash
# Toolchain-match assertion (PLAN I1, risk R6).
#
# Toolchain bumps are a scheduled milestone-boundary event, never a drive-by: exact-message
# negative tests and pretty-printed goldens both drift across Lean versions. This script
# fails the build if the pin has moved by accident.
#
#   1. our `lean-toolchain` must equal Mathlib's `lean-toolchain`;
#   2. the resolved Mathlib revision in `lake-manifest.json` must equal the `rev` pinned in
#      `lakefile.toml` (a stray `lake update` rewrites the manifest, not the lakefile).
#
# Run from the repository root.
set -euo pipefail

fail=0

ours=$(tr -d '[:space:]' < lean/lean-toolchain)
mathlib_toolchain_file=lean/.lake/packages/mathlib/lean-toolchain
if [ ! -f "$mathlib_toolchain_file" ]; then
  echo "check-toolchain: $mathlib_toolchain_file is missing — run 'lake build' first" >&2
  exit 1
fi
theirs=$(tr -d '[:space:]' < "$mathlib_toolchain_file")

if [ "$ours" != "$theirs" ]; then
  echo "check-toolchain: toolchain mismatch" >&2
  echo "  lean/lean-toolchain: $ours" >&2
  echo "  mathlib:             $theirs" >&2
  fail=1
else
  echo "check-toolchain: toolchain $ours matches Mathlib"
fi

pinned=$(grep -A3 'name = "mathlib"' lean/lakefile.toml | sed -n 's/^rev = "\(.*\)"/\1/p')
resolved=$(python3 - <<'PY'
import json
with open("lean/lake-manifest.json") as f:
    manifest = json.load(f)
for pkg in manifest["packages"]:
    if pkg.get("name") == "mathlib":
        print(pkg.get("inputRev") or "")
        break
PY
)

if [ -z "$pinned" ]; then
  echo "check-toolchain: could not read the mathlib rev from lean/lakefile.toml" >&2
  fail=1
elif [ "$pinned" != "$resolved" ]; then
  echo "check-toolchain: mathlib pin drift" >&2
  echo "  lakefile.toml:      $pinned" >&2
  echo "  lake-manifest.json: $resolved" >&2
  fail=1
else
  echo "check-toolchain: mathlib pinned at $pinned"
fi

exit "$fail"
