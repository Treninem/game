from __future__ import annotations

import math
import struct
import sys
import zlib
from pathlib import Path

SIZE = 256
RGBA = tuple[int, int, int, int]
pixels = bytearray(SIZE * SIZE * 4)


def put(x: int, y: int, c: RGBA) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        i = (y * SIZE + x) * 4
        pixels[i:i + 4] = bytes(c)


def get(x: int, y: int) -> RGBA:
    i = (y * SIZE + x) * 4
    return tuple(pixels[i:i + 4])  # type: ignore[return-value]


def blend(x: int, y: int, c: RGBA) -> None:
    if not (0 <= x < SIZE and 0 <= y < SIZE):
        return
    dst = get(x, y)
    a = c[3] / 255.0
    out = tuple(round(c[k] * a + dst[k] * (1.0 - a)) for k in range(3)) + (max(dst[3], c[3]),)
    put(x, y, out)  # type: ignore[arg-type]


def disc(cx: int, cy: int, r: int, c: RGBA, soft: bool = False) -> None:
    rr = r * r
    for y in range(max(0, cy - r), min(SIZE, cy + r + 1)):
        for x in range(max(0, cx - r), min(SIZE, cx + r + 1)):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if d <= rr:
                if soft:
                    fade = max(0.0, 1.0 - math.sqrt(d) / max(r, 1))
                    blend(x, y, (c[0], c[1], c[2], round(c[3] * fade)))
                else:
                    put(x, y, c)


def line(x0: int, y0: int, x1: int, y1: int, width: int, c: RGBA, soft_glow: int = 0) -> None:
    dx, dy = x1 - x0, y1 - y0
    steps = max(abs(dx), abs(dy), 1)
    if soft_glow:
        for s in range(steps + 1):
            x = round(x0 + dx * s / steps)
            y = round(y0 + dy * s / steps)
            disc(x, y, width // 2 + soft_glow, (c[0], c[1], c[2], 65), soft=True)
    for s in range(steps + 1):
        x = round(x0 + dx * s / steps)
        y = round(y0 + dy * s / steps)
        disc(x, y, max(1, width // 2), c)


def polygon(points: list[tuple[int, int]], c: RGBA) -> None:
    min_x = max(0, min(p[0] for p in points))
    max_x = min(SIZE - 1, max(p[0] for p in points))
    min_y = max(0, min(p[1] for p in points))
    max_y = min(SIZE - 1, max(p[1] for p in points))
    n = len(points)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            inside = False
            j = n - 1
            for i in range(n):
                xi, yi = points[i]
                xj, yj = points[j]
                if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) or 1) + xi):
                    inside = not inside
                j = i
            if inside:
                put(x, y, c)


def rounded_rect(x0: int, y0: int, x1: int, y1: int, radius: int, c: RGBA) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            qx = max(x0 + radius - x, 0, x - (x1 - radius))
            qy = max(y0 + radius - y, 0, y - (y1 - radius))
            if qx * qx + qy * qy <= radius * radius:
                put(x, y, c)


def frame() -> None:
    rounded_rect(4, 4, 251, 251, 45, (3, 7, 13, 255))
    rounded_rect(9, 9, 246, 246, 40, (21, 31, 45, 255))
    rounded_rect(13, 13, 242, 242, 36, (5, 17, 31, 255))
    for y in range(15, 241):
        for x in range(15, 241):
            # blue-black sky with a warm sunset bias on the right edge
            t = y / 255.0
            warm = max(0.0, (x - 175) / 85.0) * max(0.0, (y - 90) / 160.0)
            r = round(7 + 12 * t + 52 * warm)
            g = round(18 + 29 * t + 12 * warm)
            b = round(36 + 54 * (1.0 - t) - 20 * warm)
            put(x, y, (min(r, 255), min(g, 255), min(b, 255), 255))

    # cold celestial glow
    disc(191, 55, 42, (55, 145, 255, 60), soft=True)
    disc(191, 55, 23, (102, 205, 255, 80), soft=True)


def scenery() -> None:
    # futuristic tower and beam
    line(191, 19, 191, 92, 4, (76, 218, 255, 230), soft_glow=5)
    polygon([(180, 96), (184, 63), (188, 80), (191, 47), (195, 80), (199, 63), (203, 96)], (17, 37, 64, 255))
    line(191, 49, 191, 95, 2, (115, 236, 255, 255), soft_glow=3)

    # dragon silhouette
    polygon([(36, 56), (65, 35), (95, 31), (120, 40), (141, 54), (127, 58), (113, 55), (101, 70), (83, 74), (91, 60), (78, 55), (61, 66), (47, 64), (55, 54)], (2, 7, 14, 255))
    polygon([(78, 48), (92, 22), (96, 50)], (4, 13, 25, 255))
    polygon([(61, 49), (44, 29), (48, 56)], (4, 13, 25, 255))
    disc(120, 51, 2, (67, 222, 255, 255))

    # mountain layers
    polygon([(8, 154), (43, 103), (59, 131), (82, 82), (104, 129), (126, 104), (150, 141), (175, 105), (202, 134), (226, 95), (248, 144), (248, 188), (8, 188)], (9, 24, 40, 255))
    polygon([(8, 169), (44, 135), (65, 150), (88, 117), (109, 156), (132, 129), (154, 162), (181, 128), (209, 157), (233, 130), (248, 147), (248, 196), (8, 196)], (17, 48, 66, 255))
    polygon([(8, 184), (51, 164), (92, 177), (129, 157), (165, 176), (201, 159), (248, 174), (248, 211), (8, 211)], (24, 73, 62, 255))
    line(178, 151, 165, 207, 4, (65, 180, 232, 210), soft_glow=2)

    # warm settlement lights
    for x, y in [(201, 159), (214, 166), (225, 158), (235, 174), (188, 177), (221, 184)]:
        disc(x, y, 2, (255, 146, 39, 255), soft=True)


