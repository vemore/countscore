import 'dart:convert';

import 'package:drift/drift.dart';

import '../backend_client.dart';
import '../drift/database.dart';
import '../uuid.dart';
import 'sync_ids.dart';
import 'sync_schema.dart';

/// The group this device is in, as `sync_state` records it.
typedef SyncMembership = ({
  String groupId,
  String groupName,
  String deviceId,
  int lastServerSeq,
  int lastLamport,
});

/// An outbox row turned into a delta, ready for `POST /sync/push`.
class PreparedDelta {
  PreparedDelta({
    required this.outboxId,
    required this.entityType,
    required this.entityUuid,
    required this.op,
    required this.payload,
    required this.lamport,
    this.previousReason,
  });

  final int outboxId;
  final String entityType;

  /// The uuid the server knows: the local one, or for players and game types the
  /// linked remote one.
  final String entityUuid;
  final String op;
  final Map<String, dynamic> payload;
  final int lamport;

  /// Why the server refused this exact delta last time, if it did and it is
  /// being retried.
  final String? previousReason;

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'entity_uuid': entityUuid,
        'op': op,
        'payload': payload,
        'client_lamport': lamport,
      };
}

/// What one page of pulled deltas did to the local database.
typedef ApplyReport = ({int applied, int quarantined});

/// Server limits a payload must respect (`backend/app/services/delta_bounds.py`).
const _gameNameMax = 64;
const _gameTypeNameMax = 64;
const _roundCommentMax = 500;
const _analysisContentMax = 20000;

const _rank = {
  'game_type': 0,
  'player': 1,
  'game': 2,
  'game_player': 3,
  'round': 4,
  'score': 5,
  'game_analysis': 6,
};

