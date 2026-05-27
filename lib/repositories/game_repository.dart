import '../models/game.dart';

/// Repository interface for [Game] entities.
///
/// Implementations: [SqfliteGameRepository] today, [DriftGameRepository] after
/// Jalon 3 in ARCHITECTURE.md. The Providers depend on this abstraction so the
/// swap is a one-line change in the DI binding.
abstract class GameRepository {
  Future<int> create(Game game);
  Future<Game?> getById(int id);
  Future<List<Game>> getAll();
  Future<List<Game>> getByType(int gameTypeId);
  Future<int> update(Game game);
  Future<int> delete(int id);
}
