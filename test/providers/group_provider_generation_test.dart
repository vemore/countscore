// A sync pass that outlives a group switch reports nothing and the queued rerun
// still runs (wip/done/2026-09-26-a-sync-pass-running-across-a-group-switch-reports-unauthorized.md).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

import '../support/group_servers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GroupServers servers;
  late GroupProvider group;
  Completer<void>? gate;
  var pullEntered = Completer<void>();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'backendUrl': oldServer});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    servers = GroupServers();
    gate = null;
    pullEntered = Completer<void>();
    servers.intercept = (request) async {
      final g = gate;
      if (g != null && request.url.host == 'old.example.com' && request.url.path == '/sync/pull') {
        if (!pullEntered.isCompleted) pullEntered.complete();
        await g.future;
        // By now the old device is revoked.
        return http.Response('{"detail":"revoked"}', 401,
            headers: {'content-type': 'application/json'});
      }
      return null;
    };
    group = GroupProvider(
      db: db,
      credentials: MemorySyncCredentials(),
      httpClient: servers.client,
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
    await group.updateBackend(oldServer);
    await group.joinGroup(oldInvite, 'Phone');
    await idle(group);
    servers.seen.clear();
  });

  tearDown(() async {
    group.dispose();
    await db.close();
  });

  test('a switch during an in-flight pass ends synced, never unauthorized', () async {
    gate = Completer<void>();
    final statuses = <SyncStatus>[];
    group.addListener(() => statuses.add(group.status));

    unawaited(group.syncNow());
    await pullEntered.future;

    final c = await group.prepareJoin(newServer, newInvite, 'Tablet');
    await group.completeJoin(c);
    gate!.complete(); // the old pass now gets its 401
    await idle(group);
    await pumpEventQueue();

    expect(group.groupId, newGroupId);
    expect(group.status, SyncStatus.idle);
    expect(statuses, isNot(contains(SyncStatus.unauthorized)));
    expect(
        servers.seen
            .where((r) => r.url.path == '/sync/pull' && r.url.host == 'new.example.com'),
        isNotEmpty,
        reason: 'the new group synced without waiting for the poll');
  });

  test('a pass that outlives its generation writes neither status nor pending count', () async {
    gate = Completer<void>();
    unawaited(group.syncNow());
    await pullEntered.future;
    expect(group.pendingChanges, 0);

    await addUnsyncedChange(db);
    await group.leave();
    expect(group.status, SyncStatus.off);
    gate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await pumpEventQueue();

    expect(group.status, SyncStatus.off, reason: 'the stale 401 is not reported');
    expect(group.pendingChanges, 0, reason: 'the stale pass did not recount');
  });
}
