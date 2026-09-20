import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game_standing.dart';
import 'package:countscore/models/player_stats.dart';
import 'package:countscore/utils/player_colors.dart';

var _day = 0;

/// A finished game on [type]; [totals] in seat order, keyed by player uuid.
///
/// [outAt] is the round each player went out at, and only means anything under
/// [RankingRule.eliminationOrder] — what the repository hands over for a
/// finished game of an elimination type.
FinishedGameResult _game(
  String? type,
  Map<String, int> totals, {
  bool lowestWins = false,
  Map<String, int?> colours = const {},
  RankingRule rule = RankingRule.score,
  Map<String, int> outAt = const {},
}) {
  final seats = totals.keys.toList();
  return FinishedGameResult(
    gameId: ++_day,
    finishedAt: DateTime(2026, 1, 1).add(Duration(days: _day)),
    gameTypeKey: type,
    isLowestScoreWins: lowestWins,
    rule: rule,
    participants: [
      for (var i = 0; i < seats.length; i++)
        GameParticipant(
          playerUuid: seats[i],
          name: seats[i],
          orderIndex: i,
          total: totals[seats[i]]!,
          colorValue: colours[seats[i]],
          eliminatedAtRound: outAt[seats[i]],
        ),
    ],
  );
}

/// The reproduction of the two entries: the ZapZap game whose standings read
/// David, Chloé, Bob, Alice and whose statistics used to read David, Alice,
/// Chloé, Bob.
FinishedGameResult _zapzap({RankingRule rule = RankingRule.eliminationOrder}) =>
    _game(
      'zapzap',
      {'Alice': 101, 'Bob': 140, 'Chloé': 115, 'David': 50},
      lowestWins: true,
      rule: rule,
      outAt: rule == RankingRule.eliminationOrder
          ? const {'Alice': 1, 'Bob': 4, 'Chloé': 5}
          : const {},
    );

void main() {
  group('a finished elimination game places as its standings do', () {
    test('the reproduction: the survivor first, then last out first', () {
      final g = _zapzap();

      expect(g.rule, RankingRule.eliminationOrder);
      expect(g.rankOf('David'), 1);
      expect(g.rankOf('Chloé'), 2);
      expect(g.rankOf('Bob'), 3);
      // Alice, out after one hand, is last however low her total: the podium
      // the score rule used to credit her with.
      expect(g.rankOf('Alice'), 4);
      expect(g.wonBy('David'), isTrue);
      expect(g.wonBy('Alice'), isFalse);
    });

    test('the same game under the score rule is what it used to say', () {
      final g = _zapzap(rule: RankingRule.score);

      expect(g.rankOf('David'), 1);
      expect(g.rankOf('Alice'), 2);
      expect(g.rankOf('Chloé'), 3);
      expect(g.rankOf('Bob'), 4);
    });

    test('the card counts the wins and the average place by that rule', () {
      final results = [for (var i = 0; i < 3; i++) _zapzap()];

      final alice = PlayerCardStats.compute(results, 'Alice', 'zapzap');
      expect(alice.games, 3);
      expect(alice.wins, 0);
      expect(alice.averageRank, 4);
      expect(alice.recentRanks.map((p) => p.rank), [4, 4, 4]);
      // The opponent she most often finished ahead of: nobody is behind her.
      expect(alice.mostBeatenUuid, isNull);

      final david = PlayerCardStats.compute(results, 'David', 'zapzap');
      expect(david.wins, 3);
      expect(david.currentStreak, 3);
      expect(david.averageRank, 1);

      final board = buildLeaderboard(results, 'zapzap', minGames: 3);
      expect(board.map((e) => e.playerUuid).first, 'David');
      expect(board.firstWhere((e) => e.playerUuid == 'Alice').wins, 0);
    });

    test('two survivors are separated by the total, and a tie shares a place',
        () {
      final g = _game(
        'zapzap',
        {'Alice': 120, 'Bob': 110, 'Chloé': 20, 'David': 20},
        lowestWins: true,
        rule: RankingRule.eliminationOrder,
        outAt: const {'Alice': 2, 'Bob': 2},
      );

      expect(g.rankOf('Chloé'), 1);
      expect(g.rankOf('David'), 1);
      expect(g.rankOf('Bob'), 3);
      expect(g.rankOf('Alice'), 4);
    });

    test('a game with no rule of its own keeps the total order', () {
      final g = _game('scrabble', {'a': 10, 'b': 20});
      expect(g.rule, RankingRule.score);
      expect(g.rankOf('b'), 1);
    });
  });

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
