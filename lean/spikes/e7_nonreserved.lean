import Lean
open Lean Parser

-- mitigation test: nonReservedSymbol so `var` stays usable as an identifier
def varKw : Parser := nonReservedSymbol "var"

elab (name := varCmd) varKw x:ident ":" t:term ";" : command => do
  Lean.logInfo m!"declared ambient {x} : {t}"

var A : Type;

-- ambient Lean can still use `var` as an identifier?
def var := 3
example : Nat := var

-- is `exists` already reserved by core?
def checkExists := 1
-- (tactic `exists` exists; check token status in term position)
example : Nat := 2
