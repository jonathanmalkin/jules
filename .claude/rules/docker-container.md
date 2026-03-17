# Docker Container — Rebuild Rules

**Hybrid architecture: Mac is the primary interactive dev environment. The container (`your-agent-dev`) is the automation sidecar** running cron jobs, Slack daemon, and always-on services. Interactive agent sessions run on Mac; container sessions are Slack daemon and cron dispatches.

Commands labeled "from Mac" can be run by your agent in interactive Mac sessions or by you directly. Commands labeled "from inside the container" apply to Slack/cron sessions running inside the container.

## When `docker compose up -d` Is NOT Enough

These files are baked into the image at build time via `COPY` or `RUN`. Restarting without rebuilding runs stale code.

**Always run `docker compose build --no-cache && docker compose up -d` when changing COPY'd files.** Docker's layer cache does NOT reliably detect file changes — `docker compose build` (without `--no-cache`) will often serve a stale image even when the source file changed. Always use `--no-cache` for `entrypoint.sh`, `docker-entrypoint-root.sh`, and `crontab` changes.

**Also: VPS `git pull` may fail if the repo has diverged.** If the VPS repo is diverged from origin (concurrent-session hazard), bypass git entirely: SCP the changed files directly, then rebuild.

```bash
# When git pull fails on VPS — SCP + rebuild workflow:
scp .claude/container/entrypoint.sh your-vps:~/workspace/.claude/container/entrypoint.sh
ssh your-vps "cd ~/workspace/.claude/container && docker compose build --no-cache && docker compose up -d"
```

**Always run `docker compose build --no-cache && docker compose up -d` when changing:**

| File | Why |
|------|-----|
| `entrypoint.sh` | `COPY`'d to `/home/claude/entrypoint.sh` at build time |
| `docker-entrypoint-root.sh` | Same — baked in, not bind-mounted |
| `Dockerfile` | Obviously requires rebuild |
| `crontab` | Installed via `RUN` during build |

**The bind mount only covers `/home/claude/workspace/`.** Anything `COPY`'d elsewhere in the image is NOT live-updated at runtime.

## Where the Compose File Lives

```bash
cd ~/workspace/.claude/container/
docker compose build && docker compose up -d
```

Must `cd` there first — the compose file is not in the repo root.

## Dockerfile Layer Changes

When changing the Dockerfile itself (new packages, base image, layer order), use `--no-cache` to avoid stale layers:

```bash
docker compose build --no-cache && docker compose up -d
```

## Crontab Verification

After any container restart or rebuild, verify the crontab was installed correctly:

```bash
# From inside container (use this):
crontab -l

# From Mac:
# ssh your-vps "docker exec --user claude your-agent-dev crontab -l"
```

If crontab is missing or stale, the container needs a rebuild (not just a restart).

## Quick Reference

```bash
# Standard rebuild (entrypoint, crontab, or Dockerfile changes):
cd ~/workspace/.claude/container/ && docker compose build && docker compose up -d

# Force-fresh rebuild (Dockerfile layer changes):
cd ~/workspace/.claude/container/ && docker compose build --no-cache && docker compose up -d

# Verify running container's crontab (from inside container):
crontab -l

# Verify from Mac:
# ssh your-vps "docker exec --user claude your-agent-dev crontab -l"
```

## Container Shell & Auth

**Always pass `--user claude` for interactive shells.** Bare `docker exec` drops to root by default.

```bash
# Wrong — drops to root, any auth writes to /root/.claude/ instead of /home/claude/.claude/
docker exec -it your-agent-dev bash

# Right — stays as claude user
docker exec -it --user claude your-agent-dev bash
```

**For `claude login`:** This is the most dangerous footgun. Root auth writes to `/root/.claude/.credentials.json`. Every daemon and cron job runs as `claude` and reads `/home/claude/.claude/.credentials.json`. A mismatch causes silent "Not logged in" failures on all `claude -p` dispatches. Run this from Mac (requires interactive TTY):

