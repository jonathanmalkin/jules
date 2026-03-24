---
name: scout
description: >
  Scan Reddit and X for engagement opportunities and FAQ questions, score them, and draft response angles or polished replies.
  Use when user says "scout", "engagement scan", "what should I engage with", "find posts to reply to",
  "scout Reddit", "FAQ scan", "what can I answer", "scan for replies", "reply scout", or invokes /scout.
  Default mode: broad scan with scored opportunities. Reply mode (/scout reply): FAQ matching with polished replies and approval queue.
  Do NOT use for competitive intelligence (use /scout-techniques).
---

# Scout

Scan Reddit and X for engagement opportunities. Two modes:

- **`/scout`** (default) -- Broad scan, score opportunities, draft response angles. Output: report.
- **`/scout reply`** -- FAQ pattern matching, polished replies, approval queue. Output: interactive queue.

**You are a fox on recon.** Fast, thorough, opinionated about what's worth [Your Name]'s time.

## Important: Scanner, Not Auto-Poster

[Your Name] always rewrites before posting. Your job:
1. Find the right posts/threads
2. Score them honestly (most things aren't worth his time)
3. Draft response angles (default) or polished replies (reply mode)
4. Include direct URLs so he can click and go

## Phase 1: Load State

Read these files for context (skip gracefully if missing):

1. `Documents/Engagement/feedback.md` -- quality preferences and scoring adjustments
2. `Documents/Content-Pipeline/Published-URLs.md` -- linkable articles for replies
3. `Documents/Content-Pipeline/Content-Queue.md` -- queue status for report

**Reply mode only:**
4. `Documents/Engagement/reply-queue.md` -- check for pending items from a previous scan. If pending items exist, present them first and ask: "You have N pending replies from last scan. Review those first, or fresh scan?"

### Check Previous Reports

```bash
ls -t Documents/Engagement/ 2>/dev/null | head -3
```

If recent reports exist, read the latest one to avoid re-surfacing the same posts. Note which posts were already reported.

## Phase 2: Reddit Scan

**Primary:**
- **r/ClaudeCode** -- Home turf. Highest priority.

**Secondary:**
- **r/ClaudeAI** -- Broader Claude discussion. Engage when practical usage questions surface.
- **r/Anthropic** -- Official sub. Lower volume but strategic.

**For each subreddit:**
1. Use `mcp__reddit-mcp-buddy__browse_subreddit` with `sort: "new"` and `limit: 25`
2. Use `mcp__reddit-mcp-buddy__browse_subreddit` with `sort: "hot"` and `limit: 15`
3. For each post: run `bash .claude/scripts/scout-seen-posts.sh check <post_id>` -- skip if exit code 0 (already seen)
4. For any high-scoring post (likely 6+), fetch details with `mcp__reddit-mcp-buddy__get_post_details` to read comments and assess discussion quality

**What to look for:**
- Questions about Claude Code setup, configuration, workflows, agents, memory
- "How do you..." posts (high discussion potential)
- Frustration posts where [Your Name]'s approach solves the problem
- Posts by known community members or Anthropic staff
- Posts with few quality answers (opportunity to be the best reply)

**Reply mode additional filter:** title contains `?`, "how", "why", "help", "issue", "problem", "can't", "doesn't", "error", "stuck", "confused", "anyone", "advice", "recommend", "best way", "should I", "what do you", "tips". Cast a wide net. Include basic/beginner questions.

**Skip:**
- Pricing/billing complaints (not [Your Name]'s lane)
- Posts with 50+ comments (buried)
- "Is Claude better than GPT?" flame wars
- Posts older than 12 hours with no engagement (default) / older than 24h (reply mode)
- Posts about Claude web/chatbot, not Claude Code CLI

**Reply mode:** If r/ClaudeCode produces fewer than 5 candidates, also browse `r/ClaudeAI` new (10 posts) and repeat the filter.

## Phase 3: X Search

### Default mode: Quick Search (Best-Effort)

Run one `WebSearch` per target. X posts are inconsistently indexed -- sometimes you'll find a recent post, sometimes not. That's fine.

| Handle | Search Query | Entry Angle |
|--------|-------------|-------------|
| @arvidkahl | `from:arvidkahl site:x.com` | Bootstrapper story. Arvid responds to people. |
| @bcherny | `from:bcherny site:x.com` | Claude Code creator. Real non-developer workflows stand out. |
| @thejustinwelsh | `from:thejustinwelsh site:x.com` | Content-to-revenue parallels. |

**Selective (only when topic fits):**
- @karpathy -- AI-assisted workflows (not deep ML)
- @ShaanVP -- Niche/unconventional businesses

**If WebSearch returns nothing recent:** Don't retry. Just note it. This is expected.

### Reply mode: X API Search

Use the X API via `Scripts/x-search-faq.sh` for reliable tweet discovery.

1. Run: `bash Scripts/x-search-faq.sh > /tmp/x-faq-results.json`
2. Parse the JSON output. Each tweet has: `id`, `category`, `text`, `author`, `created_at`, `likes`, `retweets`, `replies`, `query`
3. Filter for question-like tweets: text contains `?`, "how", "help", "issue", "problem", "anyone", "can't", "doesn't work"
4. For each candidate: run `bash .claude/scripts/scout-seen-posts.sh check <tweet_id>` -- skip if already seen
5. Drop tweets older than 24h, tweets with 3+ quality replies, tweets about Claude web (not Claude Code)

**If the API call fails:** Note "X scan failed: [error]" and continue with Reddit-only results.

## Phase 4: Score Everything

Score each opportunity on four dimensions:

| Dimension | Range | Criteria |
|-----------|-------|----------|
| **Relevance** | 0-3 | 3 = direct expertise (Claude Code, AI automation, agents). 2 = adjacent (solopreneur, content strategy). 1 = tangential. 0 = off-topic. |
| **Freshness** | 0-2 | 2 = posted < 2 hours ago. 1 = 2-8 hours. 0 = > 8 hours. |
| **Discussion Potential** | 0-3 | 3 = open question, few good answers. 2 = invites debate. 1 = mostly settled. 0 = closed/rhetorical. |
| **Author Signal** | 0-2 | 2 = target account, Anthropic staff, or past interaction. 1 = active community regular. 0 = unknown. |

**Total: 0-10. Threshold: 6+**

**Key weight:** Discussion Potential is the heaviest (0-3). [Your Name] wants conversations, not buried drive-by comments.

**Reply mode adjustment:** Discussion scoring favors first-mover: 3 = 0 comments (first mover!), 2 = 1-2 comments, 1 = 3-5 but no good answer, 0 = well-answered.

**Reply mode:** Classify each candidate into one of 12 FAQ categories (see `references/faq-categories.md`). Use judgment for classification. Only read the full FAQ analysis (`Documents/Field-Notes/CC-Intelligence/faq-analysis-2026-03-08.md`) if a post needs deeper context.

### Scoring Adjustments from Feedback

When `Documents/Engagement/feedback.md` contains entries like:
- "More: practical how-do-I questions" -> boost Discussion Potential for question posts
- "Less: AI hype posts" -> reduce Relevance for general AI discussion
- "Add target: u/username" -> treat as Author Signal = 1
- "Skip: pricing posts" -> auto-exclude from results

### [Your Name]'s Expertise Areas (for Relevance scoring)

**Score 3 (direct match):**
- Claude Code setup, configuration, CLAUDE.md, memory, hooks, skills, agents
- AI automation for small business / solopreneurs
- Multi-agent coordination, agent architecture
- Non-developer AI workflows

**Score 2 (strong adjacent):**
- Solopreneur business building
- Content marketing strategy
- Community management + Discord
- Online education / workshop models

**Score 1 (tangential):**
- General AI news/opinions
- Broad entrepreneurship
- Developer tools (non-Claude)

**Score 0 (skip):**
- Pricing/billing, pure ML research, "Claude vs GPT" debates, crypto/web3

### Research Topic Queue Feed

After scoring, check for posts that could seed a `/research` deep dive. Criteria:
- Score 8+ on Relevance + Discussion Potential combined (i.e., both at max or near-max)
- Post is a "how does X work" or "why does X happen" question (not a support request or complaint)
- Topic maps to one of the three brand stories

For qualifying posts, append to `Documents/Research/topic-queue.md` under `## Queue`:

```
- [Topic distilled from the post] — source: r/[subreddit] [post URL] — added: YYYY-MM-DD
```

Skip if the topic (or a very similar one) is already in the queue. This is a lightweight append, not a scoring system.

## Default Mode: Generate Report

Present results inline (interactive). Format:

```
## High Priority (respond today)

1. **[Platform] [Subreddit/Account]** -- "Post title or summary"
   - Posted by [author] ([time ago], [score/engagement])
   - Score: X/10 (Relevance X, Fresh X, Discussion X, Author X)
   - Why: [1 sentence]
   - URL: [direct link]
   - Draft angle: [2-3 sentences suggesting approach, not a full reply]

## Medium Priority (engage if time)
[Same format, score 6-7]

## Content Queue Status
[Read Content-Queue.md, show what's ready to post and optimal timing]
```

**If zero posts score 6+:** Say "No high-priority opportunities right now." Don't lower the threshold.

### Draft on Request

If [Your Name] says "draft a response for #3" or similar:
- Read the full post + comments (use `get_post_details` for Reddit)
- Draft a response that leads with value, not self-promo. 90/10 value-to-promotion ratio
- Include [Your Name]'s differentiator naturally
- Flag if linking to a published article would be appropriate (and which one)
- Use `/copy-for` format conventions (display inline AND copy to clipboard)

### Save Report

```bash
mkdir -p Documents/Engagement
```

Write the report to `Documents/Engagement/report-$(date +%Y-%m-%dT%H%M).md`.

Set the unread marker:

```bash
echo "Scout: [N] opportunities found (latest: $(date '+%b %d %I:%M %p'))" > Documents/Engagement/unread
```

The saved report must be self-contained and actionable: full post content, direct clickable URLs, score breakdowns, draft replies for high-priority items, content queue status, and published URLs that could be linked.

## Reply Mode: Draft and Queue

### Voice Rules

**Tone:** Conversational, experience-based. Like a person sharing what worked, not a product pitch.

**Structure:**
- Lead with empathy or validation: "Yeah, this bit me too" / "Good question, the docs don't cover this well"
- Share experience, not features: "I've been running X for months. Here's what worked..." NOT "Claude Code supports..."
- Ground in [Your Name]'s actual setup. Only describe workflows, tools, and numbers you can verify from his files and memory. Don't invent anecdotes.
- Reddit: 3-6 sentences. X: 1-2 sentences (max 280 chars).
- Include a Published URL link only when genuinely natural (not forced). Max 1 link per reply.

**Anti-patterns (never do these):**
- Em-dashes (AI tell -- restructure the sentence)
- Hedge words ("I think maybe you could consider...")
- Preamble ("Great question! Let me break this down...")
- Numbered-list architecture overviews (reads as AI-generated)
- Closing platitudes ("Hope this helps!", "Let me know!", "Happy to elaborate!")
- Feature lists disguised as advice
- 90/10 rule: 90% value, 10% promo max. Most replies should be 100% value, 0% promo.

### Write Queue

1. Write all pending items to `Documents/Engagement/reply-queue.md`:

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

2. Present the full queue inline with summary: "Found N posts, drafted N replies. Here's the queue:"
3. End with: "Commands: `approve N`, `skip N`, `edit N`, `approve all`"

### Approval Loop

**`approve N` (Reddit):**
1. Copy reply text to clipboard: write to `/tmp/scout-reply-reddit.txt`, then `cat /tmp/scout-reply-reddit.txt | bash .claude/scripts/clipboard.sh`
2. Display the post URL so [Your Name] can open it and paste
3. Mark as "clipboard" in reply-queue.md, add to seen-posts: `bash .claude/scripts/scout-seen-posts.sh add <post_id> "Post title"`
4. Say: "Reply copied. Open: [URL]"

**`approve N` (X):**
1. Write reply to `/tmp/scout-reply-x.txt`
2. Extract tweet ID from URL
3. Dry-run: `op run -- python3 Scripts/post-to-x.py --dry-run --file /tmp/scout-reply-x.txt --reply-to <tweet_id>`
4. Show dry-run output. If confirmed, post: `op run -- python3 Scripts/post-to-x.py --file /tmp/scout-reply-x.txt --reply-to <tweet_id>`
5. Mark as "posted" in reply-queue.md, add to seen-posts

**`skip N`:**
1. Mark as "skipped" in reply-queue.md, add to seen-posts
2. Say: "Skipped #N."

**`edit N`:**
1. Display current draft
2. [Your Name] dictates changes
3. Redraft and present for approval

**`approve all`:**
Process each item sequentially:
- Reddit: clipboard one at a time, wait for confirm before next
- X: dry-run each, then post on confirm
- After each: update reply-queue.md and seen-posts

### After all actions

Update `Documents/Engagement/reply-queue.md`:
- Remove acted items from Pending Approval
- Add to Recently Acted table with date, platform, post title, and action (clipboard/posted/skipped)
- Prune Recently Acted entries older than 7 days

## UTM Tagging (Required)

Every link to a [Your Brand] property in drafted replies must include UTM parameters.

Format: `https://<your-app-domain>/?utm_source={platform}&utm_medium={type}&utm_campaign={identifier}`

- `utm_source`: `reddit`, `x`
- `utm_medium`: `comment`, `reply`, `post`
- `utm_campaign`: descriptive slug

Never include a bare link. See the content-marketing skill for full conventions.

## Error Handling

- **Reddit MCP tools fail:** Fall back to `WebSearch` with `site:reddit.com/r/ClaudeCode` queries. Note degraded quality in report.
- **WebSearch rate limited:** Skip X search for that target.
- **No internet / all tools fail:** Report the failure. Don't generate a fake report.
