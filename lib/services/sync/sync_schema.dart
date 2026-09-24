/// Schemas v10 and v11 for group sync, shared verbatim by both engines.
///
/// sqflite (`DatabaseService`) runs these on native installs and upgrades; Drift
/// (`AppDatabase` `onCreate` and `onUpgrade`) runs them on web. Keeping one list is what stops the
/// two from drifting apart. See .llmwiki/SchemaV10.md (v11 section) and
/// .llmwiki/Sync.md.
///
/// How it works: every write to a row that belongs to a group — or to a player or
/// game type linked into one — appends `(entity_type, entity_uuid)` to `outbox`,
/// with an empty payload and lamport 0. The sync engine turns those rows into
/// deltas at push time, from the row as it is then. Capturing in SQL rather than
/// in each repository method means no write path can forget to enqueue.
///
/// `sync_flags.suppress` is raised while pulled deltas are applied, so a change
/// received from the server is not captured and sent straight back.
library;

import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../utils/game_type_name.dart';
import '../uuid.dart';

/// Runs one statement, with optional positional arguments. `Database.execute`
/// (sqflite) and `AppDatabase.customStatement` (Drift) both fit.
typedef SqlExecutor = Future<void> Function(String sql, [List<Object?> args]);

/// Schema v10, shared by both engines: the sync bookkeeping tables and columns.
/// Idempotent — it checks each column before adding it, so it can replay on a
/// database that already has part of it.
Future<void> applySyncV10(
  Future<void> Function(String sql) execute,
  Future<Set<String>> Function(String table) columnsOf,
) async {
  // `outbox` and `sync_state` exist since v6; only add what is missing.
  const columns = {
    'outbox': {'rejected_at': 'INTEGER', 'reject_reason': 'TEXT'},
    'sync_state': {'device_id': 'TEXT', 'group_name': 'TEXT'},
  };
  for (final table in columns.entries) {
    final existing = await columnsOf(table.key);
    for (final column in table.value.entries) {
      if (existing.contains(column.key)) continue;
      await execute('ALTER TABLE ${table.key} ADD COLUMN ${column.key} ${column.value}');
    }
  }

  await execute('''
    CREATE TABLE IF NOT EXISTS group_links (
      group_id TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      local_uuid TEXT NOT NULL,
      remote_uuid TEXT NOT NULL,
      PRIMARY KEY (group_id, entity_type, local_uuid),
      UNIQUE (group_id, entity_type, remote_uuid)
    )
  ''');
  await execute('''
    CREATE TABLE IF NOT EXISTS entity_versions (
      entity_type TEXT NOT NULL,
      entity_uuid TEXT NOT NULL,
      lamport INTEGER NOT NULL,
      origin_device_id TEXT NOT NULL,
      PRIMARY KEY (entity_type, entity_uuid)
    )
  ''');
  await execute('''
    CREATE TABLE IF NOT EXISTS sync_inbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_seq INTEGER NOT NULL,
      delta TEXT NOT NULL,
      reason TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  await execute('CREATE INDEX IF NOT EXISTS idx_sync_inbox_seq ON sync_inbox(server_seq)');
}

/// Entity type → local table, in the order parents must reach the server.
const syncTables = <String, String>{
  'game_type': 'game_types',
  'player': 'players',
  'game': 'games',
  'game_player': 'game_players',
  'round': 'rounds',
  'score': 'scores',
  'game_analysis': 'game_analyses',
};

const _notSuppressed =
    'NOT EXISTS (SELECT 1 FROM sync_flags WHERE id = 1 AND suppress = 1)';

const _nowMs = "CAST(strftime('%s', 'now') AS INTEGER) * 1000";

String _capture(String entityType, String table, String event, String when) => '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_$event
AFTER ${event.toUpperCase()} ON $table
WHEN $when AND $_notSuppressed
BEGIN
  INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at)
  VALUES ('$entityType', NEW.uuid,
          CASE WHEN NEW.deleted_at IS NULL THEN 'upsert' ELSE 'delete' END,
          '', 0, $_nowMs);
END''';

/// A row created under a shared parent joins the parent's group. The repositories
/// stay group-blind: they insert with `group_id` NULL and this fixes it up, which
/// in turn fires the capture trigger on the UPDATE.
String _inherit(String table, String parentGroupSql) => '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_inherit
AFTER INSERT ON $table
WHEN NEW.group_id IS NULL AND ($parentGroupSql) IS NOT NULL
BEGIN
  UPDATE $table SET group_id = ($parentGroupSql) WHERE id = NEW.id;
END''';

String _linked(String entityType) =>
    "EXISTS (SELECT 1 FROM group_links WHERE entity_type = '$entityType' "
    'AND local_uuid = NEW.uuid)';

/// Statements that bring a v10 database to v11. Idempotent.
final syncV11Statements = <String>[
  '''
CREATE TABLE IF NOT EXISTS sync_flags (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  suppress INTEGER NOT NULL DEFAULT 0
)''',
  'INSERT OR IGNORE INTO sync_flags (id, suppress) VALUES (1, 0)',

  // Group membership flows down from the game.
  _inherit('game_players',
      'SELECT group_id FROM games WHERE id = NEW.gameId'),
  _inherit('rounds', 'SELECT group_id FROM games WHERE id = NEW.gameId'),
  _inherit('game_analyses',
      'SELECT group_id FROM games WHERE id = NEW.gameId'),
  _inherit('scores', 'SELECT group_id FROM rounds WHERE id = NEW.roundId'),

  for (final table in ['games', 'game_players', 'rounds', 'scores', 'game_analyses'])
    for (final event in ['insert', 'update'])
      _capture(
        syncTables.entries.firstWhere((e) => e.value == table).key,
        table,
        event,
        'NEW.group_id IS NOT NULL',
      ),

  // Players and game types stay local rows (group_id NULL); they sync once a
  // shared game has linked them.
  for (final entry in {'player': 'players', 'game_type': 'game_types'}.entries)
    _capture(entry.key, entry.value, 'update', _linked(entry.key)),
];

/// Schema v12, shared by both engines: `games.finishedAt`, the moment a game was
/// declared over. Null means still open. ISO-8601 TEXT like `createdAt` and
/// `lastModified`, not epoch-ms like the sync bookkeeping columns.
///
/// Idempotent — it checks the column before adding it, so it can replay on a
/// database that already has it. Pushed as `ended_at`, which the server has
/// carried since `0001_initial`.
Future<void> applyV12(
  Future<void> Function(String sql) execute,
  Future<Set<String>> Function(String table) columnsOf,
) async {
  const columns = {
    'games': {'finishedAt': 'TEXT'},
  };
  for (final table in columns.entries) {
    final existing = await columnsOf(table.key);
    for (final column in table.value.entries) {
      if (existing.contains(column.key)) continue;
      await execute('ALTER TABLE ${table.key} ADD COLUMN ${column.key} ${column.value}');
    }
  }
}

/// Every built-in game type that ships a ruleset in `assets/rules/`, keyed on
/// `game_types.builtin_key` and mapped to its `rules_slug`. `other` (`Autre`)
/// is a catch-all with no rules of its own, so it is absent: a type without a
/// slug shows the "write your own" empty state.
///
/// Keyed on the builtin key rather than on the seeded name since v16: the key
/// is the stable identity of a built-in type, and the name is not — it is
/// user-editable, and not even what the app displays (`game_type_name.dart`).
/// The v13 back-fill, which runs before `builtin_key` exists, reaches the
/// seeded names through `GameType.seededNamesBeforeV14`.
const defaultRulesSlugs = <String, String>{
  'zapzap': 'zapzap',
  'uno': 'uno',
  'scrabble': 'scrabble',
  'skyjo': 'skyjo',
  'president': 'president',
  'belote': 'belote',
  'tarot': 'tarot',
  'bridge': 'bridge',
  'rami': 'rami',
  'coinche': 'coinche',
  'yahtzee': 'yahtzee',
  'phase10': 'phase10',
  'flip7': 'flip7',
  'mille_bornes': 'mille_bornes',
  'rummikub': 'rummikub',
  'six_nimmt': 'six_nimmt',
  'qwirkle': 'qwirkle',
  'farkle': 'farkle',
  'canasta': 'canasta',
  'wizard': 'wizard',
  'triomino': 'triomino',
};

/// Schema v13, shared by both engines: `game_types.rules` and
/// `game_types.rules_slug`.
///
/// `rules` is what the user wrote — free Markdown, user content, never
/// translated. NULL means "show the shipped ruleset instead".
///
/// `rules_slug` names that shipped ruleset. It is a column rather than a match
/// on `name` because the name is user-editable: renaming "Belote" to "Belote
/// coinchée" must not lose its rules. Existing installs are back-filled from
/// the seeded names, and only for rows still flagged `isDefault` — a type the
/// user renamed or built themselves keeps a NULL slug, which is correct.
///
/// Idempotent, and it never resurrects a type the user deleted: the back-fill
/// only updates rows that are already there.
Future<void> applyV13(
  Future<void> Function(String sql) execute,
  Future<Set<String>> Function(String table) columnsOf,
) async {
  const columns = {
    'game_types': {'rules': 'TEXT', 'rules_slug': 'TEXT'},
  };
  for (final table in columns.entries) {
    final existing = await columnsOf(table.key);
    for (final column in table.value.entries) {
      if (existing.contains(column.key)) continue;
      await execute('ALTER TABLE ${table.key} ADD COLUMN ${column.key} ${column.value}');
    }
  }
  // Only the nine rulesets that shipped with v13, matched by the name they were
  // seeded with: `builtin_key` does not exist yet at this step. The twelve
  // types added in v14 get theirs from [applyV16], by key.
  for (final entry in defaultRulesSlugs.entries) {
    final name = GameType.seededNamesBeforeV14[entry.key];
    if (name == null) continue;
    await execute(
      "UPDATE game_types SET rules_slug = '${entry.value}' "
      "WHERE isDefault = 1 AND rules_slug IS NULL "
      "AND name = '${name.replaceAll("'", "''")}'",
    );
  }
}

/// Schema v14, shared by both engines: `game_types.builtin_key`, the stable
/// identity of a built-in type. Null for a type the user created or renamed.
///
/// It carries the displayed name as well (`lib/utils/game_type_name.dart`), so
/// the stored `name` of a built-in row stops mattering and two devices in
/// different locales converge on one row. See .llmwiki/SchemaV10.md.
///
/// Three steps, all idempotent so the step can replay:
///
/// 1. add the column;
/// 2. back-fill every **seeded** row, matched by the literal name it was seeded
///    with and by `isDefault = 1` — the precedent is the v4 to v5 step in
///    `database_service.dart`. `isDefault` is what separates a row the app wrote
///    from one the user made: a user's own "Yahtzee" carries 0 and is left
///    alone, so the migration never hijacks their row and renames it under them.
///    At most one row per key, the oldest: the guard is on the key, not on the
///    row, so a user with two "Uno" rows still ends up with exactly one `uno`,
///    on the first replay and on every one after it;
/// 3. insert the built-in types the pre-v14 seed never held, when the key is
///    absent **and no live row already uses that name**. The ten old ones are
///    never re-inserted, so **a type the user deleted is not resurrected**; and
///    a user who already made their own "Yahtzee" — the very premise of this
///    change — keeps that one row rather than gaining a second with the same
///    name, which the server's `unique(group_id, name)` would refuse for good
///    anyway.
///
/// Step 2 covers all 22 rather than only the ten, because the v2 to v3 step
/// seeds the *current* catalogue into an old database: a device coming from v2
/// arrives at v14 with all 22 names already present and none of them keyed.
Future<void> applyV14(
  SqlExecutor execute,
  Future<Set<String>> Function(String table) columnsOf,
) async {
  final existing = await columnsOf('game_types');
  if (!existing.contains('builtin_key')) {
    await execute('ALTER TABLE game_types ADD COLUMN builtin_key TEXT');
  }

  for (final type in GameType.defaultGameTypes()) {
    final key = type.builtinKey;
    if (key == null) continue;
    await execute(
      'UPDATE game_types SET builtin_key = ? WHERE id = ('
      '  SELECT id FROM game_types'
      '  WHERE builtin_key IS NULL AND name = ? COLLATE NOCASE AND isDefault = 1'
      '  ORDER BY id LIMIT 1)'
      ' AND NOT EXISTS (SELECT 1 FROM game_types WHERE builtin_key = ?)',
      [key, type.name, key],
    );
  }

  // The seed is written against the table as it is at v14, not as the model
  // describes it: a column a later step adds (`keypad_shortcut`, v21) is not
  // there yet, and one key too many fails the whole open. See
  // `DatabaseService._gameTypeRow`.
  final columnsNow = await columnsOf('game_types');
  final now = DateTime.now().millisecondsSinceEpoch;
  for (final type in GameType.defaultGameTypes()) {
    final key = type.builtinKey;
    if (key == null || GameType.seededNamesBeforeV14.containsKey(key)) continue;
    final values = Map<String, Object?>.from(type.toMap())
      ..remove('id')
      ..removeWhere((column, _) => !columnsNow.contains(column));
    values['uuid'] = newUuid();
    values['created_at'] = now;
    values['updated_at'] = now;
    final columns = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    await execute(
      'INSERT INTO game_types ($columns) SELECT $placeholders '
      'WHERE NOT EXISTS (SELECT 1 FROM game_types WHERE builtin_key = ?) '
      'AND NOT EXISTS (SELECT 1 FROM game_types '
      '                WHERE name = ? COLLATE NOCASE AND deleted_at IS NULL)',
      [...values.values, key, type.name],
    );
  }
}

/// The unique index [applyV15] creates: one **live** row per built-in type.
const gameTypesBuiltinKeyIndex = 'idx_game_types_builtin_key_live';

/// Schema v15, shared by both engines and by both fresh-install paths: a local
/// uniqueness guard on built-in game types, so a seeded type can never be
/// listed twice again.
///
/// The index is on `builtin_key`, not on `(group_id, name)`:
///
/// - `builtin_key` is the identity of a built-in type since v14, and the name
///   is not — the stored name of a built-in row is not even displayed, and two
///   devices in two locales hold different names for one type;
/// - it mirrors the server's `uq_game_types_group_builtin_key`
///   (`backend/app/models/game.py`), live rows only, key not null;
/// - a type the user made has a null key, so it is never constrained: it may
///   share its name with a deleted type, or with anything else.
///
/// Global rather than per group: one local row stands for a built-in type in
/// every group the device is in (`group_links` maps it), and the sync pull
/// matches an incoming built-in on its key before it would insert one.
///
/// Before the index, any surplus live row holding a key already held by an
/// older live row **loses its key** — never its data. Nothing in the app should
/// have produced one, but a failed `CREATE UNIQUE INDEX` inside `onUpgrade`
/// would leave the database unopenable for good, so the step cannot assume it.
/// The row keeps its games and shows its stored name instead.
///
/// Idempotent: the update matches nothing on a replay, and the index is
/// `IF NOT EXISTS`.
Future<void> applyV15(Future<void> Function(String sql) execute) async {
  await execute(
    'UPDATE game_types SET builtin_key = NULL '
    'WHERE builtin_key IS NOT NULL AND deleted_at IS NULL '
    'AND id > (SELECT MIN(o.id) FROM game_types o '
    '          WHERE o.builtin_key = game_types.builtin_key AND o.deleted_at IS NULL)',
  );
  await execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS $gameTypesBuiltinKeyIndex '
    'ON game_types(builtin_key) WHERE builtin_key IS NOT NULL AND deleted_at IS NULL',
  );
}

/// Schema v16, shared by both engines: the rulesets of the twelve built-in
/// types added in v14 (Coinche, Yahtzee, Phase 10 …), back-filled on
/// `rules_slug` by `builtin_key`.
///
/// No column changes. Only rows whose slug is still NULL are touched, so a
/// slug already set is kept; a type the user renamed has lost its key and is
/// left alone, exactly as the v13 back-fill leaves a renamed type. Keyed on
/// `builtin_key` rather than on the name, so the stored name — French on one
/// device, Japanese on another — does not matter.
///
/// Idempotent: a replay matches nothing. It never inserts, so a type the user
/// deleted is not resurrected.
Future<void> applyV16(SqlExecutor execute) async {
  for (final entry in defaultRulesSlugs.entries) {
    await execute(
      'UPDATE game_types SET rules_slug = ? '
      'WHERE builtin_key = ? AND rules_slug IS NULL',
      [entry.value, entry.key],
    );
  }
}

/// The columns that decide how a game type scores. Two rows that agree on all
/// of them play the same game, whatever their icon or colour.
const _scoringColumns = [
  'isLowestScoreWins',
  'playerDeadConditionType',
  'playerDeadThreshold',
  'gameOverConditionType',
  'gameOverThreshold',
];

/// Schema v17, shared by both engines: soft-deletes the keyless duplicates of
/// the built-in types that the old PWA reload bug left behind.
///
/// Before #153 every PWA reload reran `onCreate`, and before v15 that rerun
/// seeded the ten original types again. [applyV15] then stripped the key from
/// each surplus copy rather than deleting it, so a browser used in that window
/// lists every original type twice. See
/// `wip/done/2026-09-19-pwa-keeps-unkeyed-copies-of-builtin-types.md`.
///
/// A row is removed only when all of these hold:
///
/// - it is live, has no `builtin_key` and no `group_id` — a local user row;
/// - a live built-in row (key not null) has the same stored name, exactly, and
///   the same scoring fields ([_scoringColumns], NULL-safe);
/// - it holds no ruleset of its own (`rules` NULL);
/// - no game, live or deleted, points at it.
///
/// A copy with a game is the user's now and is kept, as is a user type that
/// shares a built-in name but scores differently.
///
/// A soft delete (`deleted_at`, `updated_at`), not a `DELETE`: sync sees a
/// tombstone if the row was ever linked into a group. Idempotent: a replay
/// matches only live rows, and there are none left to match.
Future<void> applyV17(SqlExecutor execute) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final sameScoring =
      _scoringColumns.map((c) => 'b.$c IS game_types.$c').join(' AND ');
  await execute(
    'UPDATE game_types SET deleted_at = ?, updated_at = ? '
    'WHERE builtin_key IS NULL AND group_id IS NULL AND deleted_at IS NULL '
    'AND rules IS NULL '
    'AND EXISTS (SELECT 1 FROM game_types b '
    '            WHERE b.builtin_key IS NOT NULL AND b.deleted_at IS NULL '
    '            AND b.id <> game_types.id AND b.name = game_types.name '
    '            AND $sameScoring) '
    'AND NOT EXISTS (SELECT 1 FROM games g WHERE g.gameTypeId = game_types.id)',
    [now, now],
  );
}

/// Schema v18, shared by both engines: replays [applyV16], so a `rules_slug`
/// emptied *after* v16 had already run comes back.
///
/// The pre-1.3.1 game-type editor rebuilt the row from the form fields alone,
/// writing `rules`, `rules_slug` and `isDefault` NULL / 0 on every save —
/// including a save that only changed the colour
/// (`wip/done/2026-09-20-editing-a-game-type-erases-its-rules.md`, fixed in
/// #179). #179 stops it happening again; nothing repaired the rows already
/// emptied, and the owner's device reached 1.3.1 with ZapZap and 6 qui prend
/// showing the empty "write your own rules" state, `builtin_key` still intact.
///
/// [applyV16] *is* that repair, with no new logic: it fills `rules_slug` from
/// `builtin_key` for all 21 keys of [defaultRulesSlugs] — not only the twelve
/// its own dartdoc highlights — and it never looks at `isDefault`, which the
/// same bug cleared and which is what makes the v13 and v14 back-fills unable
/// to help. The one reason it did not repair these rows is that a migration
/// step runs once. This step is that second run.
///
/// Safe to replay by construction: it only touches rows whose slug is still
/// NULL, it never inserts — so nothing deleted comes back — and no user action
/// clears a slug on purpose (*Restore the default* in `game_rules_screen.dart`
/// clears `rules`, not the slug). A ruleset the user wrote is left untouched,
/// and a type they created or renamed has no key and is left alone.
///
/// `rules` that the bug erased is user content with no second source and
/// cannot be restored. `isDefault` is deliberately not restored either:
/// `builtin_key` is the only test for a built-in type and nothing reads
/// `isDefault`. See .llmwiki/SchemaV10.md.
Future<void> applyV18(SqlExecutor execute) => applyV16(execute);

/// Every name each built-in type with a ruleset is known by: its name in each
/// of the ten locales (`game_type_name.dart`), the name it is seeded with, and —
/// for the first ten — the name the pre-v14 seed wrote. A name two keys share,
/// ignoring case, is left out: it says nothing about which game the row plays.
///
/// `other` is left out too. "Autre", "Other", "Otro" are what anyone calls a
/// type of their own, and the built-in carries no ruleset, so claiming such a
/// row would only swap the user's name for a localized one.
///
/// The names keep their case: [applyV19] compares them `COLLATE NOCASE`, which
/// folds ASCII only, so a lower-cased Cyrillic or accented name would never
/// match its stored form.
Map<String, Set<String>> builtinNamesByKey() {
  final namesByKey = <String, Set<String>>{};
  final keysByFolded = <String, Set<String>>{};
  void add(String key, String name) {
    namesByKey.putIfAbsent(key, () => {}).add(name);
    keysByFolded.putIfAbsent(name.toLowerCase(), () => {}).add(key);
  }

  final locales = AppLocalizations.supportedLocales.map(lookupAppLocalizations);
  for (final type in GameType.defaultGameTypes()) {
    final key = type.builtinKey!;
    if (!defaultRulesSlugs.containsKey(key)) continue;
    add(key, type.name);
    final seeded = GameType.seededNamesBeforeV14[key];
    if (seeded != null) add(key, seeded);
    for (final l10n in locales) {
      add(key, builtinGameTypeName(l10n, key)!);
    }
  }
  return {
    for (final e in namesByKey.entries)
      e.key: {
        for (final name in e.value)
          if (keysByFolded[name.toLowerCase()]!.length == 1) name,
      },
  };
}

/// Schema v19, shared by both engines: gives `builtin_key` back to the live
/// rows that never got it, then replays [applyV16] so they get their ruleset.
///
/// The v13 and v14 key back-fills selected `isDefault = 1`, and the pre-1.3.1
/// editor wrote `isDefault = 0` on every save
/// (`wip/done/2026-09-20-editing-a-game-type-erases-its-rules.md`). A seeded row
/// edited before those steps ran missed its key for good, and with it every
/// later slug repair — [applyV18] included, since [applyV16] filters on the
/// key. The owner's Skyjo is that row
/// (`wip/done/2026-09-20-a-type-that-lost-isdefault-can-never-regain-its-builtin-key.md`).
///
/// A keyless live row takes a key when **both** hold:
///
/// - its stored name is — ignoring ASCII case, as [applyV14] matched — a name
///   of exactly one built-in type with a ruleset ([builtinNamesByKey]) — so a renamed built-in, whose new name is the
///   user's choice, keeps no key;
/// - **no live row holds that key**. While the built-in type is there, a
///   homonym is the user's second row and stays theirs. The key is free only
///   when the seeded row itself lost it, or when v14 declined to insert the
///   built-in because a row of that name already existed — the owner's own
///   "6 qui prend", which predates the built-in and plays the same game.
///
/// At most one row per key: the oldest across **all** of that key's names, as
/// in [applyV14], so a keyless "Wizard" does not win over an older row stored
/// under the Russian name. The unique index of [applyV15] holds on every replay.
///
/// Neither `isDefault` nor the scoring columns are read. `isDefault` is the flag
/// the bug cleared. The scoring columns do not identify a built-in either: the
/// shipped definitions changed after these rows were seeded (6 qui prend put a
/// player out at 66, now 65), and a user who moved a threshold still plays the
/// same game, with the same rules. Nothing but `builtin_key` and `rules_slug`
/// is written: the scoring, the colours and a ruleset the user wrote stay.
/// `isDefault` is not restored, as in [applyV18]. See .llmwiki/SchemaV10.md.
///
/// Idempotent: a keyed row is never selected again, and it never inserts, so a
/// type the user deleted is not resurrected.
Future<void> applyV19(SqlExecutor execute) async {
  for (final entry in builtinNamesByKey().entries) {
    final names = entry.value.toList();
    if (names.isEmpty) continue;
    final placeholders = List.filled(names.length, '?').join(', ');
    await execute(
      'UPDATE game_types SET builtin_key = ? WHERE id = ('
      '  SELECT id FROM game_types'
      '  WHERE builtin_key IS NULL AND deleted_at IS NULL'
      '  AND name COLLATE NOCASE IN ($placeholders)'
      '  ORDER BY id LIMIT 1)'
      ' AND NOT EXISTS (SELECT 1 FROM game_types'
      '                 WHERE builtin_key = ? AND deleted_at IS NULL)',
      [entry.key, ...names, entry.key],
    );
  }
  await applyV16(execute);
}

/// The built-in types seeded with a keypad shortcut, keyed on `builtin_key`,
/// with the stored (encoded) shortcut: ZapZap, Skyjo, Belote, Scrabble and
/// Rami (`GameType.zapzap` and the others).
Map<String, String> keypadShortcutSeeds() => {
      for (final type in GameType.defaultGameTypes())
        if (type.keypadShortcut case final shortcut?)
          type.builtinKey!: shortcut.encode(),
    };

/// Schema v21, shared by both engines: `game_types.keypad_shortcut`, the score
/// keypad's per-type key — a value, or an operation on the score typed
/// (`lib/models/keypad_shortcut.dart`). TEXT, nullable: null is a plain 0.
///
/// Adds the column, then gives the live built-in rows of
/// [keypadShortcutSeeds] their shortcut, matched on `builtin_key` alone (never
/// `isDefault`, see .llmwiki/SchemaV10.md). The column is new, so a NULL here
/// was never a choice and every such row is filled; a renamed type (no key)
/// and a deleted one are left alone. `updated_at` moves, and the UPDATE fires
/// the v11 `game_types` capture trigger, so a row linked into a group pushes
/// its shortcut on the next sync.
///
/// Idempotent: the column is checked before it is added, and the back-fill
/// only touches `keypad_shortcut IS NULL`. It never inserts, so a type the
/// user deleted is not resurrected.
Future<void> applyV21(
  SqlExecutor execute,
  Future<Set<String>> Function(String table) columnsOf,
) async {
  final existing = await columnsOf('game_types');
  if (!existing.contains('keypad_shortcut')) {
    await execute('ALTER TABLE game_types ADD COLUMN keypad_shortcut TEXT');
  }
  final now = DateTime.now().millisecondsSinceEpoch;
  for (final entry in keypadShortcutSeeds().entries) {
    await execute(
      'UPDATE game_types SET keypad_shortcut = ?, updated_at = ? '
      'WHERE builtin_key = ? AND deleted_at IS NULL '
      'AND keypad_shortcut IS NULL',
      [entry.value, now, entry.key],
    );
  }
}
