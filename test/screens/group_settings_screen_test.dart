// Settings → Group → Comments and usage: the group's comment style and language,
// held on the server and editable by any member, and the LLM usage this month.
// The monthly budget is the owner's alone on the server (#117): the app must
// never send it, whoever is the owner.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/screens/group_settings_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/widgets/group_settings_section.dart';

const _url = 'https://countscore.example.com';
const _own = '33333333-3333-4333-8333-333333333333';

/// A server holding one group's settings, which PATCH changes — so a second visit
/// reads back what the first one wrote, as after a restart.
class _Server {
  final seen = <http.Request>[];
  String style = 'narrative';
  String language = 'fr';
  int? failStatus;

  Map<String, dynamic> get _group => {
        'id': '11111111-1111-4111-8111-111111111111',
        'name': 'Famille',
        'owner_device_id': _own,
        'comment_style': style,
        'comment_language': language,
        'monthly_budget_cents': 100,
        'current_month_used_cents': 42,
      };

  late final client = MockClient((request) async {
    seen.add(request);
    final path = request.url.path;
    if (failStatus != null && path.startsWith('/groups/me') && path != '/groups/me/devices') {
      return http.Response.bytes(utf8.encode('{"detail":"nope"}'), failStatus!);
    }
    final Map<String, dynamic> body = switch (path) {
      '/groups' => {
          'group': {..._group, 'share_token': '22222222-2222-4222-8222-222222222222'},
          'device': {'id': _own, 'token': '33333333333343338333333333333333.secret', 'label': 'd'},
        },
      '/groups/me' => _group,
      '/groups/me/settings' => () {
          final patch = jsonDecode(request.body) as Map<String, dynamic>;
          style = patch['comment_style'] as String? ?? style;
          language = patch['comment_language'] as String? ?? language;
          return _group;
        }(),
      '/groups/me/usage' => {
          'current_month_used_cents': 42,
          'budget_cents': 100,
          'resets_at': '2026-10-01T00:00:00Z',
        },
      '/sync/pull' => {'deltas': [], 'server_seq_max': 0, 'has_more': false},
      _ => <String, dynamic>{},
    };
    return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
  });

  Iterable<http.Request> get settingsCalls =>
      seen.where((r) => r.url.path == '/groups/me/settings' || r.url.path == '/groups/me/usage');
}

Future<GroupProvider> _provider(_Server server, {String? url = _url, bool joined = true}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final group = GroupProvider(
    db: db,
    credentials: MemorySyncCredentials(),
    httpClient: server.client,
    enableStream: false,
    pollInterval: const Duration(hours: 1),
  );
  if (joined) {
    await group.updateBackend(_url);
    await group.createGroup('Famille', 'd');
  }
  await group.updateBackend(url);
  return group;
}

Future<void> _pump(WidgetTester tester, GroupProvider group, Widget home, {String? url = _url}) {
  return tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BackendProvider(url)),
      ChangeNotifierProvider.value(value: group),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    ),
  ));
}

/// Lets the mock server's real futures complete, then settles the frames.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester, GroupProvider group) async {
  await tester.pumpWidget(const SizedBox());
  group.dispose();
}

ChoiceChip _chip(WidgetTester tester, String style) =>
    tester.widget<ChoiceChip>(find.byKey(Key('group_comment_style_$style')));

void main() {
  testWidgets('shows the style, the language and the usage from the server', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _provider(server)))!;
    await _pump(tester, group, const GroupSettingsScreen());
    await _settle(tester);

    expect(_chip(tester, 'narrative').selected, isTrue);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text(r'$0.42 spent of $1.00'), findsOneWidget);
    expect(find.text('Resets on Oct 1, 2026'), findsOneWidget);

    await _dispose(tester, group);
  });

  testWidgets('a new style and language are written to the server and read back on the next visit',
      (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _provider(server)))!;
    await _pump(tester, group, const GroupSettingsScreen());
    await _settle(tester);

    await tester.tap(find.byKey(const Key('group_comment_style_humorous')));
    await _settle(tester);
    expect(find.text('Group settings saved'), findsOneWidget);
    expect(_chip(tester, 'humorous').selected, isTrue);

    await tester.tap(find.byKey(const Key('group_comment_language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await _settle(tester);

    final patches = server.seen.where((r) => r.method == 'PATCH').toList();
    expect(patches.map((r) => jsonDecode(r.body)), [
      {'comment_style': 'humorous'},
      {'comment_language': 'en'},
    ]);
    // Never the budget: it is the owner's, and this device is the owner here.
    expect(patches.any((r) => r.body.contains('monthly_budget_cents')), isFalse);

    // A fresh visit — as after a restart — shows what the server now holds.
    await _pump(tester, group, const SizedBox());
    await _pump(tester, group, const GroupSettingsScreen());
    await _settle(tester);
    expect(_chip(tester, 'humorous').selected, isTrue);
    expect(find.text('English'), findsOneWidget);

    await _dispose(tester, group);
  });

  testWidgets('a refused change keeps what the server holds and says why', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _provider(server)))!;
    await _pump(tester, group, const GroupSettingsScreen());
    await _settle(tester);

    server.failStatus = 500;
    await tester.tap(find.byKey(const Key('group_comment_style_analytical')));
    await _settle(tester);

    expect(_chip(tester, 'narrative').selected, isTrue);
    expect(find.text('Group settings saved'), findsNothing);
    expect(find.text('Server error'), findsOneWidget);
    expect(server.style, 'narrative');

    await _dispose(tester, group);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _provider(server)))!;
    server.failStatus = 503;
    await _pump(tester, group, const GroupSettingsScreen());
    await _settle(tester);

    expect(find.byKey(const Key('group_settings_retry')), findsOneWidget);
    server.failStatus = null;
    await tester.tap(find.byKey(const Key('group_settings_retry')));
    await _settle(tester);
    expect(_chip(tester, 'narrative').selected, isTrue);

    await _dispose(tester, group);
  });

  testWidgets('with no server URL nothing is requested', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() async {
      final g = await _provider(server, url: null);
      // The first sync pass of the join may still be in flight: let it land.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return g;
    }))!;
    server.seen.clear();
    await _pump(tester, group, const GroupSettingsScreen(), url: null);
    await _settle(tester);

    expect(server.seen, isEmpty);
    expect(find.byKey(const Key('group_comment_language')), findsNothing);

    await _dispose(tester, group);
  });

  testWidgets('outside a group nothing is requested and the section offers no entry',
      (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _provider(server, joined: false)))!;
    await _pump(tester, group, const GroupSettingsScreen());
    await _settle(tester);
    expect(server.settingsCalls, isEmpty);
    expect(server.seen.where((r) => r.url.path == '/groups/me'), isEmpty);

    await _pump(tester, group, const Scaffold(body: SingleChildScrollView(child: GroupSettingsSection())));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_settings_open')), findsNothing);

    await _dispose(tester, group);
  });

  testWidgets('a member of a group opens the screen from Settings → Group', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _provider(server)))!;
    await _pump(tester, group, const Scaffold(body: SingleChildScrollView(child: GroupSettingsSection())));
    await _settle(tester);

    await tester.tap(find.byKey(const Key('group_settings_open')));
    await _settle(tester);
    expect(find.byType(GroupSettingsScreen), findsOneWidget);
    expect(find.text(r'$0.42 spent of $1.00'), findsOneWidget);

    await _dispose(tester, group);
  });
}
