import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameTypesTitle),
      ),
      body: Consumer<GameTypeProvider>(
        builder: (context, gameTypeProvider, child) {
          final gameTypes = gameTypeProvider.gameTypes;

          if (gameTypes.isEmpty) {
            return Center(
              child: Text(l10n.noGameTypes),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: gameTypes.length,
            itemBuilder: (context, index) {
              final gameType = gameTypes[index];
              return Card(
                color: gameType.cardColor.withValues(alpha: 0.1),
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
                        ? l10n.lowestScoreWins
                        : l10n.highestScoreWins,
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
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
        label: Text(l10n.newType),
      ),
    );
  }

  void _showGameTypeDialog(BuildContext context, GameType? existingGameType) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existingGameType != null;

    final nameController = TextEditingController(text: existingGameType?.name ?? '');
    final playerDeadThresholdController = TextEditingController(
      text: existingGameType?.playerDeadThreshold?.toString() ?? '',
    );
    final gameOverThresholdController = TextEditingController(
      text: existingGameType?.gameOverThreshold?.toString() ?? '',
    );
    IconData selectedIcon = existingGameType?.icon ?? Icons.sports_esports;
    Color selectedColor = existingGameType?.cardColor ?? Colors.deepPurple;
    bool isLowestScoreWins = existingGameType?.isLowestScoreWins ?? false;
    PlayerDeadConditionType? playerDeadConditionType = existingGameType?.playerDeadConditionType;
    GameOverConditionType? gameOverConditionType = existingGameType?.gameOverConditionType;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? l10n.editType : l10n.newGameType),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.gameTypeName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(l10n.icon),
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
                        Text(l10n.color),
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
                      title: Text(l10n.lowestScoreWins),
                      value: isLowestScoreWins,
                      onChanged: (value) {
                        setState(() {
                          isLowestScoreWins = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.playerEliminationCondition,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PlayerDeadConditionType?>(
                      value: playerDeadConditionType,
                      decoration: InputDecoration(
                        labelText: l10n.conditionType,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.none),
                        ),
                        DropdownMenuItem(
                          value: PlayerDeadConditionType.over,
                          child: Text(l10n.overThreshold),
                        ),
                        DropdownMenuItem(
                          value: PlayerDeadConditionType.under,
                          child: Text(l10n.underThreshold),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          playerDeadConditionType = value;
                          if (value == null) {
                            playerDeadThresholdController.clear();
                          }
                        });
                      },
                    ),
                    if (playerDeadConditionType != null) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: playerDeadThresholdController,
                        decoration: InputDecoration(
                          labelText: l10n.threshold,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.gameOverCondition,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<GameOverConditionType?>(
                      value: gameOverConditionType,
                      decoration: InputDecoration(
                        labelText: l10n.conditionType,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.none),
                        ),
                        DropdownMenuItem(
                          value: GameOverConditionType.firstPlayerOver,
                          child: Text(l10n.firstPlayerOver),
                        ),
                        DropdownMenuItem(
                          value: GameOverConditionType.firstPlayerUnder,
                          child: Text(l10n.firstPlayerUnder),
                        ),
                        DropdownMenuItem(
                          value: GameOverConditionType.lastPlayerOver,
                          child: Text(l10n.lastPlayerOver),
                        ),
                        DropdownMenuItem(
                          value: GameOverConditionType.lastPlayerUnder,
                          child: Text(l10n.lastPlayerUnder),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          gameOverConditionType = value;
                          if (value == null) {
                            gameOverThresholdController.clear();
                          }
                        });
                      },
                    ),
                    if (gameOverConditionType != null) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: gameOverThresholdController,
                        decoration: InputDecoration(
                          labelText: l10n.threshold,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.nameIsRequired)),
                      );
                      return;
                    }

                    final gameType = GameType(
                      id: existingGameType?.id,
                      name: nameController.text,
                      iconCodePoint: selectedIcon.codePoint,
                      cardColorValue: selectedColor.toARGB32(),
                      isLowestScoreWins: isLowestScoreWins,
                      playerDeadConditionType: playerDeadConditionType,
                      playerDeadThreshold: playerDeadThresholdController.text.isEmpty
                          ? null
                          : int.tryParse(playerDeadThresholdController.text),
                      gameOverConditionType: gameOverConditionType,
                      gameOverThreshold: gameOverThresholdController.text.isEmpty
                          ? null
                          : int.tryParse(gameOverThresholdController.text),
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
                  child: Text(isEditing ? l10n.edit : l10n.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGameType(BuildContext context, GameType gameType) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeleteGame(gameType.name)),
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
      try {
        await context.read<GameTypeProvider>().deleteGameType(gameType.id!);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.errorDuringExport} ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showIconPicker(BuildContext context, Function(IconData) onIconSelected) {
    final l10n = AppLocalizations.of(context)!;
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
      // Additional 16 icons
      Icons.casino_outlined,
      Icons.sports_tennis,
      Icons.sports_baseball,
      Icons.diamond,
      Icons.workspace_premium,
      Icons.auto_awesome,
      Icons.account_tree,
      Icons.extension,
      Icons.local_fire_department,
      Icons.offline_bolt,
      Icons.shield,
      Icons.emoji_objects,
      Icons.music_note,
      Icons.palette,
      Icons.school,
      Icons.sports_kabaddi,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.chooseIcon),
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
                ColorPickerType.accent: false,
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
}
