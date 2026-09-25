import 'dart:convert';

/// What a game type's keypad shortcut does to the score being typed.
enum KeypadShortcutKind {
  /// Enters a fixed score and moves on to the next player (ZapZap's
  /// "0 ZapZap", Belote's 162, Rami's 100).
  value,

  /// Multiplies the score on display, **positive scores only** (Skyjo's ×2 on
  /// the player who closed the round without the strictly lowest score: the
  /// rule doubles a penalty, never a zero or a bonus).
  multiply,

  /// Adds to the score on display (Scrabble's +50 for seven letters).
  add,
}

/// A per-game-type key on the score keypad: a value, or an operation on the
/// value currently typed. A small closed representation, stored in
/// `game_types.keypad_shortcut` as JSON (`{"kind":"multiply","amount":2}`, plus
/// an optional `"label"`) and pushed as-is under the same name.
///
/// Every instance is valid by construction: [tryCreate] and [decode] return
/// null rather than an out-of-range shortcut, and [decode] never throws, so a
/// malformed value pulled from a group, typed by hand or written by a future
/// version shows as "no shortcut" instead of breaking the keypad. The server
/// checks the same bounds (`backend/app/services/delta_bounds.py`).
class KeypadShortcut {
  const KeypadShortcut._(this.kind, this.amount, this.label);

  final KeypadShortcutKind kind;
  final int amount;

  /// What the key reads, when not the derived [defaultLabel]. User content for
  /// a custom type, never translated; the only built-in one is "0 ZapZap", a
  /// digit and a game's name, the same in every locale.
  final String? label;

  /// Inclusive bounds of [amount], per kind. A value is a score the keypad
  /// could type (six digits); a multiplier of 1 or 0 would be a key that does
  /// nothing or erases; an addition of 0 does nothing.
  static const valueMin = -999999;
  static const valueMax = 999999;
  static const multiplyMin = 2;
  static const multiplyMax = 10;
  static const addMin = -99999;
  static const addMax = 99999;

  /// The longest label, in **code points** (`String.runes`): the key is a
  /// quarter of a phone's width. Code points everywhere — here, in the editor's
  /// field and on the server (Python's `len`) — so the three agree on an emoji,
  /// which `maxLength` (grapheme clusters) and `String.length` (UTF-16 units)
  /// would each count differently.
  static const labelMaxLength = 12;

  /// The largest score the keypad holds (six digits, `kKeypadMaxDigits`).
  static const _scoreAbsMax = 999999;

  /// `(min, max)` of [amount] for [kind].
  static (int, int) boundsOf(KeypadShortcutKind kind) => switch (kind) {
        KeypadShortcutKind.value => (valueMin, valueMax),
        KeypadShortcutKind.multiply => (multiplyMin, multiplyMax),
        KeypadShortcutKind.add => (addMin, addMax),
      };

  /// A shortcut, or null when [amount] is out of [kind]'s bounds (or 0 for
  /// [KeypadShortcutKind.add]). A [label] blank or too long is dropped, not
  /// refused: the key then reads its [defaultLabel].
  static KeypadShortcut? tryCreate(
    KeypadShortcutKind kind,
    int amount, {
    String? label,
  }) {
    final (min, max) = boundsOf(kind);
    if (amount < min || amount > max) return null;
    if (kind == KeypadShortcutKind.add && amount == 0) return null;
    final trimmed = label?.trim();
    final kept = trimmed == null ||
            trimmed.isEmpty ||
            trimmed.runes.length > labelMaxLength
        ? null
        : trimmed;
    return KeypadShortcut._(kind, amount, kept);
  }

  /// The built-in seeds; the bounds hold, so these never return null.
  static KeypadShortcut value(int amount, {String? label}) =>
      tryCreate(KeypadShortcutKind.value, amount, label: label)!;
  static KeypadShortcut multiply(int amount) =>
      tryCreate(KeypadShortcutKind.multiply, amount)!;
  static KeypadShortcut add(int amount) =>
      tryCreate(KeypadShortcutKind.add, amount)!;

  /// Reads the stored or pulled form. Null for null, and for anything that is
  /// not exactly a valid shortcut — never an exception.
  static KeypadShortcut? decode(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    final kind = switch (json['kind']) {
      'value' => KeypadShortcutKind.value,
      'multiply' => KeypadShortcutKind.multiply,
      'add' => KeypadShortcutKind.add,
      _ => null,
    };
    final amount = json['amount'];
    if (kind == null || amount is! int) return null;
    final label = json['label'];
    return tryCreate(kind, amount, label: label is String ? label : null);
  }

  /// The stored and pushed form; [decode] reads it back to an equal shortcut.
  String encode() => jsonEncode({
        'kind': kind.name,
        'amount': amount,
        if (label != null) 'label': label,
      });

  /// "162", "−2", "×2", "+50", "−5": symbols and digits, the same in every
  /// locale, like the keypad's own keys.
  String get defaultLabel => switch (kind) {
        KeypadShortcutKind.value => _signed(amount, plus: false),
        KeypadShortcutKind.multiply => '×$amount',
        KeypadShortcutKind.add => _signed(amount, plus: true),
      };

  String get displayLabel => label ?? defaultLabel;

  static String _signed(int n, {required bool plus}) =>
      n < 0 ? '−${n.abs()}' : (plus ? '+$n' : '$n');

  /// Whether the key moves on to the next player: a value is a whole score,
  /// an operation leaves the score on display to be checked.
  bool get movesOn => kind == KeypadShortcutKind.value;

  /// The score after pressing the key on [current], or null when the key does
  /// nothing: a multiplier on a zero or negative score, or a result past six
  /// digits.
  int? apply(int current) {
    final int result;
    switch (kind) {
      case KeypadShortcutKind.value:
        result = amount;
      case KeypadShortcutKind.multiply:
        if (current <= 0) return null;
        result = current * amount;
      case KeypadShortcutKind.add:
        result = current + amount;
    }
    if (result.abs() > _scoreAbsMax) return null;
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is KeypadShortcut &&
      other.kind == kind &&
      other.amount == amount &&
      other.label == label;

  @override
  int get hashCode => Object.hash(kind, amount, label);

  @override
  String toString() => 'KeypadShortcut(${encode()})';
}
