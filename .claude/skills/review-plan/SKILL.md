---
name: review-plan
description: Auto-tiered review for plans, architecture decisions, and analysis documents. Classifies plans (Light/Standard/Deep) and runs proportional review depth automatically. Use when the user has a plan they want stress-tested, invokes /review-plan, or says "review this plan", "devil's advocate", "stress test this", "pre-mortem", or "what could go wrong". Also triggered automatically after writing-plans completes a plan.
---

# Plan Review & Improvement

A structured adversarial review for plans, architecture decisions, and analysis — followed by direct improvements. Fights confirmation bias by forcing you to imagine failure before committing, then fixes what you find.

## When to Use

- After writing an implementation plan, before executing it
- After research-heavy analysis, before acting on conclusions
- Before major architecture decisions
- Any time the user says "review this plan" or "devil's advocate"
- After the writing-plans skill saves a plan (writing-plans will prompt this automatically)

## Input

The plan can come from:
- A file path the user provides (`review-plan plan.md`)
- The plan currently in context from the conversation
- A plan file written during plan mode

If no plan is obvious, ask: "Which plan should I review?"

---

## Step 0: Classify

Before reviewing, classify the plan to determine review depth. State the tier and a one-line rationale before proceeding.

| Tier | Signals | What runs |
|------|---------|-----------|
| **Light** | <=3 files, easily reversible, no new patterns/deps/architecture, config edits, simple bug fixes | Decision Brief only. Skip all lenses and cold review. |
| **Standard** | 4+ files, touches core logic/APIs, new patterns or deps, research-heavy analysis | Phase 1 (5 lenses) + Phase 2 (improvements + Decision Brief). Skip cold review. |
| **Deep** | Architecture decisions, hard-to-reverse changes (DB migrations, public APIs, infra), security-sensitive, or user explicitly requested deep review | Full Phase 1 + Phase 2 + Phase 3 (cold subagent) |

Trust judgment, not rigid rules. A 2-file change that introduces a new architectural pattern is Standard. A 10-file config rename is Light.

**Light tier path:** Skip directly to writing `## Decision Brief` using the compressed single-line format (see template below). No lenses, no Review Notes. If `## Decision Brief` already exists from a prior pass, update it in-place.

**Standard/Deep tier:** Continue to Phase 1 below.

---

## Phase 1: Review

Run all seven lenses in order. Each one targets a different class of blind spot.

### Lens 1: Failure Post-Mortem

> "It's 3 months from now. This plan failed completely. Write the post-mortem."

Answer these specifically:
- What was the root cause of failure?
- What early warning signs were missed?
- Which assumption turned out to be wrong?
- What external dependency broke?

Write this as a realistic narrative, not a bullet list. Make it specific to the actual plan — no generic risks like "requirements changed."

### Lens 2: Over-Engineering Post-Mortem

> "It's 3 months from now. The project succeeded, but the plan was massive overkill. Write that post-mortem."

Answer these specifically:
- What did we build that we didn't need?
- Which "important" requirement turned out to be irrelevant?
- What simpler approach would have worked?
- Where did research depth exceed what the decision actually required?

This lens is critical for research-heavy plans where sunk cost bias ("we researched this so thoroughly, we should use all of it") inflates scope.

### Lens 3: Unstated Assumptions

List every assumption the plan makes without explicitly acknowledging it. Format:

```
Unstated assumptions:
1. [Assumption] — What happens if this is wrong?
2. [Assumption] — What happens if this is wrong?
...
```

Look specifically for:
- **Environmental assumptions** — "this API will still work this way," "this library is maintained," "this service will stay free"
- **User behavior assumptions** — "users will do X," "traffic will be Y"
- **Scope assumptions** — "this won't need Z," "the existing code handles W"
- **Research assumptions** — "the documentation is accurate," "this Stack Overflow answer is current"

### Lens 4: Autonomy Check

> "Which steps in this plan stop to ask the user for something Claude could figure out itself?"

