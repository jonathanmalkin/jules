---
name: catchup
description: "Reload essential context after /clear. Reads Terrain.md, MEMORY.md, and recent changes. Use when context feels bloated, after /clear, or at the start of a continuation session. Triggers on 'catchup', 'catch up', 'reload context', 'where were we'."
---

# Catchup — Context Reload

Deterministic context reload from known sources. Use after `/clear` or when starting a continuation session.

**Announce at start:** "Reloading context..."

## Steps

### 1. Read core context (parallel)
- Read `Terrain.md` (current operational state)
- Read your persistent memory file (e.g., `MEMORY.md`)

### 2. Check recent changes
- Run `git diff --name-only main...HEAD` to find changed files in the current branch
- If on main with no diff (common case), run `git log --oneline -5` instead to see recent work
- For each changed file: read it (skip binaries, note files > 500 lines without reading)

### 3. Check for recent session report (optional)
- Look in `Documents/Field-Notes/Logs/` for session reports from today or yesterday
- If found: read the most recent one for continuity
- If not found: skip silently

### 4. Synthesize and present
Provide a brief, warm status summary:
- Current focus (from Terrain's Now section)
- Recent changes (from git)
- Open items or blockers worth noting
- End with: "What are we working on?"

## What this is NOT
- Not `/good-morning` — no engagement scanning, no decision queue, no briefing generation
- Not a data dump — synthesize, don't list everything
- Not a substitute for reading specific files — if the user needs deep context on a file, they'll ask
