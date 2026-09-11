// The backend URL is a user setting with no default: an app that has never
// been configured must stay entirely offline. These tests pin the validation
// rules that decide what may be stored, and the persistence round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countscore/providers/backend_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackendProvider.check', () {
    test('accepts https and strips a trailing slash', () {
      expect(BackendProvider.normalize('https://countscore.example.com/'),
          'https://countscore.example.com');
      expect(BackendProvider.normalize('  https://countscore.example.com  '),
          'https://countscore.example.com');
    });

    test('keeps an explicit port and a base path', () {
      expect(BackendProvider.normalize('https://example.com:8443/countscore/'),
          'https://example.com:8443/countscore');
    });

    test('accepts http on a private or loopback address', () {
      for (final url in const [
        'http://192.168.1.50:8000',
        'http://10.0.0.4',
        'http://172.16.3.9',
        'http://127.0.0.1:8000',
        'http://localhost:8000',
        'http://nas.local',
        'http://countscore.lan',
      ]) {
        expect(BackendProvider.normalize(url), isNotNull, reason: url);
      }
    });

    test('refuses http on a public host', () {
      final check = BackendProvider.check('http://example.com');
      expect(check.url, isNull);
      expect(check.error, BackendUrlError.insecure);
      // 172.32 is outside 172.16/12 — the off-by-one that makes the range easy
      // to get wrong.
      expect(BackendProvider.check('http://172.32.0.1').error,
          BackendUrlError.insecure);
    });

    test('refuses anything that is not an absolute http(s) URL', () {
      for (final raw in const [
        'not a url',
        'countscore.example.com',
        'ftp://example.com',
        'ws://example.com',
        'https://example.com?token=x',
        'https://example.com#frag',
      ]) {
        expect(BackendProvider.check(raw).error, BackendUrlError.malformed,
            reason: raw);
      }
    });

    test('an empty field is a request to clear, not a mistake', () {
      expect(BackendProvider.check('   ').error, BackendUrlError.empty);
    });
  });

  group('BackendProvider persistence', () {
    test('a clean install with no --dart-define is not configured', () async {
      SharedPreferences.setMockInitialValues({});
      expect(BackendProvider.seed, isEmpty,
          reason: 'tests must not be run with --dart-define=BACKEND_URL');
      expect(await BackendProvider.load(), isNull);
      expect(BackendProvider(null).isConfigured, isFalse);
    });

    test('a saved URL survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = BackendProvider(null);
      await provider.setBaseUrl('https://countscore.example.com');
      expect(provider.isConfigured, isTrue);
      expect(await BackendProvider.load(), 'https://countscore.example.com');
    });

    test('clearing switches the connected features back off', () async {
      SharedPreferences.setMockInitialValues(
          {'backendUrl': 'https://countscore.example.com'});
      final provider = BackendProvider(await BackendProvider.load());
      expect(provider.isConfigured, isTrue);
      await provider.clear();
      expect(provider.isConfigured, isFalse);
      // Stored as empty rather than removed, so the build-time seed cannot
      // quietly reinstate a server the user deliberately removed.
      expect(await BackendProvider.load(), isNull);
    });

    test('testConnection is false when nothing is configured', () async {
      expect(await BackendProvider(null).testConnection(), isFalse);
    });
  });
}
