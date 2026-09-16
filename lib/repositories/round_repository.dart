import '../models/round.dart';

abstract class RoundRepository {
  Future<int> create(Round round);
  Future<List<Round>> getByGame(int gameId);

  /// How many rounds each game has, keyed by game id, in one query.
  ///
  /// The game list needs the count of every game at once to know which ones
  /// were actually played; asking per card would be one query per row over the
  /// whole history. A game with no round is simply absent from the map.
  Future<Map<int, int>> countByGame();
  Future<int> delete(int id);
  Future<int> updateComment(int roundId, String? comment);
}
