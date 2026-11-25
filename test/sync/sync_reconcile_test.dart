// A database import (Settings → Import) replaces `sync_state` and leaves the
// tokens in secure storage as they were, so the two can disagree. Before v23
// the one stored token was then used for whatever group the database named —
// a sync refused for ever, or another group's data pushed under it. Now
// `reconcileMemberships`, run by GroupProvider on start, ends each case in a
// defined state: a group with no token is left locally, a token with no group
// is forgotten.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/backend_client.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/services/sync/sync_reconcile.dart';
import 'package:countscore/services/sync/sync_store.dart';

import '../support/group_servers.dart';

const _a = 'aaaaaaaa-1111-4111-8111-111111111111';
const _b = 'bbbbbbbb-1111-4111-8111-111111111111';
const _c = 'cccccccc-1111-4111-8111-111111111111';

GroupMembership _membership(String groupId) => (
      groupId: groupId,
      groupName: 'Groupe $groupId',
      shareToken: 'unused',
      deviceId: '${groupId.substring(0, 8)}-2222-4222-8222-222222222222',
      deviceToken: 'unused',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncStore store;
  late MemorySyncCredentials credentials;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SyncStore(db);
    credentials = MemorySyncCredentials();
  });
  tearDown(() => db.close());

  /// A game with Alice, shared into [groupId] and pushed once, so the group has
  /// links, versions and a queue.
  Future<int> sharedGame(String groupId) async {
    final games = DriftGameRepository(db);
    final game = await games.create(Game(name: 'Partie $groupId', isLowestScoreWins: false));
    await DriftPlayerRepository(db).create(Player(gameId: game, name: 'Alice', orderIndex: 0));
    await store.shareGame(game, groupId);
    final m = (await store.membership(groupId))!;
    for (final d in await store.preparePush(m)) {
      await store.markSent(d, m.deviceId);
    }
    return game;
  }

  Future<String?> groupOf(int gameId) => store.groupOfGame(gameId);

  Future<int> count(String table, String groupId) async => (await db
          .customSelect('SELECT COUNT(*) AS c FROM $table WHERE group_id = ?',
              variables: [Variable(groupId)])
          .getSingle())
      .data['c'] as int;

  test('a group the database names and the credentials do not hold is left locally',
      () async {
    await store.join(_membership(_a));
    await store.join(_membership(_b));
    final inA = await sharedGame(_a);
    final inB = await sharedGame(_b);
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');

    final report = await reconcileMemberships(store, credentials);

    expect(report.left, [_b]);
    expect(report.forgotten, isEmpty);
    expect([for (final m in await store.memberships()) m.groupId], [_a]);
    expect(await groupOf(inB), isNull, reason: "B's game is a local game again");
    for (final table in ['group_links', 'entity_versions', 'outbox']) {
      expect(await count(table, _b), 0, reason: table);
    }
    expect(await groupOf(inA), _a, reason: 'A is untouched');
    expect(await count('group_links', _a), greaterThan(0));
    expect(await credentials.deviceToken(_a), 'device-a');
  });

  test('credentials for a group the database omits are forgotten', () async {
    await store.join(_membership(_a));
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');
    await credentials.save(_c, deviceToken: 'device-c', shareToken: 'share-c');

    final report = await reconcileMemberships(store, credentials);

    expect(report.left, isEmpty);
    expect(report.forgotten, {_c});
    expect(await credentials.groupIds(), {_a});
    expect(await credentials.shareToken(_c), isNull);
  });

  test('rows of a group with no membership at all are made local', () async {
    // A database cut between a leave's two halves, or edited by hand: a shared
    // game and its bookkeeping, and no sync_state row to go with them.
    await store.join(_membership(_a));
    final orphan = await sharedGame(_a);
    await db.customStatement('DELETE FROM sync_state');

    final report = await reconcileMemberships(store, credentials);

    expect(report.left, [_a]);
    expect(await groupOf(orphan), isNull);
    expect(await count('outbox', _a), 0);
    expect(await count('group_links', _a), 0);
    expect(await store.groupsWithoutMembership(), isEmpty);
  });

  test('agreeing storage is left alone', () async {
    await store.join(_membership(_a));
    final inA = await sharedGame(_a);
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');

    final report = await reconcileMemberships(store, credentials);

    expect(report.left, isEmpty);
    expect(report.forgotten, isEmpty);
    expect(await groupOf(inA), _a);
  });

  group('GroupProvider on start, after an import', () {
    var remoteChanges = 0;
    setUp(() => remoteChanges = 0);

    GroupProvider provider(GroupServers servers, [SyncCredentials? stored]) => GroupProvider(
          db: db,
          credentials: stored ?? credentials,
          httpClient: servers.client,
          onRemoteChange: () async => remoteChanges++,
          enableStream: false,
          pollInterval: const Duration(hours: 1),
        );

    Iterable<String> syncCalls(GroupServers servers) => [
          for (final r in servers.seen)
            if (r.url.path.startsWith('/sync/')) r.url.path,
        ];

    test('a database naming another group than the token does: no sync under the wrong token',
        () async {
      // The imported database is in group A; this install holds a token for
      // group B only. Before v23 that token was used for A's queue.
      await store.join(_membership(_a));
      final inA = await sharedGame(_a);
      await credentials.save(_b, deviceToken: 'device-b', shareToken: 'share-b');
      final servers = GroupServers();
      final group = provider(servers);
      addTearDown(group.dispose);

      await group.updateBackend(oldServer);
      await idle(group);

      expect(group.isJoined, isFalse);
      expect(group.status, SyncStatus.off);
      expect(servers.seen, isEmpty, reason: 'nothing is sent with a token of another group');
      expect(await store.memberships(), isEmpty);
      expect(await groupOf(inA), isNull, reason: 'kept, as a local game');
      expect(await credentials.groupIds(), isEmpty);
      expect(remoteChanges, greaterThan(0), reason: 'the games list shows it local');
    });

    test('a pre-v23 token of another group: the group is left locally, nothing pulled or '
        'pushed under it', () async {
      // On the old version this phone was in the old group (its one token
      // under the two fixed keys), then imported a database of group A. The
      // upgrade moves that token under A: only the server can tell it is not A's.
      FlutterSecureStorage.setMockInitialValues({
        SecureSyncCredentials.legacyDeviceTokenKey: oldDeviceToken,
        SecureSyncCredentials.legacyShareTokenKey: oldInvite,
      });
      final stored = SecureSyncCredentials();
      await store.join(_membership(_a));
      final inA = await sharedGame(_a);
      await addUnsyncedChange(db, _a);
      final servers = GroupServers();
      final group = provider(servers, stored);
      addTearDown(group.dispose);

      await group.updateBackend(oldServer);
      await idle(group);

      expect(syncCalls(servers), isEmpty, reason: "no pull or push under the old group's token");
      expect(servers.seen.where((r) => r.url.path == '/groups/me'), isNotEmpty,
          reason: 'the server was asked whose token it is');
      expect(group.isJoined, isFalse);
      expect(group.status, SyncStatus.off);
      expect(await store.memberships(), isEmpty);
      expect(await groupOf(inA), isNull, reason: 'kept, as a local game');
      expect(await count('outbox', _a), 0);
      expect(await stored.groupIds(), isEmpty);
      expect(await const FlutterSecureStorage().readAll(), isEmpty,
          reason: 'the token, its flag and the old keys are all gone');
      expect(remoteChanges, greaterThan(0));
    });

    test('a pre-v23 token of the same group is checked once, then syncs', () async {
      FlutterSecureStorage.setMockInitialValues({
        SecureSyncCredentials.legacyDeviceTokenKey: oldDeviceToken,
        SecureSyncCredentials.legacyShareTokenKey: oldInvite,
      });
      final stored = SecureSyncCredentials();
      await store.join(_membership(oldGroupId));
      final servers = GroupServers();
      final group = provider(servers, stored);
      addTearDown(group.dispose);

      await group.updateBackend(oldServer);
      await idle(group);

      expect(group.isJoined, isTrue);
      expect(group.status, SyncStatus.idle);
      expect(syncCalls(servers), contains('/sync/pull'));
      expect(await stored.needsGroupCheck(oldGroupId), isFalse, reason: 'remembered');
      expect(await stored.deviceToken(oldGroupId), oldDeviceToken);
    });

    test('an unanswered check leaves the pass undone, and the membership as it was', () async {
      FlutterSecureStorage.setMockInitialValues({
        SecureSyncCredentials.legacyDeviceTokenKey: oldDeviceToken,
        SecureSyncCredentials.legacyShareTokenKey: oldInvite,
      });
      final stored = SecureSyncCredentials();
      await store.join(_membership(oldGroupId));
      final servers = GroupServers()..meStatus = 503;
      final group = provider(servers, stored);
      addTearDown(group.dispose);

      await group.updateBackend(oldServer);
      await idle(group);

      expect(syncCalls(servers), isEmpty);
      expect(group.isJoined, isTrue);
      expect(group.status, SyncStatus.error);
      expect(await stored.needsGroupCheck(oldGroupId), isTrue, reason: 'asked again next pass');
    });

    test('a database naming the group the token holds syncs as before', () async {
      await store.join(_membership(oldGroupId));
      await credentials.save(oldGroupId, deviceToken: oldDeviceToken, shareToken: oldInvite);
      final servers = GroupServers();
      final group = provider(servers);
      addTearDown(group.dispose);

      await group.updateBackend(oldServer);
      await idle(group);

      expect(group.isJoined, isTrue);
      expect(group.groupId, oldGroupId);
      expect(group.shareToken, oldInvite);
      expect(group.status, SyncStatus.idle);
      expect(
          servers.seen.where((r) => r.url.path == '/sync/pull').first.headers['Authorization'],
          'Bearer $oldDeviceToken');
    });
  });
}
