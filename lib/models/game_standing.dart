import 'game_type.dart';
import 'player.dart';
import 'round.dart';

/// Which order a standing's places follow.
///
/// The rule is *derived* from the game type and the game's state, never
/// stored: no column, no migration
/// (`wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`).
enum RankingRule {
  /// The total decides, under the game's `isLowestScoreWins`. The default for
  /// every type, and what an open game always shows — while the game runs, the
  /// score order is the right thing to show whatever the shape.
  score,

  /// The survivor first, then the others by **reverse** elimination order —
  /// the last one out ranks best — the total only breaking a tie. Only a
  /// finished game of an elimination type follows it
  /// ([GameStanding.ranksByEliminationOrder]).
  eliminationOrder,
}

/// Where a game stands: its players in seat order, each one's total, and the
/// rule its places follow.
///
/// Read by the game list for every card — the Resume hero's leader and a
/// finished game's winner — without loading the game as the current one.
class GameStanding {
  GameStanding({
    required this.players,
    required this.totals,
    required this.isLowestScoreWins,
    this.rule = RankingRule.score,
    this.eliminatedAtRound = const {},
  });

  /// The standing of a game whose rounds and scores are in hand: the totals,
  /// the ranking rule its type and its state call for, and — under
  /// [RankingRule.eliminationOrder] — the round each player went out at.
  ///
  /// The one seam every caller builds a standing through: the board
  /// (`game_board_screen.dart`), the standings screen and the shared picture
  /// (`GameRanking.of`) and the home list (`GameProvider.standingOf`), so the
  /// four cannot disagree on a place.
  ///
  /// [rounds] must be in play order, as `RoundRepository.getByGame` returns
  /// them. [scoreOf] answers null where no score was entered.
  factory GameStanding.forGame({
    required List<Player> players,
    required List<Round> rounds,
    required int? Function(int playerId, int roundId) scoreOf,
    required bool isLowestScoreWins,
    required bool isFinished,
    required GameType? gameType,
  }) {
    final byElimination = isFinished && ranksByEliminationOrder(gameType);
    final totals = <int, int>{};
    final eliminatedAtRound = <int, int>{};
    for (final player in players) {
      final id = player.id;
      if (id == null) continue;
      var running = 0;
      var scored = false;
      for (final round in rounds) {
        final roundId = round.id;
        if (roundId == null) continue;
        final score = scoreOf(id, roundId);
        // A total can only cross the threshold on a round the player scored:
        // once out, a player stops being dealt in.
        if (score == null) continue;
        scored = true;
        running += score;
        if (byElimination &&
            !eliminatedAtRound.containsKey(id) &&
            gameType!.isEliminated(running)) {
          eliminatedAtRound[id] = round.roundNumber;
        }
      }
      if (scored) totals[id] = running;
    }
    return GameStanding(
      players: players,
      totals: totals,
      isLowestScoreWins: isLowestScoreWins,
      rule: byElimination ? RankingRule.eliminationOrder : RankingRule.score,
      eliminatedAtRound: eliminatedAtRound,
    );
  }

  /// Whether [gameType]'s **final** standings follow the elimination order.
  ///
  /// Only a type that both puts a player out on a threshold and ends when the
  /// last player is left standing does: a type with a threshold but a
  /// race-to-a-total ending, and a type with no rule at all, rank by score
  /// (decided 2026-09-20 by the user, in the entry above). `lastPlayerUnder`
  /// is the same shape and does not qualify today —
  /// `wip/todo_nr/2026-09-20-last-player-under-does-not-rank-by-elimination-order.md`.
  static bool ranksByEliminationOrder(GameType? gameType) =>
      gameType != null &&
      gameType.playerDeadConditionType != null &&
      gameType.playerDeadThreshold != null &&
      gameType.gameOverConditionType == GameOverConditionType.lastPlayerOver;

  /// The game's players sorted by `orderIndex`.
  final List<Player> players;

  /// Each player's total over the game's rounds, keyed by player id. A player
  /// with no score yet is absent.
  final Map<int, int> totals;

  final bool isLowestScoreWins;

  /// What [ranks] compares by.
  final RankingRule rule;

  /// The round number each eliminated player went out at — the first round
  /// whose running total crossed the type's threshold — keyed by player id.
  /// A player who is absent never went out. Empty under [RankingRule.score],
  /// which does not read it.
  final Map<int, int> eliminatedAtRound;

  /// Whether any score has been entered at all.
  bool get hasScores => totals.isNotEmpty;

  /// The one player alone on the first place — who the rankings crown — or
  /// null before the first score and on a tie for the lead: a round of all
  /// zeros crowns nobody.
  Player? get soleLeader {
    final first = leaders;
    return first.length == 1 ? first.single : null;
  }

  /// Every player on the first place, in seat order — several on a tie for
  /// the lead — or none before the first score.
  List<Player> get leaders {
    if (!hasScores) return const [];
    final place = ranks;
    return [
      for (final p in players)
        if (p.id != null && place[p.id] == 1) p
    ];
  }

  /// [player]'s total, 0 when they have no score yet.
  int totalOf(Player player) => totals[player.id] ?? 0;

  /// Each player's place, keyed by player id: 1 for the best, and players
  /// nothing separates share a place (1, 2, 2, 4). Players without an id are
  /// left out.
  ///
  /// What "best" means is [rule]'s: the total under [RankingRule.score], the
  /// elimination order under [RankingRule.eliminationOrder].
  late final Map<int, int> ranks = {
    for (final player in players)
      if (player.id != null)
        player.id!: players.where((o) => _isBetter(o, player)).length + 1,
  };

  /// Whether [a] outranks [b].
  bool _isBetter(Player a, Player b) {
    if (a.id == null || b.id == null || a.id == b.id) return false;
    if (rule == RankingRule.eliminationOrder) {
      final outA = eliminatedAtRound[a.id];
      final outB = eliminatedAtRound[b.id];
      if (outA != outB) {
        // The survivor first, then whoever went out later.
        if (outA == null) return true;
        if (outB == null) return false;
        return outA > outB;
      }
    }
    final totalA = totalOf(a);
    final totalB = totalOf(b);
    return isLowestScoreWins ? totalA < totalB : totalA > totalB;
  }

  /// The players best first; a tie keeps the seat order, since `List.sort` is
  /// not stable. The one order the board (`BoardData.byRank`) and the
  /// standings (`GameRanking.ranked`) both draw
  /// (`wip/done/2026-09-20-rank-then-seat-sort-is-duplicated.md`).
  late final List<Player> rankedPlayers = () {
    final place = ranks;
    final seat = {for (var i = 0; i < players.length; i++) players[i].id: i};
    return [...players]..sort((a, b) {
        final byPlace = (place[a.id] ?? 0).compareTo(place[b.id] ?? 0);
        return byPlace != 0
            ? byPlace
            : (seat[a.id] ?? 0).compareTo(seat[b.id] ?? 0);
      });
  }();
}
