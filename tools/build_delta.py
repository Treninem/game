#!/usr/bin/env python3
"""Build content-aware ImPuls delta packages.

The exported Godot game contains large binary files (notably the .pck). A normal
file-level updater would have to download the whole file whenever one resource
changes. This tool uses deterministic content-defined chunks and reuses matching
byte ranges from the already installed previous build. Only literal chunks that
cannot be reused are stored in the delta ZIP.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import shutil
import tempfile
import zipfile
from pathlib import Path

MIN_CHUNK = 64 * 1024
AVG_CHUNK = 256 * 1024
MAX_CHUNK = 1024 * 1024
MASK_EARLY = (1 << 19) - 1
MASK_LATE = (1 << 17) - 1
MASK64 = (1 << 64) - 1

_rng = random.Random(0x1A2B3C4D)
GEAR = [_rng.getrandbits(64) for _ in range(256)]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def rel_files(root: Path) -> dict[str, Path]:
    result: dict[str, Path] = {}
    if not root.exists():
        return result
    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        rel = path.relative_to(root).as_posix()
        if rel.endswith(".tmp") or rel.startswith("__pycache__/"):
            continue
        result[rel] = path
    return result


def manifest_for(root: Path, build: str) -> dict:
    files = {}
    for rel, path in rel_files(root).items():
        files[rel] = {"sha256": sha256_file(path), "size": path.stat().st_size}
    return {"format": 2, "build": build, "files": files}


def cdc_chunks(data: bytes):
    """Yield stable (start, end) boundaries using a FastCDC-style gear hash."""
    n = len(data)
    start = 0
    while start < n:
        remaining = n - start
        if remaining <= MIN_CHUNK:
            yield start, n
            return
        hard_end = min(n, start + MAX_CHUNK)
        normal = min(hard_end, start + AVG_CHUNK)
        i = start + MIN_CHUNK
        h = 0
        cut = hard_end
        while i < hard_end:
            h = ((h << 1) + GEAR[data[i]]) & MASK64
            mask = MASK_EARLY if i < normal else MASK_LATE
            if (h & mask) == 0:
                cut = i + 1
                break
            i += 1
        yield start, cut
        start = cut


def old_chunk_index(data: bytes) -> dict[tuple[str, int], tuple[int, int]]:
    index: dict[tuple[str, int], tuple[int, int]] = {}
    for start, end in cdc_chunks(data):
        chunk = data[start:end]
        key = (sha256_bytes(chunk), len(chunk))
        index.setdefault(key, (start, len(chunk)))
    return index


def build_file_patch(old_path: Path | None, new_path: Path, payload: bytearray) -> dict:
    new_data = new_path.read_bytes()
    old_data = old_path.read_bytes() if old_path and old_path.exists() else b""
    old_index = old_chunk_index(old_data) if old_data else {}
    ops = []

    for start, end in cdc_chunks(new_data):
        chunk = new_data[start:end]
        key = (sha256_bytes(chunk), len(chunk))
        source = old_index.get(key)
        if source is not None:
            ops.append({"op": "copy", "offset": source[0], "length": source[1]})
        else:
            payload_offset = len(payload)
            payload.extend(chunk)
            ops.append({"op": "literal", "offset": payload_offset, "length": len(chunk)})

    return {
        "size": len(new_data),
        "sha256": sha256_bytes(new_data),
        "ops": ops,
    }


def write_delta(old_dir: Path, new_dir: Path, from_build: str, to_build: str, output: Path, manifest_path: Path) -> None:
    new_manifest = manifest_for(new_dir, to_build)
    manifest_path.write_text(json.dumps(new_manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    old_files = rel_files(old_dir)
    new_files = rel_files(new_dir)
    deleted = sorted(set(old_files) - set(new_files))
    changed: dict[str, dict] = {}
    payload = bytearray()

    for rel, new_path in new_files.items():
        old_path = old_files.get(rel)
        if old_path is not None:
            old_size = old_path.stat().st_size
            if old_size == new_path.stat().st_size and sha256_file(old_path) == new_manifest["files"][rel]["sha256"]:
                continue
        changed[rel] = build_file_patch(old_path, new_path, payload)

    delta = {
        "format": 2,
        "algorithm": "fastcdc-copy-literal",
        "from": from_build,
        "to": to_build,
        "changed": changed,
        "deleted": deleted,
        "payload_size": len(payload),
        "final_manifest_sha256": sha256_file(manifest_path),
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="impuls-delta-") as td:
        td_path = Path(td)
        (td_path / "delta.json").write_text(json.dumps(delta, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        (td_path / "payload.bin").write_bytes(payload)
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
            zf.write(td_path / "delta.json", "delta.json")
            zf.write(td_path / "payload.bin", "payload.bin")

    full_bytes = sum(info["size"] for info in new_manifest["files"].values())
    reused = max(0, full_bytes - len(payload))
    ratio = (len(payload) / full_bytes * 100.0) if full_bytes else 0.0
    print(f"delta {from_build} -> {to_build}: changed_files={len(changed)} deleted={len(deleted)}")
    print(f"literal_payload={len(payload)} reused_bytes={reused} literal_ratio={ratio:.2f}% zip={output.stat().st_size}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--old-dir", type=Path, required=True)
    parser.add_argument("--new-dir", type=Path, required=True)
    parser.add_argument("--from-build", required=True)
    parser.add_argument("--to-build", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()

    if not args.new_dir.is_dir():
        raise SystemExit(f"new build directory missing: {args.new_dir}")
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    write_delta(args.old_dir, args.new_dir, args.from_build, args.to_build, args.output, args.manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
