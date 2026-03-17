---
name: long-form-publish
description: >
  Write-once, distribute-everywhere workflow for long-form content. Adapts a single article
  draft into four formats: Reddit post, X Article (generated, not auto-posted), tweet thread,
  and LinkedIn post. Automated posting: X thread (via API). Reddit is manual clipboard relay
  (API pending ~Mar 22). LinkedIn not yet configured. X Article is generated as a file but
  requires manual desktop posting. Use when user says "publish long form",
  "write once distribute twice", "cross-post this article", "format for reddit and x",
  "long form publish", or invokes /long-form-publish.
  Do NOT use for short posts or single-platform posting (use /post-article instead).
user_invocable: true
---

# Long-Form Publish

Write once, distribute everywhere. Takes one article and produces: Reddit post (manual clipboard relay, API pending), X tweet thread (auto via API), LinkedIn post (not yet configured), X Article file (generated, post manually).

## Important: Platform Constraints

| Format | Code blocks | Length | Creation |
|--------|-------------|--------|----------|
| Reddit | Yes | Full | **Manual clipboard relay** (API pending ~Mar 22) |
| X tweet thread | No | 280 chars/tweet | **Script (automated)** |
| LinkedIn | No | ~150-300 words | **Not yet configured** |
| X Article | **No** | ~25K chars max | File generated; **manual desktop posting** |

X Article is generated as `X-Article.md` but NOT posted automatically (no API exists). Thread posts independently — no article URL required.

## Inputs

User provides one of:
- A draft file path
- Article slug (finds it in Content-Pipeline)
- "Last article" (most recent item in 03-Pending-Human-Review/)
- Raw content pasted inline

## Phase 1: Load the Draft

1. Locate the source draft:
   - If file path given: read directly
   - If slug given: look in `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/`
   - If "last article": `ls -t Documents/Content-Pipeline/03-Pending-Human-Review/ | head -1`
2. Read the source file
3. Confirm article title + source with user before adapting

## Phase 1.5: Subreddit Selection

Before writing, determine which subreddits to post to. Load `Documents/Content-Pipeline/Subreddit-Reference.md` and apply the decision matrix.

1. Identify the primary brand story:
   - Story 1 ("The Setup Is the Product") — Claude Code infrastructure, skills, agents, hooks, workflows
   - Story 2 ("Build Where They Won't") — building in niche/underserved communities
   - Story 3 ("Solo Founder + AI") — one person with AI doing what used to require a team
2. Articles can span multiple stories — rank which is primary
3. Apply the Decision Matrix from Subreddit-Reference.md to select:
   - **Primary subs** (post articles): typically 2, max 3
   - **Secondary subs** (comment-only, after posting): 1-2
4. Present selection to user with brief rationale before proceeding

**Example output:**
> This article is primarily Story 1 (mastery framework) with Story 3 overtones.
> Primary: r/ClaudeCode (technical depth), r/PromptEngineering (mastery angle)
> Secondary (comment-only): r/IndieHackers
> Skip r/ClaudeAI for this one — not Claude-specific enough to warrant two primary posts.
> Proceed?

## Phase 2: Reddit Version

**Goal:** Full technical depth. [Your Name]'s voice. Discoverable on search.

Adaptation rules:
- Keep all code blocks (Reddit renders them)
- Keep technical specificity, numbers, file paths, commands
- Hook-first opening (no throat-clearing, no preamble)
- Personal framing in intro (why this matters to [Your Name] specifically)
- Strong CTA at close (engagement ask OR quiz link if relevant)
- Voice check before output:
  - No em-dashes → use period or comma
  - No AI preamble ("Great question!", "As an AI...")
  - Hook-first (first line must earn the click)
  - Flair appropriate for r/ClaudeCode (default: "Showcase" or "Discussion")

Output: Write to `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/Reddit-ClaudeCode.md`
Note: This file is the base Reddit version. Subreddit selection (from Phase 1.5) determines WHERE it's posted, not the content itself.

## Phase 3: X Article Version

**Goal:** Authority signal for existing followers. Generated as a file; post manually when you want to.

Adaptation rules:
- **Remove all code blocks.** Replace with prose descriptions or simplified examples.
  - e.g., `git add .` → "staging individual files instead of blanket adds"
  - e.g., A 20-line bash script → "a 20-line safety guard that intercepts destructive commands before they run"
- Keep narrative structure, personal voice, key insights
- Lead with why this matters (more personal, less technical than Reddit version)
- Headings OK (H1, H2). Bold/bullets OK.
- Target length: 800-2000 words (longer than a thread, shorter than a whitepaper)
- No external links mid-article (put them in a Resources section at the end)
- End with: "Found this useful? The full setup is at [GitHub link]." + brief author bio line

Output: Write to `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/X-Article.md`

**Non-blocking:** File saved, thread proceeds immediately. If you want to post the X Article:
1. Go to x.com on desktop → article compose icon
2. Paste from `X-Article.md`
3. Publish, then optionally reply to the thread with the article link

