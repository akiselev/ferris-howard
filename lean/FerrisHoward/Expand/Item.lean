/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Expand.Basic

/-!
# Item expansion (stage one)

Every FH item routes through `expandItem`, and the only `macro_rules` in the language
dispatches the command wrapper to it. One dispatch point means the golden printer, the
future `.fh` driver, and nested items (`mod { … }`) all share the same translation rather
than re-deriving it.
-/

namespace FerrisHoward
open Lean Lean.Parser.Term Lean.Parser.Command

/-! ## Attributes -/

/-- What an item's `#[…]` groups add up to: some attributes are consumed by FH, the rest
pass through to Lean. -/
structure AttrSet where
  /-- `#[def]`: `type X = e;` becomes a `def` rather than an `abbrev`. -/
  defOptOut : Bool := false
  /-- Attributes passed through verbatim (design §3's `#[attr]` → `@[attr]` row). -/
  «lean» : TSyntaxArray ``attrInstance := #[]
  deriving Inhabited

/-- Fold one attribute into the set. -/
private def addAttr (s : AttrSet) (a : TSyntax `fh_attr) : MacroM AttrSet :=
  withRef a do
    match a with
    | `(fh_attr| def) => return { s with defOptOut := true }
    | `(fh_attr| instance) =>
        return { s with «lean» := s.lean.push (← `(attrInstance| instance)) }
    | `(fh_attr| $n:ident) =>
        return { s with «lean» := s.lean.push (← `(attrInstance| $n:ident)) }
    | `(fh_attr| $n:ident($_args,*)) =>
        if n.getId == `name then
          -- design §3: `#[name(…)]` names the instance an `impl` would otherwise leave
          -- anonymous. Every M0 item already carries its own name, so there is nothing
          -- here for it to do yet.
          Macro.throwErrorAt a "FH: `#[name(…)]` names an anonymous `impl`, which arrives at A1.6"
        else
          Macro.throwErrorAt a
            s!"FH: `#[{n.getId}(…)]` takes arguments, which are not supported yet; \
               attributes with arguments arrive with the features that use them"
    | _ => Macro.throwErrorAt a "FH: no expansion for this attribute"

/-- Fold an attribute group into the set. -/
private def addAttrs (s : AttrSet) (g : TSyntax ``fhAttrs) : MacroM AttrSet := do
  match g with
  | `(fhAttrs| #[$as,*]) => as.getElems.foldlM addAttr s
  | _ => Macro.throwErrorAt g "FH: no expansion for this attribute group"

/-- Attach `@[…]` to a generated declaration.

Lean has no syntax for attaching attributes to an *arbitrary* command, so this grafts the
`declModifiers` node of a throwaway declaration onto the generated one. The alternatives
were worse: writing an attributed and an unattributed quotation for every item kind
duplicates every builder, and a follow-up `attribute [attr] name` command is a different
thing from design §3's `#[attr]` → `@[attr]` row. Guarded — anything that is not a
declaration errors, which is exactly what `mod` and `use` should do. -/
private def withAttrs (attrs : AttrSet) (d : TSyntax `command) : MacroM (TSyntax `command) := do
  if attrs.lean.isEmpty then return d
  unless d.raw.getKind == ``Lean.Parser.Command.declaration do
    Macro.throwError "FH: attributes are not supported on this item"
  let attrList := attrs.lean
  let template ← `(command| @[$attrList,*] def fhAttrTemplate := ())
  return ⟨d.raw.setArg 0 template.raw[0]⟩

/-! ## Binders -/

/-- Angle-bracket generics → **implicit** binders (design §4.2). A bare `<T>` gets
`Type _`: design §4.3's "a bare `<T>` defaults to `Space<_>`", spelled in core Lean until
`Space` itself lands at A2.4. -/
private def expandGenerics (g? : Option (TSyntax ``fhGenerics)) :
    MacroM (Array (TSyntax ``bracketedBinderF)) := do
  let some g := g? | return #[]
  let `(fhGenerics| <$ps,*>) := g | Macro.throwErrorAt g "FH: no expansion for these generics"
  ps.getElems.mapM fun p =>
    withRef p do
      match p with
      | `(fhGenericParam| $x:ident : $t) => do
          checkIdent x
          let t ← expandExpr t
          `(bracketedBinderF| {$x : $t})
      | `(fhGenericParam| $x:ident) => do
          checkIdent x
          `(bracketedBinderF| {$x : Type _})
      | _ => Macro.throwErrorAt p "FH: no expansion for this generic parameter"

