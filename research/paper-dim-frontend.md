# A LaTeX front end for the dimensional solver — controls, and the parse rate

*Companion to `research/physlib-dimensional.md` and `research/physlib-calculus.md`, which
recovered 154 multi-atom dimensional laws from a Lean physics library. Those numbers come
from a solver that knows nothing about Lean: it consumes rows of `dict[atom_id, Fraction]`
meaning "this sum of exponents is zero". Only the front end was Lean-specific. This is a
second front end — **LaTeX display equations** — validated before being pointed at a paper.*

| | result |
|---|---|
| **Positive control, small** | 7 hand-built Newtonian equations, 10 symbols → grading dimension **exactly 3**, rank 7, **0** truth violations, **0** symbols forced dimensionless |
| **Derived-law recovery** | `D(E)=D(F)+D(x)` and `D(P)=D(F)+D(v)` are *implied* though never stated; `D(E)=D(p)` and `D(F)=D(m)` are correctly **not** implied |
| **Positive control, large** | 58 equations exercising `\frac{d}{dt}`, `\int`, `\nabla\cdot`, `\dot{}`, `\Delta`, `e^{}`, `\cos`, `\sqrt` → grading dimension **exactly 3**, **0** truth violations, **21** multi-atom relations, **6** with a coefficient outside ±1 |
| **N1 error injection** | **18/18** dimensionally wrong equations detected (6 small + 12 large) |
| **N1b false-alarm control** | **0/12** dimensionally correct new equations flagged |
| **N2 shuffle, synthetic** | large corpus: grading dim 3 → **0** across all 20 seeds, truth contained **0/20**; small corpus is a weak control and is reported as such (median 2, range 1..4) |
| **N2 shuffle, real papers** | grading dimension falls in **13/13** papers that yielded rows |
| **Parse rate, 15 arXiv sources** | **658 / 1,340 = 49.1%** of display equations parsed; **525 = 39.2%** yielded at least one constraint row; per-paper median **61%**; full failure taxonomy below |
| **Withdrawn / negative** | none of the 15 papers pins a low-dimensional grading — recovered dimensions are 2–38. That is a property of the papers, not a success of the front end (§6) |

Reproduce:

```sh
uv run --no-sync scripts/paper-dim.py --selftest                 # the gate, ~1.5 s
uv run --no-sync scripts/paper-dim.py --tex flat.tex --show 20 --shuffle
uv run --no-sync scripts/paper-dim.py --tex flat.tex --dump-failures 20
```

`scripts/phys_dimlib.py` and `scripts/phys_i3.py` are imported, never modified: `AtomTable`,
`Echelon`, `eliminate_locals` and the sparse row arithmetic are the same code that produced
the physlib results.

---

## 0. The pre-registration, and where it lives

The full pre-registration is the module docstring of `scripts/paper-dim.py` — written before
any corpus was run, stating what a good answer looks like (P1, P2, P3), what both negative
controls must do (N1, N1b, N2), and **what would show it does not work**. It is quoted here
only in summary because the file is the primary record and cannot drift from the code.

The one clause worth repeating, because it is the failure mode this whole design steers
around:

> P1/P3 recovering a grading dimension **above** 3 — symbols are not being identified across
> equations, so the parser is minting a fresh atom per occurrence and the system is nearly
> empty. This is exactly the `_open` defect `phys_dimlib.py` documents; the failure presents
> as "physics has no structure".
>
> P1/P3 recovering a grading dimension **below** 3, or any truth violation — a parse rule
> invented a constraint. That is the unrecoverable direction and it collapses the lattice.

Both are checked by equality, not by a bound.

---

## 1. What the front end does

A display equation is tokenised, parsed to an expression tree, and walked to rows:

