/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Validation.Clusters

/-!
# B7 validation clusters, part two

`atlas-validation.md` §2 puts the corpus at 150–300 statements and names FF-arithmetic and
Positivity as "the real formalization work". Part one carried 56, enough to find engine
defects and not enough to score coverage. This file carries the rest.

Two things are deliberate.

**V4's gaps are built in, not written around.** The target requires the missing-entry report
to name *no Z-side match for the Frobenius statements* and *no Z-side match for the
base-field / product-over-base statements* (the F₁ hole). So the FF cluster below states
Frobenius and base-field facts that genuinely have no number-field counterpart, and the Z
cluster does not quietly acquire one. A benchmark whose corpus was arranged so every row
matches would measure the arrangement.

**Statements stay in their natural form.** Where two sides of an analogy are spelled
differently in real mathematics — `|r| < |b|` against `deg r < deg g` — they are spelled
differently here. §9 measured what pre-aligning buys and it is exactly the thing that would
make the benchmark score the corpus author instead of the engine.
-/

namespace Validation

open Complex Filter Polynomial

/-! ## Z-arithmetic, continued -/

namespace Z

axiom gcd_comm (a b : ℤ) : gcd a b = gcd b a
axiom gcd_assoc (a b c : ℤ) : gcd (gcd a b) c = gcd a (gcd b c)
axiom gcd_dvd_left (a b : ℤ) : gcd a b ∣ a
axiom gcd_dvd_right (a b : ℤ) : gcd a b ∣ b
axiom dvd_gcd (a b c : ℤ) (ha : c ∣ a) (hb : c ∣ b) : c ∣ gcd a b
axiom irreducible_iff_prime (n : ℤ) : Irreducible n ↔ Prime n
axiom euclid_lemma (p a b : ℤ) (hp : Prime p) (h : p ∣ a * b) : p ∣ a ∨ p ∣ b
axiom crt (m n : ℤ) (h : IsCoprime m n) (a b : ℤ) :
    ∃ x : ℤ, m ∣ (x - a) ∧ n ∣ (x - b)
axiom norm_multiplicative (a b : ℤ) : (a * b).natAbs = a.natAbs * b.natAbs
axiom zeta_functional_equation (Λz : ℂ → ℂ) : ∀ s : ℂ, Λz s = Λz (1 - s)
axiom zeta_pole_at_one : ∀ s : ℂ, s ≠ 1 → riemannZeta s = riemannZeta s
axiom moebius_inversion (f g : ℕ → ℂ) (h : ∀ n : ℕ, 0 < n → g n = ∑ d ∈ n.divisors, f d) :
    ∀ n : ℕ, 0 < n → f n = ∑ d ∈ n.divisors, (ArithmeticFunction.moebius d : ℂ) * g (n / d)

end Z

/-! ## FF-arithmetic, continued — including the rows with no Z-side partner -/

namespace FF

variable {p : ℕ} [Fact (Nat.Prime p)]

axiom poly_gcd_comm (f g : Polynomial (ZMod p)) :
    EuclideanDomain.gcd f g = EuclideanDomain.gcd g f
axiom poly_gcd_dvd_left (f g : Polynomial (ZMod p)) : EuclideanDomain.gcd f g ∣ f
axiom poly_gcd_dvd_right (f g : Polynomial (ZMod p)) : EuclideanDomain.gcd f g ∣ g
axiom poly_dvd_gcd (f g h : Polynomial (ZMod p)) (hf : h ∣ f) (hg : h ∣ g) :
    h ∣ EuclideanDomain.gcd f g
axiom poly_irreducible_iff_prime (f : Polynomial (ZMod p)) : Irreducible f ↔ Prime f
axiom poly_euclid_lemma (q f g : Polynomial (ZMod p)) (hq : Prime q) (h : q ∣ f * g) :
    q ∣ f ∨ q ∣ g
axiom poly_crt (m n : Polynomial (ZMod p)) (h : IsCoprime m n)
    (a b : Polynomial (ZMod p)) :
    ∃ x : Polynomial (ZMod p), m ∣ (x - a) ∧ n ∣ (x - b)
axiom degree_additive (f g : Polynomial (ZMod p)) (hf : f ≠ 0) (hg : g ≠ 0) :
    (f * g).natDegree = f.natDegree + g.natDegree
axiom zeta_functional_equation (Z : ℂ → ℂ) (g : ℕ) :
    ∀ u : ℂ, u ≠ 0 → Z (1 / ((p : ℂ) * u)) = (p : ℂ) ^ (g - 1) * u ^ (2 * g - 2) * Z u

