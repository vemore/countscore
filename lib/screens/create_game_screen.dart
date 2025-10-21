import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_type.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
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
  final List<TextEditingController> _playerControllers = [];
  List<String> _availablePlayerNames = [];

  @override
  void initState() {
    super.initState();
    _addPlayerField();
    _addPlayerField();
    _loadData();
  }

  Future<void> _loadData() async {
    final names = await context.read<GameProvider>().getAllPlayerNames();
    await context.read<GameTypeProvider>().loadGameTypes();

    final gameTypes = context.read<GameTypeProvider>().gameTypes;
    if (gameTypes.isNotEmpty && _selectedGameTypeId == null) {
      setState(() {
        _availablePlayerNames = names;
        _selectedGameTypeId = gameTypes.first.id;
        _isLowestScoreWins = gameTypes.first.isLowestScoreWins;
      });
    } else {
      setState(() {
        _availablePlayerNames = names;
      });
    }
  }

  void _addPlayerField() {
    setState(() {
      _playerControllers.add(TextEditingController());
    });
  }

  void _removePlayerField(int index) {
    if (_playerControllers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    final playerNames = _playerControllers
        .map((c) => c.text.trim())
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

            // Règle de victoire
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

            // Joueurs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Joueurs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addPlayerField,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Champs de joueurs avec autocomplétion
            ...List.generate(_playerControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _availablePlayerNames.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _playerControllers[index].text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Synchroniser les contrôleurs
                    fieldController.text = _playerControllers[index].text;
                    fieldController.addListener(() {
                      _playerControllers[index].text = fieldController.text;
                    });

                    return TextFormField(
                      controller: fieldController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Joueur ${index + 1}',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _playerControllers.length > 2
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removePlayerField(index),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nom requis';
                        }
                        return null;
                      },
                    );
                  },
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
