// The sync storage with several memberships (schema v23,
// wip/done/2026-11-25-multi-group-storage.md): `join` adds a membership, the
// queue, the quarantine and the versions carry their group, every read of them
// filters on it, and `leave` forgets one group only. No network — the store
// alone, as in sync_store_test.dart.

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

const _a = 'aaaaaaaa-1111-4111-8111-111111111111';
const _b = 'bbbbbbbb-1111-4111-8111-111111111111';
const _meInA = 'aaaaaaaa-2222-4222-8222-222222222222';
const _meInB = 'bbbbbbbb-2222-4222-8222-222222222222';
const _other = '33333333-3333-4333-8333-333333333333';

PulledDelta _delta(String type, String uuid, int lamport, int seq, Map<String, dynamic> payload,
        {String op = 'upsert'}) =>
    (
      entityType: type,
      entityUuid: uuid,
      op: op,
      payload: payload,
      clientLamport: lamport,
      originDeviceId: _other,
      serverSeq: seq,
    );

GroupMembership _membership(String groupId, String deviceId, [String name = 'Groupe']) => (
      groupId: groupId,
      groupName: name,
      shareToken: 'unused',
      deviceId: deviceId,
      deviceToken: 'unused',
    );

void main() {
  late AppDatabase db;
  late SyncStore store;
  late DriftGameRepository games;
  late DriftGameTypeRepository gameTypes;
  late DriftPlayerRepository players;
  late DriftRoundRepository rounds;
  late DriftScoreRepository scores;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SyncStore(db);
    games = DriftGameRepository(db);
    gameTypes = DriftGameTypeRepository(db);
    players = DriftPlayerRepository(db);
    rounds = DriftRoundRepository(db);
    scores = DriftScoreRepository(db);
  });
  tearDown(() => db.close());

  /// This device in group A, then in group B.
  Future<(SyncMembership, SyncMembership)> joinBoth() async {
    await store.join(_membership(_a, _meInA, 'Famille'));
    await store.join(_membership(_b, _meInB, 'Amis'));
    return ((await store.membership(_a))!, (await store.membership(_b))!);
  }

  /// A local game with Alice and [other], one round, scores, shared into [groupId].
  Future<int> sharedGame(String groupId, String name, String other) async {
    final game = await games.create(Game(name: name, isLowestScoreWins: true, gameTypeId: 1));
    final alice = await players.create(Player(gameId: game, name: 'Alice', orderIndex: 0));
    final second = await players.create(Player(gameId: game, name: other, orderIndex: 1));
    final round = await rounds.create(Round(gameId: game, roundNumber: 1));
    await scores.create(Score(playerId: alice, roundId: round, value: 10));
    await scores.create(Score(playerId: second, roundId: round, value: 4));
    await store.shareGame(game, groupId);
    return game;
  }

  /// Prepares and acknowledges everything queued for [m].
  Future<void> pushAll(SyncMembership m) async {
    for (final d in await store.preparePush(m)) {
      await store.markSent(d, m.deviceId);
    }
  }

  Future<List<Map<String, Object?>>> rowsOf(String table, String groupId) async => [
        for (final r in await db
            .customSelect('SELECT * FROM $table WHERE group_id = ? ORDER BY rowid',
                variables: [Variable(groupId)])
            .get())
          r.data,
      ];

  Future<List<Map<String, Object?>>> pendingRows() async => [
        for (final r in await db
            .customSelect('SELECT entity_type, entity_uuid, group_id FROM outbox '
                'WHERE sent_at IS NULL ORDER BY id')
            .get())
          r.data,
      ];

  group('membership', () {
    test('join adds a sync_state row beside the others instead of replacing them', () async {
      await joinBoth();

      final all = await store.memberships();
      expect([for (final m in all) m.groupId], [_a, _b]);
      expect((await store.membership(_b))!.deviceId, _meInB);
      expect((await store.membership(_b))!.groupName, 'Amis');
      expect((await store.membership())!.groupId, _a, reason: 'the first joined, for one-group callers');
      expect(await store.membership('cccccccc-1111-4111-8111-111111111111'), isNull);
    });

    test('joining a group again replaces its own row only, and keeps its lamport', () async {
      final (a, b) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      await pushAll(a);
      await store.applyPulled(a, [], 9);
      final aBefore = (await store.membership(_a))!;
      expect(aBefore.lastServerSeq, 9);
      expect(aBefore.lastLamport, greaterThan(0));

      const fresh = 'aaaaaaaa-4444-4444-8444-444444444444';
      await store.join(_membership(_a, fresh, 'Famille'));

      final aAfter = (await store.membership(_a))!;
      expect(aAfter.deviceId, fresh);
      expect(aAfter.lastServerSeq, 0, reason: 'a pull from the start is idempotent');
      expect(aAfter.lastLamport, aBefore.lastLamport);
      expect(await store.membership(_b), b);
      expect(await rowsOf('group_links', _a), isNotEmpty, reason: 'the links are kept');
    });
  });

  group('capture', () {
    test('a player linked in A and B, renamed once, yields one outbox row per group', () async {
      final (a, b) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      await sharedGame(_b, 'Jeudi', 'Carole');
      await pushAll(a);
      await pushAll(b);
      expect(await pendingRows(), isEmpty);

      await players.renameByName('Alice', 'Alicia');

      final alice = (await db
              .customSelect("SELECT uuid FROM players WHERE name = 'Alicia'")
              .getSingle())
          .data['uuid'];
      final queued = await pendingRows();
      expect(queued.where((r) => r['entity_type'] == 'player'), [
        {'entity_type': 'player', 'entity_uuid': alice, 'group_id': _a},
        {'entity_type': 'player', 'entity_uuid': alice, 'group_id': _b},
      ]);

      // Each group gets the rename, under the identity that group knows.
      final toA = (await store.preparePush(a)).where((d) => d.entityType == 'player').single;
      final toB = (await store.preparePush(b)).where((d) => d.entityType == 'player').single;
      expect(toA.payload['name'], 'Alicia');
      expect(toB.payload['name'], 'Alicia');
      expect(toA.entityUuid, isNot(toB.entityUuid));
      expect((toA.groupId, toB.groupId), (_a, _b));
    });

    test('a game and the rows under it are queued for their own group only', () async {
      final (a, b) = await joinBoth();
      final inA = await sharedGame(_a, 'Mardi', 'Bob');
      await sharedGame(_b, 'Jeudi', 'Carole');
      await pushAll(a);
      await pushAll(b);

      await rounds.create(Round(gameId: inA, roundNumber: 2));

      final queued = await pendingRows();
      expect(queued.map((r) => (r['entity_type'], r['group_id'])), [('round', _a)]);
      expect(await store.pendingCount(groupId: _b), 0);
    });

    test('a rename pulled from A is applied here and queued for no group', () async {
      final (a, b) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      await sharedGame(_b, 'Jeudi', 'Carole');
      await pushAll(a);
      await pushAll(b);
      final remote = linkedRemoteUuid(_a, 'player', 'Alice');

      await store.applyPulled(a, [
        _delta('player', remote, 50, 1,
            {'name': 'Alice A.', 'name_normalized': normalizeName('Alice A.'), 'color_value': 1}),
      ], 1);

      expect(
          (await db.customSelect("SELECT COUNT(*) AS c FROM players WHERE name = 'Alice A.'")
                  .getSingle())
              .data['c'],
          1);
      expect(await pendingRows(), isEmpty, reason: 'not relayed to B, not echoed to A');
    });
  });

  group('push and counts', () {
    test("preparePush reads only its own group's queue", () async {
      final (a, b) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      await sharedGame(_b, 'Jeudi', 'Carole');

      final toA = await store.preparePush(a);

      expect(toA, isNotEmpty);
      expect(toA.map((d) => d.groupId).toSet(), {_a});
      final gameUuids = {
        for (final d in toA)
          if (d.entityType == 'game') d.entityUuid,
      };
      final mardi = (await games.getAll()).singleWhere((g) => g.name == 'Mardi');
      expect(gameUuids, {mardi.uuid});
      // B's queue is untouched: not stamped, not coalesced, not linked.
      final bQueue = await rowsOf('outbox', _b);
      expect(bQueue, isNotEmpty);
      expect(bQueue.every((r) => r['client_lamport'] == 0), isTrue);
      expect(bQueue.where((r) => r['entity_type'] == 'player'), isEmpty,
          reason: "B's players are linked by B's own push");
      expect((await store.membership(_b))!.lastLamport, 0);
      expect((await store.membership(_a))!.lastLamport, toA.length);
    });

    test('pending and rejected counts filter on the group', () async {
      final (a, _) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      await sharedGame(_b, 'Jeudi', 'Carole');
      final pendingA = await store.pendingCount(groupId: _a);
      final pendingB = await store.pendingCount(groupId: _b);
      expect(pendingA, greaterThan(0));
      expect(pendingB, greaterThan(0));
      expect(await store.pendingCount(), pendingA + pendingB);

      final refused = (await store.preparePush(a)).first;
      await store.markRejected(refused, 'invalid');

      expect(await store.rejectedCount(groupId: _a), 1);
      expect(await store.rejectedCount(groupId: _b), 0);
      expect(await store.rejectedCount(), 1);
    });
  });

  group('pull', () {
    test("the inbox replays only its own group's quarantine", () async {
      final (a, b) = await joinBoth();
      const game = 'cccccccc-0000-4000-8000-000000000002';
      const round = 'cccccccc-0000-4000-8000-000000000004';

      // B receives a round before its game: quarantined, in B.
      final report = await store.applyPulled(b, [
        _delta('round', round, 4, 1, {'game_id': game, 'round_number': 1}),
      ], 1);
      expect(report.quarantined, 1);
      expect(await rowsOf('sync_inbox', _b), hasLength(1));

      // A's pull brings a game with that uuid. A replays A's quarantine only.
      await store.applyPulled(a, [_delta('game', game, 2, 1, {'name': 'Partie'})], 1);
      expect(await rounds.getByGame((await games.getAll()).single.id!), isEmpty,
          reason: "B's quarantined round waits for B's pull");
      expect(await rowsOf('sync_inbox', _b), hasLength(1));

      // B's next pull replays it.
      await store.applyPulled(b, [], 1);
      expect(await rounds.getByGame((await games.getAll()).single.id!), hasLength(1));
      expect(await rowsOf('sync_inbox', _b), isEmpty);
    });

    test('versions are recorded under the group they were learnt in', () async {
      final (a, b) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      await pushAll(a);
      await store.applyPulled(b, [
        _delta('game', 'cccccccc-0000-4000-8000-000000000009', 2, 1, {'name': 'Chez B'}),
      ], 1);

      expect(await rowsOf('entity_versions', _a), isNotEmpty);
      expect(
          (await rowsOf('entity_versions', _b)).map((r) => r['entity_uuid']),
          ['cccccccc-0000-4000-8000-000000000009']);
    });
  });

  group('leave', () {
    test("leave(A) leaves B's sync_state, links, outbox, inbox and versions untouched",
        () async {
      final (a, b) = await joinBoth();
      await sharedGame(_a, 'Mardi', 'Bob');
      final inB = await sharedGame(_b, 'Jeudi', 'Carole');
      await pushAll(a);
      await pushAll(b);
      // Something of each kind in each group: queued, quarantined, versioned.
      await players.renameByName('Alice', 'Alicia');
      for (final m in [a, b]) {
        await store.applyPulled(m, [
          _delta('round', 'cccccccc-0000-4000-8000-0000000000${m == a ? 'a1' : 'b1'}', 4, 2,
              {'game_id': 'cccccccc-0000-4000-8000-0000000000ff', 'round_number': 1}),
        ], 2);
      }
      const tables = ['sync_state', 'group_links', 'outbox', 'sync_inbox', 'entity_versions'];
      final bBefore = {for (final t in tables) t: await rowsOf(t, _b)};
      for (final t in tables) {
        expect(bBefore[t], isNotEmpty, reason: 'B has $t rows to keep');
        expect(await rowsOf(t, _a), isNotEmpty, reason: 'A has $t rows to drop');
      }

      await store.leave(_a);

      for (final t in tables) {
        expect(await rowsOf(t, _b), bBefore[t], reason: t);
        expect(await rowsOf(t, _a), isEmpty, reason: t);
      }
      expect((await games.getById(inB))!.groupId, _b);
      final mardi = (await games.getAll()).singleWhere((g) => g.name == 'Mardi');
      expect(mardi.groupId, isNull, reason: "A's game is local again");
      expect([for (final m in await store.memberships()) m.groupId], [_b]);
    });

    test('leave(A) keeps a tombstoned player and game type that B still links', () async {
      final (a, b) = await joinBoth();
      final inA = await sharedGame(_a, 'Mardi', 'Bob');
      await pushAll(a);
      // B knows Alice and the type from its own pulls: linked in B, by name and
      // by key, with no game of B's holding them.
      final type = (await db
              .customSelect('SELECT name, builtin_key FROM game_types WHERE id = 1')
              .getSingle())
          .data;
      await store.applyPulled(b, [
        _delta('game_type', 'cccccccc-0000-4000-8000-000000000001', 1, 1,
            {'name': type['name'], 'builtin_key': type['builtin_key']}),
        _delta('player', 'cccccccc-0000-4000-8000-000000000002', 2, 2,
            {'name': 'Alice', 'name_normalized': normalizeName('Alice')}),
      ], 2);
      expect(await rowsOf('group_links', _b), hasLength(2));
      // Alice leaves this device's catalogue: tombstoned, her seat in A's game
      // too. The type goes once A's game, its only one, is deleted.
      await players.deleteByName('Alice');
      await games.delete(inA);
      await gameTypes.delete(1);
      Future<int> tombstones(String table) async => (await db
              .customSelect('SELECT COUNT(*) AS c FROM $table WHERE deleted_at IS NOT NULL')
              .getSingle())
          .data['c'] as int;
      expect(await tombstones('players'), 1);
      expect(await tombstones('game_types'), 1);
      final pendingB = await rowsOf('outbox', _b);
      expect(pendingB.map((r) => r['entity_type']).toSet(), {'player', 'game_type'},
          reason: "B is owed Alice's last name and the type's delete");

      await store.leave(_a);

      expect(await tombstones('players'), 1, reason: 'B still links her');
      expect(await tombstones('game_types'), 1, reason: 'B still links it');
      expect(await rowsOf('outbox', _b), pendingB);
      final toB = await store.preparePush(b);
      expect(toB.map((d) => (d.entityType, d.op)).toSet(),
          {('player', 'upsert'), ('game_type', 'delete')});

      await store.leave(_b);
      expect(await tombstones('players'), 0, reason: 'no group left to inform');
      expect(await tombstones('game_types'), 0, reason: 'no group left to inform');
    });
  });
}
