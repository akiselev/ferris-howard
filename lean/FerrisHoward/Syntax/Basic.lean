/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean

/-!
# FH syntax categories and the M0 core productions (A0.1, A0.2)

Three categories, per `design.md` §4.1 and PLAN A0.1:

* `fh_item` — Rust *items* (`fn`, later `struct`/`enum`/`trait`/`mod`/…);
* `fh_pat` — Rust *patterns* (binding and match positions);
* `fh_expr` — a **single** expression category serving both term and type positions.
  There is deliberately no separate types category: dependency (`Vector<T, n>`) is
  what forces the unification, and maintaining two grammars that must later be
  merged is the mistake design §4.1 exists to prevent.

**FH slots always use FH categories, never Lean's `term`.** A malformed FH construct
must fail inside FH's grammar rather than silently falling through to Lean's, which is
what keeps command coexistence (PLAN §2) honest.

The categories are declared at the root so that quotations read `` `(fh_expr| …) ``;
the *productions* live in the `FerrisHoward` namespace so every FH node kind is
prefixed `FerrisHoward.*` — the golden printer relies on that to know where FH's own
expansion stops (`FerrisHoward/Test/Golden.lean`).

## Precedence

The F7 table (`corpus-review.md`, frozen pre-M1) runs loosest to tightest:
`->`, `<->`, `||`, `&&`, `!`, comparisons, arithmetic, then the tight postfix forms.
M0 has no operators yet — A1.5 fills the middle — so only the two ends exist here:

* **`max`**: identifiers, literals, parentheses, `match`, and the postfix chain
  (call, field, `::` path), which is left-associative and binds tightest;
* **unannotated (loosest)**: `let … ; …` and closures, whose bodies extend as far right
  as possible. `(let x = 1; x).f` therefore needs its parentheses, which is the
  reading Ruling B asks for anyway.
-/

declare_syntax_cat fh_expr
declare_syntax_cat fh_pat
declare_syntax_cat fh_item
declare_syntax_cat fh_fn_body
declare_syntax_cat fh_attr
declare_syntax_cat fh_member

namespace FerrisHoward

/-! ## Shared binder syntax

One angle-bracket parameter list serves both the generics of an item and the binders of a
quantifier — they are the same shape and the same reading.
-/

/-- One angle-bracket generic parameter: `T`, or `n: Nat`.

The annotation parses at `max`, so the closing `>` cannot be stolen by the `>` comparison:
`<n: Nat>` is a parameter list, never `n : (Nat > …)`. Same reason `fhBounds` parses at
`max`. -/
syntax fhGenericParam := Lean.binderIdent (": " fh_expr:max)?

/-! ## Expressions -/

/-- An identifier. -/
syntax:max (name := fhExprIdent) ident : fh_expr

/-- `Prop`, the kind of claims. It needs its own production because `Prop` is a Lean
*keyword* and so never arrives as an identifier. Design §4.3 keeps the spelling as-is: it
already says what it means.

`Space` and `Sort`, the other two kind words (F18), are ordinary identifiers and are
recognised in `expandExpr` rather than here — see the note there. -/
syntax:max (name := fhExprProp) "Prop" : fh_expr

/-- `Sort`, the full-generality kind (F18). Like `Prop` it is a Lean keyword and so never
arrives as an identifier, which is why it needs a production; `Space`, which is not, does
not. `Sort<u>` is the applied form and goes through generic application. -/
syntax:max (name := fhExprSort) "Sort" : fh_expr

/-- A numeric literal. FH introduces no literal syntax of its own: elaboration is
Lean's `OfNat` (Ruling C item five, the landed §9.5 amendment). -/
syntax:max (name := fhExprNum) num : fh_expr

/-- Parenthesised expression. Also the escape hatch Ruling B keeps insisting on. -/
syntax:max (name := fhExprParen) "(" fh_expr ")" : fh_expr

/-- Tuple syntax, which is Lean's **anonymous constructor** by expected type (design §4.7,
Ruling C item two): `(a, b)` is `⟨a, b⟩`, so it introduces a `Prod`, an `Exists` witness, a
`Subtype`'s value-and-proof pair, or any structure, according to what is expected.

Two or more elements: one is the parenthesised expression above, and zero is Lean's `Unit`
spelling, which FH does not have yet. Escape, as everywhere in Ruling C: name the
constructor. -/
syntax:max (name := fhExprTuple) "(" fh_expr ", " fh_expr,+ ")" : fh_expr

/-- Type ascription (F10): `(e: T)` is an elaboration *hint*, and inserts no coercion.
`e as T` is the coercion, and it is a different operator on purpose — Lean spells the two
`(e : T)` and `(↑e : T)`, Rust conflates them into `as`, and Mathlib proofs need
ascription-without-coercion constantly.

The no-coercion half of the promise is not enforced yet: it arrives with A2.0's audit,
which licenses coercions whose syntax ref is an `as` node and flags every other
(`coercion-control.md`). Until then this is Lean's ascription, which can coerce. -/
syntax:max (name := fhExprAscribe) "(" fh_expr ": " fh_expr ")" : fh_expr

/-- One argument in a call: positional, or **named** (F11) — `congruent(x, a, modulus: m)`
is `congruent x a (modulus := m)`.

Rust has no named arguments, so `ident: expr` inside a call is currently ill-formed there
and the syntax was free (corpus-review F11). It does not collide with a structure literal,
which is brace-delimited, or with ascription, which is paren-delimited but has no callee
in front of it. The `atomic` keeps a positional argument that merely *starts* with an
identifier from committing to the named reading. -/
syntax fhCallArg := (atomic(ident ": "))? fh_expr

/-- Call. `noWs` requires the callee and `(` to be adjacent: FH rejects `f (x)`, which
Rust accepts. Restriction, not divergence — relaxing it later is non-breaking, the
reverse is not (Ruling B). Recorded on the differences page. -/
syntax:max (name := fhExprCall) fh_expr:max noWs "(" fhCallArg,* ")" : fh_expr

/-- Field access and method receivers: `p.x`, `x.f(a)`. Maps to Lean's *generalized*
dot notation, which is namespace-directed and so strictly more powerful than Rust's
(design §4.7) — the mechanism lands here at A0.2, the canonical-ASCII-spelling policy
for Mathlib notations (F16) is recorded at A2.1. -/
syntax:max (name := fhExprField) fh_expr:max noWs "." noWs ident : fh_expr

/-- Generic application: `Vector<T, n>`, `Fp<P>`.

`noWs` before `<` is what separates this from a comparison: `Vector<T, n>` is application,
`a < b` is `LT.lt`. F6 closes the remaining gap by requiring a `<` comparison to be
parenthesised — see `FerrisHoward/Expand/Basic.lean`, where the rule is enforced with a
fixed message at an exact span (the parser cannot word it, per the F6 amendment).

Nested generics need a space until I5's `>`-splitting lexer lands: `Poly<Fp<P> >`, because
`>>` is a maximal-munch token. Recorded on the differences page. -/
syntax:max (name := fhExprGeneric) fh_expr:max noWs "<" fh_expr:51,+ ">" : fh_expr

/-- Comprehension braces (F13): `{x: A | P(x)}`.

What it *means* is decided by `fh_comprehension%` below — see
`FerrisHoward/Bridge/Comprehension.lean`. Distinguished from the brace escape by the
`ident ":" … "|"` shape; longest-match suffices, with no lookahead machinery. -/
syntax:max (name := fhExprComprehension) "{" ident ": " fh_expr " | " fh_expr "}" : fh_expr

/-- The election hook for comprehension braces: a `macro_rules` decides whether
`{x: A | P}` is a `Set` or a `Subtype`.

The indirection is the point. F13 was amended to elect by *expected type*, which stage one
cannot see, and there are three ways to get there — a stage-two elaborator, a class with
an `outParam`, or an explicit import. They differ in what they cost, not in what they do,
and all three are one `macro_rules` on this node. Swapping the decision does not touch the
grammar, the expander, or any fixture that does not test the decision itself. -/
syntax (name := fhComprehensionTerm) "fh_comprehension% " term:max : term

/-- The brace escape: `Vector<T, {n*2}>` (design §4.1, Rust's const-generic braces, which
Rust programmers already know).

Generic arguments parse *above* the comparison band, so `Fin<n+1>` works and the closing
`>` is never stolen — but anything at or below a comparison needs the braces. -/
syntax:max (name := fhExprBrace) "{" fh_expr "}" : fh_expr

/-- `e?` — Rust's `?` operator, which *is* monadic bind (design §4.7).

A block containing one elaborates as a `do` block, and `let x = f()?;` becomes
`let x ← f`. The monad comes from the block's expected type, which a declared return type
always supplies — Ruling C item three, escape: ascribe.

`noWs` matters here for a reason A0.6 already fixed: Lean's lexer takes `x?` as a single
identifier, so `?` can only follow something that ends in a delimiter — `f()?`, `(e)?` —
which is how every use in corpus Group 10 is written anyway. -/
syntax:max (name := fhExprTry) fh_expr:max noWs "?" : fh_expr

/-- Path: `Nat::succ`, `N::Zero`. `::` joins identifiers into one Lean name — design §6's
no-mangling policy means Mathlib names are reachable verbatim as `Nat::Prime::dvd_mul`. -/
syntax:max (name := fhExprPath) fh_expr:max "::" ident : fh_expr

/-- A field in a structure literal: `x: e`, or bare `x` for Rust's field punning, which
Lean spells the same way and means the same thing. -/
syntax fhStructLitField := ident (": " fh_expr)?

/-- Structure literal: `Point{ x: 1, y: 2 }` → `{ x := 1, y := 2 : Point }` (design §4.7).

The type is carried into the literal rather than ascribed onto it, because an ascription
would be a coercion site and F9 says coercions are written.

**This is the production that makes braces postfix**, which is what makes Rust forbid
struct literals in `if` conditions — `if x Foo { }` is ambiguous there. FH closes it with
`noWs` instead: the brace must touch the type, `Point{ x: 1 }`, so `if cond { … }` with
its space is never a literal.

That is a restriction (Rust writes the space) and it is the same one FH already makes for
calls, for the same reason: a lexical rule beats a parser that has to guess, and relaxing
it later is non-breaking. Recorded on the differences page.

All three of Rust's forms are here, because each already exists in Lean and means the
same thing: named fields, punning (`Point{ x, y }`), and functional update
(`Point{ x: 1, ..p }` → `{ p with x := 1 }`). -/
syntax:max (name := fhExprStructLit)
  fh_expr:max noWs " { " fhStructLitField,*,? (".." fh_expr)? " } " : fh_expr

/-- `match e { p => e, … }`. Trailing comma allowed, as in Rust. -/
syntax fhMatchArm := fh_pat " => " fh_expr

@[inherit_doc fhMatchArm]
syntax:max (name := fhExprMatch) "match " fh_expr " { " fhMatchArm,*,? " }" : fh_expr

/-- Universal quantification: `for<x: Nat> P(x)` is `∀ x : Nat, P x` (design §4.2,
generalising Rust's higher-ranked `for<'a>`).

Binder lists follow F2: **a type ascription distributes over the unascribed prefix**, so
`for<a, b, c: Self>` binds all three at `Self`. Rust's generic lists bound only the last,
which makes this a deliberate, loudly documented divergence.

The body extends as far right as possible (F7 iv): `for<x: T> P && Q` is
`for<x: T> (P && Q)`, and conjoining from outside means parenthesising the quantifier. -/
syntax (name := fhExprForall) "for" "<" fhGenericParam,+ ">" fh_expr : fh_expr

/-- Existential quantification, the dual of `for<>` (design §4.2).

`exists` with a data-valued body elects `Sigma`/`Subtype` by expected type — Ruling C item
four, stage two, and not yet implemented: this production always builds `Exists`. -/
syntax (name := fhExprExists) "exists" "<" fhGenericParam,+ ">" fh_expr : fh_expr

/-- `if cond { a } else { b }` → Lean's `if`, which for a Prop condition is the
**decidable** `if` (F14) — Ruling A's one real cost, and Lean's own semantics.

`if h @ (cond) { … } else { … }` binds the hypothesis (F15), reusing Rust's `@`
pattern-binding: `h : cond` in the first branch, `h : ¬cond` in the second.

The condition needs no restriction against `{`: a brace expression can only *start* an
expression, never extend one, so a condition that has already parsed cannot swallow the
block. Rust needs its no-struct-literal rule because struct literals are postfix; FH's
braces are not. -/
syntax:max (name := fhExprIf) "if " (atomic(ident " @ "))? fh_expr
  " { " fh_expr " } " " else " " { " fh_expr " } " : fh_expr

/-- Closure. Closures *are* lambdas (design §3), which is load-bearing for §4.2's
quantifiers and for big operators (`Finset::range(n).sum(|k| …)`).

Zero-argument closures (`|| e`) are not FH syntax: `||` is a single token. Restriction,
recorded on the differences page. -/
syntax (name := fhExprClosure) "|" fh_pat,+ "|" fh_expr : fh_expr

/-- `lean! { tactics }` → `by tactics` (design §4.8, A1.7).

The one place an FH slot is *not* an FH category: the interior is Lean's own tactic
parser, which is the entire point of an escape hatch — full Mathlib tactic access and a
working InfoView, for free. -/
syntax:max (name := fhExprLean) "lean!" " { " Lean.Parser.Tactic.tacticSeq " } " : fh_expr

/-- The method-spelling hook: `x.m` expands to `fh_dot% x m` and a `macro_rules` decides
what it means (F16, `FerrisHoward/Bridge/`).

The default rule is plain dot notation, so nothing changes unless a bridge is *in scope* —
and a bridge is brought into scope by `use lean::C;`, which is Rust's own rule: a trait's
methods are callable when the trait is imported. Scoped `macro_rules` implement it
directly, in stage one, with no global table and no environment access.

Not FH surface syntax; it exists so the decision has somewhere to live. -/
syntax (name := fhDotTerm) "fh_dot% " term:max ident : term

/-- `todo!()` / `todo!("msg")` → `sorry`, with the message logged (design §3). -/
syntax:max (name := fhExprTodo) "todo!" noWs "(" (str)? ")" : fh_expr


/-- `let x = e; rest`, with an optional annotation. Plain `let` stays pure — the
`?`-flavoured monadic form is A2.3. -/
syntax (name := fhExprLet) "let " fh_pat (": " fh_expr:1)? " = " fh_expr "; " fh_expr : fh_expr

/-! ## Imperative statements (A2.3, design §4.7 and §5)

Design §4.7: "`for`/`while`/`if` inside such blocks map to Lean's do-notation control
flow, which was itself designed to imperative-language expectations." And §5, on what FH
drops: "`mut` (no mutation outside do-notation's `let mut`, which Lean's do-notation
supports natively and we map directly)".

