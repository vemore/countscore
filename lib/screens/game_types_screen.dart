import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../providers/game_type_provider.dart';
import '../utils/game_type_appearance.dart';
import '../utils/game_type_name.dart';
import '../utils/insets.dart';
import 'game_rules_screen.dart';

/// The largest threshold the editor accepts. Above it the number is almost
/// certainly a typo — Farkle, the highest seeded threshold, stops at 10000 —
/// and a condition nobody can reach is indistinguishable from none at all.
const int kMaxGameTypeThreshold = 1000000;

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
          final gameTypes =
              sortGameTypesByDisplayName(l10n, gameTypeProvider.gameTypes);

          if (gameTypes.isEmpty) {
            return Center(
              child: Text(l10n.noGameTypes),
            );
          }

          return ListView.builder(
            // The bottom edge clears the "New type" button (a 56 dp extended
            // FAB above its 16 dp margin), so the last type's menu can be
            // scrolled out from under it.
            padding: withBottomInset(
              context,
              const EdgeInsets.fromLTRB(8, 8, 8, kFabClearance),
            ),
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
                    gameTypeDisplayName(l10n, gameType),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    gameType.isLowestScoreWins
                        ? l10n.lowestScoreWins
                        : l10n.highestScoreWins,
                  ),
                  onTap: () => _openRules(context, gameType),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rules',
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_outlined),
                            const SizedBox(width: 8),
                            Text(l10n.gameRulesTitle),
                          ],
                        ),
                      ),
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
                      if (value == 'rules') {
                        _openRules(context, gameType);
                      } else if (value == 'edit') {
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

  void _openRules(BuildContext context, GameType gameType) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameRulesScreen(gameType: gameType)),
    );
  }

  Future<void> _showGameTypeDialog(
      BuildContext context, GameType? existingGameType) async {
    final saved = await showDialog<_GameTypeSaved>(
      context: context,
      builder: (dialogContext) =>
          _GameTypeDialog(existingGameType: existingGameType),
    );
    if (saved == null || !context.mounted) return;

    // The rules still describe the condition the type had a moment ago.
    // Nothing is rewritten for the user: the app only offers the editor.
    final gameType = saved.gameType;
    final hasRules = (gameType.rules?.trim().isNotEmpty ?? false) ||
        gameType.rulesSlug != null;
    if (saved.conditionsChanged && hasRules) {
      await _offerRulesEditor(context, gameType);
    }
  }

  Future<void> _offerRulesEditor(
      BuildContext context, GameType gameType) async {
    final l10n = AppLocalizations.of(context)!;
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('game_type_rules_outdated'),
        title: Text(l10n.rulesOutOfDateTitle),
        content: Text(l10n.rulesOutOfDateMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.later),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.edit),
          ),
        ],
      ),
    );
    if (open == true && context.mounted) {
      _openRules(context, gameType);
    }
  }

  /// Deletion is refused **before** it is offered: the repository's exception is
  /// a guard, not a user interface, and it speaks English.
  Future<void> _deleteGameType(BuildContext context, GameType gameType) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<GameTypeProvider>();
    final id = gameType.id;
    if (id == null) return;

    final inUse = await provider.countGames(id);
    if (!context.mounted) return;
    if (inUse > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deletionImpossible),
          content: Text(l10n.gameTypeInUse(inUse)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(
          l10n.confirmDeleteGameType(gameTypeDisplayName(l10n, gameType)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    try {
      await provider.deleteGameType(id);
    } catch (_) {
      // A game created between the count and the delete: the repository's
      // guard fired after all. Anything else is not something this screen can
      // describe, so it is left to the platform's error reporting.
      final stillInUse = await provider.countGames(id);
      if (stillInUse == 0) rethrow;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gameTypeInUse(stillInUse))),
      );
    }
  }
}

/// What [_GameTypeDialog] hands back once it has written the row.
class _GameTypeSaved {
  const _GameTypeSaved(this.gameType, {required this.conditionsChanged});

  final GameType gameType;

