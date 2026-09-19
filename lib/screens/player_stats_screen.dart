import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../models/player_stats.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../utils/app_theme.dart';
import '../utils/game_type_name.dart';
import '../utils/insets.dart';
import '../utils/player_colors.dart';
import '../widgets/player_avatars.dart';
import 'player_card_screen.dart';

/// The player statistics: a leaderboard over the finished games of one game
/// type — or of all of them — with the best win rate up top. Tapping a player
/// opens their card ([PlayerCardScreen]) on the same filter.
///
/// Everything is computed from `GameProvider.getFinishedGameResults`, keyed by
/// the global player's uuid (`lib/models/player_stats.dart`).
class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  List<FinishedGameResult> _results = const [];
  List<String> _typeKeys = const [];
  Map<String, Color> _colours = const {};

  /// Keyed the way the statistics group: the built-in key when the type has
  /// one, the stored name otherwise (`COALESCE(gt.builtin_key, gt.name)`).
  Map<String, GameType> _gameTypesByKey = const {};

  /// The selected game type, [kAllGameTypes] for all of them.
  String? _filter = kAllGameTypes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();
    await gameTypeProvider.loadGameTypes();
    final results = await gameProvider.getFinishedGameResults();
    if (!mounted) return;
    setState(() {
      _gameTypesByKey = {
        for (final t in gameTypeProvider.gameTypes) t.builtinKey ?? t.name: t,
      };
      _results = results;
      _typeKeys = gameTypesByPlayCount(results);
      _colours = playerColorsByUuid(results);
      _isLoading = false;
    });
  }

  String _typeName(AppLocalizations l10n, String? key) {
    if (key == null) return l10n.allGames;
    final type = _gameTypesByKey[key];
    return type != null
        ? gameTypeDisplayName(l10n, type)
        : gameTypeDisplayNameForKey(l10n, key);
  }

  Color _colourOf(String uuid) => _colours[uuid] ?? kPlayerPalette.first;

  void _openCard(List<LeaderboardEntry> entries, LeaderboardEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final type = _filter == null ? null : _gameTypesByKey[_filter];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerCardScreen(
          results: _results,
          players: entries,
          colours: _colours,
          initialPlayerUuid: entry.playerUuid,
          gameTypeKey: _filter,
          gameTypeName: _typeName(l10n, _filter),
          gameTypeIcon: type?.icon,
          gameTypeColour: type?.cardColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playerStatistics)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(child: Text(l10n.noStatisticsAvailable))
              : _buildBoard(context, l10n),
    );
  }

  Widget _buildBoard(BuildContext context, AppLocalizations l10n) {
    final entries = buildLeaderboard(_results, _filter);
    final leader = entries.where((e) => e.rank == 1).firstOrNull;
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      padding: withBottomInset(context, const EdgeInsets.fromLTRB(16, 4, 16, 24)),
      children: [
        _buildChips(context, l10n),
        const SizedBox(height: 16),
        if (leader != null) ...[
          _Hero(
            entry: leader,
            colour: _colourOf(leader.playerUuid),
            gameTypeName: _typeName(l10n, _filter),
          ),
          const SizedBox(height: 20),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: _HeaderLabel(l10n.statsColumnPlayer,
                    key: const Key('stats_header_player'),
                    style: headerStyle,
                    alignment: AlignmentDirectional.centerStart),
              ),
              SizedBox(
                width: _gamesColumnWidth,
                child: _HeaderLabel(l10n.statsColumnGames,
                    key: const Key('stats_header_games'),
                    style: headerStyle,
                    alignment: AlignmentDirectional.center),
              ),
              SizedBox(
                width: _winsColumnWidth,
                child: _HeaderLabel(l10n.wins,
                    key: const Key('stats_header_wins'),
                    style: headerStyle,
                    alignment: AlignmentDirectional.centerEnd),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LeaderboardRow(
              key: Key('stats_row_${entry.playerUuid}'),
              entry: entry,
              colour: _colourOf(entry.playerUuid),
              onTap: () => _openCard(entries, entry),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.statsLeaderboardFooter(kMinGamesToRank),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildChips(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String? key) {
      final selected = _filter == key;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          key: Key('stats_chip_${key ?? 'all'}'),
          label: Text(_typeName(l10n, key)),
          selected: selected,
          showCheckmark: false,
          shape: const StadiumBorder(),
          selectedColor: scheme.primary,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
          onSelected: (_) => setState(() => _filter = key),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(kAllGameTypes),
          for (final key in _typeKeys) chip(key),
        ],
      ),
    );
  }
}

const double _gamesColumnWidth = 64;
const double _winsColumnWidth = 96;

/// A leaderboard column header, upper-cased on one line: a label wider than
/// its column ("PARTIDAS", sized for "GAMES") shrinks to fit rather than
/// breaking inside the word.
class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label,
      {super.key, required this.style, required this.alignment});

  final String label;
  final TextStyle? style;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(label.toUpperCase(),
            maxLines: 1, softWrap: false, style: style),
      );
}

/// A win rate as the locale writes a percentage ("41 %", "41%").
String formatWinRate(BuildContext context, double rate) =>
    NumberFormat.percentPattern(Localizations.localeOf(context).toString())
        .format(rate);

/// The best win rate, on the brand teal.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.entry,
    required this.colour,
    required this.gameTypeName,
  });

  final LeaderboardEntry entry;
  final Color colour;
  final String gameTypeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    return Container(
      key: const Key('stats_hero'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: kLeaderGold,
              shape: BoxShape.circle,
            ),
            child: PlayerAvatar(
              name: entry.name,
              color: colour,
              size: 58,
              letters: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statsBestWinRate,
                  style: TextStyle(
                      color: on.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [entry.name, formatWinRate(context, entry.winRate)]
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: on, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  [gameTypeName, l10n.statsWinsOutOfGames(entry.wins, entry.games)]
                      .join(' · '),
                  style: TextStyle(color: on.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One player: place, avatar, name, games, wins and win rate, and a bar of
/// the win rate in the player's colour. An unranked player has no place and
/// no bar.
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    super.key,
    required this.entry,
    required this.colour,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final Color colour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

    final head = Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            entry.isRanked ? '${entry.rank}' : '–',
            key: Key('stats_rank_${entry.playerUuid}'),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: muted),
          ),
        ),
        PlayerAvatar(name: entry.name, color: colour, size: 36, letters: 2),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (entry.isRanked) ...[
          SizedBox(
            width: _gamesColumnWidth,
            child: Text(
              '${entry.games}',
              key: Key('stats_games_${entry.playerUuid}'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: muted),
            ),
          ),
          SizedBox(
            width: _winsColumnWidth,
            child: Text(
              [
                '${entry.wins}',
                formatWinRate(context, entry.winRate),
              ].join(' · '),
              key: Key('stats_wins_${entry.playerUuid}'),
              textAlign: TextAlign.end,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ] else
          Flexible(
            child: Text(
              l10n.statsUnranked(entry.games),
              key: Key('stats_games_${entry.playerUuid}'),
              textAlign: TextAlign.end,
              style: TextStyle(color: muted),
            ),
          ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        hint: l10n.statsOpenPlayerCard,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                if (entry.isRanked) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.winRate,
                      minHeight: 8,
                      color: colour,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
