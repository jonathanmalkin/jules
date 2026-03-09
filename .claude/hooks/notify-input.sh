#!/bin/bash
# macOS notification when Claude needs input (only if terminal is not active).
# No-op on cloud/Linux. Assumes iTerm2 exclusively.
command -v osascript &>/dev/null || exit 0

# Consume stdin (Claude Code sends JSON) so it doesn't block
cat > /dev/null

front=$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)

# Don't notify if the terminal app is in the foreground (any tab)
[ "$front" = "iTerm2" ] && exit 0

osascript -e 'display notification "Awaiting your input" with title "Claude Code" sound name "default"'
