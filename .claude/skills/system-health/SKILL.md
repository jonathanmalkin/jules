---
name: system-health
description: >
  Run system health diagnostic and synthesize findings. Checks syntax, cross-references,
  freshness, deprecation candidates, and configuration consistency across all Claude Code
  workspace components. Use when user says "system health", "health check", "diagnostic",
  or invokes /system-health.
---

# System Health Diagnostic

Run the deterministic health check script, then synthesize findings with LLM judgment.

## Steps

1. Run the diagnostic script:
   ```bash
   bash .claude/scripts/system-health.sh
   ```
   The script exits 0 (all pass), 1 (warnings), or 2 (failures).

2. Read the saved report (the script outputs the report path)

3. **Synthesize findings** by adding LLM judgment to the raw facts:

   ### Deprecation Triage
   Read the orphan and deprecation lists. Determine which are truly dead vs. used informally
   (e.g., a script called from another device, not referenced in any config).

   ### Directive Alignment
   Map findings to your agent's directives:
   - **Move Things Forward:** stale Terrain items, customer-signal vs infrastructure balance
   - **See Around Corners:** broken cross-references, deprecated files still active
   - **Handle the Details:** orphan scripts (patterns not codified), documentation gaps
   - **Know When to Escalate:** aging Decision Queue items, FAIL-level findings

   ### Prioritized Recommendations
   Sort findings into:
   - **Fix now** — FAIL items, broken cross-references
   - **Fix this week** — WARN items, stale content, orphan cleanup
   - **Monitor** — INFO items, known deprecations pending cleanup

   ### Decision Cards
   For anything needing the user's input (deleting files, changing config, removing deprecated
   components), present as Decision Cards:
   ```
   **[DECISION]** Brief summary | **Rec:** recommendation | **Risk:** what could go wrong | **Reversible?** Yes/No
   ```

4. If new orphan scripts are detected, propose adding them to a known-scripts allowlist
   or recommend deletion.

## Also Available

- `make health` — runs the script directly (no LLM synthesis)
- Morning orchestrator runs it automatically and injects alerts into the briefing email
