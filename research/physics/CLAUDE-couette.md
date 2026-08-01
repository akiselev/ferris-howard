# CLAUDE.md — Project `couette-re-e`: Certified Energy Stability of Plane Couette Flow

You are an agent working on the first end-to-end problem of the Ferris–Howard / Atlas / Effective-Calculus pipeline. This file is your contract: context, workflow, hard rules, phase gates, and tutorials. Read it fully before acting. When this file conflicts with anything else you've been told, this file wins, except for the kernel — the kernel always wins.

## 0. The problem, and why it was chosen

**Mathematical target.** For plane Couette flow (base flow U(y) = y between plates at y = ±1), the *energy stability threshold* Re_E is the largest Reynolds number below which every divergence-free perturbation's kinetic energy decays monotonically. It is characterized variationally: energy monotonicity at Reynolds number Re holds iff the quadratic form

    Q_Re[u] = (1/Re) · ∫|∇u|² + ∫ u v U′(y)     (u div-free, no-slip)

is positive semidefinite; Re_E is the threshold. The literature value is Re_E ≈ 20.7 (Joseph-era result, attained by streamwise-independent rolls). **Our deliverable is the bracket:** a kernel-checked theorem `Re_E ∈ [a, b]` with rational a, b enclosing the literature value, assembled from (i) a certified *lower* bound (positivity of Q_Re proven for Re ≤ a: finite-dimensional certificate + analytic tail bound) and (ii) a certified *upper* bound (an explicit rational trial field with certified negative energy derivative at Re = b).

**Why this problem is the flagship tutorial:** the answer is a single number with known ground truth (calibration is honest); the mathematics is quadratic-form positivity (the pipeline's signature skeleton — same family as Weil, NPA, bootstrap); it exercises every layer — FH statements, Rust search, rational certificates, Lean interval verification, Atlas registration, Effective-Calculus packaging — at the smallest size that isn't a toy; and its stretch goal (auxiliary-functional bounds beyond the energy method) walks off the map into genuinely open territory. If the pipeline works, it works here first.

**⚠ Phase 0 amendment (2026-08-01, see `ledger/phase0-ground-check.md`).** The ground check found the classical threshold is *contested in the current literature*: the classical Joseph value (≈20.65, streamwise-perturbation maximizer) is challenged by a 2021–2023 line of work (incl. a SIAM J. Appl. Math 2023 paper) claiming streamwise perturbations are energy-stable at all Re and the true monotone threshold is Orr's spanwise value (≈44.3). Consequences, binding on all later phases: (1) frozen statements must name the quadratic form **and the admissible perturbation class** explicitly — the theorems are about precisely-stated variational problems, never about the ambiguous phrase "energy stability of Couette flow"; (2) `ANSWER_KEY.md` carries **both** thresholds keyed to their admissible classes; (3) the project gains a co-deliverable: a kernel-checked *adjudication* of the dispute — which precisely-stated problem has which threshold, difference exhibited as a hypothesis diff (formal-referee genre, first fluids case); (4) no prior formalization or certified-numerics treatment of any of this was found — the novelty claim stands, twice over.

## 1. Repository layout and modes

```
couette-re-e/
  CLAUDE.md                  ← this file
  ANSWER_KEY.md              ← frozen expectations; READ-ONLY; see §6 rule H6
  statements/                ← FH (or bootstrap-Lean) statement files; hash-frozen after Phase 1
  search/                    ← Rust: discretization, eigen-solvers, certificate synthesis
  certs/                     ← machine-generated rational certificates (JSON)
  lean/                      ← the Lean package; imports Mathlib; verification lives here
  atlas/                     ← metadata emissions: skeletons, regime tags, dictionary rows
  ledger/                    ← findings, failures, phase-gate sign-offs (append-only)
  writeup/                   ← the human-readable paper draft
```

**Bootstrap mode vs FH mode.** The FH frontend (M0) may not have landed when you start. In *bootstrap mode*, `statements/` contains Lean 4 files written against Mathlib directly, with FH-style declarations kept as doc comments above each Lean declaration (so migration to FH syntax is a mechanical diff later). Everything else in this workflow is mode-independent. Do not block on FH tooling; the mathematics does not wait for the syntax.

## 2. Hard rules (violations invalidate the phase, no exceptions)

- **H1 — Nothing counts until it re-elaborates from source.** REPL exploration is encouraged; REPL state is never evidence. Every claim is backed by a clean `lake build` (or `fh check`) from a fresh environment.
- **H2 — Statement freeze.** After Phase 1 sign-off, the target statements' hashes are recorded in `ledger/freeze.txt`. The final theorems must match those statements definitionally. If you believe a statement is *wrong*, you do not edit it — you file a ledger entry, halt the phase, and escalate. Statement drift is the classic failure mode of agent proof work; the freeze is how we make it impossible to do silently.
- **H3 — Axiom audit.** Final proofs must pass `#print axioms` against the whitelist: `propext`, `Classical.choice`, `Quot.sound`. `native_decide` is allowed **only** in Phase 2 exploration, never in a final certificate. Any `axiom` declaration anywhere in `lean/` is a build failure.
- **H4 — Sorry budget.** Phases 1–2: unlimited `sorry` (statements and scaffolding). Phase 4 exit: zero `sorry` in the transitive closure of the two main theorems. The CI reports the count; the count only moves down after Phase 3.
- **H5 — Unverified search is free; unverified conclusions are forbidden.** Rust-side numerics may use floats, heuristics, anything — their outputs are *candidates*. The moment a number appears in a Lean statement it must be a rational (or interval) that a kernel-checked computation validates. The pipeline's whole shape: search dirty, certify clean.
- **H6 — Answer-key discipline.** `ANSWER_KEY.md` records the literature value and known optimal-roll structure for *calibration checks at phase gates only*. Never consult it during search or certificate construction; never encode its numbers into trial fields or thresholds. The gate scripts compare your outputs against it; you don't.
- **H7 — Ledger everything.** Failed approaches, dead ends, surprising numerics, tool bugs: append to `ledger/findings.md` with date and phase. At this project's scale, the failure log is half the deliverable (it seeds the Atlas and the next problem's priors).

