import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../providers/theme_provider.dart';
import '../models/game.dart';
import '../models/game_type.dart';
import 'about_screen.dart';
import 'create_game_screen.dart';
import 'game_board_screen.dart';
import 'game_types_screen.dart';
import 'player_stats_screen.dart';
import 'players_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedGameTypeId; // null = tous les jeux

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
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildGameTypeFilter(),
          Expanded(child: _buildGameList()),
        ],
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.score,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Liste des joueurs'),
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
            title: const Text('Types de jeux'),
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
            title: const Text('Paramètres'),
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
            title: const Text('À propos'),
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

  Widget _buildGameTypeFilter() {
    return Consumer<GameTypeProvider>(
      builder: (context, gameTypeProvider, child) {
        final gameTypes = gameTypeProvider.gameTypes;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<int?>(
            value: _selectedGameTypeId,
            decoration: const InputDecoration(
              labelText: 'Filtrer par type de jeu',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Tous les jeux'),
              ),
              ...gameTypes.map((gameType) {
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
              setState(() {
                _selectedGameTypeId = value;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildGameList() {
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedGameTypeId == null ? 'Aucune partie' : 'Aucune partie de ce type',
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
            final gameType = gameTypeProvider.getGameTypeById(game.gameTypeId);

            return _buildGameCard(context, game, gameType, gameProvider);
          },
        );
      },
    );
  }

  Widget _buildGameCard(BuildContext context, Game game, GameType? gameType, GameProvider gameProvider) {
    final cardColor = gameType?.cardColor ?? Colors.deepPurple;
    final gameIcon = gameType?.icon ?? Icons.sports_esports;

    return FutureBuilder<List<dynamic>>(
      future: _getGamePlayers(gameProvider, game.id!),
      builder: (context, snapshot) {
        final players = snapshot.data ?? [];
        final playerCount = players.length;

        return Card(
          color: cardColor.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(
              gameIcon,
              size: 40,
              color: cardColor,
            ),
            title: Text(
              game.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Créé le ${_formatDate(game.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPlayersList(players),
              ],
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
              onSelected: (value) => _handleGameMenuAction(context, value, game, gameProvider),
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
  }

  Widget _buildPlayersList(List<dynamic> players) {
    if (players.isEmpty) {
      return const Text('Aucun joueur', style: TextStyle(fontSize: 12));
    }

    if (players.length <= 4) {
      return Wrap(
        spacing: 4,
        children: players.map((name) {
          return Chip(
            label: Text(name, style: const TextStyle(fontSize: 11)),
            padding: const EdgeInsets.all(2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      );
    }

    return Text(
      '${players.length} joueurs',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<List<String>> _getGamePlayers(GameProvider provider, int gameId) async {
    final db = provider.getAllPlayerNames();
    // En fait, on doit charger les joueurs de cette partie spécifique
    // Pour l'instant on retourne une liste vide, mais on pourrait améliorer
    return [];
  }

  Future<void> _handleGameMenuAction(
    BuildContext context,
    dynamic value,
    Game game,
    GameProvider gameProvider,
  ) async {
    if (value == 'new_same') {
      await gameProvider.loadGame(game.id!);
      final playerNames = gameProvider.currentPlayers.map((p) => p.name).toList();

      final newGameId = await gameProvider.createGame(
        '${game.name} (nouvelle)',
        game.gameTypeId,
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
          content: Text('Voulez-vous vraiment supprimer la partie "${game.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
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
            decoration: const InputDecoration(labelText: 'Nom de la partie'),
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
  }
}
