---
name: execute
description: "Execution engine for Scaffold plans. Reads EXECUTION_PLAN.md, identifies the current wave, runs each task's skill chain, gates with /verify, marks done, advances to next wave. Supports resume, single-task, dry-run, and force modes."
argument-hint: "[--continue] [--task <id>] [--wave] [--dry-run] [--skip <id>] [--force <id>]"
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
Conductor of the Scaffold execution engine. Turns a `/plan`-generated `EXECUTION_PLAN.md` into completed code — wave by wave, task by task, with hard gates after every task and checkpoints after every wave.

**What it does:**
1. Reads `EXECUTION_PLAN.md` and identifies the current wave (all tasks whose dependencies are satisfied)
2. Runs each task's skill chain based on task type (not name)
3. Gates every task with `/verify` before marking it done
4. Updates `EXECUTION_PLAN.md` after EVERY individual task
5. Checkpoints after every wave via `/context-save`
6. Asks for user confirmation before advancing to the next wave

**When to use:**
- After `/plan <goal>` has produced an `EXECUTION_PLAN.md`
- At the start of any session: `/execute --continue` picks up exactly where the last session ended
- When you need to run a single specific task: `/execute --task T3`

**When NOT to use:**
- There is no `EXECUTION_PLAN.md` — run `/plan <goal>` first
- The task is a one-off, sub-hour item — use `/workflow-gate auto` or `/gsd:quick` directly
</objective>

<context>
**Arguments:**
- `--continue` — Resume from current wave in `EXECUTION_PLAN.md`. Default behavior when a plan exists and is not yet complete.
- `--task <id>` — Execute one specific task (e.g., `--task T3`). Bypasses wave ordering. Still runs skill chain + `/verify`.
- `--wave` — Execute the current wave, then stop. Do not auto-advance. Print the next wave manifest and exit.
- `--dry-run` — Print exactly what would execute (tasks, skill chains, model tiers) without writing files or invoking any skills.
- `--skip <id>` — Mark a task as `skipped` and continue wave execution. Requires a reason (prompt user if not provided).
- `--force <id>` — Force a task to run even if its dependencies are not `done`. Logged as override in the Execution Log.

**Plan location:** `EXECUTION_PLAN.md` — look for it first in the Obsidian vault path defined in CLAUDE.md, then in the project root. If not found in either, stop and tell the user to run `/plan <goal>`.
</context>

## Process

### Step 1: Load the Plan

Read `EXECUTION_PLAN.md`. If it does not exist:

```
No plan found. Run `/plan <goal>` to create one.
```

Stop. Do nothing else.

Use a haiku agent to read and parse EXECUTION_PLAN.md — this is structured data extraction, not analysis. Parse task list, statuses, dependencies, and current wave. Return structured summary to parent context.

Parse from the plan:
- All tasks with: ID, name, type, status, dependencies, skill chain, model tier, "done when" criterion
- Wave groupings
- Execution Log (if it exists — carry it forward)
- Plan name / milestone name

If `--dry-run`: proceed to Step 2 but take no write actions and invoke no skills. Print the full execution manifest and exit.

---

### Step 2: Identify the Current Wave

**Current wave** = all tasks where:
- Status is `pending`
- ALL dependency task IDs have status `done`

**Edge cases:**
- Tasks with status `in-progress`: surface them first — they were interrupted. Ask the user whether to retry or mark blocked.
- No pending tasks and no in-progress tasks: check if all tasks are `done` → go to Step 7 (Completion). If some are `blocked` → surface blockers and stop.
- `--task <id>`: skip wave logic entirely. Locate the task by ID and go to Step 3.
- `--force <id>`: locate the task, mark dependencies as overridden, log it, proceed.

Print the wave manifest before executing anything:

```
EXECUTE — <plan name>
══════════════════════════════════════════
Wave <N> of <total> | <X> tasks ready | <Y> tasks pending after

Ready to execute:
  T2: Implement VaultSecret<T>      → sonnet → /tdd → /review → /verify
  T3: Design tenant isolation       → opus   → /decide --size medium → /verify
  T5: Scaffold CLI binary           → sonnet → /rust:scaffold → /rust:test-write → /verify

Blocked (next wave):
  T4: Tenant-aware DB queries       → depends on T2 ✗, T3 ✗

Skipped:
  T1: Project scaffolding           → skipped (manual setup already done)
══════════════════════════════════════════
Proceed? [Y to execute wave / task-id to run one specific task / n to abort]
```

Wait for user confirmation before proceeding. Do not auto-execute.

