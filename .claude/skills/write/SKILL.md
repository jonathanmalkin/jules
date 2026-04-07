---
name: write
description: "Multi-stage article pipeline from seed to published, with optional technical depth track. Takes a topic through structured decisions, website draft, LinkedIn+X distribution, and optionally deeper technical expansion to Reddit. Two flow shapes: business-only or business+technical."
user-invocable: true
---

@Profiles/Voice-Samples-Raw.md

# Write

Single-invocation pipeline that takes a topic and produces published content across platforms, with the website as the primary canvas.

**Arrives from:** Direct invocation or chained from `/think` when content creation is identified.

**Supporting references:**
- `@references/content-packet-schema.md`
- `@references/voice-scorecard.md`
- `@references/faq-reply-loop.md`
- `@references/platform-account-routing.md`

## Anti-Fabrication Guard

Before any platform-specific drafting: verify every factual claim in the draft is either (a) from [Your Name]'s stated source material, (b) from the article spec / creative brief, or (c) flagged with `[VERIFY: ...]`. Do not invent statistics, quotes, personal anecdotes, or specific claims. Use `[PLACEHOLDER: personal story about X]` for narrative elements [Your Name] should fill in.

## Two Flow Shapes

| Shape | Stages | When |
|-------|--------|------|
| **Business only** | 1 → 2 → 3 → 4 → 8 | High-level concepts, outcomes, impacts. Most posts. |
| **Business + Technical** | 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 | When the topic warrants deep technical detail (code, implementation). |

## Stage Overview

| Stage | What | Who | Notes |
|-------|------|-----|-------|
| 1. Seed + Source Material | Capture topic, stories, context | Jules + [Your Name] | ~5 min |
| 2. Decision Sprint + Creative Brief | Structured decisions, reviewable brief | [Your Name] (Jules facilitates) | 5-30 min |
| 3. Write + Edit + Publish Website (Business) | Draft, review panel, iterate, publish | Jules + [Your Name] | Variable |
| 4. LinkedIn + X (Business) | Adapt, iterate, publish. Decision point. | Jules + [Your Name] | Variable |
| 5. Write + Edit + Publish Website (Technical) | Expand with technical depth, publish | Jules + [Your Name] | OPTIONAL |
| 6. Reddit | Adapt technical article for Reddit, publish | Jules + [Your Name] | OPTIONAL |
| 7. LinkedIn + X (Technical) | Technical adaptations with Reddit link | Jules + [Your Name] | OPTIONAL |
| 8. Track | Update published records, URLs, and content state | Jules (auto) | ~1 min |

---

## Stage 1: Seed + Source Material

**Goal:** Understand what we're writing about and collect raw material.

### Step 1: Capture the topic

Check for existing drafts first:

```bash
ls Documents/Content-Pipeline/Drafts/*/[your-handle].md 2>/dev/null
```

If drafts exist, present them: "Which article? Or starting fresh?"

If starting fresh, ask:

> "What would you like to write about?"

