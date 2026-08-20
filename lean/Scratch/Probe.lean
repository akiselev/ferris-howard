import Mathlib
open Complex Polynomial

-- Anchors the validation corpus needs. Each `#check` that elaborates is a name we can
-- build on; each error names a gap we must state ourselves.
#check @RiemannHypothesis
#check @riemannZeta
#check @LSeries
#check @DirichletCharacter
#check @ArithmeticFunction.vonMangoldt
#check @Nat.Prime
#check @Polynomial.Monic
#check @ZMod
#check @IsSelfAdjoint
#check @LinearMap.IsSymmetric
#check @QuadraticForm
#check @Matrix.PosSemidef
#check @InnerProductSpace
#check @Filter.Tendsto
#check @Nat.card
#check @EuclideanDomain
#check @UniqueFactorizationMonoid
#check @Bezout
