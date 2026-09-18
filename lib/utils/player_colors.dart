import 'package:flutter/material.dart';

import '../models/player.dart';

/// Player colours, assigned at display time.
///
/// A game's players each get a colour that no other player of the same game
/// shows, decided here every time a screen draws them — never written back to
/// the database. The rule, in seat order:
///
/// 1. a player's own `colorValue` wins, unless an earlier seat of the same game
///    already shows that colour;
/// 2. everyone else takes the first colour of [kPlayerPalette] nobody in the
///    game shows yet;
/// 3. past ten distinct colours the palette starts over, by seat.
///
/// Every screen that colours a player goes through [playerColorsById] (or
/// [assignPlayerColors] when it holds colour values rather than players), so
/// the same player has the same colour on the home card, the board and the
/// ranking.

/// Ten colours readable on the light and the dark surface alike, in the order
/// they are handed out. Mid-tone on purpose: a white initial reads on each
/// (see [onPlayerColor] for the text colour to draw on them).
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
List<Color> assignPlayerColors(List<int?> colorValuesInSeatOrder) {
  final result = List<Color?>.filled(colorValuesInSeatOrder.length, null);
  final taken = <int>{};

  // 1. Own colours, first seat first.
  for (var i = 0; i < colorValuesInSeatOrder.length; i++) {
    final own = colorValuesInSeatOrder[i];
    if (own != null && taken.add(own)) {
      result[i] = Color(own);
    }
  }

  // 2. The palette, skipping every colour already shown in this game.
  var next = 0;
  for (var i = 0; i < result.length; i++) {
    if (result[i] != null) continue;
    while (next < kPlayerPalette.length &&
        taken.contains(kPlayerPalette[next].toARGB32())) {
      next++;
    }
    if (next < kPlayerPalette.length) {
      final colour = kPlayerPalette[next++];
      taken.add(colour.toARGB32());
      result[i] = colour;
    } else {
      // 3. More players than distinct colours left: repeat, by seat.
      result[i] = kPlayerPalette[i % kPlayerPalette.length];
    }
  }
  return result.cast<Color>();
}

/// Each player's display colour, keyed by player id (a `game_players.id`).
///
/// [playersInSeatOrder] is one game's players sorted by `orderIndex` — the
/// order `PlayerRepository.getByGame` returns them in. The earlier seat keeps
/// a disputed colour. Players without an id (not stored yet) are skipped.
Map<int, Color> playerColorsById(List<Player> playersInSeatOrder) {
  final colours =
      assignPlayerColors([for (final p in playersInSeatOrder) p.colorValue]);
  return {
    for (var i = 0; i < playersInSeatOrder.length; i++)
      if (playersInSeatOrder[i].id != null)
        playersInSeatOrder[i].id!: colours[i],
  };
}

/// The text or icon colour to draw on [background] — a player's colour.
Color onPlayerColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
