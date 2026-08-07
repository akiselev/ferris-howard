import Lean
open Lean Elab Command Term

/-!
E11 (I6): can a post-elaboration audit see coercion insertions, and can it tell a
*licensed* one from a silent one?

Run: `lake env lean Tests/feasibility/e11_coe_audit.lean`

Result (v4.32.2): `Lean.Elab.Term.mkCoe` pushes a `CoeExpansionTrace` custom info leaf at
every insertion, carrying the syntax ref. Both the expected-type path and the `binop%`
max-type path produce leaves; a clean declaration produces none; an explicit `↑` produces
one whose ref is the `↑` node. So licensing by syntax ref works, and no FH term needs a
stage-two wrapper. See `coercion-control.md`.
-/

def collectCoe (t : InfoTree) : Array (String × String) :=
  t.foldInfo (init := #[]) fun _ctx i acc =>
    match i with
    | .ofCustomInfo ci =>
      match ci.value.get? CoeExpansionTrace with
      | some tr => acc.push (toString ci.stx, toString tr.expandedCoeDecls)
      | none => acc
    | _ => acc

elab "#coe_audit " "in " cmd:command : command => do
  let s ← get
  modify fun st => { st with infoState := { st.infoState with trees := {} } }
  elabCommandTopLevel cmd
  let trees := (← get).infoState.trees
  let hits := trees.toArray.flatMap collectCoe
  modify fun st => { st with infoState := s.infoState }
  logInfo m!"coercion insertions: {hits.size}\n{hits.map (fun (a, b) => a ++ " => " ++ b)}"

-- (1) expected-type coercion, via `ensureHasType` → `mkCoe`: 1 hit, ref = the ascription
#coe_audit in
def x : Int := (5 : Nat)

-- (2) `binop%` max-type coercion: 1 hit, ref = the coerced leaf `n`
#coe_audit in
def y (n : Nat) (i : Int) : Int := n + i

-- (3) no coercion: 0 hits (the audit does not fire on clean code)
#coe_audit in
def z (n : Nat) : Nat := n + 1

-- (4) explicit `↑`: 1 hit, ref = the `↑` node — this is how FH licenses `e as T`
#coe_audit in
def w (n : Nat) : Int := (↑n : Int)
