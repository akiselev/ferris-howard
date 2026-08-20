/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item
import Plausible
-- `SampleableExt` for function types, without which a statement quantified over `f : A → A`
-- has no `Testable` instance — and that shape is most of what small-model instantiation is
-- for. Corpus-shaped claims quantify over functions constantly.
import Plausible.Functions

/-!
# The falsification battery (C4, agent-interface §3)

PLAN C4: "`plausible`, `decide`/`native_decide`, Rust-side enumeration/SAT with in-Lean
verification; auto-run on whole-proof failure; role-metadata steering arrives at M2."

## Why an agent needs this before it needs a proof

An agent that cannot prove a statement has two very different situations in front of it,
and telling them apart is the highest-value thing it can do next: the statement may be hard,
or it may be **false**. Hours go into the first case when the answer was the second. So the
first thing to run on a failure is not another tactic — it is a search for a counterexample.

## The battery, cheapest first

1. **`decide`** — for a closed decidable proposition, the answer is a computation and the
   kernel checks it. No search, no doubt.
2. **`plausible`** — property-based testing with shrinking, which is what turns "some
   counterexample" into a *readable* one.
3. **Small-model instantiation** — the payoff design §4.9 predicted for role metadata:
   "`Space` variables get probed with small finite types (`Bool`, `Fin 3`)". A statement
   quantified over an arbitrary space is not testable as written; instantiate the space and
   it becomes a concrete proposition `plausible` can attack.

Step 3 is where the interesting refutations come from, because a *general* claim that fails
at `Bool` is not a claim that needs a cleverer proof.

## What a negative result does and does not mean

Finding nothing is not evidence the statement is true, and this module never says it is.
The report distinguishes "refuted, here is the witness" from "no counterexample found in
what was tried", and names what was tried. Rust-side enumeration and SAT — C4's third leg —
are not here; when they arrive they extend the list rather than change the verdict
vocabulary.
-/

namespace FerrisHoward.Falsify

open Lean Elab Command Meta Term

/-- The small types a space-typed binder is probed with, cheapest first.

Design §4.9's list, in the order that makes a counterexample readable: `Bool` first because
a two-element refutation is the easiest to think about, `Fin 3` because so many statements
are true at two elements by accident, `Unit` last because it refutes almost nothing but
costs nothing to try. -/
def probeTypes : List (TSyntax `term) := Id.run do
  return [⟨mkIdent `Bool⟩, ⟨Syntax.mkApp (mkIdent `Fin) #[Syntax.mkNumLit "3"]⟩,
          ⟨mkIdent `Unit⟩]

/-- Replace every sort-typed binder of a `∀`-telescope with `probe`, keeping the rest.

`∀ {A : Type} (f : A → A) (a : A), f a = a` at `A := Bool` becomes
`∀ (f : Bool → Bool) (a : Bool), f a = a`, which is a proposition `plausible` can test —
and which is false, in one line, for a statement that looks respectable in general form. -/
partial def probeSorts (ty : Expr) (probe : Expr) : MetaM Expr := do
  match ← whnf ty with
  | .forallE n d b bi =>
      if d.isSort && !d.isProp then
        -- The binder is a *space*. Substituting is what makes the rest concrete.
        probeSorts (b.instantiate1 probe) probe
      else
        withLocalDecl n bi d fun x => do
          mkForallFVars #[x] (← probeSorts (b.instantiate1 x) probe)
  | t => pure t

/-- One attempt: elaborate `(by tac : goal)` and report what happened.

`plausible` signals a counterexample by *failing* with a message that contains it, so the
error is the result rather than a problem — which is why this catches rather than
propagates. -/
def attempt (goal : Expr) (tac : TSyntax `tactic) : TermElabM (Option String) := do
  try
    let stx ← `(term| by $tac:tactic)
    let _ ← withoutErrToSorry do
      let e ← elabTerm stx (some goal)
      synthesizeSyntheticMVarsNoPostponing
      instantiateMVars e
    return none
  catch e =>
    return some (← e.toMessageData.toString)

/-- Does this message carry a counterexample, as opposed to a tactic that merely failed?

The distinction is the whole value of the command. `plausible` announces a
counter-example; `decide` announces that it *proved the proposition false*, which is the
strongest refutation available because the kernel checked it. Anything else — no instance,
not closed, timed out — is a tactic that did not run, and reporting that as "no
counterexample" would be the one dishonest thing this module could do. -/
def isRefutation (msg : String) : Bool :=
  (msg.splitOn "Found a counter-example!").length != 1
    || (msg.splitOn "is false").length != 1

/-- Run the battery against one proposition. -/
def battery (goal : Expr) : TermElabM (Array String) := do
  let mut log := #[]
  let decideTac ← `(tactic| decide)
  let plausibleTac ← `(tactic| plausible)

  -- 1. A closed decidable proposition needs no search at all.
  match ← attempt goal decideTac with
  | none => return #["`decide` proved it — the statement is true, not merely unrefuted"]
  | some m =>
      -- The kernel checked this one, which is as certain as a refutation gets.
      if isRefutation m then return #[s!"REFUTED by `decide` (kernel-checked):\n{m}"]
      log := log.push "`decide`: not applicable or not closed"

  -- 2. Property-based search on the statement as written.
  match ← attempt goal plausibleTac with
  | none => log := log.push "`plausible`: no counterexample"
  | some m =>
      if isRefutation m then return log.push s!"REFUTED by `plausible`:\n{m}"
      log := log.push "`plausible`: could not run on this statement"

  -- 3. Small-model instantiation — design §4.9's role-metadata payoff.
  for probe in probeTypes do
    let probeE ← elabTerm probe none
    let inst ← probeSorts goal probeE
    if inst == goal then continue   -- nothing to instantiate; step 2 already covered it
    let name := toString (← ppExpr probeE)
    match ← attempt inst plausibleTac with
    | none => log := log.push s!"at {name}: no counterexample"
    | some m =>
        if isRefutation m then
          return log.push s!"REFUTED at {name}:\n{m}"
        log := log.push s!"at {name}: could not run ({m.splitOn "\n" |>.headD ""})"
  return log

/-- `#fh_falsify <decl>` — try to refute a declaration's statement.

The first thing to run when a proof will not close. A refutation ends the search; anything
else is reported as what was tried, never as evidence of truth. -/
elab "#fh_falsify " n:ident : command => do
  let name ← liftCoreM <| realizeGlobalConstNoOverload n
  let some ci := (← getEnv).find? name
    | throwErrorAt n s!"unknown declaration `{name}`"
  liftTermElabM do
    -- Universe *parameters* have to become metavariables before a space can be probed:
    -- `general.{u}` states `@Eq.{u} A (f a) a`, and substituting `A := Bool` without
    -- freeing `u` leaves `@Eq.{u} Bool …`, which is ill-typed and for which no `Testable`
    -- instance can exist. Freeing them lets `u := 1` fall out of the substitution.
    let levels ← ci.levelParams.mapM fun _ => mkFreshLevelMVar
    let ty := ci.instantiateTypeLevelParams levels
    let log ← battery ty
    let refuted := log.any fun l => l.startsWith "REFUTED" || l.startsWith "refuted"
    let header := if refuted then s!"FH falsify: `{name}` is FALSE" else
      s!"FH falsify: no counterexample for `{name}` — this is not evidence it is true"
    logInfo (header ++ "\n" ++ String.intercalate "\n" log.toList)

end FerrisHoward.Falsify
