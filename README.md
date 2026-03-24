# Scaffold

**Claude stops mid-task, lies about finishing, and forgets everything you told it. This fixes that.**

![Scaffold demo](assets/demo.gif)

**Install via Claude Marketplace:** Search `scaffold` in Claude Code plugins, or:

```bash
git clone https://github.com/alexxenn/scaffold && cd scaffold && ./install.sh
```

> **Marketplace users:** skills are namespaced as `/scaffold:preload`, `/scaffold:decide`, etc.
> **Local install users:** skills keep their short names — `/preload`, `/decide`, etc.

---

Claude Code is the best AI coding tool available and it will still destroy your afternoon. It ignores your `CLAUDE.md` after two prompts. It silently drops tasks and tells you they're done. Every session starts from absolute zero — no memory of the architecture decisions you spent three hours debating yesterday. Without structure, Claude drifts. Context rots. One bad planning step poisons the entire session and you spend more time fixing Claude than writing code.

This is a skills framework that turns Claude Code from a forgetful intern into a disciplined engineering partner. No wrappers. No external services. Just structured instructions, purpose-built skills, and always-active guardrails that Claude actually follows.

**What you get that no other framework provides:**

- **Persistent memory + Obsidian** — Claude reads your full project knowledge base at session start. Sessions resume, not restart.
- **Decision enforcement** — `/decide` spawns scaled research and debate agents, logs verdicts permanently. No more winging architecture choices.
- **Always-active domain rules** — Guardrails baked into every session. Auth before logic. No credential forwarding. Schema strictness.
- **~75% token savings** — 3-tier model routing: Haiku for search, Sonnet for code, Opus for decisions.

`scaffold · 17 skills · 5 hooks · ~75% token savings · Claude Code 2.0+`

---

## The Problem

| What You Experience | What Actually Happens | What The Framework Delivers |
|---|---|---|
| Claude delivers 60% of the work, says "done" | Mid-task abandonment with false confidence | Verification gates that enforce completion before marking tasks done |
| Every new session, you explain the project from scratch | Zero session persistence — no memory bridge between conversations | Auto-loaded project context, decisions, and execution state at session start |
| You write CLAUDE.md rules, Claude ignores them after message 5 | Rules fade as context fills; no enforcement mechanism | Session persistence protocol + memory files that survive across conversations |
| Your token bill is crushing you | Everything routes to Opus by default; no cost-aware routing | 3-tier model routing (Haiku → Sonnet → Opus) with ~75% token savings |
| You're winging architecture decisions | No structured debate; decisions made in chat without research | Decision gates with multi-agent research, WebSearch, and logged verdicts |

---

## Token Efficiency First

Every decision you make in Claude Code carries a real cost. This framework automatically routes work to the cheapest capable model — applied across all 17 skills automatically. You don't toggle it. It's always on.

| Model | Cost per MTok | Best For |
|-------|---------------|----------|
| Haiku | ~$0.25 | Research, file search, fact-finding, loading context |
| Sonnet | ~$3.00 | Code generation, test writing, synthesis, reviews |
| Opus | ~$15.00 | Architecture decisions, security analysis, debate |

**Real savings from `/decide`:**

| Decision size | Agents | vs all-Opus |
|---|---|---|
| Minor (naming, location) | 2-3 agents: haiku + sonnet | **~85% cheaper** |
| Medium (library, pattern) | 4-6 agents: haiku + sonnet | **~75% cheaper** |
| Major (architecture, framework) | 8-12 agents: haiku + sonnet + opus | **~55% cheaper** |

The routing rule: security decisions always escalate to Opus. Everything else routes down to the cheapest model that can handle it.

---

## Skills

### Core (original — built for this framework)

These don't exist anywhere else. They solve the problems Claude Code has out of the box.

| Skill | What it solves |
|---|---|
| `/project-setup` | Bootstraps a complete project skeleton — Obsidian KB, CLAUDE.md with domain rules, persistent memory, and custom skills that encode your actual types, paths, and patterns. Not generic templates. |
| `/decide` | Scaled research and structured debate for architecture decisions. 2-3 haiku agents for a naming choice, up to 12 agents with Opus debate rounds for a framework pick. Logs the verdict permanently. Blocks implementation until resolved. |
| `/preload` | Warm-starts any session in seconds. Reads all memory files, session logs, architecture decisions, and domain rules, then outputs a single execution brief. Run this once at session start instead of re-explaining your entire project. |
| `/sync-context` | Loop-compatible drift detection. Run with `/loop 15m /sync-context`. Watches for rule violations, surfaces forgotten decisions, health-checks session state. Quiet when everything's clean, loud the moment something drifts. |

