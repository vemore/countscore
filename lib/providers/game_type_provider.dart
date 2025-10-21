import 'package:flutter/foundation.dart';
import '../models/game_type.dart';
import '../services/database_service.dart';

class GameTypeProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<GameType> _gameTypes = [];

  List<GameType> get gameTypes => _gameTypes;

  Future<void> loadGameTypes() async {
    _gameTypes = await _db.getAllGameTypes();
    notifyListeners();
  }

  Future<int> createGameType(GameType gameType) async {
    final id = await _db.createGameType(gameType);
    await loadGameTypes();
    return id;
  }

  Future<void> updateGameType(GameType gameType) async {
    await _db.updateGameType(gameType);
    await loadGameTypes();
  }

  Future<void> deleteGameType(int id) async {
    await _db.deleteGameType(id);
    await loadGameTypes();
  }

  GameType? getGameTypeById(int? id) {
    if (id == null) return null;
    try {
      return _gameTypes.firstWhere((gt) => gt.id == id);
    } catch (e) {
      return null;
    }
  }
}
