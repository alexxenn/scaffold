---
name: sparc
description: "SPARC methodology: Spec → Pseudocode → Architecture → Refinement → Completion. Structured approach for complex features. From ruflo."
argument-hint: "<feature-description> [--phase <name>] [--resume] [--skip <phase>]"
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
SPARC is a 5-phase methodology for implementing complex features correctly. Unlike jumping straight to code, SPARC ensures the design is right before a line of implementation is written.

**Phases:**
1. **S**pecification — Define WHAT exactly needs to be built
2. **P**seudocode — Write HOW it works in plain language
3. **A**rchitecture — Design WHERE it lives and HOW it integrates
4. **R**efinement — Identify and resolve risks before coding
5. **C**ompletion — Implement, test, verify

**When to use:**
- New features with non-obvious implementation paths
- Features touching 5+ files or multiple system layers
- Anything you've tried to implement before and struggled with
- When `/workflow-gate` feels too light but `/gsd:plan-phase` feels too heavy

**vs. `/workflow-gate`:**
SPARC is more structured — it produces written artifacts (spec, pseudocode, architecture doc). Workflow-gate is conversational. Use SPARC for features you'll return to across sessions.

**Model routing (per /route-model):**
- Spec phase → `sonnet` (structured analysis)
- Pseudocode → `sonnet` (logic, not creativity)
- Architecture → `opus` (system-level reasoning)
- Refinement → `opus` (risk analysis)
- Completion → `sonnet` for code, `haiku` for search, `opus` for complex logic

Model routing per phase:
- Spec (S): sonnet — structured requirement extraction, bounded scope
- Pseudocode (P): sonnet — algorithmic thinking, no architecture decisions
- Architecture (A): opus — design patterns, cross-cutting concerns, trade-offs
- Refinement (R): sonnet — implementation-level review, code patterns
- Completion (C): sonnet for code generation; haiku for file reads and searches
</objective>

<context>
**Arguments:**
- `<feature-description>` — What to build
- `--phase <name>` — Jump to a specific phase: `spec`, `pseudocode`, `arch`, `refinement`, `completion`
- `--resume` — Resume from where SPARC left off (reads saved state)
- `--skip <phase>` — Skip a phase (use when you have existing artifacts)
</context>

## Phase S: Specification

**Goal:** A precise, unambiguous definition of what needs to be built.

Write or elicit:

```markdown
## Specification: <Feature Name>

### What it does (user-facing)
<One paragraph from the user's perspective. What can they do that they couldn't before?>

### Inputs
| Input | Type | Required | Constraints |
|-------|------|----------|-------------|
| <input> | <type> | yes/no | <validation rules> |

### Outputs
| Output | Type | When |
|--------|------|------|
| <output> | <type> | <condition> |

### Behavior rules
1. <Rule: given X, must Y>
2. <Rule: if Z, then W>
3. <Rule: never allow Q>

### What it does NOT do (out of scope)
- <Explicit exclusion>
- <Explicit exclusion>

### Success criteria
- [ ] <Measurable criterion>
- [ ] <Measurable criterion>
- [ ] Tests pass for all behavior rules
```

**Gate:** Spec must be complete and user-confirmed before pseudocode.

## Phase P: Pseudocode

**Goal:** HOW the feature works, in plain language. No syntax. Just logic.

```markdown
## Pseudocode: <Feature Name>

### Main flow
1. Receive <inputs>
2. Validate: <validation rules>
   - If invalid: return <error with specific message>
3. Check <precondition>
   - If not met: <what to do>
4. Execute <core logic>:
   a. <sub-step>
   b. <sub-step>
   c. <sub-step>
5. Handle side effects: <what else changes>
6. Return <output>

### Edge cases
- If <condition>: <specific behavior>
- If <condition>: <specific behavior>

### Error paths
- <Error type>: <how to handle, what to return>
- <Error type>: <how to handle, what to return>

### Key decisions in the logic
- Chose to <decision> because <reason>
- Alternative considered: <alt> — rejected because <reason>
```

**Gate:** Pseudocode must cover all spec behavior rules and edge cases.

## Phase A: Architecture

**Goal:** WHERE the code lives and HOW it integrates with the existing system.

Deploy an `opus` agent:
```
Analyze the existing codebase and propose an architecture for <feature>.
Given:
- Pseudocode: <from Phase P>
- Tech stack: <from CLAUDE.md>
- Existing patterns: <read relevant existing code>
- Domain rules: <from CLAUDE.md>

Produce:
1. File structure (which files to create/modify)
2. Data model changes (if any)
3. API surface (if any)
4. Integration points (where it connects to existing code)
5. Dependencies (new libs needed? run /decide if so)
6. Test architecture (what kinds of tests, where)
```

