import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final game = gameProvider.currentGame;
          if (game == null) {
            return const Center(
              child: Text('Aucune partie en cours'),
            );
          }

          final ranking = gameProvider.getRanking();

          if (ranking.isEmpty) {
            return const Center(
              child: Text('Aucun score enregistré'),
            );
          }

          return Column(
            children: [
              // Règle de victoire
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      game.isLowestScoreWins
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      game.isLowestScoreWins
                          ? 'Plus petit score gagne'
                          : 'Plus grand score gagne',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des joueurs classés
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    final entry = ranking[index];
                    final player = entry['player'];
                    final total = entry['total'] as int;
                    final position = index + 1;

                    // Icône pour le podium
                    Widget? leadingIcon;
                    Color? cardColor;

                    if (position == 1) {
                      leadingIcon = const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 40,
                      );
                      cardColor = Colors.amber.withOpacity(0.1);
                    } else {
                      leadingIcon = CircleAvatar(
                        child: Text('$position'),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      color: cardColor,
                      child: ListTile(
                        leading: leadingIcon,
                        title: Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            total.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
