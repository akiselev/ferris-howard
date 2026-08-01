// .claude/workflows/couette-research.js
// Run as: /couette-research            → probes repo state, runs the NEXT incomplete stage, stops.
//         /couette-research g5         → runs a specific stage (args = "g1".."g7").
// DESIGN: one stage per run, on purpose. Workflows take no mid-run user input, and
// our G-gates are human sign-offs — so every run ends AT a gate. Review the gate
// artifact, then invoke again. The script has no filesystem access itself; all IO
// happens inside agents, so repo state is read by a probe agent.

export const meta = {
  name: 'couette-research',
  description:
    'couette-re-e end-to-end: statements → vet battery → search → certificates → kernel verification → red team → clean-Lean artifact → paper. One gate-stage per run; CLAUDE.md is the contract.',
}

// ---------- shared bits ----------------------------------------------------

const S = (props, required = Object.keys(props)) => ({
  type: 'object', required, properties: props,
})
const STR = { type: 'string' }
const BOOL = { type: 'boolean' }
const ARR = items => ({ type: 'array', items })

const CONTRACT =
  'You are an agent on project couette-re-e. Read CLAUDE.md first and obey its hard rules H1–H7 ' +
  '(fresh-build evidence only; frozen statements are never edited; axiom whitelist; ledger everything). '

// Every stage ends by writing its gate file through an agent, never by assumption.
const writeGate = (gate, verdict, evidence) =>
  agent(
    CONTRACT +
    `Write ledger/gates/${gate}.md containing: date, verdict "${verdict}", and this evidence ` +
    `verbatim:\n${evidence}\nAppend one summary line to ledger/findings.md. Commit with message "gate: ${gate} ${verdict}".`,
    { label: `gate:${gate}`, phase: 'gate' },
  )

// ---------- stage: probe (always first when no args) ------------------------

const probe = () =>
  agent(
    CONTRACT +
    'Report repo state: list which of ledger/gates/{G1,G2,G3,G4,G5,G6,G7}.md exist with verdict PASS, ' +
    'and run `lake build 2>&1 | tail -3` reporting whether it is green.',
    {
      label: 'state-probe', phase: 'probe',
      schema: S({ passed: ARR(STR), buildGreen: BOOL }),
    },
  )

// ---------- G1: statements + statement-tier vet battery ---------------------

