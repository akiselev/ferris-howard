# Working on Ferris–Howard

Read `PLAN.md` for what is built and what is next. This file is for what a newcomer —
human or agent — would otherwise learn the hard way.

---

## 1. The rules that are not negotiable

**Stage one is binding (ADR-006).** FH constructs are **syntax→syntax macros**. There is no
`elab_rules` anywhere in the language, and there must not be, because `emit-lean` has to be
a single expansion step producing publication-grade Lean. If a feature seems to need an
elaborator, the answer is a `macro_rules` hook with a default rule — that is how `fh_dot%`,
`fh_comprehension%`, `fh_ty%` and `fh_bound%` all work. Look at one before inventing a
sixth mechanism.

**Never re-parse strings.** Syntax is built from syntax. `Syntax.mkAtom`/`mkIdent` and
quotations are fine; `Parser.runParserCategory` on a string you formatted is not.

**Span discipline.** User syntax passes through untouched, so its position stays the user's;
every synthesized node is built under `withRef` of the FH node it came from. The span test
tier exists to catch violations, and it has.

**The emitted artifact carries no FH dependency.** Not an import, not an `open`, not a
constant. `scripts/round-trip.py` checks this and it has caught a real leak — see §5.

**Never use destructive git to undo your own edits.** `git checkout <file>`, `git restore`,
`git reset --hard`, `git clean` discard uncommitted work that exists in no git object. Undo
your own edit by making the inverse edit.

**Do not look for the B7 answer key.** It is frozen out of repo, and implementing sessions
must not read it or search for its location. That prohibition *is* part of the validation
protocol — an implementation that has seen the held-out set cannot be evidence about it.

---

## 2. The gates

Everything below must be green before a commit. They are slow; run them anyway.

| Gate | Command | Notes |
|---|---|---|
| Lean build | `cd lean && lake build --wfail` | ~8,700 jobs warm. An uncaptured warning fails it. |
| Round-trip | `python3 scripts/round-trip.py` | Slow — see §4 on why. |
| MCP smoke | `python3 scripts/mcp-smoke.py` | Needs `cargo build -p fh-atlas --bins` first. |
| Atlas experiments | `python3 scripts/atlas-mathlib-experiment.py` | Needs a slice; see §4. |
| Rust | `cargo test -p fh-atlas && cargo clippy -p fh-atlas --all-targets && cargo fmt -p fh-atlas -- --check` | Zero warnings, not "few". |

`lake build --wfail` does **not** compile test targets in the Rust sense — and a green
result from before a signature change says nothing about after it. Re-run the actual gate
after the last edit, and never report a pass you did not just observe.

---

## 3. House style

**Comments explain *why*, never *what*.** A comment that restates the code is noise. A
comment that records why the obvious thing does not work is the most valuable line in the
file — most of the traps in §5 are in the codebase as exactly such comments.

**Test names are claims.** `carriers_holes_a_type_binder_but_not_a_prop_binder`, not
`test_erase_3`. A reader should learn the rule from the test list.

**Test properties, not implementations.** The anti-unifier is checked by idempotence,
commutativity, subsumption and well-scopedness over 646,918 real pairs — not by pinning one
skeleton. Where a property test is impossible, use a *differential* oracle written with a
different algorithm, so a shared bug cannot make both pass.

**Every fixture states what a good answer looks like before it runs.** An experiment that
can be rationalized after the fact is not an experiment. `scripts/atlas-mathlib-experiment.py`
and the design's T1–T8 are the model: name the families that must appear, and name what
would demonstrate the engine does *not* work.

**Report measured numbers, never expected ones.** If you did not run it, say so.

**Negative controls.** A tool that says everything is fine is worse than no tool. Several
gates here assert that something *must* be found: `atlas honesty` under a narrow whitelist,
the depth-blind anti-unifier's divergence, the normalization knob's cross-carrier collapse.
Each exits non-zero if the check goes quiet.

---

## 4. Costs, measured

**`atlas_extract --local <module>` costs the same as a full extraction.** `--local` filters
the *output*, not the import, so every invocation loads the module's whole closure. A
Mathlib-importing module is ~9 GB resident and tens of minutes. A full `import Mathlib`
extraction did not finish in 24 minutes at 9.4 GB and was abandoned.

Consequences: the round-trip gate's two cases cost four such loads, which dominates CI
time; and Atlas validation runs against a **named** slice, with every claim saying which.

The working slice:

```sh
cd lean && lake exe atlas_extract Mathlib.Algebra.Order.Field.Basic > /tmp/mathlib-algebra.jsonl
# 131,062 declarations, ~80 s
```

**Beware which slice you are measuring on.** `Mathlib.Logic.Basic` sounds like Mathlib and
is not: `Init` 39,590, `Lean` 27,652, `Std` 6,710, **`Mathlib` 668**. Thirty-seven per cent
of it is the Lean compiler's own metaprogramming API. Tuning constants fitted there do not
transfer, and a normalization knob that looks decorative there may simply have nothing to
work on.

**Every `atlas` CLI invocation re-parses the whole slice** — about 6 s for 131k rows before
answering anything. This is why the Python API exists (§6) and why the Rust `examples/` are
binaries rather than scripts.

---

## 5. Traps, each of which cost real time

### Lean

- **`ConstantInfo.value?` returns `none` for a theorem.** Match `.thmInfo` directly. This
  made `uses_proof` empty for *every theorem in Mathlib* — 33,521 of them — and survived
  because the extractor fixture had only `def`s.
