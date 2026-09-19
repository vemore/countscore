import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game_standing.dart';
import '../models/player.dart';
import '../providers/backend_provider.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/app_theme.dart';
import '../utils/game_type_name.dart';
import '../utils/insets.dart';
import '../utils/play_again.dart';
import '../utils/player_colors.dart';
import '../widgets/player_avatars.dart';
import 'game_analysis_screen.dart';
import 'game_board_screen.dart';

/// Who won the current game: the winner's name, a podium of the top three in
/// their colours, the other players in rank order, then "Play again" and —
/// when a server is configured — "Analysis".
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
  });

  final bool offerContinue;

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

    final players = gameProvider.currentPlayers;
    final rounds = gameProvider.currentRounds;
    final hasScores = players.any((p) =>
        rounds.any((r) => gameProvider.getScore(p.id!, r.id!) != null));
    final standing = GameStanding(
      players: players,
      totals: hasScores
          ? {for (final p in players) p.id!: gameProvider.getPlayerTotal(p.id!)}
          : const {},
      isLowestScoreWins: game.isLowestScoreWins,
    );
    final ranks = standing.ranks;
    final colours = playerColorsById(players);
    // Best first; a tie keeps the seat order, the rule `GameStanding.leader`
    // applies. `List.sort` is not stable, so the seat is the tie-breaker.
    final seat = {for (var i = 0; i < players.length; i++) players[i].id: i};
    final ranked = [...players]..sort((a, b) {
        final byRank = (ranks[a.id] ?? 0).compareTo(ranks[b.id] ?? 0);
        return byRank != 0 ? byRank : seat[a.id]!.compareTo(seat[b.id]!);
      });

    final winners = [
      for (final p in ranked)
        if (ranks[p.id] == 1) p
    ];
    final headline = !hasScores || winners.isEmpty
        ? l10n.gameFinished
        : winners.length == 1
            ? l10n.gameEndWinner(winners.single.name)
            : l10n.gameEndTie(winners.map((p) => p.name).join(', '));

    final typeId = game.gameTypeId;
    final gameType = typeId == null
        ? null
        : context.watch<GameTypeProvider>().getGameTypeById(typeId);
    final summary = [
      if (gameType != null) gameTypeDisplayName(l10n, gameType),
      l10n.gameEndRounds(rounds.length),
      game.isLowestScoreWins ? l10n.gameEndLowestWins : l10n.gameEndHighestWins,
    ].join(' · ');

    final canAnalyse = context.watch<BackendProvider>().isConfigured;
    final theme = Theme.of(context);
    final podium = ranked.take(3).toList();
    final others = ranked.skip(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(game.name, overflow: TextOverflow.ellipsis),
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
                if (podium.isNotEmpty)
                  _Podium(
                    players: podium,
                    totalOf: standing.totalOf,
                    colours: colours,
                  ),
                const SizedBox(height: 16),
                for (final player in others)
                  _RankRow(
                    rank: ranks[player.id] ?? 0,
                    player: player,
                    total: standing.totalOf(player),
                    colour: colours[player.id] ?? kPlayerPalette.first,
                  ),
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

/// The top three, second on the left, first raised in the middle, third on
/// the right — each over a block that holds their total.
class _Podium extends StatelessWidget {
  const _Podium({
    required this.players,
    required this.totalOf,
    required this.colours,
  });

  /// Best first, one to three players.
  final List<Player> players;
  final int Function(Player) totalOf;
  final Map<int, Color> colours;

  static const _heights = [112.0, 80.0, 60.0];

  @override
  Widget build(BuildContext context) {
    // Display order: 2nd, 1st, 3rd, whichever of them exist.
    final order = [
      if (players.length > 1) 1,
      0,
      if (players.length > 2) 2,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final place in order)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _Step(
                key: Key('game_end_podium_$place'),
                player: players[place],
                total: totalOf(players[place]),
                colour: colours[players[place].id] ?? kPlayerPalette.first,
                height: _heights[place],
                first: place == 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.player,
    required this.total,
    required this.colour,
    required this.height,
    required this.first,
  });

  final Player player;
  final int total;
  final Color colour;
  final double height;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = PlayerAvatar(
      name: player.name,
      color: colour,
      size: first ? 50 : 38,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (first)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: kLeaderGold,
              shape: BoxShape.circle,
            ),
            child: avatar,
          )
        else
          avatar,
        const SizedBox(height: 6),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: first
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: first ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: first ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A player past the podium: place, avatar, name, total.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.player,
    required this.total,
    required this.colour,
  });

  final int rank;
  final Player player;
  final int total;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PlayerAvatar(name: player.name, color: colour, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$total',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
