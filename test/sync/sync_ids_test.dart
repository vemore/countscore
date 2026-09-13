import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/services/sync/sync_ids.dart';

void main() {
  test('uuid5 matches the RFC 4122 / Python uuid.uuid5 vector', () {
    // python3 -c "import uuid; print(uuid.uuid5(uuid.NAMESPACE_DNS, 'python.org'))"
    expect(
      uuid5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'python.org'),
      '886313e1-3b8a-5372-9b90-0c9aee199e5d',
    );
  });

  test('a linked uuid ignores case and surrounding spaces', () {
    const group = '11111111-2222-3333-4444-555555555555';
    expect(
      linkedRemoteUuid(group, 'player', 'Alice'),
      linkedRemoteUuid(group, 'player', ' alice '),
    );
    expect(
      linkedRemoteUuid(group, 'player', 'Alice'),
      isNot(linkedRemoteUuid(group, 'game_type', 'Alice')),
    );
    expect(
      linkedRemoteUuid(group, 'player', 'Alice'),
      isNot(linkedRemoteUuid('99999999-2222-3333-4444-555555555555', 'player', 'Alice')),
    );
  });

  test('player names follow the server allow-list', () {
    expect(isSyncablePlayerName("Zoé O'Brien-Lévy"), isTrue);
    expect(isSyncablePlayerName('Иван 2'), isTrue);
    expect(isSyncablePlayerName('Dr. Who'), isTrue);
    expect(isSyncablePlayerName(''), isFalse);
    expect(isSyncablePlayerName('x' * 33), isFalse);
    expect(isSyncablePlayerName('Bob 🎲'), isFalse);
    expect(isSyncablePlayerName('<script>'), isFalse);
  });

  // Mirrors _MARKED_NAMES / _ORPHAN_MARKS in backend/tests/test_sync.py.
  test('letters carry their combining marks, other characters do not', () {
    for (final name in [
      'रवि', // Devanagari vowel sign (Mc)
      'अर्जुन', // virama (Mn) then a vowel sign
      'अँ', // candrabindu (Mn) straight on a letter
      'محمَّد', // Arabic shadda + fatha, stacked
      'Nguye\u0302\u0303n', // Vietnamese, decomposed
    ]) {
      expect(isSyncablePlayerName(name), isTrue, reason: name);
    }
    for (final name in [
      '\u093f', // a vowel sign with nothing to combine with
      '2\u0301', // after a digit
      'a \u0301', // after a space
      '\u{1f3b2}\u0301', // after a refused character
    ]) {
      expect(isSyncablePlayerName(name), isFalse, reason: name);
    }
  });
}
