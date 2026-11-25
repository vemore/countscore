// Settings → Groups as a list (wip/done/2026-11-25-multi-group-ui.md): one
// card per group with its own sync status and its own Leave, one nickname for
// all of them above, and Create and Join hidden at five groups. On the real
// GroupProvider, against a mock server holding several groups.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/widgets/group_settings_section.dart';

import '../support/group_servers.dart';

const _url = 'https://countscore.example.com';

/// A device in groups [joined] (1 to 5) of a [MultiGroupServer], as "Alice",
/// with Settings → Groups on screen.
Future<(GroupProvider, MultiGroupServer)> _pump(
  WidgetTester tester,
  List<int> joined, {
  Set<int> down = const {},
}) async {
  final server = MultiGroupServer();
  server.down.addAll([for (final n in down) 'token-$n']);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final group = GroupProvider(
    db: db,
    credentials: MemorySyncCredentials(),
    httpClient: server.client,
    enableStream: false,
    pollInterval: const Duration(hours: 1),
  );
  await tester.runAsync(() async {
    await group.updateBackend(_url);
    for (final n in joined) {
      await group.joinGroup('invite-$n', 'Alice');
    }
    await idle(group);
  });
  tester.view.physicalSize = const Size(412, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BackendProvider(_url)),
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
  await tester.pumpAndSettle();
  addTearDown(() async {
    group.dispose();
    await db.close();
  });
  return (group, server);
}

Finder _card(int n) => find.byKey(Key('group_card_${groupIdOf(n)}'));

Finder _in(int n, String key) => find.descendant(of: _card(n), matching: find.byKey(Key(key)));

String _status(WidgetTester tester, int n) => tester.widget<Text>(_in(n, 'group_status')).data!;

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

Future<void> _end(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('one card per group, in join order, under one nickname', (tester) async {
    await _pump(tester, [1, 2]);

    expect(_card(1), findsOneWidget);
    expect(_card(2), findsOneWidget);
    expect(tester.getTopLeft(_card(1)).dy, lessThan(tester.getTopLeft(_card(2)).dy));
    expect(tester.widget<Text>(_in(1, 'group_name')).data, 'Groupe 1');
    expect(tester.widget<Text>(_in(2, 'group_name')).data, 'Groupe 2');
    // One nickname for every group, above the list rather than in each card.
    expect(find.byKey(const Key('group_nickname')), findsOneWidget);
    expect(find.text('Your nickname: Alice'), findsOneWidget);
    // Folded while there are several: the actions are one tap away.
    expect(find.byKey(const Key('group_leave')), findsNothing);
    expect(find.byKey(const Key('group_create')), findsOneWidget);
    expect(find.byKey(const Key('group_join')), findsOneWidget);
    await _end(tester);
  });

  testWidgets('a single group is unfolded from the start', (tester) async {
    await _pump(tester, [1]);
    expect(_in(1, 'group_leave'), findsOneWidget);
    expect(_in(1, 'group_share_token'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('each card shows its own sync status', (tester) async {
    await _pump(tester, [1, 2], down: {2});

    expect(_status(tester, 1), startsWith('Synced at '));
    expect(_status(tester, 2), 'Server unreachable — changes will be sent later');
    final icon1 = tester.widget<Icon>(find.descendant(of: _card(1), matching: find.byType(Icon)).first);
    final icon2 = tester.widget<Icon>(find.descendant(of: _card(2), matching: find.byType(Icon)).first);
    expect(icon1.icon, Icons.cloud_done);
    expect(icon2.icon, Icons.cloud_off);
    await _end(tester);
  });

  testWidgets('leaving one group keeps the others, and says which is left', (tester) async {
    final (group, server) = await _pump(tester, [1, 2, 3]);

    await tester.tap(find.descendant(of: _card(2), matching: find.text('Groupe 2')));
    await tester.pumpAndSettle();
    await tester.tap(_in(2, 'group_leave'));
    await _settle(tester);
    expect(
      find.text('This device leaves the group Groupe 2. Its shared games stay on this device '
          'but will no longer sync. Your other groups are unchanged.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Leave group').last);
    await _settle(tester);

    expect([for (final s in group.memberships) s.groupId], [groupIdOf(1), groupIdOf(3)]);
    expect(_card(2), findsNothing);
    expect(_card(1), findsOneWidget);
    expect(_card(3), findsOneWidget);
    expect(server.calls(2, '/groups/me/devices/${deviceIdOf(2)}/revoke'), hasLength(1));
    expect(server.seen.where((r) => r.url.path.endsWith('/revoke')), hasLength(1),
        reason: 'the other groups are not left');
    expect(find.text('Left the group'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('at five groups, Create and Join give way to a note; leaving one brings them back',
      (tester) async {
    final (group, _) = await _pump(tester, [1, 2, 3, 4, 5]);

    expect(group.canJoinMore, isFalse);
    expect(find.byKey(const Key('group_create')), findsNothing);
    expect(find.byKey(const Key('group_join')), findsNothing);
    expect(
      find.text('Maximum number of groups reached (5): leave one to create or join another.'),
      findsOneWidget,
    );

    await tester.runAsync(() => group.leaveGroup(groupIdOf(5)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_create')), findsOneWidget);
    expect(find.byKey(const Key('group_join')), findsOneWidget);
    expect(find.byKey(const Key('group_max_reached')), findsNothing);
    await _end(tester);
  });
}
