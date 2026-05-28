import '../models/game_analysis.dart';

abstract class GameAnalysisRepository {
  Future<GameAnalysis?> getByGame(int gameId);
  Future<int> upsert(GameAnalysis analysis);
  Future<int> deleteByGame(int gameId);
  Future<List<Map<String, dynamic>>> getRecentPlayerHistory(
    String playerName, {
    int limit,
    int? excludeGameId,
  });
}
