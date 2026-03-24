# Scaffold

**Claude abandons tasks mid-stream, swears it's done, and remembers nothing. Meet the skills framework that fixes it.**

![Scaffold demo](assets/demo.gif)

**Install via Claude Marketplace:** Search `scaffold` in Claude Code plugins, or:

```bash
git clone https://github.com/alexxenn/scaffold && cd scaffold && ./install.sh
```

> **Marketplace users:** skills are namespaced as `/scaffold:preload`, `/scaffold:decide`, etc.
> **Local install users:** skills keep their short names — `/preload`, `/decide`, etc.

---

Claude Code is the best AI coding tool you have. It's also a context-erasing, task-abandoning, hallucination machine that forgot your architecture decisions five prompts ago. Every session starts blank. Your `CLAUDE.md` gets ignored. You spend more time repeating yourself than shipping code. One bad planning decision cascades into hours of cleanup because Claude never learns from it. You're not collaborating with an engineer — you're babysitting an overpowered text autocomplete that gaslit you into thinking it finished.

Scaffold burns the whole thing down. It keeps Claude honest.

- **Actually remember your decisions** — Persistent memory + Obsidian vault means Claude reads your full project context at session start. Architecture decisions stay decided. Sessions resume instead of restarting from scratch every time.
- **Force better architecture choices** — `/decide` runs scaled research and debate across agents, logs the verdict permanently, and blocks implementation until resolved. No more winging critical design decisions.
- **Stop Claude from lying about completion** — Workflow gates, verification checkpoints, and systematic debugging force Claude to actually finish what it starts. Tasks get audited. Progress gets logged. No silent failures.
- **Slash token spend by 75%** — 3-tier model routing (Haiku for search, Sonnet for code, Opus for decisions) gives you the right brain for the right job and keeps billing reasonable.

`scaffold · 17 skills · 5 hooks · ~75% token savings · Claude Code 2.0+`

---

## The Problem

| What You Experience | What Actually Happens | What The Framework Delivers |
|---|---|---|
| Claude delivers 60% of the work, then vanishes mid-implementation with "I've laid the groundwork" | Mid-task abandonment disguised as progress. You're left debugging half-finished code, missing edge cases, incomplete tests. | Verification gates that refuse to close a task until it actually passes. No "done" without proof. |
| Every new session, you re-explain the entire project, architecture, and last week's decisions | Zero session persistence. Each conversation starts blank. Your CLAUDE.md rules, context, and decision history evaporate the moment you close the tab. | Auto-loaded project context, architecture decisions, execution state, and rules at session start. Zero re-onboarding tax. |
| You write ironclad CLAUDE.md rules. Claude follows them for 5 messages, then forgets they exist | Rules fade as context window fills. There's no enforcement layer. The framework knows your rules exist but has no mechanism to stay true to them. | Session persistence protocol + memory files that survive across conversations. Rules are structurally enforced, not just hoped for. |
| Your token bill explodes with no visibility into why | Everything routes to Opus by default — the $15/MTok model. You're paying premium rates for research, boilerplate, and simple transformations that Haiku could handle for $0.25/MTok. | 3-tier model routing (Haiku → Sonnet → Opus) applied automatically across all skills. ~75% token savings without losing capability. |
| Architecture decisions happen in chat, no debate, no research logged | You pick a library because it "feels right." No structured research. No logged verdict. Six weeks later, you discover it was the wrong choice and there's no record of why you picked it. | Multi-agent research + structured debate with WebSearch. Every decision is logged to your architecture decision log with reasoning and dissent included. |

---

## Token Efficiency First

Every decision you make in Claude Code carries a real cost. Right now, you're probably bleeding money routing everything to Opus when cheaper models could handle 80% of your work. This framework automatically routes work to the cheapest capable model — applied across all 17 skills without you thinking about it. It's always on.

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

The routing rule: security decisions always escalate to Opus. Everything else routes down to the cheapest model that can handle it. A minor naming decision doesn't need Opus. Neither does loading context. A security audit does. The framework knows the difference — and acts accordingly.

---

## Skills

### Core (original — built for this framework)

