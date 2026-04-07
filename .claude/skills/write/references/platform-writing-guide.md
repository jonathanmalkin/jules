# Platform Writing Guide

Editorial guidance for writing well on each platform. This complements `platform-templates.md` (which covers file formats and posting mechanics). Load both when adapting articles.

## Blog ([your-domain])

### Structure

- **First paragraph is the summary.** Write it so Google's featured snippet can extract it. Answer the question the title asks.
- **Question-format headers.** "How does X work?" beats "X Architecture". Matches voice search patterns and makes scanning easier.
- **Author byline with PERSON schema.** Signals E-E-A-T (Experience, Expertise, Authoritativeness, Trust) to search engines. The byline should reference real experience, not generic credentials.

### E-E-A-T signals

- Include at least one "I built/tried/broke this" moment per article. First-hand experience is the strongest quality signal.
- Link to the Jules repo or other public proof of the work described.
- Reference specific tools, versions, and configurations. Vague descriptions ("a popular framework") lose credibility.

### Quality markers

- Vary paragraph lengths. A one-sentence paragraph hits differently after a dense technical block.
- Include a genuine opinion or recommendation, not just "here are the options." Readers want a stance.
- Close with a resource, next step, or callback. Never close with sentiment ("I hope this helps").

## Reddit

### Structure

- **TL;DR first** for posts over 800 words. Put the payoff at the top. Reddit readers decide in 3 seconds whether to keep scrolling.
- **Problem, Tried, Worked, Do Differently.** This is the native Reddit technical post structure. Readers expect it. Deviating should be intentional.
- **Specific numbers.** "Reduced deploy time from 12 minutes to 45 seconds" beats "significantly improved deploy time." Numbers build trust.

### Tone

- **Peer conversation, not presentation.** Write like you're explaining to a colleague at a whiteboard, not presenting at a conference.
- **Admit what didn't work.** Reddit penalizes posts that read like marketing. Including failures makes the successes credible.
- **Genuine closing question.** "What's your approach to X?" invites discussion. "Let me know what you think!" is engagement bait.

### Anti-patterns

- Don't open with credentials or backstory. Open with the insight.
- Don't write "As someone who..." or "I've been doing X for Y years." Show expertise through the content, not the introduction.
- Don't cross-promote aggressively. One repo link in the footer is fine. Links in every section are spam.

## X Thread

### Structure

- **Hook tweet (Tweet 1):** Bold claim + promise + thread signal (optional). Must stand alone as a compelling tweet. Under 200 chars. No links.
- **Body tweets (2 to N-2):** One idea per tweet. Vary length. Alternate between insight and example.
- **Turn tweet:** The single most shareable insight in the thread. Should work as a standalone quote-tweet. Put it in the first half (tweets 2-4), not buried at the end.
- **TL;DR (Tweet N-1):** Core insight in 2-3 sentences. For people who skip to the end.
- **CTA (Tweet N):** Links go here and only here. Article link + repo link + engagement ask.

### Writing quality

- Each tweet should have one clear idea. If you need "and" or "also," split into two tweets.
- Real stance in every tweet. "X is better than Y because..." not "X and Y both have pros and cons."
- Cut filler words ruthlessly. Threads are constrained. Every word earns its space.

### Anti-patterns

- Don't number tweets ("1/", "2/"). The platform does this visually.
- Don't start every tweet with "The..." or "This...". Vary openers.
- Don't use thread-specific cliches ("A thread", "Let me explain", "Here's what nobody tells you").

## X Article

### Structure

- **Narrative personal tone.** X Articles read like long-form tweets, not blog posts. More conversational, more opinionated.
- **No code blocks.** X Articles render backtick-code as literal text with backticks visible. Use quoted strings or describe the code in prose.
- **No bold/italic markers.** Asterisks paste as literal text. Emphasis comes from sentence structure, not formatting.
- **Resources section at end.** Collect all links in one place. Readers skim to the end for links.

