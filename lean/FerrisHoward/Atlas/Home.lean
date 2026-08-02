/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Item

/-!
# `atlas home` — carrier abstraction and the lattice walk (B3, atlas.md §1b)

Where does a theorem actually *live*?

A statement written for `CommRing` whose argument only ever adds is not a theorem about
commutative rings; it is a theorem about additive commutative monoids that happens to have
been written down in the wrong place. Mathlib's generalization linter exists because this
happens constantly, and finding it is one of the two things atlas.md claims the Atlas is
for.

## How the home is computed

Not by guessing, and not by name. Every constant an argument uses carries its own instance
binders, and those binders are a *statement* of what that constant needs. So:

> the classes a declaration needs at a carrier = the union of the instance-binder classes
> of every constant its statement and proof use, restricted to that carrier.

The restriction to instance *binders* is what makes this work. The elaborated statement
also contains the projection chain from the declared class down — `CommRing.toCommSemiring`,
`CommSemiring.toSemiring`, and so on — but that chain is an artifact of having declared
`CommRing` in the first place. Counting it would make every declaration look at home.

`a + b = b + a` proved by `add_comm` reaches `AddCommMonoid`, whatever the declaration
says it assumes. The lattice walk then asks which of the declared class's ancestors
dominates that set — and if the answer is a strict ancestor, the declaration is
over-hypothesised and the report names the weaker home.

## What this is and is not

It is a **candidate** detector, which is what a generalization linter is. Two limits, both
real and both stated in the report rather than buried:

* It reads the *elaborated* statement and proof term. A proof that goes through `simp`
  leaves whatever `simp` used, which is a fair account of the argument but not always the
  smallest one — a differently-written proof may live lower still.
* Class *ancestry* is Lean's structure-parent relation. A carrier can also be abstracted
  by routes that are not ancestry (a `Fintype` replaced by a `Finite`, say); those are
  outside this walk and B4's business.

A candidate is confirmed by moving the declaration and re-checking it. The report says so.
-/

namespace FerrisHoward.Atlas

open Lean Meta Elab Command

/-- Every class `n` extends, transitively, including `n` itself. -/
partial def ancestors (env : Environment) (n : Name) : NameSet :=
  go n {}
where
  go (n : Name) (acc : NameSet) : NameSet :=
    if acc.contains n then acc
    else
      (getStructureParentInfo env n).foldl (fun acc p => go p.structName acc) (acc.insert n)

/-- The classes a constant declares it needs, as instance binders, paired with the argument
each is *about*.

This is the load-bearing observation: an instance binder is a constant's own written
statement of what it requires, so reading them off is not inference. -/
def instanceClasses (env : Environment) (n : Name) : MetaM NameSet := do
  let some ci := env.find? n | return {}
  let levels ← ci.levelParams.mapM fun _ => mkFreshLevelMVar
  forallTelescopeReducing (ci.instantiateTypeLevelParams levels) fun xs _ => do
    let mut out : NameSet := {}
    for x in xs do
      let d ← x.fvarId!.getDecl
      if d.binderInfo == .instImplicit then
        if let .const c _ := (← whnf d.type).getAppFn then
          out := out.insert c
    return out

