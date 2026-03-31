#!/usr/bin/env bash
# send-email.sh — Send email via Resend API
#
# Safeguards:
#   1. Hardcoded recipient — your email only, no parameter override
#   2. Send log — every email logged for auditability
#
# Usage:
#   send-email.sh --subject "Morning Briefing" --html /path/to/body.html
#   send-email.sh --subject "Afternoon Scan" --body "Plain text body"
#   echo "<h1>Hi</h1>" | send-email.sh --subject "Test" --html -
#   send-email.sh --subject "Test" --dry-run    # Show what would send

set -euo pipefail

# ── Safeguard 1: Hardcoded recipient ──────────────────────────
# Replace with your email address
RECIPIENT="${EMAIL_RECIPIENT:-you@example.com}"
FROM_NAME="${EMAIL_FROM_NAME:-Agent}"
FROM_EMAIL="${EMAIL_FROM_ADDRESS:-agent@yourdomain.com}"

# ── Config ────────────────────────────────────────────────────
SEND_LOG="${SEND_LOG:-/tmp/email-send-log.jsonl}"

# ── Parse args ────────────────────────────────────────────────
SUBJECT=""
HTML_FILE=""
BODY_TEXT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --subject)  SUBJECT="$2"; shift 2 ;;
        --html)     HTML_FILE="$2"; shift 2 ;;
        --body)     BODY_TEXT="$2"; shift 2 ;;
        --dry-run)  DRY_RUN=true; shift ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$SUBJECT" ]]; then
    echo "Error: --subject is required" >&2
    exit 1
fi

if [[ -z "$HTML_FILE" && -z "$BODY_TEXT" ]]; then
    echo "Error: --html or --body is required" >&2
    exit 1
fi

TODAY=$(date +%Y-%m-%d)

# ── Build email body ─────────────────────────────────────────
if [[ -n "$HTML_FILE" ]]; then
    if [[ "$HTML_FILE" == "-" ]]; then
        HTML_CONTENT=$(cat)
    else
        HTML_CONTENT=$(cat "$HTML_FILE")
    fi
    # JSON-escape the HTML
    BODY_JSON=$(printf '%s' "$HTML_CONTENT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
    CONTENT_FIELD="\"html\": $BODY_JSON"
else
    BODY_JSON=$(printf '%s' "$BODY_TEXT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
    CONTENT_FIELD="\"text\": $BODY_JSON"
fi

SUBJECT_JSON=$(printf '%s' "$SUBJECT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

# ── Dry run ──────────────────────────────────────────────────
if $DRY_RUN; then
    echo "DRY RUN — would send:"
    echo "  To:      $RECIPIENT"
    echo "  From:    $FROM_NAME <$FROM_EMAIL>"
    echo "  Subject: $SUBJECT"
    echo "  Sends today: check $SEND_LOG"
    exit 0
fi

# ── Get API key (env var only — set in Cloud task config or Mac env) ──
API_KEY="${RESEND_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
    echo "Error: RESEND_API_KEY not set" >&2
    exit 1
fi

# ── Send via Resend API ──────────────────────────────────────
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST 'https://api.resend.com/emails' \
    -H "Authorization: Bearer $API_KEY" \
    -H 'Content-Type: application/json' \
    -d "{
        \"from\": \"$FROM_NAME <$FROM_EMAIL>\",
        \"to\": [\"$RECIPIENT\"],
        \"subject\": $SUBJECT_JSON,
        $CONTENT_FIELD
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

# ── Safeguard 2: Log every send ──────────────────────────────
LOG_ENTRY=$(python3 -c "
import json, sys
print(json.dumps({
    'date': '$TODAY',
    'time': '$(date +%H:%M:%S)',
    'subject': $SUBJECT_JSON,
    'to': '$RECIPIENT',
    'http_code': int('$HTTP_CODE'),
    'response': $( [[ -n "$RESPONSE_BODY" ]] && echo "$RESPONSE_BODY" || echo '{}' ),
}))
")

mkdir -p "$(dirname "$SEND_LOG")"
echo "$LOG_ENTRY" >> "$SEND_LOG"

# ── Report result ────────────────────────────────────────────
if [[ "$HTTP_CODE" == "200" ]]; then
    EMAIL_ID=$(echo "$RESPONSE_BODY" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("id","unknown"))' 2>/dev/null || echo "unknown")
    echo "Sent: $SUBJECT (id: $EMAIL_ID)"
else
    echo "Error: HTTP $HTTP_CODE — $RESPONSE_BODY" >&2
    exit 1
fi
