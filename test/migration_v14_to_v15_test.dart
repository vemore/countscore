// The v14 → v15 step: a unique index on live built-in game types.
//
// Built on the model of migration_v13_to_v14_test.dart — build the old
// `game_types` by hand, run the production step, assert what it guards and what
// it leaves alone. The promises: a second live copy of a built-in type is
// refused; a user's own type (no key) is never constrained, not even by a
// deleted type of the same name; and a database that somehow already holds two
// keyed copies still opens, losing a key but never a row.

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_schema.dart';

/// `game_types` as of v14, plus the one `games` column the step must not break.
Future<void> _createV14(Database db) async {
  await db.execute('''
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
  await db.execute('''
    CREATE TABLE games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      gameTypeId INTEGER
    )
  ''');
}

var _seq = 0;

Future<int> _insertType(
  Database db,
  String name, {
  String? key,
  bool isDefault = true,
  int? deletedAt,
}) =>
    db.insert('game_types', {
      'builtin_key': key,
      'name': name,
      'iconCodePoint': 0xe000,
      'cardColorValue': 0xFF000000,
      'isLowestScoreWins': 0,
      'isDefault': isDefault ? 1 : 0,
      'uuid': 'uuid-${_seq++}',
      'created_at': 1,
      'updated_at': 1,
      'deleted_at': deletedAt,
    });

void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 14, onCreate: (db, _) => _createV14(db)),
    );
  });
  tearDown(() => db.close());

  Future<void> upgrade() => applyV15(db.execute);

  test('a second live copy of a built-in type is refused', () async {
    await _insertType(db, 'Belote', key: 'belote');

    await upgrade();

    expect(
      () => _insertType(db, 'Belote', key: 'belote'),
      throwsA(isA<DatabaseException>()),
    );
    // Whatever name it carries: the key is the identity, not the name.
    expect(
      () => _insertType(db, 'Belote coinchée', key: 'belote'),
      throwsA(isA<DatabaseException>()),
    );
  });

  test("a user's own type may share a name with a deleted type", () async {
    await _insertType(db, 'Belote', key: 'belote', deletedAt: 5);
    await _insertType(db, 'Tarot', isDefault: false, deletedAt: 5);

    await upgrade();

    await _insertType(db, 'Belote', isDefault: false);
    await _insertType(db, 'Tarot', isDefault: false);
    // Two of the user's own types may even share a live name: they have no key.
    await _insertType(db, 'Tarot', isDefault: false);
    final live = await db.query('game_types', where: 'deleted_at IS NULL');
    expect(live.map((r) => r['name']), ['Belote', 'Tarot', 'Tarot']);
  });

  test('a deleted built-in type does not stop it coming back', () async {
    await _insertType(db, 'Uno', key: 'uno', deletedAt: 5);

    await upgrade();

    await _insertType(db, 'Uno', key: 'uno');
    final rows = await db.query('game_types', where: "builtin_key = 'uno'");
    expect(rows, hasLength(2));
  });

  test('surplus keyed copies lose their key, never their row or their games', () async {
    final first = await _insertType(db, 'Skyjo', key: 'skyjo');
    final second = await _insertType(db, 'Skyjo', key: 'skyjo');
    await db.insert('games', {'name': 'Partie', 'gameTypeId': second});

    await upgrade();

    final rows = await db.query('game_types', orderBy: 'id');
    expect(rows.map((r) => r['id']), [first, second]);
    expect(rows.map((r) => r['builtin_key']), ['skyjo', null]);
    final game = await db.query('games');
    expect(game.single['gameTypeId'], second);
  });

  test('replaying the step changes nothing', () async {
    await _insertType(db, 'Rami', key: 'rami');
    await _insertType(db, 'Rami', key: 'rami');

    await upgrade();
    final once = await db.query('game_types', orderBy: 'id');
    await upgrade();

    expect(await db.query('game_types', orderBy: 'id'), once);
  });

  test('both fresh installs carry the index, and seed each type once', () async {
    final native = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        // Not the in-memory instance setUp opened: that one is v14.
        singleInstance: false,
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    addTearDown(native.close);
    final nativeIndex = await native.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = ?",
      [gameTypesBuiltinKeyIndex],
    );
    expect(nativeIndex, hasLength(1));
    final nativeKeys = await native.rawQuery('SELECT builtin_key FROM game_types');
    expect(nativeKeys, hasLength(GameType.defaultGameTypes().length));

    final web = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(web.close);
    final webIndex = await web.customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = ?",
      variables: [const Variable(gameTypesBuiltinKeyIndex)],
    ).get();
    expect(webIndex, hasLength(1));
    final webKeys = await web
        .customSelect('SELECT COUNT(DISTINCT builtin_key) AS c, COUNT(*) AS n FROM game_types')
        .getSingle();
    expect(webKeys.data['c'], GameType.defaultGameTypes().length);
    expect(webKeys.data['n'], GameType.defaultGameTypes().length);
  });
}
