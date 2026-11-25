// GroupProvider with several memberships, one GroupSession each
// (wip/done/2026-11-25-multi-group-sync-sessions.md): at most five groups,
// refused before any request; one group refused or left while another syncs
// changes nothing in the other; a local write wakes the groups it queued for.

import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

import '../support/group_servers.dart';

const _server = 'https://countscore.example.com';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MultiGroupServer server;
  late MemorySyncCredentials credentials;
  late GroupProvider group;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    server = MultiGroupServer();
    credentials = MemorySyncCredentials();
    group = GroupProvider(
      db: db,
      credentials: credentials,
      httpClient: server.client,
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
    await group.updateBackend(_server);
  });

  tearDown(() async {
    group.dispose();
    await db.close();
  });

  Future<void> joinAll(Iterable<int> groups) async {
    for (final n in groups) {
      await group.joinGroup('invite-$n', 'Phone');
    }
    await idle(group);
  }

  test('a sixth group is refused before any request', () async {
    await joinAll([1, 2, 3, 4, 5]);
    expect(group.memberships, hasLength(GroupProvider.maxGroups));
    server.seen.clear();

    await expectLater(
      group.joinGroup('invite-6', 'Phone'),
      throwsA(isA<GroupActionException>()
          .having((e) => e.error, 'error', GroupActionError.tooManyGroups)),
    );
    await expectLater(
      group.createGroup('Sixième', 'Phone'),
      throwsA(isA<GroupActionException>()
          .having((e) => e.error, 'error', GroupActionError.tooManyGroups)),
    );
    expect(server.seen, isEmpty, reason: 'no device row the install would not use');
    expect([for (final s in group.memberships) s.groupId],
        [for (final n in [1, 2, 3, 4, 5]) groupIdOf(n)]);
  });

  // The configuration QR on the server this device uses (decision 7): joined
  // beside the others, never in place of them.
  test('a shared configuration of the same server adds its group, and leaves none', () async {
    await joinAll([1, 2]);
    await addPreparedChange(db, groupIdOf(1));
    server.seen.clear();

    final c = await group.prepareJoin(_server, 'invite-3', 'Phone');
    expect(c.sameGroup, isFalse);
    await group.completeJoin(c);
    await idle(group);

    expect([for (final s in group.memberships) s.groupId],
        [groupIdOf(1), groupIdOf(2), groupIdOf(3)]);
    expect(server.seen.where((r) => r.url.path.endsWith('/revoke')), isEmpty,
        reason: 'no group is left');
    expect(await credentials.deviceToken(groupIdOf(1)), 'token-1');
    expect(server.calls(3, '/sync/pull'), isNotEmpty, reason: 'the new group syncs');
  });

  test('a shared configuration of the same server is refused as a sixth group', () async {
    await joinAll([1, 2, 3, 4, 5]);

    final c = await group.prepareJoin(_server, 'invite-6', 'Phone');
    await expectLater(
      group.completeJoin(c),
      throwsA(isA<GroupActionException>()
          .having((e) => e.error, 'error', GroupActionError.tooManyGroups)),
    );
    expect(group.memberships, hasLength(GroupProvider.maxGroups));
    expect(await credentials.deviceToken(groupIdOf(6)), isNull);
    expect(server.calls(6, '/groups/me/devices/${deviceIdOf(6)}/revoke'), hasLength(1),
        reason: 'the registration the join made is withdrawn');
  });

  test('at five, a code this device holds joins its group again, but never a sixth', () async {
    await joinAll([1, 2, 3, 4, 5]);
    final five = [for (final n in [1, 2, 3, 4, 5]) groupIdOf(n)];

    // The code of group 3: a new registration with a group already joined.
    await group.joinGroup('invite-3', 'Phone');
    await idle(group);
    expect([for (final s in group.memberships) s.groupId], unorderedEquals(five));

    // A held code that the server resolves to a new group: refused once the
    // answer names it, the new registration withdrawn, nothing kept.
    server.joinsTo['invite-4'] = 6;
    await expectLater(
      group.joinGroup('invite-4', 'Phone'),
      throwsA(isA<GroupActionException>()
          .having((e) => e.error, 'error', GroupActionError.tooManyGroups)),
    );
    expect([for (final s in group.memberships) s.groupId], unorderedEquals(five));
    expect(await credentials.deviceToken(groupIdOf(6)), isNull);
    expect(server.calls(6, '/groups/me/devices/${deviceIdOf(6)}/revoke'), hasLength(1));
  });

  test('leaveGroup(A) keeps B: its game, links, credentials and sync', () async {
    await joinAll([1, 2]);
    final games = DriftGameRepository(db);
    final players = DriftPlayerRepository(db);
    final inA = await games.create(Game(name: 'Mardi A', isLowestScoreWins: true, gameTypeId: 1));
    await players.create(Player(gameId: inA, name: 'Alice', orderIndex: 0));
    final inB = await games.create(Game(name: 'Mardi B', isLowestScoreWins: true, gameTypeId: 1));
    await players.create(Player(gameId: inB, name: 'Alice', orderIndex: 0));
    await group.shareGame(inA, groupIdOf(1));
    await group.shareGame(inB, groupIdOf(2));
    await group.syncNow();
    await idle(group);
    Future<int> links(String groupId) async => (await db
            .customSelect('SELECT COUNT(*) AS c FROM group_links WHERE group_id = ?',
                variables: [Variable(groupId)])
            .getSingle())
        .data['c'] as int;
    final linksInB = await links(groupIdOf(2));
    expect(linksInB, greaterThan(0));
    server.seen.clear();

    await group.leaveGroup(groupIdOf(1));

    expect([for (final s in group.memberships) s.groupId], [groupIdOf(2)]);
    expect(server.calls(1, '/groups/me/devices/${deviceIdOf(1)}/revoke'), hasLength(1));
    expect(server.calls(2, '/groups/me/devices/${deviceIdOf(2)}/revoke'), isEmpty);
    expect((await games.getById(inA))!.groupId, isNull, reason: 'a local game now');
    expect((await games.getById(inB))!.groupId, groupIdOf(2));
    expect(await links(groupIdOf(1)), 0);
    expect(await links(groupIdOf(2)), linksInB, reason: 'Alice is still linked in B');
    expect(await players.getAllNames(), contains('Alice'));
    expect(await credentials.deviceToken(groupIdOf(1)), isNull);
    expect(await credentials.deviceToken(groupIdOf(2)), 'token-2');

    // B syncs on.
    await DriftRoundRepository(db).create(Round(gameId: inB, roundNumber: 1));
    await group.syncNow();
    await idle(group);
    expect(server.calls(2, '/sync/push'), isNotEmpty);
    expect(group.session(groupIdOf(2))!.status, SyncStatus.idle);
    expect(group.pendingChanges, 0);
  });

  test('revoked in one group, the device keeps syncing in the other', () async {
    await joinAll([1, 2]);
    server.revokedTokens.add('token-1');
    await addPreparedChange(db, groupIdOf(2));

    await group.syncNow();
    await idle(group);

    expect(group.session(groupIdOf(1))!.status, SyncStatus.unauthorized);
    expect(group.session(groupIdOf(2))!.status, SyncStatus.idle);
    expect(group.session(groupIdOf(2))!.pendingChanges, 0, reason: 'its push went through');
    expect(server.calls(2, '/sync/push'), isNotEmpty);
    expect(group.status, SyncStatus.unauthorized, reason: 'one status shown: the worst');
  });

  test('a leave and a join during a pass of another group change nothing in it', () async {
    await joinAll([1, 2]);
    await addPreparedChange(db, groupIdOf(2));
    final gate = Completer<void>();
    final entered = Completer<void>();
    server.intercept = (request) async {
      if (request.url.path == '/sync/pull' &&
          request.headers['Authorization'] == 'Bearer token-2' &&
          !gate.isCompleted) {
        if (!entered.isCompleted) entered.complete();
        await gate.future;
      }
      return null;
    };
    final statuses = <SyncStatus>[];
    final b = group.session(groupIdOf(2))!;
    group.addListener(() => statuses.add(b.status));

    final pass = b.syncNow();
    await entered.future;
    await group.leaveGroup(groupIdOf(1));
    await group.joinGroup('invite-3', 'Phone');
    gate.complete();
    await pass;
    await idle(group);

    expect([for (final s in group.memberships) s.groupId], [groupIdOf(2), groupIdOf(3)]);
    expect(group.session(groupIdOf(2)), same(b), reason: 'the same session, never restarted');
    expect(b.status, SyncStatus.idle);
    expect(b.lastSyncAt, isNotNull);
    expect(b.pendingChanges, 0);
    expect(server.calls(2, '/sync/push'), hasLength(1));
    expect(statuses, isNot(contains(SyncStatus.unauthorized)));
    expect(server.calls(1, '/groups/me/devices/${deviceIdOf(1)}/revoke'), hasLength(1),
        reason: 'only the group left was revoked');
    expect(await credentials.deviceToken(groupIdOf(2)), 'token-2');
    expect(await credentials.deviceToken(groupIdOf(1)), isNull);
  });

  test('a local write wakes the groups it queued a change for, and only them', () async {
    await joinAll([1, 2]);
    final games = DriftGameRepository(db);
    final game = await games.create(Game(name: 'Mardi', isLowestScoreWins: true, gameTypeId: 1));
    await DriftPlayerRepository(db).create(Player(gameId: game, name: 'Alice', orderIndex: 0));
    final rounds = DriftRoundRepository(db);
    final round = await rounds.create(Round(gameId: game, roundNumber: 1));
    await group.shareGame(game, groupIdOf(2));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await idle(group);
    server.seen.clear();

    // A write Drift reports (an insert through `_insertRow` is not reported:
    // wip/todo_nr/2026-11-25-a-repository-insert-does-not-wake-sync.md).
    await rounds.updateComment(round, 'Zap !');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await idle(group);

    expect(server.calls(2, '/sync/push'), isNotEmpty);
    expect(server.calls(1, '/sync/pull'), isEmpty);
    expect(group.pendingChanges, 0);
  });

  test("a shared game's analysis goes to its own group", () async {
    await joinAll([1, 2]);
    expect(group.analysesThroughGroup(gameGroupId: groupIdOf(2), gameUuid: 'g'), isTrue);
    expect(group.analysesThroughGroup(gameGroupId: groupIdOf(9), gameUuid: 'g'), isFalse);
    server.intercept = (request) async => request.url.path.endsWith('/comments')
        ? http.Response('{"content":"Bravo","model":"m"}', 200,
            headers: {'content-type': 'application/json'})
        : null;

    final result = await group.gameAnalysis(groupIdOf(2), 'game-uuid', const {});

    expect(result.content, 'Bravo');
    final call = server.seen.lastWhere((r) => r.url.path.endsWith('/comments'));
    expect(call.headers['Authorization'], 'Bearer token-2');
  });
}
