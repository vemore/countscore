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

Input, per locale: the raw `adb` captures in store_listing/<locale>/raw/, taken with the app in
that locale's language (scripts/capture_screenshots.sh <locale>). There is no shared fallback:
a locale with captions and no raw/ set is refused, so one carousel never shows another
locale's UI language. And store_listing/<locale>/screenshot_captions.txt:
one `<capture stem>: <caption>` line per capture, `#` for a comment, `|` to force the line
break (for the scripts written without spaces, where the automatic wrap may split a word).

Output: store_listing/<locale>/screenshots/phone/<capture name>.png, 1080x1920 opaque RGB —
the caption in a band above the screen, the status and navigation bars cropped off, on a
gradient of the app's teal (BRAND). The directory holds exactly the composed set: a PNG there
with no raw capture of that name is removed on compose and reported by --check. That
directory is the only place play_publish.py takes a locale's screenshots from, so
`play_publish.py listing --graphics` picks the composed set up with no change.

A locale is a directory of store_listing/ holding a title.txt, the same rule as
play_publish.py's listing_locales(). A locale with no captions file is skipped with a
warning, and --check fails on it: until it has a composed set, play_publish.py refuses to
upload its screenshots.

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
LOCALE_RAW_DIR = "raw"  # store_listing/<locale>/raw/, the locale's own captures
CAPTIONS_FILE = "screenshot_captions.txt"
OUT_DIR = Path("screenshots") / "phone"

# The status bar (clock, notification icons) and the gesture/navigation bar carry nothing
# about the app, and the notification icons date the picture: both are cropped. Pixels of
# (top, bottom) per capture size, measured on real captures — the navigation bar is 48 dp, so
# its height follows the phone's density. 1080x2400: a 1080p capture (the shared set of
# 2026-09, since deleted); 1008x2244: the Pixel 9 Pro XL at its default resolution, the per-locale sets of 2026-09-19 (status-bar
# icons end at row 90, the app bar's first ink is row 189, the navigation bar starts at 2136).
# Any other size is refused rather than cropped by guess.
SYSTEM_BARS = {
    (1080, 2400): (110, 132),
    (1008, 2244): (110, 108),
}


def system_bars(size: tuple[int, int]) -> tuple[int, int]:
    """The (top, bottom) crop of a raw capture of this size; ComposeError if unmeasured."""
    try:
        return SYSTEM_BARS[size]
    except KeyError:
        known = ", ".join(f"{w}x{h}" for w, h in SYSTEM_BARS)
        raise ComposeError(
            f"raw capture is {size[0]}x{size[1]}; the system bars are measured for {known} "
            "only (SYSTEM_BARS in scripts/compose_screenshots.py)"
        ) from None


