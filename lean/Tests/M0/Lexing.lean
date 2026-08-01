/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M0 · command coexistence and identifier lexing (A0.5, A0.6)

Two platform costs, pinned so they cannot drift silently.

* **Stage:** one (A0.6's check is a stage-one expansion-time check, for the same reason
  F6's is: the parser cannot emit custom wording).
* **Ruling D:** neither is a divergence in FH's *grammar*; both are consequences of
  hosting FH inside `.lean` files. Recorded under "Platform costs" in `differences.md`.
* **Sorry count: zero.**
-/

/-! ## A0.5 — command coexistence

Importing FH reserves its keywords as tokens in the importing file. Two halves have to
hold: ambient Lean must keep working, and the reservation must be real.
-/

/-! ### Ambient Lean still parses and elaborates -/

def plain (n : Nat) : Nat := n + 1
theorem plain_thm : True := trivial
example : plain 1 = 2 := rfl

/-! ### The reservation battery

Keyword reservation is a *parse* fact, so `#guard_msgs` cannot see it: a parse error
inside `#guard_msgs` stops `#guard_msgs` itself from parsing. `#fh_parse` runs the parser
over a string instead and reports the outcome (`FerrisHoward/Test/Parse.lean`).

The control case first — an ordinary name still parses, so the battery below is measuring
reservation and not something else.
-/

/-- info: parses -/
#guard_msgs in
#fh_parse "def ok := 3"

/-- info: parses -/
#guard_msgs in
#fh_parse "theorem t : True := trivial"

/-- info: does not parse: <input>:1:7: expected identifier -/
#guard_msgs in
#fh_parse "def fn := 3"

/-- info: does not parse: <input>:1:11: expected identifier -/
#guard_msgs in
#fh_parse "def struct := 3"

/-- info: does not parse: <input>:1:9: expected identifier -/
#guard_msgs in
#fh_parse "def enum := 3"

/-- info: does not parse: <input>:1:8: expected identifier -/
#guard_msgs in
#fh_parse "def mod := 3"

/-- info: does not parse: <input>:1:8: expected identifier -/
#guard_msgs in
#fh_parse "def use := 3"

/-- info: does not parse: <input>:1:9: expected identifier -/
#guard_msgs in
#fh_parse "def type := 3"

/-- info: does not parse: <input>:1:10: expected identifier -/
#guard_msgs in
#fh_parse "def todo! := 3"

/-! ## A0.6 — identifiers may not end in `?` or `!`

Lean's lexer treats both as identifier characters, so `x?` is *one* identifier and would
never reach FH as `x` followed by the bind operator. FH reserves the suffixes now rather
than teaching its lexer to split them: the consumers are `?`-as-do (A2.3) and `!` (A1.5),
and rejecting today keeps splitting available tomorrow — the reverse would break code.
-/

/-! ### Negative -/

/--
error: FH: `x?` — an identifier may not end in `?` or `!`; Lean's lexer would swallow the operator into the name
-/
#guard_msgs in
fn bind_like() -> Nat { let x? = 1; x? }

/-! The check reaches every identifier position, including the components of a `::` path —
which is where it bites in practice, because Mathlib has names like `Option.get!`. -/

/--
error: FH: `get!` — an identifier may not end in `?` or `!`; Lean's lexer would swallow the operator into the name
-/
#guard_msgs in
fn bang(n: Nat) -> Nat { Option::get!(n) }

/--
error: FH: `named!` — an identifier may not end in `?` or `!`; Lean's lexer would swallow the operator into the name
-/
#guard_msgs in
fn named!() -> Nat { 1 }

/-! ### Span -/

/-- info: error @ +0:29-31 «x?» -/
#guard_msgs in
#fh_spans in
fn bind_like2() -> Nat { let x? = 1; x? }
