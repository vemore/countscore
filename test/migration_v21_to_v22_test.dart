// The v21 -> v22 step: `game_types.max_rounds`, the number of rounds after
// which a game of the type is over
// (wip/done/2026-11-17-a-game-type-cannot-end-after-a-fixed-number-of-rounds.md),
// and Chouineurs, the first built-in that ends on it
// (wip/done/2026-11-17-chouineurs-is-not-a-built-in-game-type.md).
//
// Built on the model of migration_v20_to_v21_test.dart: a current database is
// stepped back to v21 — the column dropped, the Chouineurs row the current
// seed wrote deleted — then reopened through both engines' real upgrade
// callbacks and once more straight through `applyV22`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/schema_steps.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v22_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

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

  /// A current database stepped back to v21: the 22 built-ins of a v21 seed,
  /// a type of the user's own, and ZapZap linked into a group so the capture
  /// trigger has a row to see. [prepare] runs before the column is dropped,
  /// to add what one test needs.
  Future<void> writeV21File(
      {Future<void> Function(Database db)? prepare}) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    // A v21 seed never had Chouineurs.
    await db.delete('game_types',
        where: 'builtin_key = ?', whereArgs: ['chouineurs']);
    await db.insert('game_types', row(null, 'Maison', 'custom'));
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
    await prepare?.call(db);

    await db.execute('ALTER TABLE game_types DROP COLUMN max_rounds');
    await db.delete('outbox');
    await db.execute('PRAGMA user_version = 21');
    await db.close();
  }

  const selectAll = 'SELECT id, uuid, builtin_key, name, deleted_at, '
      'max_rounds, isLowestScoreWins, gameOverConditionType, '
      'gameOverThreshold, rules_slug FROM game_types ORDER BY id';

  /// The rows a v21 file holds, by uuid, read before the upgrade.
  late Set<String> uuidsBefore;

  Future<void> readUuidsBefore() async {
    final db = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(readOnly: true));
    uuidsBefore = {
      for (final r in await db.query('game_types', columns: ['uuid']))
        r['uuid'] as String,
    };
    await db.close();
  }

  /// Every pre-existing row reads null, and exactly one Chouineurs arrived,
  /// with its limit and its rules.
  void expectMigrated(List<Map<String, Object?>> rows) {
    final old = rows.where((r) => uuidsBefore.contains(r['uuid']));
    expect(old, hasLength(uuidsBefore.length));
    for (final r in old) {
      expect(r['max_rounds'], isNull,
          reason: '${r['builtin_key'] ?? r['name']} gained a round limit');
    }
    final added = rows.where((r) => !uuidsBefore.contains(r['uuid'])).toList();
    expect(added, hasLength(1), reason: 'only Chouineurs is inserted');
    final chouineurs = added.single;
    expect(chouineurs['builtin_key'], 'chouineurs');
    expect(chouineurs['name'], 'Chouineurs');
    expect(chouineurs['deleted_at'], isNull);
    expect(chouineurs['max_rounds'], 4);
    expect(chouineurs['isLowestScoreWins'], 0);
    expect(chouineurs['gameOverConditionType'], isNull);
    expect(chouineurs['gameOverThreshold'], isNull);
    expect(chouineurs['rules_slug'], 'chouineurs');
  }

  test('native: the sqflite chain adds max_rounds and inserts Chouineurs once',
      () async {
    await writeV21File();
    await readUuidsBefore();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), 22);
    final columns = {
      for (final r in await db.rawQuery('PRAGMA table_info(game_types)'))
        r['name'] as String,
    };
    expect(columns, contains('max_rounds'));
    expectMigrated(await db.rawQuery(selectAll));
    expect(await db.query('outbox'), isEmpty,
        reason: 'the step pushes nothing');
    final flag = await db.query('sync_flags', where: 'id = 1');
    expect(flag.single['suppress'], 0, reason: 'suppress must be restored');
  });

  test("web: Drift's onUpgrade adds max_rounds and inserts Chouineurs once",
      () async {
    await writeV21File();
    await readUuidsBefore();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows = await db.customSelect(selectAll).get();
    expectMigrated([for (final r in rows) r.data]);
    expect(await db.customSelect('SELECT * FROM outbox').get(), isEmpty);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 22);
  });

  test('replaying the step changes nothing, and inserts nothing', () async {
    await writeV21File();
    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    // The user lifted the limit on Chouineurs and set one on their own type:
    // a replay must keep both choices.
    await db.update('game_types', {'max_rounds': null},
        where: 'builtin_key = ?', whereArgs: ['chouineurs']);
    await db.update('game_types', {'max_rounds': 6},
        where: 'uuid = ?', whereArgs: ['custom']);
    final before = await db.rawQuery(selectAll);

    Future<Set<String>> columnsOf(String table) async => {
          for (final r in await db.rawQuery('PRAGMA table_info($table)'))
            r['name'] as String,
        };
    await applyV22(db.execute, columnsOf);

    expect(await db.rawQuery(selectAll), before);
  });

  test('a live user type named "Chouineurs" gets no second one', () async {
    await writeV21File(prepare: (db) async {
      // The user's own, made before the built-in existed, in another case.
      await db.insert('game_types', row(null, 'chouineurs', 'mine'));
    });

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    final named = await db.rawQuery(
        "SELECT uuid, builtin_key, max_rounds FROM game_types "
        "WHERE name = 'Chouineurs' COLLATE NOCASE");
    expect(named, hasLength(1));
    expect(named.single['uuid'], 'mine');
    expect(named.single['builtin_key'], isNull,
        reason: "the user's row is kept as theirs");
    expect(named.single['max_rounds'], isNull);
    expect(
        await db.query('game_types',
            where: 'builtin_key = ?', whereArgs: ['chouineurs']),
        isEmpty);
  });

  test('a Chouineurs the user deleted is not resurrected', () async {
    await writeV21File(prepare: (db) async {
      await db.insert('game_types',
          row('chouineurs', 'Chouineurs', 'deleted', deletedAt: 5));
    });

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    final rows = await db.query('game_types',
        where: 'builtin_key = ?', whereArgs: ['chouineurs']);
    expect(rows, hasLength(1));
    expect(rows.single['deleted_at'], 5);
  });

  test('a Chouineurs pulled from a newer member gets its limit, locally',
      () async {
    // A v21 device in a group with a v22 one pulled the built-in before it
    // knew the column: the row is keyed and linked, and its limit is NULL.
    await writeV21File(prepare: (db) async {
      await db.insert(
          'game_types', row('chouineurs', 'Chouineurs', 'pulled'));
      await db.insert('group_links', {
        'group_id': 'g-1',
        'entity_type': 'game_type',
        'local_uuid': 'pulled',
        'remote_uuid': 'remote-chouineurs',
      });
    });

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    final rows = await db.query('game_types',
        where: 'builtin_key = ?', whereArgs: ['chouineurs']);
    expect(rows, hasLength(1), reason: 'the key is held: no insert');
    expect(rows.single['uuid'], 'pulled');
    expect(rows.single['max_rounds'], 4);
    expect(rows.single['updated_at'], 1, reason: 'the fill is not an edit');
    // Not pushed: it would outrank whatever the group chose for the type.
    expect(await db.query('outbox'), isEmpty);
  });

  group('a user "Chouineurs" from before v19', () {
    // v19 claims a keyless row named like a built-in; it must not claim one
    // for a type added later, or the same user type would end keyed (and given
    // 4 rounds by v22) on a device upgrading from v18, and stay the user's on
    // one upgrading from v21. `builtinKeysAfterV19`.
    Future<void> writeV18File() async {
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DatabaseService.schemaVersion,
          onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
        ),
      );
      await db.delete('game_types',
          where: 'builtin_key = ?', whereArgs: ['chouineurs']);
      await db.insert('game_types', {
        ...row(null, 'Chouineurs', 'mine'),
        'gameOverConditionType': 'firstPlayerOver',
        'gameOverThreshold': 60,
      });
      await db.execute('ALTER TABLE game_types DROP COLUMN max_rounds');
      await db.execute('PRAGMA user_version = 18');
      await db.close();
    }

    void expectKeptAsTheUsers(List<Map<String, Object?>> rows) {
      final named = rows
          .where((r) => (r['name'] as String).toLowerCase() == 'chouineurs')
          .toList();
      expect(named, hasLength(1), reason: 'no second Chouineurs');
      expect(named.single['uuid'], 'mine');
      expect(named.single['builtin_key'], isNull,
          reason: 'v19 claimed a type added after it');
      expect(named.single['max_rounds'], isNull);
      expect(named.single['gameOverThreshold'], 60);
      expect(rows.where((r) => r['builtin_key'] == 'chouineurs'), isEmpty);
    }

    const select = 'SELECT uuid, name, builtin_key, max_rounds, '
        'gameOverThreshold FROM game_types';

    test('native: it stays keyless, with no limit, and alone', () async {
      await writeV18File();
      final db = await DatabaseService.instance.openForTesting(path);
      addTearDown(db.close);
      expectKeptAsTheUsers(await db.rawQuery(select));
    });

    test('web: the same through Drift', () async {
      await writeV18File();
      final db = AppDatabase.forTesting(NativeDatabase(File(path)));
      addTearDown(db.close);
      final rows = await db.customSelect(select).get();
      expectKeptAsTheUsers([for (final r in rows) r.data]);
    });
  });

  test('the seeds hold Chouineurs alone, at 4', () {
    expect(maxRoundsSeeds(), {'chouineurs': 4});
    expect(GameType.chouineurs().maxRounds, 4);
  });
}
