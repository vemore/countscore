import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/game_type.dart';
import '../providers/game_type_provider.dart';

class GameTypesScreen extends StatefulWidget {
  const GameTypesScreen({super.key});

  @override
  State<GameTypesScreen> createState() => _GameTypesScreenState();
}

class _GameTypesScreenState extends State<GameTypesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameTypeProvider>().loadGameTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Types de jeux'),
      ),
      body: Consumer<GameTypeProvider>(
        builder: (context, gameTypeProvider, child) {
          final gameTypes = gameTypeProvider.gameTypes;

          if (gameTypes.isEmpty) {
            return const Center(
              child: Text('Aucun type de jeu'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: gameTypes.length,
            itemBuilder: (context, index) {
              final gameType = gameTypes[index];
              return Card(
                color: gameType.cardColor.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: Icon(
                    gameType.icon,
                    size: 32,
                    color: gameType.cardColor,
                  ),
                  title: Text(
                    gameType.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    gameType.isLowestScoreWins
                        ? 'Plus petit score gagne'
                        : 'Plus grand score gagne',
                  ),
                  trailing: gameType.isDefault
                      ? const Chip(
                          label: Text('Prédéfini', style: TextStyle(fontSize: 10)),
                          padding: EdgeInsets.symmetric(horizontal: 6),
                        )
                      : PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
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
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showGameTypeDialog(context, gameType);
                            } else if (value == 'delete') {
                              _deleteGameType(context, gameType);
                            }
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGameTypeDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau type'),
      ),
    );
  }

  void _showGameTypeDialog(BuildContext context, GameType? existingGameType) {
    final isEditing = existingGameType != null;

    final nameController = TextEditingController(text: existingGameType?.name ?? '');
    IconData selectedIcon = existingGameType?.icon ?? Icons.sports_esports;
    Color selectedColor = existingGameType?.cardColor ?? Colors.deepPurple;
    bool isLowestScoreWins = existingGameType?.isLowestScoreWins ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier le type' : 'Nouveau type de jeu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du type de jeu',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Icône: '),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(selectedIcon, size: 32),
                          onPressed: () {
                            _showIconPicker(context, (icon) {
                              setState(() {
                                selectedIcon = icon;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Couleur: '),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final color = await _showColorPicker(context, selectedColor);
                            if (color != null) {
                              setState(() {
                                selectedColor = color;
                              });
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Plus petit score gagne'),
                      value: isLowestScoreWins,
                      onChanged: (value) {
                        setState(() {
                          isLowestScoreWins = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le nom est requis')),
                      );
                      return;
                    }

                    final gameType = GameType(
                      id: existingGameType?.id,
                      name: nameController.text,
                      iconCodePoint: selectedIcon.codePoint,
                      cardColorValue: selectedColor.value,
                      isLowestScoreWins: isLowestScoreWins,
                    );

                    if (isEditing) {
                      await context.read<GameTypeProvider>().updateGameType(gameType);
                    } else {
                      await context.read<GameTypeProvider>().createGameType(gameType);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Modifier' : 'Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGameType(BuildContext context, GameType gameType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${gameType.name}" ?'),
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
      try {
        await context.read<GameTypeProvider>().deleteGameType(gameType.id!);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showIconPicker(BuildContext context, Function(IconData) onIconSelected) {
    final icons = [
      Icons.sports_esports,
      Icons.casino,
      Icons.style,
      Icons.games,
      Icons.sports,
      Icons.flash_on,
      Icons.grid_on,
      Icons.stars,
      Icons.favorite,
      Icons.emoji_events,
      Icons.psychology,
      Icons.rocket_launch,
      Icons.sports_soccer,
      Icons.sports_basketball,
      Icons.deck,
      Icons.celebration,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir une icône'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                return IconButton(
                  icon: Icon(icons[index], size: 32),
                  onPressed: () {
                    onIconSelected(icons[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
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
                ColorPickerType.accent: false,
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
}
