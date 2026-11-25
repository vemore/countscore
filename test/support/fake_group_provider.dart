import 'dart:async';

import 'package:drift/native.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

/// A [GroupProvider] whose memberships are whatever the test says, with no
/// server behind it: real [GroupSession]s ([GroupProvider.debugPutMembership])
/// that never sync. Records the calls that change membership or the server in
/// [calls].
///
/// [joined] starts the device in one group, `group-old`, named [name] with
/// invite code [token]; [addGroup] adds more. [pending] is the cached
/// [pendingChanges] (recounted only after a sync pass in the real provider);
/// [storedPending] is what [countPending] finds in the outbox right now.
/// [joinGroupId] is the group an invite code resolves to. [server] is the
/// server this device follows: a join on it is made beside the other groups,
/// one on another server replaces them, as [GroupProvider.completeJoin] does.
class FakeGroupProvider extends GroupProvider {
  FakeGroupProvider({
    bool joined = false,
    String name = 'Famille',
    String token = 'old-invite',
    int pending = 0,
    int? storedPending,
    String joinGroupId = 'group-new',
    GroupActionException? joinError,
    String? server = 'https://old.example.com',
    String? nickname,
  }) : this._(AppDatabase.forTesting(NativeDatabase.memory()), joined, name, token, pending,
            storedPending ?? pending, joinGroupId, joinError, server, nickname);

  FakeGroupProvider._(this._db, bool joined, String name, String token, this.pending,
      this.storedPending, this.joinGroupId, this.joinError, this.server, this.fakeNickname)
      : super(
          db: _db,
          credentials: MemorySyncCredentials(),
          enableStream: false,
          pollInterval: const Duration(hours: 1),
        ) {
    if (joined) addGroup(oldGroupId, name, token);
  }

  static const oldGroupId = 'group-old';

  final AppDatabase _db;

  int pending;
  int storedPending;
  String joinGroupId;
  String? server;

  /// Thrown by [prepareJoin] when set.
  GroupActionException? joinError;

  /// The nickname this device holds; null before any.
  String? fakeNickname;

  @override
  String? get nickname => fakeNickname;

  @override
  String? get baseUrl => server;

  final calls = <String>[];

  /// Puts this device in group [groupId].
  void addGroup(
    String groupId,
    String name,
    String? token, {
    bool isOwner = false,
    SyncStatus status = SyncStatus.off,
  }) =>
      debugPutMembership(
        (groupId: groupId, groupName: name, deviceId: 'device-$groupId', lastServerSeq: 0, lastLamport: 0),
        shareToken: token,
        isOwner: isOwner,
        status: status,
      );

  @override
  int get pendingChanges => isJoined ? pending : 0;

  @override
  Future<int> countPending([String? groupId]) async => isJoined ? storedPending : 0;

  @override
  Future<void> updateBackend(String? baseUrl) async {
    calls.add('backend $baseUrl');
    server = baseUrl;
  }

  /// Completed by [markLoaded], or at once unless the test holds it back
  /// ([holdLoad]) to play a cold start whose membership is still being read.
  Completer<void>? _load;

  void holdLoad() => _load = Completer<void>();

  void markLoaded() => _load?.complete();

  @override
  Future<void> get loaded => _load?.future ?? Future<void>.value();

  @override
  Future<void> refreshDeviceLabel() async {}

  @override
  Future<void> leave() async {
    calls.add('leave');
    for (final s in memberships) {
      debugRemoveMembership(s.groupId);
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    calls.add('leave $groupId');
    debugRemoveMembership(groupId);
  }

  @override
  Future<JoinCandidate> prepareJoin(String baseUrl, String shareToken, String deviceLabel) async {
    calls.add('prepare $shareToken on $baseUrl as ${deviceLabel.trim()}');
    if (joinError != null) throw joinError!;
    return JoinCandidate(
      baseUrl: baseUrl,
      membership: (
        groupId: joinGroupId,
        groupName: 'Joined',
        shareToken: shareToken,
        deviceId: 'device-new',
        deviceToken: 'token-new',
      ),
      label: deviceLabel.trim(),
      sameGroup: session(joinGroupId) != null &&
          session(joinGroupId)!.status != SyncStatus.unauthorized,
    );
  }

  @override
  Future<void> completeJoin(JoinCandidate c) async {
    final kept = session(c.membership.groupId);
    if (c.sameGroup && kept != null) {
      calls.add('keep');
      addGroup(kept.groupId, kept.groupName, c.membership.shareToken, isOwner: kept.isOwner);
      server = c.baseUrl;
      return;
    }
    if (c.baseUrl != server) {
      if (isJoined) await leave();
      server = c.baseUrl;
    } else if (!canJoinMore && kept == null) {
      // A sixth group, as GroupProvider.completeJoin refuses it.
      calls.add('cancel');
      throw GroupActionException(GroupActionError.tooManyGroups);
    }
    calls.add('adopt ${c.membership.groupId} on ${c.baseUrl}');
    addGroup(c.membership.groupId, kept?.groupName ?? c.membership.groupName, c.membership.shareToken);
    fakeNickname = c.label;
  }

  @override
  Future<void> cancelJoin(JoinCandidate c) async => calls.add('cancel');

  @override
  void dispose() {
    super.dispose();
    _db.close();
  }
}
