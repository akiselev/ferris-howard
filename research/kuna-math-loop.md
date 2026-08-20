# A Kuna-style improvement loop for mathematical research tools

**Status:** method and pre-registration, written 2026-08-04 before the full history run.
Results belong in a separate section after the commands have run. This document does not
turn a history-mining result into a discovery claim.

## 1. What was recovered

The preceding Claude Code session ended at the start of this experiment. It had identified
Mathlib history as a possible external comparison source and launched a three-agent workflow,
but all three jobs hit the weekly quota. No ground-truth JSON, expressibility score, or loss
analysis was produced. The only durable artifact was an unfinished
`scripts/kuna-truth.py`; its sole self-test exercised lattice reconstruction and never tested
the historical source parser that creates the labels.

A separate 400-case prover run was still live. It was stopped at 55 cases (50 completed
negative verdicts, zero positive verdicts) because its command named only the target class.
The implementation replaced the first same-arity instance binder, not necessarily the source
binder in the candidate. The partial log is preserved as
`/tmp/attempt-run.invalid-first-binder.log` and is not evidence about theorem truth.

## 2. The Kuna method, without the slogan

The release post describes autonomous improvement by studying individual functions where
Kuna loses to IDA on a fundamental metric. The repository's runbook is stricter than that
summary:

1. Mine a comparable per-unit loss against a reference or original source.
2. Verify that the reference is genuinely better; a metric gap is only a prefilter.
3. Localize the loss to one pipeline decision.
4. Implement one option-gated change.
5. Let ablation decide the default, measure cost, and inspect every changed function for
   wrong output rather than checking only the witness.
6. Record a negative result when the diagnosis or change fails.

Primary sources:

- <https://noelo.org/blog/kuna-release/>
- <https://github.com/Noelo-Lab/kuna/blob/main/docs/improvement-pipeline.md>
- <https://github.com/Noelo-Lab/kuna/blob/main/docs/decbench-loop.md>

The transferable idea is therefore not “copy the stronger system.” It is **build a loss set
whose units mean what users value, verify each apparent loss, localize it, make one falsifiable
change, and test the blast radius**.

## 3. Adversarial review of the current research program

### Evidence that survives

- The kernel-verification instrument is real. The 431 confirmed weakenings are individually
  checked statements, and the prior-art screen's 44 hits show why confirmation and
  generalization must remain separate labels.
- The posting-cutoff result has the right causal shape: a monotone dose response, a matched-N
  control, an identified mechanism, and a cost measurement. It is an instrument-improvement
  result, not a mathematics discovery.
- The dimensional front end has strong synthetic controls and error-injection controls. It
  is a validated parser/solver front end. Its application to papers is not validated: only
  39.2% of display equations yielded a row, and none of the 15 papers pinned a
  low-dimensional grading.
- The project's negative-control discipline repeatedly overturned its own claims. That is
  currently more valuable than the Atlas rankings themselves.

### Claims or measurements that do not survive

- B7 is a development fixture, not held-out evidence. Statements were written so named
  analogies could exist; its rediscovery score is withdrawn.
- “REFUTED” means one inherited proof term failed. It is not a theorem-level negative. The
  attempted tactic loop was the right missing direction, but its first interface could alter
  the wrong binder and its partial run is discarded.
- Mathlib commit history is not automatically a stronger mathematician. It contains merged
  positive changes, not rejected ideas or all opportunities. It is selection-biased toward
  changes worth a pull request and toward what commit messages happen to say.
- A source diff judged with the current class lattice is not a historical replay. Class
  names and hierarchy edges can drift, and the pre-generalization proof is never put through
  today's detector.
- The system indexes statement types, not proof structure. Calling premise-name bags
  `proof_shape` does not repair that missing 97.5% of the measured formal record.
- Physics negatives remain bounded by formalization coverage. Missing Hamiltonian mechanics
  in the corpus is not evidence that classical/quantum analogy is absent.

The result is a tool-building program with unusually good controls, not yet a mathematics
research result. The Kuna loop should improve the instruments first and make that boundary
explicit.

## 4. The first bounded Kuna loop: theorem-hypothesis generalization

