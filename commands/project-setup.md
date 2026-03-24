---
name: project-setup
description: "Bootstrap a new project with Obsidian vault, CLAUDE.md, persistent memory, session logs, AND custom project-specific skills — fully replicating the ClawForge organization pattern."
argument-hint: "<project-name> [--vault-name <name>] [--skip-research] [--tech <stack>]"
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
Bootstrap a complete project organization system with:
1. Obsidian knowledge base (7 numbered folders + wiki-linked hub)
2. CLAUDE.md with session persistence protocol + domain rules
3. Claude persistent memory (MEMORY.md index + categorized files)
4. Session log system (dual-log: status tracker + dated Obsidian log)
5. **Custom project-specific skills** — NOT generic agent routing, but bespoke skills that encode the project's own types, patterns, conventions, checklists, and code templates (like ClawForge's `/rust:scaffold` with VaultSecret<T> and TenantScoped<T> baked in)

The goal is that ANY new project gets the same depth of automation ClawForge has — skills that know YOUR project's types, YOUR project's rules, YOUR project's patterns.

**After this command:** The project has custom skills, session persistence, knowledge base, and is ready for `/gsd:new-project` or direct development.
</objective>

<context>
**Arguments:**
- `<project-name>` — Required. Name of the project (e.g., "rental-ai", "saas-dashboard")
- `--vault-name <name>` — Optional. Obsidian vault folder name. Defaults to Title-Case of project name
- `--skip-research` — Skip domain research phase
- `--tech <stack>` — Technology stack (e.g., "nextjs-supabase", "rust-axum", "python-fastapi", "flutter-firebase", "django-postgres", "rails-postgres", "laravel-mysql")

**What makes this different from generic project setup:**
This skill creates CUSTOM skills for each project. Not "use react-expert agent" — but `/myproject:new-component` that knows your design system tokens, your state management pattern, your API layer conventions, your auth model, your folder structure. Like how `/rust:scaffold` knows about VaultSecret<T> and 4 crates, your project's skills will know YOUR project's specific patterns.
</context>

## Process

### Phase 0: Deep Context Gathering (Interactive)

Ask the user these questions one at a time. These answers drive EVERYTHING — especially the custom skills.

**Core Identity:**
1. What is this project? (one sentence)
2. Who is the target user/market?
3. What's the tech stack? (or `--tech` flag)

**Architecture & Patterns:**
4. What's the folder/module structure? (e.g., "monorepo with packages/", "crates/ workspace", "src/app/ Next.js", "feature-based modules")
5. What are the core domain types? (e.g., "Tenant, Agent, Message" for ClawForge, or "Product, Cart, Order" for e-commerce, or "Patient, Appointment, Provider" for healthcare)
6. What auth model? (JWT, API keys, OAuth, Supabase Auth, session-based, none yet)
7. Any domain-specific rules that MUST be enforced? Examples:
   - Multi-tenant: "tenant_id in every query"
   - HIPAA: "no PHI in logs, all patient data encrypted"
   - PCI: "no raw card numbers in app code"
   - E-commerce: "inventory checks before order confirmation"
   - Financial: "double-entry bookkeeping, all amounts in cents"
   - General: "no unwrap(), no console.log in production"

**Development Workflow:**
8. What's the timeline? (weeks/phases, or "ongoing")
9. Communication style? (e.g., "advanced no-BS", "explain everything", "terse")
10. Any existing patterns or conventions you want preserved?

Store ALL answers — they feed directly into skill generation.

### Phase 1: Analyze and Design Custom Skills

This is the critical phase. Based on Phase 0 answers, DESIGN the custom skills this project needs.

**Skill Design Process:**

