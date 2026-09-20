#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pillow>=10.0",
# ]
# ///
"""CountScore — regenerate every icon raster from the vector source.

The artwork is the owner's own drawing (ChatGPT-generated, transcribed to SVG),
hardened for the Android/Play pipeline and repainted in the app's palette. The
untouched original is `design/icon/source-from-chatgpt.svg`; this script holds
the hardened geometry and both palettes, and it is the only thing that writes
an icon file anywhere in the repository.

Two stages:

    uv run --script scripts/generate_icons.py --svg
        rewrite design/icon/*.svg from the geometry below — only when the
        artwork itself changes
    uv run --script scripts/generate_icons.py
        rasterize design/icon/*.svg into every destination the app, the store
        and the PWA read

The six vector sources, all 1024x1024:

    chosen.svg              the flat icon, full-bleed ink ground
    chosen-adaptive-bg.svg  the Android adaptive background (a flat ink square)
    chosen-adaptive-fg.svg  the Android adaptive foreground, measured into the
                            safe circle
    chosen-mono.svg         the Android themed (monochrome) layer, authored —
                            it cannot be derived, flattening the file to one
                            colour gives a blob
    chosen-maskable.svg     the PWA maskable icon, art inside the 80% circle
    chosen-favicon.svg      the reduced mark for the 16 px browser tab: the
                            "+1" alone (see .llmwiki/Release.md)

Two things are easy to get wrong and are handled here rather than by eye:

  * the safe-zone fit is *measured* from the rendered alpha, because analytic
    bounds on rotated shapes overstate the ink by about a third;
  * a monochrome shape carrying no `fill` attribute falls back to black, which
    is invisible against the mask — that is what made the pawns and the rays
    disappear from the first monochrome layer.

Requires `rsvg-convert` (librsvg) and Pillow.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESIGN = os.path.join(ROOT, "design", "icon")

SRC_VB = 1254.0  # the original artwork's viewBox
S = 1024  # ours
SAFE = 368.0  # the Android adaptive foreground, with pubspec's 8% inset
DISPLAY = 440.0  # how far the artwork reaches in the flat icon
MASKABLE = 400.0  # the PWA maskable safe circle: 80% of the image, minus margin
FAVICON = 470.0  # the reduced mark on the favicon ground, nearly full-bleed
GAP = 16  # the hairline that frees a shape from what it overlaps
BLACK = "#000000"

PALETTES = {
    "brand": dict(  # app_theme.dart + player_colors.dart — what ships
        name="Ink + gold (the app's palette)",
        ground="#0E1716", ray="#F2B705",
        card_back="#5ED8CF", card_mid="#B9D6D3", card_front="#F3F8F7",
        ink="#0E1716", plus_line="#0E1716", plus_fill="#F2B705",
        die_face="#F3F8F7", die_side="#CBDDDA",
        p1="#E4572E", p1s="#C4441F", p1h="#F5A48A",
        p2="#3B82F6", p2s="#2563C9", p2h="#9DC0FA",
        p3="#5ED8CF", p3s="#38B3AA", p3h="#A9EDE7"),
    "navy": dict(  # the original, gradients flattened — kept for provenance
        name="Navy + orange (the original)",
        ground="#04307E", ray="#FF6B4A",
        card_back="#0CE5DC", card_mid="#0393FF", card_front="#F7FAFE",
        ink="#071D5B", plus_line="#071D5B", plus_fill="#FFFFFF",
        die_face="#FFFFFF", die_side="#DCE8F9",
        p1="#FF6644", p1s="#F9482E", p1h="#FFB3A0",
        p2="#0A84FF", p2s="#0561F2", p2h="#8CC8FF",
        p3="#0CE5DC", p3s="#0BC2BA", p3h="#9CF7F3"),
}

# ---------------------------------------------------------------- the artwork

DIE_PIPS = [
    '<ellipse cx="344" cy="618" rx="28" ry="17" fill="{ink}"/>',
    '<ellipse cx="247" cy="672" rx="28" ry="17" fill="{ink}"/>',
    '<ellipse cx="344" cy="671" rx="28" ry="17" fill="{ink}"/>',
    '<ellipse cx="437" cy="662" rx="28" ry="17" fill="{ink}"/>',
    '<ellipse cx="344" cy="726" rx="28" ry="17" fill="{ink}"/>',
    '<ellipse cx="204" cy="787" rx="19" ry="27" fill="{ink}" transform="rotate(-18 204 787)"/>',
    '<ellipse cx="257" cy="855" rx="19" ry="27" fill="{ink}" transform="rotate(-18 257 855)"/>',
    '<ellipse cx="298" cy="927" rx="19" ry="27" fill="{ink}" transform="rotate(-18 298 927)"/>',
    '<ellipse cx="497" cy="763" rx="20" ry="30" fill="{ink}" transform="rotate(20 497 763)"/>',
    '<ellipse cx="402" cy="822" rx="20" ry="30" fill="{ink}" transform="rotate(20 402 822)"/>',
    '<ellipse cx="452" cy="857" rx="20" ry="30" fill="{ink}" transform="rotate(20 452 857)"/>',
    '<ellipse cx="502" cy="886" rx="20" ry="30" fill="{ink}" transform="rotate(20 502 886)"/>',
    '<ellipse cx="409" cy="947" rx="20" ry="30" fill="{ink}" transform="rotate(20 409 947)"/>',
]

RAYS = [
    'M1083.2,196.6 L1034.0,309.2 A12,12 0 0 0 1054.6,321.2 L1127.9,222.5 A26,26 0 1 0 1083.2,196.6Z',
    'M1145.1,325.7 L1055.0,388.5 A14,14 0 0 0 1068.3,412.9 L1169.9,371.0 A26,26 0 1 0 1145.1,325.7Z',
    'M1182.6,469.2 L1079.8,456.1 A14,14 0 0 0 1074.4,483.5 L1174.6,510.3 A21,21 0 1 0 1182.6,469.2Z',
    'M86.7,527.1 L168.3,576.1 A13,13 0 0 0 183.3,555.0 L109.7,494.5 A20,20 0 1 0 86.7,527.1Z',
    'M86.0,638.0 L165.6,634.0 A12,12 0 0 0 166.8,610.1 L88.0,598.2 A20,20 0 1 0 86.0,638.0Z',
]

PLUS_INNER = ('<g transform="matrix(0.98,-0.19,0.07,1,702,526)">'
              '<rect x="-118" y="-33" width="236" height="66" rx="8"/>'
              '<rect x="-33" y="-125" width="66" height="250" rx="8"/></g>'
              '<g transform="matrix(0.98,-0.19,0.07,1,950,470)">'
              '<path d="M-10,-196 L44,-202 L44,198 L-44,198 L-44,-66 L-98,-24 L-128,-84Z"/></g>')

PAWNS = [  # back to front, as they were drawn
    dict(body='M961,836.16 Q920.0,919.6 879,1003 A88,48 0 0 0 1055,1003 Q1042.0,919.6 1029,836.16Z',
         clip='M921,816.16 L983.1,836.16 Q949.5,919.6 916.0,1071 L839,1071Z',
         hx=995, hy=780, hr=78, shx=995, shy=792,
         hlx=1030, hly=750, c='p3', s='p3s', h='p3h', cid='pc3'),
    dict(body='M753,782.48 Q727.0,895.2 701,1008 A114,56 0 0 0 929,1008 Q893.0,895.2 857,782.48Z',
         clip='M713,762.48 L786.8,782.48 Q770.9,895.2 748.9,1084 L661,1084Z',
         hx=805, hy=722, hr=84, shx=805, shy=734,
         hlx=838, hly=690, c='p2', s='p2s', h='p2h', cid='pc2'),
    dict(body='M582,843.36 Q541.5,947.7 501,1052 A127,58 0 0 0 755,1052 Q724.5,947.7 694,843.36Z',
         clip='M542,823.36 L618.4,843.36 Q590.2,947.7 554.3,1130 L461,1130Z',
         hx=638, hy=780, hr=88, shx=638, shy=792,
         hlx=680, hly=748, c='p1', s='p1s', h='p1h', cid='pc1'),
]


def _force(svg, colour):
    """Paint every fill and stroke `colour`, and give a fill to the shapes that
    declare none — a shape with no fill defaults to black, which is invisible
    against the monochrome mask's black ground."""
    out = re.sub(r'(fill|stroke|stop-color)="[^"]*"', rf'\1="{colour}"', svg)
    out = re.sub(r'fill="url\([^)]*\)"', f'fill="{colour}"', out)

    def add(m):
        tag = m.group(0)
        return tag if "fill=" in tag else tag[:-2] + f' fill="{colour}"/>'

    return re.sub(r'<(path|circle|ellipse|rect|polygon)\b[^>]*/>', add, out)


