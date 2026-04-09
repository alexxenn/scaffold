---
name: session-end
description: "Automated session close — updates status memory, appends session log, saves to Mem0 + Obsidian semantic MCP, flags consolidation readiness, checks for uncommitted work. Run at end of every session."
argument-hint: "[project-name] [--summary 'what we did']"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Bash
  - mcp__mem0__add-memory
  - mcp__obsidian-semantic__vault
---

<objective>
Automate the session persistence protocol defined in CLAUDE.md. One command replaces the 3-step manual process of updating status, logging to Obsidian, and checking for stale memory.

Run this before closing any Claude Code session or when context is getting long.

What it does:
1. Updates `<project>_current_status.md` in memory with what happened this session
2. Saves session summary to Mem0 (cross-session searchable memory layer)
3. Appends a dated entry to the project's SESSION_LOG.md in Obsidian
4. Updates Obsidian semantic index via MCP (enables semantic search over session logs)
5. Saves key decisions/blockers to Mem0 separately (tagged for `/start` retrieval)
6. Checks for uncommitted changes and warns
7. Checks if MISTAKE_LOG.md has enough entries to run `/consolidate`
8. Outputs a clean "session closed" summary with the next task

This skill WRITES files (status memory + session log). All writes require review before committing.
</objective>

<context>
**Arguments:**
- `[project-name]` — Optional. Detected from cwd if omitted. Same values as `/start`.
- `--summary 'text'` — Optional. If provided, uses this as the session summary instead of inferring from context.
</context>

## Process

### Step 1: Detect Project + Paths

Same detection logic as `/start`. Map project name to:
- Status file: `.claude/projects/.../memory/<project>_current_status.md`
- Session log (unified vault): `AI-Employee-Platform/07-session-logs/SESSION_LOG.md` (main) OR `AI-Employee-Platform/<project>/07-session-logs/SESSION_LOG.md` (project-specific)
- Mistake log: `AI-Employee-Platform/05-anti-patterns/<project>/MISTAKE_LOG.md` (if exists)

**Unified vault paths only.** Do NOT use old local `*-KB/` paths. All session logs live under `AI-Employee-Platform/`.

### Step 2: Read Current State

Parallel read (haiku agents):
- **Agent A:** Current status file → what it says the current task is
- **Agent B:** Recent conversation context (last 20 assistant messages) → what actually happened
- **Agent C:** `git status` in the project directory → uncommitted changes list

### Step 3: Infer Session Summary

From Agent A + B:

**What happened this session:**
- List files created/modified (from Agent C git status)
- List decisions made (scan conversation for "decided to", "going with", "verdict:")
- List errors hit (scan for error messages, CVEs, failed attempts)
- Estimate if task is complete or still in progress

**Next task:**
- If current task appears done (tests pass, files committed): read status file for what comes next
- If current task still in progress: mark as "CONTINUE: [current task]"

If `--summary` was provided: use that text as the summary, skip inference.

### Step 4: Update Status Memory File

Read the current `<project>_current_status.md` file.

Update:
- `## Status as of [today's date]`
- `**Phase:**` — keep same unless session changed it
- `**What's done:**` — prepend new bullets from this session
- `**Next step:**` — update to what was decided this session
- `**Why/How to apply:**` — keep existing unless architecture changed

Write the updated file back.

### Step 4b: Save Session Summary to Mem0

After writing the status file, call `mcp__mem0__add-memory` to create a searchable cross-session memory entry.

**Tool call:**
```
mcp__mem0__add-memory(
  query: "[YYYY-MM-DD] [Project] session: [1-2 sentence summary of what was accomplished]. Current phase: [phase]. Next: [next task].",
  userId: "{{USER_ID}}"
)
```

The query should be a dense, searchable summary — not the full session log. Include:
- What was accomplished (1-2 sentences)
- Current phase/milestone
- Next task for the following session
- Any key technical context (e.g., "migrated to X", "blocked on Y")

This enables `/start` to search Mem0 for recent session context across all projects.

### Step 5: Append Session Log Entry

Read the project's SESSION_LOG.md (first 5 lines only — to get format).

Append a new entry at the TOP (after the header, before previous entries):

```markdown
## [YYYY-MM-DD] — [Project] — [2-word session description]

**What happened:**
- [bullet 1: main thing accomplished]
- [bullet 2: key decision or pattern discovered]
- [bullet 3: error hit or blocker encountered, if any]

**Files touched:** [comma-separated list from git status]

**Next:** [next task — 1 line]

---

```

Keep entries under 10 lines. Quality over completeness.

### Step 5b: Update Obsidian Semantic Index

After writing the session log entry to the file, call `mcp__obsidian-semantic__vault` to update the Obsidian semantic index so the new entry is searchable.

**Tool call:**
```
mcp__obsidian-semantic__vault(
  action: "update",
  path: "AI-Employee-Platform/07-session-logs/SESSION_LOG.md"
)
```

If the project has a project-specific session log, also update that path:
```
mcp__obsidian-semantic__vault(
  action: "update",
  path: "AI-Employee-Platform/<project>/07-session-logs/SESSION_LOG.md"
)
```

