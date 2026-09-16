// Marking a game finished, and what the review prompt is told about it.
//
// `setGameFinished` returns true only for the transition that actually finishes
// a game, because that return is the single gate on the Play review sheet: a
// user who finishes, reopens and finishes again in one evening must count once.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  late AppDatabase db;
  late GameProvider provider;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    provider = GameProvider(
      gameRepo: DriftGameRepository(db),
      playerRepo: DriftPlayerRepository(db),
      roundRepo: DriftRoundRepository(db),
      scoreRepo: DriftScoreRepository(db),
      gameTypeRepo: DriftGameTypeRepository(db),
      statsRepo: DriftPlayerStatsRepository(db),
    );
  });

  tearDown(() => db.close());

  Future<int> aGame() =>
      provider.createGame('Partie', null, false, ['Alice', 'Bob'], null);

  test('finishing reports the transition, re-finishing does not', () async {
    final id = await aGame();
    expect(provider.games.single.isFinished, isFalse);

    expect(await provider.setGameFinished(id, true), isTrue);
    expect(provider.games.single.isFinished, isTrue);

    // Already finished: nothing changed, so the review prompt is not offered
    // a second time.
    expect(await provider.setGameFinished(id, true), isFalse);
    expect(provider.games.single.isFinished, isTrue);
  });

  test('reopening never counts, and finishing again does', () async {
    final id = await aGame();
    await provider.setGameFinished(id, true);

    expect(await provider.setGameFinished(id, false), isFalse);
    expect(provider.games.single.isFinished, isFalse);

    // Reopening a game does not burn the count — a genuinely new finish still
    // reports one.
    expect(await provider.setGameFinished(id, true), isTrue);
  });

  test('reopening an open game is a no-op', () async {
    final id = await aGame();
    expect(await provider.setGameFinished(id, false), isFalse);
    expect(provider.games.single.isFinished, isFalse);
  });

  test('the current game reflects the change without a reload', () async {
    final id = await aGame();
    await provider.loadGame(id);
    expect(provider.currentGame!.isFinished, isFalse);

    await provider.setGameFinished(id, true);
    expect(provider.currentGame!.isFinished, isTrue);

    await provider.setGameFinished(id, false);
    expect(provider.currentGame!.isFinished, isFalse,
        reason: 'copyWith alone cannot null a field; the reopen must clear it');
  });

  test('an unknown game reports nothing', () async {
    expect(await provider.setGameFinished(9999, true), isFalse);
  });
}
