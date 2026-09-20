#!/usr/bin/env python3
"""Second round of CountScore icon candidates.

The first five said "count" or "win" without saying what the app is. The Play
Store's own score-keeper shelf says the category reads one signal above all
others: digits. "+10" (4.8), a 105/254 table (4.7), "1 2 3" (4.6), a 24/19/22
grid (4.4), "100" (4.9), "6|7", "5|4", "2|0", "30/40". So every candidate here
carries numbers, and each takes a deliberately different style.

Two colour findings shape the palette. The shelf's two best-rated apps are both
teal, so a teal ground is the least differentiating choice available; and almost
every competitor sits on a saturated full-bleed tile, which is why CountScore's
white icon vanishes between them. Grounds here are ink, teal, gold and a split.

Monochrome is built by painting a mask in draw order — white adds ink, black
cuts it away — so a shape that reads through a second colour survives as a hole
or as a hairline-separated form instead of welding itself to its neighbour.
"""
import sys
sys.path.insert(0, ".")
from glyphs import text as glyph_text

S = 1024
SAFE = 368.0

INK = "#0E1716"      # scheme.surface, dark
TEAL = "#0E8F88"     # kBrandSeedLight
TEAL_L = "#5ED8CF"   # kBrandSeedDark
GOLD = "#F2B705"     # kLeaderGold
CREAM = "#F3F8F7"    # scheme.surface, light
SLATE = "#B9D6D3"
BLACK = "#000000"
MONO_GAP = 24


class El:
    def __init__(self, svg, reach, mono="solid", halo=None):
        self.svg, self.reach, self.mono, self.halo = svg, reach, mono, halo

    def inked(self):
        import re
        return re.sub(r'(fill|stroke)="#[0-9A-Fa-f]{6}"', r'\1="#FFFFFF"', self.svg)

    def cut(self):
        import re
        return re.sub(r'(fill|stroke)="#[0-9A-Fa-f]{6}"', r'\1="#000000"',
                      self.halo if self.halo else self.svg)


def _corner_reach(x, y, w, h, rx):
    worst = 0.0
    for px, py in ((x, y), (x + w, y), (x, y + h), (x + w, y + h)):
        ix = px + (rx if px < S / 2 else -rx)
        iy = py + (rx if py < S / 2 else -rx)
        worst = max(worst, ((ix - S / 2) ** 2 + (iy - S / 2) ** 2) ** .5 + rx)
    return worst


def rect(x, y, w, h, fill, rx=0, mono="solid", transform=""):
    t = f' transform="{transform}"' if transform else ""
    svg = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"{t}/>'
    g = MONO_GAP
    halo = (f'<rect x="{x - g}" y="{y - g}" width="{w + 2 * g}" height="{h + 2 * g}" '
            f'rx="{rx + g}" fill="{BLACK}"{t}/>') if mono == "cut" else None
    return El(svg, _corner_reach(x, y, w, h, rx), mono, halo)


def circle(cx, cy, r, fill, mono="solid"):
    return El(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"/>',
              ((cx - S / 2) ** 2 + (cy - S / 2) ** 2) ** .5 + r, mono)


def poly(points, fill, mono="solid"):
    d = "M " + " L ".join(f"{x} {y}" for x, y in points) + " Z"
    reach = max(((x - S / 2) ** 2 + (y - S / 2) ** 2) ** .5 for x, y in points)
    return El(f'<path d="{d}" fill="{fill}"/>', reach, mono)


def num(s, size, cx, cy, fill, mono="solid", weight="extrabold", track=0.0):
    svg, hw, hh = glyph_text(s, size, cx, cy, fill, weight, track)
    reach = max(((cx + sx * hw - S / 2) ** 2 + (cy + sy * hh - S / 2) ** 2) ** .5
                for sx in (-1, 1) for sy in (-1, 1))
    return El(svg, reach, mono)


# --- D1 Grid: the score table itself, the way the app's own screen looks -----
def d1():
    els, cols = [], (332, 512, 692)
    for cx, fill in zip(cols, (TEAL_L, CREAM, GOLD)):
        els.append(rect(cx - 70, 250, 140, 60, fill, rx=30))
    for row, (y, vals) in enumerate(((404, ("24", "19", "22")),
                                     (524, ("31", "27", "40")))):
        for cx, v in zip(cols, vals):
            els.append(num(v, 86, cx, y, CREAM))
    els.append(rect(262, 600, 500, 14, GOLD, rx=7))
    for cx, v, fill in zip(cols, ("55", "46", "62"), (CREAM, CREAM, GOLD)):
        els.append(num(v, 94, cx, 686, fill))
    return els, INK


