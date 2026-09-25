import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/game_standing.dart';
import '../models/game_type.dart';
import '../models/player.dart';
import '../models/player_stats.dart';
import '../models/round.dart';
import '../models/score.dart';
import '../repositories/drift/drift_repositories.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_type_repository.dart';
import '../repositories/player_repository.dart';
import '../repositories/player_stats_repository.dart';
import '../repositories/round_repository.dart';
import '../repositories/score_repository.dart';
import '../services/drift/database.dart';

class GameProvider with ChangeNotifier {
  GameProvider({
    GameRepository? gameRepo,
    PlayerRepository? playerRepo,
    RoundRepository? roundRepo,
    ScoreRepository? scoreRepo,
    GameTypeRepository? gameTypeRepo,
    PlayerStatsRepository? statsRepo,
  })  : _gameRepo = gameRepo ?? DriftGameRepository(AppDatabase.instance),
        _playerRepo = playerRepo ?? DriftPlayerRepository(AppDatabase.instance),
        _roundRepo = roundRepo ?? DriftRoundRepository(AppDatabase.instance),
        _scoreRepo = scoreRepo ?? DriftScoreRepository(AppDatabase.instance),
        _gameTypeRepo = gameTypeRepo ?? DriftGameTypeRepository(AppDatabase.instance),
        _statsRepo = statsRepo ?? DriftPlayerStatsRepository(AppDatabase.instance);

  final GameRepository _gameRepo;
  final PlayerRepository _playerRepo;
  final RoundRepository _roundRepo;
  final ScoreRepository _scoreRepo;
  final GameTypeRepository _gameTypeRepo;
  final PlayerStatsRepository _statsRepo;

  List<Game> _games = [];
  Game? _currentGame;
  List<Player> _currentPlayers = [];
  List<Round> _currentRounds = [];
  Map<int, int> _roundCounts = {};
  final Map<String, Score> _scores = {}; // Key: "playerId_roundId"

  List<Game> get games => _games;
  Game? get currentGame => _currentGame;
  List<Player> get currentPlayers => _currentPlayers;
  List<Round> get currentRounds => _currentRounds;
  Map<String, Score> get scores => _scores;

  /// How many rounds each listed game has played, keyed by game id.
  ///
  /// Loaded with the list in one grouped query, because the game list needs the
  /// count of every card at once: a game with no round was never played, so it
  /// cannot be declared over. Kept in step by [addRound] and [deleteRound] so
  /// that returning from the board does not show a stale count.
  int roundCountOf(int gameId) => _roundCounts[gameId] ?? 0;

  Future<void> loadGames() async {
    _games = await _gameRepo.getAll();
    _roundCounts = await _roundRepo.countByGame();
    notifyListeners();
  }

  Future<int> createGame(
    String name,
    int? gameTypeId,
    bool isLowestScoreWins,
    List<String> playerNames,
    Map<String, int?>? playerColors,
  ) async {
    final game = Game(
      name: name,
      gameTypeId: gameTypeId,
      isLowestScoreWins: isLowestScoreWins,
    );

    final gameId = await _gameRepo.create(game);

    for (int i = 0; i < playerNames.length; i++) {
      final playerName = playerNames[i];
      await _playerRepo.create(Player(
        gameId: gameId,
        name: playerName,
        orderIndex: i,
        colorValue: playerColors?[playerName],
      ));
    }

    await loadGames();
    return gameId;
  }

  /// Creates the next game of the evening from [source]: same type, same win
  /// rule, same players in the same seat order and colours, named [name].
  /// Returns the new game's id.
  ///
  /// [source] is only read — not its rounds, not its finished state — and the
  /// current game is left as it was; the caller loads the new one.
  Future<int> playAgain(Game source, String name) async {
    final players = await _playerRepo.getByGame(source.id!); // by orderIndex
    return createGame(
      name,
      source.gameTypeId,
      source.isLowestScoreWins,
      [for (final p in players) p.name],
      {for (final p in players) p.name: p.colorValue},
    );
  }

  Future<void> loadGame(int gameId) async {
    _currentGame = await _gameRepo.getById(gameId);
    _currentPlayers = await _playerRepo.getByGame(gameId);
    _currentRounds = await _roundRepo.getByGame(gameId);

    _scores.clear();
    for (final player in _currentPlayers) {
      final playerScores = await _scoreRepo.getByPlayer(player.id!);
      for (final score in playerScores) {
        _scores['${score.playerId}_${score.roundId}'] = score;
      }
    }

    notifyListeners();
  }

  /// The number the next round of the current game gets.
  ///
  /// Max, not count: after a round in the middle is deleted, count + 1 names a
  /// round that still exists — which a shared game's server refuses.
  int get nextRoundNumber =>
      _currentRounds.fold<int>(
          0, (m, r) => r.roundNumber > m ? r.roundNumber : m) +
      1;

  Future<void> addRound() async {
    if (_currentGame == null) return;
    await _insertRound();
    notifyListeners();
  }

