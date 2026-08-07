# FH → LaTeX: The Third Backend

**Status:** Draft 0.1 · How frozen FH/Lean statements become the equations in the paper — and why they must never be typed by hand.

## 0. Landscape (verified)

The Lean world already runs a mature LaTeX↔Lean publication model: **leanblueprint** (Massot) links LaTeX theorem environments to Lean declarations via `\lean{}` macros and a `lean_decls` registry, with dependency graphs and web/PDF outputs — the FLT/PFR-class projects all use it, and **Verso Blueprint** (Lean FRO) is its designated successor, with papers/slides/notes as Lean-checked documents. Tao's endorsement states the division of labor: LaTeX carries the human-readable proof, Lean the machine-readable one, links between. The community style guide for blueprint prose is explicit: the LaTeX must read as standard mathematics with *no trace of Lean*. And the LLM wing exists too: auto-informalization of whole Lean libraries into domain-readable LaTeX, run *blind* (no access to source papers, to prevent leak-anchoring). What nobody has — because nobody else owns a surface syntax tree designed for it — is deterministic, notation-faithful equation generation. That's ours.

## 1. The rule that governs everything

**Every mathematical statement printed in the paper is machine-generated from the frozen statements. Hand transcription is forbidden.** Rationale: hand-typed LaTeX reintroduces the faithfulness gap at the last mile — the classic irony of formalization papers is a kernel-checked theorem sitting beside a typo'd LaTeX rendition of it, and *the LaTeX is what referees and citers actually read*. So `fh emit-latex` output lands in `artifact/equations.tex`, papers include equations only by `\fhstatement{couette.re_e_bracket}`-style reference, CI regenerates and diffs on every build, and a hand edit inside a generated block fails CI. The last mile goes under the same version control as everything else.

## 2. Four layers

**L1 — the notation table.** The Rosetta doc grows a third column: FH/Lean token → LaTeX (`for<>` → `\forall`, `<=` → `\le`, `in` → `\in`, `Rat` → `\mathbb{Q}`, ...). Purely mechanical; covers the logical skeleton of every statement. Parenthesization reuses the parser's precedence table, so rendered formulas are correct-by-construction rather than re-derived — the syntax→syntax M0 amendment paying its fourth dividend: `emit-latex` is a pretty-printer over the *same surface trees* the other backends walk.

**L2 — display attributes.** Each FH declaration may carry its mathematical costume:
```rust
#[latex("Q_{\\mathrm{Re}}[u]")]        fn energyForm(re: Rat, ...) -> Rat
#[latex("\\mathrm{Re}_E(\\mathcal{C})")] fn Re_E(c: AdmissibleClass) -> EReal
#[latex_class("\\mathcal{C}_{\\mathrm{full}}")] // per-constructor, on the enum
```
Binder-aware templates (argument slots, subscript positions) let `energyMonotoneAt(re, Full)` render as the notation a fluids referee expects, not as an applied identifier. Attributes live in the frozen file, so the *rendering intent* is hash-frozen with the meaning.

**L3 — the statement renderer.** A theorem becomes a theorem environment via a small controlled-natural-language scaffold: hypotheses render as "Let Re ∈ ℚ with 0 < Re ≤ L." clauses, the conclusion as a displayed equation, `#[control]`/`#[reading]` attributes route statements to the right paper section automatically. Two channels per statement, with different trust levels kept explicit: the **symbolic channel** (deterministic, from the tree — this is what's printed *as* the statement) and the **prose gloss** (LLM informalization for reader orientation — a V6 artifact, generated blind and reviewed like any informalization, never load-bearing). Deterministic where trust matters, fluent where it doesn't.

**L4 — the document.** Target Verso-Blueprint/leanblueprint conventions rather than inventing: each rendered statement carries its `\lean{}` link into `artifact/Couette.lean`, a freeze-hash footnote, and membership in the auto-generated dependency graph; proofs are *not* rendered from tactics — the paper carries human/agent-written proof sketches in blueprint house style (standard math prose, no Lean residue), with the artifact link as the proof of record. Exact rationals print honestly: bracket endpoints as decimal enclosures in the text ("Re_E ∈ [20.65, 20.67]") with the exact fractions in the appendix, both generated.

## 3. Integration and milestones

The referee pack gains its final exhibit: `equations.tex` with provenance manifest (statement hash → equation block). The vet battery gains a probe for free: the L3 symbolic rendering *is* a formal-to-display translation, so the V6 round-trip (independent agent reads only the rendered LaTeX, re-formalizes, diff against frozen) now tests the exact channel referees consume. Milestones: **L0** — hand-write `equations.tex` for couette-re-e *once*, as the golden target the generator must reproduce; **L1–L2** — the table + attributes on the couette statement file (a weekend atop the M0 macros); **L3–L4** — renderer + blueprint wiring with the CI diff rule, in time for the Phase 7 paper. End state: the paper's equations, its Lean artifact, and its FH source are three projections of one frozen tree — and for the first time in the history of the genre, the version of the theorem that humans read is *guaranteed* to be the version the kernel checked.
