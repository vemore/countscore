import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_standing.dart';
import '../models/game_type.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/game_type_name.dart';
import '../utils/player_colors.dart';
import '../utils/undo_snack_bar.dart';
import '../repositories/drift/drift_repositories.dart';
import '../repositories/game_analysis_repository.dart';
import '../services/drift/database.dart';
import '../services/game_over_dismissals.dart';
import '../services/review_prompt.dart';
import '../widgets/board_lanes.dart';
import '../widgets/board_rows.dart';
import '../widgets/dice_roller_dialog.dart';
import '../widgets/score_keypad_sheet.dart';
import '../widgets/who_starts_dialog.dart';
import 'game_analysis_screen.dart';
import 'game_end_screen.dart';
import 'game_rules_screen.dart';
import 'ranking_screen.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key, this.analysisRepo});

  /// Injected by tests only, as `GameProvider`'s repositories are: the default
  /// reaches the `AppDatabase` singleton, which opens the real database.
  final GameAnalysisRepository? analysisRepo;

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  // Track eliminated players to play sound only once
  final Set<int> _eliminatedPlayers = {};

  late final GameAnalysisRepository _analysisRepo =
      widget.analysisRepo ?? DriftGameAnalysisRepository(AppDatabase.instance);

  /// Whether the end screen was already raised by the rule, or answered
  /// "Continue playing", for the crossing currently in force.
  ///
  /// It re-arms as soon as the condition is false again — a deleted round or a
  /// corrected score puts the game back under its threshold, and crossing it
  /// once more is a new event worth asking about.
  ///
  /// A "Continue playing" is also written to [GameOverDismissals], on this
  /// device only, and read back into this flag by [_dismissalLoaded] — so
  /// leaving the board and coming back does not ask again.
  bool _gameOverDismissed = false;

  /// The stored "Continue playing" for this game, read once when the board
  /// opens. Every check awaits it, so a round added in the first frames cannot
  /// ask a question the user already answered.
  late final Future<void> _dismissalLoaded = _loadDismissal();

  /// Whether this game already has an analysis stored locally. It keeps the
  /// menu entry available after the server is cleared: the generated text is
  /// local data, and this screen is the only way to reach it.
  bool _hasCachedAnalysis = false;

  late final GameProvider _gameProvider = context.read<GameProvider>();

  /// The layout when no [SettingsProvider] is above the board (tests only);
  /// otherwise the app-wide setting is the one read and written.
  BoardView _localView = BoardView.lanes;

  BoardView _boardView(BuildContext context, {bool listen = true}) =>
      Provider.of<SettingsProvider?>(context, listen: listen)?.boardView ??
      _localView;

  void _toggleBoardView(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context, listen: false);
    final next = _boardView(context, listen: false) == BoardView.lanes
        ? BoardView.rows
        : BoardView.lanes;
    if (settings != null) {
      settings.setBoardView(next);
    } else {
      setState(() => _localView = next);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCachedAnalysis();
      _checkGameOverOnOpen();
    });
    _gameProvider.addListener(_closeIfDeletedElsewhere);
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_closeIfDeletedElsewhere);
    super.dispose();
  }

  /// A shared game deleted on another device leaves nothing to show here.
  void _closeIfDeletedElsewhere() {
    final name = _gameProvider.takeRemotelyDeletedGameName();
    if (name == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.gameDeletedElsewhere(name))));
  }

  Future<void> _loadDismissal() async {
    final uuid = _gameProvider.currentGame?.uuid;
    if (uuid == null) return;
    if (await GameOverDismissals.isDismissed(uuid)) _gameOverDismissed = true;
  }

  /// A game can be past its threshold before the board opens — crossed on
  /// another device, or in a session that ended without an answer. It is asked
  /// about once here, unless the user already chose to keep playing. A finished
  /// game has had its answer.
  Future<void> _checkGameOverOnOpen() async {
    final game = _gameProvider.currentGame;
    if (game == null || game.isFinished) return;
    final typeId = game.gameTypeId;
    final gameType = typeId == null
        ? null
        : context.read<GameTypeProvider>().getGameTypeById(typeId);
    await _maybeShowGameOver(_gameProvider, gameType);
  }

  Future<void> _refreshCachedAnalysis() async {
    final gameId = context.read<GameProvider>().currentGame?.id;
    if (gameId == null) return;
    final has = await _analysisRepo.getByGame(gameId) != null;
    if (!mounted || has == _hasCachedAnalysis) return;
    setState(() => _hasCachedAnalysis = has);
  }

  Future<void> _shareGame(GameProvider gameProvider, GroupProvider group) async {
    final l10n = AppLocalizations.of(context)!;
    final game = gameProvider.currentGame;
    if (game == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareWithGroup),
        content: Text(l10n.shareGameConfirm(group.groupName ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.shareWithGroup),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await group.shareGame(game.id!);
      await gameProvider.loadGame(game.id!);
      messenger.showSnackBar(SnackBar(content: Text(l10n.gameSharedDone)));
    } on GroupActionException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.invalidPlayerNamesForSync(e.detail.join(', '))),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final game = gameProvider.currentGame;
            return Row(
              children: [
                Flexible(child: Text(game?.name ?? l10n.game, overflow: TextOverflow.ellipsis)),
                if (game?.isShared ?? false) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.gameSharedBadge,
                    child: const Icon(Icons.cloud_done_outlined, size: 20),
                  ),
                ],
                // The list shows a finished game as finished; the board used to
                // show nothing at all, so the two disagreed about a fact one of
                // them was willing to display. Nothing is locked — a finished
                // game still takes rounds and score edits.
                if (game?.isFinished ?? false) ...[
                  const SizedBox(width: 8),
                  Chip(
                    key: const Key('board_finished_badge'),
                    label: Text(l10n.gameFinished),
                    avatar: const Icon(Icons.flag, size: 16),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Builder(builder: (context) {
            final rows = _boardView(context) == BoardView.rows;
            return IconButton(
              key: const Key('board_view_toggle'),
              isSelected: rows,
              tooltip: rows ? l10n.boardViewLanes : l10n.boardViewRows,
              icon: const Icon(Icons.table_rows_outlined),
              selectedIcon: const Icon(Icons.view_column_outlined),
              onPressed: () => _toggleBoardView(context),
            );
          }),
          // A finished game's end screen, one tap away.
          Consumer<GameProvider>(
            builder: (context, gameProvider, child) =>
                (gameProvider.currentGame?.isFinished ?? false)
                    ? IconButton(
                        key: const Key('board_game_end'),
                        tooltip: l10n.gameEndResults,
                        icon: const Icon(Icons.emoji_events_outlined),
                        onPressed: _openGameEnd,
                      )
                    : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: l10n.ranking,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RankingScreen(),
                ),
              );
            },
          ),
          Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              // The analysis is the app's only network call, so generating
              // one needs a server the user configured. An analysis already
              // stored stays reachable without one — it is local data.
              // Every game type is analysable: the rules of the game travel in
              // the payload, so a type the user invented reads as well as a
              // seeded one.
              final canAnalyse = context.watch<BackendProvider>().isConfigured ||
                  _hasCachedAnalysis;
              final group = context.watch<GroupProvider>();
              final canShare = group.isJoined &&
                  !(gameProvider.currentGame?.isShared ?? true);
              // A game with no round yet was never played, so there is nothing
              // to declare over. Reopening stays offered whatever the rounds.
              final isFinished = gameProvider.currentGame?.isFinished ?? false;
              final canFinish =
                  isFinished || gameProvider.currentRounds.isNotEmpty;
              // Only the rules entry needs the type itself; a game whose type
              // was deleted has gameTypeId NULL and has no rules to show.
              final gameTypeId = gameProvider.currentGame?.gameTypeId;
              final menuGameType = gameTypeId == null
                  ? null
                  : context.watch<GameTypeProvider>().getGameTypeById(gameTypeId);

              return PopupMenuButton<String>(
                itemBuilder: (context) => [
                  if (menuGameType != null)
                    PopupMenuItem(
                      value: 'game_rules',
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_outlined),
                          const SizedBox(width: 8),
                          Text(l10n.gameRulesTitle),
                        ],
                      ),
                    ),
                  if (gameProvider.currentPlayers.isNotEmpty)
                    PopupMenuItem(
                      value: 'who_starts',
                      child: Row(
                        children: [
                          const Icon(Icons.casino_outlined),
                          const SizedBox(width: 8),
                          Text(l10n.whoStarts),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'roll_dice',
                    child: Row(
                      children: [
                        const Icon(Icons.casino),
                        const SizedBox(width: 8),
                        Text(l10n.diceRoller),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit_game',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        Text(l10n.editGame),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_round',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 8),
                        Text(l10n.deleteLastRound),
                      ],
                    ),
                  ),
                  if (canFinish)
                    PopupMenuItem(
                      value: 'finish_game',
                      child: Row(
                        children: [
                          Icon(isFinished
                              ? Icons.replay
                              : Icons.flag_outlined),
                          const SizedBox(width: 8),
                          Text(isFinished ? l10n.reopenGame : l10n.endGame),
                        ],
                      ),
                    ),
                  if (canShare)
                    PopupMenuItem(
                      value: 'share_game',
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined),
                          const SizedBox(width: 8),
                          Text(l10n.shareWithGroup),
                        ],
                      ),
                    ),
                  if (canAnalyse)
                    PopupMenuItem(
                      value: 'analyze_game',
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome),
                          const SizedBox(width: 8),
                          Text(l10n.analyzeGame),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) async {
                  if (value == 'game_rules' && menuGameType != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameRulesScreen(gameType: menuGameType),
                      ),
                    );
                  } else if (value == 'who_starts') {
                    await WhoStartsDialog.show(
                      context,
                      [for (final p in gameProvider.currentPlayers) p.name],
                    );
                  } else if (value == 'roll_dice') {
                    await DiceRollerDialog.show(context);
                  } else if (value == 'edit_game') {
                    _showEditGameDialog();
                  } else if (value == 'delete_round' &&
                      gameProvider.currentRounds.isNotEmpty) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.confirm),
                        content: Text(l10n.confirmDeleteLastRound),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final lastRound = gameProvider.currentRounds.last;
                      await gameProvider.deleteRound(lastRound.id!);
                      // Removing a round can take the game back under its
                      // threshold, or leave it over one it was already past.
                      await _maybeShowGameOver(gameProvider, menuGameType);
                    }
                  } else if (value == 'finish_game') {
                    final gameId = gameProvider.currentGame?.id;
                    if (gameId == null) return;
                    if (!isFinished) {
                      await _finishAndShowEnd(byRule: false);
                      return;
                    }
                    // Captured before the await, as everywhere else on this
                    // screen: the messenger outlives this closure's context.
                    final messenger = ScaffoldMessenger.of(context);
                    await gameProvider.setGameFinished(gameId, false);
                    // Reopening is reversible, so it is offered back.
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(undoSnackBar(
                        message: l10n.gameReopened,
                        undoLabel: l10n.undo,
                        onUndo: () =>
                            gameProvider.setGameFinished(gameId, true),
                      ));
                  } else if (value == 'share_game') {
                    await _shareGame(gameProvider, group);
                  } else if (value == 'analyze_game') {
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameAnalysisScreen(),
                      ),
                    );
                    await _refreshCachedAnalysis();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<GameProvider, GameTypeProvider>(
        builder: (context, gameProvider, gameTypeProvider, child) {
          final players = gameProvider.currentPlayers;
          final rounds = gameProvider.currentRounds;
          final gameType = gameProvider.currentGame?.gameTypeId != null
              ? gameTypeProvider.getGameTypeById(gameProvider.currentGame!.gameTypeId!)
              : null;

          if (players.isEmpty) {
            return Center(
              child: Text(l10n.noPlayersInGame),
            );
          }

          // No leader, no place, until a score has been entered.
          final hasScores = players.any((p) =>
              rounds.any((r) => gameProvider.getScore(p.id!, r.id!) != null));
          final board = BoardData(
            players: players,
            rounds: rounds,
            scoreOf: gameProvider.getScore,
            standing: GameStanding(
              players: players,
              totals: hasScores
                  ? {for (final p in players) p.id!: gameProvider.getPlayerTotal(p.id!)}
                  : const {},
              isLowestScoreWins:
                  gameProvider.currentGame?.isLowestScoreWins ?? false,
            ),
            colors: playerColorsById(players),
            isEliminated: (total) => gameType?.isEliminated(total) ?? false,
            isNearThreshold: (total) =>
                gameType?.isNearElimination(total) ?? false,
            onRoundTap: (round) =>
                _showCommentDialog(context, gameProvider, round),
            onCellTap: (player, round) =>
                _editScore(gameProvider, gameType, player, round),
          );

          return Column(
            children: [
              Expanded(
                child: _boardView(context) == BoardView.rows
                    ? BoardRows(data: board)
                    : BoardLanes(data: board),
              ),

              // Bouton ajouter tour
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('board_add_round'),
                      onPressed: () => _enterRound(gameProvider, gameType),
                      icon: const Icon(Icons.add),
                      label: Text(
                          l10n.boardRoundButton(gameProvider.nextRoundNumber)),
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

  bool _checkGameOverCondition(GameProvider gameProvider, GameType? gameType) {
    if (gameType?.gameOverConditionType == null || gameType?.gameOverThreshold == null) {
      return false;
    }

    final players = gameProvider.currentPlayers;
    final playerTotals = players.map((p) => gameProvider.getPlayerTotal(p.id!)).toList();
    return gameType!.isGameOver(playerTotals);
  }

  /// Opens the end screen once per crossing of the threshold.
  ///
  /// Every mutation that can change a total calls this — a score edit, a round
  /// added, a round deleted — and so does the board's first build
  /// ([_checkGameOverOnOpen]). The stored "Continue playing" is dropped as soon
  /// as the condition is false, so the next crossing asks again.
  Future<void> _maybeShowGameOver(
      GameProvider gameProvider, GameType? gameType) async {
    await _dismissalLoaded;
    if (!mounted) return;
    if (!_checkGameOverCondition(gameProvider, gameType)) {
      _gameOverDismissed = false;
      final uuid = gameProvider.currentGame?.uuid;
      if (uuid != null) await GameOverDismissals.clear(uuid);
      return;
    }
    // A finished game has had its end screen; the app bar keeps it one tap
    // away.
    if (_gameOverDismissed || (gameProvider.currentGame?.isFinished ?? false)) {
      return;
    }
    _gameOverDismissed = true;
    // A slight delay so the table shows the new total before the end screen
    // covers it.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) unawaited(_finishAndShowEnd(byRule: true));
    });
  }

  void _showEditGameDialog() {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();

    if (gameProvider.currentGame == null) return;

    final gameNameController = TextEditingController(text: gameProvider.currentGame!.name);
    int? selectedGameTypeId = gameProvider.currentGame!.gameTypeId;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.editGameDialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Nom de la partie
                    Text(
                      l10n.gameName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gameNameController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: l10n.gameName,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Type de jeu
                    Text(
                      l10n.gameType,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedGameTypeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(l10n.none),
                        ),
                        ...sortGameTypesByDisplayName(
                                l10n, gameTypeProvider.gameTypes)
                            .map((gameType) {
                          return DropdownMenuItem<int?>(
                            value: gameType.id,
                            child: Row(
                              children: [
                                Icon(gameType.icon, size: 20, color: gameType.cardColor),
                                const SizedBox(width: 8),
                                Text(gameTypeDisplayName(l10n, gameType)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGameTypeId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section: Joueurs
                    Text(
                      l10n.players,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...gameProvider.currentPlayers.map((player) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: player.colorValue != null
                                ? Color(player.colorValue!)
                                : Colors.grey,
                            child: Text(
                              player.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(player.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            tooltip: l10n.removePlayer,
                            onPressed: () async {
                              final confirmRemove = await showDialog<bool>(
                                context: dialogContext,
                                builder: (confirmContext) => AlertDialog(
                                  title: Text(l10n.removePlayer),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.warningRemovePlayer),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.confirmRemovePlayer(player.name),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(confirmContext, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(confirmContext, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text(l10n.removePlayer),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmRemove == true && dialogContext.mounted) {
                                await gameProvider.deletePlayer(player.id!);
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(content: Text(l10n.playerRemoved)),
                                  );
                                  setDialogState(() {}); // Refresh dialog
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final playerName = await _showAddPlayerDialog(dialogContext);
                          if (playerName != null && playerName.isNotEmpty) {
                            await gameProvider.addPlayer(playerName);
                            setDialogState(() {}); // Refresh dialog
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addPlayerToGame),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    // Sauvegarder les modifications
                    final newName = gameNameController.text.trim();
                    if (newName.isNotEmpty && newName != gameProvider.currentGame!.name) {
                      await gameProvider.updateGameName(
                        gameProvider.currentGame!.id!,
                        newName,
                      );
                    }

                    if (selectedGameTypeId != gameProvider.currentGame!.gameTypeId) {
                      await gameProvider.updateGameType(
                        gameProvider.currentGame!.id!,
                        selectedGameTypeId,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showAddPlayerDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPlayerToGame),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.newPlayerName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  /// Records the game as finished and opens its end screen.
  ///
  /// [byRule] is the game type's rule ending the game rather than the user:
  /// the screen then offers "Continue playing", which reopens the game and is
  /// remembered on this device for as long as the game stays past its
  /// threshold. Every trigger records the same fact — the board, the rule and
  /// the game list — and the review prompt hears of each game once.
  Future<void> _finishAndShowEnd({required bool byRule}) async {
    final gameProvider = _gameProvider;
    final gameId = gameProvider.currentGame?.id;
    if (gameId == null) return;
    final justFinished = await gameProvider.setGameFinished(gameId, true);
    // Fire and forget: the service owns every guard, and nothing here waits
    // on Play.
    if (justFinished) {
      unawaited(ReviewPromptService.instance.onGameFinished());
    }
    if (!mounted) return;
    await _openGameEnd(offerContinue: byRule);
  }

  /// The end screen of the current game, finished already. `true` back from
  /// it is "Continue playing".
  Future<void> _openGameEnd({bool offerContinue = false}) async {
    final game = _gameProvider.currentGame;
    final continued = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GameEndScreen(offerContinue: offerContinue),
      ),
    );
    final gameId = game?.id;
    if (continued == true && gameId != null) {
      await _gameProvider.setGameFinished(gameId, false);
      final uuid = game?.uuid;
      if (uuid != null) await GameOverDismissals.dismiss(uuid);
    }
    // The end screen may have generated an analysis.
    if (mounted) await _refreshCachedAnalysis();
  }

  bool _isZapZap(GameType? gameType) => gameType?.builtinKey == 'zapzap';

  /// "Round N": the keypad on every player still in the game, in seat order.
  /// The round is written only on "Validate round" — closing the sheet leaves
  /// nothing behind.
  Future<void> _enterRound(
      GameProvider gameProvider, GameType? gameType) async {
    final players = gameProvider.currentPlayers;
    final before = {
      for (final p in players) p.id!: gameProvider.getPlayerTotal(p.id!)
    };
    final inPlay = gameType == null
        ? players
        : [
            for (final p in players)
              if (!gameType.isEliminated(before[p.id]!)) p
          ];
    final scores = await ScoreKeypadSheet.round(
      context,
      players: inPlay.isEmpty ? players : inPlay,
      colors: playerColorsById(players),
      totalsBefore: before,
      roundNumber: gameProvider.nextRoundNumber,
      isZapZap: _isZapZap(gameType),
    );
    if (scores == null || !mounted) return;
    await gameProvider.addRoundWithScores(scores);
    _noteEliminations(gameProvider, gameType, before);
    // Also the moment a game already past its threshold — crossed on another
    // device, or in an earlier session — gets noticed.
    await _maybeShowGameOver(gameProvider, gameType);
  }

  /// A tapped cell: the same keypad, on that one score, with "Save".
  Future<void> _editScore(GameProvider gameProvider, GameType? gameType,
      Player player, Round round) async {
    final players = gameProvider.currentPlayers;
    final roundScores = {
      for (final p in players) p.id!: gameProvider.getScore(p.id!, round.id!)
    };
    final before = {
      for (final p in players) p.id!: gameProvider.getPlayerTotal(p.id!)
    };
    final result = await ScoreKeypadSheet.single(
      context,
      players: players,
      colors: playerColorsById(players),
      totalsBefore: {
        for (final p in players) p.id!: before[p.id]! - (roundScores[p.id] ?? 0)
      },
      roundNumber: round.roundNumber,
      isZapZap: _isZapZap(gameType),
      roundScores: roundScores,
      playerId: player.id!,
    );
    final value = result?[player.id];
    if (value == null || !mounted) return;
    await gameProvider.updateScore(player.id!, round.id!, value);
    _noteEliminations(gameProvider, gameType, before);
    await _maybeShowGameOver(gameProvider, gameType);
  }

  /// Plays the alert once for each player a write just put out of the game,
  /// and forgets a player a correction brought back.
  void _noteEliminations(
      GameProvider gameProvider, GameType? gameType, Map<int, int> before) {
    if (gameType == null || !mounted) return;
    var someoneOut = false;
    setState(() {
      for (final e in before.entries) {
        final was = gameType.isEliminated(e.value);
        final now = gameType.isEliminated(gameProvider.getPlayerTotal(e.key));
        if (!was && now && _eliminatedPlayers.add(e.key)) {
          someoneOut = true;
        } else if (was && !now) {
          _eliminatedPlayers.remove(e.key);
        }
      }
    });
    if (someoneOut) SystemSound.play(SystemSoundType.alert);
  }

  void _showCommentDialog(
    BuildContext context,
    GameProvider gameProvider,
    Round round,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: round.comment ?? '');
    final hasExisting =
        round.comment != null && round.comment!.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.round} ${round.roundNumber} - ${l10n.comment}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.comment,
            hintText: l10n.enterComment,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          if (hasExisting)
            TextButton(
              onPressed: () async {
                await gameProvider.updateRoundComment(round.id!, null);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(
                l10n.delete,
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await gameProvider.updateRoundComment(
                round.id!,
                controller.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
