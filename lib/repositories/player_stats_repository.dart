import '../models/player_stats.dart';

/// Aggregated player statistics across games.
///
/// Players are known by their global `players` row since v9, never by a name
/// alone (.llmwiki/SchemaV10.md).
abstract class PlayerStatsRepository {
  /// Every live, finished game (`finishedAt` set) with at least one score, and
  /// each player's final total, most recent first. The leaderboard and the
  /// player card are computed from it (`lib/models/player_stats.dart`).
  ///
  /// Each result carries the `RankingRule` its game type calls for and, under
  /// `RankingRule.eliminationOrder`, the round each player went out at: the
  /// statistics place a finished game exactly as its standings screen does
  /// (`GameStanding`, `lib/models/game_standing.dart`).
  Future<List<FinishedGameResult>> getFinishedGameResults();
}
