import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../l10n/app_localizations.dart';
import '../models/player_stats.dart';
import '../utils/app_theme.dart';
import '../utils/insets.dart';
import '../utils/player_colors.dart';
import '../widgets/player_avatars.dart';

/// One player's card, on the game-type filter chosen on the leaderboard:
/// games, wins and average place; the place over the last
/// [kRankChartGames] games, wins in gold; the current win streak and the best
/// final total; then the average and best final totals and the opponent most
/// often finished ahead of.
///
/// Opened from `PlayerStatsScreen`, which hands over what it already loaded:
/// the card reads nothing itself. The strip of avatars at the top switches to
/// another player of the same leaderboard.
class PlayerCardScreen extends StatefulWidget {
  const PlayerCardScreen({
    super.key,
    required this.results,
    required this.players,
    required this.colours,
    required this.initialPlayerUuid,
    required this.gameTypeKey,
    required this.gameTypeName,
    this.gameTypeIcon,
    this.gameTypeColour,
  });

  final List<FinishedGameResult> results;

  /// The leaderboard the card was opened from, in its order.
  final List<LeaderboardEntry> players;
  final Map<String, Color> colours;
  final String initialPlayerUuid;

  /// [kAllGameTypes] for all of them.
  final String? gameTypeKey;
  final String gameTypeName;
  final IconData? gameTypeIcon;
  final Color? gameTypeColour;

