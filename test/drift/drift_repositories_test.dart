import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_analysis.dart';
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
    test('wins and gamesPlayed correct across two games', () async {
      // G1: Alice(10) beats Bob(5)
      final g1 = await gameRepo.create(
        Game(name: 'G1', isLowestScoreWins: false),
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
        Game(name: 'G2', isLowestScoreWins: false),
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

      final stats = await statsRepo.getStatsByName('Alice');
      expect(stats['gamesPlayed'], 2);
      expect(stats['wins'], 1);
    });

    test('unknown player returns zeros', () async {
      final stats = await statsRepo.getStatsByName('Nobody');
      expect(stats['gamesPlayed'], 0);
      expect(stats['wins'], 0);
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
      expect((await statsRepo.getStatsByName('Alice'))['gamesPlayed'], 1);

      await gameRepo.delete(gameId);

      expect((await statsRepo.getStatsByName('Alice'))['gamesPlayed'], 0);
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
