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

/// One sync pass: pull everything new, push everything pending, and resolve the
/// conflicts the server names. No timers, no sockets — the caller decides when.
///
/// Reason codes are the server's (`backend/app/routes/sync.py`, `REASON_*`).
class SyncEngine {
  SyncEngine(this._store, this._client, this._deviceToken);

  final SyncStore _store;
  final BackendClient _client;
  final String _deviceToken;

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
      final m = await _store.membership();
      if (m == null) return applied;
      final page = await _client.pull(_deviceToken, m.lastServerSeq);
      if (page.deltas.isEmpty && page.serverSeqMax <= m.lastServerSeq) return applied;
      final report = await _store.applyPulled(m, page.deltas, page.serverSeqMax);
      applied += report.applied;
      if (!page.hasMore) return applied;
    }
  }

  /// Returns true when a conflict was resolved locally and the resolution still
  /// has to be pushed after a fresh pull.
  Future<bool> _pushAll(List<SyncEvent> events) async {
    var again = false;
    while (true) {
      final m = await _store.membership();
      if (m == null) return false;
      final deltas = await _store.preparePush(m, limit: _batch);
      if (deltas.isEmpty) return again;

      final results = await _client.push(_deviceToken, [for (final d in deltas) d.toJson()]);
      var progress = false;
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
            progress |= await _resolve(d, r.reason ?? '', events);
            again = true;
        }
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
