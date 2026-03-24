---
name: sync-context
description: "Loop-compatible context refresh — re-reads memory, decisions, preferences, and surfaces drift warnings. Use with /loop 15m /sync-context"
argument-hint: "[--project <name>]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

<objective>
Lightweight context refresh designed to run on a loop during long work sessions. Prevents preference drift, forgotten decisions, and stale context.

**Use with:** `/loop 15m /sync-context`

This is NOT a full preload — it's a quick checkpoint that:
1. Re-reads the active rules and preferences that matter RIGHT NOW
2. Checks if any decisions were made this session that should be remembered
3. Flags if you're violating any established patterns
4. Reminds of the communication style and domain rules
5. Checks context window health

Designed to be fast (~10 seconds) and non-disruptive.
</objective>

<context>
**Arguments:**
- `--project <name>` — Focus on specific project. If omitted, use last-loaded project from `/preload` or detect from directory.
</context>

## Process

### Step 1: Quick Memory Refresh

Read these files ONLY (not the full memory system):

1. **Active status file** — whichever project is active:
   - `clawforge_current_status.md` OR
   - `ag_bridge_current_status.md` OR
   - `<project>_current_status.md`

   Extract: current phase, next action, blockers

2. **Feedback/preferences file** — `feedback_communication.md`

   Extract: communication rules

3. **CLAUDE.md** domain rules section ONLY (not full file)

   Extract: numbered rules list

### Step 2: Decision Recall

Check if any architecture decisions are relevant to what's currently being worked on:

1. Scan the last few messages in the conversation for keywords matching decision topics
2. If a match: re-read that specific decision and surface it

Example: If the conversation mentions "adding a dependency", surface Decision #4 (default-features = false, no openssl-sys, cargo audit).

Example: If the conversation mentions "logging" or "debug", surface Decision #1 (VaultSecret, no Debug derives on secrets).

### Step 3: Drift Detection

Check for patterns that violate established rules:

**For Rust/ClawForge projects:**
- Any recent code that uses `unwrap()` outside tests → flag
- Any `String` type where `VaultSecret<T>` should be used → flag
- Any DB query missing `tenant_id` → flag
- Any `#[derive(Debug)]` on types near secrets → flag

**For Next.js/Supabase projects:**
- Any Supabase query without RLS context → flag
- Any `console.log` left in production code → flag
- Any hardcoded API keys or secrets → flag

**For any project:**
- Check if domain rules from CLAUDE.md are being followed
- Check if communication style is being respected (are responses too verbose? too basic?)

### Step 4: Session Health Check

Quick checks:
- Are there uncommitted changes that should be committed?
- Is the session log up to date? (Has it been >2 hours since last entry?)
- Are there pending TODOs that were supposed to be done this session?
- Has the conversation been going long without updating the status file?

### Step 5: Output Sync Report

Keep it SHORT — this runs every 15 minutes, it shouldn't be a wall of text.

```
──── SYNC @ <time> ────
Phase: <current phase/task>
Rules active: <count> (<list names only>)
Decisions relevant: #<N> <title> (if any match current work)
Drift: <"Clean" or list violations>
Health: <"OK" or warnings>
────────────────────────
```

**Only expand if there's a problem:**

```
──── SYNC @ <time> ────
Phase: Phase 1 Week 1 — Core Types
Rules active: 7 (secrets, tenant, errors, deps, testing, unwrap, crates)
Decisions relevant: #1 VaultSecret<T> (you're working on credential types)
⚠ Drift: Found `unwrap()` at line 47 of tenant.rs — use `?` or `.expect("reason")`
⚠ Health: 3 uncommitted files, last commit 2h ago
Reminder: User wants advanced analysis, no basic explanations
────────────────────────
```

### Step 6: Preference Reinforcement

At the END of every sync, silently re-internalize these (don't print unless violated):

**From feedback_communication.md:**
- Advanced, no-BS analysis
- No basic or obvious advice
- Honest assessments over encouragement
- Frame in terms of AI-assisted development

**From CLAUDE.md communication style:**
- Lead with action, not reasoning
- When something is wrong, say it directly
- Don't explain basic concepts unless asked

**From user_profile.md:**
- 16yo, advanced AI knowledge, basic programming
- Uses Claude Code for 99% of coding
- Building SaaS for Greek market

These preferences are ALWAYS ACTIVE. The sync just makes sure they haven't been forgotten mid-conversation.

## Loop Integration

**Recommended setup:**
```
/loop 15m /sync-context
```

This runs every 15 minutes during active work. Adjust timing:
- `10m` for intense coding sessions with many decisions
- `20m` for research/planning sessions
- `30m` for review/documentation sessions

**What happens on each loop iteration:**
1. Quick read of 3 files (~2 seconds)
2. Drift scan of recent conversation (~3 seconds)
3. Health check (~2 seconds)
4. Print compact report (~1 second)
5. Re-internalize preferences (silent)

Total: ~8 seconds per sync. Minimal disruption.

## Rules

1. **Fast and quiet when clean.** If nothing is wrong, the report is 4 lines. Don't waste the user's attention.
2. **Loud when drifting.** If rules are being violated or preferences forgotten, expand the warning with specifics.
3. **Never modify files.** This is read-only. If something needs fixing, flag it — don't fix it.
4. **Preference reinforcement is silent.** Don't say "Reminder: you want advanced analysis" every 15 minutes. Just internally re-apply it. Only print if the CURRENT conversation is violating it.
5. **Decision recall is contextual.** Only surface decisions that match what's currently being discussed. Don't dump all decisions every sync.
6. **Multi-project aware.** If the user switched projects mid-session, detect it and load the right context.
7. **Don't repeat yourself.** If you flagged the same drift issue last sync and it hasn't been addressed, escalate the severity — don't just print the same message.