| Kuna | Ferris–Howard pilot |
|---|---|
| function | historical theorem-binder change |
| original source / verified reference | parent and child Mathlib source at one commit |
| Kuna output | detector proposal `(declaration, source class, target class)` |
| metric | exact event coverage, stratified by expressibility |
| loss set | expert events the detector did not propose |
| pipeline phase | representation → candidate generation → evidence → proof search → prior-art screen |
| option-gated fix | one rule or representation change, off by default |
| full changed-function audit | re-run all frozen development and held-out events plus existing negative controls |

This pilot is deliberately narrower than “do mathematics.” It asks whether one agent-facing
instrument recovers one repeated action expert mathematicians actually perform. If the loop
cannot be made honest here, it is not ready for open-ended conjecture generation.

## 5. Three evidence levels

### E0 — expert-event mining

Commit-message vocabulary locates candidate commits. Source diffs identify theorem/lemma
instance binders whose head class changed while their argument text stayed fixed. The target
must be a strict ancestor of the source in the extracted lattice.

E0 produces **structurally visible expert events**, not recall. Direct declaration binders
(`own`) and section-inherited binders (`inherited`) are separate strata because the latter
uses an approximation of Lean's variable-inclusion rule. Definitions, structures, new
theorems, parameter changes, and moves absent from the current lattice stay outside the
primary population; they are not silently called detector misses.

### E1 — historical replay

For a sampled event at commit `c`, run the detector on `c^` and ask whether it proposed the
exact declaration/source/target triple before seeing `c`. This is the first level that can
support a recall numerator. Each replay records the commit's toolchain, whether the old tree
builds, whether the event is expressible, and whether the detector reached the candidate.

If rebuilding arbitrary history is too expensive, select a contiguous toolchain-compatible
window and say so. A synthetic strong-binder wrapper is useful as a component test but is
not a substitute for historical replay.

### E2 — refinement

Freeze a chronological development/held-out split before changing the detector. Cluster only
development losses. For one cluster:

1. verify the child signature is genuinely weaker and the declaration still has the intended
   meaning;
2. localize the miss to representation, expressibility, candidate generation, evidence,
   tactic verification, or prior-art screening;
3. add one default-off rule with a positive fixture and an ablation that must silence it;
4. measure new proposals, kernel outcomes, runtime, and every changed held-out event;
5. reject the change if it fabricates statements, weakens the wrong binder, harms held-out
   coverage, or lacks a causal account.

That is the Kuna iteration. An aggregate score by itself is only the work queue.

## 6. Threats and required controls

- **Message selection:** compare with non-selected commits matched without replacement on
  Lean-file count and log2 line-churn bin, then nearest in time. Report paired outcomes.
- **Parser validity:** test own, inherited, add-only, and non-theorem cases synthetically;
  manually audit deterministic samples from both retained strata and rejected cases.
- **Present-day lattice drift:** retain endpoint-absent and unrelated counts. E0 says
  “according to the pinned current lattice”; E1 uses the historical environment.
- **Unit inflation:** one section-level variable edit can affect many theorems. Report both
  commit-level and declaration-event-level counts; never treat the latter as independent
  human decisions.
- **Positive-only history:** no true-negative or opportunity denominator exists at E0.
  Precision/recall language begins only with a replay population whose inclusion rule was
  frozen in advance.
- **Leakage:** tune on earlier commits and score once on the latest chronological block.
  Do not inspect held-out diffs while implementing a rule.
- **Wrong-statement success:** proof commands name source and target, refuse duplicate source
  binders, reject `sorry`/metavariables, and submit the final term to the kernel.
- **Reference worship:** read the actual diff and, where available, pull-request discussion.
  A human change can be compatibility work or taste rather than a better theorem statement.

## 7. Pre-registration for E0

Population: non-merge commits touching `*.lean` in the pinned Mathlib history. Selection uses
the full commit message and the fixed strings `generali`, `weaken`, `more general`, `relax`.
The primary event is a `theorem` or `lemma` binder-head change whose target is a strict
ancestor of the source. Own and inherited events are never pooled without showing both.

Controls are paired as specified above. The message selector passes its minimum sanity check
only if discordant pairs favor the selected commit under a one-sided exact paired test at
`p < 0.01`. Failure means the vocabulary is not a useful locator for this event type. It
does not mean maintainers do not generalize mathematics.

Before an E0 event set is used for tool refinement:

- manually audit 30 deterministically sampled `own` events; at least 27 must be exact;
- manually audit 30 deterministically sampled `inherited` events; at least 24 must be exact;
- manually audit 30 selected commits with no retained event to estimate which kinds of
  generalization the extractor cannot represent;
