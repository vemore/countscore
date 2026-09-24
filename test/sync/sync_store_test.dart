// The local half of group sync: capture triggers, delta preparation, pulled
// deltas, quarantine, leaving. No network — see sync_two_devices_test.dart for
// the round trip through a real server.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
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
  late DriftGameTypeRepository gameTypes;
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

  /// The uuid the group knows a linked local game type by.
  Future<String> remoteTypeUuid(int typeId) async {
    final row = await db.customSelect(
      'SELECT l.remote_uuid FROM group_links l JOIN game_types t ON t.uuid = l.local_uuid '
      "WHERE l.entity_type = 'game_type' AND t.id = ?",
      variables: [Variable(typeId)],
    ).getSingle();
    return row.data['remote_uuid'] as String;
  }

  /// The `rules` and `rules_slug` a game type row holds.
  Future<Map<String, Object?>> rulesOf(int typeId) async => (await db
          .customSelect('SELECT rules, rules_slug FROM game_types WHERE id = ?',
              variables: [Variable(typeId)])
          .getSingle())
      .data;

  /// The game type [localGame] plays, linked into the group by a shared game
  /// that is then deleted: the type is free of live games, so it can go too.
  Future<int> sharedTypeFreedOfGames(SyncMembership m) async {
    const typeId = 1; // localGame() plays the first seeded type
    final g = await localGame();
    await store.shareGame(g.game, m.groupId);
    // Linked into the group, and acknowledged, so only what comes next is pending.
    for (final d in await store.preparePush(m)) {
      await store.markSent(d, m.deviceId);
    }
    await games.delete(g.game);
    return typeId;
  }

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

    test('deleting a game type the group knows leaves a tombstone', () async {
      final m = await joined();
      final typeId = await sharedTypeFreedOfGames(m);
      await db.customStatement('DELETE FROM outbox');

      expect(await gameTypes.delete(typeId), 1);

      final row = await db
          .customSelect('SELECT deleted_at FROM game_types WHERE id = ?',
              variables: [Variable(typeId)])
          .getSingle();
      expect(row.data['deleted_at'], isNotNull, reason: 'the row stays, stamped');
      expect(await gameTypes.getById(typeId), isNull);
      expect((await gameTypes.getAll()).map((t) => t.id), isNot(contains(typeId)));

      final ops = {for (final r in await outbox()) '${r['entity_type']}': r['op']};
      expect(ops['game_type'], 'delete');
    });

    test('tombstoning a game type leaves its deleted games\' gameTypeId alone', () async {
      final m = await joined();
      final typeId = await sharedTypeFreedOfGames(m);
      final before = await db
          .customSelect('SELECT id, gameTypeId FROM games WHERE deleted_at IS NOT NULL')
          .get();
      expect(before.map((r) => r.data['gameTypeId']), [typeId],
          reason: 'the shared game was tombstoned, still pointing at the type');
      // Push the game's own delete, so only what the type delete causes is pending.
      for (final d in await store.preparePush(m)) {
        await store.markSent(d, m.deviceId);
      }
      await db.customStatement('DELETE FROM outbox');

      await gameTypes.delete(typeId);

      final after = await db
          .customSelect('SELECT id, gameTypeId FROM games WHERE deleted_at IS NOT NULL')
          .get();
      expect(after.map((r) => r.data), before.map((r) => r.data),
          reason: 'the type row stays, so the history keeps pointing at it');
      final pending = await outbox();
      expect(pending.map((r) => '${r['entity_type']}:${r['op']}'), ['game_type:delete'],
          reason: 'no second delete delta for a game already deleted');
    });

    test('a tombstoned built-in key is free again under the v15 index', () async {
      final m = await joined();
      final typeId = await sharedTypeFreedOfGames(m);
      final key = (await db
              .customSelect('SELECT builtin_key FROM game_types WHERE id = ?',
                  variables: [Variable(typeId)])
              .getSingle())
          .data['builtin_key'] as String;

      await gameTypes.delete(typeId);

      // The live-unique index ignores tombstones, so the key can be held again.
      final fresh = await gameTypes.create(GameType(
        builtinKey: key,
        name: 'Encore',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: false,
      ));
      final live = await db.customSelect(
        'SELECT id FROM game_types WHERE builtin_key = ? AND deleted_at IS NULL',
        variables: [Variable(key)],
      ).get();
      expect(live.map((r) => r.data['id']), [fresh]);
    });

    test('deleting a game type no group knows still removes the row', () async {
      await joined();
      final typeId = await gameTypes.create(GameType(
        name: 'Jeu local',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: false,
      ));

      await gameTypes.delete(typeId);

      final rows = await db
          .customSelect('SELECT id FROM game_types WHERE id = ?',
              variables: [Variable(typeId)])
          .get();
      expect(rows, isEmpty);
      expect(await outbox(), isEmpty);
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
      expect(game.payload.containsKey('ended_at'), isTrue,
          reason: 'sent even while open, so reopening can clear it');
      expect(game.payload['ended_at'], isNull);

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

    test('a finished game sends ended_at, and reopening sends it back to null',
        () async {
      final m = await joined();
      final g = await localGame();
      await store.shareGame(g.game, m.groupId);

      final at = DateTime(2026, 9, 16, 21, 30);
      await games.update((await games.getById(g.game))!.copyWith(finishedAt: at));
      final first = await store.preparePush(m);
      var game = first.firstWhere((d) => d.entityType == 'game');
      expect(DateTime.parse(game.payload['ended_at'] as String).toLocal(), at,
          reason: 'sent as UTC, like started_at');

      // A prepared delta keeps its payload until the server answers, so the
      // reopen is only visible once this push is acknowledged.
      for (final d in first) {
        await store.markSent(d, _me);
      }

      await games
          .update((await games.getById(g.game))!.copyWith(clearFinishedAt: true));
      game = (await store.preparePush((await store.membership())!))
          .firstWhere((d) => d.entityType == 'game');
      expect(game.payload['ended_at'], isNull);
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

    test('a deleted game type is pushed as a delete delta', () async {
      final m = await joined();
      final typeId = await sharedTypeFreedOfGames(m);
      final remote = await remoteTypeUuid(typeId);
      await gameTypes.delete(typeId);

      final deltas = await store.preparePush((await store.membership())!);

      final type = deltas.firstWhere((d) => d.entityType == 'game_type');
      expect(type.op, 'delete');
      expect(type.payload, isEmpty);
      expect(type.entityUuid, remote,
          reason: 'the group identity the type was linked under');
    });

    test('a game type with no rules_slug is pushed without the key', () async {
      final m = await joined();
      const typeId = 1;
      final g = await localGame();
      await store.shareGame(g.game, m.groupId);
      for (final d in await store.preparePush(m)) {
        await store.markSent(d, m.deviceId);
      }

      Future<Map<String, dynamic>> pushedTypePayload() async {
        final deltas = await store.preparePush((await store.membership())!);
        final type = deltas.firstWhere((d) => d.entityType == 'game_type');
        for (final d in deltas) {
          await store.markSent(d, m.deviceId);
        }
        return type.payload;
      }

      await db.customStatement(
          "UPDATE game_types SET rules_slug = 'zapzap' WHERE id = ?", [typeId]);
      expect((await pushedTypePayload())['rules_slug'], 'zapzap',
          reason: 'a slug this device holds still travels — a renamed type has '
              'nothing else to carry its rules');

      await db.customStatement(
          'UPDATE game_types SET rules_slug = NULL, rules = NULL WHERE id = ?', [typeId]);
      final wiped = await pushedTypePayload();
      expect(wiped.containsKey('rules_slug'), isFalse,
          reason: 'a wiped slug is never a deliberate value: the key is omitted '
              'so the group keeps the one a healthy device gave it');
      expect(wiped.containsKey('rules'), isTrue,
          reason: 'rules is cleared on purpose (Restore the default), so its '
              'null still travels');
      expect(wiped['rules'], isNull);
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

    test('a game pulled without ended_at is open; a later one finishes it',
        () async {
      final m = await joined();
      await pullGameFromOther(m);
      expect((await games.getAll()).single.finishedAt, isNull);

      await store.applyPulled(m, [
        _delta('game', 'aaaaaaaa-0000-4000-8000-000000000002', 6, 6, {
          'name': 'Chez Bob',
          'is_lowest_score_wins': false,
          'started_at': '2026-09-13T18:00:00Z',
          'ended_at': '2026-09-13T20:30:00Z',
        }),
      ], 6);
      expect((await games.getAll()).single.finishedAt,
          DateTime.parse('2026-09-13T20:30:00Z').toLocal());

      // Reopened on the other device: the null must land, not be ignored.
      await store.applyPulled(m, [
        _delta('game', 'aaaaaaaa-0000-4000-8000-000000000002', 7, 7, {
          'name': 'Chez Bob',
          'is_lowest_score_wins': false,
          'started_at': '2026-09-13T18:00:00Z',
          'ended_at': null,
        }),
      ], 7);
      expect((await games.getAll()).single.finishedAt, isNull);
    });

    test('a game that arrives already finished lands finished', () async {
      final m = await joined();
      await store.applyPulled(m, [
        _delta('game', 'cccccccc-0000-4000-8000-000000000001', 1, 1, {
          'name': 'Finie ailleurs',
          'is_lowest_score_wins': false,
          'started_at': '2026-09-13T18:00:00Z',
          'ended_at': '2026-09-13T21:00:00Z',
        }),
      ], 1);
      expect((await games.getAll()).single.finishedAt,
          DateTime.parse('2026-09-13T21:00:00Z').toLocal());
    });

    test('a pulled player merges with the local one of the same name', () async {
      final m = await joined();
      await localGame(); // has a local "Alice"
      await pullGameFromOther(m, aliceName: 'ALICE');

      expect(await players.getAllNames(), ['Alice', 'Bob']);
      expect((await players.getGameCountsByName())['Alice'], 2,
          reason: 'one human, both games');
    });

    test('a linked type gaining a key another local row holds keeps its own', () async {
      final m = await joined();
      await db.customStatement(
        'INSERT INTO game_types (name, iconCodePoint, cardColorValue, isLowestScoreWins, '
        "isDefault, uuid, created_at, updated_at) VALUES ('Mon Uno', 0, 0, 1, 0, 'mine', 1, 1)",
      );
      const remote = '44444444-4444-4444-8444-444444444444';
      await store.applyPulled(m, [_delta('game_type', remote, 1, 1, {'name': 'Mon Uno'})], 1);
      // The remote type becomes the built-in Uno, which the seeded row already is.
      await store.applyPulled(
          m, [_delta('game_type', remote, 2, 2, {'name': 'Mon Uno', 'builtin_key': 'uno'})], 2);

      final rows = await db
          .customSelect("SELECT uuid FROM game_types WHERE builtin_key = 'uno' "
              'AND deleted_at IS NULL')
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.data['uuid'], isNot('mine'));
      final mine = await db
          .customSelect("SELECT name, builtin_key FROM game_types WHERE uuid = 'mine'")
          .getSingle();
      expect(mine.data, {'name': 'Mon Uno', 'builtin_key': null});
    });

    test('a pulled null rules_slug does not clear the slug the local row has', () async {
      final m = await joined();
      final typeId = await sharedTypeFreedOfGames(m);
      await db.customStatement(
        "UPDATE game_types SET rules_slug = 'zapzap', rules = 'Mes règles' WHERE id = ?",
        [typeId],
      );
      final remote = await remoteTypeUuid(typeId);

      // What a device still holding the pre-1.3.1 damage sends.
      await store.applyPulled(m, [
        _delta('game_type', remote, 99, 99,
            {'name': 'ZapZap', 'builtin_key': 'zapzap', 'rules': null, 'rules_slug': null}),
      ], 99);

      expect((await rulesOf(typeId))['rules_slug'], 'zapzap',
          reason: 'the v18 repair is not undone by a null travelling back');
      expect((await rulesOf(typeId))['rules'], isNull,
          reason: 'rules is still cleared by a null — only the slug is spared');
    });

    test('a pulled rules_slug still replaces the local one', () async {
      final m = await joined();
      final typeId = await sharedTypeFreedOfGames(m);
      await db.customStatement(
          "UPDATE game_types SET rules_slug = 'zapzap' WHERE id = ?", [typeId]);
      final remote = await remoteTypeUuid(typeId);

      await store.applyPulled(m, [
        _delta('game_type', remote, 99, 99, {'name': 'Belote', 'rules_slug': 'belote'}),
      ], 99);

      expect((await rulesOf(typeId))['rules_slug'], 'belote',
          reason: 'sharing a ruleset across devices keeps working');
    });

    test('a built-in type pulled with a wiped slug is inserted with the derived one',
        () async {
      final m = await joined();
      // A device that does not have this built-in type at all.
      await db.customStatement("DELETE FROM game_types WHERE builtin_key = 'six_nimmt'");
      const remote = '66666666-6666-4666-8666-666666666666';

      await store.applyPulled(m, [
        _delta('game_type', remote, 1, 1,
            {'name': '6 nimmt!', 'builtin_key': 'six_nimmt', 'rules_slug': null}),
      ], 1);

      final row = await db
          .customSelect("SELECT rules_slug FROM game_types WHERE builtin_key = 'six_nimmt'")
          .getSingle();
      expect(row.data['rules_slug'], 'six_nimmt',
          reason: 'derived from the key, as applyV16 does — no migration will '
              'run again to repair it');
    });

    test('a custom type pulled with no slug keeps none', () async {
      final m = await joined();
      const remote = '77777777-7777-4777-8777-777777777777';

      await store.applyPulled(
          m, [_delta('game_type', remote, 1, 1, {'name': 'Mon jeu', 'rules_slug': null})], 1);

      final row = await db
          .customSelect("SELECT rules_slug FROM game_types WHERE name = 'Mon jeu'")
          .getSingle();
      expect(row.data['rules_slug'], isNull,
          reason: 'nothing to derive without a builtin key');
    });

    test('a game type deleted in the group is tombstoned here too', () async {
      final m = await joined();
      const remote = '55555555-5555-4555-8555-555555555555';
      await store.applyPulled(m, [_delta('game_type', remote, 1, 1, {'name': 'Mon Uno'})], 1);
      expect((await gameTypes.getAll()).where((t) => t.name == 'Mon Uno'), hasLength(1));

      await store.applyPulled(m, [_delta('game_type', remote, 2, 2, {}, op: 'delete')], 2);

      expect((await gameTypes.getAll()).where((t) => t.name == 'Mon Uno'), isEmpty);
      final row = await db
          .customSelect("SELECT deleted_at FROM game_types WHERE name = 'Mon Uno'")
          .getSingle();
      expect(row.data['deleted_at'], isNotNull);

      // A delete wins: a later upsert does not bring the type back.
      await store.applyPulled(
          m, [_delta('game_type', remote, 50, 3, {'name': 'Mon Uno'})], 3);
      expect((await gameTypes.getAll()).where((t) => t.name == 'Mon Uno'), isEmpty);
    });

    test('a pulled delete spares a type a live game still plays', () async {
      final m = await joined();
      const typeId = 1;
      final g = await localGame();
      await store.shareGame(g.game, m.groupId);
      await store.preparePush(m);
      final remote = await remoteTypeUuid(typeId);

      await store.applyPulled(m, [_delta('game_type', remote, 9, 9, {}, op: 'delete')], 9);

      expect(await gameTypes.getById(typeId), isNotNull,
          reason: 'the game would lose its icon, colour and rules');
      expect((await games.getById(g.game))!.gameTypeId, typeId);
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

  test('leaving drops a game type tombstone the group caused', () async {
    final m = await joined();
    final typeId = await sharedTypeFreedOfGames(m);
    await gameTypes.delete(typeId);

    await store.leave(m.groupId);

    final rows = await db
        .customSelect('SELECT id FROM game_types WHERE deleted_at IS NOT NULL')
        .get();
    expect(rows, isEmpty, reason: 'nobody left to inform, and the key is needed');
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
