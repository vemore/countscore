import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../services/backend_client.dart';
import 'backend_provider.dart';
import '../services/drift/database.dart';
import '../services/sync/sync_credentials.dart';
import '../services/sync/sync_engine.dart';
import '../services/sync/sync_store.dart';
import '../services/sync/sync_stream.dart';

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
  error,
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

  /// The group this device is already in.
  final bool sameGroup;
}

class GroupActionException implements Exception {
  GroupActionException(this.error, [this.detail = const []]);
  final GroupActionError error;

  /// The offending player names, for [GroupActionError.invalidPlayerNames].
  final List<String> detail;
}

/// Group membership and the sync loop around it.
///
/// Sync runs only while a server URL is configured **and** this device holds a
/// device token — both conditions from the user's design (wip/done/ARCHIVE-2026-09.md, 2026-09-13).
/// It is triggered by local writes (debounced), by the server's WebSocket signal,
/// on app resume, and every [pollInterval] as a safety net.
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

  final AppDatabase _db;
  final SyncCredentials _credentials;
  /// Injected by tests; null means a fresh client per call.
  final http.Client? httpClient;
  final Duration pollInterval;
  final bool enableStream;

  /// Called after sync applied changes from other devices.
  final Future<void> Function()? onRemoteChange;

  late final SyncStore _store = SyncStore(_db);

  String? _baseUrl;
  SyncMembership? _membership;
  String? _shareToken;
  String? _deviceToken;
  bool _isOwner = false;
  String? _deviceLabel;

  /// Bumped by every completed [renameDevice], so a devices list requested
  /// before a rename cannot put the old name back when it arrives after it.
  int _renames = 0;
  bool _loadingLabel = false;
  SyncStatus _status = SyncStatus.off;
  DateTime? _lastSyncAt;
  int _pending = 0;
  int _rejected = 0;
  bool _loaded = false;

  SyncStream? _stream;
  Timer? _poll;
  Timer? _debounce;
  StreamSubscription<void>? _localWrites;
  bool _running = false;
  bool _rerun = false;
  final _events = StreamController<SyncEvent>.broadcast();

  bool get isJoined => _membership != null && _deviceToken != null;
  String? get groupName => _membership?.groupName;
  String? get groupId => _membership?.groupId;
  String? get deviceId => _membership?.deviceId;
  String? get shareToken => _shareToken;

  /// This device's name in the group, as its siblings see it: what it joined or
  /// created the group with, then the server's answer to [devices] or
  /// [renameDevice]. Held in memory only, so null after a restart until the
  /// devices list is read: on start, on resume and after a successful sync while
  /// it is still unknown ([refreshDeviceLabel]).
  String? get deviceLabel => isJoined ? _deviceLabel : null;

  /// Whether this device owns the group: the only one that may remove another
  /// device, renew the invite code or hand the role over. Held in memory only —
  /// the server is asked on every start ([refreshOwner]) — and false until it
  /// answers. A server that predates owners treats every device as one.
  bool get isOwner => isJoined && _isOwner;
  SyncStatus get status => _status;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get pendingChanges => _pending;
  int get rejectedChanges => _rejected;

  /// Conflicts worth a snackbar, wherever the user is.
  Stream<SyncEvent> get events => _events.stream;

  SyncStore get store => _store;

  /// Follows the server URL from [BackendProvider]. Sync stops when it is
  /// cleared; membership is kept, so setting the URL back resumes it.
  Future<void> updateBackend(String? baseUrl) async {
    if (_loaded && baseUrl == _baseUrl) return;
    _baseUrl = baseUrl;
    if (!_loaded) {
      _loaded = true;
      try {
        _membership = await _store.membership();
        _deviceToken = await _credentials.deviceToken();
        _shareToken = await _credentials.shareToken();
      } finally {
        _ready.complete();
      }
    }
    await _restart();
  }

  final _ready = Completer<void>();

  /// Completes once the membership stored on this device has been read — by the
  /// first [updateBackend], which the provider tree makes when it creates this
  /// provider. Until then [isJoined] reads false for a device that is in a
  /// group: a configuration link opened on a cold start waits for it
  /// (`JoinLinkListener`).
  Future<void> get loaded => _ready.future;

  BackendClient _client() => BackendClient(_baseUrl!, httpClient: httpClient);

  // ── Membership ────────────────────────────────────────────────────────────

  /// Creates a group as [deviceLabel], trimmed, and joins it as its owner.
  Future<void> createGroup(String name, String deviceLabel) {
    final label = deviceLabel.trim();
    return _enter(() => _client().createGroup(name, label), owner: true, label: label);
  }

  /// Joins the group [shareToken] names as [deviceLabel]; both are trimmed.
  Future<void> joinGroup(String shareToken, String deviceLabel) {
    final label = deviceLabel.trim();
    return _enter(() => _client().joinGroup(shareToken.trim(), label),
        owner: false, label: label);
  }

  Future<void> _enter(
    Future<GroupMembership> Function() call, {
    required bool owner,
    required String label,
  }) async {
    if (_baseUrl == null) throw GroupActionException(GroupActionError.unreachable);
    // The server first: a refused create or join leaves the current group as it was.
    final m = await _register(call);
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

  /// Makes [m] this device's membership, on [baseUrl] when given. The current
  /// group, if any, is left first: revoked on the server it was registered with,
  /// since [_baseUrl] still names it at that point.
  Future<void> _adopt(
    GroupMembership m, {
    required bool owner,
    required String label,
    String? baseUrl,
  }) async {
    if (_membership != null) await leave();
    if (baseUrl != null) await _switchServer(baseUrl);
    await _credentials.save(deviceToken: m.deviceToken, shareToken: m.shareToken);
    await _store.join(m);
    _deviceToken = m.deviceToken;
    _shareToken = m.shareToken;
    _isOwner = owner;
    _deviceLabel = label;
    _membership = await _store.membership();
    await _restart();
  }

  // ── Joining from a shared configuration ───────────────────────────────────

  /// Step one of joining from a shared configuration, possibly on another server:
  /// registers this device with the group [shareToken] names on [baseUrl], and
  /// changes nothing else. Throws [GroupActionException] when the server refuses
  /// or cannot be reached; the current server and group are then untouched.
  ///
  /// The result goes to [completeJoin], or is dropped with [cancelJoin].
  /// [JoinCandidate.sameGroup] says whether it is the group this device is
  /// already in, behind a newer invite code.
  Future<JoinCandidate> prepareJoin(String baseUrl, String shareToken, String deviceLabel) async {
    final label = deviceLabel.trim();
    final m = await _register(() => BackendClient(baseUrl, httpClient: httpClient)
        .joinGroup(shareToken.trim(), label));
    final current = _membership;
    return JoinCandidate(
      baseUrl: baseUrl,
      membership: m,
      label: label,
      sameGroup: isJoined &&
          current != null &&
          m.groupId == current.groupId &&
          await _currentTokenAccepted(baseUrl),
    );
  }

  /// Whether the server still accepts this device's own token: a device the
  /// owner revoked is in "the same group" by id only, and must take the new
  /// registration rather than keep a token that is refused. Asked with
  /// `GET /groups/me`; a 401 or 403 is a no, and so is a status already
  /// [SyncStatus.unauthorized]. Anything else (the server answered the join a
  /// moment ago) keeps the current registration.
  Future<bool> _currentTokenAccepted(String baseUrl) async {
    final token = _deviceToken;
    if (token == null || _status == SyncStatus.unauthorized) return false;
    try {
      await BackendClient(baseUrl, httpClient: httpClient).groupOwner(token);
      return true;
    } on BackendException catch (e) {
      return e.statusCode != 401 && e.statusCode != 403;
    } catch (_) {
      return true;
    }
  }

  /// Moves sync to [baseUrl] and stores it as the configured server at once, in
  /// the same step as the membership that needs it: a kill between the two would
  /// otherwise leave the old URL on disk with the new group's credentials.
  /// [BackendProvider] learns it from the caller ([BackendProvider.setBaseUrl]).
  Future<void> _switchServer(String baseUrl) async {
    _baseUrl = baseUrl;
    await BackendProvider.persist(baseUrl);
  }

  /// Step two: makes [c] this device's group. For [JoinCandidate.sameGroup] the
  /// membership is kept (nothing is left, no row is unshared), the registration
  /// [prepareJoin] made is withdrawn, and the newer invite code is stored.
  /// Otherwise the current group is left, then [c] adopted, syncing with [c]'s server.
  Future<void> completeJoin(JoinCandidate c) async {
    if (c.sameGroup && _membership?.groupId == c.membership.groupId) {
      await cancelJoin(c);
      _shareToken = c.membership.shareToken;
      await _credentials.saveShareToken(c.membership.shareToken);
      // A group id is unique to its server: another URL is another way to it.
      if (c.baseUrl != _baseUrl) {
        await _switchServer(c.baseUrl);
        await _restart();
      }
      notifyListeners();
      return;
    }
    await _adopt(c.membership, owner: false, label: c.label, baseUrl: c.baseUrl);
  }

  /// Withdraws the registration [prepareJoin] made, when the user backs out or it
  /// turns out to be this device's group already. Best effort: an unreachable
  /// server keeps a device record nobody uses.
  Future<void> cancelJoin(JoinCandidate c) async {
    try {
      await BackendClient(c.baseUrl, httpClient: httpClient)
          .revokeDevice(c.membership.deviceToken, c.membership.deviceId);
    } catch (_) {
      // Offline: the record stays on the server, unused.
    }
  }

  /// The changes still waiting to reach the group, counted now. [pendingChanges]
  /// is only recounted at the end of a sync pass; this refreshes it as well.
  Future<int> countPending() async {
    if (_membership == null) return 0;
    final n = await _store.pendingCount();
    if (n != _pending) {
      _pending = n;
      notifyListeners();
    }
    return n;
  }

  /// Asks the server who owns the group. Silent on failure: the last answer stands.
  Future<void> refreshOwner() async {
    final token = _deviceToken;
    final own = deviceId;
    if (token == null || own == null || _baseUrl == null) return;
    try {
      final owner = await _client().groupOwner(token);
      final isOwner = !owner.known || owner.ownerDeviceId == own;
      if (isOwner != _isOwner) {
        _isOwner = isOwner;
        notifyListeners();
      }
    } catch (_) {
      // Offline, or revoked: the sync status says so.
    }
  }

  /// Maps a failed owner-only call, and forgets the role on a 403.
  GroupActionException _ownerActionError(Object e) {
    if (e is BackendException && e.statusCode == 403) {
      _isOwner = false;
      notifyListeners();
      return GroupActionException(GroupActionError.notOwner);
    }
    // A refused claim: the owner is alive after all. Nothing to forget — this device
    // never had the role — so [_isOwner] is left alone.
    if (e is BackendException && e.statusCode == 409) {
      return GroupActionException(GroupActionError.ownerActive);
    }
    return GroupActionException(
        e is BackendException ? GroupActionError.server : GroupActionError.unreachable);
  }

  /// Leaves the group: revokes this device on the server when it can, and in any
  /// case turns shared games back into local ones on this device.
  Future<void> leave() async {
    final m = _membership;
    final token = _deviceToken;
    await _stop();
    if (m != null && token != null && _baseUrl != null) {
      try {
        await _client().revokeDevice(token, m.deviceId);
      } catch (_) {
        // Offline or already revoked: leaving locally must still work.
      }
    }
    if (m != null) await _store.leave(m.groupId);
    await _credentials.clear();
    _membership = null;
    _deviceToken = null;
    _shareToken = null;
    _isOwner = false;
    _deviceLabel = null;
    _status = SyncStatus.off;
    _pending = 0;
    _rejected = 0;
    notifyListeners();
    await onRemoteChange?.call();
  }

  Future<void> rotateShareToken() async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null) return;
    try {
      _shareToken = await _client().rotateShareToken(token);
    } catch (e) {
      throw _ownerActionError(e);
    }
    await _credentials.saveShareToken(_shareToken!);
    notifyListeners();
  }

  /// The group's active devices, this one included. Refreshes [isOwner] and
  /// [deviceLabel] from this device's own entry — the label only when no rename
  /// completed while the list was on its way, since the list may predate it.
  Future<List<GroupDevice>> devices() async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null) return const [];
    final renames = _renames;
    try {
      final list = await _client().listDevices(token);
      final own = list.where((d) => d.id == deviceId).firstOrNull;
      if (own != null) {
        final isOwner = own.isOwner ?? true;
        final label = renames == _renames ? own.label : _deviceLabel;
        if (isOwner != _isOwner || label != _deviceLabel) {
          _isOwner = isOwner;
          _deviceLabel = label;
          notifyListeners();
        }
      }
      return list;
    } on BackendException {
      throw GroupActionException(GroupActionError.server);
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
  }

  /// Reads [deviceLabel] from the server when it is not known yet — after a
  /// restart. Called on start and resume, after each successful sync while the
  /// label is unknown, and when Settings → Group opens; one request at a time.
  /// Silent on failure: the next of those tries again.
  Future<void> refreshDeviceLabel() async {
    if (_deviceLabel != null || _loadingLabel || !_active) return;
    _loadingLabel = true;
    try {
      await devices();
    } catch (_) {
      // Offline, or revoked: the sync status says so.
    } finally {
      _loadingLabel = false;
    }
  }

  /// Renames this device in its group — the name the other members see in
  /// their devices list. [label] is trimmed; the server refuses a blank one, one
  /// over 64 code points, or one with a control character. Changes no synced row.
  Future<void> renameDevice(String label) async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null) {
      throw GroupActionException(GroupActionError.unreachable);
    }
    try {
      _deviceLabel = await _client().renameDevice(token, label.trim());
    } catch (e) {
      throw _settingsError(e);
    }
    _renames++;
    notifyListeners();
  }

  /// Shuts another device out of the group — a lost or sold phone. The owner's
  /// only. The server rotates the invite code at the same time, since that device
  /// knew it; the new code replaces the stored one. This device leaves through
  /// [leave].
  Future<void> revokeDevice(String deviceId) async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null || deviceId == this.deviceId) return;
    final String? newShareToken;
    try {
      newShareToken = await _client().revokeDevice(token, deviceId);
    } catch (e) {
      throw _ownerActionError(e);
    }
    if (newShareToken != null) {
      _shareToken = newShareToken;
      await _credentials.saveShareToken(newShareToken);
    }
    notifyListeners();
  }

  /// Hands the owner role to another device of the group. The owner's only; this
  /// device is an ordinary member afterwards.
  Future<void> transferOwnership(String deviceId) async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null || deviceId == this.deviceId) return;
    try {
      await _client().transferOwnership(token, deviceId);
    } catch (e) {
      throw _ownerActionError(e);
    }
    _isOwner = false;
    notifyListeners();
  }

  /// Takes the owner role over from an owner device the server reports dormant —
  /// a phone that uninstalled the app never leaves the group by itself, and the
  /// invite code it left behind could otherwise never be renewed. The server
  /// refuses (409, [GroupActionError.ownerActive]) while that device is still
  /// about, so the role is never flipped here on a guess.
  Future<void> claimOwnership() async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null) return;
    try {
      await _client().claimOwnership(token);
    } catch (e) {
      throw _ownerActionError(e);
    }
    _isOwner = true;
    notifyListeners();
  }

  // ── Settings and usage ────────────────────────────────────────────────────

  /// True when a call to the server is possible at all: a server URL is set and
  /// this device is in a group. Nothing below makes a request otherwise.
  bool get canReachGroup => _baseUrl != null && isJoined;

  /// The group's comment style and language, and its LLM usage this month —
  /// fetched fresh each time, nothing kept on the device.
  Future<({GroupSettings settings, GroupUsage usage})> groupSettings() async {
    if (!canReachGroup) throw GroupActionException(GroupActionError.unreachable);
    final client = _client();
    final token = _deviceToken!;
    try {
      final settings = await client.groupSettings(token);
      return (settings: settings, usage: await client.groupUsage(token));
    } catch (e) {
      throw _settingsError(e);
    }
  }

  /// Changes the group's comment style and/or language — open to every member.
  /// Returns what the server now holds.
  Future<GroupSettings> updateGroupSettings({String? commentStyle, String? commentLanguage}) async {
    if (!canReachGroup) throw GroupActionException(GroupActionError.unreachable);
    try {
      return await _client().updateGroupSettings(
        _deviceToken!,
        commentStyle: commentStyle,
        commentLanguage: commentLanguage,
      );
    } catch (e) {
      throw _settingsError(e);
    }
  }

  /// Whether [game]'s analysis goes through the group: it is shared with the
  /// group this device is in, and the server can be reached.
  bool analysesThroughGroup({required String? gameGroupId, required String? gameUuid}) =>
      canReachGroup && gameUuid != null && gameGroupId != null && gameGroupId == groupId;

  /// The analysis of a game shared with this group, billed to the group's budget
  /// and written in its language — and in its style when [payload] names no voice.
  ///
  /// A 404 is a game the server does not hold yet (its share not pushed): one
  /// sync, then one retry. Any other failure is the caller's, as a
  /// [BackendException] with its status.
  Future<({String content, String? model})> gameAnalysis(
    String gameUuid,
    Map<String, dynamic> payload,
  ) async {
    if (!canReachGroup) throw GroupActionException(GroupActionError.unreachable);
    try {
      return await _client().groupGameAnalysis(_deviceToken!, gameUuid, payload);
    } on BackendException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    await syncNow();
    return _client().groupGameAnalysis(_deviceToken!, gameUuid, payload);
  }

  static GroupActionException _settingsError(Object e) => GroupActionException(switch (e) {
        BackendException(statusCode: 429) => GroupActionError.rateLimited,
        BackendException() => GroupActionError.server,
        _ => GroupActionError.unreachable,
      });

  /// Shares a local game with the group. Refused up front when a player name is
  /// one the server would reject.
  Future<void> shareGame(int gameId) async {
    final m = _membership;
    if (m == null) return;
    final invalid = await _store.unsyncablePlayerNames(gameId);
    if (invalid.isNotEmpty) {
      throw GroupActionException(GroupActionError.invalidPlayerNames, invalid);
    }
    await _store.shareGame(gameId, m.groupId);
    scheduleSync();
  }

  // ── Loop ──────────────────────────────────────────────────────────────────

  /// Asks for a sync soon, coalescing bursts of writes into one pass.
  void scheduleSync([Duration delay = const Duration(seconds: 1)]) {
    if (!_active) return;
    _debounce?.cancel();
    _debounce = Timer(delay, syncNow);
  }

  bool get _active => _baseUrl != null && isJoined;

  Future<void> syncNow() async {
    if (!_active) return;
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    _status = SyncStatus.syncing;
    notifyListeners();
    try {
      do {
        _rerun = false;
        final result = await SyncEngine(_store, _client(), _deviceToken!).run();
        for (final e in result.events) {
          _events.add(e);
        }
        if (result.pulled > 0 || result.events.isNotEmpty) {
          await onRemoteChange?.call();
        }
        _status = switch (result.failure) {
          null => SyncStatus.idle,
          SyncFailure.unreachable => SyncStatus.offline,
          SyncFailure.unauthorized => SyncStatus.unauthorized,
          SyncFailure.server => SyncStatus.error,
        };
        if (result.failure == null) {
          _lastSyncAt = DateTime.now();
          // The server answers again: fetch a nickname an offline start missed.
          if (_deviceLabel == null) unawaited(refreshDeviceLabel());
        }
        if (result.failure != null) break;
      } while (_rerun && _active);
      _pending = await _store.pendingCount();
      _rejected = await _store.rejectedCount();
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<void> _restart() async {
    await _stop();
    if (!_active) {
      _status = SyncStatus.off;
      notifyListeners();
      return;
    }
    _status = SyncStatus.idle;
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(pollInterval, (_) => syncNow());
    // Local writes: Drift reports the tables a repository statement touched.
    _localWrites = _db
        .tableUpdates(TableUpdateQuery.onAllTables([
          _db.games, _db.rounds, _db.scores, _db.gamePlayers, //
          _db.players, _db.gameTypes, _db.gameAnalyses,
        ]))
        .listen((_) => scheduleSync());
    if (enableStream) {
      _stream = SyncStream(_client(), _deviceToken!, () => scheduleSync(Duration.zero))..start();
    }
    notifyListeners();
    unawaited(refreshOwner());
    unawaited(refreshDeviceLabel());
    unawaited(syncNow());
  }

  Future<void> _stop() async {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _debounce?.cancel();
    await _localWrites?.cancel();
    _localWrites = null;
    await _stream?.stop();
    _stream = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleSync(Duration.zero);
      unawaited(refreshOwner());
      unawaited(refreshDeviceLabel());
    }
  }

  @override
  void dispose() {
    unawaited(_stop());
    _events.close();
    super.dispose();
  }
}
