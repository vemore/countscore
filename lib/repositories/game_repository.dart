import '../models/game.dart';

/// Repository interface for [Game] entities.
///
/// Sole implementation: [DriftGameRepository] in `drift/drift_repositories.dart`
/// — see .llmwiki/DataLayer.md. The Providers depend on this abstraction, so an
/// engine swap stays a one-line change in the DI binding.
abstract class GameRepository {
  Future<int> create(Game game);
  Future<Game?> getById(int id);
  Future<List<Game>> getAll();
  Future<List<Game>> getByType(int gameTypeId);
  Future<int> update(Game game);
  Future<int> delete(int id);
}