/-- `where` bounds → **instance** binders: `where R: CommRing + Finite` is
`[CommRing R] [Finite R]`. -/
private def expandWhere (w? : Option (TSyntax ``fhWhere)) :
    MacroM (Array (TSyntax ``bracketedBinderF)) := do
  let some w := w? | return #[]
  let `(fhWhere| where $bs,*) := w | Macro.throwErrorAt w "FH: no expansion for this `where` clause"
  let mut out := #[]
  for b in bs.getElems do
    match b with
    | `(fhWhereBound| $x:ident : $bounds) =>
        checkIdent x
        for bound in bounds.raw[0].getSepArgs do
          let c ← expandExpr ⟨bound⟩
          out := out.push (← `(bracketedBinderF| [$c $x]))
    | _ => Macro.throwErrorAt b "FH: no expansion for this `where` bound"
  return out

/-! ## Items -/

/-- Is this body a hole? `todo!()` gets the same linter treatment as a bodyless `fn`: a
stub has nothing to use its parameters in. -/
private def isTodo (e : TSyntax `fh_expr) : Bool :=
  e.raw.getKind == ``fhExprTodo

/-- The value of an `fn`: its body, or `sorry` for a bodyless declaration.

Design §3: `fn f(…) -> U;` is `def f … : U := sorry`. The `sorry` is deliberately Lean's
own, so the declaration carries `sorryAx` and every downstream honesty check —
`#print axioms`, the transitive-sorry scan in C5 — sees it without FH having to be
trusted. A0.4 adds the tracking report on top.