1. **Identify the project's recurring tasks.** Every project has 5-10 things developers do repeatedly. Map them:

   For a Next.js + Supabase project, recurring tasks might be:
   - Create a new page/route
   - Create a new API endpoint
   - Create a new database table + RLS policies
   - Create a new React component with design system tokens
   - Write tests for a feature
   - Run quality checks (lint, type-check, test)
   - Add a new Supabase migration
   - Security review of auth/RLS

   For a Django + Postgres project:
   - Create a new model with admin registration
   - Create a new API view/serializer
   - Create a new migration
   - Write tests (unit, integration, API)
   - Run quality checks (ruff, mypy, pytest)
   - Add a new dependency safely
   - Security review of permissions/CSRF

   For a Flutter + Firebase project:
   - Create a new screen with navigation
   - Create a new widget (stateful/stateless)
   - Create a new Firestore collection + security rules
   - Add a new state management slice (Riverpod/Bloc)
   - Write widget tests + integration tests
   - Build and deploy checks

2. **For each task, determine what project-specific knowledge it needs.** This is what separates a custom skill from a generic agent:

   Generic: "Create a React component"
   Custom: "Create a React component in `src/components/<category>/` using our `cn()` utility, our `Button`/`Card` from shadcn, our `useAuth()` hook for protected components, with Storybook story, following our naming convention of `PascalCase.tsx` + `PascalCase.stories.tsx`"

   Generic: "Write tests"
   Custom: "Write tests using our `createTestApp()` helper, our `mockSupabaseClient()`, test that RLS policies reject cross-tenant access, use `@testing-library/react` with our custom `renderWithProviders()` wrapper"

3. **Design 5-10 skills.** Every project MUST get at minimum:

   | Skill Category | What It Does | Example Name |
   |---|---|---|
   | **Scaffold** | Create new modules/components/pages with project patterns | `<project>:new-component`, `<project>:new-page`, `<project>:new-model` |
   | **API/Route** | Create new endpoints/views with auth, validation, error handling | `<project>:new-endpoint`, `<project>:new-route` |
   | **Data** | Create new DB tables/collections with security (RLS, rules, migrations) | `<project>:new-table`, `<project>:new-migration` |
   | **Test** | Write tests using project's test utilities, patterns, priorities | `<project>:test-write` |
   | **Quality** | Run project's full lint/type/test/audit sequence | `<project>:quality-check` |
   | **Security** | Audit code against project's domain security rules | `<project>:security-audit` |
   | **Dependency** | Safely add new packages with audit and justification | `<project>:dep-add` |

   Plus domain-specific skills:
   - Multi-tenant SaaS → `<project>:tenant-feature` (scaffold with tenant isolation)
   - E-commerce → `<project>:new-product-feature` (with inventory/pricing patterns)
   - Healthcare → `<project>:phi-review` (HIPAA compliance audit)
   - Real-time → `<project>:new-realtime-channel` (WebSocket/subscription patterns)

### Phase 2: Generate Custom Skills

Create skill files at `.claude/commands/<project-slug>/`.

**Each skill MUST follow this structure** (modeled after the ClawForge Rust skills):

```markdown
---
name: <project-slug>:<skill-name>
description: "<one-line description that includes project context>"
argument-hint: "<arguments with project-specific options>"
---

<One sentence saying what this does for THIS project specifically.>

## Arguments
- `$ARGUMENTS` — Format: `<arg1> <arg2> [flags]`
  - <project-specific argument options — e.g., which module, which feature area>
  - <project-specific flags — e.g., --auth for protected routes, --realtime for subscription>

## Process

### 1. <First Step>
<Concrete instructions using project's ACTUAL types, paths, patterns>
<Code templates with project's ACTUAL imports, utilities, conventions>

### 2. <Second Step>
<More concrete instructions>

## Checklist
- [ ] <Project-specific check — e.g., "RLS policy includes tenant_id">
- [ ] <Security check from domain rules>
- [ ] <Convention check — e.g., "file follows PascalCase.tsx naming">

## Rules
- <Project-specific hard rules from Phase 0 question 7>
- <Pattern enforcement — e.g., "all state via useStore(), never local useState for shared data">
- <Security rules — e.g., "auth middleware on every protected route">
```

**Critical: Skills must encode CONCRETE project knowledge, not generic advice.**

BAD (generic):
```
Create a component following best practices.
Add appropriate tests.
```

