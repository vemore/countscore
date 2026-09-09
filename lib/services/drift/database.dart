import 'package:drift/drift.dart';

import '../../models/game_type.dart';
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());

  /// Test constructor: pass an in-memory executor (NativeDatabase.memory()).
  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createExtraIndexes();
          await _insertDefaultGameTypes();
        },
        onUpgrade: (m, from, to) async {
          // Native: the legacy sqflite layer already migrated the file to v9
          // before Drift opened it (see DatabaseService.bootstrapMigrate), so
          // Drift sees schema 9 == 9 and never runs onUpgrade. Web has no
          // legacy DB, so onCreate covers fresh installs. Nothing to do.
        },
      );

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
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_analyses_uuid ON game_analyses(uuid)',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_game_analyses_gameId ON game_analyses(gameId)',
    ];
    for (final s in stmts) {
      await customStatement(s);
    }
  }

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
        'INSERT INTO game_types ($cols) VALUES ($ph)',
        variables: m.values.map<Variable>((v) => Variable(v)).toList(),
      );
    }
  }
}
