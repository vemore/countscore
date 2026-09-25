// The v20 -> v21 step: `game_types.keypad_shortcut`, the score keypad's
// per-type key (wip/done/2026-09-18-keypad-has-no-per-game-shortcut.md). The
// column is added, and the live built-in rows that have a shortcut in the seed
// get it: ZapZap "0 ZapZap", Skyjo ×2, Belote 162, Scrabble +50, Rami 100.
//
// Built on the model of migration_v19_to_v20_test.dart: a current database is
// stepped back to v20 (the column dropped), then reopened through both
// engines' real upgrade callbacks and once more straight through `applyV21`.
// The back-fill is local: capture is suppressed, so a group-linked row pushes
// nothing and cannot outrank a shortcut the group already set.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v21_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  late int customType; // the user's own type, no key
  late int renamedSkyjo; // a Skyjo the user renamed: no key left
  late int deletedBelote; // an older Belote, deleted

  /// A current database stepped back to v20, holding the seeded built-ins
  /// (Skyjo renamed, so keyless), a deleted Belote, a type of the user's own,
  /// and ZapZap linked into a group so the capture trigger has a row to see.
  Future<void> writeV20File() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    Map<String, Object?> row(String? key, String name, String uuid,
            {int? deletedAt}) =>
        {
          'builtin_key': key,
          'name': name,
          'iconCodePoint': 0xe000,
          'cardColorValue': 0xFF000000,
          'isLowestScoreWins': 0,
          'isDefault': 0,
          'uuid': uuid,
          'created_at': 1,
          'updated_at': 1,
          'deleted_at': deletedAt,
        };
    customType = await db.insert('game_types', row(null, 'Maison', 'custom'));
    deletedBelote = await db.insert(
        'game_types', row('belote', 'Belote', 'belote-deleted', deletedAt: 5));
    renamedSkyjo = (await db.query('game_types',
            columns: ['id'], where: 'builtin_key = ?', whereArgs: ['skyjo']))
        .single['id'] as int;
    await db.update(
        'game_types', {'builtin_key': null, 'name': 'Skyjo maison'},
        where: 'id = ?', whereArgs: [renamedSkyjo]);

    final zapzapUuid = (await db.query('game_types',
            columns: ['uuid'],
            where: 'builtin_key = ? AND deleted_at IS NULL',
            whereArgs: ['zapzap']))
        .single['uuid'];
    await db.insert('group_links', {
      'group_id': 'g-1',
      'entity_type': 'game_type',
      'local_uuid': zapzapUuid,
      'remote_uuid': 'remote-zapzap',
    });

    await db.execute('ALTER TABLE game_types DROP COLUMN keypad_shortcut');
    await db.delete('outbox');
    await db.execute('PRAGMA user_version = 20');
    await db.close();
  }

  const selectAll =
      'SELECT id, builtin_key, deleted_at, keypad_shortcut FROM game_types';

  /// Every row of [rows] carries what v21 should have given it.
  void expectMigrated(List<Map<String, Object?>> rows) {
    String? shortcutOf(int id) =>
        rows.singleWhere((r) => r['id'] == id)['keypad_shortcut'] as String?;
    final live = {
      for (final r in rows)
        if (r['builtin_key'] != null && r['deleted_at'] == null)
          r['builtin_key'] as String: r['keypad_shortcut'],
    };
    expect(live['zapzap'], KeypadShortcut.value(0, label: '0 ZapZap').encode());
    expect(live['skyjo'], isNull, reason: 'the renamed Skyjo has no key');
    expect(live['scrabble'], KeypadShortcut.add(50).encode());
    expect(live['belote'], KeypadShortcut.value(162).encode());
    expect(live['rami'], KeypadShortcut.value(100).encode());
    for (final key in ['uno', 'president', 'tarot', 'bridge', 'other']) {
      expect(live[key], isNull, reason: '$key has no shortcut');
    }
    expect(shortcutOf(customType), isNull, reason: 'a user type was touched');
    expect(shortcutOf(renamedSkyjo), isNull,
        reason: 'a renamed type is the user\'s: it keeps no shortcut');
    expect(shortcutOf(deletedBelote), isNull,
        reason: 'a deleted row was rewritten');
  }

  test('native: the sqflite chain adds keypad_shortcut and fills the built-ins',
      () async {
    await writeV20File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), 21);
    expectMigrated(await db.rawQuery(selectAll));
  });

  test('the back-fill of a group-linked row enqueues no outbox row, and '
      'capture is back on afterwards', () async {
    await writeV20File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    // The linked ZapZap got its seed locally, and nothing is queued: pushed,
    // it would outrank a shortcut the group had already set on the type.
    expect(await db.query('outbox'), isEmpty);
    final flag = await db.query('sync_flags', where: 'id = 1');
    expect(flag.single['suppress'], 0, reason: 'suppress must be restored');

    // A real edit of the linked row is captured again.
    await db.update('game_types', {'name': 'ZapZap!'},
        where: "builtin_key = 'zapzap' AND deleted_at IS NULL");
    expect(await db.query('outbox', where: "entity_type = 'game_type'"),
        hasLength(1));
  });

  test("web: Drift's onUpgrade adds keypad_shortcut and fills the built-ins",
      () async {
    await writeV20File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows = await db.customSelect(selectAll).get();
    expectMigrated([for (final r in rows) r.data]);
    expect(await db.customSelect('SELECT * FROM outbox').get(), isEmpty,
        reason: 'the seed stays local on web too');
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 21);
  });

  test('replaying the step changes nothing, and keeps a shortcut the user set',
      () async {
    await writeV20File();
    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    // The user turned Belote's key into +10.
    const custom = '{"kind":"add","amount":10}';
    await db.update('game_types', {'keypad_shortcut': custom},
        where: 'builtin_key = ? AND deleted_at IS NULL', whereArgs: ['belote']);
    final before = await db.rawQuery(selectAll);

    Future<Set<String>> columnsOf(String table) async => {
          for (final r in await db.rawQuery('PRAGMA table_info($table)'))
            r['name'] as String,
        };
    await applyV21(db.execute, columnsOf);

    final after = await db.rawQuery(selectAll);
    expect(after, before);
  });

  test('the seeds are the five decided, and each decodes back to itself', () {
    final seeds = keypadShortcutSeeds();
    expect(seeds.keys.toSet(), {'zapzap', 'skyjo', 'belote', 'scrabble', 'rami'});
    for (final entry in seeds.entries) {
      expect(KeypadShortcut.decode(entry.value)?.encode(), entry.value,
          reason: entry.key);
    }
    expect(KeypadShortcut.decode(seeds['skyjo'])!.kind,
        KeypadShortcutKind.multiply);
  });
}