- report events per commit as well as raw declaration events.

No E0 number will be called detector recall, mathematical discovery, or a stronger-human
score. Those claims require E1.

## 8. Immediate execution order

1. Finish and test `scripts/kuna-truth.py` as an E0 miner, including matched controls.
2. Run it over the full selected/control sets and write measured results below this method,
   without revising the thresholds.
3. Perform the three manual audits and freeze a machine-readable event set.
4. Design a small E1 replay window; do not tune the detector yet.
5. Only after a frozen held-out split exists, take the largest verified loss cluster through
   one option-gated Kuna iteration.

## 9. E0 measured result

The full run completed against Mathlib revision `905b95818eb32af7874a58b427f50c1711a5e96c`.
The machine-readable result, including corpus/miner/lattice hashes and the matched pairs, is
`research/data/kuna-e0-events.json`. The source audit is
`research/kuna-e0-audit.md`.

| measure | message-selected | matched control |
|---|---:|---:|
| commits | 1,624 | 1,624 |
| Lean file pairs parsed | 7,510 | 7,262 |
| raw class-head moves, all declaration kinds | 9,564 | 548 |
| validated theorem/lemma carrier events | 5,936 | 185 |
| direct declaration-binder events | 1,182 | 17 |
| section-inherited events | 4,754 | 168 |
| commits with at least one retained event | **317 (19.52%)** | **21 (1.29%)** |

The control matcher found an exact `(Lean files, log2 churn bin)` match for 1,618 of 1,624
pairs. Mean changed-file counts were 4.796 versus 4.795, mean churn was 160.3 versus 157.6
lines, and the mean temporal gap was 10.3 days.

At the commit-level unit fixed in the pre-registration, 315 discordant pairs favored the
message-selected commit, 19 favored its control, 2 had events in both, and 1,288 had neither.
The one-sided exact paired p-value is `1.325351657895336e-70`, so the selector passes the
`p < 0.01` sanity check. Selected commits were about **15.1 times** as likely as matched
controls to contain this event shape.

The declaration counts are highly clustered and are not independent decisions. Among the
317 selected hit commits, the median is 6 events, the 90th percentile is 46, and the maximum
is 371. The largest commit contributes 6.25% of all events and the largest ten contribute
28.4%. There are 3,971 distinct declaration names and 268 distinct class pairs; the most
common pairs are `CommRing → CommSemiring` (740), `AddCommGroup → AddCommMonoid` (654),
and `Ring → Semiring` (476).

### Audit verdict

The pre-registered manual source audit passed both extractor thresholds:

- direct declaration binders: **30/30 exact** (threshold 27/30);
- section-inherited binders: **30/30 exact** (threshold 24/30).

“Exact” here means the named declaration/carrier experienced the recorded structural class
change. Some commits also add orthogonal assumptions, split a bundled class, or change other
parts of the signature; E0 does not certify whole-signature logical implication.

The 30 selected commits without a retained event confirm that the population is deliberately
narrow: 5 universe/sort changes, 8 new APIs, 8 proposition/predicate changes or theorem
replacements, 5 carrier/codomain/representation changes, 2 prose-only selector hits, and 2
non-theorem/additive-multiplicative refactors. This is why the 19.52% rate is **not recall**.

### E0 decision

**Proceed to E1, but do not change the detector yet.** The message vocabulary is a strongly
enriched locator for a real, source-auditable expert edit shape, and the extractor is accurate
on its sampled population. E0 still has no opportunity denominator, historical elaboration,
or evidence that Ferris–Howard would have proposed an event before seeing the child diff.

## 10. The next bounded Kuna iteration

The first E1 work unit should be a toolchain-compatible historical replay, not an immediate
rule tuned to the 740 `CommRing → CommSemiring` examples:

1. freeze a commit-grouped chronological development/evaluation manifest before running the
   detector; use a prospective post-2026-08-04 stream as the genuinely unseen holdout;
2. in a temporary Mathlib worktree at each sampled parent `c^`, build with that revision's
   `lean-toolchain` and extract the parent declaration plus local class lattice;
3. run the unchanged detector and record the exact `(declaration, source, target, carrier)`
   proposal path, including every refusal and unexpressible event;
4. elaborate the child signature and verify that it is a type-correct statement in the child
   environment; do not infer this merely from text or the present-day lattice;
