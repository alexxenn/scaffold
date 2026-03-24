---
name: review
description: "Two-stage code review: fast auto-review (sonnet) catches patterns, deep review (opus) catches architecture/security issues."
argument-hint: "[<file-or-glob>] [--deep-only] [--auto-only] [--security] [--diff]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

<objective>
Two-stage code review inspired by Superpowers' subagent-driven review pattern.

**Stage 1: Auto-Review (Sonnet)** — Fast pattern-matching pass:
- Convention violations
- Obvious bugs (null refs, off-by-one, missing error handling)
- Style/formatting issues
- Missing tests
- Domain rule violations (from CLAUDE.md)

**Stage 2: Deep Review (Opus)** — Architecture & security pass:
- Design pattern correctness
- Security vulnerabilities (OWASP top 10)
- Performance implications
- API contract compliance
- Cross-cutting concern violations (auth, logging, tenant isolation)

Running both stages on everything is wasteful. The auto-review filters — only files with issues get deep-reviewed.

**Model routing:** Stage 1 = sonnet ($), Stage 2 = opus ($$$). Only ~20-30% of files typically need Stage 2.
</objective>

<context>
**Arguments:**
- `<file-or-glob>` — What to review. File path, glob pattern, or omit for staged git changes.
- `--deep-only` — Skip auto-review, go straight to Opus deep review.
- `--auto-only` — Only run the fast Sonnet pass (for quick checks).
- `--security` — Focus deep review specifically on security concerns.
- `--diff` — Review only the diff (staged + unstaged changes), not full files.
</context>

## Stage 1: Auto-Review (Sonnet)

Spawn a `sonnet` agent per file (or group of small files) with the following prompt:

```
Review this code for:
1. Convention violations against these project rules: <CLAUDE.md domain rules>
2. Obvious bugs: null/undefined access, off-by-one, unhandled errors, race conditions
3. Missing error handling at system boundaries
4. Dead code, unused imports, unreachable branches
5. Missing or inadequate test coverage
6. Hardcoded secrets, credentials, or API keys
7. Console.log / debug statements left in production code

For each issue found, report:
- File and line number
- Severity: 🔴 critical / 🟡 warning / 🔵 info
- What's wrong (one line)
- Suggested fix (one line)

If the file looks clean, say "CLEAN" and nothing else.
```

**Parallel dispatch:** Up to 5 sonnet agents in parallel for large changesets.

**Output:**
```
## Auto-Review Results

### <file1.ts>: 2 issues
🟡 L47: Missing null check on `user.profile` — add optional chaining
🔵 L12: Unused import `formatDate` — remove

### <file2.ts>: CLEAN

### <file3.ts>: 1 issue
🔴 L89: SQL query built with string concatenation — use parameterized query

### Summary: 3 issues across 3 files (1 critical, 1 warning, 1 info)
### Files needing deep review: file1.ts, file3.ts
```

## Stage 2: Deep Review (Opus)

Only runs on files flagged by Stage 1 (or all files if `--deep-only`).

Spawn an `opus` agent with the flagged files + full project context:

```
You are a senior engineer conducting a deep code review. You have the auto-review findings below.
Go DEEPER than pattern matching. Analyze:

1. **Architecture fit** — Does this code follow the project's established patterns? Does it belong in this location? Are abstractions at the right level?

2. **Security** — OWASP top 10 check. Auth bypass paths. Data exposure. Injection vectors. Session/token handling. If the project has domain rules about security (tenant isolation, credential handling), verify compliance.

3. **Performance** — N+1 queries, unnecessary re-renders, missing indexes, unbounded loops, memory leaks, missing pagination.

4. **API contract** — If this touches an API: request/response schema correctness, error codes, backward compatibility, rate limiting.

5. **Cross-cutting concerns** — Logging, monitoring, error propagation, transaction boundaries, cache invalidation.

6. **Edge cases** — What happens with empty input? Max-length input? Concurrent access? Network failure?

Auto-review already found: <Stage 1 findings>
Project rules: <CLAUDE.md domain rules>
```

**Output:**
```
## Deep Review: <files>

### Architecture
- <finding or "Patterns followed correctly">

### Security
- <finding or "No vulnerabilities found">

### Performance
- <finding or "No performance concerns">

### Edge Cases
- <finding or "Edge cases handled">

### Verdict: APPROVE / REQUEST CHANGES / BLOCK

### Required changes (if any):
1. <change 1 — must fix before merge>
2. <change 2 — must fix before merge>

### Suggested improvements (optional):
1. <improvement — nice to have>
```

## Combined Output

```
═══════════════════════════════════════
  CODE REVIEW — <scope>
  Stage 1: <N> files scanned (sonnet)
  Stage 2: <M> files deep-reviewed (opus)
═══════════════════════════════════════

  AUTO-REVIEW: <N> issues (X critical, Y warning, Z info)
  DEEP REVIEW: <verdict>

  REQUIRED CHANGES:
  1. <change>
  2. <change>

  Model routing: <N> sonnet + <M> opus agents
  Estimated savings vs all-opus: ~<X>%
═══════════════════════════════════════
```

## Rules

1. **Stage 1 always runs first** (unless `--deep-only`). It's the filter that saves opus tokens.
2. **Stage 2 only on flagged files** + files touching auth/security/data-layer (these always get deep review regardless of Stage 1 results).
3. **Critical findings block.** 🔴 issues must be fixed — don't just list them and move on.
4. **Domain rules from CLAUDE.md are fed to BOTH stages.** Project-specific rules are the primary checklist.
5. **Security flag escalates.** `--security` makes Stage 2 focus exclusively on security with extra scrutiny.
6. **Diff mode is default for pre-commit.** When reviewing before a commit, `--diff` avoids reviewing unchanged code.
7. **Report model routing.** Always show how many agents of each tier were used so the user sees the cost savings.
8. **Don't auto-fix.** Review is read-only. List the issues — let the user or another skill fix them.
