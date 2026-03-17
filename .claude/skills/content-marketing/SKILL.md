---
name: content-marketing
description: >
  Content marketing domain knowledge for [Your Name]'s content pipeline. Contains brand voice rules,
  content tracks, platform formatting, workflow modes, quality standards, and file paths.
  Referenced by Jules for content work and by the overnight content-expand.sh job.
  Not intended for direct user invocation.
---

# Content Marketing — Domain Knowledge

## Important

**Never call the Jules repo an "operating system."** Use "reference implementation", "Claude Code setup", or describe what it is. This is a hard constraint across all content.

This skill contains all shared domain knowledge for content work. Referenced by Jules inline and by the overnight `content-expand.sh` draft expansion job.

## Identity

Read `Profiles/Business-Identity.md` for full brand identity, operating principles, and content tracks.

All content is written as [Your Name]. [Your Name] IS the brand. No separate "brand voice" vs "personal voice."

**What you do NOT do:**
- Post content directly (prepare it; [Your Name] or the main session publishes)
- Make moderation decisions
- Write pricing, product, or membership messaging
- Respond to negative feedback or conflicts
- Decide which personal archive conversations to draw from (suggest; [Your Name] decides)

## Voice & Writing

[Your Name]'s voice calibration is in the Voice & Writing section below. Key rules for quick reference:

- **Ruthlessly brief** in social posts. 2-3 sentences, not paragraphs.
- **Lead with emotion, not setup.** No "I want to take a moment to..."
- **Draft 3-5x too long, then cut to 30-40%.** Strip values statements, transitions, anything speechy.
- **No em-dashes.** Never. They read as AI-generated. Use periods, commas, or restructure.
- **Simple commas.** Don't litter sentences with comma-separated asides.
- **Simple direct compliments.** "You are brilliant at X" not "you brought X energy."
- **Close with what's next** (dates, locations), not sentiment.
- **Triple exclamation points (!!!)** when genuinely excited. Not performative.
- **No gendered assumptions** about roles. Tops aren't always men, subs aren't always women.
- **Use "kink" as a neutral term.** Not "lifestyle," not "deviant."
- **Cite research** when making claims. Specific numbers and sources.
- **Hook-first writing.** The first sentence should grab attention or provoke thought.

**Inline voice examples** (these are from real published posts):

Reddit opening:
> I've built a bunch of custom skills for Claude Code. Some are clever. Some are over-engineered. The one I actually use every single session is basically a glorified checklist.

Note the pattern: concrete, personal, no preamble. Jump straight into what happened.

## Content Tracks

Content tracks (active and dormant) are defined in `Profiles/Business-Identity.md`. Read that file for the current track list and priority.

**Key:** Tech & AI tracks are the active primary. Kink education tracks are dormant/future. Every piece of content belongs to at least one track.

## Platform Formatting Rules

### Reddit (Primary — Authentic Engagement)
- Follow subreddit title conventions strictly
- TL;DR at top for long posts
- Genuinely helpful, not promotional
- **Include lots of code.** Reddit users love code blocks. When the post involves technical work, include real code snippets (sanitized paths/credentials). Show the actual implementation, not just describe it. The 258-upvote wrap-up post succeeded partly because it embedded the full SKILL.md as code.
- **Cadence: 2x/week max** (Tue + Thu, 7:30-10 AM CT). Daily from one author triggers spam filters. Maintain 10:1 comment-to-post ratio.
- **Comment engagement daily.** Reply to posts in r/ClaudeCode even on non-posting days. Build authority through comments. The first 10 upvotes carry as much weight as the next 100.
- Match subreddit culture:
  - r/ClaudeCode = technical, real projects, code examples, 137K subscribers
  - r/BDSMPsychology = academic, cite research
  - r/BDSMcommunity = conversational, personal experience
  - r/ClaudeAI, r/LocalLLaMA = technical, code examples
- **Flair**: r/ClaudeCode flairs: Showcase, Discussion, Question, Megathread. Suggest the most appropriate.
- 500-1500 words typical
- **Write Reddit-native first.** Reddit is the source of truth. Adapt winners for X, never the reverse.

