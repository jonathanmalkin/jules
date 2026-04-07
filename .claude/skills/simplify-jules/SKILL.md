---
name: simplify-jules
description: "On-demand config hygiene — analyzes cold-start bundle for waste, duplication, and stale content"
---

# /simplify-jules

On-demand config hygiene tool. Analyzes the full cold-start file bundle for waste, duplication, stale content, and consolidation opportunities. All proposals require [Your Name]'s approval — never auto-edit any file.

---

## Phase 1 — INVENTORY

Read and count lines in every cold-start file:

- `~/.claude/CLAUDE.md` and all `@`-imported files it references
- `Active-Work/CLAUDE.md` and all `@`-imported files it references
- All `.claude/rules/*.md` files
- All `@`-tagged profile files (`Profiles/*.md`)

For each file, record: file path, line count.

Report:

```
Cold-Start Budget: X lines
Files scanned: N
Largest files: [top 5 by line count]
```

---

## Phase 2 — SECTION ANALYSIS

For each file, read every section (heading or logical block) and classify it:

| Classification | Definition |
|---|---|
| **ACTIONABLE** | Directly changes agent behavior — keep as-is |
| **DOCUMENTATION** | Describes or explains but doesn't change behavior — propose move to `Documents/` |
| **REDUNDANT** | Already said elsewhere — propose cut, cite exact duplicate (file:line) |
| **VAGUE** | Too abstract to change behavior — propose cut or rewrite |

Output one table per file:

```
### ~/.claude/CLAUDE.md
| Section | Lines | Classification | Notes |
|---------|-------|----------------|-------|
| User Preferences | 1-3 | DOCUMENTATION | Says "see project CLAUDE.md" |
...
```

Cite line numbers for every section.

---

## Phase 3 — CROSS-FILE DEDUP

After reading all files, scan for:

1. **Duplicate instructions** — same rule stated in multiple files. List both locations.
2. **Conflicting instructions** — contradictory rules. Flag both locations, describe the conflict.
3. **Consolidation opportunities** — related content spread across files that could merge without loss.

Format:

```
### Duplicates
- "Stage specific files for commits" — rules/safety.md:12 AND CLAUDE.md:47

### Conflicts
- "Use Opus for complex analysis" (CLAUDE.md:89) vs "Default to Sonnet" (rules/models.md:5) — unclear precedence

### Consolidation
- Agent delegation rules split across CLAUDE.md:82-95 and rules/request-routing.md:44-60 — could merge
```

---

## Phase 4 — STALENESS CHECK

Flag the following:

1. **Past dates** — any reference to specific dates that have already passed (e.g., "Last updated: 2025-03-01")
2. **Financial data older than 30 days** — check `personal-finance-health.md` and any embedded financial data; flag if last review date is >30 days ago
3. **Skills not invoked in 30+ days** — check `Documents/Field-Notes/Logs/` for skill invocation history. Cross-reference against all `@`-tagged skills and skill references in CLAUDE.md. Flag skills with no invocation record in the last 30 days.

Format:

```
### Stale Dates
- rules/personal-finance-health.md:5 — "Last updated: 2026-03-27" (N days ago)

### Stale Financial Data
- rules/personal-finance-health.md — last review 2026-03-27, N days ago. Flag for /financial-advisor refresh.

### Underused Skills (30+ days no invocation)
- /good-morning-demo — no log entry found
- /write-demo — no log entry found
```

---

## Phase 5 — PROPOSALS

Generate an IVE-scored proposal list:

**IVE = Impact × Velocity × Efficiency** (each 1–3, product 1–27)

| Dimension | 1 | 2 | 3 |
|-----------|---|---|---|
| Impact | Minor improvement | Moderate improvement | Significant improvement |
| Velocity | Slow to implement | Medium effort | Quick win |
| Efficiency | Few lines saved | Moderate savings | Many lines saved |

Sort proposals descending by IVE score.

For each proposal:

```
## [IVE: 18] Cut redundant safety rules from CLAUDE.md

**What:** Remove lines 44-52 in Active-Work/CLAUDE.md (git staging rules)
**Why:** REDUNDANT — identical content at rules/safety.md:10-18
**Lines saved:** 9
**Risk:** Low — content preserved at canonical location
**Cite:** Active-Work/CLAUDE.md:44-52 duplicates .claude/rules/safety.md:10-18
```

End with:

```
### Projected Budget
Before: X lines
After (if all proposals accepted): Y lines
Savings: Z lines (N%)
```

---

## Phase 6 — SAVE REPORT

Write the full report to:

```
Documents/Field-Notes/Research/YYYY-MM-DD-Simplification-Scan.md
```

Use today's date. If a file with today's date already exists, **append** a new timestamped section rather than overwriting.

Report header format:

```markdown
# Simplification Scan — YYYY-MM-DD HH:MM

Cold-Start Budget: X lines | Files: N | Run by: /simplify-jules
```

---

## Hard Rules

- **Never auto-edit any file.** Read-only analysis only.
- **All proposals require [Your Name]'s approval** before any changes are made.
- **Cite line numbers everywhere** — every classification, every duplicate, every proposal.
- Use the same proposal pipeline as the retro process: present, discuss, [Your Name] approves, then implement in a separate session.
