#!/usr/bin/env python3
"""Third round: the game-pieces ensemble — a die, a pawn, cards and a "+1".

Four objects in one icon breaks the one-idea rule the shelf rewards, so the
whole problem is keeping each silhouette separate enough to survive 48 px.
Two compositions try it two ways: E1 parks one object per quadrant so nothing
overlaps, E2 leads with a dominant "+1" and puts the pieces on a shelf under it.

D1 and D3 are dropped from consideration: the shelf already has them (Score
Counter by Martin Váňa is a number grid, Score Counter – For any game is cards
with a "+1").
"""
import sys
sys.path.insert(0, ".")
from glyphs import text as glyph_text

S = 1024
SAFE = 368.0
INK, TEAL, TEAL_L = "#0E1716", "#0E8F88", "#5ED8CF"
GOLD, CREAM, SLATE = "#F2B705", "#F3F8F7", "#B9D6D3"
BLACK = "#000000"
MONO_GAP = 22


class El:
    def __init__(self, svg, reach, mono="solid", halo=None):
        self.svg, self.reach, self.mono, self.halo = svg, reach, mono, halo

    def _paint(self, colour, src=None):
        import re
        return re.sub(r'(fill|stroke)="#[0-9A-Fa-f]{6}"', rf'\1="{colour}"', src or self.svg)

    def inked(self):
        return self._paint("#FFFFFF")

    def cut(self):
        return self._paint(BLACK, self.halo or self.svg)


def _dist(x, y):
    return ((x - S / 2) ** 2 + (y - S / 2) ** 2) ** .5


def rrect(x, y, w, h, fill, rx, mono="solid", tf="", grow=MONO_GAP, off=0.0):
    t = f' transform="{tf}"' if tf else ""
    svg = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"{t}/>'
    halo = (f'<rect x="{x-grow}" y="{y-grow}" width="{w+2*grow}" height="{h+2*grow}" '
            f'rx="{rx+grow}" fill="{BLACK}"{t}/>')
    if tf:
        # rotated: the box can point its half-diagonal in any direction, plus
        # however far the transform then slides it
        cx, cy = x + w / 2, y + h / 2
        reach = _dist(cx, cy) + ((w / 2) ** 2 + (h / 2) ** 2) ** .5 + off
    else:
        reach = 0.0
        for px, py in ((x, y), (x + w, y), (x, y + h), (x + w, y + h)):
            ix = px + (rx if px < S / 2 else -rx)
            iy = py + (rx if py < S / 2 else -rx)
            reach = max(reach, _dist(ix, iy) + rx)
    return El(svg, reach, mono, halo)


def disc(cx, cy, r, fill, mono="solid"):
    return El(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"/>',
              _dist(cx, cy) + r, mono,
              f'<circle cx="{cx}" cy="{cy}" r="{r+MONO_GAP}" fill="{BLACK}"/>')


def shape(d, fill, pts, mono="solid", tf=""):
    t = f' transform="{tf}"' if tf else ""
    return El(f'<path d="{d}" fill="{fill}"{t}/>',
              max(_dist(x, y) for x, y in pts), mono)


def num(s, size, cx, cy, fill, mono="solid"):
    svg, hw, hh = glyph_text(s, size, cx, cy, fill)
    reach = max(_dist(cx + sx * hw, cy + sy * hh) for sx in (-1, 1) for sy in (-1, 1))
    return El(svg, reach, mono)


# --- the pieces -------------------------------------------------------------
def cards(cx, cy, w, h, front=CREAM, back=SLATE):
    """Two cards, fanned. The front one is cut free in monochrome or the pair
    welds into a single blob."""
    rx = w * 0.13
    slide = ((w * 0.12) ** 2 + (h * 0.03) ** 2) ** .5
    return [rrect(cx - w / 2, cy - h / 2, w, h, back, rx, off=slide,
                  tf=f"rotate(-22 {cx} {cy}) translate({-w*0.12:.0f} {h*0.03:.0f})"),
            rrect(cx - w / 2, cy - h / 2, w, h, front, rx, mono="cut",
                  tf=f"rotate(-5 {cx} {cy})")]


def die(cx, cy, size, face=CREAM, pip=INK, tilt=-8):
    """A die, three pips on the diagonal — five would be invisible at 48 px."""
    tf = f"rotate({tilt} {cx} {cy})"
    els = [rrect(cx - size / 2, cy - size / 2, size, size, face, size * 0.2,
                 mono="cut", tf=tf)]
    off, r = size * 0.26, size * 0.135
    for dx, dy in ((-off, -off), (0, 0), (off, off)):
        els.append(El(f'<circle cx="{cx+dx:.0f}" cy="{cy+dy:.0f}" r="{r:.0f}" '
                      f'fill="{pip}" transform="{tf}"/>',
                      _dist(cx + dx, cy + dy) + r, "knock",
                      f'<circle cx="{cx+dx:.0f}" cy="{cy+dy:.0f}" r="{r:.0f}" '
                      f'fill="{BLACK}" transform="{tf}"/>'))
    return els


