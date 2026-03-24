#!/bin/bash
# PreToolUse hook: compresses verbose bash command output to save context tokens.
# Matches known high-volume commands and rewrites them through compress-wrapper.sh.
# On failure: wrapper passes full output for debugging.
set -euo pipefail

# Only process Bash tool calls
INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[[ -z "$COMMAND" ]] && exit 0

# Don't re-wrap already-wrapped commands
[[ "$COMMAND" == *"compress-wrapper.sh"* ]] && exit 0

# Resolve wrapper path relative to this script
WRAPPER="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)/compress-wrapper.sh"

# --- Simple rewrites (no wrapper needed) ---

# git status (bare) → git status --short
if [[ "$COMMAND" =~ ^[[:space:]]*git[[:space:]]+status[[:space:]]*$ ]]; then
  printf '{"updatedInput":{"command":"git status --short"}}\n'
  exit 0
fi

# --- Wrapper-based compression ---

HANDLER=""

# git diff (bare, no file args)
[[ "$COMMAND" =~ ^[[:space:]]*git[[:space:]]+diff[[:space:]]*$ ]] && HANDLER="git-diff"

# npm/pnpm install
[[ -z "$HANDLER" && "$COMMAND" =~ ^[[:space:]]*(npm|pnpm)[[:space:]]+install ]] && HANDLER="npm-install"

# test suites
[[ -z "$HANDLER" && "$COMMAND" =~ ^[[:space:]]*(npm[[:space:]]+test|pnpm[[:space:]]+test|pnpm[[:space:]]+run[[:space:]]+test|npx[[:space:]]+vitest|pnpm[[:space:]]+exec[[:space:]]+vitest) ]] && HANDLER="test-summary"

# brew install/upgrade
[[ -z "$HANDLER" && "$COMMAND" =~ ^[[:space:]]*brew[[:space:]]+(install|upgrade) ]] && HANDLER="brew-install"

# pip/pip3 install
[[ -z "$HANDLER" && "$COMMAND" =~ ^[[:space:]]*(pip3?)[[:space:]]+install ]] && HANDLER="pip-install"

# make targets
[[ -z "$HANDLER" && "$COMMAND" =~ ^[[:space:]]*make[[:space:]]+ ]] && HANDLER="make-target"

# ssh commands with potentially long output
[[ -z "$HANDLER" && "$COMMAND" =~ ^[[:space:]]*ssh[[:space:]]+ ]] && HANDLER="ssh-command"

# deploy scripts
[[ -z "$HANDLER" && "$COMMAND" =~ deploy ]] && HANDLER="deploy-script"

if [[ -n "$HANDLER" ]]; then
  CMD_B64=$(printf '%s' "$COMMAND" | base64 | tr -d '\n')
  printf '{"updatedInput":{"command":"%s %s %s"}}\n' "$WRAPPER" "$HANDLER" "$CMD_B64"
  exit 0
fi

# No match — allow as-is
exit 0
