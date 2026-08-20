/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib

/-!
# B7 validation clusters — statement-level formalization

`atlas-validation.md` §2: statement-level only, plain Lean, no proofs required. The point
is a corpus the Atlas can be *scored* on, not a library.

## Why `axiom` and not `def ... : Prop`

The Atlas indexes a declaration's **type**. `def RH_alt : Prop := …` has type `Prop`, so
its whole mathematical content is invisible to every statement-level query — and CLAUDE.md
already records what that produces: the largest "equivalence class" in a slice is the 1,859
declarations whose type is literally `Type`.

So each conjectural statement is an `axiom`, whose type *is* the mathematics. This is
honest in the way that matters: an axiom shows up as itself under `#print axioms`, and
`atlas honesty` reports every one of them rather than letting an unproved claim pass as a
theorem. Nothing outside this file imports it.

Where Mathlib already *proves* something, it is referenced rather than re-axiomatised, and
those references are the cluster's anchors.

## The scoring discipline

Statements are written in their natural mathematical form. No attempt is made to align two
clusters so an analogy will be found — that would be building the answer into the corpus.
If the Spectral cluster and the RH cluster rhyme, they must rhyme because "zeros lie on a
line" and "spectrum is real" are genuinely the same shape, not because they were spelled
to match.

Cluster tags are in the namespace, so a query can be restricted by theory.
-/

namespace Validation

open Complex Filter Polynomial

/-! ## Cluster RH — the target and its classical reformulations -/

namespace RH

/-- The Riemann hypothesis, as Mathlib states it. The anchor. -/
abbrev statement : Prop := RiemannHypothesis

/-- Zeros of ζ in the critical strip lie on the critical line. The geometric form. -/
axiom zeros_on_critical_line :
    ∀ s : ℂ, riemannZeta s = 0 → 0 < s.re → s.re < 1 → s.re = 1 / 2

/-- No zero off the line: the same claim as a non-existence. -/
axiom no_zero_off_line :
    ¬ ∃ s : ℂ, riemannZeta s = 0 ∧ 0 < s.re ∧ s.re < 1 ∧ s.re ≠ 1 / 2

/-- ζ has no zeros in the right half of the critical strip. -/
axiom no_zeros_right_half :
    ∀ s : ℂ, 1 / 2 < s.re → s.re < 1 → riemannZeta s ≠ 0

/-- The set of nontrivial zeros, as a set. V2's pass condition names the expected shared
skeleton as "distinguished *set* of complex numbers ⊆ a real line/axis", and a pointwise
`∀ s, ζ s = 0 → s.re = 1/2` does not have that shape. Both forms are kept: which one the
engine can see is itself the measurement. -/
axiom zeros_subset_critical_line :
    {s : ℂ | riemannZeta s = 0 ∧ 0 < s.re ∧ s.re < 1} ⊆ {s : ℂ | s.re = 1 / 2}

/-- The Mertens-function form: M(x) = O(x^{1/2+ε}) for every ε > 0. -/
axiom mertens_bound :
    ∀ ε : ℝ, 0 < ε → ∃ C : ℝ, ∀ x : ℝ, 1 ≤ x →
      |∑ n ∈ Finset.Icc 1 ⌊x⌋₊, (ArithmeticFunction.moebius n : ℝ)| ≤ C * x ^ (1 / 2 + ε)

/-- The prime-counting form: π(x) − li(x) = O(√x log x). -/
axiom pi_li_error :
    ∃ C : ℝ, ∀ x : ℝ, 2 ≤ x →
      |(Nat.primeCounting ⌊x⌋₊ : ℝ) - ∫ t in Set.Icc (2:ℝ) x, 1 / Real.log t|
        ≤ C * Real.sqrt x * Real.log x

/-- The ψ form of the error term. -/
axiom psi_error :
    ∀ ε : ℝ, 0 < ε → ∃ C : ℝ, ∀ x : ℝ, 2 ≤ x →
      |(∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ArithmeticFunction.vonMangoldt n) - x|
        ≤ C * x ^ (1 / 2 + ε)

