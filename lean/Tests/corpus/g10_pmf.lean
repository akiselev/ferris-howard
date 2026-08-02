/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 10 — the PMF monad, and `?` in a monad that is not `Result`

`corpus-review.md` Group 10, made executable. The review is clear about where the value
is: "the test value is confirming `?` behaves *identically* across `Option`, `Except`,
`PMF`, and `StateM` (four golden tests, one per monad)". That comparison lives in
`Tests/M2/DoNotation.lean`, which runs all four side by side; this file is the corpus
consumer and the place the group's *findings* are recorded.

* **Stage: one.**
* **Ruling D:** `?` is an *extension* — Rust's works on `Result`/`Option` by trait, FH's
  works in any monad, which is strictly more.
* **Sorry count: one**, in `two_flips_fair`, and the reason is a Mathlib change rather
  than an FH gap. See the third finding.

## Three findings, and the first is the interesting one

### 1. `half` — which settles I4

The corpus writes `PMF::bernoulli(half)`, and `half` had to be defined. The obvious
spelling is wrong, silently:

```rust
fn half() -> NNReal { 1 / 2 }        // elaborates to ↑((1 : Nat) / (2 : Nat)) = 0
```

Lean elaborates the two literals at `Nat` — nothing in `1 / 2` says otherwise — computes
`1 / 2 = 0` by natural division, and *then* coerces the result to `NNReal`. The answer is
zero, the code looks right, and nothing complains.

Except that FH complains. This is exactly what F9's audit is for, and it is the audit's
best moment so far: the coercion is Lean's, not the author's, so `linter.fh.silentCoercion`
rejects the declaration. The bug is caught at the definition rather than discovered in a
probability that does not sum to one.

The fix is F10 ascription, which is an elaboration hint and inserts no coercion:

```rust
#[noncomputable] fn half() -> NNReal { (1: NNReal) / 2 }
```

One literal is pinned, unification carries the type to the other, no coercion is inserted,
and the value is a half. **This is PLAN I4's "settle `half`", settled** — and the answer is
that Ruling C item five's `OfNat` elaboration is not enough on its own when an operator
sits between the literal and its expected type. Both spellings are below, the wrong one in
the negative tier.

### 2. `PMF::bernoulli` is deprecated, and its replacement is not a `PMF`

`PMF.bernoulli` still exists on this toolchain but warns, and the suggested replacement
`ProbabilityTheory.bernoulliMeasure` has a different type — a `Measure`, not a `PMF`. The
group's `?` content survives either way, because what is under test is the bind. The file
sets `linter.deprecated false` and says so here rather than quietly picking a different
distribution.

It also takes *two* arguments, `(p : NNReal) → p ≤ 1 → PMF Bool`, where the corpus writes
one. The proof obligation is `half_le_one`, stated below.

### 3. The corpus's proof sketch no longer closes

`lean! { ext b; fin_cases b <;> simp [two_flips, PMF.bernoulli] <;> ring }` is the corpus's
text and it does not close on this toolchain: the deprecation changed `PMF.bernoulli`'s
definition to go through `PMF.ofFintype`, so the sketch's `simp` set no longer reaches the
goal. Left as `todo!()`, visibly, rather than replaced with something that closes and
proves a different thing. Recorded for whoever revisits Group 10's text.
-/

set_option linter.deprecated false

/-! ## The corpus, as it elaborates -/

#[noncomputable] fn half() -> NNReal { (1: NNReal) / 2 }

theorem half_le_one() -> half <= 1 { lean! { norm_num [half] } }

#[noncomputable]
fn two_flips() -> PMF<Bool> {
    let x = PMF::bernoulli(half, half_le_one)?;
    let y = PMF::bernoulli(half, half_le_one)?;
    PMF::pure(Bool::xor(x, y))
}

/--
warning: declaration uses `sorry`
---
info: FH todo
-/
#guard_msgs in
theorem two_flips_fair() -> two_flips == PMF::bernoulli(half, half_le_one) {
    todo!()
}

/-! ## Tier 1 — golden expansion

The ascription passes through as an ascription — no `↑` anywhere, which is the point.
-/

/--
info: set_option autoImplicit false in
noncomputable def half_g : NNReal := HDiv.hDiv (1 : NNReal) 2
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[noncomputable] fn half_g() -> NNReal { (1: NNReal) / 2 }

/-! The block is a `do` block because it contains `?`, and the monad comes from the
declared return type — no `Id.run`, because `?` is what says "this runs in the monad"
(A2.3). The tail is an explicit `PMF::pure`: Ruling C's list is closed, so there is no
silent return-lift. -/

/--
info: set_option autoImplicit false in
noncomputable def two_flips_g : PMF Bool := do
  let x ← PMF.bernoulli half half_le_one
  let y ← PMF.bernoulli half half_le_one
  PMF.pure (Bool.xor x y)
-/
#guard_msgs (whitespace := lax) in
#fh_expand #[noncomputable]
fn two_flips_g() -> PMF<Bool> {
    let x = PMF::bernoulli(half, half_le_one)?;
    let y = PMF::bernoulli(half, half_le_one)?;
    PMF::pure(Bool::xor(x, y))
}

/-! ## Tier 2 — elaboration -/

/-- info: def two_flips : PMF Bool -/
#guard_msgs in
#print sig two_flips

/-- info: 'two_flips' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms two_flips

/-! `half` is a half — the fact the negative tier below shows is *not* automatic. -/

example : (half : NNReal) = 1 / 2 := by norm_num [half]
example : (half : Real) = 0.5 := by norm_num [half]

/-! ## Tier 3 — negative

### The one that matters

`1 / 2` on an `NNReal` is `↑((1 : Nat) / (2 : Nat))`, which is zero. F9's audit is what
stands between that and a silently wrong probability.
-/

/--
error: FH: this coercion is Lean's, not yours. F9 says coercions are written — spell it `… as T`, or change the types so none is needed.

Note: this check can be disabled with `set_option linter.fh.silentCoercion false`.
-/
#guard_msgs (whitespace := lax) in
#[noncomputable] fn naive_half() -> NNReal { 1 / 2 }

/-! And it really is zero — here it is with the audit switched off, which is the only way
to get the declaration at all. -/

set_option linter.fh.silentCoercion false in
#[noncomputable] fn wrong_half() -> NNReal { 1 / 2 }

/-- info: def wrong_half : NNReal := ↑(1 / 2) -/
#guard_msgs (whitespace := lax) in
#print wrong_half

example : wrong_half = 0 := by norm_num [wrong_half]

/-! ### `?` still has its two restrictions

They are A2.3's and they hold in `PMF` exactly as in `Option`. -/

/-- error: FH: one `?` per `let`, at the end of the value -/
#guard_msgs in
#[noncomputable] fn nested() -> PMF<Bool> {
  let x = PMF::pure(PMF::pure(true)?)?;
  PMF::pure(x)
}

/-! ## Tier 4 — span -/

/--
info: warning @ +0:20-22 «sp»
info @ +0:40-47 «todo!()»
-/
#guard_msgs in
#fh_spans in
#[noncomputable] fn sp() -> PMF<Bool> { todo!() }
