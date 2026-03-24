---
name: master-plan
description: "Review, triage, and dispatch work from the Grand Plan. Reads all project plans and Terrain.md, classifies tasks by ownership (autonomous/interactive/manual), decomposes vague items, presents decision cards in cognitive-load batches, updates both Grand Plan and Terrain based on decisions, and queues autonomous work for dispatch. Use when the user says 'master plan', 'plan review', 'what should I work on', 'triage my tasks', 'plan dispatch', 'review the grand plan', 'what's actionable', or wants to do a planning session across all projects. Also trigger when the user feels scattered and wants to get organized, or when a big batch of work completes and they want to figure out what's next. Do NOT use for single-project scoping (use /scope), life-goal decomposition (use /decompose), or daily operational briefing (use /good-morning)."
---

# Master Plan

Read the Grand Plan, triage everything actionable, present decisions, update plans, queue work.

This is an on-demand planning skill for when things feel scattered, a batch of work just completed, or new ideas have piled up. It bridges the gap between the Grand Plan (strategic) and Terrain (operational) by scanning both, surfacing what needs attention, and routing work to the right executor: the agent autonomously, [Your Name] interactively, or [Your Name] manually.

Interim skill. Designed to be replaced or modified when a proper workflow management system is in place.

## Step 0: Scope

Check if the user passed project names as arguments (e.g., `/master-plan content infrastructure`).

- **With args:** Scan only the named projects under `Documents/Grand-Plan/projects/`.
- **No args (default):** Scan everything, but filter aggressively. Only surface items that are actionable NOW: not completed, not blocked, not scheduled for a future date. Rank by a combination of dependency position (unblocking other tasks ranks higher), staleness (untouched > 7 days), and alignment with Terrain's Now section.

Announce: **"Scanning [scope]. Filtering to actionable items."**

## Step 1: Gather Context

Read in parallel (dispatch Explore subagents on Haiku where it saves time):

1. **Grand Plan task-breakdowns:** `Documents/Grand-Plan/projects/*/task-breakdown.md`
2. **Pending decision cards:** `Documents/Grand-Plan/projects/*/decisions-needed.md`
3. **Terrain.md** -- the live operational state (Now, Queue, Decision Queue, Waiting On)
4. **Recent handoffs:** `Documents/Grand-Plan/projects/*/handoffs/*-result.md` (skim for status and unresolved issues)

Build a working list of every uncompleted task across all scanned projects. For each task, capture:
- Task ID, title, project
- Type (`auto` / `interactive` / unmarked)
- Dependencies and blocked status
- Estimated time
- Whether it has a session-spec or prompt file
- Staleness (days since last touch)

## Step 2: Classify

For each task on the working list, assign an ownership category:

| Category | Criteria | What happens next |
|----------|----------|-------------------|
| **Auto** | Marked `auto` with a `session-spec:` or prompt file. Clear scope, no decisions needed. | Queued for dispatch |
| **Interactive** | Marked `interactive`, or has `decision:` field, or requires [Your Name]'s judgment mid-task | Surfaced as a session [Your Name] should run |
| **Manual** | Requires [Your Name] to do something outside Claude (phone call, physical action, login, payment) | Listed with exact action needed |
| **Needs decomposition** | No type marker, vague title, no session-spec, estimated >60m, or scope unclear | Flagged for inline or separate decomposition |
| **Blocked** | Has unmet `deps:` or `blocked-on:` | Listed separately with what's blocking it |

Tasks already marked `auto` or `interactive` in the Grand Plan keep their classification unless something has changed (e.g., a dependency resolved, making a blocked item actionable).

Announce: **"Found [N] actionable items across [M] projects. [X] auto, [Y] interactive, [Z] manual, [W] need decomposition, [B] blocked."**

## Step 3: Decompose (Hybrid)

For tasks flagged as "needs decomposition":

**Quick decomposition (inline):** If the task is <60m estimated and the scope is reasonably clear from context (Grand Plan spec, Terrain notes), propose subtasks right here with `auto`/`interactive`/`manual` labels. Present as a decision card for approval.

**Complex decomposition (defer):** If the task is >60m, scope is unclear, or it touches multiple projects, flag it for a separate `/decompose` or `/scope` session. Add it to the decomposition batch in Step 4.

The goal is to avoid blocking the planning session on deep scoping work while still resolving the easy ones.

## Step 4: Present Decision Batches

Group all items requiring [Your Name]'s input into four batches, presented sequentially. Each batch has a consistent cognitive demand level so [Your Name] can shift gears between batches rather than context-switching per item.

### Batch 1: Quick Approvals
Binary yes/no decisions. Low risk. Reversible. Examples: approve a queued auto task, confirm a completed item can be archived, approve an inline decomposition.

Format per item:
```
**[APPROVE]** `<task-id>` -- <one-line summary>
Action: <what happens on yes>
Risk: <low/none> | Reversible: yes
-> Approve / Skip / Discuss
```

### Batch 2: Direction Calls
Strategic decisions that affect scope, priority, or approach. These need more context and possibly discussion. Pull from both the Grand Plan `decisions-needed.md` files and Terrain's Decision Queue.

Format per item:
```
**[DIRECTION]** <topic>
Context: <2-3 sentences>
Rec: <agent's recommendation>
Trade-off: <what you gain vs. what you give up>
Reversible? <yes/no>
-> Approve Rec / Choose Alternative / Discuss / Defer
```

