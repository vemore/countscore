// Where a game stands, and the rule its places follow
// (`wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`).
//
// The rule is derived, never stored: a **finished** game of a type that both
// puts a player out on a threshold and ends on the last player standing ranks
// by the elimination order — the survivor first, then the others last-out
// first. Everything else — an open game of that same type, a race to a total,
// a type with no rule at all — ranks by the total.

import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/models/game_standing.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';

/// Four players, seated Alice, Bob, Chloé, David.
final _players = [
  Player(id: 1, gameId: 1, name: 'Alice', orderIndex: 0),
  Player(id: 2, gameId: 1, name: 'Bob', orderIndex: 1),
  Player(id: 3, gameId: 1, name: 'Chloé', orderIndex: 2),
  Player(id: 4, gameId: 1, name: 'David', orderIndex: 3),
];

/// The five rounds of the reproduction, in play order.
final _rounds = [
  for (var n = 1; n <= 5; n++) Round(id: n, gameId: 1, roundNumber: n),
];

/// The reproduced ZapZap game: Alice out in round 1 with 101, Bob out in
/// round 4 with 140, Chloé out in round 5 with 115, David alone at the end
/// with 50. By total it is David, Alice, Chloé, Bob; by elimination order it
/// is David, Chloé, Bob, Alice.
const _scores = <int, Map<int, int>>{
  1: {1: 101},
  2: {1: 20, 2: 30, 3: 40, 4: 50},
  3: {1: 10, 2: 20, 3: 30, 4: 25, 5: 30},
  4: {1: 5, 2: 10, 3: 10, 4: 15, 5: 10},
};

int? _scoreOf(int playerId, int roundId) => _scores[playerId]?[roundId];

/// A ZapZap-shaped type: out above [dead], the game over when the last player
/// is left standing.
GameType _elimination({
  int dead = 100,
  GameOverConditionType? over = GameOverConditionType.lastPlayerOver,
}) =>
    GameType(
      builtinKey: 'zapzap',
      name: 'ZapZap',
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: true,
      playerDeadConditionType: PlayerDeadConditionType.over,
      playerDeadThreshold: dead,
      gameOverConditionType: over,
      gameOverThreshold: over == null ? null : dead,
    );

/// A type with no rule of its own: Scrabble, Autre, and anything the user
/// builds without a threshold.
GameType _plain({bool lowestWins = false}) => GameType(
      builtinKey: 'scrabble',
      name: 'Scrabble',
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: lowestWins,
    );

GameStanding _standing({
  required bool isFinished,
  GameType? gameType,
  List<Player>? players,
  List<Round>? rounds,
  int? Function(int playerId, int roundId)? scoreOf,
  bool lowestWins = true,
}) =>
    GameStanding.forGame(
      players: players ?? _players,
      rounds: rounds ?? _rounds,
      scoreOf: scoreOf ?? _scoreOf,
      isLowestScoreWins: lowestWins,
      isFinished: isFinished,
      gameType: gameType,
    );

List<String> _order(GameStanding standing) =>
    [for (final p in standing.rankedPlayers) p.name];

