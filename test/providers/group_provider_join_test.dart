// Joining from a shared configuration (GroupProvider.prepareJoin / completeJoin /
// cancelJoin): the new group is joined before the current one is left, so a join
// the server refuses changes nothing on the device; the same group behind a newer
// invite code is kept, not left; and the unsynced count is read at the moment it
// is asked for (wip/done/2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code.md).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

import '../support/group_servers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MemorySyncCredentials credentials;
  late GroupServers servers;
  late GroupProvider group;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    credentials = MemorySyncCredentials();
    servers = GroupServers();
    group = GroupProvider(
      db: db,
      credentials: credentials,
      httpClient: servers.client,
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
    // In the old group on the old server, with one change not synced yet.
    await group.updateBackend(oldServer);
    await group.joinGroup(oldInvite, 'Phone');
    await idle(group);
    await addUnsyncedChange(db);
    servers.seen.clear();
  });

  tearDown(() async {
    group.dispose();
    await db.close();
  });

  test('a refused join changes nothing: group, credentials, outbox, server', () async {
    servers.joinStatus = 404;

    await expectLater(
      group.prepareJoin(newServer, 'stale-code', 'Tablet'),
      throwsA(isA<GroupActionException>()
          .having((e) => e.error, 'error', GroupActionError.unknownShareToken)),
    );

    expect(group.isJoined, isTrue);
    expect(group.groupId, oldGroupId);
    expect(group.shareToken, oldInvite);
    expect(await credentials.deviceToken(), oldDeviceToken);
    expect(await credentials.shareToken(), oldInvite);
    expect(await outboxCount(db), 1, reason: 'the unsynced change is still queued');
    expect(servers.seen.where((r) => r.url.path.endsWith('/revoke')), isEmpty,
        reason: 'the old device is not revoked');
  });

  test('an unreachable server changes nothing either', () async {
    servers.joinStatus = null; // throws, as a dropped connection does

    await expectLater(group.prepareJoin(newServer, newInvite, 'Tablet'),
        throwsA(isA<GroupActionException>()
            .having((e) => e.error, 'error', GroupActionError.unreachable)));
    expect(group.groupId, oldGroupId);
    expect(await outboxCount(db), 1);
  });

  test('another group: joined first, then the old one left on its own server', () async {
    final c = await group.prepareJoin(newServer, newInvite, ' Tablet ');
    expect(c.sameGroup, isFalse);
    expect(group.groupId, oldGroupId, reason: 'nothing changes before completeJoin');
    expect(await outboxCount(db), 1);

    await group.completeJoin(c);
    await idle(group);

    final revoke = servers.seen.singleWhere((r) => r.url.path.endsWith('/revoke'));
    expect(revoke.url.host, 'old.example.com');
    expect(revoke.headers['Authorization'], 'Bearer $oldDeviceToken');
    expect(group.groupId, newGroupId);
    expect(group.shareToken, newInvite);
    expect(group.deviceLabel, 'Tablet');
    expect(await credentials.deviceToken(), newDeviceToken);
    expect(servers.seen.where((r) => r.url.path == '/sync/pull').single.url.host,
        'new.example.com');
  });

  test('the same group behind a newer code is kept, not left', () async {
    servers.joinGroupId = oldGroupId;

    final c = await group.prepareJoin(oldServer, 'rotated-code', 'Tablet');
    expect(c.sameGroup, isTrue);
    await group.completeJoin(c);

    expect(group.isJoined, isTrue);
    expect(group.groupId, oldGroupId);
    expect(await credentials.deviceToken(), oldDeviceToken, reason: 'same device');
    expect(group.shareToken, 'rotated-code');
    expect(await credentials.shareToken(), 'rotated-code');
    expect(await outboxCount(db), 1, reason: 'no row unshared, nothing dropped');
    // The registration the join made is withdrawn with its own token.
    final revoke = servers.seen.singleWhere((r) => r.url.path.endsWith('/revoke'));
    expect(revoke.url.path, '/groups/me/devices/$newDeviceId/revoke');
    expect(revoke.headers['Authorization'], 'Bearer $newDeviceToken');
  });

  test('cancelJoin withdraws the new registration and keeps the old group', () async {
    final c = await group.prepareJoin(newServer, newInvite, 'Tablet');
    await group.cancelJoin(c);

    final revoke = servers.seen.singleWhere((r) => r.url.path.endsWith('/revoke'));
    expect(revoke.url.host, 'new.example.com');
    expect(revoke.headers['Authorization'], 'Bearer $newDeviceToken');
    expect(group.groupId, oldGroupId);
    expect(await outboxCount(db), 1);
  });

  test('countPending reads the outbox now, where pendingChanges waits for a sync', () async {
    expect(group.pendingChanges, 0, reason: 'recounted only at the end of a sync pass');
    expect(await group.countPending(), 1);
    expect(group.pendingChanges, 1, reason: 'and refreshed by it');
  });

  test('createGroup while in a group: a refused create leaves the group alone', () async {
    servers.createStatus = 500;
    await expectLater(group.createGroup('Other', 'Phone'), throwsA(isA<GroupActionException>()));
    expect(group.groupId, oldGroupId);
    expect(await outboxCount(db), 1);
  });
}
