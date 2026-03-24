#!/usr/bin/env bash
# refresh-secrets.sh — Nightly re-injection of 1Password secrets
# Rewrites /tmp/agent-secrets.env and ~/.claude/.credentials.json
# Runs at 2:30 AM daily — 15 min before auth-refresh validates the result
#
# FAILURE MODES & REMEDIATION
# ────────────────────────────────────────────────────────────────────────────
# FM1: OP_SERVICE_ACCOUNT_TOKEN not set
#   Symptom: Log shows "SKIP: OP_SERVICE_ACCOUNT_TOKEN not set"
#   Cause:   Container started without the op-token env_file, or entrypoint
#            failed before setting the var.
#   Fix:     cd ~/workspace/.claude/container && docker compose down && docker compose up -d
#            (entrypoint re-injects on startup)
#
# FM2: Template file missing
#   Symptom: Log shows "SKIP: template file missing at ..."
#   Cause:   Bind mount failed (docker-compose.yml misconfiguration) or file
#            was deleted from the repo.
#   Fix:     Verify bind mount: docker inspect your-agent-dev | grep env.template
#            Verify file exists: ls ~/workspace/.claude/container/.env.template
#            Restart container if mount is missing.
#
# FM3: op inject fails (non-zero exit)
#   Symptom: Log shows "FAIL: op inject exited N"
#   Cause:   1Password service account token expired, network unreachable, or
#            op CLI not installed/updated.
#   Action:  Script auto-restores from /tmp/agent-secrets.env.bak and
#            /tmp/agent-credentials.json.bak (last known good state).
#            auth-refresh at 2:45 AM validates whether restored state is sufficient.
#   Fix (if restore insufficient):
#            On Mac: op item get "Your-Vault" --vault "Your-Vault"
#            to verify service account is valid. If expired, rotate in 1Password,
#            update op-token env_file on VPS, restart container.
#
# FM4: Partial inject (< MIN_VARS vars resolved)
#   Symptom: Log shows "FAIL: only N vars resolved (expected >=20)"
#   Cause:   op inject partially resolved — some vault items missing or renamed.
#   Action:  Script keeps existing secrets file intact (does not overwrite).
#   Fix:     Check .env.template for any op:// references pointing to deleted/
#            renamed vault items. Run op inject manually to identify which item
#            fails: grep -v '^#' .env.template | grep -v '^$' | op inject --in-file /dev/stdin
#
# FM5: CLAUDE_CODE_OAUTH_TOKEN empty after successful inject
#   Symptom: Log shows "WARN: CLAUDE_CODE_OAUTH_TOKEN empty after refresh"
#   Cause:   The vault item for the Claude OAuth token was deleted, renamed, or
#            the op:// reference in .env.template changed.
#   Action:  Secrets file is refreshed but credentials.json is NOT rewritten.
#            auth-refresh will catch this at 2:45 AM.
#   Fix:     On Mac: verify the Claude setup-token exists in 1Password vault
#            "Your-Vault". Update .env.template reference if renamed.
#
# FM6: No backup available (first run, or /tmp wiped by container restart)
#   Symptom: Log shows "FAIL: ... no backup available, secrets NOT refreshed"
#   Cause:   /tmp is not persistent across container restarts. entrypoint.sh
#            now writes both .bak files at startup, so this scenario requires
#            BOTH a restart AND immediate op inject failure on that same night.
#   Action:  /tmp/agent-secrets.env was written by entrypoint on startup, so
#            the live secrets file is valid even without a backup. auth-refresh
#            at 2:45 AM will validate the startup-written credentials.
#   Fix:     Restart the container — entrypoint.sh re-runs op inject + writes
#            fresh backups:
#            cd ~/workspace/.claude/container && docker compose down && docker compose up -d
#
# BACKUP FILES (survive container lifetime, wiped on restart)
#   /tmp/agent-secrets.env.bak      — last successful secrets file
#   /tmp/agent-credentials.json.bak — last successful credentials.json
#
# LOG: ~/.claude/job-state/refresh-secrets.log
# ────────────────────────────────────────────────────────────────────────────
set -euo pipefail

TEMPLATE_FILE="$HOME/workspace/.claude/container/.env.template"
SECRETS_FILE="/tmp/agent-secrets.env"
SECRETS_BACKUP="/tmp/agent-secrets.env.bak"
CREDS_FILE="$HOME/.claude/.credentials.json"
CREDS_BACKUP="/tmp/agent-credentials.json.bak"
MIN_VARS=20   # alert if fewer than this many vars resolved
LOG_PREFIX="[secrets-refresh] $(date '+%Y-%m-%d %H:%M:%S')"