def pawn(cx, bottom, height, fill=GOLD):
    """A pawn: head, flared body, base. One closed path plus the head."""
    u = height / 100.0
    hw_base, hw_neck = 44 * u, 15 * u
    base_t, skirt_t, head_r = bottom - 18 * u, bottom - 56 * u, 21 * u
    head_c = bottom - 78 * u
    d = (f"M {cx-hw_base:.0f} {bottom:.0f} "
         f"L {cx+hw_base:.0f} {bottom:.0f} "
         f"L {cx+hw_base:.0f} {base_t:.0f} "
         f"Q {cx+hw_neck:.0f} {base_t:.0f} {cx+hw_neck:.0f} {skirt_t:.0f} "
         f"L {cx-hw_neck:.0f} {skirt_t:.0f} "
         f"Q {cx-hw_neck:.0f} {base_t:.0f} {cx-hw_base:.0f} {base_t:.0f} Z")
    pts = [(cx - hw_base, bottom), (cx + hw_base, bottom), (cx, skirt_t)]
    return [shape(d, fill, pts),
            disc(cx, head_c, head_r, fill)]


# --- E1 Ensemble, one piece per quadrant ------------------------------------
def e1(ground=INK):
    els = []
    els += cards(372, 366, 160, 214)
    els.append(disc(656, 366, 112, GOLD))
    els.append(num("+1", 92, 656, 366, INK, mono="knock"))
    els += die(372, 658, 206)
    els += pawn(656, 748, 200)
    return els, ground


# --- E3 Ensemble carré, the "+1" bare instead of badged ---------------------
# In E1 the badge survives 48 px but the "+1" inside it does not; set in bare
# gold it can be half again as large in the same quadrant.
def e3(ground=INK):
    els = []
    els += cards(372, 366, 160, 214)
    els.append(num("+1", 140, 660, 366, GOLD))
    els += die(372, 658, 206)
    els += pawn(656, 748, 200)
    return els, ground


# --- E2 Ensemble, the "+1" leading and the pieces on a shelf ----------------
def e2(ground=TEAL):
    els = [num("+1", 170, 512, 340, GOLD)]
    els += cards(330, 640, 140, 190)
    els += die(512, 652, 180)
    els += pawn(686, 738, 190)
    els.append(rrect(292, 758, 440, 22, CREAM, 11))
    return els, ground


CANDIDATES = {
    "e1": ("Ensemble carré", lambda: e1(INK)),
    "e1t": ("Ensemble carré, teal", lambda: e1(TEAL)),
    "e3": ("Ensemble carré, +1 nu", lambda: e3(INK)),
    "e3t": ("Ensemble carré, +1 nu, teal", lambda: e3(TEAL)),
    "e2": ("Ensemble aligné", lambda: e2(TEAL)),
    "e2i": ("Ensemble aligné, encre", lambda: e2(INK)),
}


def wrap(body, bg=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" '
            f'viewBox="0 0 {S} {S}">{bg}<g id="fg">{body}</g></svg>\n')


def mono_svg(els, key):
    paint = [f'<rect width="{S}" height="{S}" fill="{BLACK}"/>']
    for e in els:
        if e.mono == "solid":
            paint.append(e.inked())
        elif e.mono == "knock":
            paint.append(e.cut())
        elif e.mono == "cut":
            paint.append(e.cut())
            paint.append(e.inked())
    return wrap(f'<mask id="m-{key}">{"".join(paint)}</mask>'
                f'<rect width="{S}" height="{S}" fill="{BLACK}" mask="url(#m-{key})"/>')


def main():
    for key, (label, fn) in CANDIDATES.items():
        els, ground = fn()
        body = "".join(e.svg for e in els)
        reach = max(e.reach for e in els)
        print(f"{key:4s} {label:22s} reach r={reach:6.1f}/{SAFE:.0f}  "
              f"{'OK' if reach <= SAFE else f'OVER by {reach-SAFE:.0f}'}")
        bg = f'<rect id="bg" width="{S}" height="{S}" fill="{ground}"/>'
        open(f"{key}.svg", "w").write(wrap(body, bg))
        open(f"{key}-mono.svg", "w").write(mono_svg(els, key))
        open(f"{key}-adaptive-bg.svg", "w").write(wrap("", bg))
        open(f"{key}-adaptive-fg.svg", "w").write(wrap(
            f'<g transform="translate({S/2} {S/2}) scale(0.92) translate({-S/2} {-S/2})">'
            f'{body}</g>'))


if __name__ == "__main__":
    main()
