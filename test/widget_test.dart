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
      expect(defaultTypes.length, 10);
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
