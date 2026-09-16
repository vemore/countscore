// What the engine does with the reject reasons the server can name.
//
// The default is `markRejected`, which is terminal: the delta never goes again,
// and every shared row that depends on it then pushes a parent uuid the server
// never created and stalls on `parent_missing` for good. So each reason the
// server *can* return has to be a deliberate case, and this pins the two that
// resolve by adopting the server's identity instead.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/backend_client.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_engine.dart';
import 'package:countscore/services/sync/sync_store.dart';

const _group = '11111111-1111-4111-8111-111111111111';
const _me = '22222222-2222-4222-8222-222222222222';

void main() {
  late AppDatabase db;
  late SyncStore store;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SyncStore(db);
    await store.join((
      groupId: _group,
      groupName: 'Famille',
      shareToken: 'unused',
      deviceId: _me,
      deviceToken: 'unused',
    ));
    final games = DriftGameRepository(db);
    final players = DriftPlayerRepository(db);
    final game = await games.create(
      Game(name: 'Mardi', isLowestScoreWins: true, gameTypeId: 1),
    );
    await players.create(Player(gameId: game, name: 'Alice', orderIndex: 0));
    await store.shareGame(game, _group);
  });
  tearDown(() => db.close());

  /// A server that pulls nothing and refuses every pushed `game_type` with
  /// [reason], applying everything else.
  SyncEngine engineRefusingGameTypes(String reason, {List<String>? pushed}) {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/sync/pull')) {
        return http.Response(
          jsonEncode({'deltas': [], 'server_seq_max': 0, 'has_more': false}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final deltas = (body['deltas'] as List).cast<Map<String, dynamic>>();
      pushed?.addAll([for (final d in deltas) d['entity_type'] as String]);
      return http.Response(
        jsonEncode({
          'results': [
            for (final d in deltas)
              d['entity_type'] == 'game_type'
                  ? {'status': 'rejected', 'server_seq': null, 'reason': reason}
                  : {'status': 'applied', 'server_seq': 1, 'reason': null},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    return SyncEngine(store, BackendClient('https://example.test', httpClient: client), 'tok');
  }

  test('builtin_key_taken is resolved by adopting the server row, not rejected',
      () async {
    // Another device already holds the group's row for this built-in type, under
    // a uuid this one did not compute — an older group, linked by name before
    // built-in types linked by key. Rejecting would be permanent and would take
    // every game pointing at the type with it.
    final result = await engineRefusingGameTypes('builtin_key_taken').run();

    expect(result.failure, isNull);
    expect(await store.rejectedCount(), 0,
        reason: 'a rejected game_type would strand every game that references it');
  });

  test('an unhandled reason is still terminal', () async {
    // The counterweight: the default has to stay terminal, or a genuinely bad
    // delta would be retried forever.
    final result = await engineRefusingGameTypes('something_new').run();

    expect(result.failure, isNull);
    expect(await store.rejectedCount(), 1);
  });

  test('a resolved game_type does not loop the pass forever', () async {
    // `_resolve` returning true is progress, so the pass must terminate rather
    // than re-preparing the same delta on every round.
    final pushed = <String>[];
    await engineRefusingGameTypes('builtin_key_taken', pushed: pushed).run();

    expect(pushed.where((t) => t == 'game_type').length, lessThanOrEqualTo(3));
  });
}
