/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · structure literals (A2.3, design §4.7)

`Point{ x: 1, y: 2 }` is Lean's structure instance notation, and all three of Rust's forms
already exist there meaning the same thing: named fields, punning (`Point{ x, y }`), and
functional update (`Point{ x: 1, ..p }` → `{ p with x := 1 }`).

* **Stage: one.**
* **Ruling D:** *confined* — the spelling is Rust's and the meaning is Rust's.
* **Sorry count: zero.**

## The type goes inside the literal

`{ x := 1, y := 2 : Point }`, not `({ x := 1, y := 2 } : Point)`. An ascription is a
coercion site, and F9 says coercions are written. The `..p` form needs no type at all: the
base supplies it.

## One restriction: the brace touches the type

FH writes `Point{ x: 1 }`, Rust writes `Point { x: 1 }`. The space is the difference, and
it is load-bearing.

A struct literal makes `{` a *postfix* operator, which is exactly why Rust forbids struct
literals in an `if` condition — after `if p == Point` the next `{` could open the literal
or the block, and Rust cannot tell. FH closes the ambiguity in the lexer instead: no space
means literal, a space means block. That is the same trade FH already makes for calls
(`f(x)`, never `f (x)`) and for generic application (`Vector<T, n>`), for the same reason —
a lexical rule beats a parser that has to guess, and relaxing a restriction later is
non-breaking while the reverse is not (Ruling B). Recorded on the differences page.

The payoff is that FH needs no no-struct-literal rule: the condition below is the one Rust
rejects outright, and it reads fine here.

F11 anticipated this. `corpus-review.md` line 145 rules named call arguments in as
`f(x, modulus: m)` and notes there is "no collision with struct literals (brace-delimited)"
— paren-delimited `name: expr` is an argument, brace-delimited is a field, and that is
still true now that the braces exist.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in structure Point where x : Nat y : Nat -/
#guard_msgs (whitespace := lax) in
#fh_expand struct Point { x: Nat, y: Nat }

struct Point { x: Nat, y: Nat }

/-- info: set_option autoImplicit false in def origin : Point := { x := 0, y := 0 : Point } -/
#guard_msgs (whitespace := lax) in
#fh_expand fn origin() -> Point { Point{ x: 0, y: 0 } }

/-! Punning is Lean's field abbreviation, which is spelled the same way. -/

/--
info: set_option autoImplicit false in
def pun (x : Nat) (y : Nat) : Point := { x := x, y := y : Point }
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn pun(x: Nat, y: Nat) -> Point { Point{ x, y } }

/-! And `..base` is `with base` — no type, because the base carries one. -/

/--
info: set_option autoImplicit false in
def with_x (p : Point) (n : Nat) : Point := { p with x := n }
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn with_x(p: Point, n: Nat) -> Point { Point{ x: n, ..p } }

/-! A generic struct's parameters are **explicit**, as an `enum`'s are: `Wrap<T>` is
`Wrap T`, and writing the argument is what makes the literal's type readable. -/

/-- info: set_option autoImplicit false in structure Wrap (T : Type _) where get : T -/
#guard_msgs (whitespace := lax) in
#fh_expand struct Wrap<T> { get: T }

/-! ## Tier 2 — elaboration -/

fn origin() -> Point { Point{ x: 0, y: 0 } }
fn pun(x: Nat, y: Nat) -> Point { Point{ x, y } }
fn with_x(p: Point, n: Nat) -> Point { Point{ x: n, ..p } }

example : (origin).x = 0 := rfl
example : (pun 1 2).y = 2 := rfl

/-! The update form keeps every field it does not name — that is the whole of what it is
for. -/

example : (with_x (pun 1 2) 9).x = 9 := rfl
example : (with_x (pun 1 2) 9).y = 2 := rfl

/-- info: 'with_x' does not depend on any axioms -/
#guard_msgs in
#print axioms with_x

struct Wrap<T> { get: T }

fn wrap<T>(t: T) -> Wrap<T> { Wrap<T>{ get: t } }

example : (wrap 3).get = 3 := rfl

/-! ### The condition Rust rejects

`if p == Point { … }` is ill-formed Rust — E0658, "struct literals are not allowed here".
FH's `noWs` rule means there is nothing to disambiguate, so it just works. -/

fn is_unit(p: Point) -> Nat { if Point{ x: 1, y: 1 }.x == p.x { 1 } else { 0 } }

example : is_unit (pun 1 5) = 1 := rfl
example : is_unit (pun 2 5) = 0 := rfl

/-! ## Tier 3 — negative

The two errors are Lean's own, at FH's spans, which is what F9's "no invented diagnostics"
asks for: a missing field and a field that is not one.
-/

/-- error: Fields missing: `y` -/
#guard_msgs in
fn missing() -> Point { Point{ x: 0 } }

/-- error: `z` is not a field of structure `Point` -/
#guard_msgs in
fn extra() -> Point { Point{ x: 0, y: 0, z: 0 } }

/-! The space is the restriction, and getting it wrong is a parse error rather than a
different meaning — which is the point of putting the rule in the lexer. `#guard_msgs`
cannot see parse errors, so this goes through the `#fh_parse` harness. -/

/-- info: does not parse: <input>:1:29: expected '}' -/
#guard_msgs in
#fh_parse "fn spaced() -> Point { Point { x: 0, y: 0 } }"

/-! `_` in a header marks an index position (design §4.5), and a struct has none. -/

/--
error: FH: `_` marks an index position, and a struct has none — use an `enum` for an indexed family (design §4.5)
-/
#guard_msgs in
struct Indexed<_: Nat> { get: Nat }

/-! ## Tier 4 — span -/

/-- info: error @ +0:42-43 «z» -/
#guard_msgs in
#fh_spans in
fn extra2() -> Point { Point{ x: 0, y: 0, z: 0 } }
