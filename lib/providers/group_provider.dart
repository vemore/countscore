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
      _membership = await _store.membership();
      _deviceToken = await _credentials.deviceToken();
      _shareToken = await _credentials.shareToken();
    }
    await _restart();
  }

  BackendClient _client() => BackendClient(_baseUrl!, httpClient: httpClient);

  // ── Membership ────────────────────────────────────────────────────────────

  Future<void> createGroup(String name, String deviceLabel) =>
      _enter(() => _client().createGroup(name, deviceLabel), owner: true);

  Future<void> joinGroup(String shareToken, String deviceLabel) =>
      _enter(() => _client().joinGroup(shareToken.trim(), deviceLabel), owner: false);

  Future<void> _enter(Future<GroupMembership> Function() call, {required bool owner}) async {
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
    _isOwner = owner;
    _membership = await _store.membership();
    await _restart();
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

  /// The group's active devices, this one included. Refreshes [isOwner] from
  /// this device's own entry.
  Future<List<GroupDevice>> devices() async {
    final token = _deviceToken;
    if (token == null || _baseUrl == null) return const [];
    try {
      final list = await _client().listDevices(token);
      final own = list.where((d) => d.id == deviceId).firstOrNull;
      if (own != null) {
        final isOwner = own.isOwner ?? true;
        if (isOwner != _isOwner) {
          _isOwner = isOwner;
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
    unawaited(refreshOwner());
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
    }
  }

  @override
  void dispose() {
    unawaited(_stop());
    _events.close();
    super.dispose();
  }
}
