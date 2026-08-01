# Ferris–Howard: A Rust-Syntax Frontend for Lean 4

**Status:** Draft 0.2 (amended 2026-08-01: corpus-review Rulings A–E and F16–F18 folded in; host-embedding, repo-layout, and toolchain-pin decisions recorded) · **Architecture:** Lean-native macro frontend (in-process elaboration)
**Working name:** Ferris–Howard, after the correspondence we intend to exploit.

## 1. Goals and non-goals

The goal is a Lean 4 package that lets you write mathematics — definitions, trait/class hierarchies, theorem statements, and eventually proofs — in Rust-flavored surface syntax, elaborating in-process against Mathlib. The measure of success is concrete: the trait hierarchy, generic theorems, and conjecture stubs from our "conversation as a crate" file should elaborate as real Lean declarations, with `EuclideanDomain` bound to Mathlib's `EuclideanDomain`, `euclids_lemma` checked against `Nat.Prime.dvd_mul`, and `todo!()` producing tracked `sorry` warnings.

Non-goals, at least for versions 0 and 1: replicating Rust's operational semantics (ownership, lifetimes, `unsafe` — meaningless here and deliberately absent); full Rust-syntax metaprogramming (no proc-macro analogue; Lean's own metaprogramming remains the extension mechanism, reachable through an escape hatch); and source-compatibility with rustc (we borrow Rust's syntax and *reading experience*, not its grammar spec — where Rust's grammar fights Lean's semantics, Lean's semantics wins and we invent the minimal syntax extension).

One framing principle governs every design decision below. Rust syntax earned its place in this project as a *reading aid*: parameters vs. bound variables, trait bounds as hypotheses, return types as conclusions, `where` clauses as side conditions. Every extension we add must preserve that property — a Rust programmer with no Lean experience should be able to read a Ferris–Howard file and correctly identify what is being claimed, even when they couldn't yet write it. When we must choose between Rust-faithfulness and Lean-expressiveness, we ask: which choice keeps statements *readable as signatures*?

## 2. Architecture

The package defines top-level *per-declaration* command syntax via Lean's syntax extension machinery. **Decided (2026-08-01):** per-declaration commands, not a monolithic `rust { }` block — better incremental elaboration and precise error spans — and FH code lives inside ordinary `.lean` files through M2, so the IDE story below is inherited directly. A standalone `.fh` file format (Lake facet + preprocessor + LSP forwarding) is a materially different architecture and is deliberately deferred to M3/the agent layer. The machinery: `declare_syntax_cat` for our grammatical categories (rust-items, rust-patterns, and a *single* rust-expression category serving both term and type positions — the unified-grammar decision of §4.1; there is deliberately no separate rust-types category), parser descriptions for each production, and then a translation layer.

The translation layer should be **two-stage**, and this is the most important early implementation decision. Stage one is macro expansion: `macro_rules`-style rewrites from our syntax categories into *Lean surface syntax* — `fn` becomes `def`, `trait` becomes `class`, and so on — so that Lean's own elaborator does all type checking, universe inference, and instance resolution, and so that everything downstream (error messages, `#print`, Mathlib interop, the InfoView) behaves as if the user had written idiomatic Lean. Stage two, used only where pure syntax-to-syntax rewriting can't express the translation, is `elab_rules`: direct elaboration with access to the environment, needed for name-resolution policy (section 6), attribute bridging, and the places where one Rust item must expand to *several* Lean declarations (e.g., an `enum` that emits an inductive plus derived instances plus namespace aliases).

Favor stage one relentlessly. Every construct handled by macro expansion is a construct whose error messages, tooling, and forward compatibility we get for free; every `elab_rules` use is bespoke code agents must maintain against Lean's internal APIs. A useful discipline for the agent workstream: each feature PR must state which stage it uses and justify any stage-two usage.

Because we elaborate in-process, the IDE story is inherited rather than built: the Lean language server sees our syntax nodes, hover and go-to-definition work wherever we correctly attach source spans during expansion (span preservation is a hard requirement on every macro — sloppy spans are the number-one cause of unusable DSLs in Lean), and the proof-state InfoView works inside escape-hatch tactic blocks with zero effort from us.

