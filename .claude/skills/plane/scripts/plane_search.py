#!/usr/bin/env python3
"""
Search Plane work items by keyword across the workspace.

Usage:
    PLANE_API_KEY=... python3 plane_search.py "authentication"
    PLANE_API_KEY=... python3 plane_search.py "deploy" --state todo
    PLANE_API_KEY=... python3 plane_search.py "jules" --label jules-auto

Or with 1Password:
    PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
        python3 .claude/skills/plane/scripts/plane_search.py "authentication"
"""

import json
import re
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from plane_api import api, workspace_url, paginate, project_url


def search(query, state_filter=None, label_filter=None):
    """Search work items by keyword.

    Fetches all project issues and filters client-side by title/description.
    The workspace-level search API requires different auth, so we use
    project-scoped listing with local text matching.
    """
    all_issues = paginate("GET", project_url("/issues/"))

    query_lower = query.lower()
    results = []
    for issue in all_issues:
        name = issue.get("name", "").lower()
        desc = issue.get("description_stripped", "").lower()
        if query_lower in name or query_lower in desc:
            results.append(issue)

    # Apply state filter (uses state UUID, needs state lookup)
    # For now, skip state filtering since we don't have state_detail in list response
    # TODO: Fetch states and build UUID->group map for filtering

    return results


def format_results(results, query):
    """Format search results for human output."""
    if not results:
        return f"No results for '{query}'"

    lines = [f"Found {len(results)} results for '{query}':", ""]
    for r in results:
        seq_id = r.get("sequence_id", "?")
        identifier = f"GP-{seq_id}"
        name = r.get("name", "N/A")

        priority_names = {"urgent": "!!!", "high": "!!", "medium": "!", "low": "", "none": ""}
        priority = r.get("priority", "none")
        priority_str = priority_names.get(priority, "")
        if priority_str:
            priority_str = f" {priority_str}"

        lines.append(f"  {identifier}{priority_str} | {name[:70]}")

    return "\n".join(lines)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a.split("=")[0].lstrip("-"): a.split("=")[1] if "=" in a else True for a in sys.argv[1:] if a.startswith("--")}

    if not args:
        print("Usage: plane_search.py <QUERY> [--state todo|started|completed] [--label name]")
        sys.exit(1)

    query = args[0]
    state_filter = flags.get("state")
    label_filter = flags.get("label")

    # Map friendly state names to group names
    state_map = {"todo": "unstarted", "in_progress": "started", "done": "completed"}
    if state_filter and state_filter in state_map:
        state_filter = state_map[state_filter]

    results = search(query, state_filter, label_filter)

    if flags.get("json"):
        print(json.dumps(results, indent=2))
    else:
        print(format_results(results, query))


if __name__ == "__main__":
    main()
