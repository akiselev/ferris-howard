import Lean
open Lean PrettyPrinter Elab Command

declare_syntax_cat rx2
syntax ident : rx2
syntax num : rx2

-- fn command: body antiquote passed through; return type synthesized
syntax (name := fhFn) "fn" ident "(" ")" "->" rx2 "{" rx2 "}" : command

def rx2ToTerm : TSyntax `rx2 → MacroM (TSyntax `term)
  | `(rx2| $x:ident) => pure x
  | `(rx2| $n:num) => pure ⟨n.raw⟩
  | _ => Macro.throwUnsupported

macro_rules
  | `(command| fn $n:ident ( ) -> $ty:rx2 { $b:rx2 }) => do
    let ty ← rx2ToTerm ty
    let b ← rx2ToTerm b
    `(def $n : $ty := $b)

-- expansion pretty-printer (I2 feasibility)
elab "#fh_expand " c:command : command => do
  let stx ← liftMacroM (Lean.expandMacros c)
  let fmt ← liftCoreM <| ppCommand ⟨stx⟩
  logInfo fmt

#fh_expand fn three() -> Nat { 3 }

-- span test A: error inside user-written body (antiquote pass-through)
fn bad_body() -> Nat { Bool }

-- span test B: macro synthesizes ill-typed syntax not present in source
syntax (name := fhFn2) "fnbroken" ident : command
macro_rules
  | `(command| fnbroken $n:ident) => `(def $n : Nat := "not a nat")

fnbroken alpha
