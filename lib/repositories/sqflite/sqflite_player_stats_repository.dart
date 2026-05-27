import '../../services/database_service.dart';
import '../player_stats_repository.dart';

class SqflitePlayerStatsRepository implements PlayerStatsRepository {
  SqflitePlayerStatsRepository(this._db);

  final DatabaseService _db;

  @override
  Future<Map<String, dynamic>> getStatsByName(String playerName) =>
      _db.getPlayerStats(playerName);
}
