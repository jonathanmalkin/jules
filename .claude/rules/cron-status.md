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
| **auth-refresh** | **Hourly at :47** | `~/.claude/job-state/auth-refresh.log` + `auth-checks.jsonl` |
| **session-scan** | **7:00 PM daily** | `~/.claude/job-state/session-scan.log` |
| daily-retro | **8:00 PM** | `~/.claude/job-state/daily-retro.log` |
| email-inbox-fetch | **Hourly at :47** | `~/.claude/job-state/fetch-email.log` |
| morning-orchestrator | **Midnight** (waits for retro) | `~/.claude/good-morning-state/launchd.log` |
| tweet-scheduler | 5x/day (8,10,12,15,18) | `~/.claude/job-state/tweet-scheduler.log` |
| **daily-auth-report** | **10:03 AM daily** | `~/.claude/job-state/daily-auth-report.log` |
| **weekly-health-digest** | **Monday 9:07 AM** | `~/.claude/job-state/weekly-health-digest.log` |
| **reply-bot** | **Every 1 min (dev) / 5 min (prod)** | `~/.claude/job-state/reply-bot/bot.log` |

**Always-running services:** Slack daemon (supervised by entrypoint.sh), SSH server, cron daemon.

**Docker healthcheck:** Runs every 30s (not a cron job). Checks: (1) secrets file exists with 15+ vars, (2) no auth-failed.lock, (3) Slack daemon alive, (4) credentials.json has non-empty accessToken AND expiresAt=null (setup-token format — non-null means an OAuth token snuck in) AND file mode is 444 (read-only protection). Status visible via `docker ps` (healthy/unhealthy) and `docker inspect`. Health detail written to `~/.claude/job-state/health-status`. Bind-mounted from repo (updates without rebuild).

**Auth failure classification:** auth-check.sh and auth-refresh.sh distinguish three failure types:
- `auth_fail` — API is reachable but token is rejected (401/403). Sets `auth-failed.lock`. All cron jobs pause.
- `api_down` — Anthropic API is unreachable (timeout, 5xx). Sets `api-outage.lock`. Jobs retry automatically.
- `network` — DNS resolution failed. Alerts but no lock file.

The API reachability check uses `curl` against `api.anthropic.com/v1/messages` with an invalid key. A 401 response proves the API is up. This prevents API outages from being misdiagnosed as auth failures.

**Auth guard on cron jobs:** All cron jobs (retro, email, orchestrator, news-feed-monitor) check `auth-failed.lock` before running and exit cleanly if auth is confirmed broken. `api-outage.lock` does NOT block jobs — each job's own auth-check.sh handles retries.

**Structured auth logging:** Hourly auth checks write to `~/.claude/job-state/auth-checks.jsonl` (JSON Lines). Each entry: timestamp, test method, result, classification, latency, HTTP status. The daily 10 AM report reads this log and posts a 24h summary to #ops.

**Token expiry tracking:** entrypoint.sh writes `~/.claude/job-state/token-written-date` on each startup. The setup-token is **opaque** (`sk-ant-oat01-*`), not a JWT — there is no `exp` claim to decode. Token age is tracked via `token-written-date` file (the best available proxy). auth-refresh.sh warns at tiered thresholds: 180 days (note in log), 300 days (Slack warning), 335 days (critical alert).

**1Password service account monitoring:** auth-refresh.sh runs `op whoami` as a canary check. If the service account token is expired or invalid, an alert fires before downstream failures cascade.

**Schedule rationale:** The daily retro was moved from 3 AM to 8 PM to avoid the ~8-9 AM UTC window when Anthropic API outages are most frequent. The orchestrator runs at midnight (same evening), waiting up to 30 min for retro completion before proceeding. Email fetch runs at 11:45 PM (15 min before orchestrator). This means the briefing is assembled the night before and ready when you open Slack in the morning.

**Verbose error capture:** When `claude -p` fails, the actual stderr output is captured and logged (auth-checks.jsonl `error` field, auth-refresh.log inline). On confirmed auth failures (API reachable, token rejected), a full diagnosis dump is written to `~/.claude/job-state/auth-diagnosis.log` including: claude -p error, credentials.json state, file permissions, env vars, 1Password status, and running processes.

**Reporting cadence:** Hourly auth checks → daily 10 AM summary to #ops → weekly Monday digest to #ops.

## VPS host jobs (1 active)

These run on the **VPS host**, not inside the container. They need access to the Docker daemon or other host-level resources.

| Job | Schedule | Log path (on VPS host) | Check command (from Mac) |
|-----|----------|------------------------|--------------------------|
| docker-prune | 5:00 AM daily | `/var/log/docker-prune.log` | `ssh your-vps "cat /var/log/docker-prune.log"` |

`docker system prune -f` removes stopped containers, dangling images, and unused networks. Does NOT remove running containers, tagged images, or volumes. Keeps disk clean after frequent `docker compose build --no-cache` rebuilds.

**VPS host crontab** (managed separately from container crontab):
```bash
# View from Mac:
ssh your-vps "crontab -l"
```

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

The `entrypoint.sh` supervisor loop uses `while true; sleep 10`. Bash doesn't call `wait()` on child processes, so every `claude -p` invocation spawned by the Slack daemon or cron jobs leaves a zombie `node` process. Without a real init process, zombies accumulate indefinitely (observed: 40 zombies during load testing).

