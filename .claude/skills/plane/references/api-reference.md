# Plane API Reference (Condensed)

Base URL: `https://api.plane.so/api/v1`

Auth header: `X-API-Key: <key>`

## Work Items (Issues)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/issues/` | List (paginated, filterable) |
| POST | `/workspaces/{slug}/projects/{id}/issues/` | Create |
| GET | `/workspaces/{slug}/projects/{id}/issues/{id}/` | Retrieve |
| PATCH | `/workspaces/{slug}/projects/{id}/issues/{id}/` | Update |
| DELETE | `/workspaces/{slug}/projects/{id}/issues/{id}/` | Delete |
| GET | `/workspaces/{slug}/work-items/{identifier}/` | Get by identifier (e.g., GP-42) |
| GET | `/workspaces/{slug}/work-items/search/?search=keyword` | Search |

### Filters (query params on list)

`assignees`, `state`, `priority` (0=urgent, 1=high, 2=medium, 3=low, 4=none), `label`, `type`, `cycle`, `module`

## States

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/states/` | List all states |
| POST | `/workspaces/{slug}/projects/{id}/states/` | Create |
| PATCH | `/workspaces/{slug}/projects/{id}/states/{id}/` | Update |

## Labels

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/labels/` | List |
| POST | `/workspaces/{slug}/projects/{id}/labels/` | Create |

## Modules

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/modules/` | List |
| POST | `/workspaces/{slug}/projects/{id}/modules/` | Create |
| POST | `/workspaces/{slug}/projects/{id}/modules/{id}/module-issues/` | Add issues |
| GET | `/workspaces/{slug}/projects/{id}/modules/{id}/module-issues/` | List issues |

## Cycles

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/cycles/` | List |
| POST | `/workspaces/{slug}/projects/{id}/cycles/` | Create |
| POST | `/workspaces/{slug}/projects/{id}/cycles/{id}/cycle-issues/` | Add issues |

## Relations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/issues/{id}/relations/` | List |
| POST | `/workspaces/{slug}/projects/{id}/issues/{id}/relations/` | Create |
| DELETE | `/workspaces/{slug}/projects/{id}/issues/{id}/relations/{id}/` | Remove |

Types: `blocked_by`, `blocking`, `relates_to`, `duplicate`

## Comments

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/issues/{id}/comments/` | List |
| POST | `/workspaces/{slug}/projects/{id}/issues/{id}/comments/` | Create |

## Links

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/{id}/issues/{id}/links/` | List |
| POST | `/workspaces/{slug}/projects/{id}/issues/{id}/links/` | Create |

## Projects

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workspaces/{slug}/projects/` | List |
| GET | `/workspaces/{slug}/projects/{id}/` | Retrieve |

## Pages

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/workspaces/{slug}/projects/{id}/pages/` | Create |
| GET | `/workspaces/{slug}/projects/{id}/pages/{id}/` | Retrieve |

## Epics, Initiatives, Milestones (may be tier-gated)

Same CRUD pattern. Verify against live API before building workflows.

## Pagination

All list endpoints use cursor-based pagination:
- `?per_page=100` (max 100)
- Response: `{ "results": [...], "next_page_results": bool, "next_cursor": "..." }`

## Rate Limits

60 requests per minute. Use 1.1s delay between calls.
