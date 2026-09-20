// The closed sets the game-type editor offers: every seeded icon must be
// reachable, and every palette colour must keep the type's icon legible in both
// themes.
// wip/done/2026-09-20-the-game-type-editor-leaks-its-controllers-and-validates-nothing.md

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/utils/game_type_appearance.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color colour) {
  double channel(double component) => component <= 0.03928
      ? component / 12.92
      : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// [foreground] laid over [background] at [alpha] — the tinted card a game
/// type's icon is actually drawn on.
Color _composite(Color foreground, Color background, double alpha) {
  double mix(double a, double b) => (a * alpha + b * (1 - alpha)) * 255;
  return Color.fromARGB(
    255,
    mix(foreground.r, background.r).round(),
    mix(foreground.g, background.g).round(),
    mix(foreground.b, background.b).round(),
  );
}

void main() {
  group('kGameTypeIcons', () {
    test('holds every icon the built-in types are seeded with', () {
      final offered = kGameTypeIcons.map((i) => i.codePoint).toSet();
      final missing = GameType.defaultGameTypes()
          .where((t) => !offered.contains(t.iconCodePoint))
          .map((t) => '${t.builtinKey} (${t.iconCodePoint})')
          .toList();
      expect(
        missing,
        isEmpty,
        reason: 'a seeded icon the picker cannot reach makes changing that '
            "type's icon a one-way door",
      );
    });

    test('offers each icon once', () {
      final codePoints = kGameTypeIcons.map((i) => i.codePoint).toList();
      expect(codePoints.toSet().length, codePoints.length);
    });
  });

  group('kGameTypePalette', () {
    test('every swatch stays legible on both themes, tint included', () {
      for (final colour in kGameTypePalette) {
        for (final background in kGameTypeColorBackgrounds) {
          // Plain surface, and the two tints the icon is drawn over:
          // `game_types_screen.dart` (0.1) and `game_type_tile_grid.dart` (0.15).
          for (final alpha in const [0.0, 0.10, 0.15]) {
            final drawnOn = _composite(colour, background, alpha);
            expect(
              _contrast(colour, drawnOn),
              greaterThanOrEqualTo(kGameTypeColorMinContrast),
              reason:
                  '0x${colour.toARGB32().toRadixString(16)} on 0x${background.toARGB32().toRadixString(16)} '
                  'tinted at $alpha',
            );
          }
        }
      }
    });

    test('offers each colour once, all fully opaque', () {
      final values = kGameTypePalette.map((c) => c.toARGB32()).toList();
      expect(values.toSet().length, values.length);
      expect(kGameTypePalette.every((c) => c.a == 1.0), isTrue);
    });
  });
}
