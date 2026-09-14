import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/group_provider.dart';
import '../services/backend_client.dart';
import 'group_settings_section.dart' show groupActionErrorText;

/// Settings → Group → Devices: the group's devices, and a way to shut one out.
///
/// This device is marked and offers no revoke — leaving is the section's own
/// button, which also turns shared games back into local ones.
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

    setState(() => _busy = true);
    try {
      await group.revokeDevice(device.id);
      _message = (text: l10n.groupDeviceRevoked(device.label), error: false);
      _devices = group.devices();
    } on GroupActionException catch (e) {
      _message = (text: groupActionErrorText(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ownId = context.watch<GroupProvider>().deviceId;
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
            Text(l10n.groupDevicesExplain, style: theme.textTheme.bodySmall),
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
                          subtitle: Text(l10n.groupDeviceLastSeen(
                            dateFormat.format(device.lastSeenAt.toLocal()),
                          )),
                          trailing: device.id == ownId
                              ? Text(l10n.groupDeviceThisOne, style: theme.textTheme.labelMedium)
                              : IconButton(
                                  key: Key('group_device_revoke_${device.id}'),
                                  icon: const Icon(Icons.person_remove_outlined),
                                  tooltip: l10n.groupDeviceRevoke,
                                  color: theme.colorScheme.error,
                                  onPressed: _busy ? null : () => _revoke(device),
                                ),
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
