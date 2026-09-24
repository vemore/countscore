// The analysis is the app's only network call, so this is the only place where
// a server's answer becomes something the UI can show. A non-200 must arrive as
// a status the user can read, not as a Dart exception carrying raw JSON.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:countscore/services/backend_client.dart';

/// Always answers with these bytes and this status.
///
/// `http.Response.bytes` on purpose: the `http.Response(String, int)`
/// constructor encodes through `_encodingForHeaders`, which falls back to
/// latin-1 with no charset — it would pre-corrupt the very fixtures that check
/// the decoding.
MockClient _answering(String body, int status) => MockClient(
      (_) async => http.Response.bytes(utf8.encode(body), status),
    );

void main() {
  group('gameAnalysis', () {
    test('a non-200 arrives as a BackendException carrying the status', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"detail":"upstream LLM error: RuntimeError"}', 502),
      );

      expect(
        () => client.gameAnalysis(const {}),
        throwsA(isA<BackendException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
    });

    test('a backend that predates the rename is retried on its old path', () async {
      // A self-hosted backend is upgraded on its owner's schedule, so a phone
      // that updates first must not lose the feature.
      final paths = <String>[];
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path == BackendClient.analysisPath) {
            return http.Response.bytes(utf8.encode('Not Found'), 404);
          }
          return http.Response.bytes(
            utf8.encode('{"content":"Le professeur a parlé.","model":"m"}'),
            200,
          );
        }),
      );

      final result = await client.gameAnalysis(const {});

      expect(paths, [
        BackendClient.analysisPath,
        BackendClient.legacyAnalysisPath,
      ]);
      expect(result.content, 'Le professeur a parlé.');
    });

    test('a 404 from both paths is still a failure', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('Not Found', 404),
      );

      expect(
        () => client.gameAnalysis(const {}),
        throwsA(isA<BackendException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('the body is kept for logging, not thrown away', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"detail":"upstream LLM error: RuntimeError"}', 502),
      );

      try {
        await client.gameAnalysis(const {});
        fail('expected a BackendException');
      } on BackendException catch (e) {
        expect(e.body, contains('RuntimeError'));
        expect(e.toString(), contains('502'));
      }
    });

    test('an accented error body survives the decode', () async {
      // `response.body` would render this as mojibake: the server sends no
      // charset, so http falls back to latin-1.
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"detail":"erreur amont côté fournisseur"}', 502),
      );

      try {
        await client.gameAnalysis(const {});
        fail('expected a BackendException');
      } on BackendException catch (e) {
        expect(e.body, contains('erreur amont côté fournisseur'));
      }
    });

    test('a 200 decodes the content as utf8', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering(
          '{"content":"Le professeur a parlé.","model":"mistral-medium-latest"}',
          200,
        ),
      );

      final result = await client.gameAnalysis(const {});
      expect(result.content, 'Le professeur a parlé.');
      expect(result.model, 'mistral-medium-latest');
    });
  });

  group('group devices', () {
    test('listDevices parses the list and sends the device token', () async {
      late http.BaseRequest seen;
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response.bytes(
            utf8.encode('{"devices":[{"id":"a","label":"Tél Zoé",'
                '"joined_at":"2026-09-14T10:00:00Z","last_seen_at":"2026-09-14T10:05:00+00:00"}]}'),
            200,
          );
        }),
      );

      final devices = await client.listDevices('tok');

      expect(seen.method, 'GET');
      expect(seen.url.path, '/groups/me/devices');
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(devices, hasLength(1));
      expect(devices.single.label, 'Tél Zoé');
      expect(devices.single.lastSeenAt, DateTime.utc(2026, 9, 14, 10, 5));
      // A server that predates owners sends no is_owner.
      expect(devices.single.isOwner, isNull);
    });

    test('renameDevice patches this device only and returns the stored label', () async {
      late http.Request seen;
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response.bytes(utf8.encode('{"id":"a","label":"Zoé"}'), 200);
        }),
      );

      expect(await client.renameDevice('tok', 'Zoé'), 'Zoé');
      expect(seen.method, 'PATCH');
      expect(seen.url.path, '/groups/devices/me');
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(seen.body), {'label': 'Zoé'});
    });

    test('groupOwner reads the owner, and tells a server that predates owners', () async {
      final current = BackendClient('https://countscore.example.com',
          httpClient: _answering('{"id":"g","name":"n","owner_device_id":"d1"}', 200));
      expect(await current.groupOwner('tok'), (known: true, ownerDeviceId: 'd1'));

      final orphan = BackendClient('https://countscore.example.com',
          httpClient: _answering('{"id":"g","name":"n","owner_device_id":null}', 200));
      expect(await orphan.groupOwner('tok'), (known: true, ownerDeviceId: null));

      final legacy = BackendClient('https://countscore.example.com',
          httpClient: _answering('{"id":"g","name":"n"}', 200));
      expect((await legacy.groupOwner('tok')).known, isFalse);
    });

    test('a hand-over refused to a member arrives as a 403', () async {
      late http.Request seen;
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response.bytes(utf8.encode('{"detail":"only the group owner"}'), 403);
        }),
      );
      await expectLater(
        client.transferOwnership('tok', 'd2'),
        throwsA(isA<BackendException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
      expect(seen.method, 'PUT');
      expect(seen.url.path, '/groups/me/owner');
      expect(jsonDecode(seen.body), {'device_id': 'd2'});
    });

    test('revoking another device returns the rotated invite code', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"id":"g","name":"n","share_token":"new-code"}', 200),
      );
      expect(await client.revokeDevice('tok', 'other'), 'new-code');
    });

    test('revoking this device is leaving: 204 and no code', () async {
      final client = BackendClient('https://countscore.example.com',
          httpClient: MockClient((_) async => http.Response.bytes(const [], 204)));
      expect(await client.revokeDevice('tok', 'self'), isNull);
    });
  });

  group('group settings and usage', () {
    test('updateGroupSettings sends only the fields it is given, never the budget', () async {
      final seen = <http.Request>[];
      final client = BackendClient('https://countscore.example.com',
          httpClient: MockClient((request) async {
        seen.add(request);
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'comment_style': 'humorous',
              'comment_language': 'fr',
              'monthly_budget_cents': 100,
            })),
            200);
      }));

      final saved = await client.updateGroupSettings('tok', commentStyle: 'humorous');

      expect(saved, (commentStyle: 'humorous', commentLanguage: 'fr'));
      expect(seen.single.method, 'PATCH');
      expect(seen.single.url.path, '/groups/me/settings');
      expect(seen.single.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(seen.single.body), {'comment_style': 'humorous'});
    });

    test('groupUsage reads cents and the reset date', () async {
      final client = BackendClient('https://countscore.example.com',
          httpClient: _answering(
              '{"current_month_used_cents": 42, "budget_cents": 100,'
              ' "resets_at": "2026-10-01T00:00:00Z"}',
              200));

      final usage = await client.groupUsage('tok');

      expect(usage.usedCents, 42);
      expect(usage.budgetCents, 100);
      expect(usage.resetsAt, DateTime.utc(2026, 10, 1));
    });
  });
}
