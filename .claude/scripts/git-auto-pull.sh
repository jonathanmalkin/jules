#!/usr/bin/env bash
# Daemon: fetch all refs from origin, fast-forward pull main only.
# Runs via launchd (Mac) or cron (container) on a schedule. Not a Claude hook.

set -euo pipefail

REPO="$HOME/workspace"
LOG="$HOME/.claude/good-morning-state/git-auto-pull.log"
STATUS_FILE="/tmp/git-auto-pull-status"

mkdir -p "$(dirname "$LOG")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/notify.sh"

cd "$REPO"

# Must be in a git repo
git rev-parse --is-inside-work-tree &>/dev/null || { log "Not a git repo"; exit 0; }

# Fetch
if ! GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=10 \
  git -c fetch.negotiationAlgorithm=noop fetch origin &>/dev/null; then
  log "FETCH FAILED — network or auth issue"
  echo "fetch_failed $(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_FILE"
  exit 0
fi

LOCAL=$(git rev-parse main 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null)

if [[ "$LOCAL" == "$REMOTE" ]]; then
  log "Up to date"
  echo "up_to_date $(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_FILE"
  exit 0
fi

# Diverged?
if ! git merge-base --is-ancestor "$LOCAL" "$REMOTE" 2>/dev/null; then
  log "DIVERGED — local and origin/main have diverged, manual resolution needed"
  echo "diverged $(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_FILE"
  notify_failure "Git Auto-Pull" "main has diverged from origin — manual resolution needed"
  exit 0
fi

BEHIND=$(git rev-list --count "$LOCAL".."$REMOTE")

# Fast-forward pull
if OUTPUT=$(git pull --ff-only --autostash 2>&1); then
  COMMITS=$(git log --oneline "$LOCAL".."$REMOTE")
  log "PULLED $BEHIND commit(s): $COMMITS"
  echo "pulled $BEHIND $(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_FILE"
else
  log "PULL FAILED: $OUTPUT"
  echo "pull_failed $(date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_FILE"
  notify_failure "Git Auto-Pull" "Fast-forward pull failed"
fi
