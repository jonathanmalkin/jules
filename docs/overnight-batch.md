# Overnight Batch

One Cloud scheduled task. Three sequential phases. Runs before your morning. Output: retro proposals, improvement scan, morning briefing — committed to git and emailed.

This replaces what used to be ~1,800 lines of orchestration bash and 9 container cron jobs on a VPS. The "script" is a prompt file that Claude executes using its native tools.

## The Three Phases

### Phase 1: Retro + Memory

Reads yesterday's session issues, analyzes root causes, checks fix lineage, and proposes CLAUDE.md changes. Never applies changes directly — proposals only, reviewed interactively during the morning briefing.

Key behaviors:
- **3-occurrence threshold.** Issues seen fewer than 3 times across sessions get logged as "watching," not proposed. Counts via `git log --grep` across retro reports.
- **500-line CLAUDE.md budget.** If CLAUDE.md exceeds 500 lines, only net-negative proposals (removals) pass. No additions until under budget.
- **Fix layer classification.** Each fix targets the right layer: mechanical issues → script/hook, judgment issues → CLAUDE.md, gate issues → hook.
- **Fix lineage tracking.** Checks whether a similar fix was previously proposed, applied, or removed. If a soft fix (CLAUDE.md) was applied and the issue recurred, escalates to script/hook.
- **Subtraction scan.** Every run checks existing CLAUDE.md sections for 14-day staleness. Distinguishes "our fix resolved this" from "the system changed underneath us."

Outputs:
- `Documents/Field-Notes/YYYY-MM-DD-Retro-Proposals.md` — scored proposals with metrics
- `Documents/Field-Notes/YYYY-MM-DD-Daily-Retro.md` — retro report
- Appends to `Documents/Field-Notes/Logs/fix-lineage.jsonl` — cross-run fix history

### Phase 2: Improvement Scan

Cross-references Phase 1 output, 7-day git log, Plane project state, Claude Code releases, and config inventory. Scores each candidate with the IVE model:

- **Impact (0-4):** No improvement → Critical
- **Velocity (0-3):** Full day → Under 15 minutes
- **Efficiency (0-3):** One-shot → Meta-improvement

Produces a ranked Top 5 with decision cards. Tracks previously-surfaced items to avoid resurfacing the same improvement within 7 days.

Six categories: Config/Guidance, Automation, Workflow, Skills/Prompts, External Adoption, Architecture.

Outputs:
- `Documents/Field-Notes/YYYY-MM-DD-Improvement-Scan.md`
- Appends to `Documents/Field-Notes/Logs/improvement-scan-seen.jsonl`

### Phase 3: Morning Briefing

10-section briefing assembled from multiple sources:

| Section | Data Source | How |
|---------|-----------|-----|
| 1. Opener | Date/time | `date` |
| 2. Today's Focus | Plane + yesterday's momentum + Phase 2 | Plane MCP or REST API |
| 3. Active Work | Plane projects, current cycle | Plane MCP or REST API |
| 4. Decisions Pending | Plane blocked items + Decision Log | Plane MCP or REST API + file read |
| 5. Deadlines & Waiting On | Plane due dates, stale items | Plane MCP or REST API |
| 6. Yesterday's Activity | Git log | `git log --oneline --since="yesterday"` |
| 7. What Changed in AI | Newsletters, Reddit, HN, CC releases | Gmail MCP + helper scripts |
| 8. Email Inbox | Non-newsletter emails | Gmail MCP |
| 9. Improvement Radar | Phase 2 output | File read |
| 10. Claude Code Updates | GitHub releases | `check-cc-releases.sh` |

Section 2 is the most valuable — it cross-references priorities, momentum, deadlines, and improvements into an opinionated recommendation for what to focus on today. Not a status dump.

Section 7 uses tiered summarization: 10-15 one-liner headlines, 3-5 expanded deep callouts (scored by relevance), and a competitive changelog.

Outputs:
- `Briefing.md` (repo root, quick access)
- `Documents/Field-Notes/YYYY-MM-DD-Briefing.md` (archive)
- Email via Resend API

Final step: commit all output files and push.

