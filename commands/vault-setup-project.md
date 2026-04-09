---
name: vault-setup-project
description: "Bootstrap any project into the federated vault architecture — restructures CLAUDE.md into 3-tier format, creates mistake tracking, sets up session logs, audits security settings."
argument-hint: "<project-name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

<objective>
One-command migration for any active project to the federated vault architecture:

  BEFORE: monolithic CLAUDE.md + manual session logs + no mistake tracking + security gaps
  AFTER:  3-tier CLAUDE.md + automated session logs + MISTAKE_LOG.md + security audit report

Run once per project. Non-destructive — rewrites CLAUDE.md in-place, creates new files, never deletes anything.

This is the "apply the vault architecture to a real project" command.
</objective>

<context>
**Arguments:**
- `<project-name>` — Required. Any project folder name.
</context>

## Process

### Step 1: Resolve Project Paths

Map project name to all relevant paths:

```
Project root:   <project-root>/<project>\
CLAUDE.md:      <project root>\CLAUDE.md
Rules dir:      <project root>\.claude\rules\
Memory file:    ~/.claude/projects/.../memory/<project>_current_status.md
Session log:    AI-Employee-Platform\07-session-logs\SESSION_LOG.md (or project-specific)
Anti-patterns:  AI-Employee-Platform\05-anti-patterns\<project>\
Vault home:     <project-root>/AI-Employee-Platform\
```

Verify the project root exists. If not → error and exit.

### Step 2: Audit Current CLAUDE.md

Read the project's existing CLAUDE.md.

Classify every line/section into one of:
- **CRITICAL** — security rules, NEVER constraints, non-negotiable patterns (goes in tier 1)
- **PROJECT** — current phase, skill routing, project description (goes in tier 2)
- **REFERENCE** — links to vault docs, architecture decisions, external references (goes in tier 3 as @imports)
- **FLUFF** — vague instructions ("write clean code"), duplicated README content, prose explanations without rules (remove)

Output the classification:
```
CLAUDE.md AUDIT — [project]
────────────────────────────
Total lines: [N]
CRITICAL:   [N] lines → keep in tier 1
PROJECT:    [N] lines → keep in tier 2
REFERENCE:  [N] lines → convert to @imports in tier 3
FLUFF:      [N] lines → remove

Token count (current): ~[N] tokens
Token count (after):   ~[N] tokens (target: <150 critical, <300 total)
```

### Step 3: Rewrite CLAUDE.md into 3-Tier Format

Rewrite the file with this structure:

```markdown
# [Project Name] — Claude Instructions

## CRITICAL — Always loaded (<150 tokens)
<!-- Non-negotiable rules. Auto-injected by /consolidate. -->
[NEVER rules from classification]
[Security constraints from classification]
[Hard patterns: VaultSecret<T>, tenant_id, .strict(), etc.]

## Session Start Protocol
At the start of every fresh conversation:
1. Run `/start [project-name]`

At the end of every session:
1. Run `/session-end [project-name]`

## Project Context
[2-3 sentence project description]
**Current phase:** [phase from existing CLAUDE.md or status memory]
**Stack:** [tech stack — one line]

## Skill Routing
[Keep only THIS project's relevant skills — remove cross-project noise]
| Task | Skill |
|------|-------|
...

## Reference (load on demand via @import)
<!-- @import AI-Employee-Platform/05-anti-patterns/[project].md -->
<!-- @import AI-Employee-Platform/02-architecture/ARCHITECTURE_DECISIONS_LOG.md -->
```

Show the rewritten CLAUDE.md for review before writing.

Ask: "Write this CLAUDE.md? (y/n)"

On approval: write the file.

### Step 4: Create .claude/rules/ Structure

Create path-scoped rule files if the project has multiple domains:

**EXAMPLES — adapt to your project's stack and domain:**

**Rust project example:**
```
.claude/rules/security.md     → Secret wrappers, tenant isolation, no unwrap (no path scope = always loaded)
.claude/rules/testing.md      → Property tests, compile-fail tests, test flags (scope: tests/)
.claude/rules/api.md          → API framework patterns, error mapping, auth middleware (scope: src/api/)
```

**Web project example (Next.js + Supabase):**
```
.claude/rules/security.md     → RLS, auth-before-logic, no PII in logs (no path scope)
.claude/rules/database.md     → DB patterns, migration structure (scope: supabase/)
.claude/rules/components.md   → Design system patterns, Server/Client Component rules (scope: src/components/)
```

**Python API example (FastAPI):**
```
.claude/rules/security.md     → Auth, data protection, no secrets in logs (no path scope)
.claude/rules/api.md          → FastAPI patterns, auth, rate limiting (scope: backend/)
```

Only create files that have content. Don't create empty rule files.

Each rule file format:
```markdown
---
description: "[what these rules govern]"
globs: ["path/pattern/**"] # omit for always-load
---

[rules content — concise, NEVER/ALWAYS format]
```

### Step 5: Create Anti-Patterns Directory

Create if it doesn't exist:
```
AI-Employee-Platform/05-anti-patterns/<project>/
  MISTAKE_LOG.md
  ANTI_PATTERNS.md (empty, ready for /consolidate)
```