/-- The classes a declaration's statement and proof actually reach. -/
def reachedClasses (env : Environment) (ci : ConstantInfo) : MetaM NameSet := do
  let mut used := ci.type.getUsedConstants
  -- `value?` is `none` for a theorem on this toolchain — the same trap B1 fell into, so
  -- the constructor is matched directly. A proof is most of the evidence here.
  if let .thmInfo v := ci then used := used ++ v.value.getUsedConstants
  else if let .defnInfo v := ci then used := used ++ v.value.getUsedConstants
  -- Parent projections (`CommRing.toCommSemiring`) are themselves instances taking the
  -- *child* as an instance binder, so counting their binders reintroduces exactly the
  -- chain artifact this function exists to exclude. They are skipped.
  let isParentProjection (u : Name) : Bool :=
    let owner := u.getPrefix
    isStructure env owner && (getStructureParentInfo env owner).any (·.projFn == u)
  let mut out : NameSet := {}
  for u in used do
    -- Instances are *plumbing*: `instCommSemiringOfCommRing` takes `[CommRing R]` and
    -- says only that the elaborator threaded the declared binder somewhere, not that the
    -- argument needed it. A *lemma*'s instance binder is a real requirement, and lemmas
    -- are not instances. Dropping instances is what separates the two.
    if isParentProjection u || (← isInstance u) then continue
    -- Only a constant's *own* instance binders count as evidence. The projection chain
    -- (`CommRing.toCommSemiring`, `CommSemiring.toSemiring`, …) is in the elaborated
    -- statement too, but it is an artifact of how the statement was elaborated *given* the
    -- declared binder — counting it would make every declaration look at home, which is
    -- exactly the bug this rule replaced.
    for c in (← instanceClasses env u) do
      out := out.insert c
  return out

/-- One binder's verdict. -/
structure Verdict where
  /-- The class as declared. -/
  declared : Name
  /-- The ancestors of `declared` the declaration actually reaches. -/
  reached : Array Name
  /-- The weakest ancestor that dominates everything reached, when there is a single one. -/
  home : Option Name

/-- Walk one instance binder down the lattice. -/
def walk (env : Environment) (declared : Name) (reached : NameSet) : Verdict :=
  -- Strict ancestors only. The declared class reaches *itself* through Mathlib's derived
  -- shortcut instances (`instCommSemiringOfCommRing` and friends take `[CommRing R]`), and
  -- counting that would make every declaration look at home — which is the bug this rule
  -- replaced. A binder is at home when nothing weaker covers what is used.
  let anc := (ancestors env declared).erase declared
  -- Only ancestors matter: a class reached at *another* carrier says nothing about this
  -- binder, and including it would invent findings.
  let hit := anc.toList.filter (reached.contains ·) |>.toArray
  let hit := hit.qsort (fun a b => a.toString < b.toString)
  -- The home is the reached class that implies every other reached class — i.e. the one
  -- whose own ancestry covers the set. If several are incomparable there is no single
  -- home, and saying so beats picking one.
  let home := hit.find? fun candidate =>
    hit.all fun other => (ancestors env candidate).contains other
  { declared, reached := hit, home }

/-- `#fh_home <decl>` — where does this declaration actually live?

