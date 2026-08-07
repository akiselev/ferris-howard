# Is physics structurally different from mathematics — and does the engine's tuning transfer?

**Date:** 2026-08-04 · **Script:** `scripts/phys-census.py` · **Surface:** the Python binding
only; no engine change, no CLI.

Every floor, weight and constant in the Atlas was fitted on Mathlib. `CLAUDE.md` §4 warns
that a constant fitted on the wrong slice does not transfer, and gives the cautionary case —
`Mathlib.Logic.Basic`, which "sounds like Mathlib" and is 37% Lean metaprogramming. The same
question has never been asked of *physics*, and physlib is the one corpus in this project
other people wrote.

---

## 0. What would have counted, registered before the first run

| question | a difference | a null |
|---|---|---|
| **Q1 census** | a median ratio outside `[0.5, 2.0]`, or hole density differing by >10 pp | ratios near 1 |
| **Q2 prefilter** | a materially different fraction of declarations with **zero** surviving posting keys — the mechanism by which a size floor manufactures a false negative | the same key counts and the same zero rate |
| **Q3 ranking** | never-proposed share away from Mathlib's 33.3%, or a different floor *sensitivity* | the same split, 0 buried on both |
| **Q4 separator** | a structural statistic whose held-out AUC beats what separates two Mathlib subfields | AUC ≈ 0.5, or no better than subfield separation |

That table is the script's module docstring, written before anything ran.

### The four answers

1. **Yes, physics is structurally different** — twice the statement size, 1.7× the symbol
   density, half the binders, no instance binder at the median, and one `Iff` per twelve `Eq`
   against whole Mathlib's one per four. But the *tuning slice* differs from whole Mathlib by
   about as much as whole Mathlib differs from physics.
2. **The prefilter's size floors transfer.** Zero declarations in either stratum are left
   without a posting key at the shipped floors, and the median key counts differ by 3%. This
   is the pre-registered null, and it is the one that redirected the whole study.
3. **The ranking transfers exactly; candidate generation does not.** Zero of 559 physics true
   neighbours are buried by the scorer, and zero of 562 for mathematics — but physics loses
   40.4% of its neighbours to the prefilter against mathematics' 29.4% in the same index. The
   deficit is 30 pairs that *share an indexable key* and were never proposed anyway — and
   `candidate_budget` is directly exonerated (0 of 127 physics queries reach it), which leaves
   `max_posting_fraction` as the mechanism.
4. **No statistic identifies a corpus as physics.** `nodes_per_binder` separates physics
   modules from Mathlib modules at held-out AUC 0.821 against a 0.499 shuffle — and two
   Mathlib subfields separate from each other at a median 0.771 and a maximum 0.929 on the
   same statistic. Physics is a subfield, not a different kind of thing.

---

## 1. The corpora, and the coverage of each

The erasure holes arguments in `InstImplicit` positions **of the head constant's signature**,
so a head the slice does not contain holes nothing and that spine degrades silently to
`Presentation` (§31). Hole density is exactly the statistic this document compares, so every
corpus carries its `Corpus.closure()` coverage.

| corpus | file | declarations | coverage | role |
|---|---|---:|---:|---|
| **algebra slice** | `/tmp/mathlib-algebra.jsonl` | 131,062 | **99.25%** | the slice every shipped constant was fitted on |
| **whole Mathlib** | `/tmp/mathlib-closure.jsonl` | 470,435 | **99.74%** † | mathematics at scale |
| **physics-closed** | `/tmp/pc-physclosed.jsonl` | 95,268 | **99.46%** | the comparison corpus — physics *and* mathematics inside one index |
| **physlib `--local`** | `/tmp/fh-physlib.jsonl` | 14,563 | **12.39%** | positive control: the §31 artifact, on purpose |

† 99.74% is §35's measurement with `scripts/slice-closure.py`; it was not re-measured here,
because loading that corpus costs ~11 GB and other agents were running. Every coverage
marked without a dagger was measured by `Corpus.closure()` in this session.

**The physics-closed corpus, and why it is built rather than extracted.** A full
`lake exe atlas_extract Physlib QuantumInfo` was started and had not finished encoding after
40 minutes of CPU, so the comparison corpus was *constructed*: the transitive closure of
`uses_statement` from all 14,554 physics declarations (17,782 rows), plus 60,000 Mathlib
theorems with their own citation closure, drawn from `/tmp/mathlib-closure.jsonl` ∪
`/tmp/fh-physlib.jsonl`. It measures **99.46%** and its entire miss list is the harmless
auto-generated family §35 describes — `PiLp.innerProductSpace._proof_1` (826 statements),
`Physlib.Distribution._proof_1` (208), `complexLorentzTensor.repDim.match_1` (174) — none of
which heads a statement the erasure must normalise.

Two things follow from how it was built and both are stated rather than hidden. It is a
**cross-toolchain merge** (physlib on `v4.32.0`, Mathlib on `v4.32.2`), so CLAUDE.md §7's
caveat applies: sound for analogy — which is what skeletons, erasure and retrieval are — and
not for identity. And its physics closure is *small*: physics statements reach only 3,228
non-physics constants transitively, which is itself a finding about how narrow the vocabulary
of a physics statement is.