**Context passed to each phase agent:** compressed brief only (≤150 tokens):
- Feature name + one-line description
- Tech stack (one line)
- Relevant prior decisions (verdict only, one line each)
- Active domain rules (names only)

Do NOT pass full CLAUDE.md, full session logs, or previous phase artifacts verbatim. Summarize previous phase output to ≤200 tokens before passing to the next phase agent.

```markdown
## Architecture: <Feature Name>

### Files to create
- `<path>/<file>` — <purpose>

### Files to modify
- `<path>/<file>` — <what changes>

### Data model
<Schema changes, new types, migrations needed>

### API surface
<New endpoints, functions, events>

### Integration points
- Connects to <existing module> at <specific point>
- Called by <existing code> when <trigger>

### Dependencies
- New: <lib> — needs /decide? <yes/no>
- Existing: <lib> — already in project

### Test plan
- Unit: <what to unit test>
- Integration: <what to integration test>
- E2E: <what to e2e test if applicable>
```

**Gate:** Architecture must not conflict with prior architecture decisions (check decisions log).

## Phase R: Refinement

**Goal:** Find and resolve risks BEFORE writing code.

Deploy an `opus` agent for risk analysis:
```
Review this architecture for risks:
- Implementation risks: what's technically hard?
- Integration risks: what could break existing code?
- Performance risks: any N+1s, bottlenecks, unbounded operations?
- Security risks: any auth bypass, data exposure, injection vectors?
- Reversibility: if this is wrong, how hard is it to undo?
```

For each identified risk:
```markdown
### Risk: <description>
Severity: high / medium / low
Mitigation: <specific plan to address>
Alternative: <if high risk, is there a safer approach?>
```

**Gate:** All HIGH risks must have mitigations or be explicitly accepted with user approval.

If refinement reveals the architecture is wrong → return to Phase A with new constraints.

## Phase C: Completion

**Goal:** Implement the feature based on the spec, pseudocode, and architecture.

This phase IS the actual coding. Run it with the previous artifacts as context:

1. **Follow the file plan** from Architecture exactly
2. **Follow the pseudocode** for logic — don't improvise
3. **Follow the test plan** — write tests first (TDD) if applicable
4. **Implement in dependency order** — lower-level pieces first

After each file:
- Run tests for that file
- Check domain rules (CLAUDE.md) are respected

At the end:
- Run `/verify` against the spec's success criteria
- Run `/review --diff` on all changed files

**Completion report:**
```
SPARC COMPLETE: <Feature Name>
───────────────────────────────
Spec:         <summary>
Pseudocode:   <N> flows defined
Architecture: <N> files created, <M> modified
Refinement:   <N> risks resolved
Completion:   All success criteria met ✓
```

## State Persistence

For multi-session features, save SPARC state to Obsidian:

File: `<vault>/03-product-specs/SPARC-<feature-slug>.md`

Contains all phase artifacts. Reference with `--resume` flag in next session.

## Rules

1. **No skipping to Completion.** SPARC's value is in phases S, P, A, R — they prevent the implementation from being wrong.
2. **Pseudocode has no syntax.** If you're writing actual code in Phase P, stop. Write it in plain English.
3. **Architecture must read the codebase.** Don't design in a vacuum. Read existing patterns before proposing structure.
4. **Refinement finds real risks.** "No risks identified" is almost always wrong. Look harder.
5. **Gate failures return to the previous phase.** Don't force through a bad spec — fix it.
6. **Persist to Obsidian for features spanning sessions.** If Completion will take more than one session, write artifacts to file.
7. **Model routing is explicit per phase.** Spec/Pseudocode = sonnet. Architecture/Refinement = opus. Completion = mixed.
8. **Conflicts with architecture decisions = stop.** If the proposed architecture contradicts a logged decision, surface it before proceeding. Either the decision needs revisiting (use `/decide`) or the architecture needs adjustment.
9. **Phase summaries, not transcripts.** When passing context from Phase N to Phase N+1, summarize phase N's output to ≤200 tokens. Carrying full artifacts forward through all 5 phases multiplies context costs by 5×.
10. **Architecture phase only.** Opus is used ONLY for the Architecture phase. All other phases use sonnet or haiku. Running opus for spec extraction or pseudocode is wasteful.
