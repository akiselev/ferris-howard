# Symmetry, invariance and conservation — can the Atlas find Noether-shaped structure?

**Status:** measured 2026-08-04 · script `scripts/phys-symmetry.py` · corpora named per result
· nothing here selects on a declaration's name

Physics's deepest organizing principle is Noether's: a symmetry of the action corresponds to
a conserved quantity. If that principle leaves a trace in a *formalized* physics library, the
trace has to be structural — a shape statements come in, and a pattern in which shapes cite
which — because nothing else survives the trip from mathematics into `Expr`.

This is a report on looking for that trace with the Atlas, and on the several ways the answer
came back "no" before it came back "yes, but not the yes you wanted".

---

## 0. The rule this whole study is built to obey

**No name is ever used to select anything.** Not `grep -i invariant`, not a module whitelist
standing in for a concept. Names appear in the output so a reader can check a family at a
glance, and that is their only role. Every predicate is a property of the I3 statement
encoding (`statement-hash.md`) or of the citation graph.

The reason is not purity. It is that a name-based selector answers the question
"what did the library's authors call things", and the question here is whether the *structure*
carries the concept independently of what anyone called it. A grep would have made every
result below unfalsifiable.

---

## 1. The motifs, defined before anything was run

Peel a statement's `Pi` prefix; call the binders `B` and the remainder the conclusion `C`.
Take `C`'s application spine. If it has at least two arguments, the last two are the relation's
sides `L` and `R` — `Eq α a b` encodes as `a(a(a(c(Eq),α),a),b)`, so "the last two arguments"
picks out `(a, b)` for `Eq`, `(a, b)` for `LE.le α inst a b`, and `(p, q)` for `Iff p q`,
with no name consulted.

| motif | definition | example it must catch |
|---|---|---|
| **INV** | anti-unify `L` and `R`; every differing position is a *wrapping* — one side's subterm is the other's with a one-hole context around it, all in the same direction | `abs_neg : \|-a\| = \|a\|`, `⟪Λv,Λw⟫ = ⟪v,w⟫` |
| **INV-strict** | INV, and *one* context at every position — the same `T` applied | as above |
| **INV-IMP** | the same test on (antecedent, consequent) of a non-dependent `Pi` | `Nat.succ_le_succ : n ≤ m → n+1 ≤ m+1` |
| **SWAP** | the anti-unification's variables are a non-identity permutation: `{lᵢ} = {rᵢ}` with the pairing shuffled | `add_comm`, `f (g x) = g (f x)` |
| **CONS** | one side mentions an *explicitly* bound variable the other drops | `Nat.sub_self : n - n = 0` |
| **CONS-CLOSED** | CONS, and the dropping side is closed — `∀ t, Q t = c` | as above |

Two decisions inside INV are load-bearing and were made before any number was produced.

**A wrapping occurrence must not cross a binder.** De Bruijn indices shift under binders, so
"the same subterm" one binder deeper is a *different* term. Accepting those would be
CLAUDE.md §5's erasure defect rediscovered one level up. The search refuses to enter a
`Lam`/`Pi`/`Let` body.

**A consequent must be lowered before it is compared with its antecedent.** The consequent is
the `Pi`'s *body*, one binder deeper, so every index in it is shifted by one. The first
version of INV-IMP omitted the shift and could never fire — it was found by a positive
control, not by a test, which is the point of having positive controls.

### The positive control, run first

`python3 scripts/phys-symmetry.py --slice /tmp/mathlib-algebra.jsonl --self-test` — sixteen
lemmas whose mathematical content is known by hand, exit non-zero on any disagreement (names
used here to *state* the control, never to select the population it is checked against):

| declaration | verdict | context found |
|---|---|---|
| `abs_neg`, `abs_abs` | INV strict | `a1:Neg.neg`, `a1:abs` |
| `neg_neg`, `inv_inv`, `Int.neg_neg` | INV strict | double application |
| `Nat.add_zero` | INV strict | `a0:OfNat.ofNat\|a1:HAdd.hAdd` |
| `Nat.succ_le_succ` | INV-IMP strict | `a1:Nat.succ` |
| `add_comm`, `Nat.add_comm`, `Nat.mul_comm`, `Nat.gcd_comm`, `abs_sub_comm` | SWAP | — |
| `Nat.sub_self` | CONS closed | — |
| `le_refl` | *rejected* (`identical_sides`) | — |
| `mul_le_mul_left`, `Nat.gcd_rec` | *rejected* (`diff_not_a_wrapping`) | — |

**16 of 16 as intended**, including the three that must be rejected. `mul_le_mul_left`
(`b ≤ c → a*b ≤ a*c`) is the important rejection: monotonicity is not invariance, and a
predicate that cannot tell them apart is measuring "the two sides differ somehow".

---

## 2. What a good answer looks like — written before the measurements

Recorded here in the form it was written into the script's docstring before the first run.

**Q1 — is there a signature?**
*Works*: INV-strict fires on a minority of theorems (roughly 0.1%–10%); the hit rate on
**scrambled** pairs — `L` from one theorem, `R` from another — is far below the genuine rate;
a name-level spot check reads as invariance rather than boilerplate.
*Does not work*: ~0% (no signature), or >50% (punctuation), or the scramble control fires at
the same rate, which would mean the predicate is a property of terms and says nothing about
statements.

