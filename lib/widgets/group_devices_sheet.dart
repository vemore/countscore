import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/group_provider.dart';
import '../services/backend_client.dart';
import 'group_settings_section.dart' show groupActionErrorText;

/// Settings → Group → Devices: the group's devices, the one that owns the group,
/// and — for the owner only — a way to shut one out or hand the group over.
///
/// This device is marked and offers no revoke — leaving is the section's own
/// button, which also turns shared games back into local ones. A member that is
/// not the owner sees the list and nothing to act on.
class GroupDevicesSheet extends StatefulWidget {
  const GroupDevicesSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const GroupDevicesSheet(),
      );

  @override
  State<GroupDevicesSheet> createState() => _GroupDevicesSheetState();
}

class _GroupDevicesSheetState extends State<GroupDevicesSheet> {
  late Future<List<GroupDevice>> _devices;
  ({String text, bool error})? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _devices = context.read<GroupProvider>().devices();
  }

  Future<void> _revoke(GroupDevice device) async {
    final l10n = AppLocalizations.of(context)!;
    final group = context.read<GroupProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(l10n.groupDeviceRevokeConfirm(device.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            key: const Key('group_device_revoke_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.groupDeviceRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _act(
      () => group.revokeDevice(device.id),
      done: l10n.groupDeviceRevoked(device.label),
    );
  }

  Future<void> _makeOwner(GroupDevice device) async {
    final l10n = AppLocalizations.of(context)!;
    final group = context.read<GroupProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(l10n.groupDeviceMakeOwnerConfirm(device.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            key: const Key('group_device_make_owner_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.groupDeviceMakeOwner),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _act(
      () => group.transferOwnership(device.id),
      done: l10n.groupDeviceOwnerChanged(device.label),
    );
  }

  /// Takes the group over from an owner device that has gone quiet — a phone that
  /// uninstalled the app never leaves the group by itself. The server decides: it
  /// refuses while that device has been seen inside its dormancy window.
  Future<void> _claimOwnership(GroupDevice device) async {
    final l10n = AppLocalizations.of(context)!;
    final group = context.read<GroupProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmation),
        content: Text(l10n.groupDeviceClaimOwnerConfirm(device.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            key: const Key('group_device_claim_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.groupDeviceClaimOwner),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _act(group.claimOwnership, done: l10n.groupDeviceOwnerClaimed);
  }

  /// Runs an owner action, then reloads the list — on failure too, since a
  /// refusal usually means the owner changed meanwhile.
  Future<void> _act(Future<void> Function() action, {required String done}) async {
    final l10n = AppLocalizations.of(context)!;
    final group = context.read<GroupProvider>();
    setState(() => _busy = true);
    try {
      await action();
      _message = (text: done, error: false);
    } on GroupActionException catch (e) {
      _message = (text: groupActionErrorText(l10n, e), error: true);
    } finally {
      _devices = group.devices();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The owner's actions on another device: hand the group over, or shut it out.
  Widget _ownerActions(GroupDevice device, ThemeData theme, AppLocalizations l10n) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('group_device_make_owner_${device.id}'),
            icon: const Icon(Icons.key_outlined),
            tooltip: l10n.groupDeviceMakeOwner,
            onPressed: _busy ? null : () => _makeOwner(device),
          ),
          IconButton(
            key: Key('group_device_revoke_${device.id}'),
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: l10n.groupDeviceRevoke,
            color: theme.colorScheme.error,
            onPressed: _busy ? null : () => _revoke(device),
          ),
        ],
      );

  /// Offered to a member on the owner's row once the server reports that device
  /// dormant: without it, a group whose owner uninstalled the app keeps an owner
  /// that can never revoke a device or renew the invite code again.
  Widget _claimAction(GroupDevice device, AppLocalizations l10n) => IconButton(
        key: Key('group_device_claim_${device.id}'),
        icon: const Icon(Icons.key_outlined),
        tooltip: l10n.groupDeviceClaimOwner,
        onPressed: _busy ? null : () => _claimOwnership(device),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final group = context.watch<GroupProvider>();
    final ownId = group.deviceId;
    final isOwner = group.isOwner;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();
    final message = _message;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.groupDevices, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              isOwner ? l10n.groupDevicesExplain : l10n.groupDevicesExplainMember,
              style: theme.textTheme.bodySmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message.text,
                key: const Key('group_devices_message'),
                style: TextStyle(color: message.error ? theme.colorScheme.error : null),
              ),
            ],
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<GroupDevice>>(
                future: _devices,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final error = snapshot.error;
                  if (error != null) {
                    return Text(
                      error is GroupActionException
                          ? groupActionErrorText(l10n, error)
                          : l10n.groupErrorServer,
                      style: TextStyle(color: theme.colorScheme.error),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final device in snapshot.data ?? const <GroupDevice>[])
                        ListTile(
                          key: Key('group_device_${device.id}'),
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            device.id == ownId ? Icons.smartphone : Icons.devices_other,
                          ),
                          title: Text(device.label),
                          subtitle: Text([
                            if (device.isOwner == true) l10n.groupDeviceOwner,
                            l10n.groupDeviceLastSeen(
                              dateFormat.format(device.lastSeenAt.toLocal()),
                            ),
                          ].join(' · ')),
                          // Only the owner acts on another device; the server
                          // refuses anyone else. The one exception is the claim: a
                          // member may take the role from an owner gone quiet.
                          trailing: device.id == ownId
                              ? Text(l10n.groupDeviceThisOne, style: theme.textTheme.labelMedium)
                              : isOwner
                                  ? _ownerActions(device, theme, l10n)
                                  : device.isOwner == true && device.dormant == true
                                      ? _claimAction(device, l10n)
                                      : null,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
