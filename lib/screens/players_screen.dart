import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/player_stats.dart';
import '../providers/game_provider.dart';
import '../utils/insets.dart';
import '../utils/player_colors.dart';
import '../widgets/player_avatars.dart';

/// Every known player: their games and wins, their colour, and rename, recolour
/// and delete.
///
/// The counts are the leaderboard's (`buildLeaderboard` over
/// `GameProvider.getFinishedGameResults`): finished games with a score only,
/// so a player shows the same numbers here and under Statistics. The colours
/// are the leaderboard's too ([playerColorsByUuid]); a player with no finished
/// game takes the next colour nobody on the screen shows.
class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

/// One row of the Players screen.
class _PlayerRow {
  const _PlayerRow({
    required this.name,
    required this.colour,
    required this.games,
    required this.wins,
  });

  final String name;
  final Color colour;
  final int games;
  final int wins;
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<_PlayerRow> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final gameProvider = context.read<GameProvider>();
    final names = await gameProvider.getAllPlayerNames();
    final results = await gameProvider.getFinishedGameResults();
    final stored = await gameProvider.getPlayerColors();
    if (!mounted) return;

    final entries = {
      for (final e in buildLeaderboard(results, kAllGameTypes))
        e.name.toLowerCase(): e,
    };
    final byUuid = playerColorsByUuid(results);
    final colours = <String, Color>{
      for (final e in entries.entries)
        if (byUuid[e.value.playerUuid] != null)
          e.key: byUuid[e.value.playerUuid]!,
    };
    final rest = [
      for (final n in names)
        if (!colours.containsKey(n.toLowerCase())) n,
    ];
    final restColours = assignPlayerColors(
      [for (final n in rest) stored[n]],
      alreadyShown: byUuid.values,
    );
    for (var i = 0; i < rest.length; i++) {
      colours[rest[i].toLowerCase()] = restColours[i];
    }

    setState(() {
      _players = [
        for (final n in names)
          _PlayerRow(
            name: n,
            colour: colours[n.toLowerCase()]!,
            games: entries[n.toLowerCase()]?.games ?? 0,
            wins: entries[n.toLowerCase()]?.wins ?? 0,
          ),
      ];
      _loading = false;
    });
  }

  Future<void> _changeColour(BuildContext context, _PlayerRow player) async {
    final gameProvider = context.read<GameProvider>();
    final newColor = await _showColorPicker(context, player.colour);
    if (newColor == null || !mounted) return;
    await gameProvider.updatePlayerColor(player.name, newColor.toARGB32());
    await _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playersListTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPlayers,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.playersAppearMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: withBottomInset(context, const EdgeInsets.all(8)),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return Card(
                  key: Key('players_row_${player.name}'),
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    leading: Tooltip(
                      message: l10n.changeColor,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _changeColour(context, player),
                        child: PlayerAvatar(
                          key: Key('players_avatar_${player.name}'),
                          name: player.name,
                          color: player.colour,
                          size: 40,
                          letters: 2,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${l10n.gamesCount(player.games)}\n'
                      '${l10n.winsCount(player.wins)}',
                      key: Key('players_counts_${player.name}'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.palette, color: player.colour),
                          onPressed: () => _changeColour(context, player),
                          tooltip: l10n.changeColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showRenameDialog(context, player.name),
                          tooltip: l10n.rename,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _showDeleteDialog(context, player.name),
                          tooltip: l10n.delete,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<Color?> _showColorPicker(
    BuildContext context,
    Color currentColor,
  ) async {
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
                ColorPickerType.accent: true,
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

  Future<void> _showRenameDialog(
    BuildContext context,
    String playerName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: playerName);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final gameProvider = context.read<GameProvider>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.renamePlayer),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.newName,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != playerName) {
                  Navigator.pop(context, newName);
                }
              },
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );

    if (result != null && result != playerName) {
      await gameProvider.renamePlayer(playerName, result);
      await _loadPlayers();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.playerRenamedTo(result))),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    String playerName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.read<GameProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Every game the delete touches, open ones included — not the finished
    // games the row counts.
    final gamesPlayed =
        (await gameProvider.getPlayerGameCounts())[playerName] ?? 0;

    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deletePlayer),
          content: Text(l10n.confirmDeletePlayer(playerName, gamesPlayed)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await gameProvider.deletePlayerByName(playerName);
      await _loadPlayers();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.playerDeleted(playerName))),
        );
      }
    }
  }
}
