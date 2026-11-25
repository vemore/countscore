// The nickname: one for every group, kept on the device (SyncCredentials),
// used to create and join each group, sent to every membership by a rename and
// again to a group that missed it (wip/done/2026-11-25-the-stored-nickname-is-
// not-read-by-group-provider.md). A list that left before a rename must not put
// the old name back, and a start with the server unreachable knows the nickname.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/services/sync/sync_store.dart';

import '../support/group_servers.dart' show MultiGroupServer, groupIdOf, deviceIdOf;

const _own = '33333333-3333-4333-8333-333333333333';

/// A server with one device, this one, called [serverLabel]. [devicesGate], when
/// set, holds the devices list until it completes; [devicesDown] answers it 503.
class _Server {
  String serverLabel = 'Old';
  Completer<void>? devicesGate;
  bool devicesDown = false;
  int devicesCalls = 0;

  MockClient get client => MockClient((request) async {
        http.Response json(Object body, [int status = 200]) =>
            http.Response.bytes(utf8.encode(jsonEncode(body)), status);
        switch (request.url.path) {
          case '/groups':
            return json({
              'group': {
                'id': '11111111-1111-4111-8111-111111111111',
                'name': 'Famille',
                'share_token': '22222222-2222-4222-8222-222222222222',
              },
              'device': {'id': _own, 'token': 'tok', 'label': 'Alice'},
            }, 201);
          case '/groups/me':
            return json({'id': '11111111-1111-4111-8111-111111111111', 'owner_device_id': _own});
          case '/groups/me/devices':
            devicesCalls++;
            final label = serverLabel; // what the server held when the request arrived
            await devicesGate?.future;
            if (devicesDown) return json({'detail': 'down'}, 503);
            return json({
              'devices': [
                {
                  'id': _own,
                  'label': label,
                  'joined_at': '2026-09-24T10:00:00Z',
                  'last_seen_at': '2026-09-24T10:00:00Z',
                  'is_owner': true,
                  'dormant': false,
                },
              ],
            });
          case '/groups/devices/me':
            serverLabel = jsonDecode(request.body)['label'] as String;
            return json({'id': _own, 'label': serverLabel});
          case '/sync/pull':
            return json({'deltas': [], 'server_seq_max': 0, 'has_more': false});
        }
        return json(<String, dynamic>{});
      });
}

GroupProvider _provider(AppDatabase db, SyncCredentials credentials, _Server server) =>
    GroupProvider(
      db: db,
      credentials: credentials,
      httpClient: server.client,
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );

