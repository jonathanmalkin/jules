---
name: wrap-up
description: Use when user says "wrap up", "close session", "end session", "wrap things up", "close out this task", or invokes /wrap-up — runs end-of-session checklist for shipping, memory, and self-improvement
---

# Session Wrap-Up

Run four phases in order. All phases auto-apply without asking; present a consolidated report at the end.

## Phase 1: Quick Issue Capture (Conditional)

Do a **quick session health check** (inline, no subagents):

1. Were there errors, failed tool calls, or retries during this session?
2. Were there compliance failures (guidance existed but wasn't followed)?
3. Were there workarounds or hacky fixes?
4. Was there confusion, misunderstanding, or significant course corrections?

**If YES to any:** Extract issues and save a structured issue file. Do NOT run `/retro-deep` or spawn subagents. The heavy analysis runs in the daily morning batch.

Scan the **entire conversation** for issues across these categories:
- **Repeated errors** — Same root cause 2+ times
- **Compliance failures** — Guidance existed but wasn't followed
- **Missing guidance** — Issue arose with no existing guidance covering it
- **Workarounds** — Hacky fix where a proper solution likely exists
- **Knowledge gaps** — Information needed but unavailable or outdated

Save to `Documents/Field-Notes/Logs/YYYY-MM-DD-Session-Issues.md` (append if file exists from an earlier session):

```markdown
# Session Issues — YYYY-MM-DD (Session N)

## Issues Found

### 1. [Category] Brief description
- **Severity:** high/medium/low
- **Occurrences:** N
- **Context:** What happened — include error messages, file paths, sequence of attempts. Rich enough for someone with no conversation context to understand the issue and cross-reference against config files.
- **What was tried:** Solutions attempted, in order
- **What worked:** Final resolution (if any)

### 2. ...

## Determinism Candidates
- [description of mechanical instruction that should be a script]
```

**IMPORTANT:** Write rich context for each issue. Error messages, file paths, what was tried and in what order, why workarounds were needed. This is the only record the daily batch job will have — thin descriptions produce thin analysis.

**If high-severity issues found** (compliance failures, blocked progress): note in the session report "Recommend running `/retro-deep` for immediate analysis" so [Your Name] can trigger it manually if needed.

**If NO to all (clean session):** Skip issue capture. Note "Clean session — no issues" in the session report. Still run the determinism scan below.

After issue capture (or skip), run the **determinism scan** on this session:

Were any new instructions written to skills, rules, or CLAUDE.md? For each: is it mechanical (same input, same output, no judgment)? If yes, flag it as a script candidate. Apply the test: "If 10 different LLMs got this instruction, would they all do exactly the same thing?" If yes, create the script in `.claude/scripts/` and update the instruction to call it. Also add determinism candidates to the issue file if one was created.

## Phase 1.5: Content Seed Capture

Scan the session for content-worthy moments. This should take ~60 seconds. No drafting, no voice checking, no agent delegation.

**What qualifies as content-worthy:**
- A problem solved that other builders would hit
- A pattern or technique discovered during the session
- A tool, script, or workflow built that's generalizable
- A decision made with interesting reasoning
- A surprising finding or counterintuitive result

**If seeds found:** Write to `Documents/Content-Pipeline/01-Drafts/Seeds/YYYY-MM-DD-Session-Mining.md`. Append if the file already exists from an earlier session today.

**Seed format:**

```markdown
### [Action-oriented title]
**Platform:** [target subreddit or X, with brief reasoning]
**Hook:** [2-3 sentences. The "why this matters" angle.]
**Context:** [1 paragraph. What happened in the session, what the struggle was, what made this interesting. This is the material the overnight expansion job needs to write a real story, not a summary.]
**Key detail:** [The specific technical detail, command, error message, or insight that makes this post concrete rather than generic.]
```

The Context and Key Detail fields carry the session knowledge that won't exist overnight. Write them rich.

**If nothing content-worthy:** Skip. Note "No content seeds" in the session report. Most debugging or maintenance sessions won't produce seeds.

## Phase 1.75: Build Log Tweet (Conditional)

If the session produced concrete outcomes (code shipped, features built, decisions made, content published), draft a build log tweet.

**Skip if:** Session was purely conversational, research-only, or maintenance with no visible outcome.

**Format:**
```
What I built today with Claude Code:

[1-2 sentence summary of the main outcome]

[Optional: one specific detail that makes it interesting]

#BuildInPublic #ClaudeCode #AI
```

**Process:**
1. Draft the tweet (max 280 chars)
2. Include in the session report under "## Build Log Tweet"
3. The tweet is a DRAFT — it gets posted via the tweet scheduler after [Your Name] reviews, or auto-posted if standing order is earned

**Tone:** Casual, concrete, no hype. "Here's what got done" energy. The tweet should make another builder think "oh that's cool" or "I should try that."

## Phase 2: Session Report

Create the session report:

```bash
bash ~/workspace/.claude/scripts/session-report-scaffold.sh
```

Fill in the sections based on the conversation:

```markdown
# Session Report — [date]

**Session focus:** [1 sentence — what was the main goal?]

## What Got Done
- [Concrete outcomes — shipped code, created files, decisions made]
- **Signal check:** [Did this session move something toward a real person? Deployed, published, emailed — or internal-only?]

## Decisions Made
- [Brief — full rationale lives in Decision-Log.md]

## Open Items
- [Unfinished, blocked, or needs attention next session]

## Commitments Made
- [**What** — by when — to whom (if applicable)]

## Context for Next Session
- [WIP state, gotchas, things to watch for]

## Compaction Health
[Output from: bash .claude/scripts/compaction-stats.sh --recent 1]
```

Run `bash .claude/scripts/compaction-stats.sh --recent 1` and include its output in the report. Skip empty sections. Include the autonomy report (Goal 4) — decisions made autonomously, standing orders exercised. Skip the autonomy section if nothing to report.

## Phase 3: Update Terrain

Re-read `Terrain.md` before editing (Syncthing may have modified it).

1. Remove completed items — don't log them (session report already did)
2. Update project statuses and task items
3. Resolve answered questions, add new ones
4. Log significant decisions to `Documents/Field-Notes/Decision-Log.md` with `**Status:** revisit-by-YYYY-MM-DD` where applicable

Only touch sections affected by the session. If nothing changed, say "Terrain is current."

5. Update Jules Queue:
   - Check off any queue items completed during this session
   - Add identified follow-on items with `auto` or `propose` tags
   - Format: `- [ ] **Item** — context | auto | est:Xm *(queued YYYY-MM-DD)*`
   - If marking items `propose`, briefly note why ("needs browser" / "might be strategic pivot" / etc.)
   - Items default to `propose` unless clearly within authorized categories

## Phase 4: Ship

```bash
bash ~/workspace/.claude/scripts/wrap-up-ship.sh "Wrap-up: <brief description of session>"
```
