import 'package:flutter/foundation.dart';
import '../models/game_type.dart';
import '../repositories/game_type_repository.dart';
import '../repositories/sqflite/sqflite_game_type_repository.dart';
import '../services/database_service.dart';

class GameTypeProvider with ChangeNotifier {
  GameTypeProvider({GameTypeRepository? repo})
      : _repo = repo ?? SqfliteGameTypeRepository(DatabaseService.instance);

  final GameTypeRepository _repo;

  List<GameType> _gameTypes = [];

  List<GameType> get gameTypes => _gameTypes;

  Future<void> loadGameTypes() async {
    _gameTypes = await _repo.getAll();
    notifyListeners();
  }

  Future<int> createGameType(GameType gameType) async {
    final id = await _repo.create(gameType);
    await loadGameTypes();
    return id;
  }

  Future<void> updateGameType(GameType gameType) async {
    await _repo.update(gameType);
    await loadGameTypes();
  }

  Future<void> deleteGameType(int id) async {
    await _repo.delete(id);
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
