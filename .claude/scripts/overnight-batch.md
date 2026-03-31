# Overnight Batch — Cloud Scheduled Task Prompt

You are running as a Cloud scheduled task — autonomous, no human interaction. Do NOT use plan mode — execute directly without requiring approval. Execute four phases sequentially. If any data source fails, note it and continue. Never skip a section silently.

Today's date: use `date +%Y-%m-%d` via Bash.

---

## Phase 1: Retro + Memory

Analyze yesterday's session issues. Produce proposals, not direct edits. Think deeply — read full context, check history, score against multiple objectives.

### Steps

1. **Find session issues.** Glob for `Documents/Field-Notes/Logs/*-Session-Issues.md` dated yesterday (or most recent if yesterday has none). If no issues found, skip to Phase 2 — write "No session issues found" to the retro report.

2. **Load context.** Read:
   - `CLAUDE.md` (current behavioral config — note its line count for the size gate)
   - `Documents/Field-Notes/Logs/fix-lineage.jsonl` (prior fix history)
   - The session issues file(s) from step 1

3. **Analyze each issue.** For each issue in the file:
   - Read the actual files mentioned in the issue (not just the issue description)
   - Classify severity: `blocked-progress` or `caused-friction`
   - Count occurrences: `git log --all --oneline --grep="<issue-keyword>" -- Documents/Field-Notes/Logs/*Session-Issues*` — count how many session-issue files mention similar problems
   - Check fix lineage: was a fix previously proposed or applied for this issue class?

4. **Apply 3-occurrence threshold.** Issues with <3 occurrences go to "Watching" — log them but don't propose a fix. Issues with 3+ occurrences get a proposal.

5. **Classify fix layer.** For each proposal:
   - Mechanical/procedural (always do X) → Script or hook
   - Contextual judgment (do X when Y) → CLAUDE.md guidance
   - Pre/post action gate (block X, require Y) → Hook
   - **Check lineage:** if a soft fix (CLAUDE.md) was previously applied and the issue recurred, escalate to script/hook

6. **Subtraction scan.** For each section in CLAUDE.md:
   - Search `git log` for related session issues in the last 14 days
   - If no related issues in 14 days, mark as removal candidate
   - Classify: did our fix cause it to stop recurring, or did the underlying system change (e.g., Claude Code update)?
   - If the system changed, the fix is dead weight — propose removal

7. **Score each proposal** using this template:
   - **Severity:** blocked-progress / caused-friction
   - **Recurrence count:** N sessions (dates)
   - **Config delta:** +N / -N lines (net)
   - **Conflict check:** Does this contradict an existing CLAUDE.md section? Y/N — which
   - **Prior fix history:** None / Previously proposed DATE / Applied DATE — recurred/resolved

8. **CLAUDE.md size gate.** Count lines in CLAUDE.md. If >500 lines: only net-negative (removal) proposals pass. No additive proposals until below threshold. Report current count vs 500-line budget.

9. **Write retro proposals** to `Documents/Field-Notes/YYYY-MM-DD-Retro-Proposals.md`:
   ```
   # Retro Proposals — YYYY-MM-DD

   ## Metrics
   - Issues reviewed: N
   - Patterns detected: N
   - Proposals: N (N additions, N removals)
   - Watching (< 3 occurrences): N
   - Net config delta: +N / -N lines
   - CLAUDE.md: N/500 lines (budget: OK / OVER — removals only)

   ## Proposals
   ### 1. [Add/Remove/Modify] — Title
   [Full scoring template for each]

   ## Removal Candidates (14-day window)
   ## Watching (< 3 occurrences)
   ```

10. **Update fix lineage.** Append to `Documents/Field-Notes/Logs/fix-lineage.jsonl`:
    - One JSON line per proposal: `{"date":"YYYY-MM-DD","issue_id":"short-slug","fix_proposed":"target","target_file":"path","severity":"blocked/friction","recurrence_count":N}`
    - For previously-proposed fixes where the issue stopped recurring (14+ days), update by appending: `{"date":"YYYY-MM-DD","issue_id":"short-slug","fix_effective":true}`

11. **Write retro report** to `Documents/Field-Notes/YYYY-MM-DD-Daily-Retro.md` with a brief narrative + metrics.

---

## Phase 2: Improvement Scan

Cross-cutting strategic analysis. Score and rank improvements using the IVE model.

### Steps

