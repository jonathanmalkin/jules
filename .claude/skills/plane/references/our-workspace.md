# Our Plane Workspace

## IDs

| Entity | Value |
|--------|-------|
| Workspace slug | `[your-workspace-slug]` |
| Project (Grand Plan) | `8238b353-5e87-4b72-b199-fec061be8b98` |
| Project identifier | `GP` (issues are `GP-1`, `GP-42`, etc.) |
| [Your Name]'s User ID | `[YOUR_USER_ID]` |

## State Groups

Plane uses state groups. Our project has one state per group:

| Group | Meaning |
|-------|---------|
| `backlog` | Not yet planned |
| `unstarted` | Planned but not started (our "todo") |
| `started` | In progress |
| `completed` | Done |
| `cancelled` | Won't do |

State UUIDs change per workspace. Fetch dynamically via MCP `list_states` or gap script.

## Modules

Modules map to Grand Plan project areas:

| Module Name | Slug |
|------------|------|
| Content Pipeline | `content` |
| Infrastructure | `infrastructure` |
| Flourishing | `flourishing` |
| Jules Public | `jules-public` |
| Rebrand | `rebrand` |
| Collaboration | `collaboration` |

Module UUIDs change per workspace. Fetch dynamically.

## Labels

| Label | Purpose |
|-------|---------|
| `[your-name]` | Requires [Your Name]'s direct action |
| `jules-auto` | Jules can handle autonomously |
| `jules-interactive` | Jules needs [Your Name] present |
| `decision-needed` | Blocked on a decision |
| `deferred` | Parked for later |

## Task ID Convention

Issue titles follow the format: `Description text [TASK-ID]`

Task IDs use prefixes that map to project areas:
- `S1-`, `S2-`, etc. = Content sprints
- `P2-`, `P3-`, etc. = Infrastructure phases
- `F1-`, `F2-`, etc. = Flourishing
- `J-A`, `J-B` = Jules Public
- `R-` = Rebrand
- `C-` = Collaboration

## API Base URL

```
https://api.plane.so/api/v1/workspaces/[your-workspace-slug]/projects/8238b353-5e87-4b72-b199-fec061be8b98
```

## Auth

- Header: `X-API-Key: <key>`
- Key stored in 1Password: "Plane API" in "Dev Secrets" vault, field "API Key"
- On Mac: inject at call time via `op item get` or `op run`
- In container: add to `.env.template` if needed (not yet wired)
