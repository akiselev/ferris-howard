# The posting cutoff: what it deletes, what raising it buys, and what it costs

**Corpus.** `/tmp/pc-physclosed.jsonl` — 95,268 declarations, physlib and QuantumInfo plus
the Mathlib constants their statements reach, **99.4553% closed** (measured, §3). Module
roots are stripped to a copy at `/tmp/pfx-base.jsonl` so each physics subfield is its own
theory; `dict::theory_of` takes depth 1 outside Mathlib, and without the rewrite
`dictionary("ClassicalInfo", …)` returns an empty result with no error
(`physlib-classical-quantum.md` §4). `/tmp/fh-physlib.jsonl` is 12.4% closed and is not used.

**Engine.** `fh-atlas` through the Python binding, and **the build is not pinned** — other
sessions are editing the crate while this runs. Every number below was taken by processes
that imported one extension build; the source line references were read at the same time and
should be checked against the commit a reader is on.

**Script.** `scripts/phys-prefilter.py`.

Sections §1 and §2 are the pre-registration and were written before any measurement in this
study was run. Results begin at §3.

---

**The result in one paragraph.** The four pre-registered classical↔quantum information
correspondences are deleted by one build-time constant. Raising `max_len` from its shipped 95
to 400 returns three of them through `Corpus.dictionary`; raising it to 1,600 returns all four
as the dictionary's **top five rows**, where at the shipped value none of them is even a
candidate. The keys that carry them, measured: `0 ≤ (·:ℝ)` at document frequency 359,
`(· = · : ℝ)` at 1,761 and `((·:ℕ):ℝ)` at 243, in a corpus of 95,268 — three to seven nodes
each, and the entire structural overlap between the two sides. A matched-N control separates
the cause cleanly: at the *same* cutoff, 985 real declarations give 4 / 4 and 95,268 give
0 / 4. It costs 4.4× the query latency and 5.5× the median candidate set, and it leaves the
two pre-registered nonsense dictionaries at 35 → 36 and 7 → 7 rows. And a length cutoff turns
out to be the wrong *shape* of rule: at full scale no flat cutoff reaches 4 / 4, because
`candidate_budget` takes over — while a per-source cap, a theory-scoped budget, or a
postings-walked budget each reach it, two of them more cheaply than any cutoff does. And on
the 495,067-declaration full import closure, where the shipped fraction already yields a cutoff
of 495, recall is still 0 / 4 and the dictionary falls from 6 rows to 1: **the constant does
not transfer, and a bigger one of the same shape is not the fix.**

---

## 1. The defect, and why it is worth a study of its own

`Postings::build` drops a posting key held by more than

```rust
max_len = max((n as f32 * cfg.max_posting_fraction) as usize, cfg.min_posting_len)
```

declarations — 0.1% of the corpus, or 50, whichever is larger. On this corpus that is **95**.
The comment above it is honest about why: a key held by a large fraction of the corpus
carries no information and would dominate every candidate set it appears in.

That reasoning is correct for the query the index was built for — *what looks like this
declaration* — and exactly wrong for the query a cross-theory dictionary asks. Two theories
that state the same idea in different carriers share **common** structure, not rare
structure: `0 ≤ f x` and `∑ = 1` are what survive when the carrier changes, and those are
the keys a length cutoff removes first.

Two independent measurements already point here, and this study exists because neither one
closed the loop.

* **The dilution experiment** (`physlib-classical-quantum.md` §7, §11). Hold two theories'
  rows byte-identical and grow the corpus around them: 3 of 4 pre-registered true dictionary
  rows at 347 declarations, 0 of 4 at 20,347, monotone in between, on a 99.46%-closed corpus.
  The rows never change; only the corpus does. That report named `max_len` as the only
  quantity in the retrieval path that depends on the rest of the corpus — and said plainly
  that the crossing point was an inference, because instrumenting `Postings::build` to
  report which keys it dropped does not exist.
* **The census** (`physlib-census.md` §7). Of 36 physics truth pairs the prefilter missed
  beyond mathematics' rate, **30 share an indexable key and were never proposed**.
  `candidate_budget` is directly exonerated (0 of 127 physics queries reached it, against 10
  of 135 Mathlib queries) and `max_bucket` is not differential. `max_posting_fraction` is
  what remains — by elimination.

So there is an inference from one side and an elimination from the other, and no measurement
of the thing itself. The ground truth for that measurement already exists and was
pre-registered before any of it: four classical↔quantum information correspondences, named
from physics and then found by the anti-unifier at conclusion-anchored retention 0.697–0.889
against nulls of 0.04–0.10, all four topping the *exhaustive* dictionary and **none returned
by the shipped one**.

| # | left (classical) | right (quantum) | retention | E |
|---|---|---|---:|---|
| T1 | `Hₛ_nonneg` | `Sᵥₙ_nonneg` | 0.889 | E16 |
| T2 | `Hₛ_constant_eq_zero` | `Sᵥₙ_of_pure_zero` | 0.818 | E16/E20 |
| T3 | `H₁_nonneg` | `Sᵥₙ_nonneg` | 0.741 | E16 |
| T4 | `Hₛ_le_log_d` | `Sᵥₙ_le_log_d` | 0.697 | E16 |

A recall curve with a known numerator is rare. This one also has a matching precision
control that is already known to behave badly: `ClassicalMechanics ~ Meta` — physics against
the library's own HTML-note utility, a pair between which no correspondence can exist —
returned more rows at a *higher* mean retention than the real dictionary.

## 2. Pre-registration

### 2a. The instrument, and what it does not emulate

`IndexConfig::min_posting_len` landed recently and `max_posting_fraction` has always
existed; **neither is reachable from the Python binding**, and Rust edits are out of scope
for this session (other agents are active in the crate). `max_len` reads the corpus only
through `n`, so the knob can be moved from outside: appending rows that **parse and carry no
key** raises `n`, and therefore `max_len`, while leaving every real key's document frequency
byte-identical.

The padding row is

```json
{"kind":"def","module":"ZPad","name":"zpad.pN","stmt":"fh-stmt-v1;s(0)",
 "uses_proof":[],"uses_statement":[]}
```

a single `Sort` node. It is below every posting-key size floor (3 closed, 5 open, 8 shape) so
it contributes no posting; it has no application head so `collect_app_heads` returns nothing
and `closure()` cannot move; its module is its own theory so `restrict_prefix` and
`theory_of` exclude it from every dictionary here.

**Verified before use, on a 4,001-row base padded by 3,000 rows**: `known_heads` 125,464 and
`unknown_heads` 284,075 identical with and without padding — coverage equal to six decimal
places — and **zero** motif families contain a padding declaration. Both `s(0)` and `b0`
behave identically; `s(0)` is the one used.

**What the padding does not emulate, stated rather than hidden.** `n` also enters
`idf = ln(n/df)`, the rarity boost `1 + w·min(idf/ln n, 1)`, and `derivativeness`'s
percentile ranks. None of the three gates *admission* — `similar` floors on `common` and on
the configured score, and with the shipped `Retention` scorer neither reads `n` — but all
three move the score, hence the order inside a candidate set, hence which partner `per_decl`
selects. So every recall number is reported at two levels:

* **proposed and above floors** — membership of `similar(…, min_retention=0.30,
  min_common=6)`. Score-free, therefore unconfounded, and the primary number.
* **in the shipped `dictionary`** — confounded by ordering, reported anyway because it is
  the surface a caller has.

`generalize` is carried at every rung as the instrument's own tell-tale: it parses two
statements and calls `lgg` with no erasure, no signature lookup and no corpus, so its four
retentions must not move by a digit. If they move, the padding is not inert.

### 2b. The ladder

`max_len = max(⌊0.001·n⌋, 50)`, so a corpus of `n` rows buys a cutoff of `n/1000`.

| rung | real rows | padding | n | `max_len` | multiple of shipped |
|---|---:|---:|---:|---:|---:|
| base | 95,268 | 0 | 95,268 | 95 | 1× |
| NC-pad | 95,268 | 100 | 95,368 | 95 | 1× |
| L200 | 95,268 | 104,732 | 200,000 | 200 | 2.1× |
| L400 | 95,268 | 304,732 | 400,000 | 400 | 4.2× |
| L800 | 95,268 | 704,732 | 800,000 | 800 | 8.4× |
| L1600 | 95,268 | 1,504,732 | 1,600,000 | 1,600 | 16.8× |
| L3200 | 95,268 | 3,104,732 | 3,200,000 | 3,200 | 33.7× |