5. cluster only verified development misses by pipeline phase, choose one cluster, and make
   one default-off change; ablate it, measure runtime, and inspect every changed replay event;
6. reject the change if it only memorizes a class pair, alters the wrong carrier, or moves
   failures from candidate generation into proof search without improving exact replay.

That is the point where the Kuna analogy becomes a genuine improvement loop: a verified loss,
one localized change, an ablation, a blast-radius audit, and permission for a negative result.

## 11. E1 replay 1: the benchmark unit failed before the detector did

The first frozen replay is recorded in `research/data/kuna-e1-manifest.json`; measured output
and provenance are in `research/data/kuna-e1-result.json`. It selected Mathlib child
`d292472f13fc` and parent `f469a458bcdb`, both on Lean 4.31.0, for
`StarAlgEquiv.restrictScalars_injective`. The parent and child module each built cleanly as
1,222-job targets under the explicit historical toolchain.

The parent extraction contained 164,151 valid rows (225,320,408 bytes, SHA-256
`6c3c34e25d04b8dc7d35fd2eb39fe819664064479af6240a4da8ae02dab2b7af`). The unchanged,
pre-hashed detector built an 833-class, 914-edge lattice with zero parse errors and returned:

```text
{"skipped": "multi-carrier", "carriers": 7}
```

All seven frozen event records therefore receive the pipeline verdict **refused before
candidate generation**. That is a real coverage result, but it is not yet a detector miss.

The adversarial counterfactual changed the conclusion. The carrier-aware Lean detector, run
against the same parent declaration, proposed three unrelated unused binders and **zero of
the seven child events**. More importantly, the exact weak child theorem signature failed to
elaborate in the parent environment and passed unchanged in the child environment. The diff
explains why: the commit generalized `StarAlgEquiv.restrictScalars` and its injectivity theorem
together. The old theorem cannot be weakened in isolation while its named dependency still
requires the old algebra and semiring instances.

E0 represented that coordinated API/telescope refactor as seven declaration/carrier moves.
Those moves are exact structural observations, but they are not seven independent
opportunities available to a single-binder detector on the parent. Treating them as recall
loss would punish the detector for not proposing statements the parent environment cannot
state.

### E1 decision

**Reject the multi-carrier detector change on this sample.** The localized loss is in the
benchmark unit and expressibility gate, not yet in candidate generation. The next replay
must apply these rules before it can enter a detector denominator:

1. Elaborate the proposed child signature against the unchanged parent dependencies.
2. If it fails but passes in the child, inspect whether the commit co-generalized a named
   dependency; retain it as one grouped refactor, not independent binder events.
3. Select a direct, individually expressible parent edit for the next development replay.
4. Only a verified parent-expressible miss can justify an option-gated detector change and
   ablation.

This is a negative Kuna iteration in the useful sense: replay localized the first failure,
and the tempting implementation change was rejected because it would optimize against a
mis-specified loss.

## 12. E1 replay 2: dependency isolation and chronology both failed

Replay 2 is frozen in `research/data/kuna-e1-replay2-manifest.json` and its measured result
is `research/data/kuna-e1-replay2-result.json`. It selected
`Filter.ZeroAtFilter.boundedAtFilter` at child `edcdc3e1603` and parent `09242aa0f47b` under
Lean 4.14.0-rc2. Both 1,367-job module builds passed, and the unchanged detector judged the
sole `NormedAddCommGroup β` binder **at home** rather than proposing `SeminormedAddGroup β`.

The weakened signature by itself elaborates in the parent, but that is not a dependency
certificate: an axiom proves only that the proposition is well formed. The child's actual
proof fails in the parent and passes in the child. The same commit changed
`Asymptotics.isLittleO_one_iff` so it could accept the weaker codomain used by the new proof.
Replay 2 is therefore another coordinated change, not an independently available parent
edit, and does not enter the detector-miss denominator.

This replay also exposed a selection bug. The manifest called the event “newest” after
walking E0 artifact rows, but the artifact is not ordered by Git time. The true newest
single-event direct theorem commit was `8cf8a74bee8b`, dated 2026-02-16. Subsequent selection
must sort Git committer timestamps and then run the child proof unchanged in the parent.

### Replay-2 decision

**Reject detector tuning and strengthen eligibility again.** A valid single-event replay
must pass all three gates before detector output is scored:

