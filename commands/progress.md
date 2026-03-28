---
name: progress
description: "Read EXECUTION_PLAN.md and render a visual status of the execution plan — what's done, in-progress, blocked, and coming next. Called automatically by /preload if a plan exists."
argument-hint: "[--next] [--log] [--blocked] [--compact]"
allowed-tools:
  - Read
  - Glob
  - Grep
---

<objective>
Read EXECUTION_PLAN.md and render a clear, visual status of the current execution plan. Shows every task grouped by status: done, in-progress, current wave, next wave, blocked. Think of it as `git log --oneline` but for your execution plan — a single glance that tells you exactly where things stand and what to do next.

This skill is read-only. It never writes, edits, or modifies any file.
</objective>

<context>
**Arguments:**
- (no args) — Full visual task graph with all waves and stats
- `--next` — Show only the next executable wave (what to run right now)
- `--log` — Show the execution log (history of completed tasks with dates and notes)
- `--blocked` — Show only blocked tasks and their specific blockers + fix actions
- `--compact` — One line per task, no wave grouping, fastest overview

**When called automatically by `/preload`:** Use default mode. Output must be concise — it's embedded in a session start brief, so avoid over-explaining.
</context>

## Process

### Step 1: Locate EXECUTION_PLAN.md

Search for `EXECUTION_PLAN.md` in this order:
1. Check memory files for vault path (look for `reference_obsidian_vault.md` or similar) — then check `<vault>/<project>/EXECUTION_PLAN.md`
2. Current working directory
3. Parent directory
4. Common vault paths: `AI-Employee-Platform/`, `AI-Employee-Platform/*/`
5. Use Glob pattern `**/EXECUTION_PLAN.md` as a fallback

If not found anywhere, stop and output:
```
No active execution plan found.
Run /plan <goal> to create one.
```

### Step 2: Parse the Plan

Read the full file. Extract:

**Plan metadata:**
- Plan name / project name
- One-sentence goal
- Total task count
- Current wave number

**Per task, extract:**
- Task ID (T1, T2, etc.)
- Task title / description
- Status: `done` | `in-progress` | `pending` | `blocked` | `skipped`
- Skill(s) assigned (e.g., `/tdd→/review→/verify`, `/decide`, `manual`)
- Model routing (e.g., `[sonnet]`, `[opus]`, `[haiku]`)
- Dependencies (e.g., "Waiting on: T6, T7")
- If `in-progress`: current sub-step (e.g., "currently: /tdd phase")
- If `blocked`: reason and what failed
- Start date / completion date (from execution log section if present)
- Notes or outcome (from execution log)

**Compute stats:**
- Count by status: `done`, `in-progress`, `pending`, `blocked`, `skipped`
- Completion percentage: `done / (total - skipped) * 100`
- Current wave = tasks whose dependencies are ALL `done` and whose own status is `pending`
- Next wave = tasks whose dependencies include at least one task in the current wave
- Blocked = tasks explicitly marked blocked OR tasks whose dependency has status `blocked`

### Step 3: Check for Critical Warnings

Compute and store (for display in Step 4):

1. **Stalled tasks**: Any task with status `in-progress` and start date >7 days ago → "WARNING: T<N> has been in-progress since <date>. May be stalled."
2. **Decision tasks in current wave**: Any current-wave task using `/decide` → "NOTE: Wave contains a /decide task — execution will pause for your input."
3. **Manual tasks in current wave**: Any current-wave task marked `manual` → "NOTE: Wave contains a manual task — execution will pause for your action."
4. **Empty current wave**: If `in-progress` count = 0 and `pending` count > 0 but current wave is empty → "WARNING: No tasks are executable. Check blocked tasks."

### Step 4: Render Output

Pick the rendering mode based on the argument provided.

---

**Default (no args) — Full visual task graph:**