  /// Adds a round with its [scores] (keyed by player id) already in it, and
  /// notifies once: the board's keypad writes a round only when it is
  /// validated, so no empty row is ever shown or left behind.
  Future<void> addRoundWithScores(Map<int, int> scores) async {
    if (_currentGame == null) return;
    final roundId = await _insertRound();
    for (final e in scores.entries) {
      await _scoreRepo.upsert(
          Score(playerId: e.key, roundId: roundId, value: e.value));
      final stored = await _scoreRepo.getByPlayerAndRound(e.key, roundId);
      if (stored != null) _scores['${e.key}_$roundId'] = stored;
    }
    notifyListeners();
  }

  /// Creates the next round of the current game, without notifying.
  Future<int> _insertRound() async {
    final roundNumber = nextRoundNumber;
    final roundId = await _roundRepo.create(Round(
      gameId: _currentGame!.id!,
      roundNumber: roundNumber,
    ));

    _currentRounds.add(Round(
      id: roundId,
      gameId: _currentGame!.id!,
      roundNumber: roundNumber,
    ));

    await _gameRepo.update(_currentGame!);
    _roundCounts[_currentGame!.id!] = roundCountOf(_currentGame!.id!) + 1;
    return roundId;
  }

  Future<void> deleteRound(int roundId) async {
    await _roundRepo.delete(roundId);

    _currentRounds.removeWhere((r) => r.id == roundId);
    _scores.removeWhere((key, value) => value.roundId == roundId);

    if (_currentGame != null) {
      await _gameRepo.update(_currentGame!);
      _roundCounts[_currentGame!.id!] = _currentRounds.length;
    }

    notifyListeners();
  }

  Future<void> updateRoundComment(int roundId, String? comment) async {
    final normalized = (comment == null || comment.trim().isEmpty)
        ? null
        : comment.trim();

    await _roundRepo.updateComment(roundId, normalized);

    final index = _currentRounds.indexWhere((r) => r.id == roundId);
    if (index != -1) {
      final r = _currentRounds[index];
      _currentRounds[index] = Round(
        id: r.id,
        gameId: r.gameId,
        roundNumber: r.roundNumber,
        comment: normalized,
      );
    }

    if (_currentGame != null) {
      await _gameRepo.update(_currentGame!);
    }

    notifyListeners();
  }

  Future<void> updateScore(int playerId, int roundId, int value) async {
    final score = Score(
      playerId: playerId,
      roundId: roundId,
      value: value,
    );

    await _scoreRepo.upsert(score);

    final updatedScore = await _scoreRepo.getByPlayerAndRound(playerId, roundId);
    if (updatedScore != null) {
      _scores['${playerId}_$roundId'] = updatedScore;
    }

    if (_currentGame != null) {
      await _gameRepo.update(_currentGame!);
    }

    notifyListeners();
  }

  int? getScore(int playerId, int roundId) {
    return _scores['${playerId}_$roundId']?.value;
  }

  int getPlayerTotal(int playerId) {
    int total = 0;
    for (final round in _currentRounds) {
      final score = _scores['${playerId}_${round.id}'];
      if (score != null) {
        total += score.value;
      }
    }
    return total;
  }

  String? _remotelyDeletedGameName;

  /// The name of the open game another device deleted, returned once: the board
  /// screen reads it to close itself and say why.
  String? takeRemotelyDeletedGameName() {
    final name = _remotelyDeletedGameName;
    _remotelyDeletedGameName = null;
    return name;
  }

  /// Reloads what is on screen after group sync changed the database underneath.
  Future<void> refreshFromSync() async {
    await loadGames();
    final current = _currentGame;
    if (current == null) return;
    if (await _gameRepo.getById(current.id!) == null) {
      // Deleted on another device. The board watches for this and closes.
      _remotelyDeletedGameName = current.name;
      _currentGame = null;
      _currentPlayers = [];
      _currentRounds = [];
      _scores.clear();
      notifyListeners();
      return;
    }
    await loadGame(current.id!);
  }

  Future<void> deleteGame(int gameId) async {
    await _gameRepo.delete(gameId);
    await loadGames();

    if (_currentGame?.id == gameId) {
      _currentGame = null;
      _currentPlayers = [];
      _currentRounds = [];
      _scores.clear();
      notifyListeners();
    }
  }

  Future<void> updateGameName(int gameId, String newName) async {
    final game = await _gameRepo.getById(gameId);
    if (game != null) {
      await _gameRepo.update(game.copyWith(name: newName));
      await loadGames();

      if (_currentGame?.id == gameId) {
        _currentGame = _currentGame!.copyWith(name: newName);
        notifyListeners();
      }
    }
  }