## 3. Tooling reference

| Tool | Use | Notes |
|---|---|---|
| `lake build` / `fh check` | the oracle | H1; JSON diagnostics; sorry count |
| Lean REPL (`repl/`) | goal exploration, tactic trials | fork states freely; see H1 |
| `exact?`, `apply?`, `rw?` | Mathlib retrieval at a goal | first resort at any stuck goal |
| Loogle / LeanSearch | Mathlib retrieval by shape / NL | before writing ANY analysis lemma, search — it may exist |
| `cargo run -p search -- ...` | discretization + eigensolvers | Phase 2; outputs `certs/*.json` candidates |
| `cargo run -p certify -- ...` | float→rational certificate synthesis | Phase 3; outputs exact certificates |
| `scripts/gate.sh <phase>` | phase-gate acceptance tests | must pass before ledger sign-off |
| `atlas emit` | metadata registration | Phase 6; skeleton/regime tags |

## 4. The workflow, phase by phase

### Phase 0 — Ground check (half a day)

Verify the problem is still ours: search recent literature and formalization channels for any existing machine-checked energy-stability result (there should be none; confirm and ledger the search). Build the Lean package against pinned Mathlib; pull olean caches; confirm the REPL and gate scripts run. **Gate G0:** clean build, ledger entry `phase0-ground-check` with the literature-search record.

### Phase 1 — The statement layer (1–2 days)

Write `statements/` covering, at statement level: incompressible perturbation fields on the channel (periodic in x, z with wavenumbers as parameters; no-slip in y); the energy identity (the Reynolds–Orr equation — state it; its proof is Phase 4 work); the quadratic form Q_Re; the definitions `energyStableAt (Re) : Prop` and `Re_E` as a supremum; and the two target theorems with named rational placeholders:

```rust
// FH-style (bootstrap mode: as Lean with this as doc comment)
theorem couette_energy_stable_below(Re: Rat, h: Re <= LOWER) -> energyStableAt(Re) { todo!() }
theorem couette_not_monotone_above() -> !energyStableAt(UPPER) { todo!() }
theorem re_e_bracket() -> (LOWER <= Re_E) && (Re_E <= UPPER) { todo!() }
```

Decisions to make and ledger (these are real formalization choices, not busywork): function-space setting (recommend: work on finite Fourier×Chebyshev truncations as the *definition layer*, with the infinite-dimensional form defined via suprema over truncations — this makes the tail-bound lemma of Phase 3 the explicit bridge and keeps early phases finite-dimensional); scaling conventions (half-gap = 1, U′ = 1 — fix once, everywhere). **Gate G1:** statements elaborate; a domain-expert-persona review pass (a second agent, adversarial: "does `energyStableAt` say what the literature means?") signed in the ledger; hashes frozen. This gate is the project's most important human-judgment moment — a wrong statement certified perfectly is worse than no result.

### Phase 2 — Dirty search: find the truth before proving it (2–4 days)

In `search/`: Chebyshev–Galerkin discretization of the Euler–Lagrange eigenproblem for Q_Re over divergence-free fields at each wavenumber pair (α, β); scan the wavenumber plane; locate the minimizing structure and the numerical threshold. Expected outcome (calibration, checked by the gate against the answer key, not by you): threshold near 20.7, minimizer streamwise-independent (α = 0). Then produce the two *candidate artifacts*: a candidate `LOWER` (slightly below threshold, with the discretized form's spectral gap comfortably positive and an estimate of tail-bound headroom) and a candidate trial field for `UPPER` — projected to a low-mode rational vector field, divergence-free *exactly* (build it from a streamfunction so incompressibility is structural, not numerical). Emit both to `certs/candidates.json`. **Gate G2:** convergence study logged (threshold stable under resolution doubling); candidates emitted; calibration check passes.

### Phase 3 — Certificate synthesis (the technical heart; 1–2 weeks)

Two independent certificate builds. **(3a) Upper bound.** Interval-evaluate the production and dissipation integrals of the rational trial field symbolically-exactly (they're integrals of polynomials×trig — closed forms; compute them as exact rationals in Rust, then re-verify the same closed forms in Lean via `norm_num`-grade arithmetic). Output: exact rationals P, D with P/D > 1/UPPER ⇒ energy grows initially at UPPER ⇒ `¬ energyStableAt UPPER`. This certificate is the *easy* one — build it first, end to end, as the pipeline's shakedown. **(3b) Lower bound.** Two components: a finite-dimensional positivity certificate for the truncated form at Re = LOWER — preferred form: an exact rational **LDLᵀ factorization** of the truncated matrix (diagonal entries positive ⇒ PSD; the certificate is the factorization, checking it is multiplication — the cheapest possible kernel verification); and the **tail lemma** — an analytic Poincaré/spectral-gap estimate showing high modes beyond the truncation contribute dissipation-dominated positivity with explicit constants (this is the phase's real mathematics: a short, honest analysis lemma; search Mathlib hard before writing it — pieces of it exist). Compose: truncated-PSD + tail-domination ⇒ Q_Re ⪰ 0 ⇒ `energyStableAt LOWER`. **Gate G3:** both certificates check in Rust; the tail lemma's statement reviewed adversarially (second agent) and its Lean proof skeleton compiles with ≤ 3 `sorry`s, each ledgered with a plan.

### Phase 4 — Kernel verification (1–2 weeks)

Drive `sorry` to zero. Working order: (i) the Reynolds–Orr energy identity (integration by parts under the stated boundary conditions — Mathlib's `MeasureTheory`/`intervalIntegral` machinery; expect this to be the grindiest item); (ii) the LDLᵀ check as a `decide`-free exact-rational computation (`Rat` arithmetic scales; if kernel time balloons, restructure the certificate — smaller truncation with more tail headroom — rather than reaching for `native_decide`, per H3); (iii) the tail lemma; (iv) assembly of the three target theorems. Then the full protocol: fresh-environment build, zero sorry, axiom audit, statement-hash match, `lean4checker` recheck. **Gate G4:** all five checks green in CI; the bracket theorem exists.

### Phase 5 — Effective-Calculus packaging (1 day)

Package the result as the calculus's artifact: the theorem *is* a regime-carrying statement (`energyStableAt` for `Re ≤ LOWER` — regime explicit, error zero, cost = the certificate's check time; record the (error, regime, cost) triple in `atlas/` metadata). Register the *bracket* as the project's product type: this is the pipeline's canonical two-sided-bound artifact, and its metadata schema is what every later bracket (Hubbard, helium, molecular) will reuse — you are setting the template; keep it boring and complete.

### Phase 6 — Atlas registration (1 day)

Emit: the skeleton tag (`quadratic-form-positivity` family) with the explicit dictionary row linking this certificate's shape to the NPA/bootstrap/Weil-positivity cluster; regime and dependency metadata; the tail-lemma as a reusable named lemma with its own entry (it will recur in every spectral-truncation argument this program ever runs — it is a promotion candidate the moment it recurs, per §8 of the Effective Calculus doc). Run `atlas similar` on the main theorem as a sanity probe and ledger what comes back — this problem doubles as live Atlas test data.

### Phase 7 — Writeup and stretch (open-ended)

`writeup/`: the paper draft — prose + certificate + repo link, AI involvement disclosed per the standing etiquette; the headline is honest and sufficient: *the first machine-checked hydrodynamic stability threshold*. **Stretch (opens the research frontier):** replace the energy functional with searched auxiliary functionals (the SOS/Chernyshenko–Goulart genre) to push certified monotonicity-style bounds above Re_E toward the transition region — machine-searched functional, kernel-checked positivity, same certificate shape, unmapped territory. The stretch has no gate; it has a ledger and ambition.

## 5. Tutorial 0 — the loop in miniature (run this before Phase 1)

To internalize the search→certify→verify loop at zero risk, first run it on a toy: prove `λ_min(M) > 1/10` for the explicit 4×4 rational matrix in `tutorial/toy.json`. Steps: (1) Rust: compute the float eigenvalue (~0.11); (2) Rust: synthesize the rational certificate — an exact LDLᵀ of `M − (1/10)·I`; (3) Lean: state `theorem toy : ∀ v ≠ 0, (M - (1/10)•1).quadForm v > 0`... via the factorization check; (4) build clean, audit axioms, done. Every Phase-3/4 skill is this tutorial at scale. Expected time: one session. If any step confuses you, the confusion is important — ledger it; the tutorial's friction log is how this file improves.

## 6. Failure and escalation

Stuck > 4 hours on one goal: ledger it, fork the REPL state, try the retrieval tools again with different framings, then move to another item — the phase plans have parallel tracks on purpose. Tail lemma resists: fall back to a larger truncation + cruder tail constant (certified headroom is adjustable; elegance is not a gate criterion). Certificate too slow in kernel: shrink truncation, never weaken H3. Suspected statement error: H2 procedure, full stop. Two agents disagreeing about mathematics: both positions in the ledger, resolve by constructing the discriminating check — this project settles arguments by building the experiment, which is the whole point of it.

## 7. Definition of done

`re_e_bracket` proven under the full H-protocol with LOWER ≥ 20 and UPPER ≤ 21; artifacts registered in Atlas with the positivity-skeleton row; writeup drafted; ledger complete including the failure log; and Tutorial 0 plus this file updated with everything the next problem's agents should know that you wish you had. The bracket is the theorem; the *pipeline having run once* is the result.
