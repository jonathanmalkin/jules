# Prohibited Bash Commands

The `bash-safety-guard.sh` hook blocks these commands. Do NOT attempt them -- you'll waste a tool call. Use the substitute instead.

## Common Substitutions

**NEVER use `rm`.** Move to Trash instead: `mv <target> ~/.Trash/`

**NEVER use `find -delete` or `find -exec rm`.** Use `find` to list files, then `mv` each to `~/.Trash/`.

**NEVER use `sudo` or `doas`.** Try without elevation first. If sudo is truly required:
1. Complete ALL non-sudo steps first
2. Present the exact sudo command to the user with context on what it does
3. Let the user run it manually in their terminal

**NEVER redirect to overwrite `.env` files** (e.g., `> .env`). Use the Edit tool to modify `.env` files.

**NEVER use broad destructive git ops:** `git checkout .`, `git restore .`, `git clean -f`. Specify individual files instead.

**NEVER use `git add .` or `git add -A`.** Stage specific files instead.

**NEVER use `git push --force` or `--force-with-lease`.** Regular `git push` only.

## Also Prohibited (hand to user if needed)

These are blocked by the safety guard. If the task requires them, give the user the exact command to run manually.

- **File truncation** via `> /absolute/path` -- use Write or Edit tool instead
- **Pipe-to-shell** (`curl`/`wget` piped to `bash`/`sh`/`zsh`) -- download first, inspect, then run
- **System directory writes** (`mv`/`cp`/`ln`/`chmod`/`chown` to `/etc`, `/usr`, `/System`, `/Library`) -- give user the command
- **Disk operations** (`mkfs`, `dd of=`, `fdisk`, `parted`, `diskutil erase`) -- give user the command
- **Process/power management** (`kill -9 1`, `killall`, `shutdown`, `reboot`, `halt`) -- give user the command
