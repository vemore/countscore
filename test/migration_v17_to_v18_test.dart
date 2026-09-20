// The v17 → v18 step: `applyV16` runs a second time, so a `rules_slug` the
// pre-1.3.1 game-type editor wiped after v16 had already passed comes back.
//
// Built on the model of migration_v16_to_v17_test.dart: a current database is
// stepped back to what the owner's damaged v17 file holds — rows keyed but with
// `rules_slug`, `rules` and `isDefault` cleared, exactly as the old editor left
// them — then opened through both engines' real upgrade callbacks (sqflite's
// chain on native, Drift's `onUpgrade` on web) and once more straight through
// `applyV18`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v18_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  // The rows the acceptance names, in the damaged v17 file.
  late int zapzap; // keyed, wiped — the owner's ZapZap
  late int sixNimmt; // keyed, wiped — the owner's 6 qui prend
  late int wipedWithOwnRules; // keyed, wiped slug, but the user wrote rules
  late int renamed; // no key, no slug — renamed out of the built-ins
  late int mine; // no key, user's own type
  late int untouched; // keyed, slug intact

  /// A current database stepped back to v17, with the damage the old editor
  /// did: `rules_slug` and `isDefault` cleared on rows that keep their key.
  Future<void> writeV17File() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );

    Future<int> idOf(String key) async => (await db.query('game_types',
            columns: ['id'], where: 'builtin_key = ?', whereArgs: [key]))
        .single['id'] as int;

    Future<void> wipe(int id, {String? rules}) => db.update(
          'game_types',
          {'rules_slug': null, 'rules': rules, 'isDefault': 0},
          where: 'id = ?',
          whereArgs: [id],
        );

    zapzap = await idOf('zapzap');
    sixNimmt = await idOf('six_nimmt');
    wipedWithOwnRules = await idOf('belote');
    untouched = await idOf('tarot');
    await wipe(zapzap);
    await wipe(sixNimmt);
    await wipe(wipedWithOwnRules, rules: 'Nos règles maison.');

    // A type the user renamed: the rename cleared the key, and it never had a
    // slug (it was renamed before v16). Nothing may fill one in.
    renamed = await idOf('skyjo');
    await db.update(
      'game_types',
      {'builtin_key': null, 'name': 'Skyjo du dimanche', 'rules_slug': null},
      where: 'id = ?',
      whereArgs: [renamed],
    );
    // A type the user built themselves, sharing no identity with a built-in.
    mine = await db.insert('game_types', {
      'name': 'Le jeu du mardi',
      'iconCodePoint': 0xe000,
      'cardColorValue': 0xFF000000,
      'isLowestScoreWins': 0,
      'isDefault': 0,
      'uuid': 'mine-1',
      'created_at': 1,
      'updated_at': 1,
    });

    await db.execute('PRAGMA user_version = 17');
    await db.close();
  }

  /// `id → (rules_slug, rules, builtin_key)`.
  Map<int, List<Object?>> stateById(List<Map<String, Object?>> rows) => {
        for (final r in rows)
          r['id'] as int: [r['rules_slug'], r['rules'], r['builtin_key']],
      };

  void expectRestored(Map<int, List<Object?>> state) {
    // Criterion 1: a wiped row that kept its key gets its shipped ruleset back.
    expect(state[zapzap], ['zapzap', null, 'zapzap'],
        reason: "ZapZap's ruleset was not restored");
    expect(state[sixNimmt], ['six_nimmt', null, 'six_nimmt'],
        reason: "6 qui prend's ruleset was not restored");
    // Criterion 3: only the slug is filled — a hand-written ruleset stands.
    expect(state[wipedWithOwnRules],
        ['belote', 'Nos règles maison.', 'belote'],
        reason: 'a ruleset the user wrote was touched');
    // Criterion 2: a row with no key is left exactly as it was.
    expect(state[renamed], [null, null, null],
        reason: 'a renamed type gained a slug it never had');
    expect(state[mine], [null, null, null],
        reason: "a user's own type gained a slug");
    // A slug that was never wiped is not rewritten either.
    expect(state[untouched], ['tarot', null, 'tarot']);
  }

  test('native: the sqflite chain restores the wiped rulesets', () async {
    await writeV17File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), DatabaseService.schemaVersion);
    expectRestored(stateById(await db.query('game_types')));
  });

  test("web: Drift's onUpgrade restores the wiped rulesets", () async {
    await writeV17File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows = await db
        .customSelect('SELECT id, rules_slug, rules, builtin_key FROM game_types')
        .get();
    expectRestored(stateById(rows.map((r) => r.data).toList()));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, DatabaseService.schemaVersion);
  });

  test('applyV18 inserts nothing and replays as a no-op', () async {
    await writeV17File();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    // A built-in the user deleted, whose slug the editor wiped before the
    // delete. `applyV16` has no `deleted_at` guard, so it *does* rewrite the
    // slug of a tombstone — which is harmless and is not resurrection: the row
    // stays dead, and the outbox row the UPDATE enqueues is discarded when the
    // delta is built (`_build`, `lib/services/sync/sync_store.dart`). The
    // invariant is that no row comes back and none is inserted.
    await db.update('game_types', {'deleted_at': 9, 'rules_slug': null},
        where: 'builtin_key = ?', whereArgs: ['uno']);
    final before = (await db.query('game_types')).length;

    await applyV18(db.execute);
    final once = await db.query('game_types', orderBy: 'id');
    await applyV18(db.execute);

    expect(await db.query('game_types', orderBy: 'id'), once,
        reason: 'a replay changed a row');
    expect(once, hasLength(before), reason: 'the step inserted a row');
    final uno = once.singleWhere((r) => r['builtin_key'] == 'uno');
    expect(uno['deleted_at'], 9,
        reason: 'a type the user deleted was brought back to life');
    expect(uno['rules_slug'], 'uno',
        reason: 'the step is not expected to skip a tombstone, only to leave '
            'it dead');
    expectRestored(stateById(once));
  });

  test('isDefault is not restored: builtin_key is the only built-in test',
      () async {
    await writeV17File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    final row = (await db
            .query('game_types', where: 'id = ?', whereArgs: [zapzap]))
        .single;
    expect(row['isDefault'], 0,
        reason: 'v18 restores the slug, not the flag nothing reads');
    expect(row['rules_slug'], 'zapzap');
  });
}