For each step that involves user interaction (asking a question, requesting approval, presenting options), evaluate:
- **Is this a genuine decision only the user can make?** (preferences, budget, business direction) -> Keep it.
- **Is this something Claude can determine from context?** (which file to edit, which test to run, which library version) -> Flag it. The plan should just do it.
- **Is this a confidence hedge?** ("should I proceed?" after a straightforward step) -> Flag it. Do the work, report the result.

```
Unnecessary stops:
1. [Step N] asks "[question]" — Claude can determine this by [how]
2. [Step N] presents options for [choice] — [recommended option] is clearly correct because [why]

Justified stops:
1. [Step N] asks "[question]" — genuinely requires user preference/decision
```

### Lens 5: Questions the Plan Doesn't Answer

List the questions a skeptical reviewer would ask that the plan has no answer for:

```
Open questions:
1. [Question]?
2. [Question]?
...
```

These aren't critiques — they're gaps. Some may be acceptable ("we'll figure it out during implementation"), others may be blockers that need answers before starting.

### Lens 6: Conditions for Validity

> "Under what conditions would EACH rejected alternative have been correct?"

For every rejected approach in the plan: what would the world need to look like for that alternative to be the better choice? How plausible are those conditions?

This forces conditional rather than absolute thinking. A plan that says "we chose X over Y" should also know "Y would have been right if [specific conditions]" — because those conditions might actually emerge.

```
Conditions for validity:
1. [Rejected alternative] would be correct if: [conditions]. Plausibility: [Low/Medium/High]
2. [Rejected alternative] would be correct if: [conditions]. Plausibility: [Low/Medium/High]
...
```

If any condition scores Medium or High plausibility, flag it as a risk to monitor.

### Lens 7: Red Team Destruction

> "Attack the CHOSEN approach with genuine force."

This is not balanced assessment. This is targeted destruction of the plan's weakest links. Different from Lens 1 (organic failure narrative) and Lens 6 (building cases for alternatives). This lens assumes an adversary specifically trying to break the chosen path.

Attack vectors:
- **Single points of failure** — What breaks everything if it goes wrong?
- **Hidden dependencies** — What does this plan assume exists/works that it doesn't control?
- **Scaling cracks** — Where does this approach fail at 2x, 5x, 10x the expected load/scope?
- **Time bombs** — What works now but will break in 3-6 months?

Write as a direct attack, not a review. "This plan will fail because..." not "One potential concern is..."

---

## Phase 1 Output

Present all lenses, then a summary:

```
## Review Summary

Confidence: [High / Medium / Low] — overall assessment of plan quality

Critical issues (address before proceeding):
- [if any]

Worth considering (but not blocking):
- [if any]

Acceptable gaps (acknowledged, will resolve during execution):
- [if any]
```

---

## Phase 2: Improve

After completing the review, immediately improve the plan based on findings.

### What to fix

- **Every critical issue** — these must be addressed before the plan ships
- **High-value "worth considering" items** — if the fix is straightforward, do it now
- **Unstated assumptions** — make them explicit in the plan text
- **Open questions that have obvious answers** — resolve them inline

### What NOT to fix

- Acceptable gaps — leave them acknowledged
- Cosmetic rewrites — don't restructure sections that aren't broken
- Open questions that genuinely need user input — flag these clearly instead of guessing

### How to improve

- **If the plan is a file:** Edit it directly using the Edit tool. Make targeted fixes, not a full rewrite.
- **If the plan is in-context only (no file):** Present the revised version in your response.

### After improving

Append two sections at the end of the plan (or present them at the end of your response for in-context plans):

**`## Review Notes`** — contains:

```
**Inline review:**
[What the review found, what was changed. Brief.]

**Review confidence:** [High / Medium / Low]
```

This section also serves as the gate marker — a hook can check for it before allowing ExitPlanMode.

**`## Decision Brief`** — the go/no-go decision surface. Placed last so everything the user needs is visible at the bottom without scrolling. They read THIS section to decide whether to approve, not the full plan.

**Standard/Deep tier template:**

