---
name: plane
effort: medium
description: "Plane.so project management interface via direct API scripts. Use when user says 'plane', 'check plane', 'update plane', 'GP-42', 'plane status', 'sync to plane', 'look up task', or any Plane-related project management action."
---

# Plane.so Skill

Comprehensive interface to the Plane Cloud workspace (`[your-workspace-slug]`, project `Grand Plan`).

## Architecture: Direct API Scripts

All Plane operations use Python scripts calling the REST API via curl.
No MCP server dependency — works in interactive and batch contexts.

| Operation | Script |
|-----------|--------|
| List items, cycles, modules | `plane_list.py items`, `plane_list.py cycles`, `plane_list.py modules` |
| List items in a module | `plane_list.py module-items "Pending Review"` |
| Filter by state/due date | `plane_list.py items --state todo,in_progress --due-within 7` |
| Create item (+ add to module) | `plane_create.py "Title" --module "Pending Review"` |
| Get item by identifier (GP-42) | `plane_lookup.py GP-42` |
| Search items by keyword | `plane_search.py "keyword"` |
| Pull Plane status → markdown | `plane_pull.py [--apply]` |
| Compare local vs Plane | `plane_compare.py [--diff-only] [--module slug]` |

## Gap Script Usage

All scripts require `PLANE_API_KEY`. On Mac, inject at call time:

```bash
# Lookup by identifier
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_lookup.py GP-42

# Search
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_search.py "authentication" --state todo

# Push: markdown -> Plane (dry-run by default, --apply for live)
python3 .claude/skills/plane/scripts/plane_sync.py          # dry-run
python3 .claude/skills/plane/scripts/plane_sync.py --apply   # live changes

# Pull: Plane -> markdown (dry-run by default, --apply writes with backup)
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_pull.py           # dry-run
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_pull.py --apply   # live (backs up to .plane-pull-backup/)

# Compare: side-by-side diff (read-only)
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_compare.py              # full table
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_compare.py --diff-only  # only mismatches
PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_compare.py --module infrastructure  # filter by module
```

The sync script auto-injects credentials via `op` if `PLANE_API_KEY` is not set.

## Workspace Defaults

See `references/our-workspace.md` for all IDs, states, modules, labels, and conventions.

- Workspace: `[your-workspace-slug]`
- Project: `Grand Plan` (UUID: `8238b353-5e87-4b72-b199-fec061be8b98`)
- Identifier prefix: `GP`
- [Your Name]'s user ID: `[YOUR_USER_ID]`

## API Patterns

See `references/patterns.md` for:
- Why curl (not urllib): Plane returns 403 with Python HTTP clients
- Rate limiting: 1.1s between calls
- Cursor-based pagination
- Issue title convention: `Description [TASK-ID]`

## Container Scope

MCP server is Mac-only (interactive Claude Code sessions). It launches via `start-plane-mcp.sh`, which resolves the API key from 1Password using the `OP_SERVICE_ACCOUNT_TOKEN` (set in `~/.zshrc`). Batch jobs use gap scripts with `PLANE_API_KEY` from macOS Keychain (`security find-generic-password -s plane-api-key`).

## Reference Docs

- `references/our-workspace.md` -- IDs, states, modules, labels
- `references/api-reference.md` -- Condensed endpoint reference
- `references/mcp-tools.md` -- MCP server tool catalog (populate after smoke test)
- `references/patterns.md` -- Learned API patterns and gotchas
