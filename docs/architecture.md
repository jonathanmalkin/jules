# Architecture Overview

How the system works: the two environments, component model, overnight batch, and the five-layer model that connects everything.

## Two Environments

The system runs across two environments. No VPS, no Docker, no always-on sidecar.

**Mac (interactive development)**
- All Claude Code CLI sessions
- VS Code editing, content creation, advisory
- Agent teams
- Native clipboard, notifications, file links
- MCP servers session-managed via stdio
- Telegram access when laptop is open

**Anthropic Cloud (scheduled + remote)**
- Overnight sequential batch: retro + memory, morning briefing, email fetch
- Claude Code web app for remote interactive sessions (laptop closed/away)

**Why this works:** The Mac handles everything interactive. The Cloud handles everything scheduled. No container to maintain, no auth infrastructure to monitor, no daemon to keep alive. The overnight batch calls APIs directly via HTTP -- no MCP dependency in Cloud.

## Component Model

### Skills (17)

Interactive capabilities invoked in conversation. Each skill is a structured markdown file that defines a multi-phase workflow.

| Skill | Type | What It Does |
|-------|------|-------------|
| `/think` | Dialogue | Recursive decomposition + advisory (all altitudes 0-4) |
| `/build` | Dialogue + Script | Software dev end-to-end (scope, plan, execute, deploy) |
| `/write` | Dialogue + Script | Content production (seed to platform-ready output) |
| `/research` | Dialogue | Standalone research with persistence and cross-session pickup |
| `/debug` | Dialogue + Script | Systematic debugging |
| `/replies` | Script | Check X mentions, draft replies, post approved ones |
| `/good-morning` | Dialogue | Interactive walkthrough of morning briefing |
| `/wrap-up` | Script | End-of-session: issue capture, report, ship |
| `/stop-slop` | Script | Structural audit for AI writing patterns |
| `/pdf` | Script | PDF operations |
| `/plane` | Script | Plane.so interface (MCP + gap scripts + reconciliation) |
| `/send-email` | Script | Send email via Resend |
| `/financial-advisor` | Dialogue | Personal finance planning |
| `/generate-image-openai` | Script | Image generation with iterative workflow |
| `/search-history` | Script | Search session documents |
| `/skill-creator` | Dialogue + Script | Create/modify skills |
| `/agent-browser` | Script | Browser automation |

### Hooks (5)

Deterministic guards that fire on tool calls. No AI judgment -- a bash script executes the same way every time.

| Hook | Trigger | What It Does |
|------|---------|-------------|
| **safety-guard.sh** | PreToolUse: Bash, WebFetch, Write, Edit | Unified security + privacy. Four sections: (1) command blocking, (2) secret scanning, (3) financial data guard, (4) domain blocking |
| **notify-input.sh** | PostToolUse | Desktop notification when agent needs input |
| **rtk-rewrite.sh** | PreToolUse: Bash | RTK token optimization rewrites (includes output compression) |
| **session-start.sh** | SessionStart | Git pull on session open |

### Scripts

Skills wrap scripts for discovery. Scripts do the deterministic work.

| Script | Called By | What It Does |
|--------|----------|-------------|
| x-post.sh | `/replies` skill, manual | Post to X (OAuth 1.0a) |
| x-search.sh | `/replies` skill | Search X API |
| deploy scripts | `/build` skill | Deploy applications to hosting |

### Cloud Scheduled Process (Overnight Batch)

One Cloud scheduled task. Three sequential phases. Runs overnight.

| Phase | What It Does | Data Sources | Output |
|-------|-------------|-------------|--------|
| **1. Retro + Memory** | Analyze recent sessions, propose CLAUDE.md changes, prune stale items | Git history, session reports, CLAUDE.md, skills | Retro proposals file |
| **2. Morning Briefing** | Assemble 10-section briefing | Plane REST API, Gmail, Reddit JSON API, git log, retro output | Briefing markdown file |
| **3. Email Fetch** | Pull and categorize inbox | Gmail | Email summary in briefing |

