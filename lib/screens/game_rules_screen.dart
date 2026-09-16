import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../providers/game_type_provider.dart';
import '../services/game_rules_catalog.dart';

/// How a game type is played, and how CountScore scores it.
///
/// Three layers, most specific first: what the user wrote, the ruleset shipped
/// for [GameType.rulesSlug] in the current locale, or nothing — a custom type
/// or `Autre`, which gets the empty state. Above all three sits a summary
/// derived from the type's own fields, which is correct even for a type the
/// user built themselves.
class GameRulesScreen extends StatefulWidget {
  const GameRulesScreen({super.key, required this.gameType, this.catalog});

  final GameType gameType;

  /// Injection seam for tests, like `GameAnalysisScreen`.
  final GameRulesCatalog? catalog;

  @override
  State<GameRulesScreen> createState() => _GameRulesScreenState();
}

class _GameRulesScreenState extends State<GameRulesScreen> {
  late GameRulesCatalog _catalog;
  late GameType _gameType;
  String? _shipped;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog ?? GameRulesCatalog();
    _gameType = widget.gameType;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadShipped();
  }

  Future<void> _loadShipped() async {
    final code = Localizations.localeOf(context).languageCode;
    final text = await _catalog.rules(_gameType.rulesSlug, code);
    if (!mounted) return;
    setState(() {
      _shipped = text;
      _loading = false;
    });
  }

  /// What the page shows: the user's text when there is one, the shipped
  /// ruleset otherwise.
  String? get _displayed => _gameType.rules ?? _shipped;

  bool get _isUserWritten => _gameType.rules != null;

  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context)!;
    final edited = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _GameRulesEditor(initialText: _displayed ?? ''),
      ),
    );
    if (edited == null || !mounted) return;
    // An editor emptied back out means "no rules of mine", which is the same
    // state as never having written any.
    final trimmed = edited.trim();
    await _save(trimmed.isEmpty ? null : trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.gameRulesSaved)));
  }

  Future<void> _restoreDefault() async {
    final l10n = AppLocalizations.of(context)!;
    await _save(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.gameRulesRestored)));
  }

  Future<void> _save(String? rules) async {
    final updated = rules == null
        ? _gameType.copyWith(clearRules: true)
        : _gameType.copyWith(rules: rules);
    await context.read<GameTypeProvider>().updateGameType(updated);
    if (!mounted) return;
    setState(() => _gameType = updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = _displayed;
    return Scaffold(
      appBar: AppBar(
        title: Text(_gameType.name),
        actions: [
          if (!_loading && body != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.gameRulesEditTitle,
              onPressed: _edit,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TypeHeader(gameType: _gameType),
                const SizedBox(height: 16),
                _ScoringSummary(gameType: _gameType),
                const SizedBox(height: 24),
                if (body == null)
                  _EmptyRules(onWrite: _edit)
                else
                  ..._rulesBody(context, body),
              ],
            ),
    );
  }

  List<Widget> _rulesBody(BuildContext context, String body) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return [
      _SectionLabel(label: l10n.gameRulesSection),
      const SizedBox(height: 8),
      MarkdownBody(data: body, selectable: true),
      const SizedBox(height: 24),
      Divider(color: theme.dividerColor),
      const SizedBox(height: 8),
      if (_isUserWritten)
        Row(
          children: [
            Expanded(
              child: Text(l10n.gameRulesFromGroup,
                  style: theme.textTheme.bodySmall),
            ),
            // Only offered when there is something to go back to.
            if (_gameType.rulesSlug != null && _shipped != null)
              TextButton(
                onPressed: _restoreDefault,
                child: Text(l10n.gameRulesRestoreDefault),
              ),
          ],
        )
      else
        Text(l10n.gameRulesDisclaimer, style: theme.textTheme.bodySmall),
    ];
  }
}

/// The tinted card that names the type, matching the game-type list.
class _TypeHeader extends StatelessWidget {
  const _TypeHeader({required this.gameType});

  final GameType gameType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: gameType.cardColor.withValues(alpha: 0.1),
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(gameType.icon, size: 40, color: gameType.cardColor),
        title: Text(
          gameType.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Text(gameType.isLowestScoreWins
            ? l10n.lowestScoreWins
            : l10n.highestScoreWins),
      ),
    );
  }
}

/// How CountScore scores *this* type, read off its own fields. Always true,
/// including for a type the user created, and it is what reconciles a general
/// ruleset with the thresholds actually configured.
class _ScoringSummary extends StatelessWidget {
  const _ScoringSummary({required this.gameType});

  final GameType gameType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: l10n.gameRulesInApp),
        const SizedBox(height: 8),
        _line(
          context,
          gameType.isLowestScoreWins
              ? Icons.south_rounded
              : Icons.north_rounded,
          gameType.isLowestScoreWins
              ? l10n.lowestScoreWins
              : l10n.highestScoreWins,
        ),
        _line(context, Icons.person_off_outlined, _elimination(l10n)),
        _line(context, Icons.flag_outlined, _gameOver(l10n)),
      ],
    );
  }

  String _elimination(AppLocalizations l10n) {
    final threshold = gameType.playerDeadThreshold;
    final type = gameType.playerDeadConditionType;
    if (threshold == null || type == null) return l10n.gameRulesNoElimination;
    return switch (type) {
      PlayerDeadConditionType.over => l10n.gameRulesEliminationOver(threshold),
      PlayerDeadConditionType.under => l10n.gameRulesEliminationUnder(threshold),
    };
  }

  String _gameOver(AppLocalizations l10n) {
    final threshold = gameType.gameOverThreshold;
    final type = gameType.gameOverConditionType;
    if (threshold == null || type == null) return l10n.gameRulesNoEnd;
    return switch (type) {
      GameOverConditionType.firstPlayerOver => l10n.gameRulesEndFirstOver(threshold),
      GameOverConditionType.firstPlayerUnder => l10n.gameRulesEndFirstUnder(threshold),
      GameOverConditionType.lastPlayerOver => l10n.gameRulesEndLastOver(threshold),
      GameOverConditionType.lastPlayerUnder => l10n.gameRulesEndLastUnder(threshold),
    };
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}

/// A custom type, or `Autre`: nothing is shipped, so invite the user to write.
class _EmptyRules extends StatelessWidget {
  const _EmptyRules({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(l10n.gameRulesEmptyTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.gameRulesEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onWrite,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.gameRulesWrite),
          ),
        ],
      ),
    );
  }
}

/// Full-screen editor. It opens on whatever the page was showing, so a user
/// correcting a shipped ruleset starts from it rather than from a blank page.
class _GameRulesEditor extends StatefulWidget {
  const _GameRulesEditor({required this.initialText});

  final String initialText;

  @override
  State<_GameRulesEditor> createState() => _GameRulesEditorState();
}

class _GameRulesEditorState extends State<_GameRulesEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameRulesEditTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n.gameRulesEditorHint,
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}
