#!/usr/bin/env python3
"""The `emit-lean` round-trip gate (ADR-006 / `research/codegen.md` §2).

For each FH source below:

1. emit publication-grade Lean with `fh_emit` (which fails if any FH construct does not
   expand — the emittable lint);
2. check the artifact carries no FH dependency, by inspection;
3. elaborate it from scratch;
4. compare it to the FH original **declaration by declaration**, using the I3 canonical
   statement encoding: same names, same kinds, byte-identical statements.

Step 4 is the guarantee. It is not "the emitted file compiles" — it is "the emitted file
states exactly what we proved", which is what lets FH drop out of the trusted base. What
it does not yet do is compare *proof terms* or run `lean4checker` on the artifact alone;
both are named in ADR-006 and neither is implemented here.

Run from the repository root:  python3 scripts/round-trip.py
"""

from __future__ import annotations

import json
import pathlib
import subprocess
import sys

LEAN = pathlib.Path("lean")
EMITTED_DIR = LEAN / "Tests" / "Emitted"

# (FH source module, emitted module) — add a row per publishable fixture.
CASES = [
    ("Tests.corpus.g01_peano", "Tests.Emitted.G01Peano"),
    # Group 12 uses `use lean::Dvd;` and `use lean::Subtype;`. It is here because the
    # `use`-bearing case is the one that catches a bridge `open` leaking into the artifact
    # — which it did, until 2026-08-01. A gate with only bridge-free cases cannot see it.
    ("Tests.corpus.g12_gcd", "Tests.Emitted.G12Gcd"),
]


def run(args: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(args, cwd=LEAN, capture_output=True, text=True, **kw)


def module_path(module: str) -> pathlib.Path:
    return LEAN / (module.replace(".", "/") + ".lean")


def rows(module: str) -> dict[str, dict]:
    """Statement rows for a module, keyed by declaration name.

    Note the cost: `atlas_extract --local` still `importModules` the whole closure, so a
    Mathlib-importing fixture costs ~9 GB and minutes *per call* — the `--local` flag
    filters the output, not the import. Two cases here means four such calls. Worth
    knowing before adding a third.
    """
    proc = run(["lake", "exe", "atlas_extract", "--local", module])
    if proc.returncode != 0:
        sys.exit(f"round-trip: extraction failed for {module}\n{proc.stderr}")
    out = {}
    for line in proc.stdout.splitlines():
        if not line.startswith("{"):
            continue
        row = json.loads(line)
        out[row["name"]] = row
    return out


def main() -> int:
    EMITTED_DIR.mkdir(parents=True, exist_ok=True)
    failures = 0

    for src_module, emitted_module in CASES:
        src = module_path(src_module)
        dst = module_path(emitted_module)
        print(f"round-trip: {src_module} → {emitted_module}")

        # 1. emit
        proc = run(["lake", "exe", "fh_emit", str(src.relative_to(LEAN))])
        if proc.returncode != 0:
            print(f"  emit failed:\n{proc.stderr}")
            failures += 1
            continue
        dst.write_text(proc.stdout)
        if proc.stderr.strip():
            print(f"  {proc.stderr.strip()}")

        # 2. no FH dependency, by inspection
        if "FerrisHoward" in proc.stdout:
            print("  artifact mentions FerrisHoward — it is not FH-free")
            failures += 1
            continue

        # 3. it elaborates
        build = run(["lake", "build", emitted_module])
        if build.returncode != 0:
            print(f"  emitted artifact does not elaborate:\n{build.stdout}\n{build.stderr}")
            failures += 1
            continue

        # 4. same statements, declaration by declaration
        before, after = rows(src_module), rows(emitted_module)
        dropped_incomplete = []
        for name, row in before.items():
            other = after.get(name)
            if other is None:
                # A declaration that carries `sorryAx` is not publishable material, and a
                # negative fixture's contents only exist at all because Lean recovers from
                # the error by inserting one. Omitting those is correct; omitting a
                # *complete* declaration never is.
                #
                # `opaque` is the second recovery shape, and it is not reachable from the
                # first. A definition whose termination proof fails is added as an **opaque
                # constant** — `kind: "opaque"`, `uses_proof: []` — so it cites `sorryAx`
                # neither directly nor transitively, and a deeper sorry scan would not find
                # it either. Measured on `Tests.corpus.g12_gcd`, whose `gcd_nodec` is a
                # Tier-3 negative fixture asserting exactly that failure. A constant with no
                # body is not something an artifact can be expected to contain.
                if "sorryAx" in row.get("uses_proof", []) or row.get("kind") == "opaque":
                    dropped_incomplete.append(name)
                else:
                    print(f"  missing from the artifact: {name}")
                    failures += 1
            elif other.get("stmt") != row.get("stmt"):
                print(f"  statement changed: {name}")
                print(f"    FH:      {row.get('stmt')}")
                print(f"    emitted: {other.get('stmt')}")
                failures += 1
            elif other.get("kind") != row.get("kind"):
                print(f"  kind changed: {name}: {row['kind']} → {other['kind']}")
                failures += 1
        extra = set(after) - set(before)
        if extra:
            print(f"  artifact declares names the source does not: {sorted(extra)}")
            failures += 1
        if dropped_incomplete:
            print(f"  omitted as incomplete (depend on sorryAx): {sorted(dropped_incomplete)}")
        if failures == 0:
            kept = len(before) - len(dropped_incomplete)
            print(f"  {kept} declarations, statements identical")

    if failures:
        print(f"round-trip: {failures} failure(s)")
        return 1
    print("round-trip: green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