1. the whole child telescope is a single intended binder change;
2. the exact child statement and proof elaborate in the unchanged parent;
3. selection chronology comes from Git metadata, not artifact order.

The distinction between “the proposition can be postulated” and “the expert proof is
available before the commit” is load-bearing. Replay 2 passed the former and failed the
latter.

## 13. E1 replay 3: a genuine miss and a bounded recovery ladder

Replay 3 is frozen in `research/data/kuna-e1-replay3-manifest.json`; the full result and
ablation counts are in `research/data/kuna-e1-replay3-result.json`. The corrected selector
chose `Filter.tendsto_div_const_iff` at child `8cf8a74bee8b` and parent `8f9d9cff6bd7`, under
Lean 4.28.0:

```text
CommGroupWithZero G  ->  GroupWithZero G
```

Both 1,225-job historical builds passed from source-clean worktrees. Most importantly, the
exact child theorem body elaborated unchanged with `GroupWithZero G` in the frozen parent
and child kernels. This is a dependency-isolated parent opportunity, so detector output can
finally be classified as a replay loss rather than a benchmark defect.

The parent closure contains 162,287 valid rows (193,561,096 bytes, SHA-256
`e8f74714aaca65add3fb4b01635b0a53c2d1a95b82dcb958c1fce00ead5d57d5`). The frozen detector
hash is still `612bbe49285994b4e0d7d01d5caa8b00a3856b1aeebe4865f95f3215a407ce11`.
It built an 847-class, 847-edge lattice with zero parse errors and returned:

```text
{"skipped": "multi-carrier", "carriers": 2}
```

The refusal is wrong for a concrete, inspectable reason. The theorem has
`CommGroupWithZero G`, `TopologicalSpace G`, and `ContinuousDiv G`; all constrain `G`.
The row parser instead keys `ContinuousDiv` to its synthesized `TopologicalSpace G`
argument. The exact expert event is therefore a **genuine candidate-generation false
negative**.

### Loss localization

One plausible fix was not enough. The loss has three layers:

| layer | measured outcome |
|---|---|
| parameter-aware carrier selection | reaches the declaration, but returns `no-single-home` |
| statement-only evidence | sees `Div` and `OfNat`, but erases the `0` parameter |
| unique weakest bundle | incorrectly chooses `DivInvMonoid`, whose rewritten statement is ill typed |

The carrier rule also has a large blast radius. Across the same parent closure it changes
13,708 theorem results, reduces multi-carrier refusals from 20,540 to 10,132, and newly
judges 9,568 theorems. That may be useful coverage, but it is not a narrow repair justified
by one development event.

The safer experimental lane enumerates every strictly weaker ancestor that covers the
statement-level class heads and then asks Lean to re-elaborate each rewritten statement.
Across the closure it evaluates 10,926 requirement-bearing binder events; 8,671 have a
nonempty cover set and produce 35,461 raw proposals. For the frozen target it produces
exactly five candidates:

```text
DivInvMonoid
DivInvOneMonoid
DivisionCommMonoid
DivisionMonoid
GroupWithZero
```

Historical statement elaboration rejects the first four because they cannot synthesize
`OfNat G 0`. `GroupWithZero` alone remains, and the exact child proof then passes the parent
kernel. Thus the recovery is causally complete:

```text
refusal -> five structural covers -> one well-formed statement -> one kernel proof
```

### Replay-3 decision

**Record the miss and the exact recovery, but do not replace the default detector yet.** The
candidate enumeration recovers the historical event without memorizing its class pair, but
35,461 raw proposals need an automated historical elaboration gate. The first
`#fh_home_attempt` run correctly reported the four invalid targets as `NO STATEMENT`, yet it
did not accept the supplied proof on the surviving target even though the standalone theorem
did. Section 14 localizes and repairs that instrumentation loss without changing the kernel
certificate.

The bounded part is now exposed as `HomeIndex.statement_candidates`, a separate default-off
API. It uses parameter-aware carrier roles, statement-only evidence, and returns the entire
cover set without selecting a theorem. `HomeIndex.home` is unchanged and still returns the
frozen refusal on this replay. `scripts/fh-home-search-selftest.py` pins both behaviors on a
synthetic `ContinuousDiv`-shaped fixture, and the historical parent run returns the same five
candidates measured above.

