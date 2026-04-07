# Platform Templates

Templates and adaptation guidelines for each platform variant.

## Website Article ([your-domain])

**File:** `Code/[your-handle]/src/content/articles/{slug}.md`

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
- Footer with Jules repo link: `*Full source: [github.com/[your-github]/jules](https://github.com/[your-github]/jules)*`
- No em-dashes
- First paragraph must stand alone as an AI-extractable summary

**Deploy:** `git add` the article file, commit, push to main. Cloudflare auto-deploys. URL: `[your-domain]/articles/{slug}/`

## Reddit

**File:** `Documents/Content-Pipeline/Drafts/{Article-Folder}/Reddit.md`

**Format:**
```markdown
*Track: {track} | Platform: Reddit | Status: Draft*

# {Title following subreddit conventions}

{Body: 500-1500 words}

---

*Full source: [github.com/[your-github]/jules](https://github.com/[your-github]/jules)*
```

**Target audience:** Technical practitioners, AI builders, developers. Full depth. Code blocks welcome. This is the peer audience.

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

**File:** `Documents/Content-Pipeline/Drafts/{Article-Folder}/X-article.md`

**Format:** Plain text with limited formatting. Full guide: `Documents/Content-Pipeline/X-Article-Format-Guide.md`

**Supported formatting ONLY:**
- `#` heading, `##` subheading
- `-`/`+`/`*` bullets, `1.`/`2)` numbered lists
- `>`/`>>` quotes
- NO code blocks, NO bold/italic, NO blank lines between paragraphs

**Target audience:** Technical practitioners and AI-curious readers. Narrative tone, but don't shy from specifics.

**Adaptation rules:**
- 800-2000 words
- Narrative, personal tone
- Single blank line before `##` headers only
- Use quoted strings instead of backtick code
- Resources section at end with links
- Image prompt for Grok header (5:2 ratio) noted in the file

**Posting:** Manual paste on desktop (X Articles don't have an API)

## X Thread

**File:** `Documents/Content-Pipeline/Drafts/{Article-Folder}/X-thread.md`

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

**Account routing:** Use `@[your-handle]` for authority posts and first-person technical threads. See `@platform-account-routing.md`.

**Posting:** `xurl post "first tweet"`, then `xurl reply TWEET_ID "next tweet"` for each subsequent tweet

## LinkedIn

**File:** `Documents/Content-Pipeline/Drafts/{Article-Folder}/LinkedIn.md`

**Algorithm reference:** `@linkedin-reference.md` — load when writing LinkedIn content for format specs, hook formulas, and engagement benchmarks.

**Two post formats:**

### Short Post (100-300 characters)
```markdown
*Track: {track} | Platform: LinkedIn (Short) | Status: Draft*

{Body: 100-300 characters. Conversation starter, hot take, or question.}

{3-5 hashtags}
```

### Long Post (1,300-1,900 characters)
```markdown
*Track: {track} | Platform: LinkedIn (Long) | Status: Draft*

{Body: 1,300-1,900 characters. Authority post with depth.}

{3-5 hashtags}
```

**Avoid:** 300-1,000 characters (dead zone — too long to skim, too short for depth).

### Document Carousel
```markdown
*Track: {track} | Platform: LinkedIn (Carousel) | Status: Draft*

## Slide 1 (Hook)
{Bold claim or result — stop the scroll}

## Slide 2 (Context)
{Why this matters}

## Slides 3-{N-2} (Content)
{One idea per slide, 8-12 slides total}

## Slide {N-1} (Takeaway)
{Core insight}

## Slide {N} (CTA)
{Question + follow prompt}
```
Carousel specs: 1080x1350 px (portrait), upload as PDF. See `@linkedin-reference.md` for design guidance.

**Target audience:** AI builders, technical founders, solo operators — practitioners who are also decision-makers. Technical depth welcome. Code snippets welcome when they serve the story.

**Content mix:** 60% applied results (Story 3), 30% systems/infrastructure (Story 1), 10% contrarian/thesis (Story 2).

**Adaptation rules:**
- **Hook rule:** First 140 chars must stop the scroll. Specific numbers, contrarian takes, or personal stakes. No corporate openers.
- Short, fragmented style (LinkedIn's native format)
- Personal angle: why this matters, what was learned
- Code snippets welcome when they illustrate a point
- No URL in post body (60% reach penalty confirmed)
- Article URL goes in first comment (manual step, prompted to user)
- End with a question to drive comments (Saves > Comments > Likes in algorithm weight)
- Use feed posts, NOT LinkedIn Articles (Articles get minimal feed distribution and no API support)
- **Format rotation:** Never same format 3x in a row. Rotate between text, carousels, images, video.
- **Hashtags:** 3-5 specific ones (e.g., #ClaudeCode, #AIBuilder over #AI, #Tech). Algorithm scans post copy for context.

**Posting:** `python3 Scripts/linkedin-post.py --file /tmp/linkedin-post.txt`

## Article Folder Structure

Each article gets a folder in the pipeline:

```
Documents/Content-Pipeline/Drafts/{Article-Title}/
  [your-handle].md    # Canonical article (website version)
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

Move the entire folder to `Documents/Content-Pipeline/Published/{Article-Folder}/`
