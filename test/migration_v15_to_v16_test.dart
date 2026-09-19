// The v15 → v16 step: the twelve built-in types added in v14 get the rulesets
// that shipped for them, back-filled on `rules_slug` by `builtin_key`.
//
// Built on the model of migration_v14_to_v15_test.dart — build the old
// `game_types` by hand, run the production step, assert what it fills and what
// it leaves alone — then once more through both engines' real upgrade
// callbacks: sqflite's chain on native, Drift's `onUpgrade` on web.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/game_rules_catalog.dart';
import 'package:countscore/services/sync/sync_schema.dart';

/// The twelve types v14 inserted without a ruleset.
const _longTail = [
  'coinche', 'yahtzee', 'phase10', 'flip7', 'mille_bornes', 'rummikub', //
  'six_nimmt', 'qwirkle', 'farkle', 'canasta', 'wizard', 'triomino',
];

/// `game_types` as of v15.
Future<void> _createV15(Database db) => db.execute('''
    CREATE TABLE game_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      builtin_key TEXT,
      name TEXT NOT NULL,
      iconCodePoint INTEGER NOT NULL,
      cardColorValue INTEGER NOT NULL,
      isLowestScoreWins INTEGER NOT NULL,
      isDefault INTEGER NOT NULL DEFAULT 0,
      rules TEXT,
      rules_slug TEXT,
      uuid TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER,
      group_id TEXT
    )
  ''');

var _seq = 0;

Future<int> _insertType(
  Database db,
  String name, {
  String? key,
  String? slug,
  String? rules,
  bool isDefault = true,
}) =>
    db.insert('game_types', {
      'builtin_key': key,
      'name': name,
      'iconCodePoint': 0xe000,
      'cardColorValue': 0xFF000000,
      'isLowestScoreWins': 0,
      'isDefault': isDefault ? 1 : 0,
      'rules': rules,
      'rules_slug': slug,
      'uuid': 'uuid-${_seq++}',
      'created_at': 1,
      'updated_at': 1,
    });

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('applyV16', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 15, onCreate: (db, _) => _createV15(db)),
      );
    });
    tearDown(() => db.close());

    Future<String?> slugOf(int id) async =>
        (await db.query('game_types', where: 'id = ?', whereArgs: [id]))
            .single['rules_slug'] as String?;

    test('back-fills the twelve rows of an existing database, by key', () async {
      final ids = <String, int>{
        // The stored name does not matter: a Japanese device stores its own.
        for (final key in _longTail) key: await _insertType(db, 'nom-$key', key: key),
      };

      await applyV16(db.execute);

      for (final key in _longTail) {
        expect(await slugOf(ids[key]!), key, reason: '$key has no ruleset');
      }
    });

    test('a renamed type keeps its slug, and one renamed before gains none', () async {
      // Renaming clears the key and keeps the slug (game_types_screen.dart).
      final renamed = await _insertType(db, 'Belote coinchée', slug: 'belote');
      // A Yahtzee renamed before v16 lost its key while it had no slug yet.
      final yams = await _insertType(db, 'Yams');
      final autre = await _insertType(db, 'Autre', key: 'other');
      final mine = await _insertType(db, 'Yahtzee', isDefault: false);

      await applyV16(db.execute);

      expect(await slugOf(renamed), 'belote');
      expect(await slugOf(yams), isNull);
      expect(await slugOf(autre), isNull, reason: 'Autre has no rules of its own');
      expect(await slugOf(mine), isNull, reason: "a user's own type is not built in");
    });

    test('a slug already set is not overwritten, nor a written ruleset', () async {
      final id = await _insertType(db, 'Farkle', key: 'farkle', slug: 'farkle', rules: 'À 5000.');

      await applyV16(db.execute);

      final row = (await db.query('game_types', where: 'id = ?', whereArgs: [id])).single;
      expect(row['rules_slug'], 'farkle');
      expect(row['rules'], 'À 5000.');
    });

    test('inserts nothing, so a deleted type is not resurrected; replays are no-ops', () async {
      await _insertType(db, 'Qwirkle', key: 'qwirkle');

      await applyV16(db.execute);
      final once = await db.query('game_types', orderBy: 'id');
      await applyV16(db.execute);

      expect(await db.query('game_types', orderBy: 'id'), once);
      expect(once, hasLength(1));
    });
  });

  test('the slug map, the seed and the shipped assets agree', () {
    expect(defaultRulesSlugs.values.toSet(), GameRulesCatalog.slugs.toSet());
    expect(defaultRulesSlugs, hasLength(21));
    for (final type in GameType.defaultGameTypes()) {
      expect(type.rulesSlug, defaultRulesSlugs[type.builtinKey],
          reason: '${type.builtinKey} seeds a slug the map does not know');
    }
  });

  group('through the production upgrade callbacks', () {
    late Directory dir;
    late String path;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('countscore_v16_');
      path = '${dir.path}/countscore.db';
    });
    tearDown(() => dir.delete(recursive: true));

    /// A current database stepped back to what a v15 install holds: the twelve
    /// seeded without a slug, and `user_version` 15.
    Future<void> writeV15File() async {
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DatabaseService.schemaVersion,
          onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
        ),
      );
      final placeholders = List.filled(_longTail.length, '?').join(', ');
      await db.rawUpdate(
        'UPDATE game_types SET rules_slug = NULL WHERE builtin_key IN ($placeholders)',
        _longTail,
      );
      await db.execute('PRAGMA user_version = 15');
      await db.close();
    }

    Map<String, String?> slugsByKey(List<Map<String, Object?>> rows) => {
          for (final r in rows) r['builtin_key'] as String: r['rules_slug'] as String?,
        };

    void expectEveryRuleset(Map<String, String?> slugs) {
      expect(slugs, hasLength(GameType.defaultGameTypes().length));
      for (final entry in defaultRulesSlugs.entries) {
        expect(slugs[entry.key], entry.value, reason: '${entry.key} has no ruleset');
      }
      expect(slugs['other'], isNull);
    }

    test('native: the sqflite chain back-fills the twelve', () async {
      await writeV15File();

      final db = await DatabaseService.instance.openForTesting(path);
      addTearDown(db.close);

      expect(await db.getVersion(), 16);
      expectEveryRuleset(slugsByKey(await db.query('game_types')));
    });

    test("web: Drift's onUpgrade back-fills the twelve", () async {
      await writeV15File();

      final db = AppDatabase.forTesting(NativeDatabase(File(path)));
      addTearDown(db.close);

      final rows = await db.customSelect('SELECT builtin_key, rules_slug FROM game_types').get();
      expectEveryRuleset(slugsByKey(rows.map((r) => r.data).toList()));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, 16);
    });
  });
}
