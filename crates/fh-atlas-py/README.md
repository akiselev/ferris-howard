# fh_atlas — the Atlas core, from Python

One load, many queries.

```python
import fh_atlas as fa

corpus = fa.Corpus.load("/tmp/mathlib-algebra.jsonl")   # ~5 s, once
len(corpus)                                             # 131062
corpus.why("Nat.add_comm", "Nat.rec", lens="proof")     # ['Nat.add_comm', 'Nat.brecOn', …]
corpus.walls(lens="proof", top=5)                       # [('Eq', 53282), ('Nat', 39552), …]
corpus.skeleton("Nat.add_comm", level="carriers") == corpus.skeleton("Int.add_comm", level="carriers")
```

Every `atlas` CLI invocation re-reads and re-parses the whole slice before answering
anything — measured at 6.0 s per call on the 131,062-declaration algebra slice. A script
that asks twenty questions pays that twenty times. Measured by `tests/smoke.py` on that
slice, same twenty questions, same release binary, both paths asserted to return the same
answers:

| | time |
|---|---|
| 20 × `atlas foundations … --lens proof` | **118.6 s** |
| `Corpus.load` + 20 × `.foundations(…)` | **4.27 s** (4.27 s load + 1.5 ms of queries) |

28× end to end; the queries themselves are ~80,000× cheaper than the process that used to
answer them, and the twenty-first question is free. Across four runs the CLI side ranged
111.8–120.3 s and the handle side 4.27–4.59 s, so the ratio is 25–28×, not a tuned number.

`scripts/atlas-mathlib-experiment.py`, rewritten against this API, went from four CLI
re-parses plus a full `json.loads` of the 146 MB slice to one load: **31.0 s → 7.8 s**,
same claims, same negative controls.

## Build

Requires a Python ≥3.10 virtualenv. The wheel is `abi3-py310`, so one build serves every
later Python.

```sh
python3 -m venv .venv && . .venv/bin/activate
pip install maturin
maturin develop --release -m crates/fh-atlas-py/Cargo.toml   # or: maturin build --release
```

`cargo build -p fh-atlas-py` also works and is what CI should type-check; it produces a
`cdylib` with undefined Python symbols, which is what an extension module is. The crate
declares `test = false` — an `extension-module` cdylib cannot be linked into a Rust test
binary — so **the tests are Python**:

```sh
cargo build -p fh-atlas --bins --release        # the differential oracle
python3 crates/fh-atlas-py/tests/smoke.py       # --slice defaults to /tmp/mathlib-algebra.jsonl
```

`tests/smoke.py` checks the binding against the CLI on the queries both expose, checks the
properties no oracle can see (the lens separating claim from argument, erasure levels
forming a chain, a bad lens raising rather than guessing), and prints the measurement in
the table above.

## What is bound

`research/python-api.md` §1's architecture, and the `fa.Corpus` namespace of §2 — the
queries `atlas` itself exposes:

| Python | CLI |
|---|---|
| `Corpus.load(path)` | (the re-parse every invocation pays) |
| `len(corpus)`, `corpus.names()`, `corpus.get(name)` | `atlas stats` |
| `corpus.why(source, target, lens=…)` | `atlas why` |
| `corpus.foundations(name, lens=…)` | `atlas foundations` |
| `corpus.impact(name, lens=…)` | `atlas impact` |
| `corpus.walls(lens=…, top=…)` | `atlas walls` |
| `corpus.honesty(whitelist=…)` | `atlas honesty` |
| `corpus.skeleton(name, level=…)` | `atlas skeleton` |
| `corpus.generalize(left, right)` | — |

`lens` is `"statement" | "proof" | "both"` (default `"both"`); `level` is one of
`skel::erase::Level`'s five names, default `"carriers"`. Results are `Decl` and
`Generalization` pyclasses with read-only attributes and a `__repr__` worth printing. Type
stubs ship in the wheel (`fh_atlas.pyi`, `py.typed`).

Two deliberate departures from the sketch in §2:

* **`Decl` carries `uses_statement` and `uses_proof`.** They are the row as B1 extracted
  it, and the B1 regression claim in `scripts/atlas-mathlib-experiment.py` — "theorems
  carry proof dependencies" — is about *direct* edges. Answering it through the transitive
  closure instead costs 2.4 ms × 66,700 theorems ≈ 157 s; answering it off the row costs
  1.0 s. Without these two fields the gate would have had to re-read the JSONL in Python,
  which is the thing this package exists to stop.
