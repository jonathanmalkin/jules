#!/usr/bin/env bash
# Agent container entrypoint — 8 phases from boot to ready
# Phase 1: Workspace setup (symlinks, memory sync)
# Phase 2: SSH configuration (known_hosts, deploy keys)
# Phase 3: Secret injection (1Password → env vars)
# Phase 4: Claude Code configuration (onboarding, settings, credentials)
# Phase 5: Boot-check (run any missed scheduled jobs)
# Phase 6: Slack daemon startup
# Phase 7: MCP server startup
# Phase 8: Supervisor loop (keep daemons alive, restart on code change)
set -euo pipefail

echo "Starting agent container..."

# ============================================================================
# PHASE 1: Workspace setup
# ============================================================================

# Path portability: scripts may hardcode $HOME/workspace (convention)
ln -sfn /home/claude/workspace /home/claude/Workspace

# Memory sync: symlink Claude's memory path to the git-tracked memory folder.
# This ensures container cron jobs and Mac interactive sessions share
# the same memory via git push/pull.
MEMORY_REPO="$HOME/workspace/.claude-memory"
MEMORY_TARGET="$HOME/.claude/projects/YOUR_PROJECT_MEMORY_PATH/memory"
if [ -d "$MEMORY_REPO" ]; then
    mkdir -p "$(dirname "$MEMORY_TARGET")"
    ln -sfn "$MEMORY_REPO" "$MEMORY_TARGET"
    echo "Memory symlinked to repo (.claude-memory/)"
fi

# Set up merge driver for memory conflicts (accepts incoming version)
git -C "$HOME/workspace" config merge.theirs-memory.name "Always accept incoming memory changes" 2>/dev/null || true
git -C "$HOME/workspace" config merge.theirs-memory.driver "cp %B %A" 2>/dev/null || true

# ============================================================================
# PHASE 2: SSH configuration
# ============================================================================

# Fix SSH authorized_keys permissions (mount may set wrong perms)
if [ -f "$HOME/.ssh/authorized_keys" ]; then
    chmod 600 "$HOME/.ssh/authorized_keys" 2>/dev/null || true
fi

# Pre-populate SSH known_hosts (read-only ~/.ssh mount can't write known_hosts)
mkdir -p /tmp/ssh-state
cp "$HOME/.ssh/known_hosts" /tmp/ssh-state/known_hosts 2>/dev/null || true
ssh-keyscan -H github.com >> /tmp/ssh-state/known_hosts 2>/dev/null || true

# Write SSH config with per-repo deploy keys (bypasses host's 1Password IdentityAgent)
# Each repo gets its own deploy key for granular access control
cat > /tmp/ssh-state/ssh_config << EOF
Host github-workspace
  HostName github.com
  User git
  IdentityFile $HOME/.ssh/id_ed25519_your_agent
  IdentityAgent none
  UserKnownHostsFile /tmp/ssh-state/known_hosts

Host github-repo
  HostName github.com
  User git
  IdentityFile $HOME/.ssh/id_ed25519_your_repo
  IdentityAgent none
  UserKnownHostsFile /tmp/ssh-state/known_hosts
EOF
export GIT_SSH_COMMAND="ssh -F /tmp/ssh-state/ssh_config"
echo "SSH known_hosts pre-populated"

# ============================================================================
# PHASE 3: Secret injection (1Password)
# ============================================================================

# Fetch secrets from 1Password at startup
# OP_SERVICE_ACCOUNT_TOKEN passed via docker-compose environment
TEMPLATE_FILE="$HOME/workspace/.claude/container/.env.template"
SECRETS_FILE="/tmp/agent-secrets.env"
if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] && [ -f "$TEMPLATE_FILE" ]; then
    # Quote all values so source doesn't choke on tokens with special chars
    INJECT_OUTPUT=$(grep -v '^#' "$TEMPLATE_FILE" | grep -v '^$' | op inject --in-file /dev/stdin 2>&1)
    INJECT_EXIT=$?
    if [ $INJECT_EXIT -eq 0 ] && [ -n "$INJECT_OUTPUT" ]; then
        echo "$INJECT_OUTPUT" | sed "s/=\(.*\)/='\1'/" > "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"
        LOADED_COUNT=$(grep -c '=' "$SECRETS_FILE" 2>/dev/null || echo 0)
        echo "Secrets loaded from 1Password ($LOADED_COUNT vars)"
        if [ "$LOADED_COUNT" -lt 5 ]; then
            echo "WARNING: Expected 10+ vars, got $LOADED_COUNT — partial injection"
        fi
    else
        echo "CRITICAL: op inject failed (exit $INJECT_EXIT)"
        echo "  Output: $INJECT_OUTPUT"
    fi
