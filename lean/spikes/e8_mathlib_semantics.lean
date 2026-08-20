import Mathlib.Probability.ProbabilityMassFunction.Monad
import Mathlib.Data.ZMod.Basic

-- ? -> do across PMF: Monad instance must exist and do-notation must elaborate
#synth Monad PMF

example : PMF Bool := do
  let x ← (PMF.pure true : PMF Bool)
  pure x

-- Fact bridge
example (p : Nat) [Fact p.Prime] : Field (ZMod p) := inferInstance

-- laws-as-fields with dependent fields (Group 9 shape), Prop laws, outParam assoc type
class Cat' (Ob : Type u) where
  Hom : Ob → Ob → Type v
  id : ∀ {a : Ob}, Hom a a
  comp : ∀ {a b c : Ob}, Hom a b → Hom b c → Hom a c
  id_comp : ∀ {a b : Ob} (f : Hom a b), comp id f = f

class HasCarrier (X : Type u) (carrier : outParam (Type v)) where
  proj : X → carrier

instance : Cat' Unit where
  Hom _ _ := Unit
  id := ()
  comp _ _ := ()
  id_comp f := rfl