Repository shape (**decided 2026-08-01** — monorepo, git repo named `ferris-howard`): `lean/` holds the Lake package `FerrisHoward` with `Syntax/` (parser declarations), `Expand/` (stage-one macros), `Elab/` (stage-two elaborators), `Bridge/` (the Mathlib name/notation bridge, section 6), and `Tests/` (golden files, section 8), plus later the Atlas extractor metaprogram; `crates/` holds the Cargo workspace (`fh-atlas`, later `fh-cli`/`fh-mcp`); design docs live at the repo root. Mathlib as a dependency from day one — its presence is the entire point. Toolchain policy: pin a stable Lean toolchain + the matching Mathlib release tag, commit the manifest, and bump only at milestone boundaries in a dedicated PR that re-runs every test tier (error-substring negative tests and pretty-printed goldens both drift across Lean versions, so bumps are a scheduled event, never a drive-by).

## 3. The core mapping

The uncontroversial spine, mostly settled in prior discussion. Each row is a stage-one macro.

| Rust surface | Lean target | Notes |
|---|---|---|
| `fn f(x: T) -> U { e }` | `def f (x : T) : U := e` | body is an expression |
| `fn f(...) -> U;` (no body) | `def f ... : U := sorry` | axioms use `extern "axiom"` (§4.6) |
| `trait C { ... }` | `class C (α : Type u) ...` | see §4.4 for the self-type |
| `trait C: D + E` | `class C ... extends D, E` | supertraits = `extends` |
| `impl C for T { ... }` | `instance : C T := { ... }` | named via `#[name(...)]` if needed |
| `where T: C + D` | `[C T] [D T]` binders | instance-implicits |
| `struct S { a: T, b: U }` | `structure S where a : T; b : U` | field syntax matches |
| `enum E { A(T), B }` | `inductive E \| A : T → E \| B : E` | extended in §4.5 |
| `match e { pat => body }` | `match e with \| pat => body` | near-verbatim |
| `mod m { ... }` / `use` | `namespace m ... end` / `open` | |
| `type X = ...;` | `abbrev X := ...` | `#[def]` for `def`-transparency |
| `todo!()` / `todo!("msg")` | `sorry` (message in a log) | project-wide sorry report |
| `let x = e; ...` | `let x := e; ...` | |
| `\|x\| body` (closure) | `fun x => body` | closures ARE lambdas; load-bearing in §4.2 |
| `#[attr]` | `@[attr]` | pass-through: `#[simp]`, `#[ext]`, `#[instance]`… |

Theorems are the special case worth pinning down precisely, since they're the heart of the reading experience. **Standing decision (corpus review):** theorem declarations require the `theorem` item keyword — `theorem name(args) -> conclusion { body }` — with no automatic Prop-detection of `fn`s. The earlier proposals (automatic detection, `thm fn`, `#[theorem]`) are superseded; explicit over implicit.

```rust
theorem euclids_lemma<p: Nat, a: Nat, b: Nat>(hp: p.Prime, h: p.dvd(a * b))
    -> p.dvd(a) || p.dvd(b)
{
    lean! { exact (Nat.Prime.dvd_mul hp).mp h }
}
```

