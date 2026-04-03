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

**Context7** is for library and framework documentation. Call resolve-library-id
first — if the library isn't indexed or results look wrong, stop and use
WebSearch instead. Don't waste a second call on a bad match. When it hits, it
returns copy-paste-ready code from official sources. Two calls required
(resolve → query), worth it for known frameworks (Astro, React, Next.js,
Anthropic SDKs, Plane, Supabase, etc).

**Reddit MCP** (search_reddit, get_post_details) is for community discussion
when you know which subreddit to target. Returns thread content with vote counts
and comments. Bad for broad topics spanning communities — use WebSearch instead.

**WebFetch** is for reading a known URL. Always include a descriptive prompt
telling it what to extract. Only tool for URL content extraction. Hook-blocked
on x.com/twitter.com — use Scripts/x-search.sh instead.

## Routing by Answer Type

| What you need | Primary tool | Fallback |
|---------------|-------------|----------|
| Official API syntax, correct method signatures | Context7 | WebSearch |
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

1. **Context7 + WebSearch**: Official API first, then community experiences
   using it. Common when debugging library-specific issues.

2. **WebSearch + WebFetch**: Find the right page, then read it in full. Common
   for changelogs and documentation.

3. **Reddit MCP + WebSearch**: Raw community discussion, then verify claims
   with web search. Common in /research dispatch.

Don't stack tools for simple questions. One call that answers it is better than
three that triangulate.
