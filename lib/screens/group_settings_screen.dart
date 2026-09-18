import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../services/backend_client.dart';
import '../widgets/group_settings_section.dart' show groupActionErrorText;

/// Settings → Group → *Comments and usage*: the group's comment style and
/// language, which every member may change, and what the group spent on the LLM
/// this month. Everything lives on the server: the screen reads it fresh on each
/// visit and writes each change straight back, so nothing is stored on the device.
///
/// The monthly budget is shown, never edited: the server keeps it for the owner
/// alone, and [BackendClient.updateGroupSettings] cannot send it.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  /// The comment styles `PATCH /groups/me/settings` accepts.
  static const styles = ['narrative', 'humorous', 'analytical'];

  /// The comment languages offered: the app's own ten, by their endonym — the
  /// name a speaker recognises whatever the interface language, so deliberately
  /// not translated.
  static const languages = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'hi': 'हिन्दी',
    'ar': 'العربية',
  };

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  GroupSettings? _settings;
  GroupUsage? _usage;
  GroupActionException? _error;
  bool _loading = false;
  bool _saving = false;

  /// Bumped after every save, so the language field shows what the server
  /// holds again after a refused change.
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool get _reachable =>
      context.read<BackendProvider>().isConfigured &&
      context.read<GroupProvider>().canReachGroup;

  Future<void> _load() async {
    if (!mounted || !_reachable) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<GroupProvider>().groupSettings();
      if (!mounted) return;
      setState(() {
        _settings = result.settings;
        _usage = result.usage;
      });
    } on GroupActionException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({String? style, String? language}) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    setState(() => _saving = true);
    try {
      final saved = await context.read<GroupProvider>().updateGroupSettings(
        commentStyle: style,
        commentLanguage: language,
      );
      if (!mounted) return;
      setState(() => _settings = saved);
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupSettingsSaved)));
    } on GroupActionException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            groupActionErrorText(l10n, e),
            style: TextStyle(color: scheme.onError),
          ),
          backgroundColor: scheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _revision++;
        });
      }
    }
  }

  String _styleLabel(AppLocalizations l10n, String style) => switch (style) {
    'narrative' => l10n.groupCommentStyleNarrative,
    'humorous' => l10n.groupCommentStyleHumorous,
    'analytical' => l10n.groupCommentStyleAnalytical,
    _ => style,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configured = context.watch<BackendProvider>().isConfigured;
    final group = context.watch<GroupProvider>();

    final Widget body;
    if (!configured) {
      body = _Message(l10n.groupNeedsServer);
    } else if (!group.canReachGroup) {
      body = _Message(l10n.groupDescription);
    } else if (_settings == null) {
      body = _error == null || _loading
          ? const Center(child: CircularProgressIndicator())
          : _Message(
              groupActionErrorText(l10n, _error!),
              action: TextButton(
                key: const Key('group_settings_retry'),
                onPressed: _load,
                child: Text(l10n.retry),
              ),
            );
    } else {
      body = RefreshIndicator(onRefresh: _load, child: _content(l10n));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
      body: SafeArea(child: body),
    );
  }

  Widget _content(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final settings = _settings!;
    // A language the server holds but the app does not offer stays selectable.
    final languages = {
      ...GroupSettingsScreen.languages,
      if (!GroupSettingsScreen.languages.containsKey(settings.commentLanguage))
        settings.commentLanguage: settings.commentLanguage,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.groupSettingsDescription, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(l10n.groupCommentStyle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in GroupSettingsScreen.styles)
              ChoiceChip(
                key: Key('group_comment_style_$style'),
                label: Text(_styleLabel(l10n, style)),
                selected: settings.commentStyle == style,
                onSelected: _saving
                    ? null
                    : (_) {
                        if (settings.commentStyle != style) _save(style: style);
                      },
              ),
          ],
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: ValueKey(_revision),
          child: DropdownButtonFormField<String>(
            key: const Key('group_comment_language'),
            initialValue: settings.commentLanguage,
            decoration: InputDecoration(
              labelText: l10n.groupCommentLanguage,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final e in languages.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: _saving
                ? null
                : (code) {
                    if (code != null && code != settings.commentLanguage) {
                      _save(language: code);
                    }
                  },
          ),
        ),
        const SizedBox(height: 24),
        if (_usage != null) _UsageCard(usage: _usage!),
      ],
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});

  final GroupUsage usage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = NumberFormat.simpleCurrency(
      locale: l10n.localeName,
      name: 'USD',
    );
    final fraction = usage.budgetCents <= 0
        ? 1.0
        : (usage.usedCents / usage.budgetCents).clamp(0.0, 1.0);
    final exhausted = usage.usedCents >= usage.budgetCents;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.groupUsageTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              l10n.groupUsageAmount(
                money.format(usage.usedCents / 100),
                money.format(usage.budgetCents / 100),
              ),
              key: const Key('group_usage_amount'),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: fraction,
              color: exhausted ? theme.colorScheme.error : null,
            ),
            if (usage.resetsAt != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.groupUsageResets(
                  DateFormat.yMMMd(l10n.localeName)
                      .format(usage.resetsAt!.toLocal()),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
