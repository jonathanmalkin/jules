#!/usr/bin/env python3
"""
Shared Plane API client for gap scripts.

Uses curl (not urllib/requests) because Plane returns 403 with Python HTTP clients.
Auth via PLANE_API_KEY env var. Rate-limited to 60 req/min.
"""

import json
import os
import re
import subprocess
import sys
import time

WORKSPACE = "[your-workspace-slug]"
PROJECT_ID = "8238b353-5e87-4b72-b199-fec061be8b98"
USER_ID = "[YOUR_USER_ID]"  # [Your Name]
API_BASE = "https://api.plane.so/api/v1"

TASK_DIR = "Documents/Grand-Plan/projects"
TASK_FILES = {
    "content": f"{TASK_DIR}/content/task-breakdown.md",
    "infrastructure": f"{TASK_DIR}/infrastructure/task-breakdown.md",
    "flourishing": f"{TASK_DIR}/flourishing/task-breakdown.md",
    "jules-public": f"{TASK_DIR}/jules-public/task-breakdown.md",
    "rebrand": f"{TASK_DIR}/rebrand/task-breakdown.md",
    "collaboration": f"{TASK_DIR}/collaboration/task-breakdown.md",
}

LABEL_NAMES = ["[your-name]", "jules-auto", "jules-interactive", "decision-needed", "deferred"]


def get_api_key():
    """Get API key from env, exit with instructions if missing."""
    key = os.environ.get("PLANE_API_KEY", "")
    if not key:
        print("ERROR: Set PLANE_API_KEY env var", file=sys.stderr)
        print(
            '  PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets"'
            ' --fields label="API Key" --reveal) python3 <script>',
            file=sys.stderr,
        )
        sys.exit(1)
    return key


def api(method, url, data=None, dry_run=False):
    """Make API call via curl. Returns parsed JSON response."""
    api_key = get_api_key()

    if dry_run and method != "GET":
        print(f"  [dry-run] {method} {url}")
        if data:
            print(f"            {json.dumps(data)[:200]}")
        return {"id": "dry-run"}

    cmd = [
        "curl", "-s", "-X", method,
        "-H", f"X-API-Key: {api_key}",
        "-H", "Content-Type: application/json",
        url,
    ]
    if data:
        cmd.extend(["-d", json.dumps(data)])

    time.sleep(1.1)  # Rate limit: 60 req/min
    result = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"error": result.stdout[:300], "stderr": result.stderr[:200]}


def project_url(endpoint=""):
    """Build URL for project-scoped endpoints."""
    return f"{API_BASE}/workspaces/{WORKSPACE}/projects/{PROJECT_ID}{endpoint}"


def workspace_url(endpoint=""):
    """Build URL for workspace-scoped endpoints."""
    return f"{API_BASE}/workspaces/{WORKSPACE}{endpoint}"


def paginate(method, url, key="results"):
    """Fetch all pages from a paginated endpoint."""
    all_items = []
    cursor = None
    while True:
        page_url = f"{url}{'&' if '?' in url else '?'}per_page=100"
        if cursor:
            page_url += f"&cursor={cursor}"
        resp = api(method, page_url)
        items = resp.get(key, [])
        if isinstance(items, list):
            all_items.extend(items)
        if not resp.get("next_page_results"):
            break
        cursor = resp.get("next_cursor")
        if not cursor:
            break
    return all_items


def fetch_all_issues():
    """Fetch all project issues using cursor-based pagination."""
    return paginate("GET", project_url("/issues/"))


def fetch_states():
    """Get state maps. Returns (friendly_map, uuid_to_group).

    friendly_map: {"done": uuid, "todo": uuid, "in_progress": uuid, ...}
    uuid_to_group: {uuid: "completed", uuid: "unstarted", ...}
    """
    resp = api("GET", project_url("/states/"))
    states = resp.get("results", resp if isinstance(resp, list) else [])
    state_map = {}
    uuid_to_group = {}
    for s in states:
        group = s.get("group", "")
        uuid_to_group[s["id"]] = group
        if group == "completed":
            state_map["done"] = s["id"]
        elif group == "unstarted":
            state_map["todo"] = s["id"]
        elif group == "started":
            state_map["in_progress"] = s["id"]
        elif group == "backlog":
            state_map["backlog"] = s["id"]
        elif group == "cancelled":
            state_map["cancelled"] = s["id"]
    return state_map, uuid_to_group


def fetch_modules():
    """Get module IDs by slug. Returns {"content": uuid, ...}."""
    resp = api("GET", project_url("/modules/"))
    modules = resp.get("results", resp if isinstance(resp, list) else [])
    name_to_slug = {
        "Content Pipeline": "content",
        "Infrastructure": "infrastructure",
        "Flourishing": "flourishing",
        "Jules Public": "jules-public",
        "Rebrand": "rebrand",
        "Collaboration": "collaboration",
    }
    return {name_to_slug[m["name"]]: m["id"] for m in modules if m["name"] in name_to_slug}


def fetch_labels():
    """Get label IDs by name. Returns {"[your-name]": uuid, ...}."""
    resp = api("GET", project_url("/labels/"))
    labels = resp.get("results", resp if isinstance(resp, list) else [])
    return {l["name"]: l["id"] for l in labels if l["name"] in LABEL_NAMES}


def extract_task_id_from_plane_name(name):
    """Extract the task ID from a Plane issue title.

    Format after polish: 'Description text [TASK-ID]'
    Format before polish: 'TASK-ID: Description text'
    """
    match = re.search(r'\[([A-Za-z0-9][\w-]*)\]\s*$', name)
    if match:
        return match.group(1)
    match = re.match(r'^([A-Za-z0-9][\w-]*?):\s', name)
    if match:
        return match.group(1)
    return None


def build_plane_task_id_map(issues):
    """Build {task_id: issue} lookup from a list of Plane issues."""
    mapping = {}
    for issue in issues:
        task_id = extract_task_id_from_plane_name(issue.get("name", ""))
        if task_id:
            mapping[task_id] = issue
    return mapping


def parse_markdown_tasks():
    """Parse all task-breakdown.md files. Returns {task_id: task_info}."""
    tasks = {}
    for slug, filepath in TASK_FILES.items():
        if not os.path.exists(filepath):
            continue
        with open(filepath) as f:
            current_section = ""
            for line in f:
                line = line.strip()
                if line.startswith("## "):
                    current_section = line[3:]
                    continue
                if not re.match(r'^- \[.\] `', line):
                    continue

                done = line.startswith("- [x]")

                id_match = re.search(r'`([^`]+)`', line)
                if not id_match:
                    continue
                task_id = id_match.group(1)

                fields = line.split("|")
                title = fields[1].strip() if len(fields) >= 2 else ""
                ownership = ""
                estimate = ""
                flags = []

                for field in fields[2:]:
                    field = field.strip()
                    if field in ("auto", "interactive"):
                        ownership = field
                    elif field.startswith("auto "):
                        ownership = "auto"
                    elif field.startswith("est:"):
                        estimate = field
                    elif field.startswith((
                        "decision:", "session-spec:", "plan:",
                        "scheduled:", "blocked-on:",
                    )):
                        flags.append(field)
                    elif "**active" in field:
                        ownership = "interactive"

                tasks[task_id] = {
                    "id": task_id,
                    "done": done,
                    "title": title,
                    "ownership": ownership,
                    "estimate": estimate,
                    "flags": flags,
                    "section": current_section,
                    "module_slug": slug,
                }
    return tasks
