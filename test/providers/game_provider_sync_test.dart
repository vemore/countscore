// What the board needs to know when sync removes the game it shows.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  test('a current game deleted by sync is reported once, then forgotten', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final provider = GameProvider(
      gameRepo: DriftGameRepository(db),
      playerRepo: DriftPlayerRepository(db),
      roundRepo: DriftRoundRepository(db),
      scoreRepo: DriftScoreRepository(db),
      gameTypeRepo: DriftGameTypeRepository(db),
      statsRepo: DriftPlayerStatsRepository(db),
    );
    final id = await provider.createGame('Partagée', null, false, ['Alice', 'Bob'], null);
    await provider.loadGame(id);

    // Nothing happened yet.
    await provider.refreshFromSync();
    expect(provider.takeRemotelyDeletedGameName(), isNull);
    expect(provider.currentGame?.id, id);

    // What SyncStore does when a pulled delete arrives.
    await db.customStatement(
        'UPDATE games SET deleted_at = 1, group_id = ? WHERE id = ?', ['g', id]);
    await provider.refreshFromSync();

    expect(provider.currentGame, isNull);
    expect(provider.games, isEmpty);
    expect(provider.takeRemotelyDeletedGameName(), 'Partagée');
    expect(provider.takeRemotelyDeletedGameName(), isNull);
  });
}
