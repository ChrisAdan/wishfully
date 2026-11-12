#!/usr/bin/env python3
"""Draws the placeholder app icon: a white heart on a warm rose gradient.

Writes the 1024 by 1024 RGB PNG the App Store requires (no transparency), with the standard
library only (zlib compresses the rows, struct packs the PNG chunks). Run from the repository
root:

    python3 Tools/app-icon.py
"""

import pathlib
import struct
import zlib

OUT = pathlib.Path("App/Wishfully/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

# The App Store icon size, in pixels (Apple Human Interface Guidelines).
SIZE = 1024
# Samples per pixel edge for anti-aliasing the heart's outline.
SUPERSAMPLE = 3
# Gradient from the top-left corner to the bottom-right corner, sRGB.
TOP = (240, 128, 128)
BOTTOM = (178, 52, 92)
HEART = (255, 250, 247)
# The heart's half-width as a share of the icon, and its centre.
HEART_SCALE = 0.30
CENTRE = (0.5, 0.53)


def in_heart(x, y):
    """The classic heart curve (x^2 + y^2 - 1)^3 - x^2 y^3 <= 0, in unit coordinates."""
    return (x * x + y * y - 1) ** 3 - x * x * y ** 3 <= 0


def pixel(px, py):
    t = (px + py) / (2 * SIZE)
    colour = [round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)]
    hits = 0
    for sx in range(SUPERSAMPLE):
        for sy in range(SUPERSAMPLE):
            u = (px + (sx + 0.5) / SUPERSAMPLE) / SIZE
            v = (py + (sy + 0.5) / SUPERSAMPLE) / SIZE
            hx = (u - CENTRE[0]) / HEART_SCALE * 1.2
            hy = -(v - CENTRE[1]) / HEART_SCALE * 1.2
            if in_heart(hx, hy):
                hits += 1
    total = SUPERSAMPLE * SUPERSAMPLE
    return bytes(round((c * (total - hits) + h * hits) / total) for c, h in zip(colour, HEART))


def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def main():
    rows = b"".join(b"\x00" + b"".join(pixel(x, y) for x in range(SIZE)) for y in range(SIZE))
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(rows, 9))
    png += chunk(b"IEND", b"")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(png)
    print(f"Wrote {OUT} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
