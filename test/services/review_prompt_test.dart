// The guards around the Play in-app review sheet: enough games, a week since
// the first launch, at most once per app version, never twice in a session.
//
// The platform channel is never touched — `ReviewRequester` is the seam, and
// the fake below records what the service would have asked Play to do.
//
// The game count is not stored by the service: it is the number of games whose
// `finishedAt` is set, read from `GameRepository`. The guard tests use a fake
// repository that holds that number; the last group runs the real Drift
// repository behind `GameProvider`, where undo and reopen happen.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/repositories/game_repository.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/review_prompt.dart';

/// Only the count is read by the service; everything else is unused here.
class _FakeGames implements GameRepository {
  int finished = 0;

  @override
  Future<int> countFinished() async => finished;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequester implements ReviewRequester {
  _FakeRequester({this.available = true});

  final bool available;
  int availabilityChecks = 0;
  int requests = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<void> requestReview() async => requests++;
}

/// A clock the tests move by hand. Starts on the install date, so
/// `recordFirstLaunch` stamps that instant and `advance` ages the install.
class _Clock {
  DateTime value = DateTime(2026, 1, 1, 12);

  DateTime call() => value;

  void advance(Duration d) => value = value.add(d);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Clock clock;
  late _FakeGames games;

  ReviewPromptService service(
    _FakeRequester requester, {
    String version = '1.1.0',
    GameRepository? repo,
  }) =>
      ReviewPromptService(
        requester: requester,
        currentVersion: () async => version,
        now: clock.call,
        games: repo ?? games,
      );

  /// Finishes [count] games — one more row with `finishedAt` set each time —
  /// and returns whether the last one asked for a review. Each call goes
  /// through the same service instance, as the app does.
  Future<bool> finishGames(ReviewPromptService s, int count) async {
    var asked = false;
    for (var i = 0; i < count; i++) {
      games.finished++;
      asked = await s.onGameFinished();
    }
    return asked;
  }

  setUp(() {
    clock = _Clock();
    games = _FakeGames();
    SharedPreferences.setMockInitialValues({});
  });

  group('recordFirstLaunch', () {
    test('stamps the first launch once and never moves it', () async {
      final s = service(_FakeRequester());
      await s.recordFirstLaunch();
      final prefs = await SharedPreferences.getInstance();
      final stamped = prefs.getString(ReviewPromptService.prefsFirstLaunch);
      expect(stamped, DateTime(2026, 1, 1, 12).toIso8601String());

      clock.advance(const Duration(days: 30));
      await s.recordFirstLaunch();
      expect(prefs.getString(ReviewPromptService.prefsFirstLaunch), stamped);
    });

    test('removes the counter older versions stored', () async {
      SharedPreferences.setMockInitialValues({
        ReviewPromptService.legacyPrefsGamesFinished: 7,
      });
      await service(_FakeRequester()).recordFirstLaunch();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(ReviewPromptService.legacyPrefsGamesFinished),
        isFalse,
      );
    });
  });

  group('onGameFinished', () {
    test('stays quiet below the game threshold, however old the install',
        () async {
      final requester = _FakeRequester();
      final s = service(requester);
      await s.recordFirstLaunch();
      clock.advance(const Duration(days: 365));

      expect(
        await finishGames(s, ReviewPromptService.minGamesFinished - 1),
        isFalse,
      );
      expect(requester.requests, 0);

      // Nothing is stored: the count is whatever the database says.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(ReviewPromptService.legacyPrefsGamesFinished),
        isFalse,
      );
      expect(await finishGames(s, 1), isTrue);
    });

    test('stays quiet below the age threshold, however many games', () async {
      final requester = _FakeRequester();
      final s = service(requester);
      await s.recordFirstLaunch();
      clock.advance(ReviewPromptService.minAge - const Duration(hours: 1));

      expect(await finishGames(s, 10), isFalse);
      expect(requester.requests, 0);
    });

    test('stays quiet when the clock never started', () async {
      // No recordFirstLaunch: an unknown install date is not an old one.
      final requester = _FakeRequester();
      final s = service(requester);
      clock.advance(const Duration(days: 365));

      expect(await finishGames(s, 10), isFalse);
      expect(requester.requests, 0);
    });

    test('asks once when every guard is satisfied, and not again', () async {
      final requester = _FakeRequester();
      final s = service(requester);
      await s.recordFirstLaunch();
      clock.advance(ReviewPromptService.minAge);

      expect(
        await finishGames(s, ReviewPromptService.minGamesFinished),
        isTrue,
      );
      expect(requester.requests, 1);

      // Same session, more games: silence.
      expect(await finishGames(s, 5), isFalse);
      expect(requester.requests, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ReviewPromptService.prefsPromptedVersion),
        '1.1.0',
      );
    });

