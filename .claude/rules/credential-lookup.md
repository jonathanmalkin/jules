# Credential Lookup — Deterministic Order

## How Credentials Get Into the Container

At container startup, `entrypoint.sh` does this:
1. Reads `.claude/container/.env.template` (vault references like `op://Your-Vault/X/Consumer Key`)
2. Calls `op inject` to resolve them using the `OP_SERVICE_ACCOUNT_TOKEN` service account
3. Writes resolved values to `/tmp/agent-secrets.env` (chmod 600)
4. Cron jobs source it inline: `. /tmp/agent-secrets.env && bash script.sh`
5. Slack daemon inherits the env vars from the shell that started it

**Result:** All credentials are available as environment variables for any process running inside the container.

## Lookup Order (Deterministic)

### Inside the container (Claude sessions, cron jobs, Slack daemon)

**Always check environment variables first.** They're already there.

```python
# Python
import os
api_key = os.environ["X_API_KEY"]
```

```bash
# Shell — if env vars aren't inherited, source the secrets file
source /tmp/agent-secrets.env
echo "$X_API_KEY"
```

**Never call `op item get` or `op run` inside the container.** The 1Password CLI can use the service account token, but interactive calls require process forking that's unreliable under container thread limits.

### On the Mac (maintenance sessions only)

Use the credential caching script for X:
```bash
bash Scripts/tweet-cache-creds.sh   # caches to ~/.config/x-api-creds
source ~/.config/x-api-creds
```

Or use `op item get` directly with biometric:
```bash
op item get "X" --vault "Dev Secrets" --fields "Consumer Key"
```

## Credential Names in the Container Env

| Env Var | Service | Vault Reference |
|---------|---------|-----------------|
| `X_API_KEY` | X (Twitter) Consumer Key | `op://Your-Vault/X/Consumer Key` |
| `X_API_SECRET` | X Consumer Secret | `op://Your-Vault/X/Consumer Secret` |
| `X_ACCESS_TOKEN` | X Access Token | `op://Your-Vault/X/Access Token` |
| `X_ACCESS_SECRET` | X Access Token Secret | `op://Your-Vault/X/Access Token Secret` |
| `SLACK_BOT_TOKEN` | Slack Bot | `op://Your-Vault/Slack Bot/SLACK_BOT_TOKEN` |
| `OPENAI_API_KEY` | OpenAI | `op://Your-Vault/OpenAI API/OPENAI_API_KEY` |

Full list in `.claude/container/.env.template`.

## Adding New Credentials Mid-Session

The secrets file is written once at container startup. If a new credential is added to 1Password and the `.env.template` after the container is already running:

1. Add the `op://` reference to `.env.template`
2. Rebuild the container: `cd ~/workspace/.claude/container/ && docker compose build && docker compose up -d`
3. The new credential will be available in the next container's environment

There's no live refresh without a restart. This is a known gap.

## Debugging

If a credential lookup fails inside the container:
```bash
# Verify the secrets file exists and has content
ls -la /tmp/agent-secrets.env
wc -l /tmp/agent-secrets.env

# Check a specific var (don't print the value, just confirm it exists)
python3 -c "import os; print('X_API_KEY' in os.environ)"
```

If missing, the container may need a restart (entrypoint.sh didn't complete successfully).
