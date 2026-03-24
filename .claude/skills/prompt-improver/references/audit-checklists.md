# Audit Checklists

Type-specific checks for prompt artifacts. Each check includes severity default and what to look for.

---

## CLAUDE.md (12 checks)

### Critical

1. **Conflicting rules.** Two instructions that contradict each other. Claude will follow one unpredictably. Scan for rules that say "always X" and "never X" about the same thing, or overlapping scopes with different instructions.

2. **Dead references.** `@file` references or file paths that point to files that don't exist. Check with Glob. These cause silent failures (Claude sees "file not found" and moves on).

3. **Vague rules without conditions.** "Be careful with X" or "Use good judgment about Y." These produce inconsistent behavior. Every rule needs a concrete trigger and action: "When X happens, do Y."

### Worth Fixing

4. **Line count over 200.** CLAUDE.md is loaded every conversation turn. Bloat degrades quality on everything. If over 200 lines, identify what can move to `@file` references, rules files, or skill references.

5. **Priority placement.** The first 5 and last 5 lines get the most attention. Check: are the most critical instructions at the top? Is there filler or boilerplate occupying prime real estate?

6. **Missing "when NOT to" blocks.** Rules that say when to do something but not when to skip it. Negative boundaries prevent over-application.

7. **Corporate/passive language.** "It is recommended that..." "Consider using..." "You may want to..." These are soft suggestions Claude will often ignore. Rewrite as direct imperatives: "Use X when Y."

8. **Linter traps.** Instructions that look like they apply to all code but actually apply to specific contexts. "Always use TypeScript" when Python files also exist. "Never use `any`" when some vendor types require it.

9. **Progressive disclosure missing.** Everything dumped at the top level when some instructions belong in `@file` references loaded on demand. Rule of thumb: if a section is >20 lines and only relevant to specific tasks, extract it.

### Minor

10. **Heading structure.** Inconsistent heading levels, missing section breaks, wall-of-text sections without scannable structure.

11. **Conditional specificity.** Rules like "for large files, use X" without defining "large." Quantify thresholds.

12. **Redundancy with loaded profiles.** Instructions that duplicate what's already in always-loaded `@file` references. Extra tokens, no extra signal.

---

## SKILL.md (14 checks)

### Critical

1. **Missing or vague trigger phrases.** The `description` field in frontmatter IS the trigger. If it's generic ("helps with prompts"), Claude can't match it to user intent. Needs specific phrases users actually say.

2. **No scope boundary.** Missing "When NOT to Use" or "Do NOT use for" section. Without this, Claude routes ambiguous requests to the skill incorrectly.

3. **Conflicting instructions.** Two phases or sections that tell Claude to do opposite things. Common: a hard gate that conflicts with a later shortcut.

### Worth Fixing

4. **Missing negative triggers.** The description says when to use but doesn't exclude similar skills. If `/scope` and `/advisory` overlap, the description must disambiguate.

5. **Passive language in instructions.** "You might want to check..." "Consider running..." These are optional suggestions. Skills need imperatives: "Check X." "Run Y."

6. **No anti-patterns section.** Without explicit "don't do this" examples, Claude will discover the failure modes through trial and error. Document the known ones.

7. **Missing hard gate.** If there's a critical precondition (don't code before approval, don't post before review), it needs a `<HARD-GATE>` block, not a soft instruction.

8. **Phase structure unclear.** If the skill has multiple phases, each needs: a status label, clear entry/exit criteria, and what happens if a phase fails or is skipped.

9. **Line count over 500.** Skills over 500 lines dilute attention. Identify what can move to `references/` files.

10. **No examples.** For skills that transform input, at least one before/after example. For skills that produce output, at least one sample output format.

### Minor

11. **Frontmatter description length.** Under 20 words is too terse for reliable matching. Over 100 words dilutes signal. Sweet spot: 40-80 words with specific trigger phrases.

12. **Troubleshooting section missing.** Common failure modes and how to recover. Not critical but saves time on repeat runs.

13. **References overflow.** Reference files over 300 lines or more than 3 reference files. Sign of scope creep. Can anything be inlined or removed?

14. **Process visibility.** Status labels like `[PHASE]` help the user track where they are. Missing labels make long skills feel opaque.

---

## Agent Prompts (8 checks)

### Critical

1. **Missing scope boundary.** What the agent does AND does not do. Agents without "do NOT" rules will attempt anything that vaguely matches, burning tokens and producing garbage.

2. **No output format.** What does the agent return? A summary? A file? A list? If the caller doesn't know what to expect, they can't use the result.

3. **Missing "do NOT" rules.** Explicit prohibitions for the most common misuses. Without these, agents will cheerfully do the wrong thing when given ambiguous input.

### Worth Fixing

4. **Context richness.** Does the agent know enough to do its job? Check: does it reference the files/dirs it needs? Does it know the project structure? An agent that has to discover everything from scratch wastes tokens on exploration.

5. **Communication back.** For team agents: does the prompt explain how to report results? Missing this = agent completes work silently, team lead never finds out.

6. **Model guidance missing.** If the agent should run on a specific model (Haiku for speed, Opus for complexity), say so. Default model selection may be wrong for the task.

7. **Failure handling.** What should the agent do when it can't complete the task? Report the error? Retry? Ask? Without guidance, agents either silently fail or loop.

### Minor

8. **Corporate hedging.** "You should try to..." "Attempt to..." Agents need direct instructions. "Do X" not "Try to do X."

---

## Rules Files (7 checks)

### Critical

1. **Not actionable.** The rule describes a concept but doesn't specify what Claude should DO differently. Every rule needs a concrete behavior change: "When X, do Y instead of Z."

2. **Missing substitution pairs.** Rules that say "don't do X" without saying what to do instead. Claude needs the replacement, not just the prohibition. Format: "NEVER [bad]. Instead: [good]."

### Worth Fixing

3. **Missing edge cases.** The rule handles the common case but not the exceptions. "Always use Haiku for research" but what about research that requires synthesis? Document the edge cases.

4. **No workaround documented.** When the rule blocks a legitimate action, what's the escape hatch? "NEVER use `rm`. Instead: `mv` to `~/.Trash/`" is a complete rule. "NEVER use `rm`" without alternatives leaves Claude stuck.

5. **Missing examples.** Rules with concrete examples are followed more reliably. One good/bad example pair per rule.

6. **Trigger clarity.** When does this rule activate? If it's not obvious from context, add a "When to Apply" section.

### Minor

7. **Internal consistency.** Does the rule file contradict itself? Does it reference concepts defined elsewhere without linking? Cross-check within the file.
