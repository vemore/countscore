#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pillow>=10.0",
# ]
# ///
"""Draw the 1024x500 Play Store feature graphic, Template 1, in the app's teal.

    uv run --script scripts/generate_feature_graphic.py           # write the PNG
    uv run --script scripts/generate_feature_graphic.py --check   # verify, write nothing

Template 1 of store_listing/FEATURE_GRAPHIC_TEMPLATES.md: the app icon, the name, a tagline
and the three promises on the left; the scoring grid in a phone frame on the right.

Every pixel comes from a committed file, so the graphic is reproducible:

- the colours are the app's own — BRAND is kBrandSeedLight and GOLD is kLeaderGold, both in
  lib/utils/app_theme.dart; INK is the icon's ground and the dark theme's surface;
- the icon is store_listing/assets/icon_512.png, itself generated from design/icon/ by
  scripts/generate_icons.py (.llmwiki/Release.md);
- the phone shows store_listing/en-US/raw/05_game_board.png, an en-US capture of the
  fictional demo database (test/demo_db_test.dart) — no real person's data;
- the type is Nunito, the font the app bundles in assets/fonts/.

Output: store_listing/assets/feature_graphic.png, 1024x500 opaque RGB — every locale's,
unless store_listing/<locale>/feature_graphic.png exists. The text is English in every
locale, as the graphic is shared; a locale that wants its own drops it in beside its
title.txt.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

# ----------------------------------------------------------------- constants

WIDTH, HEIGHT = 1024, 500
SAFE_MARGIN = 50  # Play crops to a 924x400 centre on some surfaces

# The app's own colours, lib/utils/app_theme.dart.
BRAND = (0x0E, 0x8F, 0x88)  # kBrandSeedLight
BRAND_LIGHT = (0x5E, 0xD8, 0xCF)  # kBrandSeedDark, the teal lifted for a dark surface
GOLD = (0xF2, 0xB7, 0x05)  # kLeaderGold
INK = (0x0E, 0x17, 0x16)  # the icon's ground, and the dark theme's surface
WHITE = (0xFF, 0xFF, 0xFF)

TITLE = "CountScore"
TAGLINE = "Keep score for every game"
SUBLINE = "Offline scores · Stats · Share with your group"
CHIPS = ("No ads", "No tracking", "Open source")

ICON = "store_listing/assets/icon_512.png"
CAPTURE = "store_listing/en-US/raw/05_game_board.png"
OUT = "store_listing/assets/feature_graphic.png"
FONT_DIR = "assets/fonts"

# The capture's status bar, and how far down the scoring grid runs on it. Measured on the
# 1008x2244 Pixel captures (SYSTEM_BARS in scripts/compose_screenshots.py).
CAPTURE_TOP = 110
CAPTURE_GRID_BOTTOM = 1420

SUPERSAMPLE = 3  # draw at 3x and downscale: round corners and glyphs without jaggies
TOLERANCE = 2.0  # --check: mean per-channel difference a Pillow version may cost


class GraphicError(Exception):
    """A refusal with a message meant for the person running the script."""


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    """`a` blended towards `b`; t=0 keeps `a`, t=1 is `b`."""
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))  # type: ignore[return-value]


def _shade(rgb: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    """`rgb` darkened towards black: 1.0 keeps it, 0.0 is black."""
    return (round(rgb[0] * factor), round(rgb[1] * factor), round(rgb[2] * factor))


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    path = repo_root() / FONT_DIR / name
    if not path.exists():
        raise GraphicError(f"missing font {path} — the app bundles Nunito in {FONT_DIR}/")
    return ImageFont.truetype(str(path), size)


# ----------------------------------------------------------------- pieces


def background(size: tuple[int, int]) -> Image.Image:
    """The teal ground: a quiet diagonal gradient, with two lighter discs behind the phone."""
    w, h = size
    top, bottom = _mix(BRAND, BRAND_LIGHT, 0.12), _shade(BRAND, 0.62)
    img = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        draw.line([(0, y), (w, y)], fill=_mix(top, bottom, y / max(h - 1, 1)))

    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    cx = round(w * 0.74)
    for radius, alpha in ((0.95, 22), (0.62, 22)):
        gdraw.ellipse(
            [cx - round(h * radius), round(h * (0.5 - radius)),
             cx + round(h * radius), round(h * (0.5 + radius))],
            fill=(*BRAND_LIGHT, alpha),
        )
    glow = glow.filter(ImageFilter.GaussianBlur(round(h * 0.06)))
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    return img.convert("RGB")


def rounded(img: Image.Image, radius: int) -> Image.Image:
    """`img` with its corners rounded, as RGBA."""
    img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius, fill=255)
    img.putalpha(mask)
    return img


def icon(size: int) -> Image.Image:
    """The store icon, squared off at the corners it is drawn with on a launcher."""
    path = repo_root() / ICON
    if not path.exists():
        raise GraphicError(f"missing {path} — run scripts/generate_icons.py")
    art = Image.open(path).convert("RGB").resize((size, size), Image.LANCZOS)
    return rounded(art, round(size * 0.235))


def phone(width: int, height: int) -> Image.Image:
    """The scoring grid of the demo capture, in an ink phone frame, as RGBA."""
    path = repo_root() / CAPTURE
    if not path.exists():
        raise GraphicError(f"missing {path} — scripts/capture_screenshots.sh en-US")
    shot = Image.open(path).convert("RGB")
    if shot.height <= CAPTURE_GRID_BOTTOM:
        raise GraphicError(f"{path} is {shot.width}x{shot.height}; the grid crop needs more rows")

    bezel = max(round(width * 0.032), 6)
    radius = round(width * 0.135)
    frame = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, width - 1, height - 1], radius, fill=(*INK, 255))

    sw, sh = width - 2 * bezel, height - 2 * bezel
    # Crop the status bar off the top, then as much of the grid as the screen's ratio holds.
    keep = min(CAPTURE_GRID_BOTTOM, CAPTURE_TOP + round(shot.width * sh / sw))
    screen = shot.crop((0, CAPTURE_TOP, shot.width, keep)).resize((sw, sh), Image.LANCZOS)
    frame.paste(rounded(screen, radius - bezel), (bezel, bezel), rounded(screen, radius - bezel))
    return frame


def chip(text: str, height: int) -> Image.Image:
    """One gold promise pill, as RGBA, sized to its text."""
    label = font("Nunito-Bold.ttf", round(height * 0.52))
    pad = round(height * 0.62)
    box = label.getbbox(text)
    img = Image.new("RGBA", (box[2] - box[0] + 2 * pad, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([0, 0, img.width - 1, height - 1], height // 2, fill=(*GOLD, 255))
    draw.text((img.width // 2, height // 2), text, font=label, fill=INK, anchor="mm")
    return img


# ----------------------------------------------------------------- the graphic


def draw_graphic() -> Image.Image:
    """The finished 1024x500 RGB graphic."""
    s = SUPERSAMPLE
    w, h = WIDTH * s, HEIGHT * s
    img = background((w, h))
    draw = ImageDraw.Draw(img)

    # Right: the phone, bleeding off the bottom edge so it reads as a device, not a sticker.
    ph = phone(round(322 * s), round(556 * s))
    img.paste(ph, (round(664 * s), round(46 * s)), ph)

    # Left: icon and wordmark on one line.
    icon_size = round(126 * s)
    icon_x, icon_y = round(58 * s), round(98 * s)
    art = icon(icon_size)
    img.paste(art, (icon_x, icon_y), art)

    title = font("Nunito-ExtraBold.ttf", round(72 * s))
    draw.text(
        (icon_x + icon_size + round(26 * s), icon_y + icon_size // 2),
        TITLE,
        font=title,
        fill=WHITE,
        anchor="lm",
    )

    left = round(SAFE_MARGIN * s + 12 * s)
    draw.text((left, round(262 * s)), TAGLINE, font=font("Nunito-Bold.ttf", round(38 * s)),
              fill=WHITE, anchor="ls")
    draw.text((left, round(310 * s)), SUBLINE, font=font("Nunito-Regular.ttf", round(25 * s)),
              fill=_mix(BRAND, WHITE, 0.82), anchor="ls")

    x = left
    for text in CHIPS:
        pill = chip(text, round(48 * s))
        img.paste(pill, (x, round(336 * s)), pill)
        x += pill.width + round(14 * s)

    return img.resize((WIDTH, HEIGHT), Image.LANCZOS).convert("RGB")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Draw the Play Store feature graphic.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="redraw in memory and compare with the committed PNG; write nothing",
    )
    args = parser.parse_args(argv)

    out = repo_root() / OUT
    try:
        img = draw_graphic()
    except GraphicError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.check:
        if not out.exists():
            print(f"error: {OUT} is missing", file=sys.stderr)
            return 1
        committed = Image.open(out)
        if committed.size != (WIDTH, HEIGHT):
            print(
                f"error: {OUT} is {committed.width}x{committed.height}, not {WIDTH}x{HEIGHT}",
                file=sys.stderr,
            )
            return 1
        if committed.mode != "RGB":
            print(f"error: {OUT} is {committed.mode}; Play refuses an alpha channel", file=sys.stderr)
            return 1
        # Not byte equality: Pillow's resampling moves by a value or two between versions, and
        # a store asset must not go red on a dependency bump. A real difference — a stale
        # graphic, another palette — moves the mean by far more than TOLERANCE.
        diff = ImageChops.difference(committed.convert("RGB"), img)
        mean = sum(i * n for i, n in enumerate(diff.convert("L").histogram())) / (WIDTH * HEIGHT)
        if mean > TOLERANCE:
            print(
                f"error: {OUT} differs from what this script draws "
                f"(mean |difference| {mean:.2f} > {TOLERANCE}); redraw it",
                file=sys.stderr,
            )
            return 1
        print(f"ok: {OUT} is {WIDTH}x{HEIGHT} RGB and matches this script (mean {mean:.2f})")
        return 0

    img.save(out, format="PNG", optimize=True)
    print(f"wrote {OUT} ({img.width}x{img.height} {img.mode}, {out.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
