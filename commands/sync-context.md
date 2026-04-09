---
name: sync-context
description: "Loop-compatible context refresh — re-reads memory, decisions, preferences, and injects active enforcement rules into conversation. Use with /loop 15m /sync-context"
argument-hint: "[--project <name>]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - mcp__mem0__search-memories
  - mcp__obsidian-semantic__vault
---

<objective>
Lightweight context refresh designed to run on a loop during long work sessions. Prevents preference drift, forgotten decisions, and stale context.

**Use with:** `/loop 15m /sync-context`

This is NOT a full preload — it's a quick checkpoint that:
1. Re-reads the active status and preferences in parallel
2. Queries Mem0 for recent semantic session memories
3. Checks if any relevant decisions apply to current work (via Obsidian semantic search)
4. Scans for rule violations
5. **Injects active enforcement rules into the conversation** — not just a passive report
6. Reports session health

Designed to be fast (~10 seconds) and actively corrective, not just observational.
</objective>

<context>
**Arguments:**
- `--project <name>` — Focus on specific project. If omitted, detect from directory or last-loaded project.
</context>

## Process

### Step 0: Session Cache Check

Before reading anything, check if CLAUDE.md domain rules were already loaded this session:
- If `/preload` or a prior `/sync-context` was run this session: **skip Step 3 (CLAUDE.md read)**. Use the cached rules list already in context. Only re-read if the session is fresh.
- This saves ~800 tokens per sync iteration on CLAUDE.md alone.

### Step 0.5: Project Path Resolution

Resolve the active project to its unified vault path. Use this mapping for ALL vault reads:

| Project slug | Vault path | Session log path |
|---|---|---|
| `my-project` | `AI-Employee-Platform/MyProject/` | `AI-Employee-Platform/MyProject/07-session-logs/SESSION_LOG.md` |
| `my-api` | `AI-Employee-Platform/MyApi/` | `AI-Employee-Platform/MyApi/07-session-logs/SESSION_LOG.md` |

(Add your own projects following this pattern. Projects without a subfolder use `AI-Employee-Platform/07-session-logs/SESSION_LOG.md` directly.)

**Never use old local `*-KB/` paths.** Always resolve through this table.

### Step 1: Parallel Read + Mem0 Recall (4 simultaneous agents)

Dispatch ALL FOUR at the same time — do not read sequentially:

- **Agent A**: Read active status file (`<project>_current_status.md`). Extract: current task, next action, blockers.
- **Agent B**: Read `feedback_communication.md`. Extract: communication rules as a flat list.
- **Agent C**: (Skip if session cache hit from Step 0) Read CLAUDE.md domain rules section ONLY — numbered rules list + communication style block.
- **Agent D (Mem0)**: Call `mcp__mem0__search-memories` with:
  - `query`: "current status and recent work on {project_name}"
  - `userId`: "{{USER_ID}}"
  - Extract: any recent session memories, decisions, or context not yet in the status file. This catches context saved by `/session-end` that may not have been written to the status `.md` yet.

Wait for all four to complete, then aggregate. Total read time = slowest single agent, not sum of all four.

### Step 2: Targeted Decision Recall (Obsidian Semantic Search)

Use the **current task** from Agent A's output (not a conversation scan) to look up relevant decisions.

**Primary method — Obsidian semantic search:**
1. Take the current task name/description from the status file
2. Call `mcp__obsidian-semantic__vault` with `action: "search"` and query: the current task description + "architecture decision"
   - Scope search to the project's vault path from Step 0.5 (e.g., `AI-Employee-Platform/<Project>/02-architecture/`)
3. If semantic results found: extract the relevant decision block(s)
4. If no results: skip. Zero token cost.

**Fallback — direct file read:**
If the Obsidian semantic MCP is unavailable, fall back to the old method:
1. Match keywords against decision titles in `ARCHITECTURE_DECISIONS_LOG.md` (section headers only)
2. If match found: read that specific decision block only

This replaces "scan last few messages" — the status file already knows what we're doing. Semantic search finds relevant decisions even when keywords don't exactly match.

### Step 3: Drift Detection

Check for violations of the active rules. Scan recent code/conversation context for:

**Rust projects (example violations):**
- `unwrap()` outside tests → VIOLATION
- Bare `String` where a secrets wrapper should be used → VIOLATION
- DB query missing tenant/scope filter → VIOLATION
- `#[derive(Debug)]` on types that touch secrets → VIOLATION

