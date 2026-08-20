# The $\Delta(54)$ 3HDM target

> Status: technical planning note, 2026-08-02. Equations attributed to the source
> are sourced; the full-potential boundary theorem is an Atlas/FH research
> hypothesis until proved and independently reviewed.

## 1. Target and epistemic status

The primary source is Jurčiukonis and Lavoura,
[“Conditions for boundedness from below of a $\Delta(54)$-symmetric
three-Higgs-doublet model”](https://arxiv.org/abs/2605.07651), arXiv:2605.07651
v1 (2026). The authors derive an eight-vertex orbit-space criterion and report
agreement on one million randomly generated quartic potentials. Their exact
polytope construction is also available in the
[`4D-polytope` repository](https://github.com/jurciukonis/4D-polytope).

This document distinguishes:

- **Source result:** stated or directly derived in the paper.
- **Exact reformulation:** algebraically equivalent, but chosen for Lean.
- **Research hypothesis:** a new statement we intend to prove or refute.
- **Novelty status unknown:** not found in the targeted search, but absence from
  the literature has not been certified.

## 2. Fields, Gram matrices, and charge

Let each Higgs doublet be a vector $\Phi_i\in\mathbb C^2$, and arrange the three
columns into a $2\times3$ matrix

$$
M=(\Phi_1\;\Phi_2\;\Phi_3).
$$

There are two useful Gram matrices:

$$
K=M^\dagger M\in\mathbb C^{3\times3},\qquad
S=MM^\dagger\in\mathbb C^{2\times2}.
$$

$K_{ij}=A_{ij}=\Phi_i^\dagger\Phi_j$ contains the gauge-invariant inner
products. It is Hermitian positive semidefinite and has rank at most two.
Conversely, every positive semidefinite $3\times3$ Hermitian matrix of rank at
most two is a Gram matrix of three vectors in $\mathbb C^2$. This is the standard
$N$-Higgs orbit-space representation; see
[Ivanov and Nishi](https://arxiv.org/abs/1004.1799).

For a nonzero field configuration:

- rank $K=1$ means all three doublets are collinear in $\mathbb C^2$ and the
  configuration can be gauge-rotated to neutral form;
- rank $K=2$ is a charge-breaking configuration.

This rank criterion is cleaner for formal work than a gauge-fixed angular
parameterization. The zero configuration is handled separately.

## 3. The symmetric potential

Define

$$
\begin{aligned}
N &= A_{11}+A_{22}+A_{33},\\
Q &= A_{11}A_{22}+A_{11}A_{33}+A_{22}A_{33},\\
R &= |A_{12}|^2+|A_{13}|^2+|A_{23}|^2,\\
P &= A_{12}A_{13}+A_{21}A_{23}+A_{31}A_{32}.
\end{aligned}
$$

The source gives the most general renormalizable $\Delta(54)$-invariant scalar
potential as

$$
V=V_2+V_4,qquad V_2=\mu N,
$$

$$
V_4=\lambda_1N^2+\lambda_2(R-Q)
+2\lambda_3(\operatorname{Re}P-R)+\lambda_4Q
+2\sqrt3\lambda_5\operatorname{Im}P,
$$

with real $\mu,\lambda_1,\ldots,\lambda_5$. For $N>0$, define normalized orbit
coordinates

$$
x=\frac{R-Q}{N^2},\quad
y=\frac{2(\operatorname{Re}P-R)}{N^2},\quad
q=\frac{Q}{N^2},\quad
t=\frac{2\sqrt3\operatorname{Im}P}{N^2}.
$$

Then

$$
V=\mu N+\widehat\lambda(x,y,q,t)N^2,
$$

where

$$
\widehat\lambda=\lambda_1+\lambda_2x+\lambda_3y+\lambda_4q+\lambda_5t.
$$

The normalization must never be applied at $N=0$. The formal development should
prove unnormalized homogeneous inequalities first and introduce $(x,y,q,t)$ only
under the hypothesis $N>0$.

## 4. Six facets as sums of squares

Every realized orbit point obeys

$$
-\frac14\le x\le0,\qquad
3x+y+3q\ge0,\qquad
q\le\frac13,\qquad
y\le t\le-y.
\tag{F}
$$

The paper proves these bounds with elementary identities plus an angular
maximization for $x\ge-1/4$. For Lean, all six can be expressed as direct
non-negativity or sums of squares.

### 4.1 $x\le0$: pairwise Gram determinants

For any two doublets $u=(a,b)$ and $v=(c,d)$,

$$
\|u\|^2\|v\|^2-|u^\dagger v|^2=|ad-bc|^2\ge0.
$$

Summing the three pairs gives

$$
Q-R=\sum_{i<j}|\det(\Phi_i\;\Phi_j)|^2\ge0,
$$

which is exactly $x\le0$ after normalization.

### 4.2 $x\ge-1/4$: a $2\times2$ Gram identity

Cauchy–Binet gives

$$
\det S=Q-R,qquad \operatorname{tr}S=N.
$$

For the $2\times2$ Hermitian matrix $S$,

$$
N^2-4(Q-R)
=(S_{11}-S_{22})^2+4|S_{12}|^2\ge0.
$$

Thus $Q-R\le N^2/4$, or $x\ge-1/4$. This exact reformulation removes all
trigonometry, compactness, differentiation, and eigenvalue reasoning from the
hardest-looking bound.

### 4.3 $q\le1/3$: equality of three nonnegative norms

Put $a_i=A_{ii}=\|\Phi_i\|^2\ge0$. Then $N=a_1+a_2+a_3$ and
$Q=a_1a_2+a_1a_3+a_2a_3$, so

$$
N^2-3Q
=\frac12\left((a_1-a_2)^2+(a_1-a_3)^2+(a_2-a_3)^2\right)\ge0.
$$

### 4.4 The remaining three facets: Fourier-mode squares

The identity

$$
|A_{12}+A_{23}+A_{31}|^2=R+2\operatorname{Re}P\ge0
$$

becomes $3x+y+3q\ge0$.

Let $\omega=(-1+i\sqrt3)/2$, so
$\omega^3=1$, $1+\omega+\omega^2=0$, and $|\omega|=1$. Then

$$
\begin{aligned}
|A_{12}+\omega A_{23}+\omega^2A_{31}|^2
  &=R-\operatorname{Re}P-\sqrt3\operatorname{Im}P,\\
|A_{12}+\omega^2 A_{23}+\omega A_{31}|^2
  &=R-\operatorname{Re}P+\sqrt3\operatorname{Im}P.
\end{aligned}
$$

These give $t\le-y$ and $y\le t$. The exact algebraic definition of $\omega$
is preferable to $\exp(2\pi i/3)$ in Lean.

The redundant inequality $x+q=R/N^2\ge0$ is also available as a useful sanity
lemma, although it is implied by (F).

## 5. The exact polytope

The six half-spaces (F) define a four-dimensional polytope $\mathcal P$ with
eight vertices:

| vertex | $(x,y,q,t)$ | class |
|---|---|---|
| $v_1$ | $(0,0,0,0)$ | neutral |
| $v_2$ | $(0,0,1/3,0)$ | neutral |
| $v_3$ | $(-1/4,0,1/3,0)$ | charge-breaking |
| $v_4$ | $(-1/4,0,1/4,0)$ | charge-breaking |
| $v_5$ | $(-1/4,-1/4,1/3,1/4)$ | charge-breaking |
| $v_6$ | $(0,-1,1/3,1)$ | neutral |
| $v_7$ | $(-1/4,-1/4,1/3,-1/4)$ | charge-breaking |
| $v_8$ | $(0,-1,1/3,-1)$ | neutral |

The source supplies explicit Higgs-doublet witnesses for all eight vertices.
The formalization should evaluate the invariants on those witnesses and prove
their rank/charge classification. Several witnesses contain $\sqrt3$ and
$\omega$, but the resulting orbit coordinates are rational.

The exact external H-to-V calculation is tiny: six facet hyperplanes and
$\binom64=15$ four-hyperplane intersections, filtered by the six inequalities.
The source repository performs this calculation with exact Mathematica
arithmetic. We should reproduce it independently and let Lean check the resulting
certificate; the external enumerator is never part of the trust base.

### The convex-hull shortcut

Let $\mathcal O$ be the set of physically realized orbit points. We only need:

1. $\mathcal O\subseteq\mathcal P$, from the six inequalities;
2. $\mathcal P=\operatorname{conv}\{v_1,\ldots,v_8\}$, from an exact certificate;
3. $v_i\in\mathcal O$ for every $i$, from explicit field witnesses.

For every linear functional $L$,

$$
\min_{z\in\mathcal O}L(z)
=\min_{z\in\mathcal P}L(z)
=\min_i L(v_i).
$$

We do **not** need to prove that $\mathcal O=\mathcal P$, characterize every
curved boundary of $\mathcal O$, or formalize a four-dimensional picture. This
is the main feasibility insight of the campaign.

There are two good Lean certificate shapes:

- prove a rational V-representation/barycentric decomposition for every point
  satisfying (F); or
- split on which vertex value is minimal and use a Farkas/`linarith`
  certificate to derive $L(z)\ge L(v_i)$ in each of eight cases.

We should prototype both and keep the smaller checked proof.

## 6. The eight coupling forms

Evaluating $\widehat\lambda$ at the vertices gives

$$
\begin{aligned}
h_1&=\lambda_1,\\
h_2&=\lambda_1+\lambda_4/3,\\
h_3&=\lambda_1-\lambda_2/4+\lambda_4/3,\\
h_4&=\lambda_1-\lambda_2/4+\lambda_4/4,\\
h_5&=\lambda_1-(\lambda_2+\lambda_3)/4+\lambda_4/3+\lambda_5/4,\\
h_6&=\lambda_1-\lambda_3+\lambda_4/3+\lambda_5,\\
h_7&=\lambda_1-(\lambda_2+\lambda_3)/4+\lambda_4/3-\lambda_5/4,\\
h_8&=\lambda_1-\lambda_3+\lambda_4/3-\lambda_5.
\end{aligned}
$$

Write $m=\min_i h_i$. The source criterion is that the quartic potential is
non-negative exactly when all $h_i\ge0$. It reports that this criterion selected
exactly the same 561,771 cases as `NMinimize` from a sample of one million random
quartic potentials. That numerical match is strong evidence, but our certificate
will come from the six facets, exact polytope, and vertex witnesses—not from the
sample.

For the CP-invariant slice $\lambda_5=0$, $v_5$ and $v_7$ project to one vertex
and $v_6$ and $v_8$ project to one vertex, leaving six vertex forms. This is an
excellent positive control before the full eight-vertex theorem.

## 7. Freeze three different stability statements

The word “BFB” is dangerously overloaded. FH should freeze at least these three
predicates:

$$
\begin{aligned}
\operatorname{QuarticNonnegative}(\lambda)
&:\!\iff \forall\Phi,\ 0\le V_4(\lambda,\Phi),\\
\operatorname{QuarticPositive}(\lambda)
&:\!\iff \forall\Phi\ne0,\ 0<V_4(\lambda,\Phi),\\
\operatorname{FullBFB}(\mu,\lambda)
&:\!\iff \exists c\in\mathbb R,\ \forall\Phi,\ c\le V(\mu,\lambda,\Phi).
\end{aligned}
$$

The first two are homogeneous quartic claims. The third is the actual lower-
boundedness of the full polynomial. We should never store or publish a theorem
named merely `bfb` without recording which predicate it means.

The expected exact quartic statements are

$$
\operatorname{QuarticNonnegative}(\lambda)
\iff \bigwedge_{i=1}^8 h_i\ge0,
$$

$$
\operatorname{QuarticPositive}(\lambda)
\iff \bigwedge_{i=1}^8 h_i>0.
$$

The strict statement follows because the normalized orbit domain is compact and
its minimum is $m$, while $V_4=N^2\widehat\lambda$.

## 8. Candidate boundary refinement

The source assumes $\mu<0$, writes $h_i\ge0$, and discusses boundedness of the
potential. At a realized vertex with $h_i=0$, however, scaling its field witness
gives

$$
V=\mu N.
$$

If $\mu<0$, this tends to $-\infty$. The all-zero quartic couplings are the
simplest adversarial example. This suggests that non-strict inequalities are
exact for **quartic non-negativity**, but strict inequalities are required for
the **full potential** under the paper’s $\mu<0$ assumption.

This is a research hypothesis, not yet a declared correction. The terminology
may encode a convention about “BFB of the quartic part,” and a final literature
refresh or author clarification may resolve it. The formal campaign should test
the following stronger classification:

> **Proposed full-potential theorem.** Let $m=\min_i h_i$. Then
> $$
> \operatorname{FullBFB}(\mu,\lambda)
> \iff
> \left(\mu\ge0\land m\ge0\right)\lor m>0.
> $$

Equivalently,

$$
\operatorname{FullBFB}(\mu,\lambda)
\iff
(\mu\ge0\land\forall i,\ h_i\ge0)
\lor(\forall i,\ h_i>0).
$$

If the theorem holds, the exact global infimum is

$$
\inf_\Phi V=
\begin{cases}
-\mu^2/(4m), & m>0\text{ and }\mu<0,\\
0, & m\ge0\text{ and }\mu\ge0,\\
-\infty, & m<0\text{, or }m=0\text{ and }\mu<0.
\end{cases}
$$

The proof is radial once the orbit minimum $m$ is certified. Necessity is
witnessed by scaling a minimizing vertex; sufficiency completes the square in
$N$.

This boundary sensitivity has strong precedent. The current Physlib 2HDM
development defines stability as an actual global lower bound and contains a
formal counterexample showing that seemingly reasonable reasoning along quartic
flat directions can fail; see
[Tooby-Smith’s paper](https://arxiv.org/abs/2603.08139) and the
[`TwoHDM/Potential.lean` source](https://github.com/leanprover-community/physlib/blob/master/Physlib/Particles/BeyondTheStandardModel/TwoHDM/Potential.lean).
A separate 2026 3HDM study by the same $\Delta(54)$ authors explicitly changed
to strict $V_4>0$ and notes that the $V_4=0$ case is tricky; see
[arXiv:2603.23590](https://arxiv.org/abs/2603.23590). That makes this distinction
scientifically worth settling, not merely a naming preference.

## 9. Minimum and charge classification

Once $m>0$ and $\mu<0$, a vertex $v_i$ with $h_i=m$ supplies a global minimum
at radial norm $N=-\mu/(2m)$. If one $h_i$ is strictly less than all the others,
its orbit coordinate is the unique minimizing vertex. Ties expose a face and
must not be reported as a unique vacuum without further orbit analysis.

The neutral vertices are $v_1,v_2,v_6,v_8$; the charge-breaking vertices are
$v_3,v_4,v_5,v_7$. A neutral-only search can therefore miss half of the exact
candidate set and certify false conditions. This will be one of the campaign’s
deliberately failing controls.

The formal claim should initially classify orbit-space minima, not gauge-
inequivalent field representatives or phenomenologically acceptable vacua.
Those stronger classifications need additional symmetry, stabilizer, and mass-
matrix work.

## 10. Proof obligations

The smallest trustworthy theorem stack is:

1. definitions of fields, $A$, $K$, $S$, $N,Q,R,P$, $V_2$, and $V_4$;
2. reality/non-negativity and homogeneity lemmas;
3. exact algebraic facts about $\omega$;
4. the six unnormalized facet inequalities;
5. normalization under $N>0$;
6. a checked H-to-V or Farkas certificate for the eight vertices;
7. explicit field witnesses for all vertices;
8. rank-based neutral/charge classification;
9. linear-minimum equality over the physical orbit;
10. quartic non-negative and positive equivalences;
11. the full-potential theorem and global infimum;
12. CP and higher-symmetry slices as corollaries.

Every implication must have a negative control. In particular, the proof must
reject the zero-quartic/$\mu<0$ mutant, a neutral-only vertex list, swapped signs
in the two $\omega$ identities, and any normalization that silently divides by
$N=0$.
