---
name: skill-create
description: "Meta-skill: create a new Claude Code skill (.claude/commands/*.md) with correct structure, model routing, and project conventions baked in."
argument-hint: "<skill-name> [--project <slug>] [--category global|<project>] [--from-pattern <description>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

<objective>
A skill that creates new skills. Ensures every generated skill:
1. Follows the correct YAML frontmatter format
2. Has clear `<objective>`, `<context>`, and `## Process` sections
3. Includes explicit model routing (per `/route-model`)
4. Encodes project-specific patterns (not generic advice)
5. Has a rules section covering edge cases

**Two modes:**
- **Global skill** — goes in `.claude/commands/` — applies to all projects
- **Project skill** — goes in `.claude/commands/<project-slug>/` — project-specific

**From pattern:** Can analyze existing similar skills to derive the structure before writing the new one.
</objective>

<context>
**Arguments:**
- `<skill-name>` — Name of the skill (e.g., `deploy-check`, `db-migrate`, `api-test`)
- `--project <slug>` — If project-scoped, the project slug (e.g., `my-project`, `my-api`, `e-commerce-app`)
- `--category global|<project>` — Shorthand for `--project`. `global` puts it in root commands.
- `--from-pattern <description>` — Describe an existing skill to use as a structural template.
</context>

## Process

### Step 1: Gather Skill Requirements

Ask the user:

1. **What task does this skill automate?** (one sentence)
2. **When should it be used?** (trigger conditions)
3. **What arguments does it take?** (inputs, flags, optional/required)
4. **What does it produce?** (output, files created, commands run)
5. **Is it global or project-specific?**
   - If project-specific: what project patterns/types/paths must it know?
6. **What's the most common mistake or misuse to prevent?**

### Step 2: Find Structural Template

If `--from-pattern` provided, read similar existing skills for structure reference:

```
Searching for: <pattern description>
Found similar skills:
- /rust:scaffold — scaffold with code templates
- /review — two-stage with model routing
- /decide — scaled agent deployment

Using <best match> as structural template.
```

Otherwise, select template based on skill type:
- **Scaffold/generate** → use `/rust:scaffold` pattern
- **Analysis/review** → use `/review` pattern
- **Agent deployment** → use `/decide` pattern
- **Workflow enforcement** → use `/workflow-gate` pattern
- **Simple utility** → use `/verify` pattern (checklist-based)

### Step 3: Design the Skill

Draft the skill design before writing the file:

```
SKILL DESIGN: <name>
─────────────────────
File: .claude/commands/<path>/<name>.md
Name: <slug>:<name> or <name>
Category: <global/project>

Objective: <one paragraph>
Arguments: <list>
Process:
  1. <step>
  2. <step>
  3. <step>
Output: <what it produces>

Model routing:
  - <task> → haiku (why)
  - <task> → sonnet (why)
  - <task> → opus (why)

Project-specific knowledge to encode:
  - Types: <list>
  - Paths: <list>
  - Patterns: <list>
  - Rules: <list>
```

Show this to the user and confirm before writing the file.

### Step 4: Write the Skill File

Write the skill file following the canonical format:

```markdown
---
name: <slug>:<name> or <name>
description: "<one-line description — what it does + when>"
argument-hint: "<args with real examples>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash   # only if shell commands needed
  - Glob
  - Grep
  - Agent  # only if spawning subagents
  - AskUserQuestion  # only if interactive
---

<objective>
<What this skill does, when to use it, what makes it project-specific>

**Model routing:**
- <task type> → `<model>` (reason)
</objective>

<context>
**Arguments:**
- `<arg>` — Description with valid values
</context>

## Process

### Step 1: <First meaningful step>

<Concrete instructions with actual project paths, types, patterns>

### Step 2: <Next step>

<More concrete instructions>

## Output

<What the skill produces — format, location, content>

## Rules

1. <Most important constraint>
2. <Second constraint>
...
N. **Model routing is explicit.** Every Agent call specifies a model tier.
```

### Step 5: Verify the Skill

After writing:
1. Re-read the written file
2. Check: does the description appear in the skill list? (it will once Claude Code reloads)
3. Verify YAML frontmatter is valid (no tabs, correct indentation)
4. Verify the skill name matches the file path convention

### Step 6: Update Routing Tables

If project-specific skill: add to the project's CLAUDE.md skill routing table.
If global skill: add to the global CLAUDE.md (if it has a skill routing section).

```
Added to CLAUDE.md:
| <task> | `/<slug>:<name>` | <when to use> |
```

## Skill Naming Conventions

- **Global skills:** `verb-noun` → `review`, `decide`, `dispatch`, `verify`, `tdd`
- **Project skills:** `<project>:verb-noun` → `rust:scaffold`, `ag-bridge:new-tool`
- **Namespace separator:** `:` for project scope
- **No hyphens in namespace:** `ag-bridge` not `ag_bridge`
- **Action-first naming:** `new-component` not `component-new`

## Quality Checklist

- [ ] YAML frontmatter has: `name`, `description`, `argument-hint`
- [ ] `allowed-tools` only includes tools the skill actually uses
- [ ] `<objective>` explains what AND when (not just what)
- [ ] Arguments are documented with valid values, not just names
- [ ] Process steps are concrete (specific paths, types, commands) — not generic advice
- [ ] Model routing is explicit for every Agent call
- [ ] Rules section has at least 5 rules
- [ ] No copy-paste from a template without customizing for THIS skill's domain
- [ ] Skill is findable via its description in the skill list

## Rules

1. **Ask before writing.** Show the design to the user and confirm before creating the file.
2. **Concrete over generic.** If the skill could apply to any project unchanged, it's not project-specific enough.
3. **Model routing is non-negotiable.** Every new skill that spawns agents MUST include explicit model routing.
4. **Minimum 5 rules.** Skills without a strong rules section become ambiguous in edge cases.
5. **Update routing tables.** A skill that isn't in CLAUDE.md's routing table won't be used consistently.
6. **Template from existing, don't invent.** The existing skills are battle-tested patterns. Derive from them.
7. **One skill, one purpose.** If you're tempted to add `--mode`, consider if this should be two skills.
