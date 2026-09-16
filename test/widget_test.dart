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

    test('GameType default game types', () {
      final zapzap = GameType.zapzap();
      expect(zapzap.name, 'ZapZap');
      expect(zapzap.isLowestScoreWins, true);
      expect(zapzap.isDefault, true);

      final uno = GameType.uno();
      expect(uno.name, 'Uno');
      expect(uno.isLowestScoreWins, true);

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
