import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/player.dart';
import 'board_lanes.dart';
import 'player_avatars.dart';

/// How many rounds the one-row-per-player board shows at once; older rounds
/// are a swipe away.
const int kBoardRowsVisibleRounds = 4;

/// The board as one row per player: seat order by default, rank order on
/// request; the last [kBoardRowsVisibleRounds] rounds as columns, then the
/// total. The round columns scroll together, and open on the latest round.
class BoardRows extends StatefulWidget {
  const BoardRows({super.key, required this.data});

  final BoardData data;

  @override
  State<BoardRows> createState() => _BoardRowsState();
}

class _BoardRowsState extends State<BoardRows> {
  bool _byRank = false;

  static const double _rowHeight = 52;
  static const double _headerHeight = 32;
  static const double _gap = 8;
  static const double _totalWidth = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final data = widget.data;
    final players =
        _byRank && data.leader != null ? data.byRank : data.players;
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              key: const Key('board_rows_order'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.boardSeatOrder)),
                ButtonSegment(value: true, label: Text(l10n.ranking)),
              ],
              selected: {_byRank},
              onSelectionChanged: (s) => setState(() => _byRank = s.first),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            const padding = 16.0;
            final inner = constraints.maxWidth - 2 * padding;
            final nameWidth = math.min(200.0, inner * 0.38);
            final roundsWidth = inner - nameWidth - _totalWidth;
            final roundWidth = roundsWidth / kBoardRowsVisibleRounds;
            final rowsHeight = players.length * (_rowHeight + _gap);

            // Row backgrounds, under the three columns that sit on them.
            final backgrounds = Column(
              children: [
                const SizedBox(height: _headerHeight),
                for (final p in players)
                  Container(
                    height: _rowHeight,
                    margin: const EdgeInsets.only(bottom: _gap),
                    decoration: BoxDecoration(
                      color: boardTint(context, data.colorOf(p)),
                      borderRadius: BorderRadius.circular(16),
                      border: data.leader?.id == p.id
                          ? Border.all(color: data.colorOf(p), width: 2)
                          : null,
                    ),
                    // The player's colour as a strip along the row's start,
                    // following its rounded corners.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          Container(width: 5, color: data.colorOf(p)),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
              ],
            );

            Widget cellRow(Player p) => SizedBox(
                  height: _rowHeight + _gap,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _gap),
                    child: Row(
                      children: [
                        for (final round in data.rounds)
                          InkWell(
                            key: Key('board_rows_cell_${p.id}_${round.id}'),
                            onTap: () => data.onCellTap(p, round),
                            child: SizedBox(
                              width: roundWidth,
                              height: _rowHeight,
                              child: Center(
                                child: BoardScoreText(
                                  score: data.scoreOf(p.id!, round.id!),
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

            final rounds = SingleChildScrollView(
              key: const Key('board_rows_rounds'),
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: roundsWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: _headerHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final round in data.rounds)
                            InkWell(
                              onTap: () => data.onRoundTap(round),
                              child: SizedBox(
                                width: roundWidth,
                                child: Center(
                                  child: Text(
                                    l10n.boardRoundShort(round.roundNumber),
                                    style: muted.copyWith(
                                      decoration: data.isRoundCommented(round)
                                          ? TextDecoration.underline
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final p in players) cellRow(p),
                  ],
                ),
              ),
            );

            return SingleChildScrollView(
              key: const Key('board_score_grid'),
              padding: const EdgeInsets.fromLTRB(padding, 4, padding, 16),
              child: Stack(
                children: [
                  Positioned.fill(child: backgrounds),
                  SizedBox(
                    height: _headerHeight + rowsHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: nameWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: _headerHeight,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 12),
                                  child: Align(
                                    alignment:
                                        AlignmentDirectional.centerStart,
                                    child: Text(l10n.boardPlayer, style: muted),
                                  ),
                                ),
                              ),
                              for (final p in players)
                                _NameCell(
                                  key: Key('board_row_${p.id}'),
                                  data: data,
                                  player: p,
                                  height: _rowHeight,
                                  gap: _gap,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: roundsWidth, child: rounds),
                        SizedBox(
                          width: _totalWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: _headerHeight,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      end: 12),
                                  child: Center(
                                      child:
                                          Text(l10n.boardTotal, style: muted)),
                                ),
                              ),
                              for (final p in players)
                                _TotalCell(
                                  data: data,
                                  player: p,
                                  height: _rowHeight,
                                  gap: _gap,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({
    super.key,
    required this.data,
    required this.player,
    required this.height,
    required this.gap,
  });

  final BoardData data;
  final Player player;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = data.colorOf(player);
    final eliminated = data.isEliminated(data.totalOf(player));
    final isLeader = data.leader?.id == player.id;
    return Container(
      height: height,
      margin: EdgeInsets.only(bottom: gap),
      child: Row(
        children: [
          const SizedBox(width: 11),
          if (isLeader) ...[
            const BoardCrown(size: 16),
            const SizedBox(width: 2),
          ],
          PlayerAvatar(name: player.name, color: colour, size: 30, letters: 2),
          const SizedBox(width: 8),
          Expanded(
            child: Opacity(
              opacity: eliminated ? 0.5 : 1,
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  decoration: eliminated ? TextDecoration.lineThrough : null,
                  decorationColor: theme.colorScheme.error,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.data,
    required this.player,
    required this.height,
    required this.gap,
  });

  final BoardData data;
  final Player player;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final total = data.totalOf(player);
    return Container(
      height: height,
      margin: EdgeInsets.only(bottom: gap),
      padding: const EdgeInsetsDirectional.only(end: 12),
      alignment: AlignmentDirectional.centerEnd,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$total',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: data.isNearThreshold(total)
                ? boardWarningColor(context)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
