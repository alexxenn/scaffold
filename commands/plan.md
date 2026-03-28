---
name: plan
description: "Convert a goal or milestone into a persistent, dependency-aware task graph stored as EXECUTION_PLAN.md. First step of the execution engine — plan once, then /execute runs it across sessions."
argument-hint: "<goal> [--from-decide] [--from-sparc] [--append] [--dry-run]"
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
Convert a goal or milestone into a persistent, dependency-aware task graph written to `EXECUTION_PLAN.md` in the project's Obsidian vault.

This skill is the entry point of the execution engine. You plan once, then `/execute` works through the task graph across sessions without re-planning.

Outputs:
- A structured `EXECUTION_PLAN.md` with atomic tasks, dependencies, wave groupings, skill chains, and model assignments
- A printed summary showing Wave 1 tasks and the next command to run

**Model routing:**
- Research agents (codebase scan, dep scan, ADL read) → `haiku`
- Task decomposition and dependency analysis → `sonnet`
- Any `decision` task assigned within the plan → `opus`
</objective>

<context>
**Arguments:**
- `<goal>` — Required. What to plan. Can be a milestone name ("Phase 1 — Core Runtime"), a feature ("add authentication"), or a multi-task goal description.
- `--from-decide` — Pull the accepted verdict from the most recent `/decide` output and decompose it into implementation tasks automatically.
- `--from-sparc` — Pull the spec artifact from a `/sparc` session and convert it into an ordered task graph.
- `--append` — Add new tasks to an existing `EXECUTION_PLAN.md` rather than creating a new one.
- `--dry-run` — Show the proposed task graph without writing to disk.

**Task types and their skill chains:**
- `code` → `/tdd` → `/review` → `/verify`
- `feature` → `/workflow-gate auto` (or `/sparc` if >1 day of work) → `/verify`
- `decision` → `/decide --size <auto-detected>` → blocks wave until resolved
- `bug` → `/debug-systematic` → `/verify`
- `research` → `/dispatch --model haiku`
- `review` → `/review`
- `manual` → human action required, pauses `/execute`

**Model tier by task type:**
- `code` → sonnet
- `decision` → opus
- `research` → haiku
- `feature` → sonnet (execution) + opus (architecture review)
- `bug` → sonnet
- `review` → sonnet
- `manual` → n/a
</context>

## Step 1: Read Context Sources

Determine input source based on flags:

- **No flag (default):** The `<goal>` argument is the direct input.
- **`--from-decide`:** Read the most recent `/decide` output from the conversation. Extract the accepted verdict and implementation recommendations.
- **`--from-sparc`:** Read the `/sparc` spec artifact from the conversation or from disk if it was persisted. Extract the component list, interfaces, and sequence of implementation.

Locate the Obsidian vault path by reading `reference_obsidian_vault.md` from memory, or checking CLAUDE.md for vault location. Store this as `<vault-path>`.

If `EXECUTION_PLAN.md` already exists at `<vault-path>/EXECUTION_PLAN.md` AND `--append` was NOT passed, ask the user before overwriting:

```
EXECUTION_PLAN.md already exists at <path>.
Options:
  1. Overwrite — replace the existing plan entirely
  2. Append — add new tasks to the existing plan
  3. Cancel

Which? (1/2/3)
```

## Step 2: Research (parallel haiku agents)

Spawn 3 agents in parallel, all using model `haiku`:

All 3 research agents use haiku — this is pure fact-finding (file scanning, decision log reading, codebase search). No analysis required at this stage.

Cap each agent's output to ≤300 tokens. Return: list of relevant files, existing work items, relevant decisions. No elaboration.

**Agent 1 — Existing work scan:**
Search the codebase for any work already done related to the goal. Look for:
- Files that are already implemented, partially implemented, or stubbed
- Tests that already exist
- TODOs or FIXMEs referencing this area
Report: what's done, what's partially done, what's missing entirely.

**Agent 2 — Affected files and dependencies:**
Identify:
- Files and directories likely to be created or modified
- External dependencies (libraries, services, APIs) involved
- Internal module dependencies (what imports what)
Report: file list with modification type (create/modify/delete), dependency graph sketch.

**Agent 3 — Architecture constraints:**
Read `ARCHITECTURE_DECISIONS_LOG.md` from the vault (at `<vault-path>/02-architecture/ARCHITECTURE_DECISIONS_LOG.md` or equivalent). Also read `CLAUDE.md` for domain-specific rules. Extract:
- Constraints that restrict implementation choices
- Patterns that MUST be followed (e.g., auth before logic, schema strictness)
- Decisions already made that affect task design
Report: list of constraints with source references.

Synthesize all three reports before proceeding.

## Step 3: Decompose into Atomic Tasks

Use sonnet for decomposition. Cap the decomposition output: each task description ≤50 tokens, "done when" criterion ≤30 tokens. The task graph must be scannable, not a design document.

Break the goal into atomic tasks. Each task MUST satisfy all of the following:

- **Completable in one session** (≤3 hours of focused work). If a task would take longer, split it.
- **Independently verifiable** — there is a concrete, observable criterion for "done".
- **Typed** — assigned exactly one of: `code`, `decision`, `feature`, `bug`, `research`, `review`, `manual`.

For `--from-decide` input: each implementation step from the verdict becomes its own task. The decision itself is already resolved — do not create a `decision` task for it.

For `--from-sparc` input: each component or interface from the spec becomes one or more tasks. Architecture sections with open questions become `decision` tasks.

Number tasks sequentially: T1, T2, T3, ...

## Step 4: Dependency Analysis and Wave Grouping

For each task, identify which other tasks it depends on. A task is BLOCKED until all its dependencies have status `done`.