**Q2 — one motif or three?** Group INV hits by the transformation and by the `carriers`
skeleton, and score each family's subfield spread against a **size-matched null** — findings
§17: cross-field reach *is* the null, a 20-member family spans 9.2 subfields by chance.
*Works*: an INV family with spread meaningfully above its size-matched expectation whose
members come from different theories.
*Does not work*: INV families are as concentrated as everything else. §§17–18 predict exactly
this, so the honest prior is that the null wins.

**Q3 — Noether.** Count citation edges from CONS-matching declarations to INV-matching ones.
*Works*: the observed count exceeds both nulls — a uniform label shuffle **and** a
degree-matched shuffle — and is directional.
*Does not work*: inside either null. The degree-matched null is the one that matters: INV
statements might simply be popular, and a uniform shuffle cannot tell that from Noether.

**Q4 — neighbourhood shape.** In-degree, out-degree and statement size of INV declarations
against controls matched on subfield and statement size.
*Works*: a difference that survives the matching. *Does not work*: it is explained by
statement size, the obvious confound.

---

## 3. Calibration on Mathlib — and the control that changed the definition

Run first on `/tmp/mathlib-algebra.jsonl` restricted to `Mathlib.*` (24,323 rows, 15,916
theorems with a parseable statement, 15,427 of them with a relational conclusion). The slice
is a genuine import closure at **99.25%** (findings §32), so nothing here is measured on a
degraded corpus. Mathlib is the calibration corpus, not the target: it is where a physics
principle should *not* show up, which is what makes it useful.

| motif | hits | rate over 15,916 theorems |
|---|---|---|
| INV (all) | 2,213 | 13.90% |
| — INV positional (`common > 0`) | 784 | 4.93% |
| — INV whole-side (`common = 0`) | 1,429 | 8.98% |
| INV-strict (one context) | 1,993 | 12.52% |
| INV-IMP | 920 | 5.78% |
| SWAP | 295 | 1.85% |
| CONS | 1,643 | 10.32% |
| — CONS-closed | 44 | 0.28% |

Rejections are counted, not swallowed: 25,176 `diff_not_a_wrapping`, 575 `mixed_direction`,
147 `too_many_diffs`, 84 `identical_sides`. Zero parse failures over 15,916 statements.

### The scramble control, and what it killed

Same predicate, `L` from one theorem and `R` from another, 4,000 trials:

| branch | genuine rate (relational) | scrambled rate | ratio |
|---|---|---|---|
| **INV positional** | **5.08%** | **0.20%** | **25.4×** |
| INV whole-side | 9.26% | 16.40% | **0.56×** |
| SWAP | 1.91% | 0.00% (0 / 4,000) | ∞ |

**The whole-side branch fails its control outright** — it fires *more* often on statements
that have nothing to do with each other than on real ones. The reason is mechanical: when
`common = 0` the test degenerates to "is one side a subterm of the other", and when one side
is a bare bound variable the answer is almost always yes.

That branch was added on purpose, to stop `neg_neg : - -a = a` and `Nat.add_zero : n + 0 = n`
being false negatives — and the house rule says false negatives are the expensive kind. The
control says the price was 1,429 hits that a coin flip would have produced. Both facts are
reported and the branch is kept as a separate, labelled set; the *positional* branch is the
signature, and everything downstream is computed both ways.

This is the §16 failure mode caught before it became a result rather than after.

### Q1 on Mathlib: yes, and it is legible

The 784 positional hits group by **transformation** — the head constant of every sibling on
the path from the relation's side down to the hole, which is the operator that was applied.
No name, no module, no score:

| transformation | members | what it is |
|---|---|---|
| `a1:HMul.hMul` | 77 | multiplying a side and the relation surviving |
| `a0:?bvar\|a1:HPow.hPow` | 60 | raising to a bound power |
| `a1:Neg.neg` | 44 | invariance under negation |
| `a1:Inv.inv` | 39 | invariance under inversion |
| `a1:DFunLike.coe\|a1:DFunLike.coe` | 29 | `symm_apply_apply`, `apply_symm_apply` — the equiv round trip |
| `a0:?bvar\|a0:?binder\|a1:Function.swap` | 29 | order-class instances transported along `Function.swap` |
| `a1:abs` | 25 | `abs_abs`, `pow_abs`, `natAbs_abs` |

These are recognisably the invariance families of elementary algebra, recovered from term
structure alone. Whether that generalises to physics is §4.

### Q2 on Mathlib: concentration, exactly as §17 predicts

144 transformation families of ≥3 members. Subfield spread against the size-matched null:

| statistic | value |
|---|---|
| mean excess (observed − expected subfields) | **−1.76** |
| families with positive excess | **2 of 144** |
| best | +0.11 |
| worst | −4.10 (`a0:?bvar\|a1:HMul.hMul`, 50 members, 1 subfield) |

Invariance families are *more* concentrated than chance, not less. This is the third corpus
on which findings §§17–18's asymmetry reproduces, and the first where the families being
scored were selected by a structural predicate rather than by posting-list size.

### Q3 on Mathlib: the effect is real, and it is an artefact

The headline number looks like Noether:

| lens | observed CONS→INV | uniform null | degree-matched null | z |
|---|---|---|---|---|
| statement | 26 | 4.71 ± 4.33 | 22.86 ± 3.22 | **0.97** (n.s.) |
| proof | 561 | 344.97 ± 34.70 | 387.06 ± 17.70 | **9.82** |
| both | 568 | 345.27 ± 35.59 | 391.09 ± 17.60 | **10.05** |

