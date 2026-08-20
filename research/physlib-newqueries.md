# New Atlas queries: exact structure instead of a similarity float

`scripts/phys-newqueries.py` prototypes six queries the Atlas does not have. All six are
built on exact structure. None computes a similarity score, none matches on names, and each
carries a control that can fail.

The premise is `corpus-atlas-findings.md` §13–§16. Eight scoring formulas were implemented
and benchmarked by retrieval and every one landed between MRR 0.16 and 0.30, with the
spread on independent labels inside noise. What survived instead was exact structure —
statement identity, proved `Iff` edges, motif families, kernel verification — and §15 found
that partitioning a query's candidates by shared pattern beat ranking them. §46 then scored
two B7 targets on queries that were specified and never built: V6 PARTIAL for want of
`adjacent`, V9 UNRUNNABLE for want of a proof-shape index.

**Slice**: `/tmp/mathlib-algebra.jsonl` — 131,062 declarations, closure **0.9925** over
2,028,671 application heads, 66,700 of them theorems. Every number below is from a run on
that slice unless it says otherwise. physlib is reported separately in §9 and is a
**12.39%-closed** slice, which is why only the four erasure-independent methods run there.

```sh
uv run --no-sync python scripts/phys-newqueries.py --slice /tmp/mathlib-algebra.jsonl \
    --method all
uv run --no-sync python scripts/phys-newqueries.py --slice /tmp/fh-physlib.jsonl \
    --method m1,m2,m4,m6        # m3/m5 are refused below 95% closure
```

---

## 0. Scorecard

| | query | what it answers | control, and what it says | beats the shipped surface? |
|---|---|---|---|---|
| **M1** | `variants` | the statements that are this one with one constant swapped, **and the swap** | constant-lists permuted within arity: 447 against 8,251 (**18.5x**) on Mathlib, 128 against 740 (**5.8x**) on physlib | on explanation yes, `similar` cannot produce a diff; on recall barely (10.5% of substantive partners missing from top-50 on Mathlib, **0%** on physlib) |
| **M2** | `substitutions` | the corpus-wide inventory of witnessed swaps | frequency-matched right-hand side: **exactly 0** across 24 resamplings on each of two corpora | on warrant yes — no collisions; on coverage no — transfer is 10.2% of held-out pairs |
| **M3** | `adjacent` | what sits just outside an equivalence class, and why | 40/40 injected near misses found with the exact swap; **0/40** right-vocabulary wrong-structure decoys | the query did not exist; §46 scored V6 PARTIAL for its absence |
| **M4** | `proof_shape` | proofs that lean on the same *kinds* of fact | frequency-matched citation shuffle: 88 families against **6,524** (**74x**); on physlib **0** against 493 | the query did not exist; §46 scored V9 UNRUNNABLE for its absence |
| **M5** | `match` | completions of a partial statement with holes | four gates, incl. a differential against `equivalent` over 643 class members: **0 false negatives** | the query did not exist; reaches 29 where `equivalent` reaches 3 |
| **M6** | `transport_exact` | apply a swap, ask whether the image exists | frequency-matched right-hand side: **0.0%** against **22.7%** on Mathlib and **25.1%** on physlib | replaces `transport`, which §24 records has never produced anything |

Nothing here computes a similarity score and nothing matches on names.

---

## 1. The primitive: the rigid skeleton

Every I3 statement is a tree whose leaves include constant symbols. Blank every constant
name and what remains is the statement's **rigid skeleton** — the exact shape with the
vocabulary removed. Two declarations with equal skeletons differ *only* in which constants
sit in which slot, so their difference is a list of `(slot, a, b)`: an edit, not a number.

This is what the pipeline throws away. Anti-unification computes a pattern **and** the
substitutions specialising it to each side; `Generalization` keeps `skeleton`, `common`,
`vars`, `retention` and discards the substitutions entirely. Recovering them is the cheapest
new query available, because the skeleton is a hash key — the whole corpus partitions in one
pass with no floors, no `k` and no formula.

Blanking is a byte scan, not a parse. Names and string literals are byte-length-prefixed, so
a `c(` inside a name can never be mistaken for a constant marker. The length prefix goes with
the name rather than staying in the skeleton: keeping it would leak how long an operator is
spelled into the key and split families by it.

**Gate on the primitive.** Blank-then-refill must be the identity. Measured over the whole
slice: **131,062 / 131,062** statements round-trip. A lossy skeleton would merge two families
and nothing downstream would say so.

| | over 66,700 claims |
|---|---|
| distinct rigid skeletons | 43,180 |
| skeletons shared by more than one claim | 9,607, covering 33,127 claims |
| largest bucket | 660 claims |

The claim restriction is not optional. Unrestricted, the largest bucket on this slice is
7,358 structure projections — CLAUDE.md's "restrict to claims, or you are measuring Lean
rather than mathematics", for the fourth time.

---

## 2. M1 `variants` — the structural neighbourhood, with the diff

Declarations whose statement is this one with a **uniform substitution** of one constant for
another, everywhere it occurs. Indexed rather than quadratic: for each declaration and each
distinct constant it holds, the key `(skeleton, constant list with that constant masked)` is
emitted, and two declarations sharing the key with different masked constants differ exactly
by swapping one for the other.

### Measured

