---
name: good-morning
model: sonnet
effort: medium
description: Present the daily operational briefing and start-of-day context. Use when the user says "good morning", "morning briefing", "what's today look like", "what do I have today", "morning rundown", "what's on my plate", "start of day", "weekly review", "weekly briefing", or "give me the weekly". Do NOT activate for casual mid-conversation "good morning" greetings when already deep in a task.
---

# Good Morning Briefing

Interactive companion to the overnight Cloud task. The briefing is pre-generated and saved to `Briefing.md` (root) and `Documents/Field-Notes/YYYY-MM-DD-Briefing.md` (archive). This skill reads, presents, and facilitates interactive drill-downs. It never generates the briefing itself.

## Decision Tree

### Branch A — Briefing exists

1. Read `Briefing.md` at the repo root.
2. If root copy is missing, try the dated archive: `Documents/Field-Notes/$(date +%Y-%m-%d)-Briefing.md`.
3. Validate: must contain a `# Good Morning` header and be >200 characters.
4. **Staleness check:** Extract the date from the `# Good Morning — YYYY-MM-DD` header. If it doesn't match today, flag it: "Heads up — this briefing is from [date], not today. The overnight batch may not have run. Want me to pull a live summary instead?"
5. If valid and fresh (or user accepts stale), present per the [Presenting](#presenting) section.
6. If invalid (empty, garbled, no header), treat as missing — fall through to Branch B.

### Branch B — Briefing missing or invalid

1. Check git log for overnight commit:
   ```bash
   git log --oneline -5 --grep="overnight: briefing"
   ```
2. If a commit exists for today's date: run `git pull origin main`, then retry reading `Briefing.md`. If still missing after pull, fall through to fallback.
3. If no overnight commit found: the Cloud task didn't run. Inform [Your Name] and offer inline fallback.

### Fallback (ephemeral, not saved)

Generate a lightweight briefing conversationally from live sources:
- Plane: `mcp__plane__list_projects` then `mcp__plane__list_work_items` per project
- Gmail: `mcp__claude_ai_Gmail__gmail_search_messages` for last 24h
- Git: `git log --oneline --since="yesterday"`
Note that this is ephemeral and won't persist. Recommend checking why the Cloud task didn't run.

## Presenting

1. **Jules one-liner opener** — Short, warm, match the day's energy. Examples:
   - "Morning. Coffee's metaphorical, briefing's real."
   - "Tuesday. Let's see what the fox dragged in."
   - "Happy Monday -- and I use 'happy' loosely."

2. **Render the briefing** — Display the full briefing markdown as-is. Don't summarize, truncate, or reformat.

3. **Decision queue check** — If section 4 (Decisions Pending) has items, after rendering: "You've got [N] pending decisions. Want to walk through them?" If empty, skip.

4. **Focus proposal** — If [Your Name] hasn't stated what he wants to work on, propose based on briefing section 2 (Today's Focus): "I'd start with [X]. Want that, or something else?"

## Decisions Walkthrough

When [Your Name] says "yes" to the decision queue prompt, or "let's do decisions":

1. Parse briefing section 4 for each decision item.
2. Present each as a Decision Card:
   `**[DECISION]** Summary | **Rec:** X | **Risk:** Y | **Reversible?** Yes/No`
3. Wait for verdict on each: **Approve / Reject / Defer / Discuss**.
4. On Approve or Reject: search Plane for the item (`mcp__plane__search_work_items` by title), then update status via `mcp__plane__update_work_item`. If no Plane ID found, note the verdict for manual update.
5. On Defer: note the deferral reason and move to next.
6. On Discuss: switch to advisory register, think through it with [Your Name], then return for verdict.

## Newsletter Drill-Down

When [Your Name] says "tell me more about [headline]" or asks about a specific newsletter item from section 7:

1. Search Gmail for the source newsletter: `mcp__claude_ai_Gmail__gmail_search_messages` using the newsletter name or sender.
2. Read the full message: `mcp__claude_ai_Gmail__gmail_read_message`.
3. Find the relevant section and expand it — full context, links, implications.
4. If Gmail is unavailable, restate the briefing excerpt with whatever additional context is available. Less depth, not broken.

## AI News Deep Dive

When [Your Name] says "what's happening with [topic]?" or wants to go deeper on an AI item:

1. Run 2-3 targeted WebSearch queries on the topic.
2. Synthesize findings — what happened, why it matters, implications for our work.
3. If the topic warrants sustained research, offer: "Want me to kick off a proper `/research` on this?"

## Improvement Radar Review

When [Your Name] wants to review improvement candidates (section 9), or says "show me the improvements":

1. Read today's improvement scan: Glob for `Documents/Field-Notes/YYYY-MM-DD-Improvement-Scan.md` (today's date).
2. If today's scan doesn't exist, find the most recent: `Documents/Field-Notes/*-Improvement-Scan.md`.
3. Walk through each Top 5 item. For each, [Your Name] decides:
   - **Action** — Create a Plane work item via `mcp__plane__create_work_item` with the improvement details.
   - **Defer** — Skip for now, will resurface in future scans.
   - **Dismiss** — Note dismissal. Append to `Documents/Field-Notes/Logs/improvement-scan-seen.jsonl` with `"dismissed": true`.
4. After the walkthrough, summarize: "Actioned N, deferred N, dismissed N."

## Taste Calibration

When [Your Name] says "I wanted to see X", "Y was noise", "more of this", "less of that", or gives editorial feedback on briefing content:

1. Append the feedback to `Documents/Field-Notes/Logs/AI-Section-Calibration.md` with today's date:
   ```
   ## YYYY-MM-DD
   - [feedback note]
   ```
2. Create the file if it doesn't exist.
3. Acknowledge briefly: "Noted. That'll shape future briefings."

## Morning Actions

After the interactive walkthrough, if any changes were made (decisions actioned, improvements created):

```bash
git add Documents/Field-Notes/Logs/AI-Section-Calibration.md
git add Documents/Field-Notes/Logs/improvement-scan-seen.jsonl
git commit -m "morning: walkthrough actions $(date +%Y-%m-%d)"
git push origin main
```

Only commit files that were actually modified. Stage specific files only.

## Follow-Up Handling

After presenting, handle these naturally:

### Focus synthesis
"What should I focus on?" / "What matters most?" — Re-read briefing section 2, synthesize into 2-3 crisp priorities with concrete next actions.

### Yesterday's briefing
"What happened yesterday?" / "Show me yesterday's briefing":
```bash
YESTERDAY=$(date -v-1d +%Y-%m-%d)
```
Read `Documents/Field-Notes/$YESTERDAY-Briefing.md`. If it doesn't exist, check git log for yesterday's activity.

### Retro proposals
"Show me the retro" / "What did the retro find?" — Read `Documents/Field-Notes/YYYY-MM-DD-Retro-Proposals.md` (today's date, fall back to most recent).

## Error Cases

- **Briefing.md missing + no overnight commit** — Cloud task didn't run. Offer ephemeral fallback from live sources. Don't save to disk.
- **Gmail MCP unavailable** — Newsletter drill-down degrades to restating briefing excerpt. Note "(Gmail unavailable)".
- **Plane MCP unavailable** — Decision walkthrough records verdicts but can't update Plane. List what needs manual update.
- **Improvement scan missing** — Skip the radar review, note it: "No improvement scan found -- overnight batch may not have run."
- **Empty briefing file** — Treat as missing (Branch B).
