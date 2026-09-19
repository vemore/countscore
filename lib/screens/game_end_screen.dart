import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/insets.dart';
import '../utils/play_again.dart';
import '../widgets/game_ranking.dart';
import '../widgets/share_result_button.dart';
import 'game_analysis_screen.dart';
import 'game_board_screen.dart';

/// Who won the current game: the winner's name, a podium of the top three in
/// their colours, the other players in rank order, then "Play again" and —
/// when a server is configured — "Analysis". The app bar shares the standings
/// as text (`ShareResultButton`).
///
/// Opened by the board when the game type's rule ends the game, when "End
/// game" is chosen on the board or on the home list, and from a finished
/// game's app bar. It reads the game `GameProvider` holds as current; the
/// caller loads it first and records the game as finished.
///
/// With [offerContinue] — the rule ended the game, the user did not ask — a
/// "Continue playing" action pops the route with `true`, the caller's cue to
/// reopen the game (golden score, a house rule the type does not know).
class GameEndScreen extends StatelessWidget {
  const GameEndScreen({
    super.key,
    this.offerContinue = false,
    this.boardBuilder,
    this.share,
  });

  final bool offerContinue;

  /// Injected by tests only: receives the shared text instead of the system
  /// share sheet.
  final ShareTextFn? share;

  /// Injected by tests only: the board "Play again" opens. The default
  /// `GameBoardScreen` reaches the `AppDatabase` singleton.
  final WidgetBuilder? boardBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.watch<GameProvider>();
    final game = gameProvider.currentGame;
    if (game == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noCurrentGame)),
      );
    }

    final typeId = game.gameTypeId;
    final gameType = typeId == null
        ? null
        : context.watch<GameTypeProvider>().getGameTypeById(typeId);
    final ranking = GameRanking.of(gameProvider, gameType);
    final winners = ranking.winners;
    final headline = winners.isEmpty
        ? l10n.gameFinished
        : winners.length == 1
            ? l10n.gameEndWinner(winners.single.name)
            : l10n.gameEndTie(winners.map((p) => p.name).join(', '));
    final summary = rankingSummary(
      l10n,
      gameType: gameType,
      rounds: gameProvider.currentRounds.length,
      isLowestScoreWins: game.isLowestScoreWins,
    );

    final canAnalyse = context.watch<BackendProvider>().isConfigured;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(game.name, overflow: TextOverflow.ellipsis),
        actions: [ShareResultButton(share: share)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text(
                  headline,
                  key: const Key('game_end_headline'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                RankedPlayers(ranking: ranking),
              ],
            ),
          ),
          Padding(
            padding: withBottomInset(
                context, const EdgeInsets.fromLTRB(16, 8, 16, 16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (offerContinue)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      key: const Key('game_end_continue'),
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: Text(l10n.continuePlay),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('game_end_play_again'),
                        onPressed: () => playAgain(
                          context,
                          game,
                          board: boardBuilder ?? (_) => const GameBoardScreen(),
                        ),
                        icon: const Icon(Icons.replay),
                        label: Text(l10n.playAgain),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    // The analysis is the app's only network call: without a
                    // server it is not offered, and Play again takes the row.
                    if (canAnalyse) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('game_end_analysis'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GameAnalysisScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(l10n.gameEndAnalysis),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            side: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