- **`Name.append` panics when both arguments carry macro scopes.** Identifiers from
  quotations do. `eraseMacroScopes` both halves before appending; a `::` path names a
  global, so erasing is correct rather than merely safe.
- **A literal identifier in a `macro_rules` pattern will not match a hygienic one.** The F16
  bridges matched a literal `dvd` and silently never fired on a method name arriving from a
  quotation. Branch on `getId.eraseMacroScopes`.
- **Well-founded definitions do not reduce.** `gcd2` compiles by WF recursion, so Lean marks
  it `@[irreducible]`; `decide` cannot evaluate it, `#eval` can, `simp [gcd2]` unfolds it.
  Same for `while`, which goes through `Loop.forIn` and drags in `Classical.choice`.
- **Universe *parameters* must be freed before substituting into a type.** `general.{u}`
  states `@Eq.{u} A …`; substituting `A := Bool` without `mkFreshLevelMVar` leaves an
  ill-typed term for which no instance can exist.
- **`#guard_msgs` cannot see parse errors.** Use the `#fh_parse` harness.
- **`MessageLog.toList` returns only *unreported* messages, and `eoi` resets the log.** Drain
  per command or a whole file's diagnostics vanish.
- **A Lean executable needs `enableInitializersExecution` and `unsafe def main`**, or every
  *imported* parser is absent and commands truncate at their first notation.
- **`plausible` is non-deterministic.** Pin the verdict, never the witness.
- **Reserving a keyword can break FH's own source.** It has happened three times (`enum`,
  `as`, `mod`). The full reserved list is read off the grammar in `differences.md` — read it
  off the grammar again rather than trusting the list.

### Rust / Atlas

- **The I3 encoding must be parsed over bytes.** Names are byte-length-prefixed and may
  contain any UTF-8 (`c(3:ℝ,0)` is three bytes, one character).
- **`statement-hash.md` is wrong about `Const`.** The encoder emits an explicit level
  *count* before the levels. The code produces the corpus; the doc needs amending.
- **An anti-unifier's memo must be keyed by binder depth.** Without it, positions whose de
  Bruijn indices resolve to *different* binders get the same variable. It fires on 0.29% of
  real pairs and is invisible to idempotence, commutativity and subsumption — all three are
  depth-blind themselves.
- **Erasure must replace binders, never delete them.** Deleting shifts every de Bruijn index
  above it and silently changes the statement.
- **`outParam` hides a sort.** `HAdd.hAdd`'s output binder has domain `outParam (Sort u)`, an
  *application*, so a naive "is the domain a sort" test says no and produces asymmetry.
- **`Prop` is not a carrier.** Holing every implicit sort-domain argument collapses `and_comm`
  into a statement about two erased propositions.
- **Restrict to claims, or you are measuring Lean rather than mathematics.** This has now
  bitten three times in a row — B5's equivalence classes, B6's dictionary rows, B6's
  frontier — and each time the unrestricted answer was *correct* and useless. Without the
  restriction: the largest "equivalence class" is 1,859 declarations whose type is
  literally `Type`; the best dictionary rows are between two recursors; and the top
  frontier pairs are `Aesop ~ ProofWidgets` and `Aesop ~ Qq`, metaprogramming siblings that
  share shapes because they are all Lean code over syntax trees. A working slice is
  two-thirds `Init`/`Std`/`Lean`, so this is not a corner case.
- **A carrier is often an *explicit* binder.** `Nat.add_comm` binds `(n m : ℕ)` explicitly;
  a rule that only looks at implicit binders leaves the carrier in place and the whole
  normalization knob does nothing.

---

## 6. The Python API is part of the contract

`crates/fh-atlas-py` binds the Atlas core so that scripts load a corpus **once** and query
it many times, instead of paying a full re-parse per CLI call. `research/python-api.md` has
the full design; only the `Corpus` namespace is bound so far.

**If you add or change an Atlas query, update the Python binding in the same change.** Not
in a follow-up. A query that exists only in the CLI is a query that validation scripts
cannot afford to call, so it will not get exercised — and an unexercised query is an
unvalidated one. The same rule applies to the other tracks as their surfaces land: the
binding is how research scripts reach them, and a surface with no binding is a surface with
no users.

Concretely, adding a query means touching:

1. the engine (`crates/fh-atlas/src/…`),
2. the CLI (`crates/fh-atlas/src/bin/atlas.rs`),
3. the Python binding and its `.pyi` stubs (`crates/fh-atlas-py`),
4. `fh mcp`'s tool list where an agent should be able to call it
   (`crates/fh-atlas/src/bin/fh-mcp.rs`), and
5. a gate that exercises it against a real slice.

---

## 7. Layout

```
lean/FerrisHoward/     the language: Syntax/, Expand/, Bridge/, Lint/, Atlas/, Report/
lean/Tests/            fixtures — M0/ M1/ M2/ M3/ corpus/ Atlas/
lean/Fh*.lean          the executables: fh_check, fh_emit, atlas_extract
crates/fh-atlas/       the Atlas engine: graph, statement digest, skel/ (B4), json
crates/fh-atlas-py/    the Python binding
scripts/               the gates
research/              design studies; `codegen.md` carries ADR-006
```

Every FH feature lands with **four test tiers**: golden expansion, elaboration, negative
(exact pinned messages), and span. A feature with three tiers is not done.
