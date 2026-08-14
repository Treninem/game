from __future__ import annotations

import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MASTER_PNG = ROOT / "assets" / "branding" / "impuls_icon.png"
DEFAULT_ICO = ROOT / "installer" / "impuls.ico"
SIZES = [16, 24, 32, 48, 64, 128, 256]


def load_master() -> Image.Image:
    if not MASTER_PNG.exists():
        raise SystemExit(f"Missing branding master: {MASTER_PNG}")
    image = Image.open(MASTER_PNG).convert("RGBA")
    if image.width < 128 or image.height < 128:
        raise SystemExit("Branding master must be at least 128x128")
    side = min(image.width, image.height)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def main() -> None:
    image = load_master()
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_ICO
    if not out.is_absolute():
        out = ROOT / out
    out.parent.mkdir(parents=True, exist_ok=True)
    image.resize((256, 256), Image.Resampling.LANCZOS).save(
        out,
        format="ICO",
        sizes=[(s, s) for s in SIZES],
    )
    print(f"Branding master: {MASTER_PNG}")
    print(f"Windows icon: {out}")


if __name__ == "__main__":
    main()