# Slack alert helper (non-blocking)
alert() {
    local msg="$1"
    echo "$LOG_PREFIX ALERT: $msg"
    # Extract SLACK vars via grep — source breaks on space-containing values
    if [ -f "$SECRETS_FILE" ]; then
        SLACK_BOT_TOKEN=$(grep '^SLACK_BOT_TOKEN=' "$SECRETS_FILE" | cut -d= -f2- | tr -d "'")
        SLACK_OPS_CHANNEL_ID=$(grep '^SLACK_OPS_CHANNEL_ID=' "$SECRETS_FILE" | cut -d= -f2- | tr -d "'")
    fi
    if [ -n "${SLACK_BOT_TOKEN:-}" ] && [ -n "${SLACK_OPS_CHANNEL_ID:-}" ]; then
        curl -s -X POST "https://slack.com/api/chat.postMessage" \
            -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"channel\":\"$SLACK_OPS_CHANNEL_ID\",\"text\":\"[secrets-refresh] $msg\"}" \
            > /dev/null 2>&1 || true
    fi
}

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    alert "SKIP: OP_SERVICE_ACCOUNT_TOKEN not set — secrets NOT refreshed"
    exit 0
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    alert "SKIP: template file missing at $TEMPLATE_FILE — secrets NOT refreshed"
    exit 0
fi

# Fast canary — validate 1Password service account before attempting inject
if ! op whoami &> /dev/null; then
    alert "1Password service account token is invalid or expired. op whoami failed. Rotate token in 1Password, update op-token env_file on VPS, restart container."
    # Still attempt inject — it might work with cached state, and backup restore handles failure
fi

# Re-run op inject (strip comments and blank lines before piping)
INJECT_OUTPUT=$(grep -v '^#' "$TEMPLATE_FILE" | grep -v '^$' | op inject --in-file /dev/stdin 2>&1)
INJECT_EXIT=$?

if [ $INJECT_EXIT -ne 0 ] || [ -z "$INJECT_OUTPUT" ]; then
    # Inject failed — attempt restore from backup before alerting
    if [ -f "$SECRETS_BACKUP" ]; then
        cp "$SECRETS_BACKUP" "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"
        OAUTH_FROM_BACKUP=$(grep '^CLAUDE_CODE_OAUTH_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)
        if [ -n "${OAUTH_FROM_BACKUP:-}" ] && [ -f "$CREDS_BACKUP" ]; then
            chmod 644 "$CREDS_FILE" 2>/dev/null || true
            cp "$CREDS_BACKUP" "$CREDS_FILE"
            chmod 444 "$CREDS_FILE" 2>/dev/null || true
            alert "FAIL: op inject exited $INJECT_EXIT — restored from backup (secrets + credentials.json)"
        else
            alert "FAIL: op inject exited $INJECT_EXIT — restored secrets from backup (no credentials backup)"
        fi
    else
        alert "FAIL: op inject exited $INJECT_EXIT — no backup available, secrets NOT refreshed"
    fi
    exit 1
fi

# Write to temp file and validate var count before replacing
printf '%s\n' "$INJECT_OUTPUT" > "${SECRETS_FILE}.tmp"
chmod 600 "${SECRETS_FILE}.tmp"
LOADED_COUNT=$(grep -c '=' "${SECRETS_FILE}.tmp" 2>/dev/null || echo 0)

if [ "$LOADED_COUNT" -lt "$MIN_VARS" ]; then
    alert "FAIL: only $LOADED_COUNT vars resolved (expected >=$MIN_VARS) — keeping existing secrets file"
    rm -f "${SECRETS_FILE}.tmp"
    exit 1
fi

# Atomically replace secrets file and save backup of the good state
mv "${SECRETS_FILE}.tmp" "$SECRETS_FILE"
cp "$SECRETS_FILE" "$SECRETS_BACKUP"
chmod 600 "$SECRETS_BACKUP"
echo "$LOG_PREFIX OK: $LOADED_COUNT vars refreshed"

# Extract CLAUDE_CODE_OAUTH_TOKEN from refreshed file — grep avoids sourcing
# space-containing values (e.g. GMAIL_APP_PASSWORD) which break bash's set -a source
CLAUDE_CODE_OAUTH_TOKEN=$(grep '^CLAUDE_CODE_OAUTH_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    chmod 644 "$CREDS_FILE" 2>/dev/null || true
    cat > "$CREDS_FILE" << CREDSEOF
{
  "claudeAiOauth": {
    "accessToken": "${CLAUDE_CODE_OAUTH_TOKEN}",
    "refreshToken": null,
    "expiresAt": null,
    "scopes": ["user:inference", "user:profile"],
    "tokenType": "Bearer"
  }
}
CREDSEOF
    chmod 444 "$CREDS_FILE" 2>/dev/null || true
    cp "$CREDS_FILE" "$CREDS_BACKUP"
    chmod 600 "$CREDS_BACKUP"
    echo "$LOG_PREFIX Credentials.json rewritten and backed up."
else
    alert "WARN: CLAUDE_CODE_OAUTH_TOKEN empty after refresh — credentials.json NOT rewritten"
fi
