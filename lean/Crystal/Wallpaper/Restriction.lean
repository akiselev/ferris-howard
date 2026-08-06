/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib

/-!
# W2 — the crystallographic restriction in dimension 2

A finite-order element of `GL (Fin 2) ℤ` has order 1, 2, 3, 4 or 6
(`crystallographic_restriction`).

Proof route. Map the matrix into `Matrix (Fin 2) (Fin 2) ℚ` (order is preserved because the
entrywise cast is an injective ring hom). Over the field ℚ the minimal polynomial exists,
divides `Xⁿ - 1` (the matrix is annihilated by it) and divides the characteristic polynomial,
so it has degree 1 or 2:

* degree 1 forces the matrix to be a rational scalar `c • 1` with `cⁿ = 1`, so `c = ±1` and
  the order divides 2;
* degree 2 forces the minimal polynomial to *be* the characteristic polynomial
  `X² - tX + d` with integer `t`, `d` — so `X² - tX + d ∣ Xⁿ - 1`, and every real root of it
  is a real root of unity, i.e. `±1`.  If the discriminant is positive the two (distinct)
  real roots must be `1` and `-1`, pinning `(t, d) = (0, -1)` and the order divides 2.
  Otherwise `d = 1` and `t ∈ [-2, 2]`; the five cases give `B² = ±1`, `B³ = ±1`, or — for
  `t = ±2` — a square factor `(X ∓ 1)²` inside the squarefree `Xⁿ - 1`, which is absurd.

This is the cyclotomic route's skeleton (minimal-polynomial divisibility into `Xⁿ - 1`,
squarefreeness of `Xⁿ - 1` over ℚ) with the endgame done by explicit quadratic roots rather
than by factoring the minimal polynomial into distinct cyclotomics: Mathlib has the
cyclotomic ingredients individually, but no ready lemma that a squarefree divisor of
`∏ Φ_d` is a product of distinct `Φ_d`s, and rebuilding that factorization costs more than
the two `Real.sqrt` computations it would replace.  No complex numbers, no eigenvectors,
and no semisimplicity are needed.
-/

namespace Crystal.Wallpaper

open Matrix Polynomial

/-- Arithmetic endgame: a positive number dividing 2, 3, 4 or 6 is 1, 2, 3, 4 or 6. -/
private lemma eq_small_of_dvd_small {k : ℕ} (hk : 0 < k)
    (h : k ∣ 2 ∨ k ∣ 3 ∨ k ∣ 4 ∨ k ∣ 6) :
    k = 1 ∨ k = 2 ∨ k = 3 ∨ k = 4 ∨ k = 6 := by
  have hle : k ≤ 6 := by
    rcases h with h | h | h | h <;>
      exact (Nat.le_of_dvd (by norm_num) h).trans (by norm_num)
  interval_cases k <;> rcases h with h | h | h | h <;> omega

