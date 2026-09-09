import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game_analysis.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../repositories/drift/drift_repositories.dart';
import '../repositories/game_analysis_repository.dart';
import '../services/drift/database.dart';

class GameAnalysisScreen extends StatefulWidget {
  // Public so it stays usable as an injection seam from outside this library.
  const GameAnalysisScreen({super.key, this.repository});

  final GameAnalysisRepository? repository;

  @override
  State<GameAnalysisScreen> createState() => _GameAnalysisScreenState();
}

class _GameAnalysisScreenState extends State<GameAnalysisScreen> {
  static const _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://countscore.ombivince.synology.me',
  );
  static const _requestTimeout = Duration(seconds: 90);

  late final GameAnalysisRepository _repo =
      widget.repository ?? DriftGameAnalysisRepository(AppDatabase.instance);

  bool _isLoading = false;
  String? _analysisText;
  String? _error;
  DateTime? _generatedAt;
  String? _modelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCached());
  }

  /// Loads a previously saved analysis if one exists. Generation is never
  /// triggered automatically — the user taps "Generate" to spend an LLM call.
  Future<void> _loadCached() async {
    final gameId = context.read<GameProvider>().currentGame?.id;
    if (gameId == null) return;

    final saved = await _repo.getByGame(gameId);
    if (!mounted || saved == null) return;

    setState(() {
      _analysisText = saved.content;
      _generatedAt = saved.generatedAt;
      _modelId = saved.modelId;
    });
  }

  Future<void> _generate() async {
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();
    final game = gameProvider.currentGame;
    if (game == null || game.id == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gameType = game.gameTypeId != null
          ? gameTypeProvider.getGameTypeById(game.gameTypeId!)
          : null;
      final players = gameProvider.currentPlayers;
      final rounds = gameProvider.currentRounds;

      final historyByName = <String, List<Map<String, dynamic>>>{};
      final seen = <String>{};
      for (final p in players) {
        if (!seen.add(p.name)) continue;
        historyByName[p.name] = await _repo.getRecentPlayerHistory(
          p.name,
          limit: 10,
          excludeGameId: game.id,
        );
      }

      final payload = {
        'game': {
          'id': game.id,
          'name': game.name,
          'is_lowest_score_wins': game.isLowestScoreWins,
          'created_at': game.createdAt.toIso8601String(),
        },
        'game_type': gameType?.name,
        'players': [
          for (final p in players) {'id': p.id, 'name': p.name},
        ],
        'rounds': [
          for (final r in rounds)
            {
              'id': r.id,
              'number': r.roundNumber,
              'comment': r.comment,
              'scores': [
                for (final p in players)
                  {
                    'player_id': p.id,
                    'value': gameProvider.scores['${p.id}_${r.id}']?.value,
                  },
              ],
            },
        ],
        'history_by_player_name': historyByName,
      };

      final response = await http
          .post(
            Uri.parse('$_backendUrl/comments/zapzap-analysis'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = body['content'] as String;
      final modelId = body['model'] as String?;
      final now = DateTime.now();

      await _repo.upsert(GameAnalysis(
        gameId: game.id!,
        content: text,
        modelId: modelId,
        generatedAt: now,
      ));

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _analysisText = text;
        _generatedAt = now;
        _modelId = modelId;
        _error = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _error = l10n.analysisError;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _error = '${l10n.analysisError}\n$e';
      });
    }
  }

  Future<void> _regenerate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(l10n.confirmRegenerateAnalysis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.regenerateAnalysis),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _generate();
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final gameId = context.read<GameProvider>().currentGame?.id;
    if (gameId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(l10n.confirmDeleteAnalysis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _repo.deleteByGame(gameId);
    if (!mounted) return;
    setState(() {
      _analysisText = null;
      _generatedAt = null;
      _modelId = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasContent = _analysisText != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.regenerateAnalysis,
            onPressed: hasContent && !_isLoading ? _regenerate : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteAnalysis,
            onPressed: hasContent && !_isLoading ? _delete : null,
          ),
        ],
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(l10n.generatingAnalysis),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                onPressed: _generate,
              ),
            ],
          ),
        ),
      );
    }

    if (_analysisText == null) {
      return Center(
        child: FilledButton.icon(
          key: const Key('analysis_generate'),
          icon: const Icon(Icons.auto_awesome),
          label: Text(l10n.generateAnalysis),
          onPressed: _generate,
        ),
      );
    }

    final dateLabel = _generatedAt != null
        ? DateFormat.yMd(Localizations.localeOf(context).toString())
            .add_Hm()
            .format(_generatedAt!)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: _analysisText!,
            selectable: true,
          ),
          const SizedBox(height: 24),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 8),
          Text(
            '${l10n.analysisGeneratedAt(dateLabel)}${_modelId != null ? " · $_modelId" : ""}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
