import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GameOverConditionType.firstPlayerOver` ends a game when a total *reaches*
/// the threshold (`>=`, GameType.isGameOver), while the two last-player
/// conditions are last player standing: the game ends once every player but
/// one is past the threshold. The form labels and the rules sentence must say
/// what the code does.
void main() {
  test('the first-player condition says "reach", the last-player one is '
      'last player standing', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.firstPlayerOver, 'First player to reach');
    expect(en.lastPlayerOver, 'Last player standing (others over)');
    expect(en.lastPlayerUnder, 'Last player standing (others under)');

    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.firstPlayerOver, 'Premier joueur à atteindre');
    expect(fr.lastPlayerOver, 'Dernier joueur en jeu (les autres au-dessus)');
    expect(fr.lastPlayerUnder, 'Dernier joueur en jeu (les autres en dessous)');
  });

  test('the rules sentence and isGameOver agree: every player but one', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));

    // What the rules screen and the create-game screen show for the condition.
    expect(en.gameRulesEndLastOver(100),
        'The game ends when every player but one is above 100 points');
    expect(fr.gameRulesEndLastOver(100),
        "La partie s'arrête quand tous les joueurs sauf un dépassent 100 points");

    final type = GameType(
      name: 'Seuil',
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: true,
      gameOverConditionType: GameOverConditionType.lastPlayerOver,
      gameOverThreshold: 100,
    );

    // Every player but one above 100: what the sentence promises, and the game
    // ends. One more still in: it does not.
    expect(type.isGameOver([101, 120, 130, 40]), isTrue);
    expect(type.isGameOver([101, 120, 90, 40]), isFalse);

    expect(en.gameRulesEndLastUnder(0),
        'The game ends when every player but one is below 0 points');
    final under = GameType(
      name: 'Seuil',
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: false,
      gameOverConditionType: GameOverConditionType.lastPlayerUnder,
      gameOverThreshold: 0,
    );
    expect(under.isGameOver([-1, -20, -30, 5]), isTrue);
    expect(under.isGameOver([-1, -20, 3, 5]), isFalse);
  });
}
