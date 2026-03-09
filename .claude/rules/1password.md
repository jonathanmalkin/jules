---
paths:
  - "**/.env*"
  - "**/restore-secrets*"
  - "**/import-to-1password*"
  - "**/.claude/scripts/**"
---

# 1Password CLI

Secrets are stored in a dedicated vault in 1Password (vault ID: `[VAULT-ID]`). Keep all credentials in one vault for consistency. Use `op` CLI for programmatic access:

```bash
# Read a single field
op item get "[Item Name]" --vault "[Your Vault]" --fields label=API_KEY

# List all items
op item list --vault "[Your Vault]"

# Read SSH key
op read "op://[Your Vault]/[SSH Key Item]/public key"
```

SSH keys are managed by the 1Password SSH Agent -- no private key files on disk:
- Agent socket: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- Git signing uses `op-ssh-sign` at `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`

Emergency Kit should be stored in a secure offline or cloud backup location.

## Claude Code Bash Sandbox

The Bash tool sandbox doesn't inherit the 1Password desktop app integration automatically. Set this env var for `op` to work:

```bash
OP_BIOMETRIC_UNLOCK_ENABLED=true op vault list
```

Without it, `op` returns "No accounts configured" or "not currently signed in." The toggle in 1Password Settings -> Developer -> "Integrate with 1Password CLI" must also be enabled.

## `op run` with `.env.op` templates

Projects use `.env.op` files (checked into git) containing `op://` references instead of plaintext `.env` files. At runtime, `op run` resolves them and injects the values as environment variables:

```bash
# Launch a process with secrets resolved from 1Password
op run --env-file=.env.op -- python -m src

# Verify a specific variable resolves
op run --env-file=.env.op -- env | grep DISCORD_TOKEN
```

### Projects using `.env.op`

| Project | File | Makefile target |
|---------|------|-----------------|
| Your Project | `path/to/.env.op` | `make refresh-project-env` |

### Why `.env` still exists for some projects

Some tools spawn subprocesses internally -- there's no way to inject `op run` into their launch. A plaintext `.env` file is the only interface. Use a Makefile target to pull values from 1Password into that file.

### Fallback

`restore-secrets.sh` still writes plaintext `.env` files from 1Password. Use it on machines without the 1Password desktop app (CI, servers) or as a fallback.

## Troubleshooting

**`op` fails with "not signed in":**
1. Open 1Password app and unlock it (Touch ID or master password)
2. Run `make refresh-secrets` to warm the cache (one Touch ID prompt)
3. Cache lasts 24 hours -- one prompt per day

**Multiple Touch ID prompts in one session:**
The cache should prevent this. If it happens, check cache freshness:
`ls -la ~/.cache/1password/` -- files should be recent.
Run `make refresh-secrets` to refresh all caches at once.

**Claude Code sandbox can't trigger Touch ID:**
The sandbox lacks /dev/tty. If `op` fails inside Claude but works in your terminal,
run `make refresh-secrets` from your terminal -- the cache file is shared.
