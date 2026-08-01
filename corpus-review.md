# Ferris–Howard Stress Corpus & Adversarial Review

**Status:** Draft 0.2 (amended 2026-08-01: reconciled with `design.md`; F18 migration executed) · Companion to `design.md`
**Standing decision (recorded):** theorem declarations require the `theorem` keyword. No automatic Prop-detection. The governing principle throughout this review is *explicit over implicit*; every finding below is resolved in that direction unless doing so destroys readability, and each such exception is flagged.

Each group below gives the mathematics, the proposed Ferris–Howard rendering, and the ambiguities it flushed out (tagged `F1`–`F16`). Consolidated rulings follow in the review section. These files are the seed of the golden-test suite: every group should become `Tests/corpus/gNN_*.lean` (FH-in-`.lean` embedding through M2 — design.md §2; a standalone `.fh` fixture form arrives with M3) with its findings encoded as positive or negative tests.

---

## Group 1 — Peano arithmetic (recursion, induction, `==`)

```rust
enum N { Zero, Succ(pred: N) }

fn add(a: N, b: N) -> N {
    match b {
        N::Zero => a,
        N::Succ(b2) => N::Succ(add(a, b2)),
    }
}

theorem add_zero(a: N) -> add(a, N::Zero) == a {
    lean! { rfl }
}

theorem add_comm(a: N, b: N) -> add(a, b) == add(b, a) {
    lean! { induction b <;> simp [add, *] }
}
```

Stresses: structural recursion inference (no attribute needed), `::` path syntax mapping to Lean namespaces, `==` as propositional equality in return position, plain (unindexed) enums. No new findings — this is the group that must Just Work in M0/M1.

## Group 2 — Group theory (laws-as-fields, nullary inference)

```rust
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
    lean! { simpa using congrArg id (h Grp.e) }  // sketch; real proof in tests
}
```

