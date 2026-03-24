---
name: workflow-gate
description: "Enforce structured workflow: brainstorm → plan → execute → review. Hard gates prevent skipping phases. From Superpowers pattern."
argument-hint: "<phase> [--task <description>] [--skip-brainstorm] [--force]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

<objective>
Enforce a structured 4-phase workflow for any non-trivial task. Each phase has a HARD GATE — you cannot proceed to the next phase until the current one is explicitly completed and verified.

**Phases:**
1. **Brainstorm** — Explore approaches, identify constraints, consider alternatives
2. **Plan** — Concrete steps, files to touch, tests to write
3. **Execute** — Implement with atomic steps, test after each
4. **Review** — Verify correctness, check drift from plan

**When to use:**
- Any feature touching 3+ files
- Any architectural change
- Any task where "just start coding" has burned you before
- When `/gsd:execute-phase` feels too heavy

**NOT needed for:** Single-file fixes, config changes, typos.

**Model routing (per /route-model):**
- Brainstorm agents → `opus` (creative exploration)
- Plan phase → `sonnet` (structured but bounded)
- Execute → `sonnet` for code gen, `haiku` for searches
- Review agents → `sonnet` first pass, `opus` deep pass
</objective>

<context>
**Arguments:**
- `<phase>` — `brainstorm`, `plan`, `execute`, `review`, or `auto` (starts from brainstorm)
- `--task <description>` — What you're working on. Required for `auto` and `brainstorm`.
- `--skip-brainstorm` — Skip brainstorm for well-understood tasks. Still requires plan.
- `--force` — Override a gate (logged as deviation).
</context>

## Phase 1: Brainstorm

**Gate requirement:** ≥2 distinct approaches identified with tradeoffs.

1. State the task in one sentence
2. Deploy 2 Explore agents in parallel (model: `haiku` for codebase search):
   - Agent 1: Search codebase for related patterns, existing implementations
   - Agent 2: Identify affected files, dependencies, test coverage
3. Synthesize findings (parent context — no extra agent needed)
4. List ≥2 approaches:

```
## Brainstorm: <task>
### Approach A: <name>
- Pros: ...
- Cons: ...
- Files: ~N
- Risk: low/medium/high

### Approach B: <name>
- Pros: ...
- Cons: ...
- Files: ~N
- Risk: low/medium/high

### Selected: <A/B/hybrid>
### Rationale: <one line>
```

5. Ask user which approach (or accept the recommendation)

**Gate check:** ≥2 approaches + selection. No selection → no plan.

## Phase 2: Plan

**Gate requirement:** Step-by-step plan with file list and done criteria.

1. Based on selected approach, create ordered implementation steps
2. For each step: what to do → which file(s) → what test covers it
3. Mark the riskiest step
4. Define done criteria

```
## Plan: <task>
### Steps:
1. <step> → file(s) → test
2. <step> → file(s) → test
...

### Riskiest step: #<N> — <reason>
### Done when:
- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] All tests pass
```

**Gate check:** Steps + file list + done criteria. Missing any → no execute.

## Phase 3: Execute

**Gate requirement:** All plan steps completed, tests pass.

1. Execute steps IN ORDER
2. After each step: run relevant tests
3. If test fails → fix before next step
4. Track deviations from plan:
   - **Minor** (detail change): note and continue
   - **Major** (approach change): STOP → return to Plan phase

```
### Execution Log:
- Step 1: ✓ <what was done>
- Step 2: ✓ <what was done> [deviation: used X instead of Y — minor]
- Step 3: ✗ BLOCKED — <reason> → re-planning step 3-5
```

**3-failure escalation (from Superpowers):** If 3 consecutive attempts at a step fail, STOP execution and:
1. Log the 3 failures with root causes
2. Return to brainstorm with the failure data
3. The failed approach becomes a documented "what doesn't work"

## Phase 4: Review

**Gate requirement:** All done criteria met, tests pass, no unintended side effects.

1. Re-read plan's done criteria
2. Verify EACH criterion against actual code (read the files, don't trust memory)
3. Run full test suite for affected areas
4. Check for side effects:
   - Unrelated test breakage?
   - TODOs or temporary hacks introduced?
   - Convention violations? (check CLAUDE.md domain rules)

```
## Review: <task>
### Done criteria:
- [x] <criterion 1> — verified at <file:line>
- [x] <criterion 2> — verified by test <name>
- [ ] <criterion 3> — NOT MET: <reason>

### Side effects: None / <list>
### Verdict: PASS / FAIL (needs: <what>)
```

**If FAIL:** List exactly what's missing. User decides: fix now or accept as-is.

## State Tracking

Track current gate state in conversation. The format:

```
GATE STATE: <task> | Phase: <N> <name> | Gate: <OPEN/LOCKED>
```

- LOCKED = gate requirements not yet met, cannot proceed
- OPEN = gate passed, can move to next phase

## Rules

1. **Gates are HARD.** No execute without plan. No completion without review. The point is preventing skip-ahead.
2. **Brainstorm can be skipped** with `--skip-brainstorm` but plan NEVER can be.
3. **3-failure escalation is automatic.** Three consecutive failures at a step → forced re-plan.
4. **Deviations are expected** but tracked. Minor: continue. Major: re-plan.
5. **Lighter than GSD.** Use for medium tasks (1-3 hours). GSD for multi-day phases. Nothing for 5-min fixes.
6. **Artifacts stay in conversation** unless user asks to persist. Don't write plan files by default.
7. **Force override is logged.** `--force` bypasses a gate but records it visibly.
8. **Review verifies from code, not memory.** Always re-read files during review. Context may have drifted.
9. **Model routing applies.** Brainstorm exploration uses haiku agents, plan uses sonnet, review uses sonnet + opus.
