import '../../models/game_analysis.dart';
import '../../services/database_service.dart';
import '../game_analysis_repository.dart';

class SqfliteGameAnalysisRepository implements GameAnalysisRepository {
  SqfliteGameAnalysisRepository(this._db);

  final DatabaseService _db;

  @override
  Future<GameAnalysis?> getByGame(int gameId) => _db.getAnalysisByGame(gameId);

  @override
  Future<int> upsert(GameAnalysis analysis) => _db.upsertAnalysis(analysis);

  @override
  Future<int> deleteByGame(int gameId) => _db.deleteAnalysisByGame(gameId);

  @override
  Future<List<Map<String, dynamic>>> getRecentPlayerHistory(
    String playerName, {
    int limit = 10,
    int? excludeGameId,
  }) =>
      _db.getRecentPlayerHistory(
        playerName,
        limit: limit,
        excludeGameId: excludeGameId,
      );
}