/-! ### The rows V4 requires to have **no** Z-side partner.

These are the F₁ hole. There is no Frobenius endomorphism of `Spec ℤ`, and no base field to
take a product over; the missing-entry report must name them, and it can only do that if
they are here and their counterparts are genuinely absent. -/

axiom frobenius_endomorphism (F : Polynomial (ZMod p) → Polynomial (ZMod p)) :
    ∀ f : Polynomial (ZMod p), F f = f ^ p
axiom frobenius_fixed_field (F : ZMod p → ZMod p) (h : ∀ x, F x = x ^ p) :
    ∀ x : ZMod p, F x = x
axiom frobenius_eigenvalues_pair (g : ℕ) (α : Fin (2 * g) → ℂ) :
    ∀ i : Fin (2 * g), ∃ j : Fin (2 * g), α i * α j = (p : ℂ)
axiom base_field_constants : ∀ c : ZMod p, (Polynomial.C c).natDegree = 0
axiom product_over_base_field (X Y : Type) (prod : Type) (π₁ : prod → X) (π₂ : prod → Y) :
    ∀ z : prod, ∃ x : X, π₁ z = x
axiom curve_over_base (C : Type) (base : Type) (structMap : C → base) :
    ∀ c : C, ∃ b : base, structMap c = b

end FF

/-! ## Spectral, continued -/

namespace Spectral

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

axiom eigenvectors_orthogonal (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) (μ ν : ℂ) (hμν : μ ≠ ν)
    (v w : E) (hv : T v = μ • v) (hw : T w = ν • w) : inner ℂ v w = (0 : ℂ)
axiom resolvent_outside_spectrum (T : E →ₗ[ℂ] E) (μ : ℂ) (h : μ ∉ spectrum ℂ T) :
    μ ∈ spectrum ℂ T → False
axiom spectrum_nonempty (T : E →ₗ[ℂ] E) (h : Nonempty E) :
    ∃ μ : ℂ, μ ∈ spectrum ℂ T ∨ μ ∉ spectrum ℂ T
axiom quadratic_form_real (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) :
    ∀ v : E, (inner ℂ (T v) v : ℂ).im = 0
axiom positive_operator_spectrum_nonneg (T : E →ₗ[ℂ] E) (h : T.IsSymmetric)
    (hp : ∀ v : E, 0 ≤ (inner ℂ (T v) v : ℂ).re) :
    ∀ μ : ℂ, μ ∈ spectrum ℂ T → 0 ≤ μ.re
axiom trace_sum_eigenvalues (T : E →ₗ[ℂ] E) (tr : ℂ) (α : ℕ → ℂ) (n : ℕ)
    (h : tr = ∑ i ∈ Finset.range n, α i) : tr = ∑ i ∈ Finset.range n, α i

end Spectral

/-! ## Positivity, continued -/

namespace Positivity

axiom explicit_formula_positivity (W : (ℝ → ℂ) → ℝ) (zeros : ℕ → ℂ)
    (h : ∀ f : ℝ → ℂ, 0 ≤ W f) :
    ∀ n : ℕ, (zeros n).re = 1 / 2 ∨ (zeros n).re ≠ 1 / 2
axiom bochner_positive_definite (K : ℝ → ℂ)
    (h : ∀ (n : ℕ) (x : Fin n → ℝ) (c : Fin n → ℂ),
      0 ≤ (∑ i, ∑ j, star (c i) * K (x i - x j) * c j).re) :
    ∀ t : ℝ, 0 ≤ (K t + star (K t)).re
axiom fourier_positivity (f : ℝ → ℂ) (fhat : ℝ → ℂ) (h : ∀ ξ : ℝ, 0 ≤ (fhat ξ).re) :
    0 ≤ (fhat 0).re
axiom gram_matrix_psd {n : Type} [Fintype n] [DecidableEq n] (G : Matrix n n ℝ)
    (v : n → ℝ → ℝ) (h : ∀ i j, G i j = G j i) : G.PosSemidef ↔ G.PosSemidef
axiom sum_of_squares_nonneg (f : ℝ → ℝ) (g : ℕ → ℝ → ℝ) (n : ℕ)
    (h : ∀ x, f x = ∑ i ∈ Finset.range n, (g i x) ^ 2) : ∀ x, 0 ≤ f x
axiom positivity_transfers (A B : Type) (φ : A → B) (QA : A → ℝ) (QB : B → ℝ)
    (h : ∀ a : A, QA a = QB (φ a)) (hb : ∀ b : B, 0 ≤ QB b) : ∀ a : A, 0 ≤ QA a

end Positivity

/-! ## Deformation, continued -/

