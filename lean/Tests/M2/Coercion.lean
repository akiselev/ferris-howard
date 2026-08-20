/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# M2 · F9 coercion control (A2.0)

F9: coercions are always written, as `e as T`, and silent unification-driven coercion is
disabled in FH-elaborated code. `coercion-control.md` (I6) is the design; this is the gate
PLAN A2.0 asks for — *a silently-coercing expression must error*.

* **Stage:** one for `as` (a macro to `(↑e : T)`), neither for the audit (a
  post-elaboration diagnostic, so it is not part of the translation).
* **Ruling D:** `e as T` is *confined* — Rust's `as` is a cast between primitives and FH's
  is a coercion between mathematical types, but the construct is only reachable where
  Rust's would be meaningless. F10 keeps ascription separate.
* **Sorry count: zero.**

The mechanism, in one line: `mkCoe` pushes an info leaf at every insertion, and FH reports
any whose position is not inside an `as` the author wrote. No elaborator under FH terms —
that blast radius is exactly what R13 was about, and it is why the audit reads positions
rather than wrapping anything.
-/

/-! ## Tier 1 — golden expansion

`e as T` is `(↑e : T)` — Lean's real coercion, deliberately, since a marker constant in
the elaborated term would break `simp` and `norm_cast` matching against `Nat.cast`.
-/

/-- info: set_option autoImplicit false in def to_int (n : Nat) : Int := (↑n : Int) -/
#guard_msgs (whitespace := lax) in
#fh_expand fn to_int(n: Nat) -> Int { n as Int }

/-! Precedence follows Rust: tighter than `*`, looser than unary `-`. The F7 table has no
row for `as`, so this fills a gap rather than moving one. -/

/-- info: set_option autoImplicit false in def scaled (n : Nat) (r : Int) : Int := HMul.hMul (↑n : Int) r -/
#guard_msgs (whitespace := lax) in
#fh_expand fn scaled(n: Nat, r: Int) -> Int { n as Int * r }

/-! ## Tier 2 — elaboration -/

fn to_int(n: Nat) -> Int { n as Int }
fn scaled(n: Nat, r: Int) -> Int { n as Int * r }

example : to_int 3 = 3 := rfl
example : scaled 2 5 = 10 := rfl

/-- info: 'scaled' does not depend on any axioms -/
#guard_msgs in
#print axioms scaled

/-! Corpus Group 6's shape — `choose(n, k) as R` — is what F9 exists for. -/

fn binomial_term<R>(n: Nat, k: Nat, x: R) -> R where R: CommRing {
  HMul::hMul(Nat::choose(n, k) as R, x)
}

/-- info: 'binomial_term' does not depend on any axioms -/
#guard_msgs in
#print axioms binomial_term

/-! ## Tier 3 — negative: the A2.0 gate

A silently-coercing expression must error. This is the gate.
-/

/--
error: FH: this coercion is Lean's, not yours. F9 says coercions are written — spell it `… as T`, or change the types so none is needed.

Note: this check can be disabled with `set_option linter.fh.silentCoercion false`.
-/
#guard_msgs in
fn silent(n: Nat, r: Int) -> Int { Int::mul(n, r) }

/-! The same expression with the coercion written is accepted — the difference between the
two is exactly one `as`, which is the whole of F9. -/

fn not_silent(n: Nat, r: Int) -> Int { Int::mul(n as Int, r) }

example : not_silent 2 5 = 10 := rfl

/-! And a file that means to opt out can. A rule worth having is a rule worth turning off
deliberately, in one place, with the reason visible in the source. -/

set_option linter.fh.silentCoercion false in
fn opted_out(n: Nat, r: Int) -> Int { Int::mul(n, r) }

example : opted_out 2 5 = 10 := rfl

/-! ## Tier 4 — span

The report lands on the *operand* Lean coerced, not on the declaration — which is what
tells you where to write the `as`.
-/

/-- info: error @ +0:45-46 «n» -/
#guard_msgs in
#fh_spans in
fn silent2(n: Nat, r: Int) -> Int { Int::mul(n, r) }
