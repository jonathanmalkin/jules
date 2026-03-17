# Prohibited Bash Commands

The `bash-safety-guard.sh` hook blocks these commands. Do NOT attempt them — you'll waste a tool call. Use the substitute instead.

## Common Substitutions

**NEVER use `rm`.** Move to Trash instead: `mv <target> ~/.Trash/`. In the container (Debian), `~/.Trash/` is created by the entrypoint. Use it consistently across both environments.

**NEVER use `find -delete` or `find -exec rm`.** Use `find` to list files, then `mv` each to `~/.Trash/`.

**NEVER use `sudo` or `doas`.** Try without elevation first. If sudo is truly required:
1. Complete ALL non-sudo steps first
2. Present the exact sudo command to the user with context on what it does
3. Let the user run it manually in their terminal

**NEVER redirect to overwrite `.env` files** (e.g., `> .env`). Use the Edit tool to modify `.env` files.

**NEVER use broad destructive git ops:** `git checkout .`, `git restore .`, `git clean -f`. Specify individual files instead.

**NEVER use `git add .` or `git add -A`.** Stage specific files instead.

**NEVER use `git push --force` or `--force-with-lease`.** Regular `git push` only.

## SSH to your-hosting-provider

The hook blocks `rm` and `mv` in SSH commands to your-hosting-provider (pattern 14). This means:

- **Can't delete or move files** on the remote server via SSH. Give the user the exact command to run manually.
- **Approval doesn't persist** — hooks are stateless. Even if the user says "y", the hook blocks again on retry. Don't retry; hand off.
- **`~/.Trash/` doesn't exist** on your-hosting-provider (Linux). For remote cleanup, use `mv <target> /tmp/` or `mv <target> ~/` — or just give the user the command.
- **Reading `.env` files via SSH is fine** — the hook only blocks redirect-to-`.env` (e.g., `> .env`), not `cat` or `grep` of `.env` files.

## Also Prohibited (hand to user if needed)

These are blocked by the safety guard. If the task requires them, give the user the exact command to run manually.

- **File truncation** via `> /absolute/path` — use Write or Edit tool for **existing** files (see Write Tool section below for new files)
- **Pipe-to-shell** (`curl`/`wget` piped to `bash`/`sh`/`zsh`) — download first, inspect, then run
- **Upload local files** via `curl`/`wget` (`-d @`, `-F =@`, `--upload-file`) — ask user first
- **System directory writes** (`mv`/`cp`/`ln`/`chmod`/`chown` to `/etc`, `/usr`, `/System`, `/Library`) — give user the command
- **Disk operations** (`mkfs`, `dd of=`, `fdisk`, `parted`, `diskutil erase`) — give user the command
- **Process/power management** (`kill -9 1`, `killall`, `shutdown`, `reboot`, `halt`) — give user the command

## Write Tool and New Files

The Write tool requires a prior Read in the same session — including for files that don't yet exist on disk. Read on a non-existent file returns empty but satisfies the check. **Exception:** for new files with complex content (XML, SVG, multi-line strings with shell-hostile quoting), skip the Read+Write dance entirely and use a Bash heredoc — the hook only blocks `> /absolute/path`, not relative-path heredocs:

```bash
cat > newfile.drawio.svg << 'SVGEOF'
<svg content here>
SVGEOF
```

**Decision table:**
- **Existing file, any content** → Read then Write (or Edit for partial changes)
- **New file, simple content** → Read (returns empty) then Write
- **New file, complex content** (XML, SVG, multi-line with quotes) → Bash heredoc with relative path

## Testing Hooks That Would Block the Test

The `bash-safety-guard.sh` PreToolUse hook fires on the Bash tool's command string. This means: if you're testing a hook by running a bash command that contains a blocked pattern (e.g., credential strings, `-----BEGIN`), the hook blocks YOUR test command before it runs.

**Workaround:** Write the test driver to a temp file, then invoke it by path.
```bash
# Hook sees only "bash /tmp/test-hook.sh" — not the contents
cat > /tmp/test-hook.sh << 'EOF'
# test commands containing sensitive patterns go here
EOF
bash /tmp/test-hook.sh
```
The hook sees `bash /tmp/test-hook.sh` — just a file path — so it doesn't match any pattern. This is the canonical approach for all hook self-trigger situations.

## Tool Discovery in Subagents

Shell commands for checking tool availability (`which`, `brew search`, `command -v`) can trigger 1Password prompts in subagents. The hook is stateless — each subagent starts fresh, so prior approvals don't carry over. This produces repeated biometric prompts for innocuous research tasks.

**For tool availability research, prefer WebSearch over shell commands.**

If a local check is truly needed:
- `brew list | grep <name>` — fast, local, low pattern-match risk
- NOT `brew search <name>` — hits network, higher likelihood of matching hook patterns

**Never run tool-discovery shell commands in subagents** when the answer can come from WebSearch or existing knowledge. The repeated approval friction isn't worth the verification.
