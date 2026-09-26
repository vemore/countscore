import 'dart:async';

import 'package:drift/native.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

/// A [GroupProvider] whose membership is whatever the test says, with no server
/// behind it. Records the calls that change membership or the server in [calls].
///
/// [pending] is the cached [pendingChanges] (recounted only after a sync pass in
/// the real provider); [storedPending] is what [countPending] finds in the
/// outbox right now. [joinGroupId] is the group an invite code resolves to.
class FakeGroupProvider extends GroupProvider {
  FakeGroupProvider({
    bool joined = false,
    String name = 'Famille',
    String token = 'old-invite',
    int pending = 0,
    int? storedPending,
    String joinGroupId = 'group-new',
    GroupActionException? joinError,
  }) : this._(AppDatabase.forTesting(NativeDatabase.memory()), joined, name, token, pending,
            storedPending ?? pending, joinGroupId, joinError);

  FakeGroupProvider._(this._db, this.joined, this.name, this.token, this.pending,
      this.storedPending, this.joinGroupId, this.joinError)
      : super(
          db: _db,
          credentials: MemorySyncCredentials(),
          enableStream: false,
          pollInterval: const Duration(hours: 1),
        );

  final AppDatabase _db;

  bool joined;
  String name;
  String token;
  int pending;
  int storedPending;
  String joinGroupId;
  String currentGroupId = 'group-old';

  /// Thrown by [prepareJoin] when set.
  GroupActionException? joinError;

  final calls = <String>[];

  @override
  bool get isJoined => joined;

  @override
  String? get groupName => joined ? name : null;

  @override
  String? get shareToken => joined ? token : null;

  @override
  int get pendingChanges => joined ? pending : 0;

  @override
  Future<int> countPending() async => joined ? storedPending : 0;

  @override
  Future<void> updateBackend(String? baseUrl) async => calls.add('backend $baseUrl');

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
    joined = false;
    notifyListeners();
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
      sameGroup: joined && joinGroupId == currentGroupId,
    );
  }

  @override
  Future<void> completeJoin(JoinCandidate c) async {
    if (c.sameGroup) {
      calls.add('keep');
      token = c.membership.shareToken;
    } else {
      if (joined) await leave();
      calls.add('adopt ${c.membership.groupId} on ${c.baseUrl}');
      joined = true;
      token = c.membership.shareToken;
      name = c.membership.groupName;
      currentGroupId = c.membership.groupId;
    }
    notifyListeners();
  }

  @override
  Future<void> cancelJoin(JoinCandidate c) async => calls.add('cancel');

  @override
  void dispose() {
    super.dispose();
    _db.close();
  }
}
