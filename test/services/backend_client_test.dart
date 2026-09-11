// The analysis is the app's only network call, so this is the only place where
// a server's answer becomes something the UI can show. A non-200 must arrive as
// a status the user can read, not as a Dart exception carrying raw JSON.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:countscore/services/backend_client.dart';

/// Always answers with these bytes and this status.
///
/// `http.Response.bytes` on purpose: the `http.Response(String, int)`
/// constructor encodes through `_encodingForHeaders`, which falls back to
/// latin-1 with no charset — it would pre-corrupt the very fixtures that check
/// the decoding.
MockClient _answering(String body, int status) => MockClient(
      (_) async => http.Response.bytes(utf8.encode(body), status),
    );

void main() {
  group('zapzapAnalysis', () {
    test('a non-200 arrives as a BackendException carrying the status', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"detail":"upstream LLM error: RuntimeError"}', 502),
      );

      expect(
        () => client.zapzapAnalysis(const {}),
        throwsA(isA<BackendException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
    });

    test('the body is kept for logging, not thrown away', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"detail":"upstream LLM error: RuntimeError"}', 502),
      );

      try {
        await client.zapzapAnalysis(const {});
        fail('expected a BackendException');
      } on BackendException catch (e) {
        expect(e.body, contains('RuntimeError'));
        expect(e.toString(), contains('502'));
      }
    });

    test('an accented error body survives the decode', () async {
      // `response.body` would render this as mojibake: the server sends no
      // charset, so http falls back to latin-1.
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering('{"detail":"erreur amont côté fournisseur"}', 502),
      );

      try {
        await client.zapzapAnalysis(const {});
        fail('expected a BackendException');
      } on BackendException catch (e) {
        expect(e.body, contains('erreur amont côté fournisseur'));
      }
    });

    test('a 200 decodes the content as utf8', () async {
      final client = BackendClient(
        'https://countscore.example.com',
        httpClient: _answering(
          '{"content":"Le professeur a parlé.","model":"mistral-medium-latest"}',
          200,
        ),
      );

      final result = await client.zapzapAnalysis(const {});
      expect(result.content, 'Le professeur a parlé.');
      expect(result.model, 'mistral-medium-latest');
    });
  });
}