1. **Gather signals** from these sources:
   - Phase 1 retro output (just written — read the proposals file)
   - Git log, last 7 days: `git log --oneline --since="7 days ago"`
   - Plane active items: use `mcp__plane__list_projects` to discover projects, then `mcp__plane__list_work_items` for each project. Look for: blocked items, stale items (>7 days unchanged), items in current cycle.
   - Claude Code releases: run `bash .claude/scripts/check-cc-releases.sh` — check if new features replace custom config
   - CLAUDE.md + skills inventory: count lines, count skills (`ls .claude/skills/`), note potential simplifications

2. **Score each improvement candidate** using IVE:
   - **Impact (0-4):** 0=none, 1=marginal, 2=moderate (prevents error class), 3=high (eliminates recurring failure), 4=critical (security, compounds across sessions)
   - **Velocity (0-3):** 0=full day+, 1=1-4h, 2=15-60min, 3=<15min
   - **Efficiency (0-3):** 0=one-shot, 1=moderate ongoing, 2=compounds per session, 3=meta-improvement

3. **Categories** (assign one per item):
   - Config/Guidance — missing rules, unclear guidance
   - Automation — manual tasks that should be scripted
   - Workflow — friction between agent and user
   - Skills/Prompts — skill gaps, prompt quality drift
   - External Adoption — new Claude Code features not adopted
   - Architecture — structural improvements, debt paydown

4. **Deduplicate.** Read `Documents/Field-Notes/Logs/improvement-scan-seen.jsonl` (if it exists). Skip items surfaced in the last 7 days unless new evidence emerged. If resurfacing, note "[RESURFACED — new evidence: X]".

5. **Write Top 5** to `Documents/Field-Notes/YYYY-MM-DD-Improvement-Scan.md`:
   ```
   # Improvement Scan — YYYY-MM-DD

   ## Executive Summary
   2-3 sentences.

   ## Top 5
   ### 1. [Category] Title
   **IVE Score:** X/10 (Impact: N, Velocity: N, Efficiency: N)
   **[DECISION]** Summary | **Rec:** Action | **Risk:** Assessment | **Reversible?** Yes/No
   - **What:** Description
   - **Evidence:** Sources
   - **Effort:** Estimate + files
   - **Compounds?** Yes/No

   ## Scan Metadata
   ```

6. **Update seen file.** Append new item titles to `Documents/Field-Notes/Logs/improvement-scan-seen.jsonl` as `{"date":"YYYY-MM-DD","title":"..."}`.

---

## Phase 3: Morning Briefing

