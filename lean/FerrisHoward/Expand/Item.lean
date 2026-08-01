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
  /-- `#[partial]`: `partial def` — no induction principle (design §4.6). -/
  isPartial : Bool := false
  /-- `#[noncomputable]`: the specification-not-program marker. -/
  isNoncomputable : Bool := false
  /-- `#[opaque]`: a value exists and nothing may look at it. -/
  isOpaque : Bool := false
  /-- `#[terminates_by(e)]`: the well-founded measure (design §4.6). -/
  terminationBy? : Option (TSyntax `term) := none
  /-- `#[decreasing_by(lean! { … })]`: the proof that it decreases. -/
  decreasingBy? : Option (TSyntax ``Lean.Parser.Tactic.tacticSeq) := none
  /-- `#[name(n)]`: the name an otherwise-anonymous `impl` instance takes. -/
  name? : Option Ident := none
  /-- Attributes passed through verbatim (design §3's `#[attr]` → `@[attr]` row). -/
  «lean» : TSyntaxArray ``attrInstance := #[]
  deriving Inhabited

/-- Fold one attribute into the set. -/
private def addAttr (s : AttrSet) (a : TSyntax `fh_attr) : MacroM AttrSet :=
  withRef a do
    match a with
    | `(fh_attr| def) => return { s with defOptOut := true }
    | `(fh_attr| partial) => return { s with isPartial := true }
    | `(fh_attr| noncomputable) => return { s with isNoncomputable := true }
    | `(fh_attr| opaque) => return { s with isOpaque := true }
    | `(fh_attr| instance) =>
        return { s with «lean» := s.lean.push (← `(attrInstance| instance)) }
    | `(fh_attr| $n:ident) =>
        return { s with «lean» := s.lean.push (← `(attrInstance| $n:ident)) }
    | `(fh_attr| decreasing_by($e)) => do
        let `(fh_expr| lean! { $ts }) := e
          | Macro.throwErrorAt e
              "FH: `#[decreasing_by(…)]` takes a tactic block, as in \
               `#[decreasing_by(lean! { omega })]`"
        return { s with decreasingBy? := some ts }
    -- Branch on the *name* rather than pattern-matching a literal identifier: a literal
    -- ident in a quotation pattern carries hygiene information that source idents do not,
    -- so it never matches.
    | `(fh_attr| $n:ident($_args,*)) =>
        if n.getId == `terminates_by then
          match _args.getElems with
          | #[e] => do return { s with terminationBy? := some (← expandExpr e) }
          | _ => Macro.throwErrorAt a "FH: `#[terminates_by(…)]` takes one measure expression"
        else if n.getId == `name then
          -- design §3: `#[name(…)]` names the instance an `impl` would otherwise leave
          -- anonymous.
          match _args.getElems with
          | #[arg] =>
            match arg with
            | `(fh_expr| $x:ident) => return { s with name? := some x }
            | _ => Macro.throwErrorAt arg "FH: `#[name(…)]` takes an identifier"
          | _ => Macro.throwErrorAt a "FH: `#[name(…)]` takes exactly one identifier"
        else
          Macro.throwErrorAt a
            s!"FH: `#[{n.getId}(…)]` takes arguments, which are not supported yet; \
               attributes with arguments arrive with the features that use them"
    | _ => Macro.throwErrorAt a "FH: no expansion for this attribute"

/-- Fold an attribute group into the set. -/
private def addAttrs (s : AttrSet) (g : TSyntax ``fhAttrs) : MacroM AttrSet := do
  match g with
  | `(fhAttrs| #[$items,*]) => items.getElems.foldlM addAttr s
  | _ => Macro.throwErrorAt g "FH: no expansion for this attribute group"

/-- Attach `@[…]` to a generated declaration.

Lean has no syntax for attaching attributes to an *arbitrary* command, so this grafts the
`declModifiers` node of a throwaway declaration onto the generated one. The alternatives
were worse: writing an attributed and an unattributed quotation for every item kind
duplicates every builder, and a follow-up `attribute [attr] name` command is a different
thing from design §3's `#[attr]` → `@[attr]` row. Guarded — anything that is not a
declaration errors, which is exactly what `mod` and `use` should do. -/
private def withAttrs (attrs : AttrSet) (d : TSyntax `command) : MacroM (TSyntax `command) := do
  -- `#[name(…)]` is consumed by `impl`, which clears it before reaching here. On anything
  -- else it is meaningless: the item already has a name of its own.
  if let some n := attrs.name? then
    Macro.throwErrorAt n
      "FH: `#[name(…)]` names an `impl`'s instance; every other item already has a name"
  if attrs.lean.isEmpty && !attrs.isPartial && !attrs.isNoncomputable then return d
  unless d.raw.getKind == ``Lean.Parser.Command.declaration do
    Macro.throwError "FH: attributes are not supported on this item"
  -- `declModifiers` is a fixed-shape node: [doc, attributes, _, _, noncomputable, unsafe,
  -- partial]. Lean offers no way to attach modifiers to an already-built command, so the
  -- fields are taken from template quotations and grafted. The layout is pinned by the
  -- goldens in `Tests/M2/Modifiers.lean`, which is what makes the dependency safe to hold.
  let attrList := attrs.lean
  let base ← if attrList.isEmpty then
      `(command| def fhAttrTemplate := ())
    else
      `(command| @[$attrList,*] def fhAttrTemplate := ())
  let mods ← do
    let keywords ← `(command| noncomputable partial def fhModTemplate := ())
    let km := keywords.raw[0]
    let mut m := base.raw[0]
    if attrs.isNoncomputable then m := m.setArg 4 km[4]
    if attrs.isPartial then m := m.setArg 6 km[6]
    pure m
  return ⟨d.raw.setArg 0 mods⟩

/-! ## Binders -/

/-- One generic parameter, split into its binder and its optional annotation.

The binder may be `_`: in an `enum` header that marks an **index** position (design §4.5),
and elsewhere it is an ordinary anonymous binder. -/
def genericParam (p : TSyntax ``fhGenericParam) :
    MacroM (TSyntax [`ident, ``Lean.Parser.Term.hole] × Option (TSyntax `fh_expr)) :=
  withRef p do
    match p with
    | `(fhGenericParam| $x:ident : $t) => do checkIdent x; return (⟨x.raw⟩, some t)
    | `(fhGenericParam| $x:ident) => do checkIdent x; return (⟨x.raw⟩, none)
    | `(fhGenericParam| _ : $t) => do let h ← `(_); return (⟨h.raw⟩, some t)
    | `(fhGenericParam| _) => do let h ← `(_); return (⟨h.raw⟩, none)
    | _ => Macro.throwErrorAt p "FH: no expansion for this generic parameter"

/-- Angle-bracket generics → **implicit** binders (design §4.2). A bare `<T>` gets
`Type _`: design §4.3's "a bare `<T>` defaults to `Space<_>`", spelled in core Lean until
`Space` itself lands at A2.4. -/
private def expandGenerics (g? : Option (TSyntax ``fhGenerics)) :
    MacroM (Array (TSyntax ``bracketedBinderF)) := do
  let some g := g? | return #[]
  let `(fhGenerics| <$ps,*>) := g | Macro.throwErrorAt g "FH: no expansion for these generics"
  ps.getElems.mapM fun p =>
    withRef p do
      let (x, t?) ← genericParam ⟨p⟩
      match t? with
      | some t => do
          let t ← expandExpr t
          `(bracketedBinderF| {$x : $t})
      | none => `(bracketedBinderF| {$x : Type _})

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

/-- The namespace a `use` opens.

`use lean::C;` is the bridge import: it opens `FerrisHoward.Bridge.C`, whose scoped
`macro_rules` give `C`'s F16 method spellings. Everything else opens itself. Resolving it
here rather than at elaboration keeps the whole thing in stage one. -/
private def usePath? (x : Ident) : Ident :=
  match x.getId.components with
  | first :: rest =>
    if first == `lean && !rest.isEmpty then
      mkIdentFrom x (rest.foldl (· ++ ·) `FerrisHoward.Bridge)
    else x
  | _ => x

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
private def expandVariant (uniform : TSyntax `term) (v : TSyntax ``fhEnumVariant) :
    MacroM (TSyntax ``ctor) :=
  withRef v do
    match v with
    | `(fhEnumVariant| $c:ident $[$gs]? $[($fs,*)]? $[-> $ret]?) => do
        checkIdent c
        -- a variant's own generics are implicit binders on the constructor
        let generics ← expandGenerics gs
        -- absent an arrow the variant targets the uniform type; present, it declares the
        -- index (design §4.5)
        let target ← match ret with
          | some r => expandExpr r
          | none => pure uniform
        let fields ← match fs with
          | none => pure #[]
          | some fs => fs.getElems.mapM fun f =>
            match f with
            | `(fhEnumField| $n:ident : $t) => do checkIdent n; return (some n, ← expandExpr t)
            | `(fhEnumField| $t:fh_expr) => return (none, ← expandExpr t)
            | _ => Macro.throwErrorAt f "FH: no expansion for this enum field"
        let named := fields.filter (·.1.isSome)
        if named.size == fields.size then
          let binders ← fields.mapM fun (n, t) => `(bracketedBinderF| ($(n.get!) : $t))
          let all := generics ++ binders
          `(ctor| | $c:ident $all* : $target)
        else if named.isEmpty then
          let mut ty := target
          for (_, t) in fields.reverse do ty ← `($t → $ty)
          `(ctor| | $c:ident $generics* : $ty)
        else
          Macro.throwErrorAt v
            "FH: an enum variant's fields must be either all named or all unnamed"
    | _ => Macro.throwErrorAt v "FH: no expansion for this enum variant"

/-- A trait's carrier parameters: explicit binders, plus the first one, which is what a
supertrait is applied to. Lean classes are parameterised over their carrier explicitly
(design §4.4), which is the one place FH's generics are not implicit. -/
private def expandCarriers (g? : Option (TSyntax ``fhGenerics)) :
    MacroM (Array (TSyntax ``bracketedBinderF) × Option Ident) := do
  let some g := g? | return (#[], none)
  let `(fhGenerics| <$ps,*>) := g | Macro.throwErrorAt g "FH: no expansion for these generics"
  let mut binders := #[]
  let mut first := none
  for p in ps.getElems do
    let (x, t) ← withRef p do
      let (x, t?) ← genericParam ⟨p.raw⟩
      let t ← match t? with
        | some t => expandExpr t
        | none => `(Type _)
      return (x, t)
    if first.isNone then
      unless x.raw.isIdent do
        Macro.throwErrorAt p "FH: a trait's carrier needs a name, not `_`"
      first := some ⟨x.raw⟩
    binders := binders.push (← `(bracketedBinderF| ($x : $t)))
  return (binders, first)

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

/-- A trait member → a class field.

A method becomes a field whose type is a function, with its parameters kept as binders so
their names stay visible in goals and available to named arguments; a body becomes the
field's default value. A bare `name: <prop>;` is design §4.4's law — a field like any
other, which is exactly why every `impl` has to discharge it. -/
private def expandTraitMember (m : TSyntax `fh_member) : MacroM (TSyntax ``structSimpleBinder) :=
  withRef m do
    match m with
    | `(fh_member| fn $n:ident $[$gs]? ($[$ps : $ts],*) -> $ret $body:fh_fn_body) => do
        checkIdent n
        let binders ← allBinders gs none ps ts
        let ret ← expandExpr ret
        match body with
        | `(fh_fn_body| ;) => `(structSimpleBinder| $n:ident $binders* : $ret)
        | `(fh_fn_body| { $e }) => do
            let e ← expandExpr e
            `(structSimpleBinder| $n:ident $binders* : $ret := $e)
        | _ => Macro.throwErrorAt body "FH: no expansion for this method body"
    | `(fh_member| $n:ident : $ty;) => do
        checkIdent n
        let ty ← expandExpr ty
        `(structSimpleBinder| $n:ident : $ty)
    | _ => Macro.throwErrorAt m "FH: no expansion for this trait member"

/-- An impl member → a structure-instance field.

A method keeps its binders — `op (a : Int) (b : Int) := a + b` — rather than becoming a
`fun`. That is the idiomatic Lean, it keeps the parameter names and types the author
wrote, and a lambda built from bracketed binders does not survive the pretty-printer,
which the golden tier and the publication path both depend on. -/
private def expandImplMember (m : TSyntax `fh_member) : MacroM (TSyntax ``structInstField) :=
  withRef m do
    match m with
    | `(fh_member| fn $n:ident $[$_gs]? ($[$ps : $ts],*) -> $_ret { $e }) => do
        checkIdent n
        let binders ← ps.zip ts |>.mapM fun (p, t) => do
          let p ← expandBinderPat p
          let t ← expandExpr t
          `(structInstFieldBinder| ($p : $t))
        let e ← expandExpr e
        `(structInstField| $n:ident $binders:structInstFieldBinder* := $e)
    | `(fh_member| fn $n:ident $[$_gs]? ($[$_ps : $_ts],*) -> $_ret ;) =>
        Macro.throwErrorAt m
          s!"FH: `{n.getId}` needs a body here — an `impl` supplies values, and a bodyless \
             `fn` declares an obligation"
    | `(fh_member| $n:ident : $val;) => do
        checkIdent n
        let val ← expandExpr val
        `(structInstField| $n:ident := $val)
    | _ => Macro.throwErrorAt m "FH: no expansion for this impl member"

/-- An `enum` header, split into uniform **parameters** (named) and **index** positions
(written `_`) — design §4.5's marker, and the whole of what distinguishes an indexed
family from an ordinary Rust enum. -/
private def splitEnumHeader (g? : Option (TSyntax ``fhGenerics)) :
    MacroM (Array (Ident × TSyntax `term) × Array (TSyntax `term)) := do
  let some g := g? | return (#[], #[])
  let `(fhGenerics| <$ps,*>) := g | Macro.throwErrorAt g "FH: no expansion for these generics"
  let mut params := #[]
  let mut indices := #[]
  for p in ps.getElems do
    let (x, t?) ← genericParam ⟨p⟩
    let t ← match t? with
      | some t => expandExpr t
      | none => `(Type _)
    if x.raw.isIdent then
      params := params.push (⟨x.raw⟩, t)
    else
      indices := indices.push t
  return (params, indices)

/-- Peel the `set_option … in` wrappers `fhDecl` adds, leaving the bare declaration.

Used only by `mutual`, whose block cannot contain wrapped commands; the options are put
back around the whole block. -/
private partial def stripDeclOptions (stx : Syntax) : Syntax :=
  if stx.getKind == ``Lean.Parser.Command.in then
    stripDeclOptions stx.getArgs.back!
  else
    stx

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
        if attrs.isOpaque then
          -- `opaque` is a different command, not a modifier: nothing may unfold it, so
          -- termination attributes have nothing to attach to either.
          return ← fhDecl (← withAttrs attrs (← `(command| opaque $n $binders* : $ret := $body)))
            sorryValued
        let decl ← match attrs.terminationBy?, attrs.decreasingBy? with
          | none, none => `(command| def $n $binders* : $ret := $body)
          | some m, none => `(command| def $n $binders* : $ret := $body
              termination_by $m)
          | none, some t => `(command| def $n $binders* : $ret := $body
              decreasing_by $t)
          | some m, some t => `(command| def $n $binders* : $ret := $body
              termination_by $m
              decreasing_by $t)
        fhDecl (← withAttrs attrs decl) sorryValued

    | `(fh_item| theorem $n:ident $[$gs]? ($[$ps : $ts],*) -> $concl $[$wh]? $body:fh_fn_body) => do
        checkIdent n
        let binders ← allBinders gs wh ps ts
        let concl ← expandExpr concl
        let (body, sorryValued) ← expandFnBody body
        fhDecl (← withAttrs attrs (← `(command| theorem $n $binders* : $concl := $body))) sorryValued

    | `(fh_item| trait $n:ident $[$gs]? $[: $parents]? $[$wh]? { $ms* }) => do
        checkIdent n
        -- a class's carrier is an explicit parameter, unlike a `fn`'s generics
        let carriers ← expandCarriers gs
        let instances ← expandWhere wh
        let binders := carriers.1 ++ instances
        let fields ← ms.mapM expandTraitMember
        let decl ← match parents with
          | none => `(command| class $n:ident $binders* where $fields:structSimpleBinder*)
          | some bs => do
              let some self := carriers.2
                | Macro.throwErrorAt it
                    "FH: a trait with supertraits needs a carrier, as in `trait C<Self>: D`"
              let ps ← bs.raw[0].getSepArgs.mapM fun p => do
                let p ← expandExpr ⟨p⟩
                `(structParent| $p $self)
              `(command| class $n:ident $binders* extends $ps,* where
                  $fields:structSimpleBinder*)
        fhDecl (← withAttrs attrs decl)

    | `(fh_item| impl $cls for $carrier $[$wh]? { $ms* }) => do
        let cls ← expandExpr cls
        let carrier ← expandExpr carrier
        let instances ← expandWhere wh
        let fields ← ms.mapM expandImplMember
        let decl ← match attrs.name? with
          | some name => do
              checkIdent name
              `(command| instance $name:ident $instances:bracketedBinder* : $cls $carrier := { $fields:structInstField,* })
          | none => `(command| instance $instances:bracketedBinder* : $cls $carrier := { $fields:structInstField,* })
        fhDecl (← withAttrs { attrs with name? := none } decl)

    | `(fh_item| extern $kind:str { $items* }) => do
        unless kind.getString == "axiom" do
          Macro.throwErrorAt kind
            s!"FH: `extern \"{kind.getString}\"` is not a thing; the only extern block is \
               `extern \"axiom\"` (design §4.6)"
        let cmds ← items.mapM fun item =>
          withRef item do
            match item with
            | `(fh_item| fn $n:ident $[$gs]? ($[$ps : $ts],*) -> $ret $[$wh]? ;) => do
                checkIdent n
                let binders ← allBinders gs wh ps ts
                let ret ← expandExpr ret
                fhDecl (← `(command| axiom $n $binders* : $ret))
            | _ =>
                Macro.throwErrorAt item
                  ("FH: an `extern \"axiom\"` block holds bodyless `fn` declarations — a \
                    body would be an implementation, which is what an axiom does not have"
                   : String)
        return ⟨mkNullNode (cmds.map (·.raw))⟩

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

    | `(fh_item| enum $n:ident $[$gs]? { $vs,* }) => do
        checkIdent n
        -- `_` in the header marks an index position — varying per constructor — against a
        -- named parameter, which is uniform (design §4.5).
        let (params, indices) ← splitEnumHeader gs
        let uniform ← do
          let names := params.map (·.1)
          if names.isEmpty then pure (n : TSyntax `term) else `($n $names*)
        let ctors ← vs.getElems.mapM (expandVariant uniform)
        let decl ← if indices.isEmpty then
            let binders ← params.mapM fun (x, t) => `(bracketedBinderF| ($x : $t))
            `(command| inductive $n:ident $binders* where $ctors*)
          else
            let binders ← params.mapM fun (x, t) => `(bracketedBinderF| ($x : $t))
            let mut sort ← `(Type _)
            for t in indices.reverse do sort ← `($t → $sort)
            `(command| inductive $n:ident $binders* : $sort where $ctors*)
        fhDecl (← withAttrs attrs decl)

    | `(fh_item| mutual { $items* }) => do
        unless attrs.lean.isEmpty && attrs.name?.isNone do
          Macro.throwErrorAt it "FH: attributes belong on the declarations inside a `mutual`, not on the block"
        -- A mutual block takes bare declarations: Lean rejects `set_option … in` inside
        -- one ("either all elements … must be inductive/structure declarations"), so the
        -- options FH puts on every declaration are hoisted to the whole block instead.
        let decls ← items.mapM fun item => do
          let cmd ← expandItem item {}
          pure (⟨stripDeclOptions cmd.raw⟩ : TSyntax `command)
        let block ← `(command| mutual $decls:command* end)
        fhDecl block

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
        -- `use lean::C;` brings FH's bridge for `C` into scope — Rust's rule that a
        -- trait's methods are callable once the trait is imported (F16, design §6).
        -- Anything else is an ordinary `open`.
        let path ← expandExpr path
        unless path.raw.isIdent do
          Macro.throwErrorAt it "FH: `use` takes a path, as in `use Nat::Prime;`"
        let ns := usePath? ⟨path.raw⟩
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
