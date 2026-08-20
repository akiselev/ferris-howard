# FH ↔ Rust: the differences page

**Status:** Living document (Ruling D deliverable) · started 2026-08-01 at M0 · grows one entry per feature that diverges from Rust or from what a Rust reader would expect. Classification vocabulary per Ruling D: **extension** (ill-formed Rust becomes well-formed FH), **confined** (constructs Rust doesn't have), **violation** (legal-Rust-lookalike changes meaning — requires a corpus-review amendment first).

## The headline (the one sanctioned violation)

**Ruling A — operators mean mathematics, everywhere.** `==`/`!=` are `Eq`/`Ne`; `&& || !` are `∧ ∨ ¬`; `<= < > >=` are order relations; `->` is implication; `<->` is `Iff`; `in` is `∈`. All Props, unconditionally — `Bool` is reached explicitly via `decide(p)` and methods (`.xor()`, `.band()`, `.bnot()`). Consequence: `if p { }` on a Prop condition is decidable-`if` (F14). This is the sole case where code that also parses as Rust means something different, and it is the reason this page exists.

## Grammar divergences (Ruling D register)

| Divergence | Class | Source |
|---|---|---|
| `for<a, b, c: Self>` — ascription distributes over the unascribed prefix (Rust's generic lists bound only `c`) | confined (Rust's `for<>` takes only lifetimes; deliberate divergence, documented loudly per F2). Landed M1 (A1.4) with the negative test F2 asks for: a body using the *first* binder at another type is an error, which is the observable difference between the two readings | F2 |
| Types in term position: `finrank(K, V)` | extension — free, and by construction: design §4.1 has one expression grammar for both positions, so a type *is* an expression. Pinned M2 (A2.5) rather than built | F8 |
| Named arguments: `congruent(x, a, modulus: m)` | extension — `ident: expr` in a call is ill-formed Rust, so the syntax was free; brace-delimited struct literals and paren-delimited ascription are the neighbours, and neither collides. Landed M2 (A2.5) | F11 |
| `in` as a binary operator outside loops | extension | F12 |
| Comprehension braces `{x: A | P}` (Set/Subtype by expected type) | confined | F13 (as amended) |
| `if h @ (cond)` hypothesis binding | extension | F15 |
| Ambient `var` declarations, mention-based inclusion, `include` | confined — Rust has no ambient-declaration form. Landed M2 (A2.4) as Lean's own `variable`/`include`, whose mention rule *is* F17's. The annotation decides the binder: a carrier (a kind, or `impl C`) is implicit, matching what `fn f<G>(…)` produces; anything else is an explicit value or hypothesis | F17 |
| `var G: impl Grp;` for the structure form, where design §4.8 writes `var G: Grp;` | confined — `impl Trait` is Rust's own vocabulary with its actual Rust meaning, and design §5 had already dropped it from return position. Telling `var G: Grp;` from `var eps: Real;` is name resolution, which is stage two, and ADR-006 makes stage one load-bearing. **Reversible:** when a resolution mechanism exists the marker becomes optional rather than required, which is non-breaking (Ruling B) | F17, design §4.8 |
| `Space` kind vocabulary (`Space`, `Space<u>`, `Sort`, `Sort<u>`); trait names in annotation position (`var G: Grp;`) | confined — neither is Rust syntax in that position, so nothing that also parses as Rust changes meaning. `Space` is recognised by *name* rather than given a production, so no token is reserved; `Sort` needs one because Lean's lexer already makes it a keyword. Landed M2 (A2.4) for the kind half | F18 |
| `theorem` as an item keyword | confined | standing decision |
| `use lean::Fp;` brings a Mathlib object alias into scope (`Fp<P>` is `ZMod P`, `Poly<R>` is `Polynomial R`, `Fractions<R>`, `Quotient<R, I>`, `LinearMap<K, V, W>`); `use lean::Prime;` makes `where P: Prime` the binder `[Fact (Nat.Prime P)]` | confined — same import rule as F16, applied to objects and bounds instead of method spellings. Outside the import each name is an ordinary identifier. Landed M2 (A2.5) | design §6 |
| `use lean::C;` brings a class's F16 method spellings into scope (`p.dvd(a)` is `p ∣ a` only after `use lean::Dvd;`). Bridged as of M2: `Dvd`, `Abs`, `Pow`, `Find`, `Function` | confined — Rust has trait imports and this is the same rule applied to notation spellings; outside the import `.` is plain dot notation, unchanged | F16, design §6 |
| Per-variant return types on `enum` (indexed families) | extension | design §4.5 |
| `extern "axiom" { ... }` | extension | design §4.6 |
| `e as T` is a *coercion* between mathematical types, not Rust's primitive cast; a coercion FH did not write is an error | confined — Rust's `as` has no meaning to preserve here, and F10's `(e: T)` keeps ascription separate. Enforced by a post-elaboration audit (A2.0), switchable with `linter.fh.silentCoercion` | F9 |
| No coherence or orphan rule: several `impl`s may cover one class and carrier | confined — FH adopts Lean's permissiveness, which Mathlib depends on. The divergence is the *absence* of Rust's rule, and it is diagnosed rather than prohibited: `linter.fh.instanceShadow` names the instances a new `impl` joins | design §4.4 |

## Restrictions (legal Rust that FH rejects)

Not Ruling-D divergences — no construct changes meaning — but a Rust reader can still be
surprised, so they are tracked. Relaxing a restriction later is non-breaking; adding one
is not, which is why they are chosen conservatively (Ruling B).

| Restriction | Rationale | Landed |
|---|---|---|
| Call syntax admits no space before `(`: `f(x)`, never `f (x)` | FH has no juxtaposition application, so this is not needed *yet*; keeping it reserves the freedom to parse statement bodies (A2.3) without a Rust-style ambiguity, and relaxing it later breaks nothing | M0 (A0.1) |
| Field access admits no space around `.`: `x.f`, never `x . f` | same, and it is what every Rust programmer writes anyway | M0 (A0.2) |
| No zero-argument closure `\|\| e` | `\|\|` lexes as one token (and is `∨` from A1.5). Rust has the same collision and resolves it in the parser; FH will not, per Ruling B | M0 (A0.2) |
| An `enum` variant's fields are all named or all unnamed, never mixed | Rust has the same two variant shapes; mixing them has no Rust meaning to preserve, and choosing one silently would be worse | M0 (A0.3) |
| A `<` comparison must be parenthesised: `(a < b)`, never bare | F6: a bare `<` could open a generic argument list, and one rule everywhere beats a rule that depends on where you are. Enforced at expansion time with fixed wording and an exact span | M1 (A1.3) |
| Generic *arguments* parse above the comparison band | so `Fin<n + 1>` works without help while `Vector<T, {a < b}>` needs Rust's const-generic braces — the same escape Rust programmers already use | M1 (A1.2) |
| A struct literal's brace touches its type: `Point{ x: 1 }`, never `Point { x: 1 }` | a literal makes `{` postfix, which is exactly why Rust forbids struct literals in an `if` condition. FH closes the ambiguity in the lexer instead of the parser, so it *keeps* the construct Rust rejects (`if p == Point{ … } { … }` reads fine) at the cost of one space | M2 (A2.3) |
| Assignment's left side is an identifier: `x = e;`, never `p.x = e;` or `v[i] = e;` | the meanwhile-form is to rebuild — `p = Point{ x: e, ..p };` — and place-expressions are a bigger question (Rust's are about ownership, which FH has none of) than A2.3 should settle in passing | M2 (A2.3) |
| `::` joins identifiers only: `f(x)::g` is an error | `::` is name composition, `.` is a value's field or method. They resolve differently, so conflating them would make one silently mean the other | M0 (A0.2) |
| A `let`'s annotation parses tighter than a statement | without it `let y: Nat = 4; …` reads its annotation as the assignment `Nat = 4; …`, which is how the M0 fixtures caught it. `let y: (let z = 1; z) = 4` needs its parentheses; nobody writes that | M2 (A2.3) |