---

## 2. The census: physics states bigger, denser, less-quantified claims

Read off the I3 encoding, streaming, no `Corpus` involved. Theorems only — CLAUDE.md §5's
restriction to claims, without which the largest structures in any slice are recursors and
`sizeOf` instances. `tele*` are the top-level binders of the telescope; `tele_t` are the
instance binders.

### Medians

| corpus · stratum | theorems | nodes | depth | apps | distinct syms | tele | tele_t | tele_i | concl arity |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| algebra · Mathlib | 15,916 | 85 | 15 | 36 | 9 | 5 | 1 | 3 | 3 |
| algebra · substrate | 49,974 | 79 | 14 | 32 | 10 | 5 | 0 | 3 | 3 |
| whole Mathlib · Mathlib | 32,652 | **171** | 20 | 75 | 15 | 7 | 2 | 3 | 3 |
| whole Mathlib · substrate | 7,221 | **79** | 14 | 32 | 10 | 5 | 0 | 3 | 3 |
| physlib · physics | 9,494 | **367** | 23 | 173 | **26** | 4 | **0** | 1 | 3 |

Whole-Mathlib figures are a stride-8 systematic sample of the 470,435-row closure (composition
counted on every row); everything else is exhaustive. Statement encodings are what `--local`
filters *after*, so the physics rows are byte-identical in the closed and unclosed
extractions and this table does not depend on closure.

### The null control that says the pipeline works

`Init`/`Lean`/`Std`/`Batteries` are the *same declarations* in both Mathlib corpora, and the
two corpora were extracted independently and read by two different code paths (exhaustive vs
strided). Every median agrees exactly — 79 nodes, depth 14, 32 applications, 10 distinct
symbols, 5 binders, 0 instance binders, conclusion arity 3 — and so does the conclusion-head
profile (`Eq` 69.5% against 69.0%). A census that disagreed here would have been measuring
the extraction.

### What is actually different

| | physics ÷ whole Mathlib | physics ÷ algebra slice |
|---|---:|---:|
| nodes, median | **2.15×** | 4.32× |
| nodes, p90 | 5,431 ÷ 1,373 = **3.96×** | 25.3× |
| nodes, p99 | 68,825 ÷ 16,763 = 4.11× | 118× |
| nodes, max | 7,842,861 ÷ 1,022,631 | 521× |
| distinct symbols, median | **1.73×** | 2.89× |
| telescope length, median | **0.57×** | 0.80× |
| instance binders, median | 0 vs 2 | 0 vs 1 |

Physics claims are **twice the size and nearly twice the symbol density of Mathlib's, with
roughly half the binders and no instance binder at the median**. The size ratio clears the
pre-registered `[0.5, 2.0]` band; so does the telescope ratio, in the other direction.

That combination is the finding, and it has an ordinary reading: Mathlib states a claim
*generically* — quantify a carrier, assume a class, conclude — while physics states it
*concretely*, over ℝ or a fixed Hilbert space, and pays for the concreteness in the size of
the terms it has to name. `tele_t` median 2 against 0 is that difference in one number.

**And the tuning slice is the outlier, not physics.** `/tmp/mathlib-algebra.jsonl` — the
corpus every shipped constant was fitted on — has Mathlib theorems at **half** whole
Mathlib's median size (85 against 171) and a *quarter* of its p90 (215 against 1,373). On
statement size the ordering is algebra slice < whole Mathlib < physics, and the two steps are
about the same size. Nothing about physics is exotic on this axis; the fitted corpus is small.

### What a claim concludes

Share of theorems by conclusion head:

| corpus · stratum | `Eq` | `Iff` | `LE.le` | Eq ÷ Iff |
|---|---:|---:|---:|---:|
| algebra · Mathlib | 40.1% | 22.9% | 6.7% | 1.7 |
| whole Mathlib · Mathlib | 50.2% | 12.9% | 4.6% | 3.9 |
| physlib · physics | **66.3%** | **5.4%** | 4.7% | **12.2** |
| substrate (both corpora) | 69.5% / 69.0% | 11.8% / 11.4% | 2.7% | 5.9 / 6.0 |

Physics is equation-heavy and equivalence-poor: it states one `Iff` for every twelve `Eq`,
where the algebra slice states one for every 1.7 — and where the *substrate*, which is Lean's
own library rather than mathematics, sits at 5.9. The head is read off the conclusion's spine,
never off a name.

---

## 3. Hole density: the erasure transfers, and the closure control proves the measurement

Each level's mean fraction of nodes replaced by a hole, over sampled theorems.

| corpus (coverage) · stratum | sampled | exact | presentation | instances | carriers | shape |
|---|---:|---:|---:|---:|---:|---:|
| physics-closed (99.46%) · **physics** | 1,448 | 0.000 | 0.000 | 0.107 | **0.238** | 0.402 |
| physics-closed (99.46%) · Mathlib | 1,476 | 0.000 | 0.000 | 0.154 | **0.269** | 0.373 |
| algebra (99.25%) · Mathlib | 1,500 | 0.000 | 0.000 | 0.090 | **0.242** | 0.359 |
| algebra (99.25%) · substrate | 1,500 | 0.000 | 0.000 | 0.056 | 0.201 | 0.345 |
| **physlib `--local` (12.39%) · physics** | 1,444 | 0.000 | 0.000 | 0.034 | **0.058** | 0.374 |