Rules:
- A `decision` task that affects implementation design MUST be declared as a dependency of any task whose design it influences.
- Wave grouping is automatic — do not ask the user to define waves.
- A **wave** is a maximal set of tasks that can all be run in parallel given current dependency state.
- Wave 1 contains all tasks with `Depends on: none`.
- Wave N contains all tasks whose dependencies are all satisfied by Waves 1 through N-1.

Identify the critical path (longest dependency chain).

## Step 5: Assign Skill Chains and Model Tiers

For each task, assign:

**Skill chain** based on task type:
- `code` → `/tdd` → `/review` → `/verify`
- `feature` → `/workflow-gate auto` (use `/sparc` instead if the feature requires >1 day) → `/verify`
- `decision` → `/decide --size <auto>` where size is: minor (naming/location), medium (library/pattern), major (architecture/framework/security)
- `bug` → `/debug-systematic` → `/verify`
- `research` → `/dispatch --model haiku`
- `review` → `/review`
- `manual` → (human action)

**Model tier** based on task type:
- `code` → sonnet
- `decision` → opus
- `research` → haiku
- `feature` → sonnet
- `bug` → sonnet
- `review` → sonnet
- `manual` → n/a

## Step 6: Write EXECUTION_PLAN.md

If `--dry-run`: print the plan to console only, do not write to disk.

Otherwise, write to `<vault-path>/EXECUTION_PLAN.md`.

If `--append`: read the existing file first, then merge new tasks and waves. Preserve existing task statuses and execution log entries. Renumber new tasks to avoid collisions (continue from highest existing task number). Update the Summary block.

The file format:

```markdown
# Execution Plan: <goal name>
Created: <YYYY-MM-DD>
Last updated: <YYYY-MM-DD>
Project: <project name from CLAUDE.md or memory>

## Goal
<one-sentence statement of what this plan achieves>

## Summary
- Total tasks: N
- Done: 0 (0%)
- In progress: 0
- Pending: N
- Waves: N

## Tasks

### T1: <task name>
- **Status:** pending
- **Type:** code | decision | feature | bug | research | review | manual
- **Skill chain:** /tdd→/review→/verify
- **Model:** sonnet
- **Depends on:** none
- **Done when:** <concrete, verifiable criterion — e.g., "all unit tests pass and clippy reports zero warnings">
- **Notes:** (optional — add only if there is something non-obvious)

### T2: <task name>
- **Status:** pending
- **Type:** decision
- **Skill chain:** /decide --size medium
- **Model:** opus
- **Depends on:** none
- **Done when:** decision logged to ARCHITECTURE_DECISIONS_LOG.md with accepted verdict
- **Notes:** blocks T3, T4

...

## Waves

### Wave 1 — Current
Tasks: T1, T2 (parallel)
- T1: <name> | sonnet | /tdd→/review→/verify
- T2: <name> | opus | /decide --size medium

### Wave 2 — Pending (blocked on Wave 1)
Tasks: T3, T4
- T3: <name> | sonnet | /tdd→/review→/verify
- T4: <name> | sonnet | /workflow-gate auto→/verify

### Wave 3 — Pending (blocked on Wave 2)
Tasks: T5
- T5: <name> | sonnet | /review

## Execution Log
(filled by /execute as tasks complete)
```

## Step 7: Print Summary

After writing (or after generating if `--dry-run`), print:

```
PLAN CREATED — <goal>
─────────────────────────────────────
Tasks:  N total | N waves | N parallel in Wave 1
Stored: <absolute path to EXECUTION_PLAN.md>

Wave 1 (ready to execute now):
  T1: <name> → sonnet → /tdd→/review→/verify
  T2: <name> → opus  → /decide --size medium

Next: run /execute to start Wave 1
      run /progress to view full task graph
```

If `--dry-run`, replace "Stored:" line with:

```
DRY RUN — no file written. Pass without --dry-run to persist.
```

## Rules

1. **Tasks must be atomic.** If a task would take >3 hours, split it into two or more tasks with a dependency chain.
2. **Every task needs a concrete "done when" criterion.** "Implement X" is not a done criterion. "X compiles, all tests pass, clippy is clean" is. "Decision logged to ADL with accepted verdict" is.
3. **`decision` tasks always block their wave.** `/execute` will not advance past a wave that contains an unresolved decision task. This is enforced — not advisory.
4. **`manual` tasks pause execution.** They require explicit user confirmation before `/execute` continues. Mark them clearly in the wave summary.
5. **Wave grouping is automatic.** Derive waves from the dependency graph. Never ask the user to define waves.
6. **Guard against overwrite.** If `EXECUTION_PLAN.md` exists and `--append` was not passed, ask before overwriting. Never silently replace existing plans.
7. **Vault path comes from memory.** Read `reference_obsidian_vault.md` or CLAUDE.md to locate the vault — do not invent or assume a path.
8. **Constraints from ADL are hard constraints.** If a task design would violate an architecture decision already logged, flag it and redesign the task before writing the plan.
9. **After writing, always prompt next action.** Tell the user to run `/execute` or `/progress`. Do not leave the plan written with no guidance on what to do next.
10. **`--from-decide` and `--from-sparc` are input transforms only.** The rest of the skill runs identically — research, decompose, analyze dependencies, assign skill chains, write, summarize.
11. **Task descriptions are terse.** Each task name ≤10 words. Each "done when" criterion ≤20 words. The plan is a machine-readable execution graph, not documentation. Verbose tasks make /execute's context costs explode.
12. **Haiku for research, sonnet for decomposition.** The research phase (what exists, what's affected) is haiku. The synthesis phase (how to break it down) is sonnet. No opus in /plan unless an architecture decision is detected that should trigger /decide instead.
