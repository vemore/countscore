// Two devices, one real server. Skipped unless SYNC_BACKEND_URL points at a
// running backend (see .llmwiki/Testing.md, "Group sync against a local
// backend"):
//
//   SYNC_BACKEND_URL=http://127.0.0.1:8000 flutter test test/sync/sync_two_devices_test.dart
//
// Each device is an in-memory database driven by SyncEngine directly — the
// provider's timers and socket add nothing a test can assert on.

@Tags(['integration'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/backend_client.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_engine.dart';
import 'package:countscore/services/sync/sync_store.dart';

final _url = Platform.environment['SYNC_BACKEND_URL'];

class _Device {
  _Device(this.label)
      : db = AppDatabase.forTesting(NativeDatabase.memory()) {
    store = SyncStore(db);
    games = DriftGameRepository(db);
    players = DriftPlayerRepository(db);
    rounds = DriftRoundRepository(db);
    scores = DriftScoreRepository(db);
  }

  final String label;
  final AppDatabase db;
  late final SyncStore store;
  late final DriftGameRepository games;
  late final DriftPlayerRepository players;
  late final DriftRoundRepository rounds;
  late final DriftScoreRepository scores;
  late String token;

  BackendClient get client => BackendClient(_url!);

  Future<void> enter(GroupMembership m) async {
    token = m.deviceToken;
    await store.join(m);
  }

  Future<SyncPassResult> sync() => SyncEngine(store, client, token).run();

  Future<Game> onlyGame() async => (await games.getAll()).single;

  Future<Map<String, int>> totals(int gameId) async {
    final out = <String, int>{};
    final rs = await rounds.getByGame(gameId);
    for (final p in await players.getByGame(gameId)) {
      var total = 0;
      for (final r in rs) {
        total += (await scores.getByPlayerAndRound(p.id!, r.id!))?.value ?? 0;
      }
      out[p.name] = total;
    }
    return out;
  }
}

void main() {
  if (_url == null) {
    test('two devices through a real server', () {},
        skip: 'set SYNC_BACKEND_URL to run against a backend');
    return;
  }

  late _Device a;
  late _Device b;

  setUp(() async {
    a = _Device('A');
    b = _Device('B');
    final created = await a.client.createGroup('Test ${DateTime.now().microsecondsSinceEpoch}', 'A');
    await a.enter(created);
    await b.enter(await b.client.joinGroup(created.shareToken, 'B'));
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a shared game and its scores reach the other device', () async {
    final gameId = await a.games.create(Game(name: 'Mardi', isLowestScoreWins: true, gameTypeId: 1));
    final alice = await a.players.create(Player(gameId: gameId, name: 'Alice', orderIndex: 0, colorValue: 0xFFFFC107));
    final bob = await a.players.create(Player(gameId: gameId, name: 'Bob', orderIndex: 1));
    final r1 = await a.rounds.create(Round(gameId: gameId, roundNumber: 1));
    await a.scores.create(Score(playerId: alice, roundId: r1, value: 10));
    await a.scores.create(Score(playerId: bob, roundId: r1, value: 4));
    await a.store.shareGame(gameId, (await a.store.membership())!.groupId);

    expect((await a.sync()).failure, isNull);
    expect(await a.store.pendingCount(), 0);
    expect((await b.sync()).failure, isNull);

    final onB = await b.onlyGame();
    expect(onB.name, 'Mardi');
    expect(await b.totals(onB.id!), {'Alice': 10, 'Bob': 4});

    // B plays on; A sees it.
    final bPlayers = await b.players.getByGame(onB.id!);
    final r2 = await b.rounds.create(Round(gameId: onB.id!, roundNumber: 2));
    await b.scores.create(Score(playerId: bPlayers[0].id!, roundId: r2, value: 3));
    await b.rounds.updateComment(r2, 'Zap à 3 !');
    expect((await b.sync()).failure, isNull);
    expect((await a.sync()).failure, isNull);
    expect(await a.totals(gameId), {'Alice': 13, 'Bob': 4});
    expect((await a.rounds.getByGame(gameId)).last.comment, 'Zap à 3 !');
  });

  test('the same round entered on both devices is renumbered, nothing lost', () async {
    final gameId = await a.games.create(Game(name: 'Course', isLowestScoreWins: false));
    await a.players.create(Player(gameId: gameId, name: 'Alice', orderIndex: 0));
    await a.store.shareGame(gameId, (await a.store.membership())!.groupId);
    await a.sync();
    await b.sync();
    final onB = await b.onlyGame();

    // Both enter "round 1" offline.
    final aAlice = (await a.players.getByGame(gameId)).single.id!;
    final bAlice = (await b.players.getByGame(onB.id!)).single.id!;
    final ra = await a.rounds.create(Round(gameId: gameId, roundNumber: 1));
    await a.scores.create(Score(playerId: aAlice, roundId: ra, value: 5));
    final rb = await b.rounds.create(Round(gameId: onB.id!, roundNumber: 1));
    await b.scores.create(Score(playerId: bAlice, roundId: rb, value: 7));

    expect((await a.sync()).failure, isNull);
    final bResult = await b.sync();
    expect(bResult.failure, isNull);
    expect(bResult.events.whereType<RoundRenumbered>().single.newNumber, 2);
    await a.sync();

    for (final device in [(a, gameId), (b, onB.id!)]) {
      final rs = await device.$1.rounds.getByGame(device.$2);
      expect(rs.map((r) => r.roundNumber), [1, 2], reason: device.$1.label);
      expect(await device.$1.totals(device.$2), {'Alice': 12}, reason: device.$1.label);
    }
  });

  test('a delete on one device removes the game on the other', () async {
    final gameId = await a.games.create(Game(name: 'Éphémère', isLowestScoreWins: false));
    await a.players.create(Player(gameId: gameId, name: 'Alice', orderIndex: 0));
    await a.store.shareGame(gameId, (await a.store.membership())!.groupId);
    await a.sync();
    await b.sync();
    final onB = await b.onlyGame();

    await b.games.delete(onB.id!);
    await b.sync();
    // A edits the game after the delete: the delete still wins.
    await a.games.update((await a.games.getById(gameId))!.copyWith(name: 'Toujours là ?'));
    await a.sync();
    await b.sync();

    expect(await a.games.getAll(), isEmpty);
    expect(await b.games.getAll(), isEmpty);
  });

  test('players with the same name on both devices become one', () async {
    final aGame = await a.games.create(Game(name: 'A', isLowestScoreWins: false));
    await a.players.create(Player(gameId: aGame, name: 'Chloé', orderIndex: 0));
    final bGame = await b.games.create(Game(name: 'B', isLowestScoreWins: false));
    await b.players.create(Player(gameId: bGame, name: 'chloé', orderIndex: 0));
    await a.store.shareGame(aGame, (await a.store.membership())!.groupId);
    await b.store.shareGame(bGame, (await b.store.membership())!.groupId);

    expect((await a.sync()).failure, isNull);
    expect((await b.sync()).failure, isNull);
    expect((await a.sync()).failure, isNull);

    expect(await a.store.rejectedCount(), 0);
    expect(await b.store.rejectedCount(), 0);
    for (final device in [a, b]) {
      expect(await device.players.getAllNames(), hasLength(1), reason: device.label);
      expect(await device.games.getAll(), hasLength(2), reason: device.label);
      final stats = await DriftPlayerStatsRepository(device.db).getStatsByName('Chloé');
      expect(stats['gamesPlayed'], 2, reason: device.label);
    }
  });

  test('leaving keeps the games as local ones', () async {
    final gameId = await a.games.create(Game(name: 'Gardée', isLowestScoreWins: false));
    await a.players.create(Player(gameId: gameId, name: 'Alice', orderIndex: 0));
    await a.store.shareGame(gameId, (await a.store.membership())!.groupId);
    await a.sync();
    await b.sync();
    final onB = await b.onlyGame();

    final m = (await b.store.membership())!;
    await b.client.revokeDevice(b.token, m.deviceId);
    await b.store.leave(m.groupId);

    expect((await b.onlyGame()).groupId, isNull);
    expect((await b.onlyGame()).id, onB.id);
    expect(
      () => b.client.pull(b.token, 0),
      throwsA(isA<BackendException>().having((e) => e.statusCode, 'status', 401)),
    );
    final outbox = await b.db.customSelect('SELECT COUNT(*) AS c FROM outbox').getSingle();
    expect(outbox.data['c'], 0);
  });
}
