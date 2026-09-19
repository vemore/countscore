import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/player_stats.dart';
import 'package:countscore/utils/player_colors.dart';

var _day = 0;

/// A finished game on [type]; [totals] in seat order, keyed by player uuid.
FinishedGameResult _game(
  String? type,
  Map<String, int> totals, {
  bool lowestWins = false,
  Map<String, int?> colours = const {},
}) {
  final seats = totals.keys.toList();
  return FinishedGameResult(
    gameId: ++_day,
    finishedAt: DateTime(2026, 1, 1).add(Duration(days: _day)),
    gameTypeKey: type,
    isLowestScoreWins: lowestWins,
    participants: [
      for (var i = 0; i < seats.length; i++)
        GameParticipant(
          playerUuid: seats[i],
          name: seats[i],
          orderIndex: i,
          total: totals[seats[i]]!,
          colorValue: colours[seats[i]],
        ),
    ],
  );
}

void main() {
  test('ranks share a place on a tie, and a tie for first is a win for both',
      () {
    final g = _game('x', {'a': 10, 'b': 10, 'c': 5});
    expect(g.rankOf('a'), 1);
    expect(g.rankOf('b'), 1);
    expect(g.rankOf('c'), 3);
    expect(g.wonBy('b'), isTrue);
    final low = _game('x', {'a': 10, 'b': 10, 'c': 5}, lowestWins: true);
    expect(low.rankOf('c'), 1);
    expect(low.rankOf('a'), 2);
  });

  test('below five games a player is listed last, unranked', () {
    final results = [
      for (var i = 0; i < 5; i++) _game('x', {'a': 1, 'b': 2}),
      for (var i = 0; i < 4; i++) _game('x', {'c': 9, 'a': 1}),
    ];
    final board = buildLeaderboard(results, 'x');
    expect(board.map((e) => e.playerUuid), ['b', 'a', 'c']);
    expect(board.map((e) => e.rank), [1, 2, null]);
    expect(board.last.games, 4);
    expect(board.last.wins, 4);
  });

  test('game types most played first; colours follow the latest game', () {
    final results = [
      _game('rare', {'a': 1, 'b': 2}),
      _game('often', {'a': 1, 'b': 2}),
      _game('often', {'b': 1, 'a': 2},
          colours: {'b': kPlayerPalette[5].toARGB32()}),
    ];
    expect(gameTypesByPlayCount(results), ['often', 'rare']);
    final colours = playerColorsByUuid(results);
    expect(colours['b'], kPlayerPalette[5]);
    expect(colours['a'], kPlayerPalette[0]);
  });

  test('the card: average place, streak, the last twelve games, trend', () {
    final results = [
      // Fourteen games: ten losses, then four wins.
      for (var i = 0; i < 10; i++) _game('x', {'a': 1, 'b': 5}),
      for (var i = 0; i < 4; i++) _game('x', {'a': 9, 'b': 5}),
      _game('other', {'a': 1, 'b': 5}),
    ];
    final card = PlayerCardStats.compute(results, 'a', 'x');
    expect(card.games, 14);
    expect(card.wins, 4);
    expect(card.averageRank, closeTo(24 / 14, 1e-9));
    expect(card.currentStreak, 4);
    expect(card.recentRanks, hasLength(kRankChartGames));
    expect(card.recentRanks.last.won, isTrue);
    expect(card.trend, RankTrend.improving);
    expect(card.bestTotal, 9);
    expect(card.averageTotal, closeTo((10 + 36) / 14, 1e-9));
    expect(card.mostBeatenUuid, 'b');

    // Across both types the last game is a loss.
    final all = PlayerCardStats.compute(results, 'a', kAllGameTypes);
    expect(all.games, 15);
    expect(all.currentStreak, 0);
  });

  test('the best total follows the rule, and is absent across mixed rules',
      () {
    final results = [
      _game('low', {'a': 3, 'b': 5}, lowestWins: true),
      _game('low', {'a': 8, 'b': 5}, lowestWins: true),
      _game('high', {'a': 30, 'b': 5}),
      _game('high', {'a': 40, 'b': 50}),
    ];
    expect(PlayerCardStats.compute(results, 'a', 'low').bestTotal, 3);
    expect(PlayerCardStats.compute(results, 'a', 'high').bestTotal, 40);
    expect(PlayerCardStats.compute(results, 'a', kAllGameTypes).bestTotal,
        isNull);
  });
}
