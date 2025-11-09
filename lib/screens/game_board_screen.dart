import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import 'ranking_screen.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  // Track players who exceeded 100 to play sound only once
  final Set<int> _playersOver100 = {};

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
      body: Consumer2<GameProvider, GameTypeProvider>(
        builder: (context, gameProvider, gameTypeProvider, child) {
          final players = gameProvider.currentPlayers;
          final rounds = gameProvider.currentRounds;
          final gameType = gameProvider.currentGame?.gameTypeId != null
              ? gameTypeProvider.getGameTypeById(gameProvider.currentGame!.gameTypeId!)
              : null;
          final isZapZap = gameType?.name.toLowerCase() == 'zapzap';

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
                      columnSpacing: 16,
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
                          final playerTotal = gameProvider.getPlayerTotal(player.id!);
                          final isOver100 = isZapZap && playerTotal > 100;

                          return DataColumn(
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isOver100
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: isOver100
                                        ? Colors.red
                                        : null,
                                    decorationThickness: isOver100
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
                                          ? cellColor.withOpacity(0.3)
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
    GameProvider gameProvider,
    dynamic gameType,
    dynamic player,
    int roundNumber,
    int roundId,
    int currentScore,
  ) {
    final controller = TextEditingController(
      text: currentScore == 0 ? '' : currentScore.toString(),
    );

    final isZapZap = gameType?.name.toLowerCase() == 'zapzap';

    void handleScoreUpdate(int newScore) async {
      final oldTotal = gameProvider.getPlayerTotal(player.id!);

      await gameProvider.updateScore(
        player.id!,
        roundId,
        newScore,
      );

      // Check if player just exceeded 100 for ZapZap
      if (isZapZap) {
        final newTotal = gameProvider.getPlayerTotal(player.id!);
        if (oldTotal <= 100 && newTotal > 100 && !_playersOver100.contains(player.id!)) {
          setState(() {
            _playersOver100.add(player.id!);
          });
          SystemSound.play(SystemSoundType.alert);
        } else if (newTotal <= 100 && _playersOver100.contains(player.id!)) {
          setState(() {
            _playersOver100.remove(player.id!);
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${player.name} - Tour $roundNumber'),
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
              handleScoreUpdate(score);
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
                handleScoreUpdate(score);
              } else {
                handleScoreUpdate(0);
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
