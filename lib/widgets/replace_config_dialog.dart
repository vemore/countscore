import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../utils/config_link.dart';
import 'group_settings_section.dart'
    show groupActionErrorText, groupFieldFormatter, groupFieldMaxLength;

/// What [showReplaceConfigDialog] did.
enum ReplaceConfigResult {
  /// The user said no, at either question, or the link was not valid. Nothing changed.
  cancelled,

  /// This device already uses that server and that group, possibly behind an
  /// older invite code (then the newer one is stored). Nothing else changed.
  unchanged,

  /// The server and the group are the link's now.
  applied,

  /// The link's group refused this device or could not be reached. Nothing
  /// changed; the snackbar says why.
  joinFailed,
}

/// Offers to replace this device's server and group with [config], the parsed
/// content of a shared configuration link ([parseConfigLink]), showing the
/// current and the new values. Nothing changes unless the user confirms.
///
/// A group is joined **before** anything is left ([GroupProvider.prepareJoin]):
/// when the join fails (an old invite code, a rate limit, no network) the current
/// server and group stay exactly as they were. Once the server has accepted the
/// device, the link's group may turn out to be the one this device is already in
/// (same group, newer code): then nothing is left at all. Otherwise, before the
/// current group is left, a second question comes when the first did not say so
/// or when changes are still waiting to reach that group, counted at that moment
/// ([GroupProvider.countPending]); backing out there withdraws the new
/// registration ([GroupProvider.cancelJoin]).
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
    currentGroup: group.isJoined ? currentGroupLabel(l10n, group) : null,
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

  /// Asks before the current group is left; true to go on.
  Future<bool> mayLeave() async {
    final pending = await group.countPending();
    if (pending == 0 && plan.announcesLeaving) return true;
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(
          pending > 0
              ? l10n.replaceConfigUnsynced(pending)
              : l10n.replaceConfigLeavesGroup(plan.currentGroup!),
          key: const Key('replace_config_leave_question'),
        ),
        actions: [
          TextButton(
            key: const Key('replace_config_leave_cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('replace_config_leave_anyway'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(pending > 0 ? l10n.replaceConfigLeaveAnyway : l10n.groupLeave),
          ),
        ],
      ),
    );
    return ok == true;
  }

  if (!plan.joinsGroup) {
    // A server alone, another one: a group on the old server cannot follow.
    if (group.isJoined) {
      if (!await mayLeave()) return ReplaceConfigResult.cancelled;
      await group.leave();
    }
    await backend.setBaseUrl(server);
    // The proxy provider hands the URL over on its next rebuild; now is sooner.
    await group.updateBackend(server);
    snack(l10n.replaceConfigDone);
    return ReplaceConfigResult.applied;
  }

  final JoinCandidate candidate;
  try {
    candidate = await group.prepareJoin(server, config.invite!, nickname);
  } on GroupActionException catch (e) {
    snack(groupActionErrorText(l10n, e));
    return ReplaceConfigResult.joinFailed;
  }
  if (!candidate.sameGroup && group.isJoined && !await mayLeave()) {
    await group.cancelJoin(candidate);
    return ReplaceConfigResult.cancelled;
  }
  // Leaves the current group on its own server, then syncs with the new one; the
  // new URL reaches the disk with the membership (GroupProvider), and the live
  // BackendProvider right after.
  await group.completeJoin(candidate);
  if (plan.changesServer) await backend.setBaseUrl(server);
  if (candidate.sameGroup && !plan.changesServer) {
    snack(l10n.replaceConfigUnchanged);
    return ReplaceConfigResult.unchanged;
  }
  snack(l10n.replaceConfigDone);
  return ReplaceConfigResult.applied;
}

/// How the current group is named on screen: its name, or its invite code when
/// the name is not known (a membership recorded before names were kept).
String currentGroupLabel(AppLocalizations l10n, GroupProvider group) {
  final name = group.groupName?.trim() ?? '';
  if (name.isNotEmpty) return name;
  final code = group.shareToken;
  return code == null ? l10n.groupSection : l10n.replaceConfigInvite(code);
}

/// What replacing the current configuration with a link's would change, as far
/// as it can be known before asking the server.
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

  /// The current group, as [currentGroupLabel] names it; null when this device
  /// is in no group.
  final String? currentGroup;
  final String? currentInvite;
  final String newServer;

  /// The link's invite code; null for a link carrying a server alone.
  final String? newInvite;

  bool get changesServer => newServer != currentServer;

  /// A group is joined: the link has one, and not the very code this device
  /// already holds on this server. It may still turn out to be this device's
  /// group behind a newer code; only the server can tell.
  bool get joinsGroup =>
      newInvite != null && (changesServer || currentGroup == null || newInvite != currentInvite);

  /// The first question already says the current group is left: another server
  /// cannot hold it. On the same server only the join's answer tells.
  bool get announcesLeaving => currentGroup != null && changesServer;

  bool get changesAnything => changesServer || joinsGroup;
}

/// The question itself: current and new server, current and new group, a warning
/// when the current group is certainly left, and the nickname field when a group
/// is joined. Pops the trimmed nickname (empty when none is needed) on *Replace*,
/// null on *Cancel*. Public for the join route and the Android deep link.
class ReplaceConfigDialog extends StatefulWidget {
  const ReplaceConfigDialog({super.key, required this.plan});

  final ReplaceConfigPlan plan;

  @override
  State<ReplaceConfigDialog> createState() => _ReplaceConfigDialogState();
}

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
    final newGroup = plan.joinsGroup
        ? l10n.replaceConfigInvite(plan.newInvite!)
        : plan.announcesLeaving || plan.currentGroup == null
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
            if (plan.announcesLeaving)
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
                // The server counts code points, as in Settings → Group.
                inputFormatters: [groupFieldFormatter],
                decoration: InputDecoration(
                  labelText: l10n.groupNicknameLabel,
                  helperText: l10n.groupNicknameHint,
                  helperMaxLines: 2,
                  counterText: '${_nickname.text.runes.length}/$groupFieldMaxLength',
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
