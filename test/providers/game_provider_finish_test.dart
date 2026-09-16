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

  // The round count is what tells the game list which games were actually
  // played: "Finish" is offered on a game with a round, or on one already
  // finished, and on nothing else. The list needs every card's count at once,
  // so it comes from one grouped query rather than one per card.
  group('round counts', () {
    test('loadGames counts every game in one pass', () async {
      final empty = await aGame();
      final played = await aGame();

      await provider.loadGame(played);
      await provider.addRound();
      await provider.addRound();

      await provider.loadGames();
      expect(provider.roundCountOf(empty), 0);
      expect(provider.roundCountOf(played), 2);
    });

    test('an unknown game counts zero rather than throwing', () {
      expect(provider.roundCountOf(9999), 0);
    });

    test('adding and deleting a round keep the count in step', () async {
      final id = await aGame();
      await provider.loadGame(id);
      expect(provider.roundCountOf(id), 0);

      // No reload in between: the game list is rebuilt by the same
      // notifyListeners, so a stale count would show a stale menu.
      await provider.addRound();
      expect(provider.roundCountOf(id), 1);

      await provider.deleteRound(provider.currentRounds.single.id!);
      expect(provider.roundCountOf(id), 0);

      // And the database agrees.
      await provider.loadGames();
      expect(provider.roundCountOf(id), 0);
    });

    test('a deleted round is not counted after a reload', () async {
      final id = await aGame();
      await provider.loadGame(id);
      await provider.addRound();
      await provider.addRound();
      await provider.deleteRound(provider.currentRounds.first.id!);

      await provider.loadGames();
      expect(provider.roundCountOf(id), 1,
          reason: 'a tombstoned round must not keep a game "played"');
    });
  });
}
