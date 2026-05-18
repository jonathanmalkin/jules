#!/usr/bin/env python3
"""Read-only wrap-up preflight inventory.

The script avoids prompt bodies and secret values. It reports metadata needed to
avoid stepping on running schedulers and to stage only intentional git changes.
"""

from __future__ import annotations

import argparse
import datetime as dt
import glob
import json
import os
import plistlib
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python < 3.11 fallback.
    tomllib = None  # type: ignore[assignment]


HOME = Path.home()


def run(cmd: list[str], timeout: int = 8) -> dict[str, Any]:
    try:
        proc = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except Exception as exc:  # noqa: BLE001 - inventory should keep going.
        return {"ok": False, "cmd": cmd, "error": str(exc)}
    return {
        "ok": proc.returncode == 0,
        "cmd": cmd,
        "returncode": proc.returncode,
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
    }


def git_info(workspace: Path) -> dict[str, Any]:
    root = run(["git", "-C", str(workspace), "rev-parse", "--show-toplevel"])
    if not root["ok"]:
        return {"is_repo": False, "error": root.get("stderr") or root.get("error")}

    repo = Path(root["stdout"])
    status = run(["git", "-C", str(repo), "status", "--short"])
    branch = run(["git", "-C", str(repo), "branch", "--show-current"])
    upstream = run(
        ["git", "-C", str(repo), "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]
    )
    remote = run(["git", "-C", str(repo), "remote", "get-url", "origin"])

    entries = [line for line in status.get("stdout", "").splitlines() if line]
    counts = {"modified": 0, "added": 0, "deleted": 0, "renamed": 0, "untracked": 0}
    files: list[dict[str, str]] = []
    for line in entries:
        code = line[:2]
        path = line[3:] if len(line) > 3 else ""
        if code == "??":
            counts["untracked"] += 1
        if "M" in code:
            counts["modified"] += 1
        if "A" in code:
            counts["added"] += 1
        if "D" in code:
            counts["deleted"] += 1
        if "R" in code:
            counts["renamed"] += 1
        files.append({"status": code, "path": path})

    return {
        "is_repo": True,
        "root": str(repo),
        "branch": branch.get("stdout") if branch["ok"] else None,
        "upstream": upstream.get("stdout") if upstream["ok"] else None,
        "origin": sanitize_remote(remote.get("stdout", "")) if remote["ok"] else None,
        "dirty": bool(entries),
        "changed_count": len(entries),
        "counts": counts,
        "files": files,
    }


def sanitize_remote(remote: str) -> str:
    if "://" not in remote:
        return remote
    prefix, rest = remote.split("://", 1)
    if "@" in rest:
        rest = rest.split("@", 1)[1]
    return f"{prefix}://{rest}"


def crontab_info() -> dict[str, Any]:
    result = run(["crontab", "-l"])
    if result["ok"]:
        lines = [
            line
            for line in result["stdout"].splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        return {"available": True, "entry_count": len(lines), "entries": lines}

    message = result.get("stderr") or result.get("stdout") or result.get("error") or ""
    return {
        "available": False,
        "entry_count": 0,
        "reason": message,
        "no_crontab": "no crontab" in message.lower(),
    }


def launchd_info() -> dict[str, Any]:
    agents: list[dict[str, Any]] = []
    for path in sorted((HOME / "Library/LaunchAgents").glob("*.plist")):
        try:
            with path.open("rb") as handle:
                data = plistlib.load(handle)
        except Exception as exc:  # noqa: BLE001
            agents.append({"path": str(path), "parse_error": str(exc)})
            continue

        label = data.get("Label")
        state = launchctl_state(label) if label else {}
        agents.append(
            {
                "label": label,
                "path": str(path),
                "program": data.get("Program") or first_program(data.get("ProgramArguments")),
                "working_directory": data.get("WorkingDirectory"),
                "run_at_load": bool(data.get("RunAtLoad", False)),
                "keep_alive": bool(data.get("KeepAlive", False)),
                "start_interval": data.get("StartInterval"),
                "start_calendar_interval": data.get("StartCalendarInterval"),
                "stdout": data.get("StandardOutPath"),
                "stderr": data.get("StandardErrorPath"),
                "state": state,
            }
        )
    return {
        "count": len(agents),
        "running_count": sum(1 for item in agents if item.get("state", {}).get("state") == "running"),
        "agents": agents,
    }


def first_program(args: Any) -> str | None:
    if isinstance(args, list) and args:
        return str(args[0])
    return None


def launchctl_state(label: str) -> dict[str, Any]:
    result = run(["launchctl", "print", f"gui/{os.getuid()}/{label}"], timeout=5)
    if not result["ok"]:
        return {"available": False, "error": result.get("stderr") or result.get("error")}

    state: dict[str, Any] = {"available": True}
    for raw_line in result["stdout"].splitlines():
        line = raw_line.strip()
        if line.startswith("state =") and "state" not in state:
            state["state"] = line.split("=", 1)[1].strip()
        elif line.startswith("pid =") and "pid" not in state:
            state["pid"] = line.split("=", 1)[1].strip()
        elif line.startswith("runs =") and "runs" not in state:
            state["runs"] = line.split("=", 1)[1].strip()
        elif line.startswith("last exit code =") and "last_exit_code" not in state:
            state["last_exit_code"] = line.split("=", 1)[1].strip()
    return state


def hermes_cron_info(due_window_minutes: int) -> dict[str, Any]:
    profiles: list[dict[str, Any]] = []
    due_soon: list[dict[str, Any]] = []
    enabled_count = 0
    now = dt.datetime.now(dt.timezone.utc)
    window = dt.timedelta(minutes=due_window_minutes)

    for path_text in sorted(glob.glob(str(HOME / ".hermes/profiles/*/cron/jobs.json"))):
        path = Path(path_text)
        profile = path.parts[-3]
        try:
            data = json.loads(path.read_text())
        except Exception as exc:  # noqa: BLE001
            profiles.append({"profile": profile, "path": str(path), "parse_error": str(exc), "jobs": []})
            continue

        raw_jobs = data if isinstance(data, list) else data.get("jobs", [])
        jobs: list[dict[str, Any]] = []
        for job in raw_jobs:
            item = {
                "id": job.get("id"),
                "name": job.get("name"),
                "enabled": bool(job.get("enabled", False)),
                "schedule": job.get("schedule"),
                "next_run_at": job.get("next_run_at"),
                "last_status": job.get("last_status"),
                "last_run_at": job.get("last_run_at"),
                "workdir": job.get("workdir"),
                "model": job.get("model"),
                "provider": job.get("provider"),
                "enabled_toolsets": job.get("enabled_toolsets"),
            }
            jobs.append(item)
            if item["enabled"]:
                enabled_count += 1
                next_run = parse_datetime(item.get("next_run_at"))
                if next_run and dt.timedelta(0) <= next_run.astimezone(dt.timezone.utc) - now <= window:
                    due_soon.append({"profile": profile, "id": item["id"], "name": item["name"], "next_run_at": item["next_run_at"]})
        profiles.append({"profile": profile, "path": str(path), "jobs": jobs})

    return {"profile_count": len(profiles), "enabled_count": enabled_count, "due_soon": due_soon, "profiles": profiles}


def parse_datetime(value: Any) -> dt.datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def codex_automation_info() -> dict[str, Any]:
    automations: list[dict[str, Any]] = []
    for path_text in sorted(glob.glob(str(HOME / ".codex/automations/*/automation.toml"))):
        path = Path(path_text)
        if tomllib is None:
            automations.append({"id": path.parent.name, "path": str(path), "parse_error": "tomllib unavailable"})
            continue
        try:
            with path.open("rb") as handle:
                data = tomllib.load(handle)
        except Exception as exc:  # noqa: BLE001
            automations.append({"id": path.parent.name, "path": str(path), "parse_error": str(exc)})
            continue
        automations.append(
            {
                "id": path.parent.name,
                "path": str(path),
                "kind": data.get("kind"),
                "name": data.get("name"),
                "status": data.get("status"),
                "rrule": data.get("rrule"),
                "cwds": data.get("cwds"),
                "model": data.get("model"),
                "destination": data.get("destination"),
            }
        )
    return {
        "count": len(automations),
        "active_count": sum(1 for item in automations if item.get("status") == "ACTIVE"),
        "automations": automations,
    }


def build_report(args: argparse.Namespace) -> dict[str, Any]:
    workspace = Path(args.workspace).expanduser().resolve()
    return {
        "generated_at": dt.datetime.now().astimezone().isoformat(),
        "workspace": str(workspace),
        "due_window_minutes": args.due_window_minutes,
        "git": git_info(workspace),
        "crontab": crontab_info(),
        "launchd": launchd_info(),
        "hermes_cron": hermes_cron_info(args.due_window_minutes),
        "codex_automations": codex_automation_info(),
    }


def print_text(report: dict[str, Any]) -> None:
    git = report["git"]
    launchd = report["launchd"]
    hermes = report["hermes_cron"]
    codex = report["codex_automations"]
    cron = report["crontab"]

    print("Wrap-up preflight")
    print(f"- generated_at: {report['generated_at']}")
    print(f"- workspace: {report['workspace']}")
    if git.get("is_repo"):
        print(
            f"- git: branch={git.get('branch') or '(detached)'} "
            f"dirty={git.get('dirty')} changed={git.get('changed_count')} upstream={git.get('upstream')}"
        )
    else:
        print(f"- git: not a repo ({git.get('error')})")

    cron_status = "available" if cron.get("available") else cron.get("reason", "unavailable")
    print(f"- crontab: {cron_status}")
    print(f"- launchd: {launchd['count']} user agents, {launchd['running_count']} running")
    print(f"- hermes_cron: {hermes['enabled_count']} enabled jobs across {hermes['profile_count']} profiles")
    print(f"- codex_automations: {codex['count']} definitions, {codex['active_count']} active")

    if hermes["due_soon"]:
        print("Scheduler due soon:")
        for item in hermes["due_soon"]:
            print(f"- Hermes {item['profile']}: {item['name']} at {item['next_run_at']}")
    else:
        print("Scheduler due soon: none inside window")

    if git.get("dirty"):
        print("Changed files:")
        for item in git.get("files", []):
            print(f"- {item['status']} {item['path']}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default=os.getcwd())
    parser.add_argument("--due-window-minutes", type=int, default=90)
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON")
    args = parser.parse_args(argv)

    report = build_report(args)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

