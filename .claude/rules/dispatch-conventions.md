# Dispatch Conventions

Rules for `claude -p` sessions spawned by `Scripts/dispatch.sh`. These sessions run autonomously without a human at the terminal.

## Session Behavior

1. **Read your task spec first.** The prompt contains everything you need: the relevant sprint spec section, specific instructions, expected output format, and handoff path.
2. **Stay in scope.** Only do what your task spec says. Don't refactor adjacent code, add features, or "improve" things outside scope.
3. **Build-test-fix loops are expected.** If your task involves code changes, run tests and fix failures. Don't leave broken code.
4. **Write your handoff.** Results go to the path specified in your prompt (typically `Documents/Grand-Plan/projects/<sprint>/handoffs/<task-id>-result.md`).
5. **Mark completion.** Write `complete` to `Documents/Grand-Plan/projects/<sprint>/handoffs/<task-id>.status` when done. Write `failed` with error context if you can't finish.
6. **Surface decisions.** If you hit something requiring [Your Name]'s judgment, append a Decision Card to `Documents/Grand-Plan/projects/<sprint>/decisions-needed.md`. Format: `**[DECISION]** Summary | **Rec:** X | **Risk:** Y | **Reversible?** Yes/No`
7. **Commit specific files.** Stage only the files you changed. Never `git add .` or `git add -A`. Commit message format: `dispatch(<sprint>): <task-id> — <short description>`
8. **Only commit clean work.** If tests fail or code is broken, don't commit. Mark the task as failed instead.

## Status Files

Each task tracks state in `handoffs/<task-id>.status`:
- `pending` — not started (default, file may not exist)
- `running` — session is actively working
- `complete` — work done, handoff written, committed
- `failed` — session couldn't finish (error context in the status file)

Write `running` at the start of your work, then `complete` or `failed` when done.

## Decision Cards

When you need [Your Name]'s input mid-task:

```markdown
**[DECISION]** <one-line summary>
**Context:** <2-3 sentences of what you found>
**Rec:** <your recommendation>
**Risk:** <what happens if wrong>
**Reversible?** Yes/No
**Task:** <task-id>
**Date:** <YYYY-MM-DD>
```

Append to `decisions-needed.md` (don't overwrite). The morning briefing surfaces these.

## What NOT to Do

- Don't read or modify other tasks' handoff files
- Don't update `task-breakdown.md` checkboxes (the completion handler does this)
- Don't push to remote (the dispatcher handles git push if configured)
- Don't spawn subagents or teams (you're already a dispatched session)
- Don't install dependencies or modify system configuration
- Don't touch files outside your task's scope
