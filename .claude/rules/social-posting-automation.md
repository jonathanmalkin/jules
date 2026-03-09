---
paths:
  - "**/Scripts/post-to-x*"
  - "**/Scripts/chrome-debug*"
  - "**/Scripts/x-post*"
  - "**/.claude/skills/post-article/**"
---

# Social Media Posting Automation

## Architecture

X posts via Chrome CDP + `agent-browser --auto-connect`. Reddit stays manual clipboard.

**Why not Playwright sessions?** Some platforms detect and block Playwright-launched browsers -- even with `--executable-path` pointing to system Chrome, stealth args like `--disable-blink-features=AutomationControlled`, or the `--headed` flag. The `navigator.webdriver` flag and `Runtime.enable` CDP leak are the primary detection vectors.

**Why not X API?** Check your API tier -- free tiers may not support posting.

## Chrome CDP Setup

Chrome 136+ requires `--user-data-dir` for `--remote-debugging-port` to bind. Without it, the port silently fails. This was a security change to prevent infostealer malware from exploiting remote debugging.

```bash
# Launch (or use Scripts/chrome-debug.sh):
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --user-data-dir="$HOME/.chrome-debug-profile" --remote-debugging-port=9222

# Verify:
curl -s http://127.0.0.1:9222/json/version
```

**Profile:** `~/.chrome-debug-profile` -- persists login sessions across Chrome restarts. The user logs in once manually; auth persists in the profile.

## Posting Scripts

| Script | Platform | Key flags |
|--------|----------|-----------|
| `Scripts/post-to-x-auto.sh` | X | `--reply-to <url>`, `--post` |
| `Scripts/chrome-debug.sh` | (helper) | `--check` to verify |

All scripts are dry-run by default (screenshot only). Pass `--post` to actually publish.

## Troubleshooting

- **Port not binding:** Ensure `--user-data-dir` is set. Kill all Chrome instances first (`pkill -f "Google Chrome"`).
- **Login expired:** Open the Chrome debug window manually, navigate to X, log in again. The profile retains the session.
- **`agent-browser --auto-connect` fails:** Check `curl http://127.0.0.1:9222/json/version`. If empty, Chrome isn't running with debug port.
