// The v18 → v19 step: a live row with no `builtin_key` takes the key its name
// belongs to when no live row holds it, then `applyV16` gives it its ruleset.
//
// Built on the model of migration_v17_to_v18_test.dart: a current database is
// stepped back to what the owner's v18 file holds — a seeded Skyjo whose key
// the v14 back-fill missed because the old editor had cleared `isDefault`, and a
// "6 qui prend" of the user's own that predates the built-in, which v14 then
// declined to insert — and opened through both engines' real upgrade callbacks
// (sqflite's chain on native, Drift's `onUpgrade` on web) and once more straight
// through `applyV19`.

import 'dart:io';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v19_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  final wizardInRussian = lookupAppLocalizations(const Locale('ru')).gameTypeNameWizard;

  late int skyjo; // seeded, lost its key and its slug
  late int sixNimmt; // the user's own, older than the built-in, with house rules
  late int wizard; // keyless, stored under its Russian name
  late int yams; // the user's own, no built-in name
  late int yahtzeeCopy; // the user's homonym of a built-in that is still there
  late int renamed; // a built-in the user renamed
  late int deletedBelote; // a keyless homonym, deleted
  late int secondSkyjo; // a younger keyless Skyjo
  late int youngerWizard; // keyless, English name, younger than the Russian one
  late int myOther; // the user's "Other", after deleting the seeded "Autre"

  Future<int> insertType(Database db, String name, String uuid,
          {int? deletedAt, String? rules, int? deadThreshold}) =>
      db.insert('game_types', {
        'name': name,
        'iconCodePoint': 0xe000,
        'cardColorValue': 0xFF000000,
        'isLowestScoreWins': 1,
        'isDefault': 0,
        'playerDeadConditionType': deadThreshold == null ? null : 'over',
        'playerDeadThreshold': deadThreshold,
        'rules': rules,
        'uuid': uuid,
        'created_at': 1,
        'updated_at': 1,
        'deleted_at': deletedAt,
      });

  /// A current database stepped back to the owner's v18 shape.
  Future<void> writeV18File() async {
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

    // The seeded Skyjo, saved once by the pre-1.3.1 editor before v14 ran.
    skyjo = await idOf('skyjo');
    await db.update('game_types',
        {'builtin_key': null, 'rules_slug': null, 'isDefault': 0},
        where: 'id = ?', whereArgs: [skyjo]);

    // The built-ins v14 never inserted, because a row of that name existed.
    await db.delete('game_types', where: 'builtin_key IN (?, ?, ?, ?)',
        whereArgs: ['six_nimmt', 'wizard', 'belote', 'other']);
    sixNimmt = await insertType(db, '6 qui prend', 'six-1',
        rules: 'Nos règles maison.', deadThreshold: 66);
    wizard = await insertType(db, wizardInRussian, 'wizard-1');
    deletedBelote = await insertType(db, 'Belote', 'belote-1', deletedAt: 5);

    yams = await insertType(db, "Yam's", 'yams-1');
    yahtzeeCopy = await insertType(db, 'YAHTZEE', 'yahtzee-1');
    secondSkyjo = await insertType(db, 'Skyjo', 'skyjo-2');
    youngerWizard = await insertType(db, 'Wizard', 'wizard-2');
    myOther = await insertType(db, 'Other', 'other-1');

    renamed = await idOf('tarot');
    await db.update('game_types',
        {'builtin_key': null, 'rules_slug': null, 'name': 'Tarot du dimanche'},
        where: 'id = ?', whereArgs: [renamed]);

    await db.execute('PRAGMA user_version = 18');
    await db.close();
  }

  /// `id → (builtin_key, rules_slug, rules)`.
  Map<int, List<Object?>> stateById(List<Map<String, Object?>> rows) => {
        for (final r in rows)
          r['id'] as int: [r['builtin_key'], r['rules_slug'], r['rules']],
      };

  void expectRekeyed(Map<int, List<Object?>> state) {
    // Criterion 1: a row whose name is a built-in's, with the key free, gets the
    // key and the ruleset back.
    expect(state[skyjo], ['skyjo', 'skyjo', null],
        reason: 'the seeded Skyjo did not get its key and its rules back');
    expect(state[wizard], ['wizard', 'wizard', null],
        reason: 'a name stored in a non-Latin locale was not matched');
    // Criterion 4: a ruleset the user wrote stands next to the restored slug.
    expect(state[sixNimmt], ['six_nimmt', 'six_nimmt', 'Nos règles maison.'],
        reason: '6 qui prend did not get its key, or its house rules were touched');
    // Criterion 2: the user's own types stay theirs — no built-in name, or a
    // built-in that is still there.
    expect(state[yams], [null, null, null], reason: "Yam's took a key");
    expect(state[yahtzeeCopy], [null, null, null],
        reason: 'a homonym took a key another live row holds');
    // Criterion 3: a renamed built-in keeps no key.
    expect(state[renamed], [null, null, null],
        reason: 'a renamed built-in took its key back');
    // A deleted row is not keyed, and one key goes to one row: the oldest.
    expect(state[deletedBelote], [null, null, null],
        reason: 'a deleted row took a key');
    expect(state[secondSkyjo], [null, null, null],
        reason: 'a second Skyjo took a key already given');
    // The oldest row takes the key whichever of the key's names it stores.
    expect(state[youngerWizard], [null, null, null],
        reason: 'a younger row took the key from an older one under another name');
    // `other` carries no ruleset, and its names are anyone's.
    expect(state[myOther], [null, null, null],
        reason: "the user's own \"Other\" was claimed as the built-in");
  }

  test('native: the sqflite chain gives the keys back', () async {
    await writeV18File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), DatabaseService.schemaVersion);
    expectRekeyed(stateById(await db.query('game_types')));
  });

  test("web: Drift's onUpgrade gives the keys back", () async {
    await writeV18File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows = await db
        .customSelect('SELECT id, builtin_key, rules_slug, rules FROM game_types')
        .get();
    expectRekeyed(stateById(rows.map((r) => r.data).toList()));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, DatabaseService.schemaVersion);
  });

  test('applyV19 writes only the key and the slug, inserts nothing and replays '
      'as a no-op', () async {
    await writeV18File();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    final before = await db.query('game_types', orderBy: 'id');

    await applyV19(db.execute);
    final once = await db.query('game_types', orderBy: 'id');
    await applyV19(db.execute);

    expect(await db.query('game_types', orderBy: 'id'), once,
        reason: 'a replay changed a row');
    expect(once, hasLength(before.length), reason: 'the step inserted a row');
    for (var i = 0; i < before.length; i++) {
      final changed = {
        for (final c in once[i].keys)
          if (once[i][c] != before[i][c]) c,
      };
      expect(changed.difference({'builtin_key', 'rules_slug'}), isEmpty,
          reason: 'row ${before[i]['id']} changed beyond its key and slug');
    }
    final six = once.singleWhere((r) => r['id'] == sixNimmt);
    expect(six['playerDeadThreshold'], 66,
        reason: "the user's scoring is not the built-in definition's to reset");
    expect(six['isDefault'], 0, reason: 'isDefault is not restored');
    expectRekeyed(stateById(once));
  });

  test('every built-in with a ruleset is known by its name in all ten locales',
      () {
    final names = builtinNamesByKey();
    expect(names.keys.toSet(), defaultRulesSlugs.keys.toSet(),
        reason: '`other` has no ruleset and is not claimed');
    expect(names['skyjo'], contains('Skyjo'));
    expect(names['six_nimmt'], contains('6 qui prend'));
    expect(names['wizard'], contains(wizardInRussian));
    expect(names.values.expand((n) => n), isNot(contains("Yam's")));
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(names['six_nimmt'], contains(l10n.gameTypeNameSixNimmt),
          reason: '${locale.languageCode}: 6 qui prend is not matched');
    }
  });
}
