// The New game screen's tiles: the types most recently played first, and the
// selected one always on a tile.

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/recent_game_types.dart';

GameType _type(int id, String name) => GameType(
      id: id,
      name: name,
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: false,
    );

Game _game(int? typeId) =>
    Game(name: 'g', gameTypeId: typeId, isLowestScoreWins: true);

void main() {
  late AppLocalizations fr;
  setUpAll(() async {
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  final types = [
    _type(1, 'Delta'),
    _type(2, 'Alpha'),
    _type(3, 'Charlie'),
    _type(4, 'Bravo'),
  ];

  test('types of the latest games come first, the rest by name', () {
    final ordered = gameTypesRecentFirst(
        fr, types, [_game(3), _game(1), _game(3), _game(null), _game(99)]);
    expect(ordered.map((t) => t.id), [3, 1, 2, 4]);
  });

  test('no game: every type by name', () {
    expect(gameTypesRecentFirst(fr, types, const []).map((t) => t.id),
        [2, 4, 3, 1]);
  });

  test('the selected type takes the first tile when it is not on one', () {
    final ordered = gameTypesRecentFirst(fr, types, const []);
    expect(gameTypeTiles(ordered, 1, count: 3).map((t) => t.id), [1, 2, 4]);
    expect(gameTypeTiles(ordered, 4, count: 3).map((t) => t.id), [2, 4, 3]);
    expect(gameTypeTiles(ordered, null, count: 3).map((t) => t.id), [2, 4, 3]);
  });

  test('PlayerRepository counts the live games each player sits in', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final gamesRepo = DriftGameRepository(db);
    final players = DriftPlayerRepository(db);
    Future<int> seat(List<String> names) async {
      final id = await gamesRepo.create(_game(null));
      for (var i = 0; i < names.length; i++) {
        await players.create(Player(gameId: id, name: names[i], orderIndex: i));
      }
      return id;
    }

    await seat(['Ann', 'Bob']);
    await seat(['Ann', 'Cid']);
    final gone = await seat(['Ann', 'Bob']);
    await gamesRepo.delete(gone);

    expect(await players.getGameCountsByName(), {'Ann': 2, 'Bob': 1, 'Cid': 1});
  });
}