The next refinement seam is narrower than “improve the heuristic”: preserve applied class
arguments such as `OfNat G 0`, automate probe emission, and then score the option-gated lane
on more frozen events. One recovered development event establishes a real false negative and
a workable pipeline; it does not establish recall.

## 14. E2 repair: polymorphic proof attempts reached the kernel without universes

The replay-3 child proof elaborated as a standalone theorem but initially returned “not
proved” through `#fh_home_attempt`. Printing the rewritten type showed no statement drift: it
was definitionally the exact `GroupWithZero` child signature. Splitting tactic elaboration
from the final kernel call localized the failure to `addDeclCore`.

`tryTactic` created its throwaway theorem with an empty universe-parameter list even though
the rewritten type still referred to the original declaration's `u` and `u_1`. The tactic
closed the goal, and the kernel then rejected the undeclared levels. Existing attempt tests
used `R : Type`, so they were monomorphic and could not expose the defect.

The repair passes `ci.levelParams` into `tryTactic` and records them on the temporary theorem.
`attemptUniverse`, a new `Type*` regression, fails on the old implementation and is proved by
`exact?` on the new one. The historical Lean-4.28 replay then reports:

```text
DivInvMonoid          -> NO STATEMENT
DivInvOneMonoid       -> NO STATEMENT
DivisionCommMonoid    -> NO STATEMENT
DivisionMonoid        -> NO STATEMENT
GroupWithZero         -> not proved by the generic ladder
GroupWithZero         -> PROVED by the supplied child tactic
```

This closes the first complete E2 loop: a dependency-isolated expert loss, localized
representation and prover failures, default-off candidate enumeration, statement filtering,
and an exact kernel proof in the historical parent. The negative generic-ladder result remains
useful—it says the current cheap tactics do not rediscover the argument unaided—but it is no
longer confounded with a broken polymorphic kernel probe.

## 15. Replay 4: the next event is genuinely multi-carrier

Replay 4 is frozen in `research/data/kuna-e1-replay4-manifest.json` and measured in
`research/data/kuna-e1-replay4-result.json`. The corrected chronological selector chose the
next eligible event after replay 3:

```text
Submodule.mul_mem_smul_iff
CommRing S  ->  Ring S
child 4cea329f5d28, parent ff11cd516527, Lean 4.24.0
```

The source diff changes exactly that binder head and leaves the proof text untouched. Both
1,106-job historical targets built cleanly, and the exact `Ring S` statement plus unchanged
child proof elaborate in both the parent and child. This is a second dependency-isolated
expert opportunity.

The parent closure has 143,479 valid rows (175,172,683 bytes, SHA-256
`11d709b781f5b4e35b2c745eddee3bdb7fa20dc90c97c659551450a50e954a3d`). The default row
detector refuses three apparent carriers. Parameter-aware class roles correct the `Algebra`
binder from a synthesized instance to `S`, but the declaration still spans two real
carriers:

```text
CommSemiring R
CommRing S
Algebra R S
```

`HomeIndex.statement_candidates` therefore also refuses. This is the intended sound branch:
row evidence contains used constant names but not the carrier at each use site, so a flat
`Ring` requirement at `R` cannot safely justify weakening `CommRing S`.

The carrier-aware Lean detector, run in the same parent, separates the evidence and reports
the exact event:

```text
[CommSemiring R] -> Semiring
[CommRing S]     -> Ring
[Algebra S]      -> unused
```

The generic tactic ladder does not find the `Ring` proof, but the unchanged child `simp`
argument passes through the repaired `#fh_home_attempt` command and the parent kernel.
The carrier oracle now aligns class applications with their declaration telescopes, so the
instance parameters following `Algebra R S` can no longer masquerade as a third carrier.
The `trailingInstanceCarrier` regression pins that rule in the current toolchain, and the
same helper reruns cleanly in this Lean 4.24 parent: the report now names exactly the two
real carriers `R` and `S` while preserving the exact `CommRing S -> Ring S` proposal.

### Replay-4 decision

**Keep the row refusal and record a second loss cluster.** Replay 3 was blocked by a spurious
carrier assignment and coarse class-head evidence; replay 4 is blocked by genuinely missing
use-site carrier identity. Removing the multi-carrier gate would trade a measured false
negative for unmeasured cross-carrier false positives.

