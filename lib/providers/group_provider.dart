import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../services/backend_client.dart';
import 'backend_provider.dart';
import '../services/drift/database.dart';
import '../services/sync/sync_credentials.dart';
import '../services/sync/sync_engine.dart';
import '../services/sync/sync_reconcile.dart';
import '../services/sync/sync_store.dart';
import '../services/sync/sync_stream.dart';

part 'group_session.dart';

/// Where sync stands, as the Settings screen shows it.
enum SyncStatus {
  /// No server, or no group: nothing leaves the device.
  off,
  idle,
  syncing,

  /// The server did not answer. Changes wait in the outbox.
  offline,

  /// The server refused this device (revoked, or its database was reset).
  unauthorized,

  /// The server answered with an error.
  error;

  /// Worst last: what one status shown for several groups picks
  /// ([GroupProvider.status]).
  static const _byGravity = [off, idle, syncing, offline, error, unauthorized];

  /// The worse of this and [other].
  SyncStatus worse(SyncStatus other) =>
      _byGravity.indexOf(other) > _byGravity.indexOf(this) ? other : this;
}

/// Why creating, joining or sharing did not happen. One l10n string each.
enum GroupActionError {
  unknownShareToken,
  rateLimited,
  unreachable,
  server,
  invalidPlayerNames,

  /// Only the group's owner may revoke a device, rotate the code or hand over (403).
  notOwner,

  /// The owner role cannot be claimed: that device has been seen recently (409).
  ownerActive,

  /// This device is in [GroupProvider.maxGroups] groups already. Refused
  /// before any request: the server cannot tell two device rows are one install.
  tooManyGroups,
}

/// A registration with a group that [GroupProvider.prepareJoin] made, not yet
/// this device's membership. Built by [GroupProvider.prepareJoin]; public for tests.
class JoinCandidate {
  JoinCandidate({
    required this.baseUrl,
    required this.membership,
    required this.label,
    required this.sameGroup,
  });

  /// The server the device registered with.
  final String baseUrl;
  final GroupMembership membership;
  final String label;

  /// A group this device is already in, under a token the server still accepts.
  final bool sameGroup;
}

class GroupActionException implements Exception {
  GroupActionException(this.error, [this.detail = const []]);
  final GroupActionError error;

  /// The offending player names, for [GroupActionError.invalidPlayerNames].
  final List<String> detail;
}

/// The groups this device is in, one [GroupSession] each, and what they share:
/// the server, the nickname, the local-write trigger, the app lifecycle and the
/// conflict events.
///
/// Sync runs only while a server URL is configured **and** this device holds a
/// group's device token — both conditions from the user's design
/// (wip/done/ARCHIVE-2026-09.md, 2026-09-13). One server for every group, one
/// nickname for every group, at most [maxGroups] groups (the multi-group plan,
/// `wip/done/2026-11-17-belong-to-several-groups.md`). A session is triggered
/// by a local write that queued a change for its group (debounced), by its
/// server's WebSocket signal, on app resume, and every [pollInterval].
class GroupProvider with ChangeNotifier, WidgetsBindingObserver {
  GroupProvider({
    AppDatabase? db,
    SyncCredentials? credentials,
    this.httpClient,
    this.onRemoteChange,
    this.pollInterval = const Duration(seconds: 60),
    this.enableStream = true,
  })  : _db = db ?? AppDatabase.instance,
        _credentials = credentials ?? SecureSyncCredentials();

  /// The most groups one install may be in (decision 9 of the multi-group plan).
  static const maxGroups = 5;

  final AppDatabase _db;
  final SyncCredentials _credentials;
  /// Injected by tests; null means a fresh client per call.
  final http.Client? httpClient;
  final Duration pollInterval;
  final bool enableStream;

  /// Called after sync applied changes from other devices.
  final Future<void> Function()? onRemoteChange;

  late final SyncStore _store = SyncStore(_db);

