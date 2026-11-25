import 'dart:async';

import '../backend_client.dart';
import 'sync_store.dart';

/// Something the user should hear about after a sync.
sealed class SyncEvent {}

/// A round entered here took a number another device had already used; it was
/// moved to [newNumber].
class RoundRenumbered extends SyncEvent {
  RoundRenumbered(this.newNumber);
  final int newNumber;
}

/// Why a sync pass stopped.
enum SyncFailure {
  /// No answer: offline, DNS, TLS, timeout. Retried on the next trigger.
  unreachable,

  /// 401: the device was revoked, or the server no longer knows it.
  unauthorized,

  /// Any other non-2xx.
  server,
}

class SyncPassResult {
  SyncPassResult({this.failure, this.events = const [], this.pulled = 0});

  final SyncFailure? failure;
  final List<SyncEvent> events;

  /// Deltas from other devices applied locally — the UI reloads when non-zero.
  final int pulled;
}

/// One sync pass for one group: pull everything new, push everything pending,
/// and resolve the conflicts the server names. No timers, no sockets — the
/// caller decides when.
///
/// [_groupId] picks the membership, and with it the cursor, the queue and the
/// quarantine; [_deviceToken] must be that group's (`SyncCredentials`). The
/// pass ends quietly when the membership goes while it runs.
///
/// Reason codes are the server's (`backend/app/routes/sync.py`, `REASON_*`).
class SyncEngine {
  SyncEngine(this._store, this._client, this._deviceToken, this._groupId);

  final SyncStore _store;
  final BackendClient _client;
  final String _deviceToken;
  final String _groupId;

  static const _batch = 100;

  /// Pull, push, and pull/push again while a conflict needs the server's state.
  Future<SyncPassResult> run() async {
    final events = <SyncEvent>[];
    var pulled = 0;
    try {
      for (var round = 0; round < 3; round++) {
        pulled += await _pullAll();
        final needsAnotherPass = await _pushAll(events);
        if (!needsAnotherPass) break;
      }
      return SyncPassResult(events: events, pulled: pulled);
    } on BackendException catch (e) {
      return SyncPassResult(
        failure: e.statusCode == 401 ? SyncFailure.unauthorized : SyncFailure.server,
        events: events,
        pulled: pulled,
      );
    } on TimeoutException {
      return SyncPassResult(failure: SyncFailure.unreachable, events: events, pulled: pulled);
    } catch (e) {
      // SocketException, ClientException, HandshakeException… — no dart:io here,
      // so the web build compiles; anything that is not a server answer is
      // "unreachable" to the user.
      return SyncPassResult(failure: SyncFailure.unreachable, events: events, pulled: pulled);
    }
  }

  Future<int> _pullAll() async {
    var applied = 0;
    while (true) {
      final m = await _store.membership(_groupId);
      if (m == null) return applied;
      final page = await _client.pull(_deviceToken, m.lastServerSeq);
      if (page.deltas.isEmpty && page.serverSeqMax <= m.lastServerSeq) return applied;
      final report = await _store.applyPulled(m, page.deltas, page.serverSeqMax);
      applied += report.applied;
      if (!page.hasMore) return applied;
    }
  }

  /// Raises the group's clock past every lamport its log holds, from the first
  /// seq. Reads only: nothing is applied and the cursor stays. A pull from the
  /// cursor would not do — a clock that went back with its cursor (a whole
  /// database restored) is lifted by the pull every pass starts with and
  /// reuses nothing; one behind a cursor that did not (`lamport_reused`) has
  /// its lost lamports *before* the cursor. Rare enough to read the log whole.
  Future<void> _raiseClockPastLog() async {
    var since = 0;
    var max = 0;
    while (true) {
      final page = await _client.pull(_deviceToken, since);
      for (final d in page.deltas) {
        if (d.clientLamport > max) max = d.clientLamport;
      }
      if (!page.hasMore || page.deltas.isEmpty) break;
      since = page.serverSeqMax;
    }
    await _store.raiseLamport(_groupId, max);
  }

