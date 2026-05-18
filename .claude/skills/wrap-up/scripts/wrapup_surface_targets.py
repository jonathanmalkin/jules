#!/usr/bin/env python3
"""Read-only inventory of wrap-up skill surface adapter targets."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any


HOME = Path.home()
DEFAULT_CANONICAL = HOME / ".agents/skills/workflows/wrap-up"
HERMES_WRAP_UP_PROFILES = {"director", "pam"}


def status_for(path: Path, canonical: Path) -> dict[str, Any]:
    exists = path.exists() or path.is_symlink()
    item: dict[str, Any] = {
        "path": str(path),
        "exists": exists,
        "kind": "missing",
        "target": None,
        "resolves_to_canonical": False,
    }
    if path.is_symlink():
        target = os.readlink(path)
        item["kind"] = "symlink"
        item["target"] = target
        item["resolves_to_canonical"] = path.resolve() == canonical.resolve()
    elif path.exists():
        item["kind"] = "directory" if path.is_dir() else "file"
        item["resolves_to_canonical"] = path.resolve() == canonical.resolve()
    return item


def discover(canonical: Path) -> dict[str, Any]:
    targets: list[dict[str, Any]] = []

    codex = HOME / ".codex/skills"
    if codex.exists():
        item = status_for(codex / "wrap-up", canonical)
        item.update({"surface": "codex", "recommended_adapter": "symlink"})
        targets.append(item)

    claude = HOME / ".claude/skills"
    if claude.exists():
        item = status_for(claude / "wrap-up", canonical)
        item.update({"surface": "claude-code", "recommended_adapter": "symlink"})
        targets.append(item)

    profiles_root = HOME / ".hermes/profiles"
    if profiles_root.exists():
        for profile in sorted(path for path in profiles_root.iterdir() if path.is_dir()):
            workflows = profile / "skills/workflows"
            target = workflows / "wrap-up"
            if profile.name not in HERMES_WRAP_UP_PROFILES:
                item = status_for(target, canonical)
                item.update(
                    {
                        "surface": f"hermes:{profile.name}",
                        "recommended_adapter": "excluded-unless-explicitly-approved",
                        "profile": profile.name,
                    }
                )
                if not item["exists"]:
                    item["kind"] = "excluded"
                targets.append(item)
                continue

            if workflows.exists():
                item = status_for(target, canonical)
                item.update(
                    {
                        "surface": f"hermes:{profile.name}",
                        "recommended_adapter": "symlink",
                        "profile": profile.name,
                    }
                )
                targets.append(item)
            elif (profile / "skills").exists():
                targets.append(
                    {
                        "surface": f"hermes:{profile.name}",
                        "profile": profile.name,
                        "path": str(profile / "skills/workflows/wrap-up"),
                        "exists": False,
                        "kind": "no-workflows-root",
                        "target": None,
                        "resolves_to_canonical": False,
                        "recommended_adapter": "needs-review-before-creating-workflows-root",
                    }
                )

    public_jules = HOME / "Active-Work/Code/personal/jules/.claude/skills/wrap-up"
    if public_jules.parent.exists():
        item = status_for(public_jules, canonical)
        item.update({"surface": "public-jules-repo", "recommended_adapter": "sanitized-copy-not-symlink"})
        targets.append(item)

    return {"canonical": str(canonical), "targets": targets}


def print_text(report: dict[str, Any]) -> None:
    print("Wrap-up surface targets")
    print(f"- canonical: {report['canonical']}")
    for item in report["targets"]:
        print(
            f"- {item['surface']}: {item['kind']} at {item['path']} "
            f"adapter={item['recommended_adapter']} canonical={item['resolves_to_canonical']}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--canonical", default=str(DEFAULT_CANONICAL))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = discover(Path(args.canonical).expanduser())
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
