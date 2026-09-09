import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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

  /// Test hook: inject an already-open database (e.g. an in-memory FFI handle)
  /// so the singleton CRUD methods operate against it. Pass `null` to reset.
  @visibleForTesting
  static set debugDatabase(Database? db) => _database = db;

  /// Exposes [_createDB] for tests that want to build the v9 schema in an
  /// in-memory FFI database without going through [_initDB].
  @visibleForTesting
  Future<void> createDB(Database db, int version) => _createDB(db, version);

  /// Native bootstrap for the Drift migration: open the legacy sqflite file to
  /// run the v1→v9 migration chain (and create the v9 schema for fresh
  /// installs), then close so Drift can adopt the migrated file in place.
  /// See ARCHITECTURE.md §3.2 (two-release strategy).
  Future<void> bootstrapMigrate() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
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

    // Schema v9 — players are GLOBAL (unique per (group_id, name)); a separate
    // `game_players` join carries the per-game membership (order, color). See
    // ARCHITECTURE.md §3.3 / §4.1. `game_players.id` is the per-game key that
    // `scores` references (preserved across the v8→v9 migration).
    await db.execute('''
      CREATE TABLE players (
        id $idType,
        name $textType,
        colorValue INTEGER,
        uuid TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE game_players (
        id $idType,
        gameId $intType,
        player_id $intType,
        name $textType,
        orderIndex $intType,
        colorValue INTEGER,
        uuid TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
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
        FOREIGN KEY (playerId) REFERENCES game_players (id) ON DELETE CASCADE,
        FOREIGN KEY (roundId) REFERENCES rounds (id) ON DELETE CASCADE
      )
    ''');

    // Outbox: every local mutation to a synced entity (group_id != NULL) is queued
    // here for the sync worker. See ARCHITECTURE.md §5.1.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox (
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
      CREATE TABLE IF NOT EXISTS sync_state (
        group_id TEXT PRIMARY KEY,
        last_server_seq INTEGER NOT NULL DEFAULT 0,
        last_lamport INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_games_gameTypeId ON games(gameTypeId)');
    await db.execute('CREATE INDEX idx_game_players_gameId ON game_players(gameId)');
    await db.execute('CREATE INDEX idx_game_players_player_id ON game_players(player_id)');
    await db.execute('CREATE UNIQUE INDEX idx_game_players_unique ON game_players(gameId, player_id)');
    await db.execute('CREATE INDEX idx_rounds_gameId ON rounds(gameId)');
    await db.execute('CREATE INDEX idx_scores_playerId ON scores(playerId)');
    await db.execute('CREATE INDEX idx_scores_roundId ON scores(roundId)');
    await db.execute('CREATE INDEX idx_outbox_unsent ON outbox(sent_at, id)');
    await db.execute('CREATE INDEX idx_games_group_id ON games(group_id)');
    await db.execute('CREATE INDEX idx_game_players_group_id ON game_players(group_id)');
    // Local players (group_id NULL) are unique by name (case-insensitive).
    await db.execute(
      'CREATE UNIQUE INDEX idx_players_name_local ON players(name COLLATE NOCASE) WHERE group_id IS NULL',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_players_name_group ON players(group_id, name COLLATE NOCASE) WHERE group_id IS NOT NULL',
    );

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

    if (oldVersion < 8) {
      // The Bedrock prototype shipped a v7 game_analyses table without the
      // sync columns (uuid/created_at/updated_at/deleted_at/group_id). Devices
      // already at v7 never re-run the v6→v7 step, so fix them here. The table
      // is a regenerable cache of AI analyses, so dropping it is safe.
      await db.execute('DROP TABLE IF EXISTS game_analyses');
      await _createGameAnalysesTable(db);
    }

    if (oldVersion < 9) {
      await _upgradeV8toV9(db);
    }
  }

  /// v8 → v9 migration: global player identity (see ARCHITECTURE.md §3.3).
  ///
  /// Before: `players` is per-game (`players.gameId`), and `scores.playerId`
  /// references those per-game rows. Cross-game stats merge every human sharing
  /// a name (the `getPlayerStats` bug).
  ///
  /// After:
  /// - The per-game `players` table is **renamed to `game_players`** (a
  ///   membership row). Its `id` is unchanged, so `scores.playerId` keeps
  ///   pointing at the same rows — **no score data is rewritten**.
  /// - A new global `players` table holds one row per distinct human, unique by
  ///   `(group_id, name)`. All existing data is local (`group_id = NULL`).
  /// - `game_players.player_id` links each membership to its global player.
  ///
  /// Deduplication: players are collapsed by `lower(trim(name))`. Two players
  /// with the same name **in the same game** are deliberate distinct humans, so
  /// they are kept as separate global players (the 2nd+ occurrence gets a
  /// `" (n)"` suffix on the *global* identity only; the in-game display name is
  /// preserved on `game_players.name`). Duplicates remain recoverable by
  /// renaming, per §3.3.
  ///
  /// Safety: runs inside the open transaction sqflite wraps around onUpgrade.
  /// `scores` rows are untouched; only schema reshaping + backfill of the new
  /// `players` table and `game_players.player_id` happen.
  @visibleForTesting
  Future<void> upgradeV8toV9(Database db) => _upgradeV8toV9(db);

  @visibleForTesting
  Future<void> ensureV6ShapeForTesting(Database db) => _ensureV6Shape(db);

  /// Column names currently present on [table].
  Future<Set<String>> _columnsOf(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return {for (final row in rows) row['name'] as String};
  }

  /// Brings a database up to the v6 "sync-readiness" shape, whatever its
  /// recorded `user_version` claims.
  ///
  /// Some installs reached v8 while their tables still had the pre-v6 shape:
  /// no `uuid` / `created_at` / `updated_at` / `deleted_at` / `group_id`
  /// columns and no `outbox` / `sync_state` tables, even though the version
  /// counter had moved on. On those, [_upgradeV8toV9] fails with
  /// `no such column: uuid` while creating `idx_game_players_uuid`; because
  /// the migration runs inside [bootstrapMigrate], the failure propagates out
  /// of Drift's `LazyDatabase` opener and the database never opens at all —
  /// the app starts on an empty screen with every game still on disk.
  ///
  /// So probe the real schema instead of trusting the version counter.
  /// [_upgradeV5toV6] only adds what is missing, so this is a no-op on a
  /// database that genuinely went through v6.
  Future<void> _ensureV6Shape(Database db) async {
    if ((await _columnsOf(db, 'players')).contains('uuid')) return;

    // `rounds.comment` belongs to the same v5 → v6 step but is applied by
    // [_upgradeDB] rather than [_upgradeV5toV6], so it needs its own guard.
    if (!(await _columnsOf(db, 'rounds')).contains('comment')) {
      await db.execute('ALTER TABLE rounds ADD COLUMN comment TEXT');
    }

    await _upgradeV5toV6(db);
  }

  Future<void> _upgradeV8toV9(Database db) async {
    // A database stamped v8 that never received the v6 sync columns would
    // otherwise fail below on `game_players(uuid)`.
    await _ensureV6Shape(db);

    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Snapshot existing per-game players (ordered for stable disambiguation).
    final oldPlayers = await db.query(
      'players',
      columns: ['id', 'gameId', 'name', 'orderIndex', 'colorValue'],
      orderBy: 'gameId ASC, orderIndex ASC, id ASC',
    );

    // 2. Rename per-game `players` -> `game_players`. SQLite rewrites the
    //    `scores` foreign-key reference to the new name automatically; the
    //    `scores.playerId` values keep matching the same (now-renamed) rows.
    await db.execute('DROP INDEX IF EXISTS idx_players_gameId');
    await db.execute('DROP INDEX IF EXISTS idx_players_group_id');
    await db.execute('DROP INDEX IF EXISTS idx_players_uuid');
    await db.execute('ALTER TABLE players RENAME TO game_players');
    await db.execute('ALTER TABLE game_players ADD COLUMN player_id INTEGER');

    // 3. Create the new global `players` table.
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorValue INTEGER,
        uuid TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        group_id TEXT
      )
    ''');

    // 4. Deduplicate. For each game, the k-th occurrence of a normalized name
    //    maps to the k-th global player for that name (suffixing duplicates).
    final globalsByNorm = <String, List<int>>{}; // norm -> [globalId per slot]
    final latestColorByNorm = <String, int?>{}; // most-recent color wins

    // Track per-game occurrence index per normalized name.
    final perGameNameCount = <String, int>{}; // "gameId|norm" -> count so far

    for (final p in oldPlayers) {
      final gameId = p['gameId'] as int;
      final rawName = (p['name'] as String?) ?? '';
      final norm = rawName.trim().toLowerCase();
      final color = p['colorValue'] as int?;
      latestColorByNorm[norm] = color; // ordered, so last wins

      final key = '$gameId|$norm';
      final slot = perGameNameCount[key] ?? 0;
      perGameNameCount[key] = slot + 1;

      final list = globalsByNorm.putIfAbsent(norm, () => <int>[]);
      while (list.length <= slot) {
        list.add(-1);
      }
      if (list[slot] == -1) {
        // Create the global player for this (name, slot).
        final displayName = slot == 0 ? rawName.trim() : '${rawName.trim()} (${slot + 1})';
        final globalId = await db.insert('players', {
          'name': displayName.isEmpty ? rawName : displayName,
          'colorValue': color,
          'uuid': _newUuid(),
          'created_at': now,
          'updated_at': now,
        });
        list[slot] = globalId;
      }
      // Link the membership row to its global player and keep its display name.
      await db.update(
        'game_players',
        {'player_id': list[slot]},
        where: 'id = ?',
        whereArgs: [p['id']],
      );
    }

    // 5. Refresh global colors to the most-recently-used per name.
    for (final entry in latestColorByNorm.entries) {
      if (entry.value == null) continue;
      await db.update(
        'players',
        {'colorValue': entry.value},
        where: 'group_id IS NULL AND name = ? COLLATE NOCASE',
        whereArgs: [entry.key],
      );
    }

    // 6. Indexes for both tables.
    await db.execute('CREATE UNIQUE INDEX idx_players_uuid ON players(uuid)');
    await db.execute(
      'CREATE UNIQUE INDEX idx_players_name_local ON players(name COLLATE NOCASE) WHERE group_id IS NULL',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_players_name_group ON players(group_id, name COLLATE NOCASE) WHERE group_id IS NOT NULL',
    );
    await db.execute('CREATE UNIQUE INDEX idx_game_players_uuid ON game_players(uuid)');
    await db.execute('CREATE INDEX idx_game_players_gameId ON game_players(gameId)');
    await db.execute('CREATE INDEX idx_game_players_player_id ON game_players(player_id)');
    await db.execute('CREATE INDEX idx_game_players_group_id ON game_players(group_id)');
    await db.execute(
      'CREATE UNIQUE INDEX idx_game_players_unique ON game_players(gameId, player_id)',
    );
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

    const syncColumns = <String, String>{
      'uuid': 'TEXT',
      'created_at': 'INTEGER',
      'updated_at': 'INTEGER',
      'deleted_at': 'INTEGER',
      'group_id': 'TEXT',
    };

    for (final table in ['game_types', 'games', 'players', 'rounds', 'scores']) {
      // ALTER ADD COLUMN with UNIQUE is not supported by SQLite; we add as
      // plain TEXT then enforce uniqueness via a UNIQUE INDEX after backfill.
      // Only add what is missing: this step has to be replayable on databases
      // whose `user_version` ran ahead of their real schema (see
      // [_ensureV6Shape]).
      final existing = await _columnsOf(db, table);
      for (final column in syncColumns.entries) {
        if (existing.contains(column.key)) continue;
        await db.execute(
          'ALTER TABLE $table ADD COLUMN ${column.key} ${column.value}',
        );
      }
    }

    // Backfill timestamps and UUIDs for the rows that don't have them yet.
    // Games: preserve original createdAt if parseable.
    final games =
        await db.query('games', columns: ['id', 'createdAt'], where: 'uuid IS NULL');
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
      final rows = await db.query(table, columns: ['id'], where: 'uuid IS NULL');
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
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_${table}_uuid ON $table(uuid)',
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

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_unsent ON outbox(sent_at, id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_games_group_id ON games(group_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_players_group_id ON players(group_id)',
    );
  }

  // CRUD pour Game
  Future<int> createGame(Game game) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = game.toMap();
    map['uuid'] ??= _newUuid();
    map['created_at'] ??= now;
    map['updated_at'] ??= now;
    return await db.insert('games', map);
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

  // CRUD pour Player (v9: `Player` = a game_players membership; `Player.id`
  // is the game_players row id, used as the score key. Global identity lives
  // in the `players` table and is resolved find-or-create by name.)

  /// Resolve (find-or-create) the global player for [name] that is not already
  /// a member of [gameId], updating its preferred color. Returns the global id.
  Future<int> _resolveGlobalPlayerForGame(
    Database db,
    int gameId,
    String name,
    int? color,
  ) async {
    final norm = name.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    final candidates = await db.query(
      'players',
      columns: ['id'],
      where: 'group_id IS NULL AND name = ? COLLATE NOCASE AND deleted_at IS NULL',
      whereArgs: [norm],
      orderBy: 'id ASC',
    );

    for (final c in candidates) {
      final gid = c['id'] as int;
      final inGame = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM game_players WHERE gameId = ? AND player_id = ? AND deleted_at IS NULL',
        [gameId, gid],
      ));
      if ((inGame ?? 0) == 0) {
        if (color != null) {
          await db.update('players', {'colorValue': color, 'updated_at': now},
              where: 'id = ?', whereArgs: [gid]);
        }
        return gid;
      }
    }

    // Every existing "name" is already in this game -> create a distinct global
    // identity with a free " (n)" suffix (a deliberate same-game duplicate).
    var displayName = norm;
    if (candidates.isNotEmpty) {
      var n = candidates.length + 1;
      while (true) {
        final candidate = '$norm ($n)';
        final exists = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE',
          [candidate],
        ));
        if ((exists ?? 0) == 0) {
          displayName = candidate;
          break;
        }
        n++;
      }
    }
    return await db.insert('players', {
      'name': displayName.isEmpty ? norm : displayName,
      'colorValue': color,
      'uuid': _newUuid(),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> createPlayer(Player player) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final globalId = await _resolveGlobalPlayerForGame(
        db, player.gameId, player.name, player.colorValue);
    return await db.insert('game_players', {
      'gameId': player.gameId,
      'player_id': globalId,
      'name': player.name,
      'orderIndex': player.orderIndex,
      'colorValue': player.colorValue,
      'uuid': _newUuid(),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Player>> getPlayersByGame(int gameId) async {
    final db = await database;
    final maps = await db.query(
      'game_players',
      columns: ['id', 'gameId', 'name', 'orderIndex', 'colorValue'],
      where: 'gameId = ? AND deleted_at IS NULL',
      whereArgs: [gameId],
      orderBy: 'orderIndex ASC',
    );
    return maps.map((map) => Player.fromMap(map)).toList();
  }

  Future<int> updatePlayer(Player player) async {
    final db = await database;
    return await db.update(
      'game_players',
      {
        'name': player.name,
        'orderIndex': player.orderIndex,
        'colorValue': player.colorValue,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    final db = await database;
    // Foreign keys are not enforced at runtime, so cascade scores manually.
    await db.delete('scores', where: 'playerId = ?', whereArgs: [id]);
    return await db.delete(
      'game_players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD pour Round
  Future<int> createRound(Round round) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = round.toMap();
    map['uuid'] ??= _newUuid();
    map['created_at'] ??= now;
    map['updated_at'] ??= now;
    return await db.insert('rounds', map);
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = score.toMap();
    map['uuid'] ??= _newUuid();
    map['created_at'] ??= now;
    map['updated_at'] ??= now;
    return await db.insert('scores', map);
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

  // Récupérer tous les noms de joueurs (globaux, scope local)
  Future<List<String>> getAllPlayerNames() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT name FROM players WHERE group_id IS NULL AND deleted_at IS NULL ORDER BY name ASC',
    );
    return result.map((row) => row['name'] as String).toList();
  }

  // Couleur préférée par joueur global (scope local)
  Future<Map<String, int?>> getPlayerColors() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT name, colorValue FROM players WHERE group_id IS NULL AND deleted_at IS NULL ORDER BY name ASC',
    );

    final Map<String, int?> playerColors = {};
    for (final row in result) {
      playerColors[row['name'] as String] = row['colorValue'] as int?;
    }
    return playerColors;
  }

  // Statistiques par joueur (global) et par type de jeu
  Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    final db = await database;

    try {
      // Résoudre le joueur global par nom (scope local).
      final globalRows = await db.query(
        'players',
        columns: ['id'],
        where: 'group_id IS NULL AND name = ? COLLATE NOCASE AND deleted_at IS NULL',
        whereArgs: [playerName],
        limit: 1,
      );
      if (globalRows.isEmpty) {
        return {
          'gamesPlayed': 0,
          'wins': 0,
          'byGameType': <String, Map<String, int>>{},
        };
      }
      final globalId = globalRows.first['id'] as int;

      // Les parties du joueur via ses memberships game_players.
      final playerGames = await db.rawQuery('''
        SELECT
          g.id as gameId,
          COALESCE(gt.name, 'Unknown') as gameType,
          g.isLowestScoreWins,
          gp.id as gpId,
          COALESCE(SUM(s.value), 0) as playerTotal
        FROM game_players gp
        JOIN games g ON g.id = gp.gameId
        LEFT JOIN game_types gt ON g.gameTypeId = gt.id
        LEFT JOIN scores s ON s.playerId = gp.id
        WHERE gp.player_id = ? AND gp.deleted_at IS NULL
        GROUP BY g.id, gt.name, g.isLowestScoreWins, gp.id
      ''', [globalId]);

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
          SELECT gp.id, COALESCE(SUM(s.value), 0) as total
          FROM game_players gp
          LEFT JOIN scores s ON s.playerId = gp.id
          WHERE gp.gameId = ? AND gp.deleted_at IS NULL
          GROUP BY gp.id
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
        'gamesPlayed': playerGames.length,
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

  // Mettre à jour la couleur d'un joueur global et de ses memberships
  Future<void> updatePlayerColor(String playerName, int colorValue) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final globals = await db.query('players',
        columns: ['id'],
        where: 'group_id IS NULL AND name = ? COLLATE NOCASE',
        whereArgs: [playerName]);
    await db.update(
      'players',
      {'colorValue': colorValue, 'updated_at': now},
      where: 'group_id IS NULL AND name = ? COLLATE NOCASE',
      whereArgs: [playerName],
    );
    final ids = globals.map((r) => r['id'] as int).toList();
    if (ids.isNotEmpty) {
      final ph = List.filled(ids.length, '?').join(',');
      await db.update('game_players', {'colorValue': colorValue, 'updated_at': now},
          where: 'player_id IN ($ph)', whereArgs: ids);
    }
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

  // Renommer un joueur global (et le nom affiché de ses memberships)
  Future<int> renamePlayer(String oldName, String newName) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final globals = await db.query('players',
        columns: ['id'],
        where: 'group_id IS NULL AND name = ? COLLATE NOCASE',
        whereArgs: [oldName]);
    final ids = globals.map((r) => r['id'] as int).toList();
    final count = await db.update(
      'players',
      {'name': newName, 'updated_at': now},
      where: 'group_id IS NULL AND name = ? COLLATE NOCASE',
      whereArgs: [oldName],
    );
    if (ids.isNotEmpty) {
      final ph = List.filled(ids.length, '?').join(',');
      await db.update('game_players', {'name': newName, 'updated_at': now},
          where: 'player_id IN ($ph)', whereArgs: ids);
    }
    return count;
  }

  // Supprimer un joueur global, ses memberships et leurs scores
  Future<int> deletePlayerByName(String playerName) async {
    final db = await database;
    final globals = await db.query('players',
        columns: ['id'],
        where: 'group_id IS NULL AND name = ? COLLATE NOCASE',
        whereArgs: [playerName]);
    final ids = globals.map((r) => r['id'] as int).toList();
    if (ids.isEmpty) return 0;
    final ph = List.filled(ids.length, '?').join(',');
    final gps = await db.query('game_players',
        columns: ['id'], where: 'player_id IN ($ph)', whereArgs: ids);
    final gpIds = gps.map((r) => r['id'] as int).toList();
    if (gpIds.isNotEmpty) {
      final gpph = List.filled(gpIds.length, '?').join(',');
      await db.delete('scores', where: 'playerId IN ($gpph)', whereArgs: gpIds);
      await db.delete('game_players', where: 'id IN ($gpph)', whereArgs: gpIds);
    }
    return await db.delete('players', where: 'id IN ($ph)', whereArgs: ids);
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

    final globalRows = await db.query(
      'players',
      columns: ['id'],
      where: 'group_id IS NULL AND name = ? COLLATE NOCASE AND deleted_at IS NULL',
      whereArgs: [playerName],
      limit: 1,
    );
    if (globalRows.isEmpty) return [];
    final globalId = globalRows.first['id'] as int;

    final args = <Object?>[globalId];
    var whereClause = 'gp.player_id = ? AND gp.deleted_at IS NULL';
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
        gp.id as gpId,
        COALESCE(SUM(s.value), 0) as playerTotal
      FROM game_players gp
      JOIN games g ON g.id = gp.gameId
      LEFT JOIN game_types gt ON g.gameTypeId = gt.id
      LEFT JOIN scores s ON s.playerId = gp.id
      WHERE $whereClause
      GROUP BY g.id, g.name, g.createdAt, g.isLowestScoreWins, gt.name, gp.id
      ORDER BY g.createdAt DESC
      LIMIT ?
    ''', args);

    final history = <Map<String, dynamic>>[];
    for (final row in rows) {
      final gameId = row['gameId'] as int;
      final gpId = row['gpId'] as int;
      final isLowestWins = (row['isLowestScoreWins'] as int) == 1;
      final playerTotal = row['playerTotal'] as int;

      final allTotals = await db.rawQuery('''
        SELECT gp.id, COALESCE(SUM(s.value), 0) as total
        FROM game_players gp
        LEFT JOIN scores s ON s.playerId = gp.id
        WHERE gp.gameId = ? AND gp.deleted_at IS NULL
        GROUP BY gp.id
        ORDER BY total ${isLowestWins ? 'ASC' : 'DESC'}
      ''', [gameId]);

      var rank = 1;
      for (final t in allTotals) {
        if ((t['id'] as int) == gpId) break;
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
