---
name: verify
description: "Verification gate before marking work complete. Checks code against requirements, runs tests, validates no regressions. From Superpowers pattern."
argument-hint: "[--requirements <list>] [--files <glob>] [--strict]"
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
A hard gate that runs BEFORE declaring any task complete. Prevents the common failure of "it works on my machine" or "I think I finished" without actually checking.

**This skill verifies:**
1. Requirements are actually met (not just "code was written")
2. Tests pass (not just "tests exist")
3. No regressions introduced
4. Domain rules from CLAUDE.md are respected
5. No temporary hacks or TODOs left behind

**When to use:**
- Before telling the user "done"
- Before committing
- As the final phase of `/workflow-gate`
- After any multi-file change

**Model routing:**
- Requirement checking → `sonnet` (structured verification)
- Regression analysis → `haiku` (test running, file scanning)
- Deep correctness → `opus` (only if `--strict`)
</objective>

<context>
**Arguments:**
- `--requirements <list>` — Comma-separated list of things that must be true. If omitted, infer from the conversation.
- `--files <glob>` — Scope verification to specific files. If omitted, check all modified files.
- `--strict` — Deploy an opus agent for deep correctness analysis beyond pattern matching.
</context>

## Verification Checklist

### 1. Requirements Check

Use a haiku agent to scan files for requirement markers (grep-level work). Only escalate to sonnet if the requirement involves logic verification (not just "does this line exist").

For each stated requirement:
- **Read the actual code** that implements it (don't trust conversation memory)
- Verify the implementation matches the requirement (not just "code exists in the right file")
- Mark as: ✅ MET / ❌ NOT MET / ⚠️ PARTIAL

```
### Requirements:
- [x] User can log in with email/password — verified at auth.ts:45
- [x] Invalid credentials return 401 — verified by test auth.test.ts:23
- [ ] Rate limiting on login attempts — NOT IMPLEMENTED
```

### 2. Test Verification

Run tests and verify:
```bash
# Run the project's test command
# Check: all tests pass, no skipped tests, no flaky warnings
```

Report:
```
### Tests:
- Total: <N> | Passing: <N> | Failing: <N> | Skipped: <N>
- New tests added: <N>
- Existing tests broken: <N> (regression!)
```

**Any failing test = verification FAILS.** No exceptions.

### 3. Domain Rules Check

**If /preload ran this session:** Use the domain rules from the session brief — do not re-read CLAUDE.md. This saves one full file read per /verify invocation.

Read CLAUDE.md domain rules and check modified files against each rule:

For each domain rule:
- Scan modified files for violations
- Report findings

```
### Domain Rules:
- [x] Rule 1 (Input Sanitization): All new inputs go through sanitizeInput()
- [x] Rule 2 (Schema Strictness): Zod schemas use .strict()
- [ ] Rule 3 (Auth Before Logic): auth.ts:89 — business logic runs before auth check ❌
```

### 4. Cleanliness Check

Scan for things that shouldn't be in completed code:

- `TODO`, `FIXME`, `HACK`, `XXX` comments in modified files
- `console.log`, `print()`, `debugger` statements in production code
- Commented-out code blocks
- Hardcoded secrets or credentials
- Temporary test data

```
### Cleanliness:
- TODOs found: 0 ✓
- Debug statements: 0 ✓
- Commented code: 1 block at utils.ts:34 ⚠️
- Hardcoded secrets: 0 ✓
```

### 5. Regression Check

Compare the current test suite results against what passed BEFORE the changes:

- Any previously-passing test now failing? → REGRESSION
- Any test that was removed? → Flag it (might be hiding a failure)

### 6. (Strict mode only) Deep Correctness

Deploy an `opus` agent:

```
Review these changes as if you're the last check before production deployment.
Assume the auto-checks passed. Look for things automation misses:

1. Logic correctness — Does the code actually do what it claims?
2. Concurrency issues — Race conditions, deadlocks, stale reads
3. Data integrity — Can this corrupt state? Missing transactions?
4. Error propagation — Do errors surface correctly to the user?
5. Security — Can this be exploited? Auth bypass? Data leak?
```

## Verdict

```
═══════════════════════════════════════
  VERIFICATION — <task/scope>
═══════════════════════════════════════
  Requirements:  <N/M> met
  Tests:         <PASS/FAIL> (<N> total, <N> new)
  Domain rules:  <N/M> compliant
  Cleanliness:   <CLEAN/issues>
  Regressions:   <NONE/list>
  Deep check:    <PASS/FAIL/SKIPPED> (strict mode)

  VERDICT: ✅ VERIFIED / ❌ BLOCKED (<reason>)
═══════════════════════════════════════
```

## Rules

1. **Verification reads code, not memory.** Always re-read files. Conversation context may be stale.
2. **Failing tests = automatic BLOCKED.** No override. Fix tests first.
3. **Regressions are highest priority.** A regression means the change broke existing functionality — fix before anything else.
4. **Domain rules are non-negotiable.** If CLAUDE.md says "tenant_id in every query" and it's missing, that's a BLOCK.
5. **TODOs are acceptable IF documented.** A TODO with a ticket number is fine. A bare "TODO: fix later" is not.
6. **This is the LAST step.** Don't run verify, find issues, fix them, and then NOT verify again. Every fix gets re-verified.
7. **Model routing:** Most checks use sonnet or haiku (pattern matching + test running). Only `--strict` escalates to opus.
8. **Report model usage.** Show which tier was used for each check.
9. **Haiku for grep-level checks.** Scanning for TODOs, hardcoded secrets, console.log statements, and unused imports is grep-level work — always use haiku. Only escalate to sonnet/opus for semantic analysis.
10. **Context reuse.** Domain rules loaded by /preload should not be re-read. Test results from recent runs should not be re-run if nothing has changed. Avoid redundant reads within the same session.
