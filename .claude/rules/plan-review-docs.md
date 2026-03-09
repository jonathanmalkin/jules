---
paths:
  - "**/plans/**"
---

# Plan Review System (Auto-Tiered)

Plans saved to `~/.claude/plans/` are automatically reviewed at proportional depth. Two hooks + the review-plan skill handle the flow.

## How It Works

1. **Save plan** -> `plan-review-enforcer.sh` (PostToolUse) fires, injects "run /review-plan"
2. **Review-plan skill** classifies the plan into a tier (Step 0), runs the appropriate depth
3. **ExitPlanMode** -> `plan-review-gate.sh` (PreToolUse) checks for `## Decision Brief` before allowing

## Tiers

| Tier | Signals | What runs | Sections added |
|------|---------|-----------|----------------|
| **Light** | <=3 files, easily reversible, config edits, simple bug fixes | Decision Brief only (compressed format) | `## Decision Brief` |
| **Standard** | 4+ files, core logic/APIs, new patterns or deps | 5-lens review + improvements | `## Review Notes` + `## Decision Brief` (full Recommendation block) |
| **Deep** | Architecture, hard-to-reverse changes, security-sensitive, or user-requested | Full review + cold subagent | `## Review Notes` (with cold review) + `## Decision Brief` (full Recommendation block) |

## Hook Details

- **plan-review-enforcer.sh** (PostToolUse:Write|Edit) -- fires once per plan per session. Skips if `## Decision Brief` already exists.
- **plan-review-gate.sh** (PreToolUse:ExitPlanMode) -- blocks until `## Decision Brief` is present. Light-tier plans without `## Review Notes` pass correctly.
- Hooks don't hot-reload -- changes require new session.

## Key Points

- Classification is automatic -- no user intervention needed
- The review-plan skill states the tier and rationale before proceeding
- `## Decision Brief` is the universal gate marker (all tiers produce it)
- `## Review Notes` only appears for Standard and Deep tiers
- If `## Decision Brief` already exists (from a prior pass), review updates it in-place
- Plan file overwrite caution: check for existing reference material before using Write on plan files