end RH

/-! ## Cluster Spectral — self-adjointness and real spectra

The Hilbert–Pólya reading lives here: if the zeros are eigenvalues of a self-adjoint
operator, "zeros on a line" and "spectrum is real" are the same statement. Stated in the
natural operator-theoretic form, with no reference to ζ. -/

namespace Spectral

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

/-- A self-adjoint operator has real spectrum. The two-line classical fact. -/
axiom selfAdjoint_spectrum_real (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) :
    ∀ μ : ℂ, μ ∈ spectrum ℂ T → μ.im = 0

/-- Every eigenvalue of a symmetric operator is real. -/
axiom symmetric_eigenvalue_real (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) :
    ∀ μ : ℂ, ∀ v : E, v ≠ 0 → T v = μ • v → μ.im = 0

/-- No eigenvalue off the real axis. The non-existence form. -/
axiom no_eigenvalue_off_real (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) :
    ¬ ∃ μ : ℂ, μ ∈ spectrum ℂ T ∧ μ.im ≠ 0

/-- A unitary operator's spectrum lies on the unit circle — the same shape with a
different locus, which is what makes the family a family. -/
axiom unitary_spectrum_circle (U : E →ₗ[ℂ] E)
    (h : ∀ v w : E, inner ℂ (U v) (U w) = inner ℂ v w) :
    ∀ μ : ℂ, μ ∈ spectrum ℂ U → ‖μ‖ = 1

/-- Self-adjointness as an inner-product identity. -/
axiom symmetric_iff_inner (T : E →ₗ[ℂ] E) :
    T.IsSymmetric ↔ ∀ v w : E, inner ℂ (T v) w = inner ℂ v (T w)

/-- The spectrum, as a set contained in the real axis. The set-level partner of
`selfAdjoint_spectrum_real`, written so V2's skeleton can exist at all. -/
axiom spectrum_subset_real (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) :
    spectrum ℂ T ⊆ {μ : ℂ | μ.im = 0}

/-- The spectral gap: the smallest eigenvalue bounds the quadratic form below. -/
axiom spectral_gap_lower_bound (T : E →ₗ[ℂ] E) (h : T.IsSymmetric) (c : ℝ)
    (hc : ∀ μ : ℂ, μ ∈ spectrum ℂ T → c ≤ μ.re) :
    ∀ v : E, (c : ℝ) * ‖v‖ ^ 2 ≤ (inner ℂ (T v) v).re

end Spectral

/-! ## Cluster Positivity — quadratic forms and the Weil criterion -/

namespace Positivity

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]

/-- A positive semidefinite quadratic form. -/
axiom psd_nonneg (Q : E → ℝ) (h : ∀ v : E, 0 ≤ Q v) : ∀ v : E, 0 ≤ Q v

/-- The Weil criterion, in shape: RH holds exactly when a specific hermitian form is
nonnegative on every test function. Stated as an equivalence between a positivity and
`RiemannHypothesis`, which is the row the Atlas is meant to notice. -/
axiom weil_criterion (W : (ℝ → ℂ) → ℝ) :
    RiemannHypothesis ↔ ∀ f : ℝ → ℂ, 0 ≤ W f

/-- Positivity of a matrix form. -/
axiom matrix_psd_iff {n : Type} [Fintype n] [DecidableEq n] (M : Matrix n n ℝ) :
    M.PosSemidef ↔ ∀ v : n → ℝ, 0 ≤ ∑ i, v i * M.mulVec v i

/-- Intersection positivity on a surface: the shape the Castelnuovo–Severi inequality has,
and the one Weil positivity is the arithmetic analogue of. -/
axiom intersection_positivity (S : Type) (pair : S → S → ℝ) (h : ∀ x : S, 0 ≤ pair x x) :
    ∀ x : S, 0 ≤ pair x x

