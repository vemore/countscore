import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A non-2xx answer from the configured backend.
///
/// Carries the status code, which is genuinely useful to a user who runs the
/// server themselves, and the decoded body for logging — never for display: the
/// body is the server's raw JSON and usually names an internal exception type.
class BackendException implements Exception {
  BackendException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'BackendException($statusCode): $body';
}

/// A group this device belongs to, as `POST /groups` and `/groups/join` return it.
///
/// [deviceToken] is a bearer credential: it goes to secure storage and nowhere
/// else. [shareToken] is what another device pastes to join.
typedef GroupMembership = ({
  String groupId,
  String groupName,
  String shareToken,
  String deviceId,
  String deviceToken,
});

/// A member device of the caller's group, as `GET /groups/me/devices` lists it.
///
/// [isOwner] is null when the server predates group owners (every device equal).
typedef GroupDevice = ({
  String id,
  String label,
  DateTime joinedAt,
  DateTime lastSeenAt,
  bool? isOwner,
});

/// One delta as `/sync/pull` returns it.
typedef PulledDelta = ({
  String entityType,
  String entityUuid,
  String op,
  Map<String, dynamic> payload,
  int clientLamport,
  String originDeviceId,
  int serverSeq,
});

/// The server's verdict on one pushed delta.
typedef PushResult = ({String status, int? serverSeq, String? reason});

