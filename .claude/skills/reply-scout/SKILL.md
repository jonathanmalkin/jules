---
name: reply-scout
description: >
  Scan Reddit and X for Claude Code questions matching FAQ patterns, draft polished replies,
  and queue them for one-click approval. Use when user says "reply scout", "find FAQ posts",
  "scan for replies", "FAQ scan", "what can I answer", or invokes /reply-scout.
  Do NOT use for broad engagement scanning (use /engage) or competitive intelligence (use /scout-techniques).
---

# Reply Scout

Scan Reddit and X for Claude Code questions matching FAQ expertise, draft polished replies, queue for approval.

## Phase 1: Load State

Read these files for context (skip gracefully if missing):

1. `Documents/Engagement/reply-queue.md` — check for pending items from a previous scan. If pending items exist, present them first and ask: "You have N pending replies from last scan. Review those first, or fresh scan?"
2. `Documents/Engagement/feedback.md` — quality preferences and scoring adjustments
3. `Documents/Content-Pipeline/Published-URLs.md` — linkable articles for replies

## Phase 2: Reddit Scan

1. Browse your primary subreddit new (25 posts) via `mcp__reddit-mcp-buddy__browse_subreddit`
2. Browse your primary subreddit hot (15 posts) via `mcp__reddit-mcp-buddy__browse_subreddit`
3. For each post: run `bash .claude/scripts/scout-seen-posts.sh check <post_id>` — skip if exit code 0 (already seen)
4. Filter for question-like posts: title contains `?`, "how", "why", "help", "issue", "problem", "can't", "doesn't", "error", "stuck", "confused", "anyone", "advice", "recommend", "best way", "should I", "what do you", "tips". Cast a wide net. Include basic/beginner questions, not just advanced CLI topics.
5. For candidates: fetch full details + comments via `mcp__reddit-mcp-buddy__get_post_details`
6. Drop posts that are: locked, have 3+ quality answers already, older than 24h
7. If the primary subreddit produces fewer than 5 candidates, also browse secondary subreddits

**Important from feedback.md:** Check whether OP is asking about Claude (chatbot/web) vs Claude Code (CLI). Don't draft replies for web-interface questions.

## Phase 3: X Scan (API)

Use the X API via your FAQ search script for reliable tweet discovery.

1. Run: `bash Scripts/x-search-faq.sh > /tmp/x-faq-results.json`
2. Parse the JSON output. Each tweet has: `id`, `category`, `text`, `author`, `created_at`, `likes`, `retweets`, `replies`, `query`
3. Filter for question-like tweets: text contains `?`, "how", "help", "issue", "problem", "anyone", "can't", "doesn't work"
4. For each candidate: run `bash .claude/scripts/scout-seen-posts.sh check <tweet_id>` — skip if already seen
5. Drop tweets older than 24h, tweets with 3+ quality replies, tweets that are clearly about Claude web (not Claude Code)

**If the API call fails** (auth error, rate limit): note "X scan failed: [error]" and continue with Reddit-only results. Don't retry.

## Phase 4: Classify and Score

### FAQ Categories
Classify each candidate into categories based on the question content:
- **Cost** — pricing, token usage, billing, credits, API costs
- **Memory** — CLAUDE.md, project memory, auto-memory, context persistence
- **Errors** — error messages, crashes, failures, unexpected behavior
- **Workflows** — plan mode, git integration, commit patterns, session management
- **Setup** — installation, configuration, first-time setup, permissions
- **Hooks** — PreToolUse, PostToolUse, custom hooks, bash hooks
- **CLAUDE.md** — structure, best practices, what to put in CLAUDE.md
- **Agents** — subagents, agent delegation, multi-agent patterns
- **Permissions** — tool permissions, file access, security model
- **MCP** — MCP servers, tool integration, custom tools
- **IDE** — VS Code, cursor, editor integration, IDE comparison
- **Skills** — custom skills, skill triggers, slash commands

### Scoring
Score each candidate on 4 dimensions:
- **Relevance (0-3):** How well does this match your Claude Code expertise? 3 = direct FAQ pattern match, 0 = tangential
- **Freshness (0-2):** 2 = <2h old, 1 = 2-12h, 0 = 12-24h
- **Discussion (0-3):** 3 = 0 comments (first mover!), 2 = 1-2 comments, 1 = 3-5 but no good answer, 0 = well-answered
- **Author (0-2):** 2 = active poster with history, 1 = normal, 0 = throwaway or known troll