and it is directional (CONS→INV 568 against INV→CONS 417). Note already that the
statement-lens result is significant against the uniform null (z = 4.92) and **not** against
the degree-matched one (z = 0.97) — the uniform shuffle is measuring popularity.

Then the placebos, at lens `both`, against the degree-matched null:

| pair | observed / null | ratio |
|---|---|---|
| CONS→CONS | 691 / 214.5 | **3.22** |
| INV→INV | 1,285 / 651.7 | **1.97** |
| CONS→INV | 568 / 391.1 | 1.45 |
| CONS→SWAP | 52 / 84.5 | 0.62 |
| SWAP→INV | 55 / 92.3 | 0.60 |
| CONS→INV-IMP | 73 / 121.0 | 0.60 |

Same-motif citation is far more elevated than CONS→INV. And **CONS and INV overlap on 441
declarations** — a statement can drop a parameter *and* be a wrapping. So the cross-motif
number can inherit the same-motif effect through the overlap. Making the sets disjoint:

| pair | observed | degree-matched null | z | ratio |
|---|---|---|---|---|
| (CONS \ INV) → (INV \ CONS) | 226 | 242.81 ± 14.55 | **−1.16** | 0.93 |
| (CONS \ INV-POS) → (INV-POS \ CONS) | 35 | 62.75 ± 8.21 | **−3.38** | 0.56 |

**The effect disappears, and with the control-passing definition of INV it inverts.**
Mathlib shows no Noether-shaped citation structure — which is the right answer for a corpus
that is not physics, and it is the answer only because two controls were built: the
degree-matched null and the disjointness split. Either alone would have left z = 10.05
standing.

### Q4 on Mathlib: no distinguishable neighbourhood

2,213 INV declarations paired with controls matched on subfield and log₂ statement size, then
a **paired** permutation test (2,000 relabellings within pairs):

| metric | INV | matched control | paired difference | p (two-sided) |
|---|---|---|---|---|
| in-degree (mean) | 2.020 | 1.697 | +0.323 | **0.131** |
| out-degree (mean) | 23.38 | 22.86 | +0.518 | **0.130** |
| statement bytes (median) | 476 | 484 | −18.17 | 0.020 |

The in-degree gap that looks like +19% in the raw means is not significant once the pairing
is respected, and the only significant difference is a residue of the size matching itself.
**Invariance statements do not sit in a differently shaped neighbourhood.**

---

---

## 4. Physics: `/tmp/fh-physlib.jsonl`, 14,568 declarations

### 4.0 What this corpus is, and what it is not

The physlib slice covers `Physlib` and `QuantumInfo` — 9,502 theorems, of which **9,186**
parse here. 317 statements exceed the 300 KB parse cap and were skipped; they are counted,
named in the output, and are almost all tensor-contraction machinery. They are a real false
negative source at **3.3% of theorems**, and a statement that large is exactly where a
physics library's index gymnastics live, so this is not a random 3.3%.

**This slice is not closed.** `Corpus.closure` on it is 12.39%. That matters for exactly one
class of query and it is worth being precise about which, because "the corpus must be closed"
is otherwise a rule that gets applied where it does not bite:

| computed here | needs closure? |
|---|---|
| motif classification, families by transformation, scramble control | **no** — reads the raw I3 `stmt`, which is what the extractor wrote |
| citation counts, the Noether nulls, degree matching | **no** — reads `uses_statement` / `uses_proof` as extracted |
| `skeleton(level="carriers")`, `similar`, `motifs` | **yes** — the erasure holes `InstImplicit` positions *of the head constant's signature*, so a missing head holes nothing and silently degrades to `presentation` |

So §§4.1–4.4 below stand on the unclosed slice; §5 is the part that needs the closure and
says so.

**The closure extraction has since completed, and its cost is worth recording** (CLAUDE.md §4
keeps measured costs, and there was no figure for a physics closure):

```
lake exe atlas_extract Physlib QuantumInfo > /tmp/fh-physlib-closure.jsonl
[import]  818,835 constants in 49.8 s;  closure imported in 58.8 s
[select]  495,067 extractable constants
[done]    495,067 rows in 2,999,216 ms   ->  5.42 GB
```

**50 minutes and 5.4 GB**, against Mathlib's 470,435 rows / 4.83 GB (§35) — a comparable row
count at a similar size, but the write phase alone ran 50 minutes because physics statements
are one to two orders of magnitude larger than Mathlib's (physlib theorem statements: median
3.5 KB, p99 709 KB, max 71 MB; the algebra slice's median is 476 bytes).

### The closure-independence claim, now measured rather than argued

The table above asserts that §§4.1–4.5 do not degrade on an unclosed slice. That is an
argument about which code path reads what, and an argument is not a measurement. **Re-running
the identical analysis against the closed 5.42 GB slice settles it:**

| | unclosed (12.39%) | closed | |
|---|---|---|---|
| theorems parsed | 9,186 | 9,176 | 10 fewer authored rows in the closure |
| relational conclusions | 9,051 | 9,041 | |
| **INV** | **666** | **666** | identical |
| **INV positional** | **281** | **281** | identical |
| **SWAP** | **81** | **81** | identical |
| **CONS-closed** | **826** | **826** | identical |
| CONS | 2,486 | 2,479 | tracks the 10 missing rows |
| INV-positional rate | 0.03105 | 0.03108 | |
| (CONS-closed \ INV) → (INV \ CONS-closed) | z = −4.07, r = 0.57 | **z = −4.28, r = 0.57** | |

