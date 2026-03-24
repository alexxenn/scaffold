---
description: Generate or update an AGENTS.md file — universal AI agent instructions that work with Claude Code, Cursor, GitHub Copilot, and any AI that reads agent config files.
argument-hint: "[--generate | --update | --diff]"
---

# Agents MD

AGENTS.md is to AI agents what README.md is to humans. Every AI tool that touches your repo should read it.

Claude Code reads CLAUDE.md. Cursor reads .cursorrules. GitHub Copilot reads .github/copilot-instructions.md. AGENTS.md is the universal standard that all of them check.

## Mode: --generate (default)

Scan the project and generate AGENTS.md from scratch.

**Phase 1 — Discovery** (haiku):
- Read CLAUDE.md if it exists
- Scan directory structure (top 2 levels)
- Check package.json / Cargo.toml / pyproject.toml for tech stack
- Look for existing .cursorrules or copilot-instructions.md

**Phase 2 — Generate** (sonnet):

Output AGENTS.md with these sections:

```markdown
# AGENTS.md

## Project Overview
[1 paragraph: what this project does]

## Tech Stack
[languages, frameworks, key libraries]

## Directory Structure
[annotated tree of top-level dirs]

## Coding Conventions
[naming, file organization, patterns — derived from existing code]

## Key Files
[entry points, config files, files that affect everything]

## Testing
[how to run tests, where tests live, what's expected]

## Do / Don't
[project-specific rules every agent must follow]

## Domain Rules
[security rules, data handling, patterns that must never be violated]
```

Also creates symlinks/copies for tool-specific locations:
- `.github/copilot-instructions.md` → AGENTS.md content
- `.cursorrules` → AGENTS.md content (Cursor format)

## Mode: --update

Re-scan the project and update AGENTS.md sections that are stale:
- Detect if tech stack changed (new dependencies)
- Detect if directory structure changed
- Preserve manually edited sections (marked with `<!-- manual -->`)

## Mode: --diff

Show what has changed in the project since AGENTS.md was last generated. Highlights sections that need updating.

## Why this matters

GitHub issue #6235 for a universal AGENTS.md standard got 3,367 upvotes. It's the most-requested feature for AI-assisted development. Having AGENTS.md means:
- New AI tools onboard instantly
- Context doesn't drift between tools
- Team members using different AI tools get consistent behavior

## Model routing

- Discovery phase: haiku (file reading, structure analysis)
- Generation phase: sonnet (synthesis and writing)
- No opus needed
