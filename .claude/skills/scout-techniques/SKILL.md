---
name: scout-techniques
description: >
  Scout for Claude Code technical insights worth adopting. Searches r/ClaudeCode,
  GitHub Discussions (anthropics/claude-code), Hacker News, and dev blogs for posts about
  CLAUDE.md structure, hooks, skills, agents, memory, workflows, and automation patterns.
  Deep-analyzes top posts (all comments + linked resources) and compares to your .claude/
  setup. Also evaluates the built-in /insights report (session friction, CLAUDE.md suggestions)
  against current config. Use when user says "scout techniques", "what are people doing with
  claude code", "reddit techniques", "cc intel", "insights report", or invokes /scout-techniques.
  Also runs daily during morning briefing. Do NOT use for engagement opportunities
  (use /engage for that).
user_invocable: true
---

# Scout Techniques

Scout multiple sources for Claude Code technical insights, compare against your setup, and surface gaps worth closing.

## Important: This Is Intelligence, Not Engagement

Different from `/engage`. Engage optimizes for **reply-worthiness** (what should you respond to). This optimizes for **adoptability** (what should you steal). Different scoring, different output, different value.

## Execution Flow

### Phase 1: Check for Recent Reports

```bash
INTEL_DIR="$HOME/your-workspace/Documents/Field-Notes/CC-Intelligence"
TODAY=$(date +%Y-%m-%d)
ls "$INTEL_DIR/report-$TODAY.md" 2>/dev/null && echo "TODAY_EXISTS" || echo "NO_REPORT"
```

- If today's report exists AND the user didn't explicitly request a fresh scan -> present the existing report's Key Findings section and stop
- If no report or user requested fresh scan -> continue to Phase 2

Load the seen-posts tracker:
```bash
bash ~/your-workspace/.claude/scripts/scout-seen-posts.sh list
```

### Phase 2: Discovery

Four sources, each with its own retrieval method. Run all sources, then deduplicate and merge before scoring.

#### Source A: r/ClaudeCode (Reddit MCP)

**1. Keyword searches** — `search_reddit` with `subreddit: "ClaudeCode"`, `sort: "relevance"`, `time_filter: "day"`, `limit: 10` for each:
- `"CLAUDE.md" OR "claude.md"`
- `"hooks" OR "skills" OR "agents"`
- `"memory" OR "workflow" OR "automation"`
- `"setup" OR "config" OR "architecture"`

**2. Top posts** — `browse_subreddit` with `subreddit: "ClaudeCode"`, `sort: "top"`, `time_filter: "day"`, `limit: 25`

**3. Hot posts** — `browse_subreddit` with `subreddit: "ClaudeCode"`, `sort: "hot"`, `limit: 20`

#### Source B: GitHub Discussions (gh CLI)

Query the `anthropics/claude-code` repo discussions for recent activity:

```bash
# Recent discussions (last 24h) — returns JSON with title, url, body, comments
gh api graphql -f query='
{
  repository(owner: "anthropics", name: "claude-code") {
    discussions(first: 25, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        title
        url
        bodyText
        createdAt
        upvoteCount
        comments(first: 10) { totalCount }
        labels(first: 5) { nodes { name } }
      }
    }
  }
}'
```

Also check recently updated discussions (follow-up comments on older threads):
```bash
gh api graphql -f query='
{
  repository(owner: "anthropics", name: "claude-code") {
    discussions(first: 15, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        title
        url
        bodyText
        updatedAt
        upvoteCount
        comments(first: 10) { totalCount }
        labels(first: 5) { nodes { name } }
      }
    }
  }
}'
```

**What to look for:** Feature requests with workarounds, "how I use X" threads, config sharing, technique discussions. Skip bug reports and basic support questions.

#### Source C: Hacker News (Algolia API)

Search HN's public API for recent Claude Code posts. Use WebFetch on the Algolia search endpoint:

```
https://hn.algolia.com/api/v1/search_by_date?query=%22claude+code%22&tags=story&numericFilters=created_at_i>{YESTERDAY_UNIX}
```

Calculate yesterday's unix timestamp:
```bash
YESTERDAY_UNIX=$(date -v-1d +%s)
echo $YESTERDAY_UNIX
```

