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
}
