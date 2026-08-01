# The FH ↔ Lean Rosetta Stone

A learning reference: every FH construct, its Lean 4 target, and what the concept *means* on each side. Read it to learn both languages at once; the agent implements from the same table. Conventions: FH is the Rust-flavored surface; Lean is what `fh emit-lean` produces. Rulings A–E from the corpus review are baked in throughout.

## 0. The cheat sheet

| FH | Lean 4 | Concept |
|---|---|---|
| `fn f(x: A) -> B { ... }` | `def f (x : A) : B := ...` | definition / computation |
| `theorem t(h: P) -> Q { ... }` | `theorem t (h : P) : Q := ...` | proved statement |
| `todo!()` | `sorry` | hole; debt |
| `Space` / `Space<1>` | `Type` / `Type 1` | universe of types |
| `Prop` | `Prop` | universe of statements |
| `(x: A) -> B(x)` | `(x : A) → B x` | dependent function type |
| `<T: Space>` | `{T : Type}` | implicit type argument |
| `where T: Grp` | `[Grp T]` | typeclass constraint |
| `for<x: T> P(x)` | `∀ x : T, P x` | universal quantifier |
| `exists<x: T> P(x)` | `∃ x : T, P x` | existential quantifier |
| `struct` | `structure` | record type |
| `enum` | `inductive` | inductive type (the induction engine) |
| `match` | `match` | case analysis / elimination |
| `trait` | `class` | interface with laws |
| `impl Trait for T` | `instance : Trait T` | interface implementation |
| `var G: Grp;` | `variable (G : Type) [Grp G]` | ambient hypothesis |
| `==` `<=` `<` | `=` `≤` `<` | Prop-valued relations (Ruling A) |
| `&&` `\|\|` `!` `->` `<->` | `∧` `∨` `¬` `→` `↔` | logical connectives (Prop) |
| `x in S` | `x ∈ S` | membership |
| `decide(p)` | `decide p` / `by decide` | run a decision procedure (Bool world) |
| `prove { ... }` | `by ...` | tactic proof block |
| `#[attr]` | `@[attr]` | attributes |
| `mod` / `use` | `namespace` / `import`+`open` | modules |

## 1. Definitions vs theorems: the one distinction that organizes everything

```rust
// FH
fn double(n: Nat) -> Nat { 2 * n }
theorem double_even(n: Nat) -> Even(double(n)) { prove { ... } }
```
```lean
-- Lean
def double (n : Nat) : Nat := 2 * n
theorem double_even (n : Nat) : Even (double n) := by ...
```
**Both sides:** a `theorem` *is* a function — one whose return type lives in `Prop`. Its arguments are hypotheses; its body is evidence; *calling it is citing it* (`double_even 7` is a proof about 7). This is Curry–Howard, and FH makes it visually literal: theorems look like generic functions because they are. The only asymmetry: Lean treats `theorem` bodies as opaque (proof irrelevance — nobody may depend on *which* proof), while `def` bodies unfold. FH mirrors this: `fn` computes, `theorem` certifies. `todo!()`/`sorry` is a typed IOU: everything downstream compiles but the debt is tracked (our H4 budget counts these).

## 2. The two universes: `Space` and `Prop`

**Lean side:** every expression has a type; types themselves live in universes: `Prop` (statements — inhabitants are proofs), `Type` (data — `Nat`, `List ℝ`), `Type 1` (things containing `Type`), and so on. **FH side:** `Space` renames `Type` because "the type of types" reads badly and physicists say "state space" anyway; `Space<1>` is `Type 1`. The deep rule both sides share: **a proposition is a type whose elements are its proofs.** `2 + 2 == 4` is a type; a proof is a value of it; an empty proposition (no proofs) is false. Everything else in this document is bookkeeping around that idea.

## 3. Functions, dependency, and the three argument modes

