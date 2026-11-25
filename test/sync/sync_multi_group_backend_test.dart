// One device in two groups, through a real server
// (wip/done/2026-11-25-multi-group-sync-sessions.md): X is in A and B, Y in A,
// Z in B. And the client's answer to `lamport_reused`
// (wip/done/2026-11-25-client-restamps-on-lamport-reused.md), and what a
// database restored from a backup gets back of its own edits
// (wip/done/2026-11-25-a-restored-device-never-gets-its-own-later-edits-back.md). Skipped unless
// SYNC_BACKEND_URL points at a running backend, as sync_two_devices_test.dart
// (.llmwiki/Testing.md, "Group sync against a local backend"):
//
//   SYNC_BACKEND_URL=http://127.0.0.1:8000 flutter test test/sync/sync_multi_group_backend_test.dart
//
// Each device is an in-memory database driven by SyncEngine directly, one
// engine per group, as GroupSession runs it.

@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/backend_client.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_engine.dart';
import 'package:countscore/services/sync/sync_store.dart';

final _url = Platform.environment['SYNC_BACKEND_URL'];

/// Forwards to a real client, and keeps the reason of every refused delta.
class _Recorder extends http.BaseClient {
  final _inner = http.Client();
  final reasons = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (!request.url.path.endsWith('/sync/push')) return response;
    final bytes = await response.stream.toBytes();
    for (final r in (jsonDecode(utf8.decode(bytes)) as Map)['results'] as List) {
      final reason = (r as Map)['reason'];
      if (reason != null) reasons.add(reason as String);
    }
    return http.StreamedResponse(Stream.value(bytes), response.statusCode,
        headers: response.headers, request: request);
  }
}

class _Device {
  _Device() {
    _open(AppDatabase.forTesting(NativeDatabase.memory()));
  }

  late AppDatabase db;
  late SyncStore store;
  late DriftGameRepository games;
  late DriftPlayerRepository players;
  late DriftRoundRepository rounds;
  late DriftScoreRepository scores;
  late DriftGameTypeRepository gameTypes;

  void _open(AppDatabase database) {
    db = database;
    store = SyncStore(db);
    games = DriftGameRepository(db);
    players = DriftPlayerRepository(db);
    rounds = DriftRoundRepository(db);
    scores = DriftScoreRepository(db);
    gameTypes = DriftGameTypeRepository(db);
  }

  /// A copy of the whole database as it is now — a backup, or an export.
  Future<File> backup() async {
    final dir = await Directory.systemTemp.createTemp('countscore_backup_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/backup.db');
    await db.customStatement('VACUUM INTO ?', [file.path]);
    return file;
  }

  /// The database goes back to [backup], cursor and clock with it, as a
  /// restored backup or Settings → Import leaves it. The tokens stay: they
  /// live in secure storage, not in the database.
  Future<void> restore(File backup) async {
    await db.close();
    final copy = await backup.copy('${backup.parent.path}/restored.db');
    _open(AppDatabase.forTesting(NativeDatabase(copy)));
  }
  final memberships = <String, GroupMembership>{};
  final recorder = _Recorder();

  BackendClient get client => BackendClient(_url!, httpClient: recorder);

  Future<GroupMembership> create(String label) async {
    final m = await client.createGroup('Test ${DateTime.now().microsecondsSinceEpoch}', label);
    await enter(m);
    return m;
  }

  Future<void> enter(GroupMembership m) async {
    memberships[m.groupId] = m;
    await store.join(m);
  }

  Future<SyncPassResult> sync(String groupId) =>
      SyncEngine(store, client, memberships[groupId]!.deviceToken, groupId).run();

  Future<void> syncOk(String groupId) async =>
      expect((await sync(groupId)).failure, isNull);

  /// A local game named [name] with [names], one round of scores, of [typeId].
  Future<int> game(String name, List<String> names, {int typeId = 1}) async {
    final id = await games.create(Game(name: name, isLowestScoreWins: true, gameTypeId: typeId));
    final round = await rounds.create(Round(gameId: id, roundNumber: 1));
    for (var i = 0; i < names.length; i++) {
      final p = await players.create(Player(gameId: id, name: names[i], orderIndex: i));
      await scores.create(Score(playerId: p, roundId: round, value: 10 + i));
    }
    return id;
  }

  Future<List<String>> gameNames() async => [for (final g in await games.getAll()) g.name]..sort();

  Future<List<String>> playerNames() async => (await players.getAllNames())..sort();