Operator semantics follow corpus-review Ruling A: every operator has **one meaning, everywhere**. `==`/`!=` are `Eq`/`Ne`; `&& || !` are `∧ ∨ ¬`; `->` is implication (the function arrow, available in every expression position); `<->` is `Iff`; `<= < > >=` are the order relations; `in` is `∈` — all Props, unconditionally. There is no expected-type-driven double reading (an earlier draft's "`||` means `∨` when the expected type is `Prop`" is revoked as hidden implicitness). `Bool` is an ordinary type reached explicitly: `decide(p)` at Prop→Bool boundaries, methods (`.xor()`, `.band()`) for Bool algebra; the entire cost is F14's decidable-`if`, which is Lean's own semantics. Divisibility above illustrates F16: Mathlib notations without a Rust operator get canonical ASCII method spellings (`p.dvd(a)` for `p ∣ a`); Unicode operator *input* is a v2 opt-in, never required. Rust's operator vocabulary still maps onto propositions with almost no invention — it just does so unconditionally.

## 4. Covering Lean's full semantic surface

This is the research question you posed: what must be *added* to Rust-ish syntax so that everything Lean can express is expressible. Lean's semantic surface, enumerated: dependent function types; three binder classes (explicit, implicit, instance, plus strict-implicit); a universe hierarchy with `Prop` at the bottom and universe polymorphism; a unified term/type language; inductive families (indexed, recursive, mutual, nested); structures with inheritance and default fields; definitional classes; pattern matching with dependent motives; recursion with termination evidence; `partial`/`unsafe`/`noncomputable` definition modifiers; `axiom` and `opaque`; do-notation over arbitrary monads; anonymous constructors and structure instances; coercions; custom notation; and the metaprogramming tower (excluded by scope, reachable by escape hatch). Taking these in order of how much design they demand:

### 4.1 Dependent signatures — the one true extension

Rust separates the type language from the term language; Lean unifies them, and dependency is the reason. The minimal, sufficient extension: **later binders and the return type may refer to earlier parameter names.**

```rust
fn replicate<T>(n: Nat, x: T) -> Vector<T, n>;
fn get<T, n: Nat>(v: Vector<T, n>, i: Fin<n>) -> T;
```

`Vector<T, n>` with `n` a *parameter* rather than a const generic literal is ill-formed Rust and exactly well-formed Lean (`Vector T n`). Grammar-wise this costs nothing — we simply resolve identifiers in type position against in-scope binders before falling back to constants. The deep consequence: **our "type" grammar must be the full expression grammar** with Rust type sugar (`&`, generics-angle-brackets, tuples) as notation on top. Recommend implementing it that way from the start — a single `rustExpr` category used in both positions — rather than maintaining two grammars that must be merged later. This single decision is what makes everything else in this section fall out naturally: `Fin<n+1>`, `Vector<T, {n*2}>` (braces to disambiguate expression-in-type where the grammar needs help, like Rust's const-generic brace escape, which Rust programmers already know), and propositions-as-return-types are all just expressions.

### 4.2 Binders: the four classes, and quantifiers

Lean has explicit `(x : T)`, implicit `{x : T}`, instance `[C T]`, and strict-implicit `⦃x : T⦄` binders. The mapping that preserves Rust's reading experience:

Angle-bracket generics `<T, n: Nat>` become **implicit** binders — this matches Rust intuition perfectly, since Rust generics are inferred at call sites exactly as Lean implicits are. Ordinary parentheses parameters are **explicit** binders. `where` clauses become **instance** binders, also matching intuition (you never pass a trait impl explicitly in Rust either). Strict-implicits are rare enough for an attribute: `#[strict] <x: T>`. Turbofish `f::<Nat>(x)` maps to explicit instantiation `f (α := Nat) x` or `@f Nat x` — keep turbofish, it's beloved.

Quantifiers need surface syntax because they appear inside types constantly. Two Rust-native gifts solve this. Rust already has higher-ranked binder syntax, `for<'a>`, which we generalize: **`for<x: Nat> P(x)` is `∀ x : Nat, P x`**. And closures give existentials a binder: **`exists<x: Nat> P(x)`** as the dual (new keyword, same shape). Lambda is just closure syntax, already in the table. So:

```rust
theorem primes_infinite() -> for<n: Nat> exists<p: Nat> (p > n) && p.Prime;
```

reads as a signature and elaborates to `∀ n, ∃ p, p > n ∧ p.Prime`. Dependent pairs (`Σ`-types, the data-carrying `∃`) come along free: `exists` with a `Space`-valued body elaborates to `Sigma`/`Subtype` per expected type, and the anonymous-constructor bridge (§4.7) provides `(w, h)` introduction. (This expected-type disambiguation is sanctioned-implicitness item four in corpus-review Ruling C; the escape is F10 ascription.)

### 4.3 Universes and `Prop`

The hierarchy `Prop = Sort 0`, `Type = Sort 1`, `Type 1`, … with polymorphism over universe variables. Recommendation: **make universe polymorphism invisible by default.** Lean's `autoBound` behavior already infers universe parameters for most declarations; our expansion should lean on that, so users write `T: Space` (or nothing — a bare `<T>` defaults to `Space<_>`) and get polymorphic declarations. (`Space` is FH's kind vocabulary for Lean's `Type` — see §4.9; it elaborates to `Type*`/`Type u` unchanged.) For the rare explicit case, universe variables as a reserved generic namespace: `<T: Space<u>, U: Space<v>>` with `#[universes(u, v)]` available when ordering matters. `Prop` is simply a type you can name; no special syntax. The one rule users must learn — and it's a rule of the mathematics, not of our syntax — is the `Prop`/`Type` distinction itself, which we surface rather than hide: proofs erase, data doesn't, and our docs should teach it as the `PhantomData` intuition from our earlier discussion.

### 4.4 Traits → classes, honestly this time

Three deltas from Rust's trait model. First, **laws become fields.** The doc-comment axioms from our crate file are now real:

```rust
trait Semigroup<Self: Space> {
    fn op(a: Self, b: Self) -> Self;
    assoc: for<a: Self, b: Self, c: Self> op(op(a, b), c) == op(a, op(b, c));
}
```

A bare `name: <prop>` field in a trait is a proof obligation carried by every `impl` — which may discharge it with a term, a `lean!{}` tactic block, or `todo!()`. This is the payoff feature of the whole project and should be in milestone 1.

Second, the self-type: Lean classes are parameterized over their carrier explicitly, and multi-parameter classes are routine (`Module R M`). Surface: `Self` is sugar for the first class parameter (declared as `trait Semigroup<Self>` or implicitly), and additional parameters are just more generics — `trait Module<R, Self> where R: Ring`. Rust's coherence/orphan rules do **not** carry over (Lean has no orphan rule; Mathlib depends on that), which resolves a tension we noted earlier: we adopt Lean's permissiveness and surface diagnostics instead (a lint when an `impl` would shadow an existing instance — cheap to implement, addresses the real Mathlib pain point diagnostically rather than prohibitively).

Third, associated types and consts map to `outParam` class parameters and fields respectively; `fn` items with bodies inside a `trait` are default field values. All three are mechanical.

### 4.5 Inductives: enums grow indices

Rust enums cover plain and recursive inductives already. Lean's indexed families (GADTs) need one extension, foreshadowed in our design conversation: **per-variant return types.**

```rust
enum Vector<T, _: Nat> {
    Nil -> Vector<T, 0>,
    Cons<n: Nat>(head: T, tail: Vector<T, n>) -> Vector<T, n + 1>,
}
```

Absent an arrow, the variant targets the uniform type (ordinary Rust enum). Present, it declares the index — and the `_` in the header marks index positions (varying per-constructor) versus parameters (uniform). Mutual and nested inductives: a `mutual { ... }` block containing several items, mapping to Lean's `mutual ... end`. `structure` inheritance (`extends`) is already covered by the trait row; plain structs with `extends` get the same keyword.

### 4.6 Recursion, termination, and the definition modifiers

Lean demands totality evidence; Rust assumes divergence is fine. Surface policy: recursive `fn`s elaborate to `def` and inherit Lean's automatic structural/well-founded inference, which handles most textbook recursion silently. When inference fails, the user supplies `#[terminates_by(measure_expr)]` (→ `termination_by`) and optionally `#[decreasing_by(lean!{...})]`. The opt-outs are modifiers with Rust-flavored spellings: `#[partial]` (→ `partial def`, no induction principle — teach this loudly), `#[noncomputable]` (→ `noncomputable`, the specification-not-program marker from our language-design discussion), `#[opaque]` (→ `opaque`), and `extern "axiom" { fn choice(...) -> ...; }` — an extern block whose items become `axiom` declarations, which is both cute and semantically honest: axioms are exactly "functions whose implementation lives outside the language."

### 4.7 Expression-level conveniences

Do-notation: Rust's `?` operator *is* monadic bind, and the mapping is delightful — a block containing `?` elaborates as a `do` block, `let x = f()?;` becomes `let x ← f`, plain `let` stays pure, and the block's monad is inferred from the expected type. `for`/`while`/`if` inside such blocks map to Lean's do-notation control flow, which was itself designed to imperative-language expectations. This single feature makes `Option`/`Except`/`StateM` code look like the Rust it wants to be.

Structure literals `Point { x: 1, y: 2 }` → `{ x := 1, y := 2 }`; anonymous constructors: Rust tuple syntax `(a, b)` already elaborates via Lean's `⟨a, b⟩` when the expected type is a structure/inductive — adopt expected-type-driven anonymous construction wholesale. Field access and method-call dot syntax map to Lean's (generalized) dot notation, which is *more* powerful than Rust's (namespace-directed), so nothing to build. Coercions: `x as Real` → `(↑x : Real)` — always written, per F9 (silent unification-driven coercion is disabled in FH-elaborated code), and distinct from ascription per F10 (`(e: T)` is an elaboration hint that inserts no coercion; `e as T` inserts one); `as!` for `Nat`-subtraction-style lossy coercions if we want to distinguish. Operators: Rust's `Add/Mul/Neg/Index` trait vocabulary coincides with Lean's `HAdd/HMul/Neg/GetElem` heterogeneous classes almost name-for-name; we pre-bridge them in `Bridge/` so `a + b` just works on Mathlib types.

Custom notation, short of metaprogramming: a single declaration form, `notation! { ζ($s) => riemannZeta($s), precedence = 65 }`, expanding to Lean `notation` commands. This deliberately caps expressiveness (no custom parsers, no elaborators) — anything fancier goes through the escape hatch.

### 4.8 Proofs and the escape hatch

Milestone policy, unchanged from our discussion: proof *bodies* are (a) `todo!()`, (b) a term expression — which our unified expression grammar makes surprisingly capable, since `fn` calls to lemmas with hypothesis arguments are exactly term proofs — or (c) `lean! { <verbatim Lean tactics> }`, whose interior is parsed by Lean's own tactic parser, giving full Mathlib tactic access and working InfoView goals immediately. A Rust-flavored tactic sugar (`rw!`, `simp!`, `induction!` as statement-position macros) is a v2 exploration, to be attempted only after we have real usage data on which tactics dominate; my prediction from Mathlib practice is that `simp`, `rw`, `exact`, `apply`, `intro`, `cases`/`induction`, `omega`, and `linarith` cover enough that a thin sugar layer is worth it, but guessing the ergonomics before writing proofs is how DSLs acquire dead weight.

### 4.9 Ambient variables and the kind vocabulary

**Ambient variables (`var`).** Mathematical writing declares its cast once — "let $A$, $B$ be sets" — and FH adopts that via module/section-scoped declarations expanding to Lean's `variable` command:

```rust
mod cantor_things {
    var A: Space;
    var B: Space;

    fn injective(f: A -> B) -> Prop { for<a1, a2: A> (f(a1) == f(a2)) -> a1 == a2 }
    theorem cantor(f: A -> Set<A>) -> !surjective(f) { ... }
}
```

Semantics, fixed deliberately and documented under Ruling D: each declaration **generalizes independently** (the module is not a functor parameterized once — `injective` binds its own `∀ A B`, `cantor` its own `∀ A`); a variable is included only in declarations that *mention* it, with an `include` escape for hypotheses needed but unmentioned; ambient *hypotheses* are allowed (`var h: eps > 0;`) and follow the same mention rule, which gets its own corpus test since it surprises even Lean users; inline generics shadow ambient `var`s but must restate the annotation in full, with a shadowing lint; `var` scopes close at module end. And the hard rule: **binding requires a declaration site.** An identifier resolving to neither a declaration nor an in-scope `var` is an error, never an auto-bound fresh variable — Lean's `autoImplicit` is the precedent, tried at scale and disabled globally by Mathlib because a typo'd name silently becomes a universally quantified type and yields vacuous or subtly wrong theorems. That failure mode is exactly the implicitness class the adversarial review exists to exclude.

**The kind vocabulary: `Space` replaces `Type`.** The kind of a domain-of-discourse variable is written `Space`, not `Type` — "let A be a space of things" rather than a prover-internals term — elaborating to `Type*` (universe-polymorphic) with `Space<u>` for explicit universes and `Sort<u>` retained as the full-generality escape. `Prop` is kept as-is: it already says what it means. Three annotation forms are legal after `var x:` (and in kind position generally), disambiguated by what the name resolves to: a *type expression* (`var eps: Real;` — an ordinary typed variable), a *trait or trait sum* (`var G: Grp;`, `var R: CommRing + Finite;` — "let G be a group": expands to `(G : Type*) [Grp G]`, folding the carrier and its structure into one declaration, which is both the mathematician's phrasing and Mathlib's `variable {G : Type*} [Group G]` house style), or a *kind keyword* (`Space`, `Prop`, `Sort<u>` — the bare-carrier case). Trait-in-annotation-position is classified Ruling-D-confined: Rust's bare-trait-as-type is removed syntax with a different meaning (`dyn`), and our form appears only in declarations Rust doesn't have; the resolution rule is name-resolution-driven and deterministic, not expected-type inference, so it stays outside the sanctioned-implicitness list.

**Role metadata — the annotation is also an agent channel.** Kind keywords and any `#[role(...)]` attribute refinements (e.g. `#[role(index)] var i: Space;`) are recorded as structured metadata on the elaborated declaration and surfaced through `fh check`/`fh mcp`. Two distinct layers, kept separate on principle: *what the object is* (space, claim, structured carrier — user-written, this section) versus *how the name binds* (parameter, ambient, bound-under-a-quantifier, witness, let-temporary — **derivable**, so the tooling computes and reports it rather than asking the user to annotate it). The payoff is concrete for the agent layer: binding-role reports make the variable-taxonomy reading protocol machine-readable (an agent asking "what are the actual inputs of this theorem" gets an answer, not a parse), and object-role metadata drives instantiation heuristics in the falsification arm — `Space` variables get probed with small finite types (`Bool`, `Fin 3`), `index`-tagged ones with `Fin n`, trait-annotated carriers with the smallest Mathlib instance of that structure. The vocabulary is deliberately open: new roles are attributes, not grammar.

## 5. What we deliberately do not carry over

Lifetimes and borrows (no memory); `mut` (no mutation outside do-notation's `let mut`, which Lean's do-notation supports natively and we map directly); `unsafe` (its closest analogue, trusting unchecked code, is `partial`/`axiom`, already covered); the orphan rule (§4.4); `Sized`/auto-traits (no operational meaning); macros-by-example and proc macros (escape hatch instead); and Rust's `impl Trait` in return position — superseded by honest dependent types, though we could sugar `-> impl C` as `-> {t: Type // C t}`-style existentials if usage demands.

## 6. The Mathlib bridge

Two problems: names and idioms. Names: Mathlib uses `UpperCamelCase` types, `lowerCamelCase`/dot-namespaced lemmas (`Nat.Prime.dvd_mul`). Policy: **no mangling by default** — Ferris–Howard identifiers resolve as written, and Mathlib names are reachable verbatim (`Nat::Prime::dvd_mul` with `::` mapping to `.`), so there is never a translation table to hold in your head. A `use lean::EuclideanDomain;` form imports/aliases; renames happen at `use` sites Rust-style, not globally. Idioms: the bridge module ships pre-built aliases for the objects from our conversation — `Fp<P>` = `ZMod P`, with the crucial subtlety that Mathlib's field-structure instance requires `[Fact p.Prime]`, so our `where P: Prime` bound expands to exactly that `Fact` binder (this is precisely the "dependent bound Rust couldn't express" made real, and it should be the flagship example in the README); `Poly<R>` = `Polynomial R`; `Fractions<R>` = `FractionRing R`; `Quotient<R, I>` = `R ⧸ I`. The bridge is also where the operator classes are aligned (§4.7).

## 7. Milestones

**M0 — Skeleton.** Lake package, syntax categories, stage-one macros for `fn`/`def`, `struct`, plain `enum`, `mod`/`use`, `todo!()`, attributes pass-through. Exit: a file of non-dependent definitions elaborates; `#print` shows clean Lean.

**M1 — Statements.** Dependent signatures (§4.1), binder classes and quantifiers (§4.2), traits-with-laws (§4.4), the `theorem` keyword form, `lean!{}`, and the minimal `fh check` (JSON status + FH-source spans + sorry goals — the span infrastructure is cheap to emit while the macros are being written and painful to retrofit). Prerequisite pulled forward from the corpus review: the numeric-literals mini-design (integer literals permeate M0/M1 code and Lean's `OfNat` elaboration is expected-type-driven; it needs a sanctioned Ruling C entry, not improvisation). Exit: `euclids_lemma` as written in §3 (ASCII, `theorem` keyword) elaborates and its proof checks against Mathlib.

**M2 — The conversation file.** Indexed enums, termination attributes, do-notation/`?`, the Mathlib bridge module; `fh repl` and `fh mcp` (agent layer) land alongside. Exit criterion with teeth: a Ferris–Howard port of our `riemann_as_traits.rs` elaborates end-to-end — real `EuclideanDomain`, real `ZMod`, laws as fields, and `impl RiemannHypothesis for IntegerWorld` reporting exactly one `sorry`.

**M3 — Ergonomics.** Notation declarations, coercion sugar, the sorry-report tooling, error-message polish (macro spans audited so every elaboration error points at Rust-syntax source), docs written as a "for Rust programmers" tutorial that is secretly the variable-taxonomy reading protocol from our discussion. Also M3: the standalone `.fh` file format (Lake facet + preprocessor), per the §2 embedding decision.

## 8. Testing and agent workflow

Three test tiers, all CI-enforced via `lake`: **golden expansion tests** (Rust-syntax input → expected Lean surface syntax, comparing pretty-printed expansion — cheap, catches macro regressions, and reviewable by you without running Lean mentally); **elaboration tests** (files that must elaborate with zero errors and a specified `sorry` count); and **negative tests** (files that must *fail*, with expected error substrings — a DSL's error behavior is API). For the agent workstream this structure is the contract: every feature lands with all three tiers, and the golden tier doubles as the living syntax specification, which matters because "we come up with our syntax extensions as we go" needs a ratchet against accidental grammar drift. Suggest agents work from this doc section-by-section with §4 subsections as issue granularity, and that ambiguities discovered mid-implementation come back as PRs against *this document* first — the doc stays the source of truth, the grammar follows it. Authority order, made explicit after the 2026-08-01 reconciliation: this document and `corpus-review.md` are now consistent; if they ever disagree again, the corpus review's recorded rulings win until this document is amended, and the amendment lands before the code that depends on it. Corpus fixtures live at `Tests/corpus/gNN_*.lean` (FH-in-`.lean` per the §2 embedding decision; a `.fh` fixture form arrives with M3).

## 9. Open questions

Theorem detection — **resolved** by the corpus review's standing decision: the `theorem` keyword is mandatory, no automatic Prop-detection (§3). Whether `<>` generics-as-implicits ever needs a per-parameter explicitness override (`<explicit T>`?) for Mathlib functions whose type arguments are conventionally explicit — decide during M2 bridge work if friction demands; turbofish and F8 term-position types already cover the escapes. How `notation!` precedence interacts with the Rust expression grammar's fixed precedence table — default answer adopted: custom notation lives above a precedence floor so core Rust parsing is never destabilized; revisit only if M3 usage hits the floor. Naming — **resolved (2026-08-01)**: the repository is `ferris-howard`; crate/package naming for distribution is deferred until first public release.