# Decision Sprint Questions

Question bank for Stage 2. Draw from these by category. Adaptive length: simple thesis uses Round 1 only, complex thesis goes through all rounds. Use AskUserQuestion with previews for opening hooks and structural choices.

## Round 1: Structure + Content

These establish the article's skeleton. Always ask these.

1. **Opening hook** (use AskUserQuestion with previews showing 3 candidate openings):
   - Problem-I-hit opener: "I spent X hours on Y and here's what I found"
   - Insider knowledge drop: "[Specific non-obvious fact]. Here's why that matters."
   - Direct thesis: "X is wrong. Here's the better way."
   - Narrative opener: "Last Tuesday I was debugging Y when..."

2. **Section architecture** (use AskUserQuestion with preview showing outline):
   - How many major sections? (typically 3-5)
   - What order? (chronological, problem-solution, tutorial, concept-example)
   - Any sections to deliberately cut for length?

3. **What to expand vs. cut:**
   - Which parts are the real insight? (expand those)
   - Which parts are setup/context that experienced readers can skip? (trim those)

4. **Depth level for technical sections:**
   - Code-heavy (full snippets, step-by-step)?
   - Concept-heavy (explain the why, minimal code)?
   - Mixed (code for key moments, prose for reasoning)?

5. **Key examples or data points:**
   - What's the most concrete proof this works? (numbers, before/after, screenshots)
   - Any examples that didn't make the cut but should?

## Round 2: Voice + Format

These shape how it reads. Ask for medium and complex theses.

6. **Register and tone:**
   - Pure technical (r/ClaudeCode depth)?
   - Technical with personal framing (the default)?
   - Narrative-first (story that happens to be technical)?
   - Teaching mode (here's how you do this)?

7. **Visual elements:**
   - Diagrams (architecture, flow, sequence)?
   - Code blocks (how many, what language)?
   - Tables for comparisons?
   - Aside boxes for caveats?

8. **Audience context level:**
   - Assume Claude Code familiarity?
   - Include brief context for newcomers?
   - Write for a general tech audience?

9. **Length target:**
   - Short (500-800 words, focused insight)
   - Medium (800-1500 words, tutorial or deep dive)
   - Long (1500-2500 words, comprehensive guide)

10. **Code blocks:**
    - Full runnable snippets?
    - Key excerpts only?
    - No code (concept piece)?

## Round 3: Specifics

These nail down the details. Ask for complex theses.

11. **Principles/takeaways:**
    - What did you actually learn? (not "best practices" but your specific insight)
    - What would you tell someone starting this today?

12. **Closing format:**
    - Resource links (GitHub, docs)?
    - Next steps ("try this yourself")?
    - Wry callback to the opening?
    - Open question for discussion?

13. **People to tag (X thread):**
    - Anthropic team members relevant to the topic?
    - Community members who'd find this useful?
    - Check `Documents/Content-Pipeline/Social-Handles.md`

14. **Call to action:**
    - Try it yourself?
    - Read the repo?
    - Share your approach?
    - No CTA (the insight is enough)?

## Round 4: Gap Check (only if needed)

Run this when the decision spec has unresolved tensions.

15. **Spec vs outline reconciliation:**
    - Review all decisions against the outline
    - Identify contradictions (e.g., "short article" + "5 code blocks")
    - Resolve ambiguity

16. **Audience tension:**
    - Are we trying to serve two different audiences? Pick one.
    - Is the depth consistent throughout, or does it swing?

## Adaptive Length Rules

| Thesis complexity | Rounds | Approximate decisions | Time |
|-------------------|--------|----------------------|------|
| Simple (clear topic, obvious structure) | 1 | 5-8 | ~5 min |
| Medium (some structural choices) | 1-2 | 8-14 | ~10 min |
| Complex (multiple angles, audience tension) | 1-3 | 14-20 | ~15-20 min |
| Very complex (new territory, no prior art) | 1-4 | 20-30 | ~20-30 min |

**Complexity signals:**
- Simple: "Write about X" where X has one obvious angle
- Medium: "Write about X" where structure or audience isn't obvious
- Complex: "Write about X and Y" or "compare A vs B" or "the case for Z"
- Very complex: New thesis with no prior content, or controversial take requiring careful framing
