---
name: start
description: "Fresh-conversation startup — loads minimum viable context to resume work immediately. Run this first in every new Claude Code session."
argument-hint: "[project-name]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - mcp__mem0__search-memories
  - mcp__obsidian-semantic__vault
---

<objective>
Boot a fresh Claude Code session into productive work in under 30 seconds and under 2K tokens.

This is NOT `/preload` — it's leaner and faster. It loads exactly what you need to pick up where you left off:
- What project + phase
- What the last session did
- What the current task is
- Which anti-patterns to watch for
- The non-negotiable rules (NEVER list)

Run this at the START of every new conversation. Nothing else needed before you start working.

**Model routing:** All reads via haiku (parallel). Output formatted by main context. No opus/sonnet needed.
</objective>

<context>
**Arguments:**
- `[project-name]` — Optional. If omitted, detected from cwd. Valid values: any project folder name detected from cwd or CLAUDE.md.
</context>

## Process

### Step 1: Detect Project

If argument provided → use it directly.

If no argument:
1. Check cwd path for known project names: `known project names from memory or CLAUDE.md`
2. If match → use that project
3. If cwd is parent `your-workspace` → list available projects and ask which one
4. If in an unknown directory → ask user

Map project name to paths:
```
my-project         → memory: my_project_current_status.md
                   → session log: AI-Employee-Platform/<project>/07-session-logs/SESSION_LOG.md
                   → anti-patterns: AI-Employee-Platform/05-anti-patterns/my-project.md (if exists)

my-api             → memory: my_api_current_status.md
                   → session log: AI-Employee-Platform/MyApi/07-session-logs/SESSION_LOG.md
                   → anti-patterns: AI-Employee-Platform/05-anti-patterns/my-api.md (if exists)

(Add your own projects following the same pattern: slug → memory file, session log path, anti-patterns path)

```

### Step 1.5: MCP Context Recall (parallel, graceful degradation)

Run these MCP calls IN PARALLEL with each other. Both are optional — if either MCP server is unavailable (Obsidian not running, Mem0 offline), skip silently and proceed to Step 2 file-based reads.

**Mem0 Recall:**
- Tool: `mcp__mem0__search-memories`
- Parameters: `query = "latest session status and recent work on {project_name}"`, `userId = "{{USER_ID}}"`
- Extract: any context saved by `/session-end` that may be more recent than the file-based status memory

**Obsidian Semantic Search:**
- Tool: `mcp__obsidian-semantic__vault`
- Parameters: `action = "search"`, `query = "latest session {project_name}"`
- Then if the project has a session log path: `action = "read"`, target the session log file
- Extract: richer session context, related vault notes

**Merge strategy:** MCP results supplement file reads. If Mem0 returns more recent context than the status memory file, prefer Mem0. If Obsidian semantic returns richer session log content, use it. Never let MCP failures block startup.

### Step 2: Parallel File Read (3 haiku agents simultaneously)

Dispatch ALL THREE at the same time — never sequential. These are the **fallback/baseline** reads. MCP results from Step 1.5 (if available) supplement these.

**Agent A — Status:** Read `.claude/projects/.../memory/<project>_current_status.md`
Extract:
- Current phase (1 line)
- Last session summary (2-3 bullets max)
- Current task (1 line)
- Next immediate step (file path if available)
- If Mem0 returned more recent data → merge/override with Mem0 context

**Agent B — Session Log:** Read the latest entry from the project's SESSION_LOG.md (last 15 lines only)
Extract:
- Date of last session
- What changed (bullet points)
- Any decisions made
- If Obsidian semantic returned richer content → supplement with semantic results

**Agent C — Anti-Patterns:** Read `AI-Employee-Platform/05-anti-patterns/<project>.md` if it exists.
Extract: top 5 most recent anti-patterns (ID + one-line rule)
If file doesn't exist: return empty — don't create it.

Wait for all three. Total time = slowest agent, not sum.

### Step 3: Load NEVER Rules

Read the project's CLAUDE.md — critical tier only (first 30 lines or first ## section).
Extract: all NEVER rules and hard security constraints.

If no CLAUDE.md in cwd → read `~/.claude/projects/.../memory/MEMORY.md` for the project's domain rules section.

### Step 4: Output Execution Brief

Format:

```
╔══════════════════════════════════════════════╗
║  [PROJECT NAME] — [Phase + Week/Sprint]      ║
║  Last session: [date]                        ║
╚══════════════════════════════════════════════╝

LAST SESSION:
• [bullet 1 from session log]
• [bullet 2]
• [bullet 3 if relevant]

NOW: [current task — one line]
→ [file path or starting point if known]

[Only show WATCH OUT block if anti-patterns exist:]
WATCH OUT:
• [AP-ID] [one-line rule]
• [AP-ID] [one-line rule]

NEVER:
• [NEVER rule 1]
• [NEVER rule 2]
• [NEVER rule 3]
[max 5 — most critical only]

Ready. What are we doing?
```

**Token budget:** Entire output must be under 800 tokens. If context is getting long, cut WATCH OUT to 2 items and NEVER to 3.

### Step 5: Security Check (passive)

While outputting, silently check:
- Is cwd the parent `your-workspace/` directory? If yes, add warning: `⚠ Run from project subdirectory: cd [project] && claude`
- Is there a MISTAKE_LOG.md with unreviewed entries (>5 entries since last consolidation)? If yes, add: `💡 Run /consolidate — enough mistakes to distill rules`

## Rules

1. **Under 800 tokens output.** This is a startup signal, not a briefing document. Short.
2. **Parallel reads always.** Never sequential. Agents A/B/C run simultaneously. Step 1.5 MCP calls run in parallel too.
3. **Latest entry only.** Read the last 15 lines of session log — not full history.
4. **No decisions unless critical.** Don't load architecture decisions unless the current task explicitly involves one. They waste tokens for routine work.
5. **Detect project from cwd.** Don't require the user to always type the project name.
6. **Anti-patterns only if they exist.** Never create the file. If it's empty/missing, skip the block.
7. **End with a question.** Always end with "Ready. What are we doing?" or equivalent. This signals boot complete and hands control to the user.
8. **One session log entry only.** Don't read full SESSION_LOG.md history. Last 15 lines maximum.
9. **NEVER list is max 5.** Pick the most critical security/correctness rules. Long NEVER lists get ignored.
10. **Warn if running from parent directory.** Cross-project contamination risk. Always flag it.
11. **MCP graceful degradation.** If `mcp__mem0__search-memories` or `mcp__obsidian-semantic__vault` fails (server unavailable, Obsidian not running, timeout), skip silently. Never let MCP failures block or delay startup. File-based reads are always the safety net.
12. **Mem0 recency wins.** If Mem0 returns session context with a more recent timestamp than the file-based status memory, use Mem0 data as the primary source for "last session" and "current task".
13. **No old KB paths.** Never reference old local `*-KB/` paths. All vault content lives under `AI-Employee-Platform/`.
