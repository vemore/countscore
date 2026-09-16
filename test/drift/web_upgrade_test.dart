// The web upgrade path. On native, sqflite migrates the file before Drift opens
// it; on web there is no sqflite, and a browser that ran the PWA at v9 keeps its
// database. Drift's onUpgrade must then bring it to the current schema itself.
//
// Simulated on a native file: build the current schema, strip everything v10,
// v11 and v12 added, stamp user_version 9, and reopen through Drift.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;

import 'package:countscore/models/game.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

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
    final captureTriggers = await db
        .customSelect("SELECT COUNT(*) AS c FROM sqlite_master WHERE type = 'trigger'")
        .getSingle();
    expect(captureTriggers.data['c'], triggers.length);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);
  });
}
