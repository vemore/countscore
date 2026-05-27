import '../models/round.dart';

abstract class RoundRepository {
  Future<int> create(Round round);
  Future<List<Round>> getByGame(int gameId);
  Future<int> delete(int id);
}