This keeps the Obsidian semantic search index current — enables `/start` and other skills to find session context via natural language queries.

### Step 5c: Save Decisions and Blockers to Mem0

Scan the session for key decisions made and active blockers. For EACH decision or blocker found, make a separate `mcp__mem0__add-memory` call so they're individually retrievable.

**For each decision:**
```
mcp__mem0__add-memory(
  query: "[YYYY-MM-DD] [Project] DECISION: [description of what was decided and why]. Context: [brief justification].",
  userId: "{{USER_ID}}"
)
```

**For each blocker:**
```
mcp__mem0__add-memory(
  query: "[YYYY-MM-DD] [Project] BLOCKER: [what is blocking progress]. Impact: [what can't proceed]. Workaround: [if any].",
  userId: "{{USER_ID}}"
)
```

**What counts as a decision:** Library choices, architecture patterns, API design choices, naming conventions, anything logged in conversation with "decided to", "going with", "verdict:".

**What counts as a blocker:** Unresolved errors, missing credentials/access, dependency on external team, unanswered design questions.

Skip this step if the session had no notable decisions or blockers. Don't fabricate entries.

### Step 6: Mistake Capture (optional but important)

Scan conversation for:
- Commands that failed and required a fix
- Rules that were violated (from /sync-context violations or self-correction)
- Architecture decisions that were changed mid-session (usually signals a wrong assumption)

If 1+ mistakes found, offer to append to MISTAKE_LOG.md:

```
Found [N] potential mistake(s) to log:
  • [brief description of mistake + fix]
  → Append to MISTAKE_LOG.md? (y/n)
```

If user confirms, append to `AI-Employee-Platform/05-anti-patterns/<project>/MISTAKE_LOG.md`:

```markdown
## [YYYY-MM-DD] — [project] — [session description]
**What failed:** [what went wrong]
**Why it failed:** [root cause]
**Fix applied:** [what resolved it]
**Rule to add:** [draft rule in "NEVER do X" or "ALWAYS do Y" format]
**Promoted to ANTI_PATTERNS:** No — pending consolidation
```

### Step 7: Consolidation Check

Count entries in MISTAKE_LOG.md that have `**Promoted to ANTI_PATTERNS:** No`.

If count ≥ 3:
```
💡 CONSOLIDATION READY
   [N] unreviewed mistakes in MISTAKE_LOG.md
   Run /consolidate to distill into permanent rules
```

If count < 3: silent, no output.

### Step 8: Uncommitted Changes Warning

From Agent C (git status):

If uncommitted changes exist:
```
⚠ UNCOMMITTED CHANGES:
  [list of modified files]
  Commit before closing? Run: git add [files] && git commit -m "[suggested message]"
```

If clean: `✓ Working tree clean`

### Step 9: Output Session Close Summary

```
══════════════════════════════════════════
  SESSION CLOSED — [Project]
  [date] | [duration if known]
══════════════════════════════════════════

LOGGED:
  ✓ Status memory updated
  ✓ Mem0 session summary saved
  ✓ Session log appended → [log path]
  ✓ Obsidian semantic index updated
  [✓ Mem0 decisions/blockers saved (N entries) | — No decisions/blockers]
  [✓ Mistakes logged (N entries) | — No mistakes captured]

[⚠ UNCOMMITTED CHANGES: ... | ✓ Working tree clean]

[💡 CONSOLIDATION READY — N mistakes pending | —]

NEXT SESSION:
  Task: [next task]
  Start with: /start [project]

══════════════════════════════════════════
```

## Rules

1. **Always write status file first, then session log.** Status is ground truth; session log is narrative.
2. **Append to session log, never overwrite.** New entries go at the top (most recent first).
3. **Mistake capture is optional.** Ask, don't force. Some sessions have no mistakes worth logging.
4. **Session log entries max 10 lines.** Concise. If it's longer, cut it.
5. **Git status is mandatory.** Never close a session without checking for uncommitted work.
6. **Consolidation threshold is 3.** Below 3 unpromoted mistakes = not worth the noise. At 3+ = prompt.
7. **Today's date from system.** Use `date` command or system clock for accurate timestamps.
8. **Never delete existing session log entries.** Append only.
9. **Status file format preservation.** Don't change the frontmatter structure — only update the body content.
10. **One session = one log entry.** Even if the session was short. Consistency > completeness.
11. **MCP saves are non-blocking.** If `mcp__mem0__add-memory` or `mcp__obsidian-semantic__vault` fails (server down, timeout), log the failure in the output summary but do NOT block the session close. The file-based saves are the ground truth; MCP saves are supplementary.
12. **Mem0 entries must be self-contained.** Each Mem0 entry should make sense without reading the file-based status. Include project name, date, and enough context to be useful in isolation.
13. **No duplicate Mem0 entries.** One session summary + one entry per decision/blocker. Don't save the same information twice.
14. **Unified vault paths only.** All session log paths must use `AI-Employee-Platform/` prefix. Never use old local `*-KB/` paths.
