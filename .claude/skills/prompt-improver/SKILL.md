---
name: prompt-improver
description: "Audit and rewrite Claude Code prompt artifacts: CLAUDE.md files, SKILL.md files, agent prompts, and rules files. Analyzes against type-specific best practices, walks through issues by severity, and rewrites with approval. Use when the user says 'improve this prompt', 'rewrite this skill', 'audit this CLAUDE.md', 'make this agent prompt better', 'clean up this rules file', 'optimize this prompt', 'review this skill', 'tighten this up', or invokes /prompt-improver. Do NOT use for implementation plans (use /review-plan), code review, general document editing, or evaluating whether prompt content is correct for the use case."
---

# Prompt Improver

Audit and rewrite Claude Code prompt artifacts against type-specific best practices. Guided rewrite: analyze, walk through changes, get approval, save.

## When to Use

- CLAUDE.md files (project or user level)
- SKILL.md files (any skill)
- Agent prompts (`.claude/agents/*.md`)
- Rules files (`.claude/rules/*.md`)
- Pasted prompt content (will ask for type)

## When NOT to Use

- Implementation plans, architecture docs (use `/review-plan`)
- Code review or general document editing
- Evaluating whether the prompt's content is correct for its use case
- Code files, READMEs, or non-prompt documents

<HARD-GATE>
Do NOT modify files without explicit user approval. Present the full audit and proposed changes first. The user decides what gets applied.
</HARD-GATE>

---

## Phase 1: Identify

**Status: `[IDENTIFY]`**

Read the target. Accept input as:
- A file path (read it)
- Pasted content (ask: "What type of artifact is this? CLAUDE.md / SKILL.md / Agent prompt / Rules file")
- A reference like "the scope skill" or "my CLAUDE.md" (resolve the path, then read)

Detect the artifact type from:

| Signal | Type |
|--------|------|
| Path contains `CLAUDE.md` or content has `@file` references | CLAUDE.md |
| Path under `.claude/skills/` or frontmatter has `name:` + `description:` | SKILL.md |
| Path under `.claude/agents/` or frontmatter has `allowed-tools:` | Agent prompt |
| Path under `.claude/rules/` or single-topic instructional format | Rules file |

Report: "This is a **[type]** — [line count] lines. Running audit."

### @file References in CLAUDE.md

When auditing a CLAUDE.md that uses `@file` references: audit the main file only. Note which files are referenced and suggest running the skill on any that look like they'd benefit from a separate audit. Do not recurse into them.

---

## Phase 2: Audit

**Status: `[AUDIT]`**

Load `references/audit-checklists.md`. Run the checklist for the detected type against the content.

Produce an audit summary grouped by severity:

**Severity levels:**
- **Critical** — Actively harmful. Will cause Claude to misfire, ignore instructions, or behave incorrectly. (Conflicting rules, dead references, missing scope boundaries, instructions that contradict each other.)
- **Worth Fixing** — Missing best practice that degrades quality. (No anti-patterns section, vague triggers, passive language throughout, missing "when NOT to" block.)
- **Minor** — Polish. (Heading structure could be better, a single vague sentence in an otherwise sharp file, slightly verbose section.)

Present the audit as a numbered list, grouped by severity:

```
## Audit Results

### Critical (X)
1. [issue] — [one-line explanation]
2. ...

### Worth Fixing (X)
3. [issue] — [one-line explanation]
4. ...

### Minor (X)
5. [issue] — [one-line explanation]
6. ...
```

Then ask: **"Walk through one by one, or apply all and show the diff?"**

If zero issues found: "Clean bill of health. Nothing to fix." Stop.

---

## Phase 3: Rewrite

**Status: `[REWRITE]`**

Two modes. Default is **full rewrite**. Switch to **guided mode** if the user says "walk me through it" or there are 8+ issues.

### Full Rewrite (default)

Apply all Critical + Worth Fixing changes. Show the complete rewritten file with a summary of what changed and why. Minor issues: apply silently if the fix is trivial (one word, formatting), otherwise skip and note them.

Present: "Here's the rewritten version. [N] changes applied. Ready to save?"

### Guided Mode

Present each issue one at a time, critical first:

```
**Issue #[N]: [title]** ([severity])

Before:
> [exact current text]

After:
> [proposed replacement]

**Why:** [one sentence]

→ Apply / Skip / Modify?
```

Batch trivial fixes: if 3+ Minor issues are simple formatting/wording tweaks, present them as a group: "These 4 minor tweaks are all formatting polish. Apply all? [list them]"

---

## Phase 4: Summary

**Status: `[SUMMARY]`**

After all changes are decided, show a diff-style changelog:

```
## Changes Applied

- [what changed] — [why] (line ~N)
- [what changed] — [why] (line ~N)
- ...

Skipped: [list any skipped issues, if any]
```

Then: **"Save to [original path]?"**

If the user approves, write the file. If the input was pasted content (no file path), ask where to save or offer to copy to clipboard.

---

## Anti-Patterns

1. **Rewriting content, not structure.** This skill improves how prompts are structured and expressed, not whether the underlying instructions are correct for the use case. Don't second-guess domain logic.
2. **Recursive auditing.** Don't follow `@file` references into other files. Note them, suggest separate runs.
3. **Over-fixing Minor issues.** If the file is already solid and only has Minor items, say so. Don't inflate the audit to justify changes.
4. **Changing voice/personality.** If a prompt has an intentional voice (like Jules's fox personality), preserve it. Fix structure and clarity, not character.
5. **Adding features.** Don't suggest new sections, capabilities, or behaviors the prompt doesn't have. Improve what's there.
