---
name: decompose
description: "Handle high-altitude goals (life goals, strategic initiatives, project
scope at Altitude 0-2) through a Socratic dialogue. Use when [Your Name] says 'I want
to...', 'what would it take to...', 'explore whether we should...', 'help me figure
out [big goal]', or gives a goal that's bigger than a single project. Do NOT use for
specific implementation tasks (use /scope), debugging (use /systematic-debugging),
decisions already scoped (use /advisory), or simple requests (use Quick tier)."
---

# Decompose — Altitude 0-2 Goals

<HARD-GATE>
Do NOT present a full phase breakdown upfront or ask multiple questions at once.
One question, one answer, then proceed. The plan emerges from dialogue, not from
an upfront plan dump.
</HARD-GATE>

## Altitude Reference

```
ALTITUDE 0 — Life Goals       "Build a profitable business", "improve my health"
ALTITUDE 1 — Strategic Init   "Be a recognized AI builder voice", "launch X product"
ALTITUDE 2 — Project Scope    "Build the quiz results flow", "run a conversion experiment"
ALTITUDE 3 — Task Cluster     "Design the data model for X" <- /scope handles this
ALTITUDE 4 — Atomic Task      "Write schema for interest categories" <- execute directly
```

Full phase definitions and worked examples: `Documents/Field-Notes/goal-decomposition-system.md`

---

## Step 0: Altitude Check + Fast-Path

Classify the input:

- **Altitude 3+** (specific project, task cluster, atomic task): Announce the fast-path and invoke `/scope` immediately. Don't run the dialogue.
- **Altitude 0-2** (life goal, strategic initiative, broad project scope): Continue to Step 1.

**Ambiguity test:** If it could be either, ask one question: "Is this about what to build or whether/why to build it?" Scope = what to build. Decompose = whether/why/how big.

---

## Step 1: Brain Dump Parsing

Follow the `intent-extraction` rule. Voice dictation is stream-of-consciousness -- later statements win. Confirm the interpreted goal in one sentence before proceeding.

> "Here's what I'm hearing: [goal in one sentence]. That right?"

Don't proceed until confirmed. Corrections update the working goal statement.

---

## Step 2: Research Phase (Parallel, Autonomous)

Before asking questions, dispatch research agents to gather context. Run in parallel:

**Local research** (Haiku Explore subagent):
- `~/workspace/Documents/Terrain.md` -- is this already underway?
- `~/.claude/plans/` -- prior research or design docs on this topic
- `~/workspace/Documents/Field-Notes/Decision-Log.md` -- related past decisions
- Relevant code or docs if the goal touches an existing project

**Web research** (Sonnet subagent, only when competitive/market/external context is needed):
- Competitive landscape, existing tools, community approaches

Present findings as a compact 3-5 bullet summary. Then: one question to validate direction.

---

## Step 3: Blocking Clarifications Only

Ask at most one question per message. Only blocking questions -- things you genuinely can't proceed without.

Non-blocking questions go to the Decision Queue in Terrain.md, not to [Your Name] right now.

**Blocking:** Without this answer, all paths diverge (e.g., "Is this a product extension or a standalone new thing?")
**Non-blocking:** Preference question that doesn't affect the framing (e.g., "What should we name it?")

When you have enough to proceed, proceed autonomously.

---

## Step 4: Framing Dialogue

Build toward a framing statement by exploring:
- What is this, exactly? (One sentence.)
- Who's it for? (Specific, not "everyone.")
- What's the minimum version that validates the concept?
- What's the biggest risk or unknown?

One question at a time. Adapt based on answers -- don't run through the list mechanically.

**If a strategic decision surfaces** (should we do this at all? which market? pivot vs. extend?): chain to `/advisory`. Return here after the decision is made.

**When framing is confirmed:** Write a 2-3 sentence framing statement. Get approval. Then update Terrain.md `## Initiatives` section with:

```markdown
### [Initiative Name]
- **Altitude:** [0/1/2] -- [Life Goal / Strategic Initiative / Project Scope]
- **Status:** Phase 4 -- Framing (confirmed)
- **Blockers:** [None / list]
- **Plan file:** `~/.claude/plans/YYYY-MM-DD-[initiative-name]-decompose.md`
```

---

## Step 5: Requirements (Lightweight Draft)

Generate compact requirements -- key decisions only, not a full spec. Cover:
- What it does (3-5 bullets, user-facing behavior)
- What it doesn't do (explicit exclusions -- "YAGNI ruthlessly")
- Dependencies on other work
- Known risks

Present as a short list. Get approval. Save to plan file.

---

## Step 6: Architecture (Technical Goals Only)

Skip this step for non-technical goals (reputation, partnerships, life goals).

For technical goals:
- If stack or design decisions are needed: chain to `/advisory` for the decision, then return here.
- Otherwise: sketch the architecture in 3-5 bullets (components, data flow, integrations). Get approval.

---

## Step 7: Terminal Handoff

Chain to `/writing-plans` for implementation milestone breakdown.

Update Terrain.md `## Initiatives`:
```
- **Status:** Phase 7 -- Handed off to /writing-plans
```

---

## Process Visibility

Announce every step with a bold header:

- **Altitude check** -- Step 0
- **Brain dump parsing** -- Step 1
- **Research** -- Step 2
- **Clarifying question** -- Step 3
- **Framing** -- Step 4
- **Requirements** -- Step 5
- **Architecture** -- Step 6 (technical only)
- **Handoff to /writing-plans** -- Step 7

---

## Key Principles

- **One question at a time** -- Never ask multiple questions in one message.
- **Multiple choice preferred** -- Voice-dictation-friendly.
- **Later statements win** -- When dictation contradicts itself, trust the later statement.
- **Dialogue, not waterfall** -- The plan emerges from conversation. No phase dumps.
- **Research before questions** -- Run the research phase (Step 2) before asking anything.
- **Lightweight scaffolding** -- Each phase is 2-5 bullets, not a full doc.
- **Explicit chains** -- Every handoff to `/advisory`, `/scope`, or `/writing-plans` is announced.
- **Challenge the frame** -- The first goal statement is often not the real goal. Surface assumptions.
