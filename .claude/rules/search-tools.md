# Search Tool Routing

How to find information online. Applies to all contexts: ad-hoc questions, skill
execution, coding sessions, debugging, content work.

## Check Local First

Before reaching for web tools, check whether the answer is already in the repo:
- `Documents/Field-Notes/` for prior research and session reports
- `.claude/` for skills, rules, and configuration
- `Code/` for existing implementations and patterns

Web tools are for external information. Local search is faster and more relevant
for project-specific questions.

## Tool Selection

**WebSearch** (Brave-backed, built-in) is the default. Use it when nothing below
is a better fit. Free, fast, reliable — covers news, blogs, GitHub,
StackOverflow, and forums in one call.

**Reddit MCP** (search_reddit, get_post_details) is for community discussion
when you know which subreddit to target. Returns thread content with vote counts
and comments. Bad for broad topics spanning communities — use WebSearch instead.

**WebFetch** is for reading a known URL. Always include a descriptive prompt
telling it what to extract. Only tool for URL content extraction. Hook-blocked
on x.com/twitter.com — use `xurl search` instead.

## Routing by Answer Type

| What you need | Primary tool | Fallback |
|---------------|-------------|----------|
| Official API syntax, correct method signatures | WebSearch | — |
| Fix for a specific error message | WebSearch (for GitHub issues) | — |
| Recent changes, changelogs, release notes | WebSearch | — |
| Community opinions on a specific subreddit topic | Reddit MCP | WebSearch |
| Broad community sentiment across platforms | WebSearch | — |
| Comparison or tradeoff synthesis | WebSearch (for comparison articles) | — |
| Competitive intelligence, "what's X doing" | WebSearch | — |
| Content at a known URL | WebFetch with extraction prompt | — |
| Simple factual lookup | WebSearch | — |

## Combining Tools

Single-tool answers are fine for quick lookups. For deeper questions, layer:

1. **WebSearch + WebFetch**: Find the right page, then read it in full. Common
   for changelogs and documentation.

2. **Reddit MCP + WebSearch**: Raw community discussion, then verify claims
   with web search. Common in /research dispatch.

Don't stack tools for simple questions. One call that answers it is better than
three that triangulate.