Reports, per instance binder, the classes its statement and proof reach and the weakest
ancestor that covers them. A home strictly weaker than the declared class is an
over-hypothesis **candidate**, confirmed by moving the declaration and re-checking it. -/
elab "#fh_home " n:ident : command => do
  let name ← liftCoreM <| realizeGlobalConstNoOverload n
  let env ← getEnv
  let some ci := env.find? name | throwErrorAt n s!"unknown declaration `{name}`"
  liftTermElabM do
    let reached ← reachedClasses env ci
    let levels ← ci.levelParams.mapM fun _ => mkFreshLevelMVar
    let (lines, candidates, carriers) : Array String × Nat × Array String ←
      forallTelescopeReducing (ci.instantiateTypeLevelParams levels) fun xs _ => do
      let mut lines : Array String := #[]
      let mut candidates := 0
      let mut carriers : Array String := #[]
      for x in xs do
        let d ← x.fvarId!.getDecl
        unless d.binderInfo == .instImplicit do continue
        let ty ← whnf d.type
        let .const cls _ := ty.getAppFn | continue
        -- The carrier the constraint is *about*. `instanceClasses`'s own doc comment has
        -- always promised this pairing; the implementation returned a bare `NameSet` and
        -- dropped it, which is what "home loses carrier identity" means concretely.
        let carrier : String ← match ty.getAppArgs.back? with
          | some c => do pure (toString (← ppExpr c))
          | none => pure "?"
        carriers := carriers.push carrier
        let v := walk env cls reached
        -- Asked first, and about the declared class itself: if some *lemma* requires it
        -- at this carrier, nothing weaker covers the use and the walk has no verdict to
        -- give. Asking this after the lattice walk reported an at-home binder as unused,
        -- because the walk deliberately looks only at strict ancestors.
        if reached.contains cls then
          lines := lines.push s!"  [{cls} {carrier}] — at home"
        else match v.home with
        | some h =>
            candidates := candidates + 1
            lines := lines.push
              s!"  [{cls} {carrier}] — CANDIDATE: reaches only {h}; weaken and re-check"
        | none =>
            if v.reached.isEmpty then
              -- The strongest finding there is: nothing needs this binder at all.
              candidates := candidates + 1
              lines := lines.push
                s!"  [{cls} {carrier}] — CANDIDATE: unused; nothing in the statement or proof needs it"
            else
              lines := lines.push
                s!"  [{cls} {carrier}] — reaches {v.reached.toList}, no single weakest ancestor"
      return (lines, candidates, carriers)
    let header :=
      if candidates == 0 then s!"FH home: `{name}` is at home"
      else s!"FH home: `{name}` has {candidates} over-hypothesis candidate(s) — \
             a candidate is confirmed by moving the declaration and re-checking it"
    -- The verdicts above share one `reached` set, which is a set of class *names* with no
    -- carrier attached. That is sound only while every binder is about the same carrier:
    -- with two, a class reached at `R` is indistinguishable from one reached at `S`, and a
    -- binder can be told it is over-strong on evidence belonging to its neighbour. Said
    -- rather than left for a reader to discover, because the walk's own comment already
    -- claims "a class reached at another carrier says nothing about this binder" — which
    -- the evidence cannot currently support.
    let distinct := carriers.toList.eraseDups
    let caveat :=
      if distinct.length > 1 then
        s!"\n  ⚠ binders span {distinct.length} carriers ({distinct}); the reached set is \
           carrier-blind, so these verdicts are approximate"
      else ""
    logInfo (header ++ "\n" ++ String.intercalate "\n" lines.toList ++ caveat)


/-! ## Confirmation — C4's second stage

`#fh_home` reports *candidates*. A candidate is a claim about what a proof needs, and the
only thing that settles it is putting the weaker hypothesis in front of the kernel. Until
now that was done by hand: `Tests/Atlas/Home.lean` carries `overh_confirmed` beside
`overh`, written out and compiled by a human.

The construction is deliberately blunt. The declaration's type is a nest of `forallE`;
walk it, replace the candidate binder's domain `C args` with `H args` for the weaker class
`H`, and leave everything else alone. Binder *count* and *order* are untouched, so every de
Bruijn index in the body still resolves to what it did and the proof term needs no
rewriting at all — which is what makes this one kernel call rather than a re-elaboration.

The kernel then answers the real question. A proof that only ever used the weaker class's
operations typechecks; one that projects a field `H` does not have is rejected, and that
rejection is the evidence that the binder is *not* an over-hypothesis. Both outcomes are
findings.
-/

/-- Replace the domain of the `i`-th instance-implicit binder with `repl`, keeping the
binder structure identical so the body's de Bruijn indices stay valid. -/
private def weakenBinder (ty : Expr) (i : Nat) (repl : Name) : Option Expr :=
  go ty 0
