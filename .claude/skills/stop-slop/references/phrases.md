# Phrases to Remove

<!-- Source: hardikpandya/stop-slop + blader/humanizer + mshumer/unslop (fetched 2026-03-24)
     Deduplicated against Voice-Profile.md. Voice-Profile.md is canonical for word-level bans.
     This file covers phrases NOT already in Voice-Profile.md's "Never Use" section. -->

## Throat-Clearing Openers

Remove these. State the content directly.

- "Here's the thing:"
- "Here's what [X]" / "Here's this [X]" / "Here's that [X]" / "Here's why [X]"
- "The uncomfortable truth is"
- "It turns out"
- "The real [X] is"
- "Let me be clear"
- "The truth is,"
- "I'll say it again:"
- "I'm going to be honest"
- "Can we talk about"
- "Here's what I find interesting"
- "Here's the problem though"
- "But here's the catch"
- "Think about it this way"
- "This is where things get interesting"
- "The short answer is" / "The long answer is"
- "The bottom line"

Any "here's what/this/that" construction is throat-clearing. Cut it and state the point.

## Emphasis Crutches

These add no meaning. Delete them.

- "Full stop." / "Period."
- "Let that sink in."
- "This matters because"
- "Make no mistake"
- "Here's why that matters"
- "Spoiler alert:"

## Business Jargon

Replace with plain language. (Note: "delve," "leverage," "robust," "seamless," etc. are in Voice-Profile.md.)

| Avoid | Use instead |
|-------|-------------|
| Navigate (challenges) | Handle, address |
| Unpack (analysis) | Explain, examine |
| Lean into | Accept, embrace |
| Landscape (context) | Situation, field |
| Double down | Commit, increase |
| Deep dive | Analysis, examination |
| Take a step back | Reconsider |
| Moving forward | Next, from now |
| Circle back | Return to, revisit |
| On the same page | Aligned, agreed |

## Adverb Kill List

No -ly words. No softeners, no intensifiers, no hedges. Specific offenders not already in Voice-Profile.md:

- "really," "just," "literally," "genuinely," "honestly"
- "simply," "actually," "deeply," "truly"
- "fundamentally," "inherently," "inevitably"
- "interestingly," "importantly," "crucially"

Also cut these filler phrases:

- "At its core"
- "When it comes to"
- "In a world where"
- "The reality is"
- "In other words"
- "To put it simply"
- "Perhaps most importantly"
- "The good news is" / "The bad news is"

## Meta-Commentary

Remove self-referential asides. The essay should move, not announce its structure.

- "Hint:" / "Plot twist:" / "Spoiler:"
- "You already know this, but"
- "But that's another post"
- "X is a feature, not a bug"
- "The rest of this essay explains..."
- "In this section, we'll..."
- "As we'll see..."

## Performative Emphasis

False intimacy or manufactured sincerity:

- "creeps in"
- "I promise" / "They exist, I promise"

## Telling Instead of Showing

Announcing difficulty or significance rather than demonstrating it:

- "This is genuinely hard"
- "This is what [X] actually looks like"
- "actually matters"

## Vague Declaratives

Sentences that announce importance without naming the specific thing. Kill these.

- "The reasons are structural"
- "The implications are significant"
- "This is the deepest problem"
- "The stakes are high"
- "The consequences are real"

## Significance Inflation (from humanizer)

Phrases that inflate importance beyond what the content warrants:

- "marking a pivotal moment"
- "an enduring testament to"
- "underscoring its vital role"
- "reshaping how [people] [verb]"
- "at the intersection of X and Y"

## Humanizer Patterns

Unique patterns from blader/humanizer not covered above or in Voice-Profile.md:

**Copula avoidance** — LLMs substitute elaborate constructions for simple "is"/"has":
- "serves as" → "is"
- "stands as" → "is"
- "marks" → "is"
- "represents" → "is"
- "boasts" → "has"
- "features" → "has"
- "offers" → "has"

**Synonym cycling** — Unnecessarily varying word choice to avoid repetition. LLMs have repetition-penalty code that causes this. Just repeat the clearest word.
- Bad: "The protagonist... the main character... the central figure... the hero"
- Good: "The protagonist... the protagonist... they"

**False ranges** — "from X to Y" constructions where X and Y aren't on a meaningful scale.
- Bad: "from the singularity of the Big Bang to the grand cosmic web"
- Good: "covers the Big Bang, star formation, and dark matter theories"

**Rule-of-three overuse** — LLMs force ideas into groups of three to appear comprehensive.
- Bad: "innovation, inspiration, and industry insights"
- Good: "talks and panels" (use the natural number of items)

**Notability name-dropping** — Listing publications or names without context to inflate credibility.
- Bad: "cited in The New York Times, BBC, Financial Times, and The Hindu"
- Good: "In a 2024 NYT interview, she argued..."

**Superficial -ing analyses** — Tacking on "-ing" clauses that add no information:
- Bad: "symbolizing the community's resilience, reflecting broader trends, showcasing growth"
- Good: Remove or expand with actual sourced analysis

**Formulaic challenges section** — "Despite challenges typical of [X]... continues to thrive/grow"
- Just name the specific challenges and their actual outcomes

## Unslop Blog Profile Additions

From mshumer/unslop's blog-writing profile (generated from 100 samples):

**Structural bans:**
- Don't start with a broad sweeping statement before narrowing to the topic
- Don't use the "[Broad claim]. But [complication]. Here's [resolution]" formula
- Don't end by restating the thesis in grander terms than warranted
- Don't add a "The future of X" section near the end
- Don't number points unless the reader needs them in order

**Tonal bans:**
- Don't affect breathless enthusiasm ("fascinating," "remarkable," "transformative")
- Don't use false-authority voice where opinion sounds like settled consensus
- Don't end paragraphs with one-sentence dramatic kickers meant to sound profound

**Word bans (not already covered):**
- "unlock" metaphorically ("unlock potential")
- "double-edged sword"
- "at the intersection of X and Y"
- "ecosystem" (metaphorical)
- "compelling" (as filler adjective)