| construct | rule | why it is a typing rule and not a physics fact |
|---|---|---|
| `a b`, `a/b`, `\frac{a}{b}` | exponents add / subtract | |
| `x^{q}` for rational `q`, `\sqrt{}`, `\sqrt[n]{}` | exponents scale by `q`, `1/2`, `1/n` | |
| `a + b`, `a - b`, `a \pm b` | `D(a) = D(b)`, at every nesting depth | a sum is only typeable when its terms agree |
| `=`, `\equiv`, `\approx`, `\simeq` | `D(lhs) = D(rhs)` | |
| `<`, `>`, `\le`, `\ge`, `\ll`, `\gg` | `D(lhs) = D(rhs)` | a comparison requires a common scale |
| `\frac{d^k f}{dx^k}`, `\frac{\partial^2 u}{\partial x \partial y}` | `D(f) − Σ kᵢ·D(xᵢ)` | the difference quotient scales as `F/𝕜` (`physlib-calculus.md` §1) |
| `\int_a^b f\,dx`, `\int d^3x\,f` | `D(f) + k·D(x)`, and `D(a) = D(b) = D(x)` | a limit of `Σ f(xᵢ)·μ(Aᵢ)` |
| `\sum`, `\langle x\rangle`, `\|x\|`, `\|x\|`, `\max`, `\lim` | `D(x)` | |
| `\exp`, `\log`, `\ln`, `\sin`, `\cos`, `\tanh`, … | **argument dimensionless**, result dimensionless | the series has to be summable |
| `x!` | `D(x) = 0` | |
| `\dot x`, `\ddot x` | `D(x) − k·D(«dot»)` | see §2 |
| `\nabla f`, `\nabla\cdot`, `\nabla\times`, `\nabla^2` | `D(f) − k·D(«nabla»)` | see §2 |
| `\partial_\mu f`, `\Box` | `D(f) − k·D(«partial»)` | see §2 |
| `\Delta X` | `D(X)` | follows from the sum rule on `X₂ − X₁` |
| everything else | a fresh **local** atom, projected away by `eliminate_locals` | degrades to no information, never to a wrong constraint |

The transcendental rule is the strongest one in the table and the best error detector: three
of the eighteen injected errors in §4 are caught by it alone.

---

## 2. The three coordinates nobody named

`\dot x` means `dx/dt`, `\nabla` differentiates with respect to a spatial coordinate, and
`\partial_\mu` with respect to a spacetime one. Binding any of them **by name** to a symbol
called `t` or `x` would be a physics assumption smuggled into a parser, and would be wrong
in any paper that calls its time coordinate `\eta` or `\lambda`.

Instead each spends a **shared global atom** — `«dot»`, `«nabla»`, `«partial»` — the same one
everywhere in the document. The relation `«dot» = t` is then something the *equations* can
prove, and in the large positive control they do: `\dot x = v` together with `v = dx/dt`
forces `D(«dot») = D(t)`, and the recovered `«dot»` exponent vector is `(0,0,1)`, checked
against the hand truth table. `«nabla»` is likewise pinned to `(0,1,0)` by
`\nabla\cdot\vec g = -4\pi G\rho` alone — the same trick `physlib-calculus.md` §2 reports for
`volume() = ⟨Time()⟩`.

`«nabla»` and `«partial»` are deliberately **not** merged. Merging is the direction that
manufactures a constraint; if a paper works in units where they agree, its equations will say
so.

---

## 3. The positive controls

### P1 — MECH_SMALL

Seven equations (`F = ma`, `a = dv/dt`, `v = dx/dt`, `p = mv`, `E = ½mv²`, `W = Fx`,
`P = dW/dt`) over ten symbols. Measured:

```
columns 10   rank 7   grading dim 3   truth violations 0   forced dimensionless 0
    E = p + v          F = p + v - x      P = p + 2*v - x    W = p + v
    a = 2*v - x        m = p - v          t = - v + x
```

Grading dimension **exactly** 3 is the whole assertion: the hand `(M, L, T)` vectors are three
independent solutions, so the null space contains them; dimension 3 says it contains nothing
else. The recovered space *equals* the truth grading, and no unit name was read.

### P2 — laws that were never stated

`D(E) = D(F) + D(x)` (energy is force times distance) and `D(P) = D(F) + D(v)` (power is force
times velocity) are **implied** by the seven equations though neither appears among them.
`D(E) = D(p)` and `D(F) = D(m)` are **not** implied. All four are asserted; a system that
implied everything would pass the first two and fail the second two, which is the point of
including them.