`tini` acts as a proper PID 1 that reaps orphaned processes automatically. After installing tini and rebuilding, zombie count dropped to 0.

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

Your VPS provider's metrics agent exposes CPU, memory, disk, and **load average** in the dashboard.

**What "load" means:** Queue depth of processes waiting to run — not a percentage. On a 2-CPU VPS:
- **Healthy:** < 2.0 (each CPU has less than one waiting process on average)
- **Spikes during retro:** Expected — the retro script spawns multiple `claude -p` subprocesses sequentially. A spike to 3-5 during the retro window is normal.
- **Sustained > 4.0:** Investigate — likely runaway processes or OOM pressure

Load average is reported as 1-min / 5-min / 15-min. The 1-min value is the most reactive; the 15-min value shows sustained pressure.

## Slack Channels (3 active)

| Channel | Purpose | Routing |
|---------|---------|---------|
| **#chat** | Conversation with your agent + URL drops (research queue) | `SLACK_CHANNEL_ID` (default) |
| **#ops** | All automated notifications (cron jobs, deploys, alerts) | `SLACK_OPS_CHANNEL_ID` via `slack-send.sh --ops` |
| **#logs** | Verbose daemon session traces (muted) | `SLACK_LOGS_CHANNEL_ID` via `slack-send.sh --logs` |

**Archived:** #alerts (absorbed into #ops), #research (link handling moved to #chat queue-for-batch).

**Research flow:** Bare URLs dropped in #chat are queued to `~/.claude/job-state/research-queue.jsonl`. Processed during morning orchestrator (Phase 0c). Results posted to original Slack thread. Use `research: <url>` prefix for immediate real-time analysis.

## Secrets Refresh Runbook

`refresh-secrets.sh` runs at 2:30 AM daily. It re-runs `op inject` to pull fresh credentials from 1Password, writes `/tmp/agent-secrets.env` and `~/.claude/.credentials.json`, and keeps backups of the last good state. `auth-refresh.sh` at 2:45 AM validates the result.

### Check the last run

```bash
# From Mac:
ssh your-vps "docker exec --user claude your-agent-dev tail -30 /home/claude/.claude/job-state/refresh-secrets.log"

# From inside container:
tail -30 ~/.claude/job-state/refresh-secrets.log
```

**Healthy output looks like:**
```
[secrets-refresh] 2026-03-18 02:30:01 OK: 23 vars refreshed
[secrets-refresh] 2026-03-18 02:30:01 Credentials.json rewritten and backed up.
```

### Failure modes

| Symptom in log | Root cause | Auto-recovery | Manual fix |
|----------------|-----------|---------------|------------|
| `SKIP: OP_SERVICE_ACCOUNT_TOKEN not set` | Container started without op-token env_file, or entrypoint failed | None | Restart container: `cd ~/workspace/.claude/container && docker compose down && docker compose up -d` |
| `SKIP: template file missing` | Bind mount failed or `.env.template` deleted | None | Check `docker inspect your-agent-dev \| grep env.template`. Restart if mount missing. |
| `FAIL: op inject exited N — restored from backup` | 1Password unreachable or service account token expired | **Yes** — restores last good secrets + credentials.json | If auth-refresh still fails: rotate service account token in 1Password, update `~/.env/.op-token` on VPS, restart container |
| `FAIL: op inject exited N — no backup available` | Container restarted AND inject failed on same night | None | Restart container — entrypoint.sh re-runs op inject cleanly |
| `FAIL: only N vars resolved (expected >=20)` | op inject partially resolved — vault item missing or renamed | None (keeps existing file) | Run `grep -v '^#' .env.template \| grep -v '^$' \| op inject --in-file /dev/stdin` to identify the broken reference |
| `WARN: CLAUDE_CODE_OAUTH_TOKEN empty after refresh` | Claude setup-token vault item missing or renamed | None | Verify item exists in 1Password vault "Your-Vault". Update `.env.template` if renamed. |

### Backup files

Stored in `/tmp/` — survive container lifetime but wiped on restart. Rebuilt on the next successful refresh or on container start (entrypoint.sh runs op inject fresh).

```bash
# Check backup age (from Mac):
ssh your-vps "docker exec --user claude your-agent-dev ls -la /tmp/agent-secrets.env.bak /tmp/agent-credentials.json.bak"
```

### Manual refresh (skip waiting for 2:30 AM)

```bash
# From Mac:
ssh your-vps "docker exec --user claude your-agent-dev bash -c 'set -a; . /tmp/agent-secrets.env; set +a; bash /home/claude/workspace/.claude/scripts/refresh-secrets.sh'"
```

### The 2:30/2:45 window

`refresh-secrets` at 2:30 AM → `auth-refresh` at 2:45 AM. If refresh fails, auth-refresh catches it 15 minutes later and pages via Slack with remediation steps. The two jobs are designed as a pipeline: refresh first, validate second.

## When asked about "cron status" or "job status"

1. If on Mac (interactive session): use SSH commands (`ssh your-vps "docker exec --user claude your-agent-dev crontab -l"`)
2. If on container (Slack/cron): run `crontab -l` directly
3. Tail relevant log files for recent output/errors
4. Never respond based on `CronList` alone
