import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import 'ranking_screen.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  // Track eliminated players to play sound only once
  final Set<int> _eliminatedPlayers = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            return Text(gameProvider.currentGame?.name ?? l10n.game);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RankingScreen(),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
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
            ],
            onSelected: (value) async {
              final gameProvider = context.read<GameProvider>();
              if (value == 'edit_game') {
                _showEditGameDialog();
              } else if (value == 'delete_round' && gameProvider.currentRounds.isNotEmpty) {
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
                }
              }
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
          final isZapZap = gameType?.name.toLowerCase() == 'zapzap';

          // Helper function to check if player is eliminated based on game type conditions
          bool isPlayerEliminated(int playerTotal) {
            if (gameType?.playerDeadConditionType == null || gameType?.playerDeadThreshold == null) {
              return false;
            }
            switch (gameType!.playerDeadConditionType!) {
              case PlayerDeadConditionType.over:
                return playerTotal > gameType.playerDeadThreshold!;
              case PlayerDeadConditionType.under:
                return playerTotal < gameType.playerDeadThreshold!;
            }
          }

          if (players.isEmpty) {
            return Center(
              child: Text(l10n.noPlayersInGame),
            );
          }

          return Column(
            children: [
              // Tableau scrollable
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowHeight: 56,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 48,
                      columns: [
                        DataColumn(
                          label: Text(
                            l10n.round,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...players.map((player) {
                          final playerTotal = gameProvider.getPlayerTotal(player.id!);
                          final isEliminated = isPlayerEliminated(playerTotal);

                          return DataColumn(
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isEliminated
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: isEliminated
                                        ? Colors.red
                                        : null,
                                    decorationThickness: isEliminated
                                        ? 2.0
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$playerTotal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      rows: rounds.map((round) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                round.roundNumber.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...players.map((player) {
                              final score = gameProvider.getScore(
                                player.id!,
                                round.id!,
                              );
                              final isZeroScore = isZapZap && score == 0;
                              final cellColor = gameType?.cardColor ?? Theme.of(context).colorScheme.primaryContainer;

                              return DataCell(
                                InkWell(
                                  onTap: () {
                                    _showScoreDialog(
                                      context,
                                      gameProvider,
                                      gameType,
                                      player,
                                      round.roundNumber,
                                      round.id!,
                                      score ?? 0,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: score != null
                                          ? cellColor.withValues(alpha: 0.3)
                                          : null,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      score?.toString() ?? '-',
                                      style: TextStyle(
                                        fontWeight: score != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        decoration: isZeroScore
                                            ? TextDecoration.underline
                                            : null,
                                        decorationColor: isZeroScore
                                            ? cellColor
                                            : null,
                                        decorationThickness: isZeroScore
                                            ? 2.0
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Bouton ajouter tour
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await gameProvider.addRound();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addRound),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isPlayerEliminatedByTotal(int playerTotal, GameType gameType) {
    if (gameType.playerDeadConditionType == null || gameType.playerDeadThreshold == null) {
      return false;
    }
    switch (gameType.playerDeadConditionType!) {
      case PlayerDeadConditionType.over:
        return playerTotal > gameType.playerDeadThreshold!;
      case PlayerDeadConditionType.under:
        return playerTotal < gameType.playerDeadThreshold!;
    }
  }

  bool _checkGameOverCondition(GameProvider gameProvider, GameType? gameType) {
    if (gameType?.gameOverConditionType == null || gameType?.gameOverThreshold == null) {
      return false;
    }

    final players = gameProvider.currentPlayers;
    final playerTotals = players.map((p) => gameProvider.getPlayerTotal(p.id!)).toList();

    switch (gameType!.gameOverConditionType!) {
      case GameOverConditionType.firstPlayerOver:
        return playerTotals.any((total) => total > gameType.gameOverThreshold!);
      case GameOverConditionType.firstPlayerUnder:
        return playerTotals.any((total) => total < gameType.gameOverThreshold!);
      case GameOverConditionType.lastPlayerOver:
        // All players over threshold
        return playerTotals.every((total) => total > gameType.gameOverThreshold!);
      case GameOverConditionType.lastPlayerUnder:
        // All players under threshold
        return playerTotals.every((total) => total < gameType.gameOverThreshold!);
    }
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
                        ...gameTypeProvider.gameTypes.map((gameType) {
                          return DropdownMenuItem<int?>(
                            value: gameType.id,
                            child: Row(
                              children: [
                                Icon(gameType.icon, size: 20, color: gameType.cardColor),
                                const SizedBox(width: 8),
                                Text(gameType.name),
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

  void _showGameOverDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.gameOverTitle),
        content: Text(l10n.gameOverMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.continuePlay),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Return to game list
            },
            child: Text(l10n.endGame),
          ),
        ],
      ),
    );
  }

  void _showScoreDialog(
    BuildContext context,
    GameProvider gameProvider,
    dynamic gameType,
    dynamic player,
    int roundNumber,
    int roundId,
    int currentScore,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: currentScore == 0 ? '' : currentScore.toString(),
    );

    void handleScoreUpdate(int newScore) async {
      final oldTotal = gameProvider.getPlayerTotal(player.id!);

      await gameProvider.updateScore(
        player.id!,
        roundId,
        newScore,
      );

      // Check if player just got eliminated
      if (gameType?.playerDeadConditionType != null && gameType?.playerDeadThreshold != null) {
        final newTotal = gameProvider.getPlayerTotal(player.id!);
        final wasEliminated = _isPlayerEliminatedByTotal(oldTotal, gameType!);
        final isNowEliminated = _isPlayerEliminatedByTotal(newTotal, gameType);

        if (!wasEliminated && isNowEliminated && !_eliminatedPlayers.contains(player.id!)) {
          setState(() {
            _eliminatedPlayers.add(player.id!);
          });
          SystemSound.play(SystemSoundType.alert);
        } else if (wasEliminated && !isNowEliminated && _eliminatedPlayers.contains(player.id!)) {
          setState(() {
            _eliminatedPlayers.remove(player.id!);
          });
        }
      }

      // Check if game over condition is met
      if (_checkGameOverCondition(gameProvider, gameType)) {
        // Use a slight delay to ensure UI updates before showing dialog
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            _showGameOverDialog(context);
          }
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${player.name} - ${l10n.round} $roundNumber'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
          ],
          decoration: InputDecoration(
            labelText: l10n.score,
            border: const OutlineInputBorder(),
            hintText: l10n.enterScore,
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final score = int.tryParse(value) ?? 0;
              handleScoreUpdate(score);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                final score = int.tryParse(value) ?? 0;
                handleScoreUpdate(score);
              } else {
                handleScoreUpdate(0);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
