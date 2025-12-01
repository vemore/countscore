import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../widgets/player_picker_dialog.dart';
import 'game_board_screen.dart';

export '../widgets/player_picker_dialog.dart' show PlayerSelection;

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _SelectedPlayer {
  final String name;
  final int? colorValue;

  _SelectedPlayer(this.name, this.colorValue);
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  int? _selectedGameTypeId;
  bool _isLowestScoreWins = true;
  final List<_SelectedPlayer> _selectedPlayers = [];
  List<String> _availablePlayerNames = [];
  Map<String, int?> _playerColors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();

    final names = await gameProvider.getAllPlayerNames();
    final colors = await gameProvider.getPlayerColors();
    await gameProvider.loadGames();
    final games = gameProvider.games;
    await gameTypeProvider.loadGameTypes();

    final gameTypes = gameTypeProvider.gameTypes;

    // Déterminer le type de jeu par défaut
    GameType defaultGameType;
    if (games.isNotEmpty) {
      // Utiliser le type de jeu de la dernière partie créée
      defaultGameType = gameTypes.firstWhere(
        (type) => type.id == games.first.gameTypeId,
        orElse: () => gameTypes.firstWhere(
          (type) => type.name.toLowerCase() == 'zapzap',
          orElse: () => gameTypes.first,
        ),
      );
    } else {
      // Si aucune partie n'existe, utiliser ZapZap par défaut
      defaultGameType = gameTypes.firstWhere(
        (type) => type.name.toLowerCase() == 'zapzap',
        orElse: () => gameTypes.first,
      );
    }

    // Générer le nom de partie par défaut
    String defaultGameName = 'Partie 1';
    if (games.isNotEmpty) {
      defaultGameName = _incrementGameName(games.first.name);
    }

    setState(() {
      _availablePlayerNames = names;
      _playerColors = colors;
      _selectedGameTypeId = defaultGameType.id;
      _isLowestScoreWins = defaultGameType.isLowestScoreWins;
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

  Future<void> _addPlayer() async {
    final result = await showDialog<PlayerSelection>(
      context: context,
      builder: (context) => PlayerPickerDialog(
        availablePlayers: _availablePlayerNames,
        selectedPlayers: _selectedPlayers.map((p) => p.name).toList(),
      ),
    );

    if (result != null && mounted) {
      // Si c'est un nouveau joueur, l'ajouter à la liste
      if (!_availablePlayerNames.contains(result.name)) {
        _availablePlayerNames.add(result.name);
        _availablePlayerNames.sort();
      }

      setState(() {
        // Mettre à jour ou ajouter la couleur du joueur
        _playerColors[result.name] = result.colorValue;
        _selectedPlayers.add(_SelectedPlayer(result.name, result.colorValue));
      });
    }
  }

  void _removePlayer(int index) {
    setState(() {
      _selectedPlayers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.atLeast2PlayersRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameProvider = context.read<GameProvider>();
    final playerNames = _selectedPlayers.map((p) => p.name).toList();

    // Créer un map des couleurs des joueurs
    final playerColorsMap = <String, int?>{};
    for (final player in _selectedPlayers) {
      playerColorsMap[player.name] = player.colorValue;
    }

    final gameId = await gameProvider.createGame(
      _gameNameController.text.trim(),
      _selectedGameTypeId,
      _isLowestScoreWins,
      playerNames,
      playerColorsMap,
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newGame),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom de la partie
            TextFormField(
              controller: _gameNameController,
              decoration: InputDecoration(
                labelText: l10n.gameName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.style),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterName;
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
                  return Text(l10n.loadingGameTypes);
                }

                return DropdownButtonFormField<int>(
                  initialValue: _selectedGameTypeId,
                  decoration: InputDecoration(
                    labelText: l10n.gameType,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.casino),
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
                              l10n.winRule,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            RadioGroup<bool>(
                              groupValue: _isLowestScoreWins,
                              onChanged: (value) {
                                setState(() {
                                  _isLowestScoreWins = value!;
                                });
                              },
                              child: Column(
                                children: [
                                  RadioListTile<bool>(
                                    title: Text(l10n.lowestScoreWins),
                                    subtitle: Text(l10n.lowestScoreExample),
                                    value: true,
                                  ),
                                  RadioListTile<bool>(
                                    title: Text(l10n.highestScoreWins),
                                    subtitle: Text(l10n.highestScoreExample),
                                    value: false,
                                  ),
                                ],
                              ),
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
            Text(
              l10n.players,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            // Bouton d'ajout de joueur
            OutlinedButton.icon(
              onPressed: _addPlayer,
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            // Liste des joueurs sélectionnés
            if (_selectedPlayers.isNotEmpty)
              ...List.generate(_selectedPlayers.length, (index) {
                final player = _selectedPlayers[index];
                final playerColor = player.colorValue != null
                    ? Color(player.colorValue!)
                    : Colors.blue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: playerColor,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(player.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removePlayer(index),
                        tooltip: l10n.remove,
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Bouton de création
            FilledButton.icon(
              onPressed: _selectedPlayers.isNotEmpty ? _createGame : null,
              icon: const Icon(Icons.check),
              label: Text(l10n.createGame),
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
