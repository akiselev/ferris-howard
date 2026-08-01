/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import FerrisHoward.Syntax.Basic

/-!
# The method-spelling bridge (F16), and how a spelling comes into scope

F16 rules that ASCII method spellings are canonical for Mathlib notations with no Rust
operator — `p.dvd(a)` is `p ∣ a` — and that Unicode operator input is a v2 opt-in.

FH's `.` is Lean's generalized dot notation, which resolves by the receiver's head symbol:
`p.Prime` finds `Nat.Prime` because `p : Nat`. Class notations have no such home —
divisibility is `Dvd.dvd`, and no carrier type declares a `dvd` method — so the spelling
needs somewhere to come from.

## It comes from an import, exactly as in Rust

```rust
use lean::Dvd;          // the trait is in scope, so its spelling resolves
theorem euclids_lemma(...) -> p.dvd(a) || p.dvd(b) { ... }
```

A Rust programmer already knows this rule: a trait's methods are callable when the trait
is imported. FH borrows it wholesale, which is the whole design principle — Rust syntax as
a reading aid — and it beats the alternative (a global table) on every axis that matters:

* **explicit.** The file says which notations it is using. Nothing is rewritten invisibly.
* **scoped.** Outside a `use`, `x.m` is plain dot notation, unchanged.
* **safe by construction.** A bridge can shadow a real method only inside a file that
  asked for it. That turns a language-wide hazard into a local, deliberate choice — and it
  is what makes `.comp()` and `.union()` bridgeable at all, since Mathlib has 587 and 156
  declarations named `T.comp`/`T.union` that a global table would have silently replaced.
* **drift-proof.** If Mathlib grows a competing `Nat.dvd`, only files that imported `Dvd`
  are affected, and they chose it.

## The mechanism

`x.m` expands to `fh_dot% x m`. The default rule below rebuilds exactly what FH produced
before — a dotted identifier for an identifier receiver, a projection otherwise — so a
file with no `use lean::…` behaves precisely as it always did. `use lean::C;` opens
`FerrisHoward.Bridge.C`, whose `scoped macro_rules` intercept that class's spellings.

All of it is stage one: `macro_rules` producing Lean surface syntax, so `emit-lean` is
untouched and the artifact contains the resolved call.
-/

namespace FerrisHoward
open Lean

/-- The default meaning of `x.m`: what FH produced before any bridge existed.

An identifier receiver rebuilds the dotted identifier, so paths (`Nat.succ`) and dot
notation on a local (`l.length`) both resolve exactly as Lean resolves them today. Any
other receiver becomes a projection, which is the compound-receiver case
(`(x - a).abs()`). -/
macro_rules
  | `(fh_dot% $x $m:ident) =>
    if x.raw.isIdent then
      return mkIdentFrom x (x.raw.getId ++ m.getId)
    else
      `($x.$m:ident)

/-! ## The bridges

One namespace per class, holding that class's spellings. Adding a bridge is adding a
namespace here; using one is `use lean::<name>;`.
-/

namespace Bridge.Dvd

/-- `a.dvd(b)` is `a ∣ b` (F16). -/
scoped macro_rules
  | `(fh_dot% $x dvd) => `(Dvd.dvd $x)

end Bridge.Dvd

namespace Bridge.Abs

/-- `x.abs()` is `|x|` (F16).

The canonical case for this bridge: `|x|` is `Abs.abs x`, no carrier declares an `abs`
method, and generalized dot notation on a `Real` therefore looks for `Real.abs` and does
not find it. Corpus Group 4 writes `(x - a).abs()` three times in one definition. -/
scoped macro_rules
  | `(fh_dot% $x abs) => do let c := mkIdent `abs; `($c $x)

end Bridge.Abs

namespace Bridge.Pow

/-- `a.pow(n)` is `a ^ n` (F16).

Rust's `^` is exclusive-or, so FH cannot spell exponentiation with it and there is no
operator left; the ASCII method spelling is the whole of what F16 exists for. And there is
no carrier method to fall back on — corpus Group 7 writes `a.pow(P)` for `a : Fp<P>`,
whose carrier is a `match` on `P` and has no namespace at all. -/
scoped macro_rules
  | `(fh_dot% $x pow) => do let c := mkIdent `HPow.hPow; `($c $x)

end Bridge.Pow

namespace Bridge.Function

/-- `f.comp(g)` is `f ∘ g`. Bridgeable only because it is opt-in: Mathlib has 587
declarations named `T.comp`, and every one of them is the right answer for its own
receiver — so this belongs in a file that has said it means the plain function. -/
scoped macro_rules
  | `(fh_dot% $x comp) => `(Function.comp $x)

end Bridge.Function

end FerrisHoward
