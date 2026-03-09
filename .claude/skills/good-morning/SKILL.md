---
name: good-morning
description: Present the daily operational briefing and start-of-day context. Use when the user says "good morning", "morning briefing", "what's today look like", "what do I have today", "morning rundown", "what's on my plate", "start of day", "weekly review", "weekly briefing", or "give me the weekly". Do NOT activate for casual mid-conversation "good morning" greetings when already deep in a task.
---

# Good Morning Briefing

Read (or generate) today's daily briefing and present it conversationally. If a shell script generates briefings, delegate to it rather than duplicating its logic.

## Decision Tree

### 1. Check for today's briefing

```bash
TODAY=$(date +%Y-%m-%d)
BRIEFING_FILE=~/your-workspace/Briefing.md
ls -la "$BRIEFING_FILE"
```

### 1b. Check Decision Queue

Check if Terrain.md has items in the `## Decision Queue` section. If yes, note them for inclusion in the briefing presentation (step 2A or fallback).

### 1c. Mobile Inbox Sweep

Check for a mobile inbox file (e.g., `~/your-workspace/Inbox-Mobile.md`) for content beyond the header comment. If there are entries:
1. Read the entries
2. Triage each into the appropriate Terrain.md section (Inbox, Decision Queue, etc.)
3. Clear the entries from the mobile inbox (keep the header)
4. Mention what was swept: "Pulled [N] items from your mobile inbox into Terrain."

If the file is empty (just the header), skip silently.

### 2A. Briefing exists — read and present