| | |
|---|---|
| k=1 uniform-substitution pairs | **8,251** (2.9 s) |
| claims with at least one k=1 partner | 7,457 (**11.2%**) |
| distinct substitutions witnessed | 3,970 |

The full slot-level diff at every distance, over within-bucket pairs (7 buckets above 300
members skipped and reported):

```
k=0: 1,320   k=1: 6,004   k=2: 13,262   k=3: 34,838
k=4: 38,416  k=5: 71,352  k=6: 11,360   k=7: 44,000
```

Top substitutions, ranked by how many **independent skeletons** witness them so that one
large family votes once rather than once per member:

```
 99  Ne                                   <-> Eq
 39  Function.Injective                   <-> Function.Surjective
 38  Int.tdiv                             <-> Int.fdiv
 30  Function.Bijective                   <-> Function.Injective
 30  List.IsPrefix                        <-> List.IsSuffix
 29  Function.Bijective                   <-> Function.Surjective
 29  List.IsInfix                         <-> List.IsPrefix
 28  Std.DTreeMap.Internal.Impl.maxKey?   <-> Std.DTreeMap.Internal.Impl.minKey?
 27  Monotone                             <-> Antitone
 26  And                                  <-> Or
 23  Int.fmod                             <-> Int.tmod
```

No name matching produced any of these. They are what falls out of requiring two statements
to be the same tree.

### Control (degradation)

Permute which constant-list attaches to which skeleton, among skeletons taking the same
number of constants. Structure is preserved exactly; only the association between shape and
vocabulary is destroyed.

| | pairs |
|---|---|
| genuine | **8,251** |
| permuted within arity | **447** |

**18.5x.** Not zero, and it should not be: two random lists of the same length occasionally
differ in one entry. The separation is what the control is for.

### Head-to-head against `similar`, stratified

A k=1 pair is two nearly identical statements, so `similar` ought to find most of them. It
does. Stratified by §3b's derivativeness measure, computed here from citation structure only
— proof length, the fraction of the proof citing declarations whose **kind** is `constructor`
or `recursor`, and in-degree, combined as percentile ranks exactly as the shipped measure is:

| stratum | pairs | partner in `similar` top-10 | top-50 |
|---|---|---|---|
| substantive | 3,271 | 172/200 (**86.0%**) | 179/200 (89.5%) |
| derivative | 4,980 | 119/200 (59.5%) | 170/200 (85.0%) |

Of 20 sampled substantive misses, **16 were also outside `similar_brute`'s top 200** — the
same ranking with the index switched off — and 4 were inside it and ranked below `similar`'s
50. So the loss is not the prefilter discarding candidates; it is that the ranking cannot
separate a k=1 partner from a large field tied at the same retention. That is the failure
mode §15 predicted: whole families land on one score, and the tie-break is doing the work.
It is not large in aggregate — 10.5% of substantive k=1 partners are absent from `similar`'s
top 50 — but it is unrecoverable downstream, which is the kind that counts.

The first version of this stratification used only proof length and in-degree and classified
361 of 8,251 pairs as derivative, missing every `.inj`/`.injEq` batch — those proofs cite 5
to 8 constants each. The constructor/recursor fraction is the signal that catches them, and
CLAUDE.md already records that it is the one that only works in combination.

### Verdict — **keep**

It does not beat `similar` on recall by much. It beats it on something `similar` cannot do
at all: report *what differs*, as a substitution an agent can apply. And the corpus-level
inventory (§3) does not exist in any form today.

---

## 3. M2 `substitutions` — a dictionary with no scorer in it

The corpus-wide inventory M1 witnesses. This is B6's `dictionary` question answered by exact
structure, where the shipped answer is 96% collisions (§21) and is ranked by a float.

A dictionary is only a dictionary if it says something about text it was not built from.
Learned on a random half of the slice's 133 depth-2 theories, tested on the other half,
against a null that keeps the left-hand constant and resamples the right-hand one from the
corpus's own constant-occurrence distribution.

| `min_witnesses` | inventory | transfer, distinct | transfer, pairs | null (8 runs) |
|---|---|---|---|---|
| 1 | 1,555 | 35/2,070 (**1.7%**) | 487/4,758 (**10.2%**) | mean 0.0, range 0–0 |
| 2 | 293 | 25/2,070 (1.2%) | 410/4,758 (8.6%) | mean 0.0, range 0–0 |
| 3 | 248 | 15/2,070 (0.7%) | 343/4,758 (7.2%) | mean 0.0, range 0–0 |

Swept rather than thresholded, because the floor is exactly the knob that trades recall for
precision. The sweep says the floor buys nothing: the null is zero at every setting, so
raising `min_witnesses` only discards candidates.

### Verdict — **keep, with the limitation stated**

Transfer is real and unambiguous — the null is **exactly zero across 24 resamplings**. It is
also small: 1.7% of held-out substitutions and 10.2% of held-out pairs. The substitution
vocabulary is largely **theory-local**. That is not a defect of the method so much as a fact
about the corpus, and it is the same fact §17–§18 measured from the other direction:
within-theory coherence is a strong signal and cross-theory reach is at chance.

Against B6's `dictionary` this trades coverage for warrant. Every row here is an exact
structural identity with a named witness count; none of them is a collision.