Every motif count that does not depend on the 10 absent rows is **bit-identical**, and the
headline Noether refutation is unchanged. The closure requirement is real for erasure-based
queries and genuinely inert for these — which is now a fact about this corpus rather than a
reading of `erase.rs`.

### 4.1 Prevalence — and the first real difference from Mathlib

| motif | physlib | (Mathlib, for contrast) |
|---|---|---|
| INV positional | 281 · **3.11%** of relational | 5.08% |
| INV whole-side | 385 · 4.25% | 9.26% |
| SWAP | 81 · 0.89% | 1.91% |
| INV-IMP | 118 · 1.28% | 5.78% |
| **CONS** | 2,486 · **27.1% of theorems** | 10.3% |
| **CONS-closed** (`… = c`, `c` closed) | 826 · **9.0%** | **0.28%** |

(INV and SWAP rates are over the 9,051 relational conclusions, since the test cannot fire
without two sides; INV-IMP, CONS and CONS-closed are over all 9,186 parsed theorems. The
Mathlib column uses the same denominators.)

**CONS-closed is 32× more common in physics than in algebra.** That is the sharpest
structural difference in this study and it is what a physics library should look like:
"this quantity does not depend on that parameter" is a physics sentence, and it is rare in
abstract algebra. It is also the one place where a structural predicate distinguishes the
two libraries by their subject matter rather than by their size.

Rejections, again counted: 12,112 `diff_not_a_wrapping`, **1,058 `too_many_diffs`** (against
147 on Mathlib — physics conclusions differ in more places at once, and the cap of 16
differing positions is a second false negative source), 89 `mixed_direction`, 45
`identical_sides`. Zero parse failures over 9,186 statements.

### 4.2 The scramble control reproduces

| branch | genuine | scrambled (4,000 trials) | ratio |
|---|---|---|---|
| INV positional | 3.11% | 0.28% | **11.3×** |
| INV whole-side | 4.25% | 5.93% | **0.72×** |
| SWAP | 0.89% | 0.00% (0 / 4,000) | ∞ |

Same verdict on an independently-written corpus at a third of Mathlib's rate: positional INV
is a signature, whole-side INV is not. A second physlib run with 1,000 trials and a different
draw reproduces it (positional 0.30% scrambled against 3.11% genuine, 10.4×).

### 4.3 Q2 — one motif or three? **Thirty-seven, and they do not cross theories**

The 666 INV hits fall into 37 transformation families of ≥3 members. The families are
legible — names shown for reading, never used for selection:

| transformation | members | spread | reads as |
|---|---|---|---|
| `a1:DFunLike.coe` | 68 | Particles 24 · QFT 22 · Relativity 12 · Channels 6 · ForMathlib 3 · SpaceAndTime 1 | a bundled morphism applied and the equation surviving — `cubicInvariant`, `linearInvariant`, `quadInvariant`, `normalOrderF_normalOrder` |
| `a1:HSMul.hSMul` | 38 | **Relativity 21** · Particles 7 · SpaceAndTime 5 · QM 2 · EM 1 · Units 1 | the scalar-action equivariance family — `dist_smul`, `rotation_dist_smul`, `isExterma_equivariant` |
| `a1:DFunLike.coe\|a1:DFunLike.coe` | 18 | Mathematics 7 · Relativity 6 · ForMathlib 3 · QM 2 | round trips — `fromL2_toL2`, `toL2_fromL2`, `unitary_apply_star_eq`, `unitary_star_apply_eq` |
| `a1:DFunLike.coe\|a1:Neg.neg` | 7 | **Relativity 7** | metric antisymmetry — `leviCivita_antisymm`, `dualLeftMetric_antisymm` |
| `a0:?bvar\|a1:HermitianMat.cfc` | 8 | **ForMathlib 8** | continuous functional calculus preserving kernels |
| `a1:LinearPMap.closure` | 5 | **QM 5** | unbounded-operator closure |
| `a1:UnitDependent.scaleUnit` | 5 | **Units 5** | invariance under a unit rescaling |

Scored against the size-matched null:

| grouping | families (≥3) | mean excess | families with excess > 0 | best |
|---|---|---|---|---|
| by transformation | 37 | **−2.61** | **0 of 37** | −0.73 |
| by shape (relation head + hole positions + direction) | 30 | −1.84 | 4 of 30 | **+1.54** |

**Zero of thirty-seven transformation families reach their size-matched expectation.** The
largest, `DFunLike.coe` at 68 members, spans 6 subfields where chance predicts 15.7.

The pre-registered "works" condition for Q2 was a family with spread meaningfully above
size-matched expectation whose members come from different theories. It is not met. Lorentz
invariance, gauge invariance and unitary invariance are **not** one motif at this resolution;
`HSMul.hSMul` is 55% Relativity, `LinearPMap.closure` is 100% QuantumMechanics, and
`HermitianMat.cfc` is 100% QuantumInfo.

The single positive-excess family worth naming is `('Eq', 'a0|a1', 1, 'R<L')` — 33 members,
14 subfields against 12.46 expected, excess **+1.54** — whose members are `compose_id`,
`scale_one`, `one_mul`, `koszulSignInsert_append`, `normalOrderSign_append`. That is the
**unit law**, and it crosses theories because every theory has an identity element, not
because physics has a shared symmetry. The one cross-field invariance motif in a physics
corpus is `x • 1 = x`.

