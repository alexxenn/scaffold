---
name: tdd
description: "TDD iron law: write tests FIRST, then implement until they pass. Enforces red→green→refactor cycle. From Superpowers pattern."
argument-hint: "<feature-description> [--unit] [--integration] [--e2e] [--all]"
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
Enforce strict Test-Driven Development: write failing tests FIRST, then implement the minimum code to make them pass, then refactor.

**The iron law:** No implementation code is written until a failing test exists for it.

This skill:
1. Analyzes the feature requirements
2. Generates a test suite FIRST (tests that will fail because the code doesn't exist yet)
3. Runs tests to confirm they fail (RED phase)
4. Guides implementation until tests pass (GREEN phase)
5. Suggests refactoring opportunities (REFACTOR phase)

**Model routing:**
- Test case design → `sonnet` (structured, bounded)
- Implementation → `sonnet` (code generation)
- Refactoring analysis → `opus` (needs judgment about abstractions)
</objective>

<context>
**Arguments:**
- `<feature-description>` — What to build (e.g., "user authentication endpoint", "shopping cart total calculation")
- `--unit` — Generate only unit tests
- `--integration` — Generate only integration tests
- `--e2e` — Generate only end-to-end tests
- `--all` — Generate all test tiers (default)
</context>

## Phase 1: RED — Write Failing Tests

### Step 1: Analyze Requirements

From the feature description, extract:
- **Inputs**: What data does this feature accept?
- **Outputs**: What should it return/produce?
- **Side effects**: What state changes?
- **Edge cases**: Empty input, max values, invalid data, concurrent access
- **Error cases**: What should fail, and how?

### Step 2: Read Project Test Patterns

Before writing tests, check:
1. What test framework does the project use? (Jest, Vitest, pytest, cargo test, etc.)
2. What test utilities exist? (Custom renders, mock factories, test helpers)
3. What's the test file naming convention?
4. Where do tests live? (Co-located `__tests__/`, separate `tests/`, etc.)

Read CLAUDE.md for any test-specific domain rules.

### Step 3: Generate Test Suite

Write tests using the project's ACTUAL test utilities and patterns.

**Test hierarchy (when `--all`):**

**Unit tests** — Pure logic, no I/O:
```
describe('<Feature>')
  it('handles the happy path')
  it('handles empty input')
  it('handles max/boundary values')
  it('rejects invalid input with correct error')
  it('handles concurrent calls correctly')
```

**Integration tests** — With real dependencies:
```
describe('<Feature> integration')
  it('persists data correctly')
  it('respects auth/permissions')
  it('enforces domain rules (tenant isolation, etc.)')
  it('returns correct API response shape')
```

**E2E tests** — Full user flow:
```
describe('<Feature> e2e')
  it('completes the full user workflow')
  it('handles error states gracefully in UI')
```

### Step 4: Run Tests — Confirm RED

Run the test suite. ALL tests must FAIL (because the implementation doesn't exist).

```
RED PHASE: <N> tests written, <N> failing ✓
Expected failures:
- test_happy_path: ReferenceError — function not found ✓
- test_invalid_input: ReferenceError — function not found ✓
- ...
```

**If any test passes:** Something is wrong. Either:
- The feature already exists (read the codebase first)
- The test is testing the wrong thing (fix the test)

**Gate:** ALL tests must fail before proceeding to GREEN.

## Phase 2: GREEN — Implement Minimum Code

### Step 5: Implement One Test at a Time

For each failing test, write the MINIMUM code to make it pass:

1. Pick the simplest failing test
2. Write just enough code to pass it
3. Run the full suite — the targeted test should pass, others may still fail
4. Pick the next failing test
5. Repeat until all tests pass

**Critical rule:** Do NOT write "the full implementation" and then run tests. That's not TDD — that's test-after. Implement ONE behavior at a time.

```
GREEN PHASE progress:
- [x] test_happy_path — PASSING (implemented core function)
- [x] test_empty_input — PASSING (added empty check)
- [ ] test_invalid_input — FAILING (need validation)
- [ ] test_concurrent — FAILING (need locking)
```

### Step 6: Confirm GREEN

Run the full test suite. ALL tests must pass.

```
GREEN PHASE: <N> tests, <N> passing ✓
```

**Gate:** ALL tests must pass before proceeding to REFACTOR.

## Phase 3: REFACTOR — Clean Up

### Step 7: Analyze for Refactoring

Now that tests pass, look for:
- **Duplication** — same pattern repeated 2+ times
- **Naming** — are function/variable names clear?
- **Complexity** — any function doing too much?
- **Abstraction** — any obvious extraction opportunities?

**Critical rule:** Tests must STILL PASS after every refactoring step. If a refactor breaks a test, revert immediately.

```
REFACTOR PHASE:
- Extracted <function> from <location> — tests still pass ✓
- Renamed <old> to <new> for clarity — tests still pass ✓
- No further refactoring needed
```

## Output Summary

```
═══════════════════════════════════════
  TDD CYCLE COMPLETE — <feature>
═══════════════════════════════════════
  RED:      <N> tests written, all failed ✓
  GREEN:    <N> tests passing ✓
  REFACTOR: <N> improvements made ✓

  Tests:   <path to test files>
  Code:    <path to implementation files>
  Coverage: <if measurable>
═══════════════════════════════════════
```

## Rules

1. **Tests FIRST. Always.** No implementation before a failing test. This is the iron law — no exceptions.
2. **Minimum code per test.** Don't write the whole implementation at once. One test → one behavior → one pass.
3. **Tests must fail first.** If a test passes before implementation, the test is wrong or the feature exists.
4. **Refactoring never changes behavior.** Tests must pass before AND after every refactor step.
5. **Use project patterns.** Don't invent a new test framework. Use whatever the project already has.
6. **Edge cases are not optional.** Every TDD cycle must include: empty/null input, boundary values, error cases.
7. **3-failure escalation applies.** If 3 consecutive implementation attempts fail to pass a test, the test may be wrong. Re-examine the test before trying again.
8. **Model routing:** Test generation = sonnet. Implementation = sonnet. Refactoring analysis = opus (only if the refactor is non-trivial).