---

## 4. M3 `adjacent` — what sits just outside a class, and why

§46 scored V6 PARTIAL for exactly this: the RH reformulation cluster assembled and "Λ ≥ 0"
was not surfaced as an adjacent non-member, because `Corpus.adjacent` was specified and never
shipped. Two tiers, both exact:

* **tier 1, one substitution away** — outside the class, same rigid skeleton as a member,
  reported with the constant swap that separates them;
* **tier 2, one squint coarser** — outside the class at this level, inside it at the next
  coarser one. Pure `equivalent` at two levels, and it has never been asked.

The whole class inventory comes from two `classes()` calls (1,423 classes at `instances`,
2,114 at `carriers`, 3 s). A first version asked `equivalent` per candidate and did not
finish in 4,000 calls.

### Measured, over 300 sampled classes at `instances`

| | |
|---|---|
| tier 1 non-empty | **159/300** classes |
| tier 1 size | median 2, max 1,052 |
| tier 2 size | median 0, max 3 |

```
adjacent(le_of_mul_le_mul_of_pos_right):
  lt_of_mul_lt_mul_of_nonneg_right  [5 sub]  LE.le -> LT.lt, LT.lt -> LE.le,
                                             Preorder.toLE -> Preorder.toLT, ...
  lt_of_mul_lt_mul_right            [5 sub]  (same swap)

adjacent(inf_sup_left):
  max_min_distrib_left  [6 sub]  Max.max -> Min.min,
                                 Lattice.toSemilatticeInf -> Lattice.toSemilatticeSup, ...
  sup_inf_left          [6 sub]  (same swap)

adjacent(List.getLast?_eq_getLast):
  List.head?_eq_head    [2 sub]  List.getLast? -> List.head?, List.getLast -> List.head
```

The first of these is V6's shape — a claim and its order-dual neighbour, surfaced as an
adjacent non-member with the ≤/< swap named. The second is worth noting: `sup_inf_left` and
`max_min_distrib_left` are the pair §43's novelty screen reports as prior art, found there by
statement equality over 470,435 declarations after a kernel probe. Adjacency returns both
from one query on a 131k slice, with the min/max substitution written out.

### Controls

Injected into the view: 40 near misses built by substituting one constant for another whose
substitution is not witnessed anywhere in the corpus, and 40 specificity probes built by
pouring a declaration's **exact vocabulary** into a *different* skeleton of the same arity.

| | |
|---|---|
| near miss found | **40/40** |
| …with the exact substitution reported | **40/40** |
| found before injection | **0** |
| right vocabulary, wrong structure returned | **0/40** |

The second control is the one that matters. A method keyed on a bag of constants passes the
first and fails this; keying on the tree is what makes it 0/40.

### Verdict — **keep**. This is the missing V6 query, and it is cheap.

---

## 5. M4 `proof_shape` — the index §46 called UNRUNNABLE

`atlas.md` §1e specifies a proof-shape index. Statements are indexed and proofs are not, so
V9 had no surface to query.

A proof reaches the Atlas only as `uses_proof`, a list of names — but every name in it has a
statement, and the **rigid skeleton of that statement is constant-blind**, so `add_comm` and
`mul_comm` key the same. A proof's shape is therefore the multiset of the shapes of the facts
it invokes: not *what* it cites but what *kind* of fact it cites, in what proportions. No
names, no scores, exact multiset equality.

| stratum | claims with ≥2 proof citations | families | claims covered | **control** families | control covered |
|---|---|---|---|---|---|
| all claims | 65,536 | **6,524** | 21,593 (32.9%) | 88 | 242 (0.4%) |
| substantive | 49,303 | **4,531** | 12,062 (24.5%) | 61 | 150 (0.3%) |

The control resamples each proof's citations from the corpus-wide citation frequency
distribution, keeping the citation count per proof exactly. It collapses by **74x** on all
claims and **74x** on the substantive stratum.

Does it carry information the statement index does not? A family whose members already share
a rigid statement skeleton has told us nothing new:

| | |
|---|---|
| families whose members do **not** share a statement skeleton | 1,653/6,524 (**25.3%**) |
| same, substantive stratum | 1,141/4,531 (25.2%) |

A quarter of proof-shape families group statements that no statement-level query groups. Some
substantive families:

```
[63 proofs, 3 citations]  AddLeftReflectLE.le_of_add_le_add_left,
                          AddRightReflectLE.le_of_add_le_add_right,
                          CanonicallyOrderedAdd.le_add_self, CanonicallyOrderedAdd.le_self_add
[61 proofs, 5 citations]  Char.toNat_val, Char.toUInt8_val,
                          ISize.ofInt_int16ToInt, ISize.ofInt_int32ToInt
[46 proofs, 7 citations]  ISize.toUSize_add, ISize.toUSize_and,
                          ISize.toUSize_mul, ISize.toUSize_or
```

Unstratified, the five largest families are `sizeOf_spec`, `inj` and `injEq` batches — which
is Lean's output and not anyone's proof, and is why both strata are reported.

### Verdict — **keep**

V9 becomes runnable, and the null is 74x away on Mathlib and at **zero** on physlib (§9.4).

---

## 6. M5 `match` — retrieval by pattern instead of by example