  @override
  State<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends State<PlayerCardScreen> {
  late String _uuid = widget.initialPlayerUuid;

  Color _colourOf(String uuid) => widget.colours[uuid] ?? kPlayerPalette.first;

  String _nameOf(String uuid) {
    for (final p in widget.players) {
      if (p.playerUuid == uuid) return p.name;
    }
    for (final r in widget.results) {
      final p = r.participant(uuid);
      if (p != null) return p.name;
    }
    return '?';
  }

  /// Whether every game of the filter is won by the lowest total — null when
  /// they mix both rules ("All games" over several types).
  bool? get _lowestWins {
    final rules = widget.results
        .where((r) => r.matches(widget.gameTypeKey))
        .map((r) => r.isLowestScoreWins)
        .toSet();
    return rules.length == 1 ? rules.single : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final stats =
        PlayerCardStats.compute(widget.results, _uuid, widget.gameTypeKey);
    final colour = _colourOf(_uuid);
    final name = _nameOf(_uuid);
    final lowestWins = _lowestWins;

    final oneDecimal = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    final upToOneDecimal = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 1;

    final ruleText = lowestWins == null
        ? null
        : (lowestWins ? l10n.lowestScoreWins : l10n.highestScoreWins);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          [name, widget.gameTypeName].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding:
            withBottomInset(context, const EdgeInsets.fromLTRB(16, 0, 16, 24)),
        children: [
          _buildStrip(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.gameTypeIcon ?? Icons.leaderboard_outlined,
                        color: widget.gameTypeColour ??
                            theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          [widget.gameTypeName, ?ruleText].join(' · '),
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Tile(
                        key: const Key('card_games'),
                        value: '${stats.games}',
                        label: l10n.statsGamesLabel(stats.games),
                        colour: colour,
                      ),
                      const SizedBox(width: 10),
                      _Tile(
                        key: const Key('card_wins'),
                        value: '${stats.wins}',
                        label: l10n.statsWinsLabel(stats.wins),
                        colour: colour,
                      ),
                      const SizedBox(width: 10),
                      _Tile(
                        key: const Key('card_average_rank'),
                        value: stats.averageRank == null
                            ? '–'
                            : oneDecimal.format(stats.averageRank),
                        label: l10n.statsAverageRank,
                        colour: colour,
                      ),
                    ],
                  ),
                  if (stats.recentRanks.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.statsRankChartTitle(stats.recentRanks.length),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (stats.trend != null)
                          Text(
                            switch (stats.trend!) {
                              RankTrend.improving => l10n.statsTrendImproving,
                              RankTrend.declining => l10n.statsTrendDeclining,
                              RankTrend.steady => l10n.statsTrendSteady,
                            },
                            key: const Key('card_trend'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: stats.trend == RankTrend.declining
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _RankChart(
                      points: stats.recentRanks,
                      colour: colour,
                      ordinal: (rank) => l10n.statsRankOrdinal('$rank'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        key: const Key('card_streak'),
                        text: l10n.statsWinStreak(stats.currentStreak),
                        background: kLeaderGold.withValues(alpha: 0.22),
                        foreground: theme.brightness == Brightness.dark
                            ? kLeaderGold
                            : const Color(0xFF6B5000),
                      ),
                      if (stats.bestTotal != null)
                        _Pill(
                          key: const Key('card_record'),
                          text: l10n.statsRecord(stats.bestTotal!),
                          background: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          foreground: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              (widget.gameTypeKey == kAllGameTypes
                      ? widget.gameTypeName
                      : l10n.statsOnGameType(widget.gameTypeName))
                  .toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (stats.averageTotal != null)
                  _Row(
                    label: l10n.statsAverageTotal,
                    child: Text(
                      upToOneDecimal.format(stats.averageTotal),
                      key: const Key('card_average_total'),
                      style: _rowValueStyle,
                    ),
                  ),
                if (stats.bestTotal != null) ...[
                  const Divider(height: 1),
                  _Row(
                    label: l10n.statsBestTotal,
                    child: Text(
                      '${stats.bestTotal}',
                      key: const Key('card_best_total'),
                      style: _rowValueStyle,
                    ),
                  ),
                ],
                if (stats.mostBeatenUuid != null) ...[
                  const Divider(height: 1),
                  _Row(
                    label: l10n.statsMostBeaten,
                    child: Row(
                      key: const Key('card_most_beaten'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatar(
                          name: _nameOf(stats.mostBeatenUuid!),
                          color: _colourOf(stats.mostBeatenUuid!),
                          size: 30,
                          letters: 2,
                        ),
                        const SizedBox(width: 8),
                        Text(_nameOf(stats.mostBeatenUuid!),
                            style: _rowValueStyle),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final p in widget.players)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _StripAvatar(
                key: Key('card_strip_${p.playerUuid}'),
                name: p.name,
                colour: _colourOf(p.playerUuid),
                selected: p.playerUuid == _uuid,
                onTap: () => setState(() => _uuid = p.playerUuid),
              ),
            ),
        ],
      ),
    );
  }
}

const TextStyle _rowValueStyle =
    TextStyle(fontSize: 19, fontWeight: FontWeight.w900);

class _StripAvatar extends StatelessWidget {
  const _StripAvatar({
    super.key,
    required this.name,
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colour : Colors.transparent,
              width: 3,
            ),
          ),
          child: Opacity(
            opacity: selected ? 1 : 0.6,
            child: PlayerAvatar(
              name: name,
              color: colour,
              size: 44,
              letters: 2,
              borderColor: selected ? surface : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// A figure over its label, on a wash of the player's colour.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.value,
    required this.label,
    required this.colour,
  });

  final String value;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontWeight: FontWeight.w800, color: foreground)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}

/// The final place over the last games, oldest on the left, first place at
/// the top; a gold dot on each win.
class _RankChart extends StatelessWidget {
  const _RankChart({
    required this.points,
    required this.colour,
    required this.ordinal,
  });

  final List<RankPoint> points;
  final Color colour;
  final String Function(int rank) ordinal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worst = math.max(
      2,
      points.map((p) => math.max(p.playerCount, p.rank)).reduce(math.max),
    );
    return Semantics(
      label: points.map((p) => ordinal(p.rank)).join(', '),
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('card_rank_chart'),
        height: 150,
        width: double.infinity,
        child: CustomPaint(
          painter: RankChartPainter(
            ranks: [for (final p in points) p.rank],
            wins: [for (final p in points) p.won],
            worstRank: worst,
            lineColour: colour,
            winColour: kLeaderGold,
            gridColour: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            labelStyle: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            topLabel: ordinal(1),
            bottomLabel: ordinal(worst),
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

/// Draws the rank chart: a grid line per place (1 at the top), the first and
/// last places labelled, the ranks as a line and the wins as gold dots.
class RankChartPainter extends CustomPainter {
  RankChartPainter({
    required this.ranks,
    required this.wins,
    required this.worstRank,
    required this.lineColour,
    required this.winColour,
    required this.gridColour,
    required this.labelStyle,
    required this.topLabel,
    required this.bottomLabel,
    required this.textDirection,
  });

  final List<int> ranks;
  final List<bool> wins;
  final int worstRank;
  final Color lineColour;
  final Color winColour;
  final Color gridColour;
  final TextStyle labelStyle;
  final String topLabel;
  final String bottomLabel;
  final TextDirection textDirection;

  static const double _labelGap = 36;
  static const double _pad = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final top = _pad;
    final bottom = size.height - _pad;
    double yOf(int rank) =>
        top + (rank - 1) / (worstRank - 1) * (bottom - top);

    final grid = Paint()
      ..color = gridColour
      ..strokeWidth = 1;
    // A line per place while they fit; past six, only the first and the last.
    final gridRanks = worstRank <= 6
        ? [for (var r = 1; r <= worstRank; r++) r]
        : [1, worstRank];
    for (final r in gridRanks) {
      canvas.drawLine(Offset(0, yOf(r)), Offset(size.width, yOf(r)), grid);
    }

    void label(String text, int rank, {required bool above}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: textDirection,
      )..layout(maxWidth: _labelGap);
      final y = above ? yOf(rank) - tp.height - 2 : yOf(rank) + 2;
      final x = textDirection == TextDirection.rtl ? size.width - tp.width : 0.0;
      tp.paint(canvas, Offset(x, math.max(0, y)));
    }

    label(topLabel, 1, above: false);
    label(bottomLabel, worstRank, above: true);

    if (ranks.isEmpty) return;
    final rtl = textDirection == TextDirection.rtl;
    final start = rtl ? 8.0 : _labelGap + 8;
    final end = rtl ? size.width - _labelGap - 8 : size.width - 8;
    double xOf(int i) {
      final t = ranks.length == 1 ? 0.5 : i / (ranks.length - 1);
      // Oldest on the reading start.
      return rtl ? end - t * (end - start) : start + t * (end - start);
    }

    final path = Path();
    for (var i = 0; i < ranks.length; i++) {
      final o = Offset(xOf(i), yOf(ranks[i]));
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (ranks.length == 1) {
      canvas.drawCircle(
          Offset(xOf(0), yOf(ranks[0])), 5, Paint()..color = lineColour);
    }
    final gold = Paint()..color = winColour;
    for (var i = 0; i < ranks.length; i++) {
      if (wins[i]) canvas.drawCircle(Offset(xOf(i), yOf(ranks[i])), 6, gold);
    }
  }

  @override
  bool shouldRepaint(RankChartPainter old) =>
      old.ranks.join(',') != ranks.join(',') ||
      old.wins.join(',') != wins.join(',') ||
      old.worstRank != worstRank ||
      old.lineColour != lineColour ||
      old.gridColour != gridColour ||
      old.topLabel != topLabel ||
      old.bottomLabel != bottomLabel ||
      old.textDirection != textDirection;
}
