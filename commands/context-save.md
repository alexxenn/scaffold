---
description: Save current session state before context window compaction. Run when context is getting long or before switching tasks.
argument-hint: "[--status | --full | --restore]"
---

# Context Save

Context compaction deletes your session state. This skill saves it first.

## Mode: --status (default)

Save a compact status snapshot. Run this when:
- Context window is getting long (Claude warns you)
- You're about to switch to a different task
- You want a checkpoint before a risky operation

**What it saves** (sonnet):

1. **Current task** — one sentence: what are we doing right now
2. **Progress** — what's done, what's not
3. **Blockers** — anything that stopped forward progress
4. **Decisions made this session** — any choices that affect future code
5. **Next immediate action** — the exact next step, specific enough to resume without rereading context
6. **Files touched** — list of modified files

Writes to two places:
- Memory: updates `<project>_current_status.md` with above
- Resume prompt: writes `RESUME.md` in project root with a self-contained "resume from here" prompt

`RESUME.md` format:
```markdown
# Resume Point — [timestamp]

## Context
[what we were doing]

## Progress
[what's done]

## Immediate next step
[exact next action]

## Key decisions
[any decisions made]

## Files in progress
[files that were being modified]

---
To resume: paste this file into a new session, or run /preload
```

## Mode: --full

Full context dump before compaction:
- Everything in --status
- Plus: dump all relevant code snippets that won't survive compaction
- Plus: architectural context for the current task
- Writes to `CONTEXT_DUMP_[timestamp].md`

Use when in the middle of a complex refactor or multi-file change.

## Mode: --restore

Read the most recent RESUME.md and output a structured brief for starting fresh:
- What was happening
- Exact resume point
- What to do first

## When to run automatically

The Stop hook reminds you to run `/context-save` at session end. But also run it proactively when you see Claude's context warning.

## Model routing

- Writing status/resume files: sonnet
- No opus needed — this is synthesis of existing context, not reasoning
