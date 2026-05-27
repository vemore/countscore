import '../../models/player.dart';
import '../../services/database_service.dart';
import '../player_repository.dart';

class SqflitePlayerRepository implements PlayerRepository {
  SqflitePlayerRepository(this._db);

  final DatabaseService _db;

  @override
  Future<int> create(Player player) => _db.createPlayer(player);

  @override
  Future<List<Player>> getByGame(int gameId) => _db.getPlayersByGame(gameId);

  @override
  Future<int> update(Player player) => _db.updatePlayer(player);

  @override
  Future<int> delete(int id) => _db.deletePlayer(id);

  @override
  Future<List<String>> getAllNames() => _db.getAllPlayerNames();

  @override
  Future<Map<String, int?>> getColorsByName() => _db.getPlayerColors();

  @override
  Future<int> renameByName(String oldName, String newName) =>
      _db.renamePlayer(oldName, newName);

  @override
  Future<int> deleteByName(String name) => _db.deletePlayerByName(name);

  @override
  Future<void> updateColorByName(String name, int colorValue) =>
      _db.updatePlayerColor(name, colorValue);
}
