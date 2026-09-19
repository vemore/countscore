// 6 qui prend on a fresh database: the box rule ends the game when a player
// has 66 bull heads, and `PlayerDeadConditionType.over` is strict, so the type
// is seeded with 65 — a player is out on exactly 66, not on 65.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  test('a fresh database puts a 6 qui prend player out on 66, not on 65',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final types = await DriftGameTypeRepository(db).getAll();
    final sixNimmt = types.singleWhere((t) => t.builtinKey == 'six_nimmt');

    expect(sixNimmt.playerDeadThreshold, 65);
    expect(sixNimmt.isEliminated(65), isFalse);
    expect(sixNimmt.isEliminated(66), isTrue);
  });
}
