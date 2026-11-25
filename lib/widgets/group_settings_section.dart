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
      GroupActionError.tooManyGroups => l10n.groupErrorTooManyGroups(GroupProvider.maxGroups),
    };

/// Settings → Groups: the groups this device is in, as a list — each with its
/// sync status, invite code, devices, comments and usage, and its own Leave —
/// the one nickname they share, and Create and Join while fewer than
/// [GroupProvider.maxGroups]. Only usable once a server URL is set.
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

  Future<bool> _confirm(String message, String action, {Key? key}) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(message, key: key),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  /// The nickname field, first in the create and join dialogs and alone in the
  /// rename one. It starts with the nickname this device already goes by — one
  /// for every group — and empty before any: a pre-filled default was left as
  /// it was, and a group's devices could no longer be told apart.
  _Field _nicknameField(AppLocalizations l10n, {String? initial}) => (
        key: const Key('group_nickname_field'),
        label: l10n.groupNicknameLabel,
        initial: initial ?? context.read<GroupProvider>().nickname ?? '',
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
      fields: [_nicknameField(l10n, initial: group.nickname ?? '')],
    );
    // Unchanged (the dialog trims): nothing to send.
    if (values == null || values[0] == group.nickname) return;
    await _run(() => group.renameDevice(values[0]));
  }

  Future<void> _leave(GroupProvider group, GroupSession s) async {
    final l10n = AppLocalizations.of(context)!;
    // Counted now, not read from the last sync pass: a write made a moment ago
    // is still waiting, and leaving drops what waits for that group.
    final pending = await group.countPending(s.groupId);
    if (!mounted) return;
    final ok = pending > 0
        ? await _confirm(
            l10n.replaceConfigUnsynced(pending),
            l10n.replaceConfigLeaveAnyway,
            key: const Key('group_leave_unsynced'),
          )
        : await _confirm(l10n.groupLeaveConfirmNamed(s.groupName), l10n.groupLeave);
    if (!ok) return;
    await _run(() => group.leaveGroup(s.groupId), done: l10n.groupLeft);
  }

  static bool _isProblem(SyncStatus status) =>
      status == SyncStatus.offline ||
      status == SyncStatus.unauthorized ||
      status == SyncStatus.error;

  String _statusText(AppLocalizations l10n, GroupSession s) {
    final at = s.lastSyncAt;
    return switch (s.status) {
      SyncStatus.syncing => l10n.syncStatusSyncing,
      SyncStatus.offline => l10n.syncStatusOffline,
      SyncStatus.unauthorized => l10n.syncStatusUnauthorized,
      SyncStatus.error => l10n.syncStatusError,
      SyncStatus.idle || SyncStatus.off => at == null
          ? l10n.syncStatusSyncing
          : l10n.syncStatusIdle(DateFormat.Hm(l10n.localeName).format(at)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final configured = context.watch<BackendProvider>().isConfigured;
    final group = context.watch<GroupProvider>();
    final groups = group.memberships;

    final children = <Widget>[
      Text(l10n.groupDescription, style: theme.textTheme.bodySmall),
      const SizedBox(height: 12),
    ];

    if (!configured) {
      children.add(Text(l10n.groupNeedsServer));
    } else {
      if (groups.isNotEmpty) {
        // One nickname for every group (decision 8): above the list, not in it.
        final nickname = group.nickname;
        children.add(Row(
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
        ));
        for (final s in groups) {
          children.add(_groupCard(group, s, expanded: groups.length == 1));
        }
        children.add(const SizedBox(height: 12));
      }
      // At the most groups one install may be in, nothing is offered that the
      // provider would refuse (decision 9).
      if (group.canJoinMore) {
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
        children.add(Text(
          l10n.groupsMaxReached(GroupProvider.maxGroups),
          key: const Key('group_max_reached'),
          style: theme.textTheme.bodySmall,
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  /// One group: its name and sync status, unfolded to its invite code, its
  /// waiting changes and its actions. Unfolded from the start when it is the
  /// only one.
  Widget _groupCard(GroupProvider group, GroupSession s, {required bool expanded}) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final problem = _isProblem(s.status);
    final code = s.shareToken;
    return Card(
      key: Key('group_card_${s.groupId}'),
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          problem ? Icons.cloud_off : Icons.cloud_done,
          color: problem ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        title: Text(s.groupName, key: const Key('group_name'), style: theme.textTheme.titleMedium),
        subtitle: Text(_statusText(l10n, s), key: const Key('group_status')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.centerLeft,
        children: [
          if (s.pendingChanges > 0) Text(l10n.syncPending(s.pendingChanges)),
          if (s.rejectedChanges > 0)
            Text(
              l10n.syncRejected(s.rejectedChanges),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (code != null) ...[
            const SizedBox(height: 8),
            Text(l10n.shareTokenLabel, style: theme.textTheme.labelMedium),
            SelectableText(
              code,
              key: const Key('group_share_token'),
              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
            Text(l10n.shareTokenExplain, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const Key('group_sync_now'),
                icon: const Icon(Icons.sync),
                label: Text(l10n.syncNow),
                onPressed: s.status == SyncStatus.syncing ? null : s.syncNow,
              ),
              if (code != null)
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.shareTokenCopy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (mounted) _snack(l10n.shareTokenCopied);
                  },
                ),
              if (code != null)
                TextButton.icon(
                  key: const Key('group_share_qr'),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(l10n.configShareOpen),
                  onPressed: () => ConfigShareSheet.show(context, groupId: s.groupId),
                ),
              TextButton.icon(
                key: const Key('group_devices'),
                icon: const Icon(Icons.devices),
                label: Text(l10n.groupDevices),
                onPressed: () => GroupDevicesSheet.show(context, s.groupId),
              ),
              TextButton.icon(
                key: const Key('group_settings_open'),
                icon: const Icon(Icons.tune),
                label: Text(l10n.groupSettingsTitle),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GroupSettingsScreen(groupId: s.groupId),
                  ),
                ),
              ),
              // The server refuses a rotation from any device but the owner.
              if (s.isOwner)
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
                          await _run(s.rotateShareToken);
                        },
                ),
              TextButton.icon(
                key: const Key('group_leave'),
                icon: const Icon(Icons.logout),
                label: Text(l10n.groupLeave),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: _busy ? null : () => _leave(group, s),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The server's limit on a device label and a group name, in code points. Shared
/// with the replace-configuration dialog's nickname field.
const groupFieldMaxLength = 64;

/// Stops a field at [groupFieldMaxLength] code points, as the server counts.
final groupFieldFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) => newValue.text.runes.length > groupFieldMaxLength ? oldValue : newValue,
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
              inputFormatters: [groupFieldFormatter],
              decoration: InputDecoration(
                labelText: widget.fields[i].label,
                hintText: widget.fields[i].hint,
                counterText: '${_controllers[i].text.runes.length}/$groupFieldMaxLength',
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
