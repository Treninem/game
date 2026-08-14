from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

SIZE = 256
pixels = bytearray(SIZE * SIZE * 4)


def put(x: int, y: int, rgba: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        i = (y * SIZE + x) * 4
        pixels[i:i + 4] = bytes(rgba)


def disc(cx: int, cy: int, r: int, color: tuple[int, int, int, int]) -> None:
    rr = r * r
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= rr:
                put(x, y, color)


def ring(cx: int, cy: int, outer: int, inner: int, color: tuple[int, int, int, int]) -> None:
    oo, ii = outer * outer, inner * inner
    for y in range(cy - outer, cy + outer + 1):
        for x in range(cx - outer, cx + outer + 1):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if ii <= d <= oo:
                put(x, y, color)


def line(x0: int, y0: int, x1: int, y1: int, width: int, color: tuple[int, int, int, int]) -> None:
    dx, dy = x1 - x0, y1 - y0
    steps = max(abs(dx), abs(dy), 1)
    for s in range(steps + 1):
        x = round(x0 + dx * s / steps)
        y = round(y0 + dy * s / steps)
        disc(x, y, max(1, width // 2), color)


# Original ImPuls mark: dark field, cyan/violet rings, white impulse spine and cyan pulse.
disc(128, 128, 120, (12, 17, 29, 255))
ring(128, 128, 120, 111, (57, 210, 255, 255))
ring(128, 128, 100, 95, (125, 73, 255, 230))
line(128, 48, 128, 208, 15, (242, 248, 255, 255))
for a, b in zip([(58, 140), (101, 140), (120, 82), (138, 176), (156, 119)], [(101, 140), (120, 82), (138, 176), (156, 119), (201, 119)]):
    line(a[0], a[1], b[0], b[1], 12, (75, 224, 255, 255))
for y in range(31, 58):
    half = max(0, (y - 31) // 2)
    for x in range(128 - half, 129 + half):
        put(x, y, (242, 248, 255, 255))


def chunk(name: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data) & 0xFFFFFFFF)

raw = bytearray()
for y in range(SIZE):
    raw.append(0)
    row = pixels[y * SIZE * 4:(y + 1) * SIZE * 4]
    raw.extend(row)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
png += chunk(b"IEND", b"")

ico = struct.pack("<HHH", 0, 1, 1)
ico += struct.pack("<BBBBHHII", 0, 0, 0, 0, 1, 32, len(png), 22)
ico += png

out = Path(sys.argv[1] if len(sys.argv) > 1 else "installer/impuls.ico")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(ico)
print(f"Wrote {out} ({len(ico)} bytes)")