```rust
fn nth<T: Space>(v: Vec<T, n>, i: Fin(n)) -> T          // FH
```
```lean
def nth {T : Type} {n : Nat} (v : Vector T n) (i : Fin n) : T   -- Lean
```
**Dependent types** are the one true extension over real Rust: a later type may *mention an earlier value* — `Fin(n)` (naturals < n) depends on `n`, so out-of-bounds access is a type error, not a runtime panic. Lean's `(x : A) → B x` is FH's `(x: A) -> B(x)`. **Three argument modes, both sides:** explicit `(x : A)` — you pass it; implicit `{T : Type}` = FH's `<T>` generics — inferred from use; instance-implicit `[Grp G]` = FH's `where G: Grp` — found by typeclass search. Same machinery Rust's trait solver runs; Lean's is programmable.

## 4. `enum` = `inductive`: where induction actually comes from

```rust
// FH — this IS the definition of the naturals
enum Nat { Zero, Succ(Nat) }
```
```lean
inductive Nat where
  | zero : Nat
  | succ : Nat → Nat
```
**The concept, both sides:** an inductive type is *freely generated* by its constructors — its values are exactly the finite constructor trees, nothing else. That "nothing else" clause is a theorem generator: it is why case analysis is exhaustive, why `Zero ≠ Succ n` (constructors are disjoint), why `Succ` is injective, and — crucially — **it is where induction comes from**. Declaring the `enum` makes Lean synthesize the *induction principle* automatically:

```lean
Nat.rec : P zero → (∀ n, P n → P (succ n)) → ∀ n, P n
```

Read it as a function signature (it is one): give me a proof for `zero`, and a way to push a proof through `succ`, and I return proofs for everything. Induction is not an axiom you trust — it's the eliminator of a datatype you declared. A Rust intuition that transfers exactly: `Nat.rec` is `fold` for the naturals, and *proof by induction is a fold whose accumulator is evidence*.

**Using it — the `induction` tactic (identical on both sides, since FH proof blocks are Lean tactic blocks):**
```rust
theorem add_zero(n: Nat) -> (n + 0 == n) {
  prove {
    induction n with
    | zero => rfl                        // base case: 0 + 0 = 0 by computation
    | succ k ih => simp [Nat.add_succ, ih]  // step: use the hypothesis for k
  }
}
```
`ih` — the induction hypothesis — is just the recursive call's return value, viewed through Curry–Howard. Which yields the deepest bridge in this whole document: **recursion and induction are the same construct.** A structurally recursive `fn` over an `enum` *is* an induction proof that a value exists for every input; Lean compiles your `match`-recursion down to `.rec` and demands termination for exactly the reason induction demands a decreasing measure. When Lean rejects your recursion as possibly non-terminating, it is refusing to accept a circular proof.

## 5. `match`: case analysis as elimination