### Workflow & Quality Gates

Every "Claude went off the rails" story has the same root cause: no gates between phases.

| Skill | What it solves |
|---|---|
| `/workflow-gate` | Hard gates between brainstorm, plan, execute, and review. Includes 3-failure escalation — three consecutive failures force a replan instead of letting a bad step 2 poison everything downstream. |
| `/sparc` | Spec, Pseudocode, Architecture, Refinement, Completion. For complex features that need written artifacts at each stage. Persists across sessions so you never lose mid-feature progress. |
| `/tdd` | Iron law: tests written first, always. No implementation before a failing test exists. Enforces red, green, refactor with no exceptions. |
| `/review` | Two-stage code review. Sonnet auto-pass catches conventions, obvious bugs, and lint. Opus deep-reviews only the 20-30% of files that auto-pass flags. You pay for depth only where it matters. |
| `/debug-systematic` | Four-phase scientific method: Observe, Hypothesize, Test, Conclude. 3-failure escalation built in. Kills the infinite random-guessing loops that burn tokens and fix nothing. |
| `/verify` | Hard gate before marking work done. Checks requirements against actual code (not what the model remembers writing), runs tests, validates domain rules, and scans for regressions. |

### Token Efficiency & Agent Management

| Skill | What it solves |
|---|---|
| `/route-model` | The routing protocol all other skills follow. Haiku handles search and retrieval. Sonnet handles code generation. Opus handles architecture and security review. Applied automatically. |
| `/dispatch` | Parallel agent dispatch with automatic model tier routing. Give it a goal, it decomposes into parallel work units, assigns each to the correct model, and aggregates results. |
| `/worktree` | Git worktree management for safe experiments. Risky work runs in an isolated checkout — the agent literally cannot corrupt your main tree. Merge only what passes. |
| `/skill-create` | Meta-skill. Creates new properly-structured skills with model routing, project pattern awareness, and a rules section. The right way to extend the framework instead of copying and editing by hand. |

### Recovery & Context (solve the hardest Claude pain points)

| Skill | What it solves |
|---|---|
| `/loop-guard` | Audits for incomplete work: truncated files, partial commits, gaps vs original request. Forces completion before you think you're done. |
| `/context-save` | Saves current session state before context compaction. Writes a `RESUME.md` recovery prompt so you pick up exactly where you left off. |
| `/agents-md` | Generates `AGENTS.md` — universal AI agent instructions that work with Claude Code, Cursor, GitHub Copilot, and any AI that reads agent config files. Based on the community standard with 3,367 upvotes on GitHub. |

---

## Persistent Memory + Obsidian

**This is what no other Claude Code framework does.**

![Memory demo](assets/memory-demo.gif)