If `--dry-run`: print this manifest and stop. No confirmation needed.

---

### Step 3: Execute Each Task

Execute tasks in the wave. Apply parallelism rules (see below), then for each task run its skill chain:

**Context passed to each skill invocation:** compressed to ≤150 tokens:
- Task name + type + "done when" criterion
- Tech stack (one line)
- Active domain rules (names only — the invoked skill will load full rules if needed)
- Relevant prior decisions (verdict only)

Do NOT pass the full EXECUTION_PLAN.md or full session context to each skill. Each skill is responsible for loading its own context if needed.

#### Skill Chain by Task Type

**`code` task:**
1. Invoke `/tdd <task description>`
2. When `/tdd` completes → invoke `/review` on the affected files
3. Invoke `/verify`
4. If `/verify` passes → mark `done`
5. If `/verify` fails → increment failure count. At 3 failures → mark `blocked`, log reason, surface to user, do not retry.

**`decision` task:**
1. Invoke `/decide "<task name>" --size <model-derived-from-plan>`
2. PAUSE wave execution. Print:
   ```
   Decision task T<N> requires your input.
   /decide has been invoked for: <task name>
   Resume with `/execute --continue` once the decision is resolved.
   ```
3. Do not advance the wave until user confirms the decision is resolved and marks the task done.

**`feature` task:**
- If "done when" implies >1 day of work → invoke `/sparc <task name>`
- Otherwise → invoke `/workflow-gate auto --task <task name>`
- After completion: invoke `/verify`
- Pass → mark `done`. Fail → failure escalation (3 strikes → `blocked`).

**`bug` task:**
1. Invoke `/debug-systematic <task name>`
2. Invoke `/verify`
3. Pass → mark `done`. Fail → failure escalation.

**`research` task:**
1. Invoke `/dispatch "<task description>" --model haiku`
2. Aggregate results in parent context
3. No `/verify` gate needed — mark `done` after aggregation is complete

**`review` task:**
1. Extract the file list from the task description
2. Invoke `/review <files>`
3. Mark `done` after review output is produced

**`manual` task:**
1. Print the task description and "done when" criterion clearly:
   ```
   ── MANUAL TASK: T<N> ──────────────────────────────
   <task description>

   Done when: <done when criterion>

   Complete this manually, then confirm to continue.
   ────────────────────────────────────────────────────
   Confirm complete? [y / n to skip]
   ```
2. Wait for explicit user confirmation. Do not guess or skip.
3. User confirms → mark `done`. User skips → prompt for skip reason → mark `skipped`.

---

### Step 4: Parallel Execution Within a Wave

Before executing a wave, classify each task:

- Tasks that are `decision` or `manual` type → **always sequential** (require user interaction)
- All other tasks that share no input/output dependencies within the wave → **eligible for parallel dispatch**

For parallel-eligible tasks: dispatch them together using the Agent tool. Do not run them one at a time.

For sequential tasks: execute them after all parallel tasks in the wave complete.

Parallel dispatch template per task:
```
[EXECUTE TASK <ID> | TYPE: <type> | MODEL: <tier>]
Task: <task name>
Description: <task description>
Done when: <done when criterion>
Skill chain: <ordered list of skills to invoke>
Project rules: <relevant CLAUDE.md domain rules for this task type>
```

---

### Step 5: Gate Each Task with /verify

After every task's skill chain completes (except `research`, `review`, and `manual` — see above):

1. Pull the task's "done when" criterion from `EXECUTION_PLAN.md`
2. Invoke `/verify` with the criterion as the requirement
3. Evaluate:
   - **Pass** → proceed to Step 5 update
   - **Fail** → increment the task's failure counter
     - Failures 1–2: log the failure reason, retry the skill chain
     - Failure 3: mark task `blocked`, log all 3 failure reasons, surface to user, stop retrying

---

### Step 6: Update EXECUTION_PLAN.md

Update the task's status immediately after it completes — not at the end of the wave.

Update the task block:

```markdown
### T2: Implement VaultSecret<T>
- **Status:** done ✅ (completed 2026-03-27)
```

Or for blocked:

```markdown
### T2: Implement VaultSecret<T>
- **Status:** blocked ❌ (3 failures — see Execution Log)
```

