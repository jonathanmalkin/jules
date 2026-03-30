# Strategic Thinking + Execution

Think through decisions strategically with AI. Execute the rest automatically.

An open source reference implementation built on [Claude Code](https://docs.anthropic.com/en/docs/claude-code). One person's real system for running a solo business — morning briefings, content pipeline, deployment automation, strategic decision-making — with a single AI collaborator that maintains context across all of it.

`17 skills` `5 hooks` `cloud batch` `telegram` `60-90% token savings` `<500 lines in CLAUDE.md`

[GitHub](https://github.com/jonathanmalkin/jules) &#183; [Website](https://builtwithjon.com/jules)

---

## The Problem

Running a business is a continuous loop across a dozen domains — strategy, code, content, ops, finance, people. AI helps you go faster, but speed on individual tasks doesn't move the ball forward.

You still think alone. You lose context at every tool boundary. The strategic thread connecting Tuesday's decision to Friday's deploy lives only in your head.

**The hard part isn't execution. It's thinking clearly and keeping everything connected.**

## What Jules Does

<table>
<tr>
<td width="50%" valign="top">

### Thinks With You

Strategy, decisions, goal decomposition, adversarial review. The cofounder you don't have.

- Socratic dialogue that sharpens thinking
- Surfaces blind spots and second-order effects
- Disagrees when it sees a better path
- Connects today's work to long-term goals

</td>
<td width="50%" valign="top">

### Then Executes

Software, content, research, deploys, analytics — one system, same context.

- Decisions flow directly from thinking to execution
- No context loss between "what should we build" and "build it"
- Ships code, publishes content, manages projects
- Handles the details so you focus on direction

</td>
</tr>
</table>

## The Loop in Action

**Think → Build → Ship**

> "We need to reposition the brand."
> 1. `/think` — Socratic dialogue surfaces the real problem: messaging doesn't match the audience
> 2. `/build` — Scope the website changes, plan the implementation, execute
> 3. Deploy, verify live, report at wrap-up

**Think → Write → Distribute**

> "That article isn't landing."
> 1. `/think` — Identify why: too abstract, not enough practitioner detail
> 2. `/write` — Rewrite with concrete examples, code blocks, real workflow
> 3. Publish to site, format for Reddit, cross-post to LinkedIn

## Build Your Own

You don't need dozens of configurations to start. One prompt gets you a working system.

### The One-Prompt Starter

Open Claude Code in your project directory:

```
Read my codebase. Create a .claude/CLAUDE.md that describes the project, key
conventions, and common workflows. Then create one skill in .claude/skills/
for the task I do most often.
```

That's it. One CLAUDE.md and one skill. Build up from there.

### Go Deeper

Once you have the basics, point Claude Code at this repo for tailored recommendations:

```
Analyze my current Claude Code setup (CLAUDE.md, .claude/ directory, and codebase) and
compare it against the reference implementation at https://github.com/jonathanmalkin/jules.

1. Read my existing configuration and understand my project, workflow, and goals.
2. Fetch and study the Jules repo README, CLAUDE.md, profiles/, .claude/hooks/,
   .claude/skills/, and docs/architecture.md to understand the patterns.
3. Identify the highest-impact improvements I could make, prioritized by:
   - What I'm missing entirely (e.g., no safety hooks, no decision framework)
   - What I have but could strengthen (e.g., thin CLAUDE.md, no agent personality)
   - What's in Jules that doesn't apply to my situation (skip these)
4. Give me a concrete, prioritized action plan. Start with 2-3 changes I can make today.

Don't try to replicate the whole system. Tell me what would actually help MY setup.
```

<details>
<summary>Manual setup</summary>

1. Fork this repo
2. Copy the `.claude/` directory structure into your project
3. Edit `CLAUDE.md` with your agent's identity and your working style
4. Fill in the profile templates in `profiles/`
5. Start with 2-3 skills and expand based on what you actually need
6. Add hooks for safety only when the probabilistic version isn't reliable enough

Start small. The system grew organically over weeks of daily use. Don't try to build the whole thing on day one.

</details>

## Under the Hood

| Skills | Hooks | Token Savings | CLAUDE.md | Cloud Batch | Environments |
|:------:|:-----:|:-------------:|:---------:|:-----------:|:------------:|
| 17 | 5 | 60-90% via RTK | <500 lines | ON (overnight) | 4 |

## Architecture

### Environments

```
Mac (Interactive Dev)  →  Cloud (Overnight Batch)  →  Telegram (Phone Access)  →  Cloud Web (Remote Sessions)
```

No VPS, no Docker, no daemons. The Mac handles everything interactive. The Cloud handles everything scheduled.

### Five-Layer Model

```
┌─────────────────────────────────────────────────────────┐
│  Layer 5: Products         The apps being shipped       │
├─────────────────────────────────────────────────────────┤
│  Layer 4: Automation       Cloud batch (retro,          │
│                            briefing, email)             │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Configuration    CLAUDE.md + Skills + Hooks   │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Operational      Terrain, Briefing,           │
│           State            Documents                    │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Identity         Agent profile, user          │
│                            profile, goals               │
└─────────────────────────────────────────────────────────┘
```

Identity is the foundation. Products are what get shipped. Everything in between exists to connect them.

### Classification Principle

How to decide where a behavior belongs:

| If the behavior is... | It's a... |
|---|---|
| Pattern-matchable, no judgment needed | **Hook** (deterministic, fires on tool calls) |
| A repeatable procedure with defined inputs/outputs | **Script** (invoked by skill, hook, or Cloud task) |
| Requires AI judgment, dialogue, or synthesis | **Skill** (structured conversation) |
| A behavioral rule or preference | **CLAUDE.md section** (loaded every session) |
| Stable identity or context | **Profiles/** (loaded every session) |

## Skills (17)

| Skill | What It Does |
|-------|-------------|
| `think` | Recursive decomposition + advisory. Altitude system for goals, adversarial review for decisions. |
| `build` | Software dev end-to-end: scope, plan, execute, deploy. |
| `write` | Content production: seed to platform-ready output across all channels. |
| `research` | Standalone research with persistence and cross-session pickup. Living documents. |
| `debug` | Systematic debugging: hypothesize, test, narrow. |
| `replies` | Check X mentions, draft replies, post approved ones. |
| `good-morning` | Interactive walkthrough of the morning briefing (10 sections). |
| `wrap-up` | End-of-session: issue capture, report, ship. 3 phases. |
| `stop-slop` | Structural audit for AI writing patterns. |
| `pdf` | PDF operations. |
| `plane` | Plane.so interface: MCP tools + gap scripts + reconciliation. |
| `send-email` | Send email via Resend. |
| `financial-advisor` | Personal finance planning. |
| `generate-image-openai` | Image generation with iterative two-phase workflow. |
| `search-history` | Search session documents. |
| `skill-creator` | Create and modify skills. |
| `agent-browser` | Browser automation. |

## Hooks (5)

Hooks are deterministic. The LLM doesn't decide whether to run them — they fire on every matching tool call.

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `safety-guard.sh` | PreToolUse: Bash, WebFetch, Write, Edit | Unified security: command blocking, secret scanning, financial data guard, domain blocking |
| `notify-input.sh` | PostToolUse | Desktop notification when agent needs input |
| `rtk-rewrite.sh` | PreToolUse: Bash | RTK token optimization rewrites (60-90% savings on dev operations) |
| `session-start.sh` | SessionStart | Git pull on session open |

## Cloud Batch

One overnight task, three sequential phases:

| Phase | What It Does |
|-------|-------------|
| Retro + Memory | Analyze recent sessions, propose CLAUDE.md changes, prune stale items |
| Morning Briefing | Assemble 10-section briefing from Plane, Reddit, Gmail, git log, retro output |
| Email Fetch | Pull and categorize inbox |

## Evolution

| Version | What Changed |
|---------|-------------|
| **v1** — Identity + Skills | Initial release: skills, rules, hooks, agents, profile templates |
| **v2** — Infrastructure | Container infrastructure, scheduled automation, Slack daemon |
| **v3** — Planning + Research | Goal decomposition, deep research, security hooks, dispatch conventions |
| **v4** — Simplification | 32→17 skills, 15→5 hooks, rules absorbed into CLAUDE.md, VPS/Docker eliminated, Cloud batch, Telegram, RTK |

## Design Decisions

**Deterministic over probabilistic.** When a pattern works, codify it into a script. Skills are probabilistic (the LLM might follow them). Hooks and scripts are deterministic (they execute the same way every time). Push behavior toward determinism whenever possible.

**Identity persistence over memory.** Memory is lossy. Context windows reset. The CLAUDE.md hierarchy loads identity, decision rules, and behavioral patterns into every session. The agent doesn't need to remember who it is — it's told every time.

**Simple over complex.** The v3 to v4 transition proved this. 15 hooks doing 15 things became 1 hook doing the same 15 things. 20 rules files became CLAUDE.md sections. A Docker container with 9 cron jobs became one Cloud scheduled task. Same capabilities, half the maintenance.

**Explicit autonomy boundaries.** No ambiguity about what the agent can do on its own. The "Just Do It / Ask First" framework with standing orders eliminates the gray zone that makes autonomous agents unreliable.

**Minimal engineering.** Leverage Claude Code's built-in features (plan mode, skills, hooks) before building custom infrastructure. Don't build what a config option handles. Before adding something new: can an existing feature handle this?

## Acknowledgments

Five skills in this system were adapted from [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent (MIT License): `scope`, `writing-plans`, `executing-plans`, `subagent-driven-development`, and `systematic-debugging`. Each has been heavily customized and consolidated (all four are now part of `/build`) but the core methodologies originate from that project.

## License

MIT. Use it, adapt it, build on it.
