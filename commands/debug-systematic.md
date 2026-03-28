---
name: debug-systematic
description: "4-phase systematic debugging with 3-failure escalation. Scientific method: observe → hypothesize → test → conclude. From Superpowers pattern."
argument-hint: "<bug-description> [--error <message>] [--file <path>] [--escalate]"
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
Systematic debugging using the scientific method instead of random code changes. Four phases with hard gates between them, plus a 3-failure escalation that prevents infinite loops of guessing.

**Phases:**
1. **Observe** — Gather ALL symptoms before forming theories
2. **Hypothesize** — Form ranked hypotheses based on evidence
3. **Test** — Validate/invalidate hypotheses one at a time
4. **Conclude** — Fix the root cause, verify the fix, document

**3-failure rule:** If 3 consecutive fix attempts fail, STOP and escalate:
- Re-examine assumptions
- Widen the search scope
- Consider if the bug description itself is wrong

**Model routing:**
- Observation/search agents → `haiku` (pure retrieval)
- Hypothesis formation → `sonnet` (analysis)
- Root cause analysis → `opus` (deep reasoning)
</objective>

<context>
**Arguments:**
- `<bug-description>` — What's happening (e.g., "API returns 500 on login", "cart total is wrong for discounts")
- `--error <message>` — Specific error message or stack trace
- `--file <path>` — File where the bug is suspected
- `--escalate` — Start in escalation mode (skip to widened search)
</context>

## Phase 1: OBSERVE — Gather All Symptoms

**Context loading:** If /preload ran this session, use the existing domain rules brief. If not, read only the domain rules section of CLAUDE.md — not the full file.

**DO NOT form theories yet.** Only collect facts.

1. **Reproduce the bug** — Can you trigger it? Is it consistent or intermittent?

2. **Collect error data:**
   - Exact error message / stack trace
   - Which endpoint/function/line fails
   - What input triggers it
   - What input DOESN'T trigger it (working cases)

3. **Check the environment:**
   - Recent changes (git log, git diff)
   - Dependency updates
   - Config changes
   - Environment differences (dev vs prod)

4. **Search for related code** (spawn haiku agents in parallel):
   - Agent 1: Find all call sites of the failing function
   - Agent 2: Find recent changes to the failing file(s) — `git log -p <file>`
   - Agent 3: Find similar patterns elsewhere that DON'T fail (for comparison)

**Model routing for debug phases:**
- Observe phase (log reading, file scanning, reproducing): haiku
- Hypothesize phase (pattern analysis, candidate generation): sonnet
- Test phase (writing targeted test, running experiments): sonnet
- Conclude phase (root cause analysis, fix design): sonnet; opus only if bug involves distributed state, security, or requires deep causal reasoning

**Observation report:**
```
## Bug: <description>
### Symptoms:
- <symptom 1>
- <symptom 2>

### Reproduces: always / sometimes / only with <input>
### Error: <exact message>
### Recent changes: <git log summary>
### Related code: <files found>
### Working comparison: <similar code that works>
```

**Gate:** Must have symptoms + reproduction status before hypothesizing.

## Phase 2: HYPOTHESIZE — Form Ranked Theories

Based ONLY on observations (not guesses), form hypotheses:

```
### Hypotheses (ranked by evidence strength):

H1: <hypothesis> [confidence: HIGH]
    Evidence: <what observation supports this>
    Prediction: If true, then <testable prediction>

H2: <hypothesis> [confidence: MEDIUM]
    Evidence: <what observation supports this>
    Prediction: If true, then <testable prediction>

H3: <hypothesis> [confidence: LOW]
    Evidence: <weak or circumstantial>
    Prediction: If true, then <testable prediction>
```

**Rules for hypotheses:**
- Every hypothesis must cite specific observations
- Every hypothesis must have a testable prediction
- Rank by evidence strength, not gut feeling
- Include at least one "unlikely but possible" hypothesis

**Gate:** Must have ≥2 hypotheses with testable predictions.

## Phase 3: TEST — Validate One at a Time

Test hypotheses IN ORDER of confidence:

**Targeted test runs only.** When testing a hypothesis, run only the test(s) that exercise the suspected code path. Full suite runs happen only at final confirmation. Each unnecessary full-suite run during debugging burns tokens and latency.

### For each hypothesis:

1. **Design a test** — what would confirm or refute this hypothesis?
2. **Run the test** — add a debug point, write a test case, check a log
3. **Record the result:**

```
### Testing H1: <hypothesis>
Test: <what we checked>
Result: CONFIRMED / REFUTED / INCONCLUSIVE
Evidence: <what we found>
```

4. **If CONFIRMED** → proceed to Phase 4 (fix)
5. **If REFUTED** → test next hypothesis
6. **If ALL REFUTED** → 3-failure escalation

### 3-Failure Escalation

If 3 hypotheses are refuted (or 3 fix attempts fail):

```
⚠ ESCALATION TRIGGERED — 3 failures
Re-examining assumptions:
1. Is the bug description accurate? <re-check>
2. Is the bug in OUR code or a dependency? <check>
3. Are we looking in the right place? <widen search>
4. Is this actually multiple bugs? <decompose>
```

**Escalation actions:**
- Widen the search scope (look in files not previously considered)
- Check if a dependency updated recently
- Check if the bug is a symptom of a deeper issue
- Deploy an opus agent for fresh-eyes analysis of ALL collected evidence
- Ask the user if the bug description needs updating

## Phase 4: CONCLUDE — Fix and Verify

1. **Identify root cause** (not just the symptom):
```
### Root Cause:
<What actually went wrong, traced to specific code>

### Why it happened:
<The underlying reason — not "this line is wrong" but "this assumption was invalid because...">
```

2. **Implement the fix** — smallest change that addresses root cause

3. **Verify the fix:**
   - Original bug no longer reproduces
   - Related tests pass
   - No regression in other tests
   - Edge cases covered

4. **Verify it's not a band-aid:**
   - Does the fix address the ROOT cause or just suppress the symptom?
   - Could the same bug occur elsewhere with similar patterns?
   - Should we add a test specifically for this bug?

```
### Fix Applied:
- File: <path>
- Change: <what changed>
- Root cause addressed: YES / PARTIAL
- Regression test added: YES / NO
- Similar patterns to check: <list or "none">
```

## Session State

Track debugging state across the conversation:

```
DEBUG STATE: <bug> | Phase: <N> | Hypotheses: <tested/total> | Failures: <N>/3
```

## Rules

1. **Observe before hypothesizing.** Don't jump to "I think the problem is..." before collecting symptoms.
2. **Hypothesize before fixing.** Don't change code based on a hunch. Form a testable prediction first.
3. **Test one hypothesis at a time.** Don't change 3 things and see if the bug goes away — you won't know which change mattered.
4. **3-failure escalation is mandatory.** After 3 failed attempts, you MUST stop and re-examine. No "let me try one more thing."
5. **Root cause, not band-aid.** A fix that suppresses the symptom without understanding why is not a fix.
6. **Document the journey.** The observation→hypothesis→test chain is valuable for future debugging.
7. **Model routing:** Observation search = haiku. Hypothesis analysis = sonnet. Escalation fresh-eyes = opus.
8. **This complements /gsd:debug.** Use `/debug-systematic` for focused single-bug investigation. Use `/gsd:debug` for broader debugging with state persistence across sessions.
9. **Haiku for observation.** Log reading, stack trace parsing, file content scanning — all observation-phase work uses haiku. Understanding and synthesizing those observations uses sonnet. Only root cause analysis for complex systems uses opus.
