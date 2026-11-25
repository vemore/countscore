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

  /// The status `GET /groups/me` answers.
  int meStatus = 200;

  /// Device tokens the server refuses (401): devices the owner revoked.
  final revokedTokens = <String>{};

  /// Answers a request itself (a slow or refused one) before the defaults; null
  /// from it lets the default answer.
  Future<http.Response?> Function(http.BaseRequest request)? intercept;

  bool _joinedOnce = false;

  MockClient get client => MockClient((request) async {
        seen.add(request);
        final custom = await intercept?.call(request);
        if (custom != null) return custom;
        http.Response json(Object body, [int status = 200]) =>
            http.Response.bytes(utf8.encode(jsonEncode(body)), status);
        final bearer = request.headers['Authorization']?.replaceFirst('Bearer ', '');
        if (bearer != null && revokedTokens.contains(bearer)) {
          return json({'detail': 'revoked'}, 401);
        }
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
            final status = meStatus;
            if (status != 200) return json({'detail': 'down'}, status);
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

/// The id of group [n] on a [MultiGroupServer].
String groupIdOf(int n) => '${'$n' * 8}-0000-4000-8000-000000000000';

/// This device's id in group [n] on a [MultiGroupServer].
String deviceIdOf(int n) => '${'$n' * 8}-1111-4111-8111-111111111111';

/// One backend holding several groups, told apart by the device token: the
/// invite code `invite-<n>` joins group [groupIdOf] n as device [deviceIdOf] n,
/// token `token-<n>`. Pulls bring nothing, pushes are applied. Every request is
/// kept in [seen].
class MultiGroupServer {
  final seen = <http.BaseRequest>[];

  /// Device tokens the server refuses (401): devices the owner revoked.
  final revokedTokens = <String>{};

  /// Device tokens whose requests drop the connection: that group unreachable.
  final down = <String>{};

  /// The name the server holds for each device token.
  final labels = <String, String>{};

  /// Answers a request itself before the defaults; null lets the default answer.
  Future<http.Response?> Function(http.BaseRequest request)? intercept;

  MockClient get client => MockClient((request) async {
        seen.add(request);
        final custom = await intercept?.call(request);
        if (custom != null) return custom;
        http.Response json(Object body, [int status = 200]) =>
            http.Response.bytes(utf8.encode(jsonEncode(body)), status);
        final bearer = request.headers['Authorization']?.replaceFirst('Bearer ', '');
        if (bearer != null && down.contains(bearer)) {
          throw http.ClientException('connection dropped');
        }
        if (bearer != null && revokedTokens.contains(bearer)) {
          return json({'detail': 'revoked'}, 401);
        }
        final n = bearer == null ? 0 : int.parse(bearer.split('-').last);
        switch (request.url.path) {
          case '/groups/join':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final share = body['share_token'] as String;
            final joined = int.parse(share.split('-').last);
            labels['token-$joined'] = body['device_label'] as String;
            return json({
              'group': {'id': groupIdOf(joined), 'name': 'Groupe $joined', 'share_token': share},
              'device': {
                'id': deviceIdOf(joined),
                'token': 'token-$joined',
                'label': body['device_label'],
              },
            });
          case '/groups/me':
            return json({'id': groupIdOf(n), 'owner_device_id': deviceIdOf(n)});
          case '/groups/me/devices':
            return json({
              'devices': [
                {
                  'id': deviceIdOf(n),
                  'label': labels[bearer],
                  'joined_at': '2026-11-25T10:00:00Z',
                  'last_seen_at': '2026-11-25T10:00:00Z',
                  'is_owner': true,
                  'dormant': false,
                },
              ],
            });
          case '/groups/devices/me':
            labels[bearer!] = jsonDecode(request.body)['label'] as String;
            return json({'id': deviceIdOf(n), 'label': labels[bearer]});
          case '/sync/pull':
            return json({'deltas': [], 'server_seq_max': 0, 'has_more': false});
          case '/sync/push':
            final deltas = (jsonDecode(request.body)['deltas'] as List);
            return json({
              'results': [
                for (var i = 0; i < deltas.length; i++)
                  {'status': 'applied', 'server_seq': i + 1, 'reason': null},
              ],
            });
        }
        if (request.url.path.endsWith('/revoke')) return http.Response('', 204);
        return json(<String, dynamic>{});
      });

  /// The requests made with group [n]'s token to [path].
  Iterable<http.BaseRequest> calls(int n, String path) => seen.where((r) =>
      r.url.path == path && r.headers['Authorization'] == 'Bearer token-$n');
}

/// Queues one change for [groupId] already prepared — stamped, with its
/// payload — as a pass that lost its answer leaves it: the next push sends it.
Future<void> addPreparedChange(AppDatabase db, String groupId) => db.customStatement(
      'INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at, group_id) '
      "VALUES ('game', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'upsert', "
      '\'{"uuid":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","payload":{}}\', 1, 0, ?)',
      [groupId],
    );

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

/// Queues one change for [groupId] (the old group by default), as a local write
/// would, without the table update that would start a sync: the provider's
/// cached count does not see it.
Future<void> addUnsyncedChange(AppDatabase db, [String groupId = oldGroupId]) =>
    db.customStatement(
      'INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at, group_id) '
      "VALUES ('game', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'upsert', '{}', 1, 0, ?)",
      [groupId],
    );

Future<int> outboxCount(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS c FROM outbox').getSingle()).data['c'] as int;
