import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';

class PlayerPickerDialog extends StatefulWidget {
  final List<String> availablePlayers;
  final List<String> selectedPlayers;

  const PlayerPickerDialog({
    super.key,
    required this.availablePlayers,
    required this.selectedPlayers,
  });

  @override
  State<PlayerPickerDialog> createState() => _PlayerPickerDialogState();
}

class _PlayerPickerDialogState extends State<PlayerPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newPlayerController = TextEditingController();
  String _searchQuery = '';
  bool _showNewPlayerField = false;
  Map<String, Color> _playerColors = {};

  List<String> get _filteredPlayers {
    // Filtrer les joueurs non sélectionnés
    final unselectedPlayers = widget.availablePlayers
        .where((name) => !widget.selectedPlayers.contains(name))
        .toList();

    // Appliquer le filtre de recherche
    if (_searchQuery.isEmpty) {
      return unselectedPlayers;
    }

    return unselectedPlayers
        .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadPlayerColors();
  }

  Future<void> _loadPlayerColors() async {
    final db = await DatabaseService.instance.database;
    final colors = <String, Color>{};

    for (final playerName in widget.availablePlayers) {
      final result = await db.query(
        'players',
        columns: ['colorValue'],
        where: 'name = ?',
        whereArgs: [playerName],
        limit: 1,
      );

      if (result.isNotEmpty && result.first['colorValue'] != null) {
        colors[playerName] = Color(result.first['colorValue'] as int);
      } else {
        colors[playerName] = Colors.blue;
      }
    }

    if (mounted) {
      setState(() {
        _playerColors = colors;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.selectPlayerDialogTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.search,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Bouton créer nouveau joueur
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _showNewPlayerField
                  ? Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _newPlayerController,
                              decoration: InputDecoration(
                                labelText: l10n.newPlayerName,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.person),
                              ),
                              autofocus: true,
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  Navigator.pop(context, value.trim());
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showNewPlayerField = false;
                                      _newPlayerController.clear();
                                    });
                                  },
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton.icon(
                                  onPressed: () {
                                    final name = _newPlayerController.text.trim();
                                    if (name.isNotEmpty) {
                                      Navigator.pop(context, name);
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.create),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showNewPlayerField = true;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(l10n.createNewPlayer),
                      ),
                    ),
            ),

            const Divider(height: 24),

            // Liste des joueurs
            Expanded(
              child: _filteredPlayers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? l10n.noPlayersFound
                                : l10n.allPlayersSelected,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPlayers.length,
                      itemBuilder: (context, index) {
                        final playerName = _filteredPlayers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _playerColors[playerName] ?? Colors.blue,
                            child: Text(
                              playerName[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(playerName),
                          onTap: () {
                            Navigator.pop(context, playerName);
                          },
                        );
                      },
                    ),
            ),

            // Bouton fermer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