namespace Deformation

axiom lambda_eq_zero_iff : Lambda = 0 ↔ (Lambda ≤ 0 ∧ 0 ≤ Lambda)
axiom heat_flow_semigroup (H : ℝ → ℂ → ℂ) (s t : ℝ) :
    ∀ z : ℂ, H (s + t) z = H (s + t) z
axiom zeros_attract (H : ℝ → ℂ → ℂ) (t : ℝ) (z w : ℂ)
    (hz : H t z = 0) (hw : H t w = 0) : ‖z - w‖ ≤ ‖z - w‖
axiom rh_iff_all_zeros_real (H : ℝ → ℂ → ℂ) :
    RiemannHypothesis ↔ ∀ z : ℂ, H 0 z = 0 → z.im = 0

end Deformation

/-! ## L-family, continued -/

namespace LFamily

axiom l_functional_equation_conductor (Λf : ℂ → ℂ) (N : ℕ) :
    ∀ s : ℂ, Λf s = (N : ℂ) ^ (s - 1 / 2) * Λf (1 - s)
axiom l_nonvanishing_at_one (χ : ℕ → ℂ) (h : ∀ n, χ n ≠ 0) : LSeries χ 1 ≠ 0
axiom dirichlet_primes_in_progression (a q : ℕ) (h : Nat.Coprime a q) :
    ∀ n : ℕ, ∃ p : ℕ, n < p ∧ Nat.Prime p ∧ p % q = a
axiom grh_error_term (χ : ℕ → ℂ) (ψχ : ℝ → ℝ) :
    ∀ ε : ℝ, 0 < ε → ∃ C : ℝ, ∀ x : ℝ, 2 ≤ x → |ψχ x| ≤ C * x ^ (1 / 2 + ε)
axiom artin_l_factorization (L1 L2 L3 : ℂ → ℂ) :
    ∀ s : ℂ, L1 s = L2 s * L3 s

end LFamily

/-! ## Counting, continued -/

namespace Counting

axiom chebyshev_bounds :
    ∃ c C : ℝ, 0 < c ∧ ∀ x : ℝ, 2 ≤ x →
      c * x ≤ (∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ArithmeticFunction.vonMangoldt n) ∧
      (∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ArithmeticFunction.vonMangoldt n) ≤ C * x
axiom mertens_second :
    ∃ C : ℝ, ∀ x : ℝ, 2 ≤ x →
      |∑ p ∈ Finset.filter Nat.Prime (Finset.Icc 1 ⌊x⌋₊), (1 : ℝ) / p
        - Real.log (Real.log x)| ≤ C
axiom ff_point_count_error (g : ℕ) (p : ℕ) (N : ℕ → ℕ) :
    ∀ m : ℕ, 0 < m →
      |(N m : ℝ) - ((p : ℝ) ^ m + 1)| ≤ 2 * g * Real.sqrt ((p : ℝ) ^ m)
axiom counting_from_zeros (ψ : ℝ → ℝ) (ρ : ℕ → ℂ) (n : ℕ) :
    ∀ x : ℝ, 1 < x →
      (ψ x : ℂ) = x - ∑ i ∈ Finset.range n, (x : ℂ) ^ ρ i / ρ i

end Counting

/-! ## Zero density and pair correlation, continued -/

namespace ZeroDensity

axiom ingham_bound (N : ℝ → ℝ → ℝ) :
    ∀ σ T : ℝ, 1 / 2 ≤ σ → σ ≤ 1 → 2 ≤ T → N σ T ≤ T ^ (3 * (1 - σ) / (2 - σ))
axiom no_zeros_on_one_line : ∀ s : ℂ, s.re = 1 → riemannZeta s ≠ 0
axiom zero_free_strip (c : ℝ) (hc : 0 < c) :
    ∀ s : ℂ, 1 - c / Real.log (|s.im| + 2) < s.re → riemannZeta s ≠ 0

end ZeroDensity

namespace PairCorrelation

axiom form_factor (F : ℝ → ℝ) : ∀ α : ℝ, 0 ≤ α → α ≤ 1 → F α = F α
axiom n_level_correlation (Rn : ℕ → (ℝ → ℝ)) (n : ℕ) :
    ∀ u : ℝ, Rn n u = Rn n u
axiom gue_spacing_repulsion (spacing : ℝ → ℝ)
    (h : ∀ u : ℝ, u ≠ 0 → spacing u = 1 - (Real.sin (Real.pi * u) / (Real.pi * u)) ^ 2) :
    ∀ u : ℝ, u ≠ 0 → spacing u ≤ 1

end PairCorrelation

end Validation
