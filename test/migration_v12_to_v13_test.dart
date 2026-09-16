// The v12 → v13 step: `game_types.builtin_key`.
//
// Built on the model of migration_v8_to_v9_test.dart — build the *old* schema by
// hand, run the production step, assert what survived. What matters here is the
// three promises applyV13 makes: the ten seeded rows are back-filled by name,
// the twelve types the seed never had are inserted, and nothing the user deleted
// or renamed comes back.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/sync/sync_schema.dart';

/// `game_types` as of v12: everything but `builtin_key`.
Future<void> _createV12GameTypes(Database db) async {
  await db.execute('''
    CREATE TABLE game_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      iconCodePoint INTEGER NOT NULL,
      cardColorValue INTEGER NOT NULL,
      isLowestScoreWins INTEGER NOT NULL,
      isDefault INTEGER NOT NULL DEFAULT 0,
      playerDeadConditionType TEXT,
      playerDeadThreshold INTEGER,
      gameOverConditionType TEXT,
      gameOverThreshold INTEGER,
      uuid TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER,
      group_id TEXT
    )
  ''');
}

Future<Set<String>> _columnsOf(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return {for (final r in rows) r['name'] as String};
}

Future<void> _insertV12(
  Database db,
  String name, {
  int? deletedAt,
  bool isDefault = true,
  String? uuid,
}) async {
  await db.insert('game_types', {
    'name': name,
    'iconCodePoint': 0xe000,
    'cardColorValue': 0xFF000000,
    'isLowestScoreWins': 0,
    'isDefault': isDefault ? 1 : 0,
    'uuid': uuid ?? 'uuid-${name.toLowerCase()}',
    'created_at': 1,
    'updated_at': 1,
    'deleted_at': deletedAt,
  });
}

Future<Map<String, String?>> _keysByName(Database db) async {
  final rows = await db.query('game_types', columns: ['name', 'builtin_key']);
  return {for (final r in rows) r['name'] as String: r['builtin_key'] as String?};
}

