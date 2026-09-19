import '../models/player_stats.dart';

/// Aggregated player statistics across games.
///
/// Players are known by their global `players` row since v9, never by a name
/// alone (.llmwiki/SchemaV10.md).
abstract class PlayerStatsRepository {
  /// Games, wins and a per-game-type breakdown for the global player named
  /// [playerName] — the summary the Players screen shows.
  Future<Map<String, dynamic>> getStatsByName(String playerName);

  /// Every live, finished game (`finishedAt` set) with at least one score, and
  /// each player's final total, most recent first. The leaderboard and the
  /// player card are computed from it (`lib/models/player_stats.dart`).
  Future<List<FinishedGameResult>> getFinishedGameResults();
}
