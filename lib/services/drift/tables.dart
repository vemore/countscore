import 'package:drift/drift.dart';

// Drift tables mirroring the sqflite v9 schema EXACTLY (column names use the
// existing mixed casing via `.named()` so Drift can open a database created /
// migrated by the legacy sqflite layer). See .llmwiki/SchemaV9.md.

@DataClassName('GameTypeRow')
class GameTypes extends Table {
  @override
  String get tableName => 'game_types';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer().named('iconCodePoint')();
  IntColumn get cardColorValue => integer().named('cardColorValue')();
  IntColumn get isLowestScoreWins => integer().named('isLowestScoreWins')();
  IntColumn get isDefault =>
      integer().named('isDefault').withDefault(const Constant(0))();
  TextColumn get playerDeadConditionType =>
      text().named('playerDeadConditionType').nullable()();
  IntColumn get playerDeadThreshold =>
      integer().named('playerDeadThreshold').nullable()();
  TextColumn get gameOverConditionType =>
      text().named('gameOverConditionType').nullable()();
  IntColumn get gameOverThreshold =>
      integer().named('gameOverThreshold').nullable()();
  TextColumn get uuid => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}

@DataClassName('GameRow')
class Games extends Table {
  @override
  String get tableName => 'games';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get gameTypeId => integer().named('gameTypeId').nullable()();
  IntColumn get isLowestScoreWins => integer().named('isLowestScoreWins')();
  TextColumn get createdAtIso => text().named('createdAt')();
  TextColumn get lastModified => text().named('lastModified').nullable()();
  TextColumn get uuid => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}

@DataClassName('PlayerRow')
class Players extends Table {
  @override
  String get tableName => 'players';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer().named('colorValue').nullable()();
  TextColumn get uuid => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}

@DataClassName('GamePlayerRow')
class GamePlayers extends Table {
  @override
  String get tableName => 'game_players';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().named('gameId')();
  IntColumn get playerId => integer().named('player_id')();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer().named('orderIndex')();
  IntColumn get colorValue => integer().named('colorValue').nullable()();
  TextColumn get uuid => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}

@DataClassName('RoundRow')
class Rounds extends Table {
  @override
  String get tableName => 'rounds';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().named('gameId')();
  IntColumn get roundNumber => integer().named('roundNumber')();
  TextColumn get comment => text().nullable()();
  TextColumn get uuid => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}

@DataClassName('ScoreRow')
class Scores extends Table {
  @override
  String get tableName => 'scores';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer().named('playerId')();
  IntColumn get roundId => integer().named('roundId')();
  IntColumn get value => integer()();
  TextColumn get uuid => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}

@DataClassName('OutboxRow')
class Outbox extends Table {
  @override
  String get tableName => 'outbox';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityUuid => text().named('entity_uuid')();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  IntColumn get clientLamport => integer().named('client_lamport')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get sentAt => integer().named('sent_at').nullable()();
}

@DataClassName('SyncStateRow')
class SyncState extends Table {
  @override
  String get tableName => 'sync_state';

  TextColumn get groupId => text().named('group_id')();
  IntColumn get lastServerSeq =>
      integer().named('last_server_seq').withDefault(const Constant(0))();
  IntColumn get lastLamport =>
      integer().named('last_lamport').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId};
}

@DataClassName('GameAnalysisRow')
class GameAnalyses extends Table {
  @override
  String get tableName => 'game_analyses';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  IntColumn get gameId => integer().named('gameId')();
  TextColumn get content => text()();
  TextColumn get modelId => text().named('modelId').nullable()();
  TextColumn get generatedAt => text().named('generatedAt')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();
  TextColumn get groupId => text().named('group_id').nullable()();
}
