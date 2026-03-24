#!/usr/bin/env bash
# auth-check.sh — Shared Claude auth validation for cron jobs
#
# Source this file in cron scripts: source "$SCRIPTS_DIR/auth-check.sh"
# Then call: check_auth || exit 1
#
# Distinguishes three failure types:
#   AUTH_FAIL  — API is reachable but token is invalid (401/403)
#   API_DOWN   — Anthropic API is unreachable (timeout, 5xx, connection refused)
#   NETWORK    — Can't reach the internet at all
#
# Lock files:
#   auth-failed.lock  — set on AUTH_FAIL only. Blocks all cron jobs.
#   api-outage.lock   — set on API_DOWN. Cron jobs should retry with backoff.
#
# Structured log: ~/.claude/job-state/auth-checks.jsonl
#   Each line: {"ts":"...","method":"...","result":"...","classification":"...","latency_ms":N,"http_status":N}

AUTH_LOCK="$HOME/.claude/job-state/auth-failed.lock"
API_LOCK="$HOME/.claude/job-state/api-outage.lock"
AUTH_LOG="$HOME/.claude/job-state/auth-checks.jsonl"
SCRIPTS_DIR="${SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# ── Helpers ───────────────────────────────────────────────────

_log_check() {
    local method="$1" result="$2" classification="$3" latency_ms="$4" http_status="${5:-0}" error="${6:-}"
    local ts
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    mkdir -p "$(dirname "$AUTH_LOG")"
    # Escape quotes and newlines in error for valid JSON
    error=$(printf '%s' "$error" | tr '\n' ' ' | sed 's/"/\\"/g')
    if [ -n "$error" ]; then
        printf '{"ts":"%s","method":"%s","result":"%s","classification":"%s","latency_ms":%d,"http_status":%d,"error":"%s"}\n' \
            "$ts" "$method" "$result" "$classification" "$latency_ms" "$http_status" "$error" >> "$AUTH_LOG"
    else
        printf '{"ts":"%s","method":"%s","result":"%s","classification":"%s","latency_ms":%d,"http_status":%d}\n' \
            "$ts" "$method" "$result" "$classification" "$latency_ms" "$http_status" >> "$AUTH_LOG"
    fi
}

_slack_alert() {
    local msg="$1"
    if [ -x "$SCRIPTS_DIR/slack-send.sh" ]; then
        "$SCRIPTS_DIR/slack-send.sh" --ops "$msg" 2>/dev/null || true
    fi
}

# ── API reachability check ────────────────────────────────────
# Hits the Anthropic API without auth. Returns:
#   0 = API is up (got 401 — "unauthorized" means the server answered)
#   1 = API is down (timeout, 5xx, connection error)
#   2 = Network is down (can't resolve DNS / no route)
_api_reachable() {
    local start_ms end_ms http_code
    start_ms=$(date +%s%N 2>/dev/null || echo 0)

    # Quick DNS check first
    if ! host api.anthropic.com > /dev/null 2>&1; then
        end_ms=$(date +%s%N 2>/dev/null || echo 0)
        local latency=$(( (end_ms - start_ms) / 1000000 ))
        _log_check "dns_check" "fail" "network" "$latency" 0
        return 2
    fi

    http_code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 \
        -X POST "https://api.anthropic.com/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: invalid" \
        -H "anthropic-version: 2023-06-01" \
        -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"x"}]}' \
        2>/dev/null)

    end_ms=$(date +%s%N 2>/dev/null || echo 0)
    local latency=$(( (end_ms - start_ms) / 1000000 ))

    # 401 = API is up and responding (rejected our invalid key, which is expected)
    # 400 = API is up (bad request format)
    # 403 = API is up (forbidden)
    # 429 = API is up (rate limited)
    if [[ "$http_code" =~ ^(401|400|403|429)$ ]]; then
        _log_check "api_reachable" "pass" "ok" "$latency" "$http_code"
        return 0
    fi

    # 5xx or 000 (connection failed) or other = API is down
    _log_check "api_reachable" "fail" "api_down" "$latency" "$http_code"
    return 1
}

# ── Claude auth test with retry ───────────────────────────────
# Returns 0 on success, 1 on failure.
# Sets AUTH_CHECK_CLASSIFICATION to: ok, auth_fail, api_down, network
AUTH_CHECK_CLASSIFICATION="ok"

# Last claude -p stderr, available after _claude_test fails
CLAUDE_P_STDERR=""

_claude_test() {
    local start_ms end_ms output
    start_ms=$(date +%s%N 2>/dev/null || echo 0)
    output=$(echo "ping" | timeout 30 claude -p --model haiku --max-turns 1 --output-format text 2>&1) && {
        end_ms=$(date +%s%N 2>/dev/null || echo 0)
        local latency=$(( (end_ms - start_ms) / 1000000 ))
        _log_check "claude_p" "pass" "ok" "$latency"
        CLAUDE_P_STDERR=""
        return 0
    }
    end_ms=$(date +%s%N 2>/dev/null || echo 0)
    local latency=$(( (end_ms - start_ms) / 1000000 ))
    CLAUDE_P_STDERR="$output"
    # Log the first 200 chars of error output for diagnosis
    local err_snippet="${output:0:200}"
    _log_check "claude_p" "fail" "unknown" "$latency" 0 "$err_snippet"
    return 1
}

