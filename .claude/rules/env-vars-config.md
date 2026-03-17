# Claude Code Environment Variables — Configuration Reference

All Claude Code behavior vars are set in `settings.json` → `env` section.
The `.env.template` is for credentials only (resolved by 1Password at container startup).

## Active Configuration (`settings.json` env)

| Variable | Value | Why |
|----------|-------|-----|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | Enable agent teams — we use these heavily |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | `0` | Force auto memory on during rollout period |
| `ENABLE_TOOL_SEARCH` | `auto:5` | Auto-fetch deferred tool schemas, up to 5 results |
| `CLAUDE_CODE_ENABLE_TASKS` | `1` | Task tracking in non-interactive (`-p`) sessions — cron/Slack jobs |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `64000` | 64K max (default 32K) — long retro/morning outputs were hitting the limit |
| `BASH_DEFAULT_TIMEOUT_MS` | `120000` | 2 min default bash timeout (explicit, matches built-in default) |
| `BASH_MAX_TIMEOUT_MS` | `600000` | 10 min max — allows long deploys and retro scripts |

Note: `effortLevel: "high"` is also set in `settings.json` at the top level (not via env var).

## Evaluated and Not Set

These were reviewed and explicitly left at default:

| Variable | Default | Decision |
|----------|---------|----------|
| `CLAUDE_CODE_EFFORT_LEVEL` | auto | Already set via `effortLevel` in settings.json — don't duplicate |
| `CLAUDE_CODE_TASK_LIST_ID` | — | Cross-session task coordination — overkill for now |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | off | Don't hamstring cron job quality |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | 95 | Default is fine — no observed premature compaction |
| `CLAUDE_CODE_SIMPLE` | off | Minimal mode (Bash + file tools only) — not needed |
| `CLAUDE_CODE_SHELL_PREFIX` | — | Bash wrapper/auditor — no current need |
| `CLAUDE_ENV_FILE` | — | Source a shell script before bash commands — no current need |
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | — | Load CLAUDE.md from `--add-dir` paths — not used |

## Architecture Notes

**What applies where:**

- `settings.json` env vars → every Claude session (interactive terminal + `claude -p` non-interactive)
- `.env.template` → process environment for cron jobs, Slack daemon, and all their children (inherited at container startup via `op inject`)
- For behavior vars, `settings.json` is the single source of truth
- For credentials, `.env.template` is the single source of truth

**No restart needed** for `settings.json` changes — loaded fresh each session.
**Restart needed** for `.env.template` changes — injected once at container startup (no rebuild required since template is bind-mounted).

## Reference

Full env vars docs: https://code.claude.com/docs/en/env-vars
