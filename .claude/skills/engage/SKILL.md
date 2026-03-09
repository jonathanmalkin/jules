---
name: engage
description: Use when user says "engage", "engagement scan", "what should I engage with", "find posts to reply to", "scout Reddit", "scout LinkedIn", or invokes /engage — scans Reddit, LinkedIn, and X for engagement opportunities and drafts response angles
---

# Engage

Scout for high-value engagement opportunities. Score them, rank them, and draft response angles the user can rewrite and post.

> **Platform coverage reality:** Reddit is scanned automatically via API. X is searched best-effort (WebSearch sometimes finds recent public posts). LinkedIn requires manual checking — direct profile links and context are provided below.

## Important: This Is a Scanner, Not an Auto-Poster

The user always rewrites before posting. Your job:
1. Find the right posts/threads
2. Score them honestly (most things aren't worth the time)
3. Draft response *angles* — not polished replies
4. Include direct URLs so they can click and go

## Execution Flow

### Phase 1: Check Previous Reports

```bash
ls -t Documents/Engagement/ 2>/dev/null | head -3
```

If recent reports exist, read the latest one to avoid re-surfacing the same posts. Note which posts were already reported.

### Phase 2: Reddit Scan (Automated)

Scan target subreddits using MCP tools. Fetch **new** and **hot** posts from the last 24 hours.

**Primary:**
- **r/[YourPrimarySubreddit]** — Home turf. Highest priority.

**Secondary:**
- **r/[SecondarySubreddit]** — Broader discussion. Engage when practical usage questions surface.
- **r/[TertiarySubreddit]** — Related community. Lower volume but strategic.

**For each subreddit:**
1. Use `mcp__reddit-mcp-buddy__browse_subreddit` with `sort: "new"` and `limit: 25`
2. Use `mcp__reddit-mcp-buddy__browse_subreddit` with `sort: "hot"` and `limit: 15`
3. For any high-scoring post (likely 6+), fetch details with `mcp__reddit-mcp-buddy__get_post_details` to read comments and assess discussion quality

**What to look for:**
- Questions about Claude Code setup, configuration, workflows, agents, memory
- "How do you..." posts (high discussion potential)
- Frustration posts where your approach solves the problem
- Posts by known community members or Anthropic staff
- Posts with few quality answers (opportunity to be the best reply)

**Skip:**
- Pricing/billing complaints (not your lane)
- Posts with 50+ comments (buried)
- "Is Claude better than GPT?" flame wars
- Posts older than 12 hours with no engagement

### Phase 3a: X Quick Search (Best-Effort)

Run one `WebSearch` per target. X posts are inconsistently indexed by search engines — sometimes you'll find a recent post, sometimes not. That's fine. If a recent post surfaces (< 24h), score it and include in the report. If not, add the target to the LinkedIn & X Recon section.

Configure your target handles and search queries based on your niche and expertise areas.

**If WebSearch returns nothing recent:** Don't retry or try alternative queries. Just add the target to the recon checklist. This is expected.

### Phase 3b: LinkedIn Manual Recon (No Automated Scanning)

LinkedIn requires login to view recent posts — search engines can't index them reliably. Instead of pretending to scan, generate a ready-to-click checklist so the user can check these in 30 seconds per target.

**For each target, include:**
1. **Direct profile URL** (clickable)
2. **Typical posting schedule** (so the user knows when to check)
3. **Entry angle** (1 line — what makes engagement worthwhile)
4. **What to look for** (specific post topics that match your expertise)

### Phase 4: Score Everything

Score each opportunity on four dimensions:

| Dimension | Range | Criteria |
|-----------|-------|----------|
| **Relevance** | 0-3 | 3 = direct expertise match. 2 = adjacent. 1 = tangential. 0 = off-topic. |
| **Freshness** | 0-2 | 2 = posted < 2 hours ago. 1 = 2-8 hours. 0 = > 8 hours. |
| **Discussion Potential** | 0-3 | 3 = open question, few good answers, invites conversation. 2 = statement that invites debate. 1 = interesting but mostly settled. 0 = closed/rhetorical. |
| **Author Signal** | 0-2 | 2 = target account, platform staff, or past interaction. 1 = active community regular. 0 = unknown. |

**Total: 0-10. Report threshold: 6+**

**Key weight:** Discussion Potential is the heaviest (0-3). A mid-tier poster asking an open question beats a mega-account's drive-by take. The user wants conversations, not buried drive-by comments.

### Phase 5: Load Feedback Context

```bash
[ -f Documents/Engagement/feedback.md ] && cat Documents/Engagement/feedback.md
```

If feedback exists, incorporate the last 30 days of preferences into your scoring. Boost/demote categories based on history.

### Phase 6: Generate Report

Present results inline (this is interactive, not a file). Format:

```
## LinkedIn & X Recon

Check these profiles manually — takes ~30 seconds each.

| Target | Profile | Schedule | What to Look For |
|--------|---------|----------|-----------------|
| [Name/Handle] | [clickable URL] | [posting schedule] | [1-line topic filter] |

[Include any X targets where WebSearch found nothing recent]

## High Priority (respond today)

1. **[Platform] [Subreddit/Account]** — "Post title or summary"
   - Posted by [author] ([time ago], [score/engagement])
   - Score: X/10 (Relevance X, Fresh X, Discussion X, Author X)
   - Why: [1 sentence — why this is worth the time]
   - URL: [direct link]
   - Draft angle: [2-3 sentences suggesting approach, not a full reply]

## Medium Priority (engage if time)
[Same format, score 6-7]

## Content Queue Status
[Read Content-Queue.md, show what's ready to post and optimal timing]
```

**If zero posts score 6+:** Say "No high-priority opportunities right now." The LinkedIn & X Recon section always appears regardless of automated results. Don't lower the threshold.

### Phase 7: Draft on Request

If the user says "draft a response for #3" or similar:
- Read the full post + comments (use `get_post_details` for Reddit)
- Draft a response that leads with value, not self-promo. Target 90/10 value-to-promotion: 9 genuinely helpful replies for every 1 that mentions your work
- Flag if linking to a published article would be appropriate (and which one)
- Use `/copy-for` format conventions (display inline AND copy to clipboard)

## Scoring Adjustments from Feedback

When `Documents/Engagement/feedback.md` contains entries like:
- "More: practical how-do-I questions" -> boost Discussion Potential for question posts
- "Less: AI hype posts" -> reduce Relevance for general AI discussion
- "Add target: u/username" -> treat as Author Signal = 1
- "Skip: pricing posts" -> auto-exclude from results

## Expertise Areas (for Relevance scoring)

Customize these to match your expertise:

**Score 3 (direct match):**
- Claude Code setup, configuration, CLAUDE.md, memory, hooks, skills, agents
- AI automation for small business / solopreneurs
- Multi-agent coordination, agent architecture

**Score 2 (strong adjacent):**
- Solopreneur business building
- Content marketing strategy
- Community management

**Score 1 (tangential):**
- General AI news/opinions
- Broad entrepreneurship

**Score 0 (skip):**
- Pricing/billing, pure ML research, "Claude vs GPT" debates

## Content Queue Reference

Read `Documents/Content-Pipeline/Content-Queue.md` at the start of each scan. Include queue status in the report — the user should know what's ready to post alongside what's worth replying to.

## Published URLs Reference

Read `Documents/Content-Pipeline/Published-URLs.md` before drafting replies. When a reply could naturally link to a published article, include the URL.

## UTM Tagging (Required)

**Every link to your app property in drafted replies must include UTM parameters.** Reddit strips referrer paths, so without UTM tags you can't trace traffic to specific posts.

Format: `https://app.example.com/?utm_source={platform}&utm_medium={type}&utm_campaign={identifier}`

- `utm_source`: `reddit`, `linkedin`, `x`
- `utm_medium`: `comment`, `reply`, `post`
- `utm_campaign`: descriptive slug (e.g., `claudecode-skills-reply`)

Never include a bare link. See the content-marketing skill for full conventions.

## State Management

After generating the report, save it to the workspace:

```bash
mkdir -p Documents/Engagement
```

Write the report to `Documents/Engagement/report-$(date +%Y-%m-%dT%H%M).md`.

Set the unread marker:

```bash
echo "Engage: [N] opportunities found (latest: $(date '+%b %d %I:%M %p'))" > Documents/Engagement/unread
```

### Report Format Requirements

The saved report must be **self-contained and actionable** — someone reading just the file should be able to click links and copy-paste replies without returning to the chat. Include:

1. **LinkedIn & X Recon checklist** (profile URLs, schedules, angles, what-to-look-for) — always first
2. **Full post content** (title, author, score, comment count, post body or summary)
3. **Direct clickable URL** for every opportunity
4. **Score breakdown** with reasoning
5. **Draft reply for each high-priority item**, formatted for its target platform
6. **Content Queue status** table
7. **Published URLs** that could be linked in replies

## Error Handling

- **Reddit MCP tools fail:** Fall back to `WebSearch` with `site:reddit.com/r/ClaudeCode` queries. Note degraded quality in report.
- **WebSearch rate limited:** Skip X search for that target, add to LinkedIn & X Recon checklist.
- **No internet / all tools fail:** Report the failure. Don't generate a fake report.
