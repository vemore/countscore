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

  /// The server and the group are the link's now — on the same server, the
  /// link's group beside the others.
  applied,

  /// The link's group refused this device or could not be reached, or would
  /// have been one group too many. Nothing changed; the snackbar says why.
  joinFailed,
}

/// Opens [config], the parsed content of a shared configuration link
/// ([parseConfigLink]). Nothing changes unless the user confirms.
///
/// - **The server this device uses, with a group, while in a group already**:
///   "join this group too?" ([JoinGroupTooDialog]) — every group stays
///   (decision 7 of the multi-group plan). A code this device already holds
///   changes nothing and says so, with no request; neither does a newer code of
///   a group already joined, which only the server can recognise.
/// - **Otherwise** — another server, or no group yet — the configuration is
///   replaced ([ReplaceConfigDialog]), showing the current and the new values;
///   another server leaves every group (decision 4).
///
/// A group is joined **before** anything is left ([GroupProvider.prepareJoin]):
/// when the join fails (an old invite code, a rate limit, no network) the current
/// server and groups stay exactly as they were. Once the server has accepted the
/// device, the link's group may turn out to be one this device is already in
/// (same group, newer code): then nothing is left at all. Otherwise, before the
/// current groups are left, a second question comes when the first did not say so
/// or when changes are still waiting to reach them, counted at that moment
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
  final groups = group.memberships;
  final invite = config.invite;
  if (invite != null && server == backend.baseUrl && groups.isNotEmpty) {
    return _joinToo(context, group, server, invite, snack);
  }
  final plan = ReplaceConfigPlan(
    currentServer: backend.baseUrl,
    currentGroup: groups.isEmpty ? null : groupsLabel(l10n, groups),
    currentGroupCount: groups.length,
    newServer: server,
    newInvite: invite,
  );
  if (!plan.changesAnything) {
    snack(l10n.replaceConfigUnchanged);
    return ReplaceConfigResult.unchanged;
  }

  final nickname = await showDialog<String>(
    context: context,
    builder: (_) => ReplaceConfigDialog(plan: plan, nickname: group.nickname),
  );
  if (nickname == null || !context.mounted) return ReplaceConfigResult.cancelled;

  /// Asks before the current groups are left; true to go on.
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
              : l10n.replaceConfigLeavesGroups(plan.currentGroupCount, plan.currentGroup!),
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
    // A server alone, another one: the groups on the old server cannot follow.
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
    candidate = await group.prepareJoin(server, invite!, nickname);
  } on GroupActionException catch (e) {
    snack(groupActionErrorText(l10n, e));
    return ReplaceConfigResult.joinFailed;
  }
  if (!candidate.sameGroup && group.isJoined && !await mayLeave()) {
    await group.cancelJoin(candidate);
    return ReplaceConfigResult.cancelled;
  }
  // Leaves the current groups on their own server, then syncs with the new one;
  // the new URL reaches the disk with the membership (GroupProvider), and the
  // live BackendProvider right after.
  try {
    await group.completeJoin(candidate);
  } on GroupActionException catch (e) {
    snack(groupActionErrorText(l10n, e));
    return ReplaceConfigResult.joinFailed;
  }
  if (plan.changesServer) await backend.setBaseUrl(server);
  if (candidate.sameGroup && !plan.changesServer) {
    snack(l10n.replaceConfigUnchanged);
    return ReplaceConfigResult.unchanged;
  }
  snack(l10n.replaceConfigDone);
  return ReplaceConfigResult.applied;
}

/// A group link on the server this device already uses, while in a group:
/// joined beside the others, or nothing when it is one of them.
Future<ReplaceConfigResult> _joinToo(
  BuildContext context,
  GroupProvider group,
  String server,
  String invite,
  void Function(String) snack,
) async {
  final l10n = AppLocalizations.of(context)!;
  final held = group.sessionByInvite(invite);
  if (held != null) {
    snack(l10n.joinLinkAlreadyMember(groupLabel(l10n, held)));
    return ReplaceConfigResult.unchanged;
  }
  if (!group.canJoinMore) {
    snack(l10n.groupErrorTooManyGroups(GroupProvider.maxGroups));
    return ReplaceConfigResult.joinFailed;
  }
  final nickname = await showDialog<String>(
    context: context,
    builder: (_) => JoinGroupTooDialog(
      invite: invite,
      currentGroups: groupsLabel(l10n, group.memberships),
      nickname: group.nickname,
    ),
  );
  if (nickname == null || !context.mounted) return ReplaceConfigResult.cancelled;

  try {
    final candidate = await group.prepareJoin(server, invite, nickname);
    await group.completeJoin(candidate);
    final joined = group.session(candidate.membership.groupId);
    if (candidate.sameGroup) {
      // A newer code of a group already joined: stored, nothing else.
      snack(l10n.joinLinkAlreadyMember(
          joined == null ? candidate.membership.groupName : groupLabel(l10n, joined)));
      return ReplaceConfigResult.unchanged;
    }
  } on GroupActionException catch (e) {
    snack(groupActionErrorText(l10n, e));
    return ReplaceConfigResult.joinFailed;
  }
  snack(l10n.groupJoined);
  return ReplaceConfigResult.applied;
}

