#!/bin/bash
# session-start.sh — SessionStart hook
# Pulls latest changes on session open. Optionally regenerates workspace index.
# Replaces the old git-auto-pull launchd job.

set -euo pipefail

WORKSPACE="${CLAUDE_PROJECT_DIR:-$HOME/Jules}"
cd "$WORKSPACE"

# Pull latest (fast-forward only, no merge commits)
git pull --ff-only 2>/dev/null || true