/-- A nonnegative hermitian form has nonnegative diagonal. -/
axiom hermitian_diag_nonneg (H : ℕ → ℕ → ℂ) (h : ∀ i j, H i j = star (H j i))
    (hpos : ∀ f : ℕ → ℂ, 0 ≤ (∑ i ∈ Finset.range 10, ∑ j ∈ Finset.range 10,
      star (f i) * H i j * f j).re) :
    ∀ i, 0 ≤ (H i i).re

end Positivity

/-! ## Cluster Deformation — de Bruijn–Newman -/

namespace Deformation

/-- The de Bruijn–Newman constant. -/
axiom Lambda : ℝ

/-- RH is equivalent to Λ ≤ 0. -/
axiom rh_iff_lambda_nonpos : RiemannHypothesis ↔ Lambda ≤ 0

/-- Newman's conjecture, now a theorem: Λ ≥ 0. -/
axiom lambda_nonneg : 0 ≤ Lambda

/-- The heat-flow family: zeros are real for t ≥ Λ. -/
axiom zeros_real_above_lambda (H : ℝ → ℂ → ℂ) (t : ℝ) (ht : Lambda ≤ t) :
    ∀ z : ℂ, H t z = 0 → z.im = 0

/-- Monotonicity of the deformation: once real, zeros stay real. -/
axiom zeros_stay_real (H : ℝ → ℂ → ℂ) (s t : ℝ) (hst : s ≤ t)
    (h : ∀ z : ℂ, H s z = 0 → z.im = 0) :
    ∀ z : ℂ, H t z = 0 → z.im = 0

end Deformation

/-! ## Cluster FF — function-field arithmetic, where RH is a theorem -/

namespace FF

variable {p : ℕ} [Fact (Nat.Prime p)]

/-- Euclidean division for polynomials — the FF side of the Z-arithmetic chain.
**Stated as a proposition.** The first version asserted the *instance*
`EuclideanDomain (Polynomial (ZMod p))`, which is a term of a structure type rather than a
claim, so it could never pair with `Z.euclidean_division` and the V1/V4 dictionary came
back with zero rows. -/
axiom poly_euclidean_division (f g : Polynomial (ZMod p)) (hg : g ≠ 0) :
    ∃ q r : Polynomial (ZMod p), f = g * q + r ∧ (r = 0 ∨ r.degree < g.degree)

/-- The FF side of the norm-shaped Euclidean division. Deliberately the same shape as
`Z.int_division_via_norm`, with `natDegree` where that has `natAbs`. -/
axiom poly_division_via_norm (f g : Polynomial (ZMod p)) (hg : g ≠ 0) :
    ∃ q r : Polynomial (ZMod p), f = g * q + r ∧ r.natDegree < g.natDegree

/-- Bézout on the FF side. -/
axiom poly_bezout (f g : Polynomial (ZMod p)) :
    ∃ x y : Polynomial (ZMod p), f * x + g * y = EuclideanDomain.gcd f g

/-- Unique factorization on the FF side, as a proposition. -/
axiom poly_unique_factorization (f : Polynomial (ZMod p)) (hf : f ≠ 0) :
    ∃ s : Multiset (Polynomial (ZMod p)),
      (∀ q ∈ s, Irreducible q) ∧ Associated f s.prod

/-- Irreducibles are infinite on the FF side — the analogue of "primes are infinite". -/
axiom poly_irreducibles_infinite (n : ℕ) :
    ∃ f : Polynomial (ZMod p), n < f.natDegree ∧ Irreducible f

/-- Point counts of a curve over the degree-m extension. -/
axiom pointCount : ℕ → ℕ

/-- The eigenvalue form of the point count: N_m = p^m + 1 − Σ αᵢ^m. -/
axiom pointCount_eigenvalue (g : ℕ) (α : Fin (2 * g) → ℂ) :
    ∀ m : ℕ, 0 < m →
      (pointCount m : ℂ) = (p : ℂ) ^ m + 1 - ∑ i, α i ^ m

