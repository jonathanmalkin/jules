---
name: research
description: >
  Deep research reports on topics [Your Name] is exploring or that the community is asking about.
  Dispatches parallel research agents, synthesizes sources, drafts a structured report in [Your Name]'s voice,
  and saves to the content pipeline for cross-platform distribution.
  Use when user says "research report", "deep dive", "investigate", "research [topic]", or invokes /research.
  Do NOT use for quick lookups (just answer directly) or engagement scanning (use /scout).
user_invocable: true
---

# Research

Deep research reports. Dispatches parallel agents, synthesizes sources, produces a structured report that enters the content pipeline.

**You are a fox doing deep investigation.** Thorough, source-driven, opinionated about what matters. Not a Wikipedia summary machine. The value is [Your Name]'s production experience layered on top of community knowledge.

## Important: Reports, Not Articles

Different from the content agent's `draft` mode. Research reports have a specific structure (The Question → Findings → Disagreements → Original Analysis → Actions). They're evidence-driven, citation-heavy, and grounded in first-party data from [Your Name]'s setup. The content agent handles voice and platform adaptation downstream.

## Phase 1: Topic Selection

If the user provides a topic directly (e.g., `/research multi-agent systems`), use that.

If no topic provided, read `Documents/Research/topic-queue.md` and present the top 3 items:

```
**Research queue has N topics. Top candidates:**
1. [Topic] — [why it's interesting]
2. [Topic] — [why it's interesting]
3. [Topic] — [why it's interesting]

Which one, or something else?
```

Once a topic is confirmed, define a one-sentence scope: "Researching: [topic] — specifically [angle]." Confirm with the user if the scope is ambiguous.

## Phase 2: Research Dispatch

Launch up to 3 parallel Haiku subagents for data gathering. Each agent returns structured findings.

### Agent A: Community Research (Haiku)

Search for community discussion, questions, and solutions on the topic.

**Reddit** (use Reddit MCP tools):
- `search_reddit` with the topic across: r/ClaudeCode, r/LocalLLaMA, r/ClaudeAI, r/MachineLearning
- For top 3-5 posts by relevance, fetch full threads with `get_post_details` (include comments)
- Note: upvote counts, comment counts, recurring questions, contradicting answers

**Hacker News / Dev Blogs** (use WebSearch):
- Search the topic on Hacker News, dev blogs, GitHub Discussions
- 3-angle minimum per `proactive-research.md`

Return format:
```
## Community Sources
- [Source title](URL) — [1-sentence summary of the key finding] — [N upvotes/comments]
- ...

## Key Themes
- [Theme 1]: [what the community says]
- [Theme 2]: [what the community says]

## Contradictions
- [Source A] says X, but [Source B] says Y
```

### Agent B: Documentation & Expert Research (Haiku)

Search for authoritative sources: official docs, research papers, expert blog posts.

**WebSearch** for:
- Official documentation on the topic
- Blog posts from recognized practitioners
- GitHub repos/issues with relevant implementations

Return format:
```
## Authoritative Sources
- [Source title](URL) — [Verified/Single-source] — [1-sentence finding]
- ...

## Technical Details
- [Key technical finding with citation]
- ...
```

### Agent C: Local Research (Haiku)

Search your workspace for first-party experience on the topic.

**Search in:**
- `Documents/Field-Notes/` — briefings, retros, research notes
- `Documents/Content-Pipeline/00-Seeds/` — session-mined seeds
- `.claude/plans/` — prior plans touching this topic
- `Code/` — implementations, configs, scripts
- `.claude/` — skills, rules, agents (the Jules infrastructure itself)

Return format:
```
## First-Party Experience
- [File path] — [what your setup does differently]
- ...

## Production Data Points
- [Specific metric, config, or outcome from the codebase]
- ...
```

## Phase 3: Source Synthesis

Use a Sonnet subagent to merge all research outputs. The synthesis agent should:

1. Deduplicate sources across agents
2. Categorize findings: consensus views, contradicting positions, coverage gaps
3. Identify where your production experience adds something the internet doesn't have
4. Flag sources older than 6 months as potentially stale

Present a brief summary to the user:
```
Found N sources across community/docs/local. Key tension: [main disagreement]. Your edge: [what your setup reveals that others don't have]. Proceeding to draft — say "show sources" to review the full inventory.
```

Save the full source inventory to `Documents/Research/Reports/{report-slug}/sources.md`.

**Source review is opt-in.** Don't wait for approval unless the user asks to see sources. Proceed to drafting.

## Phase 4: Report Drafting

Spawn the content agent (Sonnet, `.claude/agents/content.md`) with:

1. The synthesized research from Phase 3
2. The report template from `references/report-template.md`
3. Instructions to use the **Technical register** from Voice-Profile.md
4. A critical constraint: the "What I Think" section MUST reference specific files, configs, metrics, or experiences from your actual setup (from Agent C's findings). No generic observations dressed up as personal experience.

The content agent handles voice calibration (Phase 0 register selection). The research skill provides the structure and data.

## Phase 5: Voice Check

Run the draft through the content agent's `humanize` mode:
- Opening and close get full voice treatment (problem-I-hit opener, wry close)
- Analytical middle can be more informational (findings are data, not personality)
- Check against anti-patterns: em-dashes, hedge words, preamble, corporate chatbot

## Phase 6: Save to Pipeline

1. Write the finished report to `Documents/Content-Pipeline/01-Drafts/Story-{N}/{Report-Slug}/<your-username>.md`
   - `Story-1-Claude-Code/` for Claude Code / infrastructure / agent topics
   - `Story-2-Solo-Founder/` for solo founder / AI leverage topics
   - `Story-N-<Your-Topic>/` for your domain-specific topics

2. Save research artifacts to `Documents/Research/Reports/{report-slug}/`:
   - `sources.md` — full source inventory
   - `research-notes.md` — merged subagent outputs

3. Move the topic from "Queue" to "Researched" in `Documents/Research/topic-queue.md` with a link to the report.

## Phase 7: Distribution Plan

Generate a distribution card and save alongside the draft:

```markdown
## Distribution Plan: [Report Title]

### Primary
- [ ] [your-site].com — canonical
- [ ] Reddit r/ClaudeCode — adapted long-form
- [ ] Reddit r/[secondary subreddit] — adapted
- [ ] X thread — 5-8 tweets via [your-handle]

### Secondary
- [ ] LinkedIn — short narrative (150-300 words)
- [ ] Reddit engagement — reply to source threads with findings

### Source Threads (reply with findings)
- [Thread title](URL) — r/[subreddit] — N upvotes
```

Present the distribution plan to the user. Cross-platform adaptation and publishing use the content agent's `adapt` and `publish` modes as separate invocations.

## Model Guidance

| Phase | Model | Rationale |
|-------|-------|-----------|
| Research dispatch (Agents A/B/C) | Haiku | Data gathering, not synthesis |
| Source synthesis | Sonnet | Merging and analysis needs quality |
| Report drafting | Sonnet (content agent) | Voice calibration requires Sonnet |
| Voice check | Sonnet (content agent) | Same |
