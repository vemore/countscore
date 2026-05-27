import '../models/score.dart';

abstract class ScoreRepository {
  Future<int> create(Score score);
  Future<Score?> getByPlayerAndRound(int playerId, int roundId);
  Future<List<Score>> getByPlayer(int playerId);
  Future<int> update(Score score);

  /// Inserts or updates the score for (playerId, roundId).
  Future<int> upsert(Score score);
}