```
**Recommendation:**
[1-2 sentences: what's broken/missing + what this plan does about it. Problem-to-solution framing, not a feature list.]

- **Effort:** [Trivial (< 15 min) / Small (< 1 hr) / Medium (1-4 hrs) / Large (half day+)]
- **Risk:** [One line distilling review confidence + main uncertainty from Review Notes]
- **If we skip this:** [What stays broken, what opportunity is missed, or "Nothing urgent — this is optimization"]
- **Reversible?** [Yes / Mostly / No — one clause on what makes it hard to undo if applicable]

**Actions:**
1. [Concrete step — one line per task, file path if relevant]
2. ...

**Needs your input:**
- [Anything that genuinely blocks or gates execution — merged from decision points and open questions. Omit subsection entirely if none.]

**Prompts used:**
- [Original user prompt, lightly cleaned]
- [Follow-up clarification or direction change, if any]
- [Additional prompts, one bullet per prompt]
```

**Light tier template** (compressed — full metadata block is overkill for trivial plans):

```
**Recommendation:** [1 sentence] | **Effort:** Trivial/Small | **Risk:** Low | **Reversible?** Yes

**Actions:**
1. [Steps]

**Prompts used:**
- [Prompts]
```

Omit "If we skip this" and "Needs your input" for Light tier when trivially obvious (almost always).

**Field guidance:**
- **Recommendation** replaces Outcomes. Frame as problem->solution, not a deliverable list. The user should understand WHY without scrolling back up to Context.
- **Effort** gives scale signal. A 5-file plan looks identical to a config edit without it.
- **Risk** carries the reviewer's verdict forward from Review Notes so the user doesn't have to read both sections.
- **If we skip this** is the cost-of-inaction lever. Sometimes the answer is "Nothing urgent" — that's useful too.
- **Reversible?** matches Decision Card format. Helps the user calibrate caution level.
- **Needs your input** merges decision points and open questions — in practice they overlap. One list of things that block or gate execution.

## Phase 3: Cold Review (Subagent) — Deep Tier Only

After completing Phase 2 improvements, launch a fresh subagent that reviews the plan **cold** — with no conversation history, no exploratory reasoning, just the plan file itself. **Only run this phase for Deep tier plans.**

This tests: "Can someone reading this plan from scratch understand it and spot the problems?"

### How to run

1. The plan **must be a file** for this phase to work. If the plan is in-context only, skip Phase 3 and note that cold review was skipped (no file to pass).

2. Spawn a `general-purpose` subagent with this prompt:

```
You are reviewing a plan file cold — you have no prior context about this project or conversation. Read the plan file at [PLAN_FILE_PATH] and review it through these lenses:

1. **Clarity:** Can you understand what this plan does without any additional context? Flag anything ambiguous, undefined, or that assumes knowledge you don't have.

2. **Completeness:** Are there obvious gaps — steps that reference outputs from previous steps that don't exist, or dependencies that aren't addressed?

3. **Risk:** What's the single biggest risk you see? Be specific.

After reviewing, edit the existing `## Review Notes` section in the plan file using the Edit tool. Add a `**Cold review:**` sub-label after the existing content, with your findings (3-8 bullet points). Also add `**Cold review confidence:** [High / Medium / Low]`. Do not create a new H2 section — add within the existing `## Review Notes`.
```

3. Wait for the subagent to complete. If it fails, note the failure and move on — don't block the review on subagent issues.

### After Phase 3

The plan should now have two sections at the bottom:
- `## Review Notes` (from Phase 2 inline review + Phase 3 cold review under sub-labels)
- `## Decision Brief` (Recommendation, Actions, Needs your input, Prompts used)

A hook can check for both sections before allowing ExitPlanMode.

---

## Rules

- **Be specific.** "Something might go wrong" is useless. "The Discord rate limiter will throttle bulk channel updates if we process more than 40 channels" is useful.
- **Be honest.** If the plan is solid, say so. Don't manufacture problems for the sake of looking thorough. A "Confidence: High" with zero critical issues is a valid outcome.
- **Don't re-litigate settled decisions.** If the user already chose React over Vue, don't argue for Vue. Review the plan *as designed*, not a different plan.
- **Distinguish research quality from plan quality.** A plan can be well-researched but poorly scoped, or under-researched but correctly scoped. Call out which it is.
- **Improve surgically.** Phase 2 fixes specific issues found in Phase 1. It's not an excuse to rewrite the plan to your taste.