else
    echo "WARNING: OP_SERVICE_ACCOUNT_TOKEN not set or template missing — secrets not loaded"
fi

# (sshd, cron, and crontab installed by root entrypoint before dropping to this user)

# Create state directories for scheduled jobs
mkdir -p "$HOME/.claude/agent-runner-state"
mkdir -p "$HOME/.claude/morning-state"
mkdir -p "$HOME/.claude/afternoon-state"
mkdir -p "$HOME/.claude/good-morning-state"
mkdir -p "$HOME/.claude/job-state"

# ============================================================================
# PHASE 4: Claude Code configuration
# ============================================================================

# Write Claude onboarding config — lives OUTSIDE the claude-config volume
# (at ~/.claude.json, not ~/.claude/.claude.json), so it's wiped on every rebuild.
# Without this file, Claude Code prompts for login even when credentials.json is valid.
# Replace with your own account details from claude.ai/settings.
cat > "$HOME/.claude.json" << 'ONBOARDEOF'
{
  "hasCompletedOnboarding": true,
  "theme": "light",
  "autoUpdates": false,
  "oauthAccount": {
    "accountUuid": "YOUR-ACCOUNT-UUID",
    "emailAddress": "your-email@example.com",
    "organizationUuid": "YOUR-ORG-UUID",
    "organizationName": "[Your Name]",
    "displayName": "[Your Name]",
    "organizationRole": "admin",
    "billingType": "stripe_subscription",
    "hasExtraUsageEnabled": true
  }
}
ONBOARDEOF
chmod 600 "$HOME/.claude.json"
echo "Claude onboarding config written (prevents login prompt after rebuild)"

