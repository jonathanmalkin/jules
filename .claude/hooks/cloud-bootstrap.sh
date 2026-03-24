#!/bin/bash
# cloud-bootstrap.sh — SessionStart hook for non-Mac environments
# Installs missing system packages (one-time) and configures autoMemoryDirectory
# (idempotent, self-heals every session).
# Runs FIRST, before other SessionStart hooks.
# No-ops instantly on macOS (Mac has its own user-level settings.json).

LOG="/tmp/cloud-bootstrap.log"
log() { echo "[cloud-bootstrap] $(date +%H:%M:%S) $*" >> "$LOG"; }

# Log BEFORE any early exits — otherwise silent re-runs are invisible
log "Starting — HOME=$HOME, CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-unset}, pwd=$(pwd)"

# Skip on macOS — Mac is fully configured via native settings.json
if [ "$(uname)" = "Darwin" ]; then
  log "macOS detected — skipping"
  exit 0
fi

# ── Memory config (idempotent, runs every session) ──────────────────────
# Self-heals if settings.json loses autoMemoryDirectory (e.g., platform
# overwrites it between sessions). The grep check makes this idempotent.
#
# Path resolution order:
#   1. CLAUDE_PROJECT_DIR (set by Claude Code for hooks)
#   2. git rev-parse --show-toplevel (works if cwd is inside the repo)
#   3. Known cloud VM repo paths (hardcoded fallbacks)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR/.claude-memory" ]; then
  for candidate in /home/user/workspace /home/user/repos/workspace /workspace; do
    if [ -d "$candidate/.claude-memory" ]; then
      PROJECT_DIR="$candidate"
      break
    fi
  done
fi
log "Resolved PROJECT_DIR=$PROJECT_DIR"

USER_SETTINGS="$HOME/.claude/settings.json"

if [ -d "${PROJECT_DIR}/.claude-memory" ]; then
  log ".claude-memory found at $PROJECT_DIR"

  # Register theirs-memory merge driver (entrypoint.sh does this for container)
  if ! git -C "$PROJECT_DIR" config merge.theirs-memory.driver >/dev/null 2>&1; then
    git -C "$PROJECT_DIR" config merge.theirs-memory.name "Always accept incoming memory changes" 2>/dev/null
    git -C "$PROJECT_DIR" config merge.theirs-memory.driver "cp %B %A" 2>/dev/null
    log "Registered theirs-memory merge driver"
  fi

  if ! grep -q 'autoMemoryDirectory' "$USER_SETTINGS" 2>/dev/null; then
    mkdir -p "$HOME/.claude"
    if [ -f "$USER_SETTINGS" ] && command -v jq &>/dev/null; then
      log "Merging autoMemoryDirectory into existing $USER_SETTINGS via jq"
      jq --arg dir "${PROJECT_DIR}/.claude-memory" '. + {"autoMemoryDirectory": $dir}' \
        "$USER_SETTINGS" > "${USER_SETTINGS}.tmp" && mv "${USER_SETTINGS}.tmp" "$USER_SETTINGS"
    elif [ -f "$USER_SETTINGS" ]; then
      log "jq unavailable, using python3 to merge"
      python3 -c "
import json, sys
with open('$USER_SETTINGS') as f:
    d = json.load(f)
d['autoMemoryDirectory'] = '${PROJECT_DIR}/.claude-memory'
with open('$USER_SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null && log "Merged via python3" || log "python3 merge failed"
    else
      log "Creating fresh $USER_SETTINGS"
      cat > "$USER_SETTINGS" << MEMSETTINGS
{
  "autoMemoryDirectory": "${PROJECT_DIR}/.claude-memory",
  "model": "claude-sonnet-4-6",
  "effortLevel": "medium"
}
MEMSETTINGS
    fi
  else
    log "autoMemoryDirectory already present in $USER_SETTINGS — skipping"
  fi
else
  log "No .claude-memory at $PROJECT_DIR — skipping memory config"
fi

# ── Package installation (one-time per container lifecycle) ─────────────
if [ ! -f /tmp/claude-cloud-bootstrapped ]; then
  NEEDED=()
  command -v pdftotext &>/dev/null || NEEDED+=(poppler-utils)
  command -v jq &>/dev/null || NEEDED+=(jq)

  if [ ${#NEEDED[@]} -gt 0 ]; then
    log "Installing packages: ${NEEDED[*]}"
    timeout 30 apt-get update -qq 2>/dev/null
    timeout 30 apt-get install -y -qq "${NEEDED[@]}" 2>/dev/null
  else
    log "All packages already installed"
  fi

  touch /tmp/claude-cloud-bootstrapped
fi

log "Done"
exit 0