def _shade(rgb: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    """`rgb` darkened towards black: 1.0 keeps it, 0.0 is black."""
    return (round(rgb[0] * factor), round(rgb[1] * factor), round(rgb[2] * factor))


# The app's seed colour, kBrandSeedLight in lib/utils/app_theme.dart (a test compares them).
BRAND = (0x0E, 0x8F, 0x88)
BACKGROUND = BRAND  # top of a quiet vertical gradient
BACKGROUND_BOTTOM = _shade(BRAND, 0.7)
SHADOW = _shade(BRAND, 0.2)  # under the screen
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
# A .ttc holds several faces: the CJK collection is JP, KR, SC, TC, HK in that order, and
# the Chinese listing must get the Simplified Chinese glyph shapes, not the Japanese ones.
FONT_INDEX = {"zh-CN": 2}
# Scripts whose glyphs must be shaped (joined, reordered): without libraqm Pillow draws them
# as isolated, wrongly ordered letters — legible to nobody who reads the language.
SHAPED_LOCALES = {"ar", "hi-IN"}
LANGUAGE = {"ar": "ar", "hi-IN": "hi", "ja-JP": "ja", "zh-CN": "zh-Hans"}
# A line break after one of these ends a clause (Latin, Arabic, CJK and dash punctuation).
CLAUSE_END = (",", "?", ":", "!", ";", "—", "،", "؟", "，", "？", "：", "、")
BREAK = "|"  # in a caption, forces the line break there (and is not drawn)
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


def raw_dir(root: Path, locale: str) -> Path:
    """The locale's own raw/ set — the only source; there is no shared fallback."""
    return root / LISTING_ROOT / locale / LOCALE_RAW_DIR


def raw_captures(root: Path, locale: str) -> list[Path]:
    directory = raw_dir(root, locale)
    shots = sorted(directory.glob("*.png"), key=lambda p: p.name)
    if not shots:
        raise ComposeError(
            f"{locale}: no raw capture in {directory.relative_to(root)} — take the locale's own "
            f"set first (scripts/capture_screenshots.sh {locale}); there is no shared fallback"
        )
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
    """Where to break two lines: after a clause if one fits, else at the most even split.

    A break after the comma, question mark or colon that ends a clause reads as two phrases;
    an even split in mid-phrase ("Your game is not / listed? Create it") reads as a typo.
    """
    if len(lines) != 2:
        return lines
    tokens = list(text) if by_char else text.split(" ")
    joiner = "" if by_char else " "
    best, best_width, best_clause = lines, max(font.getlength(line) for line in lines), False
    for i in range(1, len(tokens)):
        a, b = joiner.join(tokens[:i]), joiner.join(tokens[i:])
        width = max(font.getlength(a), font.getlength(b))
        if width > max_width:
            continue
        clause = a.rstrip().endswith(CLAUSE_END)
        if (clause and not best_clause) or (clause == best_clause and width < best_width):
            best, best_width, best_clause = [a, b], width, clause
    return best


def load_font(font_path: Path, size: int, locale: str) -> ImageFont.FreeTypeFont:
    index = FONT_INDEX.get(locale, 0) if font_path.suffix.lower() == ".ttc" else 0
    return ImageFont.truetype(str(font_path), size, index=index)


def fit_caption(
    text: str, font_path: Path, locale: str
) -> tuple[ImageFont.FreeTypeFont, list[str]]:
    by_char = locale in NO_SPACE_LOCALES
    max_width = WIDTH - 2 * SIDE_MARGIN
    forced = [part.strip() for part in text.split(BREAK)] if BREAK in text else None
    for size in range(MAX_FONT_SIZE, MIN_FONT_SIZE - 1, -2):
        font = load_font(font_path, size, locale)
        if forced:
            if len(forced) <= MAX_LINES and all(font.getlength(p) <= max_width for p in forced):
                return font, forced
            continue
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
    if locale in SHAPED_LOCALES and not features.check("raqm"):
        raise ComposeError(
            f"{locale}: Pillow was built without libraqm; the text would not be shaped"
        )
    if locale in LANGUAGE and features.check("raqm"):
        kwargs["language"] = LANGUAGE[locale]
    if locale in RTL_LOCALES:
        kwargs["direction"] = "rtl"
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
    crop_top, crop_bottom = system_bars((w, h))
    screen = screen.crop((0, crop_top, w, h - crop_bottom))
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
    canvas = Image.composite(Image.new("RGB", (WIDTH, HEIGHT), SHADOW), canvas, shadow)
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
    shots = raw_captures(root, locale)
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
    for stale in sorted(set(out_dir.glob("*.png")) - set(written)):
        stale.unlink()  # a capture renamed or dropped since the last compose
        print(
            f"{locale}: removed {stale.relative_to(root)} (no raw capture)",
            file=out,  # type: ignore[arg-type]
        )
    source = raw_dir(root, locale).relative_to(root)
    print(
        f"{locale}: {len(written)} screenshots from {source} -> {out_dir.relative_to(root)} "
        f"({font_path.name})",
        file=out,
    )  # type: ignore[arg-type]
    return written


def check(root: Path, locales: list[str]) -> list[str]:
    problems = []
    for locale in locales:
        names = [s.name for s in raw_captures(root, locale)]
        out_dir = root / LISTING_ROOT / locale / OUT_DIR
        for extra in sorted(p for p in out_dir.glob("*.png") if p.name not in names):
            problems.append(
                f"{locale}: {extra.relative_to(root)} matches no raw capture in "
                f"{raw_dir(root, locale).relative_to(root)} — not composed by this script"
            )
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
                f"warning: no {CAPTIONS_FILE} for {', '.join(skipped)} — no composed "
                "screenshots there, and play_publish.py --graphics will refuse the locale",
                file=sys.stderr,
            )
    except ComposeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
