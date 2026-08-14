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
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def _decode_first_valid_png(encoded: str) -> bytes:
    clean = "".join(encoded.split())
    if not clean.startswith("iVBOR"):
        start = clean.find("iVBOR")
        if start < 0:
            raise RuntimeError("No PNG base64 signature in selected ImPuls artwork")
        clean = clean[start:]

    # Historical branding imports accidentally concatenated more than one
    # base64 payload. Test every padding boundary and return the first complete
    # PNG rather than letting stale bytes break all game builds.
    boundaries: list[int] = []
    i = 0
    while i < len(clean):
        if clean[i] == "=":
            j = i
            while j + 1 < len(clean) and clean[j + 1] == "=":
                j += 1
            boundaries.append(j + 1)
            i = j + 1
        else:
            i += 1
    boundaries.append(len(clean))

    for end in boundaries:
        candidate = clean[:end]
        candidate += "=" * (-len(candidate) % 4)
        try:
            raw = base64.b64decode(candidate, validate=False)
        except Exception:
            continue
        if not raw.startswith(PNG_MAGIC):
            continue
        try:
            probe = Image.open(io.BytesIO(raw))
            probe.verify()
            return raw
        except Exception:
            continue
    raise RuntimeError("Selected ImPuls artwork does not contain a complete PNG")


def load_source() -> Image.Image:
    raw = _decode_first_valid_png(SOURCE.read_text(encoding="utf-8"))
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
