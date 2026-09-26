// The "share configuration" link (wip/done/2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code.md).
// The invite code is a credential: everything but the PWA's root must sit after
// `#`, which a browser never sends to the server or its logs.

import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/utils/config_link.dart';

const _base = 'https://scores.example.com/countscore';
const _server = 'https://scores.example.com';
const _invite = '22222222-2222-4222-8222-222222222222';

/// The part of [link] a browser sends to the server: everything before `#`.
String _sentToServer(String link) => link.split('#').first;

void main() {
  group('encode → parse round-trips', () {
    test('a server and a group', () {
      const config = ConfigLink(server: _server, invite: _invite);
      expect(parseConfigLink(encodeConfigLink(_base, config)), config);
    });

    test('a server with no group', () {
      const config = ConfigLink(server: _server);
      final link = encodeConfigLink(_base, config);
      expect(link, isNot(contains('g=')));
      expect(parseConfigLink(link), config);
    });

    test('a server with a base path, a port and a LAN address', () {
      for (final server in const [
        'https://example.com:8443/api',
        'http://192.168.1.50:8000',
        'http://nas.local',
      ]) {
        final config = ConfigLink(server: server, invite: _invite);
        expect(parseConfigLink(encodeConfigLink(_base, config)), config, reason: server);
      }
    });

    test('the app hand-over shape, with and without a group', () {
      for (final config in const [
        ConfigLink(server: _server, invite: _invite),
        ConfigLink(server: _server),
      ]) {
        final link = encodeAppConfigLink(config);
        expect(link, startsWith('countscore://join?s='));
        expect(parseConfigLink(link), config);
      }
    });
  });

  group('encodeConfigLink', () {
    test('has the form <base>/#/join?s=…&g=…', () {
      final link = encodeConfigLink(_base, const ConfigLink(server: _server, invite: _invite));
      expect(link, '$_base/#/join?s=https%3A%2F%2Fscores.example.com&g=$_invite');
    });

    test('puts the server and the invite code only after #', () {
      final link = encodeConfigLink(
        '$_base/',
        const ConfigLink(server: 'https://api.example.org', invite: _invite),
      );
      final uri = Uri.parse(link);
      expect(uri.path, '/countscore/', reason: 'the path is the PWA root, nothing more');
      expect(uri.hasQuery, isFalse, reason: 'no query before #');
      expect(uri.fragment, startsWith('/join?'));
      final sent = _sentToServer(link);
      expect(sent, '$_base/');
      expect(sent, isNot(contains(_invite)));
      expect(sent, isNot(contains('api.example.org')));
      expect(sent, isNot(contains('s=')));
    });

    test('refuses a base that is not a PWA root URL', () {
      for (final base in const [
        '',
        'scores.example.com/countscore',
        'http://example.com/countscore', // cleartext on a public host
        'https://example.com/countscore?x=1',
        'https://example.com/countscore#/',
        'ftp://example.com',
      ]) {
        expect(() => encodeConfigLink(base, const ConfigLink(server: _server)),
            throwsArgumentError, reason: base);
      }
    });
  });

  group('parseConfigLink', () {
    test('reads both shapes', () {
      expect(parseConfigLink('$_base/#/join?s=$_server&g=$_invite'),
          const ConfigLink(server: _server, invite: _invite));
      expect(parseConfigLink('countscore://join?s=$_server&g=$_invite'),
          const ConfigLink(server: _server, invite: _invite));
      expect(parseConfigLink('  countscore://join/?s=$_server  '),
          const ConfigLink(server: _server));
    });

    test('canonicalises the server as Settings would', () {
      expect(parseConfigLink('$_base/#/join?s=https%3A%2F%2Fscores.example.com%2F')?.server,
          _server);
    });

    test('reads an empty or blank g as no group', () {
      expect(parseConfigLink('$_base/#/join?s=$_server&g=')?.invite, isNull);
      expect(parseConfigLink('$_base/#/join?s=$_server&g=+')?.invite, isNull);
    });

    test('ignores s and g in a query before #', () {
      expect(parseConfigLink('$_base/?s=$_server&g=$_invite#/join'), isNull);
      expect(
        parseConfigLink('$_base/?s=https://evil.example.com&g=x#/join?s=$_server&g=$_invite'),
        const ConfigLink(server: _server, invite: _invite),
      );
    });

    test('refuses anything else', () {
      for (final link in const [
        '',
        'not a link',
        '$_base/join?s=$_server&g=$_invite', // a path, not the hash route
        '$_base/#/home?s=$_server',
        '$_base/#/join',
        '$_base/#/join?g=$_invite',
        '$_base/#/join?s=ftp://example.com',
        '$_base/#/join?s=http://example.com', // cleartext on a public host
        '$_base/#/join?s=$_server&g=two words',
        '$_base/#/join?s=%E0%A4%A',
        '$_base/#//evil.example.com/join?s=$_server',
        'countscore://other?s=$_server',
        'countscore://join/more?s=$_server',
        'countscore://join?s=$_server#frag',
        'mailto:join?s=$_server',
      ]) {
        expect(parseConfigLink(link), isNull, reason: link);
      }
    });

    test('refuses an overlong invite code', () {
      expect(parseConfigLink('$_base/#/join?s=$_server&g=${'a' * 129}'), isNull);
      expect(parseConfigLink('$_base/#/join?s=$_server&g=${'a' * 128}')?.invite, 'a' * 128);
    });
  });

  group('pwaBaseFromUri', () {
    test('reads the PWA root from the page address', () {
      expect(pwaBaseFromUri(Uri.parse('https://scores.example.com/countscore/#/')), _base);
      expect(pwaBaseFromUri(Uri.parse('https://scores.example.com/countscore/index.html')), _base);
      expect(pwaBaseFromUri(Uri.parse('https://scores.example.com/countscore/?v=2#/join?s=x')),
          _base);
      expect(pwaBaseFromUri(Uri.parse('https://owner.github.io/countscore/')),
          'https://owner.github.io/countscore');
      expect(pwaBaseFromUri(Uri.parse('http://localhost:8080/')), 'http://localhost:8080');
    });

    test('is null where there is no web page', () {
      expect(pwaBaseFromUri(Uri.parse('file:///data/app/')), isNull);
      expect(pwaBaseFromUri(Uri.parse('/countscore/')), isNull);
    });
  });

  test('toString keeps the invite code out', () {
    expect(const ConfigLink(server: _server, invite: _invite).toString(),
        isNot(contains(_invite)));
  });
}
