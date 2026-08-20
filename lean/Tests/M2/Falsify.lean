/-
Copyright (c) 2026 Ferris–Howard contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Mathlib
import FerrisHoward
import FerrisHoward.Falsify
import FerrisHoward.Test

/-!
# The falsification battery (C4)

An agent that cannot prove a statement has two very different situations in front of it,
and telling them apart is the highest-value thing it can do next: the statement may be
hard, or it may be **false**. Hours go into the first case when the answer was the second.

So `#fh_falsify` is what to run on a failure, before another tactic.

## The battery, cheapest first

1. `decide` — for a closed decidable proposition the answer is a computation, and the
   kernel checks it. That is the strongest refutation available.
2. `plausible` — property-based search with shrinking, which is what turns "some
   counterexample" into a readable one.
3. Small-model instantiation — design §4.9's predicted payoff for role metadata: "`Space`
   variables get probed with small finite types (`Bool`, `Fin 3`)". A claim quantified
   over an arbitrary space is often not testable as written; instantiate the space and it
   becomes a concrete proposition.

## Why the witnesses are not pinned below

`plausible` samples randomly, so the same false statement yields `n := 5` on one run and
`n := 6` on the next. Pinning a witness would make this file flake. What is pinned is the
**verdict**, which is the part that must never drift — and the verdict is a property of the
statement rather than of the sampler.

## What a negative result means

Nothing. `#fh_falsify` never reports "true", only "no counterexample found in what was
tried", and it names what was tried. The one exception is `decide` *proving* the
statement — that is a kernel check, not a search, and it is reported as such.
-/

/-! ## Tier 2 — the battery running

### A closed false proposition: refuted by the kernel
-/

/-- warning: declaration uses `sorry` -/
#guard_msgs in
theorem closed_false() -> (5 < 5) { lean! { sorry } }

/-- info: FH falsify: `closed_false` is FALSE -/
#guard_msgs (whitespace := lax, substring := true) in
#fh_falsify closed_false

/-! The message names *which* leg refuted it, because "the kernel says so" and "a sampler
found one" are different strengths of answer — the guard above pins the verdict line, and
the body below it reads `REFUTED by \`decide\` (kernel-checked)`.

The guards here match on a *prefix* rather than the whole message, because everything after
the verdict line is the witness and the witness is sampled. -/

/-! ### A quantified false statement: refuted with a witness -/

/-- warning: declaration uses `sorry` -/
#guard_msgs in
theorem quantified_false(n: Nat) -> (n < 5) { lean! { sorry } }

/-- info: FH falsify: `quantified_false` is FALSE -/
#guard_msgs (whitespace := lax, substring := true) in
#fh_falsify quantified_false

/-! ### A statement over an arbitrary space

`for<A> for<f: A -> A> for<a: A> f(a) == a` — "every endofunction is the identity", which
reads respectably in general form and is false at two elements. This is the shape the
small-model probes exist for, and the shape most corpus claims have.

Universe parameters have to be freed before a space can be probed: `general.{u}` states
`@Eq.{u} A (f a) a`, and substituting `A := Bool` without freeing `u` leaves `@Eq.{u} Bool
…`, which is ill-typed and for which no `Testable` instance can exist. That was the bug
this fixture caught. -/

/-- warning: declaration uses `sorry` -/
#guard_msgs in
theorem general<A>(f: A -> A, a: A) -> f(a) == a { lean! { sorry } }

/-- info: FH falsify: `general` is FALSE -/
#guard_msgs (whitespace := lax, substring := true) in
#fh_falsify general

/-! ### A true statement: no counterexample, and no claim of truth

The wording matters. Reporting "no counterexample" as "true" is the one dishonest thing
this command could do, so the header says so in the negative case explicitly.
-/

theorem true_thing(n: Nat) -> n + 0 == n { lean! { simp } }

/--
info: FH falsify: no counterexample for `true_thing` — this is not evidence it is true
-/
#guard_msgs (whitespace := lax, substring := true) in
#fh_falsify true_thing

/-! And the report names what was tried, so a reader can see how much searching stands
behind the negative — `decide`: not applicable, then `plausible`: no counterexample. -/

/-! ## Tier 3 — negative -/

/-- error: Unknown constant `no_such_theorem` -/
#guard_msgs in
#fh_falsify no_such_theorem
