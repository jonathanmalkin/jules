---
paths:
  - Scripts/post-to-x-auto.sh
  - .claude/skills/post-article/**
---

# X Browser Posting (CDP + agent-browser)

## Input Method

**Always use clipboard paste.** X's Draft.js editor rejects programmatic input:
- `fill` -- text appears in DOM but React state doesn't update (Post button stays disabled)
- `type` -- same issue
- `execCommand('insertText')` -- splits multi-line content into separate tweets (only last line posts)
- `keyboard inserttext` -- same as execCommand

**Working pattern:**
```bash
printf '%s' "$CONTENT" | pbcopy
agent-browser --auto-connect click "$COMPOSE_REF"
sleep 0.5
agent-browser --auto-connect press "Meta+v"
```

## Thread Posting

Reply to each successive tweet, not all to the original:
1. Post Tweet 1 from home compose
2. Navigate to Tweet 1 detail page -> reply with Tweet 2
3. Click into Tweet 2 (via timestamp link) -> reply with Tweet 3
4. Repeat

Find the new reply via `link "Now"` or `link "X seconds ago"` in the snapshot.

## Button Detection

Always filter out disabled buttons when finding Post/Reply:
```bash
grep 'button "Reply"' | grep -v disabled
```

## Character Limit

If X Premium is active, the char limit is **25,000** for regular posts. Posts over 280 chars show a "Show more" link to non-Premium readers. Check with `wc -m` (not `wc -c` which counts bytes).

**X Articles** (separate feature): Up to ~100,000 chars with rich formatting. Desktop-only, no API -- must be created manually in X's web editor. Cannot be automated via agent-browser.

## Premium Upsell

X shows "Want more people to see your reply?" modal after posting replies. Dismiss with:
```bash
agent-browser --auto-connect find text "Maybe later" click 2>&1 || true
```
Don't block on failure -- modal doesn't always appear.