**Next.js/Supabase projects:**
- Supabase query without RLS context → VIOLATION
- `console.log` in production code → VIOLATION
- Hardcoded API keys or secrets → VIOLATION

**Any project:**
- Responses getting verbose/explanatory when user wants terse/direct → DRIFT
- Basic advice given when user wanted advanced analysis → DRIFT
- Domain rules from CLAUDE.md not followed → VIOLATION

### Step 4: Active Rule Injection

**This is the critical step that the old version skipped.**

Regardless of whether violations were found, end EVERY sync with an explicit active rules block that **stays visible in the conversation**. This keeps rules in Claude's active context window, not just a file it read once.

Format when CLEAN:

```
──── SYNC @ <HH:MM> ────────────────────────────
Phase: <current task from status file>
Drift: Clean
Health: <OK or warning>

ACTIVE RULES (re-anchored):
  • <Rule 1 — one line>
  • <Rule 2 — one line>
  • <Rule 3 — one line>
  [all domain rules for this project]

Communication: Advanced/direct — lead with action, no fluff, no basic explanations
─────────────────────────────────────────────────
```

Format when VIOLATIONS FOUND:

```
──── SYNC @ <HH:MM> ────────────────────────────
Phase: <current task>
Health: <OK or warning>

🚫 ACTIVE VIOLATIONS — FIX BEFORE CONTINUING:
  ► [Rust Rule 6] unwrap() at src/tenant.rs:47 — use `?` or `.expect("reason")`
  ► [Rust Rule 1] `api_key: String` in types.rs:23 — must be `VaultSecret<String>`

ACTIVE RULES (re-anchored):
  • Secrets: VaultSecret<T>, no bare String, no Debug derive on secret types
  • Tenant isolation: every DB query needs WHERE tenant_id = $N
  • Errors: thiserror, no internal details in API responses
  • Deps: default-features = false, cargo audit after add
  • No unwrap() outside tests
  • Auth before logic — always
  [+ any project-specific rules]

Communication: Advanced/direct — lead with action, no fluff
─────────────────────────────────────────────────
```

**Violations are not suggestions.** They are listed as blocking items above the ACTIVE RULES block. Claude must address them before continuing with the current task.

### Step 5: Session Health Check

Quick checks (append to output):
- Uncommitted changes that should be committed?
- Session log not updated in >2 hours?
- Pending TODOs from this session not done?
- Status file stale (>3 hours since update during active coding)?

If health issues exist, add a `⚠ Health:` line. If clean, one line: `Health: OK`.

## Rules

1. **Parallel reads always.** Never read the 4 sources sequentially. Dispatch simultaneously (files + Mem0).
2. **Session cache for CLAUDE.md.** Don't re-read it every 15 minutes. Once per session is enough.
3. **Active rules block is mandatory.** Every sync must end with the ACTIVE RULES block. This is what keeps enforcement alive between preloads — without it, rules fade after the first few turns.
4. **Violations are blocking.** Don't list a violation and move on. Surface it as blocking. Claude should not continue the current task until violations are addressed.
5. **Decision recall uses status file, not message scan.** Match current task keywords against decision titles. Don't scan backwards through conversation.
6. **Fast and quiet when clean.** No violations = compact output. ACTIVE RULES block stays but is concise.
7. **Loud when drifting.** Violations get their own section above the rules block, in bold, with file:line specifics.
8. **Never modify files.** Read-only. Flag violations, don't auto-fix.
9. **No repeated unfixed violations.** If the same violation was flagged last sync and still not fixed, escalate: add `(escalated — not fixed since <time>)` suffix.
10. **Multi-project aware.** Detect project from directory or `--project` arg. Load the right rules.
11. **Unified vault paths only.** Never reference old local `*-KB/` paths. Always use `AI-Employee-Platform/{project}/` from the mapping table.
12. **MCP graceful degradation.** If `mcp__mem0__search-memories` or `mcp__obsidian-semantic__vault` are unavailable, fall back to direct file reads silently. Never fail the sync because an MCP is down.

## Model routing

- All 4 parallel reads (files + Mem0): haiku (fast, no reasoning needed)
- Obsidian semantic search: haiku (MCP handles the embedding lookup)
- Drift detection: sonnet (needs to reason about code patterns)
- Output formatting: sonnet
- No opus needed for sync — this is pattern matching, not design decisions
