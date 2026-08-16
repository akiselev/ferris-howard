# Ferris–Howard -> Lean -> Resolvent integration

**Status:** architecture contract for the scientific-specification bridge.

Ferris–Howard remains a Rust-flavored **frontend for Lean**, not a scientific compiler. The
trusted route into simulation is deliberately:

```text
Ferris–Howard source
       |
       | macro/elaboration
       v
ordinary Lean declarations
       |
       | Lean kernel check
       v
checked theorem/specification
       |
       | explicit reification + soundness theorem
       v
Resolvent deep ScientificSpec
       |
       v
Resolvent Rust compiler -> Anvil/Solverang -> Sinbad
```

There is no supported `FH AST -> Rust simulator` shortcut.

## Why the extra reification step matters

Scientific statements commonly use mathematical objects that are specifications rather than
algorithms: real derivatives, integrals, weak solutions, minimizers, spectra, limits, and
existential solution operators. Extracting arbitrary Lean syntax to Rust would confuse
mathematical denotation with an implementation and would put the translator in the trusted
computing base.

Instead the companion Resolvent Lean package defines a small deep IR (`ScientificSpec`,
refinement relations, and eventually expression/system/form/operator schemas). A domain
formalization constructs that deep object and proves that its denotation matches the native
Lean definition.

Conceptual shape:

```lean
def Heat.nativeSpec : Prop := ...

def Heat.resolventSpec : Resolvent.ScientificSpec := ...

theorem Heat.resolventSpec_sound :
    Resolvent.Denotes.denote Heat.resolventSpec <-> Heat.nativeSpec := by
  ...
```

The Rust exporter consumes `Heat.resolventSpec` only after the soundness theorem, statement
hash, and axiom policy have been checked.

## Ferris–Howard surface sugar

FH may eventually provide ergonomic attributes/commands such as:

```rust
#[resolvent_spec]
fn heat_spec(...) -> ScientificSpec {
    ...
}

#[theorem]
fn heat_spec_sound(...) -> denotes(heat_spec(...)) <-> heat_equation(...) {
    ...
}
```

These are convenience macros only. They must expand to ordinary Lean definitions/theorems;
the Resolvent exporter never trusts the FH source representation.

An FH helper command may expose a workflow like:

```text
fh resolvent check Heat.resolventSpec
fh resolvent export Heat.resolventSpec --out heat.rspec
```

but `check` must perform, at minimum:

1. clean elaboration from source;
2. no `sorry` in the transitive soundness proof;
3. existing axiom-whitelist audit;
4. frozen statement/declaration hash verification;
5. confirmation that the exported object is the checked Resolvent deep-IR type;
6. independent Lean/kernel recheck under the project's normal anti-cheat protocol.

## Bidirectional debugging loop

Simulation/certificate failures should flow back to proof work as structured artifacts rather
than prose.

Examples:

- Resolvent cannot discharge a scope-transport obligation -> emit the exact missing proposition
  for Lean/FH.
- an exact/rational counterexample is found by Resolvent/Solverang -> generate an FH/Lean
  counterexample candidate and check it inside Lean;
- a generated numerical invariant fails in Sinbad -> report the originating Lean declaration,
  Resolvent refinement receipt, and minimal scenario;
- Lean Atlas finds a potentially applicable theorem -> FH agents attempt the instance/proof;
  only the checked theorem may amend the Resolvent refinement chain.

## Trust boundary

A claimed formal-to-simulation chain is trustworthy only if a reviewer can ignore the FH
implementation completely and audit:

```text
Lean declaration + statement hash
Lean soundness theorem
Lean axiom footprint
Resolvent exported deep-IR hash
ordered refinement receipts
Sinbad executable/result provenance
```

FH's source maps, REPL, MCP, tactic search and agent conveniences remain development tooling.
They do not establish mathematical or physical truth by themselves.
