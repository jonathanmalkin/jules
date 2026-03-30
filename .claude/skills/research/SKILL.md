---
name: research
model: sonnet
effort: high
description: >
  Standalone research with persistence. Dispatches parallel research agents, synthesizes sources,
  produces structured findings with living documents for cross-session pickup.
  Use when user says "research", "look into", "deep dive", "investigate", or invokes /research.
  Do NOT use for quick lookups (just answer directly).
user-invocable: true
---

# Research

Standalone research with living documents. Dispatches parallel agents, synthesizes sources, persists findings for cross-session pickup.

**You are a fox doing deep investigation.** Thorough, source-driven, opinionated about what matters. Not a Wikipedia summary machine.

## Cross-Session Persistence

Research documents live at `Documents/Field-Notes/Research/YYYY-MM-DD-<Topic-Slug>.md`. When a research request arrives:

1. Check `Documents/Field-Notes/Research/` for an existing file matching the topic (fuzzy match on filename)
2. If found: read it, present the existing document, and offer: "Continue from [date] or start fresh?"
3. If not found: proceed to Phase 1

"Continue research on X" resumes from the Open Questions section of the existing document.

## Phase 1: Topic Selection

If the user provides a topic directly (e.g., `/research multi-agent systems`), use that.

If no topic provided, ask: "What would you like me to research?"

Once a topic is confirmed, define a one-sentence scope: "Researching: [topic] — specifically [angle]." Confirm with the user if the scope is ambiguous.

## Research Tool Selection

Pick the right tool for the query type:

See `.claude/rules/search-tools.md` for the full tool routing guide. Research-specific additions:

| Query Type | Tool | Why |
|-----------|------|-----|
| Community discussion, opinions, experiences | Reddit MCP (`search_reddit`, `get_post_details`) | Direct access to threads and comments |
| General web search, news, blog posts | WebSearch (built-in) | Broad coverage, keyword-based |
| Synthesized answer, tradeoff comparison | Perplexity search | Combines multiple sources with citations |
| Library docs, API references | Context7 (`resolve-library-id` → `query-docs`) | Returns actual docs, prevents hallucinated APIs |
| Full page content extraction | WebFetch with a descriptive prompt | Prompt parameter guides extraction |

If Context7 or Perplexity aren't configured, fall back to WebSearch + WebFetch. Don't block on missing tools.

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
- 3-angle minimum (3 distinct search queries before reporting sparse results)

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

**Context7** for library/framework docs:
- If topic involves a known library, resolve-library-id → query-docs
- If miss or not a library topic, skip to WebSearch

**WebSearch** for:
- Official documentation on the topic
- Blog posts from recognized practitioners
- GitHub repos/issues with relevant implementations

**Perplexity search** for synthesis questions:
- "What are the tradeoffs between X and Y?"
- "What's the current best practice for Z?"

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

Search [Your Name]'s workspace for first-party experience on the topic.

**Search in:**
- `Documents/Field-Notes/` — briefings, retros, research notes
- `Documents/Content-Pipeline/00-Seeds/` — session-mined seeds
- `.claude/plans/` — prior plans touching this topic
- `Code/` — implementations, configs, scripts
- `.claude/` — skills, rules, agents (the [Agent Name] infrastructure itself)

Return format:
```
## First-Party Experience
- [File path] — [what [Your Name]'s setup does differently]
- ...

## Production Data Points
- [Specific metric, config, or outcome from the codebase]
- ...
```

## Phase 3: Source Synthesis

Use a Sonnet subagent to merge all research outputs. The synthesis agent should:

1. Deduplicate sources across agents
2. Categorize findings: consensus views, contradicting positions, coverage gaps
3. Identify where [Your Name]'s production experience adds something the internet doesn't have
4. Flag sources older than 6 months as potentially stale

Present a brief summary to [Your Name]:
```
Found N sources across community/docs/local. Key tension: [main disagreement]. Your edge: [what your setup reveals that others don't have]. Proceeding to draft — say "show sources" to review the full inventory.
```

Save the full source inventory alongside the research document.

**Source review is opt-in.** Don't wait for approval unless [Your Name] asks to see sources. Proceed to drafting.

## Phase 4: Report Drafting

Draft a structured research report using a Sonnet subagent with:

1. The synthesized research from Phase 3
2. The report template from `references/report-template.md` (if available)
3. Technical register — practitioner voice, not academic
4. A critical constraint: the "What I Think" section MUST reference specific files, configs, metrics, or experiences from [Your Name]'s actual setup (from Agent C's findings). No generic observations dressed up as personal experience.

## Phase 5: Voice Check

Review the draft for AI writing patterns:
- Opening and close get full [Your Name] voice treatment (problem-I-hit opener, wry close)
- Analytical middle can be more informational (findings are data, not personality)
- Check against anti-patterns: em-dashes, hedge words, preamble, corporate chatbot

## Phase 6: Save + Present

1. Write the finished report to `Documents/Field-Notes/Research/YYYY-MM-DD-<Topic-Slug>.md`
2. Save research artifacts alongside:
   - `Documents/Field-Notes/Research/<Topic-Slug>/sources.md` — full source inventory
   - `Documents/Field-Notes/Research/<Topic-Slug>/research-notes.md` — merged subagent outputs

3. Present a 3-5 bullet summary of key findings.

4. Offer chain options when appropriate:
   - "This is starting to look like a decision. Want to run /think?"
   - "There's enough here to scope an implementation. Want to run /build?"
   - "Ready to turn this into content? Want to run /write?"
   - "Want to go deeper on [specific sub-topic]?"
   - "I'll save this — pick it up later with 'continue research on [topic]'."

Don't push chaining. Offer it once. [Your Name] decides.

## Model Guidance

| Phase | Model | Rationale |
|-------|-------|-----------|
| Research dispatch (Agents A/B/C) | Haiku | Data gathering, not synthesis |
| Source synthesis | Sonnet | Merging and analysis needs quality |
| Report drafting | Sonnet | Voice and structure |
| Voice check | Inline | Quick pass, no subagent needed |
