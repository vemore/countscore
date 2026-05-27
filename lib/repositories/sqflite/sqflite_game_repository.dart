import '../../models/game.dart';
import '../../services/database_service.dart';
import '../game_repository.dart';

/// Thin adapter from the [GameRepository] interface to the legacy
/// [DatabaseService]. Once Drift lands (Jalon 3 in ARCHITECTURE.md), replace
/// this with `DriftGameRepository` — Providers won't notice.
class SqfliteGameRepository implements GameRepository {
  SqfliteGameRepository(this._db);

  final DatabaseService _db;

  @override
  Future<int> create(Game game) => _db.createGame(game);

  @override
  Future<Game?> getById(int id) => _db.getGame(id);

  @override
  Future<List<Game>> getAll() => _db.getAllGames();

  @override
  Future<List<Game>> getByType(int gameTypeId) => _db.getGamesByType(gameTypeId);

  @override
  Future<int> update(Game game) => _db.updateGame(game);

  @override
  Future<int> delete(int id) => _db.deleteGame(id);
}
