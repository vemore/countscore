// The v22 -> v23 step: the sync queue tells groups apart
// (wip/done/2026-11-25-multi-group-storage.md). `group_id` on `outbox`,
// `sync_inbox` and `entity_versions`, back-filled from the one membership an
// upgraded install has, and capture triggers that queue a row for its group —
// a player or game type once per group it is linked in.
//
// Built on the model of migration_v21_to_v22_test.dart: a current database is
// stepped back to v22 — the three columns and their indexes dropped, the v11
// triggers put back — and filled as a v22 device in one group with work still
// queued, then reopened through both engines' real upgrade callbacks and once
// more straight through `applyV23`. The pre-v23 credentials (one pair under two
// fixed keys) are read back through the same path the app takes on start.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/schema_steps.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/services/sync/sync_reconcile.dart';
import 'package:countscore/services/sync/sync_schema.dart';
import 'package:countscore/services/sync/sync_store.dart';

const _group = '11111111-1111-4111-8111-111111111111';
const _device = '22222222-2222-4222-8222-222222222222';
const _other = '33333333-3333-4333-8333-333333333333';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v23_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  /// A current database stepped back to v22. With [member], it is a device in
  /// [_group] holding a shared game whose capture is still queued, a player
  /// renamed since it was linked, a delta already prepared, one the server
  /// refused, a quarantined pulled delta and a recorded version. Without, it
  /// has never joined, and an outbox row nobody can claim is left over.
  Future<void> writeV22File({bool member = true}) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    for (final index in [
      'idx_outbox_group_unsent', 'idx_sync_inbox_group_seq', 'idx_entity_versions_group', //
    ]) {
      await db.execute('DROP INDEX $index');
    }
    for (final table in syncTablesByGroup) {
      await db.execute('ALTER TABLE $table DROP COLUMN group_id');
    }
    // The capture triggers as v11 wrote them, which v22 still had.
    final triggers = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'trigger' AND name NOT LIKE '%_inherit'");
    for (final t in triggers) {
      await db.execute('DROP TRIGGER ${t['name']}');
    }
    for (final statement in syncV11Statements) {
      await db.execute(statement);
    }

    if (member) {
      await db.insert('sync_state', {
        'group_id': _group,
        'group_name': 'Famille',
        'device_id': _device,
        'last_server_seq': 42,
        'last_lamport': 7,
      });
      final alice = await db.insert('players',
          {'name': 'Alice', 'uuid': 'alice', 'created_at': 1, 'updated_at': 1});
      await db.insert('group_links', {
        'group_id': _group,
        'entity_type': 'player',
        'local_uuid': 'alice',
        'remote_uuid': 'remote-alice',
      });
      // Shared, so every row is captured by the v11 triggers.
      final game = await db.insert('games', {
        'name': 'Mardi',
        'isLowestScoreWins': 1,
        'createdAt': '2026-11-24T20:00:00.000',
        'uuid': 'game',
        'created_at': 1,
        'updated_at': 1,
        'group_id': _group,
      });
      await db.insert('game_players', {
        'gameId': game,
        'player_id': alice,
        'name': 'Alice',
        'orderIndex': 0,
        'uuid': 'membership',
        'created_at': 1,
        'updated_at': 1,
      });
      await db.update('players', {'name': 'Alice B'}, where: 'id = ?', whereArgs: [alice]);
      await db.insert('outbox', {
        'entity_type': 'round',
        'entity_uuid': 'prepared-round',
        'op': 'upsert',
        'payload': '{"uuid":"prepared-round","payload":{}}',
        'client_lamport': 7,
        'created_at': 1,
      });
      await db.insert('outbox', {
        'entity_type': 'score',
        'entity_uuid': 'refused-score',
        'op': 'upsert',
        'payload': '',
        'client_lamport': 6,
        'created_at': 1,
        'rejected_at': 2,
        'reject_reason': 'invalid',
      });
      await db.insert('sync_inbox', {
        'server_seq': 40,
        'delta': '{}',
        'reason': 'round',
        'created_at': 1,
      });
      await db.insert('entity_versions', {
        'entity_type': 'game',
        'entity_uuid': 'game',
        'lamport': 3,
        'origin_device_id': _other,
      });
    } else {
      await db.insert('outbox', {
        'entity_type': 'game',
        'entity_uuid': 'stray',
        'op': 'upsert',
        'payload': '',
        'client_lamport': 0,
        'created_at': 1,
      });
    }
    await db.execute('PRAGMA user_version = 22');
    await db.close();
  }

  /// The v22 file's sync rows, read before the upgrade.
  late Map<String, List<Map<String, Object?>>> before;

  Future<void> readBefore() async {
    final db = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(readOnly: true));
    before = {
      for (final table in [...syncTablesByGroup, 'sync_state'])
        table: await db.rawQuery('SELECT * FROM $table ORDER BY rowid'),
    };
    await db.close();
  }

  /// Every row of [before] is still there, unchanged, and attributed to
  /// [_group]; the membership is as it was.
  void expectKept(Map<String, List<Map<String, Object?>>> after) {
    expect(after['sync_state'], before['sync_state']);
    expect(before['outbox'], hasLength(greaterThanOrEqualTo(5)),
        reason: 'game, membership, player rename, prepared, refused');
    for (final table in syncTablesByGroup) {
      final rows = after[table]!;
      expect(rows, hasLength(before[table]!.length), reason: table);
      for (var i = 0; i < rows.length; i++) {
        expect(rows[i]['group_id'], _group, reason: '$table row $i');
        expect(Map.of(rows[i])..remove('group_id'), before[table]![i],
            reason: '$table row $i');
      }
    }
  }

  Future<Map<String, List<Map<String, Object?>>>> readAfter(
          Future<List<Map<String, Object?>>> Function(String sql) query) async =>
      {
        for (final table in [...syncTablesByGroup, 'sync_state'])
          table: await query('SELECT * FROM $table ORDER BY rowid'),
      };

  test('native: the membership and every queued row are kept, attributed to the group',
      () async {
    await writeV22File();
    await readBefore();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), 23);
    expectKept(await readAfter(db.rawQuery));

    // The capture triggers queue for the group from now on.
    await db.update('players', {'name': 'Alice C'}, where: "uuid = 'alice'");
    await db.update('games', {'name': 'Mercredi'}, where: "uuid = 'game'");
    final fresh = await db.rawQuery(
        'SELECT entity_type, group_id FROM outbox WHERE id > ? ORDER BY id',
        [before['outbox']!.last['id']]);
    expect(fresh, [
      {'entity_type': 'player', 'group_id': _group},
      {'entity_type': 'game', 'group_id': _group},
    ]);
  });

  test("web: Drift's onUpgrade keeps the membership and every queued row", () async {
    await writeV22File();
    await readBefore();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    expectKept(await readAfter((sql) async =>
        [for (final r in await db.customSelect(sql).get()) r.data]));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 23);

    // What the app counts and pushes for the group is what was queued.
    final store = SyncStore(db);
    final m = (await store.membership(_group))!;
    expect(m.lastServerSeq, 42);
    expect(m.lastLamport, 7);
    expect(await store.rejectedCount(groupId: _group), 1);
    expect(await store.pendingCount(groupId: _group),
        await store.pendingCount(), reason: 'nothing queued outside the group');
    expect(await store.pendingCount(groupId: _group), greaterThanOrEqualTo(4));
  });

  test('the credentials of the one group are kept: moved under its id, the old keys deleted',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSyncCredentials.legacyDeviceTokenKey: 'device-token',
      SecureSyncCredentials.legacyShareTokenKey: 'share-token',
    });
    await writeV22File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);
    final credentials = SecureSyncCredentials();

    // What GroupProvider does on start.
    final report = await reconcileMemberships(SyncStore(db), credentials);

    expect(report.left, isEmpty, reason: 'the membership is kept: no re-join');
    expect(report.forgotten, isEmpty);
    expect(await SyncStore(db).membership(), isNotNull);
    expect(await credentials.deviceToken(_group), 'device-token');
    expect(await credentials.shareToken(_group), 'share-token');
    expect(await credentials.groupIds(), {_group});
    final keys = (await const FlutterSecureStorage().readAll()).keys;
    expect(keys, isNot(contains(SecureSyncCredentials.legacyDeviceTokenKey)));
    expect(keys, isNot(contains(SecureSyncCredentials.legacyShareTokenKey)));
  });

  test('a device that never joined drops the row no group can claim', () async {
    await writeV22File(member: false);

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.query('outbox'), isEmpty);
    expect(await db.query('sync_state'), isEmpty);
  });

  test('replaying the step changes nothing', () async {
    await writeV22File();
    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);
    final first = await readAfter(db.rawQuery);
    final schema = await db.rawQuery('SELECT type, name, sql FROM sqlite_master ORDER BY name');

    Future<Set<String>> columnsOf(String table) async => {
          for (final r in await db.rawQuery('PRAGMA table_info($table)'))
            r['name'] as String,
        };
    await applyV23(db.execute, columnsOf);

    expect(await readAfter(db.rawQuery), first);
    expect(await db.rawQuery('SELECT type, name, sql FROM sqlite_master ORDER BY name'),
        schema);
  });
}
