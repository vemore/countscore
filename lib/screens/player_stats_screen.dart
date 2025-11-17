import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../services/database_service.dart';

class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  List<String> _playerNames = [];
  Map<String, Map<String, dynamic>> _stats = {};
  Map<String, Color> _playerColors = {};
  Map<String, GameType> _gameTypesByName = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();

    // Load game types
    await gameTypeProvider.loadGameTypes();
    final gameTypes = gameTypeProvider.gameTypes;
    final gameTypesByName = <String, GameType>{};
    for (final gameType in gameTypes) {
      gameTypesByName[gameType.name] = gameType;
    }

    final names = await gameProvider.getAllPlayerNames();

    final stats = <String, Map<String, dynamic>>{};
    final colors = <String, Color>{};
    for (final name in names) {
      stats[name] = await gameProvider.getPlayerStats(name);
      colors[name] = await _loadPlayerColor(name);
    }

    setState(() {
      _playerNames = names;
      _stats = stats;
      _playerColors = colors;
      _gameTypesByName = gameTypesByName;
      _isLoading = false;
    });
  }

  Future<Color> _loadPlayerColor(String playerName) async {
    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'players',
      columns: ['colorValue'],
      where: 'name = ?',
      whereArgs: [playerName],
      limit: 1,
    );

    if (result.isNotEmpty && result.first['colorValue'] != null) {
      return Color(result.first['colorValue'] as int);
    }

    return Colors.blue; // Default color
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playerStatistics),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playerNames.isEmpty
              ? Center(
                  child: Text(l10n.noStatisticsAvailable),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _playerNames.length,
                  itemBuilder: (context, index) {
                    final name = _playerNames[index];
                    final stats = _stats[name]!;
                    final gamesPlayed = stats['gamesPlayed'] as int;
                    final wins = stats['wins'] as int;
                    final winRate = gamesPlayed > 0
                        ? (wins / gamesPlayed * 100).toStringAsFixed(1)
                        : '0.0';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _playerColors[name] ?? Colors.blue,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(l10n.gamesCount(gamesPlayed)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.overallStatistics,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  context,
                                  l10n.gamesPlayed,
                                  gamesPlayed.toString(),
                                  Icons.casino,
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  context,
                                  l10n.wins,
                                  wins.toString(),
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  context,
                                  l10n.winRate,
                                  '$winRate%',
                                  Icons.percent,
                                  color: Colors.green,
                                ),
                                if (stats['byGameType'] != null && (stats['byGameType'] as Map).isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.byGameType,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._buildGameTypeStats(context, stats['byGameType'] as Map<String, Map<String, int>>),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGameTypeStats(BuildContext context, Map<String, Map<String, int>> statsByType) {
    final l10n = AppLocalizations.of(context)!;
    final widgets = <Widget>[];

    for (final entry in statsByType.entries) {
      final gameTypeName = entry.key;
      final stats = entry.value;
      final gamesPlayed = stats['gamesPlayed'] ?? 0;
      final wins = stats['wins'] ?? 0;
      final winRate = gamesPlayed > 0
          ? (wins / gamesPlayed * 100).toStringAsFixed(1)
          : '0.0';

      // Get game type info for icon and color
      final gameType = _gameTypesByName[gameTypeName];
      final iconData = gameType?.icon ?? Icons.casino;
      final iconColor = gameType?.cardColor ?? Theme.of(context).colorScheme.primary;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    iconData,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gameTypeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(context, l10n.gamesPlayed, gamesPlayed.toString()),
                  _buildMiniStat(context, l10n.wins, wins.toString()),
                  _buildMiniStat(context, l10n.rate, '$winRate%'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