  /// In the order they were joined.
  final _sessions = <String, GroupSession>{};
  String? _baseUrl;
  String? _nickname;

  /// Bumped by every completed [renameDevice], so a devices list requested
  /// before a rename cannot be taken for the server's answer to it.
  int _renames = 0;
  bool _loaded = false;
  bool _disposed = false;

  bool _attached = false;
  StreamSubscription<void>? _localWrites;
  Timer? _wake;
  final _events = StreamController<SyncEvent>.broadcast();

  /// Every group this device is in, in the order it joined them.
  List<GroupSession> get memberships => List.unmodifiable(_sessions.values);

  /// The session of [groupId], or null when this device is not in it.
  GroupSession? session(String? groupId) => groupId == null ? null : _sessions[groupId];

  /// The one nickname this device goes by in every group, kept on the device
  /// (`SyncCredentials.nickname`): known after a restart without a request.
  /// Null until a group is created or joined, or — on an install from before
  /// it was kept — until a devices list names this device.
  String? get nickname => _nickname;

  /// Whether this device is in at least one group.
  bool get isJoined => _sessions.isNotEmpty;

  /// Whether one more group may be created or joined ([maxGroups]).
  bool get canJoinMore => _sessions.length < maxGroups;

  /// The group whose invite code this device holds as [code], if any.
  GroupSession? sessionByInvite(String code) =>
      _sessions.values.where((s) => s.shareToken == code).firstOrNull;

  // ── Every group summed up, wherever one figure is shown ───────────────────

  /// The worst status of every group ([SyncStatus.worse]); off in none.
  SyncStatus get status =>
      _sessions.values.fold(SyncStatus.off, (worst, s) => worst.worse(s.status));

  /// The oldest last sync of every group; null while one has none.
  DateTime? get lastSyncAt {
    DateTime? oldest;
    for (final s in _sessions.values) {
      final at = s.lastSyncAt;
      if (at == null) return null;
      if (oldest == null || at.isBefore(oldest)) oldest = at;
    }
    return oldest;
  }

  int get pendingChanges => _sessions.values.fold(0, (n, s) => n + s.pendingChanges);
  int get rejectedChanges => _sessions.values.fold(0, (n, s) => n + s.rejectedChanges);

  /// The first group joined, for the tests written when a device had one
  /// group (`test/sync/sync_reconcile_test.dart`). No screen reads it.
  @visibleForTesting
  String? get groupId => _sessions.values.firstOrNull?.groupId;

  /// The first group's invite code; see [groupId].
  @visibleForTesting
  String? get shareToken => _sessions.values.firstOrNull?.shareToken;

  /// Puts [m] among the memberships — or replaces the one of its group — with
  /// no request and nothing stored, for the fake providers of widget tests.
  /// Its session never syncs while no server is followed.
  @visibleForTesting
  void debugPutMembership(SyncMembership m, {String? shareToken, bool isOwner = false}) {
    _sessions[m.groupId] =
        GroupSession._(this, m, 'test-token-${m.groupId}', shareToken, isOwner: isOwner);
    _changed();
  }

  /// Drops [groupId] from the memberships, as [debugPutMembership] added it.
  @visibleForTesting
  void debugRemoveMembership(String groupId) {
    _sessions.remove(groupId)?._closed = true;
    _changed();
  }

  // ──────────────────────────────────────────────────────────────────────────

  /// Conflicts worth a snackbar, wherever the user is.
  Stream<SyncEvent> get events => _events.stream;