  Future<int?> colourOf(String name) async => (await db.customSelect(
          'SELECT colorValue FROM players WHERE name = ? AND deleted_at IS NULL',
          variables: [Variable(name)]).getSingleOrNull())
      ?.data['colorValue'] as int?;

  Future<int> links(String groupId) async => (await db.customSelect(
          'SELECT COUNT(*) AS c FROM group_links WHERE group_id = ?',
          variables: [Variable(groupId)]).getSingle())
      .data['c'] as int;
}

void main() {
  if (_url == null) {
    if (Platform.environment['SYNC_TEST_REQUIRED'] == 'true') {
      test('one device in two groups through a real server', () {
        fail('SYNC_TEST_REQUIRED is set but SYNC_BACKEND_URL is not');
      });
      return;
    }
    test('one device in two groups through a real server', () {},
        skip: 'set SYNC_BACKEND_URL to run against a backend');
    return;
  }

  late _Device x;
  late _Device y;
  late _Device z;
  late String a;
  late String b;

  setUp(() async {
    x = _Device();
    y = _Device();
    z = _Device();
    final groupA = await y.create('Y');
    final groupB = await z.create('Z');
    a = groupA.groupId;
    b = groupB.groupId;
    await x.enter(await x.client.joinGroup(groupA.shareToken, 'X'));
    await x.enter(await x.client.joinGroup(groupB.shareToken, 'X'));
  });

  tearDown(() async {
    await x.db.close();
    await y.db.close();
    await z.db.close();
  });

  /// Alice plays in A (with Bob) and in B (with Carol): one local row on X,
  /// linked into both groups. Everyone synced.
  Future<(int, int)> aliceInBoth() async {
    final inA = await x.game('Mardi A', ['Alice', 'Bob']);
    final inB = await x.game('Mardi B', ['Alice', 'Carol']);
    await x.store.shareGame(inA, a);
    await x.store.shareGame(inB, b);
    await x.syncOk(a);
    await x.syncOk(b);
    await y.syncOk(a);
    await z.syncOk(b);
    return (inA, inB);
  }

  test('a game shared into A reaches Y and never Z; into B, the reverse', () async {
    await aliceInBoth();

    expect(await y.gameNames(), ['Mardi A']);
    expect(await z.gameNames(), ['Mardi B']);
    expect(await y.playerNames(), ['Alice', 'Bob']);
    expect(await z.playerNames(), ['Alice', 'Carol']);
    expect(await x.store.pendingCount(), 0);
    expect(await x.store.rejectedCount(), 0);

    // And back: what Y plays in A reaches X, not Z.
    final fromY = await y.game('Jeudi A', ['Dora', 'Eve']);
    await y.store.shareGame(fromY, a);
    await y.syncOk(a);
    await x.syncOk(a);
    await x.syncOk(b);
    await z.syncOk(b);
    expect(await x.gameNames(), ['Jeudi A', 'Mardi A', 'Mardi B']);
    expect(await z.gameNames(), ['Mardi B']);
  });

  test('a local rename of a player linked in A and B reaches Y and Z', () async {
    await aliceInBoth();

    await x.players.renameByName('Alice', 'Alicia');
    expect(await x.store.pendingCount(groupId: a), greaterThan(0));
    expect(await x.store.pendingCount(groupId: b), greaterThan(0));
    await x.syncOk(a);
    await x.syncOk(b);
    await y.syncOk(a);
    await z.syncOk(b);

    expect(await y.playerNames(), ['Alicia', 'Bob']);
    expect(await z.playerNames(), ['Alicia', 'Carol']);
  });

  test('a rename pulled from A is applied, not relayed to B; the next local edit carries it',
      () async {
    await aliceInBoth();

    await y.players.renameByName('Alice', 'Alicia');
    await y.syncOk(a);
    await x.syncOk(a);
    expect(await x.playerNames(), containsAll(['Alicia']));
    expect(await x.playerNames(), isNot(contains('Alice')));
    expect(await x.store.pendingCount(groupId: b), 0, reason: 'nothing queued for B');

    await x.syncOk(b);
    await z.syncOk(b);
    expect(await z.playerNames(), ['Alice', 'Carol'], reason: 'decision 3: no relay');

    // X's next local edit of that player sends it as it is now: renamed.
    await x.players.updateColorByName('Alicia', 0xFF4CAF50);
    await x.syncOk(b);
    await z.syncOk(b);
    expect(await z.playerNames(), ['Alicia', 'Carol']);
    expect(await z.colourOf('Alicia'), 0xFF4CAF50);
  });

  test('X leaves A: B keeps its games, links and sync; what B links stays', () async {
    final typeId = await x.gameTypes.create(GameType(
      name: 'Belote maison',
      iconCodePoint: 0xe000,
      cardColorValue: 0xFF795548,
      isLowestScoreWins: false,
    ));
    final inA = await x.game('Belote A', ['Alice', 'Bob'], typeId: typeId);
    final inB = await x.game('Belote B', ['Alice', 'Carol'], typeId: typeId);
    await x.store.shareGame(inA, a);
    await x.store.shareGame(inB, b);
    await x.syncOk(a);
    await x.syncOk(b);
    final linksInB = await x.links(b);

    // Leaving, as GroupProvider.leaveGroup does it.
    await x.client.revokeDevice(x.memberships[a]!.deviceToken, x.memberships[a]!.deviceId);
    await x.store.leave(a);

    expect(await x.links(a), 0);
    expect(await x.links(b), linksInB);
    expect((await x.games.getById(inA))!.groupId, isNull, reason: 'a local game now');
    expect((await x.games.getById(inB))!.groupId, b);
    expect(await x.playerNames(), containsAll(['Alice', 'Bob', 'Carol']));
    expect((await x.gameTypes.getById(typeId))?.name, 'Belote maison');
    expect([for (final m in await x.store.memberships()) m.groupId], [b]);

    // B syncs on: a round on X reaches Z, with the type.
    final round = await x.rounds.create(Round(gameId: inB, roundNumber: 2));
    final alice = (await x.players.getByGame(inB)).firstWhere((p) => p.name == 'Alice');
    await x.scores.create(Score(playerId: alice.id!, roundId: round, value: 7));
    await x.syncOk(b);
    await z.syncOk(b);
    final onZ = (await z.games.getAll()).single;
    expect((await z.rounds.getByGame(onZ.id!)).length, 2);
    expect((await z.gameTypes.getById(onZ.gameTypeId!))!.name, 'Belote maison');
  });

  test('X revoked in A keeps syncing in B', () async {
    await aliceInBoth();

    await y.client.revokeDevice(y.memberships[a]!.deviceToken, x.memberships[a]!.deviceId);

    expect((await x.sync(a)).failure, SyncFailure.unauthorized);
    final more = await x.game('Vendredi B', ['Alice', 'Carol']);
    await x.store.shareGame(more, b);
    await x.syncOk(b);
    await z.syncOk(b);
    expect(await z.gameNames(), ['Mardi B', 'Vendredi B']);
  });

  group('lamport_reused', () {
    Future<void> setClock(String sql) =>
        x.db.customStatement('UPDATE sync_state SET $sql WHERE group_id = ?', [a]);

    test('a whole database restored reuses no lamport: the first pull lifts the clock',
        () async {
      await aliceInBoth();
      await x.players.updateColorByName('Alice', 0xFF2196F3);
      await x.syncOk(a);

      await setClock('last_lamport = 0, last_server_seq = 0');
      await x.players.updateColorByName('Alice', 0xFFE91E63);
      await x.syncOk(a);
      await y.syncOk(a);

      expect(x.recorder.reasons, isNot(contains('lamport_reused')));
      expect(await x.store.rejectedCount(), 0);
      expect(await y.colourOf('Alice'), 0xFFE91E63);
    });

    test('a clock behind its own log is stamped again, pushed again and applied', () async {
      await aliceInBoth();
      await x.players.updateColorByName('Alice', 0xFF2196F3);
      await x.syncOk(a);
      // The cursor trails this device's own pushes until the next pull: one
      // more pass takes it past them.
      await x.syncOk(a);

      // The clock goes back, the cursor does not: the pull the pass starts
      // with brings nothing, and the next stamp is one the server holds.
      await setClock('last_lamport = 1');
      await x.players.updateColorByName('Alice', 0xFFE91E63);
      await x.syncOk(a);
      await y.syncOk(a);

      expect(x.recorder.reasons, contains('lamport_reused'));
      expect(await x.store.pendingCount(groupId: a), 0);
      expect(await x.store.rejectedCount(), 0);
      expect(await y.colourOf('Alice'), 0xFFE91E63, reason: 'the edit reached the group');
    });
  });

  // wip/done/2026-11-25-a-restored-device-never-gets-its-own-later-edits-back.md
  group('a restored database', () {
    Future<Game> gameOn(_Device d, int id) async => (await d.games.getById(id))!;

    Future<Game> gameNamed(_Device d, String name) async =>
        (await d.games.getAll()).singleWhere((g) => g.name == name);

    test('gets back the edit it pushed after the backup, and its next edit keeps it',
        () async {
      final (inA, _) = await aliceInBoth();
      final backup = await x.backup();

      // After the backup: X renames the game and the group takes it.
      await x.games.update((await gameOn(x, inA)).copyWith(name: 'Mardi soir'));
      await x.syncOk(a);
      await y.syncOk(a);
      expect(await y.gameNames(), ['Mardi soir']);

      // The database goes back to the copy, cursor and clock with it.
      await x.restore(backup);
      expect((await gameOn(x, inA)).name, 'Mardi A');

      await x.syncOk(a);
      expect((await gameOn(x, inA)).name, 'Mardi soir', reason: 'its own edit, back from the log');

      // The next local edit of that row is built from the row as it now is.
      await x.games.update((await gameOn(x, inA)).copyWith(isLowestScoreWins: false));
      await x.syncOk(a);
      await y.syncOk(a);
      final onY = await gameNamed(y, 'Mardi soir');
      expect(onY.isLowestScoreWins, isFalse, reason: 'the new edit reached Y');
      expect(await y.gameNames(), ['Mardi soir'], reason: 'and did not undo the rename');
      expect(await x.store.pendingCount(), 0);
      expect(await x.store.rejectedCount(), 0);
    });

    test('gets back a delete it pushed after the backup', () async {
      final (inA, _) = await aliceInBoth();
      final backup = await x.backup();

      await x.games.delete(inA);
      await x.syncOk(a);
      await y.syncOk(a);
      expect(await y.gameNames(), isEmpty);

      await x.restore(backup);
      expect(await x.gameNames(), ['Mardi A', 'Mardi B']);
      await x.syncOk(a);
      await x.syncOk(b);
      expect(await x.gameNames(), ['Mardi B']);
      await y.syncOk(a);
      expect(await y.gameNames(), isEmpty);
    });

    test('a device never restored keeps a local edit over its own older delta', () async {
      final (inA, _) = await aliceInBoth();
      await x.games.update((await gameOn(x, inA)).copyWith(name: 'Un'));
      await x.syncOk(a);

      // The cursor trails this device's own push: the next pull returns "Un",
      // older than the edit still queued.
      await x.games.update((await gameOn(x, inA)).copyWith(name: 'Deux'));
      await x.syncOk(a);
      await y.syncOk(a);

      expect((await gameOn(x, inA)).name, 'Deux');
      expect(await y.gameNames(), ['Deux']);
    });

    test('two groups: each gets back its own, in its own order, and neither disturbs '
        'the other', () async {
      final (inA, inB) = await aliceInBoth();
      final backup = await x.backup();

      // After the backup: X renames its game in each group; then Z renames
      // B's again, after X.
      await x.games.update((await gameOn(x, inA)).copyWith(name: 'Mardi A soir'));
      await x.games.update((await gameOn(x, inB)).copyWith(name: 'Mardi B soir'));
      await x.syncOk(a);
      await x.syncOk(b);
      await z.syncOk(b);
      await z.games.update((await gameNamed(z, 'Mardi B soir')).copyWith(name: 'Mardi B chez Z'));
      await z.syncOk(b);

      await x.restore(backup);
      await x.syncOk(b);
      expect((await gameOn(x, inB)).name, 'Mardi B chez Z', reason: "Z's later write wins");
      expect((await gameOn(x, inA)).name, 'Mardi A', reason: "A's pull has not run");
      await x.syncOk(a);
      expect((await gameOn(x, inA)).name, 'Mardi A soir');
      expect((await gameOn(x, inB)).name, 'Mardi B chez Z');

      // X's next edit in A reaches Y with the rename; B is not touched.
      await x.games.update((await gameOn(x, inA)).copyWith(isLowestScoreWins: false));
      expect(await x.store.pendingCount(groupId: b), 0);
      await x.syncOk(a);
      await x.syncOk(b);
      await y.syncOk(a);
      await z.syncOk(b);
      final onY = await gameNamed(y, 'Mardi A soir');
      expect(onY.isLowestScoreWins, isFalse);
      final onZ = await gameNamed(z, 'Mardi B chez Z');
      expect(onZ.isLowestScoreWins, isTrue);
      expect(await z.gameNames(), ['Mardi B chez Z']);
      expect(await x.store.rejectedCount(), 0);
    });
  });
}
