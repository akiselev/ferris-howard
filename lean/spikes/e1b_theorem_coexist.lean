import Lean
open Lean PrettyPrinter Elab Command

declare_syntax_cat rx
syntax ident : rx
syntax rx "==" rx : rx

-- FH-style theorem command over its OWN category
syntax (name := fhThm) "theorem" ident "(" (ident ":" rx),* ")" "->" rx "{" rx "}" : command

macro_rules
  | `(command| theorem $n:ident ( $[$_xs:ident : $_ts:rx],* ) -> $_c:rx { $_b:rx }) =>
    `(theorem $n : True := trivial)

-- 1. plain Lean theorem, no binders
theorem plain_ok : True := trivial

-- 2. plain Lean theorem WITH paren binders (shared prefix with FH)
theorem plain_binders (x : Nat) : x = x := rfl

-- 3. FH-style
theorem fh1(h: A) -> B { pf }

#check fh1

-- 4. attribute + plain theorem
@[simp] theorem plain_attr : True := trivial

-- 5. malformed plain Lean theorem: which grammar's error wins?
theorem oops (x : Nat) : x = x