MISTAKE_LOG.md initial content:
```markdown
# Mistake Log — [Project]

> Episodic failure record. Promoted to ANTI_PATTERNS.md by /consolidate when N≥2 same category.
> Format: ## [date] — [project] — [description]

<!-- Add entries during /session-end or manually after resolving a mistake -->
```

ANTI_PATTERNS.md initial content:
```markdown
# Anti-Patterns — [Project]

> Distilled from MISTAKE_LOG.md. Injected into CLAUDE.md critical tier by /consolidate.
> Counter-pattern reference: what we learned NOT to do.

<!-- Populated by /consolidate -->
```

Also create `CONSOLIDATION_LOG.md`:
```markdown
# Consolidation Log — [Project]

> Tracks when /consolidate ran and what was promoted.
<!-- Appended by /consolidate -->
```

### Step 6: Create/Update Obsidian Session Log Structure

Check if `AI-Employee-Platform/07-session-logs/SESSION_LOG.md` exists.

If it exists: add a dated entry noting that `/vault-setup-project` was run.

If it doesn't exist: create it with the correct format:
```markdown
# Session Log — [Project]

#sessions #[project-tag]

---

## Back to [[HOME]]

---

## [YYYY-MM-DD] — Vault Setup

**What happened:**
- Ran /vault-setup-project — migrated to federated vault architecture
- CLAUDE.md restructured into 3-tier format
- Anti-patterns tracking initialized
- Security settings audited

**Next:** First working session with new structure — run /start [project]

---
```

### Step 7: Security Audit

Check the following — report findings, don't auto-fix:

**Global settings (`~/.claude/settings.json`):**
- `skipDangerousModePermissionPrompt: true` → CRITICAL if present
- Check for suspicious wildcard MCP server permissions

**Project settings (`.claude/settings.local.json`):**
- `Bash(curl:*)` → HIGH: unrestricted network requests. Replace with specific domains.
- `Bash(python3:*)` → HIGH: arbitrary code execution. Scope to specific scripts.
- `Bash(wsl:*)` → HIGH: arbitrary WSL execution. Scope to specific commands.
- `Bash(cd:*)` → MEDIUM: can change to parent directories. Check if needed.
- Wildcards on file operations → review each one

**Output:**
```
SECURITY AUDIT — [project]
────────────────────────────────────────
[CRITICAL] ~/.claude/settings.json: skipDangerousModePermissionPrompt=true
           → Fix: set to false immediately

[HIGH] settings.local.json: Bash(curl:*) — unrestricted network
       → Fix: replace with specific URLs or domain patterns

[HIGH] settings.local.json: Bash(python3:*) — arbitrary code execution
       → Replace with: Bash(python3 scripts/specific-script.py)

[OK] CLAUDE.md: no credentials detected
[OK] No .env files found in project root

Manual review recommended for [N] remaining wildcard permissions.
────────────────────────────────────────
Run /security-harden [project] for automated fix suggestions.
```

### Step 8: Update MEMORY.md Index

Read `~/.claude/projects/.../memory/MEMORY.md`.

Add or update the project's entry:
```markdown
- [<project>_current_status.md](<project>_current_status.md) — [Project]: phase, current task, vault-setup complete
```

### Step 9: Output Setup Summary

```
╔══════════════════════════════════════════════╗
║  VAULT SETUP COMPLETE — [project]            ║
╚══════════════════════════════════════════════╝

✓ CLAUDE.md restructured → 3-tier format ([N] tokens, was [N])
✓ .claude/rules/ created → [N] path-scoped rule files
✓ Anti-patterns structure created
  → AI-Employee-Platform/05-anti-patterns/[project]/
     MISTAKE_LOG.md, ANTI_PATTERNS.md, CONSOLIDATION_LOG.md
✓ Session log initialized
✓ MEMORY.md index updated

SECURITY FINDINGS:
  [summary of any critical/high findings]

NEXT STEPS:
  1. [Fix any CRITICAL security findings]
  2. Run: /start [project]
  3. During sessions: use /session-end to close
  4. Weekly: run /consolidate [project]

╔══════════════════════════════════════════════╗
║  Session start from now on: /start [project] ║
╚══════════════════════════════════════════════╝
```

## Rules

1. **Non-destructive.** Never delete existing content. CLAUDE.md is rewritten in-place after approval. Session logs are appended to, not replaced.
2. **Show diffs before writing.** Always show the proposed CLAUDE.md rewrite and wait for approval before writing.
3. **Security audit is report-only.** Don't auto-fix security settings. Report findings, explain risk, let the user decide.
4. **3-tier format is mandatory.** Every project CLAUDE.md must have CRITICAL / Session Protocol / Project Context / Reference sections.
5. **Rule files only if they have content.** Don't create empty .claude/rules/ files. Quality over structure.
6. **Project-scoped rules only.** Don't copy rules from other projects. Project-scoped rules stay in their project.
7. **Verify paths before creating.** Check that parent directories exist before writing new files.
8. **Token count everything.** Report before/after token counts for CLAUDE.md. Target: critical tier <150 tokens.
9. **Update MEMORY.md last.** Only update the index after all files are written successfully.
10. **One project per run.** Don't process multiple projects in one invocation. Use --all if you want sequential processing.
