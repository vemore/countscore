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

const _own = '33333333-3333-4333-8333-333333333333';
const _lost = '44444444-4444-4444-8444-444444444444';

/// A server that creates a group and has nothing to sync. [owner] is the device
/// the server says owns the group; null plays a server that predates owners.
/// [dormantOwner] plays an owner that has not been seen for the server's window —
/// the uninstalled phone — and [claimStatus] what it answers to a claim.
MockClient _server(
  List<http.BaseRequest> seen, {
  String? owner = _own,
  bool dormantOwner = false,
  int claimStatus = 200,
}) =>
    MockClient((request) async {
      seen.add(request);
      final claimed = claimStatus == 200 &&
          seen.any((r) => r.url.path == '/groups/me/owner/claim');
      final currentOwner = claimed
          ? _own
          : seen.any((r) => r.url.path == '/groups/me/owner')
              ? _lost
              : owner;
      if (request.url.path == '/groups/me/owner/claim') {
        return http.Response.bytes(utf8.encode('{}'), claimStatus);
      }
      final body = switch (request.url.path) {
        '/groups/me' when request.method == 'GET' => {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Famille',
            if (owner != null) 'owner_device_id': currentOwner,
          },
        '/groups/me/owner' => {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Famille',
            'owner_device_id': _lost,
          },
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
        '/groups/me/devices' => {
            'devices': [
              {
                'id': '33333333-3333-4333-8333-333333333333',
                'label': 'd',
                'joined_at': '2026-09-14T10:00:00Z',
                'last_seen_at': '2026-09-14T10:05:00Z',
                if (owner != null) 'is_owner': currentOwner == _own,
                if (owner != null) 'dormant': false,
              },
              if (!seen.any((r) => r.url.path.endsWith('/revoke')))
                {
                  'id': '44444444-4444-4444-8444-444444444444',
                  'label': 'Lost phone',
                  'joined_at': '2026-09-14T10:01:00Z',
                  'last_seen_at': '2026-09-14T10:02:00Z',
                  if (owner != null) 'is_owner': currentOwner == _lost,
                  if (owner != null) 'dormant': dormantOwner && !claimed,
                },
            ],
          },
        '/groups/me/devices/44444444-4444-4444-8444-444444444444/revoke' => {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Famille',
            'comment_style': 'narrative',
            'comment_language': 'fr',
            'monthly_budget_cents': 100,
            'current_month_used_cents': 0,
            'share_token': '55555555-5555-4555-8555-555555555555',
          },
        _ => <String, dynamic>{},
      };
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
    });

/// Pumps Settings → Group on a provider already pointed at [_server].
Future<GroupProvider> _pumpSection(
  WidgetTester tester,
  List<http.BaseRequest> seen, {
  String? owner = _own,
  bool dormantOwner = false,
  int claimStatus = 200,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final group = GroupProvider(
    db: db,
    credentials: MemorySyncCredentials(),
    httpClient: _server(
      seen,
      owner: owner,
      dormantOwner: dormantOwner,
      claimStatus: claimStatus,
    ),
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
  return group;
}

/// Lets the mock server's real futures complete, then settles the frames.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

Future<void> _createGroup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('group_create')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('group_field_0')), 'Famille');
  await tester.tap(find.byKey(const Key('group_dialog_ok')));
  // The exit transition runs here: this is where the disposed controllers used
  // to trip the framework.
  await _settle(tester);
}