### Configuration Surface

| Surface | What Belongs There |
|---------|-------------------|
| **CLAUDE.md (project-level)** | Routing, decision authority, standing orders, behavioral rules (absorbed from rules/), agent behavior |
| **profiles/agent-profile.md** | Identity, voice, personality, registers, relationship |
| **profiles/user-profile.md** | Values, thinking patterns, communication style |
| **profiles/business-identity.md** | Company, brand, products |
| **profiles/goals.md** | Quarterly targets |
| **.mcp.json** | MCP server configs (stdio) |
| **settings.json (project)** | Hooks, env vars, permissions |
| **Plane** | All work items, projects, cycles, dependencies |

**Key principle:** CLAUDE.md = operational instructions (how the agent behaves). Profiles = identity and context (who everyone is). No duplication between them except a brief identity failsafe in CLAUDE.md.

### MCP Servers (Session-Managed on Mac)

| Server | Protocol | What It Provides |
|--------|----------|-----------------|
| reddit-mcp-buddy | stdio/http | Reddit search, posts, user analysis |
| plane | stdio | Plane.so CRUD via MCP tools |
| Gmail | Cloud connector | Email read/search |
| Google Calendar | Cloud connector | Calendar operations |
| Telegram | Plugin | Interactive messaging when laptop open |
| Chrome (claude-in-chrome) | Extension | Browser automation |

### Memory System

| Mechanism | What It Stores |
|-----------|---------------|
| **CLAUDE.md** | Behavioral corrections, preferences |
| **Plane** | Project state, work items, status |
| **Reference files** | Pointers to external systems, user profile notes |
| **Overnight retro** | Proposes changes to CLAUDE.md -- morning approval gate |

Auto-memory: **OFF.** All persistence changes go through the proposal/approval flow.

## Classification Principle

| If the behavior is... | It's a... |
|----------------------|-----------|
| Pattern-matchable, no judgment needed | **Hook** (deterministic, fires on tool calls) |
| A repeatable procedure with defined inputs/outputs | **Script** (invoked by skill, hook, or Cloud task) |
| Requires AI judgment, dialogue, or synthesis | **Skill** (structured conversation) |
| A behavioral rule or preference | **CLAUDE.md section** (loaded every session) |
| Work tracking, status, dependencies | **Plane** (external system of record) |
| Stable identity or context | **Profiles/** (loaded every session) |

## Five-Layer Model

### Layer 1: Identity
`profiles/` -- Agent profile, user profile, business identity, goals. Loaded at session start via `@` references in CLAUDE.md. Changes rarely.

### Layer 2: Operational State
`Terrain.md`, `Briefing.md`, `Documents/` -- Live working state. Changes every session.

### Layer 3: Configuration
`CLAUDE.md`, `.claude/skills/`, `.claude/hooks/` -- The behavioral layer. CLAUDE.md absorbs what used to be 20+ rules files. Changes weekly.

### Layer 4: Automation
Cloud scheduled batch -- Overnight retro, morning briefing, email fetch. Changes rarely.

### Layer 5: Products
`Code/` -- The actual applications being built. Changes constantly.

## Key Design Decisions

**Simple over complex.** The v3 to v4 transition proved this. 15 hooks became 5. 20 rules files became CLAUDE.md sections. A Docker container with 9 cron jobs became one Cloud task. Same capabilities, dramatically less maintenance.

**Deterministic over probabilistic.** When a pattern works, codify it. Skills are probabilistic. Hooks and scripts are deterministic. Push behavior toward determinism.

**Identity persistence over memory.** Memory is lossy. Context windows reset. The CLAUDE.md hierarchy loads identity and decision rules into every session.

**Explicit autonomy boundaries.** The "Just Do It / Ask First" framework with standing orders eliminates ambiguity.

**Minimal engineering.** Leverage Claude Code's built-in features before building custom infrastructure.
