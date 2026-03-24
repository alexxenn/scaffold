---
name: decide
description: "Deploy research + debate agents to make the best coding/architecture decision — scales agent count to decision size, backed by industry standards research."
argument-hint: "<decision-description> [--size minor|medium|major] [--options 'A vs B vs C']"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - Task
  - WebSearch
  - WebFetch
---

<objective>
Deploy a scaled team of research and debate agents to find the BEST coding/architecture decision for the current project. Every significant decision gets:

1. **Real research** — industry standards, benchmarks, real-world usage data, known pitfalls
2. **Multiple proposals** — agents independently propose approaches based on research
3. **Structured debate** — agents argue for/against each approach with evidence
4. **Synthesis** — combine findings into a clear verdict with reasoning
5. **Permanent logging** — write the decision to the project's Architecture Decisions Log

This is NOT opinion-based. Agents must cite real libraries, real benchmarks, real production patterns. "I think X is better" is not acceptable — "X is used by Y% of production systems because Z" is.

**Scales automatically:**
- **Minor** (2-3 agents): naming, file location, small pattern choice. ~2 min.
- **Medium** (4-6 agents): library choice, design pattern, API shape. ~5 min.
- **Major** (8-12 agents): architecture, data model, framework, security model. ~10 min.

**Model routing (per /route-model — ~70% token savings vs all-opus):**
- Minor research agents → `haiku` (fact-finding only)
- Medium research agents → `haiku`, synthesis → `sonnet`
- Major research agents → `haiku`, comparison/benchmark agents → `sonnet`, debate agents → `opus`
- Security/architecture debate always → `opus` regardless of decision size
</objective>

<context>
**Arguments:**
- `<decision-description>` — What needs to be decided (e.g., "state management: Zustand vs Jotai vs Redux Toolkit")
- `--size minor|medium|major` — Force a size tier. If omitted, auto-detect from description.
- `--options 'A vs B vs C'` — Pre-defined options to evaluate. If omitted, agents discover options.
- `--no-log` — Skip writing to Architecture Decisions Log (for quick explorations)
- `--context <file>` — Additional context file to feed agents (e.g., a spec or existing code)
</context>

## Process

### Step 0: Classify Decision Size

If `--size` not provided, auto-classify:

**Minor** (2-3 agents) — answers are mostly interchangeable, low blast radius:
- Variable/function naming conventions
- File/folder location within established structure
- CSS approach for a single component
- Which specific utility function to use
- Import style or formatting choice

**Medium** (4-6 agents) — affects multiple files, moderate blast radius:
- Library/package choice (e.g., Zustand vs Jotai)
- Design pattern selection (e.g., repository pattern vs service pattern)
- API endpoint design (REST shape, error codes, pagination)
- Testing strategy for a feature
- Database index strategy
- Component architecture (compound components vs render props vs hooks)

**Major** (8-12 agents) — affects project architecture, high blast radius:
- Framework or language choice
- Database engine selection
- Auth architecture (JWT vs sessions vs OAuth provider)
- Data model design (core domain types)
- Multi-tenancy strategy
- Caching architecture
- Real-time communication approach
- Monorepo vs polyrepo
- Deployment architecture
- Security model design

### Step 1: Read Project Context

Before deploying agents, gather context:

1. Read `CLAUDE.md` for project rules, tech stack, domain constraints
2. Read the Architecture Decisions Log for prior decisions (agents must not contradict them without explicit reason)
3. If `--context` provided, read that file
4. If the decision touches existing code, read relevant files
5. Identify the project's Obsidian vault path and decisions log path

Build a **context brief** that every agent receives:
```
PROJECT: <name>
TECH STACK: <from CLAUDE.md>
DOMAIN RULES: <from CLAUDE.md>
PRIOR DECISIONS: <relevant ones from decisions log>
DECISION NEEDED: <description>
OPTIONS TO EVALUATE: <if provided, or "discover options">
CONSTRAINTS: <timeline, team size, existing patterns>
```

### Step 2: Deploy Research Agents (Parallel)

Spawn research agents based on decision size. ALL agents get the context brief.

**Minor (2-3 agents):**
```
Agent 1: "Research industry standard for <decision>. Find what major open-source
         projects and production systems use. Cite specific repos, docs, or articles.
         Return: recommended approach + evidence."

Agent 2: "Research known pitfalls and anti-patterns for <decision>. Find real
         post-mortems, GitHub issues, or Stack Overflow discussions about what
         goes wrong. Return: what to avoid + evidence."

Agent 3: (if options provided) "Compare <Option A> vs <Option B> on: bundle size /
         performance / DX / maintenance burden / community size. Use real numbers
         where possible."
```

