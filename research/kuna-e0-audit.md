# Kuna E0 source audit

**Status:** pre-registered source audit, performed 2026-08-04 against the Mathlib
revision recorded in `research/data/kuna-e0-events.json`.

This audit judges only whether the miner exactly recovered the named structural event:
the same declaration and carrier arguments changed from the recorded source class to the
recorded ancestor class. It does **not** certify that the entire child signature is logically
weaker, that the change is mathematically novel, or that Ferris–Howard would have proposed it
at the parent revision. Those stronger questions belong to E1 historical replay.

The sample membership was fixed by the `20260804` SHA-256 selector in
`scripts/kuna-truth.py`. During the audit, a provenance defect (renamed files retained only
their child path) and an identity defect (carrier arguments were absent from event
deduplication) were found and repaired. The declaration/class-pair sample was not redrawn;
where the same pair changed on multiple carriers, the recorded carrier is selected by a
full-record hash.

## Direct declaration binders

Threshold: at least 27 of 30 exact. Result: **30 of 30 exact; pass**.

| commit | declaration | extracted event | verdict |
|---|---|---|---|
| `4e7ba671d15d` | `NormedField.tendsto_zero_smul_of_tendsto_zero_of_bounded` | `NormedField → NormedDivisionRing` on `𝕜` | exact |
| `01a1c9017b7c` | `Function.Periodic.nsmul_sub_eq` | `AddCommGroup → SubtractionCommMonoid` on `α` | exact |
| `19b4c40bc454` | `Filter.map_val_atTop_of_Ici_subset` | `SemilatticeSup → Preorder` on `α` | exact |
| `00c938fa2c40` | `Function.Antiperiodic.nat_mul_sub_eq` | `Ring → NonAssocRing` on `α` | exact |
| `a1359d02d839` | `List.sum_le_foldr_max` | `AddMonoid → AddZeroClass` on `M` | exact |
| `9ee04169ae7c` | `MeasureTheory.AEStronglyMeasurable.enorm` | `ENormedAddMonoid → ContinuousENorm` on `β` | exact |
| `33c02ffbc1c0` | `Filter.IsBoundedUnder.bddAbove_range` | `SemilatticeSup → Preorder` on `β` | exact |
| `3c3631e20f53` | `WithTop.wellFounded_lt` | `Preorder → LT` on `α` | exact |
| `f7b5ce7c9fd3` | `Finsupp.comapDomain_smul_of_injective` | `AddMonoid → Zero` on `M` | exact |
| `c8c1429f3c89` | `MeasureTheory.SimpleFunc.coe_le` | `Preorder → LE` on `β` | exact |
| `345037212607` | `Matrix.blockDiagonal'_smul` | `Module → SMulZeroClass` on `R α` | exact |
| `1d2227ece762` | `Localization.awayLift_mk` | `CommRing → CommSemiring` on `A` | exact |
| `bde6f55c01f3` | `LinearIndependent.group_smul` | `DistribMulAction → MulAction` on `G R` | exact |
| `3038499595e0` | `Codisjoint.dual` | `SemilatticeSup → PartialOrder` on `α` | exact |
| `26e4c270c0f4` | `cauchy_davenport_mul_of_linearOrder_isCancelMul` | `Semigroup → Mul` on `α` | exact |
| `c2f3c7e48850` | `Filter.Tendsto.prod_map_prod_atBot` | `SemilatticeInf → Preorder` on `γ` | exact |
| `c8c1429f3c89` | `HasLineDerivAt.tendsto_slope_zero_right` | `PartialOrder → Preorder` on `𝕜` | exact |
| `f7b5ce7c9fd3` | `Finsupp.eq_zero_of_comapDomain_eq_zero` | `AddCommMonoid → Zero` on `M` | exact |
| `9ee04169ae7c` | `MeasureTheory.SimpleFunc.setToSimpleFunc_smul` | `NormedSpace → SMulZeroClass` on `𝕜 E` | exact |
| `d8a87eebe8c9` | `tangentConeAt_mono_field` | `NormedAlgebra → SMul` on `𝕜 𝕜'` | exact |
| `307fa2553bbc` | `Function.Injective.isOrderedMonoid` | `PartialOrder → Preorder` on `β` | exact |
| `f7b5ce7c9fd3` | `DFinsupp.prod_inv` | `CommGroup → DivisionCommMonoid` on `γ` | exact |
| `ffaeb65b07d5` | `SimpleGraph.adjMatrix_mulVec_const_apply_of_regular` | `Semiring → NonAssocSemiring` on `α` | exact |
| `c8c1429f3c89` | `MeasureTheory.AEStronglyMeasurable.nullMeasurableSet_lt` | `LinearOrder → Preorder` on `β` | exact |
| `f24b1dcf8432` | `MeasureTheory.LocallyIntegrableOn.smul_continuousOn` | `NormedField → NormedRing` on `𝕜` | exact |
| `00c938fa2c40` | `MonoidHom.coe_toMultiplicative_ker` | `AddGroup → AddZeroClass` on `A'` | exact |
| `3038499595e0` | `Pi.lex_desc` | `Preorder → LT` on `α` | exact |
| `ed32f2fcb0ac` | `isArtinianRing_iff` | `Ring → Semiring` on `R` | exact |
| `1296581ef3ca` | `Pi.linearIndependent_single_one` | `Ring → Semiring` on `R` | exact |
| `19b4c40bc454` | `Filter.atBot_Iic_eq` | `SemilatticeInf → Preorder` on `α` | exact |

