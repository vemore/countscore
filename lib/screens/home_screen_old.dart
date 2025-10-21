import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import 'create_game_screen.dart';
import 'game_board_screen.dart';
import 'player_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les parties au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CountScore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayerStatsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final games = gameProvider.games;

          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune partie',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre première partie',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      game.isLowestScoreWins
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                  ),
                  title: Text(game.name),
                  subtitle: Text(
                    '${game.gameType} • ${game.isLowestScoreWins ? 'Plus petit score gagne' : 'Plus grand score gagne'}',
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'new_same',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text('Nouvelle avec mêmes joueurs'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Renommer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'new_same') {
                        // Charger les joueurs de la partie actuelle
                        await gameProvider.loadGame(game.id!);
                        final playerNames = gameProvider.currentPlayers
                            .map((p) => p.name)
                            .toList();

                        // Créer une nouvelle partie avec les mêmes joueurs et paramètres
                        final newGameId = await gameProvider.createGame(
                          '${game.name} (nouvelle)',
                          game.gameType,
                          game.isLowestScoreWins,
                          playerNames,
                        );

                        await gameProvider.loadGame(newGameId);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GameBoardScreen(),
                            ),
                          );
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: Text(
                              'Voulez-vous vraiment supprimer la partie "${game.name}" ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
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
                            title: const Text('Renommer la partie'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'Nom de la partie',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, controller.text),
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        );

                        if (newName != null && newName.isNotEmpty && context.mounted) {
                          await gameProvider.updateGameName(game.id!, newName);
                        }
                      }
                    },
                  ),
                  onTap: () async {
                    await gameProvider.loadGame(game.id!);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameBoardScreen(),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
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
        label: const Text('Nouvelle partie'),
      ),
    );
  }
}
