#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import random
import shutil
import tempfile
import zipfile
from pathlib import Path

from build_delta import write_delta


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="impuls-delta-smoke-") as td:
        root = Path(td)
        old = root / "old"
        new = root / "new"
        stage = root / "stage"
        out = root / "out"
        extract = root / "extract"
        for path in (old, new, out, extract):
            path.mkdir(parents=True, exist_ok=True)

        rng = random.Random(1337)
        base = bytearray(rng.randbytes(5 * 1024 * 1024))
        (old / "ImPuls.pck").write_bytes(base)
        newer = base[:]
        newer[900_000:900_000] = b"NEW-ASSET-" * 8192
        newer[2_700_000:2_760_000] = b"Z" * 60_000
        newer.extend(b"APPENDED-CONTENT-" * 4096)
        (new / "ImPuls.pck").write_bytes(newer)

        (old / "ImPuls.exe").write_bytes(b"EXE-v1" * 10000)
        (new / "ImPuls.exe").write_bytes(b"EXE-v2" * 10000)
        (old / "obsolete.bin").write_bytes(b"remove-me")
        (new / "new-file.bin").write_bytes(b"new-file-content" * 4096)

        delta_zip = out / "delta.zip"
        manifest_path = out / "manifest.json"
        write_delta(old, new, "build-100", "build-101", delta_zip, manifest_path)

        shutil.copytree(old, stage, dirs_exist_ok=True)
        with zipfile.ZipFile(delta_zip) as archive:
            archive.extractall(extract)

        meta = json.loads((extract / "delta.json").read_text(encoding="utf-8"))
        payload = (extract / "payload.bin").read_bytes()

        if meta.get("format") != 2 or meta.get("algorithm") != "fastcdc-copy-literal":
            raise RuntimeError("unexpected delta metadata format")

        for rel, patch in meta["changed"].items():
            target = stage / rel
            source = target.read_bytes() if target.exists() else b""
            rebuilt = bytearray()
            for op in patch["ops"]:
                offset = int(op["offset"])
                length = int(op["length"])
                if op["op"] == "copy":
                    rebuilt += source[offset: offset + length]
                elif op["op"] == "literal":
                    rebuilt += payload[offset: offset + length]
                else:
                    raise RuntimeError(f"unknown delta op: {op['op']}")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(rebuilt)
            if len(rebuilt) != int(patch["size"]) or _sha256(rebuilt) != patch["sha256"]:
                raise RuntimeError(f"rebuilt file checksum mismatch: {rel}")

        for rel in meta["deleted"]:
            target = stage / rel
            if target.exists():
                target.unlink()

        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        expected_files = set(manifest["files"].keys())
        actual_files = {
            path.relative_to(stage).as_posix()
            for path in stage.rglob("*")
            if path.is_file()
        }
        if actual_files != expected_files:
            raise RuntimeError(
                f"reconstructed file set differs: actual={sorted(actual_files)} expected={sorted(expected_files)}"
            )

        for rel, info in manifest["files"].items():
            rebuilt = (stage / rel).read_bytes()
            expected = (new / rel).read_bytes()
            if rebuilt != expected:
                raise RuntimeError(f"reconstructed bytes differ: {rel}")
            if len(rebuilt) != int(info["size"]) or _sha256(rebuilt) != info["sha256"]:
                raise RuntimeError(f"manifest mismatch: {rel}")

        literal_payload = int(meta.get("payload_size", len(payload)))
        full_size = sum(int(info["size"]) for info in manifest["files"].values())
        if literal_payload >= full_size:
            raise RuntimeError("delta did not reuse any meaningful installed content")

        print(
            "DELTA_ROUNDTRIP_PASS "
            f"files={len(expected_files)} payload={literal_payload} full={full_size}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