**Q1's hole-density criterion is a null.** Physics holes 23.8% of its nodes at `carriers`;
Mathlib holes 26.9% in the same corpus and 24.2% in the algebra slice. The spread across
three closed populations is 3 pp, against a pre-registered threshold of 10 pp. The erasure
does the same amount of work on physics as on mathematics.

**The positive control fires, hard.** The same physics declarations measured on the 12.39%-
closed `--local` extraction hole **0.058** at `carriers` — a **4.1× understatement** of the
0.238 the closed corpus gives. §31 predicted exactly this and the size of it is worth
recording: had this study been run on `/tmp/fh-physlib.jsonl`, its headline would have been
"the carrier erasure barely fires on physics", which is false and would have been reported
as a structural fact about physics rather than as a fact about the extraction command.

Note also which levels move. `exact` and `presentation` are identical across closures —
`Presentation` stars universe levels, normalises `StrictImplicit` and collapses
`OfNat.ofNat`, and consults no signature — while `instances`, `carriers` and `shape` all
degrade, because each of those asks `Signatures::arg_kind` or `is_concrete_carrier` about a
head the slice may not contain. Source B's postings are keyed at `Presentation`, so they are
closure-independent; source C's are keyed at `Shape` and are not.

---

## 4. Q2 — the size floors do not starve physics. This is a null, and it matters

`SkeletonIndex::build` files a declaration under every subterm of its `Presentation` erasure
that reaches `min_concrete_closed=3` (or `min_concrete_open=5` if the subterm has loose de
Bruijn indices), and under every subterm of its `Shape` erasure reaching `min_shape_sub=8`.
Those are build-time knobs the Python binding deliberately does not expose, so they are
simulated by parsing the skeletons the engine renders.

**The simulation is validated against the engine before it is used** (`phys-census.py check`,
on the algebra slice):

```
size agreement:            200/200   engine motif key size == parsed size
membership agreement:      120/120   a key the simulation extracts is one the engine files
walker vs arena size:      400/400   the census's node count == Arena::size
SIMULATION FAITHFUL
```

Physics and Mathlib **inside the same 95,268-declaration index**:

| stratum | floors | median concrete keys | zero concrete keys | median shape keys | zero shape keys |
|---|---|---:|---:|---:|---:|
| physics | **3/5/8 (shipped)** | 71 | **0 (0.0%)** | 19 | 14 (1.0%) |
| Mathlib | **3/5/8 (shipped)** | 73 | **0 (0.0%)** | 25 | 8 (0.5%) |
| physics | 1/1/4 | 112 | 0 (0.0%) | 25 | 1 (0.1%) |
| Mathlib | 1/1/4 | 117 | 0 (0.0%) | 31 | 0 (0.0%) |
| physics | 6/10/14 | 44 | 7 (0.5%) | 14 | 84 (5.8%) |
| Mathlib | 6/10/14 | 45 | 2 (0.1%) | 18 | 28 (1.9%) |

At the shipped floors **no declaration in either stratum is left with zero source-B keys**,
and the median key counts differ by 3%. The pre-registered difference — a materially
different zero-key rate — does not appear. The one asymmetry is source C: physics is twice as
likely to have no shape key at the shipped floor (1.0% against 0.5%) and three times as
likely at 6/10/14 (5.8% against 1.9%), because `Shape` holes every constant and physics
statements, once their constants are gone, are shallower relative to their size than
Mathlib's.

Two secondary observations, both corpus effects rather than physics effects:

* the algebra slice gives **26** median concrete keys where the same floors give 71–73 on the
  larger corpus — key count tracks statement size almost exactly, so the shipped floors were
  fitted where statements are smallest;
* `max_posting_fraction = 0.001` is applied as `((n * 0.001) as usize).max(50)`, so for any
  corpus below 50,000 declarations the cutoff is a constant 50 regardless of `n`. On physlib
  alone (14,576 rows) that is 0.34% of the corpus, not the 0.1% the field name promises. It
  does not bite here because the comparison corpus is 95,268 rows, but it is a knob that
  silently means something else on a small slice — which is the shape of corpus every physics
  workspace produces.

---

## 5. Q3 — the ranking transfers perfectly; candidate generation does not

`examples/recallcheck.rs`'s protocol, through the binding: truth is `similar_brute`'s top 5,
the prediction is `similar`'s top 50, and an untruncated `similar` separates *the prefilter
never proposed it* from *the ranking buried it*. The split is clean because `similar_brute`
applies the same `min_common`/`min_retention`, so every truth entry clears those floors by
construction.