### Writing quality

- Shorter paragraphs than blog. 2-3 sentences max per paragraph.
- More "I" and "you" than blog format. Direct address.
- Can be more opinionated and casual than the blog version. X rewards personality.

## LinkedIn

### Hook Writing (REACT Framework)

First 140 characters are everything — LinkedIn truncates on mobile with "...see more." Use REACT:

- **R**esults: Lead with a specific outcome ("I automated 12 articles across 4 platforms")
- **E**motion: Personal stake or feeling ("My AI assistant caught a bug I'd been shipping for 3 weeks")
- **A**gitation: The problem that drove the action ("Every VC told me to avoid this market")
- **C**redibility: Why you're the one ("One person. No employees. 200+ daily users.")
- **T**ime: Urgency or timeliness ("Claude Code just shipped X. Here's what changed.")

Combine 2-3 elements. Never open with generic statements ("In today's AI landscape...").

### Structure

- **Short, fragmented style.** LinkedIn's native format is short paragraphs with line breaks. Dense prose gets scrolled past.
- **Personal angle first.** "Last week I broke our deploy pipeline" beats "Deploy pipelines are critical infrastructure."
- **No URL in body.** 60% reach penalty confirmed. Article URL goes in the first comment (manual step).
- **Question close.** End with a genuine question. Saves > Comments > Likes in algorithm weight. Questions drive comments.
- **Bimodal length.** Short (100-300 chars) for conversation starters. Long (1,300-1,900 chars) for authority posts. Nothing in between.

### Format-Specific Guidance

**Text posts:** Fragment aggressively. One idea per line break. White space is your friend on mobile.

**Document carousels (highest engagement — 6.6%):**
- Hook slide → Context → Steps/Points (one per slide) → Takeaway → CTA
- 8-12 slides. One idea per slide. Large, readable text.
- 1080x1350 px (portrait). Upload as PDF.
- Design: clean, dark text on light background. Minimal decoration.

**Image posts:** Screenshots, terminal output, before/after comparisons, architecture diagrams. Real > polished.

### Writing quality

- Technical depth is welcome. Code snippets work when they serve the story.
- Show the system AND the result. "Here's my Claude Code hook" + "it caught 3 bugs this week."
- One clear takeaway per post. Practitioners value density, not breadth.
- Can reference the blog post for depth: "I wrote the full breakdown on my site (link in comments)."

### Engagement Protocol

- **Golden hour:** Respond to every comment in the first 60 minutes after posting. This window heavily influences distribution.
- **Daily routine (15 min):** Comment on 3-5 posts from target accounts (AI builders, technical founders). Reply to all comments on own posts.
- Comment quality > quantity. Substantive replies, not "great post!"

### Anti-patterns

- Don't use hashtags excessively. 3-5 specific ones, at the end.
- Don't open with "I'm excited to announce..." or "Thrilled to share..."
- Don't write in essay format. Fragment. Break lines. Make it scannable.
- Don't write AI-smooth prose. Choppy, specific, personal > polished and generic.
- Don't use vague openings ("In today's fast-paced world..."). Start with a specific result or claim.
- Don't land in the dead zone (300-1,000 characters). Go short or go long.
- Don't post the same format 3x in a row (20% reach penalty).

## Cross-Platform Cascade Strategy

When publishing the same article across all platforms, the adaptations should form a **cascade**, not copies:

1. **Blog** = canonical, full depth, SEO-optimized
2. **Reddit** = peer-oriented retelling with technical depth, emphasis on what was tried/learned
3. **X Thread** = distilled insights, one per tweet, the "highlight reel"
4. **X Article** = narrative personal retelling, more casual than blog
5. **LinkedIn** = practitioner-friendly adaptation, technical depth OK, bimodal length (short teaser or long authority post)

Each platform version should feel native to that platform. A reader who sees all five should get complementary perspectives, not the same text reformatted.
