import 'package:drift/drift.dart';

// Drift tables mirroring the sqflite v9 schema EXACTLY (column names use the
// existing mixed casing via `.named()` so Drift can open a database created /
// migrated by the legacy sqflite layer). See .llmwiki/Schema.md.

@DataClassName('GameTypeRow')
class GameTypes extends Table {
  @override
  String get tableName => 'game_types';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get builtinKey => text().named('builtin_key').nullable()();
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
  TextColumn get rules => text().nullable()();
  TextColumn get rulesSlug => text().named('rules_slug').nullable()();
  TextColumn get keypadShortcut =>
      text().named('keypad_shortcut').nullable()();
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
  TextColumn get finishedAt => text().named('finishedAt').nullable()();
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
  // v10: a delta the server refused for good. Kept, not deleted, so the UI can say so.
  IntColumn get rejectedAt => integer().named('rejected_at').nullable()();
  TextColumn get rejectReason => text().named('reject_reason').nullable()();
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
  // v10: this device's id in the group (the server's origin_device_id) and the
  // group's display name. The device token itself is never stored in the database.
  TextColumn get deviceId => text().named('device_id').nullable()();
  TextColumn get groupName => text().named('group_name').nullable()();

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

/// v10: how a local player or game type is known in a group.
///
/// Players and game types are merged by name when a game is shared, so a local row
/// and its server twin can carry different uuids. Games, rounds, scores and analyses
/// keep their local uuid on the server and need no link.
@DataClassName('GroupLinkRow')
class GroupLinks extends Table {
  @override
  String get tableName => 'group_links';

  TextColumn get groupId => text().named('group_id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get localUuid => text().named('local_uuid')();
  TextColumn get remoteUuid => text().named('remote_uuid')();

  @override
  Set<Column> get primaryKey => {groupId, entityType, localUuid};

  @override
  List<Set<Column>> get uniqueKeys => [
        {groupId, entityType, remoteUuid},
      ];
}

/// v10: the (lamport, origin device) that last wrote each synced entity, so a pulled
/// delta is applied only when it wins the server's row-level LWW order.
@DataClassName('EntityVersionRow')
class EntityVersions extends Table {
  @override
  String get tableName => 'entity_versions';

  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityUuid => text().named('entity_uuid')();
  IntColumn get lamport => integer()();
  TextColumn get originDeviceId => text().named('origin_device_id')();

  @override
  Set<Column> get primaryKey => {entityType, entityUuid};
}

/// v10: pulled deltas that cannot be applied yet — a score whose round has not
/// arrived. Replayed after every pull page.
@DataClassName('SyncInboxRow')
class SyncInbox extends Table {
  @override
  String get tableName => 'sync_inbox';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverSeq => integer().named('server_seq')();
  TextColumn get delta => text()();
  TextColumn get reason => text()();
  IntColumn get createdAt => integer().named('created_at')();
}