### P3 — PHYS_BIG

58 equations spanning mechanics, gravitation, rotation, oscillation, fluids and two quantum
relations, chosen to exercise every rule in §1 rather than to be interesting physics:

```
equations 58   parsed 58   global rows 66
columns 38     rank 35     grading dim 3     truth violations 0
multi-atom relations 21    powered 6    forced dimensionless 2
```

The two atoms forced dimensionless are `\beta = v/c` and the phase `\phi` in
`x = A_0 e^{-t/\tau_d}\cos(\omega t + \phi)` — both correct, and both *derived*: nothing told
the solver that a phase or a velocity ratio is a pure number.

**Six relations carry a coefficient outside ±1.** `physlib-dimensional.md` §52 identifies that
as the signature separating dimensional content from algebraic rearrangement, since moving
terms across `=` can only ever produce ±1.

---

## 4. N1 / N1b — the error detector and its own control

**Detection rule.** An added equation is *detected* iff it strictly reduces the grading
dimension of the system. That is the crisp reading of "this equation is not consistent with
the grading the rest of the paper supports".

Eighteen injections, each wrong in a different way, **all eighteen detected**, every one
taking the grading dimension 3 → 2:

| corpus | injection | fault |
|---|---|---|
| small | `E = m v` | dropped a velocity |
| small | `F = m v` | force written as momentum |
| small | `\theta = \sin(t)` | dimensionful trig argument |
| small | `p = m v^2` | wrong power |
| small | `W = F x + p` | sum of unlike terms |
| small | `a = \frac{dx}{dt}` | derivative order off by one |
| large | `E = m v`, `K = \frac12 m v` | dropped a velocity |
| large | `F = GMm/r`, `g = GM/r^3`, `\omega = v/r^2`, `E = \hbar\omega^2`, `P = W/t^2` | wrong power |
| large | `T_p = 2\pi\sqrt{k/m}` | inverted radicand |
| large | `x = A_0\cos(\omega + \phi)` | dimensionful trig argument |
| large | `L = I\omega + p` | sum of unlike terms |
| large | `\rho = m/A` | area where volume belongs |
| large | `W = \int F\,dt` | wrong integration measure |

**N1b is the control the detector needs.** §3 of `CLAUDE.md`: a filter that narrows output
needs its own negative control, because narrowing is where false negatives are manufactured.
A detector that fires on everything new is measuring novelty, not error. Twelve dimensionally
**correct** equations were injected — some derivable (`E = F x`, `P = \tau\omega`,
`v_e = \sqrt{2GM/r}`), some introducing symbols the corpus had never seen
(`\sigma = m/A`, `J = F t`, `\Phi = g A`) — and **none** was flagged. Grading dimension stayed
at 3 in all twelve.

---

## 5. N2 — the shuffle control

Each row's entries are re-pointed at a random **bijection** of the atom pool, per row and
independently. Coefficients and row shapes are preserved exactly; only *which symbol each
entry names* changes. A bijection rather than a random map, because a collision would shrink
a row and make the control easier to pass than it should be.

| corpus | real grading dim | shuffled median (20 seeds) | shuffled range | truth contained |
|---|---|---|---|---|
| MECH_SMALL | 3 | 2 | 1..4 | 0/20 |
| PHYS_BIG | 3 | **0** | 0..0 | 0/20 |

**The small corpus is a weak shuffle control and is reported as one.** With 7 rows over 10
atoms the shuffled system cannot saturate, and one seed in twenty gives a *higher* grading
dimension than the real system. The control that separates is the large one, where 66 rows
over 38 atoms collapse to dimension 0 on every seed, and multi-atom relations go 21 → 0. Both
are printed by `--selftest`; the assertion is on the median and on truth containment, and
containment is 0/20 in both.

On the fifteen real sources the shuffle reduces the grading dimension in **13/13** papers that
yielded any rows, and reduces the multi-atom relation count in 9/13. The four where the
relation count does not fall have 2–15 rows; below about twenty rows the control has nothing
to work with, which is a statement about those papers.

