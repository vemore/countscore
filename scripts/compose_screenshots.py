#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pillow>=10.0",
# ]
# ///
"""Compose the Play Store phone screenshots from the raw captures, one set per store locale.

    uv run --script scripts/compose_screenshots.py                 # every locale with captions
    uv run --script scripts/compose_screenshots.py --locale fr-FR  # one locale
    uv run --script scripts/compose_screenshots.py --check         # verify, write nothing

Input: the raw `adb` captures in store_listing/assets/screenshots/phone/ (written by
scripts/capture_screenshots.sh) and, per locale, store_listing/<locale>/screenshot_captions.txt:
one `<capture stem>: <caption>` line per capture, `#` for a comment.

Output: store_listing/<locale>/screenshots/phone/<capture name>.png, 1080x1920 opaque RGB —
the caption in a band above the screen, the status and navigation bars cropped off. That
directory is exactly where play_publish.py looks first for a locale's screenshots, so
`play_publish.py listing --graphics` picks the composed set up with no change.

A locale is a directory of store_listing/ holding a title.txt, the same rule as
play_publish.py's listing_locales(). A locale with no captions file is skipped with a
warning, and --check fails on it: until it has a composed set, Play would get the raw
captures from the assets/ fallback, which Play refuses (ratio 2.22, alpha channel).

Fonts: Roboto Bold (Latin, Cyrillic) is taken from the Flutter SDK's material_fonts cache;
the other scripts need a Noto font installed (see FONTS). --font overrides both.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

WIDTH, HEIGHT = 1080, 1920
LISTING_ROOT = "store_listing"
RAW_DIR = Path("assets") / "screenshots" / "phone"
CAPTIONS_FILE = "screenshot_captions.txt"
OUT_DIR = Path("screenshots") / "phone"

# Raw captures are 1080x2400 from the Pixel: the status bar (clock, notification icons) and
# the gesture/navigation bar carry nothing about the app, and the notification icons date the
# picture. Measured on the 2026-09 captures.
CROP_TOP = 110
CROP_BOTTOM = 132

BACKGROUND = (0x67, 0x3A, 0xB7)  # Deep Purple 500 — the app's seed colour (lib/main.dart)
BACKGROUND_BOTTOM = (0x45, 0x27, 0xA0)  # Deep Purple 800, for a quiet vertical gradient
TEXT = (0xFF, 0xFF, 0xFF)
BAND_HEIGHT = 340  # the caption band, top of the canvas
SIDE_MARGIN = 72  # caption text
BOTTOM_MARGIN = 64  # below the screen
SCREEN_RADIUS = 40
MAX_FONT_SIZE = 84
MIN_FONT_SIZE = 48
MAX_LINES = 2
LINE_SPACING = 1.18

# Locale -> font file names searched for, in order. Latin and Cyrillic share Roboto.
FONTS: dict[str, tuple[str, ...]] = {
    "ja-JP": ("NotoSansCJK-Bold.ttc", "NotoSansCJKjp-Bold.otf", "NotoSansJP-Bold.ttf"),
    "zh-CN": ("NotoSansCJK-Bold.ttc", "NotoSansCJKsc-Bold.otf", "NotoSansSC-Bold.ttf"),
    "hi-IN": ("NotoSansDevanagari-Bold.ttf", "NotoSansDevanagariUI-Bold.ttf"),
    "ar": ("NotoSansArabic-Bold.ttf", "NotoSansArabicUI-Bold.ttf", "NotoKufiArabic-Bold.ttf"),
}
DEFAULT_FONTS = ("Roboto-Bold.ttf",)
RTL_LOCALES = {"ar"}
# Scripts written without spaces between words: wrap on characters, not on words.
NO_SPACE_LOCALES = {"ja-JP", "zh-CN"}
FONT_DIRS = (
    "/usr/share/fonts",
    "/usr/local/share/fonts",
    "~/.local/share/fonts",
    "~/.fonts",
)


class ComposeError(Exception):
    """A refusal with a message meant for the person running the script."""


# ----------------------------------------------------------------- files


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def listing_locales(root: Path) -> list[str]:
    base = root / LISTING_ROOT
    return sorted(
        d.name
        for d in base.iterdir()
        if d.is_dir() and d.name != "assets" and (d / "title.txt").is_file()
    )


def raw_captures(root: Path) -> list[Path]:
    shots = sorted((root / LISTING_ROOT / RAW_DIR).glob("*.png"), key=lambda p: p.name)
    if not shots:
        raise ComposeError(f"no raw capture in {root / LISTING_ROOT / RAW_DIR}")
    return shots


def read_captions(path: Path, stems: list[str]) -> dict[str, str]:
    """`<stem>: <caption>` per line; every capture needs exactly one caption."""
    captions: dict[str, str] = {}
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        stem, sep, caption = line.partition(":")
        stem, caption = stem.strip(), caption.strip()
        if not sep or not caption:
            raise ComposeError(f"{path}:{n}: expected `<capture stem>: <caption>`")
        if stem not in stems:
            raise ComposeError(f"{path}:{n}: no raw capture named {stem}.png")
        if stem in captions:
            raise ComposeError(f"{path}:{n}: a second caption for {stem}")
        captions[stem] = caption
    missing = [s for s in stems if s not in captions]
    if missing:
        raise ComposeError(f"{path}: no caption for {', '.join(missing)}")
    return captions


def find_font(locale: str, override: str | None = None) -> Path:
    if override:
        path = Path(override).expanduser()
        if not path.is_file():
            raise ComposeError(f"--font {override}: no such file")
        return path
    names = FONTS.get(locale, DEFAULT_FONTS)
    dirs = [Path(d).expanduser() for d in FONT_DIRS]
    flutter = shutil.which("flutter")
    if flutter:
        dirs.insert(
            0, Path(os.path.realpath(flutter)).parent / "cache" / "artifacts" / "material_fonts"
        )
    for name in names:
        for d in dirs:
            if (d / name).is_file():
                return d / name
            if d.is_dir():
                hit = next(d.rglob(name), None)
                if hit:
                    return hit
    raise ComposeError(
        f"{locale}: none of {', '.join(names)} found in the Flutter SDK or {', '.join(FONT_DIRS)}. "
        "Install it (Debian/Ubuntu: fonts-noto-cjk, fonts-noto-core) or pass --font."
    )


# ----------------------------------------------------------------- drawing


def wrap(text: str, font: ImageFont.FreeTypeFont, max_width: int, by_char: bool) -> list[str]:
    tokens = list(text) if by_char else text.split(" ")
    joiner = "" if by_char else " "
    lines: list[str] = []
    current = ""
    for token in tokens:
        candidate = f"{current}{joiner}{token}" if current else token
        if font.getlength(candidate) <= max_width or not current:
            current = candidate
        else:
            lines.append(current)
            current = token
    if current:
        lines.append(current)
    return lines


def balance(
    lines: list[str], text: str, font: ImageFont.FreeTypeFont, max_width: int, by_char: bool
) -> list[str]:
    """Two lines of similar length read better than a full line and a widow."""
    if len(lines) != 2:
        return lines
    tokens = list(text) if by_char else text.split(" ")
    joiner = "" if by_char else " "
    best = lines
    best_width = max(font.getlength(line) for line in lines)
    for i in range(1, len(tokens)):
        a, b = joiner.join(tokens[:i]), joiner.join(tokens[i:])
        width = max(font.getlength(a), font.getlength(b))
        if width <= max_width and width < best_width:
            best, best_width = [a, b], width
    return best


def fit_caption(
    text: str, font_path: Path, locale: str
) -> tuple[ImageFont.FreeTypeFont, list[str]]:
    by_char = locale in NO_SPACE_LOCALES
    max_width = WIDTH - 2 * SIDE_MARGIN
    for size in range(MAX_FONT_SIZE, MIN_FONT_SIZE - 1, -2):
        font = ImageFont.truetype(str(font_path), size)
        lines = wrap(text, font, max_width, by_char)
        if len(lines) <= MAX_LINES and all(font.getlength(line) <= max_width for line in lines):
            return font, balance(lines, text, font, max_width, by_char)
    raise ComposeError(
        f"{locale}: caption too long for {MAX_LINES} lines at {MIN_FONT_SIZE}px: {text!r}"
    )


def gradient() -> Image.Image:
    top, bottom = BACKGROUND, BACKGROUND_BOTTOM
    column = Image.new("RGB", (1, HEIGHT))
    for y in range(HEIGHT):
        t = y / (HEIGHT - 1)
        column.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return column.resize((WIDTH, HEIGHT))


def compose(raw: Image.Image, caption: str, font_path: Path, locale: str) -> Image.Image:
    """One 1080x1920 opaque RGB store screenshot."""
    canvas = gradient()
    draw = ImageDraw.Draw(canvas)

    # Caption, centred in the band.
    font, lines = fit_caption(caption, font_path, locale)
    kwargs: dict[str, str] = {}
    if locale in RTL_LOCALES:
        if not features.check("raqm"):
            raise ComposeError(
                f"{locale}: Pillow was built without libraqm; Arabic would not be shaped"
            )
        kwargs = {"direction": "rtl", "language": "ar"}
    line_height = round(font.size * LINE_SPACING)
    block = line_height * len(lines)
    y = (BAND_HEIGHT - block) // 2 + round(font.size * 0.1)
    for line in lines:
        draw.text(
            (WIDTH // 2, y + line_height // 2), line, font=font, fill=TEXT, anchor="mm", **kwargs
        )
        y += line_height

    # The screen: crop the system bars, scale to the space left, round the corners.
    screen = raw.convert("RGB")
    w, h = screen.size
    screen = screen.crop((0, CROP_TOP, w, h - CROP_BOTTOM))
    avail_h = HEIGHT - BAND_HEIGHT - BOTTOM_MARGIN
    scale = min(avail_h / screen.height, (WIDTH - 2 * SIDE_MARGIN) / screen.width)
    size = (round(screen.width * scale), round(screen.height * scale))
    screen = screen.resize(size, Image.LANCZOS)
    x = (WIDTH - size[0]) // 2
    top = BAND_HEIGHT

    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), SCREEN_RADIUS, fill=255
    )

    shadow = Image.new("L", (WIDTH, HEIGHT), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, top + 12, x + size[0], top + size[1] + 12), SCREEN_RADIUS, fill=110
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    canvas = Image.composite(Image.new("RGB", (WIDTH, HEIGHT), (0x1A, 0x10, 0x33)), canvas, shadow)
    canvas.paste(screen, (x, top), mask)
    return canvas


# ----------------------------------------------------------------- commands


def check_image(path: Path) -> str | None:
    """None when `path` is what Play accepts from this script, else why not."""
    with Image.open(path) as im:
        if im.size != (WIDTH, HEIGHT):
            return f"{path}: {im.size[0]}x{im.size[1]}, expected {WIDTH}x{HEIGHT}"
        if im.mode != "RGB":
            return f"{path}: mode {im.mode}, expected RGB (no alpha)"
    return None


def compose_locale(
    root: Path, locale: str, font: str | None, out: object = sys.stdout
) -> list[Path]:
    shots = raw_captures(root)
    captions = read_captions(root / LISTING_ROOT / locale / CAPTIONS_FILE, [s.stem for s in shots])
    font_path = find_font(locale, font)
    out_dir = root / LISTING_ROOT / locale / OUT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for shot in shots:
        with Image.open(shot) as raw:
            image = compose(raw, captions[shot.stem], font_path, locale)
        target = out_dir / shot.name
        image.save(target, "PNG", optimize=True)
        written.append(target)
    print(
        f"{locale}: {len(written)} screenshots -> {out_dir.relative_to(root)} ({font_path.name})",
        file=out,
    )  # type: ignore[arg-type]
    return written


def check(root: Path, locales: list[str]) -> list[str]:
    problems = []
    names = [s.name for s in raw_captures(root)]
    for locale in locales:
        out_dir = root / LISTING_ROOT / locale / OUT_DIR
        for name in names:
            path = out_dir / name
            if not path.is_file():
                problems.append(f"{locale}: missing {path.relative_to(root)}")
                continue
            why = check_image(path)
            if why:
                problems.append(why)
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--locale", action="append", help="a store locale (repeatable); default: every one"
    )
    parser.add_argument("--font", help="a font file, overriding the per-locale choice")
    parser.add_argument(
        "--check", action="store_true", help="verify the composed sets, write nothing"
    )
    parser.add_argument("--root", type=Path, default=None, help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    root = args.root or repo_root()
    try:
        known = listing_locales(root)
        locales = args.locale or known
        unknown = [loc for loc in locales if loc not in known]
        if unknown:
            raise ComposeError(
                f"not a store locale: {', '.join(unknown)} (known: {', '.join(known)})"
            )
        if args.check:
            problems = check(root, locales)
            for p in problems:
                print(p, file=sys.stderr)
            print(f"check: {len(locales)} locale(s), {len(problems)} problem(s)")
            return 1 if problems else 0
        skipped = []
        for locale in locales:
            if not (root / LISTING_ROOT / locale / CAPTIONS_FILE).is_file():
                if args.locale:
                    raise ComposeError(f"{locale}: no {LISTING_ROOT}/{locale}/{CAPTIONS_FILE}")
                skipped.append(locale)
                continue
            compose_locale(root, locale, args.font)
        if skipped:
            print(
                f"warning: no {CAPTIONS_FILE} for {', '.join(skipped)} — Play would get the raw "
                "captures from the assets/ fallback there",
                file=sys.stderr,
            )
    except ComposeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
