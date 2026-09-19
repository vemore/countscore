import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/analysis_style.dart';
import '../models/game_analysis.dart';
import '../providers/backend_provider.dart';
import '../providers/game_provider.dart';
import '../providers/game_type_provider.dart';
import '../repositories/drift/drift_repositories.dart';
import '../repositories/game_analysis_repository.dart';
import '../services/backend_client.dart';
import '../services/commentary_report.dart';
import '../services/drift/database.dart';
import '../widgets/share_result_button.dart';
import 'settings_screen.dart';

class GameAnalysisScreen extends StatefulWidget {
  // Public so it stays usable as an injection seam from outside this library.
  const GameAnalysisScreen({
    super.key,
    this.repository,
    this.httpClient,
    this.launcher,
    this.share,
  });

  /// Injection seam for tests: receives the shared text instead of the
  /// system share sheet.
  final ShareTextFn? share;

  final GameAnalysisRepository? repository;

  /// Injection seam for tests, exactly like [repository]: the screen otherwise
  /// builds its own client. The app never passes one.
  final http.Client? httpClient;

  /// Injection seam for tests: opens the report `mailto:` and answers whether
  /// something handled it. Defaults to url_launcher's [launchUrl].
  final Future<bool> Function(Uri uri)? launcher;

  @override
  State<GameAnalysisScreen> createState() => _GameAnalysisScreenState();
}

class _GameAnalysisScreenState extends State<GameAnalysisScreen> {
  /// The last voice the user picked, remembered across games and launches.
  /// It is deliberately not stored with the analysis: the tone is recognisable
  /// in a sentence, and a column on `game_analyses` would cost a migration
  /// through Drift, the sqflite chain, SQLModel, Alembic and the sync bounds.
  static const stylePreferenceKey = 'analysisStyle';

  late final GameAnalysisRepository _repo =
      widget.repository ?? DriftGameAnalysisRepository(AppDatabase.instance);

