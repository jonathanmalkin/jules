---
name: wrap-up
effort: high
description: "End-of-session checklist: issue capture, session report, ship. Triggers on 'wrap up', 'close session', 'end session', 'wrap things up', or /wrap-up. Do NOT use mid-session or for task completion without ending the session."
user-invocable: true
---

# Session Wrap-Up

Run three phases in order. All phases auto-apply without asking; present a consolidated report at the end.

## Phase 1: Issue Capture (Conditional)

Do a **quick session health check** (inline, no subagents):

1. Were there errors, failed tool calls, or retries during this session?
2. Were there compliance failures (guidance existed but wasn't followed)?
3. Were there workarounds or hacky fixes?
4. Was there confusion, misunderstanding, or significant course corrections?

**If YES to any:** Extract issues and save a structured issue file.

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
- **Context:** What happened — include error messages, file paths, sequence of attempts. Rich enough for someone with no conversation context to understand the issue.
- **What was tried:** Solutions attempted, in order
- **What worked:** Final resolution (if any)

### 2. ...

## Determinism Candidates
- [description of mechanical instruction that should be a script]
```

**Write rich context for each issue.** Error messages, file paths, what was tried and in what order, why workarounds were needed. This is the only record available for later analysis.

**If NO to all (clean session):** Skip issue capture. Note "Clean session — no issues" in the session report.

## Phase 2: Session Report

Create the session report:

```bash
bash .claude/scripts/session-report-scaffold.sh
```

Fill in the sections based on the conversation:

```markdown
# Session Report — [date]

**Session focus:** [1 sentence — what was the main goal?]

## What Got Done
- [Concrete outcomes — shipped code, created files, decisions made]

## Decisions Made
- [Brief — log significant decisions to Decision-Log.md if applicable]

## Open Items
- [Unfinished, blocked, or needs attention next session]

## Commitments Made
- [**What** — by when — to whom (if applicable)]

## Context for Next Session
- [WIP state, gotchas, things to watch for]

## Handoff
**Status: Complete** — No additional work needed.
```

**OR** if the session's stated focus has unfinished work:

```markdown
## Handoff
**Status: Continues**
**Resume prompt:** `<exact prompt to paste into a fresh session>`
**What's left:** [brief list of remaining items]
**Blockers:** [anything that must happen before resumption, or "None"]
```

**Handoff rules:**
- **Always present.** Every session report gets a Handoff section.
- **Binary:** Complete or Continues. No ambiguity.
- **Complete** = the session's stated focus is resolved. Follow-on work in Open Items is normal and doesn't change the status.
- **Continues** = the session's stated focus has unfinished work. The resume prompt must be specific enough for a fresh session with no prior context. Reference specific files (plans, research docs, specs) — don't rely on "read the session report."

Skip empty sections (except Handoff — always include it).

## Phase 3: Ship

```bash
bash .claude/scripts/wrap-up-ship.sh "Wrap-up: <brief description of session>"
```

After shipping, always end with the Handoff status stated directly in the conversation:

> **Handoff: Complete** — No additional work needed.

or

> **Handoff: Continues** — [what's left + resume prompt]

This is the last thing [Your Name] sees. Don't skip it.
