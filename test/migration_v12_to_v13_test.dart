import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/schema_steps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// v12 → v13: `game_types.rules` and `game_types.rules_slug`, plus the back-fill
/// that gives an existing install its shipped rulesets.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  Future<Set<String>> columnsOf(String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return {for (final r in rows) r['name'] as String};
  }

  Future<void> applyMigration() =>
      applyV13(db.execute, (t) => columnsOf(t));

  Future<String?> slugOf(String name) async {
    final rows = await db.query('game_types',
        columns: ['rules_slug'], where: 'name = ?', whereArgs: [name]);
    return rows.single['rules_slug'] as String?;
  }

  Future<void> seed(String name, {int isDefault = 1}) => db.insert('game_types', {
        'name': name,
        'iconCodePoint': 0xe000,
        'cardColorValue': 0xFF000000,
        'isLowestScoreWins': 0,
        'isDefault': isDefault,
        'uuid': 'uuid-$name',
        'created_at': 1,
        'updated_at': 1,
      });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    // The v12 shape: everything the v13 step expects to find, and nothing more.
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
  });

  tearDown(() => db.close());

  test('adds both columns', () async {
    await applyMigration();
    expect(await columnsOf('game_types'), containsAll(['rules', 'rules_slug']));
  });

  test('back-fills the seeded types and leaves rules empty', () async {
    // v13 knows the nine rulesets of the pre-v14 seed, by the name each was
    // seeded with; `defaultRulesSlugs` is keyed on builtin_key since v16.
    final seeded = <String, String>{
      for (final entry in GameType.seededNamesBeforeV14.entries)
        if (defaultRulesSlugs.containsKey(entry.key))
          entry.value: defaultRulesSlugs[entry.key]!,
    };
    expect(seeded, hasLength(9));
    for (final name in seeded.keys) {
      await seed(name);
    }
    await applyMigration();
    for (final entry in seeded.entries) {
      expect(await slugOf(entry.key), entry.value,
          reason: '${entry.key} should map to ${entry.value}');
    }
    final rules = await db.query('game_types', columns: ['rules']);
    expect(rules.every((r) => r['rules'] == null), isTrue,
        reason: 'the back-fill must not invent a user ruleset');
  });

  test('the accented seed name survives the back-fill', () async {
    // 'Président' is the one seed whose SQL literal carries a non-ASCII
    // character; getting it wrong would silently leave it without rules.
    await seed('Président');
    await applyMigration();
    expect(await slugOf('Président'), 'president');
  });

  test('Autre gets no slug: it is a catch-all with no rules of its own',
      () async {
    await seed('Autre');
    await applyMigration();
    expect(await slugOf('Autre'), isNull);
  });

  test('a renamed or user-built type keeps a null slug', () async {
    await seed('Belote coinchée');
    await seed('Ma belote', isDefault: 0);
    await applyMigration();
    expect(await slugOf('Belote coinchée'), isNull);
    expect(await slugOf('Ma belote'), isNull);
  });

  test('a type the user deleted is not resurrected', () async {
    await applyMigration();
    expect(
      (await db.query('game_types')).length,
      0,
      reason: 'the back-fill only updates rows that are already there',
    );
  });

  test('replaying the migration is a no-op and preserves a written ruleset',
      () async {
    await seed('Skyjo');
    await applyMigration();
    await db.update('game_types', {'rules': 'Chez nous on joue à 150.'},
        where: 'name = ?', whereArgs: ['Skyjo']);
    await applyMigration();
    final row = (await db.query('game_types', where: 'name = ?', whereArgs: ['Skyjo'])).single;
    expect(row['rules'], 'Chez nous on joue à 150.');
    expect(row['rules_slug'], 'skyjo');
  });
}
