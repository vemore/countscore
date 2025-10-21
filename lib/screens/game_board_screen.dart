import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'ranking_screen.dart';

class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            return Text(gameProvider.currentGame?.name ?? 'Partie');
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
              const PopupMenuItem(
                value: 'delete_round',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Supprimer dernier tour'),
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
                    title: const Text('Confirmer'),
                    content: const Text('Supprimer le dernier tour ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer'),
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
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final players = gameProvider.currentPlayers;
          final rounds = gameProvider.currentRounds;

          if (players.isEmpty) {
            return const Center(
              child: Text('Aucun joueur dans cette partie'),
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
                      columnSpacing: 40,
                      headingRowHeight: 56,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 48,
                      columns: [
                        const DataColumn(
                          label: Text(
                            'Tour',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...players.map((player) {
                          return DataColumn(
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: ${gameProvider.getPlayerTotal(player.id!)}',
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
                              return DataCell(
                                InkWell(
                                  onTap: () {
                                    _showScoreDialog(
                                      context,
                                      player.name,
                                      round.roundNumber,
                                      score ?? 0,
                                      (newScore) {
                                        gameProvider.updateScore(
                                          player.id!,
                                          round.id!,
                                          newScore,
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: score != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.3)
                                          : null,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      score?.toString() ?? '-',
                                      style: TextStyle(
                                        fontWeight: score != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
                    label: const Text('Ajouter un tour'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showScoreDialog(
    BuildContext context,
    String playerName,
    int roundNumber,
    int currentScore,
    Function(int) onScoreUpdated,
  ) {
    final controller = TextEditingController(
      text: currentScore == 0 ? '' : currentScore.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$playerName - Tour $roundNumber'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
          ],
          decoration: const InputDecoration(
            labelText: 'Score',
            border: OutlineInputBorder(),
            hintText: 'Entrez le score',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final score = int.tryParse(value) ?? 0;
              onScoreUpdated(score);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                final score = int.tryParse(value) ?? 0;
                onScoreUpdated(score);
              } else {
                onScoreUpdated(0);
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
