#!/usr/bin/env bash
# Root-level entrypoint — starts privileged services, then drops to claude user
# Runs as root so that no-new-privileges:true can be set on the container.
# sshd and cron must be started here (root) since sudo is blocked by no-new-privileges.
set -euo pipefail

echo "Starting root services..."

# SSH daemon
/usr/sbin/sshd
echo "SSH server started on port 22"

# Install claude user's crontab (requires root write access to /var/spool/cron/)
crontab -u claude /home/claude/.crontab
echo "Cron schedule installed for claude"

# Cron daemon
cron
echo "Cron daemon started"

# Fix ownership on Docker-created volumes (default to root)
chown claude:claude /home/claude/.vscode-server 2>/dev/null || true
chown claude:claude /home/claude/.claude 2>/dev/null || true

# Drop to claude user and hand off to the user-level entrypoint
echo "Dropping to claude user..."
exec su -s /bin/bash claude -c /home/claude/entrypoint.sh
