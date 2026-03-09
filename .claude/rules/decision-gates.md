---
paths:
  - Documents/**
  - Terrain.md
---
# Decision Gates

## Decision Log Protection
- Decision Log (`Documents/Field-Notes/Decision-Log.md`) entries record decisions [USER] has made.
- Before writing to Decision Log: confirm the decision with the user first. "Offer to log" means ask, then write -- not write proactively.
- Exception: `/wrap-up` skill writes entries during session cleanup for decisions made during the session.

## Analysis vs. Action
- Analysis documents (stress tests, brainstorms, option comparisons) are thinking tools.
- When a document contains analysis + proposed actions, the actions are conversation starters -- not pre-approved tasks.
- "Implement" for an analysis document means "walk me through this" -- not "execute all action items."
- When in doubt: ask "Do you want to discuss this or execute it?"

## Status Document Updates
- Terrain.md and MEMORY.md reflect decisions the user has made, not decisions the agent thinks should be made.
- Don't update these docs to reflect decisions that haven't been explicitly confirmed.
