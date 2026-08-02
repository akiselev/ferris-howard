#!/usr/bin/env python3
"""Validation experiments for the Atlas indexes against real Mathlib (B4/B5/B6).

The point is not "the code runs". It is "the answers are the ones a mathematician would
give", so every experiment below names *what a good answer looks like* before it runs, and
fails if the answer is merely plausible.

The slice is produced by:

    cd lean && lake exe atlas_extract Mathlib.Algebra.Order.Field.Basic > /tmp/mathlib-algebra.jsonl

which takes ~80 s and is worth caching. Pass `--slice PATH` to point elsewhere, and read
CLAUDE.md §4 first: `Mathlib.Logic.Basic` sounds like Mathlib and is 37% Lean metaprogramming.

The experiments run against one `fh_atlas.Corpus` handle. They used to shell out to the
`atlas` CLI, which re-parses the whole 131k-row slice per question — eight questions, eight
re-parses, ~48 s of pure re-reading. Build the binding first:

    pip install maturin && maturin develop --release -m crates/fh-atlas-py/Cargo.toml

Run from the repository root:  python3 scripts/atlas-mathlib-experiment.py
"""

from __future__ import annotations

import argparse
import pathlib
import sys
import time

try:
    import fh_atlas as fa
except ImportError:
    sys.exit(
        "fh_atlas is not importable — build the binding with:\n"
        "  maturin develop --release -m crates/fh-atlas-py/Cargo.toml\n"
        "(see crates/fh-atlas-py/README.md)"
    )


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


# ---------------------------------------------------------------------------
# B2 — the dependency graph. Already built; these are its regression experiments.
# ---------------------------------------------------------------------------

def experiment_walls(corpus: fa.Corpus) -> Experiment:
    e = Experiment(
        "B2 walls",
        "the most-cited declarations in Mathlib are its foundations, not an artefact",
    )
    top = [name for name, _ in corpus.walls(lens="proof", top=10)]
    # `Eq` is under essentially every proof in mathematics; if it is not at the top,
    # the proof lens is not reading proof terms.
    e.check("Eq" in top[:3], f"`Eq` in the top 3 (got {top[:3]})")
    # A wall list dominated by one namespace would mean the slice is not Mathlib-wide.
    e.check(len(set(n.split(".")[0] for n in top)) >= 3, f"top 10 spans ≥3 roots: {top}")
    return e


def experiment_proof_edges(corpus: fa.Corpus) -> Experiment:
    e = Experiment(
        "B1 proof edges",
        "theorems carry proof dependencies — the bug B2 found stays fixed",
    )
    # `uses_proof` off the row, not `foundations`: the bug was that the extractor emitted
    # *no* proof edges for theorems, which is a question about direct edges. The transitive
    # closure would answer it too, at 2.4 ms per theorem against 66,700 theorems.
    theorems = [d for d in map(corpus.get, corpus.names()) if d.kind == "theorem"]
    with_edges = [d for d in theorems if d.uses_proof]
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

# Lean's own three, which everything classical uses. The binding's default, spelled out
# here because the honesty experiment passes an explicit whitelist and an explicit list is
# used exactly as given.
CLASSICAL_AXIOMS = ["propext", "Classical.choice", "Quot.sound"]


def experiment_honesty(corpus: fa.Corpus) -> Experiment:
    e = Experiment(
        "C5 honesty",
        "nothing in the slice rests on `sorryAx`, and the axioms that *are* used are the "
        "ones a reader would expect",
    )
    # The sharp claim, and the one that matters: not a single declaration's proof reaches
    # `sorryAx`. This is the transitive scan doing the job anti-cheat needs.
    resting = corpus.impact("sorryAx", lens="proof")
    e.check(not resting, f"{len(resting)} declarations rest on `sorryAx`")

    # And with the compiler axioms whitelisted, the scan is clean. Without them it is not,
    # which is the tool working: it found the four `ByteArray` unsafe internals whose
    # implementations stand on `lcProof`, out of 131k declarations.
    findings = corpus.honesty(whitelist=CLASSICAL_AXIOMS + COMPILER_AXIOMS)
    e.check(not findings, f"clean under the compiler-axiom whitelist: {findings[:4]}")

    # The negative control: with a *narrow* whitelist the scan must find something, or it
    # is not looking.
    narrow = corpus.honesty(whitelist=["propext"])
    e.check(bool(narrow), f"a narrow whitelist produces findings ({len(narrow)}) — the scan is live")
    return e


EXPERIMENTS = [experiment_proof_edges, experiment_walls, experiment_honesty]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--slice", default="/tmp/mathlib-algebra.jsonl")
    args = ap.parse_args()

    if not pathlib.Path(args.slice).exists():
        sys.exit(
            f"no slice at {args.slice}\n"
            "produce one with:  cd lean && lake exe atlas_extract "
            "Mathlib.Algebra.Order.Field.Basic > /tmp/mathlib-algebra.jsonl"
        )
    started = time.perf_counter()
    corpus = fa.Corpus.load(args.slice)
    print(f"slice: {args.slice} — {len(corpus)} declarations, parsed once in "
          f"{time.perf_counter() - started:.1f}s\n")

    ok = True
    for make in EXPERIMENTS:
        started = time.perf_counter()
        experiment = make(corpus)
        ok = experiment.report() and ok
        print(f"       ({time.perf_counter() - started:.1f}s)\n")
    print("atlas experiments:", "green" if ok else "RED")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
