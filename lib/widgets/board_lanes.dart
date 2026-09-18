import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_standing.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../utils/app_theme.dart';
import 'player_avatars.dart';

/// Up to this many players, the lanes share the width and never scroll.
const int kBoardMaxFittingLanes = 8;

/// From this many players, the lane header is the compact one: avatar,
/// vertical name, total.
const int kBoardCompactHeaderFrom = 6;

/// Beyond [kBoardMaxFittingLanes], a lane is never narrower than this, and the
/// grid scrolls sideways instead.
const double kBoardMinLaneWidth = 56;

/// No lane grows wider than this, however wide the screen: the lanes are
/// centred instead.
const double kBoardMaxLaneWidth = 180;

/// Width of the pinned round-number column.
const double kBoardRoundColumnWidth = 34;

/// What both board layouts draw from: the game's players in seat order, its
/// rounds, and what the screen does when a round or a cell is tapped.
class BoardData {
  BoardData({
    required this.players,
    required this.rounds,
    required this.scoreOf,
    required this.standing,
    required this.colors,
    required this.isEliminated,
    required this.isNearThreshold,
    required this.onRoundTap,
    required this.onCellTap,
  });

  /// The game's players, in seat order.
  final List<Player> players;
  final List<Round> rounds;

  /// A player's score in a round, null when none was entered.
  final int? Function(int playerId, int roundId) scoreOf;

  /// Totals, the leader and the places. Its leader is null while no score has
  /// been entered.
  final GameStanding standing;

  /// Each player's display colour, keyed by player id (`playerColorsById`).
  final Map<int, Color> colors;

  /// Whether a total puts a player out of the game.
  final bool Function(int total) isEliminated;

  /// Whether a total is within 20 points of the elimination threshold.
  final bool Function(int total) isNearThreshold;

  final void Function(Round round) onRoundTap;
  final void Function(Player player, Round round) onCellTap;

  late final Map<int, int> ranks = standing.ranks;
  late final Player? leader = standing.leader;

  Color colorOf(Player p) => colors[p.id] ?? Colors.grey;
  int totalOf(Player p) => standing.totalOf(p);

  bool isRoundCommented(Round round) =>
      round.comment != null && round.comment!.trim().isNotEmpty;

  /// The players best first; a tie keeps seat order.
  List<Player> get byRank {
    final seat = {for (var i = 0; i < players.length; i++) players[i]: i};
    return [...players]..sort((a, b) {
        final byPlace = (ranks[a.id] ?? 0).compareTo(ranks[b.id] ?? 0);
        return byPlace != 0 ? byPlace : seat[a]!.compareTo(seat[b]!);
      });
  }
}

/// A lane's (or a row's) background: the player's colour over the surface.
Color boardTint(BuildContext context, Color playerColor) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return Color.alphaBlend(
    playerColor.withValues(alpha: dark ? 0.16 : 0.12),
    theme.colorScheme.surface,
  );
}

/// The colour of a total close to the elimination threshold.
Color boardWarningColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF8A4C)
        : const Color(0xFFC2410C);

/// A score as the board shows it: bold, a zero on an amber pill, a dot where
/// no score was entered.
class BoardScoreText extends StatelessWidget {
  const BoardScoreText({super.key, required this.score, this.fontSize = 18});

  final int? score;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    if (score == null) {
      return Text('·',
          style: TextStyle(
              fontSize: fontSize, color: theme.colorScheme.outline, height: 1));
    }
    final text = Text(
      '$score',
      maxLines: 1,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1,
        color: score == 0
            ? (dark ? const Color(0xFFFFD166) : const Color(0xFF8A5A00))
            : theme.colorScheme.onSurface,
      ),
    );
    if (score != 0) return FittedBox(fit: BoxFit.scaleDown, child: text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? kLeaderGold.withValues(alpha: 0.2)
            : const Color(0xFFFFF0C2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: text,
    );
  }
}

/// The leader's mark.
class BoardCrown extends StatelessWidget {
  const BoardCrown({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context)!.boardLeader,
      child: Icon(Icons.emoji_events,
          key: const Key('board_leader_crown'), size: size, color: kLeaderGold),
    );
  }
}

/// The board as one lane per player: a band in the player's colour running
/// from the header (avatar, name, total, place) down to the last round. The
/// header and the cells of a lane are one column, so they cannot drift apart.
class BoardLanes extends StatelessWidget {
  const BoardLanes({super.key, required this.data});

  final BoardData data;

  static const double _rowHeight = 46;
  static const double _gap = 6;
  static const double _hPadding = 12;

  @override
  Widget build(BuildContext context) {
    final n = data.players.length;
    final compact = n >= kBoardCompactHeaderFrom;
    final headerHeight = compact ? 176.0 : 156.0;

    return LayoutBuilder(builder: (context, constraints) {
      final available =
          constraints.maxWidth - 2 * _hPadding - kBoardRoundColumnWidth;
      final fit = (available - _gap * (n - 1)) / n;
      final laneWidth = math.min(
        kBoardMaxLaneWidth,
        n <= kBoardMaxFittingLanes ? fit : math.max(fit, kBoardMinLaneWidth),
      );
      final scrolls = laneWidth * n + _gap * (n - 1) > available + 0.5;

      final lanes = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            _Lane(
              data: data,
              player: data.players[i],
              width: laneWidth,
              headerHeight: headerHeight,
              rowHeight: _rowHeight,
              compact: compact,
            ),
          ],
        ],
      );

