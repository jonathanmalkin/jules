#!/usr/bin/env bash
# slack-log-hook.sh — PostToolUse hook: logs tool events to Slack #logs thread
#
# Fires after each tool call during a claude -p daemon session.
# Only active when JULES_LOG_THREAD_TS is set (injected by slack-daemon).
# No-op in interactive terminal sessions and runner sessions.
#
# Input: JSON on stdin (Claude Code PostToolUse payload)
# Always exits 0 — never blocks tool execution.

set -euo pipefail

# ── Guard: only active during daemon sessions ──────────────────

if [ -z "${JULES_LOG_THREAD_TS:-}" ] || [ -z "${SLACK_LOGS_CHANNEL_ID:-}" ]; then
    # Not a daemon session, or #logs not configured — silently skip
    exit 0
fi

# ── Load credentials ───────────────────────────────────────────

ENV_FILE="$HOME/.env.local"
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

if [ -z "${SLACK_BOT_TOKEN:-}" ]; then
    exit 0
fi

# ── Read tool payload from stdin ───────────────────────────────

PAYLOAD=$(cat)

TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$PAYLOAD" | jq -r '.tool_input // {}' 2>/dev/null || echo "{}")

if [ -z "$TOOL_NAME" ]; then
    exit 0
fi

# ── Filter: skip noisy internal tools ─────────────────────────

case "$TOOL_NAME" in
    TodoWrite|ToolSearch|ExitPlanMode|EnterPlanMode|AskUserQuestion|SendMessage)
        exit 0
        ;;
esac

# ── Map tool → emoji + description ────────────────────────────

case "$TOOL_NAME" in
    Read)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | sed "s|$HOME/||")
        MSG="📄 Read: ${FILE:-?}"
        ;;
    Write)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | sed "s|$HOME/||")
        MSG="📝 Write: ${FILE:-?}"
        ;;
    Edit)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | sed "s|$HOME/||")
        MSG="✏️ Edit: ${FILE:-?}"
        ;;
    Bash)
        CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty' | head -c 80)
        MSG="🔧 Bash: ${CMD:-?}"
        ;;
    Agent)
        DESC=$(echo "$TOOL_INPUT" | jq -r '.description // empty' | head -c 60)
        MODEL=$(echo "$TOOL_INPUT" | jq -r '.model // ""')
        MSG="🤖 Agent: ${DESC:-?}${MODEL:+ → $MODEL}"
        ;;
    WebSearch)
        QUERY=$(echo "$TOOL_INPUT" | jq -r '.query // empty' | head -c 60)
        MSG="🌐 WebSearch: \"${QUERY:-?}\""
        ;;
    WebFetch)
        URL=$(echo "$TOOL_INPUT" | jq -r '.url // empty' | head -c 70)
        MSG="🌐 WebFetch: ${URL:-?}"
        ;;
    Glob)
        PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // empty')
        MSG="📁 Glob: ${PATTERN:-?}"
        ;;
    Grep)
        PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // empty' | head -c 50)
        MSG="🔍 Grep: ${PATTERN:-?}"
        ;;
    *)
        # Log unknown tools briefly so nothing is silently dropped
        MSG="🔹 ${TOOL_NAME}"
        ;;
esac

# ── Post to #logs thread ───────────────────────────────────────

curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg channel "$SLACK_LOGS_CHANNEL_ID" \
        --arg text "$MSG" \
        --arg thread_ts "$JULES_LOG_THREAD_TS" \
        '{channel: $channel, text: $text, thread_ts: $thread_ts}')" \
    >/dev/null 2>&1 || true

exit 0
