#!/usr/bin/env python3
"""Create a compact wrap-up report artifact.

This is a manual helper, not a background job. It writes only when --write is
provided and stores a Markdown report plus a JSON sidecar under System/Runs.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path
from zoneinfo import ZoneInfo


CENTRAL = ZoneInfo("America/Chicago")


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", value.strip().lower()).strip("-")
    return slug[:72] or "wrap-up"


def repeated(values: list[str] | None) -> list[str]:
    return [value.strip() for value in values or [] if value.strip()]


def build_record(args: argparse.Namespace) -> dict[str, object]:
    now = dt.datetime.now(CENTRAL)
    focus = args.focus.strip()
    slug = args.slug or slugify(focus)
    surface = slugify(args.surface)
    day = now.strftime("%Y-%m-%d")
    stamp = now.strftime("%H%M%S")
    workspace = Path(args.workspace).expanduser().resolve()
    base = workspace / "System" / "Runs" / surface / "wrap-up" / day
    stem = f"{stamp}-{slug}"

    return {
        "created_at": now.isoformat(),
        "workspace": str(workspace),
        "surface": args.surface,
        "status": args.status,
        "focus": focus,
        "summary": args.summary.strip(),
        "verification": repeated(args.verification),
        "git": {
            "branch": args.branch,
            "commit": args.commit,
            "push": args.push,
        },
        "scheduler_safety": repeated(args.scheduler_safety),
        "open_loops": repeated(args.open_loop),
        "improvement_candidates": repeated(args.improvement),
        "resume_prompt": args.resume_prompt.strip(),
        "paths": {
            "directory": str(base),
            "markdown": str(base / f"{stem}.md"),
            "json": str(base / f"{stem}.json"),
        },
    }


def markdown(record: dict[str, object]) -> str:
    git = record["git"] if isinstance(record["git"], dict) else {}
    lines = [
        f"# Wrap-Up Report - {record['focus']}",
        "",
        f"- Created: {record['created_at']}",
        f"- Surface: {record['surface']}",
        f"- Status: {record['status']}",
        f"- Workspace: {record['workspace']}",
        "",
        "## Summary",
        record["summary"] or "-",
        "",
        "## Verification",
        bullets(record["verification"]),
        "",
        "## Git",
        f"- Branch: {git.get('branch') or '-'}",
        f"- Commit: {git.get('commit') or '-'}",
        f"- Push: {git.get('push') or '-'}",
        "",
        "## Scheduler Safety",
        bullets(record["scheduler_safety"]),
        "",
        "## Open Loops",
        bullets(record["open_loops"]),
        "",
        "## Improvement Candidates",
        bullets(record["improvement_candidates"]),
        "",
        "## Resume Prompt",
        record["resume_prompt"] or "-",
        "",
    ]
    return "\n".join(lines)


def bullets(value: object) -> str:
    items = value if isinstance(value, list) else []
    if not items:
        return "-"
    return "\n".join(f"- {item}" for item in items)


def write_record(record: dict[str, object]) -> None:
    paths = record["paths"] if isinstance(record["paths"], dict) else {}
    directory = Path(str(paths["directory"]))
    markdown_path = Path(str(paths["markdown"]))
    json_path = Path(str(paths["json"]))
    directory.mkdir(parents=True, exist_ok=True)
    markdown_path.write_text(markdown(record), encoding="utf-8")
    json_path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(str(markdown_path))
    print(str(json_path))


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default=".")
    parser.add_argument("--surface", required=True)
    parser.add_argument("--status", choices=["Complete", "Continues"], required=True)
    parser.add_argument("--focus", required=True)
    parser.add_argument("--summary", default="")
    parser.add_argument("--verification", action="append")
    parser.add_argument("--scheduler-safety", action="append")
    parser.add_argument("--open-loop", action="append")
    parser.add_argument("--improvement", action="append")
    parser.add_argument("--resume-prompt", default="")
    parser.add_argument("--branch")
    parser.add_argument("--commit")
    parser.add_argument("--push")
    parser.add_argument("--slug")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args(argv)

    record = build_record(args)
    if args.write:
        write_record(record)
    else:
        print(json.dumps(record, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