```rust
fn pred(n: Nat) -> Nat {
  match n { Nat::Zero => Nat::Zero, Nat::Succ(k) => k }
}
```
```lean
def pred (n : Nat) : Nat :=
  match n with | .zero => .zero | .succ k => k
```
Same syntax family, same semantics, one upgrade on the Lean side worth knowing: **dependent match** — the *return type* may vary by branch, and in proofs, matching on a value teaches the type checker facts about it (matching `h : A ∨ B` gives you the `A` case and the `B` case; that's what the tactic `cases`/`rcases` does). In Rust, `match` extracts data; in Lean, `match` extracts data *and knowledge*.

## 6. `struct` = `structure`, and laws as fields

```rust
struct Point { x: Real, y: Real }

trait Monoid<M: Space> {
  fn op(a: M, b: M) -> M;
  fn e() -> M;
  law assoc: for<a: M, b: M, c: M> (op(op(a,b),c) == op(a,op(b,c)));
  law e_op:  for<a: M> (op(e(), a) == a);
}
```
```lean
structure Point where
  x : ℝ
  y : ℝ

class Monoid (M : Type) where
  op : M → M → M
  e  : M
  assoc : ∀ a b c : M, op (op a b) c = op a (op b c)
  e_op  : ∀ a : M, op e a = a
```
**The concept:** Lean structures are Rust structs — but fields may be *proofs*, because propositions are types. So an interface can carry its laws as data: FH's `law` keyword is just a field whose type is a `Prop`, and every `impl` is thereby *obligated to prove the laws* — the trait-with-laws design that real Rust can only document in comments becomes checkable. This is the single feature that makes "math as a Rust crate" work: `Monoid` isn't an interface plus a wiki page of axioms; it's one object, and the compiler enforces the wiki page.

## 7. `impl` = `instance`

```rust
impl Monoid for Nat {
  fn op(a: Nat, b: Nat) -> Nat { a + b }
  fn e() -> Nat { 0 }
  law assoc = prove { exact Nat.add_assoc };
  law e_op  = prove { exact Nat.zero_add };
}
```
```lean
instance : Monoid Nat where
  op := (· + ·)
  e := 0
  assoc := Nat.add_assoc
  e_op := Nat.zero_add
```
**Both sides:** an instance is a *proof that a type inhabits an interface*, registered with the resolver so it's found automatically at use sites (`where M: Monoid` / `[Monoid M]` triggers the search). Mathlib is, structurally, an enormous crates.io of instances: ℤ is an instance of `CommRing`, `EuclideanDomain`, `LinearOrder`... and theorems generic over `[CommRing R]` apply to every registered instance for free. Diamond note both sides know from Rust's coherence rules: overlapping instances are the footgun; Lean permits them with priorities, Mathlib has conventions — FH lints toward Rust-style discipline.

## 8. `var` = `variable`: ambient hypotheses (§4.9)

```rust
var G: Grp;            // FH: ambient group for the rest of the module
var n: Nat;
theorem pow_law(a: G) -> (a.pow(n+1) == a.pow(n).op(a)) { ... }
```
```lean
variable (G : Type) [Grp G] (n : Nat)
theorem pow_law (a : G) : a ^ (n+1) = a ^ n * a := ...
```
**The concept:** `variable` declares *telescope context* — names that any later declaration may mention, automatically becoming that declaration's leading arguments (only the ones actually used get bound). It's how mathematicians write "Let G be a group. Let n ∈ ℕ." once per chapter. FH's `var` compiles to exactly this; `section`/`end` (`mod` blocks in FH) scope it. Ruling: mentioned variables bind, unmentioned don't, and *unbound free identifiers are errors* — no autoImplicit-style silent generalization, per the corpus-review decision.

## 9. Logic: the `Bool`/`Prop` divide and Ruling A

The mental model shift for a Rust programmer, stated once, load-bearing forever: **Rust has one world of truth (`bool`, computed); Lean has two.** `Prop` is the world of *statements and evidence* — `a = b`, `x ≤ y`, `P ∧ Q` are types, possibly undecidable, proved by construction. `Bool` is the world of *computation* — `true`/`false`, produced by running code. Ruling A: FH's familiar operators are **Prop-first** — `==`, `<=`, `<`, `&&`, `||`, `!`, `->`, `<->`, `in` always mean the mathematical thing (`=`, `≤`, `<`, `∧`, `∨`, `¬`, `→`, `↔`, `∈`), because in a math library the statement world is the default. The bridge between worlds is *decidability*: `decide(p)` asks a registered decision procedure to *compute* the truth of `p` and reflect the run into a proof — Lean's `Decidable` typeclass and the `decide` tactic (how Mermin–GHZ gets proven by exhaustive evaluation). One more Rust habit to relocate: `->` inside a proposition is *implication* — which is no relocation at all, since implication and function types are the same thing (a proof of `P -> Q` is a function transforming proofs), so the Rust arrow means what it always meant.

## 10. Quantifiers

```rust
theorem exists_gt(n: Nat) -> exists<m: Nat> (n < m) {
  prove { exact ⟨n+1, Nat.lt_succ_self n⟩ }
}
```
```lean
theorem exists_gt (n : Nat) : ∃ m : Nat, n < m := ⟨n+1, Nat.lt_succ_self n⟩
```
`for<x: T> P` is `∀ x : T, P` — and here's the collapse worth internalizing: **∀ is just the dependent function arrow.** `∀ x : T, P x` and `(x : T) → P x` are the same type; universal statements are functions awaiting an argument; FH's `for<>` borrows Rust's higher-ranked-lifetime syntax because that's Rust's one existing ∀. `exists<x: T> P` is `∃ x, P x`, an inductive type with one constructor pairing a *witness* with a proof about it — construct with `⟨witness, proof⟩`, destruct with `obtain ⟨w, hw⟩ := h`. Existence claims are literally "a value plus its certificate," which is why the falsification arm can *search* for them.

## 11. The proof layer: `prove { }` = `by`

FH deliberately does **not** re-skin tactics — proof blocks are Lean tactic script, shared syntax, so everything you learn in one home works in the other. The dozen that carry most proofs: `exact e` (here is the proof term), `apply f` (reduce goal to f's hypotheses), `intro x`/`intro h` (enter a ∀ or an implication), `rw [h]` (rewrite with an equation — equality's whole job), `simp [...]` (normalize with the lemma database), `induction x with ...` (§4), `cases h` / `rcases`/`obtain` (destruct), `constructor`/`⟨_, _⟩` (build), `calc` (chained (in)equalities, the paper-style proof), `decide` (§9), `norm_num` (arithmetic), `linarith`/`positivity` (the inequality workhorses our certificates lean on), `exact?` (search Mathlib for the finishing lemma — the first thing to try when stuck). A proof is a program constructing an element of the goal type; tactics are metaprograms writing that program; the kernel replays the result and is the only judge.

## 12. Odds and ends that bite

**Numbers:** `Nat` (ℕ, unsigned, *truncated subtraction*: `3 - 5 = 0`), `Int` (ℤ), `Rat` (ℚ, exact — our certificate currency), `Real` (ℝ — *noncomputable*: classical, no `#eval`; statements about ℝ are fine, computing demands `Rat`/`Float`/intervals — this is why the certificate layer is rational by design). **Junk values (V10):** `x / 0 = 0`, `Real.sqrt (-1) = 0` — Mathlib totalizes partial operations; the statement linter demands side conditions or acknowledgments. **Attributes:** `#[simp]` → `@[simp]` (registers a rewrite), `#[rigor(...)]`, `#[units(...)]` are FH-side metadata riding the same mechanism. **Modules:** `mod couette { }` → `namespace Couette ... end Couette`; `use mathlib::algebra::*` → `import Mathlib.Algebra...` + `open`. **Commands:** `#check e` (what's your type — the REPL's question mark), `#eval e` (run it), `#print axioms t` (the H3 audit), `example : P := by ...` (anonymous theorem — scratch space). **Ruling B reminder:** comparisons near generics take mandatory parens — `(a < b)` — because `Vec<T, n>` taught Rust's parser that `<` is a chameleon, and legal-lookalike code must never silently change meaning (Ruling D).

## 13. One complete side-by-side

```rust
// FH — commutativity of addition, from nothing
enum N { Z, S(N) }

fn add(a: N, b: N) -> N {
  match a { N::Z => b, N::S(k) => N::S(add(k, b)) }
}

theorem add_z(a: N) -> (add(a, N::Z) == a) {
  prove { induction a with
    | Z => rfl
    | S k ih => simp [add, ih] }
}

theorem add_s(a: N, b: N) -> (add(a, N::S(b)) == N::S(add(a, b))) {
  prove { induction a with
    | Z => rfl
    | S k ih => simp [add, ih] }
}

theorem add_comm(a: N, b: N) -> (add(a, b) == add(b, a)) {
  prove { induction a with
    | Z => simp [add, add_z]
    | S k ih => simp [add, add_s, ih] }
}
```
```lean
inductive N where | Z : N | S : N → N

def add : N → N → N
  | .Z, b => b
  | .S k, b => .S (add k b)

theorem add_z (a : N) : add a .Z = a := by
  induction a with
  | Z => rfl
  | S k ih => simp [add, ih]

theorem add_s (a b : N) : add a (.S b) = .S (add a b) := by
  induction a with
  | Z => rfl
  | S k ih => simp [add, ih]

theorem add_comm (a b : N) : add a b = add b a := by
  induction a with
  | Z => simp [add, add_z]
  | S k ih => simp [add, add_s, ih]
```
Every concept in this document appears in those thirty lines: an `enum` generating its own induction principle; a recursive `fn` that is secretly a proof; two lemmas as generic functions; hypotheses as arguments; `ih` as a recursive call; `simp`/`rfl` as computation-as-proof; and the whole thing readable by any Rust programmer on the left while being, on the right, exactly what a referee receives. That double-readability is the project; this table is its dictionary.
