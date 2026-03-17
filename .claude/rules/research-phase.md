# Research Phase — Auto-Dispatch Before Skills

## When This Fires

Before entering any of these skills, automatically run a research phase:
- `/scope` — Research requirements landscape, existing implementations, prior decisions
- `/advisory` — Research decision context, market data, prior related decisions
- `/systematic-debugging` — Targeted research on the specific error/behavior (narrower scope)

## How It Works

After the skill is triggered but BEFORE entering its first step:

1. **Classify research needs** based on the request:
   - What local context is relevant? (plans, decisions, code, docs)
   - What external context would help? (docs, community solutions, competitive landscape)

2. **Dispatch research agents in parallel:**
   - **Local research** (Haiku Explore subagent): Codebase, plans, decision log, Terrain, memory
   - **Web research** (Sonnet subagent): Only when external context is needed (API docs, community solutions, market data)

3. **Inject research context** into the skill's first step. The skill proceeds with research already gathered.

## Research Scope by Skill

| Skill | Local Research | Web Research |
|-------|---------------|-------------|
| `/scope` | Prior plans, existing code, decision log, Terrain | API docs, library options, community patterns |
| `/advisory` | Decision log, Terrain, profiles, prior research | Market data, competitive analysis, expert opinions |
| `/systematic-debugging` | Error context, related code, recent changes | GitHub issues, Stack Overflow, known bugs |

## Quick Tier Exception

For **Quick** tier requests (simple lookups, single-action tasks), skip the research phase entirely. Research is for Debug, Advisory, and Scope tiers only.

## Budget

Research phase should complete in under 60 seconds for local-only, under 120 seconds when web research is included. If research is taking longer, proceed with what you have — don't block the skill on perfect information.