# Write user-level Claude config (idempotent — overwrites on every start)
# enabledPlugins and model preferences cannot be project-scoped; must live here
cat > "$HOME/.claude/settings.json" << 'EOF'
{
  "model": "claude-sonnet-4-6",
  "effortLevel": "medium",
  "cleanupPeriodDays": 1095,
  "skipDangerousModePermissionPrompt": true,
  "enabledPlugins": {
    "skill-creator@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "pyright-lsp@claude-plugins-official": true,
    "ralph-loop@claude-plugins-official": true
  },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
EOF

# CLAUDE.md stub — points to project-level config (used for interactive sessions)
cat > "$HOME/.claude/CLAUDE.md" << 'EOF'
# User Preferences

All preferences are in the project-level CLAUDE.md at ~/workspace/CLAUDE.md.
Always launch Claude from ~/workspace.
EOF

# .env.op — 1Password references for API keys used by Claude Code itself
cat > "$HOME/.claude/.env.op" << 'EOF'
OPENAI_API_KEY=op://Your-Vault/OpenAI API/OPENAI_API_KEY
EOF
echo "Claude user config written"

# Ensure claude binary is on PATH for interactive SSH sessions
grep -q 'PATH.*\.local/bin' "$HOME/.bashrc" 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

# Load secrets into environment (all child processes inherit these)
if [ -f "$SECRETS_FILE" ]; then
    set -a
    source "$SECRETS_FILE"
    set +a
fi

# Write Claude credentials from 1Password-injected OAuth token (1-year setup-token)
# credentials.json is needed because not all consumers source the env var.
# Token is a 1-year setup-token — refreshToken/expiresAt are N/A.
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    mkdir -p "$HOME/.claude"
    # Remove immutable flag if set from previous startup (so we can rewrite)
    chattr -i "$HOME/.claude/.credentials.json" 2>/dev/null || true
    cat > "$HOME/.claude/.credentials.json" << CREDSEOF
{
  "claudeAiOauth": {
    "accessToken": "${CLAUDE_CODE_OAUTH_TOKEN}",
    "refreshToken": null,
    "expiresAt": null,
    "scopes": ["user:inference"]
  }
}
CREDSEOF
    chmod 600 "$HOME/.claude/.credentials.json"
    # Write marker so auth-refresh can detect if claude login overwrites this
    echo "setup-token" > "$HOME/.claude/.credentials.json.type"
    # Protect against accidental overwrite by 'claude login' interactive sessions
    chattr +i "$HOME/.claude/.credentials.json" 2>/dev/null || true
    echo "Claude credentials written from 1Password (1-year setup-token, protected)"

    # Validate the token actually works before starting services
    # Catches expired tokens from 1Password that would silently fail all jobs
    if claude -p 'ping' --max-turns 1 > /dev/null 2>&1; then
        echo "Claude auth validated — token is live"
    else
        echo "CRITICAL: Claude auth FAILED — token from 1Password may be expired"
        echo "  Fix: on Mac, run 'claude setup-token'"
        echo "  then update 1Password item and restart container"
        echo "  NEVER run 'claude login' inside the container"
        # Send Slack alert if bot token is available
        if [ -n "${SLACK_BOT_TOKEN:-}" ] && [ -n "${SLACK_LOGS_CHANNEL_ID:-}" ]; then
            curl -s -X POST https://slack.com/api/chat.postMessage \
                -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"channel\":\"${SLACK_LOGS_CHANNEL_ID}\",\"text\":\":rotating_light: Claude auth FAILED at startup. Setup-token may be expired. Fix: run 'claude setup-token' on Mac, update 1Password, restart container.\"}" \
                > /dev/null 2>&1 || true
        fi
        # Attempt self-heal via auth-refresh script
        if [ -f "$HOME/workspace/.claude/scripts/auth-refresh.sh" ]; then
            echo "Attempting self-heal via auth-refresh.sh..."
            bash "$HOME/workspace/.claude/scripts/auth-refresh.sh" 2>&1 || true
        fi
    fi
else
    echo "WARNING: CLAUDE_CODE_OAUTH_TOKEN not set — Claude auth not configured"
fi

# ============================================================================
# PHASE 5: Boot-check — run any missed scheduled jobs
# ============================================================================
# If the container restarts mid-day, this catches up on jobs that should
# have already run. Replaces a 15-min polling cron with a one-shot at boot.

log_boot() { echo "[boot-check] $(date +%H:%M:%S) $*"; }
BOOT_HOUR=$(date +%-H)
STATE_DIR="$HOME/.claude/job-state"
SCRIPTS="$HOME/workspace/.claude/scripts"
TODAY=$(date +%Y-%m-%d)

check_and_run() {
    local name="$1" earliest_hour="$2" script="$3"
    local latest_hour=$(( earliest_hour + 4 ))
    local state_file="$STATE_DIR/$name.last-run"
    local last_run
    last_run=$(cat "$state_file" 2>/dev/null || echo "never")

    [ "$last_run" = "$TODAY" ] && return 0  # Already ran today
    [ "$BOOT_HOUR" -lt "$earliest_hour" ] && return 0  # Too early
    [ "$BOOT_HOUR" -ge "$latest_hour" ] && { log_boot "Skipping $name — past catch-up window (${earliest_hour}:00-${latest_hour}:00)"; return 0; }
    [ ! -f "$script" ] && return 0

    log_boot "Running missed job: $name"
    if bash "$script" >> "$STATE_DIR/$name-boot.log" 2>&1; then
        echo "$TODAY" > "$state_file"
        log_boot "$name completed"
    else
        log_boot "$name failed"
    fi
}

mkdir -p "$STATE_DIR"
check_and_run "daily-retro" 3 "$SCRIPTS/daily-retro.sh"
check_and_run "morning-orchestrator" 5 "$SCRIPTS/morning-orchestrator.sh"
check_and_run "afternoon-scan" 16 "$SCRIPTS/afternoon-scan.sh"

# ============================================================================
# PHASE 6: Slack daemon startup
# ============================================================================

# Install Slack daemon dependencies if needed
SLACK_DAEMON_DIR="$HOME/workspace/.claude/scripts/slack-daemon"
if [ -d "$SLACK_DAEMON_DIR" ] && [ -f "$SLACK_DAEMON_DIR/package.json" ]; then
    if [ ! -d "$SLACK_DAEMON_DIR/node_modules" ]; then
        echo "Installing slack daemon dependencies..."
        cd "$SLACK_DAEMON_DIR" && npm install --production 2>/dev/null || true
        cd "$HOME"
    fi
fi

# Start Slack daemon if credentials loaded
if [ -f "$SECRETS_FILE" ]; then
    if [ -d "$SLACK_DAEMON_DIR" ] && [ -f "$SLACK_DAEMON_DIR/index.js" ]; then
        cd "$SLACK_DAEMON_DIR"
        node index.js &
        SLACK_PID=$!
        echo "Slack daemon started (PID $SLACK_PID)"
        cd "$HOME"
    else
        echo "Slack daemon files not found, skipping"
    fi
else
    echo "No secrets loaded, slack daemon skipped"
fi

# ============================================================================
# PHASE 7: MCP server startup (optional)
# ============================================================================

# Start any MCP servers that should be shared across Claude sessions
# Example: reddit-mcp-buddy in HTTP mode (one shared server, not one per session)
# REDDIT_BUDDY_HTTP=true npx -y reddit-mcp-buddy > "$HOME/.claude/job-state/mcp-server.log" 2>&1 &
# MCP_PID=$!
# for i in $(seq 1 15); do
#     curl -s http://localhost:3000/mcp --max-time 1 -o /dev/null 2>&1 && break
#     sleep 1
# done

echo ""
echo "Agent container ready."
echo "  SSH:  ssh -p 2222 claude@localhost"
echo "  Auth: setup-token from 1Password (NEVER run 'claude login' inside container)"
echo ""

# ============================================================================
# PHASE 8: Supervisor loop
# ============================================================================
# Keeps the container alive. Restarts daemons on crash. Detects code changes
# in the Slack daemon and hot-reloads.

# Disable exit-on-error for the supervisor section — transient failures in
# checksum pipelines, kill -0 on reaped PIDs, and curl health checks are
# expected and must not crash the container.
set +e

# Track daemon code checksum for restart-on-change
DAEMON_CHECKSUM=""
if [ -d "$SLACK_DAEMON_DIR" ]; then
    DAEMON_CHECKSUM=$(find "$SLACK_DAEMON_DIR" -name "*.js" -o -name "*.json" | sort | xargs cat 2>/dev/null | md5sum | cut -d' ' -f1)
fi

# Supervisor: keep container alive, restart daemons on crash, hot-reload on code change
while true; do
    sleep 10

    # Restart Slack daemon if it crashed
    if [ -n "${SLACK_PID:-}" ] && ! kill -0 "$SLACK_PID" 2>/dev/null; then
        echo "Slack daemon (PID $SLACK_PID) exited — restarting..."
        if [ -d "$SLACK_DAEMON_DIR" ] && [ -f "$SLACK_DAEMON_DIR/index.js" ]; then
            cd "$SLACK_DAEMON_DIR"
            node index.js >> "$HOME/.claude/agent-runner-state/slack-dispatch.log" 2>&1 &
            SLACK_PID=$!
            echo "Slack daemon restarted (PID $SLACK_PID)"
            cd "$HOME"
        fi
    fi

    # Hot-reload: restart Slack daemon if code changed (checksum comparison)
    if [ -d "$SLACK_DAEMON_DIR" ]; then
        NEW_CHECKSUM=$(find "$SLACK_DAEMON_DIR" -name "*.js" -o -name "*.json" | sort | xargs cat 2>/dev/null | md5sum | cut -d' ' -f1)
        if [ -n "$DAEMON_CHECKSUM" ] && [ "$NEW_CHECKSUM" != "$DAEMON_CHECKSUM" ]; then
            echo "Slack daemon code changed — restarting..."
            kill "$SLACK_PID" 2>/dev/null || true
            sleep 2
            cd "$SLACK_DAEMON_DIR" && node index.js >> "$HOME/.claude/agent-runner-state/slack-dispatch.log" 2>&1 &
            SLACK_PID=$!
            echo "Slack daemon restarted (PID $SLACK_PID)"
            cd "$HOME"
        fi
        DAEMON_CHECKSUM="$NEW_CHECKSUM"
    fi
done