Every other framework resets between sessions. You re-explain your stack, your decisions, your rules — every single time. Scaffold builds a living knowledge base backed by [Obsidian](https://obsidian.md/) that Claude reads from at the start of every session.

`/project-setup` generates a full Obsidian vault for your project:

```
your-project/
├── 01-overview/          ← project goals, stack, constraints
├── 02-architecture/      ← ARCHITECTURE_DECISIONS_LOG.md (every /decide verdict)
├── 03-domain-rules/      ← your enforced coding rules
├── 04-patterns/          ← reusable patterns Claude follows
├── 05-integrations/      ← external services, APIs, schemas
├── 06-references/        ← where things live, what tools exist
└── 07-session-logs/      ← SESSION_LOG.md — dated entry every session
```

Everything is **wiki-linked in Obsidian**. Architecture decisions link to the patterns they established. Session logs link to the files they touched. Domain rules link to the code that enforces them. It's a second brain for your project — and Claude reads it.

**At the start of every session, `/preload`:**
1. Reads your current status (phase, blockers, next step)
2. Reads your latest session log entry
3. Reads all active architecture decisions
4. Reads your domain rules
5. Outputs a single execution brief — Claude knows everything, you say nothing

**The result:** Session 50 is as coherent as session 5. You stop repeating yourself to Claude forever.

---

## Decision Enforcement

When you're about to choose a library, design a data schema, or pick a security approach:

```bash
/decide "database: PostgreSQL vs PlanetScale" --size major
```

What happens:
- Haiku agents research pricing, feature parity, production use cases
- Sonnet agents benchmark query performance, connection pooling, scaling patterns
- Opus agents debate the tradeoffs for your specific constraints
- The verdict gets logged to `ARCHITECTURE_DECISIONS_LOG.md` — permanent

Auto-detection works too. Choosing a new dependency triggers `/decide --size medium` automatically. You can override, but the framework nudges you toward rigor.

**The difference:** You spend research time once, then stop re-litigating. Settled questions stay settled.

---

## Always-Active Domain Rules

CLAUDE.md rules get ignored after a few messages. This framework enforces them every session.

`/project-setup` generates your CLAUDE.md with domain-specific rules baked in. `/sync-context` detects when rules are being violated mid-session and surfaces them.

---

## Hooks

Install by merging `hooks/settings.json` into `~/.claude/settings.json`.

| Hook | Trigger | What it does |
|------|---------|-------------|
| **Stop** | Session ends | Prints checklist: run `/context-save`, update status file, log the session |
| **PostToolUse(Bash)** | After `git commit` | Suggests `/review --diff` before pushing |
| **PostToolUse(Agent)** | After agent dispatch | Logs model tier used (haiku/sonnet/opus) — see routing decisions in action |
| **PreToolUse(Bash)** | Before bash commands | Warns on: `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`, `DELETE FROM`, pushing to main/master |
| **PreToolUse(Write)** | Before writing any file | Scans content for API keys (`sk-...`, `ghp_...`, `AKIA...`, `AIza...`) before they hit disk |

---

## Installation

### Global (available in all projects)

```bash
git clone https://github.com/alexxenn/scaffold && cd scaffold && ./install.sh
```

### Manual

1. **Copy skills globally:**
   ```bash
   cp -r commands/* ~/.claude/commands/
   ```

2. **Or copy to a specific project only:**
   ```bash
   cp -r commands .claude/commands
   ```

3. **Merge hooks:**
   ```bash
   cp hooks/settings.json ~/.claude/settings.json
   ```

4. **Restart Claude Code** to load the new skills.

### Verify

```
/preload --help
```

---

## Quick Start

```bash
# 1. Load all context (memory, vault, decisions, preferences)
/preload

# 2. Bootstrap a new project with generated skills
/project-setup my-app --tech nextjs-supabase

# 3. Hit an architecture decision? Don't guess. Research it.
/decide "state management: Zustand vs Jotai"

# 4. Working for a while? Keep context from drifting.
/loop 15m /sync-context
```

### When to reach for what

| Situation | Command |
|---|---|
| Starting a complex feature | `/sparc` or `/workflow-gate` |
| About to commit | `/review --diff` |
| Something broke | `/debug-systematic` |
| Writing new code | `/tdd` |
| Architecture choice | `/decide` |
| Claude stopped mid-task | `/loop-guard` |
| Context window getting long | `/context-save` |
| New session | `/preload` (always) |

### A real day

**Morning:** `/preload` — loads memory + vault + recent decisions → tells you exactly where you left off

**During:** `/workflow-gate` for features · `/tdd` for new code · `/decide` for architecture choices

**End:** `/verify` · `/context-save`

Next morning, `/preload` picks up exactly where you stopped.

---

## Project-Specific Skills

`/project-setup` generates skills that know your project — your file structure, your conventions, your libraries, your patterns.

**Generic (what other frameworks give you):**
```
"Create a React component following best practices."
```

**Project-specific (what this generates):**
```
"Create a component in src/components/<category>/<Name>.tsx using cn() from
@/lib/utils, our shadcn components, useAuth() from @/hooks/use-auth for
protected components, PascalCase.tsx naming, with Storybook story +
renderWithProviders() test."
```

That's not a template. That's a skill generated from scanning your actual project.

---

## Extending

```bash
/skill-create deploy-check --category global
/skill-create new-feature --project my-saas
```

---

## Contributing

Issues and PRs welcome. Submit your skills to [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code).

---

## Acknowledgements

- **[ruflo](https://github.com/ruvnet/ruflo) by ruvnet** — 3-tier model routing, SPARC methodology, parallel dispatch
- **[superpowers](https://github.com/obra/superpowers) by obra** — workflow gates, TDD iron law, 2-stage review, systematic debugging, verification gates, worktree pattern
- **Original skills** (`/project-setup`, `/decide`, `/preload`, `/sync-context`, `/loop-guard`, `/context-save`, `/agents-md`) built from scratch for this framework

---

## License

MIT

---

<p align="center">
<br>
If this framework saved you from a Claude disaster, star it and tell a dev.<br>
<br>
<i>Built by someone who mass-deleted a production database with an AI agent exactly once. Never again.</i>
</p>
