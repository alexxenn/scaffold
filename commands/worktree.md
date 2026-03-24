---
name: worktree
description: "Git worktree isolation for safe experiments, risky refactors, and parallel feature work. From Superpowers pattern."
argument-hint: "<action> [--branch <name>] [--base <branch>] [--cleanup]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Manage git worktrees for isolated, parallel development. A worktree is a separate checkout of the same repo in a different directory — full isolation without stashing, branching anxiety, or dirty working trees.

**Use cases:**
- **Risky experiments** — Try an approach without touching your working code
- **Parallel features** — Work on two things simultaneously
- **Review isolation** — Check out a PR branch without disturbing your work
- **Agent isolation** — Give a subagent its own worktree so it can't corrupt your main working tree
- **Hot-fix during feature work** — Fix prod without stashing your current feature

**Why worktrees over branches?**
- No stashing — both workspaces coexist simultaneously
- No context switch — each worktree has its own index and HEAD
- True isolation — an agent operating in a worktree cannot affect your main tree
- Easy cleanup — drop the entire worktree when done
</objective>

<context>
**Arguments:**
- `<action>` — `create`, `list`, `switch`, `merge`, `drop`, or `status`
- `--branch <name>` — Branch name for the worktree. Auto-generates if omitted.
- `--base <branch>` — Base branch (default: current branch or `main`)
- `--cleanup` — Drop worktree after merge/abandon
</context>

## Actions

### `create` — Create a new isolated worktree

```bash
# Create worktree at ../<repo>-<branch-name>/
git worktree add ../<project>-<branch> -b <branch> <base>
```

**Naming convention:**
- Experiment: `<project>-experiment-<description>`
- Feature: `<project>-feat-<feature-name>`
- Hotfix: `<project>-hotfix-<issue>`
- Agent: `<project>-agent-<task>`

**Output:**
```
Worktree created:
  Path:   ../<project>-<branch>/
  Branch: <branch>
  Base:   <base-branch>

To work in it: cd ../<project>-<branch>/
To give to an agent: prompt it with "working directory: ../<project>-<branch>/"
To clean up: /worktree drop --branch <branch>
```

### `list` — Show all active worktrees

```bash
git worktree list
```

**Output:**
```
ACTIVE WORKTREES
────────────────
[main]     <path>              HEAD <short-sha> [<branch>]
[worktree] <path>-experiment   HEAD <short-sha> [<branch>] — created <date>
[worktree] <path>-feat-auth    HEAD <short-sha> [<branch>] — created <date>
```

### `status` — Show diff/status for a worktree

```bash
cd <worktree-path> && git status && git diff --stat
```

Shows what changed in the worktree vs its base branch.

### `merge` — Merge worktree changes back

Three paths depending on confidence:

1. **Direct merge** (experiment worked, changes are clean):
```bash
cd <main-tree>
git merge <worktree-branch>
```

2. **PR/review first** (for significant changes):
```bash
cd <worktree-path>
git push origin <branch>
# Then create PR — don't merge directly
```

3. **Cherry-pick specific commits** (experiment partly worked):
```bash
cd <main-tree>
git cherry-pick <commit-sha> <commit-sha>
```

Ask the user which path before proceeding.

### `drop` — Clean up a worktree

```bash
git worktree remove <path>
git branch -d <branch>  # Only if merged — use -D to force
```

**Safety check before drop:**
- Any uncommitted changes? → warn
- Branch not merged to main? → warn + confirm
- Branch has unpushed commits? → warn + confirm

### Agent Isolation Pattern

When spawning an agent to do risky work, give it a worktree:

```
1. /worktree create --branch agent-<task>
   → Creates isolated worktree at ../<project>-agent-<task>/

2. Spawn agent with: "Working directory: ../<project>-agent-<task>/"
   → Agent operates in isolation, cannot affect main tree

3. Review agent's changes: /worktree status --branch agent-<task>
   → See exactly what the agent did

4. Merge or drop based on result
   → If good: /worktree merge --branch agent-<task>
   → If bad: /worktree drop --branch agent-<task> --cleanup
```

This is the recommended pattern for any agent doing large refactors or risky changes.

## Safety Rules

1. **Always check for uncommitted changes before dropping.** Warn and confirm if the branch has work that isn't merged.
2. **Use `-d` not `-D` for branch cleanup.** `-D` force-deletes — only use if you explicitly want to discard the branch.
3. **Never drop without a status check first.** Run `status` before `drop` so the user sees what's being discarded.
4. **Agent worktrees are disposable by design.** Their whole point is isolation — expect to drop them.
5. **List before create.** Check existing worktrees to avoid duplicate branch names.
6. **Worktrees share the object store.** Changes to `.git/` config in one worktree affect all — avoid modifying git config in a worktree.
7. **Path convention is `../` relative.** Keep worktrees sibling to the main repo directory, not nested inside it.