  /// Marks a game finished, or reopens it.
  ///
  /// Returns true only when this call is what finished the game — a null
  /// `finishedAt` becoming set. Finishing an already finished game, or
  /// reopening one, returns false. Callers use that to decide whether to consider
  /// the Play review sheet at all; how many games count towards it is the
  /// number of finished games in the database (`GameRepository.countFinished`),
  /// so a finish → reopen → finish cycle counts once and an undone finish not
  /// at all.
  ///
  /// Nothing is locked here: the board disables its round button while the
  /// game is finished; score edits stay open.
  Future<bool> setGameFinished(int gameId, bool finished) async {
    final game = await _gameRepo.getById(gameId);
    if (game == null) return false;

    final wasFinished = game.isFinished;
    if (finished == wasFinished) return false;

    final updated = finished
        ? game.copyWith(finishedAt: DateTime.now())
        : game.copyWith(clearFinishedAt: true);
    await _gameRepo.update(updated);
    await loadGames();

    if (_currentGame?.id == gameId) {
      _currentGame = finished
          ? _currentGame!.copyWith(finishedAt: updated.finishedAt)
          : _currentGame!.copyWith(clearFinishedAt: true);
    }
    notifyListeners();

    return finished;
  }

  Future<void> updateGameType(int gameId, int? gameTypeId) async {
    final game = await _gameRepo.getById(gameId);
    if (game != null) {
      bool isLowestScoreWins = game.isLowestScoreWins;

      if (gameTypeId != null) {
        final gameType = await _gameTypeRepo.getById(gameTypeId);
        if (gameType != null) {
          isLowestScoreWins = gameType.isLowestScoreWins;
        }
      }

      await _gameRepo.update(game.copyWith(
        gameTypeId: gameTypeId,
        isLowestScoreWins: isLowestScoreWins,
      ));
      await loadGames();

      if (_currentGame?.id == gameId) {
        await loadGame(gameId);
      }
    }
  }

  Future<void> addPlayer(String name) async {
    if (_currentGame == null) return;

    final orderIndex = _currentPlayers.length;
    final playerId = await _playerRepo.create(Player(
      gameId: _currentGame!.id!,
      name: name,
      orderIndex: orderIndex,
    ));

    _currentPlayers.add(Player(
      id: playerId,
      gameId: _currentGame!.id!,
      name: name,
      orderIndex: orderIndex,
    ));

    notifyListeners();
  }

  Future<void> deletePlayer(int playerId) async {
    await _playerRepo.delete(playerId);
    _currentPlayers.removeWhere((p) => p.id == playerId);

    _scores.removeWhere((key, value) => value.playerId == playerId);

    notifyListeners();
  }

  Future<List<String>> getAllPlayerNames() async {
    return await _playerRepo.getAllNames();
  }

  Future<Map<String, int?>> getPlayerColors() async {
    return await _playerRepo.getColorsByName();
  }

  /// How many games each known player has played, by name (see
  /// `PlayerRepository.getGameCountsByName`).
  Future<Map<String, int>> getPlayerGameCounts() {
    return _playerRepo.getGameCountsByName();
  }

  Future<int?> getPlayerColorValue(String name) async {
    final colors = await _playerRepo.getColorsByName();
    return colors[name];
  }

  Future<void> updatePlayerColor(String name, int colorValue) async {
    await _playerRepo.updateColorByName(name, colorValue);
    notifyListeners();
  }

  Future<List<Player>> getPlayersOfGame(int gameId) {
    return _playerRepo.getByGame(gameId);
  }

  /// [game]'s players in seat order, their totals and its ranking rule,
  /// without making it the current game. Only scores of rounds that still
  /// exist are counted, as on the board, and the rounds keep their play order
  /// so that a finished elimination game ranks by who went out when
  /// (`GameStanding.forGame`).
  ///
  /// [gameType] is the game's type, which the caller holds
  /// (`GameTypeProvider`); null ranks by score, as every type without an
  /// elimination rule does.
  Future<GameStanding> standingOf(Game game, {GameType? gameType}) async {
    final players = await _playerRepo.getByGame(game.id!);
    final rounds = await _roundRepo.getByGame(game.id!);
    final roundIds = {for (final round in rounds) round.id};
    final scores = <int, Map<int, int>>{};
    for (final player in players) {
      for (final score in await _scoreRepo.getByPlayer(player.id!)) {
        if (!roundIds.contains(score.roundId)) continue;
        (scores[player.id!] ??= {})[score.roundId] = score.value;
      }
    }
    return GameStanding.forGame(
      players: players,
      rounds: rounds,
      scoreOf: (playerId, roundId) => scores[playerId]?[roundId],
      isLowestScoreWins: game.isLowestScoreWins,
      isFinished: game.isFinished,
      gameType: gameType,
    );
  }

  /// Every finished game with its players' totals — what the leaderboard and
  /// the player card are computed from (`lib/models/player_stats.dart`).
  Future<List<FinishedGameResult>> getFinishedGameResults() =>
      _statsRepo.getFinishedGameResults();

  Future<void> renamePlayer(String oldName, String newName) async {
    await _playerRepo.renameByName(oldName, newName);

    await loadGames();
    if (_currentGame != null) {
      await loadGame(_currentGame!.id!);
    }

    notifyListeners();
  }

  Future<void> deletePlayerByName(String playerName) async {
    await _playerRepo.deleteByName(playerName);

    await loadGames();
    if (_currentGame != null) {
      await loadGame(_currentGame!.id!);
    }

    notifyListeners();
  }
}
