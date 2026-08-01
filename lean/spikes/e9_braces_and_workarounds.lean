import Lean
open Lean Elab Command

declare_syntax_cat rex
syntax ident : rex
syntax num : rex
syntax:70 rex:70 "*" rex:71 : rex
-- generic app, args at prec 51 to keep comparison (50) out
syntax:100 rex:100 "<" rex:51,+ ">" : rex
syntax:50 rex:51 " < " rex:51 : rex
syntax:50 rex:51 " > " rex:51 : rex
-- F13: set-builder vs brace-escape, same leading token
syntax "{" ident ":" rex "|" rex "}" : rex
syntax "{" rex "}" : rex

elab "#rt " e:rex : command => logInfo m!"parsed: {e}"

-- brace escape
#rt Vector<T, {n*2}>
-- set-builder
#rt {x: A | P}
-- brace escape containing an ident with colon-less form
#rt {n}
-- nested generics with space workaround
#rt Set<Set<A> >
-- nested generics, no space (expected: >> token failure)
#rt Set<Set<A>>
-- generic args at prec 51: does Vec<T> now work?
#rt Vec<T>
-- comparison inside generic args must now fail (needs parens/braces)
#rt Vec<{a < b}>