## Platform costs (Lean hosting, not design choices)

Reviewed for completeness at M2 (an M3 deliverable, pulled forward because the page had
grown eleven entries since M0 and one of them had lost a sentence). The keyword list below
is read off the grammar rather than remembered.

- **Keyword reservation:** importing FH reserves its keywords as tokens in that file — ambient Lean code in the same file cannot use them as identifiers (e.g. `def type := 3` errors). The full list as of M2, read off the grammar rather than remembered: `axiom`, `break`, `continue`, `decreasing_by`, `def`, `enum`, `exists`, `extern`, `fn`, `for`, `if`, `impl`, `include`, `instance`, `lean!`, `let`, `match`, `mod`, `msg`, `mut`, `mutual`, `noncomputable`, `opaque`, `partial`, `return`, `struct`, `theorem`, `todo!`, `trait`, `type`, `use`, `var`, `while`. Most were already Lean tokens; the reservation makes them unconditional rather than contextual. Ambient Lean is otherwise unaffected — plain `def`/`theorem`/`example` parse and elaborate normally in the same file. Battery: `Tests/M0/Lexing.lean` (A0.5), which measures the reservation at *parse* level, since that is where it happens.
- **Identifier `?`/`!`:** Lean identifiers may contain `?` and `!`, so `x?` is *one* identifier and would never reach FH as `x` followed by the bind operator. As of M0, FH **rejects** identifiers ending in either, with an exact span (A0.6) — rejecting now keeps splitting available at A2.3, whereas allowing them and splitting later would break code. The cost was real: Mathlib names like `Option.get!` and `List.head!` were unreachable from FH. **The escape landed at M2 (A2.6): the F16 method bridge.** `use lean::Find;` makes `xs.find(p)` mean `xs.find?(p)` — the bridge names the method FH cannot type, using the rule F16 already had. Corpus Group 11 needed exactly this. Adding a spelling is adding a scoped `macro_rules`, so the list grows per demand rather than by anticipation.
- **`Space` and `Prop` are unreachable as names.** FH recognises `Space` by name and `Prop`/`Sort` are Lean keywords, so a declaration actually called any of the three cannot be referred to from FH. Nothing in Mathlib is, and the alternative — reserving a token — would cost ambient Lean in the same file more.
- **Named universes must be declared:** `#[universes(u)]` before `Space<u>`. FH turns `autoImplicit` off and that turns universe auto-binding off with it. The unapplied `Space` needs nothing, which is the common case.
- **Comments:** until the M3 standalone `.fh` format, FH lives in `.lean` files — `--` and `/- -/` only; Rust's `//` and `/* */` cannot lex.
- **Nested generics:** `Poly<Fp<P>>` requires the `>`-splitting lexer (I5); until it lands, write `Poly<Fp<P> >`.
- **`while` is not kernel-reducible.** Lean's `while` goes through `Loop.forIn`, so a `while`-based function *runs* (`#eval` sees the answer) but does not compute in the kernel — `rfl` cannot prove anything about it — and `#print axioms` shows `Classical.choice`. A `for` over a list is structural and has neither cost. This is a Lean fact, not an FH choice, but it is the kind of thing worth knowing before reaching for `while` where `for` would do. Battery: `Tests/M2/Statements.lean`.
- **Numeric literals need an ascription when an operator separates them from their type.** `1 / 2` in an `NNReal`-returning body elaborates to `↑((1 : Nat) / (2 : Nat))` — which is *zero*. Lean elaborates both literals at `Nat`, divides, and coerces the result; nothing in `1 / 2` says otherwise. F9's audit rejects it (the coercion is Lean's, not yours), and the spelling is `(1: NNReal) / 2` — F10 ascription, which inserts no coercion. Batteries: `Tests/corpus/g10_pmf.lean`; the ruling is PLAN I4.
- **Non-associativity by decree:** `a < b < c`, `a <-> b <-> c`, and `a in b in c` are parse errors — parenthesize (F7 as amended).
- **Precedence inversion vs Rust:** `!` binds *looser* than comparisons (`!a == b` is `!(a == b)` — the mathematical reading), per the F7 table. Frozen and pinned as goldens at A1.5 (`Tests/M1/Operators.lean`).
- **Operators expand to constants, not to Lean's notations:** `a == b` becomes `Eq a b`, not `a = b`. Lean's relational and arithmetic notations are `binrel%`/`binop%` macros that insert coercions while unifying, and F9 says coercions are written. This is I6's mechanism (`coercion-control.md`) and it is why goldens read `Eq a b`.