**NC-pad is the control on the instrument.** ⌊95,368 × 0.001⌋ = 95, the same cutoff as the
base. Every number at NC-pad must equal the base's. If any of them moves, the padding is
doing something other than what it is here for and the ladder above it means nothing.

### 2c. What a good answer looks like, and what would refute the hypothesis

* **R1 — recall.** At some rung, at least one of T1–T4 is *proposed and above floors* where
  at the base rung none is. **If all four are still absent at `max_len` = 3,200 — 34× the
  shipped cutoff — then the cutoff is not the binding constraint**, and this report says so
  rather than reaching for a larger ladder.
* **R2 — the matched-N control, which is the arm that can refute.** Raising `max_len` and
  lowering document frequency are the same move on `df / max_len`, and the dilution
  experiment already did the second. Two corpora are built at the **same** n — hence the
  same cutoff — differing only in how many of their rows are real:
  * *low-df*: the statement-closure of `ClassicalInfo ∪ Entropy` inside the corpus, padded
    to n = 200,000;
  * *high-df*: all 95,268 real rows, padded to n = 200,000.

  If the targets return in the low-df arm and not in the high-df arm at the same cutoff,
  document frequency against the cutoff is the mechanism. **If they return in both, the
  sweep is measuring something other than the cutoff**; if in neither, the cutoff is not the
  cause. The low arm is a *closure*, not a random subsample, because a random subsample of a
  closed corpus is not closed and would confound the cutoff with the erasure degrading
  (CLAUDE.md §7, findings §31).
* **R3 — precision, with the control that already misbehaves.** `ClassicalMechanics ~ Meta`
  and `Thermodynamics ~ Meta` are run at every rung beside the real pair. If raising the
  cutoff inflates the nonsense dictionaries at least as fast as the real one, the trade is
  reported as bad. Recall is the expensive direction (CLAUDE.md §3) — but a knob that buys
  nothing except more of everything is not a recall knob, it is a volume knob.
* **R4 — cost.** Index build time, peak RSS, `similar` latency and candidate-set size at
  every rung, over a fixed sample of 40 physics theorems drawn with a fixed seed. The
  interaction to watch is `candidate_budget`: `candidates` walks keys **rarest first** and
  stops adding keys once 600 candidates are held, so a newly admitted common key is walked
  *last* and may never be reached. **A cutoff that recovers recall by saturating the budget
  has not recovered recall; it has moved the loss one component along**, and the
  at-or-over-600 count is what says which happened.
* **R5 — is a length cutoff the right shape at all?** A key's informativeness is IDF-like
  and a hard cutoff on posting length is a crude proxy for it. The posting inventory —
  `motifs` at `min_family=2`, which reads the surviving keys straight off the posting lists
  — is used to measure, for each true pair, **which keys the two sides actually share and
  how many declarations hold each**. That is the instrumentation the dilution experiment
  said did not exist. With the per-declaration key sets recovered by inverting those member
  lists, alternative admission rules are simulated against the same ground truth:
  * (a) today's hard length cutoff at `M`;
  * (b) size-conditioned admission — a long list is admitted when the key is large;
  * (c) keep everything and let the rarest-first walk plus a work budget do the pruning;
  * (d) per-source caps, since source B (concrete subterms at `Presentation`) and source C
    (`Shape` subterms) have different distributions and only one of them can cross carriers.

  Each is scored on the same numerator (T1–T4 proposed) and the same cost axes (postings
  retained, candidates visited).
* **R6 — the wild question.** `similar_brute` and the `generalize`-based exhaustive path
  exist. What does exhausting *all* cross-theory pairs inside physics cost, measured, and is
  a two-tier design — prefilter within a theory, exhaust across — affordable at this scale?

### 2d. What is deliberately not claimed

The mechanics half of the ground truth is a **real negative**: all nine testable
classical↔quantum mechanics pairs anti-unify at 0.002–0.074 conclusion-anchored, at null
level, and exhausting all 218,348 classical×quantum pairs yields nothing physical in the top
400. No cutoff can recover a correspondence that is not in the statements. This study is
about the information half, where the correspondence demonstrably *is* in the statements and
the retrieval layer deletes it. `ClassicalMechanics ~ QuantumMechanics` is carried at every
rung precisely so that a recall gain there would be read as noise rather than as a discovery.

---

## 3. The baseline, and the control that says the instrument is inert

Measured on the closed corpus, conclusion anchor, `carriers`, shipped floors throughout.

| | base | NC-pad |
|---|---:|---:|
| declarations | 95,268 | 95,368 |
| padding rows | 0 | 100 |
| `max_len` | 95 | 95 |
| closure coverage | 0.9945527209261904 | 0.9945527209261904 |
| NC2 — `carriers` ≠ `presentation` | 7 / 7 | 7 / 7 |
| `generalize` T1 / T2 / T3 / T4 | 0.8889 / 0.8182 / 0.7407 / 0.6970 | 0.8889 / 0.8182 / 0.7407 / 0.6970 |
| **T1–T4 proposed and above floors** | **0 / 4** | **0 / 4** |
| candidates for T1 / T2 / T3 / T4's left | 16 / 4 / 56 / 90 | 16 / 4 / 56 / 90 |
| candidate set, median / p90 / max | 126.5 / 420 / 649 | 126.5 / 420 / 649 |
| queries at or over the 600 budget | 2 / 40 | 2 / 40 |
| `ClassicalInfo ~ Entropy` rows | 6 | 6 |
| `ClassicalInfo ~ States` rows | 18 | 18 |
| `ClassicalMechanics ~ QuantumMechanics` rows | 62 | 62 |
| **NC3** `ClassicalMechanics ~ Meta` rows | 35 | 35 |
| **NC3** `Thermodynamics ~ Meta` rows | 7 | 7 |
| index build (`closure()` forces it) | 104.1 s | 95.9 s |
| peak RSS | 7.39 GB | 7.40 GB |

**NC-pad passes exactly.** Coverage agrees to sixteen digits, every candidate count agrees,
every dictionary agrees row for row. The padding is inert where it is supposed to be, so the
ladder above it moves one quantity.

The baseline reproduces the prior report's headline independently and on the closed corpus:
**four correspondences that the anti-unifier scores at 0.70–0.89 are not merely unranked,
they are not proposed.** `Hₛ_constant_eq_zero` has **four** candidates in a corpus of 95,268.

## 4. The recall/cost curve

Every rung is the same 95,268 real declarations, padded with keyless rows to move `max_len`
and nothing else. `generalize` returns 0.8889 / 0.8182 / 0.7407 / 0.6970 at every rung, to
four decimals, so the instrument stayed inert the whole way up.

**§2b's ladder listed a seventh rung at `max_len` = 3,200 and it was not run through the
engine**, because all four targets returned at 1,600 and R1's refutation branch — "still
absent at 3,200" — could no longer fire. The n = 3,200,000 corpus was built and used for
§6a's posting inventory instead, which is the measurement that rung was there to enable.

### 4a. Recall

**Proposed and above floors** — membership of `similar(left, min_retention=0.30,
min_common=6, level="carriers", anchor="conclusion")`, which is score-free and therefore not
touched by anything the padding perturbs.

| `max_len` | T1 `Hₛ_nonneg` | T2 `Hₛ_constant_eq_zero` | T3 `H₁_nonneg` | T4 `Hₛ_le_log_d` | total |
|---:|---|---|---|---|---:|
| 95 (shipped) | no (16 cands) | no (4) | no (56) | no (90) | **0 / 4** |
| 95 (NC-pad) | no (16) | no (4) | no (56) | no (90) | **0 / 4** |
| 200 | no (16) | no (104) | no (104) | no (90) | **0 / 4** |
| 400 | **rank 17** (212) | no (4) | **rank 80** (284) | **rank 1** (310) | **3 / 4** |
| 800 | **rank 16** (625) | no (438) | **rank 86** (697) | **rank 1** (845) | **3 / 4** |
| 1,600 | **rank 16** (625) | **rank 15** (1,930) | **rank 85** (697) | **rank 1** (845) | **4 / 4** |

`(cands)` is the size of the query's whole candidate set; `rank` is the true partner's
position in `similar`'s ranked output over the whole corpus, not inside the target theory.

**And in the shipped `dictionary`**, `ClassicalInfo ~ Entropy`, conclusion anchor,
`theorems_only`:

