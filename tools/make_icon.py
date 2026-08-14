from __future__ import annotations

import base64
import io
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "branding" / "impuls_icon_source.b64"
PNG_OUT = ROOT / "assets" / "branding" / "impuls_icon.png"
DEFAULT_ICO = ROOT / "installer" / "impuls.ico"
SIZES = [16, 32, 48, 64, 128, 256]


def load_source() -> Image.Image:
    encoded = "".join(SOURCE.read_text(encoding="utf-8").split())
    encoded += "=" * (-len(encoded) % 4)
    raw = base64.b64decode(encoded, validate=True)
    if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError("Selected ImPuls branding source is not a PNG")
    probe = Image.open(io.BytesIO(raw))
    probe.verify()
    image = Image.open(io.BytesIO(raw)).convert("RGBA")
    side = min(image.width, image.height)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def main() -> None:
    image = load_source()
    PNG_OUT.parent.mkdir(parents=True, exist_ok=True)
    image.resize((512, 512), Image.Resampling.LANCZOS).save(PNG_OUT, format="PNG", optimize=True)

    out = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_ICO
    if not out.is_absolute():
        out = ROOT / out
    out.parent.mkdir(parents=True, exist_ok=True)
    image.resize((256, 256), Image.Resampling.LANCZOS).save(
        out,
        format="ICO",
        sizes=[(s, s) for s in SIZES],
    )
    print(f"Validated selected ImPuls artwork: {image.width}x{image.height}")
    print(f"Wrote branding PNG: {PNG_OUT}")
    print(f"Wrote Windows ICO: {out} ({', '.join(map(str, SIZES))})")


if __name__ == "__main__":
    main()