def halo(svg):
    """The same shape grown by GAP, in black, for the monochrome mask.

    Growing arbitrary path geometry is hard; stroking it is not. A stroke of
    2*GAP centred on the outline pushes the edge out by exactly GAP, and works
    the same on the pawn curves, the rotated cards and the die polygon."""
    m = re.search(r'stroke-width="([\d.]+)"', svg)
    w = float(m.group(1)) + 2 * GAP if m else 2 * GAP
    out = _force(svg, BLACK)
    out = re.sub(r'\sstroke(-width|-linejoin|-linecap)?="[^"]*"', "", out)
    ins = out.index(">") if out.startswith("<g") else out.index("/>")
    return (out[:ins] + f' stroke="{BLACK}" stroke-width="{w:.0f}" '
            f'stroke-linejoin="round"' + out[ins:])


def inked(svg):
    return _force(svg, "#FFFFFF")


def blacked(svg):
    return _force(svg, BLACK)


def parts(p):
    """(svg, mono role, mono shape) in draw order. A mono shape of None means
    the element carries no ink of its own in the monochrome layer."""
    out = []
    for d in RAYS:
        out.append((f'<path fill="{p["ray"]}" d="{d}"/>', "solid", f'<path d="{d}"/>'))

    cards = [
        (f'<rect x="92" y="338" width="300" height="450" rx="36" fill="{p["card_back"]}" '
         f'transform="rotate(-29 92 338)"/>', "solid"),
        (f'<rect x="207" y="214" width="330" height="480" rx="40" fill="{p["card_mid"]}" '
         f'transform="rotate(-12.5 207 214)"/>', "cut"),
        (f'<rect x="408" y="131" width="392" height="640" rx="42" fill="{p["card_front"]}" '
         f'transform="rotate(13 408 131)"/>', "cut"),
    ]
    for svg, role in cards:
        out.append((svg, role, svg))

    ace = (f'<path fill="{p["ink"]}" stroke="{p["ink"]}" stroke-width="5" stroke-linejoin="round" '
           f'fill-rule="evenodd" transform="translate(430,186) rotate(13) scale(0.93)" '
           f'd="M0,88 L38,0 L60,0 L84,88 L62,88 L58,68 L28,68 L20,88Z M35,50 L55,50 L49,20Z"/>')
    spade = (f'<path fill="{p["ink"]}" transform="translate(499,432) rotate(14) scale(1.04)" '
             f'd="M0,-122 C30,-70 100,-35 100,28 C100,78 38,96 8,56 C12,85 25,105 42,116 '
             f'L-42,116 C-25,105 -12,85 -8,56 C-38,96 -100,78 -100,28 C-100,-35 -30,-70 0,-122Z"/>')
    out.append((ace, "knock", ace))
    out.append((spade, "knock", spade))

    # the dark keyline stays; the fake drop shadow that sat at translate(8,10) is gone
    line = (f'<g fill="{p["plus_line"]}" stroke="{p["plus_line"]}" stroke-width="82" '
            f'stroke-linejoin="round">{PLUS_INNER}</g>')
    glyph = (f'<g fill="{p["plus_fill"]}" stroke="{p["plus_fill"]}" stroke-width="24" '
             f'stroke-linejoin="round">{PLUS_INNER}</g>')
    out.append((line, "none", None))
    out.append((glyph, "cut",
                f'<g fill="{BLACK}" stroke="{BLACK}" stroke-width="24" '
                f'stroke-linejoin="round">{PLUS_INNER}</g>'))

    body = ('<polygon points="345,602 508,676 526,874 357,1002 172,892 165,712" '
            'fill="{f}" stroke="{f}" stroke-width="46" stroke-linejoin="round"/>')
    out.append((body.format(f=p["die_face"]), "cut", body.format(f=BLACK)))
    for pts in ("166,716 338,794 342,1000 174,894", "368,796 522,686 531,874 370,998"):
        svg = (f'<polygon points="{pts}" fill="{p["die_side"]}" stroke="{p["die_side"]}" '
               f'stroke-width="14" stroke-linejoin="round"/>')
        # in monochrome the two side faces cannot be a different tone, so their
        # edges become hairlines instead — otherwise the die is one flat slab
        mono = (f'<polygon points="{pts}" fill="none" stroke="{BLACK}" stroke-width="16" '
                f'stroke-linejoin="round"/>')
        out.append((svg, "edge", mono))
    for pip in DIE_PIPS:
        svg = pip.format(ink=p["ink"])
        out.append((svg, "knock", svg))

    for i, w in enumerate(PAWNS):
        shade = (f'<g clip-path="url(#{w["cid"]})">'
                 f'<path fill="{p[w["s"]]}" d="{w["clip"]}"/>'
                 f'<circle cx="{w["shx"]}" cy="{w["shy"]}" r="{w["hr"]}" fill="{p[w["s"]]}"/></g>')
        out.append((f'<clipPath id="{w["cid"]}"><path d="{w["body"]}"/></clipPath>'
                    f'<path d="{w["body"]}" fill="{p[w["c"]]}"/>',
                    "solid" if i == 0 else "cut", f'<path d="{w["body"]}"/>'))
        out.append((shade, "none", None))
        out.append((f'<circle cx="{w["hx"]}" cy="{w["hy"]}" r="{w["hr"]}" fill="{p[w["c"]]}"/>',
                    "solid" if i == 0 else "cut",
                    f'<circle cx="{w["hx"]}" cy="{w["hy"]}" r="{w["hr"]}"/>'))
        out.append((f'<path fill="{p[w["h"]]}" transform="translate({w["hlx"]},{w["hly"]}) '
                    f'rotate(48)" d="M-30,0 A30,17 0 0 1 30,0 Q22,14 8,6 Q-8,14 -30,0Z"/>',
                    "none", None))
    return out


