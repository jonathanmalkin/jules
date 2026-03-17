#!/bin/bash
# clipboard-validate.sh — PostToolUse hook for Bash (pbcopy), Write, and Edit
# Validates outbound content against platform limits, UTM tags, sensitive data, and voice style.
# Fires on:
#   Bash: commands piping to pbcopy (clipboard writes)
#   Write/Edit: writes to content pipeline staging dirs or /tmp/claude-copy-for* files
# Returns additionalContext with warnings; exits 2 (block) on API key detection.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

SCRIPT_DIR="$(dirname "$0")/../scripts"
CONTENT_FILE=""
CLEANUP_TEMP=0

# ── Determine whether to fire and what file to scan ──────────────────────────

if [[ "$TOOL" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  [[ -z "$COMMAND" ]] && exit 0

  # Only fire on commands that pipe to pbcopy
  echo "$COMMAND" | grep -q 'pbcopy' || exit 0

  # Gate: only validate if the copy-for temp file exists and was recently written (< 60s)
  CONTENT_FILE="/tmp/claude-copy-for.txt"
  [[ ! -f "$CONTENT_FILE" ]] && exit 0

  if [[ "$(uname)" == "Darwin" ]]; then
    FILE_MOD=$(stat -f "%m" "$CONTENT_FILE" 2>/dev/null)
  else
    FILE_MOD=$(stat -c "%Y" "$CONTENT_FILE" 2>/dev/null)
  fi
  NOW=$(date +%s)
  if [[ -n "$FILE_MOD" ]] && (( NOW - FILE_MOD > 60 )); then
    exit 0
  fi

elif [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  [[ -z "$FILE_PATH" ]] && exit 0

  # Only scan content pipeline staging dirs and clipboard temp files
  echo "$FILE_PATH" | grep -qE '(/tmp/claude-copy-for|Documents/Content-Pipeline/(03-Staged|04-Approved))' || exit 0

  if [[ "$TOOL" == "Write" ]]; then
    # For Write, content is in tool_input — extract to temp file for scanning
    CONTENT_FILE=$(mktemp /tmp/clipboard-validate-XXXXXX)
    CLEANUP_TEMP=1
    echo "$INPUT" | jq -r '.tool_input.content // empty' > "$CONTENT_FILE"
  else
    # For Edit, file already exists on disk
    CONTENT_FILE="$FILE_PATH"
  fi
else
  exit 0
fi

WARNINGS=""
BLOCK=0

# 1. Platform-specific validation (Bash/clipboard only — skip for Write/Edit pipeline files)
if [[ "$TOOL" == "Bash" ]]; then
  PLATFORM_FILE="/tmp/claude-copy-for-platform.txt"
  if [[ -f "$PLATFORM_FILE" ]]; then
    PLATFORM=$(cat "$PLATFORM_FILE" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    PLATFORM_RESULT=$("$SCRIPT_DIR/validate-platform-content.sh" "$PLATFORM" "$CONTENT_FILE" 2>&1)
    if [[ $? -ne 0 ]]; then
      WARNINGS="${WARNINGS}${PLATFORM_RESULT}\n"
    fi
  fi

  # 2. UTM tag validation (clipboard only)
  UTM_RESULT=$("$SCRIPT_DIR/validate-utm-tags.sh" "$CONTENT_FILE" 2>&1)
  if [[ $? -ne 0 ]]; then
    WARNINGS="${WARNINGS}${UTM_RESULT}\n"
  fi
fi

# 3. Sensitive data scan — blocking on API keys, advisory on PII
SENSITIVE_RESULT=$("$SCRIPT_DIR/check-sensitive-data.sh" "$CONTENT_FILE" 2>&1)
SENSITIVE_EXIT=$?
if [[ -n "$SENSITIVE_RESULT" ]]; then
  WARNINGS="${WARNINGS}${SENSITIVE_RESULT}\n"
fi
if [[ $SENSITIVE_EXIT -ne 0 ]]; then
  BLOCK=1
fi

# 4. Voice style scan (Bash/clipboard only)
if [[ "$TOOL" == "Bash" ]]; then
  VOICE_RESULT=$("$SCRIPT_DIR/check-voice-style.sh" "$CONTENT_FILE" 2>&1)
  if [[ -n "$VOICE_RESULT" ]]; then
    WARNINGS="${WARNINGS}${VOICE_RESULT}\n"
  fi
fi

# Cleanup temp file if created for Write tool
[[ $CLEANUP_TEMP -eq 1 ]] && rm -f "$CONTENT_FILE"

# ── Output ────────────────────────────────────────────────────────────────────

if [[ $BLOCK -eq 1 ]]; then
  printf '%s' "$WARNINGS" | jq -Rs '{"decision": "block", "reason": .}'
  exit 2
fi

if [[ -n "$WARNINGS" ]]; then
  printf '%s' "$WARNINGS" | jq -Rs '{"additionalContext": .}'
fi

exit 0
