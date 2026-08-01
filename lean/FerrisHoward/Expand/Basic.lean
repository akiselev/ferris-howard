/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Bridge.Methods
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

/-- `f a b`, for the constant `f`.

Ruling A's operators expand to the underlying constants — `Eq`, `And`, `LE.le` — and not
to Lean's `=`, `∧`, `≤` notations, which are `binop%`/`binrel%` macros that insert
coercions during unification. Disabling silent coercion (F9) is exactly what I6 decided
FH does by *not* going through those elaborators (`coercion-control.md`); this function is
where that decision lives. It costs golden readability (`Eq a b`, not `a = b`) and buys
the property that a coercion in FH-authored code is one the author wrote. -/
private def app2 (c : Name) (a b : TSyntax `term) : MacroM (TSyntax `term) := do
  let f := mkIdent c
  `($f $a $b)

/-- `f a`, for the constant `f`. -/
private def app1 (c : Name) (a : TSyntax `term) : MacroM (TSyntax `term) := do
  let f := mkIdent c
  `($f $a)

/-- F2's rule, made concrete: a type ascription distributes over the **unascribed prefix**
before it, so `for<a, b, c: Self>` binds all three at `Self` and `for<a: A, b: B>` binds
each at its own. Walking right to left is the whole implementation: every parameter takes
the nearest ascription to its right.

Trailing unascribed parameters — `for<a, b>` with no ascription anywhere after them — get
a hole and are inferred, which is what a reader of `∀ a b, …` expects.

Rust's generic lists bind only the last parameter, so this is a divergence and not an
oversight; it is on the differences page for that reason. -/
private def distributeAscriptions (ps : Array (TSyntax ``fhGenericParam)) :
    MacroM (Array (Ident × Option (TSyntax `fh_expr))) := do
  let mut out : Array (Ident × Option (TSyntax `fh_expr)) := #[]
  let mut pending : Option (TSyntax `fh_expr) := none
  for p in ps.reverse do
    match p with
    | `(fhGenericParam| $x:ident : $t) =>
        checkIdent x
        pending := some t
        out := out.push (x, some t)
    | `(fhGenericParam| $x:ident) =>
        checkIdent x
        out := out.push (x, pending)
    | _ => Macro.throwErrorAt p "FH: no expansion for this binder"
  return out.reverse

mutual

/-- Translate an FH expression to a Lean term.

Both term and type positions go through here — there is one expression grammar
(design §4.1), so there is one translation. -/
partial def expandExpr (e : TSyntax `fh_expr) : MacroM (TSyntax `term) :=
  withRef e do
    match e with
    -- user syntax, untouched: the ident node keeps the user's span
    | `(fh_expr| $x:ident) => do
        checkIdent x
        -- Lean's lexer takes `p.dvd` as a *single* identifier, so the `.` production below
        -- never sees it and the F16 table has to apply here too. Splitting the last
        -- component off is safe precisely because FH distinguishes the two operators: `::`
        -- composes names and never routes through this case, so `IsUnit::dvd` still means
        -- the constant, while `p.dvd` means the notation.
        -- Lean's lexer takes `p.dvd` as a *single* identifier, so a dotted one is routed
        -- through the same hook as the `.` production. With no bridge in scope the
        -- default rule rebuilds exactly this identifier, so nothing changes.
        match x.getId with
        | .str p last =>
          if p == .anonymous then pure ⟨x.raw⟩
          else
            let recv := mkIdentFrom x p
            let m := mkIdentFrom x (Name.mkSimple last)
            `(fh_dot% $recv $m)
        | _ => pure ⟨x.raw⟩
    | `(fh_expr| $n:num) => pure ⟨n.raw⟩
    | `(fh_expr| Prop) => `(Prop)
    | `(fh_expr| ($inner)) => do
        let inner ← expandParenthesised inner
        `(($inner))
    | `(fh_expr| ($first, $rest,*)) => do
        let first ← expandParenthesised first
        let rest ← rest.getElems.mapM expandParenthesised
        let all := #[first] ++ rest
        `(⟨$all,*⟩)
    | `(fh_expr| ($e : $t)) => do
        let e ← expandParenthesised e
        let t ← expandExpr t
        `(($e : $t))
    | `(fh_expr| $f($args,*)) => do
        let f ← expandExpr f
        let args ← args.getElems.mapM expandExpr
        `($f $args*)
    | `(fh_expr| $recv.$field:ident) => do
        checkIdent field
        let recv ← expandExpr recv
        -- The method-spelling hook (F16): a bridge brought into scope by `use lean::C;`
        -- decides what the spelling means; with none in scope this is Lean's generalized
        -- dot notation, unchanged (design §4.7).
        `(fh_dot% $recv $field)
    | `(fh_expr| {$x:ident : $ty | $body}) => do
        checkIdent x
        let ty ← expandExpr ty
        let body ← expandParenthesised body
        `(fh_comprehension% (fun ($x : $ty) => $body))
    | `(fh_expr| { $inner }) => expandParenthesised inner
    | `(fh_expr| $f<$args,*>) => do
        let f ← expandExpr f
        let args ← args.getElems.mapM expandExpr
        `($f $args*)
    | `(fh_expr| $lhs :: $field:ident) => do
        joinPath (← expandExpr lhs) field e
    | `(fh_expr| match $scrut { $[$pats => $rhss],* }) => do
        let scrut ← expandExpr scrut
        let alts ← pats.zip rhss |>.mapM fun (p, r) => do
          let p ← expandPat p
          let r ← expandExpr r
          `(matchAltExpr| | $p => $r)
        `(match $scrut:term with $alts:matchAlt*)
    | `(fh_expr| for<$ps,*> $body) => do
        let binders ← quantBinders ps.getElems
        let body ← expandExpr body
        `(∀ $binders*, $body)
    | `(fh_expr| exists<$ps,*> $body) => do
        let binders ← existsBinders ps.getElems
        let body ← expandExpr body
        -- `explicitBinders` is a single-child choice node whose child, for the bracketed
        -- branch, is a null node of binders; `expandExplicitBinders` reads exactly that
        -- shape. Splicing into the quotation produces a different one, which elaborates
        -- to an `Exists` that binds nothing — silently.
        let eb := mkNode ``Lean.explicitBinders #[mkNullNode (binders.map (·.raw))]
        `(∃ $(⟨eb⟩):explicitBinders, $body)
    | `(fh_expr| |$ps,*| $body) => do
        let binders ← ps.getElems.mapM fun p => do
          let b ← expandBinderPat p
          pure (⟨b.raw⟩ : TSyntax ``funBinder)
        let body ← expandExpr body
        `(fun $binders* => $body)
    -- Ruling A's operator set (A1.5); the F7 precedence table lives in the grammar module
    | `(fh_expr| $a -> $b) => do
        let a ← expandExpr a; let b ← expandExpr b
        `($a → $b)
    | `(fh_expr| $a <-> $b) => do app2 ``Iff (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a || $b) => do app2 ``Or (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a && $b) => do app2 ``And (← expandExpr a) (← expandExpr b)
    | `(fh_expr| !$a) => do app1 ``Not (← expandExpr a)
    | `(fh_expr| $a == $b) => do app2 ``Eq (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a != $b) => do app2 ``Ne (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a <= $b) => do app2 ``LE.le (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $_a < $_b) =>
        -- F6, enforced at expansion time with a fixed message and an exact span (the
        -- parser cannot word it; corpus-review F6 as amended). One rule, everywhere:
        -- `<` can open a generic argument list, so a comparison wears parentheses.
        Macro.throwErrorAt e
          "FH: parenthesise this comparison — `(a < b)`. A bare `<` could open a generic \
           argument list"
    | `(fh_expr| $a >= $b) => do app2 ``GE.ge (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a > $b) => do app2 ``GT.gt (← expandExpr a) (← expandExpr b)
    -- `Membership.mem` takes the container first, the element second
    | `(fh_expr| $a in $b) => do app2 ``Membership.mem (← expandExpr b) (← expandExpr a)
    | `(fh_expr| $e as $t) => do
        let e ← expandExpr e
        let t ← expandExpr t
        -- `↑` under the `as` node's ref, so the audit can tell this coercion from one
        -- Lean inserted on its own (`coercion-control.md`).
        `((↑$e : $t))
    | `(fh_expr| $a + $b) => do app2 ``HAdd.hAdd (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a - $b) => do app2 ``HSub.hSub (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a * $b) => do app2 ``HMul.hMul (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a / $b) => do app2 ``HDiv.hDiv (← expandExpr a) (← expandExpr b)
    | `(fh_expr| $a % $b) => do app2 ``HMod.hMod (← expandExpr a) (← expandExpr b)
    | `(fh_expr| -$a) => do app1 ``Neg.neg (← expandExpr a)
    | `(fh_expr| if $c { $a } else { $b }) => do
        let c ← expandExpr c
        let a ← expandExpr a
        let b ← expandExpr b
        `(if $c then $a else $b)
    | `(fh_expr| if $h:ident @ $c { $a } else { $b }) => do
        checkIdent h
        let c ← expandExpr c
        let a ← expandExpr a
        let b ← expandExpr b
        `(if $h:ident : $c then $a else $b)
    | `(fh_expr| lean! { $ts }) => `(by $ts)
    -- `todo!` expands to Lean's own `sorry`, so the declaration carries `sorryAx` and
    -- the emitted artifact stays FH-free (ADR-006). The message is a *diagnostic* and
    -- lands in `FerrisHoward/Lint/Todo.lean`, not in the translation.
    | `(fh_expr| todo!()) => `(sorry)
    | `(fh_expr| todo!($_msg:str)) => `(sorry)
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

/-- Quantifier binders: F2's distributed ascriptions, as Lean bracketed binders. -/
partial def quantBinders (ps : Array (TSyntax ``fhGenericParam)) :
    MacroM (Array (TSyntax ``bracketedBinderF)) := do
  (← distributeAscriptions ps).mapM fun (x, t?) =>
    match t? with
    | some t => do
        let t ← expandExpr t
        `(bracketedBinderF| ($x : $t))
    | none => `(bracketedBinderF| ($x : _))

/-- The same binders for `∃`, whose notation takes `bracketedExplicitBinders` rather than
Lean's general bracketed binders — and requires the annotation, so an inferred binder is
spelled `(x : _)`. -/
partial def existsBinders (ps : Array (TSyntax ``fhGenericParam)) :
    MacroM (Array (TSyntax ``Lean.bracketedExplicitBinders)) := do
  (← distributeAscriptions ps).mapM fun (x, t?) => do
    let t ← match t? with
      | some t => expandExpr t
      | none => `(_)
    -- Each element must be a `binderIdent` *node*, not a bare ident: Lean's
    -- `expandExplicitBinders` reads `idents[i][0]`, so a cast ident silently becomes an
    -- anonymous binder and the body's occurrences stop resolving.
    let b ← `(Lean.binderIdent| $x:ident)
    `(bracketedExplicitBinders| ($b : $t))

/-- The one position where a `<` comparison needs no parentheses of its own: directly
inside a pair. This is F6's escape, and the reason the rule is stated as "parenthesise it"
rather than "you cannot write it". -/
partial def expandParenthesised (e : TSyntax `fh_expr) : MacroM (TSyntax `term) :=
  withRef e do
    match e with
    | `(fh_expr| $a < $b) => do app2 ``LT.lt (← expandExpr a) (← expandExpr b)
    | _ => expandExpr e

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
