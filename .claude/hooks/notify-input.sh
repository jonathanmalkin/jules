#!/bin/bash
# Notification when Claude needs input.
# Mac: native macOS notification (existing behavior)
# Container: OSC 9 escape (picked up by VS Code Terminal Notification extension or iTerm2)

# Consume stdin (Claude Code sends JSON) so it doesn't block
cat > /dev/null

# Mac: native notification (only if terminal is not in foreground)
if command -v osascript &>/dev/null; then
    front=$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)
    [[ "$front" == "iTerm2" || "$front" == "Code" ]] && exit 0
    osascript -e 'display notification "Awaiting your input" with title "Claude Code" sound name "default"'
    exit 0
fi

# Container: OSC 9 notification (VS Code Terminal Notification extension + iTerm2 SSH)
if [ -e /dev/tty ]; then
    printf '\033]9;Claude Code: Awaiting your input\033\\' > /dev/tty 2>/dev/null
fi
