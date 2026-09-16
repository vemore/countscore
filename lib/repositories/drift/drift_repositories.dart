import 'package:drift/drift.dart';

import '../../models/game.dart';
import '../../models/game_analysis.dart';
import '../../models/game_type.dart';
import '../../models/player.dart';
import '../../models/round.dart';
import '../../models/score.dart';
import '../../services/drift/database.dart';
import '../../services/uuid.dart';
import '../game_analysis_repository.dart';
import '../game_repository.dart';
import '../game_type_repository.dart';
import '../player_repository.dart';
import '../player_stats_repository.dart';
import '../round_repository.dart';
import '../score_repository.dart';

/// Drift-backed repository implementations (cross-platform: native + web).
///
/// Faithful port of the SQL validated in `DatabaseService`, run through the
/// Drift executor so the same logic works on web (sqlite3.wasm). Rows map to
/// the existing domain models via their `fromMap` factories.

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

/// Whether the row [id] of [table] belongs to a group.
///
/// Shared rows are tombstoned instead of deleted: the delete has to reach the
/// other devices, and a row that is gone cannot say it was deleted. Local rows
/// (`group_id IS NULL`) are still deleted outright, as before v10.
Future<bool> _isShared(AppDatabase db, String table, int id) async {
  final row = await db
      .customSelect(
        'SELECT group_id FROM $table WHERE id = ?',
        variables: [Variable(id)],
      )
      .getSingleOrNull();
  return row?.data['group_id'] != null;
}

/// Tombstones the live rows of [table] matching [where].
Future<void> _tombstone(
  AppDatabase db,
  String table,
  String where,
  List<Object?> args,
  int now,
) {
  return db.customStatement(
    'UPDATE $table SET deleted_at = ?, updated_at = ? '
    'WHERE deleted_at IS NULL AND ($where)',
    [now, now, ...args],
  );
}

Future<int> _insertRow(AppDatabase db, String table, Map<String, Object?> m) {
  final cols = m.keys.join(', ');
  final ph = List.filled(m.length, '?').join(', ');
  return db.customInsert(
    'INSERT INTO $table ($cols) VALUES ($ph)',
    variables: m.values.map<Variable>((v) => Variable(v)).toList(),
  );
}

class DriftGameRepository implements GameRepository {
  DriftGameRepository(this._db);
  final AppDatabase _db;

  @override
  Future<int> create(Game game) {
    final now = _nowMs();
    final m = Map<String, Object?>.from(game.toMap())..remove('id');
    m['uuid'] = newUuid();
    m['created_at'] = now;
    m['updated_at'] = now;
    return _insertRow(_db, 'games', m);
  }