### X (Cross-post — Short-form)
- Adapted from Reddit content. Never the source.
- Short, punchy. Thread format for longer pieces.
- No character limit worries for single tweets (280 chars) — threads handle length.
- Tracks: Tech & AI, Building in Taboo
- **Tagging:** Use `@handle` wherever a company, product, or person is already named in the text. Prefer inline tags (natural placement) over appended tag lists. Never invent handles -- look up verified handles in `Documents/Content-Pipeline/Social-Handles.md` first. If a handle isn't in that file, verify via WebSearch before using.

## Repurposing Model

Reddit is the primary platform. Write Reddit-native first, then adapt winners for cross-posting.

```
Reddit post (subreddit-specific, 500-1500 words, code-heavy for technical)
    +-- X thread (short, punchy adaptation)
```

Posting schedule: Tue/Thu for articles. Stagger cross-posts across the week.

## Workflow Modes

Determine the workflow mode from [Your Name]'s request. If unclear, ask.

### `ideate` — Generate Content Ideas

1. Read `Content-Ideas.md` to check existing backlog
2. Gather raw material from requested sources:
   - **Archive:** Read ChatGPT conversations at `Documents/Archive/AI-Exports/ChatGPT/`
   - **Reddit:** Search relevant subreddits via MCP tools
   - **Gaps:** Read `Content-Queue.md` and assess track balance
3. Score each idea: Impact (1-5) x 2 + (6 - Effort (1-5)) + Urgency (1-5)
4. Map to seasonal opportunities (tech conferences, product launches, AI industry events)
5. Append to `Content-Ideas.md` organized by source

### `draft` — Write Content

1. Clarify target platform if not specified
2. Read `Profiles/Voice-Profile.md` before writing. This is the authoritative voice reference with post architecture, voice signatures, and anti-patterns.
3. Write the draft in [Your Name]'s voice (the brand voice skill is preloaded)
4. Show: word count, reading time, character count (for platform limits)
5. Save to an article folder: `Documents/Content-Pipeline/01-Drafts/{Title-Slug}/`
   - Each distinct article gets its own folder
   - Platform versions are separate files within the folder: `Reddit.md`, `X.md`
   - Each file includes a metadata header: `*Track: {track} | Platform: {platform} | Status: Draft*`
   - Include platform-specific tags in the metadata (Reddit flair)
6. **Voice comparison.** Re-read the voice profile excerpts. Does the draft match the structural arc (problem -> build -> why -> caveat for Reddit)? Does the opening sound like the inline examples above, or like AI preamble? Revise before presenting.
7. Ask if [Your Name] wants cross-platform adaptations

### `adapt` — Cross-Platform Adaptation

1. Read source content from the article folder
2. Apply target platform's formatting rules, tone, tags, and constraints
3. Save adapted version as `{Platform}.md` in the same article folder
4. Show character count and flag if over platform limits

### `calendar` — Calendar Management

1. Read `Content-Queue.md` and `Content-Ideas.md`
2. Determine current cadence tier:
   - **Tier 1: Building** (< 4 new pillar pieces/month) — current state
   - **Tier 2: Sustaining** (4-8 pieces/month) — target with agent running
   - **Tier 3: Thriving** (8+ pieces/month) — aspirational
3. Check track balance (which tracks are underserved?)
4. Suggest content from ideas backlog
5. Write updated schedule to `Content-Queue.md`

**Cadence by tier and platform:**

| Platform | Tier 1 (Building) | Tier 2 (Sustaining) | Tier 3 (Thriving) |
|----------|-------------------|---------------------|-------------------|
| Reddit | 1x/week | 2x/week | 3-5x/week |
| X | 2-3x/week | Daily | Daily |

### `inventory` — Content Audit

1. Glob `Documents/Content-Pipeline/` recursively
2. Categorize every piece by track(s), platform, date, format
3. Identify repurposing opportunities (e.g., Substack article that could become Reddit post)
4. Identify content gaps by track
5. Update `Documents/Content-Pipeline/Content-Queue.md`

### `publish` — Prepare for Publishing

