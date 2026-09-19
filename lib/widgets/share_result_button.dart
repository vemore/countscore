import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/game_result_share.dart';
import 'game_ranking.dart';

/// Hands [text] to the system share sheet. On the web, `share_plus` uses the
/// Web Share API and falls back to a `mailto:` link; either may throw.
typedef ShareTextFn = Future<void> Function(String text, {String? subject});

Future<void> _systemShare(String text, {String? subject}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

/// The app-bar action that shares the current game's standings as text
/// (`buildGameResultShareText`), from the same [GameRanking] the screen draws.
///
/// Sharing is user-initiated and goes through the system share sheet: the app
/// sends nothing itself, the user picks where the text goes.
class ShareResultButton extends StatelessWidget {
  const ShareResultButton({
    super.key,
    this.commentary,
    this.tooltip,
    this.share,
  });

  /// The analysis text, appended after the standings; null on the rankings.
  final String? commentary;

  /// Defaults to `shareResult`.
  final String? tooltip;

  /// Injected by tests only: receives the text instead of the share sheet.
  final ShareTextFn? share;

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final games = context.read<GameProvider>();
    final game = games.currentGame;
    if (game == null) return;
    final typeId = game.gameTypeId;
    final gameType = typeId == null
        ? null
        : context.read<GameTypeProvider>().getGameTypeById(typeId);
    final text = buildGameResultShareText(
      l10n,
      ranking: GameRanking.of(games, gameType),
      gameType: gameType,
      playedAt: game.createdAt,
      rounds: games.currentRounds.length,
      isLowestScoreWins: game.isLowestScoreWins,
      commentary: commentary,
    );
    final messenger = ScaffoldMessenger.of(context);
    final failed = l10n.shareFailed;
    try {
      await (share ?? _systemShare)(
        text,
        subject: l10n.shareResultSubject(game.name),
      );
    } catch (e) {
      debugPrint('share failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const Key('share_result'),
      icon: const Icon(Icons.share_outlined),
      tooltip: tooltip ?? l10n.shareResult,
      onPressed: () => _share(context),
    );
  }
}
