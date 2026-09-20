import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/models/game_standing.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

GameAnalysis _makeAnalysis(int gameId, String content, DateTime ts) =>
    GameAnalysis(gameId: gameId, content: content, generatedAt: ts);

void main() {
  late AppDatabase db;
  late DriftGameTypeRepository gameTypeRepo;
  late DriftGameRepository gameRepo;
  late DriftPlayerRepository playerRepo;
  late DriftRoundRepository roundRepo;
  late DriftScoreRepository scoreRepo;
  late DriftPlayerStatsRepository statsRepo;
  late DriftGameAnalysisRepository analysisRepo;

  setUp(() {
    db = _memoryDb();
    gameTypeRepo = DriftGameTypeRepository(db);
    gameRepo = DriftGameRepository(db);
    playerRepo = DriftPlayerRepository(db);
    roundRepo = DriftRoundRepository(db);
    scoreRepo = DriftScoreRepository(db);
    statsRepo = DriftPlayerStatsRepository(db);
    analysisRepo = DriftGameAnalysisRepository(db);
  });

  tearDown(() => db.close());

  // ── GameType ──────────────────────────────────────────────────────────────
  group('GameTypeRepository', () {
    test('create / getAll / getById / update / delete', () async {
      final gt = GameType(
        name: 'TestGame',
        iconCodePoint: 0,
        cardColorValue: 0xFF0000FF,
        isLowestScoreWins: false,
      );
      final id = await gameTypeRepo.create(gt);
      expect(id, greaterThan(0));

      final all = await gameTypeRepo.getAll();
      expect(all.any((t) => t.name == 'TestGame'), isTrue);

      final found = await gameTypeRepo.getById(id);
      expect(found?.name, 'TestGame');

      await gameTypeRepo.update(found!.copyWith(name: 'Updated'));
      expect((await gameTypeRepo.getById(id))?.name, 'Updated');

      await gameTypeRepo.delete(id);
      expect(await gameTypeRepo.getById(id), isNull);
    });

    test('builtinKey round-trips through create, getAll and update', () async {
      // `update` lists its columns by hand, so a new field is silently dropped
      // there and nowhere else.
      // The seed already holds the live 'yahtzee', and a second one is refused
      // (schema v15): take the seeded row out first.
      final seeded = (await gameTypeRepo.getAll()).firstWhere((t) => t.builtinKey == 'yahtzee');
      await gameTypeRepo.delete(seeded.id!);
      final id = await gameTypeRepo.create(GameType(
        builtinKey: 'yahtzee',
        name: 'Yahtzee',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: false,
      ));
      expect((await gameTypeRepo.getById(id))?.builtinKey, 'yahtzee');
      expect(
        (await gameTypeRepo.getAll()).firstWhere((t) => t.id == id).builtinKey,
        'yahtzee',
      );

      final stored = (await gameTypeRepo.getById(id))!;
      await gameTypeRepo.update(stored.copyWith(cardColorValue: 0xFF00FF00));
      expect((await gameTypeRepo.getById(id))?.builtinKey, 'yahtzee');

      // Renaming drops the key: from then on the chosen name is what renders.
      await gameTypeRepo.update(
        stored.copyWith(name: 'Mon Yahtzee', clearBuiltinKey: true),
      );
      final renamed = await gameTypeRepo.getById(id);
      expect(renamed?.builtinKey, isNull);
      expect(renamed?.name, 'Mon Yahtzee');
    });

    test('carries rules and rulesSlug through create, read and update', () async {
      // The repository writes game types by map, so a new column needs no code
      // there — this is the test that proves it, and catches a Drift table that
      // was never regenerated.
      final id = await gameTypeRepo.create(GameType(
        name: 'Skyjo',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: true,
        rulesSlug: 'skyjo',
      ));
      final seeded = await gameTypeRepo.getById(id);
      expect(seeded!.rulesSlug, 'skyjo');
      expect(seeded.rules, isNull, reason: 'shipped rules are not stored');

      await gameTypeRepo.update(seeded.copyWith(rules: 'On joue à 150.'));
      final written = await gameTypeRepo.getById(id);
      expect(written!.rules, 'On joue à 150.');
      expect(written.rulesSlug, 'skyjo');

      await gameTypeRepo.update(written.copyWith(clearRules: true));
      expect((await gameTypeRepo.getById(id))?.rules, isNull,
          reason: 'restoring the shipped rules must write a real NULL');
    });

    test('delete throws if games reference it', () async {
      final gtId = await gameTypeRepo.create(GameType(
        name: 'InUse',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: false,
      ));
      await gameRepo.create(
        Game(name: 'G', isLowestScoreWins: false, gameTypeId: gtId),
      );
      expect(() => gameTypeRepo.delete(gtId), throwsA(isA<Exception>()));
    });

    test('counts the games using a type, and the finished ones', () async {
      final gtId = await gameTypeRepo.create(GameType(
        name: 'Counted',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: false,
      ));
      expect(await gameTypeRepo.countGames(gtId), 0);
      expect(await gameTypeRepo.countFinishedGames(gtId), 0);

      await gameRepo.create(
        Game(name: 'open', isLowestScoreWins: false, gameTypeId: gtId),
      );
      await gameRepo.create(Game(
        name: 'done',
        isLowestScoreWins: false,
        gameTypeId: gtId,
        finishedAt: DateTime(2026, 9, 20),
      ));
      expect(await gameTypeRepo.countGames(gtId), 2);
      expect(await gameTypeRepo.countFinishedGames(gtId), 1,
          reason: 'only a finished game has standings to reverse');

      // The counts are what the screen offers a deletion on, so a tombstoned
      // game must not hold a type hostage either.
      final open = (await gameRepo.getAll()).firstWhere((g) => g.name == 'open');
      await gameRepo.delete(open.id!);
      expect(await gameTypeRepo.countGames(gtId), 1);
    });

    test('an edit through copyWith carries every column the form cannot show',
        () async {
      // The editor builds the saved row with `copyWith`, and `update` writes
      // every column of `toMap()`: a column the dialog does not show must
      // survive an edit of the ones it does.
      final seeded = (await gameTypeRepo.getAll())
          .firstWhere((t) => t.builtinKey == 'zapzap');
      expect(seeded.isDefault, isTrue);
      expect(seeded.rulesSlug, 'zapzap');
      await gameTypeRepo.update(seeded.copyWith(rules: 'On joue à 150.'));
      final stored = (await gameTypeRepo.getById(seeded.id!))!;

      // Every field the dialog shows, changed at once.
      await gameTypeRepo.update(stored.copyWith(
        iconCodePoint: 0xE1A3,
        cardColorValue: 0xFF388E3C,
        isLowestScoreWins: !stored.isLowestScoreWins,
        playerDeadConditionType: PlayerDeadConditionType.under,
        playerDeadThreshold: 42,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 500,
      ));

      final after = (await gameTypeRepo.getById(seeded.id!))!;
      expect(after.rules, 'On joue à 150.');
      expect(after.rulesSlug, 'zapzap');
      expect(after.isDefault, isTrue,
          reason: 'the rules_slug back-fills select on isDefault = 1');
      expect(after.builtinKey, 'zapzap');
      expect(after.playerDeadThreshold, 42);

      // The guard: adding a column to `GameType` without deciding what the
      // editor does with it fails here rather than in a user's database.
      expect(
        after.toMap().keys.toSet(),
        {
          'id',
          'builtin_key',
          'name',
          'iconCodePoint',
          'cardColorValue',
          'isLowestScoreWins',
          'isDefault',
          'playerDeadConditionType',
          'playerDeadThreshold',
          'gameOverConditionType',
          'gameOverThreshold',
          'rules',
          'rules_slug',
        },
        reason: 'a new column must be carried by `copyWith` in '
            'game_types_screen.dart, or deliberately left out',
      );
    });

    test('a condition cleared back to None writes real NULLs', () async {
      final id = await gameTypeRepo.create(GameType(
        name: 'Conditioned',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 500,
      ));
      final stored = (await gameTypeRepo.getById(id))!;
      await gameTypeRepo.update(stored.copyWith(
        clearPlayerDeadCondition: true,
        clearGameOverCondition: true,
      ));
      final after = (await gameTypeRepo.getById(id))!;
      expect(after.playerDeadConditionType, isNull);
      expect(after.playerDeadThreshold, isNull);
      expect(after.gameOverConditionType, isNull);
      expect(after.gameOverThreshold, isNull);
    });
  });

  // ── Full game lifecycle ───────────────────────────────────────────────────
  group('Full game lifecycle', () {
    late int gameId;

    setUp(() async {
      gameId = await gameRepo.create(
        Game(name: 'Partie test', isLowestScoreWins: false),
      );
    });

    test('getAll / getById / update', () async {
      final all = await gameRepo.getAll();
      expect(all.any((g) => g.id == gameId), isTrue);

      final g = await gameRepo.getById(gameId);
      expect(g?.name, 'Partie test');

      await gameRepo.update(g!.copyWith(name: 'Renommée'));
      expect((await gameRepo.getById(gameId))?.name, 'Renommée');
    });

    test('finishedAt round-trips through create, update and reopen', () async {
      // A new game is open.
      expect((await gameRepo.getById(gameId))?.finishedAt, isNull);
      expect((await gameRepo.getById(gameId))?.isFinished, isFalse);

      // Finishing it survives the write. `update` lists its columns by hand, so
      // a field it forgets is dropped here and nowhere else.
      final at = DateTime(2026, 9, 16, 21, 30);
      await gameRepo
          .update((await gameRepo.getById(gameId))!.copyWith(finishedAt: at));
      final finished = await gameRepo.getById(gameId);
      expect(finished?.finishedAt, at);
      expect(finished?.isFinished, isTrue);

      // And reopening clears it — `copyWith` alone cannot express that.
      await gameRepo.update(finished!.copyWith(clearFinishedAt: true));
      expect((await gameRepo.getById(gameId))?.finishedAt, isNull);
    });

    test('a game created already finished keeps its finishedAt', () async {
      final at = DateTime(2026, 9, 16, 22);
      final id = await gameRepo.create(
        Game(name: 'Déjà finie', isLowestScoreWins: false, finishedAt: at),
      );
      expect((await gameRepo.getById(id))?.finishedAt, at);
    });

    test('same player name in two games → one global player', () async {
      final g2 = await gameRepo.create(
        Game(name: 'G2', isLowestScoreWins: false),
      );
      await playerRepo.create(
        Player(gameId: gameId, name: 'Alice', orderIndex: 0),
      );
      await playerRepo.create(
        Player(gameId: g2, name: 'Alice', orderIndex: 0),
      );

      final names = await playerRepo.getAllNames();
      expect(names.where((n) => n == 'Alice').length, 1);
    });

    test('scores upsert and retrieve', () async {
      final pId = await playerRepo.create(
        Player(gameId: gameId, name: 'Bob', orderIndex: 0),
      );
      final rId = await roundRepo.create(
        Round(gameId: gameId, roundNumber: 1),
      );

      await scoreRepo.upsert(Score(playerId: pId, roundId: rId, value: 42));
      expect((await scoreRepo.getByPlayerAndRound(pId, rId))?.value, 42);

      await scoreRepo.upsert(Score(playerId: pId, roundId: rId, value: 99));
      expect((await scoreRepo.getByPlayerAndRound(pId, rId))?.value, 99);
    });

    test('deleteGame cascades rounds, scores, game_players', () async {
      final pId = await playerRepo.create(
        Player(gameId: gameId, name: 'Carol', orderIndex: 0),
      );
      final rId = await roundRepo.create(
        Round(gameId: gameId, roundNumber: 1),
      );
      await scoreRepo.create(Score(playerId: pId, roundId: rId, value: 10));

      await gameRepo.delete(gameId);
      expect(await gameRepo.getById(gameId), isNull);
      expect(await roundRepo.getByGame(gameId), isEmpty);
      expect(await scoreRepo.getByPlayer(pId), isEmpty);
    });
  });

  // ── PlayerStats ───────────────────────────────────────────────────────────
  group('PlayerStatsRepository', () {
    test('finished results place the players of each game', () async {
      // G1: Alice(10) beats Bob(5)
      final g1 = await gameRepo.create(
        Game(
          name: 'G1',
          isLowestScoreWins: false,
          finishedAt: DateTime(2026, 9, 1),
        ),
      );
      final a1 = await playerRepo.create(
        Player(gameId: g1, name: 'Alice', orderIndex: 0),
      );
      final b1 = await playerRepo.create(
        Player(gameId: g1, name: 'Bob', orderIndex: 1),
      );
      final r1 = await roundRepo.create(Round(gameId: g1, roundNumber: 1));
      await scoreRepo.upsert(Score(playerId: a1, roundId: r1, value: 10));
      await scoreRepo.upsert(Score(playerId: b1, roundId: r1, value: 5));

      // G2: Charlie(8) beats Alice(3)
      final g2 = await gameRepo.create(
        Game(
          name: 'G2',
          isLowestScoreWins: false,
          finishedAt: DateTime(2026, 9, 2),
        ),
      );
      final a2 = await playerRepo.create(
        Player(gameId: g2, name: 'Alice', orderIndex: 0),
      );
      final c2 = await playerRepo.create(
        Player(gameId: g2, name: 'Charlie', orderIndex: 1),
      );
      final r2 = await roundRepo.create(Round(gameId: g2, roundNumber: 1));
      await scoreRepo.upsert(Score(playerId: a2, roundId: r2, value: 3));
      await scoreRepo.upsert(Score(playerId: c2, roundId: r2, value: 8));

      final results = await statsRepo.getFinishedGameResults();
      final alice = results.first.participants.first.playerUuid;
      expect(results.where((r) => r.participant(alice) != null), hasLength(2));
      expect(results.where((r) => r.wonBy(alice)), hasLength(1));
    });

    test('finished results: finished and scored games only, live rounds only, '
        'keyed by the global player uuid', () async {
      final finished = await gameRepo.create(Game(
        name: 'F',
        isLowestScoreWins: true,
        finishedAt: DateTime(2026, 9, 1),
      ));
      final a = await playerRepo.create(
        Player(gameId: finished, name: 'Alice', orderIndex: 0),
      );
      final b = await playerRepo.create(
        Player(gameId: finished, name: 'Bob', orderIndex: 1, colorValue: 7),
      );
      final r1 = await roundRepo.create(Round(gameId: finished, roundNumber: 1));
      final r2 = await roundRepo.create(Round(gameId: finished, roundNumber: 2));
      await scoreRepo.upsert(Score(playerId: a, roundId: r1, value: 10));
      await scoreRepo.upsert(Score(playerId: b, roundId: r1, value: 4));
      await scoreRepo.upsert(Score(playerId: a, roundId: r2, value: 1));
      await scoreRepo.upsert(Score(playerId: b, roundId: r2, value: 100));
      await roundRepo.delete(r2);

      // Open: not counted.
      final open = await gameRepo.create(Game(name: 'O', isLowestScoreWins: true));
      final ao = await playerRepo.create(
        Player(gameId: open, name: 'Alice', orderIndex: 0),
      );
      final ro = await roundRepo.create(Round(gameId: open, roundNumber: 1));
      await scoreRepo.upsert(Score(playerId: ao, roundId: ro, value: 3));
      // Finished without a score: not counted.
      final blank = await gameRepo.create(Game(
        name: 'B',
        isLowestScoreWins: true,
        finishedAt: DateTime(2026, 9, 2),
      ));
      await playerRepo.create(Player(gameId: blank, name: 'Alice', orderIndex: 0));

      final results = await statsRepo.getFinishedGameResults();
      expect(results.map((r) => r.gameId), [finished]);
      final game = results.single;
      expect(game.isLowestScoreWins, isTrue);
      expect(game.participants.map((p) => p.name), ['Alice', 'Bob']);
      expect(game.participants.map((p) => p.total), [10, 4]);
      expect(game.participants[1].colorValue, 7);

      final bobUuid = (await db
              .customSelect("SELECT uuid FROM players WHERE name = 'Bob'")
              .getSingle())
          .data['uuid'] as String;
      expect(game.participants[1].playerUuid, bobUuid);
      expect(game.wonBy(bobUuid), isTrue);
    });

    // The two entries closed by feat/elimination-ranking-model: the statistics
    // place a finished elimination game exactly as its standings screen does
    // (`wip/done/2026-09-20-statistics-rank-by-score-while-the-standings-rank-by-elimination.md`).
    test('a finished elimination game is placed by the elimination order, '
        'the same places its standings show', () async {
      // The seeded ZapZap: out above 100, over on the last player standing.
      final typeId = (await gameTypeRepo.getAll())
          .firstWhere((t) => t.builtinKey == 'zapzap')
          .id!;
      final gameId = await gameRepo.create(Game(
        name: 'ZapZap',
        gameTypeId: typeId,
        isLowestScoreWins: true,
        finishedAt: DateTime(2026, 9, 3),
      ));
      // The reproduction of `test/models/game_standing_test.dart`: Alice out
      // in round 1 with 101, Bob in round 4 with 140, Chloé in round 5 with
      // 115, David alone at the end with 50.
      const scores = <String, List<int?>>{
        'Alice': [101, null, null, null, null],
        'Bob': [20, 30, 40, 50, null],
        'Chloé': [10, 20, 30, 25, 30],
        'David': [5, 10, 10, 15, 10],
      };
      final seats = <String, int>{};
      var seat = 0;
      for (final name in scores.keys) {
        seats[name] = await playerRepo.create(
          Player(gameId: gameId, name: name, orderIndex: seat++),
        );
      }
      final rounds = [
        for (var n = 1; n <= 5; n++)
          await roundRepo.create(Round(gameId: gameId, roundNumber: n)),
      ];
      for (final name in scores.keys) {
        for (var i = 0; i < rounds.length; i++) {
          final value = scores[name]![i];
          if (value == null) continue;
          await scoreRepo.upsert(
            Score(playerId: seats[name]!, roundId: rounds[i], value: value),
          );
        }
      }

      final result = (await statsRepo.getFinishedGameResults())
          .firstWhere((r) => r.gameId == gameId);
      expect(result.rule, RankingRule.eliminationOrder);
      expect(result.participants.map((p) => p.total), [101, 140, 115, 50]);
      expect(
        result.participants.map((p) => p.eliminatedAtRound),
        [1, 4, 5, null],
      );

      // The standings screen's own places, built the way `standingOf` does.
      final players = await playerRepo.getByGame(gameId);
      final liveRounds = await roundRepo.getByGame(gameId);
      final byPlayer = <int, Map<int, int>>{};
      for (final player in players) {
        for (final score in await scoreRepo.getByPlayer(player.id!)) {
          (byPlayer[player.id!] ??= {})[score.roundId] = score.value;
        }
      }
      final standing = GameStanding.forGame(
        players: players,
        rounds: liveRounds,
        scoreOf: (p, r) => byPlayer[p]?[r],
        isLowestScoreWins: true,
        isFinished: true,
        gameType: await gameTypeRepo.getById(typeId),
      );
      final statisticsPlaces = {
        for (final p in result.participants) p.name: result.rankOf(p.playerUuid),
      };
      final standingsPlaces = {
        for (final p in players) p.name: standing.ranks[p.id],
      };
      expect(statisticsPlaces, standingsPlaces);
      expect(statisticsPlaces,
          {'Alice': 4, 'Bob': 3, 'Chloé': 2, 'David': 1});
    });

    test('a race to a total, and a game with no type, keep the score order',
        () async {
      // Skyjo has a threshold but ends on the first total to reach it: the
      // elimination order is not its rule, here or on the standings.
      final typeId = (await gameTypeRepo.getAll())
          .firstWhere((t) => t.builtinKey == 'skyjo')
          .id!;
      final raced = await gameRepo.create(Game(
        name: 'Skyjo',
        gameTypeId: typeId,
        isLowestScoreWins: true,
        finishedAt: DateTime(2026, 9, 4),
      ));
      final typeless = await gameRepo.create(Game(
        name: 'Sans type',
        isLowestScoreWins: true,
        finishedAt: DateTime(2026, 9, 5),
      ));
      for (final gameId in [raced, typeless]) {
        final a = await playerRepo.create(
          Player(gameId: gameId, name: 'Alice', orderIndex: 0),
        );
        final b = await playerRepo.create(
          Player(gameId: gameId, name: 'Bob', orderIndex: 1),
        );
        final r = await roundRepo.create(Round(gameId: gameId, roundNumber: 1));
        await scoreRepo.upsert(Score(playerId: a, roundId: r, value: 120));
        await scoreRepo.upsert(Score(playerId: b, roundId: r, value: 10));
      }

      final results = await statsRepo.getFinishedGameResults();
      for (final gameId in [raced, typeless]) {
        final result = results.firstWhere((r) => r.gameId == gameId);
        expect(result.rule, RankingRule.score);
        expect(result.participants.map((p) => p.eliminatedAtRound),
            [null, null]);
        final bob = result.participants[1].playerUuid;
        expect(result.wonBy(bob), isTrue);
      }
    });
  });

  // ── GameAnalysis ──────────────────────────────────────────────────────────
  group('GameAnalysisRepository', () {
    test('upsert creates then replaces; delete clears', () async {
      final gId = await gameRepo.create(
        Game(name: 'G', isLowestScoreWins: false),
      );
      final now = DateTime.now();

      await analysisRepo.upsert(_makeAnalysis(gId, 'first', now));
      expect((await analysisRepo.getByGame(gId))?.content, 'first');

      await analysisRepo.upsert(_makeAnalysis(gId, 'second', now));
      expect((await analysisRepo.getByGame(gId))?.content, 'second');

      await analysisRepo.deleteByGame(gId);
      expect(await analysisRepo.getByGame(gId), isNull);
    });
  });

  // ── v10: fresh Drift schema (the web install path) ─────────────────────────
  test('onCreate builds the v10 sync tables', () async {
    for (final table in ['group_links', 'entity_versions', 'sync_inbox']) {
      await db.customSelect('SELECT COUNT(*) FROM $table').getSingle();
    }
    await db.customStatement(
      "INSERT INTO group_links VALUES ('g', 'player', 'l', 'r')",
    );
    expect(
      () => db.customStatement(
        "INSERT INTO group_links VALUES ('g', 'player', 'l2', 'r')",
      ),
      throwsA(anything),
      reason: 'a remote uuid links to one local row per group and type',
    );
    await db.customSelect(
      'SELECT rejected_at, reject_reason FROM outbox',
    ).get();
    await db.customSelect('SELECT device_id, group_name FROM sync_state').get();
  });

  // ── v10: shared rows are tombstoned, local rows deleted ───────────────────
  group('Soft delete of shared rows', () {
    const group = 'g-1';
    late int gameId;
    late int aliceGp;
    late int bobGp;
    late int roundId;

    Future<void> share(int id) async {
      for (final table in ['games']) {
        await db.customStatement(
            'UPDATE $table SET group_id = ? WHERE id = ?', [group, id]);
      }
      for (final table in ['rounds', 'game_players', 'game_analyses']) {
        await db.customStatement(
            'UPDATE $table SET group_id = ? WHERE gameId = ?', [group, id]);
      }
      await db.customStatement(
          'UPDATE scores SET group_id = ? '
          'WHERE roundId IN (SELECT id FROM rounds WHERE gameId = ?)',
          [group, id]);
    }

    Future<int> count(String table, {bool tombstoned = false}) async {
      final row = await db
          .customSelect('SELECT COUNT(*) AS c FROM $table '
              'WHERE deleted_at IS ${tombstoned ? 'NOT ' : ''}NULL')
          .getSingle();
      return row.data['c'] as int;
    }

    setUp(() async {
      gameId = await gameRepo.create(
        Game(name: 'Partagée', isLowestScoreWins: false),
      );
      aliceGp = await playerRepo
          .create(Player(gameId: gameId, name: 'Alice', orderIndex: 0));
      bobGp = await playerRepo
          .create(Player(gameId: gameId, name: 'Bob', orderIndex: 1));
      roundId = await roundRepo.create(Round(gameId: gameId, roundNumber: 1));
      await scoreRepo.create(Score(playerId: aliceGp, roundId: roundId, value: 10));
      await scoreRepo.create(Score(playerId: bobGp, roundId: roundId, value: 4));
      await analysisRepo.upsert(_makeAnalysis(gameId, 'analyse', DateTime.now()));
      await share(gameId);
    });

    test('deleting a shared game tombstones it and everything under it', () async {
      await gameRepo.delete(gameId);

      expect(await gameRepo.getById(gameId), isNull);
      expect(await gameRepo.getAll(), isEmpty);
      expect(await roundRepo.getByGame(gameId), isEmpty);
      expect(await playerRepo.getByGame(gameId), isEmpty);
      expect(await scoreRepo.getByPlayer(aliceGp), isEmpty);
      expect(await analysisRepo.getByGame(gameId), isNull);

      expect(await count('games', tombstoned: true), 1);
      expect(await count('rounds', tombstoned: true), 1);
      expect(await count('game_players', tombstoned: true), 2);
      expect(await count('scores', tombstoned: true), 2);
      expect(await count('game_analyses', tombstoned: true), 1);
    });

    test('a tombstoned game counts in no statistic', () async {
      expect((await playerRepo.getGameCountsByName())['Alice'], 1);

      await gameRepo.delete(gameId);

      expect((await playerRepo.getGameCountsByName())['Alice'], isNull);
      expect(
        await analysisRepo.getRecentPlayerHistory('Alice'),
        isEmpty,
      );
    });

    test('deleting a shared round tombstones its scores only', () async {
      final round2 = await roundRepo.create(Round(gameId: gameId, roundNumber: 2));
      await share(gameId);

      await roundRepo.delete(roundId);

      expect((await roundRepo.getByGame(gameId)).map((r) => r.id), [round2]);
      expect(await scoreRepo.getByPlayerAndRound(aliceGp, roundId), isNull);
      expect(await count('rounds', tombstoned: true), 1);
      expect(await count('scores', tombstoned: true), 2);
    });

    test('deleting a player from a shared game tombstones the membership', () async {
      await playerRepo.delete(bobGp);

      expect((await playerRepo.getByGame(gameId)).map((p) => p.name), ['Alice']);
      expect(await count('game_players', tombstoned: true), 1);
      expect(await count('scores', tombstoned: true), 1);
    });

    test('deleteByName keeps a player row a shared membership still references',
        () async {
      final localGame = await gameRepo.create(
        Game(name: 'Locale', isLowestScoreWins: false),
      );
      final localBob = await playerRepo
          .create(Player(gameId: localGame, name: 'Bob', orderIndex: 0));

      await playerRepo.deleteByName('Bob');

      expect(await playerRepo.getAllNames(), ['Alice']);
      expect(await playerRepo.getByGame(localGame), isEmpty);
      // The local membership is gone for good, the shared one is a tombstone.
      final rows = await db
          .customSelect('SELECT id, deleted_at FROM game_players WHERE name = ?',
              variables: [Variable('Bob')])
          .get();
      expect(rows.map((r) => r.data['id']), [bobGp]);
      expect(rows.single.data['deleted_at'], isNotNull);
      expect(localBob, isNot(bobGp));
      expect(await count('players', tombstoned: true), 1);
    });

    test('a local game is still deleted outright', () async {
      final local = await gameRepo.create(
        Game(name: 'Locale', isLowestScoreWins: false),
      );
      await roundRepo.create(Round(gameId: local, roundNumber: 1));

      await gameRepo.delete(local);

      final rows = await db
          .customSelect('SELECT COUNT(*) AS c FROM games WHERE id = ?',
              variables: [Variable(local)])
          .getSingle();
      expect(rows.data['c'], 0);
      expect(await count('rounds', tombstoned: true), 0);
    });

    test('a game type used only by tombstoned games can be deleted', () async {
      final typeId = await gameTypeRepo.create(GameType(
        name: 'Éphémère',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: false,
      ));
      final g = await gameRepo.create(
        Game(name: 'G', isLowestScoreWins: false, gameTypeId: typeId),
      );
      await share(g);
      await gameRepo.delete(g);

      await gameTypeRepo.delete(typeId);

      expect(await gameTypeRepo.getById(typeId), isNull);
    });
  });
}
