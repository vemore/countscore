// The PWA reload bug (wip/done/2026-09-19-pwa-reload-reruns-the-database-creation.md).
//
// On the web, drift's IndexedDB storage writes to IndexedDB only after a
// statement run outside a transaction, so the schema version and every
// committed transaction stayed in memory, and a reload reran `onCreate`.
// The browser half is `integration_test/reload_persistence_test.dart`; these
// pin the two halves of the fix that run anywhere:
//
// - PersistenceFlushInterceptor issues its flush statement outside any
//   transaction after the first open and after each outermost transaction;
// - `onCreate` completes on a database that already holds its rows (the state
//   of a browser that hit the bug), and does not duplicate or resurrect a type.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/connection/persistence_flush.dart';
import 'package:countscore/services/drift/database.dart';

/// Records each custom statement, and whether it ran inside a transaction.
class _Recorder extends QueryInterceptor {
  final List<String> log = [];

  @override
  Future<void> runCustom(QueryExecutor executor, String statement, List<Object?> args) {
    log.add('${executor is TransactionExecutor ? 'tx' : 'root'}: $statement');
    return executor.runCustom(statement, args);
  }
}

const _flush = 'root: ${PersistenceFlushInterceptor.flushStatement}';

void main() {
  late _Recorder recorder;
  late AppDatabase db;

  setUp(() {
    recorder = _Recorder();
    db = AppDatabase.forTesting(
      NativeDatabase.memory()
          .interceptWith(recorder)
          .interceptWith(PersistenceFlushInterceptor()),
    );
  });
  tearDown(() => db.close());

  Future<void> insert(String value) =>
      db.customStatement("INSERT INTO scratch (x) VALUES ('$value')");

  /// Opens the database and creates the scratch table, then forgets both.
  Future<void> openAndClearLog() async {
    await db.customStatement('CREATE TABLE scratch (x TEXT)');
    recorder.log.clear();
  }

  test('flushes once, outside any transaction, after the database first opens', () async {
    await db.customSelect('SELECT 1 FROM games').get();
    await db.customSelect('SELECT 1 FROM games').get();

    expect(recorder.log.where((s) => s == _flush), hasLength(1));
  });

  test('flushes outside the transaction once it commits', () async {
    await openAndClearLog();

    await db.transaction(() => insert('a'));

    expect(recorder.log, [startsWith('tx: INSERT INTO scratch'), _flush]);
  });

  test('a nested transaction flushes once, after the outermost one', () async {
    await openAndClearLog();

    await db.transaction(() async {
      await insert('a');
      await db.transaction(() => insert('b'));
      expect(recorder.log, isNot(contains(_flush)));
    });

    expect(recorder.log.where((s) => s == _flush), hasLength(1));
    expect(recorder.log.last, _flush);
  });

  test('a rolled back transaction still flushes, and its error still surfaces', () async {
    await openAndClearLog();

    await expectLater(
      db.transaction(() async {
        await insert('a');
        throw StateError('boom');
      }),
      throwsStateError,
    );

    expect(recorder.log.last, _flush);
    expect(await db.customSelect('SELECT x FROM scratch').get(), isEmpty);
  });

  test('a batch flushes after it commits', () async {
    await openAndClearLog();

    await db.batch((b) => b.customStatement("INSERT INTO scratch (x) VALUES ('a')"));

    expect(recorder.log.last, _flush);
  });

  test('onCreate reruns cleanly on a database whose user_version was lost', () async {
    final dir = await Directory.systemTemp.createTemp('countscore_reload_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/countscore.sqlite');

    final first = AppDatabase.forTesting(NativeDatabase(file));
    final games = DriftGameRepository(first);
    final keep = await games.create(Game(name: 'Kept', isLowestScoreWins: false));
    // A built-in type deleted as a tombstone (a shared one) stays deleted.
    await first.customStatement(
        "UPDATE game_types SET deleted_at = 1 WHERE builtin_key = 'uno'");
    await first.close();

    // What a browser hit by the bug holds: every row, and version 0.
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = 0');
    raw.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final types = await db
        .customSelect(
            'SELECT builtin_key FROM game_types WHERE deleted_at IS NULL ORDER BY id')
        .get();
    final expected = GameType.defaultGameTypes()
        .map((t) => t.builtinKey)
        .where((k) => k != 'uno')
        .toList();
    expect(types.map((r) => r.data['builtin_key']).toList(), expected);
    expect((await DriftGameRepository(db).getAll()).single.id, keep);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);
  });
}
