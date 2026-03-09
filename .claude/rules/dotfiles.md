---
paths:
  - "Makefile"
  - "Brewfile"
  - ".claude/scripts/**"
---

# System Configs & Scripts

Config files live natively in their home locations (`~/.zshrc`, `~/.gitconfig`, `~/.claude/settings.json`, etc.). They are **not** managed by symlinks or any installer -- edit them directly.

Scripts live in `.claude/scripts/` (project-level, tracked in git).

**Brewfile** is at the repo root. Install with `brew bundle install --file=Brewfile`.

## Key Locations

| What | Where |
|------|-------|
| Shell configs | `~/.zshrc`, `~/.bashrc`, `~/.bash_profile`, `~/.zprofile`, `~/.zshenv` |
| Git config | `~/.gitconfig`, `~/.config/git/ignore` |
| Claude user config | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/statusline.sh`, `~/.claude/.env.op` |
| Claude project config | `.claude/` (skills, agents, hooks, rules, scripts) |
| MCP config | `~/.config/mcp.json` |
| SSH config | `~/.ssh/config` |
| Tmux config | `~/.tmux.conf` |
| Scripts | `.claude/scripts/` (orchestrator, monitor, briefing, etc.) |
| Brewfile | `Brewfile` (repo root) |

## Multi-Machine Support

- Shell configs use `$HOME` and detect architecture (`uname -m`) for Homebrew paths
- `make setup` fixes absolute paths in skill/agent `.md` files for the current machine
- `make disaster-recovery` clones repos, installs MCP servers, and installs brew packages

### Switching machines checklist

1. `git pull` (or `make disaster-recovery` on a fresh machine)
2. `make setup` -- fixes skill/agent file paths
3. `make disaster-recovery-mcp` -- installs MCP server
4. `make disaster-recovery-brew` -- installs brew packages
5. `make refresh-claude-env` -- refreshes `.env` from 1Password
6. Copy home-dir configs from backup (not managed by this repo)
7. `make verify` -- checks configs, tools, repos, and .env files

## launchd Notes

- **`caffeinate -s`** for DarkWake jobs -- wrap long-running launchd commands to hold the system awake. Mac sleeps after ~45s DarkWake otherwise. Pair with `pmset repeat wakeorpoweron` (set wake *after* job time).
- **`launchctl start` throttles back-to-back invocations** -- ~10s cooldown between manual starts. Silent drop, no error. Account for this when testing.

## Async Inbox

Single entry point: Terrain `## Inbox`. launchd runs your inbox-processing script on an interval -> `claude -p` with read-only tools, limited turns, and a timeout. Updates Terrain.md only -- all items routed to the appropriate Terrain section. Retry counter (max 3 consecutive failures). Failed items surfaced in morning briefing. Reports logged to a designated log file. Install via Makefile target.

## Naming Conventions

- **Code/ folders:** `lowercase-hyphens` (e.g., `my-app`, `my-discord-bot`)
- **Documents/ folders:** `Title-Case-Hyphens` (e.g., `My-Project`, `Educational-Content`)
- **Documents/ files:** `Title-Case-Hyphens.ext` (e.g., `Brand-Strategy.md`, `Logo.png`)
- No spaces in any folder or file names -- this ensures terminal clickability
