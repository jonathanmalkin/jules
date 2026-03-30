#!/usr/bin/env python3
"""
Compare local task-breakdown.md status with Plane Cloud status.

Read-only. Shows side-by-side diff without changing anything.

Usage:
    PLANE_API_KEY=... python3 plane_compare.py
    PLANE_API_KEY=... python3 plane_compare.py --json
    PLANE_API_KEY=... python3 plane_compare.py --module infrastructure

Or with 1Password:
    PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
        python3 .claude/skills/plane/scripts/plane_compare.py
"""

import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from plane_api import (
    fetch_all_issues,
    fetch_states,
    build_plane_task_id_map,
    parse_markdown_tasks,
)


# Map Plane state groups to display labels
GROUP_DISPLAY = {
    "completed": "completed",
    "started": "started",
    "unstarted": "todo",
    "backlog": "backlog",
    "cancelled": "cancelled",
}


def compare(module_filter=None):
    """Compare local markdown with Plane. Returns list of comparison rows."""
    print("[compare] Fetching Plane data...", file=sys.stderr)
    issues = fetch_all_issues()
    _state_map, uuid_to_group = fetch_states()

    plane_by_id = build_plane_task_id_map(issues)

    print("[compare] Parsing local markdown...", file=sys.stderr)
    md_tasks = parse_markdown_tasks()

    rows = []
    all_task_ids = set(md_tasks.keys()) | set(plane_by_id.keys())

    for task_id in sorted(all_task_ids):
        md = md_tasks.get(task_id)
        plane = plane_by_id.get(task_id)

        if module_filter and md and md["module_slug"] != module_filter:
            continue

        # Local status
        if md:
            local_status = "done" if md["done"] else "todo"
        else:
            local_status = "-"

        # Plane status
        if plane:
            plane_state_uuid = plane.get("state", "")
            plane_group = uuid_to_group.get(plane_state_uuid, "unknown")
            plane_status = GROUP_DISPLAY.get(plane_group, plane_group)
        else:
            plane_status = "-"

        # Determine diff
        if local_status == "-":
            diff = "PLANE ONLY"
        elif plane_status == "-":
            diff = "LOCAL ONLY"
        elif local_status == "done" and plane_status == "completed":
            diff = "IN SYNC"
        elif local_status == "todo" and plane_status in ("todo", "backlog"):
            diff = "IN SYNC"
        elif local_status == "done" and plane_status != "completed":
            diff = "LOCAL AHEAD"
        elif local_status == "todo" and plane_status == "completed":
            diff = "PLANE AHEAD"
        elif local_status == "todo" and plane_status == "started":
            diff = "PLANE AHEAD"
        elif local_status == "todo" and plane_status == "cancelled":
            diff = "PLANE AHEAD"
        else:
            diff = "MISMATCH"

        rows.append({
            "task_id": task_id,
            "local": local_status,
            "plane": plane_status,
            "diff": diff,
            "module": md["module_slug"] if md else "",
        })

    return rows


def format_table(rows):
    """Format comparison as aligned table."""
    if not rows:
        return "No tasks found."

    # Header
    lines = [
        f"{'TASK-ID':<16} {'LOCAL':<12} {'PLANE':<12} {'DIFF':<14} {'MODULE'}",
        f"{'-'*16} {'-'*12} {'-'*12} {'-'*14} {'-'*16}",
    ]

    for r in rows:
        lines.append(
            f"{r['task_id']:<16} {r['local']:<12} {r['plane']:<12} "
            f"{r['diff']:<14} {r['module']}"
        )

    # Summary
    in_sync = sum(1 for r in rows if r["diff"] == "IN SYNC")
    plane_ahead = sum(1 for r in rows if r["diff"] == "PLANE AHEAD")
    local_ahead = sum(1 for r in rows if r["diff"] == "LOCAL AHEAD")
    plane_only = sum(1 for r in rows if r["diff"] == "PLANE ONLY")
    local_only = sum(1 for r in rows if r["diff"] == "LOCAL ONLY")
    mismatch = sum(1 for r in rows if r["diff"] == "MISMATCH")

    lines.append("")
    parts = [f"{in_sync} in sync"]
    if plane_ahead:
        parts.append(f"{plane_ahead} Plane ahead")
    if local_ahead:
        parts.append(f"{local_ahead} local ahead")
    if plane_only:
        parts.append(f"{plane_only} Plane only")
    if local_only:
        parts.append(f"{local_only} local only")
    if mismatch:
        parts.append(f"{mismatch} mismatch")
    lines.append(f"Summary: {', '.join(parts)} ({len(rows)} total)")

    return "\n".join(lines)


def main():
    flags = {}
    for arg in sys.argv[1:]:
        if "=" in arg and arg.startswith("--"):
            key, val = arg.lstrip("-").split("=", 1)
            flags[key] = val
        elif arg.startswith("--"):
            flags[arg.lstrip("-")] = True

    module_filter = flags.get("module")
    rows = compare(module_filter)

    if flags.get("json"):
        print(json.dumps(rows, indent=2))
    elif flags.get("diff-only"):
        diff_rows = [r for r in rows if r["diff"] != "IN SYNC"]
        print(format_table(diff_rows))
    else:
        print(format_table(rows))


if __name__ == "__main__":
    main()
