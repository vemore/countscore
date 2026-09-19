// The shared result text (`buildGameResultShareText`): built from the same
// `GameRanking` the end and ranking screens draw, so its order and its places
// follow the win rule — best first, a tie sharing a place and keeping seat
// order — and it carries the game type, the date, the app's name and its Play
// URL with no tracking parameter.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_standing.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/utils/game_result_share.dart';
import 'package:countscore/widgets/game_ranking.dart';

GameType _type(String builtinKey, {required bool lowestWins}) => GameType(
      builtinKey: builtinKey,
      name: 'stored',
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: lowestWins,
    );

final _players = [
  Player(id: 1, gameId: 1, name: 'Alice', orderIndex: 0),
  Player(id: 2, gameId: 1, name: 'Bob', orderIndex: 1),
  Player(id: 3, gameId: 1, name: 'Chloé', orderIndex: 2),
  Player(id: 4, gameId: 1, name: 'Dan', orderIndex: 3),
];

GameRanking _ranking(Map<int, int> totals, GameType type) =>
    GameRanking.fromStanding(
      GameStanding(
        players: _players,
        totals: totals,
        isLowestScoreWins: type.isLowestScoreWins,
      ),
      type,
    );

String _text(AppLocalizations l10n, GameType type, Map<int, int> totals,
        {String? commentary}) =>
    buildGameResultShareText(
      l10n,
      ranking: _ranking(totals, type),
      gameType: type,
      playedAt: DateTime(2026, 9, 19, 21, 30),
      rounds: 7,
      isLowestScoreWins: type.isLowestScoreWins,
      commentary: commentary,
    );

void main() {
  late AppLocalizations fr;
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('the Play URL is the listing, with no tracking parameter', () {
    final uri = Uri.parse(kPlayStoreUrl);
    expect(uri.host, 'play.google.com');
    expect(uri.path, '/store/apps/details');
    expect(uri.queryParameters, {'id': 'com.vemore.countscore'});
  });

  test('a lowest-wins game lists the lowest total first, in French', () {
    final zapzap = _type('zapzap', lowestWins: true);
    final text = _text(fr, zapzap, {1: 42, 2: 12, 3: 101, 4: 42});

    expect(
      text,
      'Partie du 19 sept. 2026\n'
      'ZapZap · 7 tours · le score le plus bas gagne\n'
      '\n'
      '1. Bob : 12 points\n'
      '2. Alice : 42 points\n'
      '2. Dan : 42 points\n'
      '4. Chloé : 101 points\n'
      '\n'
      'Scores comptés avec CountScore : $kPlayStoreUrl',
    );
  });

  test('a highest-wins game lists the highest total first, in English', () {
    final scrabble = _type('scrabble', lowestWins: false);
    final text = _text(en, scrabble, {1: 1, 2: 312, 3: -5, 4: 280});

    expect(
      text,
      'Game of Sep 19, 2026\n'
      'Scrabble · 7 rounds · highest score wins\n'
      '\n'
      '1. Bob — 312 points\n'
      '2. Dan — 280 points\n'
      '3. Alice — 1 point\n'
      '4. Chloé — -5 points\n'
      '\n'
      'Scores kept with CountScore: $kPlayStoreUrl',
    );
  });

  test('the analysis is shared between the standings and the app line', () {
    final zapzap = _type('zapzap', lowestWins: true);
    final text = _text(en, zapzap, {1: 3, 2: 9, 3: 20, 4: 30},
        commentary: '  **Alice** ran away with it.\n');

    expect(
      text,
      endsWith('4. Dan — 30 points\n'
          '\n'
          '**Alice** ran away with it.\n'
          '\n'
          'Scores kept with CountScore: $kPlayStoreUrl'),
    );
  });

  test('every locale names the app and carries the Play URL', () async {
    final zapzap = _type('zapzap', lowestWins: true);
    for (final locale in AppLocalizations.supportedLocales) {
      await initializeDateFormatting(locale.languageCode);
      final l10n = await AppLocalizations.delegate.load(locale);
      final text = _text(l10n, zapzap, {1: 42, 2: 12, 3: 101, 4: 42});
      expect(text, contains('CountScore'), reason: '$locale');
      expect(text, contains(kPlayStoreUrl), reason: '$locale');
      expect(text, contains('Bob'), reason: '$locale');
      expect(text, contains('2026'), reason: '$locale');
    }
  });
}
