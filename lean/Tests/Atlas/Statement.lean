/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Atlas.Statement

/-!
# I3 · the canonical statement encoding

The test plan from `statement-hash.md`, minus the two halves that live elsewhere: SHA-256
itself and the version-skew rule are tested in `crates/fh-atlas/src/statement.rs`, where
the digest is computed.

Most assertions are *properties* (invariance, sensitivity) rather than pinned encodings,
because a normalization change should churn one golden, not thirty. The one pinned
encoding is the differential anchor: `crates/fh-atlas` pins the same string, so a change
on either side fails on the other.
-/

/-! ## Invariance -/

/-! Binder names are erased and the declaration's own name is not encoded — which is what
lets B8 rebind an overlay by hash across a rename. -/

theorem alpha_a (a : Nat) : a = a := rfl
theorem alpha_b (zzz : Nat) : zzz = zzz := rfl

/-- info: same statement -/
#guard_msgs in
#fh_statement_eq alpha_a alpha_b

/-! Universe parameter names are renumbered by first occurrence. -/

universe u v

def univ_a (α : Type u) : Type u := α
def univ_b (β : Type v) : Type v := β

/-- info: same statement -/
#guard_msgs in
#fh_statement_eq univ_a univ_b

/-! `Level.normalize` runs first, so levels that differ only in shape agree. -/

def lvl_a (α : Type (max u u)) : Type (max u u) := α
def lvl_b (α : Type u) : Type u := α

/-- info: same statement -/
#guard_msgs in
#fh_statement_eq lvl_a lvl_b

/-! ## Sensitivity -/

/-! Binder info is part of the statement: it is what a caller must supply. -/

theorem binder_explicit (n : Nat) : n = n := rfl
theorem binder_implicit {n : Nat} : n = n := rfl

/-- info: different statements -/
#guard_msgs in
#fh_statement_eq binder_explicit binder_implicit

/-! Weakening. This is the shape of the C5 rehearsal fixture: a statement that has grown a
hypothesis must not keep its identity. -/

theorem strong : ∀ n : Nat, n = n := fun _ => rfl
theorem weakened : ∀ n : Nat, n = 0 → n = n := fun _ _ => rfl

/-- info: different statements -/
#guard_msgs in
#fh_statement_eq strong weakened

/-! Argument order. (Note what this test may *not* be: `(a b : Nat) : a + b = b + a` and
`(b a : Nat) : b + a = a + b` are alpha-equivalent and correctly encode the same, so the
pair has to differ in the binders' types, not just their names.) -/

theorem order_nb (a : Nat) (_b : Bool) : a = a := rfl
theorem order_bn (_b : Bool) (a : Nat) : a = a := rfl

/-- info: different statements -/
#guard_msgs in
#fh_statement_eq order_nb order_bn

/-! **No unfolding**, deliberately. `MyNat` is an `abbrev`, so these two statements are
definitionally identical and Lean would accept a proof of one as a proof of the other —
and they still encode differently. That is the whole substitution recorded in §9.6:
encoding equality is *stricter* than defeq, so a false rejection is possible and a false
acceptance is not. -/

abbrev MyNat := Nat

theorem thru_abbrev (n : MyNat) : n = n := rfl
theorem thru_nat (n : Nat) : n = n := rfl

example : @thru_abbrev = @thru_nat := rfl   -- defeq: Lean cannot tell them apart

/-- info: different statements -/
#guard_msgs in
#fh_statement_eq thru_abbrev thru_nat

/-! ## Refusal

A statement whose *type* mentions `sorryAx` is not a statement. (A declaration merely
*proved* by `sorry` is fine to encode — its type is honest, and it is `#print axioms` that
reports the hole.) -/

/-- warning: declaration uses `sorry` -/
#guard_msgs in
theorem sorry_proof : 1 = 1 := sorry

/-- info: fh-stmt-v1;a(a(a(c(2:Eq,1,+(0)),c(3:Nat,0)),a(a(a(c(11:OfNat.ofNat,1,0),c(3:Nat,0)),n1),a(c(12:instOfNatNat,0),n1))),a(a(a(c(11:OfNat.ofNat,1,0),c(3:Nat,0)),n1),a(c(12:instOfNatNat,0),n1))) -/
#guard_msgs in
#fh_statement sorry_proof

/-! ## The differential anchor

Pinned here and in `crates/fh-atlas/src/statement.rs`. The Rust side digests exactly this
string; if the encoder changes, this golden fails first and the Rust constant has to be
updated deliberately rather than by accident.
-/

/-- info: fh-stmt-v1;pd(c(3:Nat,0),a(a(a(c(2:Eq,1,+(0)),c(3:Nat,0)),b0),b0)) -/
#guard_msgs in
#fh_statement alpha_a
