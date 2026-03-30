#!/usr/bin/env python3
"""
Resolve a human-readable Plane identifier (e.g., GP-42) to full work item details.

Usage:
    PLANE_API_KEY=... python3 plane_lookup.py GP-42
    PLANE_API_KEY=... python3 plane_lookup.py 42       # assumes GP- prefix

Or with 1Password:
    PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
        python3 .claude/skills/plane/scripts/plane_lookup.py GP-42
"""

import json
import sys
import os

# Add parent dir so we can import plane_api
sys.path.insert(0, os.path.dirname(__file__))
from plane_api import api, workspace_url


def lookup(identifier):
    """Resolve an identifier like GP-42 to full issue details."""
    # Normalize: if just a number, prepend GP-
    if identifier.isdigit():
        identifier = f"GP-{identifier}"

    # Use the work-items endpoint which accepts project_identifier-sequence_id
    url = workspace_url(f"/work-items/{identifier}/")
    resp = api("GET", url)

    if "error" in resp or "detail" in resp:
        print(f"ERROR: Could not resolve {identifier}", file=sys.stderr)
        print(f"  Response: {json.dumps(resp)[:300]}", file=sys.stderr)
        sys.exit(1)

    return resp


def format_issue(issue):
    """Format issue for human-readable output."""
    lines = []
    lines.append(f"  Identifier: {issue.get('project_detail', {}).get('identifier', '?')}-{issue.get('sequence_id', '?')}")
    lines.append(f"  Title: {issue.get('name', 'N/A')}")
    lines.append(f"  State: {issue.get('state_detail', {}).get('name', 'N/A')} ({issue.get('state_detail', {}).get('group', 'N/A')})")

    priority_map = {0: "Urgent", 1: "High", 2: "Medium", 3: "Low", 4: "None"}
    lines.append(f"  Priority: {priority_map.get(issue.get('priority'), 'Unknown')}")

    labels = issue.get("label_detail", [])
    if labels:
        label_names = [l.get("name", "?") for l in labels]
        lines.append(f"  Labels: {', '.join(label_names)}")

    assignees = issue.get("assignee_detail", [])
    if assignees:
        names = [a.get("display_name", a.get("email", "?")) for a in assignees]
        lines.append(f"  Assignees: {', '.join(names)}")

    if issue.get("start_date"):
        lines.append(f"  Start: {issue['start_date']}")
    if issue.get("target_date"):
        lines.append(f"  Target: {issue['target_date']}")

    lines.append(f"  Created: {issue.get('created_at', 'N/A')[:10]}")
    lines.append(f"  UUID: {issue.get('id', 'N/A')}")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: plane_lookup.py <IDENTIFIER>")
        print("  e.g., plane_lookup.py GP-42")
        print("  e.g., plane_lookup.py 42  (assumes GP- prefix)")
        sys.exit(1)

    identifier = sys.argv[1]
    issue = lookup(identifier)

    # Output as JSON if --json flag, otherwise human-readable
    if "--json" in sys.argv:
        print(json.dumps(issue, indent=2))
    else:
        print(format_issue(issue))


if __name__ == "__main__":
    main()