Every query in the shipped surface takes a declaration and asks what resembles it. None takes
a *partial statement* and asks what completes it. `match` takes an I3 term with `_` holes and
returns every declaration that one-way matches it.

Implemented as a **synchronized scan** over two byte strings rather than a tree match:
building a Python tree for every statement in a 131k slice is tens of millions of tuples and
the query never needs one. Measured cost: 0.4–0.5 s per pattern over 66,700 claims, on top of
a 4 s pass to compute their `presentation` skeletons once.

### Gates

| gate | result | second run |
|---|---|---|
| **A** hole-punch monotonicity — punching a hole anywhere must still match the source | 2,399 ok / **0 violated** | 2,398 / 0 |
| **A** hole-free exactness — a pattern with no hole matches only its own encoding, tested on same-skeleton different-constant pairs | 500 ok / **0 violated** | 500 / 0 |
| **B** differential against `equivalent`, over 60 patterns | 293 matched / **0 false negatives** | 350 / **0** |
| **C** a slot filled with a constant no declaration holds | **0 hits** | 0 |

Gate B is a differential because `equivalent` computes the same containment by a different
algorithm — string equality of erasures against one-way matching. Two independent runs over
different sampled patterns, 643 class members between them, zero false negatives.

### What it reaches that `equivalent` does not

Sweeping 20 queries, punching holes at *concrete* positions only (a hole where the erasure
already put one widens nothing):

| extra holes | median matches over 66,700 claims |
|---|---|
| +0 | 3 |
| +2 | 4 |
| +4 | 7 |
| +6 | **29** |

The median class returned by `equivalent(., "carriers")` for the same queries is **3**, which
is exactly the +0 column — the two agree where they should. Six holes reaches **29**, and the
set widened for **15 of 20** queries. That is the interface an agent with a half-written
statement needs and there is nothing like it in the shipped surface.

### A correction this produced, which a reader will otherwise walk into

The obvious form of gate B is "`skeleton(d, L)` must match `stmt(x)` for every `x` in
`equivalent(d, L)`". **It is false**, and by a wide margin: on the same 60 patterns, matching
against the raw statement gives **166 matched / 127 missed** (43%), and **278 / 72** (21%) on
the second run. The rate is sample-dependent; that it is far from zero is not.

The cause is that erasure is not hole-punching. From `presentation` upward it *rewrites*:
`OfNat.ofNat T k inst` collapses to the literal `k` and `StrictImplicit` merges into
`Implicit` (`erase.rs` `erase_spine`/`erase_binder`). Only from `presentation` to `instances`
and `carriers` is the erasure purely a replacement of subterms by holes. So a pattern taken at
`carriers` is a hole pattern over `skeleton(x, "presentation")` and is **not** one over
`stmt(x)`. Anyone building a pattern query against raw statements would silently lose a fifth
to two fifths of each class and read it as a matcher bug.

### Verdict — **keep**. All four gates green, and the query is 0.5 s over the whole claim set.

---

## 7. M6 `transport_exact` — the operation §24 says has never done anything

§24 records that B6's `transport` — "the active operation" — has never produced anything. It
applies a *skeleton* row and asks where the image lands, and the skeleton is what a scored
anti-unification left behind.

A witnessed substitution is a rewrite instead. Applying `a := b` to a statement produces a
**fully written statement**, and asking whether it exists is an exact lookup on the encoding.

| | |
|---|---|
| inventory (≥2 witnesses) | 799 substitutions |
| rewrites attempted | 31,396 |
| image is already a declaration | **7,131 (22.7%)** |
| image is open | 24,265, of which **17,510** survive the derivative and plumbing exclusions |
| **control** — frequency-matched right-hand side | 45,449 rewrites, **0 (0.0%)** |

The plumbing exclusion is `fh_home.py`'s rule, which needs no names: a constant whose
conclusion is itself a class application produces an instance rather than consuming one. B3
learned over three tries that without it every declaration reports "at home".

Open targets, after both exclusions:

```
Odd.pow_add_pow_eq_zero          [IsCancelAdd := IsRightCancelAdd]
isCancelMul_iff_forall_isRegular [IsCancelMul := IsRightCancelMul]
IsRightCancelMul.mul_right_cancel[IsRightCancelMul := IsCancelMul]
IsAddLeftRegular.all             [IsLeftCancelAdd := IsRightCancelAdd]
```

These are the same genre as §45's 387 kernel-verified weakenings and are reached from the
opposite direction — not "does this proof term typecheck under a weaker binder" but "the
corpus states this claim for one class and not for its sibling". Each is a **statement**, so
it can be handed to the kernel or refuted directly; none of them is a hole.

### The vocabulary graph, as a side effect

The inventory induces a graph on constants; its connected components are families of
interchangeable vocabulary, found with no name matching anywhere. **316 components, largest
15.**

```
[15] IsEquiv, IsLinearOrder, IsPartialOrder, IsPreorder, IsStrictOrder,
     IsStrictTotalOrder, IsStrictWeakOrder, IsTrans, ...
[ 5] IsEmpty, Nonempty, Subsingleton, Lean.Meta.FastIsEmpty, Lean.Meta.FastSubsingleton
[ 9] IO.Error.hardwareFault, IO.Error.illegalOperation, IO.Error.otherError, ...
```

