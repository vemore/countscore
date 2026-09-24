// The three types that play to a last survivor — ZapZap, Rami and 6 qui prend,
// the only ones with a `playerDeadConditionType` — are seeded with
// `lastPlayerOver` at the elimination threshold on a fresh database
// (feat/last-player-standing, 2026-09-20). An existing row with no end gets
// the same condition from schema v20: test/migration_v19_to_v20_test.dart.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  test('a fresh database ends ZapZap, Rami and 6 qui prend on the last '
      'player standing', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final types = await DriftGameTypeRepository(db).getAll();

    for (final entry in {'zapzap': 100, 'rami': 100, 'six_nimmt': 65}.entries) {
      final type = types.singleWhere((t) => t.builtinKey == entry.key);
      expect(type.gameOverConditionType, GameOverConditionType.lastPlayerOver,
          reason: entry.key);
      expect(type.gameOverThreshold, entry.value, reason: entry.key);
      expect(type.playerDeadThreshold, entry.value, reason: entry.key);
    }

    // A four-player ZapZap: three past 100 ends it, two does not.
    final zapzap = types.singleWhere((t) => t.builtinKey == 'zapzap');
    expect(zapzap.isGameOver([101, 130, 90, 40]), isFalse);
    expect(zapzap.isGameOver([101, 130, 120, 40]), isTrue);
  });

  test('the types with no automatic end are seeded without one', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final types = await DriftGameTypeRepository(db).getAll();
    for (final key in ['scrabble', 'tarot', 'bridge', 'yahtzee', 'other']) {
      final type = types.singleWhere((t) => t.builtinKey == key);
      expect(type.gameOverConditionType, isNull, reason: key);
      expect(type.gameOverThreshold, isNull, reason: key);
    }
  });
}