From [Your Name]'s answer, Jules infers:
1. **Primary audience:** Who is this for?
2. **Secondary audience:** Who else might read it?
3. **Story track:** 1 (Claude Code) / 2 (Build Where They Won't) / 3 (Solo Founder)

Confirm the inferred details: "Sounds like this is a Story [N] piece aimed at [audience]. That right?"

### Step 2: Source material

Always ask:

> "Any personal stories, experiences, or anecdotes you want in this one? Things only you could tell. I'll use placeholders for anything you don't have ready, and you can fill them in after seeing the draft."

Default message (always):

> "I'll use `[STORY NEEDED: ...]` placeholders for personal stories. You can fill them in after seeing the draft."

Store all provided source material for the decision sprint.

### Step 3: Pull the daily content packet if useful

If the topic came from recent work, or [Your Name] did not supply much source material, generate a daily content packet:

```bash
python3 .claude/scripts/generate-content-packet.py --stdout
```

Use it as supporting input, not as a substitute for real source material. The content packet should help identify:

- the strongest anchor article candidate
- recent proof points
- likely LinkedIn and X angles
- good prompting questions for [Your Name]

### Step 4: Check the answer bank when the topic is a recurring question

If the topic looks like a repeated public question, skim `Documents/Engagement/Answer-Bank/` first. Reuse any verified framing, proof pack, or canonical link direction that already exists.

---

## Stage 2: Decision Sprint + Creative Brief

**Goal:** Make all the key decisions about the article upfront, before writing.

Read `references/decision-sprint-questions.md` for the full question bank.

### Complexity assessment

Based on the topic, classify:
- **Simple** (clear topic, obvious structure): 1 round, ~5-8 decisions, ~5 min
- **Medium** (some structural choices): 2 rounds, ~8-14 decisions, ~10 min
- **Complex** (multiple angles, audience tension): 3-4 rounds, ~14-30 decisions, ~15-30 min

Announce the classification: "This feels [simple/medium/complex]. I'll run [N] rounds of questions."

### Running the sprint

Use `AskUserQuestion` for each decision. For opening hooks and structural choices, use **previews** so [Your Name] can see the options side by side.

**Round 1 (always):** Structure + Content questions. Opening hook, section architecture, what to expand/cut, depth level, key examples.

**Adversarial challenge (always, after Round 1):** "A skeptical reader sees this headline. What would they say is obvious or not worth reading?" Present the objection and a proposed counter. If the counter is weak, sharpen the angle before proceeding. See `references/decision-sprint-questions.md` for the full prompt.

**Round 2 (medium+):** Voice + Format questions. Register, visual elements, audience context, length target, code blocks.

**Round 3 (complex+):** Specifics. Principles/takeaways, closing format, people to tag, CTA.

**Round 4 (only if needed):** Gap check. Reconcile all decisions, identify conflicts, resolve ambiguity.

### Save the decision spec

After all rounds complete, write the spec to `~/.claude/plans/article-{slug}.md`:

```markdown
# Article Spec: {Title}

Created: {YYYY-MM-DD}
Story: {track}
Topic: {topic}
Audience: {primary} / {secondary}
Complexity: {simple/medium/complex}
Length target: {short/medium/long}

## Decisions

### Structure
- Opening hook: {chosen hook with full text}
- Sections: {outline}
- Depth: {level}
- Examples: {key examples}
### Voice
- Register: {register}
- Visual elements: {list}
- Code blocks: {yes/no/count}

### Specifics
- Key takeaways: {list}
- Closing format: {format}
- Tags: {people to tag}
- CTA: {call to action}

## Source Material (if provided)
{Stories, anecdotes, data, or references [Your Name] supplied during Stage 1-2}

## Supporting Packet
{Daily content packet highlights, answer-bank pointers, or prior published links used to ground the draft}

## Placeholder Map
| Section | What's needed | Type | Priority |
|---------|--------------|------|----------|
```

Also save a copy to `Documents/Field-Notes/Plans/{YYYY-MM-DD}-Article-{Slug}.md` ([Your Name]'s review copy).

### Placeholder map

After saving the decision spec, fill in the **Placeholder Map** section of the spec showing where personal stories, specific examples, data points, or anecdotes will be needed in each section. Present the spec (including the placeholder map) inline so [Your Name] can supply content before writing starts.

If [Your Name] supplies content for any placeholder, add it to the spec's `## Source Material` section. Anything not supplied will become `[STORY NEEDED: ...]` placeholders in the draft.

Confirm with [Your Name]: "Decision sprint complete. Here's the spec and placeholder map: [display inline]. Want to fill any of these before I draft, or should I placeholder them all?"

### Creative Brief

Synthesize all decisions into a single reviewable document. The last checkpoint before drafting.

| Element | Content |
|---------|---------|
| **What** | Asset type and format |
| **Who** | Target audience + where they are in their journey |
| **Core idea** | One sentence topic |
| **Angle/hook** | What makes this worth reading |
| **Key proof points** | Evidence, examples, data |
| **Goal/CTA** | What the reader should do or think after |
| **Voice notes** | Only if deviating from default voice profile |
| **Constraints** | Word count, platform requirements, things to avoid |

Present the brief. [Your Name] confirms, adjusts, or redirects. Once approved, the brief becomes the input to Stage 3.

---

## Stage 3: Write + Edit + Publish Website Article (Business Level)

**Goal:** Produce a business-level article for [your-domain], iterate until approved, then publish.

### 3a: Draft

Dispatch the content agent (Opus) with:

1. The approved creative brief (primary input) and full decision spec (reference)
2. Voice profile: `@Profiles/Voice-Profile.md`
3. **Few-shot voice examples:** Read `@Profiles/Voice-Samples-Raw.md` and select 1-2 samples that match the active register. Use this register-to-sample mapping:
   - **Technical register:** Sample 1 (Reddit Change Monitor), Sample 4 (OpenClaw Tone Correction), Sample 17 (8 Layers of Memory)
   - **Teaching register:** Sample 2 (FetLife Apology), Sample 8 (Brand Voice), Sample 13 (Kink Education Vision)
   - **Professional short-form:** Sample 5 (LinkedIn Profile), Sample 15 (Content Strategy), Sample 16 (Reddit Article Direction)
   - **Story 3 / Reflective:** Sample 21 (Value Stack Ascent), Sample 22 (Slot Machine Brain)
   Pick the 2 most relevant samples for the article's topic within the register. Include [Your Name]'s version only (not the AI version). Keep each excerpt under 300 words; use the most representative passage if longer.
4. Any source material [Your Name] provided in Stages 1-2
5. Any useful content-packet or answer-bank material from Stage 1
6. **Instruction to the content agent:**

```
Write a business-level article for [your-domain]. This is the primary version targeting
a business/professional audience — high-level concepts, outcomes, and impacts. A technical
deep-dive may follow as a separate piece, so don't try to cover implementation details here.

Mode: draft
Register: {register from spec}

## Your role

You are a synthesizer, not a creator. Your job is to build the structure, voice, and argument.
[Your Name] supplies the facts, stories, and personal experiences. When you don't have a real
fact or story, use a placeholder. Never invent one.

## Content classification

You CAN generate freely (no placeholder needed):
- General industry knowledge and commonly known facts
- Logical arguments, analysis, and synthesis of provided material
- Definitions, frameworks, and explanatory structure
- Transitions, introductions, and conclusions built from the spec
- Hypothetical examples clearly framed as illustrative ("Imagine...", "Consider a scenario...")

You MUST use a placeholder for:
- Personal anecdotes, stories, or experiences attributed to [Your Name]
- Attributed quotes from specific people
- Specific events, dates, or incidents not in the source material
- Statistics, metrics, or data points you cannot verify
- Names of people or organizations not provided in the spec or source material

## Placeholder format

Use these structured placeholders. The guidance fields help [Your Name] write the real content:

[STORY NEEDED: {what the story should accomplish}
  Purpose: {why this story is here, what it proves}
  Ideal shape: {length, structure, e.g. "2-3 sentences, problem-then-insight"}
  Example angle: {a direction [Your Name] could take, not the story itself}]

[FACT NEEDED: {what data or fact would strengthen this point}]
[STAT NEEDED: {what metric or number is needed, and why}]
[EXAMPLE NEEDED: {what kind of real example would work here}]

## Voice

You have been given 1-2 authentic writing samples from [Your Name] in this register. These are
your primary voice reference. Write in this style. Match the rhythm, sentence length variation,
opening patterns, and closing patterns you see in the samples.

Also apply Voice-Profile.md patterns for the {register} register. Before writing, quote 2-3
specific patterns from the samples you'll reproduce (not describe, reproduce).

## Self-review before returning

1. Does the opening match the chosen hook style?
2. Does the close match the chosen format?
3. Are there em-dashes? (Remove them.)
4. Does the depth match the spec?
5. Is the repo link footer present?
6. Would the first paragraph work as a standalone summary?
7. **Fabrication check:** Am I stating something as if [Your Name] experienced it? Is every first-person claim traceable to the source material? If not, convert to a placeholder.

## Output

Save the completed draft to: Documents/Content-Pipeline/Drafts/{Article-Folder}/[your-handle].md
Create the article folder if it doesn't exist.
Also return the full draft inline with word count and reading time.

At the end, include a placeholder summary (removed before publishing):

Placeholders remaining: {count}
- {section}: {placeholder type and brief description}
- {section}: {placeholder type and brief description}
```

### 3b: Stop-slop pre-edit audit

After the draft is saved, run a stop-slop structural audit on the raw AI-generated draft **before presenting it to [Your Name]**. This catches AI patterns at their source.

Dispatch a general-purpose agent (Sonnet) with:
1. The draft from `Drafts/{Article-Folder}/[your-handle].md`
2. Reference files: `.claude/skills/stop-slop/references/structures.md` and `.claude/skills/stop-slop/references/phrases.md`
3. The decision spec (for source material cross-reference)
4. Instruction: scan for structural AI patterns (false agency, binary contrasts, dramatic fragmentation, copula avoidance, formulaic structure, synonym cycling, rule-of-three). Score on 5 dimensions: Directness, Rhythm, Trust, Authenticity, Density (each 1-10).

Additionally, scan for **untraced first-person claims**: any sentence where the author says "I built/tried/found/discovered/noticed" or makes a specific factual claim (a number, a date, a named tool, a metric) that cannot be traced to the decision spec's source material section. Flag each as:

`FABRICATION RISK: "{exact quote}" — no source material match found`

This is not a judgment call. If the claim isn't in the source material and isn't a placeholder, flag it. Let the author decide.

Present the stop-slop findings inline alongside the draft:

```
## Pre-Edit Structural Audit (score: XX/50)

- [pattern]: "exact quote" → suggested fix
```

If score < 35/50: flag prominently.

After the structural audit, apply the scorecard in `references/voice-scorecard.md`. Report:

```text
Voice scorecard: {total}/25
- Voice Match: X/5
- Truth Grounding: X/5
- Technical Specificity: X/5
- Authenticity: X/5
- Platform Fit: X/5
```

If Truth Grounding is below 4/5, do not recommend publishing without another pass.

### 3c: Author edit

Display the full draft inline, followed by the stop-slop findings.

Tell [Your Name]:

> "Draft is at `Documents/Content-Pipeline/Drafts/{Article-Folder}/[your-handle].md`. Stop-slop findings are above. Edit directly, then let me know when you're done."

Wait for [Your Name] to signal completion.

After [Your Name] signals completion, read the edited file and diff against the decision spec:
1. Identify intentional departures (sections removed, structure changed, tone shifted)
2. Ask briefly: "You changed X, Y, Z from the spec. Intentional?"
3. Store confirmed departures for the review panel.

### 3d: Review panel

Read `references/review-personas.md` for full persona prompts.

**Reviewer dispatch:** Based on the story track, dispatch reviewers as **parallel content agents** (`subagent_type: "content"`):

| Story | Reviewers | Model overrides |
|-------|-----------|----------------|
| 1 (Claude Code) | Voice editor + Technical peer + Anthropic PM | opus, sonnet, opus |
| 2 (Build Where They Won't) | Voice editor + Outsider reader + Indie hacker | opus, sonnet, opus |
| 3 (Solo Founder) | Voice editor + Outsider reader + General tech + Technical peer | opus, sonnet, opus, sonnet |

Each reviewer agent gets:
- The edited draft (from 3c)
- The decision spec (from Stage 2)
- The list of intentional departures (from 3c)
- Their persona prompt (from `references/review-personas.md`)

**Stop-slop post-edit audit (parallel with reviewers):** Second pass on the edited version. Dispatch a general-purpose agent (Sonnet) to scan for AI patterns that survived edits or were introduced during editing. Include delta from pre-edit score.

**Synthesize reviews:** Categorize findings as Critical / High-Value / Worth Considering. Present to [Your Name]:

```
## Review Summary

### Critical (must fix)
- [finding with reviewer attribution]

### High-Value (recommended)
- [finding with reviewer attribution]

### Worth Considering (author's call)
- [finding with reviewer attribution]

### Structural Audit (score: XX/50, delta: +/-N)
- [findings]
```

Fix critical issues automatically (or with confirmation if ambiguous). [Your Name] decides on the rest.

**If significant edits result from the review panel:** Offer to re-run the panel. [Your Name] decides.

### 3e: Publish to website

Once the article is approved:

1. Create `Code/[your-handle]/src/content/articles/{slug}.md` with YAML frontmatter per `references/platform-templates.md`
2. Run `cd Code/[your-handle] && npm run build` to verify the build passes
3. Stage the specific article file: `git add Code/[your-handle]/src/content/articles/{slug}.md`
4. Commit: `git commit -m "article: {title}"`
5. Push: `git push origin main`
6. Cloudflare auto-deploys. Capture URL: `[your-domain]/articles/{slug}/`

---

## Stage 4: LinkedIn + X (Business Level)

**Goal:** Adapt the approved website article for LinkedIn and X, then publish.

### 4a: Write adaptations

Dispatch the content agent to write both platform variants. Each gets:
- The approved `[your-handle].md`
- The website URL (for linking)
- Platform-specific format guidelines from `@references/platform-templates.md`
- Platform-specific editorial guidance from `@references/platform-writing-guide.md`
- LinkedIn algorithm reference from `@references/linkedin-reference.md`
- Voice profile for voice consistency
- The anti-fabrication constraint below

**Anti-fabrication constraint (include in dispatch):**

```
## Anti-fabrication constraint

You are adapting an approved article, not writing new content. Every factual claim,
personal anecdote, statistic, and named example in your adaptation must come from
the approved source article. You may:
- Reframe, condense, or restructure existing claims
- Drop claims that don't fit the platform
- Add platform-appropriate framing ("I wrote about this in depth on my site")

You must NOT:
- Introduce new personal stories not in the source article
- Add statistics, metrics, or data points not in the source article
- Attribute quotes or experiences not in the source article
- State new first-person claims ("I found...", "In my experience...")
  that aren't in the source

If you need to add context the source article doesn't provide, use:
[CONTEXT NEEDED: what would strengthen this adaptation]
```

**LinkedIn format choice:** Based on the article content, choose the best format:
- **Long text post** (1,300-1,900 chars) — default for article adaptations. Technical depth welcome.
- **Short text post** (100-300 chars) — teaser/conversation starter pointing to the article.
- **Document carousel** (8-12 slides, PDF) — when the article has a clear step-by-step or list structure. Highest engagement format.

LinkedIn can carry technical depth — it's not limited to business-level framing. Show the system AND the result. Code snippets welcome when they serve the story.

**LinkedIn constraint:** Do NOT reference Reddit or promise a technical follow-up. The Reddit post doesn't exist yet. LinkedIn goes out with the website URL only.

Save variants to `Documents/Content-Pipeline/Drafts/{Article-Folder}/`:
- `LinkedIn.md`
- `X-thread.md`

### 4b: Review and iterate

Present both adaptations to [Your Name]. Iterate if needed.

### 4c: Publish

**LinkedIn:**
1. Write LinkedIn content to `/tmp/linkedin-post.txt`
2. Dry-run: `python3 Scripts/linkedin-post.py --file /tmp/linkedin-post.txt --dry-run`
3. Show preview. Post after [Your Name]'s approval: `python3 Scripts/linkedin-post.py --file /tmp/linkedin-post.txt`
4. Capture the LinkedIn URL
5. Tell [Your Name]: "Add the article URL as the first comment on LinkedIn (LinkedIn penalizes links in body text)."

**X Thread:**
1. Write thread to `/tmp/x-thread.txt` (format: tweets separated by `---`)
2. Show thread preview. Confirm with [Your Name]: "Thread looks good?"
3. Post first tweet: `xurl post "first tweet text"`, then chain replies: `xurl reply TWEET_ID "next tweet"` for each subsequent tweet
5. Capture the thread URL from output

### 4d: Decision point

> "Business-level article is live on the website, LinkedIn, and X. Want to add technical depth (expanded website article + Reddit)? Or done here?"

Default recommendation: **Done** (unless the topic is explicitly technical Story 1 content, in which case recommend continuing).

If done → skip to Stage 8.
If continuing → proceed to Stage 5.

---

## Stage 5: Write + Edit + Publish Technical Website Article (OPTIONAL)

**Goal:** Expand the article with full technical depth, iterate, and publish to the website.

### 5a: Scope the technical expansion

Before drafting, ask:

> "Expand the existing article or publish as a separate technical deep-dive?"

Record the answer. This affects Stage 8 tracking:
- **Overwrite:** same URL, updated frontmatter
- **Separate:** new slug, new URL, tracking records two website URLs

### 5b: Draft

Dispatch the content agent (Opus) with the same framework as Stage 3 (including few-shot voice examples from Voice-Samples-Raw.md, prioritizing Technical register samples), but with updated instruction:

```
Expand this business-level article into a full technical deep-dive. Add:
- Code examples (sanitized — no credentials, no personal data)
- Implementation details, architecture decisions, trade-offs
- As much depth as needed — no artificial length limits
- Keep concepts concise, but don't hold back on detail

The audience is technical practitioners who want to understand HOW, not just WHAT.
```

Provide the approved business article as the starting point.

### 5c: Stop-slop pre-edit audit

Same pattern as Stage 3b. Dispatch general-purpose agent (Sonnet) to scan the raw draft. Includes the source-traceability scan for untraced first-person claims (same instruction as 3b).

### 5d: Author edit

Same pattern as Stage 3c. Present draft + stop-slop findings. Wait for edits. Spec reconciliation.

### 5e: Review panel

Same pattern as Stage 3d. Full reviewer dispatch + stop-slop post-edit audit.

If significant edits result, offer to re-run the panel.

### 5f: Publish to website

If overwriting:
1. Update the existing article file at `Code/[your-handle]/src/content/articles/{slug}.md`
2. Update frontmatter (date, description if changed)
3. Build, commit, push (same sequence as Stage 3e)

If separate page:
1. Create new article at `Code/[your-handle]/src/content/articles/{slug}-technical.md`
2. Add cross-link in the original business article pointing to the technical version
3. Build, commit, push
4. Capture new URL: `[your-domain]/articles/{slug}-technical/`

---

## Stage 6: Reddit (OPTIONAL)

**Goal:** Adapt the technical website article for Reddit and publish.

### 6a: Write Reddit adaptation

Dispatch the content agent with:
- The approved technical article
- The website URL(s)
- Reddit format guidelines from `@references/platform-templates.md`
- Reddit editorial guidance from `@references/platform-writing-guide.md`
- The anti-fabrication constraint from Stage 4a (same block, included in dispatch)

Save to `Documents/Content-Pipeline/Drafts/{Article-Folder}/Reddit.md`

### 6b: Review and iterate

Present to [Your Name]. Iterate if needed.

### 6c: Publish

1. Write Reddit content to `/tmp/reddit-post.md`
2. If `Scripts/post-to-reddit-api.py` is available and configured, use it
3. Otherwise: copy to clipboard with `printf '%s' "$(cat /tmp/reddit-post.md)" | pbcopy`
4. Tell [Your Name]: "Reddit post copied to clipboard. Paste into r/ClaudeCode."
5. After confirmation, ask for the Reddit URL

---

## Stage 7: LinkedIn + X Technical (OPTIONAL)

**Goal:** Post technical-level content to LinkedIn and X with link back to Reddit.

### 7a: Write adaptations

Dispatch the content agent to write (include the anti-fabrication constraint from Stage 4a in each dispatch):
- LinkedIn technical adaptation (references the Reddit post and/or technical website article)
- X thread with technical framing + link to Reddit

Save to `Documents/Content-Pipeline/Drafts/{Article-Folder}/`:
- `LinkedIn-technical.md`
- `X-thread-technical.md`

### 7b: Review and iterate

Present both to [Your Name]. Iterate if needed.

### 7c: Publish

**LinkedIn:**
1. Write to `/tmp/linkedin-technical-post.txt`
2. Dry-run, show preview, post after approval
3. Capture URL

**X Thread:**
1. Write to `/tmp/x-thread-technical.txt`
2. Dry-run, confirm, post
3. Capture URL

---

## Stage 8: Track

**Goal:** Update all tracking files and move the article to published.

### Business-only flow (Stages 1-4)

1. Create/update `Documents/Content-Pipeline/Drafts/{Article-Folder}/published.md` with:
   - Website URL
   - LinkedIn URL
   - X thread URL
   - Flow shape: Business only
   - Dates for each platform

2. Move the article folder:
   ```bash
   mv "Documents/Content-Pipeline/Drafts/{Article-Folder}" "Documents/Content-Pipeline/Published/{Article-Folder}"
   ```

3. Update `Documents/Content-Pipeline/Published-URLs.md` with all new URLs

4. Update website article frontmatter `platforms:` field:
   ```yaml
   platforms:
     linkedin: "{url}"
     x_thread: "{url}"
   ```

5. Stage and commit:
   ```bash
   git add "Documents/Content-Pipeline/Published/{Article-Folder}/"
   git add Documents/Content-Pipeline/Published-URLs.md
   git add "Code/[your-handle]/src/content/articles/{slug}.md"
   git commit -m "track: {title} published (business)"
   ```

### Business + Technical flow (Stages 1-7)

Same as above, plus:
- Record second website URL if a separate technical page was created
- Add Reddit URL, LinkedIn technical URL, X technical thread URL
- Add Reddit link as comment on the original LinkedIn post (remind [Your Name])
- Update website article frontmatter with all platform URLs:
  ```yaml
  platforms:
    linkedin: "{url}"
    linkedin_technical: "{url}"
    x_thread: "{url}"
    x_thread_technical: "{url}"
    reddit: "{url}"
  ```

6. Remind [Your Name] about engagement:
   > "Article is live. Engagement windows: Reddit comments within 4 hours (critical), LinkedIn within 2 hours, X throughout the day."

---

## Error Handling

- **Content agent failure at Stage 3/5:** Retry once. If it fails again, write the draft directly (Jules writes it instead of the content agent).
- **Build failure at Stage 3e/5f:** Fix the build error before proceeding. Common issues: frontmatter format, missing imports, image paths.
- **Posting failure at Stage 4c/6c/7c:** Log the failure, continue with other platforms. Report all failures at the end. Manual posting is always the fallback.
- **LinkedIn token expired:** Skip LinkedIn, note it in the tracking file. Remind [Your Name] to refresh: `python3 Scripts/linkedin-auth.py`

## Resumability

If the pipeline is interrupted (session ends, context clears), it can be resumed:
- **Stage 2 complete?** The decision spec in `~/.claude/plans/article-{slug}.md` has everything needed.
- **Stage 3 in progress?** The draft in `Drafts/` is the checkpoint.
- **Stage 4 decision point reached?** Check which platforms have been posted to. `published.md` tracks progress.
- **Stage 5-7 in progress?** Same checkpoints apply.

To resume: "Continue /write-article for {title}" and Jules picks up from the last completed stage.
