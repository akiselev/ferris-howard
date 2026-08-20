/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · `#[opaque]` and `extern "axiom"` (A2.2)

The last two of design §4.6's opt-outs, and the honest ones.

`#[opaque]` gives a declaration whose value exists and which nothing may unfold. It is a
different *command*, not a modifier, which is why it does not go through the
`declModifiers` graft.

`extern "axiom" { fn choice(…) -> …; }` declares axioms. Design §4.6 calls the spelling
"both cute and semantically honest", and it is: an axiom is exactly a function whose
implementation lives outside the language, which is what an extern block says.

* **Stage: one.**
* **Ruling D:** *extension* — Rust's `extern` blocks declare foreign functions, and FH's
  declare foreign *truth*. Neither construct is legal Rust here, so nothing changes
  meaning.
* **Sorry count: zero**, and an axiom is not a sorry: it is a stated assumption, and
  `#print axioms` names it rather than lumping it under `sorryAx`. That distinction is the
  reason to have the syntax at all.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in opaque hidden : Nat := 42 -/
#guard_msgs (whitespace := lax) in
#fh_expand #[opaque] fn hidden() -> Nat { 42 }

/-- info: set_option autoImplicit false in axiom choice {T : Type _} (p : T → Prop) : T -/
#guard_msgs (whitespace := lax) in
#fh_expand extern "axiom" { fn choice<T>(p: T -> Prop) -> T; }

/-! ## Tier 2 — elaboration -/

#[opaque] fn hidden() -> Nat { 42 }

/-- info: opaque hidden : Nat -/
#guard_msgs in
#print hidden

/-- info: 'hidden' does not depend on any axioms -/
#guard_msgs in
#print axioms hidden

/-! A block may declare several, and each becomes its own axiom. -/

extern "axiom" {
  fn choice<T>(p: T -> Prop) -> T;
  fn oracle(n: Nat) -> Bool;
}

/-- info: axiom choice.{u_1} : {T : Type u_1} → (T → Prop) → T -/
#guard_msgs in
#print sig choice

/-! And an axiom shows up *as itself* — named, not hidden inside `sorryAx`. Anything that
uses it inherits the name, which is what makes an assumption auditable. -/

/-- info: 'choice' depends on axioms: [choice] -/
#guard_msgs in
#print axioms choice

/-! An axiom has no implementation, so anything using it is a specification rather than a
program — `#[noncomputable]` says which, and Lean insists. -/

#[noncomputable] fn uses_oracle(n: Nat) -> Bool { oracle(n) }

/-- info: 'uses_oracle' depends on axioms: [oracle] -/
#guard_msgs in
#print axioms uses_oracle

/-! ## Tier 3 — negative

An item with a body is not an axiom, and the block says so rather than quietly dropping
the body.
-/

/--
error: FH: an `extern "axiom"` block holds bodyless `fn` declarations — a body would be an implementation, which is what an axiom does not have
-/
#guard_msgs in
extern "axiom" { fn implemented(n: Nat) -> Nat { n } }

/-! There is one extern block, and it is `"axiom"`. -/

/--
error: FH: `extern "C"` is not a thing; the only extern block is `extern "axiom"` (design §4.6)
-/
#guard_msgs in
extern "C" { fn memcpy(n: Nat) -> Nat; }

/-! ## Tier 4 — span -/

/-- info: error @ +0:17-53 «fn implemented2(n: Nat) -> Nat { n }» -/
#guard_msgs in
#fh_spans in
extern "axiom" { fn implemented2(n: Nat) -> Nat { n } }
