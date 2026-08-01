# FH Solid State, Tier 1: Foundations and the Crystallographic Census

**Status:** Draft 0.1 · First of four tiers for condensed matter. Tier 1 is corpus-building plus contribution targets reachable with existing machinery — the solid-state analogue of the quantum corpus's Q1–Q4.

**Why condensed matter is FH-friendly ground.** The field's foundational layer is unusually discrete: lattices are ℤⁿ-modules, symmetries are finite and crystallographic groups, tight-binding models are finite matrices per momentum, and the deepest organizing principles (Bloch's theorem, symmetry classification) are algebra. physlib already contains the tight-binding model — a foothold placed for us. And the field's culture runs on exactly solvable models treated as load-bearing (1D Ising, SSH, harmonic chains), which is precisely the "solvable model as dictionary column" pattern this project was built on.

## S1.1 — The corpus groups

Eight groups, mirroring the quantum corpus's structure: **lattices and reciprocal lattices** (ℤⁿ sublattices, dual lattice, Brillouin zone as fundamental domain — pure Mathlib territory); **crystallographic symmetry** (point groups, space-group axioms, the wallpaper-group layer — finite group theory, corpus-native); **Bloch theory** (translation-symmetric finite chains: simultaneous diagonalization of commuting translations, Bloch's theorem for finite N as a theorem, thermodynamic limit as statement-level); **tight-binding** (SSH chain, graphene's honeycomb model as 2×2 Bloch Hamiltonians — bridge to physlib's existing formalization); **phonons** (harmonic chain via the ladder-operator skeleton from Q12 — the oscillator ubiquity benchmark collecting its first physics dividend); **classical spin models** (1D Ising transfer matrix with exact free energy — a *computation shipped as a theorem*; 2D Onsager statement-level); **linear response basics** (Kubo formula statement-level, finite-dimensional conductivity as certified matrix algebra); **entanglement in lattice systems** (area-law statements for 1D gapped systems — importing the rigorous literature at statement level, feeding Tier 3).

## S1.2 — Contribution target: the wallpaper and space group census, certified

The classification of the 17 wallpaper groups and 230 space groups is 130-year-old finished mathematics that — remarkably — appears to lack a complete machine-checked treatment. It is finite group theory plus lattice arithmetic: certified exhaustive classification is exactly our muscle. The wallpaper census (17, two dimensions) is a bounded first project with a clean headline; the space-group census (230, three dimensions, with the subtleties of enantiomorphic pairs and non-symmorphic groups) is the full deliverable and would become *the* reference artifact for every downstream symmetry computation in Tiers 2–4 — symmetry indicators, band representations, and magnetic space groups (1651 of them, the stretch goal) all consume this table. Verify-at-step-0 applies as always, but the risk here is low and the reusability maximal.

## S1.3 — Contribution target: certified band structures

Band energies are eigenvalues of explicit Hermitian matrices, computed everywhere and certified nowhere. Interval-arithmetic eigenvalue certificates (the Flyspeck-lineage tooling from Round 4) turn any tight-binding band structure into a theorem: "the SSH gap at these parameters lies in [a, b], kernel-checked." Individually small; as infrastructure, it is the F22-pattern for condensed matter — every Tier 2 topological invariant and Tier 3 gap bound consumes certified spectra, so this target is the tier's load-bearing deliverable disguised as a warm-up.

## S1.4 — Contribution target: exactly solvable, exactly certified

Formalize the 1D Ising solution end-to-end (transfer matrix → free energy → correlation length, with the absence-of-transition theorem), and the harmonic chain's exact spectrum. These are the field's teaching cornerstones, they exercise the corpus groups jointly, and they seed the Atlas: the transfer-matrix skeleton (1D statistical model ↔ 0D quantum chain, β ↔ imaginary time) is the Wick-rotation dictionary row entering the index at its simplest instance — the row Tier 3's duality mining will generalize.

## Tier-1 ledger

Everything here is months-scale with existing machinery. The census (S1.2) is the tier's publishable headline; certified spectra (S1.3) is its infrastructure; the corpus and solvable models are the substrate. Exit criterion for the tier: the wallpaper census certified, the SSH model's spectrum certified across parameter space, and the corpus elaborating end-to-end — at which point Tier 2's invariants have everything they need.
