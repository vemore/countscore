part of 'group_provider.dart';

/// One group this device is in, and the sync loop that serves it: its token,
/// its WebSocket, its poll and debounce timers, its status and counts, its
/// owner flag and its generation. [GroupProvider] holds one per membership
/// (`.llmwiki/Sync.md`, *Several groups*); nothing here reads another group's.
///
/// Built and dropped by the provider only. Every request goes to the one
/// server the provider follows.
class GroupSession {
  GroupSession._(
    this._group,
    this._membership,
    this._deviceToken,
    this._shareToken, {
    this._isOwner = false,
    this._labelOnServer,
  });

  final GroupProvider _group;
  final SyncMembership _membership;
  final String _deviceToken;
  String? _shareToken;
  bool _isOwner;

  /// This device's name as this group's server holds it, when known: from the
  /// create or join, the devices list, or a rename's answer. Null after a
  /// start until the first successful pass reads it ([_syncLabel]).
  String? _labelOnServer;

  SyncStatus _status = SyncStatus.off;
  DateTime? _lastSyncAt;
  int _pending = 0;
  int _rejected = 0;

  SyncStream? _stream;
  Timer? _poll;
  Timer? _debounce;
  bool _running = false;
  bool _rerun = false;
  bool _closed = false;

  /// Bumped by every [_stop]: a pass that began under another value works for
  /// a loop that is gone (a server change, a leave), and reports nothing.
  int _generation = 0;

  String get groupId => _membership.groupId;
  String get groupName => _membership.groupName;
  String get deviceId => _membership.deviceId;
  String? get shareToken => _shareToken;

  /// Whether this device owns the group: the only one that may remove another
  /// device, renew the invite code or hand the role over. Held in memory only —
  /// the server is asked on every start ([refreshOwner]) — and false until it
  /// answers. A server that predates owners treats every device as one.
  bool get isOwner => _isOwner;
  SyncStatus get status => _status;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get pendingChanges => _pending;
  int get rejectedChanges => _rejected;

  /// A server is set and the session has not been dropped: requests may go.
  bool get canReach => !_closed && _group._baseUrl != null;

  BackendClient _client() => _group._client();
  SyncStore get _store => _group._store;

  // ── Loop ──────────────────────────────────────────────────────────────────

  void _start() {
    _status = SyncStatus.idle;
    _poll = Timer.periodic(_group.pollInterval, (_) => syncNow());
    if (_group.enableStream) {
      _stream = SyncStream(_client(), _deviceToken, () => scheduleSync(Duration.zero))..start();
    }
    unawaited(refreshOwner());
    unawaited(syncNow());
  }

  Future<void> _stop() async {
    _generation++;
    _poll?.cancel();
    _debounce?.cancel();
    await _stream?.stop();
    _stream = null;
  }

  /// Asks for a pass of this group soon, coalescing bursts into one.
  void scheduleSync([Duration delay = const Duration(seconds: 1)]) {
    if (!canReach) return;
    _debounce?.cancel();
    _debounce = Timer(delay, syncNow);
  }

  /// Pulls and pushes this group. A pass already running reruns once instead.
  Future<void> syncNow() async {
    if (!canReach) return;
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    _status = SyncStatus.syncing;
    _group._changed();
    try {
      do {
        _rerun = false;
        final gen = _generation;
        final confirmed = await _tokenGroupConfirmed();
        // A server change or a leave meanwhile: this pass is not theirs (a
        // restart queued its own).
        if (gen != _generation || !canReach) continue;
        if (!confirmed) break;
        final result = await SyncEngine(_store, _client(), _deviceToken, groupId).run();
        if (gen != _generation) continue;
        for (final e in result.events) {
          _group._events.add(e);
        }
        if (result.pulled > 0 || result.events.isNotEmpty) {
          await _group.onRemoteChange?.call();
        }
        _status = switch (result.failure) {
          null => SyncStatus.idle,
          SyncFailure.unreachable => SyncStatus.offline,
          SyncFailure.unauthorized => SyncStatus.unauthorized,
          SyncFailure.server => SyncStatus.error,
        };
        if (result.failure != null) break;
        _lastSyncAt = DateTime.now();
        // The server answers: the nickname goes out where it has not yet.
        if (_labelOnServer == null || _labelOnServer != _group._nickname) {
          unawaited(_syncLabel());
        }
      } while (_rerun && canReach);
      final gen = _generation;
      final pending = await _store.pendingCount(groupId: groupId);
      final rejected = await _store.rejectedCount(groupId: groupId);
      if (gen == _generation) {
        _pending = pending;
        _rejected = rejected;
      }
    } finally {
      _running = false;
      _group._changed();
    }
  }

