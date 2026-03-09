#!/bin/bash
# plan-review-enforcer.sh — PostToolUse hook for Write/Edit
# When a plan file is saved to ~/.claude/plans/, records the path and
# injects additionalContext telling Claude to run review-plan immediately.
# Uses session-scoped tracking to avoid re-triggering during review edits.
# Exit 0 = success (always — PostToolUse can't block)

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect Write and Edit tool calls
[[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

# Check if this is a plan file (.claude/plans/*.md pattern)
if [[ "$FILE_PATH" == */.claude/plans/*.md ]]; then
  # Skip if the plan already has a Decision Brief (review complete — any tier)
  if [[ -f "$FILE_PATH" ]] && grep -q '^## Decision Brief' "$FILE_PATH"; then
    exit 0
  fi

  # Session-scoped tracking file
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
  TRACK_FILE="/tmp/claude-plan-review-${SESSION_ID}"

  # If review was already requested for this file in this session, skip
  if [[ -f "$TRACK_FILE" ]] && [[ "$(cat "$TRACK_FILE")" == "$FILE_PATH" ]]; then
    exit 0
  fi

  # Record and inject
  echo "$FILE_PATH" > "$TRACK_FILE"

  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "You just saved a plan file. Run /review-plan on it before calling ExitPlanMode."
  }
}
ENDJSON
fi

exit 0