# ---------------------------------------------------------------- measuring

def render(svg_text, size, dest):
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, "in.svg")
        with open(src, "w") as fh:
            fh.write(svg_text)
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), src,
                        "-o", dest], check=True)


def measure(body, size=S):
    """The centre and the radius of the drawn ink, read off the rendered alpha.

    Analytic bounds on rotated shapes overstate the subject by about a third,
    which is how 31.2% of it ended up outside the safe circle in the first
    place."""
    with tempfile.TemporaryDirectory() as d:
        png = os.path.join(d, "m.png")
        render(f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" '
               f'height="{size}" viewBox="0 0 {size} {size}">{body}</svg>', size, png)
        a = Image.open(png).convert("RGBA").split()[3]
    box = a.getbbox()
    if box is None:
        raise SystemExit("nothing was drawn")
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    px, r = a.load(), 0.0
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            if px[x, y] > 8:
                r = max(r, ((x - cx) ** 2 + (y - cy) ** 2) ** .5)
    return cx, cy, r


def ink_radius(path):
    """The radius of the non-ground ink in a rendered icon, about its centre.

    Ground-on-ground pixels do not count: what matters for a maskable icon is
    how far the *subject* reaches, not the square it is painted on."""
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    ground = px[1, 1]
    c = w / 2.0
    r = 0.0
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p[3] > 8 and max(abs(p[i] - ground[i]) for i in range(3)) > 24:
                r = max(r, ((x + .5 - c) ** 2 + (y + .5 - c) ** 2) ** .5)
    return r / w  # as a fraction of the image width