So these are not new semantics — each is Lean's own `doElem`, reached by the spelling a
Rust programmer would use. A body containing any of them *is* a `do` block, by the same
whole-body rule `?` already uses, and for the same reason: the monad has to come from the
declared return type.

Each statement carries its continuation, the shape `let` already has. That is what keeps
the grammar a single expression category (§4.1) with no statement category to keep in
sync — a block is an expression whose tail is its value.

The continuation is *optional*, which is Rust's rule: a block ending in `;` has no value.
`for i in xs { acc = acc + i; }` is the shape that needs it, and it is the shape everyone
writes. A `fn` body that ends this way has no value either, and Lean says so.

`break`, `continue` and `return e` are *tails* rather than statements: they end the block
they are in, so there is nothing to continue with. `if found { return x } rest` is the
shape that wants this, and it works because the `if` supplies the continuation.
-/

/-- `let mut x = e; rest` → `let mut x := e` (design §5). Separate from plain `let`
because mutation is worth seeing at the binding site, which is Rust's judgement too. -/
syntax:0 (name := fhExprLetMut) "let " "mut " fh_pat (": " fh_expr:1)? " = " fh_expr "; "
  (fh_expr)? : fh_expr

/-- Assignment: `x = e; rest` → `x := e`.

The left side is an identifier. Rust also assigns through a field or an index (`p.x = e`,
`v[i] = e`); those are restrictions, not divergences — recorded on the differences page,
and reachable meanwhile by rebuilding: `p = Point{ x: e, ..p };`. -/
syntax:0 (name := fhExprAssign) ident " = " fh_expr "; " (fh_expr)? : fh_expr

