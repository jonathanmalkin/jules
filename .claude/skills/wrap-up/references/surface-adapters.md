# Wrap-Up Surface Adapters

Canonical source:

```text
~/.agents/skills/workflows/wrap-up
```

Use `scripts/wrapup_surface_targets.py` to inspect adapter targets before
installing anything.

## Codex

Adapter:

```text
~/.codex/skills/wrap-up -> ~/.agents/skills/workflows/wrap-up
```

Codex-specific behavior:

- emit Codex app git directives after successful stage, commit, push, branch, or
  PR operations
- preserve Codex approval rules around destructive commands and background
  services
- do not use `git add .` or `git add -A`

## Claude Code

Adapter:

```text
~/.claude/skills/wrap-up -> ~/.agents/skills/workflows/wrap-up
```

Claude-specific behavior:

- use plain text final reports
- rely on Claude Code's slash-command/user-invocation behavior
- do not emit Codex app directives

## Hermes Profiles

Adapter for approved workflow-owning profiles:

```text
~/.hermes/profiles/<profile>/skills/workflows/wrap-up -> ~/.agents/skills/workflows/wrap-up
```

Current live Hermes adapters:

- `pam`
- `director`

Do not install wrap-up by default on:

- `archivist`
- `dreamer`
- `researcher`
- `subconscious`

Hermes-specific behavior:

- run profile-native skill review/update procedure before proposing profile or
  shared skill edits
- inspect `~/.hermes/profiles/<profile>/cron/jobs.json` before changing files
  owned by a scheduled job
- treat `config.yaml`, `cron/jobs.json`, gateway LaunchAgents, and profile logs
  as operations surfaces, not generic repo files

Profiles without approved workflow ownership need review before creating
`skills/workflows` or adding this skill.

## Public Jules Repo

Adapter:

```text
~/Active-Work/Code/personal/jules/.claude/skills/wrap-up
```

Use a sanitized copy, not a host-local symlink. Public/reference repos should not
depend on `~/.agents` paths on Jonathan's machine.
