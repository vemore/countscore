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

  /// Posts a finished game to `/comments/zapzap-analysis` and returns the
  /// generated commentary. Throws on any non-200, and on timeout.
  Future<({String content, String? model})> zapzapAnalysis(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/comments/zapzap-analysis'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(analysisTimeout);

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
}
