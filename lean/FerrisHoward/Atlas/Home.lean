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
    let (lines, candidates) ←
      forallTelescopeReducing (ci.instantiateTypeLevelParams levels) fun xs _ => do
      let mut lines : Array String := #[]
      let mut candidates := 0
      for x in xs do
        let d ← x.fvarId!.getDecl
        unless d.binderInfo == .instImplicit do continue
        let .const cls _ := (← whnf d.type).getAppFn | continue
        let v := walk env cls reached
        -- Asked first, and about the declared class itself: if some *lemma* requires it
        -- at this carrier, nothing weaker covers the use and the walk has no verdict to
        -- give. Asking this after the lattice walk reported an at-home binder as unused,
        -- because the walk deliberately looks only at strict ancestors.
        if reached.contains cls then
          lines := lines.push s!"  [{cls}] — at home"
        else match v.home with
        | some h =>
            candidates := candidates + 1
            lines := lines.push
              s!"  [{cls}] — CANDIDATE: reaches only {h}; weaken and re-check"
        | none =>
            if v.reached.isEmpty then
              -- The strongest finding there is: nothing needs this binder at all.
              candidates := candidates + 1
              lines := lines.push
                s!"  [{cls}] — CANDIDATE: unused; nothing in the statement or proof needs it"
            else
              lines := lines.push
                s!"  [{cls}] — reaches {v.reached.toList}, no single weakest ancestor"
      return (lines, candidates)
    let header :=
      if candidates == 0 then s!"FH home: `{name}` is at home"
      else s!"FH home: `{name}` has {candidates} over-hypothesis candidate(s) — \
             a candidate is confirmed by moving the declaration and re-checking it"
    logInfo (header ++ "\n" ++ String.intercalate "\n" lines.toList)

end FerrisHoward.Atlas
