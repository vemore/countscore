import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/game_result_share.dart';
import '../utils/widget_image.dart';
import 'game_ranking.dart';
import 'result_share_card.dart';

/// Hands [text] — and [image], a PNG of the standings, when it could be
/// drawn — to the system share sheet.
typedef ShareResultFn = Future<void> Function(
  String text, {
  String? subject,
  Uint8List? image,
});

/// Draws the [card] a result is shared as into a PNG.
typedef ResultImageRenderer = Future<Uint8List> Function(
    BuildContext context, Widget card);

/// The system share sheet. With an image, the PNG goes next to the text
/// (`share_plus` writes it to its `cache/share_plus` directory on Android,
/// behind its own `FileProvider`, no permission). On the web, a browser that
/// cannot share files (`navigator.canShare` false: desktop Chromium on Linux,
/// Firefox) makes the image share throw — its download fallback is off, since
/// a download would drop the text — and the text alone is shared instead, as
/// before: Web Share API, else a `mailto:`.
///
/// [sheet] is `SharePlus.instance.share` outside tests.
@visibleForTesting
Future<void> systemShareResult(
  String text, {
  String? subject,
  Uint8List? image,
  Future<ShareResult> Function(ShareParams params)? sheet,
}) async {
  final open = sheet ?? SharePlus.instance.share;
  if (image != null) {
    try {
      await open(ShareParams(
        text: text,
        subject: subject,
        files: [
          XFile.fromData(image, mimeType: 'image/png', name: kShareImageName),
        ],
        fileNameOverrides: const [kShareImageName],
        downloadFallbackEnabled: false,
      ));
      return;
    } catch (e) {
      debugPrint('image share failed, sharing the text alone: $e');
    }
  }
  await open(ShareParams(text: text, subject: subject));
}

/// The app-bar action that shares the current game's standings: the text
/// (`buildGameResultShareText`) and a PNG of them ([ResultShareCard]), both
/// from the same [GameRanking] the screen draws.
///
/// Sharing is user-initiated and goes through the system share sheet: the app
/// sends nothing itself, the user picks where the text and the image go.
class ShareResultButton extends StatelessWidget {
  const ShareResultButton({
    super.key,
    this.commentary,
    this.tooltip,
    this.share,
    this.renderImage,
  });

  /// The analysis text, appended after the standings; null on the rankings.
  final String? commentary;

  /// Defaults to `shareResult`.
  final String? tooltip;

  /// Injected by tests only: receives the text and the image instead of the
  /// share sheet.
  final ShareResultFn? share;

  /// Injected by tests only: receives the card instead of drawing it.
  /// Defaults to `renderWidgetToPng`.
  final ResultImageRenderer? renderImage;

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final games = context.read<GameProvider>();
    final game = games.currentGame;
    if (game == null) return;
    final typeId = game.gameTypeId;
    final gameType = typeId == null
        ? null
        : context.read<GameTypeProvider>().getGameTypeById(typeId);
    final ranking = GameRanking.of(games, gameType);
    final rounds = games.currentRounds.length;
    final text = buildGameResultShareText(
      l10n,
      ranking: ranking,
      gameType: gameType,
      playedAt: game.createdAt,
      rounds: rounds,
      isLowestScoreWins: game.isLowestScoreWins,
      commentary: commentary,
    );
    final card = ResultShareCard(
      ranking: ranking,
      title: l10n.shareResultTitle(
          DateFormat.yMMMd(l10n.localeName).format(game.createdAt)),
      summary: rankingSummary(
        l10n,
        gameType: gameType,
        rounds: rounds,
        isLowestScoreWins: game.isLowestScoreWins,
      ),
      appName: l10n.appTitle,
    );
    final messenger = ScaffoldMessenger.of(context);
    final failed = l10n.shareFailed;
    final subject = l10n.shareResultSubject(game.name);

    // The image is a bonus: if it cannot be drawn, the text still goes. The
    // renderer reads `context` before its first await, while it is mounted.
    Uint8List? image;
    try {
      image = await (renderImage ?? renderWidgetToPng)(context, card);
    } catch (e) {
      debugPrint('share image failed: $e');
    }
    try {
      await (share ?? systemShareResult)(text, subject: subject, image: image);
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
