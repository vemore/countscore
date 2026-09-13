// The local half of group sync: capture triggers, delta preparation, pulled
// deltas, quarantine, leaving. No network — see sync_two_devices_test.dart for
// the round trip through a real server.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/backend_client.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_ids.dart';
import 'package:countscore/services/sync/sync_store.dart';

const _group = '11111111-1111-4111-8111-111111111111';
const _me = '22222222-2222-4222-8222-222222222222';
const _other = '33333333-3333-4333-8333-333333333333';

PulledDelta _delta(
  String type,
  String uuid,
  int lamport,
  int seq,
  Map<String, dynamic> payload, {
  String op = 'upsert',
  String origin = _other,
}) =>
    (
      entityType: type,
      entityUuid: uuid,
      op: op,
      payload: payload,
      clientLamport: lamport,
      originDeviceId: origin,
      serverSeq: seq,
    );

void main() {
  late AppDatabase db;
  late SyncStore store;
  late DriftGameRepository games;
  late DriftPlayerRepository players;
  late DriftRoundRepository rounds;
  late DriftScoreRepository scores;

  Future<SyncMembership> joined() async {
    await store.join((
      groupId: _group,
      groupName: 'Famille',
      shareToken: 'unused',
      deviceId: _me,
      deviceToken: 'unused',
    ));
    return (await store.membership())!;
  }

  Future<List<Map<String, Object?>>> outbox() async => [
        for (final r in await db
            .customSelect('SELECT * FROM outbox WHERE sent_at IS NULL ORDER BY id')
            .get())
          r.data,
      ];

  /// A local game: Alice and Bob, one round, scores 10 and 4.
  Future<({int game, int alice, int bob, int round})> localGame() async {
    final game = await games.create(Game(name: 'Mardi', isLowestScoreWins: true, gameTypeId: 1));
    final alice = await players.create(Player(gameId: game, name: 'Alice', orderIndex: 0));
    final bob = await players.create(Player(gameId: game, name: 'Bob', orderIndex: 1));
    final round = await rounds.create(Round(gameId: game, roundNumber: 1));
    await scores.create(Score(playerId: alice, roundId: round, value: 10));
    await scores.create(Score(playerId: bob, roundId: round, value: 4));
    return (game: game, alice: alice, bob: bob, round: round);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SyncStore(db);
    games = DriftGameRepository(db);
    players = DriftPlayerRepository(db);
    rounds = DriftRoundRepository(db);
    scores = DriftScoreRepository(db);
  });

  tearDown(() => db.close());

  group('capture', () {
    test('a local game writes nothing to the outbox', () async {
      await localGame();
      expect(await outbox(), isEmpty);
    });

    test('sharing a game captures the game and everything under it', () async {
      final m = await joined();
      final g = await localGame();

      await store.shareGame(g.game, m.groupId);

      final captured = (await outbox()).map((r) => r['entity_type']).toList();
      expect(captured.where((t) => t == 'game'), hasLength(1));
      expect(captured.where((t) => t == 'game_player'), hasLength(2));
      expect(captured.where((t) => t == 'round'), hasLength(1));
      expect(captured.where((t) => t == 'score'), hasLength(2));
    });

    test('rows added to a shared game join its group and are captured', () async {
      final m = await joined();
      final g = await localGame();
      await store.shareGame(g.game, m.groupId);
      await db.customStatement('DELETE FROM outbox');

      final round2 = await rounds.create(Round(gameId: g.game, roundNumber: 2));
      await scores.create(Score(playerId: g.alice, roundId: round2, value: 7));

      final row = await db
          .customSelect('SELECT group_id FROM scores WHERE roundId = ?', variables: [Variable(round2)])
          .getSingle();
      expect(row.data['group_id'], _group);
      expect((await outbox()).map((r) => r['entity_type']), containsAll(['round', 'score']));
    });

    test('deleting a shared round is captured as a delete', () async {
      final m = await joined();
      final g = await localGame();
      await store.shareGame(g.game, m.groupId);
      await db.customStatement('DELETE FROM outbox');

      await rounds.delete(g.round);

      final ops = {for (final r in await outbox()) '${r['entity_type']}': r['op']};
      expect(ops, {'round': 'delete', 'score': 'delete'});
    });
  });

  group('preparePush', () {
    test('links players by name, orders parents first, stamps lamports once', () async {
      final m = await joined();
      final g = await localGame();
      await store.shareGame(g.game, m.groupId);
      await games.update((await games.getById(g.game))!.copyWith(name: 'Mardi soir'));

      final deltas = await store.preparePush(m);

      expect(deltas.map((d) => d.entityType).toList(), [
        'game_type', 'player', 'player', 'game', 'game_player', 'game_player', //
        'round', 'score', 'score',
      ]);
      // Two writes to the game became one delta, built from the current row.
      final game = deltas.firstWhere((d) => d.entityType == 'game');
      expect(game.payload['name'], 'Mardi soir');
      expect(game.payload['is_lowest_score_wins'], isTrue);

      final alice = deltas.firstWhere((d) => d.payload['name'] == 'Alice');
      expect(alice.entityUuid, linkedRemoteUuid(_group, 'player', 'alice'));
      expect(alice.payload['name_normalized'], 'alice');

      final score = deltas.firstWhere((d) => d.entityType == 'score' && d.payload['value'] == 10);
      expect(score.payload['player_id'], alice.entityUuid,
          reason: 'a score names the group player, not the per-game membership');

      final lamports = deltas.map((d) => d.lamport).toSet();
      expect(lamports, hasLength(deltas.length));

      // A retry before the server answered resends the very same deltas.
      final again = await store.preparePush((await store.membership())!);
      expect(again.map((d) => (d.outboxId, d.lamport)), deltas.map((d) => (d.outboxId, d.lamport)));
    });

    test('a player whose name the server refuses is rejected, not sent', () async {
      final m = await joined();
      final game = await games.create(Game(name: 'G', isLowestScoreWins: false));
      await players.create(Player(gameId: game, name: 'Bob 🎲', orderIndex: 0));

      expect(await store.unsyncablePlayerNames(game), ['Bob 🎲']);

      // Shared anyway (the provider refuses first; the store must still hold).
      await store.shareGame(game, m.groupId);
      final deltas = await store.preparePush(m);
      expect(deltas.where((d) => d.entityType == 'player'), isEmpty);
      expect(await store.rejectedCount(), 1);
    });
  });

  group('applyPulled', () {
    Future<void> pullGameFromOther(SyncMembership m, {String aliceName = 'Alice'}) async {
      await store.applyPulled(m, [
        _delta('player', 'aaaaaaaa-0000-4000-8000-000000000001', 1, 1,
            {'name': aliceName, 'name_normalized': normalizeName(aliceName), 'color_value': 0xFFFF0000}),
        _delta('game', 'aaaaaaaa-0000-4000-8000-000000000002', 2, 2,
            {'name': 'Chez Bob', 'is_lowest_score_wins': false, 'started_at': '2026-09-13T18:00:00Z'}),
        _delta('game_player', 'aaaaaaaa-0000-4000-8000-000000000003', 3, 3, {
          'game_id': 'aaaaaaaa-0000-4000-8000-000000000002',
          'player_id': 'aaaaaaaa-0000-4000-8000-000000000001',
          'order_index': 0,
        }),
        _delta('round', 'aaaaaaaa-0000-4000-8000-000000000004', 4, 4,
            {'game_id': 'aaaaaaaa-0000-4000-8000-000000000002', 'round_number': 1, 'comment': 'Zap !'}),
        _delta('score', 'aaaaaaaa-0000-4000-8000-000000000005', 5, 5, {
          'round_id': 'aaaaaaaa-0000-4000-8000-000000000004',
          'player_id': 'aaaaaaaa-0000-4000-8000-000000000001',
          'value': 12,
        }),
      ], 5);
    }

    test('a game from another device lands complete, and is not sent back', () async {
      final m = await joined();
      await pullGameFromOther(m);

      final all = await games.getAll();
      expect(all.single.name, 'Chez Bob');
      expect(all.single.groupId, _group);
      final gp = await players.getByGame(all.single.id!);
      expect(gp.single.name, 'Alice');
      final rs = await rounds.getByGame(all.single.id!);
      expect(rs.single.comment, 'Zap !');
      expect((await scores.getByPlayerAndRound(gp.single.id!, rs.single.id!))?.value, 12);

      expect(await outbox(), isEmpty, reason: 'applied under suppression');
      expect((await store.membership())!.lastServerSeq, 5);
      expect((await store.membership())!.lastLamport, 5);
    });

    test('a pulled player merges with the local one of the same name', () async {
      final m = await joined();
      await localGame(); // has a local "Alice"
      await pullGameFromOther(m, aliceName: 'ALICE');

      expect(await players.getAllNames(), ['Alice', 'Bob']);
      final stats = await DriftPlayerStatsRepository(db).getStatsByName('Alice');
      expect(stats['gamesPlayed'], 2, reason: 'one human, both games');
    });

    test('children that arrive before their parent wait, then apply', () async {
      final m = await joined();
      final report = await store.applyPulled(m, [
        _delta('round', 'bbbbbbbb-0000-4000-8000-000000000004', 4, 1,
            {'game_id': 'bbbbbbbb-0000-4000-8000-000000000002', 'round_number': 1}),
      ], 1);
      expect(report.quarantined, 1);
      expect(await games.getAll(), isEmpty);

      await store.applyPulled(m, [
        _delta('game', 'bbbbbbbb-0000-4000-8000-000000000002', 2, 2, {'name': 'Plus tard'}),
      ], 2);

      final game = (await games.getAll()).single;
      expect((await rounds.getByGame(game.id!)).single.roundNumber, 1);
      final inbox = await db.customSelect('SELECT COUNT(*) AS c FROM sync_inbox').getSingle();
      expect(inbox.data['c'], 0);
    });

    test('an older write loses to the version already applied', () async {
      final m = await joined();
      const uuid = 'cccccccc-0000-4000-8000-000000000002';
      await store.applyPulled(m, [_delta('game', uuid, 9, 1, {'name': 'Nouveau'})], 1);
      await store.applyPulled(m, [_delta('game', uuid, 3, 2, {'name': 'Ancien'})], 2);

      expect((await games.getAll()).single.name, 'Nouveau');
    });

    test('a delete wins over any later upsert', () async {
      final m = await joined();
      const uuid = 'dddddddd-0000-4000-8000-000000000002';
      await store.applyPulled(m, [_delta('game', uuid, 1, 1, {'name': 'G'})], 1);
      await store.applyPulled(m, [_delta('game', uuid, 2, 2, {}, op: 'delete')], 2);
      await store.applyPulled(m, [_delta('game', uuid, 50, 3, {'name': 'Retour ?'})], 3);

      expect(await games.getAll(), isEmpty);
    });

    test('this device\'s own deltas are skipped', () async {
      final m = await joined();
      await store.applyPulled(
          m, [_delta('game', 'eeeeeeee-0000-4000-8000-000000000002', 1, 1, {'name': 'G'}, origin: _me)], 1);
      expect(await games.getAll(), isEmpty);
    });

    test('the same score cell adopts the server identity', () async {
      final m = await joined();
      await pullGameFromOther(m);
      final game = (await games.getAll()).single;
      final gp = (await players.getByGame(game.id!)).single;
      final round = (await rounds.getByGame(game.id!)).single;
      // Delete the pulled score locally without capture, then type the cell anew.
      await db.customStatement('DELETE FROM scores');
      await scores.create(Score(playerId: gp.id!, roundId: round.id!, value: 99));

      await store.applyPulled(m, [
        _delta('score', 'ffffffff-0000-4000-8000-000000000005', 8, 6, {
          'round_id': 'aaaaaaaa-0000-4000-8000-000000000004',
          'player_id': 'aaaaaaaa-0000-4000-8000-000000000001',
          'value': 30,
        }),
      ], 6);

      final rows = await db.customSelect('SELECT uuid, value FROM scores').get();
      expect(rows.single.data, {'uuid': 'ffffffff-0000-4000-8000-000000000005', 'value': 30});
    });
  });

  test('renumberRound moves a round to the next free number', () async {
    final m = await joined();
    final g = await localGame();
    await rounds.create(Round(gameId: g.game, roundNumber: 2));
    await store.shareGame(g.game, m.groupId);
    final uuid = (await db
            .customSelect('SELECT uuid FROM rounds WHERE id = ?', variables: [Variable(g.round)])
            .getSingle())
        .data['uuid'] as String;

    expect(await store.renumberRound(uuid), 3);
    expect((await rounds.getByGame(g.game)).map((r) => r.roundNumber), [2, 3]);
  });

  test('leaving turns shared games back into local ones and forgets sync state', () async {
    final m = await joined();
    final g = await localGame();
    await store.shareGame(g.game, m.groupId);
    await rounds.delete(g.round); // a shared tombstone
    await store.preparePush(m);

    await store.leave(m.groupId);

    expect(await store.membership(), isNull);
    expect((await games.getById(g.game))!.groupId, isNull);
    for (final table in ['outbox', 'group_links', 'entity_versions', 'sync_inbox', 'sync_state']) {
      final c = await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
      expect(c.data['c'], 0, reason: table);
    }
    final tombstones =
        await db.customSelect('SELECT COUNT(*) AS c FROM rounds WHERE deleted_at IS NOT NULL').getSingle();
    expect(tombstones.data['c'], 0);
    // Local again: a new round is not captured.
    await rounds.create(Round(gameId: g.game, roundNumber: 1));
    expect(await outbox(), isEmpty);
  });
}
