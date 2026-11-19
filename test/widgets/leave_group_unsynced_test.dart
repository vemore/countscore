// Settings → Group *Leave* and Settings → Server *Clear*, on a real GroupProvider:
// leaving empties the outbox, so both say how many changes would be lost, counted
// when the button is pressed, and change nothing on Cancel.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/providers/settings_provider.dart';
import 'package:countscore/providers/theme_provider.dart';
import 'package:countscore/screens/settings_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

import '../support/group_servers.dart' as real;

class _Harness {
  _Harness(this.group, this.db, this.backend);
  final GroupProvider group;
  final AppDatabase db;
  final BackendProvider backend;
}

Future<_Harness> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final servers = real.GroupServers();
  final group = GroupProvider(
    db: db,
    credentials: MemorySyncCredentials(),
    httpClient: servers.client,
    enableStream: false,
    pollInterval: const Duration(hours: 1),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    group.dispose();
    await db.close();
  });
  await tester.runAsync(() async {
    await group.updateBackend(real.oldServer);
    await group.joinGroup(real.oldInvite, 'Phone');
    await real.idle(group);
  });
  final backend = BackendProvider(real.oldServer);
  final settings = SettingsProvider();
  await tester.runAsync(() => settings.ready);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: backend),
      ChangeNotifierProvider.value(value: group),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => ThemeProvider(ThemeMode.system)),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: SettingsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return _Harness(group, db, backend);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(finder);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Leave counts a write made just before the press, and Cancel changes nothing',
      (tester) async {
    final h = await _pump(tester);
    // As a local write does: the provider's cached count does not see it.
    await tester.runAsync(() => real.addUnsyncedChange(h.db));
    expect(h.group.pendingChanges, 0);

    await _tap(tester, 'group_leave');
    expect(
      find.text('1 change on this device has not reached the group yet. '
          'If you leave now, the group will never receive it.'),
      findsOneWidget,
    );
    expect(find.text('Leave anyway'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(h.group.isJoined, isTrue);
    expect(await tester.runAsync(() => real.outboxCount(h.db)), 1);
  });

  testWidgets('Clear counts the unsynced changes, and Cancel changes nothing', (tester) async {
    final h = await _pump(tester);
    await tester.runAsync(() => real.addUnsyncedChange(h.db));

    await _tap(tester, 'backend_url_clear');
    expect(find.byKey(const Key('clear_server_question')), findsOneWidget);
    expect(find.textContaining('1 change on this device has not reached the group yet'),
        findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(h.group.isJoined, isTrue);
    expect(h.backend.baseUrl, real.oldServer);
    expect(await tester.runAsync(() => real.outboxCount(h.db)), 1);
  });

  testWidgets('with nothing waiting, Leave keeps its plain question', (tester) async {
    final h = await _pump(tester);
    await _tap(tester, 'group_leave');
    expect(find.textContaining('has not reached the group'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(h.group.isJoined, isTrue);
  });
}
