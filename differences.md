# FH ↔ Rust: the differences page

**Status:** Living document (Ruling D deliverable) · started 2026-08-01 at M0 · grows one entry per feature that diverges from Rust or from what a Rust reader would expect. Classification vocabulary per Ruling D: **extension** (ill-formed Rust becomes well-formed FH), **confined** (constructs Rust doesn't have), **violation** (legal-Rust-lookalike changes meaning — requires a corpus-review amendment first).

## The headline (the one sanctioned violation)

**Ruling A — operators mean mathematics, everywhere.** `==`/`!=` are `Eq`/`Ne`; `&& || !` are `∧ ∨ ¬`; `<= < > >=` are order relations; `->` is implication; `<->` is `Iff`; `in` is `∈`. All Props, unconditionally — `Bool` is reached explicitly via `decide(p)` and methods (`.xor()`, `.band()`, `.bnot()`). Consequence: `if p { }` on a Prop condition is decidable-`if` (F14). This is the sole case where code that also parses as Rust means something different, and it is the reason this page exists.

## Grammar divergences (Ruling D register)

| Divergence | Class | Source |
|---|---|---|
| `for<a, b, c: Self>` — ascription distributes over the unascribed prefix (Rust's generic lists bound only `c`) | confined (Rust's `for<>` takes only lifetimes; deliberate divergence, documented loudly per F2) | F2 |
| Types in term position: `finrank(K, V)` | extension | F8 |
| Named arguments: `congruent(x, a, modulus: m)` | extension | F11 |
| `in` as a binary operator outside loops | extension | F12 |
| Comprehension braces `{x: A | P}` (Set/Subtype by expected type) | confined | F13 (as amended) |
| `if h @ (cond)` hypothesis binding | extension | F15 |
| Ambient `var` declarations, mention-based inclusion, `include` | confined | F17 |
| `Space` kind vocabulary; trait names in annotation position (`var G: Grp;`) | confined | F18 |
| `theorem` as an item keyword | confined | standing decision |
| Per-variant return types on `enum` (indexed families) | extension | design §4.5 |
| `extern "axiom" { ... }` | extension | design §4.6 |

## Restrictions (legal Rust that FH rejects)

Not Ruling-D divergences — no construct changes meaning — but a Rust reader can still be
surprised, so they are tracked. Relaxing a restriction later is non-breaking; adding one
is not, which is why they are chosen conservatively (Ruling B).

| Restriction | Rationale | Landed |
|---|---|---|
| Call syntax admits no space before `(`: `f(x)`, never `f (x)` | FH has no juxtaposition application, so this is not needed *yet*; keeping it reserves the freedom to parse statement bodies (A2.3) without a Rust-style ambiguity, and relaxing it later breaks nothing | M0 (A0.1) |
| Field access admits no space around `.`: `x.f`, never `x . f` | same, and it is what every Rust programmer writes anyway | M0 (A0.2) |
| No zero-argument closure `\|\| e` | `\|\|` lexes as one token (and is `∨` from A1.5). Rust has the same collision and resolves it in the parser; FH will not, per Ruling B | M0 (A0.2) |
| `::` joins identifiers only: `f(x)::g` is an error | `::` is name composition, `.` is a value's field or method. They resolve differently, so conflating them would make one silently mean the other | M0 (A0.2) |

## Platform costs (M0 facts — Lean hosting, not design choices)

- **Keyword reservation:** importing FH reserves `fn`, `struct`, `enum`, `trait`, `impl`, `var`, `theorem`, `exists` as tokens in that file — ambient Lean code in the same file cannot use them as identifiers (e.g. `def var := 3` errors). Battery test lands with A0.5.
- **Identifier `?`/`!`:** Lean identifiers may contain `?`/`!`, so FH splits trailing `?`/`!` off identifiers; bare `x?` as a `?`-bind gets a pinned negative test (A0.6).
- **Comments:** until the M3 standalone `.fh` format, FH lives in `.lean` files — `--` and `/- -/` only; Rust's `//` and `/* */` cannot lex.
- **Nested generics:** `Poly<Fp<P>>` requires the `>`-splitting lexer (I5); until it lands, write `Poly<Fp<P> >`.
- **Non-associativity by decree:** `a < b < c`, `a <-> b <-> c`, and `a in b in c` are parse errors — parenthesize (F7 as amended).
- **Precedence inversion vs Rust:** `!` binds *looser* than comparisons (`!a == b` is `!(a == b)` — the mathematical reading), per the F7 table (freeze formalizes pre-M1).