async function stageG1() {
  // 1. Elaborate statements (bootstrap Lean mirror of statements/couette.fh).
  await agent(
    CONTRACT +
    'Phase 1: mirror statements/couette.fh into lean/Statements/ per the rosetta doc. Definitions must ' +
    'elaborate with zero sorries; theorem bodies stay sorry. Do not change any statement meaning.',
    { label: 'elaborate-statements', phase: 'G1: statements' },
  )

  // 2. Vet battery, statement tier — controls, junk lint, mutation fan-out.
  const controls = agent(
    CONTRACT +
    'Prove every #[control(positive)], #[control(negative)], #[control(discrimination)] theorem in ' +
    'lean/Statements/. Report each as proven/failed with the goal text.',
    { label: 'controls', phase: 'G1: vet', schema: S({ allProven: BOOL, failures: ARR(STR) }) },
  )
  const junk = agent(
    CONTRACT +
    'V10 junk-value lint: list every use of division, Nat subtraction, sqrt, sSup in lean/Statements/ ' +
    'and verify each is guarded by a hypothesis or carries a ledgered junk-ok note. Report violations.',
    { label: 'junk-lint', phase: 'G1: vet', schema: S({ clean: BOOL, violations: ARR(STR) }) },
  )
  // Mutation battery: generate mutants, then one agent per mutant (isolated worktrees).
  const gen = await agent(
    CONTRACT +
    'V8: generate 12 statement mutants of lean/Statements/ (quantifier flips, dropped hypotheses, ' +
    'inequality reversals, class swaps Full↔XIndep). Return each as {id, description, patch}.',
    { label: 'mutant-gen', phase: 'G1: mutation',
      schema: S({ mutants: ARR(S({ id: STR, description: STR, patch: STR })) }) },
  )
  const mutantResults = await pipeline(gen.mutants, m =>
    agent(
      CONTRACT +
      `Apply this mutant patch in your isolated copy, then determine its fate: does any control proof ` +
      `now FAIL (killed), or can you PROVE the mutant statement's negation (refuted)? Otherwise it ` +
      `SURVIVES.\nMutant ${m.id}: ${m.description}\n${m.patch}`,
      { label: `mutant:${m.id}`, phase: 'G1: mutation', isolation: 'worktree',
        schema: S({ id: STR, fate: { type: 'string', enum: ['killed', 'refuted', 'survived'] }, note: STR }) },
    ),
  )

  // 3. V7 blind double-formalization + V6 informalization, independent contexts.
  const [blind, informal, ctrl, jl] = await parallel([
    agent(
      'You are a blind formalizer. Read ONLY papers/ and docs/nondimensionalization.md — you must not ' +
      'open statements/, lean/, or ledger/. Formalize the papers\' monotone-energy-stability claims as ' +
      'Lean 4 statements from scratch, naming the admissible perturbation class in every predicate. ' +
      'Write vet/blind/Statements.lean with a reading note per declaration.',
      { label: 'blind-formalizer', phase: 'G1: independence' },
    ),
    agent(
      'You are an informalizer. Read ONLY lean/Statements/ — not the papers. Render every statement in ' +
      'precise mathematical English to vet/informal/rendering.md, flagging ambiguities.',
      { label: 'informalizer', phase: 'G1: independence' },
    ),
    controls, junk,
  ])

  // 4. Judge: diff blind vs ours, informal vs papers; adjudicate divergences.
  const judge = await agent(
    CONTRACT +
    'Judge the G1 evidence. Diff vet/blind/Statements.lean against lean/Statements/ semantically; diff ' +
    'vet/informal/rendering.md against the papers\' claims. Every divergence: classify (our-error | ' +
    'source-ambiguity | blind-error) and write it to ledger/questions.md — semantic divergences BLOCK ' +
    'the gate for human review. Then decide: is G1 passable?',
    { label: 'g1-judge', phase: 'G1: judge',
      schema: S({ pass: BOOL, blockers: ARR(STR), summary: STR }) },
  )

  const survivors = mutantResults.filter(r => r.fate === 'survived')
  const pass = judge.pass && ctrl.allProven && jl.clean && survivors.length === 0
  if (pass)
    await agent(CONTRACT + 'Run scripts/freeze.sh; record hashes in ledger/freeze.txt; commit.',
      { label: 'freeze', phase: 'G1: freeze' })
  await writeGate('G1', pass ? 'PASS' : 'BLOCKED',
    `controls=${ctrl.allProven} junk=${jl.clean} mutants: ${mutantResults.map(r => r.id + ':' + r.fate).join(', ')} | ${judge.summary} | blockers: ${judge.blockers.join('; ') || 'none'}`)
  return { stage: 'G1', pass, blockers: judge.blockers, survivors }
}

// ---------- G2+G3: dirty search, then certificates --------------------------

