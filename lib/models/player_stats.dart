import 'package:flutter/material.dart';

import '../utils/player_colors.dart';
import 'game_standing.dart';

/// The player statistics: the leaderboard and the player card.
///
/// Everything here is computed in memory from [FinishedGameResult]s, which
/// `PlayerStatsRepository.getFinishedGameResults` reads. Only
/// finished games (`finishedAt` set) with at least one score count, and a
/// player is known by the uuid of their global `players` row — the key stats
/// have had since v9 (.llmwiki/Schema.md).

/// A game-type filter value meaning "every game type".
const String? kAllGameTypes = null;

/// How many finished games of the filter a player needs to be ranked.
const int kMinGamesToRank = 5;

/// How many of the most recent games the player card's rank chart shows.
const int kRankChartGames = 12;

/// One player's result in one finished game.
class GameParticipant {
  const GameParticipant({
    required this.playerUuid,
    required this.name,
    required this.orderIndex,
    required this.total,
    this.colorValue,
    this.isActive = true,
    this.eliminatedAtRound,
  });

  /// The global player's uuid (`players.uuid`).
  final String playerUuid;
  final String name;

  /// The seat (`game_players.orderIndex`).
  final int orderIndex;

  /// The colour the board starts from (`game_players.colorValue`).
  final int? colorValue;

  /// The final total over the game's live rounds.
  final int total;

  /// False for a player removed from this device's catalogue: their games
  /// still place everyone else, but they are not listed themselves.
  final bool isActive;

  /// The round this player went out at — the first round whose running total
  /// crossed the type's elimination threshold — or null where they never did.
  /// Always null outside [RankingRule.eliminationOrder], which is the only
  /// rule that reads it. The same walk `GameStanding.forGame` does, run by
  /// `PlayerStatsRepository.getFinishedGameResults`.
  final int? eliminatedAtRound;
}

/// One finished game and its players' totals, in seat order.
class FinishedGameResult {
  FinishedGameResult({
    required this.gameId,
    required this.finishedAt,
    required this.gameTypeKey,
    required this.isLowestScoreWins,
    required List<GameParticipant> participants,
    this.rule = RankingRule.score,
  }) : participants = [...participants]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  final int gameId;
  final DateTime finishedAt;

  /// `COALESCE(builtin_key, name)` of the game's type — the key the statistics
  /// have always grouped on — or null for a game without a type.
  final String? gameTypeKey;
  final bool isLowestScoreWins;
  final List<GameParticipant> participants;

  /// The rule this finished game's places follow — the same one its standings
  /// screen follows, derived by `GameStanding.ranksByEliminationOrder` from
  /// the game's type and handed over by
  /// `PlayerStatsRepository.getFinishedGameResults`. Every game that is not of
  /// an elimination type keeps [RankingRule.score], the default.
  final RankingRule rule;

  late final Map<String, int> _ranks = _computeRanks();

  Map<String, int> _computeRanks() {
    final result = <String, int>{};
    for (final p in participants) {
      final better = participants
          .where((o) => outranksUnder(
                rule: rule,
                eliminatedAtRoundA: o.eliminatedAtRound,
                eliminatedAtRoundB: p.eliminatedAtRound,
                totalA: o.total,
                totalB: p.total,
                isLowestScoreWins: isLowestScoreWins,
              ))
          .length;
      result[p.playerUuid] = better + 1;
    }
    return result;
  }

  /// [playerUuid]'s final place under [rule]: 1 for the best, a tie shares the
  /// place (1, 2, 2, 4) — the rule of `GameStanding.ranks`, down to the
  /// comparison ([outranksUnder]). Null if absent.
  int? rankOf(String playerUuid) => _ranks[playerUuid];

  /// Whether [playerUuid] won — every player tied on the first place did.
  bool wonBy(String playerUuid) => rankOf(playerUuid) == 1;

  GameParticipant? participant(String playerUuid) {
    for (final p in participants) {
      if (p.playerUuid == playerUuid) return p;
    }
    return null;
  }

  bool matches(String? gameTypeKey) =>
      gameTypeKey == kAllGameTypes || this.gameTypeKey == gameTypeKey;
}

/// The game types that have finished games, most played first (a tie goes to
/// the most recently played, then the key).
List<String> gameTypesByPlayCount(List<FinishedGameResult> results) {
  final counts = <String, int>{};
  final latest = <String, DateTime>{};
  for (final r in results) {
    final key = r.gameTypeKey;
    if (key == null) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    final l = latest[key];
    if (l == null || r.finishedAt.isAfter(l)) latest[key] = r.finishedAt;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      final byDate = latest[b]!.compareTo(latest[a]!);
      return byDate != 0 ? byDate : a.compareTo(b);
    });
  return keys;
}

