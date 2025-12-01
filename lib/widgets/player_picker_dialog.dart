import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';

class PlayerSelection {
  final String name;
  final int? colorValue;

  PlayerSelection(this.name, this.colorValue);
}

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
  String _searchQuery = '';
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

  bool get _canCreatePlayer {
    final trimmedQuery = _searchQuery.trim();
    if (trimmedQuery.isEmpty) return false;

    // Vérifier si le nom existe déjà (insensible à la casse)
    return !widget.availablePlayers.any(
      (name) => name.toLowerCase() == trimmedQuery.toLowerCase(),
    );
  }

  Color _generateRandomColor() {
    // Liste de couleurs vives et variées
    final availableColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];

    // Récupérer les valeurs ARGB des couleurs déjà utilisées
    final usedColorValues = _playerColors.values.map((c) => c.toARGB32()).toSet();

    // Filtrer les couleurs non utilisées (en comparant les valeurs ARGB)
    final unusedColors = availableColors
        .where((color) => !usedColorValues.contains(color.toARGB32()))
        .toList();

    // Si toutes les couleurs sont utilisées, choisir une couleur aléatoire
    if (unusedColors.isEmpty) {
      return availableColors[DateTime.now().millisecondsSinceEpoch % availableColors.length];
    }

    // Choisir une couleur aléatoire parmi les couleurs non utilisées
    return unusedColors[DateTime.now().millisecondsSinceEpoch % unusedColors.length];
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
        orderBy: 'id DESC',
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

  void _createNewPlayer() {
    final playerName = _searchQuery.trim();
    if (!_canCreatePlayer) return;

    // Générer une couleur aléatoire
    final color = _generateRandomColor();

    // Ajouter la couleur à la liste locale pour éviter les doublons dans la même session
    setState(() {
      _playerColors[playerName] = color;
    });

    // Fermer le dialog et retourner le joueur avec sa couleur
    Navigator.pop(context, PlayerSelection(playerName, color.toARGB32()));
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                  labelText: l10n.searchOrCreate,
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
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _canCreatePlayer ? _createNewPlayer : null,
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
                        final playerColor = _playerColors[playerName];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: playerColor ?? Colors.blue,
                            child: Text(
                              playerName[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(playerName),
                          onTap: () {
                            Navigator.pop(
                              context,
                              PlayerSelection(
                                playerName,
                                playerColor?.toARGB32(),
                              ),
                            );
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
