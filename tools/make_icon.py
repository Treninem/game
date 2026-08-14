from __future__ import annotations

import base64
import io
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
CHUNKS_DIR = ROOT / "assets" / "branding" / "source_chunks"
FALLBACK_SOURCE = ROOT / "assets" / "branding" / "impuls_icon_source.b64"
PNG_OUT = ROOT / "assets" / "branding" / "impuls_icon.png"
DEFAULT_ICO = ROOT / "installer" / "impuls.ico"
SIZES = [16, 32, 48, 64, 128, 256]
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def _read_encoded_source() -> str:
    chunks = sorted(CHUNKS_DIR.glob("*.b64part"))
    if chunks:
        return "".join(path.read_text(encoding="utf-8").strip() for path in chunks)
    if FALLBACK_SOURCE.exists():
        return FALLBACK_SOURCE.read_text(encoding="utf-8").strip()
    return ""


def _decode_source() -> Image.Image | None:
    encoded = "".join(_read_encoded_source().split())
    if not encoded:
        return None
    encoded += "=" * (-len(encoded) % 4)
    try:
        raw = base64.b64decode(encoded, validate=False)
        if not raw.startswith(PNG_MAGIC):
            return None
        probe = Image.open(io.BytesIO(raw))
        probe.verify()
        image = Image.open(io.BytesIO(raw)).convert("RGBA")
        side = min(image.width, image.height)
        left = (image.width - side) // 2
        top = (image.height - side) // 2
        return image.crop((left, top, left + side, top + side))
    except Exception as exc:
        print(f"Branding source is damaged ({exc}); using built-in ImPuls fallback artwork.")
        return None


def _fallback_artwork() -> Image.Image:
    size = 1024
    image = Image.new("RGBA", (size, size), (5, 10, 20, 255))
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((118, 118, 906, 906), outline=(30, 200, 255, 175), width=54)
    gd.ellipse((178, 178, 846, 846), outline=(75, 105, 255, 100), width=18)
    glow = glow.filter(ImageFilter.GaussianBlur(22))
    image = Image.alpha_composite(image, glow)

    draw = ImageDraw.Draw(image)
    draw.ellipse((120, 120, 904, 904), fill=(8, 22, 42, 255), outline=(63, 218, 255, 255), width=34)
    draw.ellipse((184, 184, 840, 840), fill=(10, 18, 35, 255), outline=(70, 108, 255, 220), width=9)
    # Original geometric ImPuls pulse/lightning mark; no font dependency.
    draw.polygon([(510, 220), (355, 535), (485, 535), (414, 803), (682, 425), (536, 425)], fill=(215, 248, 255, 255))
    draw.line([(285, 662), (375, 662), (420, 615), (468, 708), (525, 575), (570, 662), (742, 662)], fill=(50, 205, 255, 255), width=22, joint="curve")
    return image


def load_source() -> Image.Image:
    source = _decode_source()
    return source if source is not None else _fallback_artwork()


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
    print(f"Wrote ImPuls branding PNG: {PNG_OUT}")
    print(f"Wrote Windows ICO: {out} ({', '.join(map(str, SIZES))})")


if __name__ == "__main__":
    main()