---

## 6. Parse rate, measured on fifteen recent arXiv sources

Fifteen `e-print` sources pulled from `gr-qc`, `astro-ph.SR`, `cond-mat.stat-mech`,
`physics.flu-dyn` and `quant-ph` (the eight most recent per category at time of run;
fifteen selected without looking at their contents). `.tex` files concatenated per paper.

```
paper          eqs  parsed    rate  rows-eq   cols  rank   dim  multi  pow  macros
2608.03398     112      15    13%       12     25    16     9      7    3      22
2608.03438      95      67    71%       31     61    51    10      1    0      19
2608.03484       3       3   100%        3     18     3    15      3    2      30
2608.03619      70      56    80%       53     95    86     9      1    0      46
2608.03657       4       3    75%        3      9     5     4      2    0      16
2608.03726       0       0      —        0      0     0     0      0    0      16
2608.03747     572     200    35%      160    152   129    23     12    1      24
2608.03807       3       2    67%        2      4     2     2      0    0      19
2608.03942      47      21    45%       17     30    27     3      0    0      18
2608.03948       0       0      —        0      0     0     0      0    0      17
2608.03960      78      23    29%       21     23    19     4      1    1      20
2608.03963      27      16    59%       13     36    15    21     11    7      38
2608.03997     256     226    88%      188    272   234    38     35    4      32
2608.04004      33      20    61%       18     55    34    21      9    2      28
2608.04005      40       6    15%        4     15     8     7      2    0      43

TOTAL found 1340   parsed 658 (49.1%)   yielding >=1 row 525 (39.2%)
per-paper median rate 61%;  excluding the 572-equation outlier 2608.03747: 59.6%
```

Two papers (`2608.03726`, `2608.03948`) contain **zero** display equations. They are
observational astronomy; the front end cannot recover a grading from a paper that has no
equations, and this is reported as a property of the paper rather than as a 0% parse rate.

`2608.03747` is a high-energy amplitudes paper whose 572 "equations" are mostly `\\`-separated
fragments of a handful of page-long expressions. It contributes 43% of the found equations and
drags the pooled rate down by ten points; both the pooled and the per-paper-median figures are
given so the reader can see which is which.

### The failure taxonomy — because a silently skipped equation is a false negative

```
   249  unexpected-op     (18.6%)   a fragment that begins with an operator and could not be rejoined
   129  trailing-tokens    (9.6%)   the grammar stopped early; usually a tensor-index or matrix construct
    50  empty              (3.7%)   a segment that was only alignment or spacing
    45  dangling-operator  (3.4%)   an operator with no operand after the split
    43  truncated          (3.2%)   expression ended mid-construct
    40  unbalanced-bar     (3.0%)   `|` used for evaluation, absolute value, Dirac notation and set-builder
    40  unbalanced-brace   (3.0%)
    36  truncated-group    (2.7%)
    17  unbalanced-paren   (1.3%)   `\left(` on one align line, `\right)` on the next
    11  environment        (0.8%)   `pmatrix`, `cases`, `array` — refused rather than guessed
     9  ellipsis           (0.7%)   `\cdots` — refused, since the elided terms carry constraints
     8  unknown-symbol     (0.6%)
     5  unbalanced-angle   (0.4%)
```

Roughly two thirds of the loss is one structural cause: a multi-line `align` block whose
brackets do not close within a `\\`-separated segment. Three repairs already run and are
measured below; the residue needs a bracket-aware re-segmentation, not more grammar.

### Reading rules that fired, over the 658 parsed equations

Every ambiguity resolved is counted, so a real run can be audited rather than trusted:

```
   722  application (`f(x)` read as application, not product)
   453  index-superscript (`A^\mu` read as a name, not a power)
   261  symbolic-power (compound exponent forced dimensionless, base opaque)
   105  euler-exp        94  sum          82  unknown-command    68  subscript-on-compound
    64  partial-operator 49  bracket-list 44  silent-relation    43  bare-transcendental-arg
    40  evaluation-bar   35  integral-no-measure                 30  derivative-fraction
    22  nabla            22  delta-difference                    20  integral-measure-first
     4  integral          4  ket           3  derivative-operator
```

