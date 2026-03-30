#!/usr/bin/env python3
"""
Pull Plane Cloud status changes into local task-breakdown.md files.

Dry-run by default. Pass --apply to write changes (with backup).

Usage:
    PLANE_API_KEY=... python3 plane_pull.py              # dry-run (safe)
    PLANE_API_KEY=... python3 plane_pull.py --apply       # write changes

Or with 1Password:
    PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal) \
        python3 .claude/skills/plane/scripts/plane_pull.py
"""

import json
import os
import re
import shutil
import sys
from datetime import date

sys.path.insert(0, os.path.dirname(__file__))
from plane_api import (
    fetch_all_issues,
    fetch_states,
    build_plane_task_id_map,
    TASK_FILES,
)


BACKUP_DIR = ".plane-pull-backup"

# Map Plane state groups to display labels (for reporting)
GROUP_DISPLAY = {
    "completed": "completed",
    "started": "started",
    "unstarted": "todo",
    "backlog": "backlog",
    "cancelled": "cancelled",
}


def compute_changes(plane_by_id, uuid_to_group):
    """Scan all task-breakdown files and compute needed changes.

    Returns list of {file, task_id, line_num, old_line, new_line, action}.
    """
    changes = []
    today = date.today().isoformat()

    for slug, filepath in TASK_FILES.items():
        if not os.path.exists(filepath):
            continue

        with open(filepath) as f:
            lines = f.readlines()

        for i, line in enumerate(lines):
            stripped = line.strip()
            if not re.match(r'^- \[.\] `', stripped):
                continue

            # Extract task ID
            id_match = re.search(r'`([^`]+)`', stripped)
            if not id_match:
                continue
            task_id = id_match.group(1)

            # Check if this task exists in Plane
            plane_issue = plane_by_id.get(task_id)
            if not plane_issue:
                continue

            plane_state_uuid = plane_issue.get("state", "")
            plane_group = uuid_to_group.get(plane_state_uuid, "unknown")

            is_local_done = stripped.startswith("- [x]")
            has_active = "**active**" in stripped

            new_line = line

            if plane_group == "completed" and not is_local_done:
                # Plane completed, local not done -> mark done
                new_line = new_line.replace("- [ ]", "- [x]", 1)
                # Remove **active** marker if present
                new_line = re.sub(r'\s*\|\s*\*\*active\*\*', '', new_line)
                # Add completed date if not already present
                if "completed:" not in new_line:
                    new_line = new_line.rstrip("\n") + f" | completed:{today}\n"
                changes.append({
                    "file": filepath,
                    "task_id": task_id,
                    "line_num": i,
                    "old_line": line,
                    "new_line": new_line,
                    "action": "COMPLETE",
                    "plane_group": plane_group,
                })

            elif plane_group in ("unstarted", "backlog") and is_local_done:
                # Plane reopened, local is done -> mark undone
                new_line = new_line.replace("- [x]", "- [ ]", 1)
                # Remove completed:date
                new_line = re.sub(r'\s*\|\s*completed:\S+', '', new_line)
                changes.append({
                    "file": filepath,
                    "task_id": task_id,
                    "line_num": i,
                    "old_line": line,
                    "new_line": new_line,
                    "action": "REOPEN",
                    "plane_group": plane_group,
                })

            elif plane_group == "started" and not is_local_done and not has_active:
                # Plane in progress, local doesn't show active -> add marker
                new_line = new_line.rstrip("\n") + " | **active**\n"
                changes.append({
                    "file": filepath,
                    "task_id": task_id,
                    "line_num": i,
                    "old_line": line,
                    "new_line": new_line,
                    "action": "ACTIVATE",
                    "plane_group": plane_group,
                })

            elif plane_group == "cancelled" and not is_local_done:
                # Plane cancelled -> append marker
                if "cancelled" not in stripped:
                    new_line = new_line.rstrip("\n") + " | cancelled\n"
                    changes.append({
                        "file": filepath,
                        "task_id": task_id,
                        "line_num": i,
                        "old_line": line,
                        "new_line": new_line,
                        "action": "CANCEL",
                        "plane_group": plane_group,
                    })

    return changes


def apply_changes(changes):
    """Apply changes to files with backup."""
    os.makedirs(BACKUP_DIR, exist_ok=True)

    # Group changes by file
    files_changed = {}
    for c in changes:
        files_changed.setdefault(c["file"], []).append(c)

    for filepath, file_changes in files_changed.items():
        # Backup
        backup_name = filepath.replace("/", "_")
        backup_path = os.path.join(BACKUP_DIR, backup_name)
        shutil.copy2(filepath, backup_path)
        print(f"  Backed up: {filepath} -> {backup_path}")

        # Read, modify, write
        with open(filepath) as f:
            lines = f.readlines()

        for c in file_changes:
            lines[c["line_num"]] = c["new_line"]

        with open(filepath, "w") as f:
            f.writelines(lines)

        print(f"  Updated: {filepath} ({len(file_changes)} changes)")


def format_report(changes):
    """Format change report for human output."""
    if not changes:
        return "No changes needed. Local and Plane are in sync."

    lines = [f"Found {len(changes)} changes to pull:\n"]
    for c in changes:
        task_id = c["task_id"]
        action = c["action"]
        plane_group = c["plane_group"]
        lines.append(f"  {action:<10} {task_id:<16} (Plane: {plane_group})")

    return "\n".join(lines)


def main():
    apply = "--apply" in sys.argv
    json_output = "--json" in sys.argv

    mode = "LIVE" if apply else "DRY RUN"
    print(f"[pull] Plane Pull -- Plane Cloud -> task-breakdown.md")
    print(f"[pull] Mode: {mode}")
    print()

    print("[pull] Fetching Plane data...")
    issues = fetch_all_issues()
    _state_map, uuid_to_group = fetch_states()
    plane_by_id = build_plane_task_id_map(issues)
    print(f"  Found {len(issues)} issues ({len(plane_by_id)} matched by task ID)")

    print("\n[pull] Scanning local markdown for diffs...")
    changes = compute_changes(plane_by_id, uuid_to_group)

    if json_output:
        # Sanitize for JSON (remove raw lines)
        output = [{
            "task_id": c["task_id"],
            "action": c["action"],
            "file": c["file"],
            "plane_group": c["plane_group"],
        } for c in changes]
        print(json.dumps(output, indent=2))
        return

    print(format_report(changes))

    if not changes:
        return

    if apply:
        print(f"\n[pull] Applying {len(changes)} changes...")
        apply_changes(changes)
        print(f"\n[pull] Done! Backups in {BACKUP_DIR}/")
    else:
        print(f"\n[pull] Dry run complete. Run with --apply to write changes.")


if __name__ == "__main__":
    main()