| `max_len` | rows (`per_decl=1`) | rows (`per_decl=10`) | pre-registered rows returned |
|---:|---:|---:|---|
| 95 | 6 | 12 | — |
| 200 | 6 | 16 | — |
| 400 | 16 | — | T1, T3, T4 |
| 800 | 19 | 42 | T1, T3, T4 |
| **1,600** | **24** | **59** | **T1, T2, T3, T4** |

**R1 holds, and it holds on the surface a caller actually calls.** All four correspondences
that the prior report found by exhaustive anti-unification and could not get out of the
engine come back through `Corpus.dictionary` with **one constant changed**. Not the scorer,
not the floors, not the anchor, not the erasure, not the anti-unifier.

The order they return in is the order §5c predicts from their keys. `Hₛ_le_log_d ~
Sᵥₙ_le_log_d` arrives first and at **rank 1**, because it shares the comparatively rare
`((·:ℕ):ℝ)` cast as well as the universal `≤`. `Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero`
arrives last, at 1,600, because its *only* shared key is `a(c(2:Eq,1,*),c(4:Real,0))` — "an
equation between reals" — and nothing in the corpus is more common than that.

### 4b. Cost

Over a fixed sample of 40 physics theorems, seed 20260804, the same sample at every rung.

| `max_len` | candidates: median | p90 | max | at/over the 600 budget | `similar` median | root index build | peak RSS | rung wall |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 95 | 126.5 | 420 | 649 | 2 / 40 | 8.3 ms | 104.1 s | 7.39 GB | 323 s |
| 200 | 308 | 665 | 720 | 11 / 40 | 17.5 ms | 123.4 s | 7.56 GB | 377 s |
| 400 | 597 | 702 | 846 | 20 / 40 | 22.4 ms | 122.2 s | 7.88 GB | 372 s |
| 800 | 635 | 745 | 904 | 26 / 40 | 37.9 ms | 108.2 s | 8.51 GB | 360 s |
| 1,600 | 700.5 | 1,449 | 1,585 | **37 / 40** | 36.9 ms | 140.1 s | 9.74 GB | 459 s |

Four of four rows cost **4.4× the query latency (8.3 → 36.9 ms), 5.5× the median candidate
set, 35% more index build time and 32% more resident memory.** The build and memory figures
include the padding rows themselves, so they overstate what the knob costs on its own; the
latency and candidate figures do not, because a padding row is nobody's candidate.

**The budget is what actually binds.** At the shipped cutoff two queries in forty reach 600
candidates; at 1,600 it is thirty-seven. `candidates` walks keys rarest first and stops
taking keys once 600 candidates are held, so a newly admitted *common* key is walked last and
is reached only while the budget has room. **R4's warning arrives on schedule: past ~400 the
cutoff is no longer the binding constraint, `candidate_budget` is**, and raising the cutoff
alone from there mostly buys p90 (702 → 1,449) rather than recall.

### 4c. Precision — the control that already misbehaved

| dictionary, conclusion anchor, `per_decl=1` | 95 | 200 | 400 | 800 | 1,600 |
|---|---:|---:|---:|---:|---:|
| `ClassicalInfo ~ Entropy` — the question | 6 | 6 | 16 | 19 | **24** |
| `ClassicalInfo ~ States` | 18 | 19 | 24 | 30 | 34 |
| `ClassicalMechanics ~ QuantumMechanics` — the real negative | 62 | 64 | 73 | 76 | 85 |
| **NC3** `ClassicalMechanics ~ Meta` — physics vs an HTML note utility | **35** | **35** | **35** | **35** | **36** |
| **NC3** `Thermodynamics ~ Meta` | **7** | **7** | **7** | **7** | **7** |

**The nonsense dictionaries barely move.** `ClassicalMechanics ~ Meta` — physics against the
library's HTML-note utility, the pair that outscored the real dictionary at the shipped
cutoff — gains **one row across a 16.8× change in the cutoff**, and `Thermodynamics ~ Meta`
gains none. Over the same range the real dictionary quadruples and picks up four
pre-registered correspondences.

That is a sharper answer to R3 than expected, and the *why* is measured rather than argued.
Taking the four top rows of `ClassicalMechanics ~ Meta` and asking the engine which source
proposed each:

| row | `skeleton(shape)` equal? | sources |
|---|---|---|
| `VisViva.mk.sizeOf_spec ~ HTMLNote.mk.sizeOf_spec` | **yes** | `shape` + `shape-subterm` |
| `VisViva.mk.inj ~ HTMLNote.mk.inj` | **yes** | `shape` + `shape-subterm` |
| `VisViva.mk.injEq ~ HTMLNote.mk.injEq` | **yes** | `shape` + `shape-subterm` |
| `VisViva.ConfigurationSpace.mk.sizeOf_spec ~ PseudoInfo.mk.sizeOf_spec` | **yes** | `shape` + `shape-subterm` |
| `Hₛ_nonneg ~ Sᵥₙ_nonneg` | no | *not a candidate at all* |
| `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` | no | *not a candidate at all* |

Every nonsense row is a pair of **structural twins** — identical `Shape` erasure — retrieved
through source A, the whole-statement shape bucket, which the posting cutoff does not touch.
So the cutoff widens the source that carries *partial* overlap and leaves the one that carries
boilerplate where it was. The correspondences the study is about are in the complementary
position: not shape-equal, and at the shipped cutoff not candidates at all.

Not free, though: `ClassicalMechanics ~ QuantumMechanics`, the pre-registered *real* negative,
grows 62 → 85, and every one of those is noise by construction — the mechanics correspondence
is not in the statements at any setting. So the knob does add rows to a pair that has nothing
to find; it just adds them at the same rate as everything else rather than faster.

### 4d. What the top of the dictionary looks like at each end

`ClassicalInfo ~ Entropy`, conclusion anchor, `per_decl=1`, by retention.

At the shipped cutoff, the whole dictionary:

```
0.571  Prob.negLog_ne_top        ~ qRelativeEnt_ne_top
0.476  Prob.negLog_zero          ~ qRelativeEnt_ne_top
0.435  Prob.le_negLog_of_le_exp  ~ qRelativeEnt_op_le
0.412  Prob.negLog_one           ~ qRelEntropy_self
0.311  Prob.negLog_Antitone      ~ qRelativeEnt.lowerSemicontinuous
0.304  Prob.negLog_eq_top_iff    ~ sandwichedRelEntropy_ne_top
```

Six rows, all of one family: an `ℝ≥0∞`-valued information quantity is finite, or vanishes at
its trivial argument. The prior report hand-scored this exact family and gave it **zero A
grades** — a family resemblance between surprisal and relative entropy, not one of E16–E19.

At `max_len` = 1,600, the top of the same query:

```
0.824  Hₛ_nonneg             ~ Sᵥₙ_nonneg               <- E16, pre-registered
0.739  Hₛ_constant_eq_zero   ~ Sᵥₙ_of_pure_zero         <- E16/E20, pre-registered
0.697  Hₛ_le_log_d           ~ Sᵥₙ_le_log_d             <- E16, pre-registered
0.629  Hₛ_uniform            ~ Sᵥₙ_le_log_d             <- E16 (uniform ⇒ max), pre-registered
0.588  H₁_nonneg             ~ Sᵥₙ_nonneg               <- E16, pre-registered
0.571  Prob.negLog_ne_top    ~ qRelativeEnt_ne_top
0.476  Prob.negLog_zero      ~ qRelativeEnt_ne_top
```

**The first five rows are the pre-registered correspondences**, in the order the exhaustive
ablation put them in, and the sixth is where the shipped dictionary used to start.
`Hₛ_uniform ~ Sᵥₙ_le_log_d` is a fifth row the prior report's exhaustive list also carried at
0.629 and is not one of the four this study counts; it returns too.

The unchanged `ClassicalMechanics ~ Meta` rows, at both 95 and 1,600, are the reason §4c's
precision result holds:

```
0.894  ClassicalMechanics.VisViva.mk.sizeOf_spec ~ Physlib.HTMLNote.mk.sizeOf_spec
0.889  ClassicalMechanics.VisViva.mk.inj         ~ Physlib.HTMLNote.mk.inj
0.882  ClassicalMechanics.VisViva.mk.injEq       ~ Physlib.HTMLNote.mk.injEq
```

