import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../providers/game_provider.dart';
import '../services/database_service.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<String> _playerNames = [];
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final names = await context.read<GameProvider>().getAllPlayerNames();
    setState(() {
      _playerNames = names;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des joueurs'),
      ),
      body: _playerNames.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun joueur',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les joueurs apparaîtront ici une fois\nque vous aurez créé des parties',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _playerNames.length,
              itemBuilder: (context, index) {
                final playerName = _playerNames[index];
                return FutureBuilder<Map<String, dynamic>>(
                  future: context.read<GameProvider>().getPlayerStats(playerName),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(playerName),
                        ),
                      );
                    }

                    final stats = snapshot.data!;
                    final gamesPlayed = stats['gamesPlayed'] as int;
                    final wins = stats['wins'] as int;

                    return FutureBuilder<Color>(
                      future: _getPlayerColor(playerName),
                      builder: (context, colorSnapshot) {
                        final playerColor = colorSnapshot.data ?? Colors.blue;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () async {
                                final newColor = await _showColorPicker(context, playerColor);
                                if (newColor != null) {
                                  await _db.updatePlayerColor(playerName, newColor.value);
                                  setState(() {}); // Refresh UI
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: playerColor,
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                            ),
                            title: Text(
                              playerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '$gamesPlayed partie${gamesPlayed > 1 ? 's' : ''} • $wins victoire${wins > 1 ? 's' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.palette, color: playerColor),
                                  onPressed: () async {
                                    final newColor = await _showColorPicker(context, playerColor);
                                    if (newColor != null) {
                                      await _db.updatePlayerColor(playerName, newColor.value);
                                      setState(() {}); // Refresh UI
                                    }
                                  },
                                  tooltip: 'Changer la couleur',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showRenameDialog(context, playerName),
                                  tooltip: 'Renommer',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _showDeleteDialog(context, playerName),
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Future<Color> _getPlayerColor(String playerName) async {
    // Récupérer la couleur depuis la base de données
    final db = await _db.database;
    final result = await db.query(
      'players',
      columns: ['colorValue'],
      where: 'name = ?',
      whereArgs: [playerName],
      limit: 1,
    );

    if (result.isNotEmpty && result.first['colorValue'] != null) {
      return Color(result.first['colorValue'] as int);
    }

    return Colors.blue; // Couleur par défaut
  }

  Future<Color?> _showColorPicker(BuildContext context, Color currentColor) async {
    Color pickedColor = currentColor;
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir une couleur'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: currentColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
              pickersEnabled: const {
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, pickedColor),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(BuildContext context, String playerName) async {
    final controller = TextEditingController(text: playerName);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final gameProvider = context.read<GameProvider>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renommer le joueur'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nouveau nom',
              border: OutlineInputBorder(),
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
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != playerName) {
                  Navigator.pop(context, newName);
                }
              },
              child: const Text('Renommer'),
            ),
          ],
        );
      },
    );

    if (result != null && result != playerName) {
      await gameProvider.renamePlayer(playerName, result);
      await _loadPlayers();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Joueur renommé en "$result"')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String playerName) async {
    final gameProvider = context.read<GameProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final stats = await gameProvider.getPlayerStats(playerName);
    final gamesPlayed = stats['gamesPlayed'] as int;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le joueur'),
          content: Text(
            'Voulez-vous vraiment supprimer "$playerName" ?\n\n'
            'Ce joueur sera supprimé de toutes les $gamesPlayed partie${gamesPlayed > 1 ? 's' : ''}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await gameProvider.deletePlayerByName(playerName);
      await _loadPlayers();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Joueur "$playerName" supprimé')),
        );
      }
    }
  }
}
