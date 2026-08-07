# Agent-Directed Frontier Research

**Status:** Research operating model, draft 0.1  
**Scope:** How humans, research agents, Atlas, external scientific tools, and Lean divide responsibility

## The ambition

Ferris–Howard is intended to support **agent-directed frontier research**.

The human does not have to arrive with a conjecture that is already nearly a paper. The human supplies an intent such as:

- “work on grand unification”;
- “look for a new obstruction in quantum resource theories”;
- “find exact structure behind this numerical phenomenon”;
- “investigate whether these two papers are actually compatible.”

From that intent, the agent maps the field, identifies tractable research frontiers, forms precise questions, chooses and revises attacks, and returns certified scientific results or well-localized failures. The actual theorem, counterexample, corrected hypothesis, finite classification, or model boundary may be something the human did not know existed when the campaign began.

This is neither conventional human-directed theorem proving nor an unsupervised machine choosing what humanity should study. It is a mixed-initiative laboratory:

> **The human chooses the scientific direction and governs the campaign. The agent directs the research within that intent. Lean and independent certificate checkers determine what has actually been established.**

## The division of responsibility

### The human supplies the intent envelope

The human is responsible for the parts that are genuinely matters of purpose:

- the broad scientific domain or ambition;
- why the subject matters;
- admissible physical assumptions and philosophical commitments;
- resource, time, disclosure, and safety constraints;
- whether the campaign should favor proofs, classifications, bounds, models, or explanatory structure;
- judgment about whether a technically valid result is scientifically interesting enough to pursue or publish.

The human may propose a concrete target, but is not required to. “Grand unification” is a valid starting point even if the human cannot name the anomaly equation, representation-theory lemma, or threshold-correction question where useful novelty is hiding.

### The agent directs the investigation

Within the intent envelope, the agent is responsible for the scientific steering loop:

- survey the formal corpus, live literature, databases, and known open questions;
- construct a map of theories, claims, assumptions, techniques, and unexplored seams;
- identify targets with a credible path to a new result;
- distinguish foundationally deep problems from tractable boundary cases;
- formulate exact conjectures, disproof tasks, searches, and computational experiments;
- rank them by scientific value, tractability, falsifiability, and expected information gain;
- choose the next experiment from the evidence obtained so far;
- abandon, weaken, strengthen, or redirect a target when counterevidence demands it;
- develop definitions, lemmas, certificates, and scientific engines as the work exposes missing capabilities;
- maintain the provenance and negative-result ledger;
- propose results for independent scientific review and publication.

This is the important shift: the agent is not merely executing a sequence of proof requests chosen in advance by a human. It is performing problem selection and experimental design inside a human-chosen scientific direction.

### Atlas is the research instrument

Atlas gives the agent more than retrieval. It should expose the structure needed to decide where research effort is likely to matter:

- which theories or subtheories share proof and statement shapes;
- which assumptions account for the difference between nearby theorems;
- which dictionary rows are coherent and which break;
- which known results have conspicuous missing analogues;
- which conjectures transport cleanly enough to become research candidates;
- which frontiers have high structural support but little existing traffic;
- which failed candidates reveal a stable obstruction rather than random search noise;
- which new formal result would unlock several downstream questions.

Atlas proposes and organizes research possibilities. It does not confer truth or physical meaning by itself.

### Lean supplies the trust floor

Lean checks formal deductions and small certificate kernels. External search, numerical solvers, computer algebra, SAT/SMT, SDP/SOS, simulations, language models, and literature analysis may all generate candidates. Their output becomes a result only when promoted through the evidence route appropriate to the claim:

- a kernel-checked proof;
- an exact witness;
- a checked exhaustive-search certificate;
- a rational positivity certificate;
- a validated interval enclosure;
- or a conditional inference with explicit physical and statistical assumptions.

For physics, a theorem about a model is not automatically a theorem about nature. The model, conventions, validity regime, observables, and empirical assumptions remain first-class parts of the result.

## The agent-directed discovery loop

### 1. Interpret the intent

Turn the human's broad direction into a versioned research brief. Record inclusions, exclusions, assumptions, desired forms of result, available resources, and what would count as scientifically meaningful progress.

