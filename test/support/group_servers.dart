import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';

const oldServer = 'https://old.example.com';
const newServer = 'https://new.example.com';
const oldGroupId = '11111111-1111-4111-8111-111111111111';
const newGroupId = '55555555-5555-4555-8555-555555555555';
const oldInvite = '22222222-2222-4222-8222-222222222222';
const newInvite = '66666666-6666-4666-8666-666666666666';
const oldDeviceId = '33333333-3333-4333-8333-333333333333';
const newDeviceId = '77777777-7777-4777-8777-777777777777';
const oldDeviceToken = 'old-device-token';
const newDeviceToken = 'new-device-token';

/// Two backends behind one mock client, told apart by host: the device joins
/// the old one first ([oldGroupId]); a join on the new one — or a second join
/// on the old one — answers with [joinGroupId], or fails with [joinStatus].
/// Every request is kept in [seen].
class GroupServers {
  final seen = <http.BaseRequest>[];

  /// The group a join after the first resolves to.
  String joinGroupId = newGroupId;

  /// The status a join after the first answers; null drops the connection.
  int? joinStatus = 200;

  /// The status `POST /groups` answers.
  int createStatus = 200;

  bool _joinedOnce = false;

  MockClient get client => MockClient((request) async {
        seen.add(request);
        http.Response json(Object body, [int status = 200]) =>
            http.Response.bytes(utf8.encode(jsonEncode(body)), status);
        switch (request.url.path) {
          case '/groups/join':
            final share = jsonDecode(request.body)['share_token'] as String;
            if (!_joinedOnce) {
              _joinedOnce = true;
              return json(_membership(oldGroupId, share, oldDeviceId, oldDeviceToken));
            }
            final status = joinStatus;
            if (status == null) throw http.ClientException('connection dropped');
            if (status != 200) return json({'detail': 'no'}, status);
            return json(_membership(joinGroupId, share, newDeviceId, newDeviceToken));
          case '/groups':
            return json({'detail': 'down'}, createStatus);
          case '/groups/me':
            return json({'id': oldGroupId, 'owner_device_id': oldDeviceId});
          case '/groups/me/devices':
            return json({'devices': []});
          case '/sync/pull':
            return json({'deltas': [], 'server_seq_max': 0, 'has_more': false});
          case '/sync/push':
            return json({'detail': 'down'}, 503);
        }
        if (request.url.path.endsWith('/revoke')) return http.Response('', 204);
        return json(<String, dynamic>{});
      });

  static Map<String, dynamic> _membership(
    String groupId,
    String shareToken,
    String deviceId,
    String deviceToken,
  ) =>
      {
        'group': {
          'id': groupId,
          'name': groupId == oldGroupId ? 'Famille' : 'Amis',
          'share_token': shareToken,
        },
        'device': {'id': deviceId, 'token': deviceToken, 'label': 'x'},
      };
}

/// Lets the sync pass [GroupProvider] starts on its own finish.
Future<void> idle(GroupProvider group) async {
  for (var i = 0; i < 100; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (group.status != SyncStatus.syncing) {
      await pumpEventQueue();
      return;
    }
  }
}

/// Queues one change for the group, as a local write would, without the table
/// update that would start a sync: the provider's cached count does not see it.
Future<void> addUnsyncedChange(AppDatabase db) => db.customStatement(
      'INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at) '
      "VALUES ('game', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'upsert', '{}', 1, 0)",
    );

Future<int> outboxCount(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS c FROM outbox').getSingle()).data['c'] as int;
