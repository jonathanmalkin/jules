# Plane API Patterns

## curl, not urllib

Plane's API returns 403 when called with Python's `urllib` or `requests`. Root cause unknown but consistently observed across all five migration scripts. Always use `subprocess` + `curl`.

```python
cmd = [
    "curl", "-s", "-X", method,
    "-H", f"X-API-Key: {api_key}",
    "-H", "Content-Type: application/json",
    url,
]
if data:
    cmd.extend(["-d", json.dumps(data)])
result = subprocess.run(cmd, capture_output=True, text=True)
```

## Rate Limiting

60 requests per minute. Use 1.1s sleep between calls. For bulk operations, this is the bottleneck.

## Pagination

Cursor-based. Response includes:
- `results`: array of items
- `next_page_results`: boolean
- `next_cursor`: string cursor for next page

```python
while True:
    url = f"/issues/?per_page=100"
    if cursor:
        url += f"&cursor={cursor}"
    resp = api("GET", url)
    all_items.extend(resp.get("results", []))
    if not resp.get("next_page_results"):
        break
    cursor = resp.get("next_cursor")
```

## Issue Title Convention

Post-migration format: `Description text [TASK-ID]`

Extract with: `re.search(r'\[([A-Za-z0-9][\w-]*)\]\s*$', name)`

## State Mapping

Plane states belong to groups. Map by group name, not state name:
- `backlog` -> Backlog
- `unstarted` -> Todo
- `started` -> In Progress
- `completed` -> Done
- `cancelled` -> Cancelled

## Relations

Created via: `POST /issues/{id}/relations/`
```json
{"relation_type": "blocked_by", "issues": ["uuid-of-blocking-issue"]}
```

Valid types: `blocked_by`, `blocking`, `relates_to`, `duplicate`

## Description Format

Plane uses HTML for descriptions (`description_html` field). Simple HTML tags work:
```html
<p><strong>Task ID:</strong> <code>S1-C01</code></p>
```

## Dry Run Pattern

All gap scripts support `--dry-run` which skips write operations but still reads:
```python
DRY_RUN = "--dry-run" in sys.argv
if DRY_RUN and method not in ("GET",):
    print(f"  [dry-run] {method} {endpoint}")
    return {"id": "dry-run"}
```
