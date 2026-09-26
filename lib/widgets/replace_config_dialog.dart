import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../utils/config_link.dart';
import 'group_settings_section.dart' show groupActionErrorText;

/// What [showReplaceConfigDialog] did.
enum ReplaceConfigResult {
  /// The user said no, at either question, or the link was not valid. Nothing changed.
  cancelled,

  /// This device already uses that server and that group. Nothing asked, nothing changed.
  unchanged,

  /// The server and the group are the link's now.
  applied,

  /// The server is the link's, but joining its group failed; the snackbar says why,
  /// and Settings → Group can try again.
  joinFailed,
}

/// Offers to replace this device's server and group with [config], the parsed
/// content of a shared configuration link ([parseConfigLink]), showing the
/// current and the new values. Nothing changes unless the user confirms.
///
/// Joining goes through [GroupProvider.joinGroup], so it asks for this device's
/// nickname like Settings → Group does, and inherits the sync behaviour. When the
/// change leaves a group — another server, or another group — and that group
/// still holds changes this device has not synced ([GroupProvider.pendingChanges]),
/// a second question warns that leaving discards them.
///
/// The server is left replaced when joining fails: it is valid, and the group can
/// be joined again from Settings. The outcome is also shown as a snackbar.
Future<ReplaceConfigResult> showReplaceConfigDialog(
  BuildContext context,
  ConfigLink config,
) async {
  final l10n = AppLocalizations.of(context)!;
  final backend = context.read<BackendProvider>();
  final group = context.read<GroupProvider>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  void snack(String text) => messenger?.showSnackBar(SnackBar(content: Text(text)));

  final server = BackendProvider.check(config.server).url;
  if (server == null) {
    snack(l10n.backendUrlInvalid);
    return ReplaceConfigResult.cancelled;
  }
  final plan = ReplaceConfigPlan(
    currentServer: backend.baseUrl,
    currentGroup: group.isJoined ? group.groupName ?? '' : null,
    currentInvite: group.isJoined ? group.shareToken : null,
    newServer: server,
    newInvite: config.invite,
  );
  if (!plan.changesAnything) {
    snack(l10n.replaceConfigUnchanged);
    return ReplaceConfigResult.unchanged;
  }

  final nickname = await showDialog<String>(
    context: context,
    builder: (_) => ReplaceConfigDialog(plan: plan),
  );
  if (nickname == null || !context.mounted) return ReplaceConfigResult.cancelled;

  final pending = group.pendingChanges;
  if (plan.leavesGroup && pending > 0) {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(l10n.replaceConfigUnsynced(pending), key: const Key('replace_config_unsynced')),
        actions: [
          TextButton(
            key: const Key('replace_config_unsynced_cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('replace_config_leave_anyway'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.replaceConfigLeaveAnyway),
          ),
        ],
      ),
    );
    if (leave != true) return ReplaceConfigResult.cancelled;
  }

  // Leave first, while the group's own server is still the configured one, so
  // the device is revoked where it was registered.
  if (plan.leavesGroup) await group.leave();
  if (plan.changesServer) {
    await backend.setBaseUrl(server);
    // The proxy provider hands the URL over on its next rebuild; joining needs
    // it now. A second call with the same URL returns at once.
    await group.updateBackend(server);
  }
  if (plan.joinsGroup) {
    try {
      await group.joinGroup(config.invite!, nickname);
    } on GroupActionException catch (e) {
      snack(groupActionErrorText(l10n, e));
      return ReplaceConfigResult.joinFailed;
    }
  }
  snack(l10n.replaceConfigDone);
  return ReplaceConfigResult.applied;
}

/// What replacing the current configuration with a link's would change.
@immutable
class ReplaceConfigPlan {
  const ReplaceConfigPlan({
    required this.currentServer,
    required this.currentGroup,
    required this.currentInvite,
    required this.newServer,
    required this.newInvite,
  });

  final String? currentServer;

  /// The current group's name; null when this device is in no group.
  final String? currentGroup;
  final String? currentInvite;
  final String newServer;

  /// The link's invite code; null for a link carrying a server alone.
  final String? newInvite;

  bool get changesServer => newServer != currentServer;

  /// A group is joined: the link has one, and it is not the one this device is
  /// already in on this same server.
  bool get joinsGroup =>
      newInvite != null && (changesServer || currentGroup == null || newInvite != currentInvite);

  /// The current group is left: its server goes, or another group replaces it.
  bool get leavesGroup => currentGroup != null && (changesServer || joinsGroup);

  bool get changesAnything => changesServer || joinsGroup;
}

/// The question itself: current and new server, current and new group, a warning
/// when the current group is left, and the nickname field when a group is joined.
/// Pops the trimmed nickname (empty when none is needed) on *Replace*, null on
/// *Cancel*. Public for the join route and the Android deep link, which build on it.
class ReplaceConfigDialog extends StatefulWidget {
  const ReplaceConfigDialog({super.key, required this.plan});

  final ReplaceConfigPlan plan;

  @override
  State<ReplaceConfigDialog> createState() => _ReplaceConfigDialogState();
}

/// The server's limit on a device label, in code points (as in Settings → Group).
const _maxLabel = 64;

class _ReplaceConfigDialogState extends State<ReplaceConfigDialog> {
  final _nickname = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nickname.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  bool get _complete => !widget.plan.joinsGroup || _nickname.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plan = widget.plan;
    final newGroup = plan.newInvite != null && plan.joinsGroup
        ? l10n.replaceConfigInvite(plan.newInvite!)
        : plan.leavesGroup || plan.currentGroup == null
            ? l10n.none
            : plan.currentGroup!;

    Widget values(String heading, String now, String next, String key) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: theme.textTheme.labelLarge),
              Text(l10n.replaceConfigCurrent(now), key: Key('replace_config_${key}_current')),
              Text(l10n.replaceConfigNew(next), key: Key('replace_config_${key}_new')),
            ],
          ),
        );

    return AlertDialog(
      title: Text(l10n.replaceConfigTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            values(l10n.serverSection, plan.currentServer ?? l10n.none, plan.newServer, 'server'),
            values(l10n.groupSection, plan.currentGroup ?? l10n.none, newGroup, 'group'),
            if (plan.leavesGroup)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.replaceConfigLeavesGroup(plan.currentGroup!),
                  key: const Key('replace_config_leaves_group'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (plan.joinsGroup)
              TextField(
                key: const Key('replace_config_nickname'),
                controller: _nickname,
                autofocus: true,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      newValue.text.runes.length > _maxLabel ? oldValue : newValue),
                ],
                decoration: InputDecoration(
                  labelText: l10n.groupNicknameLabel,
                  helperText: l10n.groupNicknameHint,
                  helperMaxLines: 2,
                  counterText: '${_nickname.text.runes.length}/$_maxLabel',
                  border: const OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('replace_config_cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('replace_config_confirm'),
          onPressed: _complete ? () => Navigator.pop(context, _nickname.text.trim()) : null,
          child: Text(l10n.replaceConfigConfirm),
        ),
      ],
    );
  }
}
