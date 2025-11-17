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
              if (value == 'delete_round' && gameProvider.currentRounds.isNotEmpty) {
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