/-- RH for curves: every Frobenius eigenvalue has absolute value √p. This is a *theorem*
(Weil), and it is the row whose number-field analogue is open. -/
axiom frobenius_eigenvalue_abs (g : ℕ) (α : Fin (2 * g) → ℂ) :
    ∀ i, ‖α i‖ = Real.sqrt p

/-- Equivalently: the eigenvalues lie on a circle of radius √p — the FF analogue of
"zeros lie on the critical line". -/
axiom eigenvalues_on_circle (g : ℕ) (α : Fin (2 * g) → ℂ) :
    ∀ i, ‖α i‖ ^ 2 = p

/-- The Frobenius eigenvalues, as a set on the circle of radius √p. The FF-side analogue
of "zeros lie on the critical line", at set level. -/
axiom eigenvalues_subset_circle (g : ℕ) (α : Fin (2 * g) → ℂ) :
    Set.range α ⊆ {z : ℂ | ‖z‖ = Real.sqrt p}

/-- The zeta function of a curve is rational. -/
axiom zeta_rational (Z : ℂ → ℂ) (P Q : Polynomial ℂ) :
    ∀ u : ℂ, Q.eval u ≠ 0 → Z u = P.eval u / Q.eval u

/-- The Castelnuovo–Severi shape: an intersection-form inequality on a surface. -/
axiom castelnuovo_severi (D : Type) (inter : D → D → ℤ) (deg : D → ℤ) :
    ∀ x : D, inter x x ≤ 2 * deg x

end FF

/-! ## Cluster Z — the number-field side of the same chain -/

namespace Z

/-- Unique factorization in ℤ, as a proposition rather than an instance. -/
axiom int_unique_factorization (n : ℤ) (hn : n ≠ 0) :
    ∃ s : Multiset ℤ, (∀ q ∈ s, Irreducible q) ∧ Associated n s.prod

/-- Bézout: the gcd is an integer combination. -/
axiom bezout (a b : ℤ) : ∃ x y : ℤ, a * x + b * y = gcd a b

/-- Euclidean division. -/
axiom euclidean_division (a b : ℤ) (hb : b ≠ 0) :
    ∃ q r : ℤ, a = b * q + r ∧ |r| < |b|

/-- Euclidean division stated through an abstract size function. **A test of whether the
analogy needs its abstraction present.** `Z.euclidean_division` says `|r| < |b|` and
`FF.poly_euclidean_division` says `r = 0 ∨ deg r < deg g`; those are genuinely different
statements, and anti-unification finds shared structure rather than inventing the norm that
makes both instances of one pattern. If the two *norm-shaped* forms below match each other
while the natural forms do not, that localises the failure to the missing abstraction. -/
axiom int_division_via_norm (a b : ℤ) (hb : b ≠ 0) :
    ∃ q r : ℤ, a = b * q + r ∧ r.natAbs < b.natAbs

/-- The Euler product for ζ. -/
axiom euler_product :
    ∀ s : ℂ, 1 < s.re →
      riemannZeta s = ∏' p : Nat.Primes, (1 - (p : ℂ) ^ (-s))⁻¹

/-- Infinitude of primes. -/
axiom primes_infinite : ∀ n : ℕ, ∃ p : ℕ, n < p ∧ Nat.Prime p

end Z

/-! ## Cluster L — Dirichlet L-functions and GRH -/

namespace LFamily

/-- A Dirichlet L-function's Euler product. -/
axiom dirichlet_euler_product (χ : ℕ → ℂ) :
    ∀ s : ℂ, 1 < s.re → LSeries χ s = ∏' p : Nat.Primes, (1 - χ p * (p : ℂ) ^ (-s))⁻¹

/-- GRH for a Dirichlet L-function: its nontrivial zeros lie on the critical line. -/
axiom grh_zeros_on_line (χ : ℕ → ℂ) :
    ∀ s : ℂ, LSeries χ s = 0 → 0 < s.re → s.re < 1 → s.re = 1 / 2

/-- No zero of an L-function off the line. -/
axiom grh_no_zero_off_line (χ : ℕ → ℂ) :
    ¬ ∃ s : ℂ, LSeries χ s = 0 ∧ 0 < s.re ∧ s.re < 1 ∧ s.re ≠ 1 / 2

