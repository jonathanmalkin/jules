---
name: wrap-up
description: Use when user says "wrap up", "close session", "end session", "wrap things up", "close out this task", or invokes /wrap-up — runs end-of-session checklist for shipping, memory, and self-improvement
---

# Session Wrap-Up

Run four phases in order. All phases auto-apply without asking; present a consolidated report at the end.

## Phase 1: Retro

Run `/retro-deep`. It handles issue extraction, pattern scanning, cross-referencing, and fix application. Don't inline any of its logic — delegate completely.

After retro-deep completes, run the **determinism scan** on this session:

Were any new instructions written to skills, rules, or CLAUDE.md? For each: is it mechanical (same input, same output, no judgment)? If yes, flag it as a script candidate. Apply the test: "If 10 different LLMs got this instruction, would they all do exactly the same thing?" If yes, create the script in `.claude/scripts/` and update the instruction to call it.

## Phase 2: Session Report

Create the session report using your session report scaffold script (or manually):

```markdown
# Session Report — [date]

**Session focus:** [1 sentence — what was the main goal?]

## What Got Done
- [Concrete outcomes — shipped code, created files, decisions made]
- **Signal check:** [Did this session move something toward a real person? Deployed, published, emailed — or internal-only?]

## Decisions Made
- [Brief — full rationale lives in decision-log.md]

## Open Items
- [Unfinished, blocked, or needs attention next session]

## Commitments Made
- [**What** — by when — to whom (if applicable)]

## Context for Next Session
- [WIP state, gotchas, things to watch for]

## Compaction Health
[Output from compaction stats script if available]
```

Skip empty sections. Include the autonomy report — decisions made autonomously, standing orders exercised. Skip the autonomy section if nothing to report.

## Phase 3: Update Terrain

Re-read `Terrain.md` before editing (sync tools may have modified it).

1. Remove completed items — don't log them (session report already did)
2. Update project statuses and task items
3. Resolve answered questions, add new ones
4. Log significant decisions to `documents/decision-log.md` with `**Status:** revisit-by-YYYY-MM-DD` where applicable

Only touch sections affected by the session. If nothing changed, say "Terrain is current."

## Phase 4: Ship

Stage and commit all session artifacts (session report, Terrain updates, any modified config) with a descriptive commit message:

```
Wrap-up: <brief description of session>
```