async function stageG2G3() {
  const sweep = await agent(
    CONTRACT +
    'Phase 2: run `cargo run -p search -- sweep`, then the resolution-doubling convergence study, then ' +
    '`bash scripts/gate.sh 2` (calibration is script-only; never read ANSWER_KEY.md yourself). Emit ' +
    'certs/candidates.json. If sweep vs calibration disagree by >5%, STOP and report — do not tune.',
    { label: 'eigensweep', phase: 'G2: search',
      schema: S({ converged: BOOL, calibrated: BOOL, lower: STR, upper: STR, note: STR }) },
  )
  if (!sweep.converged || !sweep.calibrated) {
    await writeGate('G2', 'BLOCKED', `search: ${JSON.stringify(sweep)}`)
    return { stage: 'G2', pass: false, note: sweep.note }
  }
  await writeGate('G2', 'PASS', JSON.stringify(sweep))

  const [upper, lower] = await parallel([
    agent(CONTRACT + 'Phase 3a: `cargo run -p certify -- upper`; port the exact closed-form integral ' +
      'evaluations of the trial field to Lean at norm_num grade. Report P, D as exact rationals.',
      { label: 'cert-upper', phase: 'G3: certificates', schema: S({ ok: BOOL, note: STR }) }),
    agent(CONTRACT + 'Phase 3b: `cargo run -p certify -- lower` (exact LDLᵀ at LOWER). Then the tail ' +
      'lemma: search Mathlib first (Loogle, LeanSearch, exact?); produce a compiling skeleton with ≤3 ' +
      'sorries, each ledgered with a plan.',
      { label: 'cert-lower', phase: 'G3: certificates', schema: S({ ok: BOOL, sorries: { type: 'number' }, note: STR }) }),
  ])
  const diff = await agent(
    CONTRACT + 'V11: #eval the Lean energy form on 10 random small fields and compare byte-for-byte with ' +
    '`cargo run -p search -- eval-check`. Any mismatch is a blocking spec bug.',
    { label: 'differential-check', phase: 'G3: vet', schema: S({ match: BOOL, note: STR }) },
  )
  const pass = upper.ok && lower.ok && lower.sorries <= 3 && diff.match
  await writeGate('G3', pass ? 'PASS' : 'BLOCKED',
    `upper:${upper.note} | lower(${lower.sorries} sorries):${lower.note} | differential:${diff.note}`)
  return { stage: 'G3', pass }
}

// ---------- G4: kernel verification (fix-until-green loop) -------------------

async function stageG4() {
  let last = Infinity
  for (let round = 1; round <= 8; round++) {
    const check = await agent(
      CONTRACT + 'Fresh `lake build`; count sorries in the transitive closure of the three target theorems; ' +
      'list each remaining sorry with its goal.',
      { label: `audit-r${round}`, phase: 'G4: verify',
        schema: S({ sorries: { type: 'number' }, goals: ARR(STR) }) },
    )
    if (check.sorries === 0) break
    if (check.sorries >= last) {                       // no progress: stop, don't thrash
      await writeGate('G4', 'BLOCKED', `stalled at ${check.sorries} sorries: ${check.goals.join(' | ')}`)
      return { stage: 'G4', pass: false, stalled: check.goals }
    }
    last = check.sorries
    await pipeline(check.goals, g =>
      agent(CONTRACT + `Close this goal. Try exact?/apply?/rw? first; obey H2 (never edit frozen ` +
        `statements) and H3 (no native_decide). If stuck 4h-equivalent, ledger and stop.\nGOAL:\n${g}`,
        { label: 'prover', phase: `G4: round ${round}` }),
    )
  }
  const exit = await agent(
    CONTRACT + 'G4 exit protocol in a fresh environment: zero sorries; #print axioms ⊆ whitelist; ' +
    'statement hashes match ledger/freeze.txt; lean4checker passes. Report each check.',
    { label: 'exit-protocol', phase: 'G4: exit', schema: S({ allGreen: BOOL, detail: STR }) },
  )
  await writeGate('G4', exit.allGreen ? 'PASS' : 'BLOCKED', exit.detail)
  return { stage: 'G4', pass: exit.allGreen }
}

// ---------- G5: full validity battery + fidelity game ------------------------

