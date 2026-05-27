/// Aggregated player statistics across games.
///
/// Currently keyed by player **name** (legacy from v5). In Jalon 2 (v6 schema)
/// players become global per-group and this repository will switch to keying by
/// `playerUuid`, eliminating the bug where two humans named "Alice" are merged.
abstract class PlayerStatsRepository {
  Future<Map<String, dynamic>> getStatsByName(String playerName);
}