Then fetch via WebFetch with prompt: "Extract all story results. For each: title, url, points, num_comments, objectID, author. Return as a structured list."

For any HN post with 10+ points or 5+ comments, fetch the comments page too:
```
https://hn.algolia.com/api/v1/items/{objectID}
```
Prompt: "Extract all comments. Focus on technical details about Claude Code setup, configuration, workflows, or automation. Skip meta-commentary and off-topic threads."

**HN signal tends to be high-quality but infrequent.** Many days will return 0 results — that's fine.

#### Source D: Dev Blogs (WebSearch)

Search for recent blog posts about Claude Code setup and workflows:

```
WebSearch: "claude code" (setup OR workflow OR CLAUDE.md OR hooks OR skills) site:dev.to after last week
WebSearch: "claude code" (setup OR workflow OR CLAUDE.md OR hooks OR skills) site:medium.com after last week
WebSearch: "claude code" setup blog -reddit -github after last week
```

For any promising result, fetch the full post via WebFetch to extract techniques.

**Blog posts are lower volume but often the most detailed source** — authors invest time in writing up their full setup.

#### Deduplication

Merge results from all four sources. Deduplicate by:
- Exact URL match
- Post ID match (for Reddit, HN)
- Title similarity (same technique discussed on Reddit and HN)

Skip any item already in `seen-posts.json`.

### Phase 3: Score & Filter

Score each post on 4 dimensions:

| Dimension | Range | Criteria |
|-----------|-------|----------|
| **Technical Depth** | 0-3 | 3 = shares config, code, or architecture. 2 = describes workflow with specifics. 1 = mentions a technique briefly. 0 = opinion/question only. |
| **Relevance to Our Stack** | 0-3 | 3 = directly about features we use (skills, hooks, agents, memory, rules). 2 = adjacent (MCP servers, permissions, model config). 1 = general Claude Code usage. 0 = unrelated. |
| **Community Signal** | 0-2 | 2 = 50+ upvotes OR 20+ comments. 1 = 10-49 upvotes OR 5-19 comments. 0 = below thresholds. |
| **Novelty** | 0-2 | 2 = technique we haven't seen/implemented. 1 = variation on something we do. 0 = we already do this. |

**Threshold: 6+/10.** Posts below this get listed as "Scanned, not actionable" (one-liners).

**Skip entirely:**
- Posts asking basic setup questions (no technique shared)
- "Is Claude Code worth it?" / comparison posts
- Pricing/billing posts
- Posts already in `seen-posts.json`

### Phase 4: Deep Dive (score 7+ only)

