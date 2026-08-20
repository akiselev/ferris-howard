/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Syntax.Basic

/-!
# What comprehension braces mean (F13)

`{x: A | P(x)}` is one syntax for two things: a `Set A` in term position and a `Subtype`
in type position. F13's amendment rules that the election happens **by expected type**,
because "disambiguated by position" is unimplementable under a unified expression grammar
— there is no syntactic type position to look at.

## The decision, and why this one

Stage one cannot see an expected type either. Three mechanisms can:

1. a **stage-two elaborator** — cheapest to write, but ADR-006 then needs a custom
   expander for `emit-lean` or must exclude comprehensions from the publishable subset,
   and comprehensions are everywhere in Prop-heavy mathematics;
2. a **class with an `outParam`** — `{x: A | P}` becomes `Comprehension.ofPred …` and
   instance resolution elects, with `@[default_instance]` supplying F13's default. Fully
   stage one, but it puts an FH constant into every emitted artifact, which forces
   ADR-006 §2's prelude question that nothing has yet needed answered;
3. **explicit import** — `use lean::Set;` or `use lean::Subtype;` says which, in the file
   that means it.

FH takes (3), for the reason the method-spelling bridge took it: it is Rust's own rule,
the file says what it means, nothing is elected invisibly, and the artifact contains
`setOf` or `Subtype` — ordinary Lean, no prelude. It is also the only one of the three
that a reader can resolve without knowing the elaborator's state.

The cost is honest and stated: this is **not** what F13's amendment says. Election by
expected type remains the better *reading experience* — `{x: A | P}` in a return type
should not need an import to mean the obvious thing — and it stays available: swapping to
mechanism 1 or 2 is one `macro_rules` on `fh_comprehension%`, and nothing else in the
language moves. That is why the hook exists rather than the expander emitting `setOf`
directly. Queued as an amendment for whoever owns the prelude policy.
-/

namespace FerrisHoward
open Lean

/-- With no comprehension in scope, say what is missing and what would supply it. -/
macro_rules
  | `(fh_comprehension% $p) =>
    Macro.throwErrorAt p
      ("FH: no comprehension is in scope, so `{x: A | P}` has no meaning here. \
        `use lean::Set;` makes it a set; `use lean::Subtype;` makes it a subtype." : String)

/-! The two rules emit **unhygienic** identifiers, on purpose. A bridge names a constant in
the *user's* environment — `setOf` is Mathlib's and this module does not import Mathlib —
so a hygienic reference would try to resolve at the bridge's own declaration site and fail.
Resolving at the use site is what a name bridge is for, and it is what `::` paths already
do. -/

namespace Bridge.Set

/-- `{x: A | P}` is `setOf (fun x : A => P) : Set A` — F13's default reading. -/
scoped macro_rules
  | `(fh_comprehension% $p) => return Syntax.mkApp (mkIdent `setOf) #[p]

end Bridge.Set

namespace Bridge.Subtype

/-- `{x: A | P}` is `Subtype (fun x : A => P)`, the type-position reading. -/
scoped macro_rules
  | `(fh_comprehension% $p) => return Syntax.mkApp (mkIdent `Subtype) #[p]

end Bridge.Subtype

end FerrisHoward
