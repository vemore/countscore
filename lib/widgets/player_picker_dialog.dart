import 'package:flutter/material.dart';

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
  void dispose() {
    _searchController.dispose();
    _newPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Sélectionner un joueur',
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
                  labelText: 'Rechercher',
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
                              decoration: const InputDecoration(
                                labelText: 'Nom du nouveau joueur',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
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
                                  child: const Text('Annuler'),
                                ),
                                FilledButton.icon(
                                  onPressed: () {
                                    final name = _newPlayerController.text.trim();
                                    if (name.isNotEmpty) {
                                      Navigator.pop(context, name);
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Créer'),
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
                        label: const Text('Créer un nouveau joueur'),
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
                                ? 'Aucun joueur trouvé'
                                : 'Tous les joueurs ont été sélectionnés',
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
                  child: const Text('Fermer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
