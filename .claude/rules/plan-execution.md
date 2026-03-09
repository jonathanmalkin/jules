# Plan Execution Pre-Check

Before implementing changes from a plan, transcript, or prior session:

1. **Check recent commits** -- `git log --oneline -5 -- <files>` for each file in the plan's "Files Modified" table
2. **Check working tree** -- `git diff HEAD -- <files>` to see if changes are already applied
3. **If already applied:** Report "Plan already applied in commit [hash]" and skip the code changes. Proceed with any non-code steps (DB migrations, deploys, etc.).
4. **If partially applied:** Identify which steps remain and continue from there
5. **If not applied:** Proceed normally

This prevents redundant Edit calls when re-entering a plan from a previous session or transcript.
