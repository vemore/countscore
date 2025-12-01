import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../models/score.dart';
import '../services/database_service.dart';

class GameProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

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

  // Charger toutes les parties
  Future<void> loadGames() async {
    _games = await _db.getAllGames();
    notifyListeners();
  }

  // Créer une nouvelle partie
  Future<int> createGame(String name, int? gameTypeId, bool isLowestScoreWins, List<String> playerNames) async {
    final game = Game(
      name: name,
      gameTypeId: gameTypeId,
      isLowestScoreWins: isLowestScoreWins,
    );

    final gameId = await _db.createGame(game);

    // Ajouter les joueurs
    for (int i = 0; i < playerNames.length; i++) {
      await _db.createPlayer(Player(
        gameId: gameId,
        name: playerNames[i],
        orderIndex: i,
      ));
    }

    await loadGames();
    return gameId;
  }

  // Charger une partie spécifique
  Future<void> loadGame(int gameId) async {
    _currentGame = await _db.getGame(gameId);
    _currentPlayers = await _db.getPlayersByGame(gameId);
    _currentRounds = await _db.getRoundsByGame(gameId);

    // Charger tous les scores
    _scores.clear();
    for (final player in _currentPlayers) {
      final playerScores = await _db.getScoresByPlayer(player.id!);
      for (final score in playerScores) {
        _scores['${score.playerId}_${score.roundId}'] = score;
      }
    }

    notifyListeners();
  }

  // Ajouter un tour
  Future<void> addRound() async {
    if (_currentGame == null) return;

    final roundNumber = _currentRounds.length + 1;
    final roundId = await _db.createRound(Round(
      gameId: _currentGame!.id!,
      roundNumber: roundNumber,
    ));

    // Ajouter le tour à la liste locale
    _currentRounds.add(Round(
      id: roundId,
      gameId: _currentGame!.id!,
      roundNumber: roundNumber,
    ));

    // Mettre à jour la date de modification
    await _db.updateGame(_currentGame!);

    notifyListeners();
  }

  // Supprimer un tour
  Future<void> deleteRound(int roundId) async {
    await _db.deleteRound(roundId);

    // Retirer de la liste locale et réorganiser
    _currentRounds.removeWhere((r) => r.id == roundId);

    // Supprimer les scores associés de la map
    _scores.removeWhere((key, value) => value.roundId == roundId);

    // Mettre à jour la date de modification
    if (_currentGame != null) {
      await _db.updateGame(_currentGame!);
    }

    notifyListeners();
  }

  // Mettre à jour un score
  Future<void> updateScore(int playerId, int roundId, int value) async {
    final score = Score(
      playerId: playerId,
      roundId: roundId,
      value: value,
    );

    await _db.upsertScore(score);

    // Recharger le score depuis la DB pour avoir l'ID
    final updatedScore = await _db.getScore(playerId, roundId);
    if (updatedScore != null) {
      _scores['${playerId}_$roundId'] = updatedScore;
    }

    // Mettre à jour la date de modification
    if (_currentGame != null) {
      await _db.updateGame(_currentGame!);
    }

    notifyListeners();
  }

  // Obtenir le score pour un joueur et un tour
  int? getScore(int playerId, int roundId) {
    return _scores['${playerId}_$roundId']?.value;
  }

  // Calculer le total d'un joueur
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

  // Obtenir le classement
  List<Map<String, dynamic>> getRanking() {
    final ranking = <Map<String, dynamic>>[];

    for (final player in _currentPlayers) {
      ranking.add({
        'player': player,
        'total': getPlayerTotal(player.id!),
      });
    }

    // Trier selon les règles de la partie
    if (_currentGame != null) {
      ranking.sort((a, b) {
        final comparison = (a['total'] as int).compareTo(b['total'] as int);
        return _currentGame!.isLowestScoreWins ? comparison : -comparison;
      });
    }

    return ranking;
  }

  // Supprimer une partie
  Future<void> deleteGame(int gameId) async {
    await _db.deleteGame(gameId);
    await loadGames();

    // Si c'est la partie courante, la réinitialiser
    if (_currentGame?.id == gameId) {
      _currentGame = null;
      _currentPlayers = [];
      _currentRounds = [];
      _scores.clear();
      notifyListeners();
    }
  }

  // Mettre à jour le nom de la partie
  Future<void> updateGameName(int gameId, String newName) async {
    final game = await _db.getGame(gameId);
    if (game != null) {
      await _db.updateGame(game.copyWith(name: newName));
      await loadGames();

      if (_currentGame?.id == gameId) {
        _currentGame = _currentGame!.copyWith(name: newName);
        notifyListeners();
      }
    }
  }

  // Mettre à jour le type de jeu de la partie
  Future<void> updateGameType(int gameId, int? gameTypeId) async {
    final game = await _db.getGame(gameId);
    if (game != null) {
      // Synchroniser isLowestScoreWins avec le GameType sélectionné
      bool isLowestScoreWins = game.isLowestScoreWins; // Valeur par défaut

      if (gameTypeId != null) {
        final gameType = await _db.getGameType(gameTypeId);
        if (gameType != null) {
          isLowestScoreWins = gameType.isLowestScoreWins;
        }
      }

      await _db.updateGame(game.copyWith(
        gameTypeId: gameTypeId,
        isLowestScoreWins: isLowestScoreWins,
      ));
      await loadGames();

      if (_currentGame?.id == gameId) {
        await loadGame(gameId); // Recharger complètement pour rafraîchir l'UI
      }
    }
  }

  // Ajouter un joueur à la partie
  Future<void> addPlayer(String name) async {
    if (_currentGame == null) return;

    final orderIndex = _currentPlayers.length;
    final playerId = await _db.createPlayer(Player(
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

  // Supprimer un joueur
  Future<void> deletePlayer(int playerId) async {
    await _db.deletePlayer(playerId);
    _currentPlayers.removeWhere((p) => p.id == playerId);

    // Supprimer les scores associés
    _scores.removeWhere((key, value) => value.playerId == playerId);

    notifyListeners();
  }

  // Obtenir tous les noms de joueurs
  Future<List<String>> getAllPlayerNames() async {
    return await _db.getAllPlayerNames();
  }

  // Obtenir les statistiques d'un joueur
  Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    return await _db.getPlayerStats(playerName);
  }

  // Renommer un joueur dans toutes les parties
  Future<void> renamePlayer(String oldName, String newName) async {
    await _db.renamePlayer(oldName, newName);

    // Recharger les données si nécessaire
    await loadGames();
    if (_currentGame != null) {
      await loadGame(_currentGame!.id!);
    }

    notifyListeners();
  }

  // Supprimer un joueur par nom dans toutes les parties
  Future<void> deletePlayerByName(String playerName) async {
    await _db.deletePlayerByName(playerName);

    // Recharger les données
    await loadGames();
    if (_currentGame != null) {
      await loadGame(_currentGame!.id!);
    }

    notifyListeners();
  }
}
