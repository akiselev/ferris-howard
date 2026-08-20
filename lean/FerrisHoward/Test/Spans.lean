/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item

/-!
# The span tier: `#fh_spans` (I2, mandatory fourth tier per PLAN §9.3)

`#fh_spans in <cmd>` elaborates `<cmd>`, swallows its messages, and logs one line per
message giving **severity, position relative to the wrapped command, and the source text
the diagnostic underlines**:

```
/-- info: error @ +0:14-0:15 «T» -/
#guard_msgs in
#fh_spans in
fn unbound(x: T) -> Nat { x }
```

Design notes:

* **Positions are relative to the wrapped command**, so a span assertion does not churn
  when lines are added above it.
* **Message text is deliberately absent.** Stock `#guard_msgs (positions := true)` also
  reports positions (discovered on-toolchain; it is the fallback if this command ever
  gets in the way), but it reports them *together with the message*, which couples every
  span assertion to exact wording. Keeping the tiers decoupled means a reworded
  diagnostic re-baselines the negative tier only — R6 again.
* **The underlined text is what makes the assertion readable.** `+0:14-0:15` alone
  requires a reviewer to count columns; `«T»` does not, and design §8 asks for a suite
  reviewable without running Lean mentally.
-/

namespace FerrisHoward.Test
open Lean Elab Command

/-- Render one message as a span-assertion line: `severity @ +Δline:col-Δline:col «text»`,
where the deltas are relative to `baseLine` (the first line of the wrapped command). -/
def renderSpan (map : FileMap) (baseLine : Nat) (msg : Message) : String :=
  let sev :=
    match msg.severity with
    | .information => "info"
    | .warning => "warning"
    | .error => "error"
  let rel (p : Position) : String := s!"+{p.line - baseLine}:{p.column}"
  match msg.endPos with
  | none => s!"{sev} @ {rel msg.pos}-?"
  | some endPos =>
    let text := String.Pos.Raw.extract map.source (map.ofPosition msg.pos) (map.ofPosition endPos)
    -- a span may cross lines; keep the assertion on one line
    let text := text.replace "\n" "⏎"
    -- same-line spans print just the end column, as `#guard_msgs (positions := true)` does
    let stop := if endPos.line == msg.pos.line then toString endPos.column else rel endPos
    s!"{sev} @ {rel msg.pos}-{stop} «{text}»"

/-- Elaborate the following command, then report the *spans* of the diagnostics it
produced instead of the diagnostics themselves. The span tier; see the module header. -/
elab "#fh_spans " "in " cmd:command : command => do
  let msgs ← Lean.Elab.Tactic.GuardMsgs.runAndCollectMessages cmd
  modify fun st => { st with messages := {} }
  let map ← getFileMap
  let baseLine := (map.toPosition (cmd.raw.getPos?.getD 0)).line
  let lines := msgs.toList.filterMap fun msg =>
    if msg.isSilent || msg.isTrace then none else some (renderSpan map baseLine msg)
  if lines.isEmpty then
    logInfo "no diagnostics"
  else
    logInfo (String.intercalate "\n" lines)

end FerrisHoward.Test
