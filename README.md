<a id="readme-top"></a>

<div align="center">

# Strategic Thinking + Execution

Most AI tools do tasks. Jules thinks with you first, then does everything else.

An open source reference implementation built on [Claude Code][claude-code-url].

[![License: MIT][license-shield]][license-url]
[![Skills: 17][skills-shield]][skills-url]
[![Hooks: 5][hooks-shield]][hooks-url]
[![Token Savings: 60-90%][tokens-shield]][rtk-url]

[Website][website-url] · [Architecture Docs][architecture-url] · [Get Started](#build-your-own)

</div>

---

<details>
<summary><strong>Table of Contents</strong></summary>

- [The Problem](#the-problem)
- [What Jules Does](#what-jules-does)
- [The Loop in Action](#the-loop-in-action)
- [Build Your Own](#build-your-own)
- [Under the Hood](#under-the-hood)
- [Architecture](#architecture)
- [Skills](#skills-17)
- [Hooks](#hooks-5)
- [Cloud Batch](#cloud-batch)
- [Security & Privacy](#security--privacy)
- [Evolution](#evolution)
- [Design Decisions](#design-decisions)
- [Acknowledgments](#acknowledgments)
- [License](#license)

</details>

---

## The Problem

Running a business is a continuous loop across a dozen domains — strategy, code, content, ops, finance, people. AI helps you go faster, but speed on individual tasks doesn't move the ball forward.

You still think alone. You lose context at every tool boundary. The strategic thread connecting Tuesday's decision to Friday's deploy lives only in your head.

**The hard part isn't execution. It's thinking clearly and keeping everything connected.**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## What Jules Does

<table>
<tr>
<td width="50%" valign="top">

### Thinks With You

Strategy, decisions, challenging assumptions, decomposition. Socratic dialogue, adversarial review. The cofounder you don't have.

- Surfaces blind spots and second-order effects
- Disagrees when it sees a better path
- Connects today's work to long-term goals

</td>
<td width="50%" valign="top">

### Then Executes

Software, content, research, deploys, analytics — one system, same context. Decisions flow directly from thinking to execution. No context loss between "what" and "build it."

- Ships code, publishes content, manages projects
- Handles the details so you focus on direction

</td>
</tr>
</table>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## The Loop in Action

**Think → Build → Ship**

| Step | Prompt | What Happens |
|:----:|--------|-------------|
| **Think** | *"I need to figure out my brand positioning."* | Jules challenges the framing, asks one question at a time, runs adversarial review. We land on a direction together. |
| **Build** | *"Now implement it."* | Jules writes the homepage copy, updates the meta tags, adjusts the CSS, takes screenshots, iterates until it's right. |
| **Ship** | *"Deploy it."* | Build passes. Site goes live. Jules verifies the deployment. Session report captures what changed and why. |

**Think → Write → Distribute**

| Step | Prompt | What Happens |
|:----:|--------|-------------|
| **Think** | *"This article isn't landing. What's wrong?"* | Jules reads the draft, identifies structural problems, proposes a different angle. We debate it. |
| **Write** | *"Rewrite it with that framing."* | New draft, same voice calibration, same style guide. Runs a slop audit to catch AI writing patterns. |
| **Distribute** | *"Post it."* | Publishes to the site, adapts for Reddit and LinkedIn, queues the cross-posts. One command. |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Build Your Own

> [!TIP]
> You don't need dozens of configurations to start. Try this one prompt.

Open Claude Code in your project directory and paste:

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

Start small. The system grew organically over weeks of daily use.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Under the Hood

<sup>For the builders who want to know how it's made.</sup>

| | What | Details |
|:-:|------|---------|
| **17** | **Skills** | `/think`, `/build`, `/write`, `/research`, `/debug`. Multi-phase workflows, not single prompts. |
| **5** | **Hooks** | Unified safety guard, RTK token optimization, desktop notifications, session-start sync. |
| **1** | **Cloud Batch** | Overnight: daily retro, morning briefing, email fetch. Ready before the laptop opens. |
| **3** | **Environments** | Mac, Claude Web, Telegram. No VPS, no Docker, no daemons. |
| **60-90%** | **Token Savings** | [RTK][rtk-url] rewrites dev commands for massive context savings. |
| **<500** | **Lines in CLAUDE.md** | Identity, routing, authority, safety. One file, always loaded. |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Architecture

### Environments

```
┌─────────────────────┐     ┌─────────────────────────────────┐     ┌─────────────────────┐
│                     │     │          Claude Web              │     │                     │
│   Mac               │     │                                 │     │   Telegram           │
│   Interactive Dev   │     │  Scheduled    │   Interactive   │     │   Phone Access       │
│                     │     │  Batch        │   Sessions      │     │                     │
└─────────────────────┘     └─────────────────────────────────┘     └─────────────────────┘
```

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

Identity is the foundation. Products are what get shipped. Everything in between connects them.

### Classification Principle

How to decide where a behavior belongs:

| If the behavior is... | It's a... |
|---|---|
| Pattern-matchable, no judgment needed | **Hook** — deterministic, fires on tool calls |
| A repeatable procedure with defined inputs/outputs | **Script** — invoked by skill, hook, or Cloud task |
| Requires AI judgment, dialogue, or synthesis | **Skill** — structured conversation |
| A behavioral rule or preference | **CLAUDE.md section** — loaded every session |
| Stable identity and context | **Profiles/** — loaded every session |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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

Full implementation guide: [docs/overnight-batch.md](docs/overnight-batch.md)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Security & Privacy

A unified `safety-guard.sh` hook fires on every Bash, WebFetch, Write, and Edit tool call. Four layers, all deterministic — no AI judgment involved.

**Command blocking.** 16 patterns: `rm`, `sudo`, force-push, broad git staging (`git add .`), piping remote code to shell (`curl | bash`), system directory writes, `.env` overwrites via redirect, destructive git operations, and more.

**Secret scanning.** Regex detection for hardcoded credentials before any command executes — AWS keys, GitHub PATs, Anthropic/OpenAI API keys, private key material. Blocks the command and surfaces the match.

**Financial data guard.** Two-gate system. Gate 1 detects when sensitive financial files are read in the current session. Gate 2 blocks outbound actions (clipboard, curl POST, social posting scripts) that contain dollar amounts, account numbers, or financial terms. Both gates must fire — no false positives on normal work.

**Domain blocking.** WebFetch blocked on domains that return login walls (x.com, twitter.com) with workaround routing to API scripts.

**Autonomy boundaries.** Explicit "Just Do It / Ask First" framework in CLAUDE.md. Every action has clear criteria — reversible + within scope + no external impact = autonomous. Anything else gets a Decision Card. Standing orders expand the boundary over time through a proposal → approval flow.

**Defense in depth.** The hook is one layer. `settings.json` maintains a redundant deny-list at the permissions level. CLAUDE.md encodes behavioral rules. The agent profile defines escalation directives. Four independent layers, any one of which catches the problem.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Evolution

| Version | Theme | What Changed |
|:-------:|-------|-------------|
| **v1** | Identity + Skills | Personality, voice registers, decision authority. CLAUDE.md and early skill workflows. |
| **v2–v3** | Automation + Planning | Container infrastructure, scheduled jobs, planning dispatch, research agents, security hooks. |
| **v4** | Simplification | 32 skills became 17. 15 hooks became 5. VPS eliminated. Same power, half the parts. |

## Design Decisions

**Deterministic over probabilistic.** When a pattern works, codify it into a script. Skills are probabilistic (the LLM might follow them). Hooks and scripts are deterministic (they execute the same way every time). Push behavior toward determinism whenever possible.

**Identity persistence over memory.** Memory is lossy. Context windows reset. The CLAUDE.md hierarchy loads identity, decision rules, and behavioral patterns into every session. The agent doesn't need to remember who it is — it's told every time.

**Simple over complex.** The v3 to v4 transition proved this. 15 hooks doing 15 things became 1 hook doing the same 15 things. 20 rules files became CLAUDE.md sections. A Docker container with 9 cron jobs became one Cloud scheduled task. Same capabilities, half the maintenance.

**Explicit autonomy boundaries.** No ambiguity about what the agent can do on its own. The "Just Do It / Ask First" framework with standing orders eliminates the gray zone that makes autonomous agents unreliable.

**Minimal engineering.** Leverage Claude Code's built-in features before building custom infrastructure. Don't build what a config option handles.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

This system was built on top of, adapted from, and influenced by the work of others.

- **[Superpowers][superpowers-url]** by [Jesse Vincent](https://x.com/obra) (MIT) — Scoping, plan-writing, plan-execution, subagent-driven development, and systematic debugging methodologies that form the core of `/build` and `/debug`. Heavily customized and consolidated, but the foundations are Jesse's.
- **[RTK][rtk-url]** by [Patrick Szymkowiak](https://www.linkedin.com/in/patrick-szymkowiak/) (MIT) — Token optimization for CLI operations, integrated as a hook. 60-90% savings on dev tool output.
- **[Context Mode MCP][context-mode-url]** by [Mert Köseoğlu](https://x.com/mksglu) ([LinkedIn](https://www.linkedin.com/in/mksglu/)) — Context compression and FTS5 knowledge base patterns informed our approach to token management, even where we took a different path.
- **[OWASP Top 10](https://owasp.org/www-project-top-ten/)** — Secret scanning fingerprints (AWS keys, GitHub PATs, PEM detection) draw from well-established credential detection patterns. The two-gate financial data guard and defense-in-depth layers were informed by OWASP principles.
- **[Claude Code is All You Need](https://x.com/trq212/status/2035372716820218141)** by [Thariq Shihipar](https://x.com/trq212) ([LinkedIn](https://www.linkedin.com/in/thariqshihipar/)), Anthropic — Agent loop design, bash-first search, and verification patterns.
- **[Claude Code Setup Guide](https://okhlopkov.com/claude-code-setup-mcp-hooks-skills-2026/)** by [Daniil Okhlopkov](https://x.com/danokhlopkov) ([LinkedIn](https://www.linkedin.com/in/danokhlopkov/)), TON Foundation — Multi-MCP architecture, git worktrees, and self-improving CLAUDE.md.
- **[How I Use Every Claude Code Feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)** by [Shrivu Shankar](https://x.com/ShrivuShankar) — Hook placement strategy and `/catchup` workflow.

### Claude Code

v4's simplification was possible because Anthropic shipped features that replaced custom infrastructure. These capabilities, plus the [skill-creator][anthropic-skills-url] framework (Apache 2.0), are the foundation everything else builds on.

| Capability | What It Replaced | Docs |
|---|---|---|
| [Claude Web][claude-web-url] | VPS for remote sessions | Scheduled batch + interactive sessions from any browser |
| [Scheduled Triggers][claude-web-url] | 9 cron jobs + Docker container | Overnight retro, morning briefing, email fetch — one config |
| [Channels][channels-url] | Slack daemon (always-on, auth overhead) | Telegram push into sessions via MCP channel capability |
| [Dispatch][claude-web-url] | Manual task handoff | Kick off tasks from phone, pick up in desktop session |
| [Remote Control][claude-web-url] | SSH to VPS | Step away from desk, keep working from phone or browser |
| [Claude in Chrome][chrome-url] | Custom browser automation scripts | Browser automation via extension, scheduled browser tasks |
| [Skills][skills-url] | Prompt files + manual routing | Structured workflows with frontmatter, scoped hooks, tool permissions |
| [Hooks][hooks-url] | Scattered guard scripts | Deterministic lifecycle events with unified configuration |
| [skill-creator][anthropic-skills-url] | Manual skill scaffolding | Eval loop, grading agents, validation scripts (Apache 2.0) |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

[MIT](LICENSE). Use it, adapt it, build on it.

---

<!-- REFERENCE LINKS -->

[license-shield]: https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[license-url]: LICENSE
[skills-shield]: https://img.shields.io/badge/skills-17-8A2BE2?style=flat-square
[skills-url]: https://docs.anthropic.com/en/docs/claude-code/slash-commands
[hooks-shield]: https://img.shields.io/badge/hooks-5-orange?style=flat-square
[hooks-url]: https://docs.anthropic.com/en/docs/claude-code/hooks
[tokens-shield]: https://img.shields.io/badge/token_savings-60--90%25-brightgreen?style=flat-square
[rtk-url]: https://github.com/rtk-ai/rtk
[website-url]: https://builtwithjon.com/jules
[architecture-url]: docs/architecture.md
[claude-code-url]: https://docs.anthropic.com/en/docs/claude-code/overview
[claude-web-url]: https://docs.anthropic.com/en/docs/claude-code/overview
[channels-url]: https://docs.anthropic.com/en/docs/claude-code/mcp
[chrome-url]: https://docs.anthropic.com/en/docs/claude-code/ide-integrations
[superpowers-url]: https://github.com/obra/superpowers
[context-mode-url]: https://github.com/mksglu/claude-context-mode
[anthropic-skills-url]: https://github.com/anthropics/skills