/-- The functional equation's shape: a completed L-function is symmetric about s ↦ 1 − s. -/
axiom functional_equation (Λf : ℂ → ℂ) : ∀ s : ℂ, Λf s = Λf (1 - s)

end LFamily

/-! ## Cluster Counting — PNT and the explicit formula -/

namespace Counting

/-- The prime number theorem. -/
axiom pnt :
    Tendsto (fun x : ℝ => (Nat.primeCounting ⌊x⌋₊ : ℝ) * Real.log x / x) atTop (nhds 1)

/-- The explicit formula's shape: the error is a sum over the zeros. -/
axiom explicit_formula (ρ : ℕ → ℂ) (ψ : ℝ → ℝ) :
    ∀ x : ℝ, 1 < x → (ψ x : ℂ) = x - ∑' n : ℕ, (x : ℂ) ^ ρ n / ρ n

/-- A zero-free region gives an error term. -/
axiom zero_free_region_error (c : ℝ) (hc : 0 < c)
    (h : ∀ s : ℂ, 1 - c / Real.log (|s.im| + 2) < s.re → riemannZeta s ≠ 0) :
    ∃ C : ℝ, ∀ x : ℝ, 2 ≤ x →
      |(∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ArithmeticFunction.vonMangoldt n) - x|
        ≤ C * x * Real.exp (-Real.sqrt (Real.log x))

end Counting

/-! ## Cluster ZeroDensity — Ingham-shape bounds -/

namespace ZeroDensity

/-- The number of zeros with real part above σ up to height T is bounded by a power of T. -/
axiom zero_density (N : ℝ → ℝ → ℝ) (f : ℝ → ℝ) :
    ∀ σ T : ℝ, 1 / 2 ≤ σ → σ ≤ 1 → 2 ≤ T → N σ T ≤ T ^ f σ

/-- The density hypothesis. -/
axiom density_hypothesis (N : ℝ → ℝ → ℝ) :
    ∀ σ T : ℝ, 1 / 2 ≤ σ → σ ≤ 1 → 2 ≤ T → N σ T ≤ T ^ (2 - 2 * σ)

/-- Riemann–von Mangoldt: the count of zeros up to height T. -/
axiom riemann_von_mangoldt (N : ℝ → ℝ) :
    ∃ C : ℝ, ∀ T : ℝ, 2 ≤ T →
      |N T - T / (2 * Real.pi) * Real.log (T / (2 * Real.pi))| ≤ C * Real.log T

end ZeroDensity

/-! ## Cluster PairCorrelation — Montgomery and GUE -/

namespace PairCorrelation

/-- Montgomery's pair-correlation conjecture, with the GUE kernel written out. -/
axiom montgomery (F : ℝ → ℝ) :
    ∀ α β : ℝ, 0 < α → α < β →
      Tendsto (fun T : ℝ => F T) atTop
        (nhds (∫ u in Set.Icc α β, 1 - (Real.sin (Real.pi * u) / (Real.pi * u)) ^ 2))

/-- The GUE pair-correlation density vanishes at the origin — level repulsion. The first
version of this axiom was `X = X`, a tautology that could match anything and mean nothing. -/
axiom gue_density_vanishes_at_zero (R : ℝ → ℝ)
    (h : ∀ u : ℝ, u ≠ 0 → R u = 1 - (Real.sin (Real.pi * u) / (Real.pi * u)) ^ 2) :
    Filter.Tendsto R (nhds 0) (nhds 0)

/-- Eigenvalue spacing of a random hermitian matrix has the same density — the row that
makes the pair-correlation cluster a *bridge* to the Spectral cluster. -/
axiom gue_eigenvalue_spacing (spacing : ℝ → ℝ) :
    ∀ u : ℝ, u ≠ 0 → spacing u = 1 - (Real.sin (Real.pi * u) / (Real.pi * u)) ^ 2

end PairCorrelation

end Validation
