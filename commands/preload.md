---
name: preload
description: "Load ALL persistent context before execution — memory, vault decisions, domain rules, preferences, current status. The 'warm start' for any work."
argument-hint: "[--project <name>] [--brief] [--full]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

<objective>
Load every piece of persistent context that should inform the current work session. This is the mandatory "warm start" that ensures nothing is forgotten — decisions, preferences, domain rules, current status, and unfinished work.

Run this:
- **At the start of every work session** (before writing any code)
- **Before any execution phase** (`/gsd:execute-phase`, `/gsd:quick`, or manual coding)
- **After a long conversation** where early context may have drifted
- **When switching between projects** in the same workspace

This skill READS everything and presents a concise execution brief. It writes nothing.
</objective>

<context>
**Arguments:**
- `--project <name>` — Focus on a specific project (e.g., `--project clawforge`, `--project ag-bridge`). If omitted, detect from current directory or load all.
- `--brief` — Compact output: just status + next action + active rules. Default.
- `--full` — Verbose output: every memory file, every decision, every rule, full context dump.
</context>

## Process

### Step 1: Load Memory Files

Read ALL memory files from the project's memory directory:

1. Read `MEMORY.md` index to discover all memory files
2. Read every linked memory file:
   - **User profile** → who you're working with (expertise level, preferences)
   - **Feedback** → communication style, what to avoid, what works
   - **Project status files** → current phase, what's done, what's next, blockers
   - **Architecture decisions** → resolved debates that constrain implementation
   - **Reference files** → vault locations, skill locations, external systems

Store key facts for the execution brief.

### Step 2: Load Current Project Status

Find and read the active project's status file (e.g., `clawforge_current_status.md` or `ag_bridge_current_status.md`):

Extract:
- Current phase and task
- What was done last session
- Blockers
- Next immediate step
- How many sessions have been completed

### Step 3: Load Latest Session Log

Find the project's session log in the Obsidian vault:
- Check `<vault>/07-session-logs/SESSION_LOG.md`
- Read the LAST entry (most recent session)
- Extract: what changed, decisions made, files touched, next steps stated

Cross-reference with status file — if they disagree, flag it.

### Step 4: Load Architecture Decisions

Find and read `ARCHITECTURE_DECISIONS_LOG.md` from the Obsidian vault:
- List all decisions with their one-line verdict
- Flag any decisions that are relevant to the NEXT task (based on status file)

### Step 5: Load Domain Rules

Read `CLAUDE.md` from the project root:
- Extract the "Domain-Specific Rules" section (or "Rust-Specific Rules", etc.)
- Extract the "Communication Style" section
- Extract the "Decision Protocol" section (if present)
- Extract the "Skill Routing" table

### Step 6: Load Active Constraints

Check for:
- Unfinished GSD plans: look for `.planning/` directory with incomplete STATE.md
- Pending TODOs: check `.planning/todos/`
- Work-in-progress checkpoints: check for `.continue-here.md`
- Uncommitted changes: run `git status` if in a git repo

### Step 7: Generate Execution Brief

**Brief mode (default):**

```
═══════════════════════════════════════════
  EXECUTION BRIEF — <Project Name>
  <date> | Session <N+1>
═══════════════════════════════════════════

  STATUS: <phase/task from status file>
  LAST SESSION: <one-line summary from session log>
  NEXT ACTION: <from status file "next immediate step">

  ACTIVE DECISIONS (<count>):
  <Only decisions relevant to the next task>
    #<N>: <verdict> — <one-line why>

  DOMAIN RULES:
    1. <rule 1>
    2. <rule 2>
    ...

  PREFERENCES:
    - <communication style>
    - <key feedback items>

  BLOCKERS: <any from status file, or "None">

  PENDING WORK:
    - <uncommitted changes, WIP checkpoints, pending TODOs>

  SKILLS AVAILABLE:
    <top 5 most relevant skills for the next task>

═══════════════════════════════════════════
```

**Full mode (`--full`):**

Everything in brief mode PLUS:
- Complete user profile
- All feedback memories verbatim
- All architecture decisions (not just relevant ones)
- Full session log of last 3 sessions
- Complete domain rules section
- All reference file contents
- Full skill routing table

### Step 8: Context Warnings

Flag any issues:
- Status file is >7 days old → "WARNING: Status file may be stale. Verify before acting."
- Session log and status file disagree on next step → "CONFLICT: Session log says X, status says Y. Clarify before proceeding."
- Architecture decisions reference files that no longer exist → "WARNING: Decision #N references <file> which doesn't exist."
- No uncommitted changes but status says work was in progress → "WARNING: Expected WIP changes but working tree is clean."

## Rules

1. **Read-only.** This skill reads everything and writes nothing. It's a pure context loader.
2. **Always run before execution.** If you're about to write code and haven't run `/preload` this session, run it first.
3. **Cross-reference everything.** Status file vs session log vs git state — flag any inconsistencies.
4. **Relevant decisions only (brief mode).** Don't dump all 7 architecture decisions if only 2 apply to the current task.
5. **Surface blockers prominently.** If there's a blocker, it goes at the top, not buried in the middle.
6. **Multi-project aware.** If the workspace has multiple projects (ClawForge + AG Bridge), load the right one based on `--project` or current directory context.
7. **Respect communication preferences.** The brief itself should follow the user's stated communication style (no fluff, direct, advanced).
