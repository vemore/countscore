import 'player.dart';

/// Where a game stands: its players in seat order and each one's total.
///
/// Read by the game list for every card — the Resume hero's leader and a
/// finished game's winner — without loading the game as the current one.
class GameStanding {
  GameStanding({
    required this.players,
    required this.totals,
    required this.isLowestScoreWins,
  });

  /// The game's players sorted by `orderIndex`.
  final List<Player> players;

  /// Each player's total over the game's rounds, keyed by player id. A player
  /// with no score yet is absent.
  final Map<int, int> totals;

  final bool isLowestScoreWins;

  /// Whether any score has been entered at all.
  bool get hasScores => totals.isNotEmpty;

  /// The player in the lead — the winner, on a finished game — or null while
  /// no score has been entered. A tie goes to the earlier seat.
  Player? get leader {
    if (!hasScores) return null;
    Player? best;
    var bestTotal = 0;
    for (final player in players) {
      final total = totals[player.id] ?? 0;
      if (best == null ||
          (isLowestScoreWins ? total < bestTotal : total > bestTotal)) {
        best = player;
        bestTotal = total;
      }
    }
    return best;
  }

  /// The one player alone on the first place — who the rankings crown — or
  /// null before the first score and on a tie for the lead: a round of all
  /// zeros crowns nobody. [leader] still picks the earlier seat, which the
  /// board uses to decide whether to sort by rank.
  Player? get soleLeader {
    if (!hasScores) return null;
    final first = [
      for (final p in players)
        if (p.id != null && ranks[p.id] == 1) p
    ];
    return first.length == 1 ? first.single : null;
  }

  /// [player]'s total, 0 when they have no score yet.
  int totalOf(Player player) => totals[player.id] ?? 0;

  /// Each player's place, keyed by player id: 1 for the best total, and
  /// players on the same total share a place (1, 2, 2, 4). Players without an
  /// id are left out.
  Map<int, int> get ranks {
    final result = <int, int>{};
    for (final player in players) {
      if (player.id == null) continue;
      final total = totalOf(player);
      final better = players.where((other) {
        final t = totalOf(other);
        return isLowestScoreWins ? t < total : t > total;
      }).length;
      result[player.id!] = better + 1;
    }
    return result;
  }
}
