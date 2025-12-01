import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../models/game.dart';
import '../models/game_type.dart';
import '../services/database_service.dart';
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
                final gameTypes = gameTypeProvider.gameTypes;

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
                                        Text(gameType.name),
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
    final l10n = AppLocalizations.of(context)!;
    final cardColor = gameType?.cardColor ?? Colors.deepPurple;
    final gameIcon = gameType?.icon ?? Icons.sports_esports;

    return FutureBuilder<List<dynamic>>(
      future: _getGamePlayers(gameProvider, game.id!),
      builder: (context, snapshot) {
        final players = snapshot.data ?? [];

        return Card(
          color: cardColor.withValues(alpha: 0.1),
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
                  '${l10n.createdOn} ${_formatDate(game.createdAt)}',
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
                PopupMenuItem(
                  value: 'new_same',
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline),
                      const SizedBox(width: 8),
                      Text(l10n.newWithSamePlayers),
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
    final l10n = AppLocalizations.of(context)!;

    if (players.isEmpty) {
      return Text(l10n.noPlayers, style: const TextStyle(fontSize: 12));
    }

    final names = players.join(', ');
    final displayText = l10n.playersListSummary(players.length, names);

    return Text(
      displayText,
      style: const TextStyle(fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<List<String>> _getGamePlayers(GameProvider provider, int gameId) async {
    final db = DatabaseService.instance;
    final players = await db.getPlayersByGame(gameId);
    return players.map((player) => player.name).toList();
  }

  Future<void> _handleGameMenuAction(
    BuildContext context,
    dynamic value,
    Game game,
    GameProvider gameProvider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (value == 'new_same') {
      await gameProvider.loadGame(game.id!);
      final playerNames = gameProvider.currentPlayers.map((p) => p.name).toList();

      // Récupérer les couleurs des joueurs actuels
      final playerColorsMap = <String, int?>{};
      for (final player in gameProvider.currentPlayers) {
        playerColorsMap[player.name] = player.colorValue;
      }

      final newGameId = await gameProvider.createGame(
        '${game.name} ${l10n.newGameSuffix}',
        game.gameTypeId,
        game.isLowestScoreWins,
        playerNames,
        playerColorsMap,
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