async function stageG5() {
  const ddmin = agent(
    CONTRACT + 'V2/13.2: run scripts/ddmin-statement.sh — compute the minimal load-bearing statement for ' +
    'each target theorem. A nonempty diff vs the frozen statement is reported, not repaired.',
    { label: 'ddmin', phase: 'G5: shrink', schema: S({ diffs: ARR(STR) }) },
  )
  // Red team: three independent divergence provers, then artifact verification.
  const exploits = pipeline([1, 2, 3], i =>
    agent(
      'You are Divergence Prover ' + i + ' in the fidelity game. Read ONLY papers/ and the frozen ' +
      'lean/Statements/. Hunt exploits: a concrete instance where formal and informal verdicts differ; a ' +
      'junk-value scenario a statement silently accepts; a class-naming confusion a referee would trip on. ' +
      'Every exploit must include the exact command demonstrating it. Also list your top citation-threat: ' +
      'the likeliest downstream misquote of this result.',
      { label: `red-${i}`, phase: 'G5: fidelity game',
        schema: S({ exploits: ARR(S({ claim: STR, command: STR })), citationThreat: STR }) },
    ),
  )
  const [dd, reds] = await parallel([ddmin, exploits])
  const flat = reds.flatMap(r => r.exploits)
  const verified = await pipeline(flat, e =>
    agent(CONTRACT + `Check this claimed exploit by running its command exactly. Valid or invalid?\n` +
      `CLAIM: ${e.claim}\nCOMMAND: ${e.command}`,
      { label: 'exploit-check', phase: 'G5: judge', schema: S({ valid: BOOL, note: STR }) }),
  )
  const validCount = verified.filter(v => v.valid).length
  await agent(
    CONTRACT + 'Assemble dossier/: vet reports, mutation scores, ddmin diffs, fidelity transcript, ' +
    'assumption ledger (include adequacy_gap), and draft the non-claims section from these citation ' +
    `threats: ${reds.map(r => r.citationThreat).join(' | ')}`,
    { label: 'dossier', phase: 'G5: dossier' },
  )
  const pass = validCount === 0 && dd.diffs.length === 0
  await writeGate('G5', pass ? 'PASS' : 'BLOCKED',
    `valid exploits: ${validCount}; ddmin diffs: ${dd.diffs.length}`)
  return { stage: 'G5', pass, validExploits: validCount }
}

// ---------- G6+G7: adjudication, clean-Lean artifact, paper -------------------

async function stageG6G7() {
  await agent(
    CONTRACT + 'G6: sharpen readings_compatible; produce the Joseph-object vs FMP-object hypothesis-diff ' +
    'table from the formalized readings, verdict-free. Then emit the publication artifact: strip FH ' +
    'comments, apply style lints → artifact/Couette.lean importing Mathlib only; re-elaborate it fresh, ' +
    'check defeq against the development, run lean4checker on the artifact alone. Register atlas metadata.',
    { label: 'artifact', phase: 'G6: artifact' },
  )
  const gate6 = await agent(
    CONTRACT + 'Verify the artifact round-trip evidence and write it up.',
    { label: 'g6-check', phase: 'G6: artifact', schema: S({ pass: BOOL, detail: STR }) },
  )
  await writeGate('G6', gate6.pass ? 'PASS' : 'BLOCKED', gate6.detail)
  if (!gate6.pass) return { stage: 'G6', pass: false }

  await agent(
    'You are the paper writer. From dossier/, artifact/Couette.lean, and ledger highlights, write ' +
    'writeup/paper.md per the fixed structure: 1 result (bracket + sharpness), 2 the dispute as a ' +
    'hypothesis diff (verdict-free language ONLY), 3 methods, 4 validity dossier summary (lead with it), ' +
    '5 non-claims, 6 artifact link + assumption ledger verbatim. Every number cites its certificate path. ' +
    'AI involvement disclosed prominently.',
    { label: 'paper-writer', phase: 'G7: paper' },
  )
  await writeGate('G7', 'DRAFTED', 'paper.md written; awaiting human review checklist → ledger/gates/DONE.md')
  return { stage: 'G7', pass: true }
}

// ---------- dispatch ---------------------------------------------------------

const stages = { g1: stageG1, g2: stageG2G3, g3: stageG2G3, g4: stageG4, g5: stageG5, g6: stageG6G7, g7: stageG6G7 }

if (typeof args === 'string' && stages[args.toLowerCase()]) {
  return await stages[args.toLowerCase()]()
}
const state = await probe()
const order = ['G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7']
const next = order.find(g => !state.passed.includes(g)) ?? 'G7'
if (!state.buildGreen && next !== 'G1')
  return { halted: 'build is red — fix the build before running stage ' + next }
return await stages[next.toLowerCase()]()
