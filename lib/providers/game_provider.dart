import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/player.dart';
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
  final Map<String, Score> _scores = {}; // Key: "playerId_roundId"

  List<Game> get games => _games;
  Game? get currentGame => _currentGame;
  List<Player> get currentPlayers => _currentPlayers;
  List<Round> get currentRounds => _currentRounds;
  Map<String, Score> get scores => _scores;

  Future<void> loadGames() async {
    _games = await _gameRepo.getAll();
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

  Future<void> addRound() async {
    if (_currentGame == null) return;

    final roundNumber = _currentRounds.length + 1;
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

    notifyListeners();
  }

  Future<void> deleteRound(int roundId) async {
    await _roundRepo.delete(roundId);

    _currentRounds.removeWhere((r) => r.id == roundId);
    _scores.removeWhere((key, value) => value.roundId == roundId);

    if (_currentGame != null) {
      await _gameRepo.update(_currentGame!);
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

  List<Map<String, dynamic>> getRanking() {
    final ranking = <Map<String, dynamic>>[];

    for (final player in _currentPlayers) {
      ranking.add({
        'player': player,
        'total': getPlayerTotal(player.id!),
      });
    }

    if (_currentGame != null) {
      ranking.sort((a, b) {
        final comparison = (a['total'] as int).compareTo(b['total'] as int);
        return _currentGame!.isLowestScoreWins ? comparison : -comparison;
      });
    }

    return ranking;
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

  Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    return await _statsRepo.getStatsByName(playerName);
  }

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