      final grid = SingleChildScrollView(
        key: const Key('board_score_grid'),
        padding: const EdgeInsets.fromLTRB(_hPadding, 8, _hPadding, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundColumn(
              data: data,
              headerHeight: headerHeight,
              rowHeight: _rowHeight,
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('board_lanes_scroll'),
                scrollDirection: Axis.horizontal,
                physics: scrolls ? null : const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: available),
                  child: lanes,
                ),
              ),
            ),
          ],
        ),
      );

      if (n <= kBoardMaxFittingLanes) return grid;
      return Column(
        children: [
          _RankingRibbon(data: data),
          Expanded(child: grid),
        ],
      );
    });
  }
}

/// The pinned round numbers. Tapping one opens the round's comment; a round
/// with a comment is underlined.
class _RoundColumn extends StatelessWidget {
  const _RoundColumn({
    required this.data,
    required this.headerHeight,
    required this.rowHeight,
  });

  final BoardData data;
  final double headerHeight;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SizedBox(
      width: kBoardRoundColumnWidth,
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Align(
              alignment: const Alignment(0, 0.85),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(AppLocalizations.of(context)!.round,
                    style: TextStyle(fontSize: 12, color: muted)),
              ),
            ),
          ),
          for (final round in data.rounds)
            InkWell(
              key: Key('board_round_${round.roundNumber}'),
              onTap: () => data.onRoundTap(round),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: rowHeight,
                width: kBoardRoundColumnWidth,
                child: Center(
                  child: Text(
                    '${round.roundNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: muted,
                      decoration: data.isRoundCommented(round)
                          ? TextDecoration.underline
                          : null,
                      decorationThickness: 2,
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

class _Lane extends StatelessWidget {
  const _Lane({
    required this.data,
    required this.player,
    required this.width,
    required this.headerHeight,
    required this.rowHeight,
    required this.compact,
  });

  final BoardData data;
  final Player player;
  final double width;
  final double headerHeight;
  final double rowHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colour = data.colorOf(player);
    final total = data.totalOf(player);
    final isLeader = data.leader?.id == player.id;
    final eliminated = data.isEliminated(total);

    final lane = Container(
      key: Key('board_lane_${player.id}'),
      width: width,
      decoration: BoxDecoration(
        color: boardTint(context, colour),
        borderRadius: BorderRadius.circular(16),
        // Every lane has the border, so the leader's rows stay level with
        // everyone else's.
        border: Border.all(
            color: isLeader ? colour : Colors.transparent, width: 2.5),
      ),
      child: Column(
        children: [
          SizedBox(
            key: Key('board_lane_header_${player.id}'),
            width: width,
            height: headerHeight,
            child: _LaneHeader(
              data: data,
              player: player,
              colour: colour,
              total: total,
              isLeader: isLeader,
              eliminated: eliminated,
              compact: compact,
              width: width,
            ),
          ),
          for (final round in data.rounds)
            InkWell(
              key: Key('board_cell_${player.id}_${round.id}'),
              onTap: () => data.onCellTap(player, round),
              child: SizedBox(
                width: width,
                height: rowHeight,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: BoardScoreText(
                      score: data.scoreOf(player.id!, round.id!),
                      fontSize: compact ? 16 : 19,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
    return eliminated ? Opacity(opacity: 0.5, child: lane) : lane;
  }
}

class _LaneHeader extends StatelessWidget {
  const _LaneHeader({
    required this.data,
    required this.player,
    required this.colour,
    required this.total,
    required this.isLeader,
    required this.eliminated,
    required this.compact,
    required this.width,
  });

  final BoardData data;
  final Player player;
  final Color colour;
  final int total;
  final bool isLeader;
  final bool eliminated;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nameStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      decoration: eliminated ? TextDecoration.lineThrough : null,
      decorationColor: theme.colorScheme.error,
      decorationThickness: 2,
    );
    final totalColour = data.isNearThreshold(total)
        ? boardWarningColor(context)
        : theme.colorScheme.onSurface;
    final avatarSize = math.min(compact ? 30.0 : 40.0, width - 6);
    final ring = theme.colorScheme.surface;

    final children = <Widget>[
      SizedBox(
        height: 20,
        child: isLeader ? const BoardCrown() : null,
      ),
      PlayerAvatar(
        name: player.name,
        color: colour,
        size: avatarSize,
        letters: 2,
        borderColor: ring,
      ),
      const SizedBox(height: 6),
    ];

    if (compact) {
      children.addAll([
        SizedBox(
          height: 78,
          width: width,
          child: RotatedBox(
            quarterTurns: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nameStyle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$total',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: totalColour)),
          ),
        ),
      ]);
    } else {
      children.addAll([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
        SizedBox(
          height: 40,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$total',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: totalColour)),
          ),
        ),
        if (data.leader != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.boardRank(data.ranks[player.id] ?? 1),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ]);
    }
    return Column(children: children);
  }
}

/// Beyond eight players, every player in rank order, so the standing stays
/// readable while the lanes scroll.
class _RankingRibbon extends StatelessWidget {
  const _RankingRibbon({required this.data});

  final BoardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = data.leader == null ? data.players : data.byRank;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        key: const Key('board_ranking_ribbon'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: players.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = players[i];
          final isLeader = data.leader?.id == p.id;
          final total = data.totalOf(p);
          return Container(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLeader
                    ? kLeaderGold
                    : theme.colorScheme.outlineVariant,
                width: isLeader ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerAvatar(
                    name: p.name,
                    color: data.colorOf(p),
                    size: 28,
                    letters: 2),
                const SizedBox(width: 6),
                Text(p.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Text('$total',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: data.isNearThreshold(total)
                            ? boardWarningColor(context)
                            : theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        },
      ),
    );
  }
}
