# The wallpaper census, Phase 1: statement design and scaffold

**Status:** Phase 1 (W0) · 2026-08-06 · G0 passed with amendments
(`ledger-solidstate-ground-check.md`: novelty stands — zero crystallographic content in
Mathlib, absent from AFP, on the community wishlist; race risk recorded). This document
freezes the statement layer before any proof work, because the Couette ledger's central
finding applies here verbatim: *the claim's meaning lives in choices the prose usually
leaves implicit*, and for this census that choice is the equivalence relation under
which "there are exactly 17" is asserted.

## 1. The statement-design decision, made in writing

"There are 17 wallpaper groups" is standardly a count **up to abstract group
isomorphism**. That reading silently uses Bieberbach's rigidity theorem (isomorphic
crystallographic groups are affinely conjugate), without which the isomorphism count and
the geometric (affine-conjugacy) count could differ. The design:

* **The census is stated at abstract isomorphism** (`≃*`), the strong and standard
  reading. It decomposes into three named claims (formalized as `Prop`s in
  `lean/Crystal/Wallpaper/Statements.lean`, zero `sorry`, nothing asserted):
  - `census_existence` — seventeen explicit subgroups of E(2), each a wallpaper group;
  - `census_separation` — pairwise non-isomorphic;
  - `census_completeness` — every wallpaper group is isomorphic to one of them.
* **Bieberbach II (iso ⇒ affine conjugacy) is a separate milestone (W7), not a
  hypothesis.** Nothing in the census statement depends on it; proving it later
  upgrades the census's geometric meaning without touching its text.
* **The primary definition of "wallpaper group" is the lattice form**: a subgroup of the
  plane's isometry group whose translations are exactly the ℤ-span of two ℝ-independent
  vectors, with finitely many cosets over its translations. The textbook geometric
  definition (discrete + cocompact) is recorded as `IsWallpaperGroup_geometric`, and
  *the equivalence of the two definitions is itself a milestone* (W6, the Bieberbach-I
  content in dimension 2) — not assumed, and the census is falsifiable about it: if the
  two definitions disagree, the census as stated is about the lattice form and says so.

## 2. Difficulty, calibrated against what Mathlib holds today

Measured inventory (vendored Mathlib, v4.32.2): `ZLattice` — 14 files (discrete ℤ-spans
in real vector spaces, covolume); group cohomology through H² — present; semidirect
products — present; `AffineIsometryEquiv` and Mazur–Ulam — present; `charpoly` — 27
files. Crystallographic anything — zero.

| milestone | content | effort band |
|---|---|---|
| W0 (this commit) | statements module elaborates; oracle table frozen | done |
| W1 | the 17 concrete groups as explicit presentations; each `IsWallpaperGroup` | weeks |
| W2 | crystallographic restriction (finite-order elements of GL₂(ℤ) have order 1,2,3,4,6 — the trace argument) | days |
| W3 | finite subgroups of GL₂(ℤ) up to conjugacy = the 13 point groups (needs lattice/form reduction — the hard bounded core) | ~a month |
| W4 | extensions per point group: vector systems mod coboundaries + normalizer action (finite computations, H² vocabulary exists) | 2–3 weeks |
| W5 | pairwise non-isomorphism via a computable invariant battery (point-group order, orientation index, abelianization — f.g. abelian iso is decidable) | 1–2 weeks |
| W6 | completeness assembly + definitional equivalence (Bieberbach I, dim 2) | weeks |
| W7 (stretch) | Bieberbach II rigidity | month+ |

Honest total: **3–5 months single-lane for the strong-statement wallpaper census**;
the 230 space groups reuse the skeleton at year scale. The shape suits this pipeline
unusually well: W2–W5 are certified finite computation (traces, integer matrices, finite
cohomology, decidable invariants) — the D5-census muscle — and only W3/W6 carry genuine
formalization risk.

## 3. Controls, named before any proof exists

* **Differential oracle:** the CARAT/GAP enumeration (unverified computational
  crystallography, dims ≤ 6). `scripts/wallpaper-oracle.py` freezes the 17-row reference
  table (IT numbers, point-group orders, orientability, symmorphic flags) with
  provenance; every Lean-side invariant computed in W1/W5 is diffed against it. A
  disagreement is a finding either way.
* **Negative control (the census must be able to say no):** a frieze group (rank-1
  translations) must be rejected by `IsWallpaperGroup`; this is pinned as a test the
  moment W1's machinery can state it.
* **Planted-duplicate control:** an 18th candidate presentation, deliberately isomorphic
  to one of the 17 in disguise, must be *caught* by the separation battery — a
  separation instrument that never collides is not measuring.

## 4. Risks

Race (it is on the Mathlib wishlist; mitigate by landing W1+W2 early and visibly);
W3's reduction theory having no Mathlib precedent; the E(2) API friction between
`IsometryEquiv` and affine-map machinery (Mazur–Ulam exists to bridge, W6's business);
and the standing rule inherited from G0 — every novelty sentence ships as a bounded,
dated search claim, never "nobody has done this."