The next causal change belongs in extraction or the row schema: attach each cited class
requirement to the binder/carrier it constrains, then rerun only the newly judgeable
multi-carrier declarations. The carrier-aware Lean result is the differential oracle for
that work. Two valid development misses now establish two distinct pipeline clusters, not a
recall estimate.

## 16. Replay 4 closes the statement-carrier representation seam

The next change was kept separate from both frozen row methods. The extractor now emits an
optional `requirements_statement` field whose entries retain three facts together:

```text
source constant, required class, outer carrier-binder index
```

The source is necessary to apply the existing forgetful-instance exclusion; class and
carrier without provenance would make projection plumbing look semantic. The carrier index
is emitted only when a class's last structural argument is directly an outer declaration
binder. An early prototype recursively searched composite carrier expressions and assigned
requirements about `Submodule R S` to a trailing instance bvar. That is cross-carrier false
evidence, so concrete, composite, and locally-bound carriers are now omitted rather than
guessed. `extractsCarrierUse` pins the trailing-instance case in the current toolchain, and
the shared Lean-only extractor also builds under Replay 4's Lean 4.24.0.

Proof-side extraction was rejected by a performance ablation. With per-row source-role
caching, the 135-row historical module took 18,567 ms when proof requirements were enabled
and 848 ms statement-only. The final statement-only build took 903 ms (plus 1,383 ms to
import), emits 50 raw target requirements, and names exactly carrier indices `0` (`R`) and
`2` (`S`). There is no `requirements_proof` field; a later proof verdict needs a separately
engineered indexed pass, not a hidden closure-wide slowdown.

`HomeIndex.carrier_statement_candidates` consumes the new field as a default-off search
lane. On the frozen 143,479-row parent index with only the target row refreshed, 17 statement
requirements survive the forgetful-source filter. The result is:

```text
CommSemiring @ 0  -> at home
CommRing     @ 2  -> candidates {CommSemiring, Ring, Semiring}
Algebra      @ 2  -> at home
```

The expert `Ring` event is now proposed without moving evidence between `R` and `S`.
`HomeIndex.home` still refuses three apparent carriers and the earlier
`statement_candidates` still refuses two real carriers, exactly as frozen. This is candidate
generation, not a theorem verdict: historical statement re-elaboration filters the set and
the unchanged child proof remains the kernel certificate for `Ring`.

This closes the measured Replay-4 representation seam but does not create a denominator.
The next experiment must freeze a bounded population of multi-carrier historical events,
refresh only those rows, and record newly judgeable proposals, statement failures, proof
successes, and environment failures before any default detector behavior changes.

## 17. MC0: a frozen multi-carrier population finds one recovery and two new losses

The next experiment is frozen in `research/data/kuna-e1-mc0-manifest.json` and measured in
`research/data/kuna-e1-mc0-result.json`. Selection was source-only and detector-blind: newest
E0 commits first, exactly one retained expert event in the commit, an own theorem or lemma,
no other parsed telescope change, at least two distinct parent instance-argument groups, and
no reuse of Replays 1--4. The resulting population has three events. It is source-screened
and explicitly not blind to source shape, so it is a bounded diagnostic population rather
than a recall denominator.

All three exact parents were reconstructed under their pinned historical toolchains (Lean
4.18.0-rc1, 4.12.0-rc1, and 4.10.0-rc2), their target modules built cleanly, and standalone
copies of the exact child statements plus unchanged child proofs passed in the parent
kernels. The three events are therefore genuine parent opportunities rather than coordinated
dependency changes or environment failures.

The full parent closures contain 60,048, 106,733, and 101,096 rows, all with zero parse
errors. `HomeIndex.home` refuses all three as multi-carrier, as does the earlier flat
`statement_candidates` lane. The carrier-attached method separates them:

| expert event | carrier-attached outcome | parent kernel |
|---|---|---|
| `map_div'`: `MonoidHomClass F G H -> MulHomClass F G H` | judged binder, but no candidate; expert target excluded | unchanged proof passes |
| `Module.Finite.finite_basis`: `Ring R -> Semiring R` | refused as `produces-a-class` | unchanged proof passes |
| `Polynomial.map_aeval_eq_aeval_map`: `CommSemiring S -> Semiring S` | exact and unique `Semiring` proposal at carrier `S` | unchanged proof passes |

Thus the frozen outcome is one exact proposal, one wrong-target miss, and one refusal, while
all three expert proofs succeed. The useful positive result is narrow but real: carrier
attachment recovers the polynomial event without moving evidence among `R`, `S`, `T`, and
`U`.