_auth_test_with_retry() {
    local delays=(30 60 120)
    local attempt=1

    # First attempt
    if _claude_test; then
        AUTH_CHECK_CLASSIFICATION="ok"
        return 0
    fi

    # On failure, check API reachability to classify
    _api_reachable
    local api_status=$?

    if [ $api_status -eq 2 ]; then
        AUTH_CHECK_CLASSIFICATION="network"
        return 1
    elif [ $api_status -eq 1 ]; then
        # API is down — retry with backoff (it might come back)
        for delay in "${delays[@]}"; do
            attempt=$((attempt + 1))
            sleep "$delay"
            if _claude_test; then
                AUTH_CHECK_CLASSIFICATION="ok"
                return 0
            fi
        done
        AUTH_CHECK_CLASSIFICATION="api_down"
        return 1
    else
        # API is reachable but claude -p failed — retry once more to be sure
        sleep 30
        if _claude_test; then
            AUTH_CHECK_CLASSIFICATION="ok"
            return 0
        fi
        AUTH_CHECK_CLASSIFICATION="auth_fail"
        return 1
    fi
}

# ── Main entry point ──────────────────────────────────────────

check_auth() {
    # If auth-failed lock exists, check if auth recovered
    if [ -f "$AUTH_LOCK" ]; then
        if _claude_test; then
            rm -f "$AUTH_LOCK" "$API_LOCK"
            _slack_alert ":white_check_mark: Claude auth restored. Running catch-up for missed jobs."
            if [ -x "$SCRIPTS_DIR/catch-up-scheduler.sh" ]; then
                bash "$SCRIPTS_DIR/catch-up-scheduler.sh" &
            fi
            return 0
        else
            return 1
        fi
    fi

    # If api-outage lock exists, check if API recovered
    if [ -f "$API_LOCK" ]; then
        _api_reachable
        if [ $? -eq 0 ]; then
            if _claude_test; then
                rm -f "$API_LOCK"
                _slack_alert ":white_check_mark: Anthropic API recovered. Resuming jobs."
                return 0
            fi
        fi
        # API still down — don't block the caller, let them decide
        return 1
    fi

    # Normal auth check with retry and classification
    if _auth_test_with_retry; then
        return 0
    fi

    # Failed — take action based on classification
    mkdir -p "$(dirname "$AUTH_LOCK")"

    case "$AUTH_CHECK_CLASSIFICATION" in
        auth_fail)
            ( set -C; date > "$AUTH_LOCK" ) 2>/dev/null || true
            _dump_diagnosis
            _slack_alert ":rotating_light: *Claude auth failed* (API is reachable, token rejected). All jobs paused. Diagnosis dumped to auth-diagnosis.log. Fix: restart container (\`docker compose down && docker compose up -d\`). If persistent: run \`claude setup-token\` on Mac, update 1Password."
            ;;
        api_down)
            ( set -C; date > "$API_LOCK" ) 2>/dev/null || true
            _slack_alert ":cloud: *Anthropic API is down.* Jobs will retry automatically. Check https://status.anthropic.com. No action needed unless this persists > 2 hours."
            ;;
        network)
            _slack_alert ":globe_with_meridians: *Network unreachable* from container. DNS resolution failed. Check VPS connectivity."
            ;;
    esac

    return 1
}

# ── Verbose diagnosis dump (auth_fail only) ───────────────────
# Captures everything needed to diagnose a confirmed auth failure
# (API is reachable, token is being rejected). Only called when
# classification is auth_fail — not on API outages or network issues.

_dump_diagnosis() {
    local DIAG_LOG
    DIAG_LOG="$(dirname "$AUTH_LOG")/auth-diagnosis.log"
    {
        echo "=== Auth Failure Diagnosis — $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="
        echo
        echo "--- claude -p stderr (the actual error) ---"
        echo "$CLAUDE_P_STDERR"
        echo
        echo "--- claude auth status ---"
        claude auth status 2>&1 || echo "(command failed)"
        echo
        echo "--- credentials.json ---"
        python3 -c "
import json, os
creds = os.path.expanduser('~/.claude/.credentials.json')
d = json.load(open(creds))
o = d.get('claudeAiOauth', {})
print(f'token_len={len(o.get(\"accessToken\", \"\"))}')
print(f'expiresAt={o.get(\"expiresAt\")}')
print(f'has_refresh={o.get(\"refreshToken\") is not None}')
print(f'scopes={o.get(\"scopes\")}')
print(f'tokenType={o.get(\"tokenType\")}')
" 2>&1 || echo "(parse failed)"
        echo
        echo "--- credentials.json permissions ---"
        stat -c '%a %U' "$HOME/.claude/.credentials.json" 2>/dev/null || echo "(stat failed)"
        echo
        echo "--- credentials.json.type ---"
        cat "$HOME/.claude/.credentials.json.type" 2>&1 || echo "(missing)"
        echo
        echo "--- CLAUDE_CODE_OAUTH_TOKEN env ---"
        echo "length: ${#CLAUDE_CODE_OAUTH_TOKEN:-0}"
        [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && echo "prefix: ${CLAUDE_CODE_OAUTH_TOKEN:0:15}..."
        echo
        echo "--- token-written-date ---"
        cat "$HOME/.claude/job-state/token-written-date" 2>&1 || echo "(missing)"
        echo
        echo "--- secrets file ---"
        ls -la /tmp/agent-secrets.env 2>/dev/null || echo "(missing)"
        wc -l /tmp/agent-secrets.env 2>/dev/null || true
        echo
        echo "--- 1Password service account ---"
        op whoami 2>&1 || echo "(op whoami failed)"
        echo
        echo "--- claude processes ---"
        ps aux | grep '[c]laude' | head -5 || echo "(none)"
        echo
        echo "=== End Diagnosis ==="
    } >> "$DIAG_LOG" 2>&1
}
