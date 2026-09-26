// The web upgrade path. On native, sqflite migrates the file before Drift opens
// it; on web there is no sqflite, and a browser that ran the PWA at v9 keeps its
// database. Drift's onUpgrade must then bring it to the current schema itself.
//
// Simulated on a native file: build the current schema, strip everything v10,
// v11, v12, v13, v14, v15, v16 and v21 added, stamp user_version 9, and reopen
// through Drift.
// v17, v18 and v19 add no column: v17 finds no keyless copy to dedupe, v18
// replays the v16 back-fill, which has nothing left to fill, and v19 finds no
// keyless row to give a key back to. v20 adds no column either. v21 adds
// `keypad_shortcut`, and fills it on the five built-ins that have one.

import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;

import 'package:countscore/models/game.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/schema_steps.dart';

void main() {
  sqflite.sqfliteFfiInit();

  test('a v9 browser database upgrades to the current schema through Drift', () async {
    final dir = await Directory.systemTemp.createTemp('countscore_web_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/countscore.sqlite');

    final fresh = AppDatabase.forTesting(NativeDatabase(file));
    await DriftGameRepository(fresh).create(Game(name: 'Avant', isLowestScoreWins: false));
    await fresh.close();

    final raw = await sqflite.databaseFactoryFfi.openDatabase(file.path);
    final triggers = await raw.rawQuery("SELECT name FROM sqlite_master WHERE type = 'trigger'");
    for (final t in triggers) {
      await raw.execute('DROP TRIGGER ${t['name']}');
    }
    for (final table in ['group_links', 'entity_versions', 'sync_inbox', 'sync_flags']) {
      await raw.execute('DROP TABLE $table');
    }
    for (final column in ['rejected_at', 'reject_reason']) {
      await raw.execute('ALTER TABLE outbox DROP COLUMN $column');
    }
    for (final column in ['device_id', 'group_name']) {
      await raw.execute('ALTER TABLE sync_state DROP COLUMN $column');
    }
    await raw.execute('ALTER TABLE games DROP COLUMN finishedAt');
    await raw.execute('DROP INDEX $gameTypesBuiltinKeyIndex');
    await raw.execute('ALTER TABLE game_types DROP COLUMN builtin_key');
    for (final column in ['rules', 'rules_slug', 'keypad_shortcut']) {
      await raw.execute('ALTER TABLE game_types DROP COLUMN $column');
    }
    // A v9 browser holds the ten types the seed wrote then, and no more.
    await raw.delete('game_types',
        where: 'name NOT IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        whereArgs: const [
          'ZapZap', 'Uno', 'Scrabble', 'Autre', 'Skyjo', //
          'Président', 'Belote', 'Tarot', 'Bridge', 'Rami',
        ]);
    await raw.execute('PRAGMA user_version = 9');
    await raw.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    expect((await DriftGameRepository(db).getAll()).single.name, 'Avant');
    for (final table in ['group_links', 'entity_versions', 'sync_inbox', 'sync_flags']) {
      await db.customSelect('SELECT COUNT(*) FROM $table').getSingle();
    }
    await db.customSelect('SELECT rejected_at, reject_reason FROM outbox').get();
    await db.customSelect('SELECT device_id, group_name FROM sync_state').get();
    await db.customSelect('SELECT finishedAt FROM games').get();
    // v13: the ten are back-filled and the twelve new ones arrive.
    final types = await db
        .customSelect('SELECT name, builtin_key FROM game_types ORDER BY id')
        .get();
    expect(types, hasLength(22));
    expect(types.first.data['builtin_key'], 'zapzap');
    expect(
      types.map((r) => r.data['builtin_key']).toSet(),
      containsAll(const ['other', 'yahtzee', 'six_nimmt', 'triomino']),
    );
    // v13 and v16: every built-in type but Autre has its shipped ruleset —
    // the nine old ones by seeded name, the twelve new ones by key.
    final slugs = await db
        .customSelect('SELECT builtin_key, rules_slug FROM game_types')
        .get();
    for (final r in slugs) {
      expect(r.data['rules_slug'], defaultRulesSlugs[r.data['builtin_key']],
          reason: '${r.data['builtin_key']} has the wrong ruleset');
    }
    // v21: the keypad shortcut, on the five built-ins that have one only.
    final shortcuts = await db
        .customSelect('SELECT builtin_key, keypad_shortcut FROM game_types')
        .get();
    final seeds = keypadShortcutSeeds();
    expect(seeds.keys.toSet(),
        {'zapzap', 'skyjo', 'belote', 'scrabble', 'rami'});
    for (final r in shortcuts) {
      expect(r.data['keypad_shortcut'], seeds[r.data['builtin_key']],
          reason: '${r.data['builtin_key']} has the wrong keypad shortcut');
    }
    // v15: one live row per built-in key.
    final index = await db
        .customSelect("SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = ?",
            variables: [const Variable(gameTypesBuiltinKeyIndex)])
        .get();
    expect(index, hasLength(1));
    final captureTriggers = await db
        .customSelect("SELECT COUNT(*) AS c FROM sqlite_master WHERE type = 'trigger'")
        .getSingle();
    expect(captureTriggers.data['c'], triggers.length);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);
  });
}