The first is the order-class hierarchy; the second is the emptiness/inhabitation cluster
together with the two fast reimplementations Lean keeps beside it. The third, and a fourth of
14 `Std.Time.Modifier` constructors, are infrastructure — correctly detected, and exactly the
material a consumer would filter rather than something the method got wrong.

### Verdict — **keep**

The strongest of the six: 22.7% against a null of 0.0% here, and 25.1% against 0.0% on
physlib (§9.3), where the vocabulary graph recovers the SI base dimensions, the Standard
Model variants, the gauge anomaly coefficients and the three CKM quark generations from
statement trees alone.

---

## 8. What did not work, and what is not claimed

**None of these six does cross-theory analogy.** The rigid skeleton is an exact key, so it
groups declarations that are the same tree, and on both corpora that means declarations in
the same theory. M2 quantifies it directly: the substitution inventory transfers to a held-out
half of the theories at 1.7% of distinct substitutions. This *agrees* with §17–§18 — aggregate
cross-theory structure is indistinguishable from chance, within-theory coherence is very
strong — and it means exact-structure queries are a within-theory instrument. They are not a
replacement for whatever eventually does cross-theory work; they are a replacement for the
part of the ranked surface that was pretending to.

**M1's recall gain over `similar` is modest on Mathlib and zero on physlib.** 86% of
substantive k=1 partners are already in `similar`'s top 10 on the algebra slice, and 98.5% on
physlib, where `similar`'s top 50 contains **all** of them. The case for M1 is the diff and
the inventory, not retrieval, and anyone reading the Mathlib 10.5% gap as the headline would
be reading one corpus.

**M2's transfer is small.** Reported as measured; the honest headline is "unambiguously above
zero, and 10.2% of held-out pairs".

**The `equivalent`-against-raw-statement differential is refuted**, not weakened — see §6.

**Uniformity of a substitution is a modelling choice with a cost.** `adjacent` on
`Int.ofNat_mul_ofNat` reports four substitutions — `HMul.hMul -> HAdd.hAdd`,
`instHMul -> instHAdd`, `instMulNat -> instAddNat`, `Int.instMul -> Int.instAdd` — for one
conceptual change, because the instance constants travel with the operation. Nothing here
groups them into a single compound substitution, so the `max_subs` knob is coarser than the
mathematics. The natural fix is to mine co-occurring substitution sets, and it is not built.

**Not attempted**: the antichain / maximal-generality frontier from the task's seed list. The
one-way matcher makes subsumption expressible (`x` subsumes `y` when `skeleton(x, L)` matches
`skeleton(y, presentation)`), but the antichain over 66,700 claims is 4.4 billion pairs and
needs a containment prefilter that was not built. Recorded as not run rather than as a
negative result.

---

## 9. physlib

physlib's closed extraction (`/tmp/fh-physlib-closure.jsonl`) wrote its first bytes at the
very end of this session and was still growing (677 MB and rising) when this was written, so
it is **not measured here** — a slice being read while it is being written is not a slice.
Everything below is on `/tmp/fh-physlib.jsonl`, which is **12.39% closed** over 19,354,368
application heads. **M3 and M5 on a closed physlib remain to be run**; the script will do it
unchanged once `closure()` clears 0.95. `Corpus.skeleton` and
`Corpus.equivalent` degrade silently on an unclosed slice (CLAUDE.md §7, findings §31), so
M3 and M5 must not run there. The script refuses them below 95% closure rather than
reporting a number:

```
WARNING: closure below 0.95 — erasure-dependent results are not trustworthy
REFUSING m3/m5 on a slice below 95% closure; run them on a closed slice
```

M1, M2, M4 and M6 read the raw statement encoding and never erase, so they are sound on an
unclosed slice — the rigid skeleton is a property of the tree as extracted.

The slice is 14,563 declarations, 9,489 of them theorems, and averages **1,329 application
heads per declaration** against the Mathlib slice's **15.5** (19,354,368/14,563 against
2,028,671/131,062); its largest single statement is **71 MB**. That ratio broke the first
implementation and is worth recording: masking one constant at a time by materialising a
fresh constant-list costs `O(distinct constants x slots)` per declaration, and both factors
scale with statement size, so the cost is roughly quadratic in it. The first physlib run
produced no output for ten minutes and was abandoned. The shipped version uses a
position-weighted
polynomial hash so one slot's contribution is subtracted in O(1), and confirms every
candidate pair against the constant lists themselves so a 61-bit collision cannot become a
claim. Verified behaviour-preserving: the hashed version reproduces the Mathlib run exactly —
8,251 pairs, 3,970 substitutions, the same top-15 and the same 447-pair control.

### 9.1 M1 on physlib

Blank-then-refill round-trips on **14,563 / 14,563** statements, so the primitive holds on a
corpus whose statements are 86x larger.

| | |
|---|---|
| rigid skeletons over 9,489 claims | 8,040 (809 shared, covering 2,258 claims) |
| largest bucket | 59 claims |
| k=1 uniform-substitution pairs | **740** (4.7 s) |
| claims with a k=1 partner | 808 (**8.5%**) |
| distinct substitutions | 414 |
| **control** — constant-lists permuted within arity | **128** (5.8x separation) |

The top substitutions are physics, and no name matching produced them:

