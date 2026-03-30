#!/usr/bin/env python3
"""
Thin wrapper over Scripts/plane-sync.py for the Plane skill.

Adds convenience: auto-injects credentials via op run, defaults to dry-run.
Pass --apply to actually write changes.

Usage:
    python3 .claude/skills/plane/scripts/plane_sync.py              # dry-run (safe)
    python3 .claude/skills/plane/scripts/plane_sync.py --apply      # live changes

Requires PLANE_API_KEY in env or 1Password access via op.
"""

import os
import subprocess
import sys

SYNC_SCRIPT = os.path.join(
    os.path.dirname(__file__), "..", "..", "..", "..", "Scripts", "plane-sync.py"
)


def main():
    # Resolve the path to the original sync script
    script_path = os.path.normpath(SYNC_SCRIPT)
    if not os.path.exists(script_path):
        print(f"ERROR: Cannot find sync script at {script_path}", file=sys.stderr)
        sys.exit(1)

    # Build command args
    args = ["python3", script_path]

    # Default to dry-run unless --apply is passed
    if "--apply" not in sys.argv:
        args.append("--dry-run")
        print("[plane-sync] Running in DRY-RUN mode (pass --apply for live changes)")
    else:
        print("[plane-sync] Running in LIVE mode")

    # If PLANE_API_KEY is not set, try to inject via op
    env = os.environ.copy()
    if not env.get("PLANE_API_KEY"):
        print("[plane-sync] PLANE_API_KEY not set, injecting via 1Password...")
        try:
            key = subprocess.run(
                [
                    "op", "item", "get", "Plane API",
                    "--vault", "Dev Secrets",
                    "--fields", "label=API Key",
                    "--reveal",
                ],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            env["PLANE_API_KEY"] = key
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"ERROR: Could not get API key from 1Password: {e}", file=sys.stderr)
            print('  Set PLANE_API_KEY manually or ensure op CLI is configured', file=sys.stderr)
            sys.exit(1)

    # Run the sync script
    result = subprocess.run(args, env=env)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
