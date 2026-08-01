/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Emit

/-!
# The golden tier: `#fh_expand` (I2)

`#fh_expand <fh item>` logs the hygiene-sanitized Lean surface syntax that FH's stage-one
macros produce, so a golden test is

```
/-- info: <expected Lean> -/
#guard_msgs (whitespace := lax) in
#fh_expand fn f(n: Nat) -> Nat { n }
```

It is a thin wrapper over `FerrisHoward.Emit` — deliberately the *same* expansion the
publication path uses (ADR-006). A golden is therefore a preview of the emitted artifact,
which is the strongest available reason to keep goldens honest: they are not a private
record of what the macros happen to do, they are what a referee will read.

The one difference is the emittable lint, which `#fh_emit` enforces and `#fh_expand` does
not — a construct can be worth inspecting before it is worth publishing.

Neither command elaborates its argument: that is the elaboration tier's job.
-/

namespace FerrisHoward.Test
open Lean Elab Command

/-- Log the hygiene-sanitized Lean surface syntax that FH's stage-one macros produce for
the following FH item. The golden tier; see the module header. -/
elab "#fh_expand " c:command : command => do
  logInfo (← Emit.ppExpansion (← Emit.expandFh c))

end FerrisHoward.Test