The `Bool` reports whether the body is `sorry`-valued, which `fhDecl` uses to decide
whether the unused-variable linter should be silenced for this declaration. -/
private def expandFnBody (b : TSyntax `fh_fn_body) : MacroM (TSyntax `term × Bool) :=
  withRef b do
    match b with
    | `(fh_fn_body| { $e }) => return (← expandExpr e, isTodo e)
    | `(fh_fn_body| ;) => return (← `(sorry), true)
    | _ => Macro.throwErrorAt b "FH: no expansion for this function body"

/-- One `enum` variant → one Lean constructor.

A variant's fields are either all named or all unnamed, as in Rust, where those are two
different variant shapes. Named fields become binders (`| Succ (pred : N) : N`), keeping
the name visible in goals and available to named arguments; unnamed ones become an arrow
chain (`| Cons : T → E`). Mixing is an error rather than a silent choice. -/
private def expandVariant (enumName : Ident) (v : TSyntax ``fhEnumVariant) : MacroM (TSyntax ``ctor) :=
  withRef v do
    match v with
    | `(fhEnumVariant| $c:ident) => do
        checkIdent c
        `(ctor| | $c:ident : $enumName:ident)
    | `(fhEnumVariant| $c:ident($fs,*)) => do
        checkIdent c
        let fields ← fs.getElems.mapM fun f =>
          match f with
          | `(fhEnumField| $n:ident : $t) => do checkIdent n; return (some n, ← expandExpr t)
          | `(fhEnumField| $t:fh_expr) => return (none, ← expandExpr t)
          | _ => Macro.throwErrorAt f "FH: no expansion for this enum field"
        let named := fields.filter (·.1.isSome)
        if named.size == fields.size then
          let binders ← fields.mapM fun (n, t) => `(bracketedBinderF| ($(n.get!) : $t))
          `(ctor| | $c:ident $binders* : $enumName:ident)
        else if named.isEmpty then
          let mut ty : TSyntax `term := enumName
          for (_, t) in fields.reverse do ty ← `($t → $ty)
          `(ctor| | $c:ident : $ty)
        else
          Macro.throwErrorAt v
            "FH: an enum variant's fields must be either all named or all unnamed"
    | _ => Macro.throwErrorAt v "FH: no expansion for this enum variant"

/-- A declaration's binders, in Mathlib's order: implicit generics, then the instance
binders a `where` clause asks for, then the explicit parameters. Implicits and instances
are both inferred at call sites, so the order is a readability choice, not an interface
one. -/
private def allBinders (gs : Option (TSyntax ``fhGenerics)) (wh : Option (TSyntax ``fhWhere))
    (ps : Array (TSyntax `fh_pat)) (ts : Array (TSyntax `fh_expr)) :
    MacroM (Array (TSyntax ``bracketedBinderF)) := do
  let generics ← expandGenerics gs
  let instances ← expandWhere wh
  let explicits ← ps.zip ts |>.mapM fun (p, t) => expandParam p t
  return generics ++ instances ++ explicits

/-- Stage-one expansion of a single FH item into Lean surface syntax. -/
partial def expandItem (it : TSyntax `fh_item) (attrs : AttrSet := {}) : MacroM (TSyntax `command) :=
  withRef it do
    match it with
    | `(fh_item| $g:fhAttrs $inner:fh_item) => do
        expandItem inner (← addAttrs attrs g)

    | `(fh_item| fn $n:ident $[$gs]? ($[$ps : $ts],*) -> $ret $[$wh]? $body:fh_fn_body) => do
        checkIdent n
        let binders ← allBinders gs wh ps ts
        let ret ← expandExpr ret
        let (body, sorryValued) ← expandFnBody body
        fhDecl (← withAttrs attrs (← `(command| def $n $binders* : $ret := $body))) sorryValued

    | `(fh_item| theorem $n:ident $[$gs]? ($[$ps : $ts],*) -> $concl $[$wh]? $body:fh_fn_body) => do
        checkIdent n
        let binders ← allBinders gs wh ps ts
        let concl ← expandExpr concl
        let (body, sorryValued) ← expandFnBody body
        fhDecl (← withAttrs attrs (← `(command| theorem $n $binders* : $concl := $body))) sorryValued

    | `(fh_item| struct $n:ident $[: $bounds]? { $[$fnames : $ftys],* }) => do
        checkIdent n
        let fields ← fnames.zip ftys |>.mapM fun (f, t) => do
          checkIdent f
          let t ← expandExpr t
          `(structSimpleBinder| $f:ident : $t)
        let decl ← match bounds with
          | none => `(command| structure $n:ident where $fields:structSimpleBinder*)
          | some bs => do
              let ps ← bs.raw[0].getSepArgs.mapM fun p => do
                let p ← expandExpr ⟨p⟩
                `(structParent| $p:term)
              `(command| structure $n:ident extends $ps,* where $fields:structSimpleBinder*)
        fhDecl (← withAttrs attrs decl)

    | `(fh_item| enum $n:ident { $vs,* }) => do
        checkIdent n
        let ctors ← vs.getElems.mapM (expandVariant n)
        fhDecl (← withAttrs attrs (← `(command| inductive $n:ident where $ctors*)))

    | `(fh_item| mod $n:ident { $items* }) => do
        checkIdent n
        unless attrs.lean.isEmpty && !attrs.defOptOut do
          Macro.throwErrorAt it "FH: attributes are not supported on `mod`"
        let items ← items.mapM (expandItem · {})
        let open_ ← `(command| namespace $n)
        let close ← `(command| end $n)
        return ⟨mkNullNode (#[open_.raw] ++ items.map (·.raw) ++ #[close.raw])⟩

    | `(fh_item| use $path;) => do
        unless attrs.lean.isEmpty && !attrs.defOptOut do
          Macro.throwErrorAt it "FH: attributes are not supported on `use`"
        let path ← expandExpr path
        unless path.raw.isIdent do
          Macro.throwErrorAt it "FH: `use` takes a path, as in `use Nat::Prime;`"
        let ns : Ident := ⟨path.raw⟩
        `(command| open $ns:ident)

    | `(fh_item| type $n:ident = $val;) => do
        checkIdent n
        let val ← expandExpr val
        let decl ← if attrs.defOptOut then
            `(command| def $n:ident := $val)
          else
            `(command| abbrev $n:ident := $val)
        fhDecl (← withAttrs attrs decl)

    | _ => Macro.throwErrorAt it "FH: no expansion for this item"

macro_rules
  | `(command| $it:fh_item) => expandItem it

end FerrisHoward
