---
name: good-morning
effort: medium
description: Present the daily operational briefing and start-of-day context. Use when the user says "good morning", "morning briefing", "what's today look like", "what do I have today", "morning rundown", "what's on my plate", "start of day", "weekly review", "weekly briefing", or "give me the weekly". Do NOT activate for casual mid-conversation "good morning" greetings when already deep in a task.
---

# Good Morning Briefing

Interactive companion to the overnight batch. The briefing is pre-generated and saved to `Briefing.md` (root) and `Documents/Field-Notes/YYYY-MM-DD-Briefing.md` (archive). This skill reads, presents, and facilitates the interactive walkthrough. It never generates the briefing itself.

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
- Paperclip: `curl -sf "$PAPERCLIP_API_URL/api/companies/$PAPERCLIP_COMPANY_ID/issues?status=todo,in_progress" -H "Authorization: Bearer $PAPERCLIP_API_KEY"` for active issues
- Gmail: `Scripts/gmail-read.py --hours 24`
- Git: `git log --oneline --since="yesterday"`
Note that this is ephemeral and won't persist. Recommend checking why the overnight batch didn't run.

## Presenting

Structured walkthrough. Complete each step before moving to the next. Most mornings go straight through without looping — the iteration is there when needed, not forced.

### Step 1 — Overview

Jules one-liner opener.

**Pillars** (every morning, always — one bullet each):
- Restate the pillar description first, then connect it to today's reality.
- Purpose: do work that visibly impacts real people, and be known for it
- Profit: build reputation that opens revenue paths
- People: be around people I enjoy, regularly
- Health: maintain and deepen — the foundation is solid

**Project Overview** — one bullet per tracked module, always. Modules are Product, Infrastructure, Content, Speaking, Personal. If nothing moved, say so explicitly. Keep it scannable and bullet-first, not paragraph-first. Source from briefing's activity section.

Example format:
- **Product** — Interest Finder launched. Partner invite polished and deployed.
- **Infrastructure** — 1Password TCC prompts eliminated. Morning batch wake time fixed.
- **Speaking** — Nothing moved yesterday.

**Quiz Analytics** — Parse the `<!-- QUIZ_DATA -->` JSON block from the briefing. If present, render:

1. **Metric cards** (table format, one row):
   - Starts: current value + day-over-day delta % (e.g., "385 starts (+12%)")
   - Completion Rate: current + delta in pp (e.g., "33% completion (-2.1pp)")
   - Email Signups: current + delta (e.g., "12 signups (+3)")
   - Partner Invites: current value
   - Interest Finder: started / completed / results viewed + ratings breakdown

2. **Funnel** — render the `funnel` array as a bullet list with dropoff percentages between each step. If entries include a `group` field, present Quiz first and then any Interest Finder branch separately under the same funnel heading:
   ```
   - Landing Page: 385
   - Clicked Take Quiz: 167 (43% of landing)
   - Consent Given: 161 (96% of clicks)
   - Quiz Started: 159 (99% of consent)
   - Stage 2: 128 (81% of started) <- biggest dropoff
   - Results: 127 (99% of stage 2)
   - Survey Done: 108 (85% of results)
   - Email Signup: 12 (11% of survey)
   - Partner Invite: 1 (0.9% of survey)
   - Interest Finder CTA: 6
   - Interest Finder Started: 6 (100% of CTA)
   - Interest Finder Completed: 6 (100% of started)
   - Interest Results Viewed: 6 (100% of completed)
   ```
   Flag the largest dropoff step.

3. **Archetype distribution** — top 3 from the `archetypes` array with percentages.

4. **Survey highlights** — top motivation, top challenge, and any notable `wish_existed` free-text responses, using bullets instead of prose wherever possible.

If `QUIZ_DATA` block is missing from the briefing, show: "Analytics not in today's briefing — will be live tomorrow."

### Step 2 — Timeline

Consolidates deadlines, waiting-on items, and actions needed into one date-sorted view. Three categories in a single table:

