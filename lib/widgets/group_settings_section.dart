import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../screens/group_settings_screen.dart';
import 'config_share_sheet.dart';
import 'group_devices_sheet.dart';

/// The message shown for a failed group action.
String groupActionErrorText(AppLocalizations l10n, GroupActionException e) => switch (e.error) {
      GroupActionError.unknownShareToken => l10n.groupErrorUnknownToken,
      GroupActionError.rateLimited => l10n.groupErrorRateLimited,
      GroupActionError.unreachable => l10n.groupErrorUnreachable,
      GroupActionError.server => l10n.groupErrorServer,
      GroupActionError.invalidPlayerNames => l10n.invalidPlayerNamesForSync(e.detail.join(', ')),
      GroupActionError.notOwner => l10n.groupErrorNotOwner,
      GroupActionError.ownerActive => l10n.groupErrorOwnerActive,
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

  @override
  void initState() {
    super.initState();
    // After an offline start the nickname is still unknown: opening the section
    // is one more chance to read it (the provider also retries on its own).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupProvider>().refreshDeviceLabel();
    });
  }

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

  /// Asks for one or two text values, trimmed and none blank; null when cancelled.
  Future<List<String>?> _ask({
    required String title,
    required List<_Field> fields,
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

  /// The nickname field, first in the create and join dialogs and alone in the
  /// rename one. It starts empty on joining: a pre-filled default was left as it
  /// was, and a group's devices could no longer be told apart.
  _Field _nicknameField(AppLocalizations l10n, {String initial = ''}) => (
        key: const Key('group_nickname_field'),
        label: l10n.groupNicknameLabel,
        initial: initial,
        hint: null,
        helper: l10n.groupNicknameHint,
      );

  Future<void> _create(GroupProvider group) async {
    final l10n = AppLocalizations.of(context)!;
    final values = await _ask(title: l10n.groupCreate, fields: [
      _nicknameField(l10n),
      (
        key: const Key('group_name_field'),
        label: l10n.groupNameLabel,
        initial: '',
        hint: null,
        helper: null,
      ),
    ]);
    if (values == null) return;
    // The creator owns the group, and nothing on screen says so otherwise: the one
    // line that follows is where the user learns the role lives on this device and
    // can be handed to another one.
    await _run(() => group.createGroup(values[1], values[0]),
        done: l10n.groupCreatedOwnerExplain);
  }

  Future<void> _join(GroupProvider group) async {
    final l10n = AppLocalizations.of(context)!;
    final values = await _ask(title: l10n.groupJoin, fields: [
      _nicknameField(l10n),
      (
        key: const Key('group_invite_field'),
        label: l10n.shareTokenLabel,
        initial: '',
        hint: l10n.shareTokenHint,
        helper: null,
      ),
    ]);
    if (values == null) return;
    await _run(() => group.joinGroup(values[1], values[0]), done: l10n.groupJoined);
  }

  Future<void> _rename(GroupProvider group) async {
    final l10n = AppLocalizations.of(context)!;
    final values = await _ask(
      title: l10n.groupNicknameEdit,
      fields: [_nicknameField(l10n, initial: group.deviceLabel ?? '')],
    );
    // Unchanged (the dialog trims): nothing to send.
    if (values == null || values[0] == group.deviceLabel) return;
    await _run(() => group.renameDevice(values[0]));
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
      final nickname = group.deviceLabel;
      children.addAll([
        Text(l10n.groupCurrent(group.groupName ?? ''), style: theme.textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: Text(
                nickname == null ? l10n.groupNicknameLabel : l10n.groupNicknameCurrent(nickname),
                key: const Key('group_nickname'),
              ),
            ),
            IconButton(
              key: const Key('group_nickname_edit'),
              icon: const Icon(Icons.edit),
              tooltip: l10n.groupNicknameEdit,
              onPressed: _busy ? null : () => _rename(group),
            ),
          ],
        ),
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
            if (group.shareToken != null)
              TextButton.icon(
                key: const Key('group_share_qr'),
                icon: const Icon(Icons.qr_code_2),
                label: Text(l10n.configShareOpen),
                onPressed: () => ConfigShareSheet.show(context),
              ),
            TextButton.icon(
              key: const Key('group_devices'),
              icon: const Icon(Icons.devices),
              label: Text(l10n.groupDevices),
              onPressed: () => GroupDevicesSheet.show(context),
            ),
            TextButton.icon(
              key: const Key('group_settings_open'),
              icon: const Icon(Icons.tune),
              label: Text(l10n.groupSettingsTitle),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GroupSettingsScreen()),
              ),
            ),
            // The server refuses a rotation from any device but the owner.
            if (group.isOwner)
              TextButton.icon(
                key: const Key('group_rotate_share_token'),
                icon: const Icon(Icons.autorenew),
                label: Text(l10n.shareTokenRotate),
                onPressed: _busy
                    ? null
                    : () async {
                        if (!await _confirm(
                            l10n.shareTokenRotateConfirm, l10n.shareTokenRotate)) {
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


/// The server's limit on a device label and a group name, in code points.
const _maxLength = 64;

final _maxCodePoints = TextInputFormatter.withFunction(
  (oldValue, newValue) => newValue.text.runes.length > _maxLength ? oldValue : newValue,
);

/// One field of [_TextFieldsDialog]. [hint] shows inside the empty field,
/// [helper] under it for as long as the dialog is open.
typedef _Field = ({Key key, String label, String initial, String? hint, String? helper});

/// A dialog of one or more required text fields that owns its controllers. OK
/// stays disabled while any field is blank, and returns the values trimmed.
///
/// The controllers must outlive the dialog's exit transition, which keeps
/// rebuilding the fields after `showDialog` has returned: disposing them in the
/// caller as soon as the future completes trips `_dependents.isEmpty` in debug
/// builds. Here they are disposed with the dialog's own state.
class _TextFieldsDialog extends StatefulWidget {
  const _TextFieldsDialog({required this.title, required this.fields});

  final String title;
  final List<_Field> fields;

  @override
  State<_TextFieldsDialog> createState() => _TextFieldsDialogState();
}

class _TextFieldsDialogState extends State<_TextFieldsDialog> {
  late final List<TextEditingController> _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial)..addListener(_changed),
  ];

  List<String> get _values => [for (final c in _controllers) c.text.trim()];

  bool get _complete => _values.every((v) => v.isNotEmpty);

  void _changed() => setState(() {});

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
              key: widget.fields[i].key,
              controller: _controllers[i],
              autofocus: i == 0,
              // The server counts code points, where `maxLength` counts grapheme
              // clusters: an emoji sequence would pass here and fail there.
              inputFormatters: [_maxCodePoints],
              decoration: InputDecoration(
                labelText: widget.fields[i].label,
                hintText: widget.fields[i].hint,
                counterText: '${_controllers[i].text.runes.length}/$_maxLength',
                helperText: widget.fields[i].helper,
                helperMaxLines: 2,
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
          onPressed: _complete ? () => Navigator.pop(context, _values) : null,
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
