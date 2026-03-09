#!/bin/bash
# plan-review-gate.sh — PreToolUse hook for ExitPlanMode
# Blocks ExitPlanMode if a plan file was recently written (to ~/.claude/plans/)
# but doesn't contain "## Decision Brief" (required for all review tiers).
# Light-tier reviews produce only a Decision Brief (no Review Notes) — that's correct.
# Uses session-scoped tracking to avoid cross-session collisions.
# Content-based check — immune to write-order race conditions.
# Exit 0 = allow, Exit 2 = block

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only gate ExitPlanMode
[[ "$TOOL" != "ExitPlanMode" ]] && exit 0

# Session-scoped tracking file
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRACK_FILE="/tmp/claude-plan-review-${SESSION_ID}"

# Check if there's a plan file path recorded for this session
[[ ! -f "$TRACK_FILE" ]] && exit 0

PLAN_FILE=$(cat "$TRACK_FILE")
[[ -z "$PLAN_FILE" || ! -f "$PLAN_FILE" ]] && exit 0

# Content-based check: does the plan have the required Decision Brief?
if ! grep -q '^## Decision Brief' "$PLAN_FILE"; then
  echo "BLOCKED: Plan file '$PLAN_FILE' is missing Decision Brief. Run /review-plan on it first." >&2
  exit 2
fi

# Decision Brief present — clean up and allow
mv -f "$TRACK_FILE" ~/.Trash/ 2>/dev/null || true
exit 0
