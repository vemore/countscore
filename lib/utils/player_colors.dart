import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player.dart';

/// Player colours, assigned at display time.
///
/// A game's players each get a colour that no other player of the same game
/// shows, decided here every time a screen draws them — never written back to
/// the database. The rule, in seat order:
///
/// 1. a player's own `colorValue` wins, unless an earlier seat of the same game
///    already shows that colour or one too close to tell apart
///    ([playerColorsClash]: Material `green` and `lightGreen` do);
/// 2. everyone else takes the first colour of [kPlayerPalette] that clashes
///    with nothing the game shows yet;
/// 3. past ten distinct colours the palette starts over, by seat.
///
/// Every screen that colours a player goes through [playerColorsById] (or
/// [assignPlayerColors] when it holds colour values rather than players), so
/// the same player has the same colour on the home card, the board and the
/// ranking.

/// Ten colours readable on the light and the dark surface alike, in the order
/// they are handed out. Mid-tone on purpose, so the initial drawn on them is
/// dark on most and white on the darkest two ([onPlayerColor]); no two of
/// them clash ([playerColorsClash]).
const List<Color> kPlayerPalette = [
  Color(0xFFE4572E), // vermilion
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // emerald
  Color(0xFFA855F7), // purple
  Color(0xFFF59E0B), // amber
  Color(0xFFEC4899), // pink
  Color(0xFF0891B2), // cyan
  Color(0xFF65A30D), // olive green
  Color(0xFF9A6B3F), // brown
  Color(0xFF64748B), // slate
];

/// The colour of each seat, from the players' own colour values in seat order
/// (null where a player has none). The result has the same length and order.
///
/// [alreadyShown] are colours other players on the same screen already show:
/// no seat takes one of them, or one that clashes with it, from the palette.
List<Color> assignPlayerColors(
  List<int?> colorValuesInSeatOrder, {
  Iterable<Color> alreadyShown = const [],
}) {
  final result = List<Color?>.filled(colorValuesInSeatOrder.length, null);
  final shown = [...alreadyShown];
  bool free(Color c) => !shown.any((s) => playerColorsClash(s, c));

  // 1. Own colours, first seat first.
  for (var i = 0; i < colorValuesInSeatOrder.length; i++) {
    final own = colorValuesInSeatOrder[i];
    if (own == null) continue;
    final colour = Color(own);
    if (free(colour)) {
      shown.add(colour);
      result[i] = colour;
    }
  }

  // 2. The palette, skipping every colour that clashes with one already shown.
  var next = 0;
  for (var i = 0; i < result.length; i++) {
    if (result[i] != null) continue;
    while (next < kPlayerPalette.length && !free(kPlayerPalette[next])) {
      next++;
    }
    if (next < kPlayerPalette.length) {
      final colour = kPlayerPalette[next++];
      shown.add(colour);
      result[i] = colour;
    } else {
      // 3. More players than distinct colours left: repeat, by seat.
      result[i] = kPlayerPalette[i % kPlayerPalette.length];
    }
  }
  return result.cast<Color>();
}

/// Below this CIEDE2000 distance two player colours read as one on the board.
///
/// Material `green` and `lightGreen` are 10.5 apart, `blue` and `lightBlue`
/// 7.3; the two closest colours of [kPlayerPalette] (blue and slate) are 15.0.
const double kPlayerColorClashDistance = 12;

/// Whether [a] and [b] are too close to tell two players apart: the same
/// colour, or closer than [kPlayerColorClashDistance] (CIEDE2000).
bool playerColorsClash(Color a, Color b) =>
    a.toARGB32() == b.toARGB32() ||
    colorDistance(a, b) < kPlayerColorClashDistance;