## Phase 4: Tweet Thread

**Goal:** Distribution and reach for existing audience. Pulls readers into the Article.

**Structure:** 7-10 tweets, numbered.

| Tweet | Role | Rules |
|-------|------|-------|
| 1 | Hook | Credibility + Moment + Topic + Deliverable. No external links. ≤200 chars ideal. |
| 2-N-2 | Body | One idea per tweet. Bullets > prose. Vary length. One emoji per tweet max. |
| N-1 | TL;DR | Compress the core insight to 2-3 sentences. |
| N | CTA | Article link + GitHub link + engagement ask. Put ALL links here. |

**Hard rules:**
- 280 chars max per tweet (run count check)
- No links in tweets 1 through N-1
- Count tweets and announce total in tweet 1 (e.g., "Here's how it maps, level by level 🧵")
- End final tweet with a question (drives replies)

**Char count check:** After drafting all tweets, run:
```python
tweets = [...]
for i, t in enumerate(tweets, 1):
    count = len(t)
    status = "OK" if count <= 280 else f"OVER by {count-280}"
    print(f"Tweet {i}: {count} chars — {status}")
```

Output: Write to `/tmp/{slug}-thread.txt` (one tweet per line, blank line separator)

Dry-run posting:
```bash
python3 Scripts/post-to-x.py --thread /tmp/{slug}-thread.txt --dry-run
```

Present dry-run output to user for review.

## Phase 5: Post Reddit (Manual Clipboard Relay)

Reddit API access request submitted 2026-03-15, pending approval. Until approved, use manual workflow.
When API access is granted, switch to automated posting via `Scripts/post-to-reddit-api.py`.

1. Read `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/Reddit-ClaudeCode.md`
2. Run publish voice check (no em-dashes, no AI preamble, hook-first, CTA present)
3. Format for Reddit using `/copy-for reddit`
4. Tell the user: "Reddit post copied to clipboard. Paste into r/ClaudeCode, then r/ClaudeAI."
5. **Post to both r/ClaudeCode (138K) and r/ClaudeAI (566K)** -- same content, standalone posts (not crossposts)
6. After user confirms posting, ask for the Reddit URLs

## Phase 5.5: Post LinkedIn (Not Yet Configured)

LinkedIn API not yet set up. Skip this step until configured.

1. Generate LinkedIn-adapted version: narrative, no code blocks, ~150-300 words, personal angle
2. Write to `/tmp/{slug}-linkedin.txt`
3. Tell the user: "LinkedIn draft saved. Post manually when LinkedIn API is configured."

## Phase 6: Post X Thread

Thread posts immediately — no X Article URL required.

1. Re-run char count check on final draft
2. Dry-run:
   ```bash
   python3 Scripts/post-to-x.py --thread /tmp/{slug}-thread.txt --dry-run
   ```
3. User approves
4. Post for real:
   ```bash
   python3 Scripts/post-to-x.py --thread /tmp/{slug}-thread.txt
   ```
5. Capture thread URL from output

If the X Article gets posted later, add a reply to the thread with the article link.

## Phase 7: Update Tracking

1. Update `Documents/Content-Pipeline/Content-Queue.md`:
   - Move to Posted table with: date, Reddit URLs (both subs), X Article URL, X thread URL
2. Update `Documents/Content-Pipeline/Published-URLs.md` with all URLs
3. Move folder: `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/` → `05-Published/`

## Phase 8: Engagement Reminders

After all posts are live:

> **Reddit (4-hour window):** Reply to every comment — especially in r/ClaudeAI. Early engagement = algorithmic boost. Set a timer.
>
> **X:** Be the first to reply to your own thread with a follow-up take or additional resource. Reply to everyone who engages in the first hour.
>
> **X Article:** Share the article link in relevant Discord servers or communities. Articles build search authority slowly — distribution is manual at first.

## Error Handling

- **Tweet over 280 chars:** Never post overlong tweets. Fix and re-run char check before proceeding
- **Reddit post fails:** Continue with X posting, note Reddit failure
- **X posting fails:** Provide clipboard fallback (copy tweet text for manual posting)
- **Article not in pipeline:** Accept inline content and create slug from title

## X Articles: Key Facts (Research 2026-03-13)

- **Creation:** X Premium required ($8/month). Reading is free.
- **Format:** Headings, bold, bullets, images. No code blocks. Desktop-only creation.
- **SEO:** Partial — articles sometimes index on Google but indexing is inconsistent. Not reliable for organic discovery.
- **Best use:** Authority signal for existing followers. The "Article + Thread" combo outperforms standalone threads when the algorithm is in an article-boost cycle.
- **Discovery model:** Thread drives people to the Article. Article doesn't find new people on its own.
- **Length sweet spot:** 800-2000 words. Long enough to be "real content," short enough to read on mobile.
- **Link behavior:** Same as tweets — avoid links mid-article body. Put in Resources section at the end.
