import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../models/game.dart';
import '../models/game_standing.dart';
import '../models/game_type.dart';
import '../services/review_prompt.dart';
import '../widgets/player_avatars.dart';
import '../utils/game_type_name.dart';
import '../utils/insets.dart';
import '../utils/play_again.dart';
import '../utils/undo_snack_bar.dart';
import 'about_screen.dart';
import 'create_game_screen.dart';
import 'game_board_screen.dart';
import 'game_types_screen.dart';
import 'player_stats_screen.dart';
import 'players_screen.dart';
import 'settings_screen.dart';
import 'standings_screen.dart';

/// The game the home screen's Resume card offers: the open game played most
/// recently (last score or rename, else creation), or null when every game is
/// finished.
Game? resumableGame(List<Game> games) {
  Game? best;
  for (final game in games) {
    if (game.isFinished) continue;
    final at = game.lastModified ?? game.createdAt;
    if (best == null || at.isAfter(best.lastModified ?? best.createdAt)) {
      best = game;
    }
  }
  return best;
}

/// From this width (in dp) the home screen lays its game cards out in a
/// grid; below it, one column. The Resume card keeps the full width either
/// way. Home's own breakpoint: the board has none since its lanes size
/// themselves (`wip/done/2026-09-18-home-master-detail.md`).
const double kHomeGridBreakpoint = 600;

/// The width a grid column aims for: as many columns as fit cards at least
/// this wide, and never fewer than two above [kHomeGridBreakpoint].
const double kHomeGridMinCardWidth = 360;

/// The gap between two cards, across and down.
const double _kCardGap = 12;

/// How many columns of game cards a home screen [width] dp wide shows: one
/// below [kHomeGridBreakpoint], then as many cards of at least
/// [kHomeGridMinCardWidth] as fit the padded width, and never fewer than two.
int homeGridColumns(double width) {
  if (width < kHomeGridBreakpoint) return 1;
  final content = width - 32; // the list's 16 dp side padding
  final fit =
      ((content + _kCardGap) / (kHomeGridMinCardWidth + _kCardGap)).floor();
  return fit < 2 ? 2 : fit;
}

