import 'dart:io';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/game_type.dart';
import '../models/player.dart';
import '../models/game_analysis.dart';
import '../models/round.dart';
import '../models/score.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('countscore.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Schema v6 — sync-ready (see ARCHITECTURE.md §4.1)
    // Every entity has: uuid (logical key for sync), created_at, updated_at,
    // deleted_at (soft delete), group_id (NULL = local-only, non-NULL = shared).

    await db.execute('''
      CREATE TABLE game_types (
        id $idType,
        name $textType,
        iconCodePoint $intType,
        cardColorValue $intType,
        isLowestScoreWins $intType,
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

    await db.execute('''
      CREATE TABLE games (
        id $idType,
        name $textType,
        gameTypeId INTEGER,
        isLowestScoreWins $intType,
        createdAt $textType,
        lastModified TEXT,
        uuid TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT,
        FOREIGN KEY (gameTypeId) REFERENCES game_types (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE players (
        id $idType,
        gameId $intType,
        name $textType,
        orderIndex $intType,
        colorValue INTEGER,
        uuid TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE rounds (
        id $idType,
        gameId $intType,
        roundNumber $intType,
        comment TEXT,
        uuid TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scores (
        id $idType,
        playerId $intType,
        roundId $intType,
        value $intType,
        uuid TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT,
        FOREIGN KEY (playerId) REFERENCES players (id) ON DELETE CASCADE,
        FOREIGN KEY (roundId) REFERENCES rounds (id) ON DELETE CASCADE
      )
    ''');

    // Outbox: every local mutation to a synced entity (group_id != NULL) is queued
    // here for the sync worker. See ARCHITECTURE.md §5.1.
    await db.execute('''
      CREATE TABLE outbox (
        id $idType,
        entity_type $textType,
        entity_uuid $textType,
        op $textType,
        payload $textType,
        client_lamport $intType,
        created_at $intType,
        sent_at INTEGER
      )
    ''');

    // Per-group sync state: last server_seq we have pulled, last lamport we emitted.
    await db.execute('''
      CREATE TABLE sync_state (
        group_id TEXT PRIMARY KEY,
        last_server_seq INTEGER NOT NULL DEFAULT 0,
        last_lamport INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_games_gameTypeId ON games(gameTypeId)');
    await db.execute('CREATE INDEX idx_players_gameId ON players(gameId)');
    await db.execute('CREATE INDEX idx_rounds_gameId ON rounds(gameId)');
    await db.execute('CREATE INDEX idx_scores_playerId ON scores(playerId)');
    await db.execute('CREATE INDEX idx_scores_roundId ON scores(roundId)');
    await db.execute('CREATE INDEX idx_outbox_unsent ON outbox(sent_at, id)');
    await db.execute('CREATE INDEX idx_games_group_id ON games(group_id)');
    await db.execute('CREATE INDEX idx_players_group_id ON players(group_id)');

    await _createGameAnalysesTable(db);

    await _insertDefaultGameTypes(db);
  }

  Future<void> _createGameAnalysesTable(Database db) async {
    await db.execute('''
      CREATE TABLE game_analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        gameId INTEGER NOT NULL UNIQUE,
        content TEXT NOT NULL,
        modelId TEXT,
        generatedAt TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_game_analyses_gameId ON game_analyses(gameId)');
    await db.execute('CREATE INDEX idx_game_analyses_group_id ON game_analyses(group_id)');
  }

  Future<void> _insertDefaultGameTypes(Database db) async {
    // On v6+ tables we must also populate the sync-readiness columns (uuid,
    // created_at, updated_at, group_id). On older tables these columns don't
    // exist yet; sqflite's `insert` will silently drop unknown keys, but to be
    // explicit we detect the column presence first.
    final hasSyncCols = await _hasColumn(db, 'game_types', 'uuid');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final gameType in GameType.defaultGameTypes()) {
      final map = gameType.toMap();
      if (hasSyncCols) {
        map['uuid'] = _newUuid();
        map['created_at'] = now;
        map['updated_at'] = now;
        // Default game types are local (no group ownership); stays NULL.
      }
      await db.insert('game_types', map);
    }
  }

  /// Returns true if the column exists on the given table.
  Future<bool> _hasColumn(Database db, String table, String column) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    return cols.any((c) => c['name'] == column);
  }

  /// Generates a v4-like UUID string. We avoid pulling the ``uuid`` package
  /// just for this — a 16-byte cryptographically-random hex string is enough
  /// for our uniqueness needs (1/2^122 collision probability).
  static String _newUuid() {
    final rng = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // RFC 4122 v4 markers
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
        '${hex(4)}${hex(5)}-'
        '${hex(6)}${hex(7)}-'
        '${hex(8)}${hex(9)}-'
        '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE games ADD COLUMN gameType TEXT NOT NULL DEFAULT \'ZapZap\'');
    }

    if (oldVersion < 3) {
      // Créer la table game_types
      await db.execute('''
        CREATE TABLE game_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          iconCodePoint INTEGER NOT NULL,
          cardColorValue INTEGER NOT NULL,
          isLowestScoreWins INTEGER NOT NULL,
          isDefault INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await _insertDefaultGameTypes(db);

      // Ajouter gameTypeId à games
      await db.execute('ALTER TABLE games ADD COLUMN gameTypeId INTEGER');
      await db.execute('CREATE INDEX idx_games_gameTypeId ON games(gameTypeId)');
    }

    if (oldVersion < 4) {
      // Ajouter colorValue à players
      await db.execute('ALTER TABLE players ADD COLUMN colorValue INTEGER');

      // Si gameType existe encore, faire la migration vers gameTypeId
      final columns = await db.rawQuery('PRAGMA table_info(games)');
      final hasGameType = columns.any((col) => col['name'] == 'gameType');

      if (hasGameType) {
        // Migrer les données existantes
        final games = await db.query('games');
        for (final game in games) {
          final gameType = game['gameType'] as String?;
          if (gameType != null) {
            final typeResult = await db.query(
              'game_types',
              where: 'name = ?',
              whereArgs: [gameType],
              limit: 1,
            );
            if (typeResult.isNotEmpty) {
              await db.update(
                'games',
                {'gameTypeId': typeResult.first['id']},
                where: 'id = ?',
                whereArgs: [game['id']],
              );
            }
          }
        }
      }
    }

    if (oldVersion < 5) {
      // Add new columns for player elimination and game over conditions
      await db.execute('ALTER TABLE game_types ADD COLUMN playerDeadConditionType TEXT');
      await db.execute('ALTER TABLE game_types ADD COLUMN playerDeadThreshold INTEGER');
      await db.execute('ALTER TABLE game_types ADD COLUMN gameOverConditionType TEXT');
      await db.execute('ALTER TABLE game_types ADD COLUMN gameOverThreshold INTEGER');

      // Update existing game types with appropriate conditions
      // ZapZap: player dead over 100
      await db.execute('''
        UPDATE game_types
        SET playerDeadConditionType = 'over', playerDeadThreshold = 100
        WHERE name = 'ZapZap'
      ''');

      // Skyjo: game over when first player over 100
      final skyjoExists = await db.query('game_types', where: 'name = ?', whereArgs: ['Skyjo']);
      if (skyjoExists.isEmpty) {
        await db.insert('game_types', GameType.skyjo().toMap());
      } else {
        await db.execute('''
          UPDATE game_types
          SET gameOverConditionType = 'firstPlayerOver', gameOverThreshold = 100
          WHERE name = 'Skyjo'
        ''');
      }

      // Président: game over when first player over 11
      final presidentExists = await db.query('game_types', where: 'name = ?', whereArgs: ['Président']);
      if (presidentExists.isEmpty) {
        await db.insert('game_types', GameType.president().toMap());
      } else {
        await db.execute('''
          UPDATE game_types
          SET gameOverConditionType = 'firstPlayerOver', gameOverThreshold = 11
          WHERE name = 'Président'
        ''');
      }

      // Belote: game over when first player over 1000
      final beloteExists = await db.query('game_types', where: 'name = ?', whereArgs: ['Belote']);
      if (beloteExists.isEmpty) {
        await db.insert('game_types', GameType.belote().toMap());
      } else {
        await db.execute('''
          UPDATE game_types
          SET gameOverConditionType = 'firstPlayerOver', gameOverThreshold = 1000
          WHERE name = 'Belote'
        ''');
      }

      // Tarot: no conditions
      final tarotExists = await db.query('game_types', where: 'name = ?', whereArgs: ['Tarot']);
      if (tarotExists.isEmpty) {
        await db.insert('game_types', GameType.tarot().toMap());
      }

      // Bridge: no conditions
      final bridgeExists = await db.query('game_types', where: 'name = ?', whereArgs: ['Bridge']);
      if (bridgeExists.isEmpty) {
        await db.insert('game_types', GameType.bridge().toMap());
      }

      // Rami: player dead over 100
      final ramiExists = await db.query('game_types', where: 'name = ?', whereArgs: ['Rami']);
      if (ramiExists.isEmpty) {
        await db.insert('game_types', GameType.rami().toMap());
      } else {
        await db.execute('''
          UPDATE game_types
          SET playerDeadConditionType = 'over', playerDeadThreshold = 100
          WHERE name = 'Rami'
        ''');
      }
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE rounds ADD COLUMN comment TEXT');
      await _upgradeV5toV6(db);
    }

    if (oldVersion < 7) {
      await _createGameAnalysesTable(db);
    }
  }

  /// v5 → v6 migration: sync-readiness.
  ///
  /// What changes:
  /// - Every entity table gets ``uuid TEXT UNIQUE NOT NULL``,
  ///   ``created_at INTEGER NOT NULL``, ``updated_at INTEGER NOT NULL``,
  ///   ``deleted_at INTEGER NULL``, ``group_id TEXT NULL``.
  /// - New tables: ``outbox`` (sync queue), ``sync_state`` (per-group cursor).
  /// - Backfill: every existing row gets a fresh UUID and timestamps set to
  ///   the current time (for games, we preserve ``createdAt`` ISO string by
  ///   parsing it back to epoch ms). ``group_id`` stays NULL — all existing
  ///   data is treated as local-only, which is the user's expectation.
  ///
  /// Safety / reversibility notes:
  /// - We do NOT drop any existing column. Worst case the new columns are
  ///   unused.
  /// - The full normalization of players (global per group, see
  ///   ARCHITECTURE.md §3.3) is deferred to a future migration v8 because it
  ///   requires actual groups to scope into; doing it here would force every
  ///   existing user into a transient state.
  Future<void> _upgradeV5toV6(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final table in ['game_types', 'games', 'players', 'rounds', 'scores']) {
      // ALTER ADD COLUMN with UNIQUE is not supported by SQLite; we add as
      // plain TEXT then enforce uniqueness via a UNIQUE INDEX after backfill.
      await db.execute('ALTER TABLE $table ADD COLUMN uuid TEXT');
      await db.execute('ALTER TABLE $table ADD COLUMN created_at INTEGER');
      await db.execute('ALTER TABLE $table ADD COLUMN updated_at INTEGER');
      await db.execute('ALTER TABLE $table ADD COLUMN deleted_at INTEGER');
      await db.execute('ALTER TABLE $table ADD COLUMN group_id TEXT');
    }

    // Backfill timestamps and UUIDs.
    // Games: preserve original createdAt if parseable.
    final games = await db.query('games', columns: ['id', 'createdAt']);
    for (final g in games) {
      int createdAtMs = now;
      final createdAtStr = g['createdAt'] as String?;
      if (createdAtStr != null) {
        try {
          createdAtMs = DateTime.parse(createdAtStr).millisecondsSinceEpoch;
        } catch (_) {/* keep now */}
      }
      await db.update(
        'games',
        {
          'uuid': _newUuid(),
          'created_at': createdAtMs,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [g['id']],
      );
    }

    // Other tables: now/now (no original timestamp to preserve).
    for (final table in ['game_types', 'players', 'rounds', 'scores']) {
      final rows = await db.query(table, columns: ['id']);
      for (final r in rows) {
        await db.update(
          table,
          {
            'uuid': _newUuid(),
            'created_at': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [r['id']],
        );
      }
    }

    // Now enforce the UNIQUE constraint on uuid for each table.
    for (final table in ['game_types', 'games', 'players', 'rounds', 'scores']) {
      await db.execute(
        'CREATE UNIQUE INDEX idx_${table}_uuid ON $table(uuid)',
      );
    }

    // New tables: outbox, sync_state.
    await db.execute('''
      CREATE TABLE outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_uuid TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        client_lamport INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        sent_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_state (
        group_id TEXT PRIMARY KEY,
        last_server_seq INTEGER NOT NULL DEFAULT 0,
        last_lamport INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_outbox_unsent ON outbox(sent_at, id)');
    await db.execute('CREATE INDEX idx_games_group_id ON games(group_id)');
    await db.execute('CREATE INDEX idx_players_group_id ON players(group_id)');
  }

  // CRUD pour Game
  Future<int> createGame(Game game) async {
    final db = await database;
    return await db.insert('games', game.toMap());
  }

  Future<Game?> getGame(int id) async {
    final db = await database;
    final maps = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Game.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Game>> getAllGames() async {
    final db = await database;
    final maps = await db.query('games', orderBy: 'createdAt DESC, lastModified DESC');
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  Future<List<Game>> getGamesByType(int gameTypeId) async {
    final db = await database;
    final maps = await db.query(
      'games',
      where: 'gameTypeId = ?',
      whereArgs: [gameTypeId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  Future<int> updateGame(Game game) async {
    final db = await database;
    return await db.update(
      'games',
      game.copyWith(lastModified: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  Future<int> deleteGame(int id) async {
    final db = await database;
    return await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD pour Player
  Future<int> createPlayer(Player player) async {
    final db = await database;
    return await db.insert('players', player.toMap());
  }

  Future<List<Player>> getPlayersByGame(int gameId) async {
    final db = await database;
    final maps = await db.query(
      'players',
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'orderIndex ASC',
    );
    return maps.map((map) => Player.fromMap(map)).toList();
  }

  Future<int> updatePlayer(Player player) async {
    final db = await database;
    return await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    final db = await database;
    return await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD pour Round
  Future<int> createRound(Round round) async {
    final db = await database;
    return await db.insert('rounds', round.toMap());
  }

  Future<List<Round>> getRoundsByGame(int gameId) async {
    final db = await database;
    final maps = await db.query(
      'rounds',
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'roundNumber ASC',
    );
    return maps.map((map) => Round.fromMap(map)).toList();
  }

  Future<int> deleteRound(int id) async {
    final db = await database;
    return await db.delete(
      'rounds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateRoundComment(int roundId, String? comment) async {
    final db = await database;
    return await db.update(
      'rounds',
      {'comment': comment},
      where: 'id = ?',
      whereArgs: [roundId],
    );
  }

  // CRUD pour Score
  Future<int> createScore(Score score) async {
    final db = await database;
    return await db.insert('scores', score.toMap());
  }

  Future<Score?> getScore(int playerId, int roundId) async {
    final db = await database;
    final maps = await db.query(
      'scores',
      where: 'playerId = ? AND roundId = ?',
      whereArgs: [playerId, roundId],
    );

    if (maps.isNotEmpty) {
      return Score.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Score>> getScoresByPlayer(int playerId) async {
    final db = await database;
    final maps = await db.query(
      'scores',
      where: 'playerId = ?',
      whereArgs: [playerId],
    );
    return maps.map((map) => Score.fromMap(map)).toList();
  }

  Future<int> updateScore(Score score) async {
    final db = await database;
    return await db.update(
      'scores',
      score.toMap(),
      where: 'id = ?',
      whereArgs: [score.id],
    );
  }

  Future<int> upsertScore(Score score) async {
    final existing = await getScore(score.playerId, score.roundId);
    if (existing != null) {
      return await updateScore(score.copyWith(id: existing.id));
    } else {
      return await createScore(score);
    }
  }

  // Récupérer tous les noms de joueurs uniques
  Future<List<String>> getAllPlayerNames() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT name FROM players ORDER BY name ASC',
    );
    return result.map((row) => row['name'] as String).toList();
  }

  // Récupérer les couleurs des joueurs (dernière couleur utilisée par chaque joueur)
  Future<Map<String, int?>> getPlayerColors() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p1.name, p1.colorValue
      FROM players p1
      INNER JOIN (
        SELECT name, MAX(id) as maxId
        FROM players
        GROUP BY name
      ) p2 ON p1.name = p2.name AND p1.id = p2.maxId
      ORDER BY p1.name ASC
    ''');

    final Map<String, int?> playerColors = {};
    for (final row in result) {
      playerColors[row['name'] as String] = row['colorValue'] as int?;
    }
    return playerColors;
  }

  // Statistiques par joueur et par type de jeu
  Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    final db = await database;

    try {
      // Nombre total de parties jouées (doit correspondre à la somme par type de jeu)
      final totalGamesPlayed = await db.rawQuery('''
        SELECT COUNT(DISTINCT g.id) as count
        FROM games g
        JOIN players p ON p.gameId = g.id
        WHERE p.name = ?
      ''', [playerName]);

      // Récupérer toutes les parties du joueur avec leurs scores
      final playerGames = await db.rawQuery('''
        SELECT
          g.id as gameId,
          COALESCE(gt.name, 'Unknown') as gameType,
          g.isLowestScoreWins,
          COALESCE(SUM(s.value), 0) as playerTotal
        FROM games g
        JOIN players p ON p.gameId = g.id
        LEFT JOIN game_types gt ON g.gameTypeId = gt.id
        LEFT JOIN scores s ON s.playerId = p.id
        WHERE p.name = ?
        GROUP BY g.id, gt.name, g.isLowestScoreWins
      ''', [playerName]);

      int totalWins = 0;
      final statsByGameType = <String, Map<String, int>>{};

      // Pour chaque partie, vérifier si le joueur a gagné
      for (final game in playerGames) {
        final gameId = game['gameId'] as int;
        final gameType = game['gameType'] as String;
        final isLowestWins = (game['isLowestScoreWins'] as int) == 1;
        final playerTotal = game['playerTotal'] as int;

        // Récupérer tous les totaux des joueurs pour cette partie
        final allTotals = await db.rawQuery('''
          SELECT p.id, COALESCE(SUM(s.value), 0) as total
          FROM players p
          LEFT JOIN scores s ON s.playerId = p.id
          WHERE p.gameId = ?
          GROUP BY p.id
          ORDER BY total ${isLowestWins ? 'ASC' : 'DESC'}
        ''', [gameId]);

        // Vérifier si le joueur est THE winner (première place uniquement)
        bool hasWon = false;
        if (allTotals.isNotEmpty) {
          final bestTotal = allTotals.first['total'] as int;

          // Le joueur a gagné seulement s'il a le meilleur score ET est la première place
          // En cas d'égalité, on compte les deux comme gagnants
          hasWon = (playerTotal == bestTotal);
        }

        if (hasWon) {
          totalWins++;
        }

        // Statistiques par type de jeu
        if (!statsByGameType.containsKey(gameType)) {
          statsByGameType[gameType] = {'gamesPlayed': 0, 'wins': 0};
        }
        statsByGameType[gameType]!['gamesPlayed'] =
            (statsByGameType[gameType]!['gamesPlayed']! + 1);
        if (hasWon) {
          statsByGameType[gameType]!['wins'] =
              (statsByGameType[gameType]!['wins']! + 1);
        }
      }

      return {
        'gamesPlayed': totalGamesPlayed.first['count'] as int,
        'wins': totalWins,
        'byGameType': statsByGameType,
      };
    } catch (e) {
      // Return empty stats on error
      return {
        'gamesPlayed': 0,
        'wins': 0,
        'byGameType': <String, Map<String, int>>{},
      };
    }
  }

  // CRUD pour GameType
  Future<int> createGameType(GameType gameType) async {
    final db = await database;
    return await db.insert('game_types', gameType.toMap());
  }

  Future<GameType?> getGameType(int id) async {
    final db = await database;
    final maps = await db.query(
      'game_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return GameType.fromMap(maps.first);
    }
    return null;
  }

  Future<List<GameType>> getAllGameTypes() async {
    final db = await database;
    final maps = await db.query('game_types', orderBy: 'name ASC');
    return maps.map((map) => GameType.fromMap(map)).toList();
  }

  Future<int> updateGameType(GameType gameType) async {
    final db = await database;
    return await db.update(
      'game_types',
      gameType.toMap(),
      where: 'id = ?',
      whereArgs: [gameType.id],
    );
  }

  Future<int> deleteGameType(int id) async {
    final db = await database;
    // Vérifier si des jeux utilisent ce type
    final gamesCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM games WHERE gameTypeId = ?',
      [id],
    ));

    if (gamesCount != null && gamesCount > 0) {
      // Ne pas supprimer si des jeux l'utilisent
      throw Exception('Cannot delete game type: $gamesCount games are using it');
    }

    return await db.delete(
      'game_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mettre à jour la couleur d'un joueur spécifique (par nom unique)
  Future<void> updatePlayerColor(String playerName, int colorValue) async {
    final db = await database;
    await db.update(
      'players',
      {'colorValue': colorValue},
      where: 'name = ?',
      whereArgs: [playerName],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Exporter la base de données vers un dossier spécifié
  Future<String> exportDatabase(String destinationPath) async {
    try {
      final db = await database;
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'countscore.db');

      // Créer le nom de fichier avec timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'countscore_backup_$timestamp.db';
      final destinationFile = join(destinationPath, fileName);

      // Fermer la base de données pour permettre la copie
      await db.close();
      _database = null;

      // Copier le fichier
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationFile);

      // Rouvrir la base de données
      await database;

      return destinationFile;
    } catch (e) {
      // Rouvrir la base de données en cas d'erreur
      await database;
      throw Exception('Erreur lors de l\'export de la base de données: $e');
    }
  }

  // Importer une base de données depuis un fichier spécifié
  Future<void> importDatabase(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);

      // Vérifier que le fichier existe
      if (!await sourceFile.exists()) {
        throw Exception('Le fichier source n\'existe pas');
      }

      // Fermer la base de données actuelle
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Obtenir le chemin de la base de données actuelle
      final dbPath = await getDatabasesPath();
      final destinationPath = join(dbPath, 'countscore.db');

      // Sauvegarder l'ancienne base de données (backup de sécurité)
      final destinationFile = File(destinationPath);
      if (await destinationFile.exists()) {
        final backupPath = join(dbPath, 'countscore_backup_before_import.db');
        await destinationFile.copy(backupPath);
      }

      // Copier la nouvelle base de données
      await sourceFile.copy(destinationPath);

      // Rouvrir la base de données
      await database;
    } catch (e) {
      // En cas d'erreur, tenter de restaurer le backup
      try {
        final dbPath = await getDatabasesPath();
        final backupPath = join(dbPath, 'countscore_backup_before_import.db');
        final backupFile = File(backupPath);

        if (await backupFile.exists()) {
          final destinationPath = join(dbPath, 'countscore.db');
          await backupFile.copy(destinationPath);
        }
      } catch (restoreError) {
        // Ignorer les erreurs de restauration
      }

      // Rouvrir la base de données
      await database;
      throw Exception('Erreur lors de l\'import de la base de données: $e');
    }
  }

  // Obtenir le chemin de la base de données actuelle
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'countscore.db');
  }

  // Renommer un joueur dans toutes les parties
  Future<int> renamePlayer(String oldName, String newName) async {
    final db = await database;
    return await db.update(
      'players',
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  // Supprimer un joueur par nom dans toutes les parties
  Future<int> deletePlayerByName(String playerName) async {
    final db = await database;
    return await db.delete(
      'players',
      where: 'name = ?',
      whereArgs: [playerName],
    );
  }

  // ===== Game Analyses =====

  Future<GameAnalysis?> getAnalysisByGame(int gameId) async {
    final db = await database;
    final rows = await db.query(
      'game_analyses',
      where: 'gameId = ? AND deleted_at IS NULL',
      whereArgs: [gameId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameAnalysis.fromMap(rows.first);
  }

  Future<int> upsertAnalysis(GameAnalysis analysis) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = analysis.toMap();
    map['uuid'] ??= _newUuid();
    map['created_at'] ??= now;
    map['updated_at'] = now;
    return await db.insert(
      'game_analyses',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteAnalysisByGame(int gameId) async {
    final db = await database;
    return await db.delete(
      'game_analyses',
      where: 'gameId = ?',
      whereArgs: [gameId],
    );
  }

  /// Returns the N most recent finished games involving a player (by name),
  /// excluding [excludeGameId]. Used to give the AI commentator context.
  /// Each entry includes the player's final score, rank and didWin flag so the
  /// analysis can reference win/loss streaks.
  Future<List<Map<String, dynamic>>> getRecentPlayerHistory(
    String playerName, {
    int limit = 10,
    int? excludeGameId,
  }) async {
    final db = await database;

    final args = <Object?>[playerName];
    var whereClause = 'p.name = ?';
    if (excludeGameId != null) {
      whereClause += ' AND g.id != ?';
      args.add(excludeGameId);
    }
    args.add(limit);

    final rows = await db.rawQuery('''
      SELECT
        g.id as gameId,
        g.name as gameName,
        g.createdAt as createdAt,
        g.isLowestScoreWins as isLowestScoreWins,
        COALESCE(gt.name, 'Unknown') as gameType,
        COALESCE(SUM(s.value), 0) as playerTotal
      FROM games g
      JOIN players p ON p.gameId = g.id
      LEFT JOIN game_types gt ON g.gameTypeId = gt.id
      LEFT JOIN scores s ON s.playerId = p.id
      WHERE $whereClause
      GROUP BY g.id, g.name, g.createdAt, g.isLowestScoreWins, gt.name
      ORDER BY g.createdAt DESC
      LIMIT ?
    ''', args);

    final history = <Map<String, dynamic>>[];
    for (final row in rows) {
      final gameId = row['gameId'] as int;
      final isLowestWins = (row['isLowestScoreWins'] as int) == 1;
      final playerTotal = row['playerTotal'] as int;

      final allTotals = await db.rawQuery('''
        SELECT p.id, p.name, COALESCE(SUM(s.value), 0) as total
        FROM players p
        LEFT JOIN scores s ON s.playerId = p.id
        WHERE p.gameId = ?
        GROUP BY p.id, p.name
        ORDER BY total ${isLowestWins ? 'ASC' : 'DESC'}
      ''', [gameId]);

      var rank = 1;
      for (final t in allTotals) {
        if ((t['name'] as String) == playerName) break;
        if ((t['total'] as int) != playerTotal) rank++;
      }
      final didWin = allTotals.isNotEmpty &&
          (allTotals.first['total'] as int) == playerTotal;

      history.add({
        'gameId': gameId,
        'gameName': row['gameName'] as String,
        'gameType': row['gameType'] as String,
        'date': row['createdAt'] as String,
        'finalScore': playerTotal,
        'totalPlayers': allTotals.length,
        'rank': rank,
        'didWin': didWin,
      });
    }
    return history;
  }
}
