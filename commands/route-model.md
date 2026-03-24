---
name: route-model
description: "3-tier model routing for agent spawning — haiku for retrieval, sonnet for generation, opus for reasoning. ~75% token cost reduction."
argument-hint: "[--show-routing] [--override <model>]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---

<objective>
Intelligent model routing that assigns the cheapest capable model to every agent spawn. Based on ruflo's 3-tier routing pattern that achieves ~75% token cost reduction.

This is NOT a standalone skill you run manually — it's a **routing protocol** that ALL other skills must follow when spawning agents. Think of it as a lookup table hardcoded into every Agent call.

**Use `--show-routing`** to see the current routing table and estimated savings.
**Use `--override <model>`** to force all agents to a specific model (for debugging or when you need max quality).
</objective>

<context>
**The Problem:**
Every Agent tool call defaults to the parent model (usually Opus). But most agent tasks don't need Opus-level reasoning. Spawning Opus for a file search is like hiring a PhD to read a phonebook.

**The Solution:**
Classify every agent task into one of 3 tiers BEFORE spawning:

| Tier | Model | Token Cost | When |
|------|-------|-----------|------|
| **T1: Retrieval** | `haiku` | ~$0.25/MTok in, ~$1.25/MTok out | Pure search, read, glob, grep, fact-finding |
| **T2: Generation** | `sonnet` | ~$3/MTok in, ~$15/MTok out | Code generation, single-file edits, test writing, synthesis |
| **T3: Reasoning** | `opus` | ~$15/MTok in, ~$75/MTok out | Architecture, multi-file refactors, debate, security analysis |

**Cost ratio:** T1 is ~60x cheaper than T3 on input, ~60x cheaper on output.
</context>

## Routing Table

### Tier 1: Haiku ($) — Retrieval & Fact-Finding

Use `model: "haiku"` on Agent calls for:

- **Codebase exploration** — `subagent_type: "Explore"` for file searches, pattern finding
- **Research data gathering** — finding facts, reading docs, fetching URLs (not analyzing them)
- **`/decide` minor research agents** — gathering data points, not evaluating them
- **`/preload` context loading** — pure file reads and extraction
- **`/sync-context` drift checks** — pattern matching against rules
- **Dependency checks** — version lookups, compatibility checks
- **File inventory** — listing files, counting lines, checking structure
- **Simple grep/search agents** — finding occurrences, not understanding them

**Haiku is NOT for:** Anything requiring judgment, trade-off analysis, code generation, or multi-step reasoning.

### Tier 2: Sonnet ($$) — Generation & Synthesis

Use `model: "sonnet"` on Agent calls for:

- **Code generation** — writing new functions, components, tests (bounded scope)
- **Single-file edits** — refactoring within one file
- **Test writing** — generating test cases from specs
- **Documentation** — writing docs, comments, READMEs
- **`/decide` medium research agents** — synthesizing findings, comparing options
- **`/review` first-pass auto-review** — checking patterns, conventions, obvious issues
- **Code formatting/linting analysis** — style and convention checking
- **Translation tasks** — converting between formats, languages, schemas
- **`/tdd` test generation** — writing test cases (not designing test strategy)
- **`/sparc` pseudocode and spec phases** — structured but not deeply creative

**Sonnet is NOT for:** Architecture decisions, security analysis, multi-file refactors, debate rounds.

### Tier 3: Opus ($$$) — Deep Reasoning & Architecture

Use `model: "opus"` (or omit `model` to inherit parent) for:

- **Architecture decisions** — `/decide` major debate agents
- **Security analysis** — `/review` deep security pass, threat modeling
- **Multi-file refactors** — changes spanning 3+ files with interdependencies
- **Debate rounds** — `/decide` advocacy and rebuttal agents
- **`/workflow-gate` brainstorm phase** — exploring approaches requires creativity
- **`/debug-systematic` root cause analysis** — connecting symptoms across the system
- **`/sparc` architecture and refinement phases** — design-level thinking
- **Complex integration work** — connecting multiple systems or services
- **`/verify` deep verification** — checking correctness across the entire change

## How to Apply This Protocol

### When writing a skill that spawns agents:

**BEFORE (wasteful):**
```
Agent: "Search the codebase for all files importing auth middleware"
→ Runs on Opus (inherited). Cost: $$$
```

**AFTER (routed):**
```
Agent: model: "haiku", "Search the codebase for all files importing auth middleware"
→ Runs on Haiku. Cost: $. Same result.
```

### When `/decide` spawns research agents:

**Minor decision (2-3 agents):**
- Research agents → `haiku` (just gathering facts)
- Synthesis → done by parent (no extra agent needed)

**Medium decision (4-6 agents):**
- Research agents 1-4 → `haiku` (data gathering)
- Synthesis agent → `sonnet` (combining findings)
- Debate agents → `sonnet` (medium-stakes advocacy)

**Major decision (8-12 agents):**
- Research agents 1-6 → `haiku` (data gathering)
- Benchmark/comparison agents → `sonnet` (structured comparison)
- Debate agents → `opus` (high-stakes multi-factor reasoning)
- Final honest assessment → `opus` (needs full reasoning capacity)

### Estimated Savings per Skill

| Skill | Before (all Opus) | After (routed) | Savings |
|-------|-------------------|----------------|---------|
| `/decide --size minor` | 3 × Opus | 2 Haiku + 1 Sonnet | ~85% |
| `/decide --size medium` | 6 × Opus | 4 Haiku + 2 Sonnet | ~75% |
| `/decide --size major` | 12 × Opus | 6 Haiku + 3 Sonnet + 3 Opus | ~55% |
| `/preload` | 1 × Opus | 1 × Haiku | ~95% |
| `/review` | 2 × Opus | 1 Sonnet + 1 Opus | ~40% |
| `/dispatch` (5 agents) | 5 × Opus | Mixed by task | ~60-80% |
| **Weighted average** | | | **~70-75%** |

## Edge Cases

1. **When in doubt, route UP not DOWN.** If you're unsure whether a task is T1 or T2, use T2. The cost of a wrong-tier-down (bad result, wasted retry) exceeds the cost of a wrong-tier-up (slightly more expensive, correct result).

2. **Override for debugging.** If a haiku agent returns garbage, retry with sonnet. If sonnet struggles, escalate to opus. Don't retry at the same tier.

3. **Background agents can be lower tier.** Agents running in background with `run_in_background: true` are less time-sensitive — optimize for cost.

4. **Security tasks are ALWAYS T3.** Never route security analysis, auth review, or threat modeling below Opus. The cost of missing a vulnerability vastly exceeds token savings.

5. **User can override.** `--override opus` forces all agents to Opus for a session. Use when quality matters more than cost.

## Rules

1. **Every Agent call in every skill must have an explicit model tier.** No implicit inheritance for agent spawns — make the routing decision visible.
2. **Security tasks are always Opus.** Non-negotiable. Security analysis at haiku/sonnet quality is worse than no analysis.
3. **Route UP on failure, not retry at same tier.** If haiku fails, don't retry haiku — escalate to sonnet.
4. **The routing table is a guideline, not a straitjacket.** If a specific task needs more reasoning than its category suggests, route up.
5. **Show routing in verbose mode.** When `--show-routing` is active, print the model tier for every agent spawn so the user can audit.
6. **Track savings.** When a skill completes, optionally report: "Agents spawned: N (X haiku, Y sonnet, Z opus) — estimated ~N% savings vs all-opus."
7. **This protocol applies to ALL skills.** `/decide`, `/review`, `/dispatch`, `/workflow-gate`, `/sparc`, `/tdd`, `/verify`, `/debug-systematic` — all must route.
