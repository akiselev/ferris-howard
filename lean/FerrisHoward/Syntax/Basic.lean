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
syntax fhGenericParam := ident (": " fh_expr:max)?

/-! ## Expressions -/

/-- An identifier. -/
syntax:max (name := fhExprIdent) ident : fh_expr

/-- `Prop`, the kind of claims. It needs its own production because `Prop` is a Lean
*keyword* and so never arrives as an identifier. Design §4.3 keeps the spelling as-is: it
already says what it means. (`Space`, F18's replacement for `Type`, is an ordinary
identifier and arrives with A2.4.) -/
syntax:max (name := fhExprProp) "Prop" : fh_expr

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

/-- Call. `noWs` requires the callee and `(` to be adjacent: FH rejects `f (x)`, which
Rust accepts. Restriction, not divergence — relaxing it later is non-breaking, the
reverse is not (Ruling B). Recorded on the differences page. -/
syntax:max (name := fhExprCall) fh_expr:max noWs "(" fh_expr,* ")" : fh_expr

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

/-- The brace escape: `Vector<T, {n*2}>` (design §4.1, Rust's const-generic braces, which
Rust programmers already know).

Generic arguments parse *above* the comparison band, so `Fin<n+1>` works and the closing
`>` is never stolen — but anything at or below a comparison needs the braces. -/
syntax:max (name := fhExprBrace) "{" fh_expr "}" : fh_expr

/-- Path: `Nat::succ`, `N::Zero`. `::` joins identifiers into one Lean name — design §6's
no-mangling policy means Mathlib names are reachable verbatim as `Nat::Prime::dvd_mul`. -/
syntax:max (name := fhExprPath) fh_expr:max "::" ident : fh_expr

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
syntax (name := fhExprLet) "let " fh_pat (": " fh_expr)? " = " fh_expr "; " fh_expr : fh_expr

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
syntax (name := fhFn) "fn " ident (fhGenerics)? "(" (fh_pat ": " fh_expr),* ")" " -> " fh_expr (fhWhere)? fh_fn_body : fh_item

/-- `theorem name(args) -> conclusion { proof }` → `theorem name (args) : conclusion := proof`.

The `theorem` keyword is mandatory and there is no Prop-detection of `fn`s (the corpus
review's standing decision, design §3). FH's `theorem` coexists with Lean's own by
longest-match dispatch at the command boundary — verified on-toolchain, and the reason
plain Lean `theorem` still parses in an FH file. -/
syntax (name := fhTheorem) "theorem " ident (fhGenerics)? "(" (fh_pat ": " fh_expr),* ")" " -> " fh_expr (fhWhere)? fh_fn_body : fh_item

/-- `struct S { a: T, b: U }` → `structure S where a : T; b : U`, and
`struct S: B1 + B2 { … }` → `structure S extends B1, B2 where …` (design §3's trait row,
which §4.5 extends to plain structs). -/
syntax (name := fhStruct) "struct " ident (": " fhBounds)?
  " { " (ident ": " fh_expr),*,? " } " : fh_item

/-- One field of an `enum` variant: `pred: N`, or an unnamed type.

`atomic` is a two-token lookahead, not a backtracking parser: it is what distinguishes
`Succ(pred: N)` from `Cons(Nat)`, and it is exactly what Lean's own `structParent` does
for the same shape. Ruling B's concern is the *expression* grammar, where a backtrack
would become an ambiguity report. -/
syntax fhEnumField := (atomic(ident ": "))? fh_expr

/-- One `enum` variant: `Zero`, `Succ(pred: N)`, `Cons(T)`. -/
syntax fhEnumVariant := ident ("(" fhEnumField,*,? ")")?

/-- `enum E { A(T), B }` → `inductive E where | A : T → E | B : E`. Plain (unindexed)
enums only; per-variant return types for indexed families are A2.2. -/
syntax (name := fhEnum) "enum " ident " { " fhEnumVariant,*,? " } " : fh_item

/-- `mod m { … }` → `namespace m … end m`. -/
syntax (name := fhMod) "mod " ident " { " fh_item* " } " : fh_item

/-- `use a::b;` → `open a.b`. Rust-style renaming at use sites is M2 bridge work. -/
syntax (name := fhUse) "use " fh_expr ";" : fh_item

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