  @override
  Future<Game?> getById(int id) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM games WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    return row == null ? null : Game.fromMap(row.data);
  }

  @override
  Future<List<Game>> getAll() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM games WHERE deleted_at IS NULL '
          'ORDER BY createdAt DESC, lastModified DESC',
        )
        .get();
    return rows.map((r) => Game.fromMap(r.data)).toList();
  }

  @override
  Future<List<Game>> getByType(int gameTypeId) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM games WHERE gameTypeId = ? AND deleted_at IS NULL '
          'ORDER BY createdAt DESC',
          variables: [Variable(gameTypeId)],
        )
        .get();
    return rows.map((r) => Game.fromMap(r.data)).toList();
  }

  @override
  Future<int> update(Game game) {
    final now = DateTime.now();
    return _db.customUpdate(
      'UPDATE games SET name = ?, gameTypeId = ?, isLowestScoreWins = ?, '
      'createdAt = ?, lastModified = ?, finishedAt = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable(game.name),
        Variable(game.gameTypeId),
        Variable(game.isLowestScoreWins ? 1 : 0),
        Variable(game.createdAt.toIso8601String()),
        Variable(now.toIso8601String()),
        Variable(game.finishedAt?.toIso8601String()),
        Variable(now.millisecondsSinceEpoch),
        Variable(game.id),
      ],
      updates: {_db.games},
    );
  }

  @override
  Future<int> delete(int id) async {
    return _db.transaction(() async {
      if (await _isShared(_db, 'games', id)) {
        final now = _nowMs();
        await _tombstone(
          _db,
          'scores',
          'roundId IN (SELECT id FROM rounds WHERE gameId = ?)',
          [id],
          now,
        );
        await _tombstone(
          _db,
          'scores',
          'playerId IN (SELECT id FROM game_players WHERE gameId = ?)',
          [id],
          now,
        );
        await _tombstone(_db, 'rounds', 'gameId = ?', [id], now);
        await _tombstone(_db, 'game_players', 'gameId = ?', [id], now);
        await _tombstone(_db, 'game_analyses', 'gameId = ?', [id], now);
        return _db.customUpdate(
          'UPDATE games SET deleted_at = ?, updated_at = ? '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable(now), Variable(now), Variable(id)],
          updates: {_db.games},
        );
      }
      await _db.customStatement(
        'DELETE FROM scores WHERE roundId IN (SELECT id FROM rounds WHERE gameId = ?)',
        [id],
      );
      await _db.customStatement(
        'DELETE FROM scores WHERE playerId IN (SELECT id FROM game_players WHERE gameId = ?)',
        [id],
      );
      await _db.customStatement('DELETE FROM rounds WHERE gameId = ?', [id]);
      await _db.customStatement('DELETE FROM game_players WHERE gameId = ?', [
        id,
      ]);
      await _db.customStatement('DELETE FROM game_analyses WHERE gameId = ?', [
        id,
      ]);
      return _db.customUpdate(
        'DELETE FROM games WHERE id = ?',
        variables: [Variable(id)],
        updates: {_db.games},
      );
    });
  }
}

class DriftGameTypeRepository implements GameTypeRepository {
  DriftGameTypeRepository(this._db);
  final AppDatabase _db;

  @override
  Future<int> create(GameType gameType) {
    final now = _nowMs();
    final m = Map<String, Object?>.from(gameType.toMap())..remove('id');
    m['uuid'] = newUuid();
    m['created_at'] = now;
    m['updated_at'] = now;
    return _insertRow(_db, 'game_types', m);
  }

  @override
  Future<GameType?> getById(int id) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM game_types WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    return row == null ? null : GameType.fromMap(row.data);
  }

  @override
  Future<List<GameType>> getAll() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM game_types WHERE deleted_at IS NULL ORDER BY name ASC',
        )
        .get();
    return rows.map((r) => GameType.fromMap(r.data)).toList();
  }

  @override
  Future<int> update(GameType gameType) {
    final m = Map<String, Object?>.from(gameType.toMap());
    m.remove('id');
    m['updated_at'] = _nowMs();
    final assignments = m.keys.map((k) => '$k = ?').join(', ');
    return _db.customUpdate(
      'UPDATE game_types SET $assignments WHERE id = ?',
      variables: [
        ...m.values.map<Variable>((v) => Variable(v)),
        Variable(gameType.id),
      ],
      updates: {_db.gameTypes},
    );
  }

  @override
  Future<int> delete(int id) async {
    final countRow = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM games WHERE gameTypeId = ? AND deleted_at IS NULL',
          variables: [Variable(id)],
        )
        .getSingle();
    final count = countRow.data['c'] as int;
    if (count > 0) {
      throw Exception('Cannot delete game type: $count games are using it');
    }
    // A tombstoned game nobody can see must not keep the type alive.
    await _db.customStatement(
      'UPDATE games SET gameTypeId = NULL WHERE gameTypeId = ? AND deleted_at IS NOT NULL',
      [id],
    );
    return _db.customUpdate(
      'DELETE FROM game_types WHERE id = ?',
      variables: [Variable(id)],
      updates: {_db.gameTypes},
    );
  }
}

class DriftRoundRepository implements RoundRepository {
  DriftRoundRepository(this._db);
  final AppDatabase _db;

  @override
  Future<int> create(Round round) {
    final now = _nowMs();
    final m = Map<String, Object?>.from(round.toMap())..remove('id');
    m['uuid'] = newUuid();
    m['created_at'] = now;
    m['updated_at'] = now;
    return _insertRow(_db, 'rounds', m);
  }

