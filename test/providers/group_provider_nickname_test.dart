// GroupProvider.deviceLabel: this device's nickname in its group, held in memory
// and read back from the devices list. A list that left before a rename must not
// put the old name back, and a start with the server unreachable must not leave
// the nickname unknown for good.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

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
    expect(group.deviceLabel, 'Alice');

    // The list leaves while the server still says "Old"...
    server.devicesGate = Completer<void>();
    final list = group.devices();
    await pumpEventQueue();
    // ...the rename completes before it comes back...
    await group.renameDevice('  New ');
    expect(group.deviceLabel, 'New');
    server.devicesGate!.complete();
    await list;

    // ...and the stale answer leaves the new name alone.
    expect(group.deviceLabel, 'New');

    // A list that leaves after the rename is trusted again.
    server.devicesGate = null;
    server.serverLabel = 'Renamed elsewhere';
    await group.devices();
    expect(group.deviceLabel, 'Renamed elsewhere');
  });

  test('a nickname missed at an offline start is read after the next successful sync',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final credentials = MemorySyncCredentials();
    final server = _Server()..serverLabel = 'Alice';
    final first = _provider(db, credentials, server);
    await first.updateBackend('https://countscore.example.com');
    await first.createGroup('Famille', 'Alice');
    await _idle(first);
    first.dispose();

    // A restart: the membership is on disk, the nickname only in memory.
    server.devicesDown = true;
    final calls = server.devicesCalls;
    final group = _provider(db, credentials, server);
    addTearDown(group.dispose);
    await group.updateBackend('https://countscore.example.com');
    await _idle(group);
    expect(group.isJoined, isTrue);
    expect(server.devicesCalls, greaterThan(calls), reason: 'asked on start');
    expect(group.deviceLabel, isNull);

    server.devicesDown = false;
    await group.syncNow();
    await _idle(group);
    expect(group.deviceLabel, 'Alice');
  });
}