## File Layout

What needs to exist in the repo before the task runs:

```
.claude/scripts/
├── overnight-batch.md          # The prompt (~250 lines)
├── send-email.sh               # Resend API email sender
├── check-cc-releases.sh        # GitHub releases checker (~30 lines)
└── reddit-hn-scan.sh           # Reddit/HN top posts (~50 lines)
```

Output locations the task writes to:

```
Briefing.md                                              # Latest briefing (overwritten each run)
Documents/Field-Notes/YYYY-MM-DD-Briefing.md             # Dated archive
Documents/Field-Notes/YYYY-MM-DD-Retro-Proposals.md      # Scored proposals
Documents/Field-Notes/YYYY-MM-DD-Daily-Retro.md          # Retro report
Documents/Field-Notes/YYYY-MM-DD-Improvement-Scan.md     # Top 5 improvements
Documents/Field-Notes/Logs/fix-lineage.jsonl              # Append-only fix history
Documents/Field-Notes/Logs/improvement-scan-seen.jsonl    # Append-only dedup tracker
```

### Helper Scripts

**check-cc-releases.sh** — Fetches latest `anthropics/claude-code` release from GitHub API (public, no auth). Outputs JSON `{version, date, body, url}`.

**reddit-hn-scan.sh** — Fetches top posts from configured subreddits + HN using public JSON APIs. Uses `User-Agent` header for Reddit. Outputs JSON array of `{title, url, score, source, comments}`.

**send-email.sh** — Sends the briefing as an email via Resend API. Converts markdown to HTML inline. Uses `RESEND_API_KEY` from environment.

Helper scripts exist because deterministic data-fetching is better as bash than tool calls. Curl commands execute the same way every time; an LLM crafting HTTP requests can drift.

## The Prompt File

`overnight-batch.md` is the task. The Cloud runner reads it as the session prompt and executes each phase using native Claude Code tools (Bash, Read, Write, Edit, MCP connectors, WebFetch).

Key patterns in the prompt:

**Sequential phases.** Each phase ends with an explicit marker: "Phase N complete. Moving to Phase N+1." This prevents the model from jumping ahead or mixing phases.

**Explicit error handling.** Every data source has a defined fallback:

| Source | Failure Mode | Fallback |
|--------|-------------|----------|
| Gmail MCP | Connector unavailable | Skip newsletter and inbox sections. Note "(Gmail unavailable)" |
| Plane | API unreachable | Read `Terrain.md` for project state |
| Reddit JSON API | Rate limited or down | Skip Reddit items. Note "(Reddit scan unavailable)" |
| GitHub API | Rate limited | Skip CC updates section |
| Git push | Auth failure | Leave files committed locally. Log error in briefing header |
| Phase 1 (retro) | No session issues | Skip retro. Section 9 shows "No retro data" |

The prompt includes: "If any data source fails, include the section header with a one-line note explaining what's unavailable. Never skip a section silently."

**Specific file staging.** The commit step names exact files — never `git add .` or `git add -A`.

## Cloud Task Configuration

Configure via the web UI at claude.ai → Code → Scheduled.

| Setting | Value | Why |
|---------|-------|-----|
| Schedule | `0 6 * * *` (daily, 6:00 AM your timezone) | Ready before your morning |
| Internet access | Full | Reddit, HN, GitHub, Resend APIs |
| MCP Connectors | Gmail (+ Plane if available as connector) | Data gathering |
| Env vars | `RESEND_API_KEY` | Email delivery |
| Repository | Your GitHub repo | Reads config, writes output |
| Branch | `main` | Direct commits |
| Allow unrestricted pushes | Yes | Task must push output |
| Max turns | 50 | Enough for three phases with tool calls |

Steps:
1. Go to claude.ai → Code → Scheduled
2. Create new scheduled task
3. Set the prompt to the contents of `overnight-batch.md` (or reference the file path)
4. Configure schedule, repo, branch, connectors, and env vars per the table above
5. Enable "Allow unrestricted branch pushes"
6. Run manually once to verify — check the session transcript in the web UI

## Cloud Environment Constraints