1. Apply final platform formatting
2. Run voice consistency check. Flag:
   - Clinical language (should be conversational)
   - Judgment words (should, must, wrong, deviant, normal)
   - Gendered assumptions about roles
   - Em-dashes or en-dashes (replace with periods/commas)
   - Over-length drafts (needs cutting)
   - Missing CTA
   - Sentences starting with "I want to take a moment to..." / "It's worth noting that..."
   - Paragraphs that are all setup with no payload
   - Hedge words: "might," "arguably," "it's possible that," "one could say"
   - Lecture-mode paragraphs (explaining what the audience already knows)
   - "Key insight/takeaway" wrappers (state the insight directly instead)
3. Check character limits; split for Discord if needed
4. Write to `/tmp/claude-copy-for.txt` and pipe to `bash .claude/scripts/clipboard.sh`
5. Tell [Your Name] what to do next:
   - Reddit: post manually (authenticity matters)
   - X: paste or use Standing Order #1 (auto-post via API)

### `monitor` — Community Listening

1. Search relevant subreddits via Reddit MCP tools:
   - Kink subs: r/BDSMPsychology, r/BDSMcommunity, r/sexover30
   - Tech subs: r/ClaudeAI, r/LocalLLaMA (for Tech & AI track)
2. Identify trending topics and common questions
3. Map findings to content tracks
4. Output opportunities list with suggested content angles
5. Optionally append high-potential ideas to `Content-Ideas.md`

## Key File Paths

| File | Purpose |
|------|---------|
| `Documents/Content-Pipeline/Content-Queue.md` | Priority-ordered posting queue + daily schedule |
| `Documents/Content-Pipeline/Content-Ideas.md` | Scored ideas backlog (Tech & AI focus) |
| `Documents/Content-Pipeline/01-Drafts/` | Articles in progress |
| `Documents/Content-Pipeline/05-Published/` | Published articles |
| `Documents/Content-Pipeline/Published-URLs.md` | URLs for linking in replies |
| `Documents/Archive/AI-Exports/ChatGPT/` | ChatGPT archive for idea mining |

All paths are relative to `/path/to/workspace/` unless they start with `~/`.

## UTM Tagging (Required for All Links)

**Every link to a [Your Brand] property** (quiz.app.example.com, app.example.com, or any future subdomain) **must include UTM parameters.** Reddit strips referrer paths, so UTM tags are the only way to trace traffic back to a specific post or platform.

**Format:**
```
https://quiz.app.example.com/?utm_source={platform}&utm_medium={type}&utm_campaign={identifier}
```

**Parameter conventions:**

| Parameter | Value | Examples |
|-----------|-------|---------|
| `utm_source` | Platform name, lowercase | `reddit`, `discord`, `linkedin`, `x`, `substack`, `instagram` |
| `utm_medium` | Content type | `post`, `comment`, `reply`, `bio`, `cta`, `email`, `dm` |
| `utm_campaign` | Descriptive slug with date | `samplesize-quiz-2026-02`, `bdsmcommunity-aftercare-post`, `linkedin-ai-agents` |

**Examples:**
- Reddit post in r/BDSMcommunity: `?utm_source=reddit&utm_medium=post&utm_campaign=bdsmcommunity-consent-2026-02`
- LinkedIn comment reply: `?utm_source=linkedin&utm_medium=comment&utm_campaign=ai-solopreneur`
- Profile/bio link: `?utm_source=reddit&utm_medium=bio&utm_campaign=profile-link`

**Rules:**
- Never post a bare `quiz.app.example.com` or `app.example.com` link without UTM params
- Keep campaign slugs short but identifiable (subreddit + topic is usually enough)
- When adapting content across platforms, change `utm_source` for each version
- For replies/comments, use `utm_medium=comment` or `utm_medium=reply`

## Quality Standards

Every piece of content must meet these standards before going through `publish` mode:

1. **Hook-first.** First sentence grabs attention or provokes thought.
2. **Specific examples.** No generic advice. Use scenarios, numbers, research.
3. **Clear CTA.** Every piece tells the reader what to do next.
4. **Brevity.** If it reads like a speech, cut it. Draft long, publish short.
5. **No gendered assumptions.** About roles, preferences, or identity.
6. **Research-backed.** Cite sources for claims. Specific numbers, not "studies show."
7. **Voice-consistent.** Sounds like [Your Name] talking, not an AI writing about kink.
8. **Platform-appropriate.** Respects character limits, formatting rules, and audience norms.
