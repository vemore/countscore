import '../models/game_type.dart';

abstract class GameTypeRepository {
  Future<int> create(GameType gameType);
  Future<GameType?> getById(int id);
  Future<List<GameType>> getAll();
  Future<int> update(GameType gameType);

  /// How many live games reference the type. The screen asks **before**
  /// offering the deletion, so the refusal can be a localized sentence naming
  /// the count instead of the exception [delete] throws.
  Future<int> countGames(int id);

  /// How many of those games are finished — the standings that flipping the
  /// type's win direction would reverse (`GameStanding.ranks` is recomputed
  /// from the scores every time, never stored).
  Future<int> countFinishedGames(int id);

  /// Throws if at least one game still references the type.
  Future<int> delete(int id);
}
