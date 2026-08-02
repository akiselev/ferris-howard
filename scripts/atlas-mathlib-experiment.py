#!/usr/bin/env python3
"""Validation experiments for the Atlas indexes against real Mathlib (B4/B5/B6).

The point is not "the code runs". It is "the answers are the ones a mathematician would
give", so every experiment below names *what a good answer looks like* before it runs, and
fails if the answer is merely plausible.

The slice is produced by:

    cd lean && lake exe atlas_extract Mathlib > /tmp/mathlib-full.jsonl

which takes minutes and is worth caching. Pass `--slice PATH` to point elsewhere.

Run from the repository root:  python3 scripts/atlas-mathlib-experiment.py
"""

from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
ATLAS = ROOT / "target" / "release" / "atlas"
ATLAS_DEBUG = ROOT / "target" / "debug" / "atlas"


class Experiment:
    """One named claim about the Atlas, with the evidence that would settle it."""

    def __init__(self, name: str, claim: str) -> None:
        self.name = name
        self.claim = claim
        self.notes: list[str] = []
        self.passed: bool | None = None

    def check(self, condition: bool, detail: str) -> None:
        self.notes.append(("  ok   " if condition else "  FAIL ") + detail)
        self.passed = condition if self.passed is None else (self.passed and condition)

    def report(self) -> bool:
        status = "PASS" if self.passed else "FAIL"
        print(f"[{status}] {self.name}\n       claim: {self.claim}")
        for n in self.notes:
            print(n)
        return bool(self.passed)


def atlas(*args: str, slice_path: str) -> tuple[str, int]:
    exe = ATLAS if ATLAS.exists() else ATLAS_DEBUG
    if not exe.exists():
        sys.exit("atlas binary not built — run `cargo build -p fh-atlas --bins --release`")
    started = time.time()
    proc = subprocess.run(
        [str(exe), args[0], slice_path, *args[1:]],
        capture_output=True, text=True, cwd=ROOT, timeout=1800,
    )
    elapsed = time.time() - started
    if elapsed > 5:
        print(f"       ({args[0]} took {elapsed:.0f}s)", file=sys.stderr)
    return proc.stdout, proc.returncode


def load(slice_path: str) -> list[dict]:
    with open(slice_path) as f:
        return [json.loads(line) for line in f if line.strip()]


# ---------------------------------------------------------------------------
# B2 — the dependency graph. Already built; these are its regression experiments.
# ---------------------------------------------------------------------------

def experiment_walls(slice_path: str, rows: list[dict]) -> Experiment:
    e = Experiment(
        "B2 walls",
        "the most-cited declarations in Mathlib are its foundations, not an artefact",
    )
    out, _ = atlas("walls", "--lens", "proof", slice_path=slice_path)
    names = [ln.split()[-1] for ln in out.splitlines() if ln.strip()]
    top = names[:10]
    # `Eq` is under essentially every proof in mathematics; if it is not at the top,
    # the proof lens is not reading proof terms.
    e.check("Eq" in top[:3], f"`Eq` in the top 3 (got {top[:3]})")
    # A wall list dominated by one namespace would mean the slice is not Mathlib-wide.
    e.check(len(set(n.split(".")[0] for n in top)) >= 3, f"top 10 spans ≥3 roots: {top}")
    return e


def experiment_proof_edges(slice_path: str, rows: list[dict]) -> Experiment:
    e = Experiment(
        "B1 proof edges",
        "theorems carry proof dependencies — the bug B2 found stays fixed",
    )
    theorems = [r for r in rows if r["kind"] == "theorem"]
    with_edges = [r for r in theorems if r.get("uses_proof")]
    e.check(len(theorems) > 1000, f"{len(theorems)} theorems in the slice")
    ratio = len(with_edges) / max(len(theorems), 1)
    e.check(ratio > 0.9, f"{ratio:.1%} of theorems have proof edges")
    return e


# Lean's compiler axioms. They stand behind `unsafe` implementations, are erased at
# runtime, and never participate in a proof of a theorem — so they are a legitimate
# whitelist entry rather than a finding. Naming them here rather than widening the tool's
# default keeps the default strict.
COMPILER_AXIOMS = [
    "lcProof", "lcAny", "lcCast", "lcErased", "lcUnreachable", "lcVoid",
    "Quot.lcInv", "isScalarObj", "Lean.trustCompiler",
    "Lean.ofReduceBool", "Lean.ofReduceNat",
]


def experiment_honesty(slice_path: str, rows: list[dict]) -> Experiment:
    e = Experiment(
        "C5 honesty",
        "nothing in the slice rests on `sorryAx`, and the axioms that *are* used are the "
        "ones a reader would expect",
    )
    # The sharp claim, and the one that matters: not a single declaration's proof reaches
    # `sorryAx`. This is the transitive scan doing the job anti-cheat needs.
    out, _ = atlas("impact", "sorryAx", "--lens", "proof", slice_path=slice_path)
    resting = [ln for ln in out.splitlines() if ln.strip()]
    e.check(not resting, f"{len(resting)} declarations rest on `sorryAx`")

    # And with the compiler axioms whitelisted, the scan is clean. Without them it is not,
    # which is the tool working: it found the four `ByteArray` unsafe internals whose
    # implementations stand on `lcProof`, out of 131k declarations.
    out, code = atlas(
        "honesty", "propext", "Classical.choice", "Quot.sound", *COMPILER_AXIOMS,
        slice_path=slice_path,
    )
    e.check(code == 0, f"clean under the compiler-axiom whitelist: {out.strip()[:160]}")

    # The negative control: with a *narrow* whitelist the scan must find something, or it
    # is not looking.
    out, code = atlas("honesty", "propext", slice_path=slice_path)
    e.check(code != 0, "a narrow whitelist produces findings (the scan is live)")
    return e


EXPERIMENTS = [experiment_proof_edges, experiment_walls, experiment_honesty]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--slice", default="/tmp/mathlib-full.jsonl")
    args = ap.parse_args()

    if not pathlib.Path(args.slice).exists():
        sys.exit(
            f"no slice at {args.slice}\n"
            "produce one with:  cd lean && lake exe atlas_extract Mathlib > /tmp/mathlib-full.jsonl"
        )
    rows = load(args.slice)
    print(f"slice: {args.slice} — {len(rows)} declarations\n")

    ok = True
    for make in EXPERIMENTS:
        ok = make(args.slice, rows).report() and ok
        print()
    print("atlas experiments:", "green" if ok else "RED")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
