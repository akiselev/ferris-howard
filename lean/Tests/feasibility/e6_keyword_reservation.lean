import Lean
-- E6: does declaring `var`/`fn` commands reserve the token globally in importing files?
syntax "var" ident ":" term ";" : command
syntax "fn" ident : command

-- ambient Lean using `var` as an identifier in the SAME file:
def var := 3

example : Nat := var

theorem t (var : Nat) : var = var := rfl
