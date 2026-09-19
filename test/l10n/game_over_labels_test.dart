import 'package:countscore/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GameOverConditionType.firstPlayerOver` ends a game when a total *reaches*
/// the threshold (`>=`, GameType.isGameOver), while `lastPlayerOver` keeps the
/// strict reading. The form labels must say so: "over" reads as strictly above.
void main() {
  test('the first-player condition says "reach", the last-player one "over"',
      () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.firstPlayerOver, 'First player to reach');
    expect(en.lastPlayerOver, 'Last player over');

    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.firstPlayerOver, 'Premier joueur à atteindre');
    expect(fr.lastPlayerOver, 'Dernier joueur au-dessus');
  });
}