This is findings §17's asymmetry, reproduced a third time on a set selected by a completely
different criterion: **structural coherence within a field is strong and cross-field
structure is at or below chance.**

### 4.4 Q3 — Noether: no

CONS→INV citation, lens `both`, 1 hop, 200 shuffles:

| set pair | \|A\| | \|B\| | overlap | observed | z vs degree-matched null | ratio | reverse |
|---|---|---|---|---|---|---|---|
| CONS → INV (raw) | 2,486 | 666 | 266 | 287 | 1.63 | 1.08 | 299 |
| (CONS \ INV) → (INV \ CONS) | 2,220 | 400 | 0 | 126 | **−2.17** | **0.84** | 87 |
| (CONS \ INV-POS) → (INV-POS \ CONS) | 2,341 | 136 | 0 | 49 | −0.53 | 0.94 | 35 |
| **(CONS-closed \ INV) → (INV \ CONS-closed)** | 810 | 650 | 0 | 45 | **−4.07** | **0.57** | 47 |
| **(CONS-closed \ INV-POS) → (INV-POS \ CONS-closed)** | 826 | 281 | 0 | 17 | **−2.84** | **0.56** | 17 |

The last two rows are the sharpest form of the test — CONS-closed is `∀ t, Q t = c` for a
closed `c`, the 826 physlib theorems that say a quantity is *literally constant*. Against a
degree-matched null they cite invariance-shaped declarations at **57% of chance, z = −4.07**.

That is not a null result. **Conservation-shaped statements in physlib rest on
invariance-shaped statements significantly less often than degree-matched controls do**, and
the effect gets stronger as the conservation reading gets tighter — the opposite of what a
structural Noether would predict, where tightening the conservation motif should sharpen the
signal.

The reverse direction is also flat or larger (INV→CONS 299 against CONS→INV 287 raw; 47
against 45 for CONS-closed; 17 against 17 for the tightest pair). Noether predicts a
direction; the data has none.

**Relaxing to two citation steps does not rescue it — it sharpens the refutation.** A
conservation theorem need not cite the invariance lemma directly; its proof might reach it
one step further down. Counting everything within two hops (reachability precomputed once,
so the nulls re-use it):

| set pair | 1 hop obs / null | z | 2 hop obs / null | z |
|---|---|---|---|---|
| (CONS \ INV) → (INV \ CONS) | 126 / 150.4 | −2.17 | 278 / 314.4 | −1.82 |
| (CONS \ INV-POS) → (INV-POS \ CONS) | 49 / 52.2 | −0.53 | 100 / 108.6 | −0.73 |
| **(CONS-closed \ INV) → (INV \ CONS-closed)** | 45 / 79.1 | −4.07 | **92 / 167.0** | **−5.31** |
| (CONS-closed \ INV-POS) → (INV-POS \ CONS-closed) | 17 / 30.6 | −2.84 | 38 / 64.4 | −2.87 |

At two hops the tightest conservation reading reaches invariance-shaped declarations at
**55% of the degree-matched rate, z = −5.31**. Every free parameter that could have hidden a
weak Noether signal — direct-versus-transitive, statement-versus-proof lens, tight-versus-loose
conservation — has been swept, and the effect is negative at every setting.

The placebos, same lens and null:

| pair | ratio to degree-matched null | z |
|---|---|---|
| INV → INV | **3.11** | 21.41 |
| CONS → CONS | **1.56** | 19.71 |
| CONS → SWAP | 1.11 | 0.76 |
| CONS → INV-IMP | 0.96 | −0.31 |
| SWAP → INV | 0.42 | −1.29 |

So the citation graph *does* carry strong motif structure — declarations of the same motif
cite each other far above chance, on both corpora. It is homophily, not Noether. A
conservation statement is no more likely to rest on an invariance statement than on anything
else of the same degree, and once the motif classes are made disjoint it is slightly *less*
likely.

**The pre-registered "does not work" condition for Q3 is met on both corpora.** The
structural rendering of Noether tested here is refuted, not merely unsupported.

### 4.5 Q4 — neighbourhood shape: no

666 INV declarations, 657 with a subfield-and-size-matched partner, paired permutation test:

| metric | INV | matched control | paired difference | p |
|---|---|---|---|---|
| in-degree (mean) | 1.368 | 1.598 | −0.219 | 0.170 |
| out-degree (mean) | 83.23 | 89.99 | −6.478 | 0.059 |
| statement bytes (median) | 2,178 | 2,159 | +1,170 | 0.256 |

Nothing significant at the 5% level, and the near-miss on out-degree runs *downward* —
invariance statements cite slightly fewer things than their matched controls, the opposite of
a hub. Both corpora agree: **the dependency graph around an invariance statement is not
shaped differently.**

---

## 5. The three queries that need a closed corpus

Run on `/tmp/mathlib-algebra.jsonl`, checked at **coverage 0.9925** (2,013,373 known
application heads against 15,298 unknown, the misses being `Array._sizeOf_inst` and friends)
before any of the three was called. **These three answers are Mathlib's**; §4 is where the
physics is. The physics closure was extracted (495,067 rows, 5.42 GB) and `Corpus.load` on it
was **OOM-killed at exit 137** — so the physics versions of §5.1–5.3 are not measured, and the
reason is recorded in §7 rather than papered over.

### 5.1 `motifs()` does not contain the invariance motif