### 2. Map the opportunity landscape

Ingest current literature and formal corpora. Use Atlas to assemble a live graph of theories, results, assumptions, unresolved claims, computational methods, and formalization gaps. Separate established facts, reported numerical evidence, conjectures, disagreements, and inference.

### 3. Generate a portfolio, not one heroic bet

Construct targets at several scales:

- calibration problems that exercise the machinery;
- low-cost falsification probes;
- bounded frontier questions with exact outputs;
- medium-risk theorem or classification programs;
- ambitious long-horizon conjectures.

Each target receives a research dossier: novelty status, exact statement, provenance, required infrastructure, plausible attacks, cheap counterexample tests, certification route, scientific payoff, and stopping conditions.

### 4. Choose experiments by information gain

The first experiment is not necessarily the easiest proof. Prefer experiments whose outcomes all teach us something: a proof, a counterexample, a sharper hypothesis, a no-go boundary, a formalization correction, or a diagnosed missing engine.

Freeze the question before expensive search. Record predicted outcomes and decision rules. This keeps the agent from silently redefining success after seeing the result.

### 5. Attack, observe, and redirect

Run the strongest appropriate exploratory machinery. Feed counterexamples, proof traces, solver residuals, failed reconstructions, and literature conflicts back into Atlas. Let the evidence determine the next target and the next engine improvement.

The agent may change tactics autonomously inside the intent envelope. It must surface a decision when the work would materially change the campaign's scientific purpose, assumptions, resource commitment, or publication posture.

### 6. Certify and challenge

Separate discovery from checking. Rebuild the result in a clean environment, challenge definitions and convention choices, test limiting cases, seek independent computations, and obtain domain review. A formally correct proof of the wrong formalization is an instrument failure, not a discovery.

### 7. Publish and update the map

Publish positive and negative results with their proof or certificate, definitions, assumptions, provenance, costs, failed neighbors, and agent involvement. Return the new structure to the corpus so that it changes subsequent problem selection.

## Example: a grand-unification campaign

The human says, “I want to work on grand unification.” The agent should not respond by demanding a preselected theorem, nor should it jump directly to inventing a complete theory.

It might instead:

1. map candidate gauge groups, representations, breaking chains, anomaly constraints, operator bases, coupling-unification conditions, proton-decay constraints, and the exact status of relevant classification results;
2. identify a bounded seam—for example, an incompletely classified representation family under explicit anomaly and phenomenological constraints;
3. formulate exact enumeration and no-go questions;
4. eliminate impossible regions with certified finite search and algebraic certificates;
5. notice a recurring obstruction or a previously missed viable family;
6. state and prove the resulting classification or no-go theorem in Lean;
7. distinguish that mathematical result from any further claim that the model describes nature.

The human chose grand unification. The agent found the research question.

## Campaign governance

Agent direction does not mean unaccountable autonomy. Every campaign needs:

- a frozen human intent and scope;
- a reproducible literature and corpus snapshot;
- explicit target-selection scores and rationales;
- budgets and stop conditions;
- a permanent counterexample and failure ledger;
- separation between candidate generation and certification;
- escalation points for changing physical assumptions or campaign purpose;
- independent review of novelty, definitions, and scientific interpretation;
- disclosure of agent involvement.

The human can redirect or stop the campaign at any time. The agent should also recommend stopping when a direction is exhausted, ill-posed, already known, or dominated by missing prerequisites.

## What success looks like

An agent-directed campaign succeeds when it creates durable scientific information, not when it merely produces a long autonomous trace. Valid outcomes include:

- a new theorem or proof;
- a counterexample to a live claim;
- a corrected theorem with minimal hypotheses;
- a certified finite classification or no-go;
- a new quantitative bound;
- a resolved disagreement in the literature;
- a structural map that exposes a defensible new question;
- an explicit diagnosis of the formal or computational capability required next.

The long-term standard is demanding: a person should be able to name a scientific ambition, let an agent direct a transparent and governed research campaign, and receive results whose correctness and scope do not depend on trusting the agent.

