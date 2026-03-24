---
paths:
  - "**/plans/**"
---

# Plan Pre-Check

Before implementing changes from a plan, transcript, or prior session:

1. **Check recent commits** — `git log --oneline -5 -- <files>` for each file in the plan's "Files Modified" table
2. **Check working tree** — `git diff HEAD -- <files>` to see if changes are already applied
3. **If already applied:** Report "Plan already applied in commit [hash]" and skip the code changes. Proceed with any non-code steps (DB migrations, deploys, etc.).
4. **If partially applied:** Identify which steps remain and continue from there
5. **If not applied:** Proceed normally

This prevents redundant Edit calls when re-entering a plan from a previous session or transcript.

# Plan Review System (Auto-Tiered)

Plans saved to `~/.claude/plans/` are automatically reviewed at proportional depth. Two hooks + the review-plan skill handle the flow.

## How It Works

1. **Save plan** → `plan-review-enforcer.sh` (PostToolUse) fires, injects "run /review-plan"
2. **Review-plan skill** classifies the plan into a tier (Step 0), runs the appropriate depth
3. **ExitPlanMode** → `plan-review-gate.sh` (PreToolUse) checks for `## Decision Brief` before allowing

## Tiers

| Tier | Signals | What runs | Sections added |
|------|---------|-----------|----------------|
| **Light** | ≤3 files, easily reversible, config edits, simple bug fixes | Reviewed marker only | `## Reviewed` |
| **Standard** | 4+ files, core logic/APIs, new patterns or deps | 5-lens review + direct improvements | `## Reviewed` |
| **Deep** | Architecture, hard-to-reverse changes, security-sensitive, or user-requested | Full review + cold subagent + direct improvements | `## Reviewed` |

## Hook Details

- **plan-review-enforcer.sh** (PostToolUse:Write|Edit) — fires once per plan per session. Skips if `## Reviewed` already exists.
- **plan-review-gate.sh** (PreToolUse:ExitPlanMode) — blocks until `## Reviewed` is present.
- Hooks don't hot-reload — changes require new session.

## Key Points

- Classification is automatic — no user intervention needed
- The review-plan skill states the tier and rationale before proceeding
- `## Reviewed` is the universal gate marker (all tiers produce it)
- Reviews improve the plan directly — no separate Decision Brief or Review Notes sections
- If `## Reviewed` already exists (from a prior pass), review leaves it in place
- Plan file overwrite caution: check for existing reference material before using Write on plan files

## Parallel Task Group Insertion

When inserting a new parallel task block into a script, trace which tasks use `&` (background/parallel) vs. inline (sequential):

- Tasks with `&` at the end run in the parallel group
- The first task WITHOUT `&` is sequential — it runs after the parallel group
- Insert new parallel tasks BEFORE that first sequential task, not after it

**Wrong:** Inserting after the last `&` task but after an inline sequential task lands you outside the parallel group.
**Right:** Find the line where the parallel group ends (last `&` task + `wait`), insert the new `&` task before the `wait` call or before the first inline sequential task.
