---
name: retro-deep
description: "Automated daily batch retrospective. Runs at 3 AM via daily-retro.sh on the VPS container. Analyzes session issues, cross-references config, applies fixes. NOT for interactive use. This skill folder is the single source of truth for the retro analytical framework and system prompts used by the batch script."
---

# Retro Deep — Automated Daily Batch

This skill defines the analytical framework for the daily retrospective batch process. It is **not invoked interactively**. The execution engine is `.claude/scripts/daily-retro.sh` (runs at 3 AM CST via container cron).

## Architecture

```
3:00 AM  daily-retro.sh
           ├── Find session issue files (bash)
           ├── Pre-read config files (bash)
           ├── 3 parallel Sonnet-medium agents (config-audit, solution-research, pattern-scan)
           ├── Sonnet-high synthesis + apply fixes (25 turns)
           ├── Quality check (bash)
           ├── Git commit/push
           └── Write signal file → consumed by morning orchestrator at 5 AM
```

## Issue Categories

1. **Repeated errors** — Same root cause surfaced 2+ times
2. **Compliance failures** — Guidance existed but wasn't followed
3. **Missing guidance** — Issue arose that no guidance covers but should
4. **Workarounds** — Hacky fix where a proper solution likely exists
5. **Knowledge gaps** — Information needed but unavailable or outdated

## Severity Levels

- **High** — Blocked progress
- **Medium** — Caused delay
- **Low** — Minor friction

## Fix Types

| Fix Type | When | Target |
|----------|------|--------|
| Memory update | Stable pattern/workaround | `memory/MEMORY.md` or topic file |
| Rule add/update | Domain-specific guidance | `.claude/rules/*.md` |
| Skill update | Skill missed a case | `.claude/skills/*/SKILL.md` |
| CLAUDE.md update | Core behavior change | `CLAUDE.md` |
| Script creation | Recurring manual task | `.claude/scripts/` |

## System Prompts

The `references/` directory contains system prompts used by `daily-retro.sh`:

- `references/config-auditor.md` — Audits config files for guidance gaps, clarity issues, conflicts
- `references/solution-researcher.md` — Researches proper fixes for workarounds and knowledge gaps
- `references/pattern-scanner.md` — Searches session reports for cross-session recurrence
- `references/synthesis.md` — Synthesizes all analysis, applies fixes, produces report

## Key Principles

- **Blame the system, not the operator.** If guidance existed and wasn't followed, the guidance was unclear. Fix the guidance.
- **Specificity over platitudes.** "Be more careful" is not a fix. "Add X to file Y" is.
- **Minimal effective fix.** Don't add a hook when a memory note suffices.
- **Fix recurrence, not instance.** Every fix should prevent the issue from happening again.
- **Cross-session awareness.** A fix that didn't stick needs a stronger intervention (memory -> rule -> hook).

## Integration

- **Input:** `Documents/Field-Notes/Logs/*-Session-Issues.md` (written by wrap-up Phase 1)
- **Output:** `Documents/Field-Notes/YYYY-MM-DD-Daily-Retro.md` (consumed by morning orchestrator briefing)
- **Signal file:** `~/.claude/job-state/daily-retro.status` (read by morning orchestrator)
- **Config changes:** Auto-committed and pushed after synthesis
