import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../services/backend_client.dart';
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
enum GroupActionError { unknownShareToken, rateLimited, unreachable, server, invalidPlayerNames }

class GroupActionException implements Exception {
  GroupActionException(this.error, [this.detail = const []]);
  final GroupActionError error;

  /// The offending player names, for [GroupActionError.invalidPlayerNames].
  final List<String> detail;
}

/// Group membership and the sync loop around it.
///
/// Sync runs only while a server URL is configured **and** this device holds a
/// device token — both conditions from the user's design (TODO.md, 2026-09-13).
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
      _membership = await _store.membership();
      _deviceToken = await _credentials.deviceToken();
      _shareToken = await _credentials.shareToken();
    }
    await _restart();
  }

  BackendClient _client() => BackendClient(_baseUrl!, httpClient: httpClient);

  // ── Membership ────────────────────────────────────────────────────────────

  Future<void> createGroup(String name, String deviceLabel) =>
      _enter(() => _client().createGroup(name, deviceLabel));

  Future<void> joinGroup(String shareToken, String deviceLabel) =>
      _enter(() => _client().joinGroup(shareToken.trim(), deviceLabel));

  Future<void> _enter(Future<GroupMembership> Function() call) async {
    if (_baseUrl == null) throw GroupActionException(GroupActionError.unreachable);
    if (_membership != null) await leave();
    final GroupMembership m;
    try {
      m = await call();
    } on BackendException catch (e) {
      throw GroupActionException(switch (e.statusCode) {
        404 || 422 => GroupActionError.unknownShareToken,
        429 => GroupActionError.rateLimited,
        _ => GroupActionError.server,
      });
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
    await _credentials.save(deviceToken: m.deviceToken, shareToken: m.shareToken);
    await _store.join(m);
    _deviceToken = m.deviceToken;
    _shareToken = m.shareToken;
    _membership = await _store.membership();
    await _restart();
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
    } on BackendException {
      throw GroupActionException(GroupActionError.server);
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
    await _credentials.saveShareToken(_shareToken!);
    notifyListeners();
  }

  /// The group's active devices, this one included.
  Future<List<GroupDevice>> devices() async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null) return const [];
    try {
      return await _client().listDevices(token);
    } on BackendException {
      throw GroupActionException(GroupActionError.server);
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
  }

  /// Shuts another device out of the group — a lost or sold phone. The server
  /// rotates the invite code at the same time, since that device knew it; the
  /// new code replaces the stored one. This device leaves through [leave].
  Future<void> revokeDevice(String deviceId) async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null || deviceId == this.deviceId) return;
    final String? newShareToken;
    try {
      newShareToken = await _client().revokeDevice(token, deviceId);
    } on BackendException {
      throw GroupActionException(GroupActionError.server);
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
    if (newShareToken != null) {
      _shareToken = newShareToken;
      await _credentials.saveShareToken(newShareToken);
    }
    notifyListeners();
  }

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
        if (result.failure == null) _lastSyncAt = DateTime.now();
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
    if (state == AppLifecycleState.resumed) scheduleSync(Duration.zero);
  }

  @override
  void dispose() {
    unawaited(_stop());
    _events.close();
    super.dispose();
  }
}
