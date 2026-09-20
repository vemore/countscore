// Basic smoke tests for CountScore app

import 'package:flutter_test/flutter_test.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/game_type.dart';

void main() {
  group('Model Tests', () {
    test('Game model creation', () {
      final game = Game(
        name: 'Test Game',
        gameTypeId: 1,
        isLowestScoreWins: true,
      );

      expect(game.name, 'Test Game');
      expect(game.gameTypeId, 1);
      expect(game.isLowestScoreWins, true);
    });

    test('Game model toMap and fromMap', () {
      final game = Game(
        id: 1,
        name: 'Test Game',
        gameTypeId: 2,
        isLowestScoreWins: false,
      );

      final map = game.toMap();
      expect(map['name'], 'Test Game');
      expect(map['gameTypeId'], 2);
      expect(map['isLowestScoreWins'], 0);

      final fromMap = Game.fromMap(map);
      expect(fromMap.name, 'Test Game');
      expect(fromMap.gameTypeId, 2);
      expect(fromMap.isLowestScoreWins, false);
    });

    test('Player model creation', () {
      final player = Player(
        id: 1,
        gameId: 1,
        name: 'Alice',
        orderIndex: 0,
        colorValue: 0xFF2196F3,
      );

      expect(player.id, 1);
      expect(player.gameId, 1);
      expect(player.name, 'Alice');
      expect(player.orderIndex, 0);
      expect(player.colorValue, 0xFF2196F3);
    });

    test('Score model creation', () {
      final score = Score(
        id: 1,
        playerId: 1,
        roundId: 1,
        value: 42,
      );

      expect(score.id, 1);
      expect(score.playerId, 1);
      expect(score.roundId, 1);
      expect(score.value, 42);
    });

    test('Round model creation', () {
      final round = Round(
        id: 1,
        gameId: 1,
        roundNumber: 1,
      );

      expect(round.id, 1);
      expect(round.gameId, 1);
      expect(round.roundNumber, 1);
    });

    group('GameType.isGameOver', () {
      GameType withRule(GameOverConditionType type) => GameType(
            name: 'Seuil',
            iconCodePoint: 0,
            cardColorValue: 0,
            isLowestScoreWins: false,
            gameOverConditionType: type,
            gameOverThreshold: 10,
          );

      test('Président: a player on exactly 10 has won, one on 9 has not', () {
        final president = GameType.president();
        expect(president.isGameOver([10, 4, 2]), isTrue);
        expect(president.isGameOver([9, 8, 2]), isFalse);
        expect(president.isGameOver([11, 0]), isTrue);
      });

      test('Skyjo stops at 100 or more', () {
        expect(GameType.skyjo().isGameOver([100, 40]), isTrue);
        expect(GameType.skyjo().isGameOver([99, 40]), isFalse);
      });

      test('firstPlayerUnder keeps its strict comparison', () {
        expect(withRule(GameOverConditionType.firstPlayerUnder).isGameOver([10, 20]), isFalse);
        expect(withRule(GameOverConditionType.firstPlayerUnder).isGameOver([9, 20]), isTrue);
      });

      test('lastPlayerOver ends when every player but one is past the threshold', () {
        final rule = withRule(GameOverConditionType.lastPlayerOver);
        // Four players, threshold 10: the game runs until three of them are out.
        expect(rule.isGameOver([11, 12, 5, 4]), isFalse);
        expect(rule.isGameOver([11, 12, 13, 4]), isTrue);
        // The survivor's own total is irrelevant — it is what stopped moving.
        expect(rule.isGameOver([11, 12, 13, 0]), isTrue);
        // Everyone out at once still ends the game.
        expect(rule.isGameOver([11, 12, 13, 14]), isTrue);
        // Two players: one out is enough, and 10 is not "over" 10.
        expect(rule.isGameOver([10, 9]), isFalse);
        expect(rule.isGameOver([9, 11]), isTrue);
        // A single player has nobody to be the last one standing.
        expect(rule.isGameOver([4]), isFalse);
        expect(rule.isGameOver([40]), isFalse);
      });

      test('lastPlayerUnder is the mirror image', () {
        final rule = withRule(GameOverConditionType.lastPlayerUnder);
        expect(rule.isGameOver([9, 8, 15, 16]), isFalse);
        expect(rule.isGameOver([9, 8, 7, 16]), isTrue);
        expect(rule.isGameOver([9, 8, 7, 6]), isTrue);
        expect(rule.isGameOver([10, 20]), isFalse);
        expect(rule.isGameOver([11, 9]), isTrue);
        expect(rule.isGameOver([5]), isFalse);
      });

      test('a type without a rule never ends by itself', () {
        expect(GameType.scrabble().isGameOver([1000000]), isFalse);
      });

      test('the three elimination types end on the last player standing', () {
        for (final type in [GameType.zapzap(), GameType.rami()]) {
          expect(type.gameOverConditionType,
              GameOverConditionType.lastPlayerOver, reason: type.name);
          expect(type.gameOverThreshold, type.playerDeadThreshold,
              reason: type.name);
          // Four players past 100 one by one: the fourth round is the last.
          expect(type.isGameOver([101, 130, 90, 40]), isFalse, reason: type.name);
          expect(type.isGameOver([101, 130, 120, 40]), isTrue, reason: type.name);
        }

        final sixNimmt = GameType.sixNimmt();
        expect(sixNimmt.gameOverConditionType,
            GameOverConditionType.lastPlayerOver);
        expect(sixNimmt.gameOverThreshold, 65);
        // The same strict 65 as the elimination rule: 65 is still in.
        expect(sixNimmt.isGameOver([66, 70, 65, 10]), isFalse);
        expect(sixNimmt.isGameOver([66, 70, 80, 10]), isTrue);
      });

      test('the types with no automatic end keep none', () {
        const keyless = {
          'scrabble', 'tarot', 'bridge', 'yahtzee', 'phase10',
          'rummikub', 'qwirkle', 'wizard', 'triomino', 'other',
        };
        for (final type in GameType.defaultGameTypes()
            .where((t) => keyless.contains(t.builtinKey))) {
          expect(type.gameOverConditionType, isNull, reason: type.name);
          expect(type.gameOverThreshold, isNull, reason: type.name);
        }
      });
    });

    group('GameType.isEliminated', () {
      test('ZapZap and Rami: out once a total exceeds 100, not on it', () {
        for (final type in [GameType.zapzap(), GameType.rami()]) {
          expect(type.isEliminated(100), isFalse, reason: type.name);
          expect(type.isEliminated(101), isTrue, reason: type.name);
        }
      });

      test('6 qui prend: out on exactly 66, as its rule says, not on 65', () {
        final sixNimmt = GameType.sixNimmt();
        expect(sixNimmt.playerDeadThreshold, 65);
        expect(sixNimmt.isEliminated(65), isFalse);
        expect(sixNimmt.isEliminated(66), isTrue);
      });

      test('under: out below the threshold; near within 20 points', () {
        final type = GameType(
          name: 'Seuil',
          iconCodePoint: 0,
          cardColorValue: 0,
          isLowestScoreWins: false,
          playerDeadConditionType: PlayerDeadConditionType.under,
          playerDeadThreshold: 0,
        );
        expect(type.isEliminated(0), isFalse);
        expect(type.isEliminated(-1), isTrue);
        expect(type.isNearElimination(20), isTrue);
        expect(type.isNearElimination(21), isFalse);
        expect(type.isNearElimination(-1), isFalse);
      });

      test('near: within 20 points of an over threshold, not past it', () {
        final zapzap = GameType.zapzap();
        expect(zapzap.isNearElimination(79), isFalse);
        expect(zapzap.isNearElimination(80), isTrue);
        expect(zapzap.isNearElimination(100), isTrue);
        expect(zapzap.isNearElimination(101), isFalse);
      });

      test('a type without a rule puts nobody out', () {
        expect(GameType.scrabble().isEliminated(1000000), isFalse);
        expect(GameType.scrabble().isNearElimination(1000000), isFalse);
      });
    });

    test('GameType default game types', () {
      final zapzap = GameType.zapzap();
      expect(zapzap.name, 'ZapZap');
      expect(zapzap.isLowestScoreWins, true);
      expect(zapzap.isDefault, true);

      final uno = GameType.uno();
      expect(uno.name, 'Uno');
      // The box rule: highest total wins, the game ends on reaching 500.
      expect(uno.isLowestScoreWins, false);
      expect(uno.gameOverConditionType, GameOverConditionType.firstPlayerOver);
      expect(uno.gameOverThreshold, 500);

      final president = GameType.president();
      expect(president.isLowestScoreWins, false);
      expect(president.gameOverConditionType, GameOverConditionType.firstPlayerOver);
      expect(president.gameOverThreshold, 10);

      final scrabble = GameType.scrabble();
      expect(scrabble.name, 'Scrabble');
      expect(scrabble.isLowestScoreWins, false);

      final autre = GameType.autre();
      expect(autre.name, 'Autre');
    });

    test('GameType default game types list', () {
      final defaultTypes = GameType.defaultGameTypes();
      expect(defaultTypes.length, 22);
      // The first ten indices are what an install seeded before schema v13
      // already holds, in that order. New types are appended, never inserted.
      expect(defaultTypes[0].name, 'ZapZap');
      expect(defaultTypes[1].name, 'Uno');
      expect(defaultTypes[2].name, 'Scrabble');
      expect(defaultTypes[3].name, 'Autre');
      expect(defaultTypes[4].name, 'Skyjo');
      expect(defaultTypes[5].name, 'Président');
      expect(defaultTypes[6].name, 'Belote');
      expect(defaultTypes[7].name, 'Tarot');
      expect(defaultTypes[8].name, 'Bridge');
      expect(defaultTypes[9].name, 'Rami');
      expect(defaultTypes[10].name, 'Coinche');
      expect(defaultTypes[11].name, 'Yahtzee');
      expect(defaultTypes[12].name, 'Phase 10');
      expect(defaultTypes[13].name, 'Flip 7');
      expect(defaultTypes[14].name, 'Mille Bornes');
      expect(defaultTypes[15].name, 'Rummikub');
      expect(defaultTypes[16].name, '6 qui prend');
      expect(defaultTypes[17].name, 'Qwirkle');
      expect(defaultTypes[18].name, 'Farkle');
      expect(defaultTypes[19].name, 'Canasta');
      expect(defaultTypes[20].name, 'Wizard');
      expect(defaultTypes[21].name, 'Triomino');
    });

    test('GameType built-in keys', () {
      final defaultTypes = GameType.defaultGameTypes();
      expect(defaultTypes.map((t) => t.builtinKey).toList(), [
        'zapzap', 'uno', 'scrabble', 'other', 'skyjo', 'president', //
        'belote', 'tarot', 'bridge', 'rami', 'coinche', 'yahtzee', //
        'phase10', 'flip7', 'mille_bornes', 'rummikub', 'six_nimmt', //
        'qwirkle', 'farkle', 'canasta', 'wizard', 'triomino',
      ]);
      // The ten the v13 migration back-fills rather than inserts.
      expect(GameType.seededNamesBeforeV14.keys,
          defaultTypes.take(10).map((t) => t.builtinKey));
      expect(GameType.seededNamesBeforeV14.values,
          defaultTypes.take(10).map((t) => t.name));
    });

    test('GameType builtinKey survives toMap / fromMap and copyWith', () {
      final type = GameType.yahtzee();
      expect(type.toMap()['builtin_key'], 'yahtzee');
      expect(GameType.fromMap(type.toMap()).builtinKey, 'yahtzee');

      // Changing anything but the name keeps the key...
      expect(type.copyWith(cardColorValue: 1).builtinKey, 'yahtzee');
      // ...and renaming gives it up, so the chosen name is what is rendered.
      expect(type.copyWith(name: 'Mon jeu', clearBuiltinKey: true).builtinKey, isNull);
      // It keeps its shipped ruleset, though: the slug is not the name.
      expect(type.rulesSlug, 'yahtzee');
      expect(type.copyWith(name: 'Mon jeu', clearBuiltinKey: true).rulesSlug, 'yahtzee');
    });

    test('Game copyWith method', () {
      final game = Game(
        id: 1,
        name: 'Original',
        gameTypeId: 1,
        isLowestScoreWins: true,
      );

      final updated = game.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.id, 1);
      expect(updated.gameTypeId, 1);
      expect(updated.isLowestScoreWins, true);
    });
  });
}
