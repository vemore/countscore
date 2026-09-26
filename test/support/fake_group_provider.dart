import 'package:drift/native.dart';

import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

/// A [GroupProvider] whose membership is whatever the test says, with no server
/// behind it. Records the calls that change membership or the server in [calls].
class FakeGroupProvider extends GroupProvider {
  FakeGroupProvider({
    bool joined = false,
    String name = 'Famille',
    String token = 'old-invite',
    int pending = 0,
    GroupActionException? joinError,
  }) : this._(AppDatabase.forTesting(NativeDatabase.memory()), joined, name, token, pending,
            joinError);

  FakeGroupProvider._(this._db, this.joined, this.name, this.token, this.pending, this.joinError)
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

  /// Thrown by [joinGroup] when set.
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
  Future<void> updateBackend(String? baseUrl) async => calls.add('backend $baseUrl');

  @override
  Future<void> refreshDeviceLabel() async {}

  @override
  Future<void> leave() async {
    calls.add('leave');
    joined = false;
    notifyListeners();
  }

  @override
  Future<void> joinGroup(String shareToken, String deviceLabel) async {
    calls.add('join $shareToken as $deviceLabel');
    if (joinError != null) throw joinError!;
    joined = true;
    token = shareToken;
    name = 'Joined';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _db.close();
  }
}