void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 12, onCreate: (db, _) => _createV12GameTypes(db)),
    );
  });
  tearDown(() => db.close());

  Future<void> upgrade() => applyV13(db.execute, (t) => _columnsOf(db, t));

  test('the ten seeded rows are back-filled by the name they were seeded with', () async {
    for (final name in GameType.seededNamesBeforeV13.values) {
      await _insertV12(db, name);
    }

    await upgrade();

    final keys = await _keysByName(db);
    for (final seeded in GameType.seededNamesBeforeV13.entries) {
      expect(keys[seeded.value], seeded.key, reason: seeded.value);
    }
  });

  test('the twelve types the seed never had are inserted, with their key', () async {
    for (final name in GameType.seededNamesBeforeV13.values) {
      await _insertV12(db, name);
    }

    await upgrade();

    final rows = await db.query('game_types', columns: ['builtin_key', 'uuid']);
    final keys = rows.map((r) => r['builtin_key'] as String?).toSet();
    expect(keys, hasLength(22));
    expect(keys, containsAll(GameType.defaultGameTypes().map((t) => t.builtinKey)));
    // Every inserted row is sync-ready: a uuid of its own.
    expect(rows.map((r) => r['uuid']).toSet(), hasLength(rows.length));
    expect(rows.every((r) => (r['uuid'] as String).isNotEmpty), isTrue);
  });

  test('a type the user deleted does not come back', () async {
    // The user kept only ZapZap; the other nine seeded rows are gone.
    await _insertV12(db, 'ZapZap');

    await upgrade();

    final keys = await _keysByName(db);
    expect(keys.keys, contains('ZapZap'));
    expect(keys.keys, isNot(contains('Skyjo')));
    expect(keys.keys, isNot(contains('Autre')));
    // The twelve new ones still arrive: they were never his to delete.
    expect(keys.keys, contains('Yahtzee'));
    expect(keys, hasLength(13));
  });

  test('a type the user renamed stays a user type', () async {
    await _insertV12(db, 'Le jeu du jeudi'); // was Skyjo, renamed
    await _insertV12(db, 'ZapZap');

    await upgrade();

    final keys = await _keysByName(db);
    expect(keys['Le jeu du jeudi'], isNull);
    expect(keys['ZapZap'], 'zapzap');
    expect(keys.containsKey('Skyjo'), isFalse);
  });

  test('two seeded rows with the same name yield one key, the oldest row', () async {
    await _insertV12(db, 'Uno');
    await _insertV12(db, 'uno', uuid: 'uuid-uno-2');

    await upgrade();

    final rows = await db.query('game_types',
        where: 'builtin_key = ?', whereArgs: ['uno'], orderBy: 'id');
    expect(rows, hasLength(1));
    expect(rows.single['uuid'], 'uuid-uno');
  });

  test('replaying over a duplicated name still leaves one key', () async {
    // The two halves of the previous cases together. The back-fill guard is on
    // the *key*, not on the row: without it the replay would find the second
    // "Uno" — still `builtin_key IS NULL` — and key that one too, leaving two
    // rows the new partial unique index refuses.
    await _insertV12(db, 'Uno');
    await _insertV12(db, 'uno', uuid: 'uuid-uno-2');

    await upgrade();
    await upgrade();
    await upgrade();

    final rows = await db.query('game_types', where: 'builtin_key = ?', whereArgs: ['uno']);
    expect(rows, hasLength(1));
    expect(rows.single['uuid'], 'uuid-uno');
  });

  test("a type the user made themselves is never claimed, nor duplicated", () async {
    // The premise of the entry this closes: someone who wanted Yahtzee made one.
    // `isDefault = 0` is what says the row is theirs, so the back-fill leaves it
    // keyless — its name is theirs to choose and must not start being localized
    // under them — and the insert is blocked by the name, so they do not end up
    // with two "Yahtzee" rows that the server's unique(group_id, name) would
    // then refuse for good.
    await _insertV12(db, 'ZapZap');
    await _insertV12(db, 'Yahtzee', isDefault: false);

    await upgrade();

    final yahtzee = await db.query('game_types', where: 'name = ? COLLATE NOCASE',
        whereArgs: ['Yahtzee']);
    expect(yahtzee, hasLength(1));
    expect(yahtzee.single['builtin_key'], isNull);
    expect(yahtzee.single['isDefault'], 0);
    // The other eleven still arrive.
    final keyed = await db.query('game_types', where: 'builtin_key IS NOT NULL');
    expect(keyed, hasLength(12));
  });

  test('a seeded row the user renamed frees its name for the new type', () async {
    // "Le jeu du jeudi" was Skyjo; nothing matches 'Skyjo' any more, so no key.
    // Unrelated to the twelve, which arrive as usual.
    await _insertV12(db, 'Le jeu du jeudi');

    await upgrade();

    final rows = await db.query('game_types', columns: ['name', 'builtin_key']);
    expect(rows.firstWhere((r) => r['name'] == 'Le jeu du jeudi')['builtin_key'], isNull);
    expect(rows.where((r) => r['builtin_key'] != null), hasLength(12));
  });

  test('replaying the step changes nothing', () async {
    for (final name in GameType.seededNamesBeforeV13.values) {
      await _insertV12(db, name);
    }

    await upgrade();
    final after = await _keysByName(db);
    await upgrade();

    expect(await _keysByName(db), after);
  });

  test('a tombstoned built-in row does not block its key from being re-seeded',
      () async {
    // deleted_at only matters to the readers; the migration matches on the name,
    // so a tombstoned "Autre" is the row that takes the key. This pins the
    // behaviour rather than endorsing it: either way the user sees no change.
    await _insertV12(db, 'Autre', deletedAt: 99);

    await upgrade();

    final rows = await db.query('game_types', where: 'builtin_key = ?', whereArgs: ['other']);
    expect(rows.single['deleted_at'], 99);
  });
}