These don't exist anywhere else. They solve the problems Claude Code has out of the box.

| Skill | What it solves |
|---|---|
| `/project-setup` | Bootstraps a complete project skeleton with Obsidian KB, CLAUDE.md domain rules, persistent memory, and custom skills — all pre-configured for your actual types, paths, and patterns instead of generic templates. Start new projects in minutes, not hours. |
| `/decide` | Kills decision paralysis through scaled research and structured debate. 2-3 agents for naming choices, up to 12 agents with Opus debate rounds for architecture decisions. Verdict gets logged permanently and blocks implementation until resolved. |
| `/preload` | Warm-starts any session in seconds by reading all memory, session logs, architecture decisions, and domain rules into a single execution brief. Never re-explain your project again. |
| `/sync-context` | Runs on a loop (`/loop 15m /sync-context`) to catch drift in real time — rule violations, forgotten decisions, and session health issues. Silent when clean, loud when something breaks. |

### Workflow & Quality Gates

Every "Claude went off the rails" story has the same root cause: no gates between phases. These skills enforce them.

| Skill | What it solves |
|---|---|
| `/workflow-gate` | Hard gates between brainstorm, plan, execute, and review with built-in 3-failure escalation — three consecutive failures force a replan instead of letting a bad step 2 poison everything downstream. |
| `/sparc` | Spec, Pseudocode, Architecture, Refinement, Completion. For complex features, forces written artifacts at each stage and persists progress across sessions so you never lose mid-feature work. |
| `/tdd` | Iron law: tests written first, always. Enforces red → green → refactor with no exceptions. Implementation cannot start until a failing test exists. |
| `/review` | Two-stage code review: Sonnet auto-passes simple files (conventions, obvious bugs, lint), Opus deep-reviews only the 20-30% that matter. You pay for depth only where it counts. |
| `/debug-systematic` | Four-phase scientific method: Observe, Hypothesize, Test, Conclude. 3-failure escalation built in. Kills infinite random-guessing loops that burn tokens and fix nothing. |
| `/verify` | Hard gate before marking work done. Checks requirements against actual code (not what the model remembers writing), runs tests, validates domain rules, and scans for regressions. |

### Token Efficiency & Agent Management

Maximize output per token by routing work to the right model tier and parallelizing intelligently.

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

Every other framework resets between sessions. Session 1, you explain your stack, your decisions, your rules. Session 5, you explain them again. Session 50, you're still explaining the same things. Scaffold builds a living knowledge base backed by [Obsidian](https://obsidian.md/) that Claude reads from at the start of every session — so you never have to repeat yourself again.

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

**The result:** You pick up mid-task, mid-thought, mid-refactor. Context survives you. Decisions stick. Patterns compound. Session 50 is as coherent as session 5 — because it's a continuation of it.

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

**The payoff:** You research once, then move on. Settled questions stay settled. No re-litigating the same choice three months later because you forgot why you made it.

---

## Always-Active Domain Rules

CLAUDE.md rules get ignored after a few messages. Scaffold enforces them every session.

`/project-setup` generates your CLAUDE.md with domain-specific rules baked in: auth checks before logic, input sanitization, no unwrap() outside tests, tenant isolation, rate limiting — whatever your stack demands. `/sync-context` detects when rules are being violated mid-session and surfaces them immediately. Not in a post-mortem code review, but in real-time. Rules aren't suggestions; they're embedded in the execution loop. Violations bubble up before they compound.

---

## Hooks

Install by merging `hooks/settings.json` into `~/.claude/settings.json`. Hooks fire even when Claude forgets — they're the guardrails that don't depend on memory.

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

**Morning:** Run `/preload`. It reads your memory from yesterday, pulls the latest session log from your vault, loads your project's decisions and patterns. Twenty seconds later, you know exactly where you left off and what's blocking you.

**During:** `/workflow-gate` for features · `/tdd` for new code · `/decide` for architecture choices · `/debug-systematic` when tests fail.

**End:** `/verify` runs a final gate — lint, typecheck, tests. If it passes, you're done. Then `/context-save` writes a recovery prompt for tomorrow.

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