```bash
ssh your-vps "docker exec -it --user claude your-agent-dev claude login"
```

**Recovery (if you ran `claude login` as root):**

```bash
# Copy credentials from root to claude user and fix ownership
ssh your-vps "docker exec --user root your-agent-dev bash -c 'cp /root/.claude/.credentials.json /home/claude/.claude/.credentials.json && chown claude:claude /home/claude/.claude/.credentials.json'"
```

## Credential Wiring

Credentials flow from 1Password into the container at startup — not at runtime.

**The chain:**
1. `OP_SERVICE_ACCOUNT_TOKEN` is injected by docker-compose as an env var
2. `docker-entrypoint-root.sh` starts sshd/cron as root, then drops to `claude` user via `su`
3. `entrypoint.sh` runs `op inject` — resolves `op://Your-Vault/...` references in `.env.template` and writes real values to `/tmp/agent-secrets.env` (600 perms)
4. `set -a; source /tmp/agent-secrets.env; set +a` — exports all secrets as env vars, inherited by all child processes (slack daemon, cron jobs, `claude -p` calls)
5. `CLAUDE_CODE_OAUTH_TOKEN` gets special treatment: also written to `~/.claude/.credentials.json`

**Where creds live inside the container:**
- All secrets: `/tmp/agent-secrets.env` (cache file, persists for container lifetime)
- Claude auth: `~/.claude/.credentials.json`
- Everything else: process environment (inherited by children)

**No live refresh.** Creds are fetched once at startup. Adding a new 1Password item after the container is running requires a restart:
```bash
# Credential-only changes (no rebuild needed — template is bind-mounted):
cd ~/workspace/.claude/container/ && docker compose down && docker compose up -d
```

## Crash-Loop Recovery

When the container is in a restart loop, `docker exec` is unreliable — the container exits before commands complete. Use this workflow from the Mac instead.

### Diagnosis

```bash
# See why the container is crashing (from Mac)
ssh your-vps "docker logs your-agent-dev --tail 50"

# Watch live restart behavior
ssh your-vps "docker ps -a | grep your-agent-dev"
```

### Delivering a Fix When `docker exec` Is Unreliable

If the fix is a file change (e.g., patching `entrypoint.sh`), use SCP to copy directly to the VPS host, then rebuild:

```bash
# Copy fixed file to VPS host (from Mac)
scp .claude/container/entrypoint.sh your-vps:~/workspace/.claude/container/entrypoint.sh

# Rebuild and restart from VPS host (from Mac via SSH)
ssh your-vps "cd ~/workspace/.claude/container/ && docker compose build && docker compose up -d"
```

The rebuild bakes the patched file into the image, breaking the crash loop.

### VPS SSH Config and Deploy Keys

The VPS has its own `~/.ssh/config` with host aliases mapping to repo-scoped deploy keys. Configure these for your GitHub repos.

**If SSH auth fails on the VPS:** Check `~/.ssh/config` exists and maps the right key to the right alias. Deploy keys are repo-scoped on GitHub, so using the wrong key gives "Repository not found" (not "permission denied").

### Summary: Crash-Loop Toolkit

| Step | Command (run from Mac) |
|------|------------------------|
| Diagnose | `ssh your-vps "docker logs your-agent-dev --tail 50"` |
| Deliver fix | `scp <local-file> your-vps:<remote-path>` |
| Rebuild | `ssh your-vps "cd ~/workspace/.claude/container/ && docker compose build && docker compose up -d"` |
| Verify | `ssh your-vps "docker ps | grep your-agent-dev"` |

## Pending Improvement

Consider bind-mounting `entrypoint.sh` in `docker-compose.yml` to eliminate the rebuild requirement for that file:

```yaml
volumes:
  - ../../:/home/claude/workspace        # existing
  - ./entrypoint.sh:/home/claude/entrypoint.sh  # eliminates rebuild for entrypoint edits
```

Prerequisites: `chmod +x .claude/container/entrypoint.sh` on the Mac side. Dockerfile and crontab changes would still require rebuilds.