/// How a group is named on screen: its name, or its invite code when the name
/// is not known (a membership recorded before names were kept).
String groupLabel(AppLocalizations l10n, GroupSession s) {
  final name = s.groupName.trim();
  if (name.isNotEmpty) return name;
  final code = s.shareToken;
  return code == null ? l10n.groupSection : l10n.replaceConfigInvite(code);
}

/// Every group of [groups], by [groupLabel], in the order they were joined.
String groupsLabel(AppLocalizations l10n, List<GroupSession> groups) =>
    [for (final s in groups) groupLabel(l10n, s)].join(', ');

/// What replacing the current configuration with a link's would change, as far
/// as it can be known before asking the server. Not used for a group link on
/// the same server while in a group: that one is joined beside the others.
@immutable
class ReplaceConfigPlan {
  const ReplaceConfigPlan({
    required this.currentServer,
    required this.currentGroup,
    this.currentGroupCount = 1,
    required this.newServer,
    required this.newInvite,
  });

  final String? currentServer;

  /// The current groups, as [groupsLabel] names them; null when this device
  /// is in none.
  final String? currentGroup;

  /// How many groups [currentGroup] names.
  final int currentGroupCount;
  final String newServer;

  /// The link's invite code; null for a link carrying a server alone.
  final String? newInvite;

  bool get changesServer => newServer != currentServer;

  /// A group is joined: the link has one, on another server or while this
  /// device is in none.
  bool get joinsGroup => newInvite != null && (changesServer || currentGroup == null);

  /// The first question already says the current groups are left: another
  /// server cannot hold them.
  bool get announcesLeaving => currentGroup != null && changesServer;

  bool get changesAnything => changesServer || joinsGroup;
}

/// The question itself: current and new server, current and new group, a warning
/// when the current group is certainly left, and the nickname field when a group
/// is joined. Pops the trimmed nickname (empty when none is needed) on *Replace*,
/// null on *Cancel*. Public for the join route and the Android deep link.
class ReplaceConfigDialog extends StatefulWidget {
  const ReplaceConfigDialog({super.key, required this.plan, this.nickname});

  final ReplaceConfigPlan plan;

  /// The nickname this device already goes by, which the field starts from.
  final String? nickname;

  @override
  State<ReplaceConfigDialog> createState() => _ReplaceConfigDialogState();
}

class _ReplaceConfigDialogState extends State<ReplaceConfigDialog> {
  late final _nickname = TextEditingController(text: widget.nickname ?? '');

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
            values(plan.currentGroupCount > 1 ? l10n.groupsSection : l10n.groupSection,
                plan.currentGroup ?? l10n.none, newGroup, 'group'),
            if (plan.announcesLeaving)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.replaceConfigLeavesGroups(plan.currentGroupCount, plan.currentGroup!),
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

/// "Join this group too?": the link's group on the server this device already
/// uses, beside [currentGroups], which stay. Pops the trimmed nickname on
/// *Join*, null on *Cancel*. The nickname is the one every group shares,
/// filled in when this device has one.
class JoinGroupTooDialog extends StatefulWidget {
  const JoinGroupTooDialog({
    super.key,
    required this.invite,
    required this.currentGroups,
    this.nickname,
  });

  final String invite;
  final String currentGroups;
  final String? nickname;

  @override
  State<JoinGroupTooDialog> createState() => _JoinGroupTooDialogState();
}

class _JoinGroupTooDialogState extends State<JoinGroupTooDialog> {
  late final _nickname = TextEditingController(text: widget.nickname ?? '')
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _nickname.text.trim();
    return AlertDialog(
      title: Text(l10n.joinGroupTooTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.joinGroupTooBody(widget.invite, widget.currentGroups),
              key: const Key('join_group_too_body'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('replace_config_nickname'),
              controller: _nickname,
              autofocus: widget.nickname == null,
              // The server counts code points, as in Settings → Groups.
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
          key: const Key('join_group_too_confirm'),
          onPressed: name.isEmpty ? null : () => Navigator.pop(context, name),
          child: Text(l10n.joinGroupTooConfirm),
        ),
      ],
    );
  }
}