  @override
  Future<List<Round>> getByGame(int gameId) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM rounds WHERE gameId = ? AND deleted_at IS NULL '
          'ORDER BY roundNumber ASC',
          variables: [Variable(gameId)],
        )
        .get();
    return rows.map((r) => Round.fromMap(r.data)).toList();
  }

  @override
  Future<Map<int, int>> countByGame() async {
    final rows = await _db
        .customSelect(
          'SELECT gameId, COUNT(*) AS c FROM rounds WHERE deleted_at IS NULL '
          'GROUP BY gameId',
        )
        .get();
    return {
      for (final r in rows) r.data['gameId'] as int: r.data['c'] as int,
    };
  }

  @override
  Future<int> delete(int id) async {
    return _db.transaction(() async {
      if (await _isShared(_db, 'rounds', id)) {
        final now = _nowMs();
        await _tombstone(_db, 'scores', 'roundId = ?', [id], now);
        return _db.customUpdate(
          'UPDATE rounds SET deleted_at = ?, updated_at = ? '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable(now), Variable(now), Variable(id)],
          updates: {_db.rounds},
        );
      }
      await _db.customStatement('DELETE FROM scores WHERE roundId = ?', [id]);
      return _db.customUpdate(
        'DELETE FROM rounds WHERE id = ?',
        variables: [Variable(id)],
        updates: {_db.rounds},
      );
    });
  }

  @override
  Future<int> updateComment(int roundId, String? comment) {
    return _db.customUpdate(
      'UPDATE rounds SET comment = ?, updated_at = ? WHERE id = ?',
      variables: [Variable(comment), Variable(_nowMs()), Variable(roundId)],
      updates: {_db.rounds},
    );
  }
}

class DriftScoreRepository implements ScoreRepository {
  DriftScoreRepository(this._db);
  final AppDatabase _db;

  @override
  Future<int> create(Score score) {
    final now = _nowMs();
    final m = Map<String, Object?>.from(score.toMap())..remove('id');
    m['uuid'] = newUuid();
    m['created_at'] = now;
    m['updated_at'] = now;
    return _insertRow(_db, 'scores', m);
  }

  @override
  Future<Score?> getByPlayerAndRound(int playerId, int roundId) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM scores WHERE playerId = ? AND roundId = ? AND deleted_at IS NULL',
          variables: [Variable(playerId), Variable(roundId)],
        )
        .getSingleOrNull();
    return row == null ? null : Score.fromMap(row.data);
  }

  @override
  Future<List<Score>> getByPlayer(int playerId) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM scores WHERE playerId = ? AND deleted_at IS NULL',
          variables: [Variable(playerId)],
        )
        .get();
    return rows.map((r) => Score.fromMap(r.data)).toList();
  }

  @override
  Future<int> update(Score score) {
    return _db.customUpdate(
      'UPDATE scores SET playerId = ?, roundId = ?, value = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable(score.playerId),
        Variable(score.roundId),
        Variable(score.value),
        Variable(_nowMs()),
        Variable(score.id),
      ],
      updates: {_db.scores},
    );
  }

  @override
  Future<int> upsert(Score score) async {
    final existing = await getByPlayerAndRound(score.playerId, score.roundId);
    if (existing != null) {
      return update(score.copyWith(id: existing.id));
    }
    return create(score);
  }
}

class DriftPlayerRepository implements PlayerRepository {
  DriftPlayerRepository(this._db);
  final AppDatabase _db;

