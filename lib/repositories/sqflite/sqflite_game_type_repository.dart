import '../../models/game_type.dart';
import '../../services/database_service.dart';
import '../game_type_repository.dart';

class SqfliteGameTypeRepository implements GameTypeRepository {
  SqfliteGameTypeRepository(this._db);

  final DatabaseService _db;

  @override
  Future<int> create(GameType gameType) => _db.createGameType(gameType);

  @override
  Future<GameType?> getById(int id) => _db.getGameType(id);

  @override
  Future<List<GameType>> getAll() => _db.getAllGameTypes();

  @override
  Future<int> update(GameType gameType) => _db.updateGameType(gameType);

  @override
  Future<int> delete(int id) => _db.deleteGameType(id);
}