/// A rounded status label on a game card.
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.background, required this.child, this.tooltip});

  final Color background;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.boardBuilder});

  /// Injected by tests only: the board a game opens on. The default
  /// `GameBoardScreen` reaches the `AppDatabase` singleton.
  final WidgetBuilder? boardBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedGameTypeId; // null = tous les jeux

  WidgetBuilder get _board =>
      widget.boardBuilder ?? (context) => const GameBoardScreen();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadGames();
      context.read<GameTypeProvider>().loadGameTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          Badge(
            isLabelVisible: _selectedGameTypeId != null,
            offset: const Offset(-4, 4),
            child: IconButton(
              icon: const Icon(Icons.filter_alt),
              tooltip: l10n.filterGames,
              onPressed: _showFilterBottomSheet,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: l10n.playerStatistics,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayerStatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildGameList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGameScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.newGame),
      ),
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: withBottomInset(context, EdgeInsets.zero),
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'store_listing/assets/icon_512.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CountScore',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n.homeTitle),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(l10n.playersListTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.games),
            title: Text(l10n.gameTypesTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameTypesScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settingsTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.aboutTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    int? tempSelectedGameTypeId = _selectedGameTypeId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Consumer<GameTypeProvider>(
              builder: (context, gameTypeProvider, child) {
                final gameTypes = sortGameTypesByDisplayName(
                    l10n, gameTypeProvider.gameTypes);

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.filterGames,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.selectGameType,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: RadioGroup<int?>(
                            groupValue: tempSelectedGameTypeId,
                            onChanged: (value) {
                              setModalState(() {
                                tempSelectedGameTypeId = value;
                              });
                            },
                            child: Column(
                              children: [
                                RadioListTile<int?>(
                                  title: Text(l10n.allGames),
                                  value: null,
                                ),
                                ...gameTypes.map((gameType) {
                                  return RadioListTile<int?>(
                                    title: Row(
                                      children: [
                                        Icon(
                                          gameType.icon,
                                          size: 24,
                                          color: gameType.cardColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(gameTypeDisplayName(l10n, gameType)),
                                      ],
                                    ),
                                    value: gameType.id,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedGameTypeId = null;
                                });
                                Navigator.pop(context);
                              },
                              child: Text(l10n.resetFilter),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedGameTypeId = tempSelectedGameTypeId;
                                });
                                Navigator.pop(context);
                              },
                              child: Text(l10n.applyFilter),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGameList() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<GameProvider, GameTypeProvider>(
      builder: (context, gameProvider, gameTypeProvider, child) {
        var games = gameProvider.games;

        // Filtrer par type de jeu si nécessaire
        if (_selectedGameTypeId != null) {
          games = games.where((game) => game.gameTypeId == _selectedGameTypeId).toList();
        }

        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.style,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedGameTypeId == null ? l10n.noGames : l10n.noGamesOfThisType,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createFirstGame,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
            ),
          );
        }

        final resume = resumableGame(games);
        final rest = [
          for (final game in games)
            if (!identical(game, resume)) game,
        ];

        return LayoutBuilder(builder: (context, constraints) {
          final columns = homeGridColumns(constraints.maxWidth);
          // Between the breakpoint and two full cards, a grid card is
          // narrower than a phone's: its status pill moves under the name.
          final cardWidth =
              (constraints.maxWidth - 32 - (columns - 1) * _kCardGap) /
                  columns;
          final compact = columns > 1 && cardWidth < kHomeGridMinCardWidth;
          Widget card(Game game) => _buildGameCard(context, game,
              gameTypeProvider.getGameTypeById(game.gameTypeId), gameProvider,
              compact: compact);
          return ListView(
            // The bottom 88 keeps the last card clear of the extended FAB.
            padding: withBottomInset(
                context, const EdgeInsets.fromLTRB(16, 8, 16, 88)),
            children: [
              if (resume != null)
                _buildResumeHero(context, resume,
                    gameTypeProvider.getGameTypeById(resume.gameTypeId),
                    gameProvider),
              if (rest.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: 4, top: resume != null ? 24 : 8, bottom: 12),
                  child: Text(
                    l10n.recentGames.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (columns == 1)
                  for (final game in rest)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _kCardGap),
                      child: card(game),
                    )
                else
                  // Rows of equal-height cards rather than a GridView: a
                  // card is as tall as its content, which a fixed aspect
                  // ratio would clip or pad.
                  for (var i = 0; i < rest.length; i += columns)
                    Padding(
                      key: Key('homeGridRow${i ~/ columns}'),
                      padding: const EdgeInsets.only(bottom: _kCardGap),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var c = 0; c < columns; c++) ...[
                              if (c > 0) const SizedBox(width: _kCardGap),
                              Expanded(
                                child: i + c < rest.length
                                    ? card(rest[i + c])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          );
        });
      },
    );
  }

  /// "Type · date" under a game's name; the date alone for a game without type.
  String _typeAndDate(BuildContext context, Game game, GameType? gameType) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final date = game.createdAt.year == now.year
        ? DateFormat.MMMd(l10n.localeName).format(game.createdAt)
        : DateFormat.yMMMd(l10n.localeName).format(game.createdAt);
    return [
      if (gameType != null) gameTypeDisplayName(l10n, gameType),
      date,
    ].join(' · ');
  }

  Future<void> _openBoard(
      BuildContext context, Game game, GameProvider gameProvider) async {
    await gameProvider.loadGame(game.id!);
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: _board));
    }
  }

  /// The most recently played open game, one tap from its board: its name,
  /// type and round, the leader and the players.
  Widget _buildResumeHero(BuildContext context, Game game, GameType? gameType,
      GameProvider gameProvider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    // Light: the brand teal itself. Dark: a teal-tinted surface, so the card
    // does not glare; the button carries the accent instead.
    final background = dark
        ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.16),
            theme.cardTheme.color ?? scheme.surface)
        : scheme.primary;
    final foreground = dark ? scheme.onSurface : scheme.onPrimary;
    final rounds = gameProvider.roundCountOf(game.id!);
    final subtitle = [
      if (gameType != null) gameTypeDisplayName(l10n, gameType),
      if (rounds > 0) l10n.roundNumber(rounds),
    ].join(' · ');

    return Material(
      key: const Key('resumeHero'),
      color: background,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openBoard(context, game, gameProvider),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(gameType?.icon ?? Icons.sports_esports,
                      color: foreground, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: foreground),
                    ),
                  ),
                  if (game.isShared)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: l10n.gameSharedBadge,
                        child: Icon(Icons.cloud_done_outlined,
                            size: 18, color: foreground),
                      ),
                    ),
                  _buildGameMenu(context, game, gameProvider,
                      iconColor: foreground),
                ],
              ),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4, end: 12),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground.withValues(alpha: 0.85)),
                  ),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: FutureBuilder<GameStanding>(
                  future: gameProvider.standingOf(game),
                  builder: (context, snapshot) {
                    final standing = snapshot.data;
                    // Nobody is named on a tie for the lead.
                    final leader = standing?.soleLeader;
                    return Row(
                      children: [
                        // Ringed in the text colour: a teal or cyan player
                        // would vanish into the teal hero otherwise.
                        PlayerAvatarStack(
                          key: const Key('resumeHeroAvatars'),
                          players: standing?.players ?? const [],
                          size: 32,
                          maxShown: 4,
                          borderColor: foreground,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: leader == null
                              ? const SizedBox.shrink()
                              : Text(
                                  l10n.gameLeader(
                                      leader.name, standing!.totalOf(leader)),
                                  key: const Key('resumeHeroLeader'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(color: foreground),
                                ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                dark ? scheme.primary : scheme.onPrimary,
                            foregroundColor:
                                dark ? scheme.onPrimary : scheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 14),
                          ),
                          onPressed: () =>
                              _openBoard(context, game, gameProvider),
                          child: Text(l10n.resumeGame),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A game card. [compact] puts the status pill beside the players rather
  /// than beside the name, for a grid card narrower than
  /// [kHomeGridMinCardWidth].
  Widget _buildGameCard(BuildContext context, Game game, GameType? gameType,
      GameProvider gameProvider,
      {bool compact = false}) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final gameColor = gameType?.cardColor ?? scheme.primary;
    final gameIcon = gameType?.icon ?? Icons.sports_esports;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openBoard(context, game, gameProvider),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 4, 16),
          child: FutureBuilder<GameStanding>(
            future: gameProvider.standingOf(game),
            builder: (context, snapshot) {
              final standing = snapshot.data;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The game's colour lives in this tile only: the card
                  // itself stays white, so amber does not turn to beige.
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: gameColor.withValues(alpha: dark ? 0.2 : 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(gameIcon, color: gameColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                game.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            if (game.isShared) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: l10n.gameSharedBadge,
                                child: Icon(
                                  Icons.cloud_done_outlined,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _typeAndDate(context, game, gameType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (standing != null && standing.players.isEmpty)
                              Text(l10n.noPlayers,
                                  style: theme.textTheme.bodySmall)
                            else
                              PlayerAvatarStack(
                                  players: standing?.players ?? const []),
                            if (compact)
                              _buildStatusPill(context, game, standing),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      // Bounds the pill, whose winner name is Flexible; at
                      // most 140 dp wide, so the bound never bites.
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: _buildStatusPill(context, game, standing),
                      ),
                    ),
                  ],
                  _buildGameMenu(context, game, gameProvider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// "In progress" on an open game; the winner, or "Finished" when nobody
  /// scored, on a finished one.
  Widget _buildStatusPill(
      BuildContext context, Game game, GameStanding? standing) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelLarge;

    if (!game.isFinished) {
      return _Pill(
        key: const Key('statusInProgress'),
        background: scheme.primary.withValues(alpha: 0.14),
        child: Text(l10n.gameInProgress,
            style: style?.copyWith(color: scheme.primary)),
      );
    }
    // A tie for the lead names no single winner: the flag and "Finished",
    // with every tied player in the tooltip, as the end screen names them.
    final winner = standing?.soleLeader;
    final tied = winner == null ? standing?.leaders ?? const [] : const [];
    final muted = scheme.onSurfaceVariant;
    return _Pill(
      key: const Key('statusFinished'),
      background: scheme.surfaceContainerHighest,
      tooltip: winner != null
          ? l10n.gameWonBy(winner.name)
          : tied.length > 1
              ? l10n.gameEndTie(tied.map((p) => p.name).join(', '))
              : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(winner == null ? Icons.flag_outlined : Icons.emoji_events_outlined,
              size: 16, color: muted),
          const SizedBox(width: 4),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                winner?.name ?? l10n.gameFinished,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(color: muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameMenu(
    BuildContext context,
    Game game,
    GameProvider gameProvider, {
    Color? iconColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // A game with no round yet was never played, so there is nothing to declare
    // over — the same rule the board applies, and the one that keeps an empty
    // game out of the review prompt's count. Reopening stays offered whatever
    // the rounds.
    final canFinish = game.isFinished || gameProvider.roundCountOf(game.id!) > 0;

    return PopupMenuButton(
      iconColor: iconColor,
      itemBuilder: (context) => [
        // The same action under two names: on a finished game it is
        // the next game of the evening.
        PopupMenuItem(
          value: game.isFinished ? 'play_again' : 'new_same',
          child: Row(
            children: [
              Icon(game.isFinished ? Icons.restart_alt : Icons.add_circle_outline),
              const SizedBox(width: 8),
              Text(game.isFinished ? l10n.playAgain : l10n.newWithSamePlayers),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit),
              const SizedBox(width: 8),
              Text(l10n.rename),
            ],
          ),
        ),
        if (canFinish)
          PopupMenuItem(
            value: 'finish_game',
            child: Row(
              children: [
                Icon(game.isFinished ? Icons.replay : Icons.flag_outlined),
                const SizedBox(width: 8),
                Text(game.isFinished ? l10n.reopenGame : l10n.endGame),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleGameMenuAction(context, value, game, gameProvider),
    );
  }

  Future<void> _handleGameMenuAction(
    BuildContext context,
    dynamic value,
    Game game,
    GameProvider gameProvider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (value == 'finish_game') {
      // Captured before the await: the card this menu belongs to may be gone
      // from the tree by the time the write returns.
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final gameId = game.id!;
      final finished = !game.isFinished;
      final justFinished = await gameProvider.setGameFinished(gameId, finished);
      // Same guard as the board: only a game that was open and now is not
      // is a moment to consider the review prompt, which counts finished
      // games from the database itself.
      if (justFinished) {
        unawaited(ReviewPromptService.instance.onGameFinished());
      }
      if (finished) {
        // Who won, rather than a snackbar that never said: the standings
        // read the current game, so it is loaded first.
        await gameProvider.loadGame(gameId);
        await navigator.push(MaterialPageRoute(
          builder: (_) => StandingsScreen(boardBuilder: widget.boardBuilder),
        ));
        return;
      }
      // Reopening is reversible, so say what happened and offer it back.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(undoSnackBar(
          message: l10n.gameReopened,
          undoLabel: l10n.undo,
          onUndo: () => gameProvider.setGameFinished(gameId, true),
        ));
    } else if (value == 'new_same' || value == 'play_again') {
      await playAgain(context, game, board: _board);
    } else if (value == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmDeletion),
          content: Text(l10n.confirmDeleteGame(game.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        await gameProvider.deleteGame(game.id!);
      }
    } else if (value == 'rename') {
      final controller = TextEditingController(text: game.name);
      final newName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.renameGame),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.gameName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.save),
            ),
          ],
        ),
      );

      if (newName != null && newName.isNotEmpty && context.mounted) {
        await gameProvider.updateGameName(game.id!, newName);
      }
    }
  }
}