  /// Whether a pass may run under this token. One moved from the pre-v23 keys
  /// (`SyncCredentials.needsGroupCheck`) names no group: a database imported on
  /// the old version may be another group's than the token. So before anything
  /// is pulled or pushed under it, `GET /groups/me` says which group it is —
  /// once; a match is remembered. Another group's token is treated as no token
  /// at all, as `reconcileMemberships` does: this group is left on this device
  /// (its games stay, as local ones) and the token forgotten. No answer leaves
  /// the pass undone, to be tried again.
  Future<bool> _tokenGroupConfirmed() async {
    final credentials = _group._credentials;
    if (!await credentials.needsGroupCheck(groupId)) return true;
    final gen = _generation;
    final String tokenGroup;
    try {
      tokenGroup = await _client().groupIdOf(_deviceToken);
    } on BackendException catch (e) {
      _status = e.statusCode == 401 ? SyncStatus.unauthorized : SyncStatus.error;
      return false;
    } catch (_) {
      _status = SyncStatus.offline;
      return false;
    }
    if (gen != _generation) return false; // stopped meanwhile: not this pass's
    if (tokenGroup == groupId) {
      await credentials.markGroupChecked(groupId);
      return true;
    }
    await _group._drop(this);
    return false;
  }

  /// Counts this group's waiting changes now, and refreshes [pendingChanges].
  Future<int> countPending() async {
    final n = await _store.pendingCount(groupId: groupId);
    if (n != _pending) {
      _pending = n;
      _group._changed();
    }
    return n;
  }

  // ── The nickname ──────────────────────────────────────────────────────────

  /// Brings this group's copy of the nickname in line with the device's: reads
  /// it once after a start (the devices list, which also teaches the device a
  /// nickname it never stored — an install from before it was kept), then
  /// sends the device's when they differ: a rename that failed here, or was
  /// lost to a restart, goes again. Silent on failure: the next pass retries.
  Future<void> _syncLabel() async {
    if (_labelBusy) return;
    _labelBusy = true;
    try {
      if (_labelOnServer == null) await devices();
      final nickname = _group._nickname;
      if (nickname != null && _labelOnServer != nickname && canReach) {
        await _sendLabel(nickname);
      }
    } catch (_) {
      // Offline, or revoked: the sync status says so.
    } finally {
      _labelBusy = false;
    }
  }

  bool _labelBusy = false;

  /// `PATCH /groups/devices/me`; remembers what the server answered.
  Future<void> _sendLabel(String label) async {
    _labelOnServer = await _client().renameDevice(_deviceToken, label);
  }

  // ── Requests to the group ─────────────────────────────────────────────────

  /// Asks the server who owns the group. Silent on failure: the last answer stands.
  Future<void> refreshOwner() async {
    if (!canReach) return;
    try {
      final owner = await _client().groupOwner(_deviceToken);
      final isOwner = !owner.known || owner.ownerDeviceId == deviceId;
      if (isOwner != _isOwner) {
        _isOwner = isOwner;
        _group._changed();
      }
    } catch (_) {
      // Offline, or revoked: the sync status says so.
    }
  }

  /// Whether the server still accepts this device's token: a device the owner
  /// revoked is in the group by id only, and must take a new registration
  /// rather than keep a token that is refused. Asked with `GET /groups/me` on
  /// [baseUrl]; a 401 or 403 is a no, and so is a status already
  /// [SyncStatus.unauthorized]. Anything else keeps the registration.
  Future<bool> _tokenAccepted(String baseUrl) async {
    if (_status == SyncStatus.unauthorized) return false;
    try {
      await BackendClient(baseUrl, httpClient: _group.httpClient).groupOwner(_deviceToken);
      return true;
    } on BackendException catch (e) {
      return e.statusCode != 401 && e.statusCode != 403;
    } catch (_) {
      return true;
    }
  }

