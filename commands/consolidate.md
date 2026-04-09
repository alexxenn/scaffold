---
name: consolidate
description: "Learning pipeline — scans MISTAKE_LOG.md, promotes repeated failures (N≥2) to ANTI_PATTERNS.md, injects approved rules into CLAUDE.md critical tier. Run weekly or when /session-end flags consolidation ready."
argument-hint: "[project-name] [--all] [--auto-approve]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

<objective>
This is the episodic-to-semantic consolidation pipeline. It closes the learning loop:

  Session mistakes (episodic)
      ↓ [/consolidate]
  ANTI_PATTERNS.md (semantic)
      ↓ [on approval]
  CLAUDE.md critical tier (procedural = changes behavior)

Based on the Reflexion architecture (ICLR 2024): verbal self-critique from past failures, accumulated into persistent rules, results in measurably better performance (91% HumanEval pass@1 vs 80% baseline).

**When to run:**
- `/session-end` shows "CONSOLIDATION READY — N mistakes pending"
- Manually every 1-2 weeks per project
- Before starting a new phase (lock in lessons from last phase)

**Run for one project at a time.** Use `--all` to process all projects sequentially.
</objective>

<context>
**Arguments:**
- `[project-name]` — Project to consolidate. Detected from cwd if omitted.
- `--all` — Process all projects detected in the workspace sequentially.
- `--auto-approve` — Skip human approval step and directly inject approved rules. Use with caution.
</context>

## Process

### Step 1: Detect Project + Load Mistake Log

Resolve project name (same logic as `/start`).

Read `AI-Employee-Platform/05-anti-patterns/<project>/MISTAKE_LOG.md`.

If file doesn't exist:
```
No MISTAKE_LOG.md found for [project].
Create it? Run /vault-setup-project [project] first.
```

If file exists but empty / no unpromoted entries:
```
[project]: No mistakes pending promotion. Nothing to consolidate.
```

### Step 2: Parse + Group Failures

Extract all entries where `**Promoted to ANTI_PATTERNS:** No`.

For each entry, extract:
- Failure category (infer from "What failed" + "Why it failed")
- Draft rule (from "Rule to add" field)
- Date

Group by failure category. Common categories:
- `security/credentials` — secrets, credential handling
- `security/tenant-isolation` — missing tenant_id, cross-tenant data
- `api/error-handling` — wrong error types, unwrap(), exposed internals
- `deps/features` — wrong cargo features, missing default-features=false
- `schema/validation` — missing .strict(), unknown fields accepted
- `database/rls` — missing RLS policies, wrong policy form
- `testing/coverage` — missing security tests, false positives
- `architecture/pattern` — wrong pattern for the context
- `workflow/git` — wrong branch, uncommitted work
- `other` — anything that doesn't fit above

### Step 3: Apply Promotion Threshold

For each category group:

- **Count ≥ 2** in same category → **PROMOTE** (pattern, not coincidence)
- **Count = 1** → **WATCH** (note it but don't promote yet)
- **Count = 1 BUT rule is marked high-confidence** → promote anyway

Also promote any single entry where the mistake took >30 minutes to resolve (usually indicates the rule was non-obvious and worth encoding).

### Step 4: Generate Promotion Diff

For each PROMOTE group, draft:

**ANTI_PATTERNS.md entry:**
```markdown
### AP-[NNN] — [category]: [short rule title] ([project])
**Derived from:** [N] incidents ([date1], [date2], ...)
**Rule:** [One concrete "NEVER do X" or "ALWAYS do Y" statement]
**Why:** [Why this matters — consequence of getting it wrong]
**Confidence:** [Low | Medium | High]
**Injected into CLAUDE.md:** No — pending approval
```

**Proposed CLAUDE.md critical tier addition:**
```
• [one-line rule distilled from AP entry — fits in NEVER list]
```

Output ALL proposed promotions as a diff for human review:

```
CONSOLIDATION DIFF — [project]
════════════════════════════════════════

[N] mistakes processed → [M] promotions proposed

PROMOTE (N≥2 occurrences):

  AP-001 — security/credentials: VaultSecret<T> for all secrets
  ──────────────────────────────────────────────────────────────
  Derived from: 3 incidents (2026-03-15, 2026-03-22, 2026-04-03)
  Rule: NEVER use bare String for credentials. Always VaultSecret<T>.
  Why: Bare String allows accidental Debug printing and lacks zero-copy
       protection. Hit 3 times, each costing 15-30min to diagnose.
  Confidence: High
  → Proposed CLAUDE.md addition: "• NEVER bare String for credentials — VaultSecret<T> only"

  AP-002 — schema/validation: Zod .strict() on all schemas
  ──────────────────────────────────────────────────────────────
  Derived from: 2 incidents (2026-04-01, 2026-04-02)
  Rule: ALWAYS add .strict() to Zod schemas to reject unknown fields.
  Why: Without .strict(), extra fields pass silently — injection surface.
  Confidence: High
  → Proposed CLAUDE.md addition: "• ALWAYS .strict() on Zod schemas — no unknown fields"

WATCH (1 occurrence, not yet promoted):

  [date] — api/error-handling: exposed internal error in API response
  Rule: Don't expose DB errors directly. Wrap in opaque ApiError.
  Status: 1 occurrence. Will promote on next recurrence.

════════════════════════════════════════
Approve ALL promotions? (y/n/selective)
Or: approve specific ones by entering AP numbers (e.g., "001 002")
```

### Step 5: Apply Approved Promotions

After user approves (or `--auto-approve` flag):

**5a. Write to ANTI_PATTERNS.md:**

Read `AI-Employee-Platform/05-anti-patterns/<project>.md` (create if doesn't exist).
Append each approved AP entry.

File structure:
```markdown
# Anti-Patterns — [Project]

> Consolidated from MISTAKE_LOG.md. Injected into CLAUDE.md critical tier.
> Last consolidation: [date]

### AP-001 — ...
### AP-002 — ...
```

**5b. Inject into CLAUDE.md critical tier:**

Read project's CLAUDE.md.
Find the `## CRITICAL` section (or create it at the top if doesn't exist).
Append each approved rule to the NEVER list.

```markdown
## CRITICAL — Always loaded
<!-- Auto-injected by /consolidate -->
- NEVER bare String for credentials — VaultSecret<T> only
- ALWAYS .strict() on Zod schemas — no unknown fields
[existing rules]
```

**5c. Mark as promoted in MISTAKE_LOG.md:**

For each promoted entry, update:
`**Promoted to ANTI_PATTERNS:** No` → `**Promoted to ANTI_PATTERNS:** Yes — [date] (AP-NNN)`

**5d. Update CONSOLIDATION_LOG.md:**

Append entry:
```markdown
## [date] — [project]
- Processed: [N] mistakes
- Promoted: [M] to ANTI_PATTERNS
- Injected: [M] rules into CLAUDE.md critical tier
- AP IDs: AP-NNN, AP-NNN, ...
```

### Step 6: Output Summary

```
CONSOLIDATION COMPLETE — [project]
────────────────────────────────────
Mistakes processed:  [N]
Rules promoted:      [M]
CLAUDE.md updated:   ✓ ([M] rules added to critical tier)
ANTI_PATTERNS.md:    ✓ ([M] entries appended)

New NEVER rules active in next session:
  • [rule 1]
  • [rule 2]

Run /start [project] to load updated rules.
────────────────────────────────────
```

## Rules

1. **N≥2 threshold is the default.** One mistake = coincidence. Two = pattern. Override with `--auto-approve` only for obvious critical security rules.
2. **Human approval required by default.** Never inject rules into CLAUDE.md without showing the diff first. Rules shape all future behavior.
3. **Rules must be concrete.** "NEVER bare String for credentials" is concrete. "Be careful with secrets" is not. If you can't write a concrete rule, don't promote.
4. **Mark promoted entries in MISTAKE_LOG.md.** Never delete them — they're the episodic source of truth.
5. **CLAUDE.md critical tier only.** Don't inject into the project context or reference sections. Rules go in critical tier so they're always loaded.
6. **AP numbering is sequential per project.** AP-001, AP-002, etc. Check existing ANTI_PATTERNS.md for highest number before assigning.
7. **Consolidate per project, not globally.** Rules are project-specific. A Rust rule doesn't belong in a Next.js project's CLAUDE.md.
8. **One CLAUDE.md line per rule.** Keep injected rules under 80 characters. Long rules don't get remembered.
9. **Confidence level matters.** High confidence → inject immediately. Medium → inject with a note. Low → promote to ANTI_PATTERNS but don't inject to CLAUDE.md yet.
10. **Run before each new phase.** Phase boundaries are natural consolidation points — lock in lessons before starting new work.
