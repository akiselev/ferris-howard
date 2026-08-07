/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lean

/-!
# Parse-level assertions (`#fh_parse`)

Some FH behaviour is a *parse* fact, not an elaboration fact — most importantly keyword
reservation (A0.5): once FH is imported, `def fn := 3` no longer parses. `#guard_msgs`
cannot test that, because a parse error inside it stops `#guard_msgs` itself from parsing.

So `#fh_parse "…"` runs the parser over a string in the current environment and logs the
outcome, which `#guard_msgs` then checks as an ordinary message. This is the one place FH
parses a string on purpose; ground rule 3's "never re-parse strings" is about macro
expansion, where re-parsing destroys spans.
-/

namespace FerrisHoward.Test
open Lean Elab Command

/-- Parse a string as a command in the current environment and report the outcome.
Used for the keyword-reservation battery. -/
elab "#fh_parse " s:str : command => do
  match Parser.runParserCategory (← getEnv) `command s.getString with
  | .ok _ => logInfo "parses"
  | .error e => logInfo m!"does not parse: {e}"

end FerrisHoward.Test
