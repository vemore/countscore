// Settings → Group, pumped with asserts on. The create dialog once disposed its
// text controllers while its exit transition was still building the fields,
// which only a debug build notices (`_dependents.isEmpty`) — found on a Pixel on
// 2026-09-13, invisible in the release PWA.

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
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/widgets/group_settings_section.dart';

/// A server that creates a group and has nothing to sync.
MockClient _server(List<http.BaseRequest> seen) => MockClient((request) async {
      seen.add(request);
      final body = switch (request.url.path) {
        '/groups' => {
            'group': {
              'id': '11111111-1111-4111-8111-111111111111',
              'name': jsonDecode(request.body)['name'],
              'comment_style': 'narrative',
              'comment_language': 'fr',
              'monthly_budget_cents': 100,
              'current_month_used_cents': 0,
              'share_token': '22222222-2222-4222-8222-222222222222',
            },
            'device': {
              'id': '33333333-3333-4333-8333-333333333333',
              'token': '33333333333343338333333333333333.secret',
              'label': 'd',
            },
          },
        '/sync/pull' => {'deltas': [], 'server_seq_max': 0, 'has_more': false},
        _ => <String, dynamic>{},
      };
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
    });

void main() {
  testWidgets('creating a group through the dialog shows the group and its code', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seen = <http.BaseRequest>[];
    final group = GroupProvider(
      db: db,
      credentials: MemorySyncCredentials(),
      httpClient: _server(seen),
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
    await tester.runAsync(() => group.updateBackend('https://countscore.example.com'));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BackendProvider('https://countscore.example.com')),
        ChangeNotifierProvider.value(value: group),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: Scaffold(body: SingleChildScrollView(child: GroupSettingsSection())),
      ),
    ));

    await tester.tap(find.byKey(const Key('group_create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('group_field_0')), 'Famille');
    await tester.tap(find.byKey(const Key('group_dialog_ok')));
    // The exit transition runs here: this is where the disposed controllers used
    // to trip the framework.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(seen.map((r) => r.url.path), contains('/groups'));
    expect(find.text('Group: Famille'), findsOneWidget);
    expect(find.byKey(const Key('group_share_token')), findsOneWidget);

    // Stop the poll timer before the binding checks for pending timers.
    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });
}