The topic asks to start from `motifs()` — the corpus-wide sub-pattern inventory — and ask
which of its shapes are invariance-shaped. Both sources, top 400 by `size × log(family)`,
each pattern classified by the same predicate that classifies a statement:

| source | motifs | relational | **INV** | SWAP |
|---|---|---|---|---|
| `shape` | 400 | 326 | **8** (2.5%) | 0 |
| `subterm` | 400 | 366 | **39** (10.7%) | 0 |

All **eight** `shape` hits are one family — `sizeOf_spec`, the auto-generated size lemma —
and the 39 `subterm` hits are led by `Std.Iterators` plumbing (`toArray_keysIter` ×10,
`toArray_valuesIter` ×6, `toArray_iter` ×2), plus `Equiv.optionSubtype` and `step_flatMap`.
Not one is mathematics.

**Corpus-wide shared structure turning out to be punctuation is now a list findings §16
started** — `walls`, `busiest_heads`, `similar`, `classes`, `dictionary`, `frontier`, raw
motif mining — and `motifs` filtered for invariance shape belongs on it. `motifs` inventories
the sub-patterns
*shared between declarations*; an invariance statement's content is a relation between a
statement's *own two halves*, and no amount of cross-declaration pattern mining surfaces it.
That is the argument for §6.2's `self_generalize`, and it is measured rather than asserted.

*(Reporting caveat: `subfields` reads 0 for most motif rows because the members are
`Init`/`Lean`/`Std` declarations outside the `Mathlib.*` analysis scope. It affects the
spread column only, not the INV counts.)*

### 5.2 Whole-statement grouping at `carriers` is dead here too

900 of the INV hits grouped by `skeleton(level="carriers")`: the largest families are **4
members**. They are `mul_one` ×4, `one_mul` ×4, `add_zero` ×3 — all `Mathlib.Algebra`, all
one subfield, all below their size-matched expectation. Findings §16 measured mean family
size 1.00 for whole-statement grouping corpus-wide; restricting to a structurally selected
subset does not rescue it.

The unit law shows up here as the largest carriers-level invariance family, on the same
corpus where it was the only positive-excess *shape* family in physics (§4.3). Two
independent groupings, two corpora, same answer: the one invariance motif that genuinely
crosses theories is `x * 1 = x`.

### 5.3 `similar` *does* retrieve the motif — 3.1× its base rate

80 INV declarations and 80 non-INV declarations as queries, `level="carriers"`,
`anchor="conclusion"`, `top=25`, floors dropped to `min_retention=0.05` / `min_common=3` per
the recall rule:

| query set | neighbours returned | of which INV | rate | vs base rate |
|---|---|---|---|---|
| INV | 1,464 | 629 | **42.96%** | **3.09×** |
| non-INV | 1,347 | 162 | 12.03% | 0.87× |
| — base rate of INV among theorems | | | 13.90% | 1.00× |

The engine's own neighbour query, which has never been told what invariance is, returns
invariance-shaped neighbours from an invariance-shaped query at three times chance, and at
chance from a control query. **This is the one unambiguously positive result in the study:
the Atlas can retrieve the motif even though it cannot name it.**

The cross-subfield share does *not* move — 173 of 629 (27.5%) from INV queries against 48 of
162 (29.6%) from controls. So `similar` retrieves the motif and does not retrieve it across
theories, which is §4.3's finding arriving by a second route.

---

## 6. Atlas queries this study needed and had to write by hand

Everything above runs on a **Python re-implementation of the I3 parser** (~330 lines inside
`scripts/phys-symmetry.py`) because the engine exposes no way to reach inside a statement.
`skeleton` returns the whole erased statement as a string; `generalize` anti-unifies *two*
declarations. There is no way to ask what a statement concludes, or to anti-unify a statement
with itself.

That is the gap. Three queries close it, in dependency order. All three are cheap in Rust —
`skel/term.rs` already has the arena, `skel/lgg.rs` already has the anti-unifier with the
depth-keyed memo — and the Python version of this analysis costs 4–20 minutes per corpus
where the Rust one would cost seconds.

### 6.1 `Corpus.conclusion(name, level="exact") -> Conclusion`

```
class Conclusion:
    binders:  list[tuple[str, str, bool]]  # (binder_info, rendered domain, dependent?)
    body:     str                          # the Pi-prefix stripped, rendered in I3
    head:     str | None                   # the conclusion spine's head constant; None if flex
    args:     list[str]                    # its arguments, rendered, head-first order
    arity:    int
```

*Semantics.* `Arena::peel_pis` already exists (`term.rs:250`). `head`/`args` are
`Arena::spine`. `level` erases first, so `conclusion(n, "carriers")` is the carrier-blind
conclusion.

*Errors.* `UnknownDeclaration`, `NoStatement`, `ValueError` on a bad level — same as
`skeleton`.

*Why it must exist:* every question of the form "what does this theorem claim, as opposed to
what does it assume" currently requires re-parsing the encoding outside the engine. The
`anchor="conclusion"` option on `similar` proves the engine already needs this internally; it
just does not hand it out.

### 6.2 `Corpus.self_generalize(name, left, right, anchor="conclusion") -> SelfLgg`

Anti-unify **two subterms of one statement**, selected by index into the conclusion's spine
(`left=-2, right=-1` is "the relation's two sides").

```
class SelfLgg:
    skeleton:    str                        # the shared pattern, `?k` for each difference
    common:      int                        # concrete nodes shared
    bindings:    list[tuple[str, str]]      # (left subterm, right subterm) per variable
    contexts:    list[str | None]           # one-hole context per variable, `None` if neither
                                            # side embeds in the other, `"#"` marks the hole
    crosses_binder: list[bool]              # per variable: does the embedding cross a binder?
```