**Medium (4-6 agents):**
```
Agent 1 (Industry Standards): "Research how the top 10 production-grade <tech stack>
         projects handle <decision>. Check GitHub repos with >5K stars.
         Return: patterns with adoption data."

Agent 2 (Benchmarks): "Find real benchmarks comparing the options. Check npm trends,
         bundle size (bundlephobia), performance benchmarks, GitHub stars/issues
         trajectory. Return: quantitative comparison."

Agent 3 (DX & Maintenance): "Evaluate each option for developer experience: learning
         curve, TypeScript support, documentation quality, migration path, breaking
         change history. Return: DX comparison matrix."

Agent 4 (Compatibility): "Check compatibility of each option with our existing stack:
         <tech stack details>. Look for known conflicts, version requirements,
         peer dependency issues. Return: compatibility report."

Agent 5 (Pitfalls): "Research production failures, post-mortems, and common mistakes
         for each option. Check GitHub issues labeled 'bug', migration horror
         stories, performance gotchas. Return: risk assessment per option."

Agent 6 (Future-Proofing): "Evaluate each option's trajectory: release cadence,
         maintainer activity, corporate backing, roadmap alignment with our needs.
         Return: longevity assessment."
```

**Major (8-12 agents):**
All of the above, PLUS:
```
Agent 7 (Security): "Audit each option for security implications. Check CVE history,
         supply chain risk (dependency count), known vulnerability patterns.
         Return: security comparison."

Agent 8 (Scale): "Research how each option performs at scale (>10K users, >1M records,
         >100 concurrent connections). Find real case studies.
         Return: scalability assessment."

Agent 9 (Migration): "If we pick each option, what's the migration effort FROM our
         current state? What's the migration path AWAY if we need to switch later?
         Return: lock-in and migration cost analysis."

Agent 10 (Cost): "Estimate the total cost of each option: infrastructure cost,
          development time, operational overhead, licensing.
          Return: TCO comparison."

Agent 11-12 (Domain-Specific): Spawn additional agents based on the specific
          decision domain (e.g., for a database decision: replication expert,
          query optimization expert).
```

**CRITICAL: All agents must use WebSearch and WebFetch to find REAL data.** No hallucinated benchmarks. If data can't be found, the agent must say "no data available" rather than guess.

### Step 3: Synthesize Research

After all research agents return, create a **Research Synthesis**:

```markdown
## Research Synthesis: <Decision Description>

### Options Identified
1. **Option A** — <one-line description>
2. **Option B** — <one-line description>
3. **Option C** — <if applicable>

### Evidence Summary

| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| Industry adoption | <data> | <data> | <data> |
| Performance | <data> | <data> | <data> |
| Bundle/binary size | <data> | <data> | <data> |
| DX & learning curve | <data> | <data> | <data> |
| Maintenance health | <data> | <data> | <data> |
| Compatibility | <data> | <data> | <data> |
| Security track record | <data> | <data> | <data> |
| Scale evidence | <data> | <data> | <data> |
| Migration cost | <data> | <data> | <data> |

### Key Findings
- <Finding 1 with source>
- <Finding 2 with source>
- <Finding 3 with source>

### Red Flags
- <Any dealbreakers found during research>
```

### Step 4: Deploy Debate Agents (Parallel)

Now spawn debate agents. Each agent ADVOCATES for one option and ATTACKS the others — using ONLY evidence from Step 3.

**Minor (1 debate round):**
```
Agent A: "You are advocating for <Option A>. Using ONLY the research evidence provided,
         make the strongest possible case for Option A AND the strongest case AGAINST
         each alternative. Be specific — cite the evidence."

Agent B: "You are advocating for <Option B>. Same instructions."
```

**Medium (1-2 debate rounds):**
Round 1: Same as minor but with more agents (one per option).
Round 2 (rebuttal): Each agent responds to the other agents' arguments.
```
Agent A-rebuttal: "Agent B argued <X>. Here's why that argument is weak: <evidence>.
                   Here's what Agent B missed about Option A: <evidence>."
```

