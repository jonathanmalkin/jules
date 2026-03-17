#!/usr/bin/env bash
# auth-refresh.sh — Daily auth health check before cron jobs
#
# Primary: validates CLAUDE_CODE_OAUTH_TOKEN env var works
# On failure: alerts via Slack with exact remediation steps
# Does NOT attempt any token refresh — uses only the official setup-token
#
# Runs at 2:45 AM, 15 min before first cron job (daily-retro at 3 AM).
set -euo pipefail

LOG="$HOME/.claude/job-state/auth-refresh.log"
CREDS="$HOME/.claude/.credentials.json"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[auth-check] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

alert() {
    local msg="$1"
    log "ALERT: $msg"
    if [ -x "$SCRIPTS_DIR/slack-send.sh" ]; then
        "$SCRIPTS_DIR/slack-send.sh" --ops ":key: Auth check: $msg" 2>/dev/null || true
    fi
}

# ── Check 1: Is CLAUDE_CODE_OAUTH_TOKEN set? ───────────────
if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    # Try sourcing the secrets file
    if [ -f /tmp/agent-secrets.env ]; then
        set -a; . /tmp/agent-secrets.env; set +a
    fi
    if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
        alert "CLAUDE_CODE_OAUTH_TOKEN not in environment. 1Password injection may have failed at startup. Restart container: docker compose down && docker compose up -d"
        exit 1
    fi
fi
log "Env var present (length: ${#CLAUDE_CODE_OAUTH_TOKEN})"

# ── Check 2: Does auth actually work? ──────────────────────
if claude auth status > /dev/null 2>&1; then
    log "Auth OK."
    # Clear any stale lock file from previous failures
    rm -f "$HOME/.claude/job-state/auth-failed.lock"
    exit 0
fi

# ── Check 3: Auth failed — try claude -p directly ──────────
log "Auth status check failed. Testing claude -p directly..."

if echo "ping" | timeout 30 claude -p --model haiku --max-turns 1 --output-format text > /dev/null 2>&1; then
    log "claude -p works despite auth status failure. Proceeding."
    rm -f "$HOME/.claude/job-state/auth-failed.lock"
    exit 0
fi

# ── Auth is truly broken ───────────────────────────────────
# Check if credentials.json was overwritten by claude login
if [ -f "$CREDS" ]; then
    EXPIRES_AT=$(python3 -c "
import json
d = json.load(open('$CREDS'))
ea = d.get('claudeAiOauth', {}).get('expiresAt')
print('null' if ea is None else str(ea))
" 2>/dev/null || echo "error")
else
    EXPIRES_AT="missing"
fi

# Check marker file for overwrite detection
if [ -f "$HOME/.claude/.credentials.json.type" ]; then
    EXPECTED_TYPE=$(cat "$HOME/.claude/.credentials.json.type")
    if [ "$EXPECTED_TYPE" = "setup-token" ] && [ "$EXPIRES_AT" != "null" ] && [ "$EXPIRES_AT" != "missing" ] && [ "$EXPIRES_AT" != "error" ]; then
        alert "Auth FAILED. credentials.json was overwritten by 'claude login' (expected setup-token, got OAuth token with expiresAt=$EXPIRES_AT). NEVER run 'claude login' inside the container. Fix: restart container to rewrite from setup-token: docker compose down && docker compose up -d"
        exit 1
    fi
fi

if [ "$EXPIRES_AT" = "missing" ]; then
    alert "Auth FAILED. credentials.json is missing. Fix: restart container (docker compose down && docker compose up -d)"
elif [ "$EXPIRES_AT" != "null" ] && [ "$EXPIRES_AT" != "error" ]; then
    DAYS=$(python3 -c "
import time
ea = $EXPIRES_AT
days = (ea/1000 - time.time()) / 86400
print(round(days, 1))
" 2>/dev/null || echo "?")
    alert "Auth FAILED. credentials.json has expiresAt=$EXPIRES_AT (${DAYS} days). Likely overwritten by 'claude login'. NEVER run 'claude login' inside the container. Fix: restart container to rewrite from setup-token: docker compose down && docker compose up -d"
else
    alert "Auth FAILED. Setup-token may be expired (1-year limit). Fix: run 'claude setup-token' on Mac, update 1Password, restart container."
fi

exit 1
