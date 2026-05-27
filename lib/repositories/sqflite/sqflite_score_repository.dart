import '../../models/score.dart';
import '../../services/database_service.dart';
import '../score_repository.dart';

class SqfliteScoreRepository implements ScoreRepository {
  SqfliteScoreRepository(this._db);

  final DatabaseService _db;

  @override
  Future<int> create(Score score) => _db.createScore(score);

  @override
  Future<Score?> getByPlayerAndRound(int playerId, int roundId) =>
      _db.getScore(playerId, roundId);

  @override
  Future<List<Score>> getByPlayer(int playerId) => _db.getScoresByPlayer(playerId);

  @override
  Future<int> update(Score score) => _db.updateScore(score);

  @override
  Future<int> upsert(Score score) => _db.upsertScore(score);
}
