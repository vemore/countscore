import 'package:flutter/material.dart';

import '../models/player.dart';
import '../utils/player_colors.dart';

/// A player's initial — or first [letters] letters — on their display colour.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 28,
    this.borderColor,
    this.letters = 1,
  });

  final String name;
  final Color color;
  final double size;

  /// How many letters of the name to show: the board shows two ("Li"), so two
  /// players sharing an initial stay apart.
  final int letters;

  /// The ring that separates overlapping avatars — the colour of what they
  /// sit on. None when null.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final chars = trimmed.characters;
    final initial = trimmed.isEmpty
        ? '?'
        : chars.first.toUpperCase() + chars.skip(1).take(letters - 1).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: onPlayerColor(color),
          fontWeight: FontWeight.w800,
          fontSize: size * (letters > 1 ? 0.4 : 0.46),
          height: 1,
        ),
      ),
    );
  }
}

/// A game's players as a row of overlapping avatars, in seat order and in
/// their display colours ([playerColorsById]), with the two letters the board
/// shows ("Li", "La"). Past [maxShown] the rest are summed up as "+N".
class PlayerAvatarStack extends StatelessWidget {
  const PlayerAvatarStack({
    super.key,
    required this.players,
    this.size = 28,
    this.maxShown = 5,
    this.borderColor,
    this.letters = 2,
  });

  /// One game's players, in seat order.
  final List<Player> players;
  final double size;
  final int maxShown;
  final Color? borderColor;

  /// How many letters of each name to show ([PlayerAvatar.letters]).
  final int letters;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return SizedBox(height: size);
    final colours = playerColorsById(players);
    final shown = players.take(maxShown).toList();
    final hidden = players.length - shown.length;
    final step = size * 0.72;
    final ring = borderColor ?? Theme.of(context).cardTheme.color;
    final count = shown.length + (hidden > 0 ? 1 : 0);

    return Semantics(
      label: players.map((p) => p.name).join(', '),
      excludeSemantics: true,
      child: SizedBox(
        height: size,
        width: step * (count - 1) + size,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              PositionedDirectional(
                start: step * i,
                child: PlayerAvatar(
                  name: shown[i].name,
                  color: colours[shown[i].id] ??
                      kPlayerPalette[i % kPlayerPalette.length],
                  size: size,
                  borderColor: ring,
                  letters: letters,
                ),
              ),
            if (hidden > 0)
              PositionedDirectional(
                start: step * shown.length,
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: ring == null
                        ? null
                        : Border.all(color: ring, width: 2),
                  ),
                  child: Text(
                    '+$hidden',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