| corpus (coverage, n) · stratum | queries | truth | recall@50 | never proposed | **buried** | median candidates raw / after floors |
|---|---:|---:|---:|---:|---:|---:|
| physics-closed (99.46%, 95,268) · **physics** | 127 | 559 | **59.6%** | 226 (**40.4%**) | **0 (0.0%)** | 156 / 4 |
| physics-closed (99.46%, 95,268) · Mathlib | 135 | 562 | **70.6%** | 165 (**29.4%**) | **0 (0.0%)** | 176 / 5 |
| algebra (99.25%, 131,062) · Mathlib | 142 | 694 | 71.9% | 190 (27.4%) | 5 (0.7%) | 160 / 14 |
| algebra (99.25%, 131,062) · substrate | 146 | 694 | 65.0% | 231 (33.3%) | 12 (1.7%) | 181 / 17 |
| physlib `--local` (12.39%, 14,563) · physics | 100 | 331 | 82.5% | 58 (17.5%) | 0 (0.0%) | 75 / 3 |

**The scorer transfers.** Zero true neighbours are buried by the ranking on physics, and zero
on Mathlib in the same corpus. CLAUDE.md §5's "remaining recall work belongs in candidate
generation; the scorer is not losing anything" holds on a corpus it was never measured on.

**Candidate generation transfers worse.** In one index, with one set of postings and one
corpus size, physics loses 40.4% of its true neighbours to the prefilter against mathematics'
29.4% — an 11-point deficit, 1.37×.

**The unclosed row is there to be disbelieved.** On the 12.39%-closed extraction the same
queries look *better* than Mathlib (82.5% recall, 17.5% never proposed). They are not: with
almost no head signature available the `carriers` erasure barely fires, so the truth set is
computed over near-unerased terms and collapses onto a smaller, easier neighbourhood. An
unclosed corpus does not merely add noise here, it moves the answer in the flattering
direction.

### Floor sensitivity: it separates corpora, not subjects

Recall@50 against a truth set fixed at the shipped floors, sweeping `min_retention` with
`min_common = 6`:

| corpus · stratum | 0.10 | 0.20 | **0.30 (shipped)** | 0.45 | 0.60 | drop 0.30→0.60 |
|---|---:|---:|---:|---:|---:|---:|
| physics-closed · physics | 0.596 | 0.596 | **0.596** | 0.522 | 0.411 | **−18.5 pp (−31%)** |
| physics-closed · Mathlib | 0.706 | 0.706 | **0.706** | 0.616 | 0.468 | **−23.8 pp (−34%)** |
| algebra · Mathlib | 0.719 | 0.719 | **0.719** | 0.697 | 0.651 | −6.8 pp (−9%) |
| algebra · substrate | 0.650 | 0.650 | **0.650** | 0.631 | 0.591 | −5.9 pp (−8%) |
| physlib `--local` · physics | 0.825 | 0.825 | **0.825** | 0.653 | 0.517 | −30.8 pp (−37%) |

Physics and Mathlib behave the *same* — within one corpus, mathematics is if anything the
more sensitive of the two. What differs by a factor of four is the **corpus**: on the algebra
slice raising the retention floor to 0.60 costs 8–9% of recall, and on the 95k mixed corpus
it costs 31–34%. Had only the cross-corpus comparison been run (physlib `--local` against the
algebra slice, −37% against −9%) the obvious conclusion would have been "physics is four times
more floor-sensitive", and it would have been wrong. The within-corpus control is what
refutes it.

Lowering `min_retention` below 0.30 changes nothing anywhere, and that is an artifact of the
protocol rather than a fact about the floor: `similar_brute` has no floor knob in the binding,
so the truth set is always the one the shipped floors define, and a lower floor can only
recover *buried* entries — of which there are none.

`min_common` is nearly inert on both: 6 → 14 costs 5.9 pp on the algebra slice's Mathlib and
4.9 pp on physics.

---

## 6. Equivalence classes and motifs

Claims only (`classes` excludes non-propositions outright, and `theorems_only` additionally
drops Prop-valued definitions), on the 95,268-row physics-closed corpus at 99.46%:

| level | classes | members | largest | mean size | dominant stratum of the top 200 |
|---|---:|---:|---:|---:|---|
| exact | 629 | 1,277 | 3 | 2.03 | Mathlib 199 · physics 1 |
| presentation | 662 | 1,344 | 3 | 2.03 | Mathlib 200 · physics 0 |
| instances | 1,052 | 2,224 | 5 | 2.11 | Mathlib 200 · physics 0 |
| carriers | 1,151 | 2,445 | 5 | 2.12 | Mathlib 195 · physics 5 |

Physics is 15% of the corpus and supplies 0–2.5% of the largest equivalence classes.
Mathematics states the same thing twice; physics essentially does not — consistent with §3c's
observation that what physlib duplicates is *code* (a units API replicated per dimension), not
claims.

Motif families (top 400 by `size × ln(family)`, so both columns are size-biased in the same
way on every corpus):

| corpus | source | mean family | max family | **mean motif size** | max motif size |
|---|---|---:|---:|---:|---:|
| algebra slice (131,062) | subterm | 5.97 | 41 | **245** | 1,209 |
| physlib `--local` | subterm | 4.46 | 33 | **15,124** | 171,597 |
| physics-closed (mixed) | subterm | 3.42 | 11 | **42,926** | 171,597 |

The recurring structure physics shares is two orders of magnitude larger than the recurring
structure mathematics shares. A shared Mathlib motif is a 245-node fragment; a shared physics
motif is a 15,000-node one.

---

## 7. Where the missing 40% actually goes — and it is not the size floors

