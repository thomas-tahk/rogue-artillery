#!/usr/bin/env python3
"""Programmatic placeholder art for Rogue Artillery.

Generates colored pixel-art sprites at the exact dimensions the scenes already
expect, so nothing in the Godot project needs rewiring:

    assets/sprites/tank.png    64x32   (shooter.tscn Sprite2D)
    assets/sprites/dirt.png    32x32   (terrain.tscn, 2x2 atlas of 16x16 tiles)
    assets/sprites/bullet.png   8x8    (bullets.tscn Sprite2D)

These are deliberately throwaway placeholders authored by code -- NOT final art.
Re-run with:  python3 tools/gen_placeholder_art.py
"""

import os
import math
import random

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "sprites"))


# --- tiny pixel-drawing helpers --------------------------------------------

def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((int(x), int(y)), c)


def rect(img, x0, y0, x1, y1, c):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            px(img, x, y, c)


def hline(img, x0, x1, y, c):
    for x in range(int(x0), int(x1) + 1):
        px(img, x, y, c)


def disc(img, cx, cy, r, c):
    for y in range(int(cy - r), int(cy + r) + 1):
        for x in range(int(cx - r), int(cx + r) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px(img, x, y, c)


# --- seamless value noise (wraps on a torus, so tiles never seam) -----------

def wrapped_noise(size, cells, seed):
    rnd = random.Random(seed)
    grid = [[rnd.random() for _ in range(cells)] for _ in range(cells)]

    def sample(u, v):
        gx, gy = u * cells, v * cells
        x0, y0 = int(gx) % cells, int(gy) % cells
        x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
        fx, fy = gx - int(gx), gy - int(gy)
        # smoothstep for softer blobs
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)
        top = grid[y0][x0] * (1 - fx) + grid[y0][x1] * fx
        bot = grid[y1][x0] * (1 - fx) + grid[y1][x1] * fx
        return top * (1 - fy) + bot * fy

    out = [[0.0] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            n = 0.6 * sample(x / size, y / size)
            n += 0.4 * sample((x / size) * 2 % 1.0, (y / size) * 2 % 1.0)
            out[y][x] = n
    return out


# --- TANK (64x32) -----------------------------------------------------------

def gen_tank():
    img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))

    OUTLINE = (28, 33, 22, 255)
    TREAD = (44, 46, 40, 255)
    TREAD_HI = (78, 80, 70, 255)
    BODY = (96, 112, 64, 255)
    BODY_HI = (132, 150, 92, 255)
    BODY_LO = (66, 80, 44, 255)
    BARREL = (74, 84, 56, 255)

    # Treads: rounded dark band along the bottom
    rect(img, 6, 23, 56, 30, OUTLINE)
    rect(img, 8, 24, 54, 29, TREAD)
    for wx in range(11, 53, 6):          # wheel highlights / track links
        disc(img, wx, 26, 2, TREAD_HI)
        px(img, wx, 26, TREAD)
    hline(img, 9, 53, 24, TREAD_HI)

    # Hull: trapezoid sitting on the treads
    for y in range(14, 23):
        inset = (y - 14) // 3
        rect(img, 8 + inset, y, 54 - inset, y, BODY)
    # hull outline
    rect(img, 8, 13, 54, 13, OUTLINE)
    for y in range(13, 24):
        px(img, 8 + (y - 14) // 3 if y > 13 else 8, y, OUTLINE)
        px(img, 54 - (y - 14) // 3 if y > 13 else 54, y, OUTLINE)
    hline(img, 10, 52, 14, BODY_HI)      # top highlight
    rect(img, 10, 20, 52, 22, BODY_LO)   # lower shade

    # Turret dome
    for y in range(8, 15):
        half = int(math.sqrt(max(0, 49 - (y - 14) ** 2)))
        rect(img, 29 - half // 2 - 2, y, 29 + half // 2 + 2, y, BODY)
    disc(img, 29, 13, 8, BODY)
    rect(img, 21, 14, 37, 16, BODY)
    # turret shading + outline cap
    disc(img, 27, 11, 3, BODY_HI)
    hline(img, 22, 36, 7, OUTLINE)

    # Barrel: points right toward the muzzle pivot (~x 36 -> right edge)
    rect(img, 35, 10, 63, 13, OUTLINE)
    rect(img, 35, 11, 62, 12, BARREL)
    rect(img, 58, 10, 63, 13, OUTLINE)   # muzzle brake
    rect(img, 59, 11, 62, 12, BODY_HI)

    img.save(os.path.join(OUT, "tank.png"))


# --- DIRT (32x32 atlas: 2x2 seamless 16x16 tiles) ---------------------------

def dirt_tile(seed):
    tile = Image.new("RGBA", (16, 16), (0, 0, 0, 255))
    shades = [
        (74, 50, 30, 255),
        (88, 60, 36, 255),
        (102, 72, 44, 255),
        (60, 40, 22, 255),
    ]
    n = wrapped_noise(16, 4, seed)
    for y in range(16):
        for x in range(16):
            v = n[y][x]
            idx = 0 if v < 0.35 else 1 if v < 0.6 else 2 if v < 0.8 else 3
            tile.putpixel((x, y), shades[idx if idx != 3 else 2])

    # a few pebbles, wrapped so edges still tile
    rnd = random.Random(seed * 7 + 1)
    for _ in range(5):
        cx, cy = rnd.randrange(16), rnd.randrange(16)
        dark = (52, 34, 18, 255)
        lite = (120, 90, 58, 255)
        for dx, dy, c in [(0, 0, dark), (1, 0, dark), (0, 1, dark), (1, 1, dark),
                          (0, 0, lite)]:
            tile.putpixel(((cx + dx) % 16, (cy + dy) % 16), c)
    return tile


def gen_dirt():
    atlas = Image.new("RGBA", (32, 32), (0, 0, 0, 255))
    for i, (ox, oy) in enumerate([(0, 0), (16, 0), (0, 16), (16, 16)]):
        atlas.paste(dirt_tile(1000 + i), (ox, oy))
    atlas.save(os.path.join(OUT, "dirt.png"))


# --- BULLET (8x8) -----------------------------------------------------------

def gen_bullet():
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    OUT_C = (60, 30, 10, 255)
    SHELL = (180, 110, 40, 255)
    CORE = (250, 210, 90, 255)
    # squat horizontal shell with a pointed nose on the right
    rect(img, 1, 2, 5, 5, OUT_C)
    rect(img, 2, 3, 6, 4, SHELL)
    px(img, 6, 3, OUT_C)
    px(img, 7, 3, OUT_C)
    px(img, 2, 3, CORE)
    px(img, 3, 3, CORE)
    px(img, 3, 4, SHELL)
    img.save(os.path.join(OUT, "bullet.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    gen_tank()
    gen_dirt()
    gen_bullet()
    print("wrote tank.png, dirt.png, bullet.png to", OUT)


if __name__ == "__main__":
    main()
