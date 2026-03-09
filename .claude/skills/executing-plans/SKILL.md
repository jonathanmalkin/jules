---
name: executing-plans
description: "Execute a written implementation plan with human review between batches. Use when user says 'execute this plan', 'implement the plan', 'run the plan', or has a plan file to work through. Best when the user wants to review progress between batches or the tasks need careful sequencing. Do NOT use for fast autonomous execution — use subagent-driven-development instead."
---

*Adapted from [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent. Heavily customized.*

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Run `/compact` between batches with focus: "Focus on: [current task], [files modified], [decisions made], [next steps]"
- Execute next batch
- Repeat until complete

### Step 5: Deploy (if applicable)

After all tasks complete and tests pass:

1. **Check if the project has a deploy skill** (look in `.claude/skills/` or check available skills)
2. **If deploy skill exists** -> invoke it. Check the project's CLAUDE.md for deployment frequency guidance:
   - Some projects deploy after each task (e.g., Discord bot)
   - Others deploy to staging after all tasks complete (e.g., apps with staging -> approval -> production pipeline)
3. **If no deploy skill** -> skip silently. No need to ask about deployment.

### Step 6: Finalize

After all tasks complete, tests pass, and deployment (if applicable):
1. Run the full test suite one final time
2. Verify all changes are committed
3. Confirm no untracked files that should be committed
4. Report: "All tasks complete. Tests passing. Committed to main."

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess

## Worktree Protection (multi-task plans)

For plans touching code across multiple batches, use `EnterWorktree` at the start to protect main from partial implementations if a session crashes mid-plan:

1. `EnterWorktree` (creates branch from HEAD)
2. Execute all batches in the worktree
3. When all tasks pass + final verification: merge branch to main
4. Worktree cleaned up on session exit

This is optional for small plans but recommended for 5+ task plans.

## Integration

**Related skills:**
- **writing-plans** - Creates the plan this skill executes
- **subagent-driven-development** - Use for same-session execution instead of parallel session