§4 says the floors leave physics with as many keys as mathematics; §5 says physics still
loses 40.4% of its true neighbours before ranking. Those are only compatible if the loss
happens *after* a key exists. `phys-census.py reachability` settles it by asking, for every
truth pair, whether the query and its true neighbour share **any** key that clears the
shipped floors — an empty intersection means no budget, no cutoff and no scorer could have
retrieved that pair, because the index cannot see it.

Both strata, in the physics-closed corpus at 99.46%, at the shipped floors:

| | physics | Mathlib |
|---|---:|---:|
| queries | 74 | 79 |
| truth pairs | 298 | 295 |
| pairs sharing ≥1 indexable key | 248 (**83.2%**) | 251 (**85.1%**) |
| proposed by the prefilter | 170 | 203 |
| …of which share a key | **170/170** | **203/203** |
| **missed** | 128 | 92 |
| …**sharing no key at all** — invisible by design | **50 (16.8% of truth)** | **44 (14.9% of truth)** |
| …**sharing a key and still not proposed** | **78 (26.2% of truth)** | **48 (16.3% of truth)** |
| shared keys per pair, median | 8 | 15 |
| shared keys per pair, mean | 45.1 | 33.5 |

Every proposed pair shares a key, which is the sanity check — that is how it was proposed.

**The whole of the physics deficit sits in one cell.** Physics loses 36 more truth pairs
than mathematics does (128 against 92). Six of those are pairs that share no key at all
(50 against 44 — statistically the same); **thirty of them share a key of indexable size and
were never proposed anyway.** The size floors gave physics a key for those pairs and
something after the floors threw it away.

Two mechanisms, and the one the floors control is the smaller and the *equal* one:

* **Structurally invisible** — 16.8% of physics truth pairs against 14.9% of Mathlib's.
  Sources B and C retrieve by *exact subterm identity*; anti-unification, which defines the
  truth set, needs no identity at all and will happily align two statements that agree in
  shape and differ in every leaf. Those pairs share no key by construction and no floor
  setting can create one. Physics and mathematics are equally exposed to this.
* **Reachable and not retrieved** — 26.2% against 16.3%, and this is the whole difference.
  These pairs share a key that clears the shipped floors, so the loss is *downstream* of the
  floors: either `max_posting_fraction`, which deletes a key at build time when more than
  `max(n × 0.001, 50)` declarations carry it, or `candidate_budget`, which stops accumulating
  at 600. **The budget is not it.** `candidates` breaks only when `hits.len() >= 600` at the
  top of an iteration, so a query whose candidate set ends below 600 exhausted its *keys*,
  not its budget:

  | corpus · stratum | queries | median | p90 | max raw candidates | queries at or over the 600 budget |
  |---|---:|---:|---:|---:|---:|
  | physics-closed · **physics** | 127 | 156 | 337 | 591 | **0** |
  | physics-closed · Mathlib | 135 | 176 | 469 | 637 | 10 |
  | algebra · Mathlib | 142 | 160 | 309 | 567 | 0 |
  | algebra · substrate | 146 | 181 | 375 | 590 | 0 |

  Not one physics query was budget-limited, while ten Mathlib queries were — the budget binds
  on the stratum with *better* recall and never on the stratum with worse. Source A's
  `max_bucket` is not differential either (physics reaches the shape bucket on 50 of 127
  queries, mathematics on 49 of 135). By elimination the remaining mechanism is
  **`max_posting_fraction` deleting the shared key at build time**, which is an elimination
  rather than a direct measurement and is the thing §10.3 exists to confirm.

That mechanism fits §6's motif measurement exactly. Physics shares *large, common* structure —
a 15,000-node fragment of the same units or `LinearMap` machinery, carried by many
declarations at once. A key like that has a long posting list, and a long posting list is
precisely what `max_posting_fraction` deletes as uninformative.

---

## 8. Q4 — a name-free separator exists, and it does not identify *physics*

The unit is a module with at least 20 theorems: 168 physics modules against 243 Mathlib
modules, drawn from the whole-Mathlib closure. Each is summarised by structural means only —
node count, depth, applications, distinct symbols, telescope length, instance binders,
conclusion arity, and five ratios of those. **No name is a feature**; module paths supply the
label and nothing else. Modules are split at random into a training half and a held-out half,
and the held-out AUC is reported beside two controls.

| statistic | held-out AUC (folded) | label shuffle | **Mathlib-subfield pairs: median** | max |
|---|---:|---:|---:|---:|
| `nodes_per_binder` | **0.821** | 0.499 | 0.771 | 0.929 |
| `distinct_syms` | **0.814** | 0.502 | 0.768 | 0.970 |
| `tele_i` (implicit binders) | 0.771 | 0.501 | 0.606 | 0.860 |
| `apps_per_node` | 0.756 | 0.500 | 0.845 | 0.946 |
| `apps` | 0.751 | 0.498 | 0.808 | 0.963 |
| `nodes` | 0.745 | 0.503 | 0.798 | 0.968 |
| `tele_t` (instance binders) | 0.685 | 0.503 | 0.709 | 0.947 |
| `depth` | 0.654 | 0.500 | 0.757 | 0.967 |
| `depth_per_log_nodes` | 0.512 | 0.497 | 0.738 | 0.928 |

