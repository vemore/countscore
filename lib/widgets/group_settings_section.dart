import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import 'group_devices_sheet.dart';

/// The message shown for a failed group action.
String groupActionErrorText(AppLocalizations l10n, GroupActionException e) => switch (e.error) {
      GroupActionError.unknownShareToken => l10n.groupErrorUnknownToken,
      GroupActionError.rateLimited => l10n.groupErrorRateLimited,
      GroupActionError.unreachable => l10n.groupErrorUnreachable,
      GroupActionError.server => l10n.groupErrorServer,
      GroupActionError.invalidPlayerNames => l10n.invalidPlayerNamesForSync(e.detail.join(', ')),
    };

/// Settings → Group: create or join a group, show its invite code and devices,
/// leave it, and say where sync stands. Only usable once a server URL is set.
class GroupSettingsSection extends StatefulWidget {
  const GroupSettingsSection({super.key});

  @override
  State<GroupSettingsSection> createState() => _GroupSettingsSectionState();
}

class _GroupSettingsSectionState extends State<GroupSettingsSection> {
  bool _busy = false;

  void _snack(String message, {bool ok = true}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: ok ? null : scheme.onError)),
      backgroundColor: ok ? null : scheme.error,
    ));
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && done != null) _snack(done);
    } on GroupActionException catch (e) {
      if (mounted) _snack(groupActionErrorText(l10n, e), ok: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for one or two text values; null when cancelled.
  Future<List<String>?> _ask({
    required String title,
    required List<({String label, String initial, String? hint})> fields,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => _TextFieldsDialog(title: title, fields: fields),
    );
  }

  Future<bool> _confirm(String message, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _create(GroupProvider group) async {
    final l10n = AppLocalizations.of(context)!;
    final values = await _ask(title: l10n.groupCreate, fields: [
      (label: l10n.groupNameLabel, initial: '', hint: null),
      (label: l10n.deviceLabelLabel, initial: l10n.deviceLabelDefault, hint: null),
    ]);
    if (values == null) return;
    await _run(() => group.createGroup(values[0], values[1]), done: l10n.groupJoined);
  }

  Future<void> _join(GroupProvider group) async {
    final l10n = AppLocalizations.of(context)!;
    final values = await _ask(title: l10n.groupJoin, fields: [
      (label: l10n.shareTokenLabel, initial: '', hint: l10n.shareTokenHint),
      (label: l10n.deviceLabelLabel, initial: l10n.deviceLabelDefault, hint: null),
    ]);
    if (values == null) return;
    await _run(() => group.joinGroup(values[0], values[1]), done: l10n.groupJoined);
  }

  String _statusText(AppLocalizations l10n, GroupProvider group) {
    return switch (group.status) {
      SyncStatus.syncing => l10n.syncStatusSyncing,
      SyncStatus.offline => l10n.syncStatusOffline,
      SyncStatus.unauthorized => l10n.syncStatusUnauthorized,
      SyncStatus.error => l10n.syncStatusError,
      SyncStatus.idle || SyncStatus.off => group.lastSyncAt == null
          ? l10n.syncStatusSyncing
          : l10n.syncStatusIdle(DateFormat.Hm(l10n.localeName).format(group.lastSyncAt!)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final configured = context.watch<BackendProvider>().isConfigured;
    final group = context.watch<GroupProvider>();

    final children = <Widget>[
      Text(l10n.groupDescription, style: theme.textTheme.bodySmall),
      const SizedBox(height: 12),
    ];

    if (!configured) {
      children.add(Text(l10n.groupNeedsServer));
    } else if (!group.isJoined) {
      children.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('group_create'),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.groupCreate),
            onPressed: _busy ? null : () => _create(group),
          ),
          OutlinedButton.icon(
            key: const Key('group_join'),
            icon: const Icon(Icons.login),
            label: Text(l10n.groupJoin),
            onPressed: _busy ? null : () => _join(group),
          ),
        ],
      ));
    } else {
      final problem = group.status == SyncStatus.offline ||
          group.status == SyncStatus.unauthorized ||
          group.status == SyncStatus.error;
      children.addAll([
        Text(l10n.groupCurrent(group.groupName ?? ''), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (group.shareToken != null) ...[
          Text(l10n.shareTokenLabel, style: theme.textTheme.labelMedium),
          SelectableText(
            group.shareToken!,
            key: const Key('group_share_token'),
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
          Text(l10n.shareTokenExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(
              problem ? Icons.cloud_off : Icons.cloud_done,
              size: 18,
              color: problem ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_statusText(l10n, group))),
          ],
        ),
        if (group.pendingChanges > 0) Text(l10n.syncPending(group.pendingChanges)),
        if (group.rejectedChanges > 0)
          Text(
            l10n.syncRejected(group.rejectedChanges),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const Key('group_sync_now'),
              icon: const Icon(Icons.sync),
              label: Text(l10n.syncNow),
              onPressed: group.status == SyncStatus.syncing ? null : group.syncNow,
            ),
            if (group.shareToken != null)
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l10n.shareTokenCopy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: group.shareToken!));
                  if (mounted) _snack(l10n.shareTokenCopied);
                },
              ),
            TextButton.icon(
              key: const Key('group_devices'),
              icon: const Icon(Icons.devices),
              label: Text(l10n.groupDevices),
              onPressed: () => GroupDevicesSheet.show(context),
            ),
            TextButton.icon(
              icon: const Icon(Icons.autorenew),
              label: Text(l10n.shareTokenRotate),
              onPressed: _busy
                  ? null
                  : () async {
                      if (!await _confirm(l10n.shareTokenRotateConfirm, l10n.shareTokenRotate)) {
                        return;
                      }
                      await _run(group.rotateShareToken);
                    },
            ),
            TextButton.icon(
              key: const Key('group_leave'),
              icon: const Icon(Icons.logout),
              label: Text(l10n.groupLeave),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _busy
                  ? null
                  : () async {
                      if (!await _confirm(l10n.groupLeaveConfirm, l10n.groupLeave)) return;
                      await _run(group.leave, done: l10n.groupLeft);
                    },
            ),
          ],
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}


/// A dialog of one or more text fields that owns its controllers.
///
/// The controllers must outlive the dialog's exit transition, which keeps
/// rebuilding the fields after `showDialog` has returned: disposing them in the
/// caller as soon as the future completes trips `_dependents.isEmpty` in debug
/// builds. Here they are disposed with the dialog's own state.
class _TextFieldsDialog extends StatefulWidget {
  const _TextFieldsDialog({required this.title, required this.fields});

  final String title;
  final List<({String label, String initial, String? hint})> fields;

  @override
  State<_TextFieldsDialog> createState() => _TextFieldsDialogState();
}

class _TextFieldsDialogState extends State<_TextFieldsDialog> {
  late final List<TextEditingController> _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            TextField(
              key: Key('group_field_$i'),
              controller: _controllers[i],
              autofocus: i == 0,
              maxLength: 64,
              decoration: InputDecoration(
                labelText: widget.fields[i].label,
                hintText: widget.fields[i].hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('group_dialog_ok'),
          onPressed: () {
            final values = [for (final c in _controllers) c.text.trim()];
            if (values.any((v) => v.isEmpty)) return;
            Navigator.pop(context, values);
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
