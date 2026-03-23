---
paths:
  - "**/plans/**"
---

# Plan Review System (Auto-Tiered)

Plans saved to `~/.claude/plans/` are automatically reviewed at proportional depth. Two hooks + the review-plan skill handle the flow.

## How It Works

1. **Save plan** -> `plan-review-enforcer.sh` (PostToolUse) fires, injects "run /review-plan"
2. **Review-plan skill** classifies the plan into a tier (Step 0), runs the appropriate depth
3. **ExitPlanMode** -> `plan-review-gate.sh` (PreToolUse) checks for `## Reviewed` before allowing

## Tiers

| Tier | Signals | What runs | Sections added |
|------|---------|-----------|----------------|
| **Light** | <=3 files, easily reversible, config edits, simple bug fixes | Reviewed marker only | `## Reviewed` |
| **Standard** | 4+ files, core logic/APIs, new patterns or deps | 5-lens review + direct improvements | `## Reviewed` |
| **Deep** | Architecture, hard-to-reverse changes, security-sensitive, or user-requested | Full review + cold subagent + direct improvements | `## Reviewed` |

## Hook Details

- **plan-review-enforcer.sh** (PostToolUse:Write|Edit) -- fires once per plan per session. Skips if `## Reviewed` already exists.
- **plan-review-gate.sh** (PreToolUse:ExitPlanMode) -- blocks until `## Reviewed` is present.
- Hooks don't hot-reload -- changes require new session.

## Key Points

- Classification is automatic -- no user intervention needed
- The review-plan skill states the tier and rationale before proceeding
- `## Reviewed` is the universal gate marker (all tiers produce it)
- Reviews improve the plan directly -- no separate Decision Brief or Review Notes sections
- If `## Reviewed` already exists (from a prior pass), review leaves it in place
- Plan file overwrite caution: check for existing reference material before using Write on plan files