**The shuffle control is clean.** 200 label permutations per statistic on the held-out half
give a mean AUC of 0.496–0.504 and a maximum deviation of 0.09–0.13, so 0.821 is not an
artifact of module-size heterogeneity.

**The subfield control refutes the interesting reading.** The last two columns are all
15 pairwise AUCs among six Mathlib subtrees — `Algebra`, `Data`, `CategoryTheory`,
`Topology`, `Order`, `Analysis` — folded to `[0.5, 1]`. For **every** statistic the *median*
Mathlib-against-Mathlib separation is at or near the physics-against-mathematics separation,
and the *maximum* exceeds it on all fifteen. `apps_per_node` separates two Mathlib subfields
better (0.845 median) than it separates physics from mathematics (0.756).

So the answer is a controlled **no**. Physics *is* separable from mathematics by structure
alone, at 0.82 with a clean null — and that is unremarkable, because so is `Mathlib.Analysis`
from `Mathlib.Data`. There is no statistic here that says "this corpus is physics" rather
than "this corpus is a different subfield". Had the subfield control been skipped, the
0.821 would have read as a discovery.

The direction is worth recording anyway, since it is the same one §2 found: physics modules
score **high** on statement size per binder and on distinct symbols, and **low** on implicit
and instance binders. Concrete, verbose, unquantified — one step further along the axis that
already runs from `Mathlib.Data` to `Mathlib.Analysis`.

---

## 9. Verdict: which tuned constants transfer, and which do not

| constant | shipped value | verdict on physics | evidence |
|---|---|---|---|
| `min_concrete_closed` | 3 | **transfers** | 0.0% zero-key declarations in both strata of one index; median key counts 71 vs 73 |
| `min_concrete_open` | 5 | **transfers** | same measurement |
| `min_shape_sub` | 8 | **transfers, with a caveat** | zero-shape-key 1.0% (physics) vs 0.5% (Mathlib); at 14 it is 5.8% vs 1.9% — the gap is real but the shipped value is not where it bites |
| `min_common` | 6 | **transfers** | 6 → 14 costs 4.9 pp on physics, 5.9 pp on Mathlib |
| `min_retention` | 0.30 | **does not transfer — but not because of physics** | 0.30 → 0.60 costs 31% of recall on physics and 34% on Mathlib *in the same corpus*, against 8–9% on the algebra slice. The constant is corpus-sensitive, and it was fitted on the least sensitive corpus available |
| ranking weights (`rarity_weight`, `cross_weight`, `scoped_weight`, `derivative_weight`) | 0.5 / 0.15 / 0.30 / 0.45 | **transfer** | 0 of 559 physics true neighbours buried by the ranking; 0 of 562 for Mathlib |
| `max_posting_fraction` | 0.001 | **does not transfer** | Two defects. `((n as f32 * f) as usize).max(50)` makes the cutoff a constant 50 for any corpus smaller than 50k — 0.34% of physlib's 14,576 rows rather than the 0.1% the name promises. And on the 95,268-row corpus §7 puts 30 of physics' 36 extra missed pairs in the "shares a key, never proposed" bucket, which by elimination is this constant |
| `candidate_budget` | 600 | **exonerated** | 0 of 127 physics queries reached the budget (max 591); 10 of 135 Mathlib queries did. It binds on the stratum with *better* recall and never on the worse one |
| `max_bucket` | 600 | **not differential** | source A reaches 50 of 127 physics queries and 49 of 135 Mathlib ones |

### The sentence to keep

**Physics is not the problem; the tuning slice is.** On every axis measured here, physics sits
one step further along a direction Mathlib is already moving in — statements get bigger, keys
get more numerous, floors get more sensitive as you go from `/tmp/mathlib-algebra.jsonl` to
whole Mathlib to physlib, and the algebra-to-Mathlib step is about the same size as the
Mathlib-to-physics step. The constants were fitted at the small end of that line.

---

## 10. Spec for the engine change

Four changes, in the order they are worth making, and one thing not to build. Each names its
gate, because a knob without a negative control is a knob nobody can trust (CLAUDE.md §3).

### 10.1 `Corpus.profile()` — make "what kind of corpus is this" askable

**Why first.** Every claim in this document needed a structural census, and there was no
surface for one, so `scripts/phys-census.py` re-walks the I3 encoding in Python. Measured:
153 s for the 131,062-row algebra slice, 601 s for a **one-in-eight** sample of the 470,435-row
Mathlib closure, and the exhaustive version of that run was abandoned after reading 1.2 GB of
4.8 GB in 28 minutes. The engine already walks every statement at build time.

**Shape.** `SkeletonIndex::profile() -> CorpusProfile`, with per-stratum breakdown by module
root:

