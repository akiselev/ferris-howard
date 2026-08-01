/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M0 · `todo!` and the sorry report (A0.4)

* **Stage: one for the translation, two for the elaboration of `fh_todo%`.** Justified in
  `FerrisHoward/Elab/Todo.lean`: the message has to reach the message log and `MacroM`
  cannot log, only throw.
* **Ruling D:** `todo!()` is design §3's row; Rust's `todo!()` also means "not written
  yet", and here it means it in the strong sense — the declaration depends on `sorryAx`.
* **Sorry count: three**, asserted below, and that is the point of the file.
-/

/-! ## Tier 1 — golden expansion -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
def stub (n : Nat) : Nat :=
  fh_todo%
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn stub(n: Nat) -> Nat { todo!() }

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
def stub2 : Nat :=
  fh_todo%"needs the Euclid argument"
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn stub2() -> Nat { todo!("needs the Euclid argument") }

/-! ## Tier 2 — elaboration

Both messages fire: FH's own log line, carrying the text, and Lean's `sorry` warning. The
second is the one that cannot be faked — it comes from the kernel-visible `sorryAx` in the
declaration, not from FH's say-so.
-/

/--
info: FH todo
---
warning: declaration uses `sorry`
-/
#guard_msgs in
fn stub(n: Nat) -> Nat { todo!() }

/--
info: FH todo: needs the Euclid argument
---
warning: declaration uses `sorry`
-/
#guard_msgs in
fn stub2() -> Nat { todo!("needs the Euclid argument") }

/-- warning: declaration uses `sorry` -/
#guard_msgs in
fn bodyless(n: Nat) -> Nat;

fn clean() -> Nat { 1 }

/-- info: 'stub' depends on axioms: [sorryAx] -/
#guard_msgs in
#print axioms stub

/-- info: 'clean' does not depend on any axioms -/
#guard_msgs in
#print axioms clean

/-! The report is derived from the environment rather than from a list FH kept while
expanding, so `bodyless` — which never wrote `todo!` — is in it too. -/

/--
info: FH sorry report: 3 declaration(s) depend on `sorryAx`
  bodyless
  stub
  stub2
-/
#guard_msgs in
#fh_sorry_report

/-! ## Tier 3 — negative -/

/-- error: FH: `#[name(…)]` names an anonymous `impl`, which arrives at A1.6 -/
#guard_msgs in
#[name(other)] fn renamed() -> Nat { 1 }

/--
error: FH: `#[terminates_by(…)]` takes arguments, which are not supported yet; attributes with arguments arrive with the features that use them
-/
#guard_msgs in
#[terminates_by(n)] fn measured(n: Nat) -> Nat { n }

/-! ## Tier 4 — span

`todo!`'s log lands on the `todo!` itself, and Lean's `sorry` warning on the declaration
name — which is the pair a reader wants: what is missing, and which declaration is
incomplete.
-/

/--
info: info @ +0:22-35 «todo!("here")»
warning @ +0:3-10 «spanned»
-/
#guard_msgs in
#fh_spans in
fn spanned() -> Nat { todo!("here") }