where
  go (e : Expr) (seen : Nat) : Option Expr :=
    match e with
    | .forallE n d b bi =>
      if bi == .instImplicit then
        if seen == i then
          -- Same arguments, weaker head: `CommRing R` becomes `AddCommMagma R`.
          let d' := mkAppN (.const repl (d.getAppFn.constLevels!)) d.getAppArgs
          some (.forallE n d' b bi)
        else (go b (seen + 1)).map (.forallE n d · bi)
      else (go b seen).map (.forallE n d · bi)
    | _ => none

/-- `#fh_home_confirm <decl>` — put every candidate in front of the kernel.

Reports, per candidate binder, whether the declaration's own proof still typechecks with
the weaker class, and how long the attempt took. The timing is the point as much as the
verdict: it is the number that decides whether confirmation can run over a corpus or only
over a shortlist, and scoping that milestone without it would be inventing a cost. -/
elab "#fh_home_confirm " n:ident : command => do
  let name ← liftCoreM <| realizeGlobalConstNoOverload n
  let env ← getEnv
  let some ci := env.find? name | throwErrorAt n s!"unknown declaration `{name}`"
  let some value := (match ci with
    | .thmInfo v => some v.value
    | .defnInfo v => some v.value
    | _ => none) | throwErrorAt n s!"`{name}` has no value to re-check"
  liftTermElabM do
    let reached ← reachedClasses env ci
    let levels ← ci.levelParams.mapM fun _ => mkFreshLevelMVar
    let mut idx := 0
    let mut lines : Array String := #[]
    let binders ← forallTelescopeReducing (ci.instantiateTypeLevelParams levels) fun xs _ => do
      let mut out : Array Name := #[]
      for x in xs do
        let d ← x.fvarId!.getDecl
        unless d.binderInfo == .instImplicit do continue
        let .const cls _ := (← whnf d.type).getAppFn | continue
        out := out.push cls
      return out
    for cls in binders do
      let v := walk env cls reached
      if !reached.contains cls then
        if let some h := v.home then
          match weakenBinder ci.type idx h with
          | none => lines := lines.push s!"  [{cls}] -> {h}: could not rebuild the binder"
          | some ty' =>
            let t0 ← IO.monoMsNow
            -- Anonymous constructor rather than named fields: `type` lexes as a token
            -- in structure-instance position, so `type := ty'` will not parse here.
            -- `TheoremVal` extends `ConstantVal`, hence the nesting.
            let probe := name ++ `fh_weakened
            let decl := Declaration.thmDecl
              ⟨⟨probe, ci.levelParams, ty'⟩, value, [probe]⟩
            -- The kernel is the oracle. `addDecl` on a throwaway name, and the environment
            -- is discarded either way: this asks a question, it does not extend anything.
            -- `addDecl` does **not** answer this question. Its kernel check surfaces as a
            -- separately-logged error rather than as an exception a `try` can see, so the
            -- first version of this command reported CONFIRMED for a declaration the
            -- kernel had just rejected — including for `needsit`, whose proof genuinely
            -- needs `CommRing`. A confirmation tool that says "confirmed" when the kernel
            -- refuses is worse than no tool.
            --
            -- `addDeclCore` returns an `Except` instead, so the verdict is a value and
            -- cannot escape. The environment it returns is discarded: this asks a
            -- question, it does not extend anything.
            let ok := ((← getEnv).addDeclCore 0 decl none).toOption.isSome
            let ms := (← IO.monoMsNow) - t0
            -- The asymmetry is real and must not be flattened. Acceptance is a proof:
            -- the declaration's own term typechecks against the weaker hypothesis, so the
            -- binder was an over-hypothesis. **Rejection proves nothing**, because the
            -- elaborator baked instance projections into the value when it was first
            -- checked — `add_comm a b` under `[CommRing R]` carries
            -- `CommRing.toCommSemiring`, and retyping the binder breaks that chain whether
            -- or not the proof needed the strength. Measured on B3's own fixture: `overh`
            -- is a *known* over-hypothesis (`overh_confirmed` compiles by hand) and this
            -- test rejects it.
            --
            -- Settling a rejection means re-synthesising the value's instance arguments in
            -- the weakened context, which is C4's re-elaboration proper. Until that exists
            -- the negative outcome is INCONCLUSIVE, and calling it "refuted" would be
            -- reporting a false negative as a finding.
            lines := lines.push <|
              if ok then
                s!"  [{cls}] -> {h}: CONFIRMED in {ms}ms — the term typechecks without {cls}"
              else
                s!"  [{cls}] -> {h}: INCONCLUSIVE in {ms}ms — retyping alone cannot settle \
                   this; the value's instance projections are baked to {cls} and need \
                   re-synthesis"
      idx := idx + 1
    if lines.isEmpty then
      logInfo s!"FH home: `{name}` has no candidate to confirm"
    else
      logInfo <| s!"FH home confirm: `{name}`\n" ++ "\n".intercalate lines.toList

end FerrisHoward.Atlas