# ---------------------------------------------------------------- stage 1

def write_svgs(key):
    p = PALETTES[key]
    ps = parts(p)
    base = S / SRC_VB  # the original canvas is 1254 wide; bring it into ours
    art = "".join(s for s, _, _ in ps)
    raw = f'<g transform="scale({base:.5f})">{art}</g>'
    cx, cy, r = measure(raw)

    def framed(target, inner):
        k = target / r
        return (f'<g transform="translate({S / 2 - cx * k:.1f} {S / 2 - cy * k:.1f}) '
                f'scale({k:.5f})"><g transform="scale({base:.5f})">{inner}</g></g>')

    def wrap(inner, ground=None):
        bg = f'<rect id="bg" width="{S}" height="{S}" fill="{ground}"/>' if ground else ""
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" '
                f'viewBox="0 0 {S} {S}">{bg}<g id="fg">{inner}</g></svg>\n')

    paint = [f'<rect width="{S}" height="{S}" fill="{BLACK}"/>']
    for svg, role, shape in ps:
        if role == "none":
            continue
        if role == "solid":
            paint.append(inked(shape))
        elif role in ("knock", "edge"):
            paint.append(blacked(shape))
        elif role == "cut":
            paint.append(halo(shape))
            paint.append(inked(shape))
    mono_art = framed(SAFE, "".join(paint))

    # The reduced mark: the "+1" alone, and only its gold glyph — the ink
    # keyline that frees it from the cards in the full icon is the colour of the
    # favicon's own ground, so keeping it would only shrink the gold by its own
    # width, which is what a 16 px tab has least of.
    mark = (f'<g fill="{p["plus_fill"]}" stroke="{p["plus_fill"]}" stroke-width="24" '
            f'stroke-linejoin="round">{PLUS_INNER}</g>')
    mraw = f'<g transform="scale({base:.5f})">{mark}</g>'
    mcx, mcy, mr = measure(mraw)
    mk = FAVICON / mr
    favicon = (f'<g transform="translate({S / 2 - mcx * mk:.1f} {S / 2 - mcy * mk:.1f}) '
               f'scale({mk:.5f})"><g transform="scale({base:.5f})">{mark}</g></g>')

    files = {
        "chosen.svg": wrap(framed(DISPLAY, art), p["ground"]),
        "chosen-adaptive-bg.svg": wrap("", p["ground"]),
        "chosen-adaptive-fg.svg": wrap(framed(SAFE, art)),
        "chosen-maskable.svg": wrap(framed(MASKABLE, art), p["ground"]),
        "chosen-favicon.svg": wrap(favicon, p["ground"]),
        "chosen-mono.svg": wrap(
            f'<mask id="m"><rect width="{S}" height="{S}" fill="{BLACK}"/>{mono_art}</mask>'
            f'<rect width="{S}" height="{S}" fill="{BLACK}" mask="url(#m)"/>'),
    }
    os.makedirs(DESIGN, exist_ok=True)
    for name, text in files.items():
        with open(os.path.join(DESIGN, name), "w") as fh:
            fh.write(text)
        print(f"  wrote design/icon/{name}")

    # Measured on the subject alone: the ground is a full-bleed square, and its
    # corners would drown any reading of how far the artwork reaches. `limit` is
    # the radius past which something is really lost — the mask circle, or the
    # canvas edge — not the radius we aimed the framing at.
    checks = (("chosen.svg", DISPLAY, S / 2, "the canvas"),
              ("chosen-adaptive-fg.svg", SAFE, SAFE, "Android's safe circle"),
              ("chosen-maskable.svg", MASKABLE, 0.40 * S, "the PWA 80% circle"),
              ("chosen-favicon.svg", FAVICON, S / 2, "the canvas"))
    for name, target, limit, what in checks:
        with open(os.path.join(DESIGN, name)) as fh:
            text = fh.read()
        body = text[text.index('<g id="fg">'):text.rindex("</svg>")]
        _, _, got = measure(body)
        # +1 px of tolerance: the framing is applied to a measurement taken off
        # an antialiased render, and re-measuring the result costs a pixel.
        verdict = "nothing clipped" if got <= limit + 1 else f"CLIPPED by {what}"
        print(f"  {name:24s} subject r={got:6.1f}  aimed {target:5.0f}  "
              f"limit {limit:5.0f}  {verdict}")


