/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M3 · `fh_expr` is extensible, and two bugs that hid behind it

Groundwork for `notation!`, and the fixture for three fixes that a design study turned up
before a line of `notation!` existed.

* **Stage: one.** `Macro.expandMacro?` is ordinary `MacroM` — no elaborator, no
  environment access beyond what any `macro_rules` already has.
* **Sorry count: zero.**

## The extension point

`expandExpr` used to reject any `fh_expr` production it did not recognise. Now it gives it
one chance to be a macro first, which is exactly how Lean's own `term` category behaves.
That single line is what makes the category extensible from outside `Expand/Basic.lean` —
and it is what `notation!` will be built on, since a `notation!` declaration is nothing but
an `fh_expr` production plus a macro for it.

## Three bugs, none of which needed `notation!` to bite

Two were latent and would have been found the hard way.

**1. `::` from a quotation panicked.** `joinPath` builds a name with `Name.append`, which
*panics* when both arguments carry macro scopes — and an identifier arriving from a
quotation carries them. Any FH-emitting macro that wrote `Nat::succ(x)` would have crashed
rather than errored. Erasing scopes is right rather than merely safe: `::` names a global
by construction, and a global is never hygienic.

**2. `use lean::Dvd;` leaked `open FerrisHoward.Bridge.Dvd` into the emitted artifact.**
ADR-006 says the artifact carries no FH dependency, and that `open` is one. The round-trip
gate would have caught it — but only for a file that uses a bridge, and the gate's only
case was bridge-free. Both the emitter and the gate are fixed; corpus Group 12 is now a
round-trip case precisely because it uses two bridges.

**3. The dot-notation bridges match on hygienic idents.** A method name reaching
`fh_dot%` from a quotation carries scopes, so a bridge pattern written `` `(fh_dot% $x
dvd) `` does not fire on it. The default rule now erases scopes before rebuilding the
dotted name, which is what makes a bridged spelling work from inside a macro.
-/

/-! ## Tier 1 — the extension point

An ordinary `macro` into `fh_expr` now works, and FH expands its result as if it had
written it.

Splicing into *call* position needed one addition. F11 made a call argument its own node
(`fhCallArg`), so `` `(fh_expr| f($x)) `` did not typecheck for an `fh_expr` `$x` — every
macro that builds a call would have hit it. A `CoeHTCT` in the grammar file fixes it once
rather than in each macro.
-/

open Lean in
macro "twice(" n:fh_expr ")" : fh_expr => `(fh_expr| $n + $n)

/-- info: set_option autoImplicit false in def four : Nat := HAdd.hAdd 2 2 -/
#guard_msgs (whitespace := lax) in
#fh_expand fn four() -> Nat { twice(2) }

/-! ## Tier 2 — elaboration

It is a real production: it composes, it nests, and its result is ordinary Lean.
-/

fn four() -> Nat { twice(2) }
fn sixteen() -> Nat { twice(twice(4)) }

example : four = 4 := rfl
example : sixteen = 16 := rfl

/-- info: 'sixteen' does not depend on any axioms -/
#guard_msgs in
#print axioms sixteen

/-! ### The `::` fix

`Nat::succ(0)` arriving from a quotation. Before the fix this did not error — it *panicked*,
inside `Name.append`, because both halves carried macro scopes.
-/

open Lean in
macro "genpath" : fh_expr => `(fh_expr| Nat::succ(0))

/-- info: set_option autoImplicit false in def viaQuot : Nat := Nat.succ 0 -/
#guard_msgs (whitespace := lax) in
#fh_expand fn viaQuot() -> Nat { genpath }

fn viaQuot() -> Nat { genpath }

example : viaQuot = 1 := rfl

/-! ### The dot-notation fix

A method spelling reaching `fh_dot%` from a quotation. The receiver and the method name
both carry scopes; the name is rebuilt with them erased, because a method spelling is
never a binder.
-/

open Lean in
macro "bump(" n:fh_expr ")" : fh_expr => `(fh_expr| $(n).succ())

/-- info: set_option autoImplicit false in def three : Nat := 2.succ -/
#guard_msgs (whitespace := lax) in
#fh_expand fn three() -> Nat { bump(2) }

fn three() -> Nat { bump(2) }

example : three = 3 := rfl

/-! ### Splicing into call position, and a bridge reached through a macro

Two things at once, and the second is the interesting one: a bridged method spelling
(`use lean::Dvd;` making `.dvd()` mean `∣`) now works when the receiver and method arrive
from a *quotation*. It did not before — the bridge patterns matched a literal `dvd`, and a
method name from a quotation carries macro scopes, so the pattern never fired. Every bridge
now branches on the erased name.
-/

section
use lean::Dvd;

open Lean in
macro "divides(" a:fh_expr "," b:fh_expr ")" : fh_expr => `(fh_expr| $(a).dvd($b))

/-- info: set_option autoImplicit false in def d (p : Nat) (a : Nat) : Prop := Dvd.dvd p a -/
#guard_msgs (whitespace := lax) in
#fh_expand fn d(p: Nat, a: Nat) -> Prop { divides(p, a) }

fn viaMacro(p: Nat, a: Nat) -> Prop { divides(p, a) }
fn directly(p: Nat, a: Nat) -> Prop { p.dvd(a) }

/-! The two spellings agree, which is the property that matters — a bridge that behaves
differently inside a macro would be worse than one that did not work there at all. -/

example : viaMacro = directly := rfl

end

/-! ## Tier 3 — negative

The extension point is a *fallback*, not a bypass. It does not weaken the statement rule —
a statement in expression position is still FH's error, because that check runs first and
never reaches the macro lookup.
-/

/--
error: FH: `for`, `while`, `let mut`, assignment, `break`, `continue` and `return` are statements — they belong in a block, not inside an expression
-/
#guard_msgs in
fn stmt_in_expr(n: Nat) -> Nat { let x = (for i in List::range(n) { n } 0); x }
