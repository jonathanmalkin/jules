---
name: retro-deep
description: "Deep retrospective. Full forensic analysis of the current conversation — every issue, compliance gap, workaround, and cross-session pattern. Saves report to Documents/Field-Notes/, auto-applies fixes. Also runs automatically during wrap-up Phase 1. Standalone triggers: 'retro deep', 'full retro', 'audit this session', 'session retrospective', 'deep retrospective', 'what went wrong this session'."
---

# Retro Deep — End-of-Session Forensics

Full diagnostic of the current session. Identify everything that went wrong, cross-reference against all guidance, research proper solutions, save a report, and apply fixes so the next session is better.

## When to Use

- End of a rough session with multiple issues
- Before `/wrap-up` on a session where things went sideways
- User wants a thorough session audit
- Runs automatically as part of wrap-up Phase 1 Step 2 (no manual invocation needed)

## Phase 1: Issue Extraction (Inline)

Scan the **entire conversation**. Capture everything — don't filter for severity yet.

### Issue Categories

1. **Repeated errors** — Same root cause surfaced 2+ times (not just same symptom)
2. **Compliance failures** — Guidance existed in CLAUDE.md, memory, rules, or skills that should have prevented the issue but wasn't followed
3. **Missing guidance** — An issue arose that no existing guidance covers, but should
4. **Workarounds** — Hacky fix where a proper solution likely exists
5. **Knowledge gaps** — Information was needed but unavailable or outdated

For each issue, document:
- **What happened** — brief description
- **Occurrences** — how many times, with approximate locations in conversation
- **What was tried** — solutions attempted, in order
- **What worked** — final resolution (if any)
- **Category** — which of the 5 above
- **Severity** — high (blocked progress), medium (caused delay), low (minor friction)

### Probabilistic Drift Check

Also scan for moments where:
- A skill instruction was skipped (LLM didn't follow a "remember to..." or "always..." rule)
- A compliance failure would have been caught by a hook but wasn't (because it's still prose)
- A new instruction was written to a skill/rule/CLAUDE.md that's mechanical and could be a script

For each finding, note: "Determinism candidate — could be a hook/script instead of an instruction."
Apply the test: "If 10 different LLMs got this instruction, would they all do exactly the same thing?"
If yes -> file it as a script candidate in the retro report.

## Phase 2: Cross-Reference + Research + Patterns (Parallel Subagents)

**Only runs if Phase 1 found issues.** If no issues, skip to Phase 3 (report "clean session").

Spawn **three subagents simultaneously** with the full issues list, using dedicated agents:

### Config Auditor

Spawn as `subagent_type: "retro-config-auditor"`. Provide the full issues list.

The agent reads all config files (CLAUDE.md, rules, skills, memory) and reports guidance gaps, clarity issues, and conflicts for each issue.

### Solution Researcher

Spawn as `subagent_type: "retro-solution-researcher"`. Provide workarounds and knowledge gaps.

The agent searches for known issues, upstream fixes, library updates, config options, and alternative approaches. Returns recommended fixes with source URLs and confidence levels.

### Pattern Scanner

Spawn as `subagent_type: "retro-pattern-scanner"`. Provide the specific issues found.

The agent searches session reports, retro reports, memory files, and plan headers for cross-session recurrence. Reports whether each issue has appeared before, when, and whether prior fixes stuck.

## Phase 3: Synthesis + Report (Inline)

### Build the Report

Save to `~/your-workspace/Documents/Field-Notes/YYYY-MM-DD-Session-Retro.md`:

```markdown
# Session Retrospective — YYYY-MM-DD

## Summary
[2-3 sentences: what the session was about, how it went, key themes]

## Issues Found

### 1. [Issue Title]
**Category**: [Repeated error | Compliance failure | Missing guidance | Workaround | Knowledge gap]
**Severity**: [High | Medium | Low]
**Occurrences**: N times
**What happened**: ...
**Existing guidance**: [Quote from config file, or "None"]
**Cross-session**: [Has this come up before? From Pattern Scanner]
**Root cause**: ...
**Fix**: [What to change and where]
**Status**: [Applied | Pending manual action]

### 2. [Issue Title]
...

## Changes Applied
- `[file path]`: [Change description]
- ...

## Changes Pending (Manual Action Required)
- [Description of what needs to happen and why it can't be automated]

## Cross-Session Patterns
[Patterns that span multiple sessions — recurring themes, chronic issues]

## Recommendations
[Structural improvements beyond individual fixes — workflow changes, tool changes, skill gaps to address]
```

### Apply Fixes

For each issue, determine the minimal effective fix:

| Fix Type | When | Target |
|----------|------|--------|
| Memory update | Stable pattern/workaround to remember | `memory/MEMORY.md` or topic file |
| Rule add/update | Domain-specific guidance for future sessions | `.claude/rules/*.md` |
| Skill update | Skill missed a case or gave wrong guidance | `.claude/skills/*/SKILL.md` |
| CLAUDE.md update | Core behavior/preference change | `CLAUDE.md` |
| Hook add/update | Automated prevention needed | `.claude/hooks/` or settings.json |
| Script creation | Recurring manual task to automate | Appropriate location |

Apply each fix. Show what changed:

```
**Fix 1**: [Category] [Brief description]
-> Updating `[file]`: [what's being added/changed]
[Apply the change]
Done.
```

## Phase 4: Verification

After applying all fixes:
1. Re-read modified files to confirm changes landed correctly
2. Check for conflicts — does a new rule contradict an existing one?
3. If conflicts found, flag them and resolve (don't silently override)

## Integration

- **With wrap-up**: If `/retro-deep` runs before `/wrap-up`, wrap-up should skip Phase 1 Step 2 (self-improvement scan) — retro already covered it more thoroughly. Mention this to the user.
- **With systematic-debugging**: If retro finds an unresolved bug, suggest invoking `/systematic-debugging` for root cause analysis.
- **With good-morning**: The retro report in `Documents/Field-Notes/` will be picked up by the morning briefing, so quality matters.

## Key Principles

- **Blame the system, not the operator.** If guidance existed and wasn't followed, the guidance was unclear or badly placed. Fix the guidance.
- **Specificity over platitudes.** "Be more careful" is not a fix. "Add X to file Y" is.
- **Minimal effective fix.** Don't add a hook when a memory note suffices. Don't write a skill when a rule covers it.
- **Fix recurrence, not instance.** Every fix should prevent the issue from happening *again*.
- **Cross-session awareness.** A fix that's been applied before and didn't stick needs a stronger intervention (escalate from memory note -> rule -> hook).
- **Thorough but actionable.** This is the full sweep, so be comprehensive. But every finding must lead to a concrete action or explicit "no action needed" with reasoning.

## Output Format

After the report is saved and fixes are applied:

```
**Retro Deep Complete**
Report saved: Documents/Field-Notes/YYYY-MM-DD-Session-Retro.md

**[N] issues found across [M] categories:**
- [High severity count] high / [Medium count] medium / [Low count] low

**[X] fixes applied:**
- [One line per fix]

**[Y] manual actions needed:**
- [One line per manual action]

**Cross-session patterns:**
- [One line per pattern, if any]
```

If `/wrap-up` hasn't been run yet, remind: "This covered the analysis — run `/wrap-up` for commit, memory, and status updates."
