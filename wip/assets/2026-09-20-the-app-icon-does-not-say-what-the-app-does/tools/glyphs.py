"""Turns digits into SVG path data using the app's own bundled Nunito.

An icon must not depend on a font being installed where it is rendered, so the
numerals ship as outlines. Nunito is what the app itself uses
(lib/utils/app_theme.dart, kAppFontFamily), which keeps the icon and the UI in
one voice.
"""
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

FONTS = {
    "extrabold": "/home/vemore/workspace/countscore/assets/fonts/Nunito-ExtraBold.ttf",
    "bold": "/home/vemore/workspace/countscore/assets/fonts/Nunito-Bold.ttf",
}
_cache = {}


def _font(weight):
    if weight not in _cache:
        f = TTFont(FONTS[weight])
        _cache[weight] = (f, f.getGlyphSet(), f.getBestCmap(),
                          f["head"].unitsPerEm,
                          getattr(f["OS/2"], "sCapHeight", None) or int(f["head"].unitsPerEm * .71))
    return _cache[weight]


def text(s, size, cx, cy, fill, weight="extrabold", track=0.0):
    """One <g> of outlines for `s`, optically centred on (cx, cy).

    `size` is the cap height in canvas units, so two calls with the same size
    line their digits up whatever the string. `track` adds letter-spacing as a
    fraction of size. Returns (svg, half_width, half_height)."""
    font, glyphs, cmap, upem, cap = _font(weight)
    scale = size / cap
    extra = track * size / scale  # tracking, back in font units

    advances, names = [], []
    for ch in s:
        name = cmap[ord(ch)]
        names.append(name)
        advances.append(glyphs[name].width + extra)
    total = sum(advances) - extra  # no trailing gap

    parts, x = [], -total / 2
    for name, adv in zip(names, advances):
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        d = pen.getCommands()
        if d:
            parts.append(f'<path d="{d}" transform="translate({x:.1f} 0)"/>')
        x += adv

    body = "".join(parts)
    svg = (f'<g fill="{fill}" transform="translate({cx} {cy + size / 2}) '
           f'scale({scale:.5f} {-scale:.5f})">{body}</g>')
    return svg, total * scale / 2, size / 2
