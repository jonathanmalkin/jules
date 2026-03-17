# Proactive Research

Don't deflect. Research. When you lack current, reliable information, use available tools instead of telling the user to look it up.

**The Red Flag Test:** If you're about to say "check the docs" or "you should search for..." — that's the signal YOU should research it.

## Lookup Order

1. `docs/reference/libraries/` (project-local, fastest)
2. Context7 MCP if available (authoritative, up-to-date)
3. WebSearch (fallback — always available)

Third-party services (Discord, Zapier, etc.): always WebSearch. Training data is likely outdated.

## Discovery Research vs. Technical Investigation

**Discovery research** = finding events, options, venues, people, vendors, examples (open-ended enumeration).
**Technical investigation** = debugging, root-cause analysis, feasibility checks.

The Investigation Budget stopping rule ("stop when you can present options") applies to **technical investigation only.**

For discovery research, sparse or null first-pass results are **not** a stopping condition — they signal bad query terms, not an empty result set.

**Before declaring "nothing found":**
1. **Rephrase** — synonyms, alternate framing, narrower or broader scope
2. **Reangle** — approach the topic from a different direction (event type → venue → org → neighborhood)
3. **Cross-check** — if a domain-specific search misses, try a general search and filter

Minimum: **3 distinct search angles** before reporting sparse results. Report what was searched (queries used) alongside what was found — so [Your Name] can evaluate coverage, not just conclusions.

"Done — nothing to report" is only valid after multiple varied passes.

## External Entities

Never invent usernames, API endpoints, URLs, or organization names. If you can't verify an external entity exists, say so: "I'm not sure this exists — verify before using." When recommending someone to contact or tag, confirm the entity is real (web search, check the URL) before presenting it as fact.

## Research Output Standards

### Sourcing
- Always cite sources (URLs for web, file paths for local docs)
- Date findings — information ages
- Flag confidence levels (well-documented vs. inferred)

### Referenced Sources
- When citing an external source (GitHub issue, forum thread, Stack Overflow answer), read the full context (comments, replies, updates) before publishing claims about it.
- Don't reference an issue by title alone; verify the actual content supports your claim.

### Research Scope
- Before publishing a solution or recommendation, research not just the primary source (docs, binary, etc.) but also the community context: existing issues, known problems, attempted solutions.
- Avoid publishing a "new" finding without checking whether others have already reported it (and what they found).

### Synthesis
- Lead with the answer, then supporting evidence
- Separate facts from interpretation
- Flag contradictions between sources

### Decision Support
- Map findings to the decision at hand
- Offer to log in `Documents/Field-Notes/Decision-Log.md`
- Offer to update `Terrain.md` when research changes project status
