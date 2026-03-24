#!/bin/bash
# inject-environment.sh — SessionStart hook
# Detects which environment the agent is running in and injects it as context.
# This lets the agent make correct environment-specific decisions automatically
# (SSH commands, credential paths, clipboard, docker exec, etc.)

# Detection order: most specific first.
# Primary container signal: /tmp/agent-secrets.env written by entrypoint.sh on every container start.
# SSH state file is a secondary signal (may not be present in all container sessions).
if [ "$CLAUDE_CODE_REMOTE" = "true" ]; then
  ENV_NAME="anthropic-cloud"
  ENV_NOTES="Anthropic hosted cloud container. No persistent storage. No SSH access. No container tools. Uses CLAUDE_CODE_REMOTE=true."
elif [ -f /tmp/agent-secrets.env ] || [ -f /tmp/ssh-state/ssh_config ]; then
  ENV_NAME="your-container"
  ENV_NOTES="your-agent-dev Docker container on VPS. Git push uses: GIT_SSH_COMMAND='ssh -F /tmp/ssh-state/ssh_config'. Credentials in /tmp/agent-secrets.env and env vars. No pbcopy. No docker exec (already inside). Daemon restarts via kill + supervisor respawn."
elif [ "$(uname -s)" = "Darwin" ]; then
  ENV_NAME="mac"
  ENV_NOTES="Mac interactive session. Primary dev environment. Credentials via 1Password biometric. pbcopy/pbpaste available. Native file links and clipboard. Container is automation sidecar (cron, Slack daemon). Access container via 'ssh your-container' for logs/debugging. Git push uses native SSH + github-workspace alias. Can run 'ssh your-vps' and 'docker exec'. Homebrew tools available."
else
  ENV_NAME="unknown"
  ENV_NOTES="Environment could not be determined."
fi

# Surface today's session report for cross-session continuity
TODAY=$(date +%Y-%m-%d)
TODAY_REPORT="$HOME/workspace/Documents/Field-Notes/Logs/${TODAY}-Session-Report.md"
HANDOFF=""
if [ -f "$TODAY_REPORT" ]; then
  HANDOFF=" Today's session report exists at $TODAY_REPORT. Read it for context from earlier sessions today."
fi

cat <<HEREDOC | jq -Rs '{"context": .}'
Agent is running in: ${ENV_NAME}. ${ENV_NOTES}${HANDOFF}
HEREDOC
