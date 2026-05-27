import '../../models/round.dart';
import '../../services/database_service.dart';
import '../round_repository.dart';

class SqfliteRoundRepository implements RoundRepository {
  SqfliteRoundRepository(this._db);

  final DatabaseService _db;

  @override
  Future<int> create(Round round) => _db.createRound(round);

  @override
  Future<List<Round>> getByGame(int gameId) => _db.getRoundsByGame(gameId);

  @override
  Future<int> delete(int id) => _db.deleteRound(id);
}