# ---------------------------------------------------------------- stage 2

# source SVG -> (destination, pixel size)
RASTERS = [
    ("chosen.svg", "store_listing/assets/icon_512.png", 512),
    ("chosen-adaptive-fg.svg", "design/icon/adaptive_foreground.png", 1024),
    ("chosen-mono.svg", "design/icon/adaptive_monochrome.png", 1024),
    ("chosen.svg", "web/icons/Icon-192.png", 192),
    ("chosen.svg", "web/icons/Icon-512.png", 512),
    ("chosen-maskable.svg", "web/icons/Icon-maskable-192.png", 192),
    ("chosen-maskable.svg", "web/icons/Icon-maskable-512.png", 512),
    ("chosen-favicon.svg", "web/favicon.png", 64),
]


def rasterize():
    for src, dest, size in RASTERS:
        path = os.path.join(DESIGN, src)
        if not os.path.exists(path):
            raise SystemExit(f"missing vector source {path} — run with --svg first")
        with open(path) as fh:
            svg = fh.read()
        out = os.path.join(ROOT, dest)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        render(svg, size, out)
        print(f"  {dest:42s} {size:>4}px  <- design/icon/{src}")

    # what the PWA promises: a maskable icon keeps its subject inside the
    # circle of 80% of the image, i.e. within a radius of 0.40 of the width.
    for dest in ("web/icons/Icon-maskable-512.png", "web/icons/Icon-maskable-192.png"):
        r = ink_radius(os.path.join(ROOT, dest))
        ok = "ok" if r <= 0.40 else "OUTSIDE THE 80% SAFE CIRCLE"
        print(f"  {dest:42s} subject radius {r:.3f} of the width (<= 0.400) {ok}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--svg", action="store_true",
                    help="rewrite design/icon/*.svg from the geometry in this file")
    ap.add_argument("--palette", default="brand", choices=sorted(PALETTES),
                    help="which palette --svg paints with (default: brand, what ships)")
    ap.add_argument("--no-rasters", action="store_true",
                    help="stop after --svg, write no PNG")
    args = ap.parse_args()

    if args.svg:
        print(f"vector sources ({PALETTES[args.palette]['name']}):")
        write_svgs(args.palette)
    if not args.no_rasters:
        print("rasters:")
        rasterize()
    return 0


if __name__ == "__main__":
    sys.exit(main())
