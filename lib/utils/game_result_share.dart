import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../widgets/game_ranking.dart';

/// The app's Play Store listing, built from the application id
/// (`android/app/build.gradle.kts`). Plain on purpose: no `referrer`, no
/// `utm_*` — the shared text carries no tracking parameter.
const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.vemore.countscore';

/// The text a finished (or running) game is shared as, from the ranking the
/// screen draws — so the message and the podium cannot disagree:
///
/// ```text
/// Partie du 19 sept. 2026
/// ZapZap · 7 tours · le score le plus bas gagne
///
/// 1. Alice : 12 points
/// 2. Bob : 35 points
///
/// <commentary, when sharing the analysis>
///
/// Scores comptés avec CountScore : https://play.google.com/…
/// ```
///
/// Pure: the date is formatted in [AppLocalizations.localeName], nothing is
/// read from a provider. The caller hands it to the system share sheet.
String buildGameResultShareText(
  AppLocalizations l10n, {
  required GameRanking ranking,
  required GameType? gameType,
  required DateTime playedAt,
  required int rounds,
  required bool isLowestScoreWins,
  String? commentary,
}) {
  final date = DateFormat.yMMMd(l10n.localeName).format(playedAt);
  final lines = <String>[
    l10n.shareResultTitle(date),
    rankingSummary(
      l10n,
      gameType: gameType,
      rounds: rounds,
      isLowestScoreWins: isLowestScoreWins,
    ),
    '',
    for (final player in ranking.ranked)
      l10n.shareResultStanding(
        ranking.ranks[player.id] ?? 0,
        player.name,
        ranking.totalOf(player),
      ),
    if (commentary != null && commentary.trim().isNotEmpty) ...[
      '',
      commentary.trim(),
    ],
    '',
    l10n.shareResultFooter(l10n.appTitle, kPlayStoreUrl),
  ];
  return lines.join('\n');
}