void main() {
  group('the reproduction: ZapZap, out above 100, five rounds', () {
    test('the totals are the same whichever rule ranks them', () {
      for (final finished in [false, true]) {
        final standing = _standing(
            isFinished: finished, gameType: _elimination());
        expect(standing.totals, {1: 101, 2: 140, 3: 115, 4: 50});
        expect(standing.hasScores, isTrue);
      }
    });

    test('finished, it ranks by the elimination order, not the total', () {
      final standing =
          _standing(isFinished: true, gameType: _elimination());

      expect(standing.rule, RankingRule.eliminationOrder);
      // The round each one went out at: David never did.
      expect(standing.eliminatedAtRound, {1: 1, 2: 4, 3: 5});
      // David alone at the end, then the others last-out first; Alice, out
      // after one hand, is last however low her total.
      expect(_order(standing), ['David', 'Chloé', 'Bob', 'Alice']);
      expect(standing.ranks, {4: 1, 3: 2, 2: 3, 1: 4});
      expect(standing.soleLeader?.name, 'David');
      expect([for (final p in standing.leaders) p.name], ['David']);
    });

    test('open, the same game still ranks by the total', () {
      final standing =
          _standing(isFinished: false, gameType: _elimination());

      expect(standing.rule, RankingRule.score);
      expect(standing.eliminatedAtRound, isEmpty);
      expect(_order(standing), ['David', 'Alice', 'Chloé', 'Bob']);
      expect(standing.ranks, {4: 1, 1: 2, 3: 3, 2: 4});
      expect(standing.soleLeader?.name, 'David');
    });
  });

  group('which types depart from the score order', () {
    test('a threshold alone is not enough: a race to a total ranks by score',
        () {
      final raceToATotal = GameType(
        builtinKey: 'skyjo',
        name: 'Skyjo',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 100,
      );

      expect(GameStanding.ranksByEliminationOrder(raceToATotal), isFalse);
      final standing = _standing(isFinished: true, gameType: raceToATotal);
      expect(standing.rule, RankingRule.score);
      expect(_order(standing), ['David', 'Alice', 'Chloé', 'Bob']);
    });

    test('a type with no rule ranks by score, and so does no type at all', () {
      for (final type in [_plain(lowestWins: true), null]) {
        expect(GameStanding.ranksByEliminationOrder(type), isFalse);
        final standing = _standing(isFinished: true, gameType: type);
        expect(standing.rule, RankingRule.score);
        expect(_order(standing), ['David', 'Alice', 'Chloé', 'Bob']);
      }
    });

    test('the last-player-standing condition without a threshold ranks by score',
        () {
      final noThreshold = GameType(
        name: 'Maison',
        iconCodePoint: 0,
        cardColorValue: 0,
        isLowestScoreWins: true,
        gameOverConditionType: GameOverConditionType.lastPlayerOver,
        gameOverThreshold: 100,
      );

      expect(GameStanding.ranksByEliminationOrder(noThreshold), isFalse);
      expect(_standing(isFinished: true, gameType: noThreshold).rule,
          RankingRule.score);
    });

    test('a threshold plus last player standing is the one shape that does',
        () {
      expect(GameStanding.ranksByEliminationOrder(_elimination()), isTrue);
    });
  });

  group('the elimination order itself', () {
    test('the total only breaks a tie between two players out together', () {
      // Both Alice and Bob cross 100 in round 2; Bob crosses it by less.
      const scores = <int, Map<int, int>>{
        1: {1: 60, 2: 60},
        2: {1: 60, 2: 50},
        3: {1: 10, 2: 10},
        4: {1: 5, 2: 5},
      };
      final standing = _standing(
        isFinished: true,
        gameType: _elimination(),
        rounds: [for (var n = 1; n <= 2; n++) Round(id: n, gameId: 1, roundNumber: n)],
        scoreOf: (p, r) => scores[p]?[r],
      );

      expect(standing.eliminatedAtRound, {1: 2, 2: 2});
      expect(standing.totals, {1: 120, 2: 110, 3: 20, 4: 10});
      // David and Chloé survived, lowest total first; then the two who went
      // out in round 2, the lower total first.
      expect(_order(standing), ['David', 'Chloé', 'Bob', 'Alice']);
      expect(standing.ranks, {4: 1, 3: 2, 2: 3, 1: 4});
    });

    test('two survivors are separated by the total, and a tie shares a place',
        () {
      const scores = <int, Map<int, int>>{
        1: {1: 101},
        2: {1: 101},
        3: {1: 10},
        4: {1: 10},
      };
      final standing = _standing(
        isFinished: true,
        gameType: _elimination(),
        rounds: [Round(id: 1, gameId: 1, roundNumber: 1)],
        scoreOf: (p, r) => scores[p]?[r],
      );

      // Chloé and David tie at 10 and share the first place; Alice and Bob
      // went out in the same round on the same total and share the third.
      expect(standing.ranks, {3: 1, 4: 1, 1: 3, 2: 3});
      expect(_order(standing), ['Chloé', 'David', 'Alice', 'Bob']);
      expect(standing.soleLeader, isNull);
    });

    test('a player who never scored is neither out nor ranked last by it', () {
      final standing = _standing(
        isFinished: true,
        gameType: _elimination(),
        rounds: [Round(id: 1, gameId: 1, roundNumber: 1)],
        scoreOf: (p, r) => p == 1 ? 101 : null,
      );

      expect(standing.eliminatedAtRound, {1: 1});
      expect(standing.totals, {1: 101});
      expect(standing.hasScores, isTrue);
      expect(_order(standing).last, 'Alice');
    });

    test('no score at all crowns nobody, whatever the rule', () {
      final standing = _standing(
        isFinished: true,
        gameType: _elimination(),
        scoreOf: (p, r) => null,
      );

      expect(standing.hasScores, isFalse);
      expect(standing.leaders, isEmpty);
      expect(standing.soleLeader, isNull);
    });
  });

  test('rankedPlayers keeps the seat order on a tie', () {
    final standing = _standing(
      isFinished: false,
      gameType: _plain(),
      lowestWins: false,
      rounds: [Round(id: 1, gameId: 1, roundNumber: 1)],
      // Alice and Chloé tie at 30, Bob and David at 10.
      scoreOf: (p, r) => const {1: 30, 2: 10, 3: 30, 4: 10}[p],
    );

    expect(standing.ranks, {1: 1, 3: 1, 2: 3, 4: 3});
    expect(_order(standing), ['Alice', 'Chloé', 'Bob', 'David']);
  });
}