/// The CIEDE2000 colour difference between [a] and [b], alpha ignored: about 1
/// is the smallest difference an eye sees, past 20 two colours are plainly
/// different.
double colorDistance(Color a, Color b) {
  final l1 = _lab(a), l2 = _lab(b);
  double rad(double deg) => deg * math.pi / 180;
  double deg(double rad) => rad * 180 / math.pi;
  double pow7(double x) => math.pow(x, 7).toDouble();

  final c1 = math.sqrt(l1[1] * l1[1] + l1[2] * l1[2]);
  final c2 = math.sqrt(l2[1] * l2[1] + l2[2] * l2[2]);
  final cBar = (c1 + c2) / 2;
  final g = 0.5 * (1 - math.sqrt(pow7(cBar) / (pow7(cBar) + pow7(25))));
  final a1 = (1 + g) * l1[1], a2 = (1 + g) * l2[1];
  final c1p = math.sqrt(a1 * a1 + l1[2] * l1[2]);
  final c2p = math.sqrt(a2 * a2 + l2[2] * l2[2]);
  double hue(double b, double a) =>
      (b == 0 && a == 0) ? 0 : (deg(math.atan2(b, a)) + 360) % 360;
  final h1p = hue(l1[2], a1), h2p = hue(l2[2], a2);

  final dL = l2[0] - l1[0];
  final dC = c2p - c1p;
  var dh = 0.0;
  if (c1p * c2p != 0) {
    dh = h2p - h1p;
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
  }
  final dH = 2 * math.sqrt(c1p * c2p) * math.sin(rad(dh / 2));

  final lBar = (l1[0] + l2[0]) / 2;
  final cBarP = (c1p + c2p) / 2;
  double hBar;
  if (c1p * c2p == 0) {
    hBar = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBar = (h1p + h2p) / 2;
  } else {
    hBar = (h1p + h2p + (h1p + h2p < 360 ? 360 : -360)) / 2;
  }
  final t =
      1 -
      0.17 * math.cos(rad(hBar - 30)) +
      0.24 * math.cos(rad(2 * hBar)) +
      0.32 * math.cos(rad(3 * hBar + 6)) -
      0.20 * math.cos(rad(4 * hBar - 63));
  final dTheta = 30 * math.exp(-math.pow((hBar - 275) / 25, 2));
  final rC = 2 * math.sqrt(pow7(cBarP) / (pow7(cBarP) + pow7(25)));
  final sL =
      1 +
      0.015 *
          (lBar - 50) *
          (lBar - 50) /
          math.sqrt(20 + (lBar - 50) * (lBar - 50));
  final sC = 1 + 0.045 * cBarP;
  final sH = 1 + 0.015 * cBarP * t;
  final rT = -math.sin(rad(2 * dTheta)) * rC;
  final l = dL / sL, c = dC / sC, h = dH / sH;
  return math.sqrt(l * l + c * c + h * h + rT * c * h);
}

double _linear(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// CIE L*a*b* (D65) of an sRGB colour.
List<double> _lab(Color c) {
  final r = _linear(c.r), g = _linear(c.g), b = _linear(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double v) =>
      v > 0.008856 ? math.pow(v, 1 / 3).toDouble() : 7.787 * v + 16 / 116;
  final fy = f(y);
  return [116 * fy - 16, 500 * (f(x) - fy), 200 * (fy - f(z))];
}

/// Each player's display colour, keyed by player id (a `game_players.id`).
///
/// [playersInSeatOrder] is one game's players sorted by `orderIndex` — the
/// order `PlayerRepository.getByGame` returns them in. The earlier seat keeps
/// a disputed colour. Players without an id (not stored yet) are skipped.
Map<int, Color> playerColorsById(List<Player> playersInSeatOrder) {
  final colours = assignPlayerColors([
    for (final p in playersInSeatOrder) p.colorValue,
  ]);
  return {
    for (var i = 0; i < playersInSeatOrder.length; i++)
      if (playersInSeatOrder[i].id != null)
        playersInSeatOrder[i].id!: colours[i],
  };
}

/// The WCAG contrast ratio between two opaque colours, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The text or icon colour to draw on [background] — a player's colour: white
/// or near-black, whichever contrasts more (WCAG), so a yellow disc gets a
/// dark initial and a navy one a white initial.
Color onPlayerColor(Color background) {
  final opaque = background.withValues(alpha: 1);
  final dark = Color.alphaBlend(Colors.black87, opaque);
  return contrastRatio(Colors.white, opaque) >= contrastRatio(dark, opaque)
      ? Colors.white
      : Colors.black87;
}