Constructor injectivity and size lemmas, and §4c's table measures what carries them: identical
`Shape` erasure, retrieved through source A. That is why the nonsense dictionary gains one row
across a 16.8× change in a knob that only touches sources B and C.

### 4e. Transfer: the same query on the 495,067-declaration import closure

The full physlib import closure finished extracting during this run —
`/tmp/fh-physlib-closure.jsonl`, 5.4 GB, **495,067 declarations**: Mathlib 348,222, Lean
48,089, Init 39,590, Std 33,837, Physlib 12,031, QuantumInfo 2,527. It is a genuine closure
and measures **99.5907%**. It is 5.2× the corpus everything above was measured on, so the
shipped `max_posting_fraction` = 0.001 gives `max_len` = **495** — already above the 359 that
§5c measured for T1 and T3's carrying key on the smaller corpus.

Run once, unpadded, at the shipped defaults:

| | 95,268-row corpus | **495,067-row closure** |
|---|---:|---:|
| closure coverage | 0.994553 | **0.995907** |
| `max_len` at the shipped fraction | 95 | **495** |
| **T1–T4 proposed and above floors** | 0 / 4 | **0 / 4** |
| candidates for T1 / T2 / T3 / T4's left | 16 / 4 / 56 / 90 | 53 / 28 / 459 / 332 |
| `ClassicalInfo ~ Entropy` rows | 6 | **1** |
| `ClassicalInfo ~ States` rows | 18 | 17 |
| `ClassicalMechanics ~ QuantumMechanics` rows | 62 | 62 |
| **NC3** `ClassicalMechanics ~ Meta` rows | 35 | **18** |
| **NC3** `Thermodynamics ~ Meta` rows | 7 | **1** |
| candidate set median / p90 / max | 126.5 / 420 / 649 | 603 / 734 / 836 |
| queries at or over the 600 budget | 2 / 40 | 11 / 20 |
| load / root index / wall | 26.7 / 104.1 / 323 s | 73.0 / 284.1 / 824 s |
| peak RSS | 7.39 GB | **19.86 GB** |

**The defect is worse at scale, not better, and this is the prior report's P6 confirmed on a
real corpus rather than by dilution.** `max_len` rose 5.2× and recall stayed at zero, because
the document frequency of `0 ≤ (·:ℝ)` rose faster than 0.1% of the corpus did — the same
mechanism §5c measures across 985 → 3,820 → 95,268, extended one step further. The dictionary
does not merely fail to improve: `ClassicalInfo ~ Entropy` **falls from 6 rows to 1**.

Two more things worth recording. The nonsense dictionaries shrink too — 35 → 18 and 7 → 1 —
so this is a degradation of the whole retrieval layer with corpus size and not a
recall-for-precision trade. And it settles the parameterisation question: a fraction that
works here (§10 recommends the effect of 0.02 on the 95k corpus) would be `max_len` ≈ 9,900
on this one, which is not a cutoff. **The fix cannot be a bigger constant of the same shape**,
which is what §6a's per-source cap, scoped budget and work budget are for.

## 5. Which keys carry the correspondence, and how common they are

This is the instrumentation the dilution experiment said did not exist, and it turns out not
to need a Rust change either: `motifs(source, min_family=2, …)` reads the posting lists key
by key with the family that holds each, so **the index can be read as an inventory**.
Inverting those member lists recovers every declaration's key set — the whole input to
candidate generation.

It has one limit and the script reports it: the inventory can only show keys that survived
*this* corpus's own cutoff. So it is run on padded slices, where `max_len` exceeds the
largest document frequency the slice can have and the inventory is complete.

Two closed sub-corpora, both built by transitive closure under `uses_statement` (a random
subsample of a closed corpus is not closed, and the erasure would degrade with it):

| sub-corpus | seeds | rows | padded to | `max_len` | inventory |
|---|---:|---:|---:|---:|---|
| `closure(ClassicalInfo ∪ Entropy)` | 347 | 985 | 1,000,000 | 1,000 | complete |
| `closure(QuantumInfo.*)` | 2,527 | 3,820 | 1,000,000 | 1,000 | complete |

### 5a. The keys, quoted

All four pairs share keys, and **every shared key comes from source B** — concrete subterms
of the `Presentation` erasure. Not one comes from source C, the `Shape` index, which is the
source the design describes as the one that carries cross-carrier analogy. On the 985-row
corpus, with the rendered key beside its document frequency:

```
Hₛ_nonneg ~ Sᵥₙ_nonneg                    (also H₁_nonneg ~ Sᵥₙ_nonneg)
  df=61  size=7  a(a(a(c(5:LE.le,1,*),c(4:Real,0)),c(11:Real.instLE,0)),n0)
  df=81  size=3  a(c(5:LE.le,1,*),c(4:Real,0))
  df=81  size=5  a(a(c(5:LE.le,1,*),c(4:Real,0)),c(11:Real.instLE,0))

Hₛ_constant_eq_zero ~ Sᵥₙ_of_pure_zero
  df=70  size=3  a(c(2:Eq,1,*),c(4:Real,0))

Hₛ_le_log_d ~ Sᵥₙ_le_log_d
  df=9   size=3  a(c(8:Nat.cast,1,*),c(4:Real,0))
  df=9   size=5  a(a(c(8:Nat.cast,1,*),c(4:Real,0)),c(16:Real.instNatCast,0))
  df=81  size=3  a(c(5:LE.le,1,*),c(4:Real,0))
  df=81  size=5  a(a(c(5:LE.le,1,*),c(4:Real,0)),c(11:Real.instLE,0))
```

Read plainly: **the classical↔quantum information dictionary hangs on `0 ≤ (·:ℝ)`,
`(· = · : ℝ)` and `((·:ℕ) : ℝ)`.** Three to seven nodes each. Nothing larger is shared,
because the two sides are `0 ≤ Hₛ p` over a `ProbDistribution` and `0 ≤ Sᵥₙ ρ` over an
`MState`, and after `Presentation` the only common material is the order and the carrier it
is stated in.

That single fact settles most of the design question before any sweep. A key held by 6–8% of
its corpus is exactly what `max(⌊0.001·n⌋, 50)` exists to delete, and it is the entire
overlap. And the keys are **at the size floor** — `min_concrete_closed` is 3 — so no rule
that admits long lists *when the key is large* can rescue them.

### 5b. Why source C is silent, which is a different defect

The `Shape` erasure of the two sides:

```
Hₛ_nonneg   pd(_,pd(_,pd(a(a(_,b1),_),a(a(a(a(_,_),_),_),a(a(a(_,_),_),b0)))))
Sᵥₙ_nonneg  pd(_,pd(_,pd(_,pd(a(a(a(_,b2),_),_),a(a(a(a(_,_),_),_),a(a(a(a(_,_),_),_),b0))))))
```

