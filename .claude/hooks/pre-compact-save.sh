#!/bin/bash
# PreCompact hook: injects task state into compaction context and saves recovery snapshot.
# Fires before every autocompact. The systemMessage survives compaction, preserving task orientation.
set -euo pipefail

BREADCRUMB="/tmp/claude-task-breadcrumb.txt"
SNAPSHOT="/tmp/claude-precompact-state.txt"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Gather state
BRANCH=$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "detached")
DIFF_STAT=$(cd "$PROJECT_DIR" && git diff --stat HEAD 2>/dev/null | tail -5)
STATUS=$(cd "$PROJECT_DIR" && git status --short 2>/dev/null | head -20)
TASK=""
if [[ -f "$BREADCRUMB" ]]; then
  TASK=$(head -5 "$BREADCRUMB")
fi

# Build compact state summary
STATE="[PreCompact State]"
if [[ -n "$TASK" ]]; then
  STATE="$STATE\nTask: $TASK"
fi
STATE="$STATE\nBranch: $BRANCH"
if [[ -n "$DIFF_STAT" ]]; then
  STATE="$STATE\nChanged:\n$DIFF_STAT"
fi
if [[ -n "$STATUS" ]]; then
  STATE="$STATE\nWorking tree:\n$STATUS"
fi

# Save full recovery snapshot
printf '%b\n' "$STATE" > "$SNAPSHOT"
printf 'Snapshot saved: %s at %s\n' "$SNAPSHOT" "$(date +%H:%M:%S)" >> "$SNAPSHOT"

# Output systemMessage for compaction context injection
MSG=$(printf '%b' "$STATE" | jq -Rs .)
printf '{"systemMessage":%s}\n' "$MSG"