# --- D2 Duel: the two-field scoreboard the shelf keeps proving --------------
def d2():
    bg = [poly([(0, 0), (592, 0), (472, S), (0, S)], TEAL),
          poly([(592, 0), (S, 0), (S, S), (472, S)], GOLD)]
    els = [El('<path d="M 592 0 L 472 1024" stroke="#F3F8F7" stroke-width="26" '
              'fill="none"/>', 300.0),
           num("7", 288, 302, 512, CREAM),
           num("9", 288, 722, 512, INK)]
    return els, bg


# --- D3 Cards: a hand, and the points it just scored ------------------------
def d3():
    back = rect(372, 292, 280, 440, SLATE, rx=36,
                transform="rotate(-16 512 512) translate(-100 18)")
    back.reach = 261 + (100 ** 2 + 18 ** 2) ** .5
    return [back,
            rect(372, 292, 280, 440, CREAM, rx=36, mono="cut"),
            num("+7", 178, 512, 512, TEAL, mono="knock")], TEAL


# --- D4 Notepad: the paper pad the app replaces, and the running total ------
def d4():
    els = [rect(282, 262, 490, 530, SLATE, rx=40),
           rect(266, 246, 490, 530, CREAM, rx=40, mono="cut")]
    for cx in (352, 452, 552, 652):
        els.append(rect(cx - 18, 222, 36, 68, INK, rx=18, mono="cut"))
    for y, w in ((390, 372), (458, 292), (526, 332)):
        els.append(rect(322, y, w, 26, TEAL, rx=13, mono="knock"))
    els.append(rect(322, 598, 372, 14, INK, rx=7, mono="knock"))
    els.append(rect(322, 626, 372, 14, INK, rx=7, mono="knock"))
    els.append(num("128", 112, 512, 702, INK, mono="knock"))
    return els, GOLD


# --- D5 Total: one number, ruled off the way a score sheet ends -------------
def d5():
    return [num("128", 228, 512, 438, GOLD),
            rect(322, 618, 380, 22, CREAM, rx=11),
            rect(322, 662, 380, 22, CREAM, rx=11)], INK


# --- D6 Standings: several players, each with a total, the leader on top ----
def d6():
    els = []
    for i, (fill, dot, val) in enumerate(((GOLD, INK, "62"),
                                          (CREAM, TEAL, "46"),
                                          (CREAM, TEAL, "31"))):
        y = 300 + i * 152
        els.append(rect(232, y, 560, 120, fill, rx=60))
        els.append(circle(316, y + 60, 32, dot, mono="knock"))
        els.append(num(val, 78, 690, y + 60, INK, mono="knock"))
    return els, TEAL


CANDIDATES = {"d1": ("Grille", d1), "d2": ("Duel", d2), "d3": ("Cartes", d3),
              "d4": ("Carnet", d4), "d5": ("Total", d5), "d6": ("Classement", d6)}


def wrap(body, bg=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" '
            f'viewBox="0 0 {S} {S}">{bg}<g id="fg">{body}</g></svg>\n')


def bg_svg(bg):
    if isinstance(bg, str):
        return f'<rect id="bg" width="{S}" height="{S}" fill="{bg}"/>'
    return '<g id="bg">' + "".join(e.svg for e in bg) + '</g>'


def mono_svg(els, key):
    """Paint the mask in draw order: white adds ink, black takes it away."""
    paint = [f'<rect width="{S}" height="{S}" fill="{BLACK}"/>']
    for e in els:
        if e.mono == "solid":
            paint.append(e.inked())
        elif e.mono == "knock":
            paint.append(e.cut())
        elif e.mono == "cut":
            paint.append(e.cut())
            paint.append(e.inked())
    mask = f'<mask id="m-{key}">{"".join(paint)}</mask>'
    return wrap(f'{mask}<rect width="{S}" height="{S}" fill="{BLACK}" '
                f'mask="url(#m-{key})"/>')


def main():
    for key, (label, fn) in CANDIDATES.items():
        els, bg = fn()
        body = "".join(e.svg for e in els)
        reach = max(e.reach for e in els)
        verdict = "OK" if reach <= SAFE else f"OVER by {reach - SAFE:.0f}"
        print(f"{key} {label:11s} reach r={reach:6.1f}/{SAFE:.0f}  {verdict}")

        open(f"{key}.svg", "w").write(wrap(body, bg_svg(bg)))
        open(f"{key}-mono.svg", "w").write(mono_svg(els, key))
        open(f"{key}-adaptive-fg.svg", "w").write(wrap(
            f'<g transform="translate({S/2} {S/2}) scale(0.92) '
            f'translate({-S/2} {-S/2})">{body}</g>'))
        open(f"{key}-adaptive-bg.svg", "w").write(wrap("", bg_svg(bg)))


if __name__ == "__main__":
    main()