/// Everything group sync does to the local database, and nothing that touches the
/// network. See .llmwiki/Sync.md for the protocol and `sync_schema.dart` for how
/// local writes land in `outbox`.
class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  // ── Membership ────────────────────────────────────────────────────────────

  Future<SyncMembership?> membership() async {
    final row = await _db
        .customSelect('SELECT * FROM sync_state WHERE device_id IS NOT NULL LIMIT 1')
        .getSingleOrNull();
    if (row == null) return null;
    return (
      groupId: row.data['group_id'] as String,
      groupName: (row.data['group_name'] as String?) ?? '',
      deviceId: row.data['device_id'] as String,
      lastServerSeq: row.data['last_server_seq'] as int,
      lastLamport: row.data['last_lamport'] as int,
    );
  }

  /// Records a fresh membership. One group per device: any previous state goes.
  Future<void> join(GroupMembership m) async {
    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM sync_state');
      await _db.customStatement(
        'INSERT INTO sync_state (group_id, group_name, device_id, last_server_seq, last_lamport) '
        'VALUES (?, ?, ?, 0, 0)',
        [m.groupId, m.groupName, m.deviceId],
      );
    });
  }

  /// Turns every shared row of [groupId] back into a local one and forgets all
  /// sync bookkeeping. Tombstones have nobody left to inform, so they go for good.
  Future<void> leave(String groupId) async {
    await _db.transaction(() async {
      await _setSuppress(true);
      for (final table in [
        'scores', 'rounds', 'game_analyses', 'game_players', 'games', //
      ]) {
        await _db.customStatement(
            'DELETE FROM $table WHERE group_id = ? AND deleted_at IS NOT NULL',
            [groupId]);
        await _db.customStatement(
            'UPDATE $table SET group_id = NULL WHERE group_id = ?', [groupId]);
      }
      // Global players tombstoned only because a shared membership held them.
      await _db.customStatement(
        'DELETE FROM players WHERE deleted_at IS NOT NULL AND id NOT IN '
        '(SELECT player_id FROM game_players)',
      );
      for (final table in ['outbox', 'group_links', 'entity_versions', 'sync_inbox', 'sync_state']) {
        await _db.customStatement('DELETE FROM $table');
      }
      await _setSuppress(false);
    });
  }

  // ── Sharing ───────────────────────────────────────────────────────────────

  /// Names in [gameId] the server would refuse, so sharing can be refused first.
  Future<List<String>> unsyncablePlayerNames(int gameId) async {
    final rows = await _db.customSelect(
      'SELECT p.name FROM game_players gp JOIN players p ON p.id = gp.player_id '
      'WHERE gp.gameId = ? AND gp.deleted_at IS NULL',
      variables: [Variable(gameId)],
    ).get();
    return [
      for (final r in rows)
        if (!isSyncablePlayerName(r.data['name'] as String)) r.data['name'] as String,
    ];
  }

  /// Moves a local game and everything under it into [groupId]. The capture
  /// triggers enqueue each row as its `group_id` changes.
  Future<void> shareGame(int gameId, String groupId) async {
    await _db.transaction(() async {
      await _db.customStatement(
          'UPDATE games SET group_id = ? WHERE id = ? AND group_id IS NULL',
          [groupId, gameId]);
      for (final table in ['game_players', 'rounds', 'game_analyses']) {
        await _db.customStatement(
          'UPDATE $table SET group_id = ? WHERE gameId = ? AND group_id IS NULL '
          'AND deleted_at IS NULL',
          [groupId, gameId],
        );
      }
      await _db.customStatement(
        'UPDATE scores SET group_id = ? WHERE group_id IS NULL AND deleted_at IS NULL '
        'AND roundId IN (SELECT id FROM rounds WHERE gameId = ?)',
        [groupId, gameId],
      );
      // A local tombstone under a game that was never shared has nothing to tell.
      await _db.customStatement(
          'DELETE FROM scores WHERE group_id IS NULL AND deleted_at IS NOT NULL '
          'AND roundId IN (SELECT id FROM rounds WHERE gameId = ?)',
          [gameId]);
    });
  }

  Future<String?> groupOfGame(int gameId) async {
    final row = await _db.customSelect('SELECT group_id FROM games WHERE id = ?',
        variables: [Variable(gameId)]).getSingleOrNull();
    return row?.data['group_id'] as String?;
  }

  // ── Push ──────────────────────────────────────────────────────────────────

  /// Number of local changes not yet accepted by the server.
  Future<int> pendingCount() async {
    final row = await _db
        .customSelect('SELECT COUNT(DISTINCT entity_type || entity_uuid) AS c FROM outbox '
            'WHERE sent_at IS NULL AND rejected_at IS NULL')
        .getSingle();
    return row.data['c'] as int;
  }

  /// Number of local changes the server refused for good.
  Future<int> rejectedCount() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM outbox WHERE rejected_at IS NOT NULL')
        .getSingle();
    return row.data['c'] as int;
  }

  /// Turns captured outbox rows into deltas: coalesces several writes to one
  /// entity, builds each payload from the row as it is now, links players and
  /// game types into the group, and stamps a lamport. A delta prepared once keeps
  /// its lamport and payload until the server has answered, so a retry after a
  /// lost response is recognised as a duplicate instead of applied twice.
  Future<List<PreparedDelta>> preparePush(SyncMembership m, {int limit = 100}) {
    return _db.transaction(() async {
      await _ensureLinks(m.groupId);

      final fresh = await _db
          .customSelect('SELECT * FROM outbox WHERE sent_at IS NULL AND rejected_at IS NULL '
              'AND client_lamport = 0 ORDER BY id')
          .get();
      final seen = <String>{};
      var lamport = (await membership())?.lastLamport ?? m.lastLamport;
      for (final row in fresh) {
        final id = row.data['id'] as int;
        final type = row.data['entity_type'] as String;
        final uuid = row.data['entity_uuid'] as String;
        if (!seen.add('$type/$uuid')) {
          await _db.customStatement('DELETE FROM outbox WHERE id = ?', [id]);
          continue;
        }
        final built = await _build(m.groupId, type, uuid);
        if (built == null) {
          await _db.customStatement('DELETE FROM outbox WHERE id = ?', [id]);
          continue;
        }
        if (built.error != null) {
          await _reject(id, built.error!);
          continue;
        }
        lamport++;
        await _db.customStatement(
          'UPDATE outbox SET op = ?, payload = ?, client_lamport = ? WHERE id = ?',
          [
            built.op,
            jsonEncode({'uuid': built.remoteUuid, 'payload': built.payload}),
            lamport,
            id,
          ],
        );
      }
      await _db.customStatement(
          'UPDATE sync_state SET last_lamport = ? WHERE group_id = ?', [lamport, m.groupId]);

      final ready = await _db
          .customSelect('SELECT * FROM outbox WHERE sent_at IS NULL AND rejected_at IS NULL '
              'AND client_lamport > 0')
          .get();
      final deltas = [
        for (final row in ready)
          () {
            final stored = jsonDecode(row.data['payload'] as String) as Map<String, dynamic>;
            return PreparedDelta(
              outboxId: row.data['id'] as int,
              entityType: row.data['entity_type'] as String,
              entityUuid: stored['uuid'] as String,
              op: row.data['op'] as String,
              payload: (stored['payload'] as Map).cast<String, dynamic>(),
              lamport: row.data['client_lamport'] as int,
              previousReason: row.data['reject_reason'] as String?,
            );
          }(),
      ]..sort((a, b) {
          final byRank = _rank[a.entityType]!.compareTo(_rank[b.entityType]!);
          return byRank != 0 ? byRank : a.outboxId.compareTo(b.outboxId);
        });
      return deltas.take(limit).toList();
    });
  }

  /// The server took the delta (applied or duplicate): it is done, and its
  /// lamport is the version this device now knows for the entity.
  Future<void> markSent(PreparedDelta d, String deviceId) async {
    await _db.transaction(() async {
      await _db.customStatement(
          'UPDATE outbox SET sent_at = ? WHERE id = ?', [_nowMs(), d.outboxId]);
      await _recordVersion(d.entityType, d.entityUuid, d.lamport, deviceId);
    });
  }

  /// The server kept a newer write, or the conflict is resolved some other way:
  /// done, but the version stays whatever the winner's pull will bring.
  Future<void> markSuperseded(PreparedDelta d) => _db.customStatement(
      'UPDATE outbox SET sent_at = ? WHERE id = ?', [_nowMs(), d.outboxId]);

  /// Refused for good; kept so the UI can count it.
  Future<void> markRejected(PreparedDelta d, String reason) => _reject(d.outboxId, reason);

  /// Refused for now (a parent not yet on the server): stays pending, remembers why.
  Future<void> markRetry(PreparedDelta d, String reason) => _db.customStatement(
      'UPDATE outbox SET reject_reason = ? WHERE id = ?', [reason, d.outboxId]);

  /// Moves a shared round the server refused (`round_number_taken`) to the next
  /// free number. Returns the new number, or null when the round is gone.
  Future<int?> renumberRound(String roundUuid) {
    return _db.transaction(() async {
      final round = await _db.customSelect(
        'SELECT id, gameId FROM rounds WHERE uuid = ? AND deleted_at IS NULL',
        variables: [Variable(roundUuid)],
      ).getSingleOrNull();
      if (round == null) return null;
      final max = await _db.customSelect(
        'SELECT COALESCE(MAX(roundNumber), 0) AS m FROM rounds '
        'WHERE gameId = ? AND deleted_at IS NULL',
        variables: [Variable(round.data['gameId'] as int)],
      ).getSingle();
      final next = (max.data['m'] as int) + 1;
      await _db.customStatement(
        'UPDATE rounds SET roundNumber = ?, updated_at = ? WHERE id = ?',
        [next, _nowMs(), round.data['id'] as int],
      );
      return next;
    });
  }

  Future<void> _reject(int outboxId, String reason) => _db.customStatement(
        'UPDATE outbox SET rejected_at = ?, reject_reason = ? WHERE id = ?',
        [_nowMs(), reason, outboxId],
      );

  /// Every player and game type a shared row references gets a group link, and a
  /// captured upsert the first time. Linking is what makes a local row visible to
  /// the capture triggers at all.
  Future<void> _ensureLinks(String groupId) async {
    final players = await _db.customSelect(
      'SELECT DISTINCT p.uuid, p.name FROM game_players gp JOIN players p ON p.id = gp.player_id '
      'WHERE gp.group_id = ? AND p.uuid NOT IN '
      "(SELECT local_uuid FROM group_links WHERE group_id = ? AND entity_type = 'player')",
      variables: [Variable(groupId), Variable(groupId)],
    ).get();
    for (final p in players) {
      await _link(groupId, 'player', p.data['uuid'] as String, p.data['name'] as String);
    }
    final types = await _db.customSelect(
      'SELECT DISTINCT t.uuid, t.name, t.builtin_key FROM games g '
      'JOIN game_types t ON t.id = g.gameTypeId '
      'WHERE g.group_id = ? AND t.uuid NOT IN '
      "(SELECT local_uuid FROM group_links WHERE group_id = ? AND entity_type = 'game_type')",
      variables: [Variable(groupId), Variable(groupId)],
    ).get();
    for (final t in types) {
      await _link(
        groupId,
        'game_type',
        t.data['uuid'] as String,
        t.data['name'] as String,
        builtinKey: t.data['builtin_key'] as String?,
      );
    }
  }

  Future<void> _link(String groupId, String type, String localUuid, String name,
      {String? builtinKey}) async {
    final remote = type == 'game_type'
        ? linkedGameTypeRemoteUuid(groupId, builtinKey, name)
        : linkedRemoteUuid(groupId, type, name);
    // Another local row may already hold that remote identity — two local
    // "Alice (2)"-style duplicates that normalise alike. Keep the first link.
    final taken = await _db.customSelect(
      'SELECT 1 FROM group_links WHERE group_id = ? AND entity_type = ? AND remote_uuid = ?',
      variables: [Variable(groupId), Variable(type), Variable(remote)],
    ).getSingleOrNull();
    if (taken != null) return;
    await _db.customStatement(
      'INSERT INTO group_links (group_id, entity_type, local_uuid, remote_uuid) VALUES (?, ?, ?, ?)',
      [groupId, type, localUuid, remote],
    );
    await _db.customStatement(
      'INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport, created_at) '
      "VALUES (?, ?, 'upsert', '', 0, ?)",
      [type, localUuid, _nowMs()],
    );
  }

  Future<String?> _remoteOf(String groupId, String type, String localUuid) async {
    final row = await _db.customSelect(
      'SELECT remote_uuid FROM group_links WHERE group_id = ? AND entity_type = ? AND local_uuid = ?',
      variables: [Variable(groupId), Variable(type), Variable(localUuid)],
    ).getSingleOrNull();
    return row?.data['remote_uuid'] as String?;
  }

  Future<String?> _localOf(String groupId, String type, String remoteUuid) async {
    final row = await _db.customSelect(
      'SELECT local_uuid FROM group_links WHERE group_id = ? AND entity_type = ? AND remote_uuid = ?',
      variables: [Variable(groupId), Variable(type), Variable(remoteUuid)],
    ).getSingleOrNull();
    return row?.data['local_uuid'] as String?;
  }

  /// The delta for one captured entity, from the row as it is now. Null when the
  /// row is gone or has nothing to send; `error` when the server would refuse it.
  Future<({String op, String remoteUuid, Map<String, dynamic> payload, String? error})?>
      _build(String groupId, String type, String uuid) async {
    final table = syncTables[type]!;
    final row = await _db.customSelect('SELECT * FROM $table WHERE uuid = ?',
        variables: [Variable(uuid)]).getSingleOrNull();
    if (row == null) return null;
    final r = row.data;
    final deleted = r['deleted_at'] != null;
    final op = deleted ? 'delete' : 'upsert';

    switch (type) {
      case 'player':
        // Deleting a player from this device's catalogue is not a group event;
        // its shared memberships are tombstoned and sync on their own.
        if (deleted) return null;
        final remote = await _remoteOf(groupId, type, uuid);
        if (remote == null) return null;
        final name = (r['name'] as String).trim();
        if (!isSyncablePlayerName(name)) {
          return (op: op, remoteUuid: remote, payload: const <String, dynamic>{}, error: 'invalid_player_name');
        }
        return (
          op: op,
          remoteUuid: remote,
          payload: {
            'name': name,
            'name_normalized': normalizeName(name),
            'color_value': r['colorValue'],
          },
          error: null,
        );

      case 'game_type':
        if (deleted) return null;
        final remote = await _remoteOf(groupId, type, uuid);
        if (remote == null) return null;
        return (
          op: op,
          remoteUuid: remote,
          payload: {
            'name': _clip(r['name'] as String, _gameTypeNameMax),
            // The identity *and* the displayed name of a built-in type. The
            // name travels too, so a device that does not know this key still
            // has something to show. See .llmwiki/Sync.md.
            'builtin_key': r['builtin_key'],
            'icon_code_point': r['iconCodePoint'],
            'card_color_value': r['cardColorValue'],
            'is_lowest_score_wins': r['isLowestScoreWins'] == 1,
            'is_default': r['isDefault'] == 1,
            'player_dead_condition_type': r['playerDeadConditionType'],
            'player_dead_threshold': r['playerDeadThreshold'],
            'game_over_condition_type': r['gameOverConditionType'],
            'game_over_threshold': r['gameOverThreshold'],
          },
          error: null,
        );

      case 'game':
        if (deleted) return (op: op, remoteUuid: uuid, payload: const <String, dynamic>{}, error: null);
        String? typeRemote;
        final typeId = r['gameTypeId'] as int?;
        if (typeId != null) {
          final t = await _db.customSelect('SELECT uuid FROM game_types WHERE id = ?',
              variables: [Variable(typeId)]).getSingleOrNull();
          if (t != null) typeRemote = await _remoteOf(groupId, 'game_type', t.data['uuid'] as String);
        }
        return (
          op: op,
          remoteUuid: uuid,
          payload: {
            'name': _clip(r['name'] as String, _gameNameMax),
            'game_type_id': typeRemote,
            'is_lowest_score_wins': r['isLowestScoreWins'] == 1,
            'started_at': _isoUtc(r['createdAt'] as String),
            // Always sent, null included: that is what clears the column on the
            // server and on the other devices when a game is reopened.
            'ended_at': r['finishedAt'] == null
                ? null
                : _isoUtc(r['finishedAt'] as String),
          },
          error: null,
        );

      case 'game_player':
        final refs = await _db.customSelect(
          'SELECT g.uuid AS game, p.uuid AS player FROM games g, players p '
          'WHERE g.id = ? AND p.id = ?',
          variables: [Variable(r['gameId'] as int), Variable(r['player_id'] as int)],
        ).getSingleOrNull();
        if (refs == null) return null;
        final player = await _remoteOf(groupId, 'player', refs.data['player'] as String);
        if (player == null) return null;
        final keys = {'game_id': refs.data['game'], 'player_id': player};
        if (deleted) return (op: op, remoteUuid: uuid, payload: keys, error: null);
        return (
          op: op,
          remoteUuid: uuid,
          payload: {
            ...keys,
            'order_index': (r['orderIndex'] as int).clamp(0, 64),
            'color_value': r['colorValue'],
          },
          error: null,
        );

      case 'round':
        if (deleted) return (op: op, remoteUuid: uuid, payload: const <String, dynamic>{}, error: null);
        final game = await _uuidOf('games', r['gameId'] as int);
        if (game == null) return null;
        final comment = r['comment'] as String?;
        return (
          op: op,
          remoteUuid: uuid,
          payload: {
            'game_id': game,
            'round_number': r['roundNumber'],
            'comment': comment == null ? null : _clip(comment, _roundCommentMax),
          },
          error: null,
        );

      case 'score':
        if (deleted) return (op: op, remoteUuid: uuid, payload: const <String, dynamic>{}, error: null);
        final refs = await _db.customSelect(
          'SELECT rd.uuid AS round, p.uuid AS player FROM rounds rd, game_players gp '
          'JOIN players p ON p.id = gp.player_id WHERE rd.id = ? AND gp.id = ?',
          variables: [Variable(r['roundId'] as int), Variable(r['playerId'] as int)],
        ).getSingleOrNull();
        if (refs == null) return null;
        final player = await _remoteOf(groupId, 'player', refs.data['player'] as String);
        if (player == null) return null;
        return (
          op: op,
          remoteUuid: uuid,
          payload: {
            'round_id': refs.data['round'],
            'player_id': player,
            'value': r['value'],
          },
          error: null,
        );

      case 'game_analysis':
        if (deleted) return (op: op, remoteUuid: uuid, payload: const <String, dynamic>{}, error: null);
        final game = await _uuidOf('games', r['gameId'] as int);
        if (game == null) return null;
        return (
          op: op,
          remoteUuid: uuid,
          payload: {
            'game_id': game,
            'content': _clip(r['content'] as String, _analysisContentMax),
            'model_id': r['modelId'],
            'generated_at': _isoUtc(r['generatedAt'] as String),
          },
          error: null,
        );
    }
    return null;
  }

  // ── Pull ──────────────────────────────────────────────────────────────────

  /// Applies one page of pulled deltas and advances the cursor, atomically. Local
  /// capture is suppressed throughout: nothing applied here is sent back.
  Future<ApplyReport> applyPulled(
    SyncMembership m,
    List<PulledDelta> deltas,
    int serverSeqMax,
  ) {
    return _db.transaction(() async {
      await _setSuppress(true);
      var applied = 0;
      var quarantined = 0;
      var maxLamport = 0;
      for (final d in deltas) {
        if (d.clientLamport > maxLamport) maxLamport = d.clientLamport;
        final outcome = await _applyOne(m, d);
        if (outcome == null) {
          applied++;
        } else if (outcome != _skip) {
          quarantined++;
          await _db.customStatement(
            'INSERT INTO sync_inbox (server_seq, delta, reason, created_at) VALUES (?, ?, ?, ?)',
            [d.serverSeq, jsonEncode(_deltaJson(d)), outcome, _nowMs()],
          );
        }
      }
      applied += await _replayInbox(m);
      await _db.customStatement(
        'UPDATE sync_state SET last_server_seq = MAX(last_server_seq, ?), '
        'last_lamport = MAX(last_lamport, ?) WHERE group_id = ?',
        [serverSeqMax, maxLamport, m.groupId],
      );
      await _setSuppress(false);
      return (applied: applied, quarantined: quarantined);
    });
  }

  static const _skip = '';

  /// Retries quarantined deltas in server order until a pass makes no progress.
  Future<int> _replayInbox(SyncMembership m) async {
    var total = 0;
    while (true) {
      final rows = await _db
          .customSelect('SELECT id, delta FROM sync_inbox ORDER BY server_seq, id')
          .get();
      var progress = 0;
      for (final row in rows) {
        final d = _deltaFromJson(jsonDecode(row.data['delta'] as String) as Map<String, dynamic>);
        final outcome = await _applyOne(m, d);
        if (outcome == null || outcome == _skip) {
          await _db.customStatement('DELETE FROM sync_inbox WHERE id = ?', [row.data['id']]);
          if (outcome == null) progress++;
        }
      }
      total += progress;
      if (progress == 0) return total;
    }
  }

  /// Null when applied, [_skip] when there is nothing to do, otherwise the reason
  /// the delta has to wait.
  Future<String?> _applyOne(SyncMembership m, PulledDelta d) async {
    if (d.originDeviceId == m.deviceId) {
      await _recordVersion(d.entityType, d.entityUuid, d.clientLamport, d.originDeviceId);
      return _skip;
    }
    final version = await _db.customSelect(
      'SELECT lamport, origin_device_id FROM entity_versions WHERE entity_type = ? AND entity_uuid = ?',
      variables: [Variable(d.entityType), Variable(d.entityUuid)],
    ).getSingleOrNull();
    if (d.op == 'upsert' && version != null) {
      final lamport = version.data['lamport'] as int;
      final origin = version.data['origin_device_id'] as String;
      // The server's order: (client_lamport, origin_device_id); canonical
      // lower-case uuid strings sort like the bytes the server compares.
      final newer = d.clientLamport > lamport ||
          (d.clientLamport == lamport && d.originDeviceId.compareTo(origin) > 0);
      if (!newer) return _skip;
    }

    final String? waiting = switch (d.entityType) {
      'player' => await _applyPlayer(m.groupId, d),
      'game_type' => await _applyGameType(m.groupId, d),
      'game' => await _applyGame(m.groupId, d),
      'game_player' => await _applyGamePlayer(m.groupId, d),
      'round' => await _applyRound(m.groupId, d),
      'score' => await _applyScore(m.groupId, d),
      'game_analysis' => await _applyAnalysis(m.groupId, d),
      _ => _skip,
    };
    if (waiting != null) return waiting;
    await _recordVersion(d.entityType, d.entityUuid, d.clientLamport, d.originDeviceId);
    if (d.op == 'delete') {
      // A delete wins: whatever this device still meant to send about it is moot.
      await _db.customStatement(
        'DELETE FROM outbox WHERE sent_at IS NULL AND entity_type = ? AND entity_uuid = ?',
        [d.entityType, d.entityUuid],
      );
    }
    return null;
  }

  Future<String?> _applyPlayer(String groupId, PulledDelta d) async {
    if (d.op == 'delete') return null; // see _build: not a group event
    final name = (d.payload['name'] as String?)?.trim();
    final color = d.payload['color_value'] as int?;
    final now = _nowMs();
    final linked = await _localOf(groupId, 'player', d.entityUuid);
    if (linked != null) {
      final local = await _db.customSelect('SELECT id, name FROM players WHERE uuid = ?',
          variables: [Variable(linked)]).getSingleOrNull();
      if (local != null) {
        final id = local.data['id'] as int;
        if (name != null && name != local.data['name']) {
          final clash = await _db.customSelect(
            'SELECT 1 FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE AND id != ?',
            variables: [Variable(name), Variable(id)],
          ).getSingleOrNull();
          // A rename onto a name this device already uses for someone else would
          // break the local unique name; keep the local name, take the colour.
          if (clash == null) {
            await _db.customStatement(
                'UPDATE players SET name = ?, updated_at = ? WHERE id = ?', [name, now, id]);
            await _db.customStatement(
                'UPDATE game_players SET name = ? WHERE player_id = ?', [name, id]);
          }
        }
        if (d.payload.containsKey('color_value')) {
          await _db.customStatement(
              'UPDATE players SET colorValue = ?, updated_at = ? WHERE id = ?', [color, now, id]);
        }
        return null;
      }
    }
    if (name == null) return 'player_without_name';
    final byName = await _db.customSelect(
      'SELECT uuid FROM players WHERE group_id IS NULL AND name = ? COLLATE NOCASE '
      'AND deleted_at IS NULL ORDER BY id LIMIT 1',
      variables: [Variable(name)],
    ).getSingleOrNull();
    String localUuid;
    if (byName != null) {
      localUuid = byName.data['uuid'] as String;
    } else {
      localUuid = newUuid();
      await _db.customStatement(
        'INSERT INTO players (name, colorValue, uuid, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
        [name, color, localUuid, now, now],
      );
    }
    await _db.customStatement(
      'INSERT OR REPLACE INTO group_links (group_id, entity_type, local_uuid, remote_uuid) '
      "VALUES (?, 'player', ?, ?)",
      [groupId, localUuid, d.entityUuid],
    );
    return null;
  }

  Future<String?> _applyGameType(String groupId, PulledDelta d) async {
    if (d.op == 'delete') return null;
    final p = d.payload;
    final now = _nowMs();
    final values = <String, Object?>{
      if (p.containsKey('name')) 'name': p['name'],
      if (p.containsKey('builtin_key')) 'builtin_key': p['builtin_key'],
      if (p.containsKey('icon_code_point')) 'iconCodePoint': p['icon_code_point'],
      if (p.containsKey('card_color_value')) 'cardColorValue': p['card_color_value'],
      if (p.containsKey('is_lowest_score_wins'))
        'isLowestScoreWins': p['is_lowest_score_wins'] == true ? 1 : 0,
      if (p.containsKey('player_dead_condition_type'))
        'playerDeadConditionType': p['player_dead_condition_type'],
      if (p.containsKey('player_dead_threshold')) 'playerDeadThreshold': p['player_dead_threshold'],
      if (p.containsKey('game_over_condition_type'))
        'gameOverConditionType': p['game_over_condition_type'],
      if (p.containsKey('game_over_threshold')) 'gameOverThreshold': p['game_over_threshold'],
    };
    final linked = await _localOf(groupId, 'game_type', d.entityUuid);
    if (linked != null) {
      final exists = await _db.customSelect('SELECT id FROM game_types WHERE uuid = ?',
          variables: [Variable(linked)]).getSingleOrNull();
      if (exists != null) {
        await _update('game_types', exists.data['id'] as int, {...values, 'updated_at': now});
        return null;
      }
    }
    final name = p['name'] as String?;
    if (name == null) return 'game_type_without_name';
    final builtinKey = p['builtin_key'] as String?;
    // A built-in type matches on its key first: the two devices may be in
    // different locales, and then the names do not match at all.
    var match = builtinKey == null
        ? null
        : await _db.customSelect(
            'SELECT uuid FROM game_types WHERE builtin_key = ? AND deleted_at IS NULL '
            'ORDER BY id LIMIT 1',
            variables: [Variable(builtinKey)],
          ).getSingleOrNull();
    match ??= await _db.customSelect(
      'SELECT uuid FROM game_types WHERE name = ? COLLATE NOCASE AND deleted_at IS NULL '
      'ORDER BY id LIMIT 1',
      variables: [Variable(name)],
    ).getSingleOrNull();
    String localUuid;
    if (match != null) {
      // The same built-in or custom type this device already has: link, keep local
      // settings. The local row is the one this device's games already point at.
      localUuid = match.data['uuid'] as String;
    } else {
      localUuid = newUuid();
      await _insert('game_types', {
        'name': name,
        'builtin_key': builtinKey,
        'iconCodePoint': p['icon_code_point'] ?? 0,
        'cardColorValue': p['card_color_value'] ?? 0,
        'isLowestScoreWins': p['is_lowest_score_wins'] == true ? 1 : 0,
        'isDefault': 0,
        'playerDeadConditionType': p['player_dead_condition_type'],
        'playerDeadThreshold': p['player_dead_threshold'],
        'gameOverConditionType': p['game_over_condition_type'],
        'gameOverThreshold': p['game_over_threshold'],
        'uuid': localUuid,
        'created_at': now,
        'updated_at': now,
      });
    }
    await _db.customStatement(
      'INSERT OR REPLACE INTO group_links (group_id, entity_type, local_uuid, remote_uuid) '
      "VALUES (?, 'game_type', ?, ?)",
      [groupId, localUuid, d.entityUuid],
    );
    return null;
  }

  Future<String?> _applyGame(String groupId, PulledDelta d) async {
    final existing = await _idOf('games', d.entityUuid);
    final now = _nowMs();
    if (d.op == 'delete') {
      if (existing != null) await _tombstoneGame(existing, now);
      return null;
    }
    if (existing != null && await _isTombstoned('games', existing)) return null;

    final p = d.payload;
    int? typeId;
    final typeRemote = p['game_type_id'] as String?;
    if (typeRemote != null) {
      final local = await _localOf(groupId, 'game_type', typeRemote);
      if (local == null) return 'game_type';
      typeId = await _idOf('game_types', local);
    }
    final values = <String, Object?>{
      if (p.containsKey('name')) 'name': p['name'],
      if (p.containsKey('game_type_id')) 'gameTypeId': typeId,
      if (p.containsKey('is_lowest_score_wins'))
        'isLowestScoreWins': p['is_lowest_score_wins'] == true ? 1 : 0,
      if (p.containsKey('ended_at')) 'finishedAt': _localIso(p['ended_at'] as String?),
      'lastModified': DateTime.now().toIso8601String(),
      'updated_at': now,
    };
    if (existing != null) {
      await _update('games', existing, values);
      return null;
    }
    final started = p['started_at'] as String?;
    await _insert('games', {
      'name': p['name'] ?? '',
      'gameTypeId': typeId,
      'isLowestScoreWins': p['is_lowest_score_wins'] == true ? 1 : 0,
      'createdAt': started == null
          ? DateTime.now().toIso8601String()
          : DateTime.parse(started).toLocal().toIso8601String(),
      'finishedAt': _localIso(p['ended_at'] as String?),
      'lastModified': values['lastModified'],
      'uuid': d.entityUuid,
      'created_at': now,
      'updated_at': now,
      'group_id': groupId,
    });
    return null;
  }

  Future<String?> _applyGamePlayer(String groupId, PulledDelta d) async {
    final gameUuid = d.payload['game_id'] as String?;
    final playerRemote = d.payload['player_id'] as String?;
    if (gameUuid == null || playerRemote == null) return _skip;
    final gameId = await _idOf('games', gameUuid);
    final playerLocal = await _localOf(groupId, 'player', playerRemote);
    final playerId = playerLocal == null ? null : await _idOf('players', playerLocal);
    final now = _nowMs();
    if (d.op == 'delete') {
      if (gameId == null || playerId == null) return null;
      final gp = await _db.customSelect(
        'SELECT id FROM game_players WHERE gameId = ? AND player_id = ? AND deleted_at IS NULL',
        variables: [Variable(gameId), Variable(playerId)],
      ).getSingleOrNull();
      if (gp != null) {
        final id = gp.data['id'] as int;
        await _tombstoneWhere('scores', 'playerId = ?', [id], now);
        await _tombstoneWhere('game_players', 'id = ?', [id], now);
      }
      return null;
    }
    if (gameId == null) return 'game';
    if (playerId == null) return 'player';
    if (await _isTombstoned('games', gameId)) return null;

    final player = await _db.customSelect('SELECT name, colorValue FROM players WHERE id = ?',
        variables: [Variable(playerId)]).getSingle();
    final gp = await _db.customSelect(
      'SELECT id FROM game_players WHERE gameId = ? AND player_id = ?',
      variables: [Variable(gameId), Variable(playerId)],
    ).getSingleOrNull();
    final order = d.payload['order_index'] as int? ?? 0;
    final color = d.payload.containsKey('color_value')
        ? d.payload['color_value']
        : player.data['colorValue'];
    if (gp != null) {
      await _update('game_players', gp.data['id'] as int, {
        'orderIndex': order,
        'colorValue': color,
        'deleted_at': null,
        'updated_at': now,
      });
      return null;
    }
    final uuidFree = await _idOf('game_players', d.entityUuid) == null;
    await _insert('game_players', {
      'gameId': gameId,
      'player_id': playerId,
      'name': player.data['name'],
      'orderIndex': order,
      'colorValue': color,
      'uuid': uuidFree ? d.entityUuid : newUuid(),
      'created_at': now,
      'updated_at': now,
      'group_id': groupId,
    });
    return null;
  }

  Future<String?> _applyRound(String groupId, PulledDelta d) async {
    final existing = await _idOf('rounds', d.entityUuid);
    final now = _nowMs();
    if (d.op == 'delete') {
      if (existing != null) {
        await _tombstoneWhere('scores', 'roundId = ?', [existing], now);
        await _tombstoneWhere('rounds', 'id = ?', [existing], now);
      }
      return null;
    }
    if (existing != null) {
      if (await _isTombstoned('rounds', existing)) return null;
      await _update('rounds', existing, {
        if (d.payload.containsKey('round_number')) 'roundNumber': d.payload['round_number'],
        if (d.payload.containsKey('comment')) 'comment': d.payload['comment'],
        'updated_at': now,
      });
      return null;
    }
    final gameUuid = d.payload['game_id'] as String?;
    final gameId = gameUuid == null ? null : await _idOf('games', gameUuid);
    if (gameId == null) return 'game';
    if (await _isTombstoned('games', gameId)) return null;
    await _insert('rounds', {
      'gameId': gameId,
      'roundNumber': d.payload['round_number'] ?? 0,
      'comment': d.payload['comment'],
      'uuid': d.entityUuid,
      'created_at': now,
      'updated_at': now,
      'group_id': groupId,
    });
    return null;
  }

  Future<String?> _applyScore(String groupId, PulledDelta d) async {
    final existing = await _idOf('scores', d.entityUuid);
    final now = _nowMs();
    if (d.op == 'delete') {
      if (existing != null) await _tombstoneWhere('scores', 'id = ?', [existing], now);
      return null;
    }
    if (existing != null && await _isTombstoned('scores', existing)) return null;
    if (existing != null && !d.payload.containsKey('round_id')) {
      await _update('scores', existing, {'value': d.payload['value'], 'updated_at': now});
      return null;
    }
    final roundUuid = d.payload['round_id'] as String?;
    final playerRemote = d.payload['player_id'] as String?;
    if (roundUuid == null || playerRemote == null) return _skip;
    final round = await _db.customSelect(
      'SELECT id, gameId, deleted_at FROM rounds WHERE uuid = ?',
      variables: [Variable(roundUuid)],
    ).getSingleOrNull();
    if (round == null) return 'round';
    if (round.data['deleted_at'] != null) return null;
    final playerLocal = await _localOf(groupId, 'player', playerRemote);
    if (playerLocal == null) return 'player';
    final gp = await _db.customSelect(
      'SELECT gp.id FROM game_players gp JOIN players p ON p.id = gp.player_id '
      'WHERE gp.gameId = ? AND p.uuid = ? AND gp.deleted_at IS NULL',
      variables: [Variable(round.data['gameId'] as int), Variable(playerLocal)],
    ).getSingleOrNull();
    if (gp == null) return 'game_player';
    final roundId = round.data['id'] as int;
    final gpId = gp.data['id'] as int;

    if (existing != null) {
      await _update('scores', existing,
          {'value': d.payload['value'], 'roundId': roundId, 'playerId': gpId, 'updated_at': now});
      return null;
    }
    // This device typed the same cell under another uuid: take the server's
    // identity so both devices converge on one row.
    final sameCell = await _db.customSelect(
      'SELECT id FROM scores WHERE playerId = ? AND roundId = ? AND deleted_at IS NULL',
      variables: [Variable(gpId), Variable(roundId)],
    ).getSingleOrNull();
    if (sameCell != null) {
      await _update('scores', sameCell.data['id'] as int,
          {'uuid': d.entityUuid, 'value': d.payload['value'], 'updated_at': now});
      return null;
    }
    await _insert('scores', {
      'playerId': gpId,
      'roundId': roundId,
      'value': d.payload['value'] ?? 0,
      'uuid': d.entityUuid,
      'created_at': now,
      'updated_at': now,
      'group_id': groupId,
    });
    return null;
  }

  Future<String?> _applyAnalysis(String groupId, PulledDelta d) async {
    final existing = await _idOf('game_analyses', d.entityUuid);
    final now = _nowMs();
    if (d.op == 'delete') {
      if (existing != null) await _tombstoneWhere('game_analyses', 'id = ?', [existing], now);
      return null;
    }
    final p = d.payload;
    final values = <String, Object?>{
      if (p.containsKey('content')) 'content': p['content'],
      if (p.containsKey('model_id')) 'modelId': p['model_id'],
      if (p.containsKey('generated_at'))
        'generatedAt': DateTime.parse(p['generated_at'] as String).toLocal().toIso8601String(),
      'updated_at': now,
    };
    if (existing != null) {
      if (await _isTombstoned('game_analyses', existing)) return null;
      await _update('game_analyses', existing, values);
      return null;
    }
    final gameUuid = p['game_id'] as String?;
    final gameId = gameUuid == null ? null : await _idOf('games', gameUuid);
    if (gameId == null) return 'game';
    // One analysis per game locally: whatever row this device has for the game
    // takes the server's identity and content.
    final sameGame = await _db.customSelect('SELECT id FROM game_analyses WHERE gameId = ?',
        variables: [Variable(gameId)]).getSingleOrNull();
    if (sameGame != null) {
      await _update('game_analyses', sameGame.data['id'] as int,
          {...values, 'uuid': d.entityUuid, 'deleted_at': null, 'group_id': groupId});
      return null;
    }
    await _insert('game_analyses', {
      'gameId': gameId,
      'content': p['content'] ?? '',
      'modelId': p['model_id'],
      'generatedAt': values['generatedAt'] ?? DateTime.now().toIso8601String(),
      'uuid': d.entityUuid,
      'created_at': now,
      'updated_at': now,
      'group_id': groupId,
    });
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _setSuppress(bool on) => _db.customStatement(
      'INSERT OR REPLACE INTO sync_flags (id, suppress) VALUES (1, ?)', [on ? 1 : 0]);

  Future<void> _recordVersion(String type, String uuid, int lamport, String origin) =>
      _db.customStatement(
        'INSERT INTO entity_versions (entity_type, entity_uuid, lamport, origin_device_id) '
        'VALUES (?, ?, ?, ?) ON CONFLICT (entity_type, entity_uuid) DO UPDATE SET '
        'lamport = excluded.lamport, origin_device_id = excluded.origin_device_id '
        'WHERE excluded.lamport > entity_versions.lamport OR (excluded.lamport = '
        'entity_versions.lamport AND excluded.origin_device_id > entity_versions.origin_device_id)',
        [type, uuid, lamport, origin],
      );

  Future<int?> _idOf(String table, String uuid) async {
    final row = await _db.customSelect('SELECT id FROM $table WHERE uuid = ?',
        variables: [Variable(uuid)]).getSingleOrNull();
    return row?.data['id'] as int?;
  }

  Future<String?> _uuidOf(String table, int id) async {
    final row = await _db.customSelect('SELECT uuid FROM $table WHERE id = ?',
        variables: [Variable(id)]).getSingleOrNull();
    return row?.data['uuid'] as String?;
  }

  Future<bool> _isTombstoned(String table, int id) async {
    final row = await _db.customSelect('SELECT deleted_at FROM $table WHERE id = ?',
        variables: [Variable(id)]).getSingleOrNull();
    return row?.data['deleted_at'] != null;
  }

  Future<void> _tombstoneWhere(String table, String where, List<Object?> args, int now) =>
      _db.customStatement(
        'UPDATE $table SET deleted_at = ?, updated_at = ? WHERE deleted_at IS NULL AND ($where)',
        [now, now, ...args],
      );

  Future<void> _tombstoneGame(int gameId, int now) async {
    await _tombstoneWhere(
        'scores', 'roundId IN (SELECT id FROM rounds WHERE gameId = ?)', [gameId], now);
    await _tombstoneWhere(
        'scores', 'playerId IN (SELECT id FROM game_players WHERE gameId = ?)', [gameId], now);
    for (final table in ['rounds', 'game_players', 'game_analyses']) {
      await _tombstoneWhere(table, 'gameId = ?', [gameId], now);
    }
    await _tombstoneWhere('games', 'id = ?', [gameId], now);
  }

  Future<void> _insert(String table, Map<String, Object?> values) => _db.customInsert(
        'INSERT INTO $table (${values.keys.join(', ')}) '
        'VALUES (${List.filled(values.length, '?').join(', ')})',
        variables: [for (final v in values.values) Variable(v)],
      );

  Future<void> _update(String table, int id, Map<String, Object?> values) {
    if (values.isEmpty) return Future.value();
    return _db.customStatement(
      'UPDATE $table SET ${values.keys.map((k) => '$k = ?').join(', ')} WHERE id = ?',
      [...values.values, id],
    );
  }

  static int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  static String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);

  /// Local timestamps are ISO strings without an offset, in the device's zone.
  static String _isoUtc(String local) => DateTime.parse(local).toUtc().toIso8601String();

  /// The reverse of [_isoUtc]: a UTC timestamp from the server back into the
  /// device's zone, null passed straight through.
  static String? _localIso(String? utc) =>
      utc == null ? null : DateTime.parse(utc).toLocal().toIso8601String();

  static Map<String, dynamic> _deltaJson(PulledDelta d) => {
        'entity_type': d.entityType,
        'entity_uuid': d.entityUuid,
        'op': d.op,
        'payload': d.payload,
        'client_lamport': d.clientLamport,
        'origin_device_id': d.originDeviceId,
        'server_seq': d.serverSeq,
      };

  static PulledDelta _deltaFromJson(Map<String, dynamic> j) => (
        entityType: j['entity_type'] as String,
        entityUuid: j['entity_uuid'] as String,
        op: j['op'] as String,
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        clientLamport: j['client_lamport'] as int,
        originDeviceId: j['origin_device_id'] as String,
        serverSeq: j['server_seq'] as int,
      );
}
