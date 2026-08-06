#!/usr/bin/env python3
"""The work-budget prefilter gate, paired (physlib-prefilter.md §10 S1, findings §66).

One arm per invocation, because a conclusion-anchored index of the 95,268-row physics
corpus is ~7.4 GB resident and the two arms must not share a process:

    uv run scripts/phys-budget-check.py --arm off   # shipped cutoff: expects 0/4
    uv run scripts/phys-budget-check.py --arm on    # work budget:    expects 4/4

The ground truth is the four pre-registered classical<->quantum information
correspondences (physlib-classical-quantum.md §2a), found by exhaustive anti-unification
at conclusion-anchored retention 0.697-0.889 and returned by the shipped `dictionary` not
at all — none is even a candidate. §10 S1's gate is paired and must be able to fail in
both directions: the budget arm must return them AND the cutoff arm must not, else the
test passes when the ranking is broken as readily as when the repair works. The
negative-control pair rides along because a knob that only widens is a volume knob: the
nonsense dictionaries must not gain rows faster than the real one.

Exits non-zero when the invoked arm misses its expectation. Every number printed is
measured in this process; nothing is quoted from the study.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
import time

try:
    import fh_atlas as fa
except ImportError:  # pragma: no cover - the script is useless without it
    sys.exit("fh_atlas is not importable — run under `uv run`")

# Module roots must be stripped (each physics subfield its own theory) or
# `dictionary("ClassicalInfo", ...)` returns an empty result with no error —
# `scripts/phys-prefilter.py prepare_base` writes this file from /tmp/pc-physclosed.jsonl.
BASE = pathlib.Path("/tmp/pfx-base.jsonl")

# The doc's reference point. Fitted on two corpora and deliberately not a shipped
# default; this script measures at it, it does not recommend it.
W = 2_000

TRUE_ROWS = [
    ("Hₛ_nonneg", "Sᵥₙ_nonneg", "E16"),
    ("Hₛ_constant_eq_zero", "Sᵥₙ_of_pure_zero", "E16/E20"),
    ("H₁_nonneg", "Sᵥₙ_nonneg", "E16"),
    ("Hₛ_le_log_d", "Sᵥₙ_le_log_d", "E16"),
]

# The real dictionary, then the pre-registered negative controls: physics against the
# library's HTML-note utility, a pair between which no correspondence can exist.
PAIRS = [
    ("ClassicalInfo", "Entropy"),
    ("ClassicalMechanics", "Meta"),
    ("Thermodynamics", "Meta"),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--arm", choices=["on", "off"], required=True)
    ap.add_argument("--slice", type=pathlib.Path, default=BASE)
    ap.add_argument("--budget", type=int, default=W)
    args = ap.parse_args()

    if not args.slice.exists():
        # A skipped gate says so; a green one that measured nothing would not.
        print(f"SKIPPED: no corpus at {args.slice}")
        return 0

    budget = args.budget if args.arm == "on" else None
    rec: dict = {"arm": args.arm, "posting_work_budget": budget, "slice": str(args.slice)}

    t = time.time()
    c = fa.Corpus.load(args.slice)
    rec["declarations"] = len(c)
    rec["load_s"] = round(time.time() - t, 1)

    # Proposed and above floors — membership of `similar` at the shipped floors, which is
    # score-free and therefore the primary number (prefilter §2a).
    t = time.time()
    proposed = {}
    hits = 0
    for left, right, ev in TRUE_ROWS:
        row: dict = {"E": ev}
        ns = c.similar(
            left,
            top=10**7,
            level="carriers",
            anchor="conclusion",
            min_retention=0.30,
            min_common=6,
            posting_work_budget=budget,
        )
        row["n_above_floors"] = len(ns)
        hit = next(((i + 1, n) for i, n in enumerate(ns) if n.name == right), None)
        row["found"] = hit is not None
        if hit:
            hits += 1
            row["rank"] = hit[0]
            row["retention"] = round(hit[1].retention, 4)
        proposed[f"{left} ~ {right}"] = row
    rec["proposed_above_floors"] = proposed
    rec["proposed_total"] = f"{hits} / {len(TRUE_ROWS)}"
    rec["proposed_s"] = round(time.time() - t, 1)

    # The shipped surface, and the precision control beside it.
    dicts = {}
    dict_hits: set[str] = set()
    for left, right in PAIRS:
        entry = {}
        for per_decl in (1, 10) if left == "ClassicalInfo" else (1,):
            d = c.dictionary(
                left,
                right,
                per_decl=per_decl,
                theorems_only=True,
                anchor="conclusion",
                posting_work_budget=budget,
            )
            found = [
                f"{r.left} ~ {r.right}"
                for r in d.rows
                if any(r.left == a and r.right == b for a, b, _ in TRUE_ROWS)
            ]
            if left == "ClassicalInfo":
                dict_hits.update(found)
            entry[f"per_decl={per_decl}"] = {"rows": len(d.rows), "pre_registered": found}
        dicts[f"{left} ~ {right}"] = entry
    rec["dictionaries"] = dicts
    rec["dictionary_total"] = f"{len(dict_hits)} / {len(TRUE_ROWS)}"

    print(json.dumps(rec, ensure_ascii=False, indent=2))

    # The paired verdict. `on` must find all four in both instruments; `off` must find
    # none — an `off` arm that finds any means the fixture no longer measures the cutoff.
    want = len(TRUE_ROWS) if args.arm == "on" else 0
    ok = hits == want and len(dict_hits) == want
    print(
        f"VERDICT: {'PASS' if ok else 'FAIL'} — arm={args.arm} "
        f"proposed {hits}/4 (want {want}), dictionary {len(dict_hits)}/4 (want {want})"
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