/// Lets the sync pass that [GroupProvider] starts on its own finish.
Future<void> _idle(GroupProvider group) async {
  for (var i = 0; i < 100; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (group.status != SyncStatus.syncing) {
      await pumpEventQueue();
      return;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a devices list that predates a rename does not bring the old name back', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final server = _Server();
    final group = _provider(db, MemorySyncCredentials(), server);
    addTearDown(group.dispose);
    await group.updateBackend('https://countscore.example.com');
    await group.createGroup('Famille', '  Alice ');
    expect(group.nickname, 'Alice');

    // The list leaves while the server still says "Old"...
    server.devicesGate = Completer<void>();
    final list = group.memberships.single.devices();
    await pumpEventQueue();
    // ...the rename completes before it comes back...
    await group.renameDevice('  New ');
    expect(group.nickname, 'New');
    server.devicesGate!.complete();
    await list;

    // ...and the stale answer leaves the new name alone.
    expect(group.nickname, 'New');

    // A list that disagrees afterwards is a group that missed the nickname:
    // the device's own wins, and goes out again with the next pass.
    server.devicesGate = null;
    server.serverLabel = 'Renamed elsewhere';
    await group.memberships.single.devices();
    expect(group.nickname, 'New');
    await group.syncNow();
    await _idle(group);
    expect(server.serverLabel, 'New');
  });

  test('after a restart with the server unreachable, the nickname is the one last saved',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final credentials = MemorySyncCredentials();
    final server = _Server()..serverLabel = 'Alice';
    final first = _provider(db, credentials, server);
    await first.updateBackend('https://countscore.example.com');
    await first.createGroup('Famille', 'Alice');
    await _idle(first);
    await first.renameDevice('Alicia');
    first.dispose();
    expect(await credentials.nickname(), 'Alicia');

    // A restart, offline: nothing answers, and nothing needs to.
    final group = GroupProvider(
      db: db,
      credentials: credentials,
      httpClient: MockClient((_) async => throw http.ClientException('offline')),
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
    addTearDown(group.dispose);
    await group.updateBackend('https://countscore.example.com');
    expect(group.nickname, 'Alicia');
    await _idle(group);
    expect(group.status, SyncStatus.offline);
    expect(group.nickname, 'Alicia');
  });

  test('an install that never stored a nickname learns it from the devices list', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final credentials = MemorySyncCredentials();
    // A membership from before the nickname was kept: token, no nickname.
    await SyncStore(db).join((
      groupId: groupIdOf(1),
      groupName: 'Famille',
      shareToken: 'invite-1',
      deviceId: deviceIdOf(1),
      deviceToken: 'token-1',
    ));
    await credentials.save(groupIdOf(1), deviceToken: 'token-1', shareToken: 'invite-1');
    final server = MultiGroupServer()..labels['token-1'] = 'Alice';
    final group = _multi(db, credentials, server);
    addTearDown(group.dispose);

    await group.updateBackend('https://countscore.example.com');
    await _idle(group);
    await pumpEventQueue();

    expect(group.nickname, 'Alice');
    expect(await credentials.nickname(), 'Alice');
  });

  group('several groups', () {
    late AppDatabase db;
    late MemorySyncCredentials credentials;
    late MultiGroupServer server;
    late GroupProvider group;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      credentials = MemorySyncCredentials();
      server = MultiGroupServer();
      group = _multi(db, credentials, server);
      await group.updateBackend('https://countscore.example.com');
      await group.joinGroup('invite-1', 'Alice');
      await group.joinGroup('invite-2', group.nickname!);
      await _idle(group);
    });

    tearDown(() async {
      group.dispose();
      await db.close();
    });

    test('set once, it is what each group was joined with', () async {
      expect(server.labels, {'token-1': 'Alice', 'token-2': 'Alice'});
      expect(await credentials.nickname(), 'Alice');
    });

    test('a rename reaches every membership, and one that failed goes at its next pass',
        () async {
      server.down.add('token-2');
      await group.renameDevice(' Bob ');

      expect(group.nickname, 'Bob');
      expect(await credentials.nickname(), 'Bob', reason: 'stored once, for every group');
      expect(server.labels, {'token-1': 'Bob', 'token-2': 'Alice'});

      server.down.remove('token-2');
      await group.session(groupIdOf(2))!.syncNow();
      await _idle(group);
      await pumpEventQueue();
      expect(server.labels['token-2'], 'Bob');
    });

    test('a name the server refuses is stored nowhere', () async {
      server.intercept = (request) async => request.url.path == '/groups/devices/me'
          ? http.Response('{"detail":"invalid"}', 422)
          : null;
      await expectLater(group.renameDevice('Bad'), throwsA(isA<GroupActionException>()));
      expect(group.nickname, 'Alice');
      expect(await credentials.nickname(), 'Alice');
    });

    test('a rename no group took for a server error is the caller\'s, and stored nowhere',
        () async {
      server.intercept = (request) async => request.url.path == '/groups/devices/me'
          ? http.Response('{"detail":"slow down"}', 429)
          : null;
      await expectLater(
        group.renameDevice('Bob'),
        throwsA(isA<GroupActionException>()
            .having((e) => e.error, 'error', GroupActionError.rateLimited)),
      );
      expect(group.nickname, 'Alice');
      expect(await credentials.nickname(), 'Alice');
    });

    test('a rename one group took is kept; the group that answered an error gets it later',
        () async {
      server.intercept = (request) async => request.url.path == '/groups/devices/me' &&
              request.headers['Authorization'] == 'Bearer token-2'
          ? http.Response('{"detail":"down"}', 503)
          : null;
      await group.renameDevice('Bob');
      expect(await credentials.nickname(), 'Bob');
      expect(server.labels, {'token-1': 'Bob', 'token-2': 'Alice'});

      server.intercept = null;
      await group.session(groupIdOf(2))!.syncNow();
      await _idle(group);
      await pumpEventQueue();
      expect(server.labels['token-2'], 'Bob');
    });

    test('while a rename is on its way the new name is the one held, and a refusal restores',
        () async {
      final gate = Completer<void>();
      server.intercept = (request) async {
        if (request.url.path != '/groups/devices/me') return null;
        await gate.future;
        return http.Response('{"detail":"invalid"}', 422);
      };
      final rename = group.renameDevice('Bob');
      await pumpEventQueue();
      expect(group.nickname, 'Bob', reason: "a pass meanwhile sends this one, not 'Alice'");
      gate.complete();
      await expectLater(rename, throwsA(isA<GroupActionException>()));
      expect(group.nickname, 'Alice');
    });

    test('joining under another name renames the groups already joined', () async {
      await group.joinGroup('invite-3', 'Ali');
      await _idle(group);
      await pumpEventQueue();

      expect(group.nickname, 'Ali');
      expect(server.labels, {'token-1': 'Ali', 'token-2': 'Ali', 'token-3': 'Ali'});
    });
  });
}

GroupProvider _multi(AppDatabase db, SyncCredentials credentials, MultiGroupServer server) =>
    GroupProvider(
      db: db,
      credentials: credentials,
      httpClient: server.client,
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