The Cloud runner clones your repo fresh every run. This means:

**Available:**
- Bash (full shell: git, curl, python3, standard Unix tools)
- Read/Write/Edit (file operations on the cloned repo)
- MCP connectors configured in claude.ai (Gmail, Google Calendar, Slack, Plane)
- WebFetch/WebSearch (full internet access)
- Git (clone, commit, push to the configured repo)

**Not available:**
- Local filesystem beyond the cloned repo
- `~/.claude/` config (skills, hooks, rules must be committed to the repo)
- Persistent state between runs (every run starts from a fresh clone)
- `claude -p` subprocesses (the session IS Claude Code)
- User-level secrets files (use env vars in Cloud task settings)

**Cross-run state** is maintained through git-committed files. The fix lineage log and improvement scan tracker are append-only JSONL files — each run reads them from the repo, appends new entries, and commits. This is how the retro tracks whether a fix was previously proposed and whether it worked.

## The Consumer: good-morning Skill

The overnight batch produces output. The `good-morning` skill consumes it during your first interactive session of the day.

The skill's decision tree:

1. Read `Briefing.md` at repo root
2. If missing, try the dated archive: `Documents/Field-Notes/YYYY-MM-DD-Briefing.md`
3. **Staleness check:** Extract date from `# Good Morning — YYYY-MM-DD` header. If not today's date, flag it
4. If briefing is missing entirely, check `git log --grep="overnight: briefing"` for today
5. If overnight commit exists but file is missing locally: `git pull`, retry
6. If no overnight commit: the Cloud task didn't run. Offer ephemeral fallback from live API calls

The fallback generates a lightweight briefing conversationally — it works, but it's slower and doesn't include retro proposals or the improvement scan. The overnight batch is the intended path.

## Gotchas

Hard-won lessons from getting this running.

### 1. `defaultMode: plan` blocks Cloud tasks forever

If your `.claude/settings.json` contains `"defaultMode": "plan"`, the Cloud runner inherits it. It enters plan mode and waits for human approval — which never comes. Every run blocks indefinitely.

**Fix:** Move `defaultMode` to `settings.local.json`. Claude Code gitignores this file automatically, so the Cloud runner never sees it. Your local interactive sessions still get plan mode via the local override (which has higher precedence than `settings.json`).

This one cost us 5+ failed runs and an entire day of debugging.

### 2. `disallowed_tools` in trigger config is silently ignored

The RemoteTrigger API accepts a `session_context` field with `disallowed_tools`. It returns 200 with the field in the response. The Cloud runner ignores it completely. Don't rely on this to restrict model behavior.

### 3. Cloud environment setup scripts are unreliable for settings patching

We tried creating a Cloud environment with a setup script (`sed -i 's/"defaultMode": "plan",*//' .claude/settings.json`) to strip the problematic setting before the session starts. It didn't work — settings may be loaded before or independently of the setup script.

### 4. Web UI edits clobber API updates

If you update a trigger via the RemoteTrigger API, then later toggle a setting in the web UI, the UI overwrites your entire trigger config with its cached version. Your API changes are lost.

**Fix:** If you need both UI and API changes, make UI changes first, then API updates. Always include all fields in API updates — partial updates get merged with cached (possibly stale) state.

### 5. No run history via API

The RemoteTrigger API (list, get, create, update, run) provides trigger configuration only. There's no endpoint for past run history, session transcripts, or failure reasons.

**To debug failed runs:** Open the web UI at claude.ai → Code → Scheduled. Each trigger shows its run history with session links and status.

Related issues: anthropics/claude-code#30463, anthropics/claude-code#22220, anthropics/claude-code#23384.

### 6. GitHub only

Cloud scheduled tasks only support GitHub repositories. No GitLab, Bitbucket, or local repos. The task clones from GitHub at the start of each run.

## Commit Pattern

The overnight batch commits with a consistent message pattern:

```
overnight: briefing + retro YYYY-MM-DD
```

The good-morning skill uses `git log --grep="overnight: briefing"` to detect whether the batch ran. Keep this pattern consistent so the consumer can find the output.
