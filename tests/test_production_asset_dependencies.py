"""Fail before import when a production glTF has missing external data."""

import json
from pathlib import Path
from urllib.parse import unquote


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    errors = []
    models = sorted((root / "assets" / "production").rglob("*.gltf"))
    if not models:
        errors.append("No production glTF models found")
    for model in models:
        try:
            data = json.loads(model.read_text(encoding="utf-8-sig"))
            for entry in data.get("buffers", []) + data.get("images", []):
                uri = entry.get("uri", "")
                if not uri or uri.startswith("data:"):
                    continue
                dependency = model.parent / unquote(uri)
                if not dependency.is_file() or dependency.stat().st_size == 0:
                    errors.append(f"{model.relative_to(root)}: missing dependency {uri}")
        except (OSError, ValueError, TypeError, AttributeError) as exc:
            errors.append(f"{model.relative_to(root)}: {exc}")
    for error in errors:
        print(error)
    if errors:
        return 1
    print(f"Production asset dependencies passed: {len(models)} glTF models")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
