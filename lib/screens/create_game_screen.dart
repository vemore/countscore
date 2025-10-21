import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_type.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../widgets/player_picker_dialog.dart';
import 'game_board_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  int? _selectedGameTypeId;
  bool _isLowestScoreWins = true;
  final List<String> _selectedPlayerNames = [];
  List<String> _availablePlayerNames = [];

  @override
  void initState() {
    super.initState();
    _selectedPlayerNames.add('');
    _selectedPlayerNames.add('');
    _loadData();
  }

  Future<void> _loadData() async {
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();

    final names = await gameProvider.getAllPlayerNames();
    await gameProvider.loadGames();
    final games = gameProvider.games;
    await gameTypeProvider.loadGameTypes();

    final gameTypes = gameTypeProvider.gameTypes;

    // Trouver le type de jeu ZapZap par défaut
    final zapzapType = gameTypes.firstWhere(
      (type) => type.name.toLowerCase() == 'zapzap',
      orElse: () => gameTypes.first,
    );

    // Générer le nom de partie par défaut
    String defaultGameName = 'Partie 1';
    if (games.isNotEmpty) {
      defaultGameName = _incrementGameName(games.first.name);
    }

    setState(() {
      _availablePlayerNames = names;
      _selectedGameTypeId = zapzapType.id;
      _isLowestScoreWins = zapzapType.isLowestScoreWins;
      _gameNameController.text = defaultGameName;
    });
  }

  String _incrementGameName(String lastName) {
    // Extraire les chiffres de fin avec RegExp
    final regex = RegExp(r'(\d+)$');
    final match = regex.firstMatch(lastName);

    if (match != null) {
      // Il y a des chiffres à la fin
      final number = int.parse(match.group(1)!);
      final prefix = lastName.substring(0, match.start);
      return '$prefix${number + 1}';
    } else {
      // Pas de chiffres à la fin, ajouter " 1"
      return '$lastName 1';
    }
  }

  void _addPlayerSlot() {
    setState(() {
      _selectedPlayerNames.add('');
    });
  }

  void _removePlayerSlot(int index) {
    if (_selectedPlayerNames.length > 2) {
      setState(() {
        _selectedPlayerNames.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    final playerNames = _selectedPlayerNames
        .where((name) => name.isNotEmpty)
        .toList();

    if (playerNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins 2 joueurs sont requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameProvider = context.read<GameProvider>();
    final gameId = await gameProvider.createGame(
      _gameNameController.text.trim(),
      _selectedGameTypeId,
      _isLowestScoreWins,
      playerNames,
    );

    await gameProvider.loadGame(gameId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GameBoardScreen(),
        ),
      );
    }
  }

  Future<void> _showPlayerPicker(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PlayerPickerDialog(
        availablePlayers: _availablePlayerNames,
        selectedPlayers: _selectedPlayerNames,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPlayerNames[index] = result;
        // Rafraîchir la liste si un nouveau joueur a été créé
        if (!_availablePlayerNames.contains(result)) {
          _availablePlayerNames.add(result);
          _availablePlayerNames.sort();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle partie'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom de la partie
            TextFormField(
              controller: _gameNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la partie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.style),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Type de jeu
            Consumer<GameTypeProvider>(
              builder: (context, gameTypeProvider, child) {
                final gameTypes = gameTypeProvider.gameTypes;

                if (gameTypes.isEmpty) {
                  return const Text('Chargement des types de jeux...');
                }

                return DropdownButtonFormField<int>(
                  value: _selectedGameTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Type de jeu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.casino),
                  ),
                  items: gameTypes.map((GameType type) {
                    return DropdownMenuItem<int>(
                      value: type.id,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 20, color: type.cardColor),
                          const SizedBox(width: 8),
                          Text(type.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      final selectedType = gameTypes.firstWhere((t) => t.id == newValue);
                      setState(() {
                        _selectedGameTypeId = newValue;
                        _isLowestScoreWins = selectedType.isLowestScoreWins;
                      });
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Règle de victoire (affichée seulement si "Autre" est sélectionné)
            Consumer<GameTypeProvider>(
              builder: (context, gameTypeProvider, child) {
                final selectedType = gameTypeProvider.gameTypes
                    .firstWhere((t) => t.id == _selectedGameTypeId,
                        orElse: () => gameTypeProvider.gameTypes.first);

                if (selectedType.name.toLowerCase() != 'autre') {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Règle de victoire',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            RadioListTile<bool>(
                              title: const Text('Plus petit score gagne'),
                              subtitle: const Text('Ex: Golf, Hearts'),
                              value: true,
                              groupValue: _isLowestScoreWins,
                              onChanged: (value) {
                                setState(() {
                                  _isLowestScoreWins = value!;
                                });
                              },
                            ),
                            RadioListTile<bool>(
                              title: const Text('Plus grand score gagne'),
                              subtitle: const Text('Ex: Rami, Belote'),
                              value: false,
                              groupValue: _isLowestScoreWins,
                              onChanged: (value) {
                                setState(() {
                                  _isLowestScoreWins = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Joueurs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Joueurs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addPlayerSlot,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Boutons de sélection de joueurs
            ...List.generate(_selectedPlayerNames.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showPlayerPicker(index),
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Joueur ${index + 1}',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedPlayerNames[index].isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedPlayerNames[index] = '';
                                });
                              },
                              tooltip: 'Effacer',
                            ),
                          if (_selectedPlayerNames.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removePlayerSlot(index),
                              tooltip: 'Retirer',
                            ),
                        ],
                      ),
                    ),
                    child: Text(
                      _selectedPlayerNames[index].isEmpty
                          ? 'Sélectionner un joueur...'
                          : _selectedPlayerNames[index],
                      style: TextStyle(
                        color: _selectedPlayerNames[index].isEmpty
                            ? Theme.of(context).hintColor
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Bouton de création
            FilledButton.icon(
              onPressed: _createGame,
              icon: const Icon(Icons.check),
              label: const Text('Créer la partie'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
