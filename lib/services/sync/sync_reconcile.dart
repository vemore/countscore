import 'sync_credentials.dart';
import 'sync_store.dart';

/// What [reconcileMemberships] changed: the groups left locally, and the groups
/// whose stored credentials were forgotten.
typedef ReconcileReport = ({List<String> left, Set<String> forgotten});

/// Brings the database's memberships and the device's credentials back into
/// agreement, before anything syncs.
///
/// They live apart — `sync_state` in the database, the tokens in secure storage
/// (`SyncCredentials`) — and a database import (Settings → Import) or a
/// restored backup replaces one and not the other. Each mismatch ends in a
/// defined state rather than in a sync that 401s for ever:
///
/// - **A group the database names and no token is held for** — a membership,
///   or a shared row, link or queue entry of a group that is not one: left on
///   this device, as the Leave button does offline. Its games stay, as local
///   games; joining it again (its QR code) shares them anew.
/// - **A token held for a group the database does not name** — an import of a
///   backup older than the join: forgotten. The device record stays on the
///   server, unused, as after leaving offline.
///
/// The legacy single pair (before schema v23) is claimed here by the group the
/// database names, through [SyncCredentials.deviceToken], or forgotten when it
/// names none.
Future<ReconcileReport> reconcileMemberships(
  SyncStore store,
  SyncCredentials credentials,
) async {
  final held = <String>{};
  final left = <String>[];
  for (final m in await store.memberships()) {
    if (await credentials.deviceToken(m.groupId) != null) {
      held.add(m.groupId);
    } else {
      await store.leave(m.groupId);
      left.add(m.groupId);
    }
  }
  for (final groupId in await store.groupsWithoutMembership()) {
    await store.leave(groupId);
    left.add(groupId);
  }
  final forgotten = await credentials.retainOnly(held);
  return (left: left, forgotten: forgotten);
}
