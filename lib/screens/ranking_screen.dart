import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/insets.dart';
import '../utils/play_again.dart';
import '../widgets/game_ranking.dart';
import '../widgets/share_result_button.dart';
import 'game_board_screen.dart';

/// Where an open game stands, from the board's leaderboard button: the win
/// rule on one line, then the same podium and ranked rows as the end screen
/// (`RankedPlayers`) — player colours, the leader's crown, totals near the
/// elimination threshold in orange, eliminated players struck out — and
/// "Play again". The app bar shares the standings as text and image
/// (`ShareResultButton`).
class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key, this.boardBuilder, this.share});

  /// Injected by tests only: receives the shared text and image instead of the system
  /// share sheet.
  final ShareResultFn? share;

  /// Injected by tests only: the board "Play again" opens. The default
  /// `GameBoardScreen` reaches the `AppDatabase` singleton.
  final WidgetBuilder? boardBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canShare = context.select<GameProvider, bool>(
        (g) => g.currentGame != null && g.currentPlayers.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ranking),
        actions: [if (canShare) ShareResultButton(share: share)],
      ),
      body: Builder(
        builder: (context) {
          final gameProvider = context.watch<GameProvider>();
          final game = gameProvider.currentGame;
          if (game == null) {
            return Center(child: Text(l10n.noCurrentGame));
          }
          if (gameProvider.currentPlayers.isEmpty) {
            return Center(child: Text(l10n.noScoresRecorded));
          }

          final typeId = game.gameTypeId;
          final gameType = typeId == null
              ? null
              : context.watch<GameTypeProvider>().getGameTypeById(typeId);
          final ranking = GameRanking.of(gameProvider, gameType);
          final theme = Theme.of(context);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Text(
                      rankingSummary(
                        l10n,
                        gameType: gameType,
                        rounds: gameProvider.currentRounds.length,
                        isLowestScoreWins: game.isLowestScoreWins,
                      ),
                      key: const Key('ranking_summary'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    RankedPlayers(ranking: ranking),
                  ],
                ),
              ),

              // The next game of the evening, without the creation flow. The
              // bottom inset is here rather than on the list: this is the last
              // thing above the navigation bar.
              Padding(
                padding: withBottomInset(
                    context, const EdgeInsets.fromLTRB(16, 8, 16, 16)),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('ranking_play_again'),
                    onPressed: () => playAgain(
                      context,
                      game,
                      board: boardBuilder ?? (_) => const GameBoardScreen(),
                    ),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.playAgain),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
