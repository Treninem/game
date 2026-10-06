#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION_FILE = ROOT / "VERSION"
PROJECT_FILE = ROOT / "project.godot"
BOOTSTRAP_FILE = ROOT / "scripts" / "bootstrap.gd"


def read_text(path: Path) -> str:
    if not path.is_file():
        raise RuntimeError(f"required version source is missing: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require_match(pattern: str, text: str, label: str) -> str:
    match = re.search(pattern, text, flags=re.MULTILINE)
    if match is None:
        raise RuntimeError(f"could not read {label}")
    return match.group(1).strip()


def main() -> int:
    try:
        canonical = read_text(VERSION_FILE).strip()
        if not canonical:
            raise RuntimeError("VERSION is empty")

        project_version = require_match(
            r'^config/version="([^"]+)"\s*$',
            read_text(PROJECT_FILE),
            "project.godot application version",
        )
        bootstrap_version = require_match(
            r'^const VERSION\s*:=\s*"([^"]+)"\s*$',
            read_text(BOOTSTRAP_FILE),
            "scripts/bootstrap.gd VERSION",
        )
    except RuntimeError as exc:
        print(f"VERSION_SYNC_FAIL: {exc}", file=sys.stderr)
        return 2

    values = {
        "VERSION": canonical,
        "project.godot": project_version,
        "scripts/bootstrap.gd": bootstrap_version,
    }
    mismatched = {name: value for name, value in values.items() if value != canonical}
    if mismatched:
        print("VERSION_SYNC_FAIL: version metadata differs", file=sys.stderr)
        for name, value in values.items():
            print(f"  {name}: {value}", file=sys.stderr)
        return 3

    print(f"VERSION_SYNC_PASS: {canonical}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
