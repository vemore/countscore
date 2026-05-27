import '../models/game_type.dart';

abstract class GameTypeRepository {
  Future<int> create(GameType gameType);
  Future<GameType?> getById(int id);
  Future<List<GameType>> getAll();
  Future<int> update(GameType gameType);

  /// Throws if at least one game still references the type.
  Future<int> delete(int id);
}