/-- `for x in coll { body } rest` → Lean's `for x in coll do …`.

Distinguished from the `for<x: T> P` quantifier by what follows `for`: an angle bracket
binds, a pattern iterates. Rust reads both the same way. -/
syntax:0 (name := fhExprFor) "for " fh_pat " in " fh_expr " { " fh_expr " } " (fh_expr)? : fh_expr

/-- `while cond { body } rest` → Lean's `while cond do …`. The condition is a `Bool`,
which is Lean's rule for `while` and Rust's for everything. -/
syntax:0 (name := fhExprWhile) "while " fh_expr " { " fh_expr " } " (fh_expr)? : fh_expr

/-- `if cond { body } rest` — the *statement* `if`, which has no `else` and so no value.

The expression `if` (`fhExprIf`) requires one, because an expression must have a value in
both branches; this form is the do-notation one, where the else-branch is "carry on". Rust
draws the same line, and the parser picks between them by whether `else` follows. -/
syntax:0 (name := fhExprIfStmt) "if " fh_expr " { " fh_expr " } " (fh_expr)? : fh_expr

/-- `break` — Lean's `break`, inside a `for` or `while`. -/
syntax:0 (name := fhExprBreak) "break" : fh_expr

/-- `continue` — Lean's `continue`, inside a `for` or `while`. -/
syntax:0 (name := fhExprContinue) "continue" : fh_expr