```
 13  Function.Injective                     <-> Function.Surjective
 10  Physlib.Wirtinger.dWirtingerAntiCoord  <-> Physlib.Wirtinger.dWirtingerCoord
  9  WickContraction.fstFieldOfContract     <-> WickContraction.sndFieldOfContract
  8  Physlib.Wirtinger.dWirtingerDir        <-> Physlib.Wirtinger.dWirtingerAntiDir
  6  Dimension.charge <-> Dimension.mass <-> Dimension.temperature
       <-> Dimension.time <-> Dimension.length      (all pairs, 6 skeletons each)
  6  SMRHN.SM                               <-> SMRHN.SMNoGrav
```

The `Dimension.*` block is the SI base dimensions recovered as a fully connected
interchangeable family — every one of the ten pairs among `charge`, `length`, `mass`,
`temperature`, `time` is witnessed by 6 independent skeletons. `SM` against `SMNoGrav` is the
Standard Model with and without gravity.

**The recall argument for M1 does not survive here.** On physlib, `similar` already returns
the k=1 partner for **197/200 (98.5%)** of substantive pairs at top-10 and **200/200 (100%)**
at top-50. Whatever M1 is worth on this corpus, it is the diff and the inventory, not
retrieval — which sharpens §2's verdict rather than contradicting it.

### 9.2 M2 on physlib

31 theories, split 16/15; 278 substitutions learned on half A, 137 distinct over 291 pairs
held out on half B.

| `min_witnesses` | inventory | transfer, distinct | transfer, pairs | null (8 runs) |
|---|---|---|---|---|
| 1 | 278 | 6/137 (**4.4%**) | 22/291 (**7.6%**) | 0.0, range 0–0 |
| 2 | 64 | 2/137 (1.5%) | 11/291 (3.8%) | 0.0, range 0–0 |
| 3 | 26 | 1/137 (0.7%) | 10/291 (3.4%) | 0.0, range 0–0 |

The same shape as Mathlib: unambiguously above a null of exactly zero, and small. Two corpora
now agree that the substitution vocabulary is theory-local.

### 9.3 M6 on physlib

| | |
|---|---|
| inventory (≥2 witnesses) | 120 substitutions |
| claims skipped as subjects for exceeding 200 kB | 419 |
| rewrites attempted | 3,324 |
| image is already a declaration | **833 (25.1%)** |
| image is open | 2,491, of which **2,081** survive the derivative and plumbing exclusions |
| **control** — frequency-matched right-hand side | 6,038 rewrites, **0 (0.0%)** |

25.1% against 0.0%, reproducing Mathlib's 22.7% against 0.0% on an independently written
corpus in a different subject.

```
CKMMatrix.cRow_cross_tRow_conj        [CKMMatrix.cRow := CKMMatrix.uRow]
CKMMatrix.cRow_cross_tRow_eq_uRow     [CKMMatrix.uRow := CKMMatrix.tRow]
CanonicalEnsemble.derivWithin_log_phys_eq_derivWithin_log_math
                                      [partitionFunction := mathematicalPartitionFunction]
CanonicalEnsemble.differentialEntropy_eq_kB_beta_meanEnergy_add_kB_log_mathZ
                                      [μBolt := μProd]
```

The vocabulary graph is the clearest result in this document. **69 components, largest 5:**

```
[5] Dimension.charge, Dimension.length, Dimension.mass,
    Dimension.temperature, Dimension.time
[4] SM.SMNoGrav, SMRHN.PlusU1, SMRHN.SM, SMRHN.SMNoGrav
[4] SMACCs.accGrav, SMACCs.accSU2, SMACCs.accSU3, SMACCs.accYY
[4] SMνACCs.accGrav, SMνACCs.accSU2, SMνACCs.accSU3, SMνACCs.accYY
[3] CKMMatrix.cRow, CKMMatrix.tRow, CKMMatrix.uRow
[3] ClassicalMechanics.HarmonicOscillator.k,
    ClassicalMechanics.HarmonicOscillator.m,
    ClassicalMechanics.HarmonicOscillator.ω
```

The SI base dimensions; the Standard Model variants; the gauge anomaly coefficients, twice,
once for the model with right-handed neutrinos and once without; the three quark generations
of the CKM matrix; the harmonic oscillator's three parameters. Every one of those is a
physicist's grouping, and every one was recovered from statement trees alone — no names, no
scores, no subfield labels.

### 9.4 M4 on physlib

| stratum | claims with ≥2 proof citations | families | covered | **control** |
|---|---|---|---|---|
| all claims | 9,413 | **493** | 1,356 (14.4%) | **0 families, 0 claims** |
| substantive | 7,083 | **296** | 753 (10.6%) | **0 families, 0 claims** |

| | |
|---|---|
| families whose members do **not** share a statement skeleton | 148/493 (**30.0%**) |
| same, substantive stratum | 91/296 (30.7%) |

The control does not merely collapse here, it goes to **zero**: no two physlib proofs given
frequency-matched random citation lists ever land on the same multiset of statement shapes.
The genuine index finds 493. Some substantive families:

