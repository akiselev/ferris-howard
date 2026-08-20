import Lean
open Lean PrettyPrinter Elab Command

-- E1: competing `theorem` command in a downstream "package" (same file here)
syntax (name := fhTheorem) "theorem" ident "(" ident ":" term ")" "->" term "{" term "}" : command

macro_rules
  | `(command| theorem $n:ident ( $x:ident : $t:term ) -> $c:term { $prf:term }) =>
    `(theorem $n ($x : $t) : $c := $prf)

-- plain Lean theorem must still parse
theorem plain_ok : True := trivial

-- FH-style theorem must parse and elaborate
theorem fh_style(h: True) -> True { h }

#check fh_style

-- E4: one-step-ish expansion + ppCommand golden feasibility
elab "#fh_expand " c:command : command => do
  let stx ← liftMacroM (Lean.expandMacros c)
  let fmt ← liftCoreM <| ppCommand ⟨stx⟩
  logInfo fmt

#fh_expand theorem fh_style2(h: True) -> True { h }

-- malformed FH theorem: what error does the user see?
theorem bad_one(x: Nat) -> { x }