**Major (2-3 debate rounds):**
Round 1: Initial advocacy (one agent per option)
Round 2: Rebuttals (agents respond to each other's arguments)
Round 3: Final statements — each agent gives their HONEST assessment (dropping the advocacy role):
```
Agent A-honest: "Dropping my advocacy role. Honestly evaluating all options against
                our specific constraints (<project rules, timeline, team>):
                My recommendation is <X> because <evidence>."
```

### Step 5: Verdict & Decision

After debate completes, synthesize the final decision:

1. **Tally the evidence** — which option won on the most criteria?
2. **Weight by project priority** — does the project prioritize security over DX? Speed over flexibility? (Use CLAUDE.md domain rules)
3. **Check for dealbreakers** — any red flags that eliminate an option regardless of other merits?
4. **Check prior decisions** — does any option conflict with existing architecture decisions?
5. **Draft the verdict**

Present to the user:

```markdown
## Decision: <Title>

**Verdict: Option <X>**

**Why:**
- <Primary reason with evidence>
- <Secondary reason with evidence>

**Why not <Option Y>:**
- <Reason with evidence>

**Why not <Option Z>:**
- <Reason with evidence>

**Risk accepted:**
- <Any downsides of the chosen option, honestly stated>

**Impact on project:**
- <What code/config changes this implies>
- <What future decisions this constrains>
```

Ask the user: **"Accept this decision, or want to override/discuss?"**

### Step 6: Log the Decision

If user accepts (and `--no-log` not passed):

1. **Find the Architecture Decisions Log** — look for `ARCHITECTURE_DECISIONS_LOG.md` in the project's Obsidian vault (check `02-architecture/` first, then search)

2. **Determine the decision number** — count existing decisions, increment by 1

3. **Append the decision** in this format:
```markdown
---

## Decision <N>: <Title>

**What:** <Chosen approach — one clear sentence>

**Why:**
- <Reason 1 with evidence>
- <Reason 2 with evidence>

**Why not <Alternative A>:**
- <Reason with evidence from debate>

**Why not <Alternative B>:**
- <Reason with evidence from debate>

**Research basis:**
- <Key sources: benchmarks, repos, articles cited by agents>
- <Quantitative data points that drove the decision>

**Impact:**
- <What this means for implementation>
- <What future decisions are now constrained>

**Risk accepted:**
- <Honest assessment of chosen option's downsides>

---
```

4. **Update HOME.md** key decisions table (if it has one)

5. **Update relevant memory files** if this decision changes project direction

### Step 7: Report

Print a concise summary:

```
Decision #<N>: <Title>
  Verdict: <Option X>
  Agents deployed: <count> research + <count> debate
  Research sources: <count> real sources cited
  Logged to: <path to decisions log>

  Key evidence: <one-line summary of the decisive factor>
```

## Auto-Trigger Guidelines

This skill should be invoked (by you or suggested to the user) when you detect:

**Always trigger (major):**
- Choosing a framework, library, or major dependency
- Designing a data model or database schema
- Selecting an auth/security approach
- Deciding on deployment/infrastructure architecture
- Any decision that affects >5 files or is hard to reverse

**Suggest triggering (medium):**
- Choosing between 2+ reasonable design patterns
- API endpoint design when multiple valid shapes exist
- Testing strategy for a complex feature
- Performance optimization approach

**Skip (use your own judgment):**
- Naming that follows existing conventions
- File placement within established structure
- Formatting or style choices covered by linters
- Implementation details within an already-decided pattern

## Rules

1. **Evidence over opinion.** Every claim in the debate must cite a real source (benchmark, GitHub repo, article, production case study). "I think X is better" is not an argument.
2. **WebSearch is mandatory for research agents.** Agents that return only from training data are not doing their job. Research must include current data.
3. **Honest assessment over advocacy.** The final round of major debates drops advocacy — agents give their genuine recommendation.
4. **Prior decisions are binding.** New decisions must not contradict existing architecture decisions unless the user explicitly wants to revisit.
5. **Scale appropriately.** Don't deploy 12 agents for a naming decision. Don't deploy 2 agents for a database architecture decision.
6. **No hallucinated benchmarks.** If performance data can't be found, say "no benchmark data available" — never fabricate numbers.
7. **Project context first.** The "best" option in general may not be the best for THIS project. Always evaluate against the project's specific tech stack, domain rules, timeline, and constraints.
8. **Log permanently.** Unless `--no-log`, every accepted decision goes into the Architecture Decisions Log. This is the project's institutional memory.
9. **Present alternatives honestly.** The rejected options' strengths must be acknowledged, not dismissed. This helps future revisiting.
10. **User has final say.** The verdict is a recommendation. Always ask for confirmation before logging.
