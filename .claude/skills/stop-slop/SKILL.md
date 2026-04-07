---
name: stop-slop
model: opus
effort: medium
description: >
  Structural audit for AI writing patterns. Catches paragraph-level tells that
  word-level checks miss: false agency, binary contrasts, dramatic fragmentation,
  narrator-from-a-distance, formulaic rhythm. Scores on 5 dimensions (35/50 threshold).
  Use on content pipeline output before publishing. Invoke with /stop-slop.
user-invocable: true
---

# Stop Slop: Structural AI Pattern Audit

<!-- Source: hardikpandya/stop-slop (fetched 2026-03-24), with cherry-picks from
     blader/humanizer and mshumer/unslop blog-writing profile. Snapshot, not auto-updated. -->

Eliminate structural AI writing patterns from prose. This skill focuses on **paragraph-level and structural tells** that survive word-level editing. Voice-Profile.md handles banned words/phrases. This handles the architecture of the writing.

## When to Use

- Content pipeline output (articles, Reddit posts, X threads) before publishing
- As part of `/write-article` Stage 5 review panel
- In content agent `humanize` mode as Pass 3 (structural audit)
- Manual invocation via `/stop-slop` on any draft

Do NOT run on: Jules conversational output, internal docs, code comments, quick replies.

## Core Rules

1. **Break formulaic structures.** No binary contrasts ("Not X. Y."), negative listings, dramatic fragmentation, rhetorical setups. See `references/structures.md`.

2. **Kill false agency.** Inanimate things don't perform human actions. "The complaint becomes a fix" = no. "The team fixed it" = yes. Name the human actor.

3. **Use active voice.** Every sentence needs a subject doing something. No passive constructions hiding the actor.

4. **Be specific.** No vague declaratives ("The reasons are structural"). Name the specific thing.

5. **Put the reader in the room.** No narrator-from-a-distance. "You" beats "People." Specifics beat abstractions.

6. **Vary rhythm.** Mix sentence lengths. Two items beat three. End paragraphs differently. No em dashes. No staccato fragmentation stacking.

7. **Trust readers.** State facts directly. Skip softening, justification, hand-holding.

8. **Cut quotables.** If it sounds like a pull-quote, rewrite it.

9. **No formulaic article structure.** Don't default to: intro hook, context, 3-5 body sections, takeaway, CTA. Vary. No "Final thoughts" or "Key takeaways" headers. No rhetorical questions as section transitions.

10. **Commit or don't claim.** No hedging every other sentence with "might," "could potentially," "it remains to be seen." Either make the claim or drop it.

## Quick Checks

Before delivering prose, scan for:

- Inanimate thing doing a human verb? Name the person.
- "Not X, it's Y" binary contrast? State Y directly.
- Three consecutive sentences match length? Break one.
- Paragraph ends with punchy one-liner? Vary it.
- Any "here's what/this/that" throat-clearing? Cut to the point.
- Narrator-from-a-distance ("Nobody designed this")? Put the reader in the scene.
- Formulaic structure (hook, context, 3 body sections, takeaway)? Vary it.
- Rule-of-three construction? Use two items or one.
- Synonym cycling (protagonist, main character, central figure)? Just repeat the clearest word.
- "Serves as" / "stands as" / "features" instead of "is" / "has"? Use the simple copula.
- False range ("from X to Y" where the scale is meaningless)? List topics directly.
- Sentence lengths clustering in 10-20 word range? Calculate SD of word counts per sentence. SD < 8 = metronomic (AI tell). [Your Name]'s writing: SD 9-14.

## Scoring Rubric

Rate 1-10 on each dimension:

| Dimension | Question |
|-----------|----------|
| **Directness** | Does it state things or announce them? Is it making points or building up to them? |
| **Rhythm** | Do sentence lengths vary naturally, or is the cadence metronomic? Any staccato stacking? **Burstiness check:** Calculate the standard deviation of sentence word counts across the draft. Human writing typically has SD > 8 words ([Your Name]'s samples: SD 9-14). Flag if SD < 8 as "metronomic uniformity" and cap Rhythm score at 6/10 regardless of other rhythm qualities. Report the SD value in the audit output. |
| **Trust** | Does it respect reader intelligence, or does it soften, justify, and hand-hold? |
| **Authenticity** | Does it sound like a specific human wrote it, or like median-internet-text? |
| **Density** | Is every sentence doing work, or is there cuttable filler? |

**Threshold: 35/50.** Below 35: surface specific failing patterns with suggested rewrites. The human reviewer must explicitly approve or revise before publication.

**Calibration note:** 35/50 was calibrated against [Your Name]'s published articles (scored 38-44) and raw voice samples (scored 40-47). Adjust if publishing standards change.

## Output Format

When invoked as an audit:

```
## Stop-Slop Audit

**Score: [N]/50** (Directness: X | Rhythm: X | Trust: X | Authenticity: X | Density: X)
**Burstiness:** Sentence length SD = X.X words (threshold: 8.0 | [Your Name] baseline: 9-14)

### Findings

[List each structural pattern found, with line reference and severity]

### Suggested Rewrites

[For each finding, show the original and a rewritten version]

### Verdict

PASS (score >= 35) / REVISE (score < 35, with specific items to address)
```

## References

- `references/phrases.md` — Phrase-level patterns to cut (deduplicated against Voice-Profile.md)
- `references/structures.md` — Structural anti-patterns with examples
- `references/examples.md` — Before/after transformations
