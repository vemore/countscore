import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/game_standing.dart';
import '../models/game_type.dart';
import '../providers/backend_provider.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/insets.dart';
import '../utils/play_again.dart';
import '../widgets/game_ranking.dart';
import '../widgets/share_result_button.dart';
import 'game_analysis_screen.dart';
import 'game_board_screen.dart';

/// Where the current game stands — the app's one standings screen, in two
/// states.
///
/// The game's own `isFinished` decides which: an **open** game shows the live
/// standings under the *Ranking* title, a **finished** one shows its result —
/// the winner's name (`game_end_headline`) and, with a server configured,
/// *Analysis*. Everything else is common to both: the win rule on one line
/// (`ranking_summary`) — followed, on a game the elimination order ranks, by
/// the line that says so (`ranking_elimination_note`) — the podium and the
/// ranked rows (`RankedPlayers`),
/// *Play again*, and the app bar's share action (`ShareResultButton`), which
/// sends the standings as text and as an image.
///
/// It reads the game `GameProvider` holds as current; the caller loads it
/// first, and — on the paths that end a game — records it as finished. Pushed
/// by the board's leaderboard button (`_openStandings`), by the rule that ends
/// a game, and by "End game" on the home list.
///
/// With [offerContinue] — the rule ended the game, the user did not ask — a
/// "Continue playing" action pops the route with `true`, the caller's cue to
/// reopen the game (golden score, a house rule the type does not know).
///
/// Before 2026-09-20 this was two screens, `RankingScreen` and
/// `GameEndScreen`, reached by two adjacent app-bar buttons on a finished
/// game (`wip/done/2026-09-20-ranking-and-end-screen-are-the-same-screen.md`).
class StandingsScreen extends StatelessWidget {
  const StandingsScreen({
    super.key,
    this.offerContinue = false,
    this.boardBuilder,
    this.share,
  });

  final bool offerContinue;

  /// Injected by tests only: receives the shared text and image instead of the
  /// system share sheet.
  final ShareResultFn? share;

  /// Injected by tests only: the board "Play again" opens. The default
  /// `GameBoardScreen` reaches the `AppDatabase` singleton.
  final WidgetBuilder? boardBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.watch<GameProvider>();
    final game = gameProvider.currentGame;
    // The one distinction the screen branches on, and the one the ranking rule
    // will branch on next: a finished game shows a result, an open one shows
    // where it stands.
    final finished = game?.isFinished ?? false;
    final hasPlayers = game != null && gameProvider.currentPlayers.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(finished ? l10n.gameEndResults : l10n.ranking),
        actions: [if (hasPlayers) ShareResultButton(share: share)],
      ),
      body: game == null
          ? Center(child: Text(l10n.noCurrentGame))
          : !hasPlayers
              ? Center(child: Text(l10n.noScoresRecorded))
              : _Standings(
                  game: game,
                  finished: finished,
                  offerContinue: offerContinue,
                  boardBuilder: boardBuilder,
                ),
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings({
    required this.game,
    required this.finished,
    required this.offerContinue,
    required this.boardBuilder,
  });

  final Game game;
  final bool finished;
  final bool offerContinue;
  final WidgetBuilder? boardBuilder;

  /// Who the finished game belongs to: the winner, the players tied at the
  /// top, or nobody when no score was recorded.
  String _headline(AppLocalizations l10n, GameRanking ranking) {
    final winners = ranking.winners;
    return winners.isEmpty
        ? l10n.gameFinished
        : winners.length == 1
            ? l10n.gameEndWinner(winners.single.name)
            : l10n.gameEndTie(winners.map((p) => p.name).join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.watch<GameProvider>();
    final theme = Theme.of(context);
    final typeId = game.gameTypeId;
    final GameType? gameType = typeId == null
        ? null
        : context.watch<GameTypeProvider>().getGameTypeById(typeId);
    final ranking = GameRanking.of(gameProvider, gameType);
    // The analysis is the app's only network call: without a server it is not
    // offered, and Play again takes the row.
    final canAnalyse =
        finished && context.watch<BackendProvider>().isConfigured;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (finished) ...[
                Text(
                  _headline(l10n, ranking),
                  key: const Key('game_end_headline'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                rankingSummary(
                  l10n,
                  gameType: gameType,
                  rounds: gameProvider.currentRounds.length,
                  isLowestScoreWins: game.isLowestScoreWins,
                ),
                key: const Key('ranking_summary'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              // Read alone, a finished elimination game's places look like a
              // bug: the last one out ranks second whatever the totals say.
              // Only the finished game gets the line — the rule is derived
              // from `isFinished`, and an open game ranks by the total, which
              // needs no explaining
              // (`wip/done/2026-09-20-elimination-ranking-is-unexplained-on-screen.md`).
              if (ranking.standing.rule == RankingRule.eliminationOrder) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.rankingEliminationNote,
                  key: const Key('ranking_elimination_note'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 20),
              RankedPlayers(ranking: ranking),
            ],
          ),
        ),

        // The next game of the evening, without the creation flow. The bottom
        // inset is here rather than on the list: this is the last thing above
        // the navigation bar.
        Padding(
          padding:
              withBottomInset(context, const EdgeInsets.fromLTRB(16, 8, 16, 16)),
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
                      // The key says which state the button is in, so that the
                      // two screens' tests kept their seam when they merged.
                      key: Key(finished
                          ? 'game_end_play_again'
                          : 'ranking_play_again'),
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
                          side:
                              BorderSide(color: theme.colorScheme.outlineVariant),
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
    );
  }
}
