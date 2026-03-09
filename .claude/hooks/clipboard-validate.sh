#!/bin/bash
# clipboard-validate.sh -- PostToolUse hook for Bash commands containing pbcopy
# Validates clipboard content against platform limits, UTM tags, and sensitive data.
# Returns additionalContext with warnings via jq -Rs pattern.
#
# NOTE: This hook calls supporting scripts in .claude/scripts/:
#   - validate-platform-content.sh (platform char limits, formatting rules)
#   - validate-utm-tags.sh (UTM parameter validation)
#   - check-sensitive-data.sh (PII/secret detection)
#   - check-voice-style.sh (em-dash detection, style consistency)
# You'll need to create these scripts for your use case.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect Bash commands
[[ "$TOOL" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Only fire on commands that pipe to pbcopy
echo "$COMMAND" | grep -q 'pbcopy' || exit 0

# Gate: only validate if the copy-for temp file exists and was recently written (< 60s)
CONTENT_FILE="/tmp/claude-copy-for.txt"
[[ ! -f "$CONTENT_FILE" ]] && exit 0

# Check file age -- skip if older than 60 seconds (stale from a previous session)
if [[ "$(uname)" == "Darwin" ]]; then
  FILE_MOD=$(stat -f "%m" "$CONTENT_FILE" 2>/dev/null)
else
  FILE_MOD=$(stat -c "%Y" "$CONTENT_FILE" 2>/dev/null)
fi
NOW=$(date +%s)
if [[ -n "$FILE_MOD" ]] && (( NOW - FILE_MOD > 60 )); then
  exit 0
fi

SCRIPT_DIR="$(dirname "$0")/../scripts"
WARNINGS=""

# 1. Platform-specific validation (if platform sidecar exists)
PLATFORM_FILE="/tmp/claude-copy-for-platform.txt"
if [[ -f "$PLATFORM_FILE" ]]; then
  PLATFORM=$(cat "$PLATFORM_FILE" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  PLATFORM_RESULT=$("$SCRIPT_DIR/validate-platform-content.sh" "$PLATFORM" "$CONTENT_FILE" 2>&1)
  if [[ $? -ne 0 ]]; then
    WARNINGS="${WARNINGS}${PLATFORM_RESULT}\n"
  fi
fi

# 2. Sensitive data scan (always advisory)
SENSITIVE_RESULT=$("$SCRIPT_DIR/check-sensitive-data.sh" "$CONTENT_FILE" 2>&1)
if [[ -n "$SENSITIVE_RESULT" ]]; then
  WARNINGS="${WARNINGS}${SENSITIVE_RESULT}\n"
fi

# Return warnings as additionalContext if any found
if [[ -n "$WARNINGS" ]]; then
  printf '%s' "$WARNINGS" | jq -Rs '{"additionalContext": .}'
fi

exit 0
