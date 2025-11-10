import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playersListTitle)),
      body: _playerNames.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPlayers,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.playersAppearMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
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
                  future: context.read<GameProvider>().getPlayerStats(
                    playerName,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
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
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () async {
                                final newColor = await _showColorPicker(
                                  context,
                                  playerColor,
                                );
                                if (newColor != null) {
                                  await _db.updatePlayerColor(
                                    playerName,
                                    newColor.value,
                                  );
                                  setState(() {}); // Refresh UI
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: playerColor,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              playerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${l10n.gamesCount(gamesPlayed)}\n${l10n.winsCount(wins)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.palette, color: playerColor),
                                  onPressed: () async {
                                    final newColor = await _showColorPicker(
                                      context,
                                      playerColor,
                                    );
                                    if (newColor != null) {
                                      await _db.updatePlayerColor(
                                        playerName,
                                        newColor.value,
                                      );
                                      setState(() {}); // Refresh UI
                                    }
                                  },
                                  tooltip: l10n.changeColor,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showRenameDialog(context, playerName),
                                  tooltip: l10n.rename,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _showDeleteDialog(context, playerName),
                                  tooltip: l10n.delete,
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

  Future<Color?> _showColorPicker(
    BuildContext context,
    Color currentColor,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    Color pickedColor = currentColor;
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.chooseColor),
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
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, pickedColor),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    String playerName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: playerName);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final gameProvider = context.read<GameProvider>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.renamePlayer),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.newName,
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
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != playerName) {
                  Navigator.pop(context, newName);
                }
              },
              child: Text(l10n.rename),
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
          SnackBar(content: Text(l10n.playerRenamedTo(result))),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    String playerName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.read<GameProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final stats = await gameProvider.getPlayerStats(playerName);
    final gamesPlayed = stats['gamesPlayed'] as int;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deletePlayer),
          content: Text(l10n.confirmDeletePlayer(playerName, gamesPlayed)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
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
          SnackBar(content: Text(l10n.playerDeleted(playerName))),
        );
      }
    }
  }
}