*Semantics.* The existing `lgg` with its depth-keyed memo, run on two nodes of the same
arena, plus a one-hole-context search per variable. `contexts` is the whole reason to build
this rather than reuse `generalize`: the *substitution* is what carries the motif, and
`Generalization` throws it away, keeping only `common`, `vars` and `retention`.

*`crosses_binder` is not optional.* A context found through a `Lam`/`Pi`/`Let` body relates
terms at different de Bruijn depths, so "the same subterm" there is a different term. The
Python version refuses those silently; the engine should return them flagged, so a caller
choosing recall can see what it is admitting. This is the same class of defect as
`erase.rs`'s "replace binders, never delete them" — reported, not swallowed.

*Errors.* `UnknownDeclaration`, `NoStatement`, `IndexError` when the spine is shorter than
the requested index.

### 6.3 `Corpus.motif_classes(kind, level="exact", theorems_only=True) -> list[MotifFamily]`

The corpus-wide inventory: classify every theorem's conclusion and return the families.

```
class MotifFamily:
    motif:      str            # "INV" | "INV_IMP" | "SWAP" | "CONS"
    variant:    str            # "positional" | "whole_side" for INV; "closed" for CONS
    transform:  str            # the context key — `"a1:Neg.neg"` — "" when not applicable
    members:    list[str]
    strict:     bool           # one context at every differing position
```

*Semantics.* One pass over the arena, `self_generalize` per theorem, group by
`(motif, variant, transform)`. It is `motifs()`'s sibling: `motifs` inventories the shared
*sub-patterns*, this inventories the shared *relations between a statement's own parts*, and
the two find different things — §4 below shows `motifs` returns almost nothing
invariance-shaped while this returns hundreds of families on the same corpus.

*The negative control ships with the query, not beside it.* `motif_classes` must expose the
scrambled baseline — reclassify with `L` and `R` drawn from different statements — as a
first-class field, because §3 shows one of the two INV variants fails that control and
nothing in the output reveals it. A query whose result cannot be wrong is CLAUDE.md §3's
"tool that says everything is fine".

*Where it lands.* Engine `crates/fh-atlas/src/skel/`, Python binding plus `.pyi`, `fh mcp`
tool list, and a gate over `/tmp/mathlib-algebra.jsonl` asserting the positional/whole-side
separation reproduces (25.4× against 0.56×) — a two-sided assertion, so it goes red if either
branch drifts.

### 6.4 The prerequisite none of the three can work around

**`Corpus::load` has to stop holding the whole slice in memory.** Measured: Mathlib's closure
(4.83 GB, 470,435 rows) loads; physlib's (5.42 GB, 495,067 rows) is OOM-killed on a 31 GB
machine, because physics concentrates its bytes in individual statements two orders of
magnitude larger than Mathlib's rather than spreading them over many small ones.

That is not a physlib quirk to be worked around — it is the first corpus in this project whose
*shape* rather than size defeats the loader, and every §5-class query on physics is blocked
behind it. A streaming or `mmap`-backed arena is a larger change than any query in §6, and it
is the one that decides whether the Atlas can be pointed at physics at full fidelity at all.

### 6.5 What is *not* worth adding (yet)

A `noether(A, B, lens)` graph query. The citation graph is already bound, the shuffles are
twelve lines of Python, and the hard part of §3's result was choosing the nulls — which is a
research decision that must stay visible in the script, not a default buried in the engine.

---

## 7. Failures, limits and things that would change the answer

**One of the four pre-registered questions came back yes; the other three came back "does not
work" — and one of those only after a control removed an effect that had looked like
z = +10.** In order:

| question | pre-registered "works" | verdict |
|---|---|---|
| Q1 signature | fires on 0.1–10%, far above scramble, legible | **yes** — 5.08% / 3.11%, 25.4× / 11.3× above scramble, families legible |
| Q2 one motif or three | a family above its size-matched spread | **no** — 0 of 37 physics families reach expectation |
| Q3 Noether | above both nulls, directional | **no** — below chance once the classes are disjoint, and undirected |
| Q4 neighbourhood | a difference surviving matching | **no** — nothing at p < 0.05 on either corpus |

### The four things that were nearly wrong

1. **INV whole-side.** Added to avoid false negatives on `neg_neg`; fires *more* on scrambled
   pairs than on real ones (0.56× / 0.72×). Kept as a labelled set, excluded from every
   headline number. Without the scramble control it would have carried 1,429 of Mathlib's
   2,213 INV hits and every downstream number with it.
2. **The uniform label shuffle.** On Mathlib's statement lens it gives z = 4.92 where the
   degree-matched shuffle gives z = 0.97. A study with only the shuffle the topic asked for
   would have reported a Noether effect that is entirely popularity.
3. **The CONS/INV overlap.** 441 declarations on Mathlib, 266 on physlib are *both*. Since
   same-motif citation runs at 1.97–3.22× chance, an overlapping pair inherits that. Making
   the sets disjoint moved Mathlib's headline from z = +10.05 to z = −1.16.
4. **INV-IMP could never fire.** The consequent of a non-dependent `Pi` is one binder deeper
   than its antecedent; the first version compared them unshifted and returned zero on
   everything. Caught by a hand-built positive control, not by a test.