`unknown-command` at 82 is the number to watch: an unrecognised command becomes an atom, which
is safe (it can only fail to constrain) but is not free, because it enters every product it
sits in. The census names them — the residue is `\mathsfi` (26), `\mid` (22), `\slashed` (7),
`\odot`, `\intercal`, `\cal`, `\binom` — and it is now small enough to read. It was **2,296**
before the fixes in §7.

---

## 7. What the parse rate cost, by ablation

Each of these is a measured trade, not a guess.

| change | effect |
|---|---|
| **expand `\newcommand`/`\def`/`\DeclareMathOperator`** | equations *found* 802 → 1,340 and equations *parsed* **478 → 658**. The pooled rate falls 59.6% → 49.1% because the newly-revealed equations are harder — the absolute count is the honest metric, and `CLAUDE.md` §3 says take recall |
| **`physics` package macros** (`\abs`, `\cross`, `\dv`, `\ket`, …) | `\abs` (139 occurrences) and `\cross` (121) stop being spurious atoms. Net zero on parse count |
| **`\abs` handled in the parser, not by text expansion** | expanding it to `\left|…\right|` cost **29 of 257** equations on one source — bars the grammar cannot pair with the paper's own. The largest single regression in this file's history |
| **align-continuation join** (`X &= A \\ &= B`) | recovered 194 `unexpected-op` failures |
| **failure-driven re-join** (retry a failing fragment glued to its predecessor, keep it only if it then parses) | parsed 633 → 658, and cannot lose an equation that already parsed |
| **`\notag` removed from the argument-eating list** | it takes no argument; listing it made it swallow the `&` *and* the following operator on an align continuation |
| **`\text{where}`, `\text{for}`, … end an equation** | one paper had recovered the relation `\phi = -\theta_{amp} - where` |
| **`--paren product`** (read `f(x)` as a product) | multi-atom relations 84 → **97** on the real corpus. The extra 13 are exactly the ones the conservative reading refuses to fabricate; `V(r)` would contribute `D(V) + D(r)` |
| **`--delta opaque`** | columns 795 → 799, relations unchanged |

---

## 8. What this does **not** establish

* **No physics claim is made about any paper.** The fifteen sources were used to measure a
  parse rate and to run the shuffle control on real input. Their recovered relations were
  read only far enough to find parser defects (that is how `\text{where}` was caught).
* **None of the fifteen pins a low-dimensional grading.** Recovered grading dimensions are 2
  to 38, against 3 for the synthetic controls, because most symbols in a real paper appear in
  one equation and are therefore free. A paper is not a closed equation system the way a
  formalised library is; getting a physically meaningful lattice out of one will need either
  many more equations or symbol identification across papers. **The front end is validated;
  the application is not.**
* **A 49% parse rate is a 51% false-negative rate**, and §6's taxonomy is the evidence for
  where it goes rather than an excuse for it. `CLAUDE.md` §3 is explicit that a candidate
  never proposed cannot be recovered downstream.
* **The `f(x)` reading is a choice, not a theorem.** It is the safe direction — losing a
  constraint rather than inventing one — and §7 measures that it costs 13 multi-atom relations
  on the real corpus. A paper that writes `k(T - T_0)` for a product is read wrongly, quietly,
  and the only defence is the `application` counter in the audit census.
* **`\text{}` prose detection is an English word list.** It contains no physics, but it is a
  list, and a paper that uses `\text{in}` as a subscript-free symbol would be truncated.

---

## 9. Files

* `scripts/paper-dim.py` — the front end, the pre-registration, and `--selftest` (44 checks,
  ~1.5 s, exits non-zero on any failure).
* `scripts/phys_dimlib.py` — imported unchanged: `AtomTable`, `Echelon`, `eliminate_locals`.
* `research/physlib-dimensional.md`, `research/physlib-calculus.md` — the prior art whose
  rules §1 restates in LaTeX terms.
