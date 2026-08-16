# Ferris–Howard -> Lean -> Resolvent

**Status:** normative integration design for the scientific refinement stack.

Ferris–Howard remains a Rust-flavored **Lean frontend**. It does not become a scientific
compiler and it is not in the trusted computing base for a Resolvent model.

## Trust boundary

The only authoritative path is:

```text
FH source
   |
macro/elaboration
   v
ordinary Lean declaration
   |
Lean kernel check + axiom audit + frozen statement hash
   v
kernel-visible declaration
   |
proved reification theorem
   v
Resolvent deep-IR artifact + ReificationReceipt
```

Resolvent must never consume FH surface syntax as semantic input. A bug in an FH macro may
cause elaboration to fail or may elaborate a different Lean declaration, but it cannot make a
`KernelProved` Resolvent receipt valid unless the resulting Lean theorem actually proves the
reification claim for the frozen declaration.

## Proposed surface attributes

Ferris–Howard may eventually provide ergonomic attributes such as:

```rust
#[resolvent_spec]
fn nonlinear_heat(...) -> Prop { ... }

#[resolvent_observable("thermocouple_voltage")]
fn sensor_model(...) -> Real { ... }
```

These attributes are **syntax sugar only**. They should expand to ordinary Lean attributes
or companion declarations registered by the Resolvent Lean package. No FH-specific AST is
sent to Rust.

The generated Lean-side contract should make the deep reification explicit, conceptually:

```lean
def nonlinearHeatSpec : Resolvent.ScientificSpec := ...

theorem nonlinearHeatSpec_sound :
    Resolvent.ScientificSpec.denote nonlinearHeatSpec <-> nonlinearHeat := by
  ...
```

The exporter then records the elaborated theorem/declaration name, statement digest, axiom
footprint, toolchain/commit, artifact digest and soundness theorem in a Resolvent
`ReificationReceipt`.

## Agent workflow

The existing anti-cheat protocol in `agent-interface.md` remains the gate:

1. freeze the formal statement before proof/code-generation attempts;
2. elaborate from source in a fresh environment;
3. require zero `sorry` in the promoted theorem/reification chain;
4. audit axioms against the campaign whitelist;
5. verify the statement hash did not change;
6. independently kernel-check the resulting Lean artifact;
7. only then permit the Resolvent receipt to claim `KernelProved`.

REPL state is still exploratory and never authoritative.

## Formal specification is larger than an equation

A model exported to Resolvent should eventually identify, in Lean:

- governing equations/laws;
- assumptions and their exact scope;
- initial/boundary conditions when applicable;
- parameter and state domains;
- observables;
- measurement models when empirical comparison is intended;
- invariants/properties that can become generated validators.

This is the Lean counterpart of `resolvent::ScientificSpec`. A PDE statement alone is not a
complete scientific specification.

## Proof-producing migration

Not every scientific lowering will be fully formalized on day one. The integration must
still distinguish:

- a kernel-proved reification;
- a checked certificate;
- an asserted/unchecked export used for exploration.

Ferris–Howard must not display all three as "proved". The evidence grade comes from the Lean
artifact/receipt, not from the fact that FH successfully parsed the source.

## Relationship to Lean Atlas

Ferris–Howard authors and checks statements; Lean Atlas reads the elaborated corpus. Atlas
may suggest relevant theorems, transformations or representations, but a suggested relation
becomes formal only after Lean checks it. Resolvent then consumes the checked result.

No Atlas ranking and no agent consensus changes the FH proof gate.

## First vertical target

The first end-to-end integration should formalize a small nonlinear heat specification and
one or more properties (for example a conservation/energy statement), reify it to Resolvent,
run the Resolvent -> Sinbad numerical path, and attach the generated validator results back
to the formal declaration through content-addressed receipts.
