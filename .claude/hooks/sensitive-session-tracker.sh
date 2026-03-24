#!/bin/bash
# sensitive-session-tracker.sh — PostToolUse hook on Read
# Flags sessions that read sensitive financial files
#
# CUSTOMIZE: Update the case patterns below to match your sensitive file paths.
# Examples: financial documents, health records, legal files, credentials.

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name — only process Read calls
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[[ "$TOOL_NAME" != "Read" ]] && exit 0

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0

# Check against sensitive patterns
# CUSTOMIZE: Replace these with your own sensitive file paths
case "$FILE_PATH" in
  */Documents/Personal-Finance/*|*/Documents/Personal-Finance)
    ;; # match
  */Profiles/Personal-Finance*.md)
    ;; # match
  */Documents/*/Financials/*|*/Documents/*/Financials)
    ;; # match
  *)
    exit 0 ;; # no match
esac

# Determine flag file path
FLAG_FILE="${CLAUDE_SENSITIVE_SESSION_FILE:-/tmp/claude-sensitive-session-$$}"

# Append timestamp and path
echo "$(date -u +%s):$FILE_PATH" >> "$FLAG_FILE"

exit 0
