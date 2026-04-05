# Platform Templates

Templates and adaptation guidelines for each platform variant.

## Website Article ([your-domain])

**File:** `Code/[your-site]/src/content/articles/{slug}.md`

**Frontmatter template:**
```yaml
---
title: "{title}"
date: "{YYYY-MM-DD}"
description: "{50-160 char SEO description}"
story: {1|2|3}
tags: [{tag1}, {tag2}]
draft: false
platforms:
  reddit: ""
  x_article: ""
  x_thread: ""
  linkedin: ""
---
```

**Body guidelines:**
- Markdown with full formatting support
- Code blocks with language identifiers
- Images in `src/assets/articles/{slug}/`
- Footer with [Agent Name] repo link: `*Full source: [github.com/jonathanmalkin/jules](https://github.com/jonathanmalkin/jules)*`
- No em-dashes
- First paragraph must stand alone as an AI-extractable summary

**Deploy:** `git add` the article file, commit, push to main. Cloudflare auto-deploys. URL: `[your-domain]/articles/{slug}/`

## Reddit

**File:** `Documents/Content-Pipeline/02-Pending-Review/{Article-Folder}/Reddit.md`

**Format:**
```markdown
*Track: {track} | Platform: Reddit | Status: Draft*

# {Title following subreddit conventions}

{Body: 500-1500 words}

---

*Full source: [github.com/jonathanmalkin/jules](https://github.com/jonathanmalkin/jules)*
```

**Target audience:** Technical practitioners, AI builders, developers. Full depth. Code blocks welcome. This is the peer audience. (LinkedIn targets business decision-makers instead.)

**Adaptation rules:**
- Hook-first opening (the most interesting insight leads)
- Full technical depth, don't dumb it down
- Code blocks welcome, use them
- TL;DR at top for posts over 800 words
- Personal framing: "I built/tried/found" not "One could/should"
- Strong close: resource link, next step, or discussion prompt
- No engagement bait ("What do you think?" is fine, "Drop a comment!" is not)
- Follow subreddit conventions from `Documents/Content-Pipeline/Subreddit-Reference.md`

**Posting:** `Scripts/post-to-reddit-api.py` if activated, otherwise clipboard relay

## X Article

**File:** `Documents/Content-Pipeline/02-Pending-Review/{Article-Folder}/X-article.md`

**Format:** Plain text with limited formatting. Full guide: `Documents/Content-Pipeline/X-Article-Format-Guide.md`

**Supported formatting ONLY:**
- `#` heading, `##` subheading
- `-`/`+`/`*` bullets, `1.`/`2)` numbered lists
- `>`/`>>` quotes
- NO code blocks, NO bold/italic, NO blank lines between paragraphs

**Target audience:** Technical practitioners and AI-curious readers. Narrative tone, but don't shy from specifics. (LinkedIn targets business decision-makers instead.)

**Adaptation rules:**
- 800-2000 words
- Narrative, personal tone
- Single blank line before `##` headers only
- Use quoted strings instead of backtick code
- Resources section at end with links
- Image prompt for Grok header (5:2 ratio) noted in the file

**Posting:** Manual paste on desktop (X Articles don't have an API)

## X Thread

**File:** `Documents/Content-Pipeline/02-Pending-Review/{Article-Folder}/X-thread.md`

**Format:**
```markdown
*Track: {track} | Platform: X Thread | Status: Draft*

## Tweet 1 (Hook)
{text, <=200 chars}

## Tweet 2
{text, <=280 chars}

...

## Tweet {N-1} (TL;DR)
{text, <=280 chars}

## Tweet {N} (CTA)
{text with links, <=280 chars}
```

**Structure rules:**
| Tweet | Role | Rules |
|-------|------|-------|
| 1 | Hook | Credibility + Topic + Deliverable. No links. <=200 chars. |
| 2 to N-2 | Body | One idea per tweet. Vary length. One emoji max per tweet. |
| N-1 | TL;DR | Core insight in 2-3 sentences. |
| N | CTA | Article link + GitHub link + engagement ask. ALL links here. |

**Character counting:**
- Max 280 chars per tweet
- URLs are compressed to 23 chars by t.co (regardless of actual length)
- When counting: replace each URL with 23 chars
- 5 tweets max (keep it tight)

**Tagging:** Check `Documents/Content-Pipeline/Social-Handles.md` for verified handles. Tag relevant people in body tweets, not the hook.

**Posting:** `xurl post "first tweet"`, then `xurl reply TWEET_ID "next tweet"` for each subsequent tweet

## LinkedIn

**File:** `Documents/Content-Pipeline/02-Pending-Review/{Article-Folder}/LinkedIn.md`

**Format:**
```markdown
*Track: {track} | Platform: LinkedIn | Status: Draft*

{Body: 150-300 words, no URL in body}
```

**Target audience:** Business owners, managers, executives. NOT developers. Frame AI as operational leverage, not technical achievement. Strip jargon. Lead with business outcomes, not implementation details. This is the key audience split: LinkedIn = decision-makers, X/Reddit = technical practitioners.

**Adaptation rules:**
- Short, fragmented style (LinkedIn's native format)
- Personal angle: why this matters, what was learned
- Hook-first opening
- No code blocks
- No URL in post body (LinkedIn penalizes links in body text)
- End with a question targeting decision-makers (operational pain points, delegation, ROI), not builders
- Article URL goes in first comment (manual step, prompted to user)
- Use feed posts, NOT LinkedIn Articles (Articles get minimal feed distribution and no API support)

**Posting:** `python3 Scripts/post-to-linkedin.py --file /tmp/linkedin-post.txt`

## Article Folder Structure

Each article gets a folder in the pipeline:

```
Documents/Content-Pipeline/02-Pending-Review/{Article-Title}/
  [your-site].md    # Canonical article (website version)
  Reddit.md          # Reddit adaptation
  X-article.md       # X Article adaptation
  X-thread.md        # X Thread adaptation
  LinkedIn.md        # LinkedIn adaptation
  published.md       # Created at publish time with all URLs and dates
```

## Post-Publish Tracking

After all platforms are posted, create/update `published.md`:

```markdown
# {Title}

Published: {YYYY-MM-DD}
Story: {track}

## Platform URLs

| Platform | URL | Published |
|----------|-----|-----------|
| [your-domain] | {url} | {date} |
| Reddit | {url} | {date} |
| X Article | {url} | {date} |
| X Thread | {url} | {date} |
| LinkedIn | {url} | {date} |
```

Move the entire folder to `Documents/Content-Pipeline/04-Published/Story-{N}/{Article-Folder}/`
