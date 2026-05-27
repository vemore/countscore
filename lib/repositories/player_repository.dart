import '../models/player.dart';

abstract class PlayerRepository {
  Future<int> create(Player player);
  Future<List<Player>> getByGame(int gameId);
  Future<int> update(Player player);
  Future<int> delete(int id);

  /// Cross-game queries — these will be revisited in Jalon 2 (v6 schema) when
  /// players become global per-group. For now they aggregate by ``name``, which
  /// has the known bug of merging different humans with the same name.
  Future<List<String>> getAllNames();
  Future<Map<String, int?>> getColorsByName();
  Future<int> renameByName(String oldName, String newName);
  Future<int> deleteByName(String name);
  Future<void> updateColorByName(String name, int colorValue);
}