/-- `return e` — Lean's `return`, which leaves the whole `do` block.

This is the one place FH lifts into the monad without being asked, and it is not an
exception to Ruling C: `return` *is* `pure` in do-notation, in Lean as in Rust's `?`
desugaring, and writing it is the request. -/
syntax:0 (name := fhExprReturn) "return " fh_expr : fh_expr

/-! ## Operators (Ruling A, F7)

One meaning everywhere: `==`/`!=` are `Eq`/`Ne`, `&& || !` are `∧ ∨ ¬`, `->` is
implication, `<->` is `Iff`, `<= < > >=` are the order relations, `in` is `∈` — all
Props, unconditionally. `Bool` is an ordinary type reached explicitly (`decide(p)`, which
needs no syntax of its own: it is a call).

The F7 table, frozen pre-M1, loosest to tightest, with the precedences used here:

| level | operators | associativity |
|---|---|---|
| 25 | `->` | right |
| 27 | `<->` | **non**-associative |
| 30 | `||` | left |
| 35 | `&&` | left |
| 40 | `!` (prefix) | — |
| 50 | `==` `!=` `<` `<=` `>` `>=` `in` | **non**-associative |
| 65 | `+` `-` | left |
| 70 | `*` `/` `%` | left |
| 75 | `-` (prefix) | — |
| max | call, field, `::` | left |

