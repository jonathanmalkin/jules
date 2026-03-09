---
name: writing-plans
description: "Design implementation plans for multi-step coding tasks before writing any code. Use when user says 'plan this', 'write a plan', 'how should we implement this', or has requirements/specs for a feature, refactor, or fix that will touch multiple files. Also use when a task is complex enough that jumping straight to code would be risky. Do NOT use for single-file changes or trivial fixes."
---

*Adapted from [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent. Heavily customized.*

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `~/.claude/plans/YYYY-MM-DD-<feature-name>.md`

**Show the plan file path** at the start so the user can review it live in their editor.

**Plan summary format:** Include all user prompts (original + follow-ups) in the plan's `## Decision Brief` > `Prompts used` section.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Structure

**Every plan MUST follow this structure:**

```markdown
# [Feature Name] Plan

> **For Claude:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task.

## Goal
[One sentence]

## Approach
[2-5 sentences: architecture, key tradeoffs, tech stack. No code blocks.]

---

## Implementation Detail

### Task 1: [Name]
[TDD steps, code blocks, exact commands — all task content lives here]

### Task N: [Name]
...

---

[Decision Brief (Recommendation, Actions, Needs your input, Prompts used) appended by review-plan. Review Notes for Standard+ tier.]
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Pre-Execution Review

After saving the plan file, run `/review-plan` on it. The review skill auto-classifies the plan into a tier (Light / Standard / Deep) and runs proportional review depth.

A PostToolUse hook reminds you to run review-plan when you save to `~/.claude/plans/`. A PreToolUse hook blocks ExitPlanMode until the plan has a `## Decision Brief`.

Workflow:
1. Save the plan to `~/.claude/plans/YYYY-MM-DD-<feature-name>.md`
2. Run `/review-plan` — it classifies tier and runs the appropriate depth
3. THEN call ExitPlanMode — the user sees the reviewed plan

The user should never see a first draft. They see the already-improved version.

## Execution Handoff

After the plan passes review, offer execution choice:

**"Plan reviewed and ready. Executing with subagent-driven-development (fresh subagent per task, two-stage review)."**

- **REQUIRED SUB-SKILL:** Use subagent-driven-development
- Stay in this session
- Fresh subagent per task + spec compliance review + code quality review

**If user requests batch execution instead:**
- Guide them to open new session
- **REQUIRED SUB-SKILL:** New session uses executing-plans
