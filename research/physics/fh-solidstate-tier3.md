# FH Solid State, Tier 3: Gaps, Phases, and Dualities

**Status:** Draft 0.1 · Third tier. Ambition step: from classifying Hamiltonians to proving things about their *physics* — spectral gaps, phase structure, and the duality web — where the pipeline's signature trick (finite certificate → infinite conclusion) becomes the whole game.

**The tier's thesis.** The deepest questions of the field concern thermodynamic limits, which no finite computation touches — *except* through a family of remarkable theorems (finite-size gap criteria, MPS classification, transfer-matrix positivity) that convert a checkable finite condition into an infinite-volume conclusion. Those conversion theorems are the field's own Euclidean-domain moment: identify the finite certificate that carries infinite weight, then let machines hunt certificates. Tier 3 industrializes that pattern.

## S3.1 — Certified spectral gaps via finite-size criteria

Knabe-type bounds and the martingale method prove theorems of the form: *if* a finite-chain gap exceeds an explicit threshold, *then* the infinite system is gapped. The hypothesis is a finite eigenvalue computation — exactly what Tier 1's certified-spectra infrastructure produces. Program: formalize the criteria (frustration-free spin chains first), then run certified gap campaigns: for model families of interest, machine-search the parameter space for points where the finite criterion certifiably fires, shipping "this model is gapped in region R" as theorems about infinite quantum systems obtained from kernel-checked finite algebra. The genre's crown precedent is the 2D AKLT gap — settled only recently, *computer-assisted*, by exactly this shape of argument with the numerics unverified; re-deriving a result of that class with the numerical core certified is the tier's flagship, and extending the method's reach (better thresholds, new lattices) is open research the criterion literature actively wants.

## S3.2 — Phase classification through certified MPS

In one dimension the phase story is rigorous: gapped phases classified via matrix product states, SPT order detected by projective symmetry data on the MPS tensors — finite multilinear algebra. Program: formalize the MPS toolkit (canonical forms, injectivity, the fundamental theorem) — a service to quantum-information formalization far beyond this tier — then certified phase diagnostics: given a concrete MPS family, the projective class (the SPT label) computed and proven, transitions located as certified failures of smooth interpolation. Target models: cluster state, AKLT, the standard SPT menagerie. Deliverable shape: the 1D phase classification operating as a *certified instrument* — feed it a model family, receive theorems about which phases occur where. Honest boundary: 2D phase classification is Tier-4-and-beyond; here the two-dimensional content is statement-level imports.

## S3.3 — The duality web, mined on the lattice

Round 2's A4 (duality mining) lands here with its natural target set: condensed matter's duality web — Kramers–Wannier, Jordan–Wigner, boson–vortex, the modern 2+1d web — much of which is *exact and finite* on the lattice. Program: certify the classical instances as transport rows (Kramers–Wannier as the mandatory calibration, Jordan–Wigner as an exact operator dictionary with the fermion-boundary-term subtleties finally pinned in a kernel rather than an appendix); then run the collision-mining engine over lattice model families with the Atlas prioritizing structurally-rhyming pairs. The specialized payoff over A4-generic: condensed matter's web is *dense* — new exact finite dualities plausibly exist near the known ones, and even certified re-derivations carry value here because the web's lattice-level details (boundary conditions, symmetry sectors) are notoriously error-prone in the literature.

## S3.4 — Sign-problem cartography for frustrated magnets

Round 4's C4, specialized to its highest-value habitat: frustrated magnetism and doped systems, where the sign problem gates the field's biggest questions (spin liquids, the Hubbard territory Tier 4 enters). Certified cures for specific frustrated families (proven stoquastic bases → classical simulability theorems) and certified no-gos within transformation classes, assembling a *sign-problem phase diagram* of the standard model zoo — folklore replaced by boundaries with proofs.

## S3.5 — The decidability boundary, drawn where it was discovered

The spectral-gap undecidability theorem (Cubitt–Pérez-García–Wolf) *is* a condensed-matter statement — B6's phase-diagram program has its natural home in this tier. The near-term rung: certified decision procedures for the decidable side (gap-ness for commuting-projector models, phase equivalence for finite stabilizer families), which compose directly with S3.1's gap certificates and S3.2's phase instrument: one toolkit that either *decides* your model's question with a verified algorithm or *locates* it beyond the decidable boundary — a piece of scientific software with no existing analogue.

## Tier-3 ledger

S3.1 and S3.2 are the tier's spine and are startable once Tier 1's spectra infrastructure exists; S3.3 rides Round 2 machinery; S3.4/S3.5 are steady-state programs shared with earlier rounds. Exit criterion: one certified thermodynamic-limit gap theorem, the 1D phase instrument running, and Kramers–Wannier rediscovered by the miner. The tier's meta-payoff: it establishes the *finite-certificate-infinite-conclusion* pattern as the pipeline's core physics product — which is exactly the pattern Tier 4 will need, stretched to its limits, against the problems the field actually loses sleep over.