The two failures localize different seams. `map_div'` uses a multi-parameter hom class. The
event binder is reached, but the present class-head ancestry test finds no attached ancestor
requirement that licenses `MulHomClass`; a valid expert target is consequently absent from
the candidate set. `finite_basis` concludes `_root_.Finite ι`, so the broad
`produces-a-class` policy refuses the theorem before inspecting its `Ring R` binder. A
one-event diagnostic that bypasses only that guard returns `Semiring` as the exact candidate,
showing that the carrier representation is sufficient there and the guard is the sole loss.

### MC0 decision

**Do not change either default.** One success in three events validates the representation
seam, not the policy. Removing `produces-a-class` globally from one positive theorem would
also expose instance-producing declarations that the exclusion was designed to suppress,
and proposing arbitrary hom-class ancestors without an attached requirement would be an
uncontrolled expansion.

The next bounded seam is now concrete: distinguish theorem claims with class-valued
conclusions from declarations that produce instances, freeze controls for that policy split,
and separately design a parameter-aware requirement relation for multi-parameter hom
classes. Only then should either change be rescored against the frozen events and controls.

## 18. MC1: the instance registry separates `finite_basis` from real producers

MC1 is frozen in `research/data/kuna-e1-mc1-manifest.json` and measured in
`research/data/kuna-e1-mc1-result.json`. It is explicitly post-hoc: MC0 had already exposed
the `finite_basis` refusal. The question here is narrower than prediction—whether the
historical environment contains an exact fact that separates an ordinary theorem with a
class-valued conclusion from declarations registered for typeclass synthesis.

It does. The extractor now emits `is_instance` as an explicit boolean for every row, read
from `Lean.Meta.isInstanceCore` in the imported environment. This cannot be reconstructed
from the existing `kind` field: in the frozen Lean-4.12 parent, 124 theorem constants whose
conclusions are classes are registered instances, while 439 are not. The current regression
puts an ordinary theorem and a registered instance with the same class-valued conclusion
side by side and requires opposite flags.

The refreshed 106,733-row closure has no unknown flags and 8,804 registered instances.
Deleting only `is_instance` from every refreshed row produces a byte-identical JSON stream
to the MC0 closure, so the statement, dependency, and carrier evidence did not drift. The
full extraction took 79.31 seconds; the Home index again has 634 classes, 881 parent edges,
4,123 forgetful declarations, and zero parse errors.

Among the 10,607 declarations whose conclusion head is a recognized class:

| kind | registered instance | non-instance |
|---|---:|---:|
| constructor | 1 | 599 |
| def | 8,666 | 776 |
| opaque | 0 | 2 |
| theorem | 124 | 439 |

The preregistered first ablation admitted every explicit non-instance in the carrier lane.
It leaked zero registered instances, but it was still much too broad: 611 declarations
produced candidates and 478 of them were constructors or definitions. That policy is
rejected rather than rationalized after seeing the count.

The implemented rule is narrower and remains option-gated:

```text
class-producing row is judgeable only if kind = theorem and is_instance = false
```

Registered theorems, constructors, definitions, opaque constants, and legacy rows with no
flag retain the conservative refusal. `HomeIndex.home` and `statement_candidates` are
unchanged. Across the same frozen closure, zero registered instances enter judgment; 287
non-instance theorem claims are judged, 133 declarations produce 180 candidate-bearing
binders and 834 raw proposals, and 55 candidate declarations are projection-like.

The positive event now passes through the normal method without mutating the index:

```text
Module.Finite.finite_basis
kind = theorem, is_instance = false, conclusion = Finite
Ring @ R -> candidates {Semiring}
```

The exact `Semiring R` child statement and unchanged proof already passed the historical
parent kernel in MC0. Thus the original refusal is closed causally: missing registry
metadata, then an over-broad producer guard, then the exact expert candidate and proof.

### MC1 decision

**Accept the representation and the narrow rule only in the existing default-off carrier
lane.** Do not activate it more broadly. The structural safety control passes—zero actual
instances leak—but 834 raw proposals from class-valued theorem claims have not been tested
for statement elaboration or proof precision. The next experiment must freeze a
deterministic sample stratified by candidate family and projection-like status, then run the
same statement-and-kernel gates used for the expert replays.