**Threshold:** Queue posts scoring 6+ out of 10. Skip below 6.

## Phase 5: Draft Replies

### Voice Rules

**Tone:** Conversational, experience-based. Like a person sharing what worked, not a product pitch.

**Structure:**
- Lead with empathy or validation: "Yeah, this bit me too" / "Good question, the docs don't cover this well" / "Ran into this exact thing last week"
- Share experience, not features: "I've been running X for months. Here's what worked..." NOT "Claude Code supports..."
- Ground in your actual setup. Only describe workflows, tools, and numbers you can verify from your files and memory. Don't invent or extrapolate anecdotes.
- Reddit: 3-6 sentences. X: 1-2 sentences (max 280 chars).
- Include a Published URL link only when genuinely natural (not forced). Max 1 link per reply.

**Anti-patterns (never do these):**
- Em-dashes (AI tell — restructure the sentence)
- Hedge words ("I think maybe you could consider...")
- Preamble ("Great question! Let me break this down...")
- Numbered-list architecture overviews (reads as AI-generated)
- Closing platitudes ("Hope this helps!", "Let me know!", "Happy to elaborate!")
- Feature lists disguised as advice
- 90/10 rule: 90% value, 10% promo max. Most replies should be 100% value, 0% promo.

**Voice reality check:** After the first batch, if the user rewrites >50% of replies, the voice rules need tuning. Note this for calibration.

## Phase 6: Write Queue

1. Write all pending items to `Documents/Engagement/reply-queue.md` using this format:

```
## Pending Approval

### #1 [Reddit r/ClaudeCode] "Post title here"
- **URL:** https://reddit.com/r/ClaudeCode/comments/...
- **Posted:** Xh ago by u/author (N upvotes, N comments)
- **FAQ Match:** Category > Specific pattern
- **Score:** X/10 (R:X F:X D:X A:X)

**Draft reply:**
> [polished reply text]

---
```

2. Present the full queue inline in the conversation with a summary: "Found N posts, drafted N replies. Here's the queue:"
3. Show each item with its score, category, and draft
4. End with: "Commands: `approve N`, `skip N`, `edit N`, `approve all`"

## Phase 7: Approval Loop

Handle these commands after presenting the queue:

### `approve N` (Reddit)
1. Copy the reply text to clipboard: write to `/tmp/reply-scout-reddit.txt`, then `printf '%s' "$(cat /tmp/reply-scout-reddit.txt)" | pbcopy`
2. Display the post URL so the user can open it and paste
3. Mark as "clipboard" in reply-queue.md (move to Recently Acted table)
4. Add to seen-posts tracker: `bash .claude/scripts/scout-seen-posts.sh add <post_id> "Post title"`
5. Say: "Reply copied. Open: [URL]"

### `approve N` (X)
1. Write reply to `/tmp/reply-scout-x.txt`
2. Extract tweet ID from the post URL
3. Dry-run first: `python3 Scripts/post-to-x.py --dry-run --file /tmp/reply-scout-x.txt --reply-to <tweet_id>`
4. Show the dry-run output. If the user confirms, post for real: `python3 Scripts/post-to-x.py --file /tmp/reply-scout-x.txt --reply-to <tweet_id>`
5. Mark as "posted" in reply-queue.md, add to seen-posts tracker

### `skip N`
1. Mark as "skipped" in reply-queue.md (move to Recently Acted with action "skipped")
2. Add to seen-posts tracker: `bash .claude/scripts/scout-seen-posts.sh add <post_id> "Post title"`
3. Say: "Skipped #N."

### `edit N`
1. Display the current draft
2. User dictates changes
3. Redraft based on feedback
4. Present the new draft for approval

### `approve all`
Process each item sequentially:
- Reddit items: clipboard one at a time, wait for user to confirm paste before next
- X items: dry-run each, then post on confirm
- After each: update reply-queue.md and seen-posts tracker

### After all actions
Update `Documents/Engagement/reply-queue.md`:
- Remove acted items from Pending Approval
- Add to Recently Acted table with date, platform, post title, and action (clipboard/posted/skipped)
- Prune Recently Acted entries older than 7 days
