---
name: build
model: opus
effort: high
description: "Software development end-to-end: scope -> design -> plan -> execute -> deploy. Merges scope, writing-plans, executing-plans, and subagent-driven-development. Use when the user says 'build', 'implement', 'code', 'write a script', 'create a feature', or when /think chains here after identifying a concrete software deliverable."
user-invocable: true
---

# Build

Software development end-to-end: scope -> design -> plan -> execute -> deploy -> ship. Handles the full lifecycle from "I want to build X" to "it's live and committed."

**Arrives from:** Direct invocation, or chained from `/think` when a concrete software deliverable is identified.

---

## Step 0: Scope Verification

**If arriving from `/think`:** Requirements already exist (framing statement, constraints, minimum version). Confirm they're sufficient, then skip to Step 2.

**If standalone invocation:** Run a lightweight scope pass.

1. What exactly are we building?
2. Who uses it? (user, automated system, Jules)
3. What's explicitly out of scope?
4. What's the minimum version that delivers value?

Confirm scope before proceeding. One question at a time, with proposed answers. Don't frontload all questions -- ask, get the answer, then ask the next one.

---

## Step 1: Existing Code Search

Dispatch a parallel Haiku Explore subagent to search for:

- Related code, existing utilities, patterns to reuse
- Project-level CLAUDE.md and config
- Similar implementations in the codebase

Present findings in 3-5 bullets. Don't re-research what was already found in `/think`.

**Reuse over rebuild.** Actively search for existing functions and utilities that can be reused. Never propose new code when a suitable implementation already exists in the codebase.

---

## Step 2: Design

Architecture sketch: 3-5 bullets covering components, data flow, interfaces.

Identify dependencies, risks, and open questions. If major design decisions are needed, surface them as Decision Cards:

> **[DECISION]** Summary | **Rec:** X | **Risk:** Y | **Reversible?** Yes/No

One-way doors get explicit approval before proceeding.

**Design review.** Dispatch a fresh Sonnet subagent with the design sketch. Prompt: "Are we building the right thing? Simpler approach? Edge cases? Missing tests? Feasibility?"

**Self-review (run internally, surface only issues):**

1. **Failure post-mortem:** "3 months from now, this failed. What happened?"
2. **Over-engineering post-mortem:** "3 months from now, this was massive overkill. What didn't we need?"
3. **Unstated assumptions:** What are we assuming without acknowledging?
4. **Open questions:** What would a skeptical reviewer ask?

---

## Step 3: Plan

Break work into batches of 3-7 tasks each. A batch is a logical unit of work that can be reviewed as a set.

Each task includes:

- **File:** File to modify (or create)
- **Action:** What to do (specific action, not vague direction)
- **Verify:** How to confirm it worked (test command, expected output, visual check)

Task granularity: one action per 2-5 minutes (write test -> run it -> implement -> run again -> commit).

Save plan to **both** locations:
1. `~/.claude/plans/YYYY-MM-DD-[description].md`
2. `Documents/Field-Notes/Plans/YYYY-MM-DD-[description].md`

Present plan for approval before executing.

---

## Step 4: Execute

Two modes. **Batch is default.** Autonomous requires explicit opt-in.

### Batch Mode (default)

1. Execute one batch of tasks
2. After each batch: present what was done, what changed, any issues encountered
3. Wait for approval before proceeding to the next batch
4. If a task fails: report the error, retry once if transient, stop and report if persistent. Don't silently swallow errors.

### Autonomous Mode

Only when [Your Name] explicitly says "just run it", "autonomous mode", or "don't wait for me."

1. Dispatch one subagent per independent task using `isolation: "worktree"` for filesystem safety
2. Two-stage review per task:
   - **Stage 1 (spec compliance):** Does the output match the task spec?
   - **Stage 2 (code quality):** Is the code clean, tested, and consistent with project patterns?
3. Continuous progress -- don't wait for human sign-off between tasks
4. Report results when all tasks complete

### Both modes

- Run tests after implementation changes. Don't leave broken code.
- Subagents cannot write to subdirectory repos (`Code/jules/`, `Code/kink-archetypes/`). Main session handles those writes.

---

## Step 5: Deploy

Look up the project-specific deploy process:

| Project | Deploy Command |
|---------|---------------|
| [your-domain] | `Scripts/push-[your-handle].sh` |
| Quiz app | `Scripts/deploy-quiz.sh` |
| Other | Present the deploy command for review before running |

**Verify after deploy:** Check the live URL or service endpoint. "Deploy succeeded" is not the same as "it works."

If no deploy is needed (library code, internal tools), skip this step.

---

## Step 6: Ship

1. Stage specific files for commit (never `git add .` or `-A`)
2. Write a descriptive commit message
3. `git push`
4. If the session is substantial, remind about `/wrap-up`