### Batch 3: Blockers
Items that are stuck and need [Your Name]'s input to unblock downstream work. These are inherently urgent because other tasks depend on them.

Format per item:
```
**[BLOCKER]** `<task-id>` -- <what's stuck>
Blocked: <list of downstream tasks waiting on this>
Options: <A, B, or C>
Rec: <which option and why>
-> Choose A / B / C / Discuss
```

### Batch 4: Decomposition Proposals
Tasks the skill decomposed inline (from Step 3) plus tasks flagged for separate decomposition.

For inline decompositions:
```
**[DECOMPOSE]** `<task-id>` -- <original vague task>
Proposed breakdown:
  - `<sub-id-1>` | <subtask> | auto | est:Xm
  - `<sub-id-2>` | <subtask> | interactive | est:Ym
  - `<sub-id-3>` | <subtask> | manual | est:Zm
-> Approve / Modify / Defer to /decompose
```

For deferred decompositions:
```
**[NEEDS SCOPING]** `<task-id>` -- <task title>
Why: <too complex for inline decomposition -- estimated >60m, unclear scope, multi-project>
Suggested: Run `/decompose` or `/scope` in a separate session
-> Acknowledge / Discuss
```

Present one batch at a time using AskUserQuestion with clickable options (up to 4 questions per call). For binary decisions, use Approve/Skip options. For direction calls, offer 2-4 concrete alternatives. Wait for responses before moving to the next batch. Skip empty batches.

### Processing Free-Text Answers

When a user provides a free-text answer (not a simple approve/skip), analyze the response for:
1. **Decision cleared:** A blocker or decision point was resolved. Update immediately.
2. **New question surfaced:** The answer raises a follow-up decision. Add to the current or next batch.
3. **Research needed:** The answer requires investigation before a decision can be made. Queue an auto research task.
4. **Reframing:** The answer changes how the item should be understood. Update the item's description and re-classify.

## Step 4b: Convergence Loop

After all 4 batches are complete, re-scan the working list. Decisions in earlier batches may have:
- Unblocked items that were previously blocked
- Created new decision points from free-text answers
- Spawned new auto tasks that themselves have decision prerequisites

If new actionable decisions exist, run another pass through the batches (only the new/changed items). Repeat until the system converges: no more decisions need [Your Name]'s input, and everything remaining is either queued for autonomous work or explicitly deferred.

The goal: by the time the skill exits, [Your Name]'s decision-making bottleneck is fully drained for this cycle.

## Step 5: Apply Decisions

After convergence:

### Update Grand Plan
- Mark approved tasks with updated metadata in the relevant `task-breakdown.md`
- Add approved inline decompositions as new task entries
- Remove or update resolved decision cards from `decisions-needed.md`
- Update completion dates for anything marked done during the session

### Update Terrain.md
Re-read Terrain.md immediately before editing (sync tools can modify it between reads).

- **Queue:** Add approved auto tasks that aren't already there. Include `| auto | est:Xm` metadata.
- **Now section:** Update with any new interactive or manual tasks for today/tomorrow.
- **Decision Queue:** Remove resolved decisions. Add any new ones surfaced during the session.
- **Waiting On:** Update if any blockers changed status.
- **Projects table:** Update status and next-action columns for affected projects.

Announce: **"Updated [N] items in Grand Plan, [M] items in Terrain."**

## Step 6: Summary and Handoff

Present a session summary:

```
## Master Plan Session Summary

**Decisions made:** [count]
**Auto tasks queued:** [count] (ready for dispatch)
**Interactive sessions needed:** [count]
**Manual actions for [Your Name]:** [count]
**Deferred to /decompose:** [count]

### Auto Queue (dispatch when ready)
- `<task-id>` -- <title> | est:Xm
- ...

### Interactive Sessions
- `<task-id>` -- <title> | est:Xm | <what's needed>
- ...

### Manual Actions
- <action> -- <context>
- ...

### Deferred Scoping
- `<task-id>` -- <title> | suggested: /decompose or /scope
- ...
```

Do not auto-dispatch. The user triggers dispatch separately (via `dispatch.sh`, subagent teams, or individual sessions).

## Key Principles

**Actionable over comprehensive.** The Grand Plan has dozens of items. The skill's job is to surface the 5-15 that matter RIGHT NOW, not to present a full inventory. Filter aggressively.

**Decisions are the bottleneck.** [Your Name]'s decision-making time is the scarcest resource. Every item presented should genuinely need their input. If the agent can make the call autonomously (per standing orders), do it and report at wrap-up instead.

**Batch by cognitive load.** Quick approvals first (warm up), direction calls second (deep thinking), blockers third (urgency), decomposition fourth (creative). This respects how brains work.

**Update both systems.** Grand Plan is the strategic record. Terrain is the operational dashboard. Both must stay in sync. Grand Plan is the source of truth for task definitions; Terrain is the source of truth for what's happening today.

**Queue, don't dispatch.** This skill is a planning session, not an execution engine. It queues work for dispatch. [Your Name] decides when and how to trigger execution. This keeps the planning and execution concerns separate.

**Dependency-driven, not calendar-driven.** Only assign dates when there's a real external deadline (appointment, publication date, expiration). Everything else is dependency chains: "next in queue when unblocked." The skill's job is to remove blocks, not schedule days. "As soon as prerequisites are done" is the default state for all non-deadline items.

**Interim by design.** This skill will be replaced or modified when a workflow management system is in place. Keep it simple. Don't build elaborate state tracking. Lean on the existing file-based system.
