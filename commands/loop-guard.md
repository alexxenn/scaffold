---
description: Detect and recover from Claude stopping mid-task. Run when Claude has gone quiet, delivered partial work, or you suspect it stopped early.
argument-hint: "[--check | --recover | --checklist <task>]"
---

# Loop Guard

Claude stops mid-task more than it should. This skill forces completion.

## Mode: --check (default)

Audit the current state for signs of incomplete work:

**File audit** (haiku):
- Scan recently modified files for truncated code (unclosed brackets, incomplete functions, missing exports)
- Check for TODO/FIXME/PLACEHOLDER markers left in modified files
- Detect half-written test files (describe blocks with no tests)

**Git audit** (haiku):
- `git status` — uncommitted changes that look like partial work
- `git diff --stat` — files modified but not staged
- Check for merge conflicts

**Task audit** (haiku):
- Re-read the original request from context
- List what was asked vs what exists now
- Identify the gap

Output format:
```
LOOP-GUARD AUDIT
================
Files complete: ✓ / ✗ [list any incomplete]
Git state: clean / [describe partial state]
Task gap: [what was asked but not delivered]

VERDICT: complete / INCOMPLETE
```

If INCOMPLETE, proceed to --recover automatically.

## Mode: --recover

Resume from partial state:

1. **Read the gap** — identify exactly what's missing
2. **No restart** — continue from where work stopped, don't redo completed parts
3. **Completion checklist** — before finishing, verify against original request
4. **Hard stop prevention** — use this checklist before responding "done":
   - [ ] All files mentioned in the task exist
   - [ ] No truncated code
   - [ ] Tests written (if task involved code)
   - [ ] No TODOs left from this session

## Mode: --checklist <task>

Generate a task-specific completion checklist before starting work. Use this at the START of complex tasks to define "done" unambiguously.

Input: task description
Output: numbered completion checklist that can be checked off

Run this before starting, check it before finishing.

## Model routing

- File/git auditing: haiku (fast search, no reasoning needed)
- Gap analysis: sonnet (synthesis)
- Recovery planning: sonnet (generation)
- Complex root cause: opus only if recovery fails twice