/// The single place that knows how to turn a backend base URL into a request.
///
/// The base URL is supplied by the user at runtime (see [BackendProvider]);
/// there is no default, so a client is only ever constructed once a server has
/// been configured.
class BackendClient {
  BackendClient(this.baseUrl, {http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  /// Absolute origin with no trailing slash, e.g. `https://countscore.example`.
  final String baseUrl;
  final http.Client _client;

  /// Generous: the LLM writes several hundred tokens of Markdown.
  static const analysisTimeout = Duration(seconds: 90);

  /// Short on purpose — this one answers a user waiting on a button.
  static const healthTimeout = Duration(seconds: 10);

  /// Group and sync calls: small JSON both ways, but a pull page can be 500 deltas
  /// over a phone network.
  static const syncTimeout = Duration(seconds: 30);

  /// `true` when the server answers `GET /health` with 200.
  ///
  /// Never throws: an unreachable host, a TLS failure and a 502 are all the
  /// same answer to the user pressing "test connection".
  Future<bool> health() async {
    try {
      final response =
          await _client.get(Uri.parse('$baseUrl/health')).timeout(healthTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// The path the analysis moved to once it stopped being ZapZap-only.
  static const analysisPath = '/comments/game-analysis';

  /// What the same endpoint was called until then. A self-hosted backend is
  /// upgraded on its owner's schedule, so a phone that updates first must not
  /// lose the feature: [gameAnalysis] retries here on a 404.
  static const legacyAnalysisPath = '/comments/zapzap-analysis';

  /// Posts a finished game for analysis and returns the generated commentary.
  /// Throws on any non-200, and on timeout.
  Future<({String content, String? model})> gameAnalysis(
    Map<String, dynamic> payload,
  ) async {
    var response = await _postAnalysis(analysisPath, payload);
    if (response.statusCode == 404) {
      // A backend older than the rename. It ignores `style` and `language` —
      // its schema drops unknown fields — so the answer is the French
      // professor: degraded, but an analysis.
      response = await _postAnalysis(legacyAnalysisPath, payload);
    }

    if (response.statusCode != 200) {
      // bodyBytes, not body: `body` falls back to latin-1 when the response
      // carries no charset, which turns an accented error message into mojibake.
      throw BackendException(
        response.statusCode,
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (
      content: body['content'] as String,
      model: body['model'] as String?,
    );
  }

  Future<http.Response> _postAnalysis(
    String path,
    Map<String, dynamic> payload,
  ) {
    return _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(analysisTimeout);
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  /// `POST /groups`: creates a group with this device as its first member.
  Future<GroupMembership> createGroup(String name, String deviceLabel) async {
    final body = await _send('POST', '/groups', body: {
      'name': name,
      'device_label': deviceLabel,
    });
    return _membership(body);
  }

  /// `POST /groups/join`. A 404 means the share token is unknown or was rotated.
  Future<GroupMembership> joinGroup(String shareToken, String deviceLabel) async {
    final body = await _send('POST', '/groups/join', body: {
      'share_token': shareToken,
      'device_label': deviceLabel,
    });
    return _membership(body);
  }

  /// `POST /groups/me/rotate-share-token`: invalidates the old link, returns the new.
  Future<String> rotateShareToken(String deviceToken) async {
    final body = await _send('POST', '/groups/me/rotate-share-token',
        token: deviceToken);
    return body['share_token'] as String;
  }

  /// `GET /groups/me/devices`: the group's active devices, oldest first.
  Future<List<GroupDevice>> listDevices(String deviceToken) async {
    final body = await _send('GET', '/groups/me/devices', token: deviceToken);
    return [
      for (final d in body['devices'] as List)
        (
          id: d['id'] as String,
          label: d['label'] as String,
          joinedAt: DateTime.parse(d['joined_at'] as String),
          lastSeenAt: DateTime.parse(d['last_seen_at'] as String),
          isOwner: d['is_owner'] as bool?,
        ),
    ];
  }

  /// `GET /groups/me`: the id of the group's owner device.
  ///
  /// [known] is false when the server predates group owners and sends no
  /// `owner_device_id` at all — every device is then equal.
  Future<({bool known, String? ownerDeviceId})> groupOwner(String deviceToken) async {
    final body = await _send('GET', '/groups/me', token: deviceToken);
    return (
      known: body.containsKey('owner_device_id'),
      ownerDeviceId: body['owner_device_id'] as String?,
    );
  }

  /// `PUT /groups/me/owner`: hands the owner role to [deviceId]. Owner only (403).
  Future<void> transferOwnership(String deviceToken, String deviceId) async {
    await _send('PUT', '/groups/me/owner', token: deviceToken, body: {'device_id': deviceId});
  }

  /// `POST /groups/me/devices/{id}/revoke`.
  ///
  /// On another device's id the server also rotates the invite code and returns
  /// the new one. On this device's own id it is leaving: 204, and null here.
  Future<String?> revokeDevice(String deviceToken, String deviceId) async {
    final body = await _send('POST', '/groups/me/devices/$deviceId/revoke',
        token: deviceToken);
    return body['share_token'] as String?;
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// `POST /sync/push`. Results come back in the order of [deltas].
  Future<List<PushResult>> push(
      String deviceToken, List<Map<String, dynamic>> deltas) async {
    final body = await _send('POST', '/sync/push',
        token: deviceToken, body: {'deltas': deltas});
    return [
      for (final r in body['results'] as List)
        (
          status: r['status'] as String,
          serverSeq: r['server_seq'] as int?,
          reason: r['reason'] as String?,
        ),
    ];
  }

  /// `GET /sync/pull?since_seq=…`.
  Future<({List<PulledDelta> deltas, int serverSeqMax, bool hasMore})> pull(
      String deviceToken, int sinceSeq, {int limit = 500}) async {
    final body = await _send('GET', '/sync/pull?since_seq=$sinceSeq&limit=$limit',
        token: deviceToken);
    return (
      deltas: [
        for (final d in body['deltas'] as List)
          (
            entityType: d['entity_type'] as String,
            entityUuid: d['entity_uuid'] as String,
            op: d['op'] as String,
            payload: (d['payload'] as Map).cast<String, dynamic>(),
            clientLamport: d['client_lamport'] as int,
            originDeviceId: d['origin_device_id'] as String,
            serverSeq: d['server_seq'] as int,
          ),
      ],
      serverSeqMax: body['server_seq_max'] as int,
      hasMore: body['has_more'] as bool,
    );
  }

  /// `POST /sync/ws-ticket`, then the URL to open with it. The device token never
  /// appears in the stream URL; the ticket dies on first use.
  Future<Uri> streamUri(String deviceToken) async {
    final body = await _send('POST', '/sync/ws-ticket', token: deviceToken);
    final base = Uri.parse(baseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/sync/stream',
      queryParameters: {'ticket': body['ticket'] as String},
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    // Every write needs a body the server can measure: it answers 411 to a POST
    // without Content-Length (backend/app/main.py, limit_body_size).
    if (method != 'GET') {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body ?? const {});
    }
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(syncTimeout),
    ).timeout(syncTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(
        response.statusCode,
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
    }
    if (response.bodyBytes.isEmpty) return const {};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  static GroupMembership _membership(Map<String, dynamic> body) {
    final group = body['group'] as Map<String, dynamic>;
    final device = body['device'] as Map<String, dynamic>;
    return (
      groupId: group['id'] as String,
      groupName: group['name'] as String,
      shareToken: group['share_token'] as String,
      deviceId: device['id'] as String,
      deviceToken: device['token'] as String,
    );
  }
}
