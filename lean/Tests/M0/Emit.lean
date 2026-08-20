/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M0 · `emit-lean` and the emittable lint (ADR-006 / `research/codegen.md` §2)

FH constructs are syntax → syntax macros, so the publication artifact is one
macro-expansion step plus a formatter. `#fh_emit` is that step for a single item;
`lake exe fh_emit <file>` is the whole-file program, and `scripts/round-trip.py` is the
gate that proves the artifact states what we proved.

* **Stage: one**, necessarily — that is the discipline this file tests.
* **Sorry count: zero.**

The invariant, stated so it can fail loudly: **no FH node kind may survive expansion.** If
one does, the construct cannot be published, and the lint says so at the point the
construct is written rather than at the point a referee asks for the file.
-/

/-! ## Emission is the expansion

`#fh_emit` and `#fh_expand` agree by construction — they are the same expander. A golden
is therefore a preview of the emitted artifact.
-/

/--
info: set_option autoImplicit false in
def double (n : Nat) : Nat :=
  Nat.add n n
-/
#guard_msgs (whitespace := lax) in
#fh_emit fn double(n: Nat) -> Nat { Nat::add(n, n) }

/-! Multi-command items emit as several declarations, in order. -/

/--
info: namespace inner
set_option autoImplicit false in
def two : Nat :=
  2
end inner
-/
#guard_msgs (whitespace := lax) in
#fh_emit mod inner { fn two() -> Nat { 2 } }

/-! ## The lint has teeth

The failure mode is not "a construct with no macro" — that already errors, loudly, in the
expander. It is a construct whose macro *succeeds* while leaving FH syntax behind, so the
expansion looks fine and the artifact silently depends on FH.

That is not hypothetical: `todo!` did exactly this until ADR-006, expanding to an
FH-provided `fh_todo%` term. The construct below reproduces it deliberately, so the lint
that now prevents it has something to catch.
-/

namespace FerrisHoward

/-- A term only FH provides — the shape of the historical `fh_todo%`. -/
syntax (name := fhLeftover) "fh_leftover%" : term

/-- An item whose macro succeeds while leaving FH syntax in its expansion. -/
syntax (name := fhLeaky) "leaky! " ident : fh_item

macro_rules
  | `(command| leaky! $n:ident) => `(command| def $n : Nat := fh_leftover%)

end FerrisHoward

/--
error: FH: `FerrisHoward.fhLeftover` does not expand to Lean surface syntax, so it cannot be emitted. Give it an expander, or keep it out of the publishable subset.
-/
#guard_msgs in
#fh_emit leaky! leaks