/// Each player's display colour, keyed by uuid.
///
/// The same rule as the board ([assignPlayerColors]), applied to the players in
/// the order they first appear walking the games from the most recent one, by
/// seat: the latest game's players show exactly the colours its board showed,
/// and the colours do not change with the game-type filter.
Map<String, Color> playerColorsByUuid(List<FinishedGameResult> results) {
  final ordered = [...results]
    ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  final uuids = <String>[];
  final colourValues = <int?>[];
  final seen = <String>{};
  for (final r in ordered) {
    for (final p in r.participants) {
      if (seen.add(p.playerUuid)) {
        uuids.add(p.playerUuid);
        colourValues.add(p.colorValue);
      }
    }
  }
  final colours = assignPlayerColors(colourValues);
  return {for (var i = 0; i < uuids.length; i++) uuids[i]: colours[i]};
}

/// One row of the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerUuid,
    required this.name,
    required this.games,
    required this.wins,
    this.rank,
  });

  final String playerUuid;
  final String name;
  final int games;
  final int wins;

  /// 1-based place among the ranked players, or null below [kMinGamesToRank].
  final int? rank;

  bool get isRanked => rank != null;

  /// Between 0 and 1.
  double get winRate => games == 0 ? 0 : wins / games;
}

/// The leaderboard for [gameTypeKey] ([kAllGameTypes] for every type).
///
/// Ranked players (at least [minGames] games of the filter) come first, by win
/// rate, then wins, then games, then name; two players on the same rate, wins
/// and games share a place. The others follow, unranked, most games first.
List<LeaderboardEntry> buildLeaderboard(
  List<FinishedGameResult> results,
  String? gameTypeKey, {
  int minGames = kMinGamesToRank,
}) {
  final games = <String, int>{};
  final wins = <String, int>{};
  final names = <String, String>{};
  // Most recent first, so the name kept is the latest one.
  final ordered = [...results]
    ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  for (final r in ordered) {
    if (!r.matches(gameTypeKey)) continue;
    for (final p in r.participants) {
      if (!p.isActive) continue;
      names.putIfAbsent(p.playerUuid, () => p.name);
      games[p.playerUuid] = (games[p.playerUuid] ?? 0) + 1;
      if (r.wonBy(p.playerUuid)) {
        wins[p.playerUuid] = (wins[p.playerUuid] ?? 0) + 1;
      }
    }
  }

  LeaderboardEntry entry(String uuid, [int? rank]) => LeaderboardEntry(
        playerUuid: uuid,
        name: names[uuid]!,
        games: games[uuid]!,
        wins: wins[uuid] ?? 0,
        rank: rank,
      );

  int byName(String a, String b) =>
      names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase());

  final all = games.keys.map(entry).toList();
  final ranked = all.where((e) => e.games >= minGames).toList()
    ..sort((a, b) {
      final byRate = b.winRate.compareTo(a.winRate);
      if (byRate != 0) return byRate;
      final byWins = b.wins.compareTo(a.wins);
      if (byWins != 0) return byWins;
      final byGames = b.games.compareTo(a.games);
      if (byGames != 0) return byGames;
      return byName(a.playerUuid, b.playerUuid);
    });
  final unranked = all.where((e) => e.games < minGames).toList()
    ..sort((a, b) {
      final byGames = b.games.compareTo(a.games);
      return byGames != 0 ? byGames : byName(a.playerUuid, b.playerUuid);
    });

  final result = <LeaderboardEntry>[];
  for (var i = 0; i < ranked.length; i++) {
    final e = ranked[i];
    var rank = i + 1;
    if (i > 0) {
      final prev = ranked[i - 1];
      if (prev.winRate == e.winRate &&
          prev.wins == e.wins &&
          prev.games == e.games) {
        rank = result[i - 1].rank!;
      }
    }
    result.add(entry(e.playerUuid, rank));
  }
  result.addAll(unranked);
  return result;
}

/// One point of the rank chart: a game, oldest first.
class RankPoint {
  const RankPoint({
    required this.rank,
    required this.playerCount,
    required this.won,
  });

  final int rank;
  final int playerCount;
  final bool won;
}