GOOD (project-specific):
```
Create a component in `src/components/<category>/<Name>.tsx`:
\`\`\`tsx
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
// If --auth: import { useAuth } from "@/hooks/use-auth";
// If --form: import { useForm } from "react-hook-form";
// If --data: import { useQuery } from "@tanstack/react-query";

interface <Name>Props {
  className?: string;
  // ... typed props
}

export function <Name>({ className, ...props }: <Name>Props) {
  // If --auth: const { user, isLoading } = useAuth();
  // If --auth: if (isLoading) return <Skeleton />;
  // If --auth: if (!user) redirect("/login");

  return (
    <div className={cn("<base-classes>", className)}>
      {/* implementation */}
    </div>
  );
}
\`\`\`

Write Storybook story at `src/components/<category>/<Name>.stories.tsx`
Write test at `src/components/<category>/__tests__/<Name>.test.tsx`
```

### Phase 3: Create Obsidian Vault

Create the Obsidian vault at `<vault-name>/`:

```
<vault-name>/
├── HOME.md                          # Central hub — wiki-links to all sections
├── PROJECT_PLAN.md                  # Timeline with phases/milestones
├── TECH_STACK.md                    # Tech decisions with justifications
├── 01-research/                     # Domain/market research
├── 02-architecture/
│   └── ARCHITECTURE_DECISIONS_LOG.md
├── 03-product-specs/                # Feature specs, schemas, API contracts
├── 04-pricing-business/             # Business model (if applicable)
├── 05-archive/                      # Rejected ideas
├── 06-phases/
│   └── PHASE_INDEX.md               # Phase navigation + status
└── 07-session-logs/
    └── SESSION_LOG.md               # Append-only dated entries
```

**HOME.md must include:**
- Quick navigation table with wiki-links to all major docs
- Project context (target user, tech stack, timeline from Phase 0)
- Key decisions table (initially empty — filled as decisions are made)
- Custom skills reference table (list all generated skills with when to use)
- Back-link convention: every file starts with `## Back to [[HOME]]`
- Tag convention: every file tagged with `#<project-slug>`

**SESSION_LOG.md:** Write initial Session 1 entry documenting:
- Project bootstrapped with `/project-setup`
- Vault created, memory initialized, N custom skills generated
- List the custom skills created
- Next steps

**ARCHITECTURE_DECISIONS_LOG.md:** Empty template with format instructions (same as ClawForge pattern — What/Why/Why-not-alternatives/Impact per decision)

### Phase 4: Generate CLAUDE.md

Create `CLAUDE.md` at the project root with:

