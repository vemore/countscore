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

  test('the initial is drawn in white on a dark colour, dark on a light one',
      () {
    expect(onPlayerColor(const Color(0xFF3B82F6)), Colors.white);
    expect(onPlayerColor(const Color(0xFFFFF59D)), Colors.black87);
  });
}