Two rows are worth reading twice. `!` binds *looser* than comparisons, so `!a == b` is
`¬(a = b)` — the mathematical reading, and an inversion of Rust's table. And the
comparison band is non-associative: `a < b < c` and `a in b in c` are parse errors, the
classic math-notation trap closed by decree (Ruling B).
-/

/-- Implication — the function arrow, available in every expression position (F3). -/
syntax:25 (name := fhExprArrow) fh_expr:26 " -> " fh_expr:25 : fh_expr

/-- `Iff` (F4). Non-associative: chained iff is the same trap as chained comparison. -/
syntax:27 (name := fhExprIff) fh_expr:28 " <-> " fh_expr:28 : fh_expr

/-- Disjunction. -/
syntax:30 (name := fhExprOr) fh_expr:30 " || " fh_expr:31 : fh_expr

/-- Conjunction. -/
syntax:35 (name := fhExprAnd) fh_expr:35 " && " fh_expr:36 : fh_expr

/-- Negation. Looser than the comparisons, so `!a == b` is `¬(a = b)`. -/
syntax:40 (name := fhExprNot) "!" fh_expr:40 : fh_expr

/-- Propositional equality. -/
syntax:50 (name := fhExprEq) fh_expr:51 " == " fh_expr:51 : fh_expr

/-- Propositional disequality. -/
syntax:50 (name := fhExprNe) fh_expr:51 " != " fh_expr:51 : fh_expr

/-- `≤`. -/
syntax:50 (name := fhExprLe) fh_expr:51 " <= " fh_expr:51 : fh_expr

/-- `<`. -/
syntax:50 (name := fhExprLt) fh_expr:51 " < " fh_expr:51 : fh_expr

/-- `≥`. -/
syntax:50 (name := fhExprGe) fh_expr:51 " >= " fh_expr:51 : fh_expr

/-- `>`. -/
syntax:50 (name := fhExprGt) fh_expr:51 " > " fh_expr:51 : fh_expr

/-- Membership (F12): `x in s` is `x ∈ s`. Rust reserves `in` but uses it only in loop
headers, and FH's quantifiers are bracketed, so the spelling is free. -/
syntax:50 (name := fhExprIn) fh_expr:51 " in " fh_expr:51 : fh_expr

/-- Coercion (F9): `e as T` is `(↑e : T)`, and it is the **only** licensed way for a
coercion to appear in FH-elaborated code — A2.0's audit flags every other one.

Distinct from ascription on purpose (F10): `(e: T)` hints, `e as T` converts. Lean spells
them `(e : T)` and `(↑e : T)`; Rust conflates both into `as`; FH keeps them separable
because Mathlib proofs need ascription-without-coercion constantly.

Precedence follows Rust — tighter than `*`, looser than unary `-` — which the F7 table did
not cover, since `as` is not one of its rows. -/
syntax:72 (name := fhExprAs) fh_expr:72 " as " fh_expr:73 : fh_expr

/-- Addition. -/
syntax:65 (name := fhExprAdd) fh_expr:65 " + " fh_expr:66 : fh_expr