**Deadlines** — items due within 7 days. Flag today/overdue with warning emoji.
**Waiting On** — external blockers with expected resolution dates (ball not in [Your Name]'s court).
**Actions Needed** — things only [Your Name] can do (reviews, approvals, manual tasks).

All entries in one table sorted by date, with a category column. Link: "Full details in [today's briefing](#deadlines)."

### Step 3 — Decisions

Present ALL decisions from the briefing's Decisions Pending section as a single batched AskUserQuestion. Each decision must be fully self-contained:
- What triggered it
- What changes if approved vs rejected
- Recommended option labeled "(Recommended)"
- Risk + reversibility

Link: "Full context in [today's briefing](#decisions)."

After verdicts: act immediately — update Paperclip issue statuses, create issues, note manual follow-ups.

### Step 4 — Proposals

Separate batched AskUserQuestion — different register from strategic decisions. Two sources combined:

**Retro proposals** — Read `Documents/Field-Notes/YYYY-MM-DD-Retro-Proposals.md` (today, fall back to most recent). Each proposal: what it changes, why, config delta if applicable, recommendation. Options: **Approve / Reject / Defer**.

**Improvement radar proposed changes** — from the briefing's Improvement Radar section, surface items that recommend adoption or have actionable config changes. Each item: what it changes, why, recommendation. Options: **Adopt / Defer / Dismiss**.
- Adopt → create Paperclip issue
- Dismiss → append to `Documents/Field-Notes/Logs/improvement-scan-seen.jsonl` with `"dismissed": true`

Links: "Full retro detail in [today's briefing](#retro-proposals). Full improvement scores in [today's briefing](#improvement-radar)."

On Approve (retro): queue for implementation (not done during morning).

Skip this step silently if no retro file exists and no improvement items have proposed changes.

### Step 5 — Pending Review

Items with status `in_review` in Paperclip. Show each with enough context to decide. This step reviews existing issues only; do not create new Paperclip issues from session-report open items during the morning flow.
- **Cancel** — PATCH status to `cancelled`
- **Done** — PATCH status to `done`
- **Schedule** — assign to project + set priority + move to `todo`

Link: "Full list in [today's briefing](#pending-review)."

Skip if empty.

### Step 6 — Day Plan + Content Ops + Iterate

Synthesize everything above into a concrete recommendation for today:
- 2-3 priorities in order
- First action for each (specific enough to start immediately)
- Flag any conflicts or tradeoffs

If content is part of today's work, overlay a content-ops recommendation:

1. Generate or refresh the daily content packet:
   ```bash
   python3 .claude/scripts/generate-content-packet.py --stdout
   ```
2. Surface:
   - one recommended anchor article
   - one LinkedIn post topic
   - one X original topic
   - recent source highlights from actual work
3. If the packet is thin, ask one prompt from the packet before recommending content work.
4. If [Your Name] wants engagement work, recommend:
   - `watch-contacts` for X reply scouting
   - manual-first LinkedIn engagement based on tracked accounts and current priorities

Then: "Does this feel right, or do you want to adjust anything?"

If [Your Name] wants to revisit a section, loop back — this is a dialogue, not a one-way presentation. Most days this step closes the morning. Occasionally it surfaces something that needs another pass at decisions or priorities. Follow the thread.

### Step 7 — Newsletters & AI Headlines

Show only Must-Read items (1-3 max) with one-liner + link each. Then: "Full newsletter list in [today's briefing](#newsletters)."

If not in briefing, pull live from Gmail:
```bash
python3 Scripts/gmail-read.py --newsletters --hours 24
```

## Decisions Walkthrough

When [Your Name] says "let's do decisions" mid-session or returns to decisions:

1. Parse briefing Decisions Pending section for each item.
2. Batch all decisions into a single AskUserQuestion with full context per decision.
3. On Approve/Reject: search Paperclip (`curl -sf "$PAPERCLIP_API_URL/api/companies/$PAPERCLIP_COMPANY_ID/issues?q=<keyword>" -H "Authorization: Bearer $PAPERCLIP_API_KEY"`), update status via `curl -sf -X PATCH "$PAPERCLIP_API_URL/api/issues/<issueId>" -H "Authorization: Bearer $PAPERCLIP_API_KEY" -H "Content-Type: application/json" -d '{"status":"<new-status>"}'`. If no issue found, note it.
4. On Defer: note reason, move on.
5. On Discuss: advisory register, think it through, return for verdict.

## Newsletter Drill-Down

When [Your Name] says "tell me more about [headline]" or asks about a specific item:

1. Search Gmail: `python3 Scripts/gmail-read.py --hours 48` and grep for the newsletter name or sender.
2. Expand the relevant section — full context, links, implications for our work.
3. If Gmail unavailable: restate briefing excerpt with available context.

## AI News Deep Dive

When [Your Name] says "what's happening with [topic]?":

1. Run 2-3 targeted WebSearch queries.
2. Synthesize: what happened, why it matters, implications for our work.
3. If sustained research warranted: "Want me to kick off a `/research` on this?"

## Improvement Radar Review

When [Your Name] says "show me the improvements":

1. Read today's improvement scan: Glob for `Documents/Field-Notes/YYYY-MM-DD-Improvement-Scan.md`.
2. Fall back to most recent if today's missing.
3. Walk through Top 5. For each: Action / Defer / Dismiss.
4. Summarize: "Actioned N, deferred N, dismissed N."

## Taste Calibration

When [Your Name] gives editorial feedback ("I wanted to see X", "Y was noise", "more of this"):

1. Append to `Documents/Field-Notes/Logs/AI-Section-Calibration.md`:
   ```
   ## YYYY-MM-DD
   - [feedback note]
   ```
2. Acknowledge: "Noted. That'll shape future briefings."

## Morning Actions

After walkthrough, commit any modified files:

```bash
git add Documents/Field-Notes/Logs/AI-Section-Calibration.md
git add Documents/Field-Notes/Logs/improvement-scan-seen.jsonl
git commit -m "morning: walkthrough actions $(date +%Y-%m-%d)"
git push origin main
```

Stage specific files only. Only commit files that were actually modified.

## Follow-Up Handling

### Focus synthesis
"What should I focus on?" — Synthesize Day Plan output from Step 6 into 2-3 crisp priorities with concrete next actions.

### Content packet
"What should I write?" / "Give me the content plan for today":

1. Run:
   ```bash
   python3 .claude/scripts/generate-content-packet.py --stdout
   ```
2. Present:
   - recommended anchor article
   - recommended LinkedIn post
   - recommended X post
   - recent proof points and source highlights
3. Ask one grounding prompt if the packet needs [Your Name]'s judgment.
4. If useful, recommend the next drafting move in `Documents/Content-Pipeline/Drafts/`.

### Yesterday's briefing
"What happened yesterday?":
```bash
YESTERDAY=$(date -v-1d +%Y-%m-%d)
```
Read `Documents/Field-Notes/$YESTERDAY-Briefing.md`. Fall back to git log.

### Retro proposals
"Show me the retro" — Read `Documents/Field-Notes/YYYY-MM-DD-Retro-Proposals.md` (today, fall back to most recent).

### Quiz drill-down
"How's the quiz doing?" / "Tell me more about the analytics":
1. Parse the `<!-- QUIZ_DATA -->` JSON block from the briefing.
2. Render full metric cards with day-over-day deltas (starts, completion rate, email signups, partner invites).
3. Render complete funnel with dropoff analysis — flag the biggest dropoff and any anomalies vs baseline (76.6% completion, 4.6% email rate).
4. Show full archetype distribution (all archetypes, not just top 3) with percentages and counts.
5. Show survey data: experience level breakdown, motivation breakdown, biggest challenge breakdown, and `wish_existed` free-text responses.
6. Compare to prior day if `prior` values exist in QUIZ_DATA.
7. Link to HTML report if it exists: `open ~/Active-Work/Documents/Field-Notes/$(date +%Y-%m-%d)-Analytics-Report.html`
8. Offer: "Want me to pull live data? I can run `make quiz-report-latest` for a fresh snapshot."

## Error Cases

- **Briefing.md missing + no overnight commit** — Offer ephemeral fallback. Don't save to disk.
- **Gmail unavailable** — Newsletter step: note "(Gmail unavailable)", use briefing AI section only. Drill-down degrades to briefing excerpt.
- **Paperclip unavailable** — Record verdicts, list what needs manual Paperclip update.
- **Improvement scan missing** — Skip Step 4 improvement items, note it.
- **Analytics missing from briefing** — Show placeholder, note it'll be live when overnight batch includes it.
- **Empty briefing file** — Treat as missing (Branch B).
- **Retro file missing** — Skip retro portion of Step 4 silently.
