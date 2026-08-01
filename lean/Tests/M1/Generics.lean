/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward
import FerrisHoward.Test

/-!
# M1 · dependent signatures, generics and `where` (A1.2, A1.3)

Angle-bracket generics become **implicit** binders and `where` bounds become **instance**
binders — the two mappings design §4.2 chooses because they match Rust intuition exactly:
neither is ever passed explicitly at a call site in either language.

Dependency then costs nothing (design §4.1's "one true extension"): later binders and the
return type may mention earlier parameters, because FH's type grammar *is* its expression
grammar. `Vector<T, n>` with `n` a parameter is ill-formed Rust and exactly well-formed
Lean.

* **Stage: one.**
* **Ruling D:** dependent signatures are an *extension* (ill-formed Rust becomes
  well-formed FH). The brace escape is Rust's own const-generic spelling.
* **Sorry count: two**, the two `todo!()` stubs.

Not here: turbofish, whose consumer is F1's nullary inference (Group 2), and which needs
to decide between `@f T x` and Lean's named-argument form — that decision belongs with the
feature that forces it.
-/

/-! ## Tier 1 — golden expansion -/

/-- info: set_option autoImplicit false in def id_g {T : Type _} (x : T) : T := x -/
#guard_msgs (whitespace := lax) in
#fh_expand fn id_g<T>(x: T) -> T { x }

/-! A bare `<T>` gets `Type _` — design §4.3's "defaults to `Space<_>`", spelled in core
Lean until `Space` itself arrives at A2.4. An annotated parameter says what it is, and
values are as ordinary there as types: `<n: Nat>` is Rust's const generic without needing
a `const` marker, because FH's generics already bind values (design §4.1). -/

/--
info: set_option autoImplicit false in
def get_g {T : Type _} {n : Nat} (v : Vector T n) (i : Fin n) : T :=
  v.get i
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn get_g<T, n: Nat>(v: Vector<T, n>, i: Fin<n>) -> T { v.get(i) }

/-! Generic arguments parse above the comparison band, so `Fin<n + 1>` needs no help; a
comparison inside them does, and gets Rust's const-generic braces. -/

/--
info: set_option autoImplicit false in
set_option linter.unusedVariables false in
def dep_g {T : Type _} {n : Nat} (v : Vector T (HMul.hMul n 2)) : Fin (HAdd.hAdd n 1) :=
  sorry
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn dep_g<T, n: Nat>(v: Vector<T, {n * 2} >) -> Fin<n + 1> { todo!() }

/-! `where` bounds are instance binders, and they land in Mathlib's order — implicit
carrier, then its structure, then the explicit arguments. -/

/--
info: set_option autoImplicit false in
def compose_g {A : Type _} {B : Type _} {C : Type _} (f : A → B) (g : B → C) : A → C :=
  Function.comp g f
-/
#guard_msgs (whitespace := lax) in
#fh_expand fn compose_g<A, B, C>(f: A -> B, g: B -> C) -> A -> C { Function::comp(g, f) }

/-- info: set_option autoImplicit false in def least_g {T : Type _} [LE T] (a : T) (b : T) : Prop := LE.le a b -/
#guard_msgs (whitespace := lax) in
#fh_expand fn least_g<T>(a: T, b: T) -> Prop where T: LE { a <= b }

/-! ## Tier 2 — elaboration -/

fn id_g<T>(x: T) -> T { x }
fn get_g<T, n: Nat>(v: Vector<T, n>, i: Fin<n>) -> T { v.get(i) }
fn compose_g<A, B, C>(f: A -> B, g: B -> C) -> A -> C { Function::comp(g, f) }
fn least_g<T>(a: T, b: T) -> Prop where T: LE { a <= b }

theorem id_g_eq<T>(x: T) -> id_g(x) == x { lean! { rfl } }

theorem least_g_intro<T>(a: T, b: T, h: LE::le(a, b)) -> least_g(a, b) where T: LE {
  lean! { exact h }
}

example : get_g (Vector.mk #[7] rfl) 0 = 7 := rfl
example : compose_g (fun n => n + 1) (fun n => n * 2) 3 = 8 := rfl

/-- info: 'id_g_eq' does not depend on any axioms -/
#guard_msgs in
#print axioms id_g_eq

/-! ## Tier 3 — negative

F6: a `<` comparison must be parenthesised, because a bare `<` could open a generic
argument list. One rule, everywhere — the corpus review's own answer to "may it be relaxed
where no generic application can occur" was no.

Enforced at expansion time with fixed wording and an exact span, per the F6 amendment: the
parser cannot word an error, so it would have said "expected `>`" and left the reader to
guess.
-/

/-- error: FH: parenthesise this comparison — `(a < b)`. A bare `<` could open a generic argument list -/
#guard_msgs in
fn cmp(a: Nat, b: Nat) -> Prop { a < b }

/-- info: parses -/
#guard_msgs in
#fh_parse "fn cmp_ok(a: Nat, b: Nat) -> Prop { (a < b) }"

/-! ## Tier 4 — span

The error covers the comparison, not the enclosing body.
-/

/-- info: error @ +0:34-39 «a < b» -/
#guard_msgs in
#fh_spans in
fn cmp2(a: Nat, b: Nat) -> Prop { a < b }
