/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Syntax.Basic

/-!
# Stage-one translation helpers

Everything here is **stage one**: FH surface syntax → Lean *surface* syntax, in `MacroM`
(design §2, ground rule 2). No `elab_rules`, no environment access.

## Span discipline (ground rule 3)

Two rules, mechanically checked by the span tier from M0:

1. User syntax passes through **untouched** — `expandExpr` returns the very ident/literal
   node the user wrote, so its position is exactly theirs.
2. Every *synthesized* node is built under `withRef` of the FH source node it comes from,
   so quotation-generated syntax inherits that span rather than defaulting to the whole
   command.

Never re-parse strings.
-/

namespace FerrisHoward
open Lean Lean.Parser.Term

/-- Translate an FH expression to a Lean term.

Both term and type positions go through here — there is one expression grammar
(design §4.1), so there is one translation. -/
partial def expandExpr (e : TSyntax `fh_expr) : MacroM (TSyntax `term) :=
  withRef e do
    match e with
    -- user syntax, untouched: the ident node keeps the user's span
    | `(fh_expr| $x:ident) => pure ⟨x.raw⟩
    | `(fh_expr| $n:num) => pure ⟨n.raw⟩
    | `(fh_expr| ($inner)) => do
        let inner ← expandExpr inner
        `(($inner))
    | `(fh_expr| $f($args,*)) => do
        let f ← expandExpr f
        let args ← args.getElems.mapM expandExpr
        `($f $args*)
    | _ => Macro.throwErrorAt e "FH: no expansion for this expression form"

/-- Translate an FH pattern used in *binder* position to a Lean binder identifier.

Only the two irrefutable forms are legal here; destructuring parameter patterns
(`fn f((a, b): (Nat, Nat))`) are an A0.2 question, not an M0 one. -/
def expandBinderPat (p : TSyntax `fh_pat) : MacroM (TSyntax [`ident, ``Lean.Parser.Term.hole]) :=
  withRef p do
    match p with
    | `(fh_pat| $x:ident) => pure ⟨x.raw⟩
    | `(fh_pat| _) => do let h ← `(_); pure ⟨h.raw⟩
    | _ => Macro.throwErrorAt p "FH: this pattern is not allowed in binder position"

/-- Build one explicit binder `(p : T)`.

Parentheses parameters are **explicit** binders (design §4.2); angle-bracket generics
become implicits at A1.3. -/
def expandParam (p : TSyntax `fh_pat) (t : TSyntax `fh_expr) :
    MacroM (TSyntax ``bracketedBinderF) := do
  let p ← expandBinderPat p
  let t ← expandExpr t
  `(bracketedBinderF| ($p : $t))

/-- Wrap a generated declaration in the declaration-scoped options every FH expansion
carries.

`autoImplicit false` is **no-auto-bind from day one** (PLAN A0.1, F17's hard rule): an
identifier resolving to neither a declaration nor an in-scope binder is an error, never a
fresh universally quantified variable. Mathlib disabled `autoImplicit` globally for
exactly the reason FH refuses it by construction — a typo'd name silently becoming a
quantified type variable yields vacuous theorems.

This is stage one on purpose: `set_option … in` is a command combinator, so the rule is
expressed in the expansion itself rather than in a bespoke elaborator, and it is visible
in the golden tier where a semantic commitment of this size belongs. `relaxedAutoImplicit`
needs no setting — with `autoImplicit` off it is not consulted (verified on-toolchain). -/
def fhDecl (d : TSyntax `command) : MacroM (TSyntax `command) :=
  `(command| set_option autoImplicit false in $d)

end FerrisHoward
