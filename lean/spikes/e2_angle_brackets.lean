import Lean
open Lean Elab Command

declare_syntax_cat rexpr
syntax ident : rexpr
syntax "(" rexpr ")" : rexpr
-- generic application: trailing <...> at high precedence
syntax:100 rexpr:100 "<" rexpr,+ ">" : rexpr
-- comparisons, non-assoc-ish
syntax:50 rexpr:51 " < " rexpr:51 : rexpr
syntax:50 rexpr:51 " > " rexpr:51 : rexpr
-- membership
syntax:55 rexpr:56 " in " rexpr:56 : rexpr

elab "#rtest " e:rexpr : command => logInfo m!"parsed: {e}"

-- simple generic
#rtest Vec<T>
-- nested generic: the >> maximal-munch problem
#rtest Set<Set<A>>
-- comparison with spaces
#rtest (a < b)
-- unparenthesized comparison at top level
#rtest a < b
-- ambiguous: comparison chain vs generic then >
#rtest a < b > c
-- in as binary op
#rtest x in s

-- ambient Lean still fine with `in`?
open Nat in
#check 1

def sumList : Nat := Id.run do
  let mut acc := 0
  for x in [1,2,3] do
    acc := acc + x
  return acc
