---
name: user-testing
description: >
  Persona-driven UX evaluation of a deployed web app on mobile viewports.
  Dispatches 3 review groups (user perspectives, technical review, business review)
  covering 8 evaluation lenses. Returns structured problem/fix list.
  Use when user says "user test", "UX test", "persona test", "test as users",
  or after deploying user-facing changes via subagent-driven-development.
  Do NOT use for functional smoke testing -- use a dedicated smoke-test skill instead.
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

# User Testing

Persona-driven UX evaluation on mobile viewports. 8 evaluation lenses grouped into 3 sequential subagents. All testing at 375x812 (primary traffic = mobile links on phones).

## When to Use

| Trigger | Action |
|---------|--------|
| `/user-test` or `/user-test staging` | Test staging (default) |
| `/user-test production` | Test production |
| After deploying user-facing changes | Auto-suggested by subagent-driven-development |
| "user test", "UX test", "persona test" | Ask which environment |

**Skip when:** Bug fixes, refactors, backend-only changes, config, test-only, small copy tweaks.

## Environment

| Env | URL |
|-----|-----|
| Staging | `https://staging.example.com` |
| Production | `https://app.example.com` |

Default to **staging** unless specified.

## The Process

```
Phase 0: Setup
  -> Run setup-test-session.sh (creates dirs, mobile viewport, navigate to key page)
  -> Verify app is loaded

Phase 1: Dispatch review groups (sequential)
  -> Group 1: User Perspectives (new user + experienced user)
  -> Group 2: Technical Review (mobile QA + accessibility + design)
  -> Group 3: Business Review (privacy + conversions + overall UX)

Phase 2: Consolidation
  -> Read all 3 reports from /tmp/user-test/
  -> Deduplicate, assign severity, prioritize

Phase 3: Output
  -> Return structured problem/fix list to caller
```

## Phase 0: Setup

Run the setup script to get the app loaded on mobile:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-test-session.sh <TARGET_URL>
```

This script:
1. Creates `/tmp/user-test/` and `/tmp/user-test/screenshots/`
2. Closes existing agent-browser sessions
3. Opens target URL at 375x812 mobile viewport
4. Navigates through any onboarding/consent gates
5. Reaches the main content or results page
6. Saves baseline screenshots

**If setup fails:** Stop and report the failure. Don't dispatch groups.

## Phase 1: Dispatch Review Groups

Dispatch 3 subagents **sequentially**. Each group gets its own agent-browser session at 375x812.

Read the full prompt templates from `references/group-prompts.md` before dispatching.

### Dispatching a Group

For each group, dispatch a `general-purpose` subagent with:
- The group's full prompt from `references/group-prompts.md`
- Target URL substituted into the prompt
- Model: **sonnet** (visual evaluation needs reasoning, but not opus-level)

```
Agent tool (general-purpose, model: sonnet):
  description: "User test: Group N -- [group name]"
  prompt: [full prompt from group-prompts.md with URL substituted]
```

**Between groups:** The previous group's agent-browser session may still be open. Each group prompt includes setup commands that close and reopen the browser. No manual cleanup needed.

### Group Definitions

**Group 1 -- User Perspectives:** Two navigation passes. Pass 1 as a nervous first-time user (full flow: landing -> onboarding -> first 5 interactions manually -> fast-forward rest -> results). Pass 2 as a skeptical experienced user (results page evaluation). Reports to `/tmp/user-test/group1-report.md`.

**Group 2 -- Technical Review:** Systematic mobile QA (touch targets via `get box`, overflow checks), accessibility audit (ARIA, skip-links, keyboard nav, contrast), and visual design evaluation (screenshots + Read). Reports to `/tmp/user-test/group2-report.md`.

**Group 3 -- Business Review:** Privacy audit (network requests, data disclosure, consent flow), conversion funnel testing (all CTAs, download, share, email capture, retake), and overall UX assessment (cognitive load, information architecture, error states). Reports to `/tmp/user-test/group3-report.md`.

## Phase 2: Consolidation

After all 3 groups complete:

1. **Read all reports:**
   ```
   /tmp/user-test/group1-report.md
   /tmp/user-test/group2-report.md
   /tmp/user-test/group3-report.md
   ```

2. **Deduplicate:** Same issue found by multiple groups -> merge into one entry, list all groups that found it.

3. **Assign severity:**
   - **Critical** -- Blocks user flow (can't complete flow, can't see results, broken CTA)
   - **Major** -- Significant UX problem (confusing copy, poor mobile layout, accessibility failure, trust issue)
   - **Minor** -- Polish (spacing, minor visual inconsistency, nice-to-have improvement)

4. **Severity boosting:** Issues found by 2+ groups get bumped one severity level (Minor->Major, Major->Critical). Issues found by all 3 groups are automatically Critical.

5. **Prioritize:** Within each severity, order by: (a) number of groups that found it, (b) impact on conversion funnel, (c) ease of fix.

## Phase 3: Output

Return the consolidated report in this format:

```markdown
# User Testing Report -- [date] -- [environment]

## Issues Found

### Critical (blocks user flow)
1. **[Title]** -- [Description] | Found by: [group(s)] | Screenshot: [path]
   - Suggested fix: [specific recommendation]

### Major (significant UX problems)
1. **[Title]** -- [Description] | Found by: [group(s)] | Screenshot: [path]
   - Suggested fix: [specific recommendation]

### Minor (polish)
1. **[Title]** -- [Description] | Found by: [group(s)] | Screenshot: [path]
   - Suggested fix: [specific recommendation]

## What's Working Well
- [Positive observation] -- [group]

## Action Items (ordered by priority)
1. [Fix X in Y file] -- addresses Critical #1
2. [Adjust Z copy] -- addresses Major #2
```

The **Action Items** section is the key deliverable -- each item specific enough for an implementer subagent to pick up as a task.

## Fix Loop (when called from subagent-driven-development)

When the calling agent receives Critical or Major issues:

1. Dispatch an implementer subagent with the Action Items as tasks
2. Implementer fixes -> commits -> redeploy to staging
3. Re-run **only the affected group(s)**, not all three
4. If re-test passes -> proceed to production deploy
5. If re-test finds new issues -> loop (max 2 iterations, then report remaining to user)

Minor issues: logged in the report, noted for the user at wrap-up. Not acted on immediately.

## Red Flags

**Never:**
- Skip setup (app must be loaded before dispatching groups)
- Dispatch groups in parallel (they share the agent-browser session)
- Accept a group report that has no screenshots (visual evaluation is mandatory)
- Skip consolidation (raw group reports are not the deliverable)
- Run more than 2 fix loop iterations (diminishing returns -- report and move on)

**If a group subagent fails:**
- Check if agent-browser is responsive (`agent-browser screenshot /tmp/user-test/debug.png`)
- If browser crashed, restart and retry that group once
- If it fails again, skip that group and note the gap in the report

## Integration

**Related skills:**
- **smoke-test** -- Functional smoke testing (does it work?). User testing is UX evaluation (does it feel right?).
- **subagent-driven-development** -- Calls this skill after deploying user-facing changes.
- **deploy** -- Deploy skill runs before user testing.