/// Whether the ranks are getting better, worse or neither.
enum RankTrend { improving, declining, steady }

/// A player's card for one game-type filter.
class PlayerCardStats {
  const PlayerCardStats({
    required this.games,
    required this.wins,
    required this.averageRank,
    required this.recentRanks,
    required this.currentStreak,
    required this.averageTotal,
    required this.bestTotal,
    required this.mostBeatenUuid,
    required this.trend,
  });

  final int games;
  final int wins;

  /// Mean final place, null with no game.
  final double? averageRank;

  /// The last [kRankChartGames] games, oldest first.
  final List<RankPoint> recentRanks;

  /// Wins in a row up to the most recent game (0 if it was not a win).
  final int currentStreak;

  /// Mean final total, null with no game.
  final double? averageTotal;

  /// The best final total — the lowest where the lowest score wins. Null
  /// with no game, or when the games mix both directions ("All games").
  final int? bestTotal;

  /// The opponent this player most often finished ahead of (a strictly better
  /// place), null when there is none.
  final String? mostBeatenUuid;

  /// Null with fewer than four games on the chart.
  final RankTrend? trend;

  static PlayerCardStats compute(
    List<FinishedGameResult> results,
    String playerUuid,
    String? gameTypeKey,
  ) {
    final mine = results
        .where((r) => r.matches(gameTypeKey) && r.rankOf(playerUuid) != null)
        .toList()
      ..sort((a, b) {
        final byDate = a.finishedAt.compareTo(b.finishedAt);
        return byDate != 0 ? byDate : a.gameId.compareTo(b.gameId);
      });

    var wins = 0;
    var rankSum = 0;
    var totalSum = 0;
    int? best;
    final lowestWins = mine.map((r) => r.isLowestScoreWins).toSet();
    final aheadOf = <String, int>{};
    final lastAhead = <String, int>{};
    for (var i = 0; i < mine.length; i++) {
      final r = mine[i];
      final rank = r.rankOf(playerUuid)!;
      final total = r.participant(playerUuid)!.total;
      if (rank == 1) wins++;
      rankSum += rank;
      totalSum += total;
      if (lowestWins.length == 1) {
        final lowest = lowestWins.single;
        if (best == null || (lowest ? total < best : total > best)) {
          best = total;
        }
      }
      for (final o in r.participants) {
        if (o.playerUuid == playerUuid || !o.isActive) continue;
        if ((r.rankOf(o.playerUuid) ?? 0) > rank) {
          aheadOf[o.playerUuid] = (aheadOf[o.playerUuid] ?? 0) + 1;
          lastAhead[o.playerUuid] = i;
        }
      }
    }

    var streak = 0;
    for (final r in mine.reversed) {
      if (!r.wonBy(playerUuid)) break;
      streak++;
    }

    String? mostBeaten;
    for (final entry in aheadOf.entries) {
      if (mostBeaten == null ||
          entry.value > aheadOf[mostBeaten]! ||
          (entry.value == aheadOf[mostBeaten]! &&
              lastAhead[entry.key]! > lastAhead[mostBeaten]!)) {
        mostBeaten = entry.key;
      }
    }

    final recent = mine.length > kRankChartGames
        ? mine.sublist(mine.length - kRankChartGames)
        : mine;
    final points = [
      for (final r in recent)
        RankPoint(
          rank: r.rankOf(playerUuid)!,
          playerCount: r.participants.length,
          won: r.wonBy(playerUuid),
        ),
    ];

    return PlayerCardStats(
      games: mine.length,
      wins: wins,
      averageRank: mine.isEmpty ? null : rankSum / mine.length,
      recentRanks: points,
      currentStreak: streak,
      averageTotal: mine.isEmpty ? null : totalSum / mine.length,
      bestTotal: best,
      mostBeatenUuid: mostBeaten,
      trend: _trendOf(points),
    );
  }

  /// The chart's second half against its first: a mean place better by at
  /// least a quarter of a place is progress, worse by as much is a decline.
  static RankTrend? _trendOf(List<RankPoint> points) {
    if (points.length < 4) return null;
    final half = points.length ~/ 2;
    double mean(Iterable<RankPoint> ps) =>
        ps.map((p) => p.rank).reduce((a, b) => a + b) / ps.length;
    final before = mean(points.take(half));
    final after = mean(points.skip(points.length - half));
    if (after <= before - 0.25) return RankTrend.improving;
    if (after >= before + 0.25) return RankTrend.declining;
    return RankTrend.steady;
  }
}
