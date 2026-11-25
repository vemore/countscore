/// Schemas v10 and v11 for group sync, and the v23 capture triggers, shared
/// verbatim by both engines.
///
/// sqflite (`DatabaseService`) runs these on native installs and upgrades; Drift
/// (`AppDatabase` `onCreate` and `onUpgrade`) runs them on web. Keeping one list is what stops the
/// two from drifting apart. See .llmwiki/Schema.md (v11 section) and
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
///
/// Only the sync bookkeeping lives here. The shared schema steps from v12 on,
/// sync-related or not, are in `lib/services/schema_steps.dart` — `applyV23`
/// there installs [syncV23CaptureStatements].
library;

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

/// The tables whose rows carry their own `group_id`: a game and everything
/// under it belong to one group at most.
const _groupTables = ['games', 'game_players', 'rounds', 'scores', 'game_analyses'];

/// The tables whose rows are one local row linked into each group
/// (`group_links`): a player is one person across groups, a game type one type.
const _linkedTables = {'player': 'players', 'game_type': 'game_types'};

String _op() => "CASE WHEN NEW.deleted_at IS NULL THEN 'upsert' ELSE 'delete' END";

/// Schema v23: the capture triggers write the group a row is queued for.
///
/// - A game, or a row under one, is queued once, for `NEW.group_id`.
/// - A player or a game type is queued **once per group it is linked in** — a
///   local rename reaches every group (decision 3 of
///   `wip/todo/2026-11-17-belong-to-several-groups.md`). A rename pulled from
///   one group is applied with `sync_flags.suppress` raised, so it is queued
///   for none: it is not relayed to the other groups.
///
/// Same trigger names as v11, dropped first, so a v11 trigger is replaced and a
/// replay is harmless. Needs `outbox.group_id`: `applyV23` adds it before.
final syncV23CaptureStatements = <String>[
  for (final table in _groupTables)
    for (final event in ['insert', 'update']) ...[
      'DROP TRIGGER IF EXISTS trg_sync_${table}_$event',
      '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_$event
AFTER ${event.toUpperCase()} ON $table
WHEN NEW.group_id IS NOT NULL AND $_notSuppressed
BEGIN
  INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at, group_id)
  VALUES ('${syncTables.entries.firstWhere((e) => e.value == table).key}', NEW.uuid,
          ${_op()}, '', 0, $_nowMs, NEW.group_id);
END''',
    ],
  for (final entry in _linkedTables.entries) ...[
    'DROP TRIGGER IF EXISTS trg_sync_${entry.value}_update',
    '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${entry.value}_update
AFTER UPDATE ON ${entry.value}
WHEN ${_linked(entry.key)} AND $_notSuppressed
BEGIN
  INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at, group_id)
  SELECT '${entry.key}', NEW.uuid, ${_op()}, '', 0, $_nowMs, l.group_id
  FROM group_links l WHERE l.entity_type = '${entry.key}' AND l.local_uuid = NEW.uuid;
END''',
  ],
];
