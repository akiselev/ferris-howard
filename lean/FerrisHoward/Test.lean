/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Test.Golden
import FerrisHoward.Test.Parse
import FerrisHoward.Test.Spans

/-!
# The FH test harness (I2)

Four tiers, all on `#guard_msgs` (design §8 as amended by PLAN §9.3). Every feature lands
with all four:

| tier | mechanism |
|---|---|
| golden expansion | `#guard_msgs (whitespace := lax) in #fh_expand …` |
| elaboration | the declaration elaborates; `#print axioms` pins sorry-freeness |
| negative | `#guard_msgs in …` on input that must fail, exact message |
| span | `#guard_msgs in #fh_spans in …` |

Import this module in fixtures; the language itself (`import FerrisHoward`) does not
depend on it.
-/
