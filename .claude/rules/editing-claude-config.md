---
paths:
  - "**/.claude/**"
---

# Editing Claude Code Configuration

Configuration lives in two places:

**Project-level config** (skills, rules, hooks, agents) -- edit in the project `.claude/` directory:
- `~/your-workspace/.claude/skills/<name>/SKILL.md`
- `~/your-workspace/.claude/rules/<name>.md`
- `~/your-workspace/.claude/hooks/`
- `~/your-workspace/.claude/agents/`
- `~/your-workspace/.claude/settings.json` (project settings -- hooks, env vars)

**User-level config** (settings, statusline) -- standalone files in `~/.claude/`:
- `~/.claude/settings.json` (user settings -- permissions, plugins)
- `~/.claude/statusline.sh`
- `~/.claude/CLAUDE.md` (stub -- real config in project-level CLAUDE.md)

Project-level config loads automatically when Claude is launched from `~/your-workspace`. No symlinks involved.

**Commit changes in the workspace repo:**
```bash
cd ~/your-workspace && git add .claude/... && git commit -m "..."
```

## Hooks Behavior

- **Hooks can't detect UI actions** -- Shift-Tab and `/slash-commands` are client-side, don't fire hooks. Only AI-initiated tool calls fire hooks.
- **SessionStart hooks: output is unreliable.** Only working pattern: `cat <<HEREDOC` + `jq -Rs`. Use for context injection only; launchd for background tasks.
- **`/dev/tty` unavailable in Bash tool sandbox** -- returns "Device not configured." Hooks (unsandboxed) likely have it. For iTerm2 escape sequences: try `/dev/tty` first, fall back to `ps -o tty= -p $PPID`.

## Cloud Sessions (Anthropic App)

Cloud VMs clone the repo at session start -- push changes and start a NEW session to pick up updates. Sub-project skills don't transfer to cloud; plugin skills need the plugin enabled on the cloud instance. Case-sensitive paths (`.claude/` not `.Claude/`).