Stresses: proof obligations as trait fields; hypotheses that are themselves quantified Props (`h`'s type is a `for<>`). **F1 (nullary inference):** `Grp::e()` has no argument from which to infer `G` — same situation as Rust's `Default::default()`, which Rust resolves from expected type. Adversarial question: is expected-type-driven resolution acceptable implicitness? Ruling below (yes, with a turbofish escape: `Grp::e::<G>()`), because Rust programmers already have exactly this intuition. **F2 (multiple binders, shared type):** `for<a, b, c: Self>` — Rust generic lists don't share bounds this way (`<a, b, c: Self>` in Rust means only `c` is bounded). We diverge deliberately: in `for<>`/`exists<>` binder lists, a type ascription distributes over the *unascribed prefix*. Divergence from Rust must be documented loudly; negative test required for the Rust reading.

## Group 3 — Order theory (Prop-valued operators, implication, iff)

```rust
trait POrder<Self> {
    fn le(a: Self, b: Self) -> Prop;

    refl:     for<a: Self> a <= a;
    antisymm: for<a, b: Self> (a <= b) -> (b <= a) -> a == b;
    trans:    for<a, b, c: Self> (a <= b) -> (b <= c) -> (a <= c);
}

// A Galois connection between two ordered types.
fn galois_connection<A, B>(f: A -> B, g: B -> A) -> Prop
where A: POrder, B: POrder
{
    for<a: A, b: B> (f(a) <= b) <-> (a <= g(b))
}
```

**F3 (implication):** hypothesis chains need an arrow in expression position. Resolution: since propositions *are* types, implication *is* the function arrow — `->` becomes a first-class right-associative operator of the unified expression grammar, lowest precedence. `(a <= b) -> (b <= a) -> a == b` is `a ≤ b → b ≤ a → a = b`. This is not new syntax; it is the type-arrow made available everywhere, which the unified grammar already implied. **F4 (iff):** no Rust spelling exists; adopt `<->`, precedence just above `->`. **F5 (Prop-valued comparisons):** `<=`, `<`, `>`, `>=` denote the mathematical relations (`≤` etc.), i.e. Props, not Bools. This is the single most consequential ruling in the review — see "Prop-first operators" below, and Group 11 for the `if` consequence. **F6 (comparison vs. generics):** `a < b` in type/expression position collides with generic application `a<...>`. Ruling: in any position where `<` could open a generic argument list, a comparison must be parenthesized — `(a < b)` — enforced by the parser with a targeted error ("if you meant less-than, add parentheses"). The corpus above already obeys this. Negative test: `fn f(h: a < b)` unparenthesized must fail with that message.

## Group 4 — Real analysis: ε–δ limits (nested quantifiers, precedence)

```rust
fn tends_to(f: Real -> Real, a: Real, L: Real) -> Prop {
    for<eps: Real> (eps > 0) ->
        exists<delta: Real> (delta > 0) &&
            for<x: Real>
                ((0 < (x - a).abs()) && ((x - a).abs() < delta)) ->
                    ((f(x) - L).abs() < eps)
}

theorem limit_unique(f: Real -> Real, a: Real, L1: Real, L2: Real,
                     h1: tends_to(f, a, L1), h2: tends_to(f, a, L2))
    -> L1 == L2
{
    todo!()
}
```

Stresses: function types as parameter types (`Real -> Real` — the F3 arrow again, now in type position, same operator); deep quantifier alternation; method-call chains inside Props. **F7 (precedence table):** the interaction of `->`, `<->`, `&&`, `||`, comparisons, and arithmetic must be specified once, normatively. Ruling: from loosest to tightest, `->` (right-assoc), `<->`, `||`, `&&`, `!`, comparisons (non-associative — `a < b < c` is a parse error, matching Rust and avoiding a classic math-notation trap), then Rust's arithmetic precedence unchanged. `exists<>`/`for<>` scope extends as far right as possible (like Lean's `∀`, unlike C's declarators); parenthesize to stop them early. Golden tests must pin every row of this table.

## Group 5 — Linear algebra: rank–nullity (bundled morphisms, types as arguments)

```rust
theorem rank_nullity<K, V, W>(f: LinearMap<K, V, W>)
    -> finrank(K, ker(f)) + finrank(K, range(f)) == finrank(K, V)
where K: Field, V: AddCommGroup + Module<K> + FiniteDimensional<K>,
      W: AddCommGroup + Module<K>
{
    lean! { exact Submodule.finrank_quotient_add_finrank ... }  // via first iso thm
}
```

Stresses: multi-parameter classes (`Module<K>` — Self is `V`, `K` is the extra parameter, matching §4.4's convention); `+`-composition of bounds mapping to multiple instance binders. **F8 (types as term arguments):** `finrank(K, V)` passes types in value position. In the unified grammar this is well-formed (types are terms); the finding is purely psychological — Rust eyes expect `finrank::<K, V>()`. Ruling: both are accepted and identical; corpus and docs prefer the term-position form for arguments Mathlib declares explicit, turbofish for implicits being forced. Bundled morphism types (`LinearMap<K, V, W>` for `V →ₗ[K] W`) need no new syntax, only bridge aliases — record `LinearMap`, `RingHom`, `MonoidHom` in `Bridge/`.

## Group 6 — Combinatorics: the binomial theorem (big operators, coercions)

```rust
theorem binomial<R>(x: R, y: R, n: Nat)
    -> (x + y).pow(n)
        == Finset::range(n + 1).sum(|k| (choose(n, k) as R) * x.pow(k) * y.pow(n - k))
where R: CommRing
{
    lean! { exact Commute.add_pow (Commute.all x y) n }
}
```

Stresses: big operators via iterator-method style — `Finset::range(n+1).sum(|k| ...)` needs no Σ syntax, closures-as-binders carry it, and it maps to `Finset.sum` directly. **F9 (coercion explicitness):** `choose(n, k)` is a `Nat` being multiplied into `R`. Lean/Mathlib inserts `↑` coercions semi-silently; our explicitness principle rules the opposite: **coercions are always written**, as `expr as T` (elaborating to `(↑expr : T)`). Silent unification-driven coercion is disabled in FH-elaborated code. This will occasionally be verbose (chained coercions in analysis); accepted cost, revisit only with usage evidence. Corollary ruling **F10 (ascription vs. coercion):** `(e: T)` in expression position is *type ascription* (elaboration hint, no coercion inserted); `e as T` is *coercion*. Distinct operations, distinct syntax — a distinction Lean spells `(e : T)` vs `(↑e : T)` and Rust conflates into `as`; we keep both meanings separable because Mathlib proofs constantly need ascription-without-coercion.

## Group 7 — Number theory: our home turf (Fact bounds, named arguments)

```rust
theorem fermat_little<P: Nat>(a: Fp<P>) -> a.pow(P) == a
where P: Prime
{
    lean! { exact ZMod.pow_card a }
}

theorem primes_infinite() -> for<n: Nat> exists<p: Nat> (p > n) && p.Prime {
    lean! { intro n; exact Nat.exists_infinite_primes (n + 1) |>.imp (by omega) }
}

theorem crt(a: Nat, b: Nat, m: Nat, n: Nat, h: coprime(m, n))
    -> exists<x: Nat> congruent(x, a, modulus: m) && congruent(x, b, modulus: n)
{
    todo!()
}
```

Stresses: the flagship `where P: Prime` → `[Fact P.Prime]` bridge; `p.Prime` as generalized dot notation reaching `Nat.Prime p` (dot syntax on a Prop-valued family — Lean handles this natively and *case-sensitively*, we inherit; the spelling is `p.Prime`, never `p.prime`, per design §6's no-mangling policy). Note also: no `const` modifier on `<P: Nat>` — FH angle-bracket generics are already implicit binders over values as well as types (design §4.1's dependency), so Rust's const-generic marker adds nothing and is not FH syntax. **F11 (named arguments):** `congruent(x, a, modulus: m)` — Rust has no named args; Lean does (`(modulus := m)`). Ruling: adopt `name: expr` in call position mapping to Lean named arguments. Grammar check: in Rust, `ident: expr` inside a call is currently ill-formed, so the syntax is free; no collision with struct literals (brace-delimited) or ascription (paren-delimited, F10). This also retroactively blesses the keyword-argument idiom from our notation discussions.

## Group 8 — Set theory: Cantor's theorem (membership, negation, set-builder)

```rust
fn injective<A, B>(f: A -> B) -> Prop {
    for<a1, a2: A> (f(a1) == f(a2)) -> a1 == a2
}

fn surjective<A, B>(f: A -> B) -> Prop {
    for<b: B> exists<a: A> f(a) == b
}

theorem cantor<A>(f: A -> Set<A>) -> !surjective(f) {
    // diagonal set: those x not members of their own image
    let d: Set<A> = {x: A | !(x in f(x))};
    lean! { intro hsurj; obtain ⟨a, ha⟩ := hsurj d; ... }
}
```

**F12 (membership):** adopt `in` as a binary Prop operator, `x in s` → `x ∈ s`. Grammar-safe: Rust reserves `in` but uses it only inside `for` loops, and our `for<>` quantifier is bracketed, so no collision — negative test to confirm `for` headers never capture it. **F13 (set-builder vs. subtype):** `{x: A | P(x)}` appears in *term* position (a `Set<A>`, i.e. `A -> Prop`) and in *type* position (a subtype, `{r: Nat | P(r)}` as in Group 12). Same surface, two elaborations, disambiguated by position — acceptable because the two meanings are the same mathematical idea (comprehension) and Lean itself uses `{x | P}` for both `Set` and `Subtype` notation. The brace-expression escape in generic args (`Vector<T, {n*2}>`) is distinguished by the absence of `ident:` + `|` — parser rule with two-token lookahead; both readings get golden tests.

## Group 9 — Category theory (universes, dependent fields)

```rust
#[universes(u, v)]
trait Cat<Self: Space<u>> {
    fn Hom(a: Self, b: Self) -> Space<v>;

    fn id<a: Self>() -> Hom(a, a);
    fn comp<a: Self, b: Self, c: Self>(f: Hom(a, b), g: Hom(b, c)) -> Hom(a, c);

    id_comp: for<a, b: Self> for<f: Hom(a, b)> comp(id(), f) == f;
    comp_id: for<a, b: Self> for<f: Hom(a, b)> comp(f, id()) == f;
    assoc:   for<a, b, c, d: Self>
             for<f: Hom(a, b), g: Hom(b, c), h: Hom(c, d)>
                 comp(comp(f, g), h) == comp(f, comp(g, h));
}
```

Stresses: a field whose *type* is computed by applying another field (`Hom(a, b)` in binder and return positions — full dependency inside a trait body); explicit universes via `Space<u>` and the `#[universes]` attribute; `id()`'s object argument inferred from context (F1 again, harder — needs the expected-type machinery to thread through `comp`'s unification; this group is the acid test for it). No new findings, but Group 9 is deliberately the elaboration stress-maximum: if stage-one macros can expand this to Lean `class` syntax and Lean elaborates it, the architecture is validated. Schedule it as the M2 gate alongside the conversation file.

## Group 10 — Probability: PMF monad (do-notation, `?`)

```rust
fn two_flips() -> PMF<Bool> {
    let x = PMF::bernoulli(half)?;
    let y = PMF::bernoulli(half)?;
    PMF::pure(x.xor(y))
}

theorem two_flips_fair() -> two_flips() == PMF::bernoulli(half) {
    lean! { ext b; fin_cases b <;> simp [two_flips, PMF.bernoulli] <;> ring }
}
```

Stresses: `?` as monadic bind in an arbitrary monad (not `Result`) — the block elaborates as `do`, monad inferred from the return type; explicit `pure` in tail position (no silent return-lift — explicitness again); `x.xor(y)` because `^` remains arithmetic. Finding-free if §4.7 is implemented as designed; the test value is confirming `?` behaves *identically* across `Option`, `Except`, `PMF`, and `StateM` (four golden tests, one per monad).

## Group 11 — Logic (negation, Decidable, dependent if)

```rust
theorem demorgan<p: Prop, q: Prop>() -> !(p || q) <-> (!p && !q) {
    lean! { tauto }
}

fn min2(a: Nat, b: Nat) -> Nat {
    if a <= b { a } else { b }
}

fn find_root(f: Nat -> Nat, bound: Nat) -> Option<Nat> {
    Finset::range(bound).toList().find(|n| decide(f(n) == 0))
}
```

**F14 (the price of Prop-first, paid here):** because `a <= b` is a Prop, `if a <= b { ... }` cannot be Bool-tested — it elaborates to Lean's decidable-if, requiring a `Decidable (a ≤ b)` instance. For `Nat`, `Real` (classically), and everything Mathlib-standard, instances exist and the code reads exactly like Rust; for exotic Props the error message must say "no Decidable instance" in those words. This is the *correct* semantics (it's Lean's own), and the Rust-reading is preserved — but it's the review's biggest hidden semantic shift, so it gets a doc section and a dedicated error. Where a genuine `Bool` is needed (HOF interfaces like `find`), `decide(p)` converts explicitly — F5's companion. **F15 (dependent if):** proofs sometimes need the hypothesis in scope: adopt `if h @ (a <= b) { /* h: a <= b */ } else { /* h: !(a <= b) */ }`, reusing Rust's `@` pattern-binding. Rust precedent makes it readable; maps to `if h : a ≤ b then _ else _`.

## Group 12 — Verified computation: gcd with specification (termination, subtypes, dvd)

```rust
#[terminates_by(b)]
fn gcd2(a: Nat, b: Nat) -> Nat {
    if b == 0 { a } else { gcd2(b, a % b) }
}

theorem gcd2_dvd(a: Nat, b: Nat) -> gcd2(a, b).dvd(a) && gcd2(a, b).dvd(b) {
    todo!()
}

theorem gcd2_greatest(a: Nat, b: Nat, d: Nat, ha: d.dvd(a), hb: d.dvd(b))
    -> d.dvd(gcd2(a, b))
{
    todo!()
}

fn nat_sqrt(n: Nat) -> {r: Nat | (r * r <= n) && (n < (r + 1) * (r + 1))} {
    todo!()
}
```

Stresses: `#[terminates_by]` with the well-founded measure (`b` decreases — our monovariant discussion, now as an attribute); `if b == 0` exercising F14 (Decidable Eq on Nat — fine); divisibility as method `d.dvd(a)` → `d ∣ a` (**F16, unicode policy:** ASCII-method spellings are canonical for every Mathlib notation without a Rust operator — `.dvd()`, `.union()`, `.comp()`; Unicode operator input is a v2 opt-in, never required — keeps the corpus typeable everywhere); subtype in return position via F13's type-position comprehension, elaborating to `{r : Nat // r*r ≤ n ∧ n < (r+1)*(r+1)}` with the value–proof pair introduced by F10 ascription + tuple syntax.

---

# Adversarial Review — Consolidated Rulings

**Ruling A: Prop-first operator semantics (F3, F4, F5, F12, F14, and Group 4's `&&`).** The comparison, equality, and logical operators of Rust are reassigned to their *mathematical* meanings: `==`/`!=` are `Eq`/`Ne`, `<= < > >=` are order relations, `&& || !` are `∧ ∨ ¬`, `->` is implication/function-arrow, `<->` is `Iff`, `in` is `∈`. Bool is demoted to an ordinary type reached explicitly: `decide(p)` for Prop→Bool, methods (`.xor`, `.band`) for Bool algebra. There is no expected-type-driven double reading of any operator — the earlier design's "`||` means `∨` when in Prop position" is *revoked* as hidden implicitness; one operator, one meaning, everywhere. This inverts Rust's priorities to match the domain's: in a mathematics frontend, propositions are the common case. The entire cost is F14's Decidable-if, which is Lean's own semantics and correctly surfaces exactly where classical/computable distinctions genuinely live.

**Ruling B: parenthesization over parser cleverness (F6, F7).** Comparisons adjacent to generic-argument position require parens; `a < b < c` is an error; the precedence table in F7 is normative and frozen pre-M1 (changing precedence after users exist is a breaking change of the worst kind). We accept slightly noisier source over backtracking parsers — every backtrack is a future ambiguity report.

**Ruling C: sanctioned implicitness, enumerated and closed.** Four places retain expected-type-driven behavior, each with an explicit escape: nullary/output-position inference (F1; escape: turbofish), tuple-syntax anonymous constructors for `Exists`/`Sigma`/structures (escape: named constructor), monad inference for `?`-blocks (escape: ascribe the block, F10), and `exists` with a `Space`-valued body electing `Sigma`/`Subtype` from the expected type (design §4.2; escape: F10 ascription). Everything else is explicit: theorem keyword (standing decision), coercions written as `as` (F9), ascription distinct from coercion (F10), `pure` written in do-tails (Group 10), `decide` written at Prop/Bool boundaries (Ruling A). The review's meta-rule: implicitness is permitted only where Rust itself already trained the intuition (`Default::default()`, `.into()`-style inference), because there it *is* the Rust reading experience.

**Ruling D: acknowledged divergences from Rust, to be documented as a "differences" page.** Distributed binder ascription in `for<>`/`exists<>` (F2); types in term position (F8); named arguments (F11); `@`-binding on `if` (F15); comprehension braces (F13); `in` outside loops (F12). Amended 2026-08-01: the F17/F18 constructs are Ruling-D entries too — ambient `var` declarations with mention-based inclusion and the `include` escape, ambient hypotheses, the `Space` kind vocabulary, and trait-names-in-annotation-position (all confined: declaration forms Rust doesn't have). Each is either a strict extension (ill-formed Rust becomes well-formed FH) or confined to constructs Rust lacks — none changes the meaning of a construct that is *also* legal Rust. That invariant ("legal-Rust-lookalike code never silently means something different"... with the sole, loudly-documented exception of Ruling A's operators, which is why Ruling A is the headline) is worth enforcing forever: add a CI check that every grammar change is classified extension/confined/violation, and violations need this document amended first.

**Ruling E: corpus as specification.** These twelve groups become `Tests/corpus/` with the F-findings as named test cases (positive and negative). Implementation order recommendation for the agents: Groups 1→3→4 (grammar core: F3–F7 are load-bearing for everything), then 8/11/12 (the Prop-first consequences), then 2/9 (trait/elaboration depth), then 5/6/7/10 (bridge + ergonomics). Group 9 gates M2.

## Amendments (post-review)

**F17 (ambient variables).** `var` declarations at module scope, expanding to Lean's `variable`: mandatory declaration sites (auto-binding rejected — Mathlib's disabling of `autoImplicit` is the cited precedent: typo'd identifiers silently becoming quantified type variables is the exact implicitness class this review exists to exclude), independent generalization per declaration, mention-based inclusion with `include` escape, shadowing requires full restatement plus lint. Full spec in design doc §4.9. Corpus impact: Groups 3, 8, 9 to be rewritten in `var` style alongside their inline-generic originals — both forms must elaborate identically, which is itself a golden test. The ambient-hypothesis mention rule (`var h: eps > 0;` included only when mentioned) gets a dedicated positive/negative test pair.

**F18 (kind vocabulary).** `Space` replaces `Type` in all FH kind positions (`Space<u>` for explicit universes, `Sort<u>` escape, `Prop` unchanged); trait names are legal in annotation position of `var` and generics, folding carrier + structure (`var G: Grp;` → `(G : Type*) [Grp G]`), disambiguated by name resolution (type vs. trait), classified Ruling-D-confined. Kind keywords and `#[role(...)]` refinements persist as structured metadata surfaced via `fh check`/`fh mcp`; binding roles (parameter/ambient/bound/witness/temporary) are computed by tooling, never user-annotated. Corpus impact: all groups' `Type<u>` occurrences (Group 9 especially) migrate to `Space<u>`; Group 9's `trait Cat<Self: Type<u>>` becomes `trait Cat<Self: Space<u>>`. (Migration executed 2026-08-01 — Group 9 above now reads `Space<u>`/`Space<v>`, and design §4.4's `Semigroup` example reads `Self: Space`.)

**Open after review:** whether `!` on Bool should hard-error (forcing `.bnot()`) or coerce via `decide` — leaning hard-error for symmetry with Ruling A; whether F6's parenthesization requirement can be relaxed inside `for<>` bodies where no generic application can occur (leaning no — one rule, everywhere); and the `half` literal in Group 10 (rational literals: `1/2` as `Real` division vs. `Rat` literal — needs a literals-and-elaboration mini-design, since numeric literal polymorphism is Lean's own subtlest UX area and we should not improvise it). **Amendment (2026-08-01): the literals mini-design is pulled forward from pre-M2 to pre-M1.** Integer literals (`n + 1`, `if b == 0`, `range(n + 1)`) already permeate M0/M1 corpus code, and Lean's `OfNat` numeral elaboration is expected-type-driven — which Ruling C's closed list does not currently sanction. The mini-design must add that entry deliberately (recommended shape: inherit Lean's `OfNat`/`OfScientific` behavior as sanctioned item five, escape: F10 ascription) rather than leave polymorphic literals as unsanctioned implicitness by accident.