## Section-inherited binders

Threshold: at least 24 of 30 exact. Result: **30 of 30 exact; pass**.

The verdict means the named declaration lies in the changed scope and its statement uses the
recorded carrier. It remains an approximation of Lean's auto-bound variable inclusion until
E1 elaborates the parent and child revisions.

| commit | declaration | extracted event | verdict |
|---|---|---|---|
| `9d89f49884a4` | `ContinuousMultilinearMap.mkPiField_apply_one_eq_self` | `NormedAddCommGroup → SeminormedAddCommGroup` on `G` | exact |
| `eeb7b5465918` | `inv_antitoneOn_Iio` | `LinearOrder → PartialOrder` on `α` | exact |
| `781b85cf8b70` | `Finset.analyticOn_prod` | `NontriviallyNormedField → NormedDivisionRing` on `𝕝` | exact |
| `dd7fc3b379ce` | `LinearMap.rank_zero` | `AddCommGroup → AddCommMonoid` on `V` | exact |
| `9afdff78cbdf` | `LinearIndependent.repr_eq_single` | `Ring → Semiring` on `R` | exact |
| `d68208406d73` | `CFC.nnrpow_eq_rpow` | `IsTopologicalRing → IsSemitopologicalRing` on `A` | exact |
| `66e14198c9ac` | `Module.Flat.of_isLocalizedModule` | `AddCommGroup → AddCommMonoid` on `Mp` | exact |
| `2fc69c7f2cf8` | `ContinuousLinearMapWOT.ext_dual` | `RCLike → NormedField` on `𝕜` | exact |
| `d68208406d73` | `Subsemiring.topologicalClosure_coe` | `IsTopologicalSemiring → IsSemitopologicalSemiring` on `R` | exact |
| `5f7fa5a09f53` | `Bialgebra.TensorProduct.map_toAlgHom` | `Bialgebra → Algebra` on `R C` | exact |
| `d68208406d73` | `NonUnitalStarAlgebra.elemental.self_mem` | `IsTopologicalSemiring → IsSemitopologicalSemiring` on `A` | exact |
| `c94dd5909556` | `Valuation.isClosed_closedBall` | `CommRing → Ring` on `R` | exact |
| `e9da88d74d4f` | `OrderIso.essInf_apply` | `CompleteLattice → ConditionallyCompleteLattice` on `β` | exact |
| `d68208406d73` | `Subring.le_topologicalClosure` | `IsTopologicalRing → IsSemitopologicalRing` on `R` | exact |
| `9afdff78cbdf` | `LinearIndependent.eq_zero_of_pair` | `AddCommGroup → AddCommMonoid` on `M` | exact |
| `d8a87eebe8c9` | `UniqueDiffOn.mono_field` | `NontriviallyNormedField → Semiring` on `𝕜` | exact |
| `74bdd8deff80` | `StieltjesFunction.length_eq` | `ConditionallyCompleteLinearOrder → LinearOrder` on `R` | exact |
| `d67fcdf39426` | `isCoatomistic_dual_iff_isAtomistic` | `CompleteLattice → PartialOrder` on `α` | exact |
| `3368abb80080` | `Module.lt_rank_of_lt_finrank` | `AddCommGroup → AddCommMonoid` on `M` | exact |
| `6313738aeb18` | `DirectSum.decompose_eq_mul_idempotent` | `Ring → Semiring` on `R` | exact |
| `eb17951d2e42` | `MeasureTheory.Integrable.exists_boundedContinuous_integral_sub_le` | `T4Space → NormalSpace` on `α` | exact |
| `9754d542d3eb` | `deriv_const_smul` | `Semiring → Monoid` on `R` | exact |
| `dffa0f212982` | `fderiv_eq` | `NormedAddCommGroup → AddCommGroup` on `E` | exact |
| `16a1c5cebbf7` | `FormalMultilinearSeries.congr_zero` | `IsTopologicalAddGroup → ContinuousAdd` on `F` | exact |
| `fd00e5be8f21` | `PrimeSpectrum._root_.Ideal.finite_minimalPrimes_of_isNoetherianRing` | `CommRing → CommSemiring` on `R` | exact |
| `c94dd5909556` | `Valuation.mem_nhds_zero_iff` | `CommRing → Ring` on `R` | exact |
| `781b85cf8b70` | `AnalyticAt.div` | `NontriviallyNormedField → NormedDivisionRing` on `𝕝` | exact |
| `01d39ae1d084` | `MeasureTheory.MemLp.of_measure_le_smul` | `ENormedAddMonoid → ContinuousENorm` on `ε` | exact |
| `d68208406d73` | `StarSubalgebra.le_topologicalClosure` | `IsTopologicalSemiring → IsSemitopologicalSemiring` on `A` | exact |
| `66e14198c9ac` | `Module.Flat.linearIndependent_one_tmul` | `AddCommGroup → AddCommMonoid` on `M` | exact |

## Selected commits with no retained event

All 30 were read at the source diff and full commit message. This is a coverage audit, not a
false-negative count: most units are intentionally outside E0's theorem/lemma class-head
replacement population.

| commit | observed generalization genre | why E0 has no event |
|---|---|---|
| `dfb1dd3875cc` | universe polymorphism | changes universe levels, not a class binder |
| `29764c6a4d41` | instance compatibility | adds explicit `BEq`/`LawfulBEq` assumptions |
| `f9f5e911c45b` | new generic API | adds a theorem rather than changing an old binder |
| `44bb47ffc51b` | new construction | introduces symmetric tensor powers |
| `c9a156995762` | proposition removal | removes measurability hypotheses, not class heads |
| `031dbdd26b0c` | theorem replacement | changes carrier/signature and introduces an auxiliary theorem |
| `584dd88ac2b9` | universe polymorphism | generalizes universe levels |
| `771e087dbef4` | predicate generalization | finite-group assumptions become element-level torsion predicates; declarations are renamed |
| `62a0adf40aa5` | new theorem/API | the message's relaxation is incidental to new results |
| `19879d983a2f` | universe polymorphism | generalizes universe levels |
| `46946047569c` | heterogeneous codomain | changes `𝕜 → 𝕜` to `𝕜 → 𝕜'` and related signatures |
| `8079a741a8bf` | heterogeneous carrier | splits one quiver type into source and target types |
| `e3128c5dc960` | universe polymorphism | generalizes universe levels |
| `fef02eb4cdf4` | prose-only selector hit | “generalizing” occurs in documentation/link text only |
| `091be7a83776` | new enorm API | adds parallel lemmas; the mentioned weakening was already present |
| `d2568da6e252` | proposition generalization | `IsOpenEmbedding` becomes `IsInducing` under a renamed theorem |
| `7c54188c064d` | sort polymorphism | changes `Type` to `Sort` |
| `94db9443fb29` | new future-facing API | adds ordered-vadd mixins; message says they may enable later generalization |
| `5842b73dcd15` | signature/carrier refactor | base-field theorem becomes a free commutative-ring theorem with changed parameters |
| `00acfa1c1874` | new partial-inverse API | adds `Invertible` variants rather than replacing a class head in one theorem |
| `b37ece246ff7` | new constructor/API | “more generally applicable” describes the framework, not a binder diff |
| `6ba1c133d185` | prose-only selector hit | documentation says an earlier PR generalized the theorem |
| `433c27554ead` | heterogeneous scalars | homogeneous tensor operations gain separate base/scalar types |
| `94b541f6d9f7` | theorem replacement | generalizes and renames an inequality lemma; no class-head replacement |
| `bad84cb577f8` | proposition weakening | changes `0 < x` to `0 ≤ x` |
| `cb4d969bd780` | moved/replaced theorem | fills proof stubs and moves a theorem under a changed signature |
| `f328333d3828` | definition/structure refactor | the two raw class moves are non-theorem declarations |
| `d49c7afae11a` | new theorem | adds a more general analogue without changing an old declaration |
| `9a1b545e7b7a` | representation change | redefines `grundyValue` from ordinals to nimbers |
| `5ebeef0d4abd` | additive/multiplicative refactor | introduces multiplicative theorems and derives additive twins |

Observed genre totals:

| genre | commits |
|---|---:|
| universe or sort polymorphism | 5 |
| new theorem, construction, or API | 8 |
| proposition/predicate weakening, rename, or replacement | 8 |
| carrier, codomain, scalar, or representation change | 5 |
| prose-only selector hit | 2 |
| non-theorem or additive/multiplicative refactor | 2 |

This sample says E0 covers one real and common edit shape well, while commit-message
vocabulary spans a much larger space. It supplies no opportunity denominator and therefore
cannot be used to compute recall.