Read the file with the Read tool. Present it following the [Presenting](#presenting) section below.

### 2B. Briefing doesn't exist — check status, then generate

First check if a scheduled job ran and failed (e.g., a status file from the last run). Tell the user what went wrong before attempting to regenerate.

Then generate the briefing using your briefing generation script or command.

If it succeeds, read the generated file and present it.

If it fails, follow the [Fallback](#fallback) section.

## Deadline Classification

When the briefing includes deadlines, classify them:
- **Hard deadlines** — immovable dates with consequences (e.g., tax filing Apr 15)
- **Soft deadlines** — advisory timing, flexible (e.g., booking a service)
- **Reminders** — awareness items, no urgency (e.g., conference starts next week)

Focus on the most relevant/actionable. Don't list everything.

## Presenting

1. **Agent one-liner opener** — A short, warm greeting. Match the day's energy. Examples:
   - "Morning. Coffee's metaphorical, briefing's real."
   - "Tuesday. Let's see what's on the board."
   - "Happy Monday — and I use 'happy' loosely."

2. **Render the briefing** — Display the full briefing markdown as-is. Don't summarize or truncate.

3. **Dashboard pulse** — If you have a dashboard or monitoring command, fire it off while the user reads the briefing. Don't wait for output or comment on it — just open it for a quick visual scan alongside the briefing. If it fails, mention briefly and move on.

4. **Decision Queue** — If Terrain.md has items in `## Decision Queue`, surface them after the briefing: "You've got [N] pending decisions. Want to knock them out?" If the user says yes, present each as a Decision Card (`**[DECISION]** summary | Rec | Risk | Reversible? → Approve/Reject/Discuss`). If the queue is empty, skip this step.

5. **Staleness check** — After presenting, run the [Freshness Check](#freshness-check).

## New Briefing Sections

The briefing generator can include these additional signals (when data exists):
- **Decision Revisits** — Overdue and upcoming `revisit-by` dates from the decision log
- **System Health** — Missed wrap-ups, stale memory entries (>90 days), abandoned drafts (>7 days)
- **Missed Wrap-Ups** — Dates with git commits but no session report

Present them as-is when they appear in the briefing.

## Daily Housekeeping

Run these silently after presenting the briefing. Report findings only if issues are found.

### Content Mining (Pre-Computed)

If a content mining step runs in your morning automation, check for cached results:
```bash
TODAY=$(date +%Y-%m-%d)
ls ~/your-workspace/Documents/Content-Pipeline/01-Drafts/Seeds/$TODAY-Session-Mining.md 2>/dev/null
```
If a seed file exists, briefly mention it: "Mined yesterday's session — [N] content seed(s) saved." If no seed file exists, the orchestrator found nothing publishable — skip silently.

### File Placement Audit

Run any file placement or naming validation scripts you have. If violations are found, auto-fix them (rename files, move strays). Report what was fixed.

### Blocker Review

Read your blockers file if it exists. Flag any blockers older than 7 days as stale. If a pattern emerges (same blocker type recurring), note it as a Decision Card candidate for the queue.

### Daily Pattern Check

Scan the last 3 days of session reports and retro reports for recurring themes:
```bash
ls -t ~/your-workspace/Documents/Field-Notes/Logs/*Session-Report* | head -3
ls -t ~/your-workspace/Documents/Field-Notes/*Session-Retro* | head -3
```
Look for: same issue type appearing across multiple sessions, fixes that didn't stick, chronic infrastructure work crowding out customer-facing work. If a pattern is found, surface it in one line during the briefing.

## Freshness Check

Check when `Terrain.md` was last updated:

```bash
stat -f "%Sm" -t "%Y-%m-%d" ~/your-workspace/Terrain.md
```

If the file was last modified 3+ days ago, flag it:

> "Heads up — Terrain.md hasn't been touched since [date]. The briefing is only as fresh as its inputs. Want me to help update it?"

If it's fresh (updated within the last 2 days), say nothing about it.

## Follow-Up Handling

After presenting, the user may ask for follow-ups. Handle these naturally:

### Regenerate (`--force`)

If the user says "regenerate", "redo the briefing", "force regenerate", or similar:

1. **Confirm first** — "This'll overwrite today's existing briefing. Go for it?"
2. On confirmation, run the briefing generation command with a force flag.
3. Read and present the new briefing.

### Update Terrain

If the user says "update terrain", "update state doc", "update status", or wants to refresh the operating dashboard:

- Read `Terrain.md`
- Ask what changed or what needs updating
- Edit the file as directed
- Offer to regenerate the briefing afterward (since the inputs changed)

### Focus proposal (proactive)

After presenting the briefing, if the user hasn't stated what they want to work on, propose the highest-signal item from Terrain's Now section: "I'd start with [X]. Want that, or something else?"

Also: if recent session reports show no customer-facing output for 3+ days, mention it briefly. One line, not a lecture. The user can dismiss it.

### Focus synthesis

If the user asks "what should I focus on today?", "what matters most?", or wants a tighter summary:

- Re-read the briefing's "Now" and "Today's Focus" sections
- Synthesize into 2-3 crisp priorities with concrete next actions
- If the briefing doesn't have these sections, pull from Terrain.md directly

### Weekly review on demand

If the user says "weekly review", "weekly briefing", "give me the weekly":

1. Generate the weekly-format briefing using the appropriate command.
2. Read the generated file and present it following the [Presenting](#presenting) section. It will have the richer Monday/weekly format regardless of what day it is.

### Yesterday's report

If the user asks "what happened yesterday?" or "show me yesterday's briefing":

```bash
YESTERDAY=$(date -v-1d +%Y-%m-%d)
ls ~/your-workspace/Documents/Field-Notes/$YESTERDAY-Briefing.md
```

Read and present it if it exists. If not, check for a session report:

```bash
ls ~/your-workspace/Documents/Field-Notes/Logs/$YESTERDAY-Session-Report.md
```

## Fallback

If the briefing generation command fails (script error, API unavailable, network issue):

1. Show the error output so the user can see what went wrong
2. Offer to generate an inline briefing from the same inputs:
   - Read `Terrain.md`
   - Check yesterday's git log: `git log --oneline --since="yesterday 00:00:00" --until="today 00:00:00"`
   - Check for a monitor report if one exists
3. Generate the briefing conversationally using orientation-first sections (Orientation, Decision Queue, Approaching Deadlines, Leading Indicators, Yesterday, Today's Focus)
4. **Do not save to disk** — the inline fallback is ephemeral. Mention this so the user knows it won't persist.

## Error Cases

- **Terrain.md missing** — Generate the briefing anyway (git log and monitor report are still useful). Note the missing state doc and offer to create one.
- **Documents directory doesn't exist** — Create it manually: `mkdir -p ~/your-workspace/Documents/Field-Notes`
- **Garbled or empty briefing file** — If the file exists but is empty or malformed (no markdown headers, under 50 characters), treat it as missing and offer to regenerate.
- **API failures during fallback** — If even the fallback can't read Terrain, just summarize yesterday's git activity and mention the limitations.