  /// Find-or-create the global player for [name] not already in [gameId].
  Future<int> _resolveGlobal(int gameId, String name, int? color) async {
    final norm = name.trim();
    final now = _nowMs();

    final candidates = await _db
        .customSelect(
          'SELECT id FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE AND deleted_at IS NULL ORDER BY id ASC',
          variables: [Variable(norm)],
        )
        .get();

    for (final c in candidates) {
      final gid = c.data['id'] as int;
      final inGameRow = await _db
          .customSelect(
            'SELECT COUNT(*) AS c FROM game_players WHERE gameId = ? AND player_id = ? AND deleted_at IS NULL',
            variables: [Variable(gameId), Variable(gid)],
          )
          .getSingle();
      if ((inGameRow.data['c'] as int) == 0) {
        if (color != null) {
          await _db.customUpdate(
            'UPDATE players SET colorValue = ?, updated_at = ? WHERE id = ?',
            variables: [Variable(color), Variable(now), Variable(gid)],
            updates: {_db.players},
          );
        }
        return gid;
      }
    }

    var displayName = norm;
    if (candidates.isNotEmpty) {
      var n = candidates.length + 1;
      while (true) {
        final candidate = '$norm ($n)';
        final existsRow = await _db
            .customSelect(
              'SELECT COUNT(*) AS c FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
              variables: [Variable(candidate)],
            )
            .getSingle();
        if ((existsRow.data['c'] as int) == 0) {
          displayName = candidate;
          break;
        }
        n++;
      }
    }
    return _insertRow(_db, 'players', {
      'name': displayName.isEmpty ? norm : displayName,
      'colorValue': color,
      'uuid': newUuid(),
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<int> create(Player player) async {
    final now = _nowMs();
    final globalId = await _resolveGlobal(
      player.gameId,
      player.name,
      player.colorValue,
    );
    return _insertRow(_db, 'game_players', {
      'gameId': player.gameId,
      'player_id': globalId,
      'name': player.name,
      'orderIndex': player.orderIndex,
      'colorValue': player.colorValue,
      'uuid': newUuid(),
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<List<Player>> getByGame(int gameId) async {
    final rows = await _db
        .customSelect(
          'SELECT id, gameId, name, orderIndex, colorValue FROM game_players '
          'WHERE gameId = ? AND deleted_at IS NULL ORDER BY orderIndex ASC',
          variables: [Variable(gameId)],
        )
        .get();
    return rows.map((r) => Player.fromMap(r.data)).toList();
  }

  @override
  Future<int> update(Player player) {
    return _db.customUpdate(
      'UPDATE game_players SET name = ?, orderIndex = ?, colorValue = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable(player.name),
        Variable(player.orderIndex),
        Variable(player.colorValue),
        Variable(_nowMs()),
        Variable(player.id),
      ],
      updates: {_db.gamePlayers},
    );
  }

  @override
  Future<int> delete(int id) async {
    return _db.transaction(() async {
      if (await _isShared(_db, 'game_players', id)) {
        final now = _nowMs();
        await _tombstone(_db, 'scores', 'playerId = ?', [id], now);
        return _db.customUpdate(
          'UPDATE game_players SET deleted_at = ?, updated_at = ? '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable(now), Variable(now), Variable(id)],
          updates: {_db.gamePlayers},
        );
      }
      await _db.customStatement('DELETE FROM scores WHERE playerId = ?', [id]);
      return _db.customUpdate(
        'DELETE FROM game_players WHERE id = ?',
        variables: [Variable(id)],
        updates: {_db.gamePlayers},
      );
    });
  }

  @override
  Future<List<String>> getAllNames() async {
    final rows = await _db
        .customSelect(
          'SELECT name FROM players WHERE group_id IS NULL AND deleted_at IS NULL ORDER BY name ASC',
        )
        .get();
    return rows.map((r) => r.data['name'] as String).toList();
  }

  @override
  Future<Map<String, int?>> getColorsByName() async {
    final rows = await _db
        .customSelect(
          'SELECT name, colorValue FROM players WHERE group_id IS NULL AND deleted_at IS NULL ORDER BY name ASC',
        )
        .get();
    final map = <String, int?>{};
    for (final r in rows) {
      map[r.data['name'] as String] = r.data['colorValue'] as int?;
    }
    return map;
  }

  @override
  Future<int> renameByName(String oldName, String newName) async {
    final now = _nowMs();
    final globals = await _db
        .customSelect(
          'SELECT id FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
          variables: [Variable(oldName)],
        )
        .get();
    final ids = globals.map((r) => r.data['id'] as int).toList();
    final count = await _db.customUpdate(
      'UPDATE players SET name = ?, updated_at = ? WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
      variables: [Variable(newName), Variable(now), Variable(oldName)],
      updates: {_db.players},
    );
    if (ids.isNotEmpty) {
      final ph = List.filled(ids.length, '?').join(',');
      await _db.customUpdate(
        'UPDATE game_players SET name = ?, updated_at = ? WHERE player_id IN ($ph)',
        variables: [
          Variable(newName),
          Variable(now),
          ...ids.map((e) => Variable(e)),
        ],
        updates: {_db.gamePlayers},
      );
    }
    return count;
  }

  @override
  Future<int> deleteByName(String name) async {
    return _db.transaction(() async {
      final globals = await _db
          .customSelect(
            'SELECT id FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
            variables: [Variable(name)],
          )
          .get();
      final ids = globals.map((r) => r.data['id'] as int).toList();
      if (ids.isEmpty) return 0;
      final ph = List.filled(ids.length, '?').join(',');
      final gps = await _db
          .customSelect(
            'SELECT id, group_id FROM game_players WHERE player_id IN ($ph)',
            variables: ids.map((e) => Variable(e)).toList(),
          )
          .get();
      final localGp = [
        for (final r in gps)
          if (r.data['group_id'] == null) r.data['id'] as int,
      ];
      final sharedGp = [
        for (final r in gps)
          if (r.data['group_id'] != null) r.data['id'] as int,
      ];
      if (localGp.isNotEmpty) {
        final gpph = List.filled(localGp.length, '?').join(',');
        await _db.customStatement(
          'DELETE FROM scores WHERE playerId IN ($gpph)',
          localGp,
        );
        await _db.customStatement(
          'DELETE FROM game_players WHERE id IN ($gpph)',
          localGp,
        );
      }
      if (sharedGp.isEmpty) {
        return _db.customUpdate(
          'DELETE FROM players WHERE id IN ($ph)',
          variables: ids.map((e) => Variable(e)).toList(),
          updates: {_db.players},
        );
      }
      // Memberships in shared games are tombstoned, so the player row they
      // reference is too rather than deleted from under them.
      final now = _nowMs();
      final gpph = List.filled(sharedGp.length, '?').join(',');
      await _tombstone(_db, 'scores', 'playerId IN ($gpph)', sharedGp, now);
      await _tombstone(_db, 'game_players', 'id IN ($gpph)', sharedGp, now);
      return _db.customUpdate(
        'UPDATE players SET deleted_at = ?, updated_at = ? '
        'WHERE id IN ($ph) AND deleted_at IS NULL',
        variables: [
          Variable(now),
          Variable(now),
          ...ids.map((e) => Variable(e)),
        ],
        updates: {_db.players},
      );
    });
  }

  @override
  Future<void> updateColorByName(String name, int colorValue) async {
    final now = _nowMs();
    final globals = await _db
        .customSelect(
          'SELECT id FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
          variables: [Variable(name)],
        )
        .get();
    await _db.customUpdate(
      'UPDATE players SET colorValue = ?, updated_at = ? WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
      variables: [Variable(colorValue), Variable(now), Variable(name)],
      updates: {_db.players},
    );
    final ids = globals.map((r) => r.data['id'] as int).toList();
    if (ids.isNotEmpty) {
      final ph = List.filled(ids.length, '?').join(',');
      await _db.customUpdate(
        'UPDATE game_players SET colorValue = ?, updated_at = ? WHERE player_id IN ($ph)',
        variables: [
          Variable(colorValue),
          Variable(now),
          ...ids.map((e) => Variable(e)),
        ],
        updates: {_db.gamePlayers},
      );
    }
  }
}

class DriftPlayerStatsRepository implements PlayerStatsRepository {
  DriftPlayerStatsRepository(this._db);
  final AppDatabase _db;

  @override
  Future<Map<String, dynamic>> getStatsByName(String playerName) async {
    try {
      final globalRows = await _db
          .customSelect(
            'SELECT id FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE AND deleted_at IS NULL LIMIT 1',
            variables: [Variable(playerName)],
          )
          .get();
      if (globalRows.isEmpty) {
        return {
          'gamesPlayed': 0,
          'wins': 0,
          'byGameType': <String, Map<String, int>>{},
        };
      }
      final globalId = globalRows.first.data['id'] as int;

      final playerGames = await _db
          .customSelect(
            '''
        SELECT g.id AS gameId, COALESCE(gt.name, 'Unknown') AS gameType,
               g.isLowestScoreWins AS isLowestScoreWins, gp.id AS gpId,
               COALESCE(SUM(s.value), 0) AS playerTotal
        FROM game_players gp
        JOIN games g ON g.id = gp.gameId AND g.deleted_at IS NULL
        LEFT JOIN game_types gt ON g.gameTypeId = gt.id
        LEFT JOIN scores s ON s.playerId = gp.id AND s.deleted_at IS NULL
        WHERE gp.player_id = ? AND gp.deleted_at IS NULL
        GROUP BY g.id, gt.name, g.isLowestScoreWins, gp.id
      ''',
            variables: [Variable(globalId)],
          )
          .get();

      int totalWins = 0;
      final statsByGameType = <String, Map<String, int>>{};

      for (final game in playerGames) {
        final gameId = game.data['gameId'] as int;
        final gameType = game.data['gameType'] as String;
        final isLowestWins = (game.data['isLowestScoreWins'] as int) == 1;
        final playerTotal = game.data['playerTotal'] as int;

        final allTotals = await _db
            .customSelect(
              'SELECT gp.id, COALESCE(SUM(s.value), 0) AS total '
              'FROM game_players gp '
              'LEFT JOIN scores s ON s.playerId = gp.id AND s.deleted_at IS NULL '
              'WHERE gp.gameId = ? AND gp.deleted_at IS NULL GROUP BY gp.id '
              'ORDER BY total ${isLowestWins ? 'ASC' : 'DESC'}',
              variables: [Variable(gameId)],
            )
            .get();

        bool hasWon = false;
        if (allTotals.isNotEmpty) {
          final bestTotal = allTotals.first.data['total'] as int;
          hasWon = playerTotal == bestTotal;
        }
        if (hasWon) totalWins++;

        statsByGameType.putIfAbsent(
          gameType,
          () => {'gamesPlayed': 0, 'wins': 0},
        );
        statsByGameType[gameType]!['gamesPlayed'] =
            statsByGameType[gameType]!['gamesPlayed']! + 1;
        if (hasWon) {
          statsByGameType[gameType]!['wins'] =
              statsByGameType[gameType]!['wins']! + 1;
        }
      }

      return {
        'gamesPlayed': playerGames.length,
        'wins': totalWins,
        'byGameType': statsByGameType,
      };
    } catch (_) {
      return {
        'gamesPlayed': 0,
        'wins': 0,
        'byGameType': <String, Map<String, int>>{},
      };
    }
  }
}

class DriftGameAnalysisRepository implements GameAnalysisRepository {
  DriftGameAnalysisRepository(this._db);
  final AppDatabase _db;

  @override
  Future<GameAnalysis?> getByGame(int gameId) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM game_analyses WHERE gameId = ? AND deleted_at IS NULL LIMIT 1',
          variables: [Variable(gameId)],
        )
        .getSingleOrNull();
    return row == null ? null : GameAnalysis.fromMap(row.data);
  }

  @override
  Future<int> upsert(GameAnalysis analysis) async {
    final now = _nowMs();
    final existing = await _db
        .customSelect(
          'SELECT id, uuid, group_id, deleted_at FROM game_analyses WHERE gameId = ?',
          variables: [Variable(analysis.gameId)],
        )
        .getSingleOrNull();
    if (existing != null) {
      final id = existing.data['id'] as int;
      // A shared analysis that was deleted is a tombstone the whole group knows,
      // and the server ignores any later write to that uuid: a new analysis of
      // the same game is a new entity.
      final uuid = existing.data['group_id'] != null &&
              existing.data['deleted_at'] != null
          ? newUuid()
          : existing.data['uuid'] as String;
      return _db.customUpdate(
        'UPDATE game_analyses SET content = ?, modelId = ?, generatedAt = ?, '
        'updated_at = ?, deleted_at = NULL, uuid = ? WHERE id = ?',
        variables: [
          Variable(analysis.content),
          Variable(analysis.modelId),
          Variable(analysis.generatedAt.toIso8601String()),
          Variable(now),
          Variable(uuid),
          Variable(id),
        ],
        updates: {_db.gameAnalyses},
      );
    }
    return _insertRow(_db, 'game_analyses', {
      'gameId': analysis.gameId,
      'content': analysis.content,
      'modelId': analysis.modelId,
      'generatedAt': analysis.generatedAt.toIso8601String(),
      'uuid': newUuid(),
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<int> deleteByGame(int gameId) async {
    final now = _nowMs();
    // Shared: tombstone, so the delete reaches the group. Local: gone.
    final tombstoned = await _db.customUpdate(
      'UPDATE game_analyses SET deleted_at = ?, updated_at = ? '
      'WHERE gameId = ? AND group_id IS NOT NULL AND deleted_at IS NULL',
      variables: [Variable(now), Variable(now), Variable(gameId)],
      updates: {_db.gameAnalyses},
    );
    if (tombstoned > 0) return tombstoned;
    return _db.customUpdate(
      'DELETE FROM game_analyses WHERE gameId = ? AND group_id IS NULL',
      variables: [Variable(gameId)],
      updates: {_db.gameAnalyses},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentPlayerHistory(
    String playerName, {
    int limit = 10,
    int? excludeGameId,
  }) async {
    final globalRows = await _db
        .customSelect(
          'SELECT id FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE AND deleted_at IS NULL LIMIT 1',
          variables: [Variable(playerName)],
        )
        .get();
    if (globalRows.isEmpty) return [];
    final globalId = globalRows.first.data['id'] as int;

    final vars = <Variable>[Variable(globalId)];
    var whereClause = 'gp.player_id = ? AND gp.deleted_at IS NULL';
    if (excludeGameId != null) {
      whereClause += ' AND g.id != ?';
      vars.add(Variable(excludeGameId));
    }
    vars.add(Variable(limit));

    final rows = await _db.customSelect('''
      SELECT g.id AS gameId, g.name AS gameName, g.createdAt AS createdAt,
             g.isLowestScoreWins AS isLowestScoreWins,
             COALESCE(gt.name, 'Unknown') AS gameType, gp.id AS gpId,
             COALESCE(SUM(s.value), 0) AS playerTotal
      FROM game_players gp
      JOIN games g ON g.id = gp.gameId AND g.deleted_at IS NULL
      LEFT JOIN game_types gt ON g.gameTypeId = gt.id
      LEFT JOIN scores s ON s.playerId = gp.id AND s.deleted_at IS NULL
      WHERE $whereClause
      GROUP BY g.id, g.name, g.createdAt, g.isLowestScoreWins, gt.name, gp.id
      ORDER BY g.createdAt DESC
      LIMIT ?
    ''', variables: vars).get();

    final history = <Map<String, dynamic>>[];
    for (final row in rows) {
      final gameId = row.data['gameId'] as int;
      final gpId = row.data['gpId'] as int;
      final isLowestWins = (row.data['isLowestScoreWins'] as int) == 1;
      final playerTotal = row.data['playerTotal'] as int;

      final allTotals = await _db
          .customSelect(
            'SELECT gp.id, COALESCE(SUM(s.value), 0) AS total '
            'FROM game_players gp '
            'LEFT JOIN scores s ON s.playerId = gp.id AND s.deleted_at IS NULL '
            'WHERE gp.gameId = ? AND gp.deleted_at IS NULL GROUP BY gp.id '
            'ORDER BY total ${isLowestWins ? 'ASC' : 'DESC'}',
            variables: [Variable(gameId)],
          )
          .get();

      var rank = 1;
      for (final t in allTotals) {
        if ((t.data['id'] as int) == gpId) break;
        if ((t.data['total'] as int) != playerTotal) rank++;
      }
      final didWin =
          allTotals.isNotEmpty &&
          (allTotals.first.data['total'] as int) == playerTotal;

      history.add({
        'gameId': gameId,
        'gameName': row.data['gameName'] as String,
        'gameType': row.data['gameType'] as String,
        'date': row.data['createdAt'] as String,
        'finalScore': playerTotal,
        'totalPlayers': allTotals.length,
        'rank': rank,
        'didWin': didWin,
      });
    }
    return history;
  }
}
