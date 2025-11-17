import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/game_type.dart';
import '../models/player.dart';
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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Table game_types
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
        gameOverThreshold INTEGER
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
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE rounds (
        id $idType,
        gameId $intType,
        roundNumber $intType,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scores (
        id $idType,
        playerId $intType,
        roundId $intType,
        value $intType,
        FOREIGN KEY (playerId) REFERENCES players (id) ON DELETE CASCADE,
        FOREIGN KEY (roundId) REFERENCES rounds (id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_games_gameTypeId ON games(gameTypeId)');
    await db.execute('CREATE INDEX idx_players_gameId ON players(gameId)');
    await db.execute('CREATE INDEX idx_rounds_gameId ON rounds(gameId)');
    await db.execute('CREATE INDEX idx_scores_playerId ON scores(playerId)');
    await db.execute('CREATE INDEX idx_scores_roundId ON scores(roundId)');

    // Insérer les types de jeux par défaut
    await _insertDefaultGameTypes(db);
  }

  Future<void> _insertDefaultGameTypes(Database db) async {
    for (final gameType in GameType.defaultGameTypes()) {
      await db.insert('game_types', gameType.toMap());
    }
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
}
