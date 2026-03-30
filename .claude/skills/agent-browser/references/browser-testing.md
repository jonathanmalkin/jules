# Browser Testing

Use the `agent-browser` skill for all browser automation and testing. It's 10-100x faster than screenshot-based tools.

**Core workflow:**
1. `agent-browser open <url>` - Navigate
2. `agent-browser snapshot -i` - Get element refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact
4. Re-snapshot after any navigation or DOM change

**Key commands:**
- `snapshot -i` - Interactive elements only (fastest)
- `snapshot -i -C` - Include cursor-interactive elements (onclick divs)
- `wait --load networkidle` - Wait for network idle
- `screenshot` / `screenshot --full` - Capture page
- `--headed` flag - Watch browser visually for debugging

**Overlay/toast handling:** If `agent-browser click @ref` fails with "blocked by another element," an overlay (toast, modal backdrop) is covering the target. Use `agent-browser eval` with JS to click through overlays or dismiss them first.

**For local dev testing:** Start dev server first, then use agent-browser to test the running app.
