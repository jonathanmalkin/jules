---
name: wrap-up
description: End-of-conversation shipping and review workflow. Use when the user says wrap up, close out, end session, ship this, commit and push, prepare handoff, or asks for a session closeout. Runs a scheduler-safe preflight, verifies work, commits and pushes specific files when appropriate, captures open loops and improvement candidates, and ends with a clear handoff.
---

# Wrap-Up

Use this at the end of a meaningful conversation or when the user asks to ship,
close out, commit, push, or prepare a handoff.

The job is not just repo cleanup. The job is to leave the workspace in a known
state, avoid stepping on running schedulers, ship only intentional changes, and
turn repeated friction into improvement candidates.

## Opening

Start with `Workflow: wrap-up`. Then run the deterministic preflight before
making any changes:

```bash
python3 ~/.agents/skills/workflows/wrap-up/scripts/wrapup_preflight.py --workspace "$PWD" --due-window-minutes 90
```

If this skill is running from a copied surface where `~/.agents` is unavailable,
run the copy-local script at `scripts/wrapup_preflight.py`.

## Core Sequence

Run these phases in order.

### 1. Outcome State

Summarize the session's original objective and current state:

- what got done
- what did not get done
- whether the work changed scope
- whether the handoff is `Complete` or `Continues`

Do not call the session complete if the stated objective is unfinished.

### 2. Scheduler-Safe Preflight

Use the preflight script output as the collision map. At minimum, account for:

- user LaunchAgents in `~/Library/LaunchAgents`
- user crontab from `crontab -l`
- Hermes cron jobs in `~/.hermes/profiles/*/cron/jobs.json`
- Codex automations in `~/.codex/automations/*/automation.toml`
- running Hermes gateways, dashboards, WebUI, Dev Secrets, history-search, and
  other launchd-managed services when visible

Default safety rules:

- Do not restart, unload, kickstart, repair, or create background services
  during normal wrap-up.
- Do not edit LaunchAgents, Hermes `config.yaml`, Hermes `cron/jobs.json`,
  secrets runtime files, scheduler scripts, or automation definitions unless the
  session explicitly touched scheduler work.
- Treat scheduler output, logs, state snapshots, lock files, and generated
  reports as owned by running processes unless they are part of this session's
  deliverable.
- If a scheduled job is unhealthy, record it as an improvement candidate unless
  the user explicitly asked for scheduler repair.
- If a job is due soon, avoid broad staging. Stage only files known to belong to
  this session.

If the preflight cannot inspect a surface because of permissions, report that
surface as unverified. Do not claim it is clean.

### 3. Verification

Run the narrowest meaningful checks for the work done:

- tests for code changes
- build or typecheck for frontend/app changes
- script smoke checks for wrappers and automation helpers
- syntax checks for JSON, TOML, YAML, plist, shell, or Python files
- health checks for services only when the session touched those services

If verification is skipped, state why. A skipped check is not a pass.

### 4. Change Review

Inspect git before staging:

```bash
git status --short
git diff --stat
```

Classify changes:

- session changes to stage
- user or scheduler changes to leave alone
- generated artifacts to review before staging
- secret or credential-looking files to avoid and flag
- unrelated dirty files to preserve

Never use `git add .` or `git add -A`. Stage specific files only.

### 5. Commit

Commit only after verification and change review.

Use a descriptive message that says what shipped, not that the session ended.
Prefer:

```text
Add scheduler-safe wrap-up workflow
Repair Pam calendar auth probe
Update Jules Live Studio turn handling
```

Avoid vague messages like:

```text
Wrap-up changes
Session updates
Misc fixes
```

Do not use `--no-verify` unless the user explicitly approves bypassing hooks and
the reason is stated in the final report.

### 6. Push

Push the current branch to its configured upstream or to the branch requested by
the user.

Rules:

- Do not force push.
- If push is rejected, report the reason and stop for review unless the user
  already authorized pull/rebase behavior.
- Do not pull or rebase during generic wrap-up unless that behavior was clearly
  approved for this session.
- If the user said "do not pull", preserve that constraint.

### 7. Open Loops and Commitments

List only real open loops:

- blockers
- next actions
- user commitments to another person
- outbound drafts needing approval
- calendar, email, social, or partner follow-ups
- background jobs or health issues discovered but not repaired

For a continuing handoff, include a resume prompt specific enough for a fresh
session.

### 8. Improvement Candidates

Look for improvements in these categories:

- **Skill gap**: the assistant struggled or missed existing guidance.
- **Friction**: a repeated manual step should become a script, check, or skill.
- **Knowledge**: a durable fact should be captured in the right local doc.
- **Automation**: a scheduled job, wrapper, or health check could be hardened.
- **Quality**: tests, docs, or validation were missing for behavior that matters.

Do not automatically edit shared instructions during wrap-up. Present concrete
candidates with suggested files or procedures.

Hermes profiles may run their own profile-native skill review/update procedure.
Codex and Claude should follow this skill's guidance and propose shared skill
edits for review before changing `.agents` or profile-specific skills.

### 9. Final Report

End with a compact report:

```markdown
Wrap-up complete.

Verification:
- [check]: pass/fail/skipped

Git:
- branch:
- commit:
- push:

Scheduler safety:
- checked:
- due soon:
- unverified:

Open loops:
- ...

Improvement candidates:
- ...

Handoff: Complete - [one sentence]
```

If the objective continues, end with:

```markdown
Handoff: Continues - [what remains]
Resume prompt: [exact prompt]
```

On Codex, after a successful stage, commit, push, branch creation, or PR creation,
emit the relevant Codex app git directives in the final answer.

### 10. Optional Report Artifact

The conversational final report is always required. A file artifact is
conditional.

Save a wrap-up report file when at least one is true:

- code, docs, config, or assets were committed or pushed
- a durable decision was made
- the work continues and needs a fresh-session resume prompt
- a background job, scheduler, automation, auth surface, or service was touched
- there are concrete improvement candidates worth reviewing later
- Jonathan explicitly asks for a report artifact

Do not save a file for trivial Q&A, quick lookups, or conversations with no
state change.

When saving, use a run artifact path rather than a durable Knowledge-OS report:

```text
System/Runs/<surface>/wrap-up/YYYY-MM-DD/HHMMSS-<slug>.md
System/Runs/<surface>/wrap-up/YYYY-MM-DD/HHMMSS-<slug>.json
```

Use the helper to create the artifact deterministically:

```bash
python3 ~/.agents/skills/workflows/wrap-up/scripts/wrapup_report.py \
  --workspace "$PWD" \
  --surface codex \
  --status Complete \
  --focus "Add scheduler-safe wrap-up workflow" \
  --summary "Created the shared wrap-up skill and helper scripts." \
  --verification "preflight helper runs" \
  --improvement "Review surface symlink plan before installing adapters" \
  --write
```

Report artifacts are receipts and ingestion inputs. They do not replace
transcripts, git history, history-search, Pam reports, Subconscious notes,
Researcher intake, Archivist distillation, Builder's Log, or future gbrain.

For gbrain, keep the artifact short and structured: session id if known, surface,
status, focus, files/commits, verification, scheduler safety, open loops,
improvement candidates, and resume prompt. Do not paste raw transcript content or
secret values.

Promote only durable decisions, reusable facts, or stable operating rules into
Knowledge-OS or memory. Do not treat every wrap-up artifact as durable knowledge.

## Surface Adapters

The canonical skill lives at:

```text
~/.agents/skills/workflows/wrap-up
```

Use the read-only target planner before installing or changing surface links:

```bash
python3 ~/.agents/skills/workflows/wrap-up/scripts/wrapup_surface_targets.py
```

Recommended adapter behavior:

- **Codex**: symlink `~/.codex/skills/wrap-up` to the canonical skill. Codex
  adds app git directives after successful git operations.
- **Claude Code**: symlink `~/.claude/skills/wrap-up` to the canonical skill.
  Claude uses plain final text and its own slash-command behavior.
- **Hermes profiles**: symlink
  `~/.hermes/profiles/<profile>/skills/workflows/wrap-up` for approved
  workflow-owning profiles only. Current live adapters are `pam` and `director`.
  Do not install this skill on `archivist`, `dreamer`, `researcher`, or
  `subconscious` unless Jonathan explicitly re-approves those profile surfaces.
  Hermes may run profile-native skill review before proposing shared edits.
- **Public/reference Jules repo**: copy or sync a sanitized copy into the repo
  rather than symlinking to a host-local path.

Do not replace existing physical skill directories with symlinks without review.

## Deterministic Helpers

- `scripts/wrapup_preflight.py`: read-only scheduler, git, and automation
  preflight. It intentionally avoids prompts and secret values.
- `scripts/wrapup_surface_targets.py`: read-only inventory of surface adapter
  targets and whether each is missing, a symlink, or a physical directory.
- `scripts/wrapup_report.py`: optional writer for compact Markdown plus JSON
  wrap-up artifacts under `System/Runs/<surface>/wrap-up/`.
