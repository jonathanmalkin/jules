---
name: plane
model: sonnet
effort: medium
description: "Plane.so project management interface. Routes between MCP tools (most CRUD operations) and gap scripts (identifier lookup, search, bulk sync). Use when user says 'plane', 'check plane', 'update plane', 'GP-42', 'plane status', 'sync to plane', 'look up task', or any Plane-related project management action."
---

# Plane.so Skill

Comprehensive interface to the Plane Cloud workspace (`open-door-learning`, project `Grand Plan`).

## Architecture: MCP Server + Gap Scripts

**MCP tools** (prefixed `mcp__plane__`) handle ~70% of operations: work item CRUD, cycles, modules, states, labels, relations, comments, links, worklogs, pages.

**Gap scripts** handle what the MCP server doesn't cover:
- **Identifier lookup** (`GP-42` -> full item details)
- **Workspace search** (keyword search across all items)
- **Bulk sync** (markdown task-breakdown.md -> Plane state sync)

### When to use which

| Operation | Tool |
|-----------|------|
| List/create/update/delete work items | MCP: `mcp__plane__list_work_items`, `create_work_item`, etc. |
| Get item by UUID | MCP: `mcp__plane__retrieve_work_item` |
| Get item by identifier (GP-42) | Gap: `plane_lookup.py GP-42` |
| Search items by keyword | Gap: `plane_search.py "keyword"` |
| Bulk sync markdown -> Plane | Gap: `plane_sync.py [--apply]` |
| Pull Plane status -> markdown | Gap: `plane_pull.py [--apply]` |
| Compare local vs Plane (read-only) | Gap: `plane_compare.py [--diff-only] [--module slug]` |
| Manage cycles, modules, states, labels | MCP tools |
| Create/list relations | MCP: `mcp__plane__list_relations`, `create_relation` |
| Comments, links, worklogs | MCP tools |
| Pages | MCP tools |

## Gap Script Usage

All scripts require `PLANE_API_KEY`. On Mac, inject at call time:

```bash
# Lookup by identifier
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_lookup.py GP-42

# Search
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_search.py "authentication" --state todo

# Push: markdown -> Plane (dry-run by default, --apply for live)
python3 .claude/skills/plane/scripts/plane_sync.py          # dry-run
python3 .claude/skills/plane/scripts/plane_sync.py --apply   # live changes

# Pull: Plane -> markdown (dry-run by default, --apply writes with backup)
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_pull.py           # dry-run
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_pull.py --apply   # live (backs up to .plane-pull-backup/)

# Compare: side-by-side diff (read-only)
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_compare.py              # full table
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_compare.py --diff-only  # only mismatches
PLANE_API_KEY=$(op item get "Plane API" --vault "Your-Vault" --fields label="API Key" --reveal) \
    python3 .claude/skills/plane/scripts/plane_compare.py --module infrastructure  # filter by module
```

The sync script auto-injects credentials via `op` if `PLANE_API_KEY` is not set.

## Workspace Defaults

See `references/our-workspace.md` for all IDs, states, modules, labels, and conventions.

- Workspace: `open-door-learning`
- Project: `Grand Plan` (UUID: `8238b353-5e87-4b72-b199-fec061be8b98`)
- Identifier prefix: `GP`
- [Your Name]'s user ID: `[your-user-id]`

## API Patterns

See `references/patterns.md` for:
- Why curl (not urllib): Plane returns 403 with Python HTTP clients
- Rate limiting: 1.1s between calls
- Cursor-based pagination
- Issue title convention: `Description [TASK-ID]`

## Container Scope

MCP server is Mac-only (interactive Claude Code sessions). It launches via `start-plane-mcp.sh`, which resolves the API key from 1Password using the `OP_SERVICE_ACCOUNT_TOKEN` (set in `~/.zshrc`). Container sessions (Slack, cron) don't have Plane MCP tools available. For container use, gap scripts are callable if `PLANE_API_KEY` is added to `.env.template`. This is not yet wired.

## Legacy Scripts

`Scripts/plane-sync.py`, `Scripts/plane-enrich.py`, `Scripts/plane-polish.py`, `Scripts/plane-fix-dates.py`, `Scripts/plane-migrate.sh` remain in place. The skill gap scripts wrap or replace their functionality. After 2+ weeks of stable skill use, consider adding deprecation notes to the legacy scripts.

## Reference Docs

- `references/our-workspace.md` -- IDs, states, modules, labels
- `references/api-reference.md` -- Condensed endpoint reference
- `references/mcp-tools.md` -- MCP server tool catalog (populate after smoke test)
- `references/patterns.md` -- Learned API patterns and gotchas
