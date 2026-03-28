---
name: dispatch
description: "Parallel agent dispatch with model-aware routing. Spawn N agents concurrently, each at the correct tier (haiku/sonnet/opus). From Ruflo + Superpowers pattern."
argument-hint: "<task-list-or-description> [--concurrency <N>] [--model <tier>] [--background]"
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
Structured parallel agent dispatch: spawn multiple agents concurrently with each one automatically assigned the correct model tier based on task type.

This is the operational layer of `/route-model` — where routing theory becomes execution. Instead of spawning agents ad-hoc, `/dispatch` manages:
1. Task decomposition (break a goal into parallel units of work)
2. Model assignment (haiku/sonnet/opus per task)
3. Parallel execution (max N concurrent agents)
4. Result aggregation (collect and synthesize outputs)

**When to use:**
- Any task with 3+ independent subtasks
- Research across multiple codebases/docs/files simultaneously
- Parallel code generation for multiple unrelated modules
- Bulk analysis (scanning multiple files at once)

**vs. just spawning agents manually:**
`/dispatch` adds: task decomposition assistance, automatic model routing, concurrency control, result aggregation format.
</objective>

<context>
**Arguments:**
- `<task-list-or-description>` — Either a description of what to parallelize, or a comma-separated list of tasks.
- `--concurrency <N>` — Max parallel agents. Default: 5. Lower for rate-limit-sensitive work.
- `--model <tier>` — Override all agents to a specific tier: `haiku`, `sonnet`, `opus`. Default: auto-route.
- `--background` — Run agents in background (use when you don't need results immediately).
</context>

## Process

### Step 1: Decompose Into Parallel Units

Given the goal, identify which subtasks are:
- **Independent** (no output of A is input to B) → parallelize
- **Sequential** (A's output feeds B) → chain, don't parallelize
- **Partially dependent** (A feeds B but B and C are independent) → parallel where possible

Output a task manifest:

```
DISPATCH MANIFEST
─────────────────
Goal: <overall goal>
Tasks: <N> parallel units
Estimated savings vs sequential: ~<X>% time, ~<Y>% tokens

Task 1: <description>  → model: haiku  → <why>
Task 2: <description>  → model: sonnet → <why>
Task 3: <description>  → model: opus   → <why>
Task 4: <description>  → model: haiku  → <why>
Task 5: <description>  → model: sonnet → <why>
```

**Token budget per agent:** Keep individual agent prompts under 500 tokens. The task description + context brief should be compressed to essentials. If a task requires >500 tokens of context to describe, it's too large — split it.

### Step 2: Model Assignment (per /route-model)

For each task, assign model tier:

**→ haiku** if the task is:
- File search, glob, grep
- URL fetching, doc reading
- Listing, counting, inventory
- Fact-finding without analysis
- Simple data extraction

**→ sonnet** if the task is:
- Code generation (bounded scope)
- Synthesis of gathered data
- Comparison/evaluation of options
- Test writing
- Documentation

**→ opus** if the task is:
- Architecture analysis
- Security review
- Multi-factor trade-off reasoning
- Debate/advocacy
- Root cause analysis

### Step 3: Execute in Parallel

Spawn all agents simultaneously (up to `--concurrency` limit).

Each agent prompt follows this template:
```
[TASK <N> of <TOTAL> | MODEL: <tier>]
<task description>

Context: <relevant project context>
Output format: <what to return>
Constraints: <any project rules that apply>
```

**Context compression:** The "Context" field in each agent prompt must be ≤100 tokens. Summarize project context as: "Project: X | Stack: Y | Rules: Z (names only)". Never pass full CLAUDE.md or full file contents as context.

Track status:
```
DISPATCH STATUS
───────────────
[✓] Task 1: haiku  — Complete (1.2s)
[✓] Task 2: sonnet — Complete (3.1s)
[⏳] Task 3: opus  — Running...
[⏳] Task 4: haiku — Running...
[ ] Task 5: sonnet — Pending
```

### Step 4: Aggregate Results

After all agents complete, aggregate:

1. **Collect** all agent outputs
2. **Cross-reference** findings (did multiple agents find the same thing?)
3. **Identify conflicts** (did agents find contradictory information?)
4. **Synthesize** into a unified result (parent context — no extra agent needed for simple aggregation; spawn a sonnet agent for complex synthesis)

Output:

```
DISPATCH RESULTS
────────────────
Goal: <overall goal>
Completed: <N>/<N> tasks

<Task 1 findings>
<Task 2 findings>
<Task 3 findings>

Synthesis:
<Combined result / key takeaways / conflicts noted>

Model efficiency:
  Haiku agents: <N> (~$<est>)
  Sonnet agents: <N> (~$<est>)
  Opus agents: <N> (~$<est>)
  Savings vs all-opus: ~<X>%
```

## Common Dispatch Patterns

### Research Dispatch (all haiku)
```
/dispatch "gather data on X" --model haiku
→ Agent 1: Search GitHub repos
→ Agent 2: Fetch documentation
→ Agent 3: Find benchmark data
→ Agent 4: Check npm/crates/pypi stats
```

### Code Generation Dispatch (all sonnet)
```
/dispatch "implement modules A, B, C" --model sonnet
→ Agent 1: Implement module A
→ Agent 2: Implement module B
→ Agent 3: Implement module C
→ Aggregate: verify no conflicts in shared types
```

### Mixed Analysis Dispatch
```
/dispatch "analyze codebase security"
→ Agent 1: Scan for hardcoded secrets (haiku)
→ Agent 2: Find SQL query patterns (haiku)
→ Agent 3: Analyze auth flow (opus)
→ Agent 4: Check dependency CVEs (sonnet)
→ Agent 5: Review error handling (sonnet)
```

### Parallel Review Dispatch
```
/dispatch "review all changed files"
→ Agent per file: auto-review pass (sonnet)
→ Flag files for deep review (parent aggregates)
→ /review --deep-only on flagged files only
```

## Rules

1. **Decompose first, spawn second.** Print the manifest before spawning. This lets the user correct the decomposition before wasting tokens.
2. **Maximize haiku.** If a task could be done by haiku, assign haiku. Only escalate when the task genuinely requires higher reasoning.
3. **Concurrency limit prevents rate limits.** Default 5 concurrent agents. For long-running sessions, reduce to 3. For bursts, can go to 10.
4. **Aggregate in parent context when possible.** Don't spawn an extra "aggregation agent" unless synthesis is genuinely complex. Simple aggregation happens in parent.
5. **Background for non-blocking tasks.** If the user can continue working while agents run, use `--background`. Note: results won't be available until agents complete.
6. **Conflict detection is mandatory.** When multiple agents find contradictory results, flag it — don't silently pick one.
7. **Report model efficiency.** Always show the split between haiku/sonnet/opus agents and estimated savings. This makes the routing benefit visible.
8. **Agent prompt budget.** Each spawned agent's full prompt (task + context + output format + constraints) must stay under 500 tokens. Compress context aggressively — agents need direction, not a documentation dump.
9. **Prefer batching over spawning.** For tasks that take <30 seconds each, batch 2-3 into one agent rather than spawning separate agents. Agent spawn overhead is real. Don't spawn 10 haiku agents for 10 one-line grep operations — one agent can do all 10.