  SyncStore get store => _store;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// Follows the server URL from [BackendProvider]. Sync stops when it is
  /// cleared; memberships are kept, so setting the URL back resumes them.
  Future<void> updateBackend(String? baseUrl) async {
    if (_loaded && baseUrl == _baseUrl) return;
    _baseUrl = baseUrl;
    var leftOnStart = false;
    if (!_loaded) {
      _loaded = true;
      try {
        // An imported database may name groups the stored tokens do not, or
        // the reverse: settle that before anything syncs. Secure storage that
        // cannot be read is no reason to leave anything: the reads below then
        // fail as they did before.
        try {
          final report = await reconcileMemberships(_store, _credentials);
          // A group left here turned its games local: the list shows them so.
          leftOnStart = report.left.isNotEmpty;
        } catch (e) {
          debugPrint('GroupProvider: memberships not reconciled: $e');
        }
        try {
          _nickname = await _credentials.nickname();
        } catch (e) {
          debugPrint('GroupProvider: nickname not read: $e');
        }
        for (final m in await _store.memberships()) {
          final token = await _credentials.deviceToken(m.groupId);
          if (token == null) continue;
          _sessions[m.groupId] =
              GroupSession._(this, m, token, await _credentials.shareToken(m.groupId));
        }
      } finally {
        _ready.complete();
      }
    }
    if (leftOnStart) await onRemoteChange?.call();
    await _restart();
  }

  final _ready = Completer<void>();

  /// Completes once the memberships stored on this device have been read — by
  /// the first [updateBackend], which the provider tree makes when it creates
  /// this provider. Until then [isJoined] reads false for a device that is in a
  /// group: a configuration link opened on a cold start waits for it
  /// (`JoinLinkListener`).
  Future<void> get loaded => _ready.future;

  BackendClient _client() => BackendClient(_baseUrl!, httpClient: httpClient);

  // ── Membership ────────────────────────────────────────────────────────────

  /// Creates a group as [deviceLabel], trimmed, and joins it as its owner,
  /// beside the groups this device is already in.
  Future<void> createGroup(String name, String deviceLabel) {
    final label = deviceLabel.trim();
    return _enter(() => _client().createGroup(name, label), owner: true, label: label);
  }

  /// Joins the group [shareToken] names as [deviceLabel], beside the groups
  /// this device is already in; both are trimmed.
  Future<void> joinGroup(String shareToken, String deviceLabel) {
    final label = deviceLabel.trim();
    final token = shareToken.trim();
    return _enter(() => _client().joinGroup(token, label),
        owner: false, label: label, shareToken: token);
  }

  Future<void> _enter(
    Future<GroupMembership> Function() call, {
    required bool owner,
    required String label,
    String? shareToken,
  }) async {
    if (_baseUrl == null) throw GroupActionException(GroupActionError.unreachable);
    // Before the server: a refused create or join leaves every group as it
    // was, and a sixth registration would be a device row nobody uses. A code
    // this device holds for one of its groups is let through: it most likely
    // names that group again, and only the answer says which group it is.
    final full = _sessions.length >= maxGroups;
    if (full && !_sessions.values.any((s) => shareToken != null && s.shareToken == shareToken)) {
      throw GroupActionException(GroupActionError.tooManyGroups);
    }
    final m = await _register(call);
    if (full && !_sessions.containsKey(m.groupId)) {
      // A new group after all: its registration is withdrawn, nothing kept.
      await _revoke(m.deviceToken, m.deviceId);
      throw GroupActionException(GroupActionError.tooManyGroups);
    }
    await _adopt(m, owner: owner, label: label);
  }

