import Lean
open Lean PrettyPrinter Elab Command

-- laws-as-fields with dependent fields (Group 9 shape) — no Mathlib needed
class Cat' (Ob : Type u) where
  Hom : Ob → Ob → Type v
  id : ∀ {a : Ob}, Hom a a
  comp : ∀ {a b c : Ob}, Hom a b → Hom b c → Hom a c
  id_comp : ∀ {a b : Ob} (f : Hom a b), comp id f = f

instance : Cat' Unit where
  Hom _ _ := Unit
  id := ()
  comp _ _ := ()
  id_comp _ := rfl

class HasCarrier (X : Type u) (carrier : outParam (Type v)) where
  proj : X → carrier

-- hygiene in pretty-printed expansions: macro introduces a fresh binder `y`
syntax (name := fhLet) "fnlet" ident : command
macro_rules
  | `(command| fnlet $n:ident) => `(def $n : Nat := let y := 3; y)

elab "#fh_expand " c:command : command => do
  let stx ← liftMacroM (Lean.expandMacros c)
  let fmt ← liftCoreM <| ppCommand ⟨stx⟩
  logInfo fmt

#fh_expand fnlet beta

-- is `exists` reserved in core? (tactic `exists` exists)
def checkTok : Nat := 1
example : True := by exists