```
[12 proofs,  3 citations]  FTheory.SU5.Quanta.IsViable.allows_top_yukawa,
                           …charges_allowed_by_section_config, …has_all_charges,
                           …linear_anomalies
[10 proofs,  4 citations]  Dimension.L𝓭_charge, Dimension.L𝓭_length,
                           Dimension.L𝓭_mass, Dimension.L𝓭_temperature
[ 8 proofs, 122 citations] phaseShiftApply.cb, phaseShiftApply.cd,
                           phaseShiftApply.cs, phaseShiftApply.tb
```

The last is eight proofs agreeing on a 122-element multiset of cited statement shapes. That
is not a coincidence anything else in the Atlas can currently see.

---

## 10. Implementation specs

Each of these touches the five places CLAUDE.md §6 lists: engine, CLI, Python binding and
`.pyi`, `fh mcp`'s tool list, and a gate exercising it against a real slice. Only the engine
and binding signatures and the gate are given here.

### S1 `Corpus.variants` and `Corpus.substitutions`

New module `crates/fh-atlas/src/skel/rigid.rs`:

```rust
/// A statement with every constant name blanked: the exact shape, vocabulary removed.
/// Built from the `Arena` the skeleton index already holds, in one pass.
pub struct RigidIndex {
    skel:    Vec<SkelId>,            // decl -> rigid skeleton
    slots:   Vec<Range<u32>>,        // decl -> its slice of `fill`
    fill:    Vec<SymId>,             // the constants filling every slot, in slot order
    members: Vec<Vec<DeclId>>,       // rigid skeleton -> declarations sharing it
    level:   Level,                  // which erasure the skeleton was taken over
}

pub struct Variant {
    pub name: String,
    pub module: String,
    pub kind: String,
    /// distinct constant substitutions separating the two statements
    pub subs: Vec<(String, String)>,
    /// how many slots differ; >= subs.len(), equal exactly when every swap is uniform
    pub slots_differing: u32,
    pub uniform: bool,
}

pub struct Substitution {
    pub left: String,
    pub right: String,
    /// distinct rigid skeletons witnessing it — a family votes once, not once per member
    pub witnesses: u32,
    pub examples: Vec<(String, String)>,
}

impl RigidIndex {
    pub fn build(a: &Arena, decls: &[DeclId], level: Level) -> RigidIndex;
    pub fn variants(&self, d: DeclId, max_subs: u32) -> Vec<Variant>;
    pub fn substitutions(&self, min_witnesses: u32, top: usize) -> Vec<Substitution>;
}
```

Binding:

```python
def variants(self, name: str, max_subs: int = 1, level: Level = "exact",
             theorems_only: bool = True) -> list[Variant]: ...
def substitutions(self, min_witnesses: int = 1, top: int = 200,
                  theorems_only: bool = True) -> list[Substitution]: ...
```

`min_witnesses` defaults to **1**, not 2: the measured sweep loses recall monotonically as it
rises while the null stays at exactly zero, so the floor costs candidates and buys nothing.

`variants` must use the incremental mask (§9), not a fresh list per constant.

Gates — `crates/fh-atlas/tests/rigid.rs`:

