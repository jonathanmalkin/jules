#!/usr/bin/env python3
"""Create a Plane work item and optionally add it to a module.

Usage:
    python3 plane_create.py "Fix login bug"
    python3 plane_create.py "Fix login bug" --module "Pending Review"
    python3 plane_create.py "Fix login bug" --state todo --priority medium
    python3 plane_create.py "Fix login bug" --dry-run

Output: JSON of created item to stdout.
"""

import argparse
import json
import sys

from plane_api import api, project_url, fetch_states, fetch_modules


PRIORITY_MAP = {"none": 0, "low": 1, "medium": 2, "high": 3, "urgent": 4}


def find_module_by_name(name):
    resp = api("GET", project_url("/modules/"))
    modules = resp.get("results", resp if isinstance(resp, list) else [])
    for m in modules:
        if m["name"].lower() == name.lower():
            return m["id"]
    return None


def main():
    parser = argparse.ArgumentParser(description="Create Plane work item")
    parser.add_argument("title", help="Item title")
    parser.add_argument("--description", default="", help="Item description")
    parser.add_argument("--state", default="todo",
                        choices=["todo", "in_progress", "done", "backlog", "cancelled"])
    parser.add_argument("--priority", default="none",
                        choices=["none", "low", "medium", "high", "urgent"])
    parser.add_argument("--module", help="Module name to add item to")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    state_map, _ = fetch_states()
    state_id = state_map.get(args.state)
    if not state_id:
        print(f"State '{args.state}' not found", file=sys.stderr)
        sys.exit(1)

    data = {
        "name": args.title,
        "state": state_id,
        "priority": PRIORITY_MAP[args.priority],
    }
    if args.description:
        data["description_html"] = f"<p>{args.description}</p>"

    result = api("POST", project_url("/issues/"), data, dry_run=args.dry_run)

    if args.module and not args.dry_run:
        mod_id = find_module_by_name(args.module)
        if mod_id:
            issue_id = result.get("id")
            if issue_id:
                api("POST", project_url(f"/modules/{mod_id}/issues/"),
                     {"issues": [issue_id]})
                result["_added_to_module"] = args.module
        else:
            result["_module_warning"] = f"Module '{args.module}' not found"

    json.dump(result, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