    test('stays quiet in a new session once this version has asked', () async {
      final first = _FakeRequester();
      final s1 = service(first);
      await s1.recordFirstLaunch();
      clock.advance(ReviewPromptService.minAge);
      expect(
        await finishGames(s1, ReviewPromptService.minGamesFinished),
        isTrue,
      );

      // A restart: fresh instance, same preferences, same version.
      final second = _FakeRequester();
      final s2 = service(second);
      expect(await finishGames(s2, 3), isFalse);
      expect(second.requests, 0);
      expect(second.availabilityChecks, 0);
    });

    test('asks again after the app is updated', () async {
      final first = _FakeRequester();
      final s1 = service(first);
      await s1.recordFirstLaunch();
      clock.advance(ReviewPromptService.minAge);
      expect(
        await finishGames(s1, ReviewPromptService.minGamesFinished),
        isTrue,
      );

      final second = _FakeRequester();
      final s2 = service(second, version: '1.2.0');
      expect(await s2.onGameFinished(), isTrue);
      expect(second.requests, 1);
    });

    test('an unavailable platform does not burn the version', () async {
      final unavailable = _FakeRequester(available: false);
      final s1 = service(unavailable);
      await s1.recordFirstLaunch();
      clock.advance(ReviewPromptService.minAge);

      expect(
        await finishGames(s1, ReviewPromptService.minGamesFinished),
        isFalse,
      );
      expect(unavailable.requests, 0);
      expect(s1.requestedThisSession, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ReviewPromptService.prefsPromptedVersion),
        isNull,
      );

      // A later run on a device that has Play Services can still ask.
      final available = _FakeRequester();
      expect(await service(available).onGameFinished(), isTrue);
      expect(available.requests, 1);
    });
  });

  // The count follows the state: the real repository, behind the provider
  // whose `setGameFinished` the board, the list and the Undo snackbar call.
  group('the count follows the finished games', () {
    late AppDatabase db;
    late GameProvider provider;
    late ReviewPromptService s;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftGameRepository(db);
      provider = GameProvider(
        gameRepo: repo,
        playerRepo: DriftPlayerRepository(db),
        roundRepo: DriftRoundRepository(db),
        scoreRepo: DriftScoreRepository(db),
        gameTypeRepo: DriftGameTypeRepository(db),
        statsRepo: DriftPlayerStatsRepository(db),
      );
      s = service(_FakeRequester(), repo: repo);
    });

    tearDown(() => db.close());

    Future<int> aGame() =>
        provider.createGame('Partie', null, false, ['Alice', 'Bob'], null);

    test('finish then Undo leaves the count where it was', () async {
      final before = await aGame();
      await provider.setGameFinished(before, true);
      expect(await s.finishedGames(), 1);

      final id = await aGame();
      expect(await provider.setGameFinished(id, true), isTrue);
      expect(await s.finishedGames(), 2);
      // The snackbar's Undo is `setGameFinished(id, false)`.
      await provider.setGameFinished(id, false);
      expect(await s.finishedGames(), 1);
    });

    test('finish, reopen, finish counts one game', () async {
      final id = await aGame();
      await provider.setGameFinished(id, true);
      await provider.setGameFinished(id, false);
      await provider.setGameFinished(id, true);
      expect(await s.finishedGames(), 1);
    });

    test('a deleted finished game no longer counts', () async {
      final id = await aGame();
      await provider.setGameFinished(id, true);
      await DriftGameRepository(db).delete(id);
      expect(await s.finishedGames(), 0);
    });

    test('the Undo of a third finish keeps the sheet away', () async {
      await s.recordFirstLaunch();
      clock.advance(ReviewPromptService.minAge);
      for (var i = 0; i < ReviewPromptService.minGamesFinished - 1; i++) {
        await provider.setGameFinished(await aGame(), true);
      }
      final id = await aGame();
      await provider.setGameFinished(id, true);
      await provider.setGameFinished(id, false);
      // Whatever calls the service next, the undone finish is not counted.
      expect(await s.onGameFinished(), isFalse);
    });
  });
}