### Limits that bound what any of this can claim

* **3.3% of physlib theorems (317) were never parsed** — over the 300 KB cap. Not a random
  3.3%: they are the tensor-contraction statements, which is where a physics library's index
  symmetry lives. This is the largest single false negative in the study.
* **1,058 physlib conclusions exceeded the 16-differing-position cap** (against 147 on
  Mathlib). A statement whose two sides differ in seventeen places may still be an
  invariance; this measurement cannot see it.
* **"Last two arguments of the conclusion spine" is a heuristic.** It is right for `Eq`,
  `Iff`, `LE.le` and every binary relation, and meaningless for `HasDerivAt f f' x`. Those
  become noise, not false hits — the tests reject them — but they inflate the `relational`
  denominator.
* **CONS is broad by construction**: 27.1% of physlib theorems. It says "one side does not
  mention a parameter the other does", which is a superset of conservation. CONS-closed
  (9.0%) is the tight reading and is tested separately.
* **The physlib slice §4 runs on is not closed (12.39%).** §§4.1–4.5 do not depend on that
  (they read raw `stmt` and raw citation lists); §5's three queries do, and were therefore run
  on Mathlib's closure instead. **The physics half of §5 is not measured, and no number here
  stands in for it.**
* **The physics closure exists, and `Corpus.load` on it was OOM-killed.** This was run, not
  predicted. With 20 GB free the process completed every raw-statement and graph stage (which
  is where the closure-independence table in §4.0 comes from), reached
  `loading the Rust corpus for erasure …`, and was killed by the kernel — **exit 137**. A
  concurrent process had earlier been observed at **15.2 GB RSS** loading the same file, so
  the load alone is around half of this 31 GB machine before the B4 skeleton index is built on
  top of it.

  So §5 against physics is **not measured, and could not be**, on this hardware while other
  work is running. That is a resource limit rather than a negative result and must not be read
  as one — but it is also a real finding about the engine: **the Atlas cannot currently open a
  closed physics corpus.** Mathlib's closure is 4.83 GB for 470,435 rows and works; physlib's
  is 5.42 GB for 495,067 rows and does not, because the bytes are concentrated in enormous
  individual statements rather than spread over many small ones. Whatever the index costs per
  byte, physics pays it in a shape the current implementation cannot absorb.
* **`subfield` is the depth-2 module prefix.** `Physlib.Relativity` and `Physlib.QFT` are
  different subfields; `QuantumInfo.ForMathlib` is a subfield that is really a Mathlib
  staging area, and it is the largest single contributor to several families. Treating it as
  a physics theory flatters the cross-field numbers, which are negative anyway.

### What would change the answer

* **A closed physlib slice** would let §5 run on physics: whether `similar` retrieves the
  invariance motif *in physics* at 3× base rate is the single most useful unmeasured number
  here, because §5.3 is the one positive result and it is currently Mathlib-only. **The slice
  exists** — `/tmp/fh-physlib-closure.jsonl`, 495,067 rows, 5.42 GB (§4.0) — **and loading it
  was OOM-killed** (§7 limits). Getting this number needs either more memory than 31 GB or a
  streaming/mmap corpus loader, which is a bigger change than any query in §6. The command,
  for a machine that can hold it:

  ```sh
  uv run scripts/phys-symmetry.py --slice /tmp/fh-physlib-closure.jsonl \
      --authored Physlib,QuantumInfo --max-stmt 300000 \
      --skeletons 900 --similar-probes 80 --motifs-top 400 \
      --out /tmp/fh-phys-sym-physlib-closed.json
  ```

  and check the printed `closure coverage` is ≥ 0.95 **before** reading anything from
  `motif_inventory`, `inv_carriers_families` or `similar_retrieval`. The script prints it and
  does not gate on it, deliberately: a silent gate is how §31 happened.
* **A conservation motif built from `deriv`/`IsConst`-shaped structure** rather than from
  parameter-dropping. CONS is a syntactic proxy; the physics reading — "the time derivative
  of this quantity along a solution is zero" — has its own shape, and testing Noether with a
  proxy that fires on 27% of theorems is a weak test of a strong claim. That the answer came
  back *below* chance rather than merely null is what makes it worth reporting anyway.
* **Anchoring the Noether test on proofs rather than statements.** The `proof` lens is where
  the signal was on Mathlib before the disjointness control killed it, and a formalized
  Noether theorem would show up as a proof-lens edge. physlib's proof lens gives ratio 1.10
  (z = 1.75) raw and 0.84 disjoint — so the answer does not change, but a corpus that
  actually *contains* a Noether theorem might.

### The one-line summary

The Atlas can find invariance: a name-free structural predicate isolates it at 25× a
scrambled baseline, groups it into families a physicist would recognise, and the engine's own
`similar` retrieves it at 3.1× base rate without being told what it is. What the Atlas cannot
find is the *organizing* part of the organizing principle — invariance families are more
theory-bound than chance (0 of 37 above expectation), and conservation statements are
*less* likely to cite invariance statements than degree-matched controls — at every lens,
hop count and tightness of the conservation reading, reaching z = −5.31. Noether's theorem is
not visible in the shape of a physics library's citation graph, and it is not visible in a way
that four separate controls agree on.

The last of those controls is the one that closes the loop: re-running the whole analysis on
the 5.42 GB *closed* physics corpus reproduces every motif count bit-identically. The result
does not depend on the corpus defect it was most at risk from — which is the only reason the
negative is worth stating at all.