  /// Runs a create or join call, mapping its failures. Changes nothing here.
  static Future<GroupMembership> _register(Future<GroupMembership> Function() call) async {
    try {
      return await call();
    } on BackendException catch (e) {
      throw GroupActionException(switch (e.statusCode) {
        404 || 422 => GroupActionError.unknownShareToken,
        429 => GroupActionError.rateLimited,
        _ => GroupActionError.server,
      });
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
  }

  /// Adds [m] to this device's memberships, registered as [label], which
  /// becomes the nickname of every group. A group already joined under
  /// another registration takes the new one; the old is withdrawn.
  Future<void> _adopt(GroupMembership m, {required bool owner, required String label}) async {
    final previous = _sessions.remove(m.groupId);
    if (previous != null) {
      previous._closed = true;
      await previous._stop();
      unawaited(_revoke(previous._deviceToken, previous.deviceId));
    }
    await _credentials.save(m.groupId, deviceToken: m.deviceToken, shareToken: m.shareToken);
    await _store.join(m);
    final session = GroupSession._(
      this,
      (await _store.membership(m.groupId))!,
      m.deviceToken,
      m.shareToken,
      isOwner: owner,
      labelOnServer: label,
    );
    _sessions[m.groupId] = session;
    if (label != _nickname) {
      await _saveNickname(label);
      // One nickname for every group: the others hear of it now, or at their next pass.
      for (final other in _sessions.values) {
        if (other != session) unawaited(other._syncLabel());
      }
    }
    if (_baseUrl != null) {
      _attach();
      session._start();
    }
    _changed();
  }

  /// Revokes a registration of this device. Best effort: offline, or already
  /// revoked, the record stays on the server, unused.
  Future<void> _revoke(String token, String deviceId, [String? baseUrl]) async {
    final url = baseUrl ?? _baseUrl;
    if (url == null) return;
    try {
      await BackendClient(url, httpClient: httpClient).revokeDevice(token, deviceId);
    } catch (_) {
      // Offline or already revoked: leaving locally must still work.
    }
  }

  // ── Joining from a shared configuration ───────────────────────────────────

  /// Step one of joining from a shared configuration, possibly on another server:
  /// registers this device with the group [shareToken] names on [baseUrl], and
  /// changes nothing else. Throws [GroupActionException] when the server refuses
  /// or cannot be reached; the current server and groups are then untouched.
  ///
  /// The result goes to [completeJoin], or is dropped with [cancelJoin].
  /// [JoinCandidate.sameGroup] says whether it is a group this device is
  /// already in, behind a newer invite code.
  Future<JoinCandidate> prepareJoin(String baseUrl, String shareToken, String deviceLabel) async {
    final label = deviceLabel.trim();
    final m = await _register(() => BackendClient(baseUrl, httpClient: httpClient)
        .joinGroup(shareToken.trim(), label));
    return JoinCandidate(
      baseUrl: baseUrl,
      membership: m,
      label: label,
      sameGroup: await _sessions[m.groupId]?._tokenAccepted(baseUrl) ?? false,
    );
  }

  /// Moves sync to [baseUrl] and stores it as the configured server at once, in
  /// the same step as the membership that needs it: a kill between the two would
  /// otherwise leave the old URL on disk with the new group's credentials.
  /// [BackendProvider] learns it from the caller ([BackendProvider.setBaseUrl]).
  Future<void> _switchServer(String baseUrl) async {
    _baseUrl = baseUrl;
    await BackendProvider.persist(baseUrl);
  }

  /// Step two. For [JoinCandidate.sameGroup] the membership is kept (nothing
  /// is left, no row is unshared), the registration [prepareJoin] made is
  /// withdrawn, and the newer invite code is stored. Otherwise, on the server
  /// this device already uses, [c] joins beside the other groups (decision 7
  /// of the multi-group plan) — refused with [GroupActionError.tooManyGroups],
  /// its registration withdrawn, when that would make a sixth; a group already
  /// joined under a token the server refuses takes the new registration. On
  /// another server the configuration is replaced (decision 4): every group is
  /// left, on the server they were registered with, then [c] adopted on its own.
  Future<void> completeJoin(JoinCandidate c) async {
    final kept = c.sameGroup ? _sessions[c.membership.groupId] : null;
    if (kept != null) {
      await cancelJoin(c);
      kept._shareToken = c.membership.shareToken;
      await _credentials.saveShareToken(kept.groupId, c.membership.shareToken);
      // A group id is unique to its server: another URL is another way to it.
      if (c.baseUrl != _baseUrl) {
        await _switchServer(c.baseUrl);
        await _restart();
      }
      _changed();
      return;
    }
    if (c.baseUrl == _baseUrl) {
      if (!canJoinMore && !_sessions.containsKey(c.membership.groupId)) {
        await cancelJoin(c);
        throw GroupActionException(GroupActionError.tooManyGroups);
      }
      await _adopt(c.membership, owner: false, label: c.label);
      return;
    }
    await leave();
    await _switchServer(c.baseUrl);
    await _adopt(c.membership, owner: false, label: c.label);
  }

  /// Withdraws the registration [prepareJoin] made, when the user backs out or it
  /// turns out to be this device's group already.
  Future<void> cancelJoin(JoinCandidate c) =>
      _revoke(c.membership.deviceToken, c.membership.deviceId, c.baseUrl);

  /// The changes still waiting to reach [groupId], or every group, counted
  /// now. [pendingChanges] is only recounted at the end of a sync pass; this
  /// refreshes it as well.
  Future<int> countPending([String? groupId]) async {
    var n = 0;
    for (final s in [..._sessions.values]) {
      if (groupId == null || s.groupId == groupId) n += await s.countPending();
    }
    return n;
  }

  /// Asks each group's server who owns it. Silent on failure.
  Future<void> refreshOwner() async {
    await Future.wait([for (final s in _sessions.values) s.refreshOwner()]);
  }

  /// Leaves every group: clearing the server, or a configuration of another one.
  Future<void> leave() async {
    for (final groupId in [..._sessions.keys]) {
      await leaveGroup(groupId);
    }
  }

  /// Leaves [groupId]: revokes this device there when the server answers, and
  /// in any case turns that group's shared games back into local ones. Every
  /// other group, and a pass of it under way, is left as it was.
  Future<void> leaveGroup(String groupId) async {
    final s = _sessions[groupId];
    if (s == null) return;
    s._closed = true;
    await s._stop();
    await _revoke(s._deviceToken, s.deviceId);
    await _drop(s);
  }

  /// Forgets [s]: its shared games become local ones, its token goes. Nothing
  /// is sent to the server.
  Future<void> _drop(GroupSession s) async {
    s._closed = true;
    await s._stop();
    if (_sessions[s.groupId] == s) _sessions.remove(s.groupId);
    await _store.leave(s.groupId);
    await _credentials.clear(s.groupId);
    if (_sessions.isEmpty) await _detach();
    _changed();
    await onRemoteChange?.call();
  }

  // ── The nickname ──────────────────────────────────────────────────────────

  Future<void> _saveNickname(String label) async {
    _nickname = label;
    await _credentials.saveNickname(label);
  }

  /// A devices list named this device [label]: the nickname, if the device
  /// holds none yet — an install from before it was kept.
  Future<void> _learnNickname(String label) async {
    if (_nickname == null) await _saveNickname(label);
  }

  /// Reads the nickname from a server when the device holds none — an install
  /// upgraded from when it was kept in memory only. Also tried after each
  /// successful pass while unknown. Silent on failure.
  Future<void> refreshDeviceLabel() async {
    if (_nickname != null) return;
    await Future.wait([
      for (final s in _sessions.values)
        if (s.canReach) s._syncLabel(),
    ]);
  }

  /// Renames this device in every group — the name the other members see in
  /// their devices list. [label] is trimmed; the server refuses a blank one, one
  /// over 64 code points, or one with a control character, and nothing is then
  /// stored. So is a rename no group took because a server answered with an
  /// error (429, 401, 5xx): the error is the caller's. A group that cannot be
  /// reached, or answered an error while another took the name, gets it at its
  /// next successful pass. Changes no synced row.
  Future<void> renameDevice(String label) async {
    final name = label.trim();
    if (_baseUrl == null || _sessions.isEmpty) {
      throw GroupActionException(GroupActionError.unreachable);
    }
    final previous = _nickname;
    // Set first: a pass that checks its label meanwhile (`_syncLabel`) sends
    // the new name, never the old one back.
    _nickname = name;
    var accepted = 0;
    Object? refusal;
    for (final s in [..._sessions.values]) {
      try {
        await s._sendLabel(name);
        accepted++;
      } on BackendException catch (e) {
        if (e.statusCode == 422) {
          // The name itself is refused: it would be everywhere.
          _nickname = previous;
          throw _settingsError(e);
        }
        refusal ??= e;
      } catch (_) {
        // Unreachable: retried by that group's next pass.
      }
    }
    if (accepted == 0 && refusal != null) {
      _nickname = previous;
      throw _settingsError(refusal);
    }
    _renames++;
    await _saveNickname(name);
    _changed();
  }

  // ── A game's group ────────────────────────────────────────────────────────

  static GroupActionException _settingsError(Object e) => GroupActionException(switch (e) {
        BackendException(statusCode: 429) => GroupActionError.rateLimited,
        BackendException() => GroupActionError.server,
        _ => GroupActionError.unreachable,
      });

  /// Whether a game's analysis goes through its group: shared with a group
  /// this device is in, and the server can be reached.
  bool analysesThroughGroup({required String? gameGroupId, required String? gameUuid}) =>
      gameUuid != null && (session(gameGroupId)?.canReach ?? false);

  /// The analysis of a game shared with [groupId] ([GroupSession.gameAnalysis]).
  Future<({String content, String? model})> gameAnalysis(
    String groupId,
    String gameUuid,
    Map<String, dynamic> payload,
  ) =>
      (session(groupId) ?? (throw GroupActionException(GroupActionError.unreachable)))
          .gameAnalysis(gameUuid, payload);

  /// Shares a local game with [groupId] ([GroupSession.shareGame]); nothing
  /// when this device is not in it.
  Future<void> shareGame(int gameId, String groupId) async =>
      session(groupId)?.shareGame(gameId);

  // ── Loop ──────────────────────────────────────────────────────────────────

  /// Asks every group for a pass soon.
  void scheduleSync([Duration delay = const Duration(seconds: 1)]) {
    for (final s in _sessions.values) {
      s.scheduleSync(delay);
    }
  }

  /// A pass of every group, side by side.
  Future<void> syncNow() async {
    await Future.wait([for (final s in [..._sessions.values]) s.syncNow()]);
  }

  /// A local write queued changes: the groups that have some go, once a burst
  /// of writes has settled.
  void _scheduleWake() {
    _wake?.cancel();
    _wake = Timer(const Duration(seconds: 1), () async {
      if (_sessions.isEmpty) return;
      for (final groupId in await _store.groupsWithPending()) {
        unawaited(_sessions[groupId]?.syncNow());
      }
    });
  }

  void _attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    // Local writes: Drift reports the tables a repository statement touched.
    _localWrites = _db
        .tableUpdates(TableUpdateQuery.onAllTables([
          _db.games, _db.rounds, _db.scores, _db.gamePlayers, //
          _db.players, _db.gameTypes, _db.gameAnalyses,
        ]))
        .listen((_) => _scheduleWake());
  }

  Future<void> _detach() async {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    _wake?.cancel();
    await _localWrites?.cancel();
    _localWrites = null;
  }

  /// Stops every session, and starts them again on the current server.
  Future<void> _restart() async {
    for (final s in _sessions.values) {
      await s._stop();
    }
    await _detach();
    if (_baseUrl == null || _sessions.isEmpty) {
      for (final s in _sessions.values) {
        s._status = SyncStatus.off;
      }
      _changed();
      return;
    }
    _attach();
    for (final s in _sessions.values) {
      s._start();
    }
    _changed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    for (final s in _sessions.values) {
      s.scheduleSync(Duration.zero);
      unawaited(s.refreshOwner());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _sessions.values) {
      s._closed = true;
      unawaited(s._stop());
    }
    unawaited(_detach());
    _events.close();
    super.dispose();
  }
}

