import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../providers/group_provider.dart';
import '../utils/game_type_name.dart';
import '../utils/play_again.dart';
import '../utils/player_colors.dart';
import '../utils/recent_game_types.dart';
import '../widgets/game_type_tile_grid.dart';
import '../widgets/player_picker_sheet.dart';
import '../widgets/seat_order_list.dart';
import 'game_board_screen.dart';

export '../widgets/player_picker_sheet.dart' show PlayerSelection;

/// New game: a name, a game type picked from tiles (most recently played
/// first), and the players in seat order — the order the board, the keypad
/// and the rows all follow — then "Start".
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key, this.boardBuilder});

  /// Opens the created game; the real `GameBoardScreen` when null. Tests pass
  /// their own, since the real board reaches the database singleton.
  final WidgetBuilder? boardBuilder;

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  int? _selectedGameTypeId;
  bool _isLowestScoreWins = true;

  /// Whether [_loadData] has finished, successfully or not: until then an
  /// empty type list means "still loading", afterwards it means "none".
  bool _loaded = false;

  /// The players, in seat order.
  final List<PlayerSelection> _seated = [];

  /// Known players, most frequent first, and their own colour values.
  List<String> _knownPlayers = [];
  Map<String, int?> _colorValues = {};
  LastGamePlayers? _lastGame;

  // On by default while this device is in a group — the user's design choice.
  bool _shareWithGroup = true;

  @override
  void initState() {
    super.initState();
    _loadData().whenComplete(() {
      if (mounted) setState(() => _loaded = true);
    });
  }

  Future<void> _loadData() async {
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();

    final names = await gameProvider.getAllPlayerNames();
    final colors = await gameProvider.getPlayerColors();
    final counts = await gameProvider.getPlayerGameCounts();
    await gameProvider.loadGames();
    final games = gameProvider.games;
    await gameTypeProvider.loadGameTypes();
    final gameTypes = gameTypeProvider.gameTypes;

    LastGamePlayers? lastGame;
    if (games.isNotEmpty) {
      final players = await gameProvider.getPlayersOfGame(games.first.id!);
      lastGame = LastGamePlayers(games.first.name, [
        for (final p in players) PlayerSelection(p.name, p.colorValue),
      ]);
    }

    // The type of the last game created, else ZapZap.
    GameType zapzapOrFirst() => gameTypes.firstWhere(
          (type) => type.builtinKey == 'zapzap',
          orElse: () => gameTypes.first,
        );
    final GameType? defaultGameType = gameTypes.isEmpty
        ? null
        : games.isNotEmpty
            ? gameTypes.firstWhere(
                (type) => type.id == games.first.gameTypeId,
                orElse: zapzapOrFirst,
              )
            : zapzapOrFirst();

    names.sort((a, b) {
      final byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      return byCount != 0 ? byCount : collateNames(a, b);
    });

    if (!mounted) return;
    // The first game is named in the app's language; later ones count on from
    // the last game's name, whatever language it is in.
    final defaultGameName = games.isEmpty
        ? AppLocalizations.of(context)!.defaultGameName(1)
        : nextGameName(games.first.name);
    setState(() {
      _knownPlayers = names;
      _colorValues = colors;
      _lastGame = lastGame;
      _selectedGameTypeId = defaultGameType?.id;
      _isLowestScoreWins = defaultGameType?.isLowestScoreWins ?? true;
      _gameNameController.text = defaultGameName;
    });
  }

  void _selectType(GameType type) {
    setState(() {
      _selectedGameTypeId = type.id;
      _isLowestScoreWins = type.isLowestScoreWins;
    });
  }

  /// Drops the focus before a sheet opens. A modal route gives focus back to
  /// what held it when it closes: the name field, whose keyboard then covered
  /// the players just picked.
  void _unfocusBeforeSheet() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _showAllTypes(List<GameType> types) async {
    _unfocusBeforeSheet();
    final picked = await showAllGameTypesSheet(context,
        types: types, selectedId: _selectedGameTypeId);
    if (picked != null && mounted) _selectType(picked);
  }

  Future<void> _pickPlayers() async {
    _unfocusBeforeSheet();
    final result = await showPlayerPickerSheet(
      context,
      knownPlayers: _knownPlayers,
      colorValues: _colorValues,
      seated: List.of(_seated),
      lastGame: _lastGame,
    );
    if (result == null || !mounted) return;
    setState(() {
      _seated
        ..clear()
        ..addAll(result);
      for (final p in result) {
        if (!_knownPlayers.contains(p.name)) _knownPlayers.insert(0, p.name);
        _colorValues.putIfAbsent(p.name, () => p.colorValue);
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final player = _seated.removeAt(oldIndex);
      _seated.insert(newIndex, player);
    });
  }

  void _removePlayer(int index) {
    setState(() => _seated.removeAt(index));
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    final gameProvider = context.read<GameProvider>();
    final playerNames = _seated.map((p) => p.name).toList();
    final playerColorsMap = <String, int?>{
      for (final player in _seated) player.name: player.colorValue,
    };

    final group = context.read<GroupProvider>();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final gameId = await gameProvider.createGame(
      _gameNameController.text.trim(),
      _selectedGameTypeId,
      _isLowestScoreWins,
      playerNames,
      playerColorsMap,
    );

    if (group.isJoined && _shareWithGroup) {
      try {
        await group.shareGame(gameId);
      } on GroupActionException catch (e) {
        // The game exists either way; it just stays local.
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.invalidPlayerNamesForSync(e.detail.join(', '))),
        ));
      }
    }

    await gameProvider.loadGame(gameId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: widget.boardBuilder ?? (context) => const GameBoardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gameTypes = context.watch<GameTypeProvider>().gameTypes;
    final games = context.watch<GameProvider>().games;
    final recentFirst = gameTypesRecentFirst(l10n, gameTypes, games);
    final tiles = gameTypeTiles(recentFirst, _selectedGameTypeId);
    final selectedType = gameTypes
        .where((t) => t.id == _selectedGameTypeId)
        .firstOrNull;
    final colours =
        assignPlayerColors([for (final p in _seated) p.colorValue]);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newGame)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _Overline(l10n.newGameNameLabel),
            TextFormField(
              key: const Key('create_game_name'),
              controller: _gameNameController,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 4, bottom: 10),
                border: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: scheme.primary.withValues(alpha: 0.25), width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: scheme.primary.withValues(alpha: 0.25), width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _Overline(l10n.newGameGameLabel)),
                if (gameTypes.isNotEmpty)
                  TextButton(
                    key: const Key('game_type_all'),
                    onPressed: () => _showAllTypes(gameTypes),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: Text(l10n.newGameAllGames(gameTypes.length)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (gameTypes.isEmpty)
              Text(
                _loaded ? l10n.noGameTypes : l10n.loadingGameTypes,
                key: const Key('game_type_empty'),
              )
            else
              GameTypeTileGrid(
                types: tiles,
                selectedId: _selectedGameTypeId,
                onSelected: _selectType,
              ),
            const SizedBox(height: 10),
            if (selectedType != null) _ruleLine(context, selectedType),
            const SizedBox(height: 24),
            // One line when both fit, the hint under the label otherwise.
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  _Overline(l10n.newGamePlayersLabel),
                  if (_seated.length >= 2)
                    Text(
                      l10n.newGameDragToReorder,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SeatOrderList(
              players: _seated,
              colours: colours,
              onReorder: _reorder,
              onRemove: _removePlayer,
            ),
            _AddPlayerRow(
              key: const Key('create_add_player'),
              label: l10n.newGameAddPlayer,
              onTap: _pickPlayers,
            ),
            Consumer<GroupProvider>(
              builder: (context, group, child) {
                if (!group.isJoined) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SwitchListTile(
                    key: const Key('create_share_with_group'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.cloud_upload_outlined),
                    title: Text(l10n.shareWithGroup),
                    subtitle:
                        Text(l10n.shareWithGroupSubtitle(group.groupName ?? '')),
                    value: _shareWithGroup,
                    onChanged: (value) => setState(() => _shareWithGroup = value),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              key: const Key('create_game_submit'),
              onPressed: _seated.length >= 2 ? _createGame : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(l10n.newGameStart(_seated.length),
                  style: const TextStyle(fontSize: 18)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The selected type's win rule and end condition, as one line — or, for
  /// "Other", the choice of win rule.
  Widget _ruleLine(BuildContext context, GameType type) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (type.builtinKey == 'other') {
      return SegmentedButton<bool>(
        key: const Key('create_win_rule'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: true, label: Text(l10n.lowestScoreWins)),
          ButtonSegment(value: false, label: Text(l10n.highestScoreWins)),
        ],
        selected: {_isLowestScoreWins},
        onSelectionChanged: (value) =>
            setState(() => _isLowestScoreWins = value.first),
      );
    }
    final rule = type.isLowestScoreWins
        ? l10n.lowestScoreWins
        : l10n.highestScoreWins;
    final end = _gameOver(l10n, type);
    return Text(
      end == null ? rule : '$rule · $end',
      key: const Key('create_rule_line'),
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  String? _gameOver(AppLocalizations l10n, GameType type) {
    final threshold = type.gameOverThreshold;
    final condition = type.gameOverConditionType;
    if (threshold == null || condition == null) return null;
    return switch (condition) {
      GameOverConditionType.firstPlayerOver => l10n.gameRulesEndFirstOver(threshold),
      GameOverConditionType.firstPlayerUnder => l10n.gameRulesEndFirstUnder(threshold),
      GameOverConditionType.lastPlayerOver => l10n.gameRulesEndLastOver(threshold),
      GameOverConditionType.lastPlayerUnder => l10n.gameRulesEndLastUnder(threshold),
    };
  }
}

/// A small capitalised section label.
class _Overline extends StatelessWidget {
  const _Overline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The dashed "Add a player" row under the seats.
class _AddPlayerRow extends StatelessWidget {
  const _AddPlayerRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
          colour: scheme.primary.withValues(alpha: 0.45), radius: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: scheme.primary),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.colour, required this.radius});

  final Color colour;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75), Radius.circular(radius)));
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
            metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.colour != colour || old.radius != radius;
}
