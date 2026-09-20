import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_standing.dart';
import '../models/game_type.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../utils/game_type_name.dart';
import '../utils/player_colors.dart';
import 'board_lanes.dart';
import 'player_avatars.dart';

/// The current game's players best first, as the `StandingsScreen` draws
/// them — open or finished — and as the shared picture repeats them.
///
/// Built from [GameProvider] and the game's type, so the screen and the
/// picture cannot disagree on a place, a colour or who is out.
class GameRanking {
  GameRanking._({
    required this.standing,
    required this.ranked,
    required this.colours,
    required this.isEliminated,
    required this.isNearThreshold,
  });

  /// The current game of [games], whose type is [gameType] (null for a game
  /// without one). The caller checks that a game is current.
  factory GameRanking.of(GameProvider games, GameType? gameType) {
    final game = games.currentGame!;
    return GameRanking.fromStanding(
      GameStanding.forGame(
        players: games.currentPlayers,
        rounds: games.currentRounds,
        scoreOf: games.getScore,
        isLowestScoreWins: game.isLowestScoreWins,
        isFinished: game.isFinished,
        gameType: gameType,
      ),
      gameType,
    );
  }

  /// The ranking of [standing] under [gameType]'s elimination rule — what
  /// [GameRanking.of] builds from the current game, open to a caller (a test,
  /// the shared text) that holds a standing without a [GameProvider].
  ///
  /// The order is [standing]'s own (`GameStanding.rankedPlayers`), the same
  /// the board draws: which rule decides it is the standing's business.
  factory GameRanking.fromStanding(GameStanding standing, GameType? gameType) {
    final players = standing.players;
    return GameRanking._(
      standing: standing,
      ranked: standing.rankedPlayers,
      colours: playerColorsById(players),
      isEliminated: (total) => gameType?.isEliminated(total) ?? false,
      isNearThreshold: (total) =>
          gameType?.isNearElimination(total) ?? false,
    );
  }

  final GameStanding standing;

  /// The players best first; a tie keeps seat order.
  final List<Player> ranked;

  /// Each player's display colour, keyed by player id (`playerColorsById`).
  final Map<int, Color> colours;

  /// Whether a total puts a player out of the game.
  final bool Function(int total) isEliminated;

  /// Whether a total is within 20 points of the elimination threshold.
  final bool Function(int total) isNearThreshold;

  late final Map<int, int> ranks = standing.ranks;

  bool get hasScores => standing.hasScores;

  /// The player in the lead, crowned; null before the first score and on a
  /// tie for the lead, where the tied players share the first place instead.
  Player? get leader => standing.soleLeader;

  /// Every player on the first place — more than one on a tie. Empty before
  /// the first score.
  List<Player> get winners =>
      hasScores ? [for (final p in ranked) if (ranks[p.id] == 1) p] : const [];

  int totalOf(Player p) => standing.totalOf(p);
  Color colourOf(Player p) => colours[p.id] ?? kPlayerPalette.first;
}

/// The one line under a ranking's title: game type · rounds · win rule.
String rankingSummary(
  AppLocalizations l10n, {
  required GameType? gameType,
  required int rounds,
  required bool isLowestScoreWins,
}) =>
    [
      if (gameType != null) gameTypeDisplayName(l10n, gameType),
      l10n.gameEndRounds(rounds),
      isLowestScoreWins ? l10n.gameEndLowestWins : l10n.gameEndHighestWins,
    ].join(' · ');

/// A podium of the top three in their colours, the leader crowned, then
/// **every** player in rank order — the top three twice on purpose, once as
/// the picture and once at the head of the list, so the standings read top to
/// bottom without decoding the podium's 2-1-3 layout first
/// (`wip/done/2026-09-20-podium-hides-the-first-three-from-the-list.md`).
/// Not scrollable itself: the screen puts it in a list.
class RankedPlayers extends StatelessWidget {
  const RankedPlayers({super.key, required this.ranking});

  final GameRanking ranking;

  @override
  Widget build(BuildContext context) {
    final podium = ranking.ranked.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (podium.isNotEmpty) _Podium(players: podium, ranking: ranking),
        const SizedBox(height: 16),
        for (final player in ranking.ranked)
          _RankRow(
            key: Key('ranking_row_${player.id}'),
            player: player,
            ranking: ranking,
          ),
      ],
    );
  }
}

/// A total's colour: orange near the elimination threshold, [fallback]
/// otherwise.
Color _totalColour(BuildContext context, GameRanking ranking, int total,
        Color fallback) =>
    ranking.isNearThreshold(total) ? boardWarningColor(context) : fallback;

/// An eliminated player is drawn as on the board: faded, name struck out.
Widget _outIf(bool eliminated, Widget child) =>
    eliminated ? Opacity(opacity: 0.5, child: child) : child;

/// The top three, second on the left, first raised in the middle, third on
/// the right — each over a block that holds their total, as high as their
/// place: a tie shares a step.
class _Podium extends StatelessWidget {
  const _Podium({required this.players, required this.ranking});

  /// Best first, one to three players.
  final List<Player> players;
  final GameRanking ranking;

  static const _heights = [112.0, 80.0, 60.0];

  /// The step [player] stands on: their place, not their position, so that
  /// players on the same total stand on the same step (1, 1, 3).
  int _step(Player player, int position) =>
      ((ranking.ranks[player.id] ?? position + 1) - 1).clamp(0, 2);

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
                key: Key('ranking_podium_$place'),
                player: players[place],
                ranking: ranking,
                height: _heights[_step(players[place], place)],
                first: _step(players[place], place) == 0,
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
    required this.ranking,
    required this.height,
    required this.first,
  });

  final Player player;
  final GameRanking ranking;
  final double height;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = ranking.totalOf(player);
    final eliminated = ranking.isEliminated(total);
    final crowned = ranking.leader?.id == player.id;
    final avatar = PlayerAvatar(
      name: player.name,
      color: ranking.colourOf(player),
      size: first ? 50 : 38,
      letters: 2,
    );
    return _outIf(
      eliminated,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crowned) const BoardCrown(size: 26),
          if (crowned)
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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              decoration: eliminated ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            key: Key('ranking_step_${player.id}'),
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
                    // The first block is filled with the primary colour: its
                    // total stays readable rather than orange.
                    color: first
                        ? scheme.onPrimary
                        : _totalColour(context, ranking, total, scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One player of the list under the podium: place, avatar, name, total. The
/// first place — every player on it, on a tie — is drawn on the primary
/// container, so the head of the list is as easy to find as the podium.
class _RankRow extends StatelessWidget {
  const _RankRow({super.key, required this.player, required this.ranking});

  final Player player;
  final GameRanking ranking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = ranking.totalOf(player);
    final eliminated = ranking.isEliminated(total);
    final place = ranking.ranks[player.id] ?? 0;
    final first = ranking.hasScores && place == 1;
    return _outIf(
      eliminated,
      Card(
        margin: const EdgeInsets.only(bottom: 6),
        color: first ? scheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: first ? scheme.primary : scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$place',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: first
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PlayerAvatar(
                  name: player.name,
                  color: ranking.colourOf(player),
                  size: 32,
                  letters: 2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: first ? scheme.onPrimaryContainer : null,
                    decoration: eliminated ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Text(
                '$total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _totalColour(context, ranking, total,
                      first ? scheme.onPrimaryContainer : scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
