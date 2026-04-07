#!/usr/bin/env python3
"""List Plane work items, cycles, and modules with filtering.

Usage:
    python3 plane_list.py items                          # All active items
    python3 plane_list.py items --state todo,in_progress # Filter by state
    python3 plane_list.py items --module infrastructure  # Filter by module
    python3 plane_list.py items --due-within 7           # Due within N days
    python3 plane_list.py cycles                         # All cycles
    python3 plane_list.py modules                        # All modules
    python3 plane_list.py module-items "Pending Review"  # Items in a module

Output: JSON to stdout for script consumption.
"""

import argparse
import json
import sys
from datetime import datetime, timedelta

from plane_api import (
    api, paginate, project_url, fetch_states, fetch_modules,
    fetch_all_issues, PROJECT_ID, WORKSPACE, API_BASE,
)


def list_items(args):
    state_map, uuid_to_group = fetch_states()
    issues = fetch_all_issues()

    if args.state:
        allowed_groups = set()
        for s in args.state.split(","):
            s = s.strip()
            if s == "todo":
                allowed_groups.add("unstarted")
            elif s == "in_progress":
                allowed_groups.add("started")
            elif s == "done":
                allowed_groups.add("completed")
            else:
                allowed_groups.add(s)
        issues = [i for i in issues if uuid_to_group.get(i.get("state")) in allowed_groups]

    if args.module:
        modules = fetch_modules()
        mod_id = modules.get(args.module)
        if mod_id:
            mod_issues = paginate(
                "GET",
                project_url(f"/modules/{mod_id}/issues/"),
            )
            mod_issue_ids = {i.get("issue") or i.get("id") for i in mod_issues}
            issues = [i for i in issues if i["id"] in mod_issue_ids]

    if args.due_within:
        cutoff = datetime.now() + timedelta(days=args.due_within)
        filtered = []
        for i in issues:
            due = i.get("target_date")
            if due:
                due_date = datetime.strptime(due, "%Y-%m-%d")
                if due_date <= cutoff:
                    filtered.append(i)
        issues = filtered

    results = []
    for i in issues:
        group = uuid_to_group.get(i.get("state"), "unknown")
        results.append({
            "id": i["id"],
            "identifier": i.get("project_detail", {}).get("identifier", "GP")
                + "-" + str(i.get("sequence_id", "")),
            "name": i.get("name", ""),
            "state": group,
            "priority": i.get("priority"),
            "due": i.get("target_date"),
            "assignees": i.get("assignees", []),
        })

    json.dump(results, sys.stdout, indent=2)
    print()


def list_cycles(_args):
    resp = api("GET", project_url("/cycles/"))
    cycles = resp.get("results", resp if isinstance(resp, list) else [])
    results = []
    for c in cycles:
        results.append({
            "id": c["id"],
            "name": c.get("name", ""),
            "start": c.get("start_date"),
            "end": c.get("end_date"),
            "status": c.get("status"),
        })
    json.dump(results, sys.stdout, indent=2)
    print()


def list_modules(_args):
    resp = api("GET", project_url("/modules/"))
    modules = resp.get("results", resp if isinstance(resp, list) else [])
    results = []
    for m in modules:
        results.append({
            "id": m["id"],
            "name": m.get("name", ""),
            "status": m.get("status"),
        })
    json.dump(results, sys.stdout, indent=2)
    print()


def list_module_items(args):
    resp = api("GET", project_url("/modules/"))
    modules = resp.get("results", resp if isinstance(resp, list) else [])
    target = None
    for m in modules:
        if m["name"].lower() == args.module_name.lower():
            target = m
            break
    if not target:
        print(f"Module '{args.module_name}' not found", file=sys.stderr)
        sys.exit(1)

    mod_issues = paginate("GET", project_url(f"/modules/{target['id']}/issues/"))
    state_map, uuid_to_group = fetch_states()

    # Module issues endpoint returns issue details inline
    results = []
    for i in mod_issues:
        issue = i.get("issue_detail", i)
        group = uuid_to_group.get(issue.get("state"), "unknown")
        results.append({
            "id": issue.get("id", i.get("issue", "")),
            "name": issue.get("name", ""),
            "state": group,
            "priority": issue.get("priority"),
            "due": issue.get("target_date"),
        })

    json.dump(results, sys.stdout, indent=2)
    print()


def main():
    parser = argparse.ArgumentParser(description="List Plane data")
    sub = parser.add_subparsers(dest="command", required=True)

    items_p = sub.add_parser("items")
    items_p.add_argument("--state", help="Comma-separated: todo,in_progress,done,backlog,cancelled")
    items_p.add_argument("--module", help="Module slug: infrastructure, content, etc.")
    items_p.add_argument("--due-within", type=int, help="Due within N days")

    sub.add_parser("cycles")
    sub.add_parser("modules")

    mod_items_p = sub.add_parser("module-items")
    mod_items_p.add_argument("module_name", help="Module name (e.g. 'Pending Review')")

    args = parser.parse_args()

    if args.command == "items":
        list_items(args)
    elif args.command == "cycles":
        list_cycles(args)
    elif args.command == "modules":
        list_modules(args)
    elif args.command == "module-items":
        list_module_items(args)


if __name__ == "__main__":
    main()
