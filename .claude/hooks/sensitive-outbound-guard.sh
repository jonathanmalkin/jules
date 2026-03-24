#!/bin/bash
# sensitive-outbound-guard.sh — PreToolUse hook for outbound Bash + MCP tools
# Two-gate logic:
#   Gate 1: Was sensitive financial data read this session? (flag file check)
#   Gate 2: Does the outbound content contain financial patterns?
# Exit 0 = allow, Exit 2 = block (stderr shown to user)

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ── Gate 1: Session flag ──────────────────────────────────────────────────────
# The financial-advisor skill writes this file when sensitive docs are loaded.
# Check env var first; fall back to the PID-based default.
FLAG_FILE="${CLAUDE_SENSITIVE_SESSION_FILE:-/tmp/claude-sensitive-session-$$}"
[[ ! -f "$FLAG_FILE" ]] && exit 0

# ── Determine if this is an outbound tool ────────────────────────────────────
CONTENT=""

if [[ "$TOOL" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  [[ -z "$COMMAND" ]] && exit 0

  # Override: user explicitly confirmed the content is safe
  echo "$COMMAND" | grep -q '^# SAFE-OVERRIDE:' && exit 0

  # Only gate outbound Bash: clipboard writes, HTTP POSTs, X posting scripts
  echo "$COMMAND" | grep -qE '(pbcopy|curl.*(--data|-d|-F|--upload-file)|wget.*--post|x-post\.sh|post-to-x\.py)' || exit 0

  CONTENT="$COMMAND"

elif echo "$TOOL" | grep -qE 'mcp__.*slack.*(send_message|schedule_message|create_canvas)'; then
  # Extract message/content field from Slack MCP tools
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.message // .tool_input.content // .tool_input.text // empty')
  [[ -z "$CONTENT" ]] && exit 0

else
  # Not an outbound tool we gate
  exit 0
fi

# ── Gate 2: Financial pattern detection ──────────────────────────────────────
# Dollar amounts
echo "$CONTENT" | grep -qE '\$[0-9,]+' && MATCH=1

# Percentage in financial context
if [[ -z "$MATCH" ]]; then
  echo "$CONTENT" | grep -qiE '[0-9]+%[^a-z]*\b(return|yield|rate|allocation|burn|interest|growth)\b' && MATCH=1
  echo "$CONTENT" | grep -qiE '\b(return|yield|rate|allocation|burn|interest|growth)\b[^a-z]*[0-9]+%' && MATCH=1
fi

# Account-related terms
if [[ -z "$MATCH" ]]; then
  echo "$CONTENT" | grep -qiE '\b(account\s+number|routing\s+number|balance|portfolio|brokerage|checking|savings)\b' && MATCH=1
fi

# Specific financial terms
if [[ -z "$MATCH" ]]; then
  echo "$CONTENT" | grep -qiE '\b(runway|burn\s+rate|net\s+worth|retirement|401k|roth|ira|dividend|drawdown|withdrawal|contribution|rebalance)\b' && MATCH=1
fi

# 8+ digit sequences that look like account numbers (not version numbers or zip codes)
if [[ -z "$MATCH" ]]; then
  echo "$CONTENT" | grep -qE '\b[0-9]{8,}\b' && MATCH=1
fi

[[ -z "$MATCH" ]] && exit 0

# ── Both gates triggered: block ───────────────────────────────────────────────
cat >&2 <<'EOF'
BLOCKED: Sensitive financial data was read this session.
This outbound action contains financial patterns.
Sanitize the content or confirm with: # SAFE-OVERRIDE: <command>
EOF

exit 2