void main() {
  testWidgets('creating a group through the dialog shows the group and its code', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen);

    await _createGroup(tester);

    expect(tester.takeException(), isNull);
    expect(seen.map((r) => r.url.path), contains('/groups'));
    expect(find.text('Group: Famille'), findsOneWidget);
    expect(find.byKey(const Key('group_share_token')), findsOneWidget);

    // Stop the poll timer before the binding checks for pending timers.
    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('removing a lost device shows the rotated invite code', (tester) async {
    const own = _own;
    const lost = _lost;
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen);
    await _createGroup(tester);

    await tester.tap(find.byKey(const Key('group_devices')));
    await _settle(tester);

    expect(find.text('Lost phone'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    // Leaving is the section's own button: this device offers no revoke.
    expect(find.byKey(const Key('group_device_revoke_$own')), findsNothing);

    await tester.tap(find.byKey(const Key('group_device_revoke_$lost')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_device_revoke_confirm')));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(
      seen.where((r) => r.method == 'POST').map((r) => r.url.path),
      contains('/groups/me/devices/$lost/revoke'),
    );
    expect(find.text('Lost phone'), findsNothing);
    expect(find.text('“Lost phone” was removed. The invite code has changed.'), findsOneWidget);
    expect(group.shareToken, '55555555-5555-4555-8555-555555555555');

    Navigator.of(tester.element(find.byType(GroupSettingsSection))).pop();
    await tester.pumpAndSettle();
    expect(find.text('55555555-5555-4555-8555-555555555555'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('the owner sees the rotate button and the owner mark', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen);
    await _createGroup(tester);

    expect(group.isOwner, isTrue);
    expect(find.byKey(const Key('group_rotate_share_token')), findsOneWidget);

    await tester.tap(find.byKey(const Key('group_devices')));
    await _settle(tester);
    expect(find.textContaining('Owner · '), findsOneWidget);
    expect(find.byKey(const Key('group_device_make_owner_$_lost')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('a member that is not the owner cannot rotate or remove', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen, owner: _lost);
    await _createGroup(tester);

    // The server said another device owns the group.
    expect(seen.map((r) => r.url.path), contains('/groups/me'));
    expect(group.isOwner, isFalse);
    expect(find.byKey(const Key('group_rotate_share_token')), findsNothing);

    await tester.tap(find.byKey(const Key('group_devices')));
    await _settle(tester);
    expect(find.text('Lost phone'), findsOneWidget);
    expect(find.byKey(const Key('group_device_revoke_$_lost')), findsNothing);
    expect(find.byKey(const Key('group_device_make_owner_$_lost')), findsNothing);
    // The owner is about: there is nothing to claim either.
    expect(find.byKey(const Key('group_device_claim_$_lost')), findsNothing);
    expect(
      find.text("Only the group's owner can remove a device or change the invite code."),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('the owner hands the group over and loses the owner actions', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen);
    await _createGroup(tester);

    await tester.tap(find.byKey(const Key('group_devices')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('group_device_make_owner_$_lost')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_device_make_owner_confirm')));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    final put = seen.lastWhere((r) => r.url.path == '/groups/me/owner') as http.Request;
    expect(put.method, 'PUT');
    expect(jsonDecode(put.body), {'device_id': _lost});
    expect(group.isOwner, isFalse);
    expect(find.text('“Lost phone” now owns the group.'), findsOneWidget);
    expect(find.byKey(const Key('group_device_revoke_$_lost')), findsNothing);

    Navigator.of(tester.element(find.byType(GroupSettingsSection))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_rotate_share_token')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('a member claims the group from an owner that has gone quiet', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen, owner: _lost, dormantOwner: true);
    await _createGroup(tester);

    expect(group.isOwner, isFalse);
    await tester.tap(find.byKey(const Key('group_devices')));
    await _settle(tester);

    await tester.tap(find.byKey(const Key('group_device_claim_$_lost')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_device_claim_confirm')));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    final claim = seen.lastWhere((r) => r.url.path == '/groups/me/owner/claim');
    expect(claim.method, 'POST');
    expect(group.isOwner, isTrue);
    expect(find.text('This device now owns the group.'), findsOneWidget);
    // With the role in hand, the owner actions are back on the other device.
    expect(find.byKey(const Key('group_device_revoke_$_lost')), findsOneWidget);

    Navigator.of(tester.element(find.byType(GroupSettingsSection))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_rotate_share_token')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('a claim the server refuses leaves the role where it was', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(
      tester,
      seen,
      owner: _lost,
      dormantOwner: true,
      claimStatus: 409,
    );
    await _createGroup(tester);

    await tester.tap(find.byKey(const Key('group_devices')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('group_device_claim_$_lost')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_device_claim_confirm')));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(group.isOwner, isFalse);
    expect(
      find.text("The group's owner has been seen recently: ownership cannot be claimed."),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });

  testWidgets('a server that predates owners leaves every device the actions', (tester) async {
    final seen = <http.BaseRequest>[];
    final group = await _pumpSection(tester, seen, owner: null);
    await _createGroup(tester);

    expect(group.isOwner, isTrue);
    expect(find.byKey(const Key('group_rotate_share_token')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    group.dispose();
  });
}
