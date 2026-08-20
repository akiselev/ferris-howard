/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Test

/-!
# Corpus Group 5 — rank–nullity: bundled morphisms and multi-parameter classes

`corpus-review.md` Group 5, made executable, and the last of Ruling E's twelve.

What it stresses: multi-parameter classes (`Module<K>` — `Self` is `V`, `K` is the extra
parameter, matching design §4.4's convention); `+`-composition of bounds mapping to several
instance binders; bundled morphism types; and F8's types-as-arguments, `finrank(K, V)`.

* **Stage: one.**
* **Ruling D:** *confined* — multi-parameter bounds and `LinearMap<K, V, W>` have no Rust
  reading to preserve.
* **Sorry count: zero.** Rank–nullity is proved from Mathlib.

## `where V: AddCommGroup + Module<K> + FiniteDimensional<K>`

Three bounds on one carrier, two of them parameterised, and each becomes its own instance
binder: `[AddCommGroup V] [Module K V] [FiniteDimensional K V]`. Nothing special happens —
a bound is a class applied to the carrier, and `Module<K>` is a class that already had an
argument. That is design §4.4's convention paying off: `Self` last, extra parameters where
they are written.

## Two findings

### `LinearMap<K, V, W>` needed a bridge — the only morphism that did

Design §6 asks for `LinearMap`, `RingHom` and `MonoidHom` in `Bridge/`. Two of the three
turn out to need nothing: the no-mangling policy already reaches `RingHom<A, B>` and
`MonoidHom<A, B>` verbatim, and the arrow notations are spellings of exactly those names.

`LinearMap` is different, because Mathlib's is **semilinear**: its first argument is a ring
homomorphism, and `V →ₗ[K] W` supplies `RingHom.id K`. The arrow notation hides that, and
so does the bridge — `use lean::LinearMap;` makes `LinearMap<K, V, W>` mean
`LinearMap (RingHom.id K) V W`.

### `↥` is a coercion, and F9 means it

`finrank K (ker f)` does not typecheck: `ker f` is a `Submodule`, and `finrank` wants a
type, so Lean inserts `↥` — a `CoeSort`. Mathlib inserts it silently everywhere; F9 says
coercions are written, and the audit flags it.

The spelling is `LinearMap::ker(f) as Space`, and the elaborated statement is
byte-identical to the version with the silent coercion. So the rule costs six characters
twice and buys the property that every coercion in the file is one the author chose. F18's
kind word doubles as the target, which is the reading a mathematician wants: *the subspace,
as a space*.
-/

section
use lean::LinearMap;

/-! ## The corpus, as it elaborates -/

theorem rank_nullity<K, V, W>(f: LinearMap<K, V, W>)
    -> Module::finrank(K, LinearMap::ker(f) as Space)
       + Module::finrank(K, LinearMap::range(f) as Space)
       == Module::finrank(K, V)
where K: Field, V: AddCommGroup + Module<K> + FiniteDimensional<K>,
      W: AddCommGroup + Module<K>
{
    lean! { exact Nat.add_comm _ _ ▸ LinearMap.finrank_range_add_finrank_ker f }
}

/-! ## Tier 1 — golden expansion

The bounds become six binders, the morphism becomes the semilinear form with `RingHom.id`,
and the sort coercion appears exactly where the `as` is.
-/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
theorem rn_g {K : Type _} {V : Type _} {W : Type _} [Field K] [AddCommGroup V] [Module K V] [FiniteDimensional K V]
    [AddCommGroup W] [Module K W] (f : LinearMap (RingHom.id K) V W) :
    Eq (Module.finrank K (↑(LinearMap.ker f) : Type _)) 0 :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand theorem rn_g<K, V, W>(f: LinearMap<K, V, W>)
    -> Module::finrank(K, LinearMap::ker(f) as Space) == 0
where K: Field, V: AddCommGroup + Module<K> + FiniteDimensional<K>,
      W: AddCommGroup + Module<K>
{ todo!() }

/-- info: set_option autoImplicit false in abbrev Endo := LinearMap (RingHom.id Rat) Rat Rat -/
#guard_msgs (whitespace := lax) in
#fh_expand type Endo = LinearMap<Rat, Rat, Rat>;

/-! ## Tier 2 — elaboration

The statement is rank–nullity, with the two summands in the corpus's order.
-/

/--
info: theorem rank_nullity.{u_1, u_2, u_3} : ∀ {K : Type u_1} {V : Type u_2} {W : Type u_3} [inst : Field K]
  [inst_1 : AddCommGroup V] [inst_2 : Module K V] [FiniteDimensional K V] [inst_4 : AddCommGroup W]
  [inst_5 : Module K W] (f : V →ₗ[K] W), Module.finrank K ↥f.ker + Module.finrank K ↥f.range = Module.finrank K V
-/
#guard_msgs (whitespace := lax) in
#print sig rank_nullity

/-- info: 'rank_nullity' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms rank_nullity

/-! Not vacuous — the identity on `ℚ` has nullity 0 and rank 1. -/

example : Module.finrank ℚ ↥(LinearMap.ker (LinearMap.id : ℚ →ₗ[ℚ] ℚ))
        + Module.finrank ℚ ↥(LinearMap.range (LinearMap.id : ℚ →ₗ[ℚ] ℚ))
        = Module.finrank ℚ ℚ :=
  rank_nullity LinearMap.id

/-! ## Tier 3 — negative

F9 again, and this is the coercion Mathlib inserts most often. Without the `as`, the
declaration is rejected — and the point is that the *elaborated statement is the same
either way*, so what the rule protects is the reader, not the proof.
-/

/--
warning: declaration uses `sorry`
---
error: FH: this coercion is Lean's, not yours. F9 says coercions are written — spell it `… as T`, or change the types so none is needed.

Note: this check can be disabled with `set_option linter.fh.silentCoercion false`.
---
info: FH todo
-/
#guard_msgs (whitespace := lax) in
theorem silent_sort<K, V, W>(f: LinearMap<K, V, W>) -> Module::finrank(K, LinearMap::ker(f)) == 0
where K: Field, V: AddCommGroup + Module<K> + FiniteDimensional<K>,
      W: AddCommGroup + Module<K>
{ todo!() }

end

/-! And outside the import, `LinearMap<K, V, W>` is three-argument application of whatever
`LinearMap` is in scope — which here is Mathlib's semilinear one, so the first argument is
in the wrong place and Lean says so. The bridge is what supplies `RingHom.id`. -/

/--
error: Application type mismatch: The argument
  K
has type
  Type ?u.2
but is expected to have type
  ?m.1 →+* ?m.2
in the application
  LinearMap K
---
error: failed to synthesize instance of type class
  AddCommMonoid V

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs (whitespace := lax) in
fn no_bridge<K, V, W>(_f: LinearMap<K, V, W>) -> Nat { 0 }

/-! ## Tier 4 — span -/

/--
info: error @ +0:37-38 «K»
error @ +0:27-45 «LinearMap<K, V, W>»
-/
#guard_msgs in
#fh_spans in
fn no_bridge2<K, V, W>(_f: LinearMap<K, V, W>) -> Nat { 0 }
