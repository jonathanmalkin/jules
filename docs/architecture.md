# Architecture Overview

How Jules works as a system: the hybrid architecture, credential flow, job pipeline, and the five-layer model that connects everything.

## Hybrid Architecture

Jules runs across two environments that stay in sync via git.

**Mac (interactive development)**
- All Claude Code CLI sessions
- VS Code editing, content creation, advisory
- Agent teams (uses available RAM)
- Native clipboard, notifications, file links

**VPS Container (automation sidecar)**
- 8 cron jobs (retro, morning, afternoon, tweets, auth, git pull, catch-up, news monitor)
- Slack daemon (24/7 phone access via Socket Mode)
- MCP servers (Reddit, etc.)
- SSH server for remote access

**Why two environments?** The Mac is where creative and interactive work happens. But cron jobs need to run at 3 AM, the Slack daemon needs to be always-on, and you can't rely on a laptop being open. The VPS container runs 24/7 with a predictable environment. The Mac connects to it via SSH when needed.

## Memory Sync

Both environments share the same Claude Code memory via git:

1. Memory files live in `.claude-memory/` in the repo root
2. Both environments symlink `~/.claude/projects/.../memory/` to this directory
3. A `.gitattributes` merge driver (`theirs-memory`) auto-resolves conflicts (latest push wins)
4. The container runs `git pull` every minute to stay current

This means a morning cron job on the container can read memory written during yesterday's interactive session on the Mac, and vice versa.

## Credential Flow

Secrets flow from 1Password into the container at startup, not at runtime.

```
1Password (cloud)
  → OP_SERVICE_ACCOUNT_TOKEN (docker-compose env_file)
    → entrypoint.sh calls `op inject`
      → .env.template (vault refs) resolved to real values
        → /tmp/agent-secrets.env (chmod 600)
          → `source` exports to all child processes
            → Slack daemon, cron jobs, claude -p calls inherit secrets
```

Claude Code's own auth uses a special path: `CLAUDE_CODE_OAUTH_TOKEN` is also written to `~/.claude/.credentials.json` with `chattr +i` (immutable flag) to prevent accidental overwrite by `claude login`.

The auth-refresh job runs at 2:45 AM (15 minutes before the first scheduled job) to validate the token is still live and alert via Slack if it isn't.

## Job Pipeline

The daily job pipeline runs on the container via cron:

| Time | Job | What it does | Depends on |
|------|-----|-------------|------------|
| Every 1 min | git-auto-pull | Keeps container in sync with GitHub | -- |
| 2:45 AM | auth-refresh | Validates Claude auth, alerts on failure | -- |
| 3:00 AM | daily-retro | Analyzes session issues with parallel agents | auth-refresh |
| 5:00 AM | morning-orchestrator | Memory synthesis + briefing generation | daily-retro signal file |
| 8 AM-10 PM | news-feed-monitor | Polls RSS feeds for relevant content | -- |
| 4:00 PM | afternoon-scan | Mid-day context refresh | -- |

The retro writes a signal file (`~/.claude/job-state/daily-retro.status`) that the morning orchestrator reads. This decouples the two jobs while preserving the data dependency.

## Slack Daemon

The Slack daemon is the bridge between your phone and the container. It runs as a Node.js process using Slack's Socket Mode (no public URLs needed).

**Message flow:**
1. You send a message via Slack (phone, desktop, anywhere)
2. Socket Mode delivers it to the daemon
3. Daemon classifies: one-word command? Complex request? URL research?
4. Commands (status, help, logs) are handled deterministically in JS
5. Everything else spawns `claude -p` with the message as input
6. Claude's output streams back to Slack as tagged messages

**Complexity heuristic:** Messages with 2+ action patterns or 3+ action verbs get the decompose-first flow, where Claude breaks the request into autonomous steps, user steps, and blocked steps before executing.

**Security:** The daemon injects a security prompt into every `claude -p` call that prevents reading SSH keys, credential files, or making unauthorized network requests.

## Five-Layer Model

The system is organized in five layers, from identity (most stable) to products (most changeable):

### Layer 1: Identity
`Profiles/` -- Agent profile, user profile, business identity, goals. Loaded at session start via `@` references in CLAUDE.md. Changes rarely.

### Layer 2: Operational State
`Terrain.md`, `Briefing.md`, `Documents/` -- Live working state. Terrain tracks what's happening now, next, and waiting. Briefing is generated daily. Changes every session.

### Layer 3: Infrastructure
`.claude/` -- Skills, rules, hooks, agents, settings. The behavioral layer that shapes how the agent works. Changes weekly as patterns are codified.

### Layer 4: Automation
`.claude/container/`, `.claude/scripts/` -- Docker setup, cron jobs, Slack daemon. The always-on layer that runs without human input. Changes monthly.

### Layer 5: Products
`Code/` -- The actual applications being built. Changes constantly, but the infrastructure layers above are what make rapid iteration possible.

## Container Architecture

The container uses a two-stage entrypoint:

1. **Root entrypoint** (`docker-entrypoint-root.sh`): Starts sshd and cron (require root), installs crontab, fixes volume permissions, then drops to the `claude` user.

2. **User entrypoint** (`entrypoint.sh`): 8 phases from boot to ready -- workspace setup, SSH config, 1Password injection, Claude config, boot-check for missed jobs, Slack daemon startup, MCP servers, supervisor loop.

The supervisor loop at the end keeps the container alive, restarts crashed daemons, and hot-reloads the Slack daemon when its code changes (via file checksum comparison).

**tini as PID 1** is an architectural invariant. Without it, every `claude -p` spawned by cron or the Slack daemon leaves a zombie process. tini reaps them automatically.

## Key Design Decisions

**Signal files over direct calls.** The daily retro and morning orchestrator communicate via a signal file rather than the orchestrator calling the retro directly. This means either can run independently, retry without affecting the other, and the orchestrator gracefully handles a missing or failed retro.

**Poll-and-kill timeout wrapper.** Every `claude -p` call uses a timeout wrapper that polls the PID and kills the process tree on timeout. The previous approach (timeout inside `$()`) failed to kill hung API calls (21-minute and 104-minute hangs in production). The poll-and-kill pattern reliably terminates runaway processes.

**Immutable credentials file.** The `chattr +i` flag on `.credentials.json` prevents `claude login` from accidentally overwriting the setup-token with a short-lived OAuth token. The auth-refresh job detects and alerts if this protection is bypassed.