def characters() -> None:
    # hero silhouette with sword
    disc(126, 84, 11, (4, 8, 13, 255))
    polygon([(114, 93), (137, 93), (143, 127), (136, 155), (116, 155), (109, 126)], (3, 7, 12, 255))
    polygon([(116, 145), (124, 145), (121, 182), (109, 182)], (3, 7, 12, 255))
    polygon([(130, 145), (138, 145), (143, 182), (131, 182)], (3, 7, 12, 255))
    line(137, 92, 161, 65, 4, (187, 209, 226, 255), soft_glow=1)
    line(157, 61, 164, 68, 3, (255, 136, 35, 255), soft_glow=1)

    # wolf companion
    polygon([(62, 143), (54, 130), (51, 145), (45, 152), (47, 166), (60, 170), (69, 160), (77, 170), (88, 170), (88, 156), (81, 146), (70, 141)], (4, 8, 13, 255))
    polygon([(53, 145), (48, 132), (45, 148)], (6, 12, 20, 255))
    disc(64, 148, 1, (82, 221, 255, 255))


def emblem() -> None:
    # rock pedestal
    polygon([(40, 183), (72, 168), (103, 177), (128, 166), (158, 178), (188, 169), (226, 185), (246, 250), (15, 250)], (5, 9, 15, 255))

    # large metallic I/shield
    polygon([(99, 143), (157, 143), (170, 156), (151, 168), (151, 211), (169, 222), (156, 242), (100, 242), (87, 222), (105, 211), (105, 168), (86, 156)], (9, 18, 31, 255))
    # cyan glow around the plate
    for w, a in [(15, 32), (9, 55), (5, 95)]:
        line(101, 147, 155, 147, w, (42, 190, 255, a), soft_glow=2)
    polygon([(108, 149), (148, 149), (155, 157), (142, 164), (142, 216), (154, 223), (147, 235), (109, 235), (102, 223), (114, 216), (114, 164), (101, 157)], (109, 137, 171, 255))
    polygon([(115, 153), (141, 153), (146, 158), (136, 163), (136, 219), (145, 224), (140, 230), (116, 230), (111, 224), (120, 219), (120, 163), (110, 158)], (13, 25, 42, 255))

    # signature electric impulse
    pts = [(88, 196), (108, 196), (115, 184), (122, 211), (129, 175), (137, 204), (144, 190), (166, 190)]
    for a, b in zip(pts, pts[1:]):
        line(a[0], a[1], b[0], b[1], 4, (90, 237, 255, 255), soft_glow=5)

    # corner energy and sparks
    line(17, 57, 17, 37, 2, (79, 221, 255, 220), soft_glow=2)
    line(17, 37, 41, 17, 2, (79, 221, 255, 220), soft_glow=2)
    line(215, 240, 240, 240, 2, (255, 127, 35, 220), soft_glow=2)
    for x, y, c in [(30, 119, (77, 220, 255, 230)), (222, 117, (255, 142, 42, 230)), (31, 197, (77, 220, 255, 220)), (209, 197, (255, 142, 42, 220))]:
        disc(x, y, 3, c, soft=True)


def png_chunk(name: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data) & 0xFFFFFFFF)


def make_png(size: int) -> bytes:
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        sy = min(SIZE - 1, round((y + 0.5) * SIZE / size - 0.5))
        for x in range(size):
            sx = min(SIZE - 1, round((x + 0.5) * SIZE / size - 0.5))
            raw.extend(get(sx, sy))
    data = b"\x89PNG\r\n\x1a\n"
    data += png_chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    data += png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += png_chunk(b"IEND", b"")
    return data


frame()
scenery()
characters()
emblem()

sizes = [16, 32, 48, 64, 128, 256]
images = [(s, make_png(s)) for s in sizes]
header_size = 6 + 16 * len(images)
offset = header_size
entries = bytearray()
payload = bytearray()
for size, png in images:
    dim = 0 if size == 256 else size
    entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(png), offset)
    payload += png
    offset += len(png)

ico = struct.pack("<HHH", 0, 1, len(images)) + entries + payload
out = Path(sys.argv[1] if len(sys.argv) > 1 else "installer/impuls.ico")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(ico)
print(f"Wrote premium ImPuls icon {out} ({len(ico)} bytes, {len(images)} sizes)")
