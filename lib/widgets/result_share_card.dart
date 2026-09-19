import 'package:flutter/material.dart';

import 'game_ranking.dart';

/// The picture a result is shared as: the title, the summary line, the
/// standings drawn by [RankedPlayers] — the podium in the players' colours,
/// then the others — and the app's name.
///
/// Drawn off-screen (`renderWidgetToPng`) from the same [GameRanking] the
/// screen shows, so the image cannot rank differently from the podium. The
/// strings come in already localized: the card reads no provider.
class ResultShareCard extends StatelessWidget {
  const ResultShareCard({
    super.key,
    required this.ranking,
    required this.title,
    required this.summary,
    required this.appName,
  });

  final GameRanking ranking;

  /// "Game of {date}" (`shareResultTitle`).
  final String title;

  /// Game type · rounds · win rule (`rankingSummary`).
  final String summary;

  /// `appTitle`, the card's signature.
  final String appName;

  /// The card's logical width; rendered at 3x, the PNG is 1200 px wide.
  static const width = 400.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: scheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                key: const Key('share_card_title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              RankedPlayers(ranking: ranking),
              const SizedBox(height: 4),
              Text(
                appName,
                key: const Key('share_card_app'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