Assemble a 10-section briefing. This is an integrated narrative, not a concatenation. Section 2 (Today's Focus) is the most valuable — opinionated, cross-referencing all prior phases.

### Data Gathering

Run these data-gathering steps. If any source fails, note "(source unavailable)" in the relevant section and continue.

**Plane data:** Discover projects via `mcp__plane__list_projects` (reuse from Phase 2 if already fetched). Then:
- `mcp__plane__list_work_items` for each project — get all items with status, assignee, dates, labels
- `mcp__plane__list_cycles` for active cycles

**Gmail newsletters:** Search `mcp__claude_ai_Gmail__gmail_search_messages` for messages from the last 24 hours. Read each with `mcp__claude_ai_Gmail__gmail_read_message`. These are newsletters — summarize them.

**Gmail non-newsletter emails:** Search for emails that are NOT from known newsletter senders (substack.com, beehiiv.com, buttondown.email, and other newsletter platforms). These go in section 8.

**Reddit/HN:** Run `bash .claude/scripts/reddit-hn-scan.sh` — returns JSON array of top posts.

**Claude Code releases:** Reuse output from Phase 2's `check-cc-releases.sh` call.

**Git history:** Run `git log --oneline --since="yesterday"` via Bash.

**Retro + Improvement data:** Read the files written in Phases 1 and 2.

### Sections

Write the briefing in the agent's voice — warm, direct, opinionated. ~1000-1500 words total.

**1. Opener.** Warm timestamp. Day of week, date, one contextually relevant line.

**2. Today's Focus.** The most valuable section. Cross-reference: Plane active items + deadlines + yesterday's momentum + Phase 2 top improvements. Produce an **opinionated recommendation** for what to focus on today. Not a status dump — a recommendation.

**3. Active Work.** All Plane projects — current cycle status, what's in progress, what's blocked. Brief.

**4. Decisions Pending.** Items needing the user's judgment. From Plane (blocked items) + any Decision Log revisit dates found in `Documents/Field-Notes/Decision-Log.md`. Format each as a decision card with recommendation.

**5. Deadlines & Waiting On.** Upcoming deadlines (next 7 days from Plane). Stale items (>7 days untouched) flagged. External blockers.

**6. Yesterday's Activity.** Git commits, brief. What shipped or moved.

**7. What Changed in AI.** Three tiers from newsletters:
- **Headlines** (10-15 items, 1 line each): `- [Source] Summary`
- **Deep Callouts** (3-5 items, 2-3 sentences): scored by relevance. Prioritize: model/tool releases, Claude Code relevance, open source, competitive moves. Deprioritize: funding rounds, corporate adoption, regulatory, opinion without new info. **Flag contradictions** — if two sources disagree about a tool or announcement, that's high-signal.
- **Competitive Changelog**: Claude Code releases (with specific config recommendations).
- **Reddit/HN Pulse**: Top 3-5 posts with significant engagement.
- **Full newsletter links** at bottom: `Read full: [Name](link) | ...`

If Gmail is unavailable, note it and use Reddit/HN data only.

**8. Email Inbox.** Subject line list of non-newsletter emails. If none or Gmail unavailable, omit section.

**9. Improvement Radar.** Top 3 from the Phase 2 improvement scan. Include IVE scores and decision card one-liners.

**10. Claude Code Updates.** If a new release was detected: version, key changes, specific recommendations for our config (settings to enable, deprecated features to remove, capabilities to adopt). If no new release, omit section.

### Write the briefing

Write to `Documents/Field-Notes/YYYY-MM-DD-Briefing.md`:
```
# Good Morning — YYYY-MM-DD HH:MM

[10 sections]

---
*Generated by overnight-batch Cloud task*
```

Also copy (Write tool) the same content to `Briefing.md` at the repo root.

---

## Phase 4: Delivery

1. **Send email.** Run:
   ```bash
   bash .claude/scripts/send-email.sh --subject "Morning Briefing — $(date '+%b %d')" --html "$(python3 -c "
   import re
   md = open('Documents/Field-Notes/$(date +%Y-%m-%d)-Briefing.md').read()
   html = md
   html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
   html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
   html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)
   html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
   # Convert list items and wrap in <ul> blocks
   html = re.sub(r'^- (.+)$', r'<li>\1</li>', html, flags=re.MULTILINE)
   html = re.sub(r'((?:^<li>.*</li>\n?)+)', lambda m: '<ul>' + re.sub(r'\n{2,}', '\n', m.group(0)).strip() + '</ul>\n', html, flags=re.MULTILINE)
   html = html.replace('\n\n', '</p><p>').replace('\n', '<br>')
   # Clean up <br> inside <ul> blocks
   html = re.sub(r'</li><br><li>', '</li><li>', html)
   html = re.sub(r'<ul><br>', '<ul>', html)
   html = re.sub(r'<br></ul>', '</ul>', html)
   html = f'<div style=\"font-family:system-ui;max-width:680px;margin:0 auto;padding:20px;line-height:1.6\">{html}</div>'
   print(html)
   ")"
   ```
   If email fails, note it but don't fail the batch.

2. **Git commit and push.** Stage specific files only:
   ```bash
   git add Documents/Field-Notes/$(date +%Y-%m-%d)-Briefing.md
   git add Briefing.md
   git add Documents/Field-Notes/$(date +%Y-%m-%d)-Daily-Retro.md
   git add Documents/Field-Notes/$(date +%Y-%m-%d)-Retro-Proposals.md
   git add Documents/Field-Notes/$(date +%Y-%m-%d)-Improvement-Scan.md
   git add Documents/Field-Notes/Logs/fix-lineage.jsonl
   git add Documents/Field-Notes/Logs/improvement-scan-seen.jsonl
   git commit -m "overnight: briefing + retro $(date +%Y-%m-%d)"
   git push origin main
   ```

---

## Error Handling

| Source | If it fails | Fallback |
|--------|-----------|----------|
| Gmail MCP | Connector unavailable | Skip newsletter + inbox sections. Note "(Gmail unavailable)" |
| Plane MCP | API unreachable | Skip sections 2-5 or use minimal git-log-only briefing |
| Reddit/HN scan | Script errors or rate limited | Skip Reddit/HN subsection. Note "(scan unavailable)" |
| GitHub API | Rate limited | Skip section 10 |
| Git push | Auth failure | Files are committed locally. Note error at top of briefing |
| Phase 1 | No session issues | Skip entirely. Section 9 shows "No retro data" |
| Email send | Resend API error | Continue — briefing is in git, will be pulled to Mac |

Never let a single source failure kill the entire batch. Each section degrades independently.

---

## Constraints

- Do NOT edit CLAUDE.md, skills, hooks, or any config files directly. Write proposals only.
- Do NOT create branches. Commit directly to main.
- Stage specific files only — never `git add .` or `git add -A`.
- Keep the briefing to ~1000-1500 words. Scannable in 5 minutes with coffee.
