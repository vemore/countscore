import 'package:drift/drift.dart';

import '../../models/game_type.dart';
import '../sync/sync_schema.dart';
import '../uuid.dart';
import 'connection/connection.dart' as conn;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  GameTypes,
  Games,
  Players,
  GamePlayers,
  Rounds,
  Scores,
  Outbox,
  SyncState,
  GameAnalyses,
  GroupLinks,
  EntityVersions,
  SyncInbox,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());

  /// Test constructor: pass an in-memory executor (NativeDatabase.memory()).
  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createExtraIndexes();
          for (final statement in syncV11Statements) {
            await customStatement(statement);
          }
          await applyV15(customStatement);
          await _insertDefaultGameTypes();
        },
        onUpgrade: (m, from, to) async {
          // Native: the legacy sqflite layer already migrated the file to the
          // current version before Drift opened it (see
          // DatabaseService.bootstrapMigrate), so Drift sees the same version on
          // both sides and never gets here.
          //
          // Web does get here: the PWA has been in production since 2026-09-13
          // at v9, and a browser keeps its database between releases. Only the
          // steps after v9 are needed, and they are the same SQL sqflite runs.
          if (from < 10) {
            await applySyncV10(customStatement, _columnsOf);
          }
          if (from < 11) {
            for (final statement in syncV11Statements) {
              await customStatement(statement);
            }
          }
          if (from < 12) {
            await applyV12(customStatement, _columnsOf);
          }
          if (from < 13) {
            await applyV13(customStatement, _columnsOf);
          }
          if (from < 14) {
            await applyV14(customStatement, _columnsOf);
          }
          if (from < 15) {
            await applyV15(customStatement);
          }
          if (from < 16) {
            await applyV16(customStatement);
          }
          if (from < 17) {
            await applyV17(customStatement);
          }
        },
      );

  Future<Set<String>> _columnsOf(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return {for (final r in rows) r.data['name'] as String};
  }

  Future<void> _createExtraIndexes() async {
    const stmts = [
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_types_uuid ON game_types(uuid)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_games_uuid ON games(uuid)',
      'CREATE INDEX IF NOT EXISTS idx_games_gameTypeId ON games(gameTypeId)',
      'CREATE INDEX IF NOT EXISTS idx_games_group_id ON games(group_id)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_players_uuid ON players(uuid)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_players_name_local ON players(name COLLATE NOCASE) WHERE group_id IS NULL',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_players_name_group ON players(group_id, name COLLATE NOCASE) WHERE group_id IS NOT NULL',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_players_uuid ON game_players(uuid)',
      'CREATE INDEX IF NOT EXISTS idx_game_players_gameId ON game_players(gameId)',
      'CREATE INDEX IF NOT EXISTS idx_game_players_player_id ON game_players(player_id)',
      'CREATE INDEX IF NOT EXISTS idx_game_players_group_id ON game_players(group_id)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_players_unique ON game_players(gameId, player_id)',
      'CREATE INDEX IF NOT EXISTS idx_rounds_gameId ON rounds(gameId)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_rounds_uuid ON rounds(uuid)',
      'CREATE INDEX IF NOT EXISTS idx_scores_playerId ON scores(playerId)',
      'CREATE INDEX IF NOT EXISTS idx_scores_roundId ON scores(roundId)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_scores_uuid ON scores(uuid)',
      'CREATE INDEX IF NOT EXISTS idx_outbox_unsent ON outbox(sent_at, id)',
      'CREATE INDEX IF NOT EXISTS idx_sync_inbox_seq ON sync_inbox(server_seq)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_analyses_uuid ON game_analyses(uuid)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_analyses_gameId ON game_analyses(gameId)',
    ];
    for (final s in stmts) {
      await customStatement(s);
    }
  }

  /// Seeds the built-in types, skipping any whose `builtin_key` is already
  /// present, a tombstone included, so a deleted shared type is not
  /// resurrected.
  ///
  /// Idempotent because `onCreate` can run on a database that already holds
  /// them: a PWA whose `user_version` never reached IndexedDB (see
  /// `PersistenceFlushInterceptor`) reads version 0 on every load. Every other
  /// step of `onCreate` is `IF NOT EXISTS` already, so such a browser now
  /// completes `onCreate`, gets its version written, and recovers.
  Future<void> _insertDefaultGameTypes() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final gt in GameType.defaultGameTypes()) {
      final m = Map<String, dynamic>.from(gt.toMap())..remove('id');
      m['uuid'] = newUuid();
      m['created_at'] = now;
      m['updated_at'] = now;
      final cols = m.keys.join(', ');
      final ph = List.filled(m.length, '?').join(', ');
      await customInsert(
        'INSERT INTO game_types ($cols) SELECT $ph '
        'WHERE NOT EXISTS (SELECT 1 FROM game_types WHERE builtin_key = ?)',
        variables: [
          ...m.values.map<Variable>((v) => Variable(v)),
          Variable(gt.builtinKey),
        ],
      );
    }
  }
}
