#!/bin/bash
# cloud-bootstrap.sh — SessionStart hook for cloud containers
# Installs missing system packages that hooks depend on.
# Runs FIRST, before other SessionStart hooks.
# No-ops instantly on local (macOS) environments.

# Skip entirely on local
[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0

# One-time flag — don't re-run within same container
[ -f /tmp/claude-cloud-bootstrapped ] && exit 0

# Install missing system packages from default apt sources only
# gh is excluded — requires custom apt repo, not worth the complexity
NEEDED=()
command -v pdftotext &>/dev/null || NEEDED+=(poppler-utils)

if [ ${#NEEDED[@]} -gt 0 ]; then
  # Timeout after 30s to prevent blocking session start
  timeout 30 apt-get update -qq 2>/dev/null
  timeout 30 apt-get install -y -qq "${NEEDED[@]}" 2>/dev/null
fi

touch /tmp/claude-cloud-bootstrapped
exit 0