/-- The ℚ-side workhorse: a finite-order `2 × 2` rational matrix whose trace and determinant
are integers has order dividing 2, 3, 4 or 6.  (Stated over ℚ, not ℤ, because the minimal
polynomial needs a field; integrality of trace and determinant is all the argument uses.) -/
private theorem orderOf_dvd_of_int_trace_det (B : Matrix (Fin 2) (Fin 2) ℚ) {t d : ℤ}
    (htr : B.trace = (t : ℚ)) (hdet : B.det = (d : ℚ)) (hfin : IsOfFinOrder B) :
    orderOf B ∣ 2 ∨ orderOf B ∣ 3 ∨ orderOf B ∣ 4 ∨ orderOf B ∣ 6 := by
  set n := orderOf B with hn_def
  have hn : n ≠ 0 := hfin.orderOf_pos.ne'
  have hBn : B ^ n = 1 := pow_orderOf_eq_one B
  have haev : aeval B ((X : ℚ[X]) ^ n - 1) = 0 := by
    simp [map_sub, map_pow, aeval_X, hBn]
  have hint : IsIntegral ℚ B :=
    ⟨X ^ n - 1, by simpa using monic_X_pow_sub_C (1 : ℚ) hn, by rwa [← aeval_def]⟩
  have hdvdP : minpoly ℚ B ∣ (X : ℚ[X]) ^ n - 1 := minpoly.dvd ℚ B haev
  have hd1 : 1 ≤ (minpoly ℚ B).natDegree := minpoly.natDegree_pos hint
  have hd2 : (minpoly ℚ B).natDegree ≤ 2 := by
    have h := Polynomial.natDegree_le_of_dvd (minpoly_dvd_charpoly B)
      (charpoly_monic B).ne_zero
    rwa [charpoly_natDegree_eq_dim, Fintype.card_fin] at h
  rcases (by omega : (minpoly ℚ B).natDegree = 1 ∨ (minpoly ℚ B).natDegree = 2) with
    hdeg | hdeg
  · -- Degree 1: B is a rational scalar, and a scalar of finite order is ±1.
    have hX := (minpoly.monic hint).eq_X_add_C hdeg
    have h0 := minpoly.aeval ℚ B
    rw [hX] at h0
    simp only [map_add, aeval_X, aeval_C, Algebra.algebraMap_eq_smul_one] at h0
    rw [add_eq_zero_iff_eq_neg] at h0
    have hB : B = (-(minpoly ℚ B).coeff 0) • 1 := by rw [neg_smul]; exact h0
    set c : ℚ := -(minpoly ℚ B).coeff 0 with hc_def
    have hcn : c ^ n = 1 := by
      have h1 : (c ^ n) • (1 : Matrix (Fin 2) (Fin 2) ℚ) = 1 := by
        calc (c ^ n) • (1 : Matrix (Fin 2) (Fin 2) ℚ)
            = (c • (1 : Matrix (Fin 2) (Fin 2) ℚ)) ^ n := by rw [_root_.smul_pow, one_pow]
          _ = B ^ n := by rw [← hB]
          _ = 1 := hBn
      simpa using Matrix.ext_iff.mpr h1 0 0
    have hc2 : c ^ 2 = 1 := by
      rcases (pow_eq_one_iff_of_ne_zero hn).mp hcn with h | ⟨h, _⟩ <;> rw [h] <;> norm_num
    have hB2 : B ^ 2 = 1 := by rw [hB, _root_.smul_pow, one_pow, hc2, one_smul]
    exact Or.inl (orderOf_dvd_of_pow_eq_one hB2)
  · -- Degree 2: the minimal polynomial is the characteristic polynomial.
    have hPc : minpoly ℚ B = B.charpoly :=
      Polynomial.eq_of_dvd_of_natDegree_le_of_leadingCoeff (minpoly_dvd_charpoly B)
        (by rw [charpoly_natDegree_eq_dim, Fintype.card_fin, hdeg])
        (by rw [(minpoly.monic hint).leadingCoeff, (charpoly_monic B).leadingCoeff])
    have hchar : B.charpoly = X ^ 2 - C (t : ℚ) * X + C (d : ℚ) := by
      rw [charpoly_fin_two, htr, hdet]
    have hdvd : B.charpoly ∣ (X : ℚ[X]) ^ n - 1 := hPc ▸ hdvdP
    -- A finite-order matrix has determinant ±1 (det is multiplicative).
    have hdet1 : d = 1 ∨ d = -1 := by
      have h1 : (d : ℚ) ^ n = 1 := by
        have h := congrArg Matrix.det hBn
        rwa [Matrix.det_pow, Matrix.det_one, hdet] at h
      have h2 : d ^ n = 1 := by exact_mod_cast h1
      rcases (pow_eq_one_iff_of_ne_zero hn).mp h2 with h | ⟨h, _⟩
      exacts [Or.inl h, Or.inr h]
    -- Any real root of the characteristic polynomial is a real nth root of unity, so ±1.
    have key : ∀ r : ℝ, r ^ 2 - (t : ℝ) * r + (d : ℝ) = 0 → r = 1 ∨ r = -1 := by
      intro r hr
      have hroot : aeval r B.charpoly = 0 := by
        rw [hchar]
        simp only [map_add, map_sub, map_mul, map_pow, aeval_X, aeval_C, eq_ratCast,
          Rat.cast_intCast]
        linear_combination hr
      have hrn : r ^ n = 1 := by
        obtain ⟨q, hq⟩ := hdvd
        have h2 := congrArg (aeval r) hq
        simp only [map_sub, map_pow, map_one, map_mul, aeval_X, hroot, zero_mul] at h2
        linarith
      rcases (pow_eq_one_iff_of_ne_zero hn).mp hrn with h | ⟨h, _⟩
      exacts [Or.inl h, Or.inr h]
    -- Cayley–Hamilton in explicit 2×2 form.
    have hCH : B ^ 2 = (t : ℚ) • B - (d : ℚ) • 1 := by
      have h0 := aeval_self_charpoly B
      rw [hchar] at h0
      simp only [map_add, map_sub, map_mul, map_pow, aeval_X, aeval_C,
        Algebra.algebraMap_eq_smul_one, smul_mul_assoc, one_mul] at h0
      rw [eq_sub_iff_add_eq]
      rw [sub_add_eq_add_sub, sub_eq_zero] at h0
      exact h0
    rcases le_or_gt ((t : ℝ) ^ 2 - 4 * (d : ℝ)) 0 with hle | hpos
    · -- Nonpositive discriminant: d = 1 (else the discriminant is t² + 4 > 0) and |t| ≤ 2.
      have hd1' : d = 1 := by
        rcases hdet1 with h | h
        · exact h
        · exfalso; rw [h] at hle; push_cast at hle; nlinarith [sq_nonneg (t : ℝ)]
      subst hd1'
      push_cast at hle
      have hlb : -2 ≤ t := by
        exact_mod_cast (by nlinarith [sq_nonneg ((t : ℝ) + 2)] : (-2 : ℝ) ≤ (t : ℝ))
      have hub : t ≤ 2 := by
        exact_mod_cast (by nlinarith [sq_nonneg ((t : ℝ) - 2)] : (t : ℝ) ≤ (2 : ℝ))
      -- Squarefreeness of Xⁿ - 1, needed to kill the double-root cases t = ±2.
      have hsf : Squarefree ((X : ℚ[X]) ^ n - 1) := by
        have h := Polynomial.separable_X_pow_sub_C (1 : ℚ) (Nat.cast_ne_zero.mpr hn)
          one_ne_zero
        rw [Polynomial.C_1] at h
        exact h.squarefree
      interval_cases t
      · -- t = -2: charpoly = (X + 1)² divides the squarefree Xⁿ - 1 — impossible.
        exfalso
        have hdvd2 : ((X : ℚ[X]) - C (-1 : ℚ)) * ((X : ℚ[X]) - C (-1 : ℚ)) ∣
            (X : ℚ[X]) ^ n - 1 := by
          refine (dvd_of_eq ?_).trans hdvd
          rw [hchar]
          push_cast
          simp only [map_neg, map_one, map_ofNat]
          ring
        exact Polynomial.not_isUnit_X_sub_C (-1 : ℚ) (hsf _ hdvd2)
      · -- t = -1: B³ = 1.
        have hCH' : B ^ 2 = -B - 1 := by
          push_cast at hCH; simpa [neg_smul, one_smul] using hCH
        have hB3 : B ^ 3 = 1 := by
          rw [show (3 : ℕ) = 2 + 1 from rfl, pow_succ, hCH', sub_mul, neg_mul, one_mul,
            ← pow_two, hCH']
          abel
        exact Or.inr (Or.inl (orderOf_dvd_of_pow_eq_one hB3))
      · -- t = 0: B² = -1, so B⁴ = 1.
        have hCH' : B ^ 2 = -1 := by
          push_cast at hCH; simpa using hCH
        have hB4 : B ^ 4 = 1 := by
          rw [show (4 : ℕ) = 2 * 2 from rfl, pow_mul, hCH', neg_one_sq]
        exact Or.inr (Or.inr (Or.inl (orderOf_dvd_of_pow_eq_one hB4)))
      · -- t = 1: B³ = -1, so B⁶ = 1.
        have hCH' : B ^ 2 = B - 1 := by
          push_cast at hCH; simpa using hCH
        have hB3 : B ^ 3 = -1 := by
          rw [show (3 : ℕ) = 2 + 1 from rfl, pow_succ, hCH', sub_mul, one_mul, ← pow_two,
            hCH']
          abel
        have hB6 : B ^ 6 = 1 := by
          rw [show (6 : ℕ) = 3 * 2 from rfl, pow_mul, hB3, neg_one_sq]
        exact Or.inr (Or.inr (Or.inr (orderOf_dvd_of_pow_eq_one hB6)))
      · -- t = 2: charpoly = (X - 1)² divides the squarefree Xⁿ - 1 — impossible.
        exfalso
        have hdvd2 : ((X : ℚ[X]) - C (1 : ℚ)) * ((X : ℚ[X]) - C (1 : ℚ)) ∣
            (X : ℚ[X]) ^ n - 1 := by
          refine (dvd_of_eq ?_).trans hdvd
          rw [hchar]
          push_cast
          simp only [map_one, map_ofNat]
          ring
        exact Polynomial.not_isUnit_X_sub_C (1 : ℚ) (hsf _ hdvd2)
    · -- Positive discriminant: two distinct real roots, both ±1, so they are 1 and -1;
      -- Vieta then pins t = 0, d = -1, and B² = 1.
      set s : ℝ := Real.sqrt ((t : ℝ) ^ 2 - 4 * (d : ℝ)) with hs_def
      have hs2 : s ^ 2 = (t : ℝ) ^ 2 - 4 * (d : ℝ) := Real.sq_sqrt hpos.le
      have hsp : 0 < s := Real.sqrt_pos.mpr hpos
      have hr1 := key (((t : ℝ) + s) / 2) (by linear_combination hs2 / 4)
      have hr2 := key (((t : ℝ) - s) / 2) (by linear_combination hs2 / 4)
      have htd : (t : ℝ) = 0 ∧ (d : ℝ) = -1 := by
        rcases hr1 with h1 | h1 <;> rcases hr2 with h2 | h2
        · exfalso; linarith
        · have hseq : s = 2 := by linarith
          have hteq : (t : ℝ) = 0 := by linarith
          refine ⟨hteq, ?_⟩
          rw [hseq, hteq] at hs2
          norm_num at hs2
          linarith
        · exfalso; linarith
        · exfalso; linarith
      have htz : t = 0 := by exact_mod_cast htd.1
      have hdz : d = -1 := by exact_mod_cast htd.2
      have hB2 : B ^ 2 = 1 := by
        rw [hCH, htz, hdz]
        norm_num
      exact Or.inl (orderOf_dvd_of_pow_eq_one hB2)

/-- **The crystallographic restriction, dimension 2 (W2).**  A finite-order element of
`GL (Fin 2) ℤ` has order 1, 2, 3, 4 or 6.  This is the arithmetic input to the wallpaper
census: it is why only 2-, 3-, 4- and 6-fold rotations can appear in a point group. -/
theorem crystallographic_restriction (A : GL (Fin 2) ℤ) (hA : IsOfFinOrder A) :
    orderOf A = 1 ∨ orderOf A = 2 ∨ orderOf A = 3 ∨ orderOf A = 4 ∨ orderOf A = 6 := by
  -- Push the matrix into ℚ; the entrywise cast is injective, so the order is unchanged.
  have hinj : Function.Injective ((Int.castRingHom ℚ).mapMatrix :
      Matrix (Fin 2) (Fin 2) ℤ →+* Matrix (Fin 2) (Fin 2) ℚ) := by
    intro M N h
    ext i j
    have h' := Matrix.ext_iff.mpr h i j
    simp only [RingHom.mapMatrix_apply, Matrix.map_apply, Int.coe_castRingHom] at h'
    exact_mod_cast h'
  set B : Matrix (Fin 2) (Fin 2) ℚ :=
    (Int.castRingHom ℚ).mapMatrix (A : Matrix (Fin 2) (Fin 2) ℤ) with hB_def
  have horder : orderOf B = orderOf A := by
    have h1 : orderOf ((Int.castRingHom ℚ).mapMatrix.toMonoidHom
        (A : Matrix (Fin 2) (Fin 2) ℤ)) = orderOf (A : Matrix (Fin 2) (Fin 2) ℤ) :=
      orderOf_injective (Int.castRingHom ℚ).mapMatrix.toMonoidHom
        (fun _ _ hab => hinj hab) _
    exact h1.trans orderOf_units
  have hfinB : IsOfFinOrder B := by
    obtain ⟨k, hk, hAk⟩ := isOfFinOrder_iff_pow_eq_one.mp hA
    refine isOfFinOrder_iff_pow_eq_one.mpr ⟨k, hk, ?_⟩
    calc B ^ k
        = (Int.castRingHom ℚ).mapMatrix ((A : Matrix (Fin 2) (Fin 2) ℤ) ^ k) := by
          rw [hB_def, map_pow]
      _ = 1 := by rw [← Units.val_pow_eq_pow_val, hAk, Units.val_one, map_one]
  have htr : B.trace = (((A : Matrix (Fin 2) (Fin 2) ℤ).trace : ℤ) : ℚ) := by
    rw [hB_def, RingHom.mapMatrix_apply]
    exact (AddMonoidHom.map_trace (Int.castRingHom ℚ) _).symm
  have hdet : B.det = (((A : Matrix (Fin 2) (Fin 2) ℤ).det : ℤ) : ℚ) := by
    rw [hB_def, ← RingHom.map_det]
    rfl
  have hdvd : orderOf A ∣ 2 ∨ orderOf A ∣ 3 ∨ orderOf A ∣ 4 ∨ orderOf A ∣ 6 := by
    have h := orderOf_dvd_of_int_trace_det B htr hdet hfinB
    rwa [horder] at h
  exact eq_small_of_dvd_small hA.orderOf_pos hdvd

/-! ## Sanity witnesses

The bound is tight at 4 and 6: the two matrices below are honest elements of `GL (Fin 2) ℤ`
of orders 6 and 4, so the theorem's hypothesis is satisfiable and its conclusion's largest
cases are realized.  (An empty hypothesis would make the theorem vacuously true — these
examples are the guard against that.) -/

/-- Closing `M = 1` through the `!![..]` literal: `Matrix.one_fin_two` does not fire as a
simp lemma against the ring's `1` here (the `One` instances unify only definitionally), so
the identification is done once, term-level. -/
private lemma eq_one_of_eq_fin_two {M : Matrix (Fin 2) (Fin 2) ℤ}
    (h : M = !![1, 0; 0, 1]) : M = 1 :=
  h.trans Matrix.one_fin_two.symm

/-- An order-6 element of `GL (Fin 2) ℤ` (a hexagonal rotation in the lattice basis). -/
def rot6 : GL (Fin 2) ℤ :=
  ⟨!![1, -1; 1, 0], !![0, 1; -1, 1],
    eq_one_of_eq_fin_two (by norm_num [Matrix.mul_fin_two]),
    eq_one_of_eq_fin_two (by norm_num [Matrix.mul_fin_two])⟩

/-- An order-4 element of `GL (Fin 2) ℤ` (the quarter turn). -/
def rot4 : GL (Fin 2) ℤ :=
  ⟨!![0, -1; 1, 0], !![0, 1; -1, 0],
    eq_one_of_eq_fin_two (by norm_num [Matrix.mul_fin_two]),
    eq_one_of_eq_fin_two (by norm_num [Matrix.mul_fin_two])⟩

private lemma rot6_val_sq :
    (!![1, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = !![0, -1; 1, -1] := by
  rw [pow_two]; norm_num [Matrix.mul_fin_two]

private lemma rot6_val_cube :
    (!![1, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 3 = !![-1, 0; 0, -1] := by
  rw [show (3 : ℕ) = 2 + 1 from rfl, pow_succ, rot6_val_sq]
  norm_num [Matrix.mul_fin_two]

private lemma rot4_val_sq :
    (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = !![-1, 0; 0, -1] := by
  rw [pow_two]; norm_num [Matrix.mul_fin_two]

theorem rot6_pow_six : rot6 ^ 6 = 1 := by
  apply Units.ext
  rw [Units.val_pow_eq_pow_val, Units.val_one]
  show (!![1, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 6 = 1
  refine eq_one_of_eq_fin_two ?_
  rw [show (6 : ℕ) = 3 * 2 from rfl, pow_mul, rot6_val_cube, pow_two]
  norm_num [Matrix.mul_fin_two]

theorem rot4_pow_four : rot4 ^ 4 = 1 := by
  apply Units.ext
  rw [Units.val_pow_eq_pow_val, Units.val_one]
  show (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 4 = 1
  refine eq_one_of_eq_fin_two ?_
  rw [show (4 : ℕ) = 2 * 2 from rfl, pow_mul, rot4_val_sq, pow_two]
  norm_num [Matrix.mul_fin_two]

theorem orderOf_rot6 : orderOf rot6 = 6 := by
  have hfin : IsOfFinOrder rot6 :=
    isOfFinOrder_iff_pow_eq_one.mpr ⟨6, by norm_num, rot6_pow_six⟩
  have hdvd := orderOf_dvd_of_pow_eq_one rot6_pow_six
  -- Exclude the proper divisors 1, 2, 3 by inspecting one matrix entry of each power.
  have h2 : ¬ orderOf rot6 ∣ 2 := by
    rw [orderOf_dvd_iff_pow_eq_one]
    intro h
    have hv := congrArg Units.val h
    rw [Units.val_pow_eq_pow_val, Units.val_one,
      show (rot6 : Matrix (Fin 2) (Fin 2) ℤ) = !![1, -1; 1, 0] from rfl,
      rot6_val_sq] at hv
    have h00 := Matrix.ext_iff.mpr hv 0 0
    simp at h00
  have h3 : ¬ orderOf rot6 ∣ 3 := by
    rw [orderOf_dvd_iff_pow_eq_one]
    intro h
    have hv := congrArg Units.val h
    rw [Units.val_pow_eq_pow_val, Units.val_one,
      show (rot6 : Matrix (Fin 2) (Fin 2) ℤ) = !![1, -1; 1, 0] from rfl,
      rot6_val_cube] at hv
    have h00 := Matrix.ext_iff.mpr hv 0 0
    simp at h00
  have hle := Nat.le_of_dvd (by norm_num) hdvd
  have hpos := hfin.orderOf_pos
  set k := orderOf rot6
  interval_cases k <;> omega

theorem orderOf_rot4 : orderOf rot4 = 4 := by
  have hfin : IsOfFinOrder rot4 :=
    isOfFinOrder_iff_pow_eq_one.mpr ⟨4, by norm_num, rot4_pow_four⟩
  have hdvd := orderOf_dvd_of_pow_eq_one rot4_pow_four
  have h2 : ¬ orderOf rot4 ∣ 2 := by
    rw [orderOf_dvd_iff_pow_eq_one]
    intro h
    have hv := congrArg Units.val h
    rw [Units.val_pow_eq_pow_val, Units.val_one,
      show (rot4 : Matrix (Fin 2) (Fin 2) ℤ) = !![0, -1; 1, 0] from rfl,
      rot4_val_sq] at hv
    have h00 := Matrix.ext_iff.mpr hv 0 0
    simp at h00
  have hle := Nat.le_of_dvd (by norm_num) hdvd
  have hpos := hfin.orderOf_pos
  set k := orderOf rot4
  interval_cases k <;> omega

/-- The main theorem instantiates on a genuine order-6 element — the hypothesis is not
vacuous, and 6 is attained. -/
example : orderOf rot6 = 1 ∨ orderOf rot6 = 2 ∨ orderOf rot6 = 3 ∨ orderOf rot6 = 4 ∨
    orderOf rot6 = 6 :=
  crystallographic_restriction rot6
    (isOfFinOrder_iff_pow_eq_one.mpr ⟨6, by norm_num, rot6_pow_six⟩)

end Crystal.Wallpaper