```markdown
# <Project Name> — Claude Instructions

## Session Persistence Protocol

**At the END of every session** (or when context is getting long), you MUST:

1. **Update `<slug>_current_status.md`** in Claude memory with:
   - What was accomplished this session
   - Current phase/task
   - Any blockers or decisions made
   - Next steps for the following session

2. **Create/update a session log** in Obsidian at `<vault>/07-session-logs/SESSION_LOG.md`:
   - Append a dated entry with: what changed, files touched, decisions made
   - Keep entries concise (3-5 bullet points per session)

3. **Update any stale memory files** if architecture decisions changed or new patterns were established.

**At the START of every session**, you MUST:
1. Read `<slug>_current_status.md` from memory
2. Read the latest session log entry from Obsidian
3. Resume from where we left off without asking for a recap

---

## Project Context

<one-sentence description from Phase 0>
- Obsidian vault: `<vault>/` (use wiki-links in any .md files there)
- Architecture decisions: `02-architecture/ARCHITECTURE_DECISIONS_LOG.md`
- Custom skills: `.claude/commands/<slug>/` (<N> project-specific skills)

---

## Skill Routing — What To Use When

### <Project Name> Development
| Task | Skill | How to invoke |
|---|---|---|
<For each custom skill generated in Phase 2, add a row>
| <task description> | `/<slug>:<skill-name>` | <brief note> |

### Context & Execution
| Task | Skill | How to invoke |
|---|---|---|
| Load all context before work | `/preload` | Reads memory + vault + decisions + preferences → execution brief |
| Keep context fresh (loop) | `/sync-context` | Use with `/loop 15m /sync-context` — drift detection + preference refresh |

### Decision Making
| Task | Skill | How to invoke |
|---|---|---|
| Any significant decision | `/decide` | Scales agents to decision size, researches industry standards, runs structured debate |
| Minor choice (naming, location) | `/decide --size minor` | 2-3 agents, quick research |
| Medium choice (library, pattern) | `/decide --size medium` | 4-6 agents, research + debate |
| Major choice (architecture, framework) | `/decide --size major` | 8-12 agents, deep research + multi-round debate |

### Project Management
| Task | Skill | How to invoke |
|---|---|---|
| Plan a phase | `/gsd:plan-phase` | Creates executable plan |
| Execute a phase | `/gsd:execute-phase` | Wave-based parallel execution |
| Check progress | `/gsd:progress` | Status + next action routing |
| Debug a bug | `/gsd:debug` | Scientific method debugging |
| Quick task | `/gsd:quick` | Atomic commits, state management |
| Code review | `/coderabbit:code-review` | AI code review |

### Supplementary Agents (use when custom skills aren't enough)
<Add 3-5 relevant agents/plugins based on tech stack. NOT as primary routing — only as fallback when the custom skill doesn't cover the specific case>

---

## Decision Protocol (Always Active)

When you encounter a decision that affects code architecture, library choice, data modeling, security approach, or any choice that touches >3 files or is hard to reverse:

1. **Auto-detect the decision size** (minor/medium/major)
2. **Invoke `/decide`** with the decision description
3. **Wait for the research + debate to complete** before implementing
4. **The accepted verdict gets logged** to `02-architecture/ARCHITECTURE_DECISIONS_LOG.md`

**When to trigger automatically (no need to ask):**
- Choosing a new library or dependency
- Designing a new data model or schema
- Selecting between 2+ reasonable architecture patterns
- Any security-related implementation choice

**When to ask first:**
- Refactoring existing code to a different pattern
- Changing a previously-made decision
- Decisions with tight deadlines where research time matters

**Never trigger for:**
- Following an already-decided pattern
- Naming that matches existing conventions
- File placement within established structure
- Bug fixes with an obvious correct approach

---

## Domain-Specific Rules (Always Active)

<Generate from Phase 0 question 7 answers. Format as numbered rules like ClawForge:>
1. **<Rule name>**: <concrete rule with specific patterns/types>
2. **<Rule name>**: <another rule>
...

---

## Communication Style

<From Phase 0 question 9>
```

### Phase 5: Create Memory Files

Create in the Claude memory directory:

**MEMORY.md (index):**
```markdown
# Memory Index

## User
- (user memories added as project progresses)

## Feedback
- (feedback memories added as preferences are learned)

## Project
- [<slug>_current_status.md](<slug>_current_status.md) - Current development status and next steps

## Reference
- [reference_vault.md](reference_vault.md) - Obsidian vault location and structure
- [reference_custom_skills.md](reference_custom_skills.md) - Custom skills created for this project
```

**<slug>_current_status.md:**
```markdown
---
name: <Project Name> Development Status
description: Current status of <Project Name> — phase, blockers, next steps
type: project
---

## Status as of <today YYYY-MM-DD>

**Phase:** Project initialization complete
**What's done:**
- Obsidian vault with 7-folder structure
- CLAUDE.md with session persistence protocol
- <N> custom project skills created
- Memory system initialized

**Custom skills created:**
<List each skill with one-line description>

**What's NOT done yet:**
- Architecture decisions (pending)
- Phase planning (pending)
- Implementation (pending)

**Next immediate step:** Define architecture decisions, or run `/gsd:new-project` for detailed planning

**Why:** Fresh project setup — infrastructure ready for planning or development.
**How to apply:** Start next session by reading this file + latest session log entry.
```

**reference_vault.md:**
Standard vault reference with location + structure + conventions.