  /// An elimination or game-over condition actually changed — the case where
  /// the type's rules may now describe something the type no longer does.
  final bool conditionsChanged;
}

/// The create / edit form.
///
/// A `StatefulWidget` rather than the `StatefulBuilder` it used to be: the three
/// controllers need a `dispose`, and the per-field errors need somewhere to
/// live. A snackbar cannot carry them — `ScaffoldMessenger.of` reaches the app's
/// messenger, which draws behind the modal barrier.
class _GameTypeDialog extends StatefulWidget {
  const _GameTypeDialog({this.existingGameType});

  final GameType? existingGameType;

  @override
  State<_GameTypeDialog> createState() => _GameTypeDialogState();
}

class _GameTypeDialogState extends State<_GameTypeDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _playerDeadThresholdController =
      TextEditingController();
  final TextEditingController _gameOverThresholdController =
      TextEditingController();

  late IconData _icon;
  late Color _colour;
  late bool _isLowestScoreWins;
  PlayerDeadConditionType? _playerDeadType;
  GameOverConditionType? _gameOverType;

  String? _nameError;
  String? _playerDeadError;
  String? _gameOverError;
  bool _saving = false;
  bool _nameSeeded = false;

  GameType? get _existing => widget.existingGameType;
  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _playerDeadThresholdController.text =
        existing?.playerDeadThreshold?.toString() ?? '';
    _gameOverThresholdController.text =
        existing?.gameOverThreshold?.toString() ?? '';
    _icon = existing?.icon ?? Icons.sports_esports;
    _colour = existing?.cardColor ?? kGameTypePalette.first;
    _isLowestScoreWins = existing?.isLowestScoreWins ?? false;
    _playerDeadType = existing?.playerDeadConditionType;
    _gameOverType = existing?.gameOverConditionType;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameSeeded) return;
    _nameSeeded = true;
    // The localized name, so that a user who edits a built-in type sees the
    // name the rest of the app shows them, not the seeded literal.
    final existing = _existing;
    if (existing != null) {
      _nameController.text =
          gameTypeDisplayName(AppLocalizations.of(context)!, existing);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _playerDeadThresholdController.dispose();
    _gameOverThresholdController.dispose();
    super.dispose();
  }

  /// A game-over condition that rewards the opposite of the chosen winner —
  /// *lowest score wins* with *first player to reach 500*. Flagged, never
  /// refused: a house rule may want exactly that.
  bool get _directionContradicted =>
      (_isLowestScoreWins &&
          _gameOverType == GameOverConditionType.firstPlayerOver) ||
      (!_isLowestScoreWins &&
          _gameOverType == GameOverConditionType.firstPlayerUnder);

  /// The threshold in [text], and the error to show under the field.
  ({int? value, String? error}) _threshold(
    AppLocalizations l10n,
    bool required,
    String text,
  ) {
    if (!required) return (value: null, error: null);
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return (value: null, error: l10n.thresholdIsRequired);
    if (parsed > kMaxGameTypeThreshold) {
      return (value: null, error: l10n.thresholdTooLarge(kMaxGameTypeThreshold));
    }
    return (value: parsed, error: null);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final playerDead =
        _threshold(l10n, _playerDeadType != null, _playerDeadThresholdController.text);
    final gameOver =
        _threshold(l10n, _gameOverType != null, _gameOverThresholdController.text);

    setState(() {
      _nameError = name.isEmpty ? l10n.nameIsRequired : null;
      _playerDeadError = playerDead.error;
      _gameOverError = gameOver.error;
    });
    if (_nameError != null || _playerDeadError != null || _gameOverError != null) {
      return;
    }

    final provider = context.read<GameTypeProvider>();
    final existing = _existing;

    if (existing == null) {
      final created = GameType(
        name: name,
        iconCodePoint: _icon.codePoint,
        cardColorValue: _colour.toARGB32(),
        isLowestScoreWins: _isLowestScoreWins,
        playerDeadConditionType: _playerDeadType,
        playerDeadThreshold: playerDead.value,
        gameOverConditionType: _gameOverType,
        gameOverThreshold: gameOver.value,
      );
      setState(() => _saving = true);
      await provider.createGameType(created);
      if (!mounted) return;
      Navigator.pop(context, _GameTypeSaved(created, conditionsChanged: false));
      return;
    }

    // Reversing the win direction rewrites every standing of every finished
    // game of this type — they are recomputed from the scores, never stored.
    final id = existing.id;
    if (_isLowestScoreWins != existing.isLowestScoreWins && id != null) {
      final finished = await provider.countFinishedGames(id);
      if (!mounted) return;
      if (finished > 0) {
        final confirmed = await _confirmDirectionFlip(finished);
        if (!confirmed || !mounted) return;
      }
    }

    // Renaming a built-in type gives up its key: the key is what the display
    // name is read from, so keeping it would silently ignore the name the user
    // just typed. Everything else may change with the key intact.
    final renamed = isBuiltinRename(l10n, existing, name);
    // `copyWith`, never a fresh `GameType`: a column this form does not show —
    // `rules`, `rulesSlug`, `isDefault` — must survive an edit, and the
    // repository writes every column of `toMap()`.
    final saved = existing.copyWith(
      name: name,
      clearBuiltinKey: renamed,
      iconCodePoint: _icon.codePoint,
      cardColorValue: _colour.toARGB32(),
      isLowestScoreWins: _isLowestScoreWins,
      playerDeadConditionType: _playerDeadType,
      playerDeadThreshold: playerDead.value,
      clearPlayerDeadCondition: _playerDeadType == null,
      gameOverConditionType: _gameOverType,
      gameOverThreshold: gameOver.value,
      clearGameOverCondition: _gameOverType == null,
    );
    final conditionsChanged =
        saved.playerDeadConditionType != existing.playerDeadConditionType ||
            saved.playerDeadThreshold != existing.playerDeadThreshold ||
            saved.gameOverConditionType != existing.gameOverConditionType ||
            saved.gameOverThreshold != existing.gameOverThreshold;

    setState(() => _saving = true);
    await provider.updateGameType(saved);
    if (!mounted) return;
    Navigator.pop(
      context,
      _GameTypeSaved(saved, conditionsChanged: conditionsChanged),
    );
  }

  /// Cancelling here leaves the row exactly as it was: the form stays open.
  Future<bool> _confirmDirectionFlip(int finishedGames) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('game_type_direction_warning'),
        title: Text(l10n.winDirectionChangeTitle),
        content: Text(l10n.winDirectionChangeWarning(finishedGames)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _pickIcon() async {
    final chosen = await showDialog<IconData>(
      context: context,
      builder: (dialogContext) => _IconPickerDialog(current: _icon),
    );
    if (chosen != null && mounted) setState(() => _icon = chosen);
  }

  Future<void> _pickColour() async {
    final chosen = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => _ColorPickerDialog(current: _colour),
    );
    if (chosen != null && mounted) setState(() => _colour = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEditing ? l10n.editType : l10n.newGameType),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('game_type_name_field'),
              controller: _nameController,
              maxLength: 64, // the server's `max_length=64`; longer is clipped on push
              decoration: InputDecoration(
                labelText: l10n.gameTypeName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.icon),
                const SizedBox(width: 12),
                IconButton(
                  key: const Key('game_type_icon_button'),
                  icon: Icon(_icon, size: 32),
                  tooltip: l10n.chooseIcon,
                  onPressed: _pickIcon,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.color),
                const SizedBox(width: 12),
                Tooltip(
                  message: l10n.chooseColor,
                  child: Semantics(
                    button: true,
                    child: GestureDetector(
                      key: const Key('game_type_color_button'),
                      onTap: _pickColour,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _colour,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.lowestScoreWins),
              value: _isLowestScoreWins,
              onChanged: (value) => setState(() => _isLowestScoreWins = value),
            ),
            if (_directionContradicted)
              Padding(
                key: const Key('game_type_direction_contradiction'),
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.winDirectionContradiction,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.playerEliminationCondition,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PlayerDeadConditionType?>(
              initialValue: _playerDeadType,
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
                  _playerDeadType = value;
                  _playerDeadError = null;
                  if (value == null) {
                    _playerDeadThresholdController.clear();
                  }
                });
              },
            ),
            if (_playerDeadType != null) ...[
              const SizedBox(height: 8),
              _ThresholdField(
                fieldKey: const Key('game_type_player_dead_threshold'),
                controller: _playerDeadThresholdController,
                label: l10n.threshold,
                errorText: _playerDeadError,
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.gameOverCondition,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<GameOverConditionType?>(
              initialValue: _gameOverType,
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
                  _gameOverType = value;
                  _gameOverError = null;
                  if (value == null) {
                    _gameOverThresholdController.clear();
                  }
                });
              },
            ),
            if (_gameOverType != null) ...[
              const SizedBox(height: 8),
              _ThresholdField(
                fieldKey: const Key('game_type_game_over_threshold'),
                controller: _gameOverThresholdController,
                label: l10n.threshold,
                errorText: _gameOverError,
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
          key: const Key('game_type_save_button'),
          onPressed: _saving ? null : _submit,
          child: Text(_isEditing ? l10n.edit : l10n.create),
        ),
      ],
    );
  }
}

