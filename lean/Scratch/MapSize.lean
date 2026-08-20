/-
Copyright (c) 2026 Ferris-Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib.Algebra.Order.Field.Basic

/-!
# How much of the formal record does the Atlas actually read?

Every index in this project is built from `ConstantInfo.type`. The proof term is computed by
the extractor and then thrown away — `atlas-extract/FhAtlas/Extract.lean:111` reduces it to a
sorted list of constant *names*.

So the question "is the formal corpus too sparse to mine" has a prior question: **what
fraction of the corpus have we been reading at all?** If a theorem's proof term is the same
size as its statement, then statements are most of the record and sparsity is the real
limit. If proof terms are an order of magnitude larger, then the corpus is far richer than
anything measured so far, and the limit has been the projection rather than the territory.

This measures it. No sampling: every theorem in the import closure, exact node counts.

`.thmInfo` directly rather than `ConstantInfo.value?`, which returns `none` for a theorem on
this toolchain — the trap that once made `uses_proof` empty for all 33,521 theorems in
Mathlib.
-/

open Lean

/-- Expression nodes, counted structurally. `Expr` is a DAG in memory, and this deliberately
counts the *tree* — two occurrences of a subterm are two occurrences, which is what an
index over subterms would have to key. -/
partial def nodes : Expr → Nat
  | .app f a => 1 + nodes f + nodes a
  | .lam _ d b _ => 1 + nodes d + nodes b
  | .forallE _ d b _ => 1 + nodes d + nodes b
  | .letE _ t v b _ => 1 + nodes t + nodes v + nodes b
  | .mdata _ e => 1 + nodes e
  | .proj _ _ e => 1 + nodes e
  | _ => 1

structure Tally where
  n : Nat := 0
  stmt : Nat := 0
  prf : Nat := 0
  /-- Theorems whose proof term is at least ten times its statement. -/
  heavy : Nat := 0
  maxRatio : Nat := 0
  deriving Inhabited

unsafe def main : IO UInt32 := do
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := `Mathlib.Algebra.Order.Field.Basic }] {}
  let mut t : Tally := {}
  for (name, info) in env.constants.toList do
    if name.isInternalDetail then continue
    -- A theorem's proof lives in `thmInfo.value`; `value?` hands back `none` for it.
    let some v := (match info with | .thmInfo ti => some ti.value | _ => none) | continue
    let s := nodes info.type
    let p := nodes v
    t := { t with
      n := t.n + 1, stmt := t.stmt + s, prf := t.prf + p,
      heavy := if p ≥ 10 * s then t.heavy + 1 else t.heavy,
      maxRatio := max t.maxRatio (if s == 0 then 0 else p / s) }
  IO.println s!"theorems            : {t.n}"
  IO.println s!"statement nodes     : {t.stmt}"
  IO.println s!"proof-term nodes    : {t.prf}"
  if t.stmt > 0 then
    IO.println s!"proof/statement     : {t.prf / t.stmt}x  (integer ratio of totals)"
  IO.println s!"proof >= 10x stmt   : {t.heavy}  ({t.heavy * 100 / (max t.n 1)}%)"
  IO.println s!"largest single ratio: {t.maxRatio}x"
  return 0