  /// Maps a failed owner-only call, and forgets the role on a 403.
  GroupActionException _ownerActionError(Object e) {
    if (e is BackendException && e.statusCode == 403) {
      _isOwner = false;
      _group._changed();
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

  void _requireServer() {
    if (!canReach) throw GroupActionException(GroupActionError.unreachable);
  }

  Future<void> rotateShareToken() async {
    if (!canReach) return;
    try {
      _shareToken = await _client().rotateShareToken(_deviceToken);
    } catch (e) {
      throw _ownerActionError(e);
    }
    await _group._credentials.saveShareToken(groupId, _shareToken!);
    _group._changed();
  }

  /// The group's active devices, this one included. Refreshes [isOwner] from
  /// this device's own entry, and what the server calls it — unless a rename
  /// completed while the list was on its way, since the list may predate it.
  Future<List<GroupDevice>> devices() async {
    if (!canReach) return const [];
    final renames = _group._renames;
    try {
      final list = await _client().listDevices(_deviceToken);
      final own = list.where((d) => d.id == deviceId).firstOrNull;
      if (own != null) {
        _isOwner = own.isOwner ?? true;
        if (renames == _group._renames) {
          _labelOnServer = own.label;
          await _group._learnNickname(own.label);
        }
        _group._changed();
      }
      return list;
    } on BackendException {
      throw GroupActionException(GroupActionError.server);
    } catch (_) {
      throw GroupActionException(GroupActionError.unreachable);
    }
  }

  /// Shuts another device out of the group — a lost or sold phone. The owner's
  /// only. The server rotates the invite code at the same time, since that
  /// device knew it; the new code replaces the stored one.
  Future<void> revokeDevice(String otherDeviceId) async {
    if (!canReach || otherDeviceId == deviceId) return;
    final String? newShareToken;
    try {
      newShareToken = await _client().revokeDevice(_deviceToken, otherDeviceId);
    } catch (e) {
      throw _ownerActionError(e);
    }
    if (newShareToken != null) {
      _shareToken = newShareToken;
      await _group._credentials.saveShareToken(groupId, newShareToken);
    }
    _group._changed();
  }

  /// Hands the owner role to another device of the group. The owner's only.
  Future<void> transferOwnership(String otherDeviceId) async {
    if (!canReach || otherDeviceId == deviceId) return;
    try {
      await _client().transferOwnership(_deviceToken, otherDeviceId);
    } catch (e) {
      throw _ownerActionError(e);
    }
    _isOwner = false;
    _group._changed();
  }

  /// Takes the owner role over from an owner device the server reports
  /// dormant. The server refuses (409, [GroupActionError.ownerActive]) while
  /// that device is still about, so the role is never flipped on a guess.
  Future<void> claimOwnership() async {
    if (!canReach) return;
    try {
      await _client().claimOwnership(_deviceToken);
    } catch (e) {
      throw _ownerActionError(e);
    }
    _isOwner = true;
    _group._changed();
  }

  /// The group's comment style and language, and its LLM usage this month —
  /// fetched fresh each time, nothing kept on the device.
  Future<({GroupSettings settings, GroupUsage usage})> groupSettings() async {
    _requireServer();
    final client = _client();
    try {
      final settings = await client.groupSettings(_deviceToken);
      return (settings: settings, usage: await client.groupUsage(_deviceToken));
    } catch (e) {
      throw GroupProvider._settingsError(e);
    }
  }

  /// Changes the group's comment style and/or language — open to every member.
  Future<GroupSettings> updateGroupSettings({String? commentStyle, String? commentLanguage}) async {
    _requireServer();
    try {
      return await _client().updateGroupSettings(
        _deviceToken,
        commentStyle: commentStyle,
        commentLanguage: commentLanguage,
      );
    } catch (e) {
      throw GroupProvider._settingsError(e);
    }
  }

  /// The analysis of a game shared with this group, billed to its budget and
  /// written in its language — and in its style when [payload] names no voice.
  ///
  /// A 404 is a game the server does not hold yet (its share not pushed): one
  /// pass of this group, then one retry. Any other failure is the caller's, as
  /// a [BackendException] with its status.
  Future<({String content, String? model})> gameAnalysis(
    String gameUuid,
    Map<String, dynamic> payload,
  ) async {
    _requireServer();
    try {
      return await _client().groupGameAnalysis(_deviceToken, gameUuid, payload);
    } on BackendException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    await syncNow();
    return _client().groupGameAnalysis(_deviceToken, gameUuid, payload);
  }

  /// Shares a local game with this group. Refused up front when a player name
  /// is one the server would reject.
  Future<void> shareGame(int gameId) async {
    final invalid = await _store.unsyncablePlayerNames(gameId);
    if (invalid.isNotEmpty) {
      throw GroupActionException(GroupActionError.invalidPlayerNames, invalid);
    }
    await _store.shareGame(gameId, groupId);
    scheduleSync();
  }
}