/// A whole-number field: `keyboardType` is a keyboard *hint* — on the web build
/// letters reach the controller unless a formatter stops them.
class _ThresholdField extends StatelessWidget {
  const _ThresholdField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.errorText,
  });

  /// On the `TextField` itself, so a test can type into it.
  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: errorText,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // no letters, no minus sign
        LengthLimitingTextInputFormatter(7), // kMaxGameTypeThreshold is 7 digits
      ],
    );
  }
}

class _IconPickerDialog extends StatelessWidget {
  const _IconPickerDialog({required this.current});

  final IconData current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
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
          itemCount: kGameTypeIcons.length,
          itemBuilder: (context, index) {
            final icon = kGameTypeIcons[index];
            final isCurrent = icon.codePoint == current.codePoint;
            // No tooltip on the glyphs themselves: they have no names in the
            // ARB files, and the picker's title already says what a tap does.
            // The current one is labelled — that label is about state.
            final button = IconButton(
              key: isCurrent ? const Key('game_type_icon_current') : null,
              icon: Icon(icon, size: 32),
              tooltip: isCurrent ? l10n.currentIcon : null,
              color: isCurrent ? scheme.primary : null,
              onPressed: () => Navigator.pop(context, icon),
            );
            if (!isCurrent) return button;
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
                border: Border.all(color: scheme.primary, width: 2),
              ),
              child: button,
            );
          },
        ),
      ),
    );
  }
}

/// A closed set of swatches rather than a free colour wheel.
///
/// The colour is drawn at full opacity as the type's icon over a light or a
/// dark card, and an ARGB wheel can return one that vanishes in one theme or
/// the other. [kGameTypePalette] is checked for contrast in both.
class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog({required this.current});

  final Color current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final currentValue = current.toARGB32();
    final inPalette =
        kGameTypePalette.any((c) => c.toARGB32() == currentValue);
    // A type already coloured outside the palette keeps its colour on offer:
    // opening the picker must never recolour a type by itself.
    final swatches = <Color>[
      if (!inPalette) current,
      ...kGameTypePalette,
    ];

    return AlertDialog(
      title: Text(l10n.chooseColor),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: swatches.length,
          itemBuilder: (context, index) {
            final colour = swatches[index];
            final isCurrent = colour.toARGB32() == currentValue;
            return Semantics(
              button: true,
              selected: isCurrent,
              child: Tooltip(
                message: isCurrent ? l10n.currentColor : '',
                child: InkWell(
                  key: Key('game_type_color_${colour.toARGB32()}'),
                  onTap: () => Navigator.pop(context, colour),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colour,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? scheme.onSurface : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isCurrent
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