* **`corpus.get` returns `None` for an unknown name; everything else raises.** "Is it
  here" is `get`'s question, so `None` is its answer. For `foundations`, `why`, `skeleton`
  and `generalize` a missing declaration is a mistake, and they raise
  `UnknownDeclaration` naming it. `impact` deliberately accepts names outside the slice:
  asking what rests on something not extracted is a fair question, and the answer is the
  part of the slice that cites it.

### Errors

`AtlasError` is the base. `FileNotFoundError` for a missing slice, `SliceError` for one
whose rows do not parse (naming the line), `UnknownDeclaration` for a name not in the
slice, `NoStatement` for a declaration whose statement is absent or unparseable (naming
the reason B1 gave), `ValueError` for a lens or level that does not exist (listing the ones
that do). None of these are `None` returns: a script that mistyped a lens should stop, not
quietly get `both`.

### The `&mut Arena` problem

`skel::erase::erase` and `skel::lgg::generalize` both take `&mut Arena` — erasure interns
the holed nodes it produces and anti-unification interns its variables, so a *query*
mutates. Python has no `&mut` to hand out.

The arena, its signature table and its erasure cache therefore live **inside the handle
behind a `Mutex`**, and the pyclass is `frozen`: Python sees a shared handle, Rust does the
locking. Consequences, stated rather than discovered:

* Skeleton and generalize calls from several Python threads serialize on that lock. The
  graph queries touch no arena, take no lock, and run genuinely in parallel — every
  operation releases the GIL (`py.detach`, which is what PyO3 ≥0.26 calls
  `py.allow_threads`).
* The arena grows monotonically. Erasure is cached per `(term, level)`, so a repeated
  level is free; `generalize` interns fresh variables per call.
* It is built on the **first** skeleton query, not at load — parsing 131k statement
  encodings costs 3.5 s that a graph-only session should not pay. `Corpus.load` stays a
  graph load.

## What is *not* bound, and why

Two groups, and the distinction matters: queries the engine already answers and this
binding does not reach, versus API surface with no Rust behind it at all.

**Bound in the CLI, not here — the debt this crate owes CLAUDE.md §6.** B4's index, B5 and
B6 all landed while this binding was being written, and a query validation scripts cannot
call is a query that does not get exercised. Each needs a result type, which is why none
of them is a one-liner:

* **`corpus.similar(…)`** (`atlas similar`, `skel::index`) — needs a `Match` carrying the
  reported level, the retention and which of the three index sources found it.
* **`corpus.equivalent(…)` / `corpus.classes()`** (`atlas equivalent`, `atlas classes`,
  `equiv`) — B5's equivalence graph.
* **`corpus.dictionary(…)` / `corpus.transport(…)` / `corpus.frontier()`** (`dict`) —
  B6, including the unmatched half, which is the part `python-api.md` §2 calls
  `.missing_entries` and the part a research script actually reads.

**No Rust behind it yet:**

* **`corpus.home`, `corpus.resolve`** — the residual/home-theory operations of §2.
* **`fa.Session` / `GoalState`** — no Lean REPL subprocess management exists yet. §1 puts
  the process boundary here deliberately; nothing of it is written.
* **`fa.vet`, `fa.certs`, `fa.grade`, `fa.converge`, `fa.Trace`, `fa.ledger`** — Tracks C,
  D and E. No kernels to call, no traces to load, no ledger to write.
* **Campaign journaling, replay, `.cost` on results, `fa.require`** — §3's four principles.
  They are properties of an API with something to journal; with one namespace bound there
  is nothing yet to record.
* **NumPy / buffer-protocol interop and `fractions.Fraction` rationals** — §1's zero-copy
  discipline. No matrix or trace crosses the boundary yet, so the package has no NumPy
  dependency at all.
* **Doctests in CI against a vendored mini-corpus** — §2's S7 rule applied to the API. The
  docstrings here carry no `>>>` examples yet; `tests/smoke.py` is the gate instead, and it
  needs a real slice rather than a vendored one.

`Corpus.load` also does not take a corpus *pin* (`"mathlib@pin"`) or carry an environment
fingerprint: it takes a path to a B1 JSONL slice, because that is what the extractor
produces today.
