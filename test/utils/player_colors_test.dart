// Player colours are decided at display time, by seat, and never collide in a
// game: a player's own colour wins unless an earlier seat already shows it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/player.dart';
import 'package:countscore/utils/player_colors.dart';

Player seat(int id, {int? colorValue}) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      orderIndex: id,
      colorValue: colorValue,
    );

void main() {
  test('the palette holds ten distinct colours', () {
    expect(kPlayerPalette.length, 10);
    expect(kPlayerPalette.map((c) => c.toARGB32()).toSet().length, 10);
  });

  test('ten players with no colour get ten distinct colours', () {
    final players = [for (var i = 1; i <= 10; i++) seat(i)];

    final colours = playerColorsById(players);

    expect(colours.length, 10);
    expect(colours.values.map((c) => c.toARGB32()).toSet().length, 10);
    // In palette order, by seat.
    expect(colours[1], kPlayerPalette[0]);
    expect(colours[10], kPlayerPalette[9]);
  });

  test("a player's own colour wins", () {
    const own = 0xFF123456;
    final colours = playerColorsById([seat(1), seat(2, colorValue: own)]);

    expect(colours[2]!.toARGB32(), own);
    expect(colours[1], kPlayerPalette[0]);
  });

  test('a duplicate colour in one game is reassigned, the earlier seat keeps it',
      () {
    const shared = 0xFF123456;
    final colours = playerColorsById([
      seat(1, colorValue: shared),
      seat(2, colorValue: shared),
      seat(3),
    ]);

    expect(colours[1]!.toARGB32(), shared);
    expect(colours[2]!.toARGB32(), isNot(shared));
    expect(colours.values.map((c) => c.toARGB32()).toSet().length, 3);
  });

  test('a palette colour already owned by a player is not handed out again',
      () {
    final taken = kPlayerPalette[0].toARGB32();
    final colours = playerColorsById([
      seat(1),
      seat(2, colorValue: taken),
    ]);

    expect(colours[2]!.toARGB32(), taken);
    expect(colours[1], kPlayerPalette[1]);
  });

  test('more players than colours repeat the palette rather than fail', () {
    final colours = assignPlayerColors(List<int?>.filled(12, null));

    expect(colours.length, 12);
    expect(colours.take(10).map((c) => c.toARGB32()).toSet().length, 10);
  });

  test('nothing is written: the players are left as they were', () {
    final players = [seat(1), seat(2)];
    playerColorsById(players);
    expect(players.every((p) => p.colorValue == null), isTrue);
  });

  test('Material green and lightGreen in one game resolve to two colours that '
      'do not clash', () {
    final colours = playerColorsById([
      seat(1, colorValue: Colors.green.toARGB32()),
      seat(2, colorValue: Colors.lightGreen.toARGB32()),
    ]);

    // The first seat keeps its own colour; the second takes the palette.
    expect(colours[1]!.toARGB32(), Colors.green.toARGB32());
    expect(kPlayerPalette, contains(colours[2]));
    expect(playerColorsClash(colours[1]!, colours[2]!), isFalse);
  });

  test('a palette colour close to an own colour is skipped', () {
    // Material blue is a near-twin of the palette blue.
    final colours = assignPlayerColors([null, null, Colors.blue.toARGB32()]);

    expect(colours[0], kPlayerPalette[0]);
    expect(colours[1], isNot(kPlayerPalette[1]));
    expect(playerColorsClash(colours[1], colours[2]), isFalse);
  });

  test('no two palette colours clash', () {
    for (var i = 0; i < kPlayerPalette.length; i++) {
      for (var j = i + 1; j < kPlayerPalette.length; j++) {
        expect(playerColorsClash(kPlayerPalette[i], kPlayerPalette[j]), isFalse,
            reason: '$i and $j');
      }
    }
  });

  test('colours already shown elsewhere on the screen are not handed out', () {
    final colours =
        assignPlayerColors([null], alreadyShown: [kPlayerPalette[0]]);
    expect(colours.single, kPlayerPalette[1]);
  });

  test('every palette colour gets an initial with a WCAG contrast of 4.5:1',
      () {
    for (final colour in kPlayerPalette) {
      final text = Color.alphaBlend(onPlayerColor(colour), colour);
      expect(contrastRatio(text, colour), greaterThanOrEqualTo(4.5),
          reason: '$colour');
    }
  });

  test('the initial is white on a dark colour, dark on a light one', () {
    expect(onPlayerColor(const Color(0xFF1E3A8A)), Colors.white);
    expect(onPlayerColor(const Color(0xFFFFEB3B)), Colors.black87);
    expect(onPlayerColor(const Color(0xFFFFF59D)), Colors.black87);
  });
}
