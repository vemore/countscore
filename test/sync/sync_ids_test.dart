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
}