/-- Subtraction. -/
syntax:65 (name := fhExprSub) fh_expr:65 " - " fh_expr:66 : fh_expr

/-- Multiplication. -/
syntax:70 (name := fhExprMul) fh_expr:70 " * " fh_expr:71 : fh_expr

/-- Division. -/
syntax:70 (name := fhExprDiv) fh_expr:70 " / " fh_expr:71 : fh_expr

/-- Remainder. -/
syntax:70 (name := fhExprMod) fh_expr:70 " % " fh_expr:71 : fh_expr

/-- Negation of a number. -/
syntax:75 (name := fhExprNeg) "-" fh_expr:75 : fh_expr

/-! ## Patterns -/

/-- A binding pattern (in match position, a lowercase name binds; a resolvable one is a
constructor — Lean's rule, inherited). -/
syntax:max (name := fhPatIdent) ident : fh_pat

/-- The wildcard pattern: `fn f(_: Nat)`, `_ => …`. -/
syntax:max (name := fhPatHole) "_" : fh_pat

/-- A literal pattern. -/
syntax:max (name := fhPatNum) num : fh_pat

/-- A constructor path in pattern position: `N::Zero`. -/
syntax:max (name := fhPatPath) fh_pat:max "::" ident : fh_pat

/-- A constructor application in pattern position: `N::Succ(k)`. -/
syntax:max (name := fhPatCtor) fh_pat:max noWs "(" fh_pat,* ")" : fh_pat

/-! ## Attributes

`#[attr]` → `@[attr]` (design §3). Arguments are FH expressions, because the attributes
that take them take *FH* things: `#[terminates_by(b)]`, `#[universes(u, v)]`,
`#[name(foo)]`. A few attribute names are consumed by FH rather than passed through —
`#[def]` at A0.3 — and the rest pass through by name.

Attribute names that are Lean *keywords* cannot be identifiers, so each gets its own
production. `#[def]` and `#[instance]` are the two M0 needs; `#[partial]`,
`#[noncomputable]` and `#[opaque]` arrive with A2.2, which is also where they stop being
attributes and become definition modifiers. -/
/-- An attribute, optionally applied to FH expressions: `#[simp]`, `#[terminates_by(b)]`. -/
syntax (name := fhAttrIdent) ident ("(" fh_expr,*,? ")")? : fh_attr

/-- `#[def]`: the `type` opt-out, `abbrev` → `def` (design §3). -/
syntax (name := fhAttrDef) "def" : fh_attr

/-- `#[instance]`, passed through as `@[instance]`. -/
syntax (name := fhAttrInstance) "instance" : fh_attr

/-- `#[decreasing_by(lean! { … })]` (design §4.6). Its own production because
`decreasing_by` is a Lean keyword and so never arrives as an identifier. -/
syntax (name := fhAttrDecreasingBy) "decreasing_by" "(" fh_expr ")" : fh_attr

/-- `#[partial]` → `partial def`: no induction principle, and design §4.6 says to teach
that loudly. Its own production — another Lean keyword. -/
syntax (name := fhAttrPartial) "partial" : fh_attr

/-- `#[noncomputable]` → `noncomputable def`, the specification-not-program marker. -/
syntax (name := fhAttrNoncomputable) "noncomputable" : fh_attr

/-- `#[opaque]` → an `opaque` declaration: a value exists, and nothing may look at it. -/
syntax (name := fhAttrOpaque) "opaque" : fh_attr

/-- An attribute group: `#[simp]`, `#[simp, ext]`. -/
syntax fhAttrs := "#[" fh_attr,*,? "]"

/-! ## Items

### Shared binder syntax

Angle-bracket generics, `+`-separated bounds, and `where` clauses are used by several item
forms, so they are declared once here.
-/

/-- Angle-bracket generics. They become **implicit** binders (design §4.2), which is the
Rust intuition exactly: generics are inferred at call sites as Lean implicits are. A bare
`<T>` defaults to `Type _` (design §4.3's `Space<_>`; the `Space` spelling itself is
A2.4). -/
syntax fhGenerics := "<" fhGenericParam,*,? ">"

/-- A `+`-separated bound list: `B1 + B2`. Bounds parse at `max` so that `+` stays the
separator once A1.5 makes it an operator — `B1 + B2` is two bounds, never one sum. -/
syntax fhBounds := sepBy1(fh_expr:max, " + ")

/-- One `where` bound: `T: Grp`, `R: CommRing + Finite`. -/
syntax fhWhereBound := ident ": " fhBounds

/-- A `where` clause. Bounds become **instance** binders — again the Rust intuition, since
you never pass a trait impl explicitly there either. -/
syntax fhWhere := " where " fhWhereBound,+

/-- The body of an `fn`: an expression block. -/
syntax (name := fhFnBodyExpr) " { " fh_expr " }" : fh_fn_body

/-- A bodyless `fn`, ending in `;`: elaborates to a `sorry`-backed definition
(design §3). Axioms are `extern "axiom"` (§4.6), not this. -/
syntax (name := fhFnBodyNone) ";" : fh_fn_body

/-- `fn name(p: T, …) -> R { e }` → `def name (p : T) … : R := e`, and
`fn name(…) -> R;` → the same with `:= sorry`.

Two bodies rather than two `fn` productions: distinct leading tokens (`{` vs `;`) keep
the grammar backtrack-free, which is Ruling B's scope note. -/
syntax (name := fhFn) "fn " ident (fhGenerics)? "(" (fh_pat ": " fh_expr),* ")"
  " -> " fh_expr (fhWhere)? fh_fn_body : fh_item

/-- `theorem name(args) -> conclusion { proof }` → `theorem name (args) : conclusion := proof`.

The `theorem` keyword is mandatory and there is no Prop-detection of `fn`s (the corpus
review's standing decision, design §3). FH's `theorem` coexists with Lean's own by
longest-match dispatch at the command boundary — verified on-toolchain, and the reason
plain Lean `theorem` still parses in an FH file. -/
syntax (name := fhTheorem) "theorem " ident (fhGenerics)? "(" (fh_pat ": " fh_expr),* ")"
  " -> " fh_expr (fhWhere)? fh_fn_body : fh_item

/-- `struct S { a: T, b: U }` → `structure S where a : T; b : U`, and
`struct S: B1 + B2 { … }` → `structure S extends B1, B2 where …` (design §3's trait row,
which §4.5 extends to plain structs). -/
syntax (name := fhStruct) "struct " ident (fhGenerics)? (": " fhBounds)?
  " { " (ident ": " fh_expr),*,? " } " : fh_item

/-- One field of an `enum` variant: `pred: N`, or an unnamed type.

`atomic` is a two-token lookahead, not a backtracking parser: it is what distinguishes
`Succ(pred: N)` from `Cons(Nat)`, and it is exactly what Lean's own `structParent` does
for the same shape. Ruling B's concern is the *expression* grammar, where a backtrack
would become an ambiguity report. -/
syntax fhEnumField := (atomic(ident ": "))? fh_expr

/-- One `enum` variant: `Zero`, `Succ(pred: N)`, `Cons(T)`, and — for an indexed family —
`Cons<n: Nat>(head: T, tail: Vector<T, n>) -> Vector<T, n + 1>` (design §4.5).

A per-variant return type is what declares the index; absent one, the variant targets the
uniform type, which is an ordinary Rust enum. -/
syntax fhEnumVariant := ident (fhGenerics)? ("(" fhEnumField,*,? ")")? (" -> " fh_expr)?

/-- `enum E { A(T), B }` → `inductive E where | A : T → E | B : E`, and with a header
`enum Vector<T, _: Nat>` the `_` marks an **index** position — varying per constructor —
against `T`, which is a uniform parameter (design §4.5). -/
syntax (name := fhEnum) "enum " ident (fhGenerics)? " { " fhEnumVariant,*,? " } " : fh_item

/-- `mutual { … }` → Lean's `mutual … end` (design §4.5): several declarations that refer
to one another. -/
syntax (name := fhMutual) "mutual " " { " fh_item* " } " : fh_item

/-- `mod m { … }` → `namespace m … end m`. -/
syntax (name := fhMod) "mod " ident " { " fh_item* " } " : fh_item

/-- `use a::b;` → `open a.b`. Rust-style renaming at use sites is M2 bridge work. -/
syntax (name := fhUse) "use " fh_expr ";" : fh_item

/-! ### Ambient variables (A2.4, F17, design §4.8)

`var eps: Real;` is Lean's `variable`, which *is* F17's mention-based inclusion: a
declaration gets an ambient variable exactly when it mentions it, and `include` is the
escape for a hypothesis that is needed but unmentioned. Both are Lean commands, so both
are stage one and free.

**The annotation decides the binder.** A *carrier* — a kind (`Space`, `Sort`, `Prop`) or a
structure (`impl Grp`) — is implicit, matching what `fn f<G>(…)` already produces and what
Mathlib writes; anything else is an explicit value or hypothesis. That rule is what makes
design §4.8's "inline generics shadow ambient `var`s" mean the same thing on both sides.

**One deviation from design §4.8, and it is reversible.** Design writes the structure form
as `var G: Grp;` and disambiguates it from `var eps: Real;` "by what the name resolves
to". Name resolution needs the environment, which is stage two, and ADR-006 makes stage
one load-bearing — so FH asks for the marker instead. `impl Grp` is Rust's own vocabulary
with its actual Rust meaning ("some type implementing `Grp`"), design §5 having dropped
`impl Trait` from return position, so the token was free. When a resolution mechanism
exists the marker becomes *optional* rather than required, which is a non-breaking change
— Ruling B's test, and the reason to require it now rather than guess.
-/

/-- `var x: T;` — an ambient variable. The annotation is a type expression or a kind. -/
syntax (name := fhVar) "var " ident ": " fh_expr ";" : fh_item

/-- `var G: impl Grp;` / `var R: impl CommRing + Finite;` — an ambient *carrier* with
structure: `variable {G : Type _} [Grp G]`. -/
syntax (name := fhVarImpl) "var " ident ": " "impl " fhBounds ";" : fh_item

/-- `include h;` — F17's escape, for a hypothesis a declaration needs but does not
mention. Lean's own command, with Lean's own rule. -/
syntax (name := fhInclude) "include " ident,+ ";" : fh_item

/-- `type X = e;` → `abbrev X := e`, or `def` under `#[def]` (design §3). -/
syntax (name := fhType) "type " ident " = " fh_expr ";" : fh_item

/-! ### Traits and impls (A1.6)

A trait body and an impl body hold the same two shapes, so they share one category: a
**method** (`fn`, with or without a body) and a **field** (`name: value;`). What the two
mean differs by context — in a trait a method is a field declaration and a bodyless one is
an obligation; in an impl both are the values that discharge them. -/

/-- A method: a field whose type is a function. In a trait, a body is the field's default
value (design §4.4); in an impl, it is the implementation. -/
syntax (name := fhMemberFn) "fn " ident (fhGenerics)? "(" (fh_pat ": " fh_expr),* ")"
  " -> " fh_expr fh_fn_body : fh_member

/-- A field. In a trait, `assoc: <prop>;` is design §4.4's **laws-as-fields** — a proof
obligation every `impl` carries. In an impl it is the value discharging one, which may be
a term, a `lean! { }` block, or `todo!()`. -/
syntax (name := fhMemberField) ident ": " fh_expr ";" : fh_member

/-- `trait C<Self> { … }` → `class C (Self : Type _) where …`.

Three deltas from Rust, all design §4.4: laws are fields; the carrier is an explicit class
parameter (so generics here become *explicit* binders, unlike on a `fn`); and extra
parameters are just more generics, which is how multi-parameter classes like `Module<R,
Self>` arrive. Supertraits become `extends`, with each parent applied to the carrier. -/
syntax (name := fhTrait) "trait " ident (fhGenerics)? (": " fhBounds)? (fhWhere)?
  " { " fh_member* " } " : fh_item

/-- `impl C for T { … }` → `instance : C T := { … }`, named by `#[name(…)]` when it needs
a name. Rust's coherence and orphan rules do not carry over — Lean has none and Mathlib
depends on that (design §4.4). -/
syntax (name := fhImpl) "impl " fh_expr:max " for " fh_expr:max (fhWhere)?
  " { " fh_member* " } " : fh_item

/-- `extern "axiom" { fn choice(…) -> …; }` → `axiom` declarations (design §4.6).

Both cute and semantically honest: an axiom is exactly a function whose implementation
lives outside the language. Items inside must be bodyless — a body would be an
implementation, which is the thing an axiom does not have. -/
syntax (name := fhExtern) "extern " str " { " fh_item* " } " : fh_item

/-- An item carrying attributes. A separate production rather than an optional prefix on
every item, so each production keeps a distinct leading token and the grammar stays
backtrack-free (Ruling B). -/
syntax (name := fhItemAttrs) fhAttrs fh_item : fh_item

/-! ## The command entry point

Per-declaration commands, not a monolithic `rust { }` block (design §2). Lifting the
whole item category to `command` in one production keeps a single dispatch point for
stage one; verified on-toolchain that plain Lean commands in the same file are
unaffected (PLAN §2's longest-match dispatch fact). -/
syntax (name := fhItemCommand) fh_item : command

end FerrisHoward
