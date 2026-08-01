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

/-- FH identifiers may not end in `?` or `!` (A0.6).

Lean's lexer treats both as identifier characters, so `maybe_val?` is *one* identifier and
`x?` would never reach FH as `x` followed by the bind operator. FH reserves the two
suffixes rather than teaching its lexer to split them: the consumers are `?`-as-do (A2.3)
and `!` (A1.5), and rejecting now keeps the option of splitting later — the reverse would
be a breaking change.

Checked at expansion time with an exact span, for the same reason F6 is (the parser cannot
emit custom wording; corpus-review F6 as amended). -/
def checkIdent (x : Ident) : MacroM Unit := do
  for c in x.getId.components do
    if let .str _ s := c then
      if s.endsWith "?" || s.endsWith "!" then
        Macro.throwErrorAt x
          s!"FH: `{s}` — an identifier may not end in `?` or `!`; Lean's lexer would swallow \
             the operator into the name"

/-- Join a `::` path into a single Lean name: `Nat::Prime::dvd_mul` is the identifier
`Nat.Prime.dvd_mul`. Design §6's no-mangling policy means this is all the "bridge" a
Mathlib name needs.

Only identifiers compose; `f(x)::g` is a syntax-level error rather than a silent
reinterpretation as field access, which is a different operation with different
resolution. -/
private def joinPath (lhs : TSyntax `term) (field : Ident) (ref : Syntax) : MacroM (TSyntax `term) := do
  checkIdent field
  unless lhs.raw.isIdent do
    Macro.throwErrorAt ref "FH: `::` joins identifiers; for a value's field or method use `.`"
  return mkIdentFrom ref (lhs.raw.getId ++ field.getId)

mutual

/-- Translate an FH expression to a Lean term.

Both term and type positions go through here — there is one expression grammar
(design §4.1), so there is one translation. -/
partial def expandExpr (e : TSyntax `fh_expr) : MacroM (TSyntax `term) :=
  withRef e do
    match e with
    -- user syntax, untouched: the ident node keeps the user's span
    | `(fh_expr| $x:ident) => do checkIdent x; pure ⟨x.raw⟩
    | `(fh_expr| $n:num) => pure ⟨n.raw⟩
    | `(fh_expr| ($inner)) => do
        let inner ← expandExpr inner
        `(($inner))
    | `(fh_expr| $f($args,*)) => do
        let f ← expandExpr f
        let args ← args.getElems.mapM expandExpr
        `($f $args*)
    | `(fh_expr| $recv.$field:ident) => do
        checkIdent field
        let recv ← expandExpr recv
        `($recv.$field)
    | `(fh_expr| $lhs :: $field:ident) => do
        joinPath (← expandExpr lhs) field e
    | `(fh_expr| match $scrut { $[$pats => $rhss],* }) => do
        let scrut ← expandExpr scrut
        let alts ← pats.zip rhss |>.mapM fun (p, r) => do
          let p ← expandPat p
          let r ← expandExpr r
          `(matchAltExpr| | $p => $r)
        `(match $scrut:term with $alts:matchAlt*)
    | `(fh_expr| |$ps,*| $body) => do
        let binders ← ps.getElems.mapM fun p => do
          let b ← expandBinderPat p
          pure (⟨b.raw⟩ : TSyntax ``funBinder)
        let body ← expandExpr body
        `(fun $binders* => $body)
    | `(fh_expr| todo!()) => `(fh_todo%)
    | `(fh_expr| todo!($msg:str)) => `(fh_todo% $msg)
    | `(fh_expr| let $p $[: $ty]? = $val; $rest) => do
        let p ← expandBinderPat p
        let val ← expandExpr val
        let rest ← expandExpr rest
        match ty with
        | some ty => do
            let ty ← expandExpr ty
            `(let $p : $ty := $val; $rest)
        | none => `(let $p := $val; $rest)
    | _ => Macro.throwErrorAt e "FH: no expansion for this expression form"

/-- Translate an FH pattern to a Lean pattern (which is a term).

Whether a bare identifier binds or matches a constructor is Lean's rule, inherited
verbatim — the same rule Rust has, so nothing needs explaining to a Rust reader. -/
partial def expandPat (p : TSyntax `fh_pat) : MacroM (TSyntax `term) :=
  withRef p do
    match p with
    | `(fh_pat| $x:ident) => do checkIdent x; pure ⟨x.raw⟩
    | `(fh_pat| _) => `(_)
    | `(fh_pat| $n:num) => pure ⟨n.raw⟩
    | `(fh_pat| $lhs :: $field:ident) => do
        joinPath (← expandPat lhs) field p
    | `(fh_pat| $ctor($args,*)) => do
        let ctor ← expandPat ctor
        let args ← args.getElems.mapM expandPat
        `($ctor $args*)
    | _ => Macro.throwErrorAt p "FH: no expansion for this pattern"

/-- Translate an FH pattern used in *binder* position to a Lean binder identifier.

Only the two irrefutable forms are legal here; destructuring parameter patterns
(`fn f((a, b): (Nat, Nat))`) are a later question, not an M0 one. -/
partial def expandBinderPat (p : TSyntax `fh_pat) : MacroM (TSyntax [`ident, ``Lean.Parser.Term.hole]) :=
  withRef p do
    match p with
    | `(fh_pat| $x:ident) => do checkIdent x; pure ⟨x.raw⟩
    | `(fh_pat| _) => do let h ← `(_); pure ⟨h.raw⟩
    | _ => Macro.throwErrorAt p "FH: this pattern is not allowed in binder position"

end

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
needs no setting — with `autoImplicit` off it is not consulted (verified on-toolchain).

`unusedVariables` is switched off for `sorry`-valued declarations only. A bodyless `fn`
declares an interface and has no body to use its parameters in, so the linter would fire
on every conjecture stub — the one thing design §1 promises FH is good at. The
`declaration uses 'sorry'` warning is untouched: that one is the point. -/
def fhDecl (d : TSyntax `command) (sorryValued : Bool := false) : MacroM (TSyntax `command) := do
  let d ← if sorryValued then `(command| set_option linter.unusedVariables false in $d) else pure d
  `(command| set_option autoImplicit false in $d)

end FerrisHoward