For each qualifying post:
1. Fetch full post + all comments via `get_post_details` with max comment depth
2. Extract every technique, config snippet, and pattern from comments (replies often have the gold)
3. For linked resources:
   - **Non-Reddit URLs** (GitHub, blogs, gists): Fetch via `WebFetch`
   - **Reddit URLs**: Use `get_post_details` only — Reddit blocks WebFetch/scraping
   - Extract relevant sections (don't dump entire repos)
4. Note the specific files/configs/commands mentioned

### Phase 5: Compare to Our Setup

Generate a fresh environment map first — things change daily:

```bash
cd ~/your-workspace && make claude-map
```

Then read the environment map for the full inventory of skills, hooks, rules, scripts, agents, and CLAUDE.md structure.

For each technique found, classify:

| Status | Meaning | Action |
|--------|---------|--------|
| **Already Implemented** | We do this or something equivalent | Note which file implements it. Validation. |
| **Gap — Worth Adopting** | We don't do this, and we should | Concrete recommendation: what to add, which file to modify, estimated effort. |
| **Gap — Not Relevant** | We don't do this, and that's fine | Brief note on why it doesn't fit. |
| **Partial — Could Improve** | We do a simpler version | What we have vs. what they do, whether upgrading is worth it. |

### Phase 6: Generate Report

```bash
INTEL_DIR="$HOME/your-workspace/Documents/Field-Notes/CC-Intelligence"
mkdir -p "$INTEL_DIR"
```

Save to `$INTEL_DIR/report-YYYY-MM-DD.md`:

```markdown
# CC Intelligence Report — YYYY-MM-DD

## Key Findings

### Worth Adopting
[Ranked by impact. Each includes: source post, technique summary,
how to implement, which existing files it touches, effort estimate]

### Could Improve
[Things we partially do but could do better]

### Already Covered
[Validation — techniques we already implement. Brief.]

### Interesting but Not Actionable
[Worth watching, not worth implementing now]

## Items Analyzed

### [Title] (score X/10)
- **Source:** Reddit / GitHub Discussions / Hacker News / Blog
- **URL:** [direct link]
- **Author:** username | **Score/Upvotes:** N | **Comments:** N
- **Summary:** [2-3 sentences]
- **Techniques found:** [bullet list]
- **Key comments:** [notable replies with insights]
- **Linked resources:** [what was fetched and what was found]
- **Our status:** [Already Implemented / Gap / Partial]

## Items Scanned (below threshold)
- [Title] (source) — [1-line reason it didn't qualify]

## Methodology
- Date scanned: YYYY-MM-DD
- Sources: r/ClaudeCode, GitHub Discussions (anthropics/claude-code), Hacker News, dev blogs
- Items evaluated: N
- Items deep-analyzed: N
- Time range: past 24 hours (Reddit, HN, GitHub), past week (blogs)
```

Update seen-posts tracker — add each analyzed post:
```bash
bash ~/your-workspace/.claude/scripts/scout-seen-posts.sh add <post_id> "<title>"
```

### Phase 7: Evaluate /insights Report (if available)

The built-in `/insights` command generates `~/.claude/usage-data/report.html` with CLAUDE.md suggestions, skill/hook recommendations, and friction analysis based on the last 30 days of sessions.

**Critical: /insights is a data source, not a to-do list.** It runs on Haiku with zero knowledge of your .claude/ setup (standing orders, hooks, skills, rules, scripts). Most suggestions re-invent things you already have. Evaluate every recommendation against the actual environment before acting on anything. Expect ~60% redundancy.

**Check for a recent report:**
```bash
ls -la ~/.claude/usage-data/report.html 2>/dev/null
```

If the report exists and was modified in the last 7 days:

1. Read `~/.claude/usage-data/report.html` and extract all recommendations
2. Generate a fresh environment map: `cd ~/your-workspace && make claude-map`
3. For each recommendation, classify against the current setup:

| Status | Meaning | Action |
|--------|---------|--------|
| **Already Implemented** | We do this or something equivalent | Note which file covers it. Skip. |
| **Gap — Worth Adopting** | We don't do this, and we should | Concrete fix: which file, what change, effort estimate. |
| **Gap — Not Relevant** | We don't do this, and that's fine | Brief note on why. |
| **Partial — Could Improve** | We do a simpler version | What we have vs. what's suggested, whether upgrading is worth it. |
| **Over-Engineered** | Suggestion is too complex for current scale | Note why. |

4. Check for factual errors in the report
5. Merge findings into the scout report's Key Findings sections

### Phase 8: Act on Findings

After saving the report, route each finding by size:

#### Quick Wins — Just Do It

Criteria (ALL must be true):
- Single file change (add a rule, tweak a hook, update CLAUDE.md)
- < 30 minutes estimated effort
- No user-visible behavior change outside the Claude Code environment
- Version-controlled (easily reversible)

**Action:** Implement immediately. No need to ask. Report what was changed at the end:

> **Applied [N] quick wins from today's scout:**
> - Added X to `.claude/rules/foo.md` (source: [post title])
> - Updated hook in `.claude/hooks/bar.sh` (source: [post title])
>
> Roll back any of these with `git revert` if they don't feel right.

#### Substantial Changes — Decision Queue

Criteria (ANY triggers this):
- Multi-file change or new skill/agent
- Architectural decision
- Adds a dependency or external integration
- Estimated effort > 30 minutes

**Action:** Create a Decision Card in Terrain.md `## Decision Queue`:

```
- **[DECISION]** Scout finding: [technique summary] | **Rec:** [what to do] | **Source:** [post URL] | **Effort:** [estimate] | **Reversible?** Yes/No -> Approve / Reject / Discuss *(added YYYY-MM-DD)*
```

#### Already Implemented / Not Relevant

No action. Note in the report for validation.

#### Present Inline

After acting, present a summary:
- Quick wins applied (what changed, which files)
- Decision Cards queued (what's pending review)
- Total items scanned vs. analyzed for context