  static const _lamportReused = 'lamport_reused';

  /// The deltas of one batch refused `lamport_reused`: this device logged
  /// other deltas under those lamports already — its clock is behind its own
  /// log. One scan raises the clock past every lamport the log holds, then
  /// each delta is stamped again after it and pushed again by this pass.
  ///
  /// The scan comes first: one that fails (offline, a 5xx, the app killed)
  /// leaves every row as it was, prepared under its old lamport, so the next
  /// pass meets the same refusal and does it all again — a failed scan is not
  /// a first refusal. A delta refused again after a scan that succeeded is
  /// rejected: the scan did not reach the reused lamport, and looping would
  /// not either.
  Future<void> _restamp(List<PreparedDelta> reused) async {
    final again = [for (final d in reused) if (d.previousReason == _lamportReused) d];
    for (final d in again) {
      await _store.markRejected(d, _lamportReused);
    }
    final first = [for (final d in reused) if (d.previousReason != _lamportReused) d];
    if (first.isEmpty) return;
    await _raiseClockPastLog();
    for (final d in first) {
      await _store.markRestamp(d, _lamportReused);
    }
  }

  /// Returns true when a conflict was resolved locally and the resolution still
  /// has to be pushed after a fresh pull.
  Future<bool> _pushAll(List<SyncEvent> events) async {
    var again = false;
    while (true) {
      final m = await _store.membership(_groupId);
      if (m == null) return false;
      final deltas = await _store.preparePush(m, limit: _batch);
      if (deltas.isEmpty) return again;

      final results = await _client.push(_deviceToken, [for (final d in deltas) d.toJson()]);
      var progress = false;
      final reused = <PreparedDelta>[];
      for (var i = 0; i < deltas.length; i++) {
        final d = deltas[i];
        final r = results[i];
        switch (r.status) {
          case 'applied' || 'duplicate':
            await _store.markSent(d, m.deviceId);
            progress = true;
          case 'merged_lww':
            // A newer write, or a delete, already holds the entity. The winner
            // comes back on the next pull.
            await _store.markSuperseded(d);
            progress = true;
          default:
            if (r.reason == _lamportReused) {
              reused.add(d);
            } else {
              progress |= await _resolve(d, r.reason ?? '', events);
            }
            again = true;
        }
      }
      if (reused.isNotEmpty) {
        await _restamp(reused);
        progress = true;
      }
      // Everything left is waiting on something only a pull can bring.
      if (!progress) return again;
    }
  }

  Future<bool> _resolve(PreparedDelta d, String reason, List<SyncEvent> events) async {
    switch (reason) {
      case 'round_number_taken':
        // First wins on the server; this device's round moves to the next free
        // number, after the winner has been pulled so "next" really is free.
        await _store.markSuperseded(d);
        await _pullAll();
        final number = await _store.renumberRound(d.entityUuid);
        if (number != null) events.add(RoundRenumbered(number));
        return true;
      case 'score_exists' || 'analysis_exists':
        // Another device wrote the same cell or analysis under its own uuid; the
        // pull adopts that identity locally.
        await _store.markSuperseded(d);
        return true;
      case 'builtin_key_taken':
        // Another device already holds the group's row for this built-in type,
        // under a uuid this one did not compute — an older group, linked by name
        // before built-in types linked by key. Pulling adopts that identity, and
        // `_applyGameType` matches it to the local row on the key. Rejecting
        // instead would be terminal, and every shared game pointing at this type
        // would then push a `game_type_id` the server never created and stall on
        // `parent_missing` for good.
        await _store.markSuperseded(d);
        await _pullAll();
        return true;
      case 'parent_missing':
        // The parent went in an earlier batch that failed, or is still queued.
        // Retry once; a second refusal means it is not coming.
        if (d.previousReason == 'parent_missing') {
          await _store.markRejected(d, reason);
          return true;
        }
        await _store.markRetry(d, reason);
        return false;
      default:
        await _store.markRejected(d, reason);
        return true;
    }
  }
}