They are not equal, so source A (the whole-statement shape bucket) cannot fire — confirmed
directly: `skeleton(L,"shape") != skeleton(R,"shape")` for all four pairs (§4c's table). They
differ because the quantum side carries one more binder (`DecidableEq`) and one more argument
on every applied constant.

**What is measured** is that the inventory contains **zero** shared source-C keys for any of
the four pairs, at any corpus size, while `min_shape_sub` = 8. **What is read off the two
renderings above** — and is an inference, not a measurement — is that the largest shape
structure the two sides do share is the `0 ≤ …` head `a(a(a(a(_,_),_),_), …)`, which as a
standalone subterm is under eight nodes and so cannot become a key.

If that reading is right, the two sources fail on this pair for opposite reasons: source C's
shared structure is below its **size floor**, and source B's is above its **length cutoff**.
The distinction matters because raising the cutoff cannot fix the first. `min_shape_sub` is a
build-time floor and is not reachable from the binding either, so **whether lowering it to 6
or 7 would create the key is stated here as untested, not as a result** — S5 is the test.

### 5c. Document frequency grows with the corpus, sublinearly

Minimum document frequency of a shared key, per pair, measured on three closed corpora — the
full one included, padded to n = 3,200,000 so its inventory reaches df 3,200:

| corpus | rows | T1 | T2 | T3 | T4 |
|---|---:|---:|---:|---:|---:|
| `closure(ClassicalInfo ∪ Entropy)` | 985 | 61 | 70 | 61 | 9 |
| `closure(QuantumInfo.*)` | 3,820 | 149 | 243 | 149 | 25 |
| **the corpus** | **95,268** | **359** | **1,761** | **359** | **243** |
| as a fraction of the corpus | | 0.38% | **1.85%** | 0.38% | 0.26% |

The keys at n = 95,268, quoted:

```
T1, T3   df=359    a(a(a(c(5:LE.le,1,*),c(4:Real,0)),c(11:Real.instLE,0)),n0)   "0 ≤ (·:ℝ)"
T2       df=1,761  a(c(2:Eq,1,*),c(4:Real,0))                                   "(· = · : ℝ)"
T4       df=243    a(c(8:Nat.cast,1,*),c(4:Real,0))                             "((·:ℕ):ℝ)"
```

The shipped cutoff on this corpus is **95**. To admit T1 and T3 it must be 359 —
`max_posting_fraction` = 0.0038. To admit T2 it must be 1,761 — **0.0185, eighteen times the
shipped 0.001**.

**These numbers predict §4's ladder and are confirmed by it.** Ordered by their carrying
key's frequency the pairs should return T4 (243), then T1 and T3 (359), then T2 (1,761); the
engine returns T4, T1 and T3 at `max_len` = 400 and T2 at 1,600. The ordinal prediction is
exact and the magnitudes bracket correctly. Two instruments, one built from `motifs` and one
from `dictionary`, agreeing on a threshold neither was fitted to.

**And the fraction falls while the count rises**, which is why the shipped rule gets *tighter*
as a corpus grows: T1's key is held by 6.2% of a 985-declaration corpus and 0.38% of a
95,268-declaration one, but 95 does not admit 359. On the 347-row two-theory slice the prior
report found 3 of 4 targets at `max_len` = 50; the same rule on the same statements, in a
corpus 274 times larger, finds none.

### 5d. One fidelity caveat, and it is load-bearing

`Corpus.motifs` reads `skeletons()`, which is `skeletons_at(Anchor::Root, false)` — there is
no anchor parameter. So **every document frequency in §5 and §6 is root-anchored, while every
recall number in §4 is conclusion-anchored**, because that is the anchor cross-theory analogy
needs.

The two are not interchangeable and the direction of the difference is known: the
conclusion-anchored index keys on `arena.conclusion(t)`, so a key occurring only in a
hypothesis is counted at the root and not at the conclusion. **Root-anchored df is therefore
an upper bound on conclusion-anchored df**, and every threshold in §5c is an upper bound on
the cutoff the shipped conclusion-anchored query actually needs. That is consistent with the
one place the two instruments differ: T2's root df is 1,761 and the engine returned it at
`max_len` = 1,600.

§6's comparison *between rules* is internally consistent — one index, one anchor, one budget —
and is the right shape of evidence for a design choice. It is not a prediction of the exact
row count a conclusion-anchored dictionary would return, and is not offered as one. Making it
one needs `motifs` to take an anchor, which is S3.

## 6. Four admission rules, scored on the same numerator

`SkeletonIndex::candidates` is short enough to reproduce exactly — walk the query's keys
rarest first, stop adding keys once the budget is held — and §5 recovered its whole input.
So an admission rule can be scored offline against the same four correspondences and the
same cost axes, with no Rust change and no engine rebuild. `scripts/phys-prefilter.py
admission` is that simulation; the walk mirrors the Rust line for line, including that the
budget is checked *at the top* of each key, so one long list may overshoot it.

On `closure(QuantumInfo.*)` — 3,820 declarations, inventory complete, budget 600:

| admission rule | keys | postings | T1–T4 | candidates, median | postings visited, median |
|---|---:|---:|---:|---:|---:|
| length ≤ 50 (the shipped floor) | 34,340 | 138,949 | **1 / 4** | 71 | 300 |
| length ≤ 95 (the shipped fraction here) | 34,606 | 157,397 | **1 / 4** | 144.5 | 705.5 |
| length ≤ 200 | 34,726 | 173,711 | 3 / 4 | 224.5 | 766.5 |
| length ≤ 400 | 34,755 | 181,597 | **4 / 4** | 469.5 | 1,052.5 |
| length ≤ 800 … no cutoff | 34,756 | 182,286 | **4 / 4** | 625 | 1,509 |
| length ≤ 95 **or size ≥ 16** | 34,643 | 162,862 | 1 / 4 | 156.5 | 705.5 |
| length ≤ 95 **or size ≥ 32** | 34,613 | 158,395 | 1 / 4 | 144.5 | 705.5 |
| length ≤ 95 **or size ≥ 64** | 34,607 | 157,525 | 1 / 4 | 144.5 | 705.5 |
| subterm ≤ 95, shape ≤ 3,200 | 34,628 | 161,896 | 1 / 4 | 517 | 1,277.5 |
| **subterm ≤ 3,200, shape ≤ 95** | 34,734 | 177,787 | **4 / 4** | 333.5 | 873.5 |

And with no cutoff at all, bounding query work directly instead:

| keep every key, stop after W postings visited | T1–T4 | candidates, median | p90 |
|---|---:|---:|---:|
| W = 2,000 | **4 / 4** | 396 | 775 |
| W = 10,000 | **4 / 4** | 691.5 | 1,129 |
| W = 50,000 | **4 / 4** | 691.5 | 1,163 |
| W = 250,000 | **4 / 4** | 691.5 | 1,163 |

Four things are measured here.

**Dropping the cutoff entirely costs 0.43% of the keys and 15.8% of the postings.** 34,606 →
34,756 keys, 157,397 → 182,286 postings. That is the whole price of the recall, on the index
side, and it is small because the deleted keys are few — they are just enormously
load-bearing. The engine's own comment says a long list is "dropped, not down-weighted:
down-weighting still pays the cost of walking it". The cost of *holding* it is 15.8%; the
cost of *walking* it is what a budget already bounds.

**Size-conditioned admission does not work, and the measurement says why rather than that.**
`length ≤ 95 or size ≥ S` recovers nothing at S = 16, 32 or 64, because the carrying keys are
3, 5 and 7 nodes. Informativeness is not size. This was the most plausible of the alternatives
on paper and it is refuted on the first corpus that has ground truth.

**A per-source cap is the cheapest rule that works.** Raising only source B to 3,200 and
leaving source C at 95 gets 4 / 4 at 177,787 postings and a median candidate set of 333.5 —
against 182,286 and 625 for a flat no-cutoff. Half the candidate inflation for the same
recall. The reason is §5a: every shared key is source B, and source C's long lists are
`Shape` fragments that buy candidates without buying these rows.

**The work budget dominates the length cutoff on both axes.** W = 2,000 postings visited,
with *every* key kept, returns 4 / 4 at a median candidate set of 396 — fewer candidates than
the flat no-cutoff (625) and fewer than `length ≤ 400` (469.5), which is the weakest cutoff
that also reaches 4 / 4. A budget over the quantity actually being spent beats a proxy for it,
which is unsurprising once stated and was not measurable before.

**The constant W = 2,000 is not a recommendation.** It is fitted on a 3,820-declaration
corpus, and §5c's growth curve is exactly the reason to distrust a constant fitted at one
scale. What transfers is the *shape* of the rule; §10 says which measurement fixes the
constant.

### 6a. The same comparison at full scale, where the budget takes over

The corpus, padded to n = 3,200,000 so the inventory reaches df 3,200. Root-anchored (§5d);
budget 600, as shipped. The index holds **1,348,906 keys** with family ≥ 2 — 1,026,027 from
source B and 322,879 from source C — over **7,998,407 postings**, and 92,671 of the 95,268
declarations hold at least one key.

| admission rule | keys | postings | T1–T4 | candidates: median | p90 |
|---|---:|---:|---:|---:|---:|
| length ≤ 50 | 1,334,693 | 5,775,960 | **0 / 4** | 101.5 | 246 |
| **length ≤ 95 (shipped)** | 1,342,540 | 6,305,451 | **0 / 4** | 168 | 514 |
| length ≤ 200 | 1,346,413 | 6,832,774 | 0 / 4 | 384 | 609 |
| length ≤ 400 | 1,347,969 | 7,265,480 | 3 / 4 | 605.5 | 713 |
| length ≤ 800 | 1,348,637 | 7,629,554 | 3 / 4 | 618 | 776 |
| length ≤ 1,600 | 1,348,837 | 7,844,867 | 3 / 4 | 638.5 | 806 |
| **length ≤ 3,200 = no cutoff** | 1,348,906 | 7,998,407 | **3 / 4** | 662.5 | 976 |
| length ≤ 95 or size ≥ 16 | 1,344,027 | 6,605,613 | 0 / 4 | 326.5 | 688 |
| length ≤ 95 or size ≥ 32 | 1,343,048 | 6,393,567 | 0 / 4 | 184.5 | 554 |
| length ≤ 95 or size ≥ 64 | 1,342,747 | 6,338,171 | 0 / 4 | 176.5 | 514 |
| source B ≤ 95, source C ≤ 3,200 | 1,344,010 | 6,738,078 | 0 / 4 | 614.5 | 1,434 |
| **source B ≤ 3,200, source C ≤ 95** | 1,347,436 | 7,565,780 | **4 / 4** | 654 | 1,077 |

| keep every key, stop after W postings walked | T1–T4 | candidates: median | p90 |
|---|---:|---:|---:|
| W = 2,000 | **4 / 4** | 475 | 1,769 |
| W = 10,000 | **4 / 4** | 1,834.5 | 5,772 |
| W = 50,000 | **4 / 4** | 4,002 | 8,706 |

| cutoff, with the 600 slots counted over… | corpus-wide | only the right theory |
|---|---:|---:|
| 95 | 0 / 4 | 0 / 4 |
| 400 | 3 / 4 | 3 / 4 |
| 1,600 | 3 / 4 | 3 / 4 |
| no cutoff | **3 / 4** | **4 / 4** |

**Removing the cutoff entirely costs 0.47% of the keys and 26.9% of the postings** —
6,305,451 → 7,998,407 — and 6,366 more keys. That is the whole index-side price, measured at
the scale the engine actually runs at.

**And at full scale a flat length cutoff cannot reach 4 / 4 at all.** Every rung from 400 to
"no cutoff" gives three. The reason is R4's interaction arriving in its strongest form: with
all keys admitted, `Hₛ_constant_eq_zero`'s walk fills 600 candidate slots on rarer keys before
it reaches `(· = · : ℝ)` at df 1,761. **The cutoff stops being the binding constraint and
`candidate_budget` takes over.**

Three different changes each get past it, and none of them is a bigger cutoff:

* **a per-source cap** — source B open, source C left at 95 — reaches 4 / 4 at 7,565,780
  postings, *fewer* than no-cutoff and with a lower p90 than either mixed rule. Source C's
  long lists spend budget without buying these rows, because every shared key is source B
  (§5a);
* **scoping the budget** to the right theory reaches 4 / 4 with no cutoff at all, which is the
  measurement behind S2: the 600 slots are spent corpus-wide on a query restricted to 181
  declarations;
* **a work budget** reaches 4 / 4 at every W from 2,000, at a median candidate set of 475 —
  lower than `length ≤ 400`'s 605.5, which only reaches three.

**Size-conditioned admission fails at every scale**, on both sub-corpora and here. The keys are
3, 5 and 7 nodes; informativeness is not size.

## 7. The matched-N control: same cutoff, different document frequency

R2's arm, and the one that could have refuted the whole reading. Two corpora at **n =
200,000** — hence the same `max_len` = 200, the same `idf` normalisation, the same
`derivativeness` rank space — differing only in how many of the rows are real declarations
competing for the same keys.

| | low-df arm | high-df arm |
|---|---:|---:|
| real declarations | **985** (`closure(ClassicalInfo ∪ Entropy)`) | **95,268** (the whole corpus) |
| keyless padding | 199,015 | 104,732 |
| n | 200,000 | 200,000 |
| `max_len` | **200** | **200** |
| closure coverage | 0.992941 | 0.994553 |
| `generalize` T1–T4 | 0.8889 / 0.8182 / 0.7407 / 0.6970 | identical |
| **T1–T4 proposed and above floors** | **4 / 4**, at ranks 1, 1, 2, 1 | **0 / 4** |
| `ClassicalInfo ~ Entropy` rows | 29, containing all four | 6, containing none |
| candidate set, median / max | 106.5 / 161 | 308 / 720 |
| queries at or over the 600 budget | **0 / 40** | 11 / 40 |
| peak RSS | 0.39 GB | 7.57 GB |

**Four out of four against zero out of four, at the same cutoff.** The two arms hold the same
four statements, encode them identically (`generalize` agrees to four decimals), and run the
same engine at the same `max_len`. The only thing that differs is how many other declarations
hold `0 ≤ (·:ℝ)`.

So the mechanism is not "a bigger corpus is harder" in any general sense, and it is not any of
the things `n` does besides set the cutoff — those are held fixed here by construction. It is
**document frequency measured against a corpus-wide cutoff, while the query is restricted to
one 181-declaration theory**. The engine deletes `(· = · : ℝ)` because 1,761 declarations
hold it (§5c), and then answers a question in which all but a handful of those 1,761 could
never have been a candidate.

That is the argument for S2 as much as for S1: the *fraction* is not wrong, the **scope** is.

## 8. What the prefilter-free path costs, and whether two tiers are affordable

The wild question: is a prefilter the wrong architecture for cross-theory work at all?
Physics corpora are small — 9,480 theorems across 26 theories in this one — and the answer
turns on a throughput number nobody had measured on a closed physics corpus.

**Exhaustive within the pair that matters.** Every `ClassicalInfo` theorem against every
`Entropy` theorem, `generalize` at the conclusion anchor, engine floors (`common ≥ 6`,
`retention ≥ 0.30`):

| | measured |
|---|---:|
| pairs | 15,655 |
| seconds | 45.2 |
| pairs per second | **346** |
| rows above floors | **273** |
| pre-registered rows found | **4 / 4** |

The top of that list is `Hₛ_nonneg ~ Sᵥₙ_nonneg` 0.889, `Hₛ_constant_eq_zero ~
Sᵥₙ_of_pure_zero` 0.818, `H₁_nonneg ~ Sᵥₙ_nonneg` 0.741, `Hₛ_le_log_d ~ Sᵥₙ_le_log_d` 0.697
— which reproduces `physlib-classical-quantum.md` §7 exactly, on the closed corpus, with an
independently written script. 273 rows against the shipped dictionary's 6.

**346 pairs per second is a fact about the binding, not about the engine.** The same
measurement run against `similar_brute` — which is the identical comparison done inside Rust,
one anti-unification per declaration in the slice — gives a **median 0.11 s per query over
95,268 declarations**, i.e. about **866,000 anti-unifications per second**. (Mean 1.06 s,
90,000/s; the distribution is long-tailed because physics statements are.) The prior report
measured 218,348 `generalize` pairs in 59.9 s on the closed arm, 3,645/s, against this run's
346/s on the same corpus — a tenfold disagreement between two Python loops that this study
cannot resolve and does not paper over. The Rust-side figure is the one that matters for a
design decision, and it is three orders of magnitude larger than either.

**So the two-tier design is affordable, and by a wide margin.**

| | measured or derived |
|---|---:|
| physics theorems (26 theories) | 9,480 |
| ordered cross-theory pairs among them | 81,582,112 |
| at 346 pairs/s (this script, through the binding) | 235,582 s ≈ 65 h |
| at 866,000/s (`similar_brute`'s measured rate, in Rust) | **94 s** |
| at 90,000/s (`similar_brute`'s mean rate) | 908 s |
| `similar_brute` once per physics theorem, whole corpus | 9,480 × 0.11 s ≈ **17 min** |

Exhausting every cross-theory pair inside physics is a minute and a half to fifteen minutes
of one core. That is not a research budget, it is a build step.

**But it is not the recommendation, and the reason is in the prior report's own control.**
Removing the prefilter buys recall *and* artifacts: the pre-registered nonsense pairs had a
**higher** above-floor density than the real one (5.15% against 1.74%) and 25 of 25 top rows
were constructor-injectivity lemmas. §4c shows raising the cutoff does not do that — the
nonsense dictionary gained one row in a 16.8× sweep — because the boilerplate arrives through
source A, which the cutoff never touched. **Raising the cutoff is a strictly better trade
than removing the prefilter**, and it is available now.

Where exhaustive belongs is as a *floor* under the prefilter for small scopes: when
`|left| × |right|` is under a bound, skip retrieval entirely, and score the rows through
`Row::score` rather than by retention so the derivativeness penalty is applied. That is
`physlib-classical-quantum.md` §12's S1, and this study's contribution to it is the
throughput number that says the bound can be set at tens of millions of pairs rather than
the 250,000 that spec guessed.

## 9. Verdicts against the pre-registration

| | verdict |
|---|---|
| **R1** — at least one of T1–T4 proposed where none was | **PASS, all four.** 0 / 4 at the shipped cutoff of 95; 3 / 4 at 400; **4 / 4 at 1,600**, and all four appear in `Corpus.dictionary("ClassicalInfo","Entropy", anchor="conclusion")` as its **top five rows**. One constant changed; scorer, floors, anchor, erasure and anti-unifier untouched. |
| **R2** — the matched-N control | **PASS, in the confirming direction.** At n = 200,000 and `max_len` = 200 in both arms: 985 real declarations give **4 / 4** at ranks 1, 1, 2, 1; 95,268 real declarations give **0 / 4**. Same cutoff, same `idf` normalisation, same `derivativeness` rank space, identical `generalize` retentions. The mechanism is document frequency against a corpus-wide cutoff and nothing else `n` does. |
| **R3** — precision | **PASS, and better than expected.** Across a 16.8× sweep the two pre-registered nonsense dictionaries move from 35 → 36 and 7 → 7 rows, while `ClassicalInfo ~ Entropy` goes 6 → 24 and its top five become the pre-registered correspondences. The reason is mechanical: the nonsense rows are `mk.inj` / `sizeOf_spec` structural twins retrieved by source A, which the posting cutoff never touched. **Bounded**, though: `ClassicalMechanics ~ QuantumMechanics` — the pre-registered *real* negative — grows 62 → 85, and every one of those is noise. |
| **R4** — cost | **Reported, and the interaction fired.** 8.3 → 36.9 ms median `similar`; 126.5 → 700.5 median candidates; p90 420 → 1,449; index build +35%; peak RSS +32% (padding included, so an overstatement). Queries at or over the 600 budget: **2 / 40 → 37 / 40**. Past `max_len` ≈ 400 the cutoff stops being the binding constraint and `candidate_budget` becomes it — which the full-scale simulation confirms by reaching only 3 / 4 even with *every* key admitted. |
| **R5** — is a length cutoff the right shape | **No, measured three ways.** Size-conditioned admission recovers nothing at any scale (the keys are 3–7 nodes). A per-source cap reaches 4 / 4 at **fewer** postings than a flat no-cutoff. A work budget reaches 4 / 4 at a *lower* median candidate set than the weakest length cutoff that reaches three. And a flat cutoff cannot reach 4 / 4 at full scale at all. |
| **R6** — the wild question | **Exhaustive is affordable and is still not the answer.** All 81,582,112 ordered cross-theory pairs inside physics cost 94 s at `similar_brute`'s measured Rust rate (866k anti-unifications/s), 908 s at its mean rate, 17 min as one `similar_brute` per physics theorem. But the prior report's own control shows removing the prefilter buys artifacts at a *higher* rate than rows, and §4c shows raising the cutoff does not. Exhaustive belongs as a floor for small scopes, not as the architecture. |
| **NC-pad** — the instrument | **PASS.** Padding the base by 100 rows leaves `max_len` at 95, and every number is identical: coverage to sixteen digits, all four `generalize` retentions, all four candidate counts, all five dictionaries row for row. |
| **NC2** — erasure liveness | **PASS at every rung.** 7 / 7 of the sampled declarations have `carriers` ≠ `presentation`. |
| **closure** | **PASS at every rung.** 0.9945527209261904 on every padded corpus; 0.992941 on the matched control's 985-row closed sub-corpus; 0.995907 on the 495,067-row import closure. |
| **transfer** (not pre-registered; the closure finished mid-run) | **The defect is worse at scale.** On the 495,067-declaration full import closure the shipped fraction gives `max_len` = 495 — five times the value that leaves recall at zero on the smaller corpus — and recall is still **0 / 4**, while `ClassicalInfo ~ Entropy` falls from 6 rows to 1 and both nonsense dictionaries shrink as well. Document frequency outruns 0.1% of the corpus. |

## 10. Specification for the engine

Specs, not implementations. Each names the defect, the measurement that demonstrates it, and
the gate that must ship with it. Ordered by measured payoff.

### S1. The admission rule is the wrong *shape*, not the wrong constant

**Defect.** `Postings::build` drops a key held by more than `max(⌊n·max_posting_fraction⌋,
min_posting_len)` declarations. The rule is a count of holders; the property it is proxying
for is informativeness. On the one corpus where the right answer is known, the two come
apart completely: the keys that carry all four correspondences are `0 ≤ (·:ℝ)`,
`(· = · : ℝ)` and `((·:ℕ):ℝ)` — three to seven nodes, held by 0.26–1.85% of the 95,268-row
corpus and 0.9–7.1% of a 985-row one — and a rule that deletes the top 0.1% by holder count
deletes exactly those.

**Measured** (§6a, the corpus, 95,268 declarations, root-anchored, budget 600):

| rule | postings | T1–T4 | candidates, median / p90 |
|---|---:|---:|---:|
| `length ≤ 95` (shipped) | 6,305,451 | 0 / 4 | 168 / 514 |
| `length ≤ 95 or size ≥ 32` | 6,393,567 | 0 / 4 | 184.5 / 554 |
| no cutoff | 7,998,407 | 3 / 4 | 662.5 / 976 |
| **source B open, source C ≤ 95** | 7,565,780 | **4 / 4** | 654 / 1,077 |
| **no cutoff, stop after 2,000 postings walked** | 7,998,407 | **4 / 4** | 475 / 1,769 |
| no cutoff, 600 slots counted **in the right theory** | 7,998,407 | **4 / 4** | — |

**Spec.**

```rust
pub enum Admission {
    /// Today, bit for bit. Every existing result is at this policy.
    Length { fraction: f32, floor: usize },
    /// Independently per source. The measurement says the two sources want different
    /// answers: every shared key of a cross-theory pair is source B, and source C's long
    /// lists buy candidates without buying rows.
    PerSource { concrete: Box<Admission>, shape: Box<Admission> },
    /// Keep every key. The index grows by the postings the cutoff was deleting — measured
    /// at +26.9% on the 95,268-row corpus and +15.8% on a 3,820-row one, for +0.47% and
    /// +0.43% more *keys* — and the query is bounded by `work_budget` instead.
    KeepAll,
}

pub struct IndexConfig {
    pub admission: Admission,      // default: Length { 0.001, 50 } — unchanged
    /// Postings walked before `candidates` stops taking keys, alongside the existing
    /// `candidate_budget`. The rarest-first walk already orders keys correctly; this
    /// bounds the quantity actually being spent instead of a proxy for it.
    pub work_budget: usize,
    ...
}
```

`candidates` gains `visited += postings.len()` and breaks on either budget. The check stays
at the *top* of a key, so one long list may overshoot — that is today's behaviour for
`candidate_budget` and changing it is a separate decision.

**The recommended default, and the measurement that justifies it.**

```rust
admission: Admission::PerSource {
    concrete: Box::new(Admission::KeepAll),
    shape:    Box::new(Admission::Length { fraction: 0.001, floor: 50 }),
},
work_budget: <fitted, see below>,
candidate_budget: 2_000,      // was 600
```

Three separable claims, each with the number that carries it.

1. **Source B keeps everything.** At full scale that rule is the only length-style rule that
   reaches 4 / 4, and it does so at **7,565,780 postings against 7,998,407** for a flat
   no-cutoff and a p90 candidate set of 1,077 against 1,434 for the mirror rule. Every shared
   key of every one of the four correspondences is source B (§5a), and source C's long lists
   spend budget without buying rows.
2. **Source C keeps today's rule**, because nothing measured here asks it to change and
   §5b says its problem is a size *floor*, not a length cutoff. Changing both at once would
   make the next measurement unattributable.
3. **`candidate_budget` rises to 2,000.** This is forced, not optional: at `max_len` = 1,600
   the engine's own candidate sets ran median 700.5, p90 1,449, max 1,585 with **37 of 40
   queries at or over 600**, and the full-scale simulation reaches only 3 / 4 with every key
   admitted *because* the budget fills first. 2,000 covers the measured maximum on this
   corpus with margin; it is a constant fitted on one corpus and is flagged as one.

**`work_budget` is deliberately left unfitted.** W = 2,000 postings reaches 4 / 4 on both the
3,820-declaration corpus and the 95,268-declaration one, which is suggestive and is not a fit
— two points, one of them censored at df 3,200. §5c is the standing warning: `min_retention =
0.30`, `max_posting_fraction = 0.001` and `min_posting_len = 50` were all fitted on the 131k
algebra slice and none of the three transfers. The fitting protocol is the paired one from
`physlib-census.md` §10.4 — sweep W on **two** corpora of different statement scale, the
algebra slice and the physics-closed slice, and take the smallest value at which
`phys-census.py reachability`'s *reachable-and-not-retrieved* cell stops falling **while the
shares-no-key cell stays fixed**. The second half is what distinguishes "the budget was the
binder" from "something moved".

**What this does not fix, and the honest bound on it.** Across the same 95 → 1,600 sweep,
`ClassicalMechanics ~ QuantumMechanics` grows **62 → 85** and every one of those 23 rows is
noise, because that correspondence is not in the statements at any setting (§2d). The two
pre-registered nonsense pairs together grow **42 → 43**. `ClassicalInfo ~ Entropy` grows
**6 → 24** and its top five become the pre-registered correspondences. So the knob buys the
rows that exist and pays for them in rows that do not, at a rate that differs sharply by pair
— which is the trade CLAUDE.md §3 says to take, stated with its price so that it is taken
knowingly rather than by default.

**Gate, paired, and it must be able to fail in both directions.** On a physlib slice:
`KeepAll` returns `Hₛ_nonneg ~ Sᵥₙ_nonneg` **and** `Length { 0.001, 50 }` does not. A test
that only asserts the first passes when the cutoff is removed *and* when the ranking is
broken; the second half is what makes it a measurement. Add the negative-control pair —
`ClassicalMechanics ~ Meta` must not gain rows faster than `ClassicalInfo ~ Entropy` — since
narrowing and widening both manufacture errors and only one of them is visible in a recall
number.

### S2. The cutoff and the budget are corpus-global; the query is not

**Defect.** `similar` calls `candidates` and *then* applies `restrict_prefix`. So a
theory-restricted dictionary spends its 600 candidate slots over all 95,268 declarations and
filters afterwards, and `max_len` counts holders over the whole corpus even when the
retrieval scope is one 181-declaration theory. `IndexConfig::restrict_prefix`'s own comment
says the filter is "applied inside retrieval rather than after it" — it is applied inside
`similar`, which is after candidate generation, and that is the step where the loss happens.

The prior report reached the same conclusion from the dilution direction and stated it as a
requirement: *`max_len` must be computed over the retrieval scope, not over the corpus*. This
study adds that `candidate_budget` has the same problem, and that the two are separable.

**Spec.** `candidates` takes the restriction and applies it to each posting list as it walks,
so both budgets count only candidates that can become rows. Where the restriction is known at
build time, `Postings::build` should additionally admit a key whose *in-scope* document
frequency is under the cutoff even when its corpus-wide frequency is not — which is a
per-scope index and therefore a bigger change, and is why the query-time half is specified
first.

### S3. The build-time knobs must be reachable from the binding

**Defect.** `min_posting_len`, `max_posting_fraction`, `candidate_budget`, `max_bucket` and
`min_shape_sub` are all build-time and none is exposed. `Corpus::skeletons` says so in a
comment and gives the reason: they change what the index contains, so a per-call value means
a rebuild.

**Measured, as a cost.** This study moved the cutoff by appending **up to 3.1 million
keyless rows** to a 2.4 GB corpus, one full index build per rung. It works and it was
verified inert (§3), but it costs a rebuild per rung — 323 to 459 s each, plus writing a
2.5 GB file — it perturbs `idf`, the rarity boost and `derivativeness` as side effects
(§2a), it forces every measurement onto the root anchor because `motifs` has no anchor
(§5d), and **the reachable cutoff is n_padded/1000, so it is bounded by how much memory a
rung of keyless rows costs** — 7.4 GB at the base, 9.7 GB at `max_len` = 1,600.

**Spec.** Key the cached index by the build-time knobs the way `skeletons_at` is already
keyed by `(anchor, normalize_arity)`, and expose them on `similar`, `dictionary` and a new
`Corpus.index_profile()`. `physlib-census.md` §10.3 specifies the same change for the same
reason and this is the second independent study to stop one step short for want of it.

### S4. `Postings::build` should report what it dropped

**Defect.** Two reports have now had to infer the cutoff's effect. The dilution experiment
said outright that "instrumenting `Postings::build` to report which keys it dropped would
turn the inference into a measurement, and that instrumentation does not exist"; the census
reached the same constant by eliminating `candidate_budget` and `max_bucket`.

**What replaced it here, and why it is not enough.** `motifs(source, min_family=2, …)` reads
the surviving postings key by key, so inverting its member lists recovers the whole input to
candidate generation (§5, §6). But it can only show what survived — which is precisely the
complement of the question — so every measurement above had to be taken on a padded corpus
whose cutoff was raised past the keys of interest.

**Spec.** `SkeletonIndex` keeps `dropped: Vec<(TermId, u32)>` — the key and its document
frequency — behind the existing `motifs` surface as `source = "dropped"`, plus
`Corpus.postings(source, min_df, max_df) -> [(key, df, size, idf)]` without member names, so
an index-health check does not cost the rendering of every posting list. One line at build
time, and it is the difference between this report and a shorter one.

### S5. `min_shape_sub = 8` blocks the shape route for exactly these pairs

**Measured** (§5b). The two sides' `Shape` erasures share the `0 ≤ …` head, but as a subterm
it is **7 nodes** and the floor is 8. Every shared key of all four pairs is source B, and
source C — the source whose doc-comment says it "carries the design" because it is what lets
`le_trans` reach `dvd_trans` — contributes nothing.

**Not a spec, a measurement request**, because the floor is not reachable from the binding
and lowering it is a recall/cost trade with no data: rebuild the index at
`min_shape_sub ∈ {5, 6, 7, 8}` and report the four targets against source-C posting count and
candidate-set size. If 7 creates the key, the cheapest fix in this whole report is a
one-character change — and if it does not, S1 is the only route and that is worth knowing
before shipping S1.

### S6. `similar_brute` still cannot answer the question it exists to answer

It takes no `anchor`, so the differential reference for `similar` is root-anchored while
every cross-theory result in this project rides on the conclusion anchor. That was specified
in `physlib-classical-quantum.md` §12 S5 and has not landed; it is repeated here because
this study wanted a prefilter-free recall reference at the conclusion anchor and had to build
one out of `generalize` instead.

## 11. Reproducing this

```sh
# the ladder. Writes /tmp/pfx-base.jsonl (the module-root rewrite of the closed corpus),
# then one padded corpus and one child process per rung.
uv run scripts/phys-prefilter.py sweep --rungs 0 95368 200000 400000 800000 1600000

# the matched-N control: same n, same cutoff, 985 real rows against 95,268
uv run scripts/phys-prefilter.py matched --matched-n 200000

# the posting inventory and the admission rules, on a slice padded past its own cutoff.
# The full-corpus arm (§6a) is the base padded to n = 3,200,000, i.e. max_len = 3,200;
# its output is /tmp/pfx/admission-fullcorpus-n3200000.json.
uv run scripts/phys-prefilter.py admission --slice /tmp/pfx-small-1M.jsonl
uv run scripts/phys-prefilter.py admission --slice /tmp/pfx-clo-qi-1M.jsonl

# what the prefilter-free path costs at physics scale
uv run scripts/phys-prefilter.py exhaustive

# transfer: the same query on the 495,067-row full import closure, module roots rewritten
uv run scripts/phys-prefilter.py one --slice /tmp/pfx-fullclo.jsonl \
    --label fullclosure-n495067 --out /tmp/pfx/fullclosure.json --queries 20

# the table
uv run scripts/phys-prefilter.py report
```

Raw JSON for every run quoted above is in `/tmp/pfx/`, each stamped with the slice it came
from, its `n`, its effective `max_len` and its closure coverage.

`report` sorts by `max_len` and therefore **interleaves three different corpora** — the
padded ladder, the matched control's two arms, and the 495,067-row closure. The `label` and
`n` columns say which; the `max_len` column alone does not, and reading down it as if it were
one experiment would put a 495,067-declaration corpus between two 95,268-declaration ones.

**The padded corpora are large and are not kept.** A rung is `cat base padding > work`, one
index build, then the file is deleted; the largest is 3.2 million rows over a 2.4 GB base.
That is the cost of moving a build-time constant from outside the process, and S3 is the
change that makes it unnecessary.
