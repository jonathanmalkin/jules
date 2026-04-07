---
name: search-history
effort: medium
description: "Search structured session documents: session reports, issues, retros, memory syntheses, plans, research docs, Decision Log, and System Evolution. Use when user says 'search history', 'search sessions', 'find session', 'when did we', 'what session', 'session where', 'search logs', 'find that plan', 'what plan did we write', 'look through past sessions', 'did we ever discuss', 'have we talked about', 'what was the decision about', 'check field notes', or wants to find past session context."
---

# Search History — Structured Document Search

Search structured wrap-up output and field notes across eight document types. Complementary to `claude-history` (which searches raw conversation JSONL).

## Step 1: Parse Query

Extract from the user's input:
- **Keywords**: the search terms (everything that isn't a flag)
- **`--type` filter** (optional): one of `reports`, `issues`, `retros`, `memory`, `plans`, `research`, `decisions`, `evolution`, or `all`. Default: `all`.
- **`--since YYYY-MM-DD`** (optional): only include files dated on or after this date. Applies to all dated file types (reports, issues, retros, memory, plans, research). Does not apply to Decision Log or System Evolution (single files, always searched in full). Default: no date filter.

If the input is just `/search-history` with no keywords, ask what to search for.

## Step 2: Search Targets

Eight document types with their glob patterns:

| Type Key | Label | Glob Pattern | Dated? |
|----------|-------|-------------|--------|
| `reports` | Session Reports | `Documents/Field-Notes/Logs/*-Session-Report*.md` | Yes |
| `issues` | Session Issues | `Documents/Field-Notes/Logs/*-Session-Issues*.md` | Yes |
| `retros` | Session Retros | `Documents/Field-Notes/Logs/*-Session-Retro*.md` | Yes |
| `memory` | Memory Syntheses | `Documents/Field-Notes/Logs/*-Memory-Synthesis*.md` | Yes |
| `plans` | Plans | `Documents/Field-Notes/Plans/*.md` | Yes |
| `research` | Research Docs | `Documents/Field-Notes/Research/*.md` | Yes |
| `decisions` | Decision Log | `Documents/Field-Notes/Decision-Log.md` | No |
| `evolution` | System Evolution | `Documents/System/System-Evolution.md` | No |

When `--type` is specified, search only that type. Otherwise search all eight.

## Step 3: Execute Search

For each active document type:

1. **Glob** to find matching files.
2. For dated types (reports, issues, retros, memory, plans, research): if `--since` is set, filter filenames by date prefix (`YYYY-MM-DD` >= since date). Files without a parseable date prefix are included.
3. **Grep** for keywords across the matched files. Use case-insensitive search. Request `content` output mode with 2 lines of context (`-C 2`).
4. For Decision Log and System Evolution (single files): `--since` is NOT applied — always search the full file.

Run searches for independent document types in parallel where possible.

## Step 4: Present Results

### Count-first mode

If total matches exceed 10 across all types, present a count summary first:

```
Match counts:
  Session Reports: 4 matches (3 files)
  Plans: 8 matches (5 files)
  Research Docs: 2 matches (1 file)
  Decision Log: 1 match
```

Then ask: "Want to see all results, or drill into a specific type?"

If the user says "all" or the total is <= 10, show full results immediately.

### Full results

Group results by document type. Within each group, sort newest-first (filename date prefix makes this natural).

Format each match as:
```
**<Document Type>**
`file_path:line_number` — <matching line with context>
```

**Multi-session days:** When multiple files share the same date prefix (e.g., `2026-03-18-Session-Report.md` and `2026-03-18-Session-Report-3.md`), note it: "3 reports for 2026-03-18."

### Zero results

If no results found across all types:
1. Suggest broadening keywords or removing `--type` filter.
2. Offer the exact `claude-history` fallback command:
   ```
   claude-history -L
   ```
   Then search interactively for the keywords. This searches raw conversation transcripts, which may contain what the structured docs missed.

## Step 5: Synthesis (optional)

After presenting matches (or after count-first drill-down), offer:

> "Want me to read the top matches and summarize the timeline?"

If the user accepts, read the 3-5 most relevant files (highest match density or most recent), then write a 1-2 paragraph narrative synthesis: what happened, when, and how the topic evolved across sessions. This turns search-history from a search tool into a narrative reconstruction tool.

## Step 6: Follow-Up

After presenting results, offer:
- "Want me to read the full file for any of these?"
- "Want to narrow the search with `--type` or `--since`?"
- "Want me to summarize the timeline across these matches?"

## Disambiguation

This skill searches **structured wrap-up output and field notes** (session reports, plans, research docs, decisions, evolution). For searching **raw conversation transcripts**, use `claude-history` (Homebrew tap — `claude-history -L`, then search interactively).
