#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION_FILE = ROOT / "VERSION"
PROJECT_FILE = ROOT / "project.godot"
BOOTSTRAP_FILE = ROOT / "scripts" / "bootstrap.gd"
INSTALLER_FILE = ROOT / "installer" / "ImPuls.iss"


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

        numeric_match = re.match(r"^([0-9]+(?:\.[0-9]+){1,3})(?:[-+].*)?$", canonical)
        if numeric_match is None:
            raise RuntimeError(f"VERSION has unsupported format: {canonical}")
        numeric_version = numeric_match.group(1)

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

        installer_text = read_text(INSTALLER_FILE)
        installer_fallback = require_match(
            r'^\s*#define MyAppVersion "([^"]+)"\s*$',
            installer_text,
            "installer/ImPuls.iss MyAppVersion fallback",
        )
        if "VersionInfoVersion={#MyAppVersion}" not in installer_text:
            raise RuntimeError("installer VersionInfoVersion is not derived from MyAppVersion")
        if "VersionInfoProductVersion={#MyAppVersion}" not in installer_text:
            raise RuntimeError("installer VersionInfoProductVersion is not derived from MyAppVersion")
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

    if installer_fallback != numeric_version:
        print("VERSION_SYNC_FAIL: installer fallback differs", file=sys.stderr)
        print(f"  VERSION numeric: {numeric_version}", file=sys.stderr)
        print(f"  installer/ImPuls.iss: {installer_fallback}", file=sys.stderr)
        return 4

    print(f"VERSION_SYNC_PASS: {canonical} (installer {numeric_version})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
