/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 2 — group theory, and laws as fields

`corpus-review.md` Group 2, made executable, and the feature fixture for A1.6. Design §4.4
calls laws-as-fields "the payoff feature of the whole project"; this is it working.

What it stresses: proof obligations as trait fields; hypotheses that are themselves
quantified Props (`h`'s type is a `for<>`); and **F1**, nullary inference — `Grp::e()` has
no argument from which to infer `G`, and resolves from the expected type, exactly as
Rust's `Default::default()` does. Ruling C item one, with turbofish as the escape.

* **Stage: one.**
* **Ruling D:** `trait` bodies carrying laws are *confined* — Rust traits have no such
  member. Everything else here is design §3's spine.
* **Sorry count: zero.**

The proof of `id_unique` is not the corpus's, which is marked "sketch; real proof in
tests". `Grp` as stated has a *left* identity and *left* inverses, so `e2 = e` needs the
standard derivation rather than one `simpa`.
-/

trait Grp<Self> {
    fn op(a: Self, b: Self) -> Self;
    fn e() -> Self;
    fn inv(a: Self) -> Self;

    assoc:    for<a: Self, b: Self, c: Self> op(op(a, b), c) == op(a, op(b, c));
    id_left:  for<a: Self> op(e(), a) == a;
    inv_left: for<a: Self> op(inv(a), a) == e();
}

theorem id_unique<G>(e2: G, h: for<a: G> Grp::op(e2, a) == a) -> e2 == Grp::e()
where G: Grp
{
    lean! {
      have h2 : Grp.op e2 e2 = e2 := h e2
      calc e2 = Grp.op Grp.e e2 := (Grp.id_left e2).symm
        _ = Grp.op (Grp.op (Grp.inv e2) e2) e2 := by rw [Grp.inv_left]
        _ = Grp.op (Grp.inv e2) (Grp.op e2 e2) := Grp.assoc _ _ _
        _ = Grp.op (Grp.inv e2) e2 := by rw [h2]
        _ = Grp.e := Grp.inv_left e2
    }
}

/-! ## Tier 1 — golden expansion

A trait is a class over an explicit carrier, its methods are fields whose types are
functions, and its laws are fields like any other — which is precisely why every `impl`
has to discharge them.
-/

/--
info: set_option autoImplicit false in
class Semigroup (Self : Type _) where
  op (a : Self) (b : Self) : Self
  assoc : ∀ (a : Self) (b : Self) (c : Self), Eq (op (op a b) c) (op a (op b c))
-/
#guard_msgs (whitespace := lax) in
#fh_expand trait Semigroup<Self> {
    fn op(a: Self, b: Self) -> Self;
    assoc: for<a: Self, b: Self, c: Self> op(op(a, b), c) == op(a, op(b, c));
}

/-! `where` bounds on a theorem become instance binders, so `G: Grp` is `[Grp G]` — the
mapping design §4.2 chooses because you never pass a trait impl explicitly in either
language. And `Grp::e()` becomes `Grp.e`, whose carrier the expected type supplies. -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem left_id_unique {G : Type _} [Grp G] (e2 : G) (h : Eq (Grp.op e2 e2) e2) : Eq e2 (Grp.e) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem left_id_unique<G>(e2: G, h: Grp::op(e2, e2) == e2) -> e2 == Grp::e()
where G: Grp
{
    todo!()
}

/-! ## Tier 2 — elaboration

The statement is the corpus's, and it is the one that had to come out right:
`∀ {G} [Grp G] (e2 : G), (∀ a, op e2 a = a) → e2 = e`.
-/

/-- info: 'id_unique' does not depend on any axioms -/
#guard_msgs in
#print axioms id_unique

/-- info: theorem id_unique.{u_1} : ∀ {G : Type u_1} [inst : Grp G] (e2 : G), (∀ (a : G), Grp.op e2 a = a) → e2 = Grp.e -/
#guard_msgs in
#print sig id_unique

/-! An `impl` discharges every obligation, laws included. Nothing here is a `sorry`: the
instance is a real group. -/

impl Grp for Int {
    fn op(a: Int, b: Int) -> Int { a + b }
    fn e() -> Int { 0 }
    fn inv(a: Int) -> Int { -a }

    assoc: lean! { intro a b c; omega };
    id_left: lean! { intro a; omega };
    inv_left: lean! { intro a; omega };
}

example : Grp.op (3 : Int) 4 = 7 := rfl
example : (Grp.e : Int) = 0 := rfl

/-- info: 'instGrpInt' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms instGrpInt

/-! ## F1's escape

Ruling C item one sanctions expected-type-driven nullary inference and names **turbofish**
as its escape. Turbofish turns out to have no sound stage-one lowering — `@Grp.e G` leaves
the instance argument explicit and fails on this very example, and the named form
`Grp.e (Self := G)` needs the callee's binder name, which is elaboration information a
macro cannot see. The escape that works, and that FH already has, is F10 ascription.
-/

fn pinned<G>() -> G where G: Grp { (Grp::e(): G) }

/-- info: def pinned.{u_1} : {G : Type u_1} → [Grp G] → G := fun {G} [Grp G] => Grp.e -/
#guard_msgs (whitespace := lax) in
#print pinned

/-! ## Tier 3 — negative

An obligation is a field, so omitting one is Lean's own missing-field error — the law is
not advisory and there is no way to be quiet about it.
-/

/--
error: Fields missing: `inv_left`
-/
#guard_msgs in
impl Grp for Nat {
    fn op(a: Nat, b: Nat) -> Nat { a + b }
    fn e() -> Nat { 0 }
    fn inv(a: Nat) -> Nat { a }

    assoc: lean! { intro a b c; omega };
    id_left: lean! { intro a; omega };
}

/-! And a bodyless `fn` in an `impl` is FH's error, because the two contexts mean opposite
things: in a trait it declares an obligation, in an impl it would leave one open. -/

/--
error: FH: `op` needs a body here — an `impl` supplies values, and a bodyless `fn` declares an obligation
-/
#guard_msgs in
impl Grp for Bool {
    fn op(a: Bool, b: Bool) -> Bool;
}

/-! ## Tier 4 — span -/

/-- info: error @ +1:4-36 «fn op(a: Bool, b: Bool) -> Bool;» -/
#guard_msgs in
#fh_spans in
impl Grp for Bool {
    fn op(a: Bool, b: Bool) -> Bool;
}
