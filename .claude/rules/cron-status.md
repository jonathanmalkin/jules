# Cron & Job Status

## Default: Check the VPS container

All scheduled jobs run on the **your-agent-dev container on the VPS**. The Mac runs git-auto-pull and is the primary interactive dev environment. When asked about job status, cron, orchestrator, or scheduled tasks, check the VPS container.

## Two internal systems — don't confuse them

**`CronList` tool** = Claude Code's internal session scheduler. Only for tasks scheduled via `CronCreate` in the current session. Nothing to do with system cron.

**Container cron jobs** = the real scheduled work. Check with SSH + docker exec (see commands below).

## Container cron jobs (example set)

Customize these for your schedule.

| Job | Schedule | Log path (in container) |
|-----|----------|------------------------|
| git auto-pull | Every 1 min | `/tmp/git-auto-pull.log` |
| Slack daemon restart (on code change) | Every 1 min (30s delay) | — |
| catch-up-scheduler | Every 15 min | `~/.claude/job-state/catch-up.log` |
| auth-refresh | 2:45 AM daily | `~/.claude/job-state/auth-refresh.log` |
| daily-retro | 3:00 AM | `~/.claude/job-state/daily-retro.log` |
| morning-orchestrator | 5:00 AM | `~/.claude/good-morning-state/launchd.log` |
| afternoon-scan | 4:00 PM | `~/.claude/job-state/afternoon-scan.log` |

**Always-running services:** Slack daemon (supervised by entrypoint.sh), SSH server, cron daemon.

## Mac jobs (1 active)

| Job | Schedule | Check command |
|-----|----------|--------------|
| git-auto-pull | Every 5 min (launchd) | `cat /tmp/git-auto-pull-status` |

## Commands to check status

**Your agent runs on Mac (interactive) or container (cron/automation).** For interactive Mac sessions, use the SSH commands to check container jobs. For container sessions (Slack, cron), use the direct commands.

### From inside the container (Slack/cron sessions)

```bash
# Container cron jobs (full list)
crontab -l

# Morning orchestrator log (today's run)
tail -30 ~/.claude/good-morning-state/launchd.log

# Any container job log
tail -30 ~/.claude/job-state/<job-name>.log

# Slack daemon health
ps aux | grep slack-daemon
```

### From Mac (interactive sessions)

```bash
# Container cron jobs (full list)
ssh your-vps "docker exec --user claude your-agent-dev crontab -l"

# Morning orchestrator log (today's run)
ssh your-vps "docker exec --user claude your-agent-dev tail -30 /home/claude/.claude/good-morning-state/launchd.log"

# Any container job log
ssh your-vps "docker exec --user claude your-agent-dev tail -30 /home/claude/.claude/job-state/<job-name>.log"

# Slack daemon health
ssh your-vps "docker exec --user claude your-agent-dev ps aux | grep slack-daemon"

# Mac's git-auto-pull (the only Mac job)
cat /tmp/git-auto-pull-status
```

## Container Process Management

**`tini` is installed as PID 1 in the `your-agent-dev` container. This is an architectural invariant — required, not optional.**

### Why it matters

The `entrypoint.sh` supervisor loop uses `while true; sleep 10`. Bash doesn't call `wait()` on child processes, so every `claude -p` invocation spawned by the Slack daemon or cron jobs leaves a zombie `node` process. Without a real init process, zombies accumulate indefinitely.

`tini` acts as a proper PID 1 that reaps orphaned processes automatically.

### Invariant

Any Dockerfile rebuild or entrypoint change must preserve tini as PID 1:

```dockerfile
# Required in Dockerfile:
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/home/claude/entrypoint.sh"]
```

Use exec form (JSON array) — NOT shell form (`ENTRYPOINT /sbin/tini --`). Shell form puts `sh` at PID 1, defeating the purpose.

### Verification

```bash
# From inside the container:
# Check zombie count — should be 0 after a tini-based build
ps aux | grep -c ' Z '

# Confirm tini is PID 1
cat /proc/1/cmdline | tr '\0' ' '

# From Mac:
# ssh your-vps "docker exec --user claude your-agent-dev ps aux | grep -c ' Z '"
# ssh your-vps "docker exec --user claude your-agent-dev cat /proc/1/cmdline | tr '\\0' ' '"
```

**Note:** `--strict-mcp-config` in `claude -p` calls prevents a narrower zombie vector (MCP children blocking `$()`) — but that's a scripting flag, not a substitute for tini. Both layers are needed.

## VPS Metrics — Load Average

**What "load" means:** Queue depth of processes waiting to run — not a percentage. On a 2-CPU VPS:
- **Healthy:** < 2.0 (each CPU has less than one waiting process on average)
- **Spikes during retro:** Expected — the retro script spawns multiple `claude -p` subprocesses sequentially.
- **Sustained > 4.0:** Investigate — likely runaway processes or OOM pressure

Load average is reported as 1-min / 5-min / 15-min. The 1-min value is the most reactive; the 15-min value shows sustained pressure.

## When asked about "cron status" or "job status"

1. If on Mac (interactive session): use SSH commands (`ssh your-vps "docker exec --user claude your-agent-dev crontab -l"`)
2. If on container (Slack/cron): run `crontab -l` directly
3. Tail relevant log files for recent output/errors
4. Never respond based on `CronList` alone