| test | what fails it |
|---|---|
| `variants_names_the_single_constant_that_differs` | two fixtures identical but for `Eq`/`Ne`; `subs` must be exactly `[("Eq","Ne")]` |
| `variants_refuses_the_same_vocabulary_in_a_different_shape` | **negative control**: a fixture holding the same constants in a different tree must not be returned. This is what fails if the key degrades to a bag of constants |
| `variants_reports_a_two_constant_swap_only_at_max_subs_two` | discrimination across the knob |
| `rigid_skeleton_round_trips` (`FH_SLICE`) | blank-then-refill must be the identity over the whole slice; a lossy skeleton merges families silently |
| `substitutions_transfer_across_a_theory_split` (`FH_SLICE`) | learn on half the theories, test on the other; **red if transfer does not exceed a frequency-matched null, and red if the null arm did not run** (`pairs == 0` reported as such, per §20's trap) |
| `variant_count_collapses_under_a_within_arity_permutation` (`FH_SLICE`) | the degradation control; red if the permuted arm scores within 3x of genuine |

### S2 `Corpus.adjacent`

```rust
pub enum AdjacencyTier { OneSubstitution, OneLevelCoarser }

pub struct Adjacent {
    pub member: String,                // the class member it is adjacent to
    pub name: String,                  // the non-member
    pub tier: AdjacencyTier,
    pub subs: Vec<(String, String)>,   // empty for OneLevelCoarser
}

pub fn adjacent(&self, name: &str, level: Level) -> Result<Vec<Adjacent>, GraphError>;
```

Binding: `Corpus.adjacent(name, level="instances") -> list[Adjacent]`.

Gates — `crates/fh-atlas/tests/adjacent.rs`:

| test | what fails it |
|---|---|
| `adjacent_never_returns_a_member_of_its_own_class` | definitional |
| `adjacent_finds_an_injected_near_miss_and_names_the_swap` | inject a statement differing by one constant; must return it *with that substitution* |
| `adjacent_refuses_a_row_with_the_right_vocabulary_and_the_wrong_shape` | **the specificity control**; a vocabulary-keyed implementation passes the previous test and fails this |
| `adjacent_is_empty_before_the_injection` | §40's clean-control shape |
| `adjacent_tier_two_is_the_next_level_only` | equal at `carriers` but not `instances` must land in tier 2, never tier 1 |

### S3 `Corpus.proof_shape`, `proofs_like`, `proof_families`

```rust
/// The multiset of the rigid skeletons of the statements a proof cites. Constant-blind by
/// construction, so `add_comm` and `mul_comm` key the same and two proofs leaning on a
/// commutativity lemma agree whichever operation it was about.
pub struct ProofShape(pub u64);

pub struct ProofFamily {
    pub shape: ProofShape,
    pub citations: u32,
    pub members: Vec<String>,
    /// true when the members do NOT all share a statement skeleton — the part the statement
    /// index cannot reach, and the reason this index is not redundant
    pub statement_diverse: bool,
}

pub fn proof_shape(&self, name: &str) -> Result<Option<ProofShape>, GraphError>;
pub fn proofs_like(&self, name: &str) -> Result<Vec<String>, GraphError>;
pub fn proof_families(&self, min_citations: u32, min_family: u32, top: usize)
    -> Vec<ProofFamily>;
```

Gates — `crates/fh-atlas/tests/proofshape.rs`:

| test | what fails it |
|---|---|
| `two_proofs_citing_differently_named_lemmas_of_one_shape_share_a_family` | the whole point; a name-keyed implementation fails it |
| `a_proof_citing_a_lemma_of_a_different_shape_does_not` | discrimination |
| `a_cited_constant_outside_the_slice_keys_by_identity_and_is_counted` | silent-degradation guard: the count must be surfaced, never folded into one bucket |
| `proof_families_collapse_under_a_frequency_matched_citation_shuffle` (`FH_SLICE`) | **negative control**; red if the shuffled arm produces families within 5x of genuine, and red if the shuffle did not run |

### S4 `Corpus.match_pattern`

```rust
pub struct PatternMatch {
    pub name: String,
    pub module: String,
    /// what each hole was filled with, rendered — the partition key
    pub fills: Vec<String>,
}

/// Declarations whose `erase(stmt, level)` is an instance of `pattern`, grouped by `fills`.
/// A partition, never a ranking — findings §15.
pub fn match_pattern(&self, pattern: &str, level: Level)
    -> Result<Vec<(Vec<String>, Vec<PatternMatch>)>, ParseError>;
```

Gates — `crates/fh-atlas/tests/pattern.rs`:

| test | what fails it |
|---|---|
| `punching_a_hole_anywhere_still_matches_the_source` (`FH_SLICE`, property) | monotonicity |
| `a_hole_free_pattern_matches_only_its_own_encoding` (`FH_SLICE`, property) | exactness, hardest on same-skeleton different-constant pairs |
| `every_member_of_an_equivalence_class_matches_its_skeleton` (`FH_SLICE`, differential) | matching against `equivalent`. **The pattern must be taken at a level above `presentation` and matched against `skeleton(x, "presentation")`** — see §6; matching against `stmt` fails on a fifth to two fifths of members and the failure is the erasure's rewrites, not the matcher's |
| `a_constant_no_declaration_holds_matches_nothing` | the null |

### S5 `Corpus.transport_exact`

A rewrite copies the whole statement, so the subject's size is the unit cost and the engine
must cap it and **count the skips**. Measured on physlib: without a cap the control arm did
not return after ten minutes of CPU, because the slice holds a 71 MB statement and the null
draws common constants that reach it.

```rust
pub struct Rewrite {
    pub subject: String,
    pub left: String,
    pub right: String,
    /// the image statement, fully written in the I3 grammar — not a pattern
    pub image: String,
    /// the declaration the image already is, when it is one
    pub exists: Option<String>,
}

pub fn transport_exact(&self, subject: &str, left: &str, right: &str)
    -> Result<Rewrite, GraphError>;

/// Every rewrite the witnessed inventory suggests for one subject.
pub fn rewrite_targets(&self, subject: &str, min_witnesses: u32) -> Vec<Rewrite>;
```

Gates — `crates/fh-atlas/tests/transport_exact.rs`:

| test | what fails it |
|---|---|
| `an_image_that_is_a_declaration_is_reported_as_existing` | positive |
| `an_open_image_is_reported_with_its_statement_written_out` | the difference from B6's `transport`, which returns a skeleton |
| `a_subject_not_holding_the_left_constant_is_refused` | applicability, never a silent identity |
| `hit_rate_exceeds_a_frequency_matched_null` (`FH_SLICE`) | **negative control**; red if the null arm scores within 10x, red if it did not run |

---

## 11. Costs, measured on the 131k slice

| step | time |
|---|---|
| `Corpus.load` | 5.7 s |
| `Corpus.closure` | 14.5 s |
| build the view: fetch + blank all 131,062 statements (Python) | 23 s |
| enumerate all k=1 uniform substitutions over 66,700 claims | **2.9 s** |
| all within-bucket diffs at every distance | 3 s |
| `classes()` at two levels | 3 s |
| proof-shape families plus the shuffle control | 11 s |
| `presentation` skeletons for all 66,700 claims | 4 s |
| one hole-pattern scan over all 66,700 claims | **0.4–0.5 s** |
| 31,396 rewrites plus the exact-existence lookup | 15 s |

Every one of these is a Python prototype over the binding. In Rust, sharing the arena the
skeleton index already builds, all of them are index-build-time or better.
