# Ferris–Howard -> Lean -> Resolvent

Ferris–Howard remains a Rust-flavored **Lean frontend**. It does not become a scientific
compiler and it is not in the trusted computing base for a Resolvent model.

## Authority path

```text
FH source
   |
macro expansion / elaboration
   v
ordinary Lean declaration
   |
statement freeze + axiom audit + kernel check
   v
@[resolvent_*] discovery labels
   |
proved reification theorem / checked certificate
   v
Resolvent deep-IR artifact + ReificationReceipt
```

Resolvent must never consume FH surface syntax as semantic input. The implementation in
`FerrisHoward.Bridge.Resolvent` labels and inventories **kernel-visible Lean declarations**.
It exports no FH AST.

## Labels

- `@[resolvent_spec]` — candidate declaration for a `ScientificSpec`;
- `@[resolvent_observable]` — candidate mathematical observable / measurement model;
- `@[resolvent_property]` — candidate property/invariant for a validation contract;
- `@[resolvent_reification]` — candidate theorem/certificate used to justify a reification.

The labels are intentionally weak metadata. Applying `@[resolvent_reification]` does not
make a theorem a valid `KernelProved` receipt by itself. The exporter must still identify
the exact source declaration and target artifact and check that the named theorem proves the
required semantic relation.

`#fh_resolvent_manifest` emits deterministic tab-separated rows from the elaborated Lean
environment, and `#fh_resolvent_require_spec` is a CI/campaign guard against an empty model
selection.

## Existing anti-cheat protocol remains authoritative

A promoted formal bridge must still:

1. freeze the statement before proof/code-generation attempts;
2. elaborate from source in a fresh environment;
3. contain no `sorry` in the promoted theorem chain;
4. pass the axiom whitelist;
5. retain the frozen statement identity;
6. survive independent kernel checking;
7. name the exact Resolvent artifact digest and soundness theorem in its receipt.

REPL state, a successful FH parse, a manifest label, an Atlas suggestion, or agent consensus
is never enough to claim formal soundness.

## Formal scientific specification

The long-term Lean companion package should reify more than an equation: assumptions and
scope, laws/equations, initial/boundary conditions, observables, measurement models, and
properties belong to the specification. This is the Lean counterpart of
`resolvent::ScientificSpec`.