```rust
pub struct CorpusProfile {
    pub declarations: usize,
    pub claims: usize,
    /// Quantiles of `Arena::size` over claims: p25, median, p75, p90, p99.
    pub statement_size: [u32; 5],
    pub telescope_len: [u32; 5],
    pub instance_binders: [u32; 5],
    pub distinct_syms: [u32; 5],
    /// Hole fraction at each level, mean over claims.
    pub hole_fraction: [f32; 5],
    /// Posting keys per declaration at the configured floors, and how many get none.
    pub keys_per_decl: [u32; 5],
    pub decls_without_keys: usize,
    /// The effective posting cutoff, since `max_posting_fraction` is not it below n=50k.
    pub effective_posting_cutoff: usize,
    pub by_module_root: Vec<(String, ProfileRow)>,
}
```

**Touches** (§6's five points): `crates/fh-atlas/src/skel/index.rs`; `bin/atlas.rs`;
`crates/fh-atlas-py` plus `.pyi`; `bin/fh-mcp.rs` — an agent choosing floors needs this more
than a human does; and a gate.

**Gate, with its control.** `scripts/slice-closure.py` already runs a paired assertion; add
the analogous one here. The profile of `/tmp/mathlib-algebra.jsonl` must report a median claim
size **below** that of a whole-Mathlib closure, and the profile of a corpus restricted to
`Init.*` must differ from both. A profile that reports the same numbers for the algebra slice
and for whole Mathlib is broken — 85 against 171 is a 2× separation with nothing between them
to tune, exactly the shape §32's closure gate has.

### 10.2 Fix `max_posting_fraction`'s hidden floor

**Defect.** `index.rs:839`:

```rust
let max_len = ((n as f32 * cfg.max_posting_fraction) as usize).max(50);
```

For `n < 50_000` the configured fraction has no effect at all, and the field name says
otherwise. Physics corpora are exactly this size — physlib is 14,576 declarations, and the
`--local` extraction of any single library will be in the same range.

**Change.** Make the floor a named field, `min_posting_cutoff: usize` (default 50, preserving
today's behaviour bit for bit), and record the *effective* cutoff on the index so
`profile()` can report it. This is a two-line change plus a field; its value is that the knob
stops lying.

**Gate.** A unit test asserting that on a 10,000-row fixture `effective_posting_cutoff == 50`
while `max_posting_fraction * n == 10`, and that setting `min_posting_cutoff: 0` makes the
fraction bind. Both directions, because the point is that the two regimes are distinguishable.

### 10.3 Expose the posting cutoff and the candidate budget to the differential

**Why this is now the first-priority experiment rather than a floor change.** §7 attributes
the entire physics recall deficit — 30 of the 36 extra missed pairs — to truth pairs that
*share an indexable key and were not proposed anyway*, and rules out `candidate_budget` and
`max_bucket` by direct measurement. That leaves `max_posting_fraction` deleting the key at
build time as the only named mechanism, by elimination. `max_posting_fraction` is a
build-time knob and is not reachable from the binding, so the study stops one step short of
confirming it.

**Change.** Let `similar` take `max_posting_fraction`, `candidate_budget` and `max_bucket`
per call — which means the index has to be keyed by the build-time knobs the way
`skeletons_at` is already keyed by `(anchor, normalize_arity)`, since changing
`max_posting_fraction` changes what the index *contains*. And give `similar_brute` the same
`min_common` / `min_retention` parameters `similar` has, so the truth set can be recomputed
at a lower floor instead of being pinned at the shipped one; §5's sweep has an uninformative
downward arm purely because it cannot.

**Gate.** `phys-census.py reachability`'s split is the assertion, and it is a paired one:
with `max_posting_fraction` raised, the *reachable-and-not-retrieved* count must fall while
the *shares-no-key* count stays fixed — the second half is what distinguishes "the cutoff was
the binder" from "something moved". If both move, the knob is not doing what the label says.
Run it on the algebra slice and the physics-closed slice, because the point is transfer.

### 10.4 Corpus-adaptive floors, opt-in, measured by ablation

**Do not** make the shipped floors adaptive by default. The measurement above says the size
floors are *not* where physics loses recall — the zero-key rate is 0.0% in both strata — so an
adaptive floor would be a change with no demonstrated benefit, and CLAUDE.md's rule is that a
filter which narrows output needs its own negative control.

What the measurement *does* support is making the floors expressible as a target rather than
as node counts, so that a corpus with 4× the statement size does not silently get 3× the keys:

```rust
pub enum FloorPolicy {
    /// Today's defaults. Stays the default; every existing result is at this policy.
    Absolute { closed: u32, open: u32, shape: u32 },
    /// Choose the floors at build time so the median claim retains `target` source-B keys,
    /// by scanning the corpus's own subterm-size distribution.
    AdaptiveKeys { target: u32 },
}
```

**Gate, and it must be an ablation, not a before-and-after.** CLAUDE.md §5: `similar_brute`
ranks *by* retention and filters by `min_retention`, so anything that moves the candidate set
moves the truth set too. The honest measurement is `recallcheck`-style, on a fixed truth set
computed once at `FloorPolicy::Absolute`, comparing candidate-set size and never-proposed
share under each policy on **two** corpora of different statement scale — the algebra slice
and the physics-closed slice. `AdaptiveKeys` ships only if it does not lose recall on either,
and it should be judged on cost (keys per declaration, index size) rather than on recall,
because recall is not what it is for.

### 10.5 What the measurement says *not* to build

* **Do not retune the ranking weights per corpus.** Zero true neighbours were buried by the
  ranking on either stratum. There is nothing there to win.
* **Do not lower `min_retention` on the strength of §5's sweep.** The sweep's downward arm is
  uninformative by construction — the truth set is defined at 0.30 and nothing is buried — so
  it measures the floor's cost and not its benefit. §10.3 is what makes it answerable.
* **Do not lower the posting-key size floors** hoping to recover physics recall. §7 says 30
  of the 36 extra misses already have a key. Lowering the floors adds keys to pairs that are
  found anyway and does nothing for the pairs that share no key at all, whose count is the
  same in both strata.

---

## 11. What was not run, and what would change the answer

* **The full `atlas_extract Physlib QuantumInfo` closure was not used.** The invocation this
  session waited on ran 40+ minutes of CPU at ~9 GB in `encode-all` without writing a byte —
  that path materialises every row before it writes — so the comparison corpus was constructed
  instead. A second, streaming extraction (`[select] 495,067 extractable constants`) began
  writing `/tmp/fh-physlib-closure.jsonl` in the last minutes of this session and is not
  measured here. **Everything in §3–§7 should be re-run on it when it lands**: it is
  single-toolchain, so it is the one thing that would settle whether the cross-toolchain merge
  matters, and the direction of any error from the merge is unknown rather than bounded.
* **`/tmp/mathlib-closure.jsonl`'s coverage was not re-measured** (§35's 99.74% is cited). It
  is used only for the census, which does not touch the erasure.
* **The physics-closed corpus's Mathlib stratum is not a uniform sample of Mathlib.** It is
  everything physics cites plus the first 60,000 Mathlib theorems in module order, and its
  sampled claim size (median 279 nodes at `exact`) sits between the algebra slice's 85 and its
  own p90. Every physics-vs-mathematics comparison in §4 and §5 is therefore *within* that
  corpus and against that stratum; the unbiased Mathlib size figures come from the whole-
  Mathlib census in §2.
* **`max_posting_fraction` is implicated by elimination, not by measurement.** §7 rules out
  the budget and `max_bucket` directly, which leaves the posting cutoff as the only mechanism
  in `candidates` that can drop a pair sharing an indexable key. Confirming it needs the knob
  exposed (§10.3); until then it is an argument from exhaustion of alternatives, and it would
  be wrong if there were a fourth mechanism nobody has named.
* **Statements above 256 kB of encoding were excluded and counted**: 52 of 1,500 sampled
  physics theorems (3.5%, median 482 kB) and 24 of 1,500 Mathlib (1.6%, median 722 kB), and 8
  of 135 physics queries in the differential. The exclusion can only remove mass from the
  upper tail, so §2's claim that physics statements are larger is if anything understated.
* **One physics declaration encodes to 71 MB** and 7.8 million nodes. Nothing in this pipeline
  can process it and nothing in the Atlas has ever been measured on anything like it.

---

## 12. How to re-derive every number here

```sh
# the simulation's control — must print SIMULATION FAITHFUL and exit 0
uv run scripts/phys-census.py check /tmp/mathlib-algebra.jsonl --min-size 3

# §2, the streaming census (no Corpus load, so no memory pressure)
uv run scripts/phys-census.py census /tmp/mathlib-algebra.jsonl   --out census-algebra.json
uv run scripts/phys-census.py census /tmp/fh-physlib.jsonl        --out census-physlib.json
uv run scripts/phys-census.py census /tmp/mathlib-closure.jsonl   --stride 8 --progress \
                                                                  --out census-mathlib.json

# §3–§7, everything that needs a Corpus, from one load
uv run scripts/phys-census.py full /tmp/pc-physclosed.jsonl --prefix pcx \
    --strata phys,math --sample 1500 --queries 150 --classes
uv run scripts/phys-census.py reachability /tmp/pc-physclosed.jsonl \
    --out pcx-reach-phys.json --stratum phys --sample 80
uv run scripts/phys-census.py reachability /tmp/pc-physclosed.jsonl \
    --out pcx-reach-math.json --stratum math --sample 80

# the positive control: the same measurements on the 12.39%-closed extraction
uv run scripts/phys-census.py erasure /tmp/fh-physlib.jsonl --strata phys \
    --out erasure-physlib-unclosed.json

# §8
uv run scripts/phys-census.py separator census-physlib.json census-mathlib.json \
    --out separator.json

# the tables above, rendered rather than transcribed
uv run scripts/phys-census.py tables --census "algebra=census-algebra.json" … --out tables.md
```

and the comparison corpus itself:

```sh
cat /tmp/mathlib-closure.jsonl /tmp/fh-physlib.jsonl > /tmp/pc-merged-physmath.jsonl
uv run scripts/phys-census.py build-closed /tmp/pc-merged-physmath.jsonl \
    --out /tmp/pc-physclosed.jsonl
# read 485,011 rows · closure of the physics seeds 17,782 · +60,000 Mathlib theorems and
# their closure → 101,393 names, 95,268 of which have a row → Corpus.closure() 99.46%
```

`Corpus.closure()` is the gate on that construction, not a formality: a slice built this way
that measured below 95% would have to be discarded, because every hole-density and
equivalence-class number in §3 and §6 is computed *through* the erasure.