  bool _isLoading = false;
  String? _analysisText;
  String? _error;
  DateTime? _generatedAt;
  String? _modelId;
  int? _analysisId;
  AnalysisStyle _style = AnalysisStyle.fallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCached());
    _loadStyle();
  }

  /// An unreadable or unknown stored value decodes to the default, the same
  /// rule [ThemeMode] follows in `theme_provider.dart`.
  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final style = AnalysisStyle.fromId(prefs.getString(stylePreferenceKey));
    if (!mounted) return;
    setState(() => _style = style);
  }

  Future<void> _selectStyle(AnalysisStyle style) async {
    setState(() => _style = style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(stylePreferenceKey, style.id);
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
      _analysisId = saved.id;
    });
  }

  Future<void> _generate() async {
    final gameProvider = context.read<GameProvider>();
    final gameTypeProvider = context.read<GameTypeProvider>();
    final baseUrl = context.read<BackendProvider>().baseUrl;
    // Read before the first await: the payload is built after several of them.
    final languageCode = Localizations.localeOf(context).languageCode;
    final game = gameProvider.currentGame;
    if (game == null || game.id == null || baseUrl == null) return;

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
        'style': _style.id,
        // The analysis answers in the language the app is displayed in. A
        // backend older than this drops both fields and uses its own defaults.
        'language': languageCode,
        // Any game type can be analysed now, including one the user created,
        // so what the app actually enforced travels with the game rather than
        // being guessed from its name.
        'game_type_rules': {
          'is_lowest_score_wins': game.isLowestScoreWins,
          'player_dead_condition_type':
              gameType?.playerDeadConditionType?.toDbString(),
          'player_dead_threshold': gameType?.playerDeadThreshold,
          'game_over_condition_type':
              gameType?.gameOverConditionType?.toDbString(),
          'game_over_threshold': gameType?.gameOverThreshold,
        },
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

      final result = await BackendClient(baseUrl, httpClient: widget.httpClient)
          .gameAnalysis(payload);
      final text = result.content;
      final modelId = result.model;
      final now = DateTime.now();

      await _repo.upsert(GameAnalysis(
        gameId: game.id!,
        content: text,
        modelId: modelId,
        generatedAt: now,
      ));

      // Re-read rather than trust upsert's return value: it is the new row id
      // on insert but the affected-row count on update.
      final analysisId = (await _repo.getByGame(game.id!))?.id;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _analysisText = text;
        _generatedAt = now;
        _modelId = modelId;
        _analysisId = analysisId;
        _error = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      _reportFailure(AppLocalizations.of(context)!.analysisError);
    } on BackendException catch (e) {
      if (!mounted) return;
      debugPrint('game analysis failed: $e'); // status + body stay in the log
      final l10n = AppLocalizations.of(context)!;
      // 503 is temporary by contract — no LLM credentials, or the provider's
      // quota is exhausted — so it gets words a user can act on: try later.
      _reportFailure(
        e.statusCode == 503
            ? l10n.analysisErrorUnavailable
            : l10n.analysisErrorStatus(e.statusCode),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('game analysis failed: $e');
      _reportFailure(AppLocalizations.of(context)!.analysisError);
    }
  }

  /// Reports a generation failure without destroying what is already on screen.
  ///
  /// A cached analysis is local data that a failed refresh never touched — the
  /// repository is only written on success. Replacing it with a full-screen
  /// error made it look destroyed, so with content present the failure is a
  /// snackbar and the error state is kept for the case where there is nothing
  /// to show at all.
  void _reportFailure(String message) {
    final hadContent = _analysisText != null;
    setState(() {
      _isLoading = false;
      if (!hadContent) _error = message;
    });
    if (!hadContent) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  /// Opens a prefilled email reporting the commentary on screen. The user sends
  /// it from their own mail app; the app itself transmits nothing.
  Future<void> _report() async {
    final text = _analysisText;
    if (text == null) return;
    final l10n = AppLocalizations.of(context)!;
    final uri = buildCommentaryReportUri(
      subject: l10n.reportCommentarySubject,
      body: l10n.reportCommentaryBody(
        commentaryReportReference(
          analysisId: _analysisId,
          modelId: _modelId,
          generatedAt: _generatedAt,
        ),
        truncateForReport(text),
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    final noMailApp = l10n.reportCommentaryNoMailApp(commentaryReportEmail);

    bool opened;
    try {
      opened = await (widget.launcher ?? launchUrl)(uri);
    } catch (e) {
      debugPrint('commentary report: no handler for mailto: $e');
      opened = false;
    }
    if (opened || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(noMailApp)));
  }

  Future<void> _regenerate() async {
    final l10n = AppLocalizations.of(context)!;
    // Picking another voice is the usual reason to regenerate, so the chips
    // are offered here rather than behind a trip back to the empty state.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.confirm),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.confirmRegenerateAnalysis),
              const SizedBox(height: 16),
              _StylePicker(
                selected: _style,
                onSelected: (style) async {
                  await _selectStyle(style);
                  setDialogState(() {});
                },
              ),
            ],
          ),
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
      _analysisId = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasContent = _analysisText != null;
    // A cached analysis stays readable with no server configured — it is local
    // data. Only generating it needs one.
    final canGenerate = context.watch<BackendProvider>().isConfigured;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        actions: [
          // The standings, then the commentary: shared only once there is
          // one, and not mid-generation.
          if (hasContent && !_isLoading)
            ShareResultButton(
              commentary: _analysisText,
              tooltip: l10n.shareAnalysis,
              share: widget.share,
            ),
          IconButton(
            key: const Key('analysis_report'),
            icon: const Icon(Icons.flag_outlined),
            tooltip: l10n.reportCommentary,
            onPressed: hasContent && !_isLoading ? _report : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.regenerateAnalysis,
            onPressed:
                hasContent && canGenerate && !_isLoading ? _regenerate : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteAnalysis,
            onPressed: hasContent && !_isLoading ? _delete : null,
          ),
        ],
      ),
      // The footer used to be drawn behind the system gesture bar. Wrapping the
      // whole body covers all four branches; `top` is already handled by the AppBar.
      body: SafeArea(
        top: false,
        child: _buildBody(context, l10n, canGenerate: canGenerate),
      ),
    );
  }

  /// Shown when no backend is configured: the feature is off by default and
  /// the user has to point the app at a server of their own.
  Widget _buildNoServer(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.analysisRequiresBackend,
              key: const Key('analysis_no_server'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.settings),
              label: Text(l10n.openSettings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n, {
    required bool canGenerate,
  }) {
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

    // Only ever non-null when there is nothing to show: `_reportFailure` sends a
    // failure here exclusively when no analysis is loaded, and to a snackbar
    // otherwise. So this branch preceding the `_analysisText == null` one below
    // is safe, and moving it would leave a second route back to the old bug.
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
      if (!canGenerate) return _buildNoServer(context, l10n);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StylePicker(selected: _style, onSelected: _selectStyle),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('analysis_generate'),
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.generateAnalysis),
                onPressed: _generate,
              ),
            ],
          ),
        ),
      );
    }

    final dateLabel = _generatedAt != null
        ? DateFormat.yMd(Localizations.localeOf(context).toString())
            .add_Hm()
            .format(_generatedAt!)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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

/// The row of voices an analysis can be written in.
///
/// Labels are translated, [AnalysisStyle.id] is not: the id is what the backend
/// and the stored preference speak.
class _StylePicker extends StatelessWidget {
  const _StylePicker({required this.selected, required this.onSelected});

  final AnalysisStyle selected;
  final ValueChanged<AnalysisStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.analysisStyle, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in AnalysisStyle.values)
              ChoiceChip(
                key: Key('analysis_style_${style.id}'),
                avatar: Icon(style.icon, size: 18),
                label: Text(style.label(l10n)),
                selected: style == selected,
                onSelected: (_) => onSelected(style),
              ),
          ],
        ),
      ],
    );
  }
}
