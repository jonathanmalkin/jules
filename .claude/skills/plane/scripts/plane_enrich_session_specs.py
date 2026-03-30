#!/usr/bin/env python3
"""
Enrich existing Plane issues with session-spec content from task-breakdown.md files.

Reads task-breakdown lines, extracts session-spec text, finds the matching Plane issue,
and appends the session-spec to the issue description if not already present.

One-shot script for Phase 1.5B of Plane evaluation.

Usage:
    PLANE_API_KEY=... python3 plane_enrich_session_specs.py              # dry-run
    PLANE_API_KEY=... python3 plane_enrich_session_specs.py --apply       # update issues
"""

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from plane_api import (
    api, project_url, fetch_all_issues, fetch_states,
    build_plane_task_id_map, TASK_FILES,
)

DRY_RUN = "--apply" not in sys.argv

# Plan file references: task_id -> plan file path
PLAN_REFS = {
    "J-A0": "~/.claude/plans/jules-reference-diagrams.md",
    "P6-6A": "Documents/Field-Notes/Plans/2026-03-21-Self-Healing-Container-Jobs.md",
    "P6-6B": "Documents/Field-Notes/Plans/2026-03-21-Self-Healing-Container-Jobs.md",
    "P6-6C": "Documents/Field-Notes/Plans/2026-03-21-Self-Healing-Container-Jobs.md",
    "P6-6D": "Documents/Field-Notes/Plans/2026-03-21-Self-Healing-Container-Jobs.md",
    "P6-6E": "Documents/Field-Notes/Plans/2026-03-21-Self-Healing-Container-Jobs.md",
    "P10-10A": "Documents/Field-Notes/Plans/2026-03-22-Feedback-Loops-Framework.md",
    "P10-10B": "Documents/Field-Notes/Plans/2026-03-22-Feedback-Loops-Framework.md",
    "P10-10C": "Documents/Field-Notes/Plans/2026-03-22-Feedback-Loops-Framework.md",
    "P10-10D": "Documents/Field-Notes/Plans/2026-03-22-Feedback-Loops-Framework.md",
    "P10-10E": "Documents/Field-Notes/Plans/2026-03-22-Feedback-Loops-Framework.md",
    "P10-10F": "Documents/Field-Notes/Plans/2026-03-22-Feedback-Loops-Framework.md",
    "P13-13A": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13B": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13C": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13D": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13E": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13F": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13G": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P13-13H": "Documents/Field-Notes/Plans/2026-03-23-xAI-Sonar-API-Integration-Design.md",
    "P14-14A": "~/.claude/plans/linked-brewing-pancake.md",
    "P14-14B": "~/.claude/plans/linked-brewing-pancake.md",
    "P14-14C": "~/.claude/plans/linked-brewing-pancake.md",
    "P12-12A": "Documents/Field-Notes/Plans/Grand-Plan/2-Infrastructure.md",
}


def extract_session_specs():
    """Parse task-breakdown files for session-spec content. Returns {task_id: spec_text}."""
    specs = {}
    for slug, filepath in TASK_FILES.items():
        if not os.path.exists(filepath):
            continue
        with open(filepath) as f:
            for line in f:
                stripped = line.strip()
                if not re.match(r'^- \[ \] `', stripped):
                    continue  # Only incomplete tasks

                id_match = re.search(r'`([^`]+)`', stripped)
                if not id_match:
                    continue
                task_id = id_match.group(1)

                # Extract session-spec
                spec_match = re.search(r'session-spec:\s*(.+?)(?:\s*\||\s*$)', stripped)
                if spec_match:
                    specs[task_id] = spec_match.group(1).strip()

    return specs


def build_enriched_description(existing_html, session_spec, plan_ref, task_id):
    """Build enriched HTML description."""
    parts = []

    # Keep existing description
    if existing_html and existing_html.strip():
        parts.append(existing_html)

    # Add session spec if not already in description
    if session_spec and "Session Spec" not in (existing_html or ""):
        parts.append(f"<h3>Session Spec</h3><p>{session_spec}</p>")

    # Add plan reference
    if plan_ref and "Plan File" not in (existing_html or ""):
        parts.append(f"<h3>Plan File</h3><p><code>{plan_ref}</code></p>")

    return "\n".join(parts)


def main():
    mode = "DRY RUN" if DRY_RUN else "LIVE"
    print(f"[enrich] Plane Issue Enrichment | Mode: {mode}\n")

    # Fetch Plane issues
    print("[enrich] Fetching Plane data...")
    issues = fetch_all_issues()
    plane_by_id = build_plane_task_id_map(issues)
    print(f"  {len(plane_by_id)} issues matched by task ID")

    # Extract session specs from markdown
    print("[enrich] Parsing session-specs from task-breakdown files...")
    specs = extract_session_specs()
    print(f"  Found {len(specs)} tasks with session-specs")

    # Find tasks to enrich
    updates = []
    for task_id in set(list(specs.keys()) + list(PLAN_REFS.keys())):
        plane_issue = plane_by_id.get(task_id)
        if not plane_issue:
            continue

        session_spec = specs.get(task_id)
        plan_ref = PLAN_REFS.get(task_id)

        # Check if already enriched
        existing = plane_issue.get("description_html", "") or ""
        if session_spec and "Session Spec" in existing:
            session_spec = None
        if plan_ref and "Plan File" in existing:
            plan_ref = None

        if not session_spec and not plan_ref:
            continue

        new_desc = build_enriched_description(existing, session_spec, plan_ref, task_id)
        updates.append({
            "task_id": task_id,
            "issue_id": plane_issue["id"],
            "session_spec": session_spec,
            "plan_ref": plan_ref,
            "new_description_html": new_desc,
        })

    print(f"\n[enrich] {len(updates)} issues to enrich")

    for u in updates:
        parts = []
        if u["session_spec"]:
            parts.append(f"spec: {u['session_spec'][:60]}...")
        if u["plan_ref"]:
            parts.append(f"plan: {u['plan_ref']}")
        detail = " + ".join(parts)

        if DRY_RUN:
            print(f"  [dry-run] {u['task_id']}: {detail}")
        else:
            print(f"  UPDATE: {u['task_id']}: {detail}")
            resp = api("PATCH", project_url(f"/issues/{u['issue_id']}/"),
                       {"description_html": u["new_description_html"]})
            if "error" in resp:
                print(f"    ERROR: {json.dumps(resp)[:200]}")

    print(f"\n[enrich] {'Would update' if DRY_RUN else 'Updated'} {len(updates)} issues")


if __name__ == "__main__":
    main()