```
PROGRESS — <plan name>
═══════════════════════════════════════════════════
  Goal: <one-sentence goal>
  Progress: <progress-bar> <pct>% (<done>/<total> tasks done)

  ✅ DONE (<count>)
  ─────────────────────────────────────────────────
  T1  <title>                             <skill>          [<model>]
  T2  <title>                             <skill>          [<model>]

  🔄 IN PROGRESS (<count>)
  ─────────────────────────────────────────────────
  T5  <title>                             <skill>          [<model>]
      → Currently: <current sub-step>

  ⏳ CURRENT WAVE — ready to execute (<count>)
  ─────────────────────────────────────────────────
  T6  <title>                             <skill>          [<model>]
  T7  <title>                             <skill>          [<model>]
  → Run: /execute to start this wave

  🔒 NEXT WAVE — pending (<count>)
  ─────────────────────────────────────────────────
  T8  <title>                             <skill>          [<model>]
      Waiting on: T6 ✗, T7 ✗

  🚫 BLOCKED (<count>)
  ─────────────────────────────────────────────────
  T10 <title>                             <skill>          [<model>]
      Blocked: <reason>
      Action needed: <fix command>

<warnings and notes here, if any>

═══════════════════════════════════════════════════
  Next action: /execute (Wave <N>: T6 + T7 in parallel)
```

**Progress bar generation:**
- Width = 20 characters
- Filled chars = `round(pct / 100 * 20)` using `█`
- Remaining chars = `░`
- Example at 40%: `████████░░░░░░░░░░░░`
- Compute from actual task statuses — not from any Summary section in the file

**"Next action" rule:** One command, no ambiguity. If current wave is ready → `/execute`. If a decision task is next → `/decide "<topic>"`. If everything is blocked → "resolve blocker for T<N>". If plan is 100% done → "Plan complete. Run `/plan <next goal>` to start a new phase."

---

**`--next` — Next executable wave only:**

```
NEXT WAVE — <plan name>
────────────────────────────────────
Wave <N> | <count> tasks ready | <parallel|sequential>

  T6: <title>     → <model> → <full invocation command>
  T7: <title>     → <model> → <full invocation command>

Run: /execute
```

For each task, write out the exact skill invocation (e.g., `/workflow-gate auto --task "auth middleware"`, `/decide "rate limiting approach" --size medium`).

Flag if any task is `manual` or `decision` type — these pause execution.

---

**`--log` — Execution history:**

```
EXECUTION LOG — <plan name>
────────────────────────────────────
<date>  T<N>  ✅ done    <title> — <outcome/note>
<date>  T<N>  ✅ done    <title> — <outcome/note>
<date>  T<N>  🔄 active  <title> — <current sub-step>
```

Show all completed tasks in chronological order, then the active task at the bottom. If no dates are recorded, omit the date column. If no notes are recorded, omit the dash and note.

---

**`--blocked` — Blocked tasks only:**

```
BLOCKED TASKS — <plan name>
────────────────────────────────────
T<N>: <title>
  Skill: <skill>
  Blocked because: <specific reason>
  Failure: <what failed or what's missing>
  Fix: <exact command or action to unblock>
```

If no tasks are blocked: output "No blocked tasks. All clear."

---

**`--compact` — One line per task:**

```
✅ T1  <title>
✅ T2  <title>
🔄 T5  <title>
⏳ T6  <title>          ← NEXT WAVE
⏳ T7  <title>          ← NEXT WAVE
🔒 T8  <title>
🚫 T10 <title>          [BLOCKED]
```

Status icons:
- `✅` = done
- `🔄` = in-progress
- `⏳` = pending (current wave tasks get `← NEXT WAVE` suffix)
- `🔒` = pending but blocked by dependency
- `🚫` = explicitly blocked
- `—`  = skipped

## Rules

1. **Read-only.** Never write, edit, create, or modify any file. If you feel the urge to "update" the plan — stop. The user controls the plan.
2. **No plan = clear message.** If `EXECUTION_PLAN.md` doesn't exist, say so and tell the user to run `/plan`. Don't guess or fabricate a plan.
3. **Accurate progress bar.** Always compute from actual task statuses. Never trust a `## Summary` or `## Stats` section in the file — re-derive from the task list directly.
4. **Flag decision and manual tasks prominently.** These pause execution — the user needs to know before starting a wave, not after.
5. **Single next action.** The bottom line is always one command. No lists, no "or you could...". One thing. The most important thing right now.
6. **Concise when called by `/preload`.** This skill is embedded in session start briefs. Default output must not exceed ~50 lines. If the plan is very large, collapse `DONE` tasks to a count summary (e.g., "✅ DONE (12) — see `--log` for details").
7. **Dependency resolution is computed, not trusted.** If a task says "Waiting on T6" but T6 is marked done, treat it as unblocked. The plan file may be stale — always re-derive dependency state from actual task statuses.
8. **No hallucinated dates.** If a task has no recorded date, don't invent one. Omit the date field or write `—`.
