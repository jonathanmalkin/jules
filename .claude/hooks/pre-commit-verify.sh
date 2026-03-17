#!/bin/bash
# pre-commit-verify.sh — PreToolUse hook for Bash commands
# When a git commit is about to run, injects additionalContext reminding
# Claude to verify before committing (tests, diff review, clean workspace).
# Also reminds about /wrap-up once per session (learning pipeline entry point).
# Exit 0 = allow (with advisory context)

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect Bash commands
[[ "$TOOL" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Only trigger on git commit commands
if echo "$COMMAND" | grep -qE '\bgit\b.*\bcommit\b'; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
  VERIFIED=false
  WRAPUP_REMINDED=false

  [[ -f /tmp/claude-verified-this-session ]] && VERIFIED=true
  WRAPUP_TRACK="/tmp/claude-wrapup-reminded-${SESSION_ID}"
  [[ -f "$WRAPUP_TRACK" ]] && WRAPUP_REMINDED=true

  # Build advisory message from applicable parts
  MSG=""

  if ! $VERIFIED; then
    MSG="PRE-COMMIT CHECK: Before committing, confirm you have: (1) run relevant tests and they pass, (2) reviewed the staged diff for unintended changes or debug artifacts, (3) checked for temp files or .env changes that shouldn't be committed. If you've already verified, create /tmp/claude-verified-this-session to suppress this reminder."
  fi

  if ! $WRAPUP_REMINDED; then
    touch "$WRAPUP_TRACK"
    WRAPUP_MSG="WRAP-UP REMINDER: This session has commits. Remember to /wrap-up before ending — it feeds the learning pipeline (session reports, memory updates, terrain, morning briefing)."
    if [ -n "$MSG" ]; then
      MSG="$MSG | $WRAPUP_MSG"
    else
      MSG="$WRAPUP_MSG"
    fi
  fi

  # Emit combined advisory if there's anything to say
  if [ -n "$MSG" ]; then
    # Use jq to safely encode the message as JSON string
    printf '%s' "$MSG" | jq -Rs '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:.}}'
  fi
fi

exit 0
