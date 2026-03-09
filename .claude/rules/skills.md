---
paths:
  - "**/skills/**"
---

# Skill Conventions

Follow these rules when creating or modifying Claude Code skills. Distilled from Anthropic's "Complete Guide to Building Skills for Claude" (March 2026, 33pp).

## File Structure

- Folder name: `kebab-case` (no spaces, underscores, or capitals)
- Main file: exactly `SKILL.md` (case-sensitive -- not `skill.md`, `SKILL.MD`, etc.)
- Optional subdirectories: `scripts/`, `references/`, `assets/`
- No `README.md` inside skill folders -- all documentation goes in SKILL.md or `references/`

## Frontmatter (Required)

Every SKILL.md must start with YAML frontmatter between `---` delimiters:

```yaml
---
name: my-skill-name
description: What it does and when to use it. Include specific trigger phrases.
---
```

### `name` field
- kebab-case only, no spaces or capitals
- Must match the folder name
- Must not start with "claude" or "anthropic" (reserved)

### `description` field
- Structure: `[What it does] + [When to use it] + [Key capabilities]`
- Must include BOTH what the skill does AND trigger conditions
- Include specific phrases users would say (e.g., "generate an image", "create a picture")
- Under 1024 characters
- No XML angle brackets (`<` or `>`)
- Add negative triggers if the skill could over-trigger ("Do NOT use for...")
- Be specific -- "Processes documents" is too vague; "Processes PDF legal documents for contract review" is correct

### Bad descriptions (avoid)
- Too vague: "Helps with projects."
- Missing triggers: "Creates sophisticated multi-page documentation systems."
- Too technical, no user triggers: "Implements the Project entity model with hierarchical relationships."

## Writing Instructions

- Put critical instructions at the top of the body
- Use `## Important` or `## Critical` headers for key sections
- Use bullet points and numbered lists -- keep instructions concise
- Be specific and actionable: "Run `python scripts/validate.py --input {filename}`" not "Validate the data before proceeding"
- Include error handling: document common failures and how to resolve them
- Include examples showing common scenarios with expected actions/results
- Reference bundled files clearly: "consult `references/api-guide.md` for rate limiting guidance"
- Keep SKILL.md under 5,000 words -- move detailed docs to `references/`

## Progressive Disclosure

Skills load in three levels -- design for this:
1. **Frontmatter** (always loaded): Just enough for Claude to decide when to activate
2. **SKILL.md body** (loaded on activation): Full instructions and guidance
3. **Linked files** in `references/` (loaded on demand): Detailed documentation Claude reads as needed

## Determinism Check

Before saving a new or modified skill, scan each instruction for:
- **Validation rules** (character limits, format checks, required fields) -> should be a script
- **File operations** (move, rename, archive by pattern) -> should be a script
- **Date/time calculations** (staleness, deadlines, age) -> should be a script
- **Pattern matching** (UTM tags, naming conventions, sensitive data) -> should be a script

If an instruction is mechanical (same input -> same output, no judgment needed), write a script
in `.claude/scripts/` and have the skill call it. Don't add more prose.

**Test:** "If 10 different LLMs got this instruction, would they all do exactly the same thing?"
If yes -> script. If no -> keep as instruction.

## Optional Frontmatter Fields

Beyond `name` and `description`, these fields are available:

```yaml
license: MIT                    # For open-source skills
compatibility: Requires Node 18+ and GitHub MCP server  # 1-500 chars, environment needs
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch"    # Restrict which tools the skill can use
metadata:                       # Custom fields
  author: Your Name
  version: 1.0.0
  mcp-server: server-name       # Links skill to an MCP server
  category: productivity
  tags: [automation, workflow]
```

## Problem-First vs Tool-First

**Problem-first:** "I need to set up a project workspace" -- skill orchestrates the right tools. Users describe outcomes; the skill handles tools. Most skills use this approach.

**Tool-first:** "I have Notion MCP connected" -- skill teaches optimal workflows for tools the user already has. The skill provides expertise, not orchestration.

## Design Patterns

Five patterns from Anthropic's guide. Most skills combine elements of several.

| Pattern | Use when | Example |
|---------|----------|---------|
| **Sequential workflow** | Multi-step processes in specific order | deploy-app |
| **Multi-MCP coordination** | Workflows spanning multiple services | engage (Reddit + LinkedIn + X) |
| **Iterative refinement** | Output quality improves with loops | review-plan |
| **Context-aware tool selection** | Same outcome, different tools by context | pdf (different tools per operation) |
| **Domain-specific intelligence** | Skill adds knowledge beyond tool access | growth-audit, content-marketing |

## Iteration Signals

**Undertriggering** (skill doesn't load when it should): add more detail, keywords, and trigger phrases to description. Check if users are manually invoking it.

**Overtriggering** (skill loads for irrelevant queries): add negative triggers ("Do NOT use for..."), be more specific about scope. Consider clarifying scope boundaries.

## Context Budget

With 32 skills enabled, keep SKILL.md sizes lean. Anthropic flags 20-50 simultaneous skills as the evaluation threshold. If a skill grows past ~300 lines, move detailed content to `references/` and link to it.

## Instructions Not Followed

If a skill loads but Claude ignores its instructions:
1. **Too verbose** -- keep instructions concise, use bullet points, move detail to `references/`
2. **Critical stuff buried** -- put must-do instructions at the top under `## Important` or `## Critical`
3. **Ambiguous language** -- "Make sure to validate properly" fails; "CRITICAL: Before calling X, verify: [list]" works
4. **Model laziness** -- add a `## Performance Notes` section: "Take your time", "Quality is more important than speed", "Do not skip validation steps"

## Testing Checklist

Before committing a new or modified skill:
- [ ] Folder is kebab-case
- [ ] File is exactly `SKILL.md`
- [ ] Frontmatter has `---` delimiters, `name`, and `description`
- [ ] `name` matches folder name, is kebab-case
- [ ] `description` includes what AND when (trigger phrases)
- [ ] No XML tags in frontmatter
- [ ] Instructions are clear, actionable, use bullet points
- [ ] Error handling documented for common failures
- [ ] Examples included for typical scenarios
- [ ] Tested triggering on obvious tasks and paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics
- [ ] SKILL.md under 300 lines (or uses `references/` for overflow)