**reference_custom_skills.md:**
```markdown
---
name: Custom Project Skills
description: <N> custom skills for <Project Name> at .claude/commands/<slug>/ — scaffold, endpoint, test, quality, security, dep-add
type: reference
---

## Skills Location
`.claude/commands/<slug>/`

## Available Skills

| Skill | Command | When to use |
|---|---|---|
<Table of all created skills>

## Also Available
- GSD skills (`/gsd:*`) for project management
- <Relevant plugins> for specialized tasks

## Skill Design Source
Skills were generated based on: <tech stack>, <domain rules>, <core types>, <folder structure> from project initialization.
When project patterns evolve significantly, skills may need updating.
```

### Phase 6: Optional Research Phase

If `--skip-research` was NOT passed:
> "Want me to run multi-agent research on your domain? This populates `01-research/` with market analysis, competitive landscape, and technical feasibility. (y/n)"

If yes, spawn 4-6 agents in parallel, synthesize into `01-research/RESEARCH_SYNTHESIS.md`.

### Phase 7: Verification & Summary

**Verify:**
- [ ] `.claude/commands/<slug>/` exists with N skill files
- [ ] Each skill has valid YAML frontmatter (name, description, argument-hint)
- [ ] Each skill has project-specific patterns (not generic advice)
- [ ] `CLAUDE.md` exists with session persistence protocol + skill routing
- [ ] Obsidian vault has all 7 numbered folders + HOME.md
- [ ] `SESSION_LOG.md` has Session 1 entry with today's date
- [ ] Memory MEMORY.md index links to status + reference files
- [ ] `<slug>_current_status.md` exists with initial status
- [ ] Skill routing table in CLAUDE.md matches actual skill files
- [ ] All wiki-links in vault resolve correctly

**Print summary:**
```
Project "<Project Name>" initialized.

Obsidian vault: <vault-name>/ (7 folders + hub)
CLAUDE.md:      Session persistence + skill routing + <N> domain rules
Memory:         MEMORY.md + status tracker + vault reference + skills reference
Custom skills:  .claude/commands/<slug>/ (<N> skills)

Skills created:
  /<slug>:<skill-1>  — <description>
  /<slug>:<skill-2>  — <description>
  /<slug>:<skill-3>  — <description>
  ...

Session persistence ACTIVE. Each session auto-updates:
  1. Memory: <slug>_current_status.md
  2. Obsidian: <vault>/07-session-logs/SESSION_LOG.md

Next steps:
  - `/gsd:new-project` for detailed phase planning
  - Or start building — session tracking + custom skills are ready
```

## Rules

1. **Skills MUST be project-specific.** If a skill could work for any project without modification, it's too generic. Every skill must reference concrete project types, paths, patterns, or conventions.
2. **Skills encode the project's own rules.** If the project has "tenant_id in every query", every skill that touches data must enforce it. If the project uses shadcn, every component skill must import from the design system.
3. **Minimum 5 skills, maximum 12.** Under 5 means you didn't identify enough recurring tasks. Over 12 means skills are too granular — merge related ones.
4. **Skills use the project's ACTUAL code templates.** Not pseudocode, not "add appropriate imports" — real import paths, real utility functions, real folder structure.
5. **CLAUDE.md routes to custom skills FIRST, generic agents SECOND.** The skill routing table puts project-specific skills as the primary recommendation. Generic agents are supplementary fallback only.
6. **All Obsidian files use wiki-links** (`[[path|display]]`). Never relative markdown links.
7. **Memory files use YAML frontmatter** with `name`, `description`, `type`.
8. **Session log is append-only** — never rewrite old entries.
9. **Convert relative dates to absolute** (e.g., "next week" → "2026-03-29").
10. **Don't over-generate content.** Templates with clear sections to fill in > fake placeholder content. But custom skills MUST have real code templates.
11. **Adapt the number and type of skills to the project.** A CRUD app needs different skills than a real-time system. A mobile app needs different skills than a CLI tool. Don't force-fit categories.