Append to the Execution Log section (create it if it doesn't exist):

```markdown
## Execution Log
- 2026-03-27 | T2 done | VaultSecret<T> impl, all property tests pass, no Debug on secret types
- 2026-03-27 | T3 done | Decision: secrecy crate selected, logged to ARCHITECTURE_DECISIONS_LOG.md
- 2026-03-27 | T4 blocked | 3 failures: tenant_id missing in queries — needs schema change first
- 2026-03-27 | T5 skipped | Reason: already scaffolded manually in prior session
- 2026-03-27 | T6 forced | Dependencies T4 ✗ overridden by user — logged as deviation
```

---

### Step 7: Advance or Checkpoint

After all tasks in a wave complete:

**All passed:**
1. Checkpoint: update the project status file (`<project>_current_status.md`) and the session log in Obsidian at `07-session-logs/SESSION_LOG.md`
2. Print the next wave manifest (same format as Step 2)
3. Ask for confirmation before executing the next wave:
   ```
   Wave <N> complete. Ready for Wave <N+1>?
   [Y to execute / n to stop here]
   ```
4. Do not auto-run the next wave without explicit confirmation.

**Some failed (blocked):**
1. Checkpoint current state
2. Print blocked tasks with their failure reasons
3. Ask user how to proceed:
   ```
   Wave <N> blocked. The following tasks need attention:
     T4: blocked — tenant_id missing in queries
     T7: blocked — compile error in macro expansion

   Options:
     skip <id>  — skip this task and continue
     force <id> — retry ignoring failure state
     fix        — you fix it manually, then run /execute --continue
     stop       — stop here and resume later
   ```

**`--wave` flag active:** After wave completes (pass or fail), print next wave manifest and stop. Do not prompt for continuation.

---

### Step 8: Completion

When all tasks across all waves are `done` or `skipped` (no `pending`, no `in-progress`, no `blocked`):

```
MILESTONE COMPLETE — <plan name>
────────────────────────────────────────
Tasks completed:  <N>
Tasks skipped:    <N>
Tasks blocked:    <N>
First task:       <date>
Last task:        <date>

Run `/progress` for the full execution log.
Archive EXECUTION_PLAN.md? [y / n]
────────────────────────────────────────
```

If user confirms archival:
1. Move `EXECUTION_PLAN.md` to `<vault>/archive/EXECUTION_PLAN_<date>.md`
2. Update the status memory file to reflect milestone complete
3. Append a final entry to the Obsidian session log

If `blocked` tasks exist when all others are done, state is not "complete" — surface the blockers and ask for direction.

---

## Rules

1. **Never skip a wave's `decision` tasks.** A `decision` task in the current wave blocks the entire wave until resolved. Print it prominently. Do not silently continue past it.

2. **Never auto-advance to the next wave without user confirmation.** Always print the next wave manifest and wait for an explicit `Y`. Runaway execution is worse than a slow one.

3. **Update EXECUTION_PLAN.md after EVERY task.** Not at the end of the wave — after each individual task completes (pass, fail, skip, or block). If execution is interrupted mid-wave, the plan must reflect reality.

4. **`manual` tasks are sacred pauses.** Print exactly what the human needs to do. Wait for explicit confirmation. Do not guess, infer, or skip without asking.

5. **`--dry-run` must be safe.** Reads files and prints the execution plan. Writes nothing. Invokes no skills. No side effects of any kind.

6. **Skill chain is determined by task type, not task name.** The `type` field in `EXECUTION_PLAN.md` is the source of truth. A task named "Design tenant isolation" with type `decision` runs `/decide`, not `/sparc`.

7. **3-failure escalation is automatic.** Three consecutive `/verify` failures on one task → mark `blocked`, log all three failure reasons, surface to user, do not retry until user clears the block.

8. **Parallel tasks are dispatched together.** Non-sequential, non-dependent tasks in the same wave go out as a batch via the Agent tool. Do not run eligible parallel tasks one at a time.

9. **Log everything to the Execution Log.** Every task completion, failure, skip, block, and force-override gets a timestamped entry. No silent operations.

10. **If no EXECUTION_PLAN.md exists:** print `No plan found. Run /plan <goal> to create one.` and stop. Do not create the plan, do not guess at tasks.

11. **`decision` tasks require pause and user resolution.** Do not mark a `decision` task done by yourself. The decision must be confirmed resolved by the user before continuing.

12. **`--force` is logged as a deviation.** It is never silent. The Execution Log entry must say "forced — dependency override by user" for auditability.
13. **Haiku for plan operations.** Reading, parsing, and updating EXECUTION_PLAN.md are all haiku-level operations — structured data manipulation, not reasoning. Never escalate plan I/O to sonnet or opus.
14. **Compressed task context.** Each task invocation gets a ≤150-token brief. The invoked skill (e.g., /tdd, /decide) handles its own context loading. /execute is the conductor, not the context carrier.
