// The keypad shortcut is a closed, validated representation: whatever reaches
// `decode` — a stored row, a pulled delta, a value from a later version — it
// returns a valid shortcut or null, never an exception
// (wip/done/2026-09-18-keypad-has-no-per-game-shortcut.md).

import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game_type.dart';

void main() {
  group('apply', () {
    test('×2 doubles a positive score only', () {
      final double = KeypadShortcut.multiply(2);
      expect(double.apply(12), 24);
      expect(double.apply(0), isNull);
      expect(double.apply(-3), isNull);
      expect(double.movesOn, isFalse);
    });

    test('+50 adds to the score, whatever its sign', () {
      final bingo = KeypadShortcut.add(50);
      expect(bingo.apply(23), 73);
      expect(bingo.apply(0), 50);
      expect(bingo.apply(-60), -10);
    });

    test('a value replaces the score and moves on', () {
      final belote = KeypadShortcut.value(162);
      expect(belote.apply(40), 162);
      expect(belote.movesOn, isTrue);
    });

    test('a result past six digits does nothing', () {
      expect(KeypadShortcut.multiply(10).apply(100000), isNull);
      expect(KeypadShortcut.add(99999).apply(999999), isNull);
    });
  });

  group('labels', () {
    test('are derived from the kind and the number', () {
      expect(KeypadShortcut.value(162).displayLabel, '162');
      expect(KeypadShortcut.value(-2).displayLabel, '−2');
      expect(KeypadShortcut.multiply(2).displayLabel, '×2');
      expect(KeypadShortcut.add(50).displayLabel, '+50');
      expect(KeypadShortcut.add(-5).displayLabel, '−5');
    });

    test('a label of its own wins; a blank or too long one is dropped', () {
      expect(GameType.zapzap().keypadShortcut!.displayLabel, '0 ZapZap');
      expect(
          KeypadShortcut.tryCreate(KeypadShortcutKind.add, 5, label: '  ')!
              .label,
          isNull);
      expect(
          KeypadShortcut.tryCreate(KeypadShortcutKind.add, 5,
                  label: 'x' * (KeypadShortcut.labelMaxLength + 1))!
              .label,
          isNull);
    });
  });

  group('label length', () {
    test('is counted in code points, as the editor and the server count it',
        () {
      final twelve = '😀' * 12; // 24 UTF-16 units, 12 code points
      expect(
          KeypadShortcut.tryCreate(KeypadShortcutKind.value, 1, label: twelve)!
              .label,
          twelve);
      expect(
          KeypadShortcut.tryCreate(KeypadShortcutKind.value, 1,
                  label: '😀' * 13)!
              .label,
          isNull);
    });
  });

  group('bounds', () {
    test('an amount out of its kind\'s bounds is refused', () {
      expect(KeypadShortcut.tryCreate(KeypadShortcutKind.multiply, 1), isNull);
      expect(KeypadShortcut.tryCreate(KeypadShortcutKind.multiply, 11), isNull);
      expect(KeypadShortcut.tryCreate(KeypadShortcutKind.add, 0), isNull);
      expect(KeypadShortcut.tryCreate(KeypadShortcutKind.add, 100000), isNull);
      expect(
          KeypadShortcut.tryCreate(KeypadShortcutKind.value, 1000000), isNull);
      expect(KeypadShortcut.tryCreate(KeypadShortcutKind.value, 0), isNotNull);
    });
  });

  group('decode', () {
    test('reads back what encode wrote', () {
      for (final s in [
        KeypadShortcut.value(0, label: '0 ZapZap'),
        KeypadShortcut.multiply(2),
        KeypadShortcut.add(-5),
      ]) {
        expect(KeypadShortcut.decode(s.encode()), s);
      }
    });

    test('returns null for anything malformed, and never throws', () {
      for (final raw in <Object?>[
        null,
        '',
        'not json',
        '[1, 2]',
        '"multiply"',
        '{}',
        '{"kind":"multiply"}',
        '{"kind":"multiply","amount":"2"}',
        '{"kind":"multiply","amount":2.5}',
        '{"kind":"multiply","amount":1}',
        '{"kind":"divide","amount":2}',
        '{"kind":"add","amount":0}',
        '{"kind":"value","amount":99999999999}',
        42,
      ]) {
        expect(KeypadShortcut.decode(raw), isNull, reason: '$raw');
      }
    });

    test('a label of the wrong type is dropped, the shortcut kept', () {
      expect(KeypadShortcut.decode('{"kind":"add","amount":50,"label":7}'),
          KeypadShortcut.add(50));
    });

    test('GameType.fromMap reads a malformed column as no shortcut', () {
      final map = GameType.skyjo().toMap()..['keypad_shortcut'] = '{oops';
      expect(GameType.fromMap(map).keypadShortcut, isNull);
    });
  });
}
