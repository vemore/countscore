// Settings: no section heading is drawn without a row under it, and the last row
// clears the bottom inset. On the PWA the page once ended on a bare "Screen"
// heading, its only switch hidden behind kIsWeb — which reads as a page cut short
// (wip/done/2026-09-19-settings-screen-section-is-empty-on-the-web.md).
//
// kIsWeb is a compile-time constant, so the web build is played by a provider
// that, like the PWA's, cannot export or import the database.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

/// The PWA's settings: everything but the database export and import.
class _WebSettings extends SettingsProvider {
  @override
  bool get supportsDbExportImport => false;
}

const _bottomInset = 48.0;

Future<SettingsProvider> _pump(WidgetTester tester, {required bool web}) async {
  tester.view.physicalSize = const Size(412, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final group = GroupProvider(
    db: db,
    credentials: MemorySyncCredentials(),
    httpClient: MockClient((_) async => http.Response('{}', 404)),
    enableStream: false,
    pollInterval: const Duration(hours: 1),
  );
  final settings = web ? _WebSettings() : SettingsProvider();
  await tester.runAsync(() => settings.ready);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BackendProvider(null)),
      ChangeNotifierProvider.value(value: group),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => ThemeProvider(ThemeMode.system)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      // A phone's gesture bar, which the last row must clear.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(bottom: _bottomInset),
          viewPadding: const EdgeInsets.only(bottom: _bottomInset),
        ),
        child: child!,
      ),
      home: const SettingsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return settings;
}

/// Scrolls Settings to its end.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -5000));
  await tester.pumpAndSettle();
}

/// The row drawn right under [heading], in reading order: the heading must not
/// be the last thing on the page, and the next thing must not be another heading.
void _expectRowUnder(WidgetTester tester, String heading, Finder row) {
  final headingBox = tester.getRect(find.text(heading));
  final rowBox = tester.getRect(row);
  expect(rowBox.top, greaterThanOrEqualTo(headingBox.bottom),
      reason: '"$heading" has its row under it');
  expect(rowBox.top - headingBox.bottom, lessThan(24),
      reason: 'nothing sits between "$heading" and its row');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('on the web', () {
    testWidgets('"Screen" has the keep-awake switch under it, and there is no Backup',
        (tester) async {
      await _pump(tester, web: true);
      await _scrollToEnd(tester);

      expect(find.text('Screen'), findsOneWidget);
      final keepAwake = find.byKey(const Key('keep_screen_awake'));
      expect(keepAwake, findsOneWidget);
      expect(find.text('Keep screen awake'), findsOneWidget);
      _expectRowUnder(tester, 'Screen', keepAwake);

      expect(find.text('Backup'), findsNothing);
      expect(find.text('Export database'), findsNothing);
    });

    testWidgets('the last row clears the bottom inset at 412 x 860', (tester) async {
      await _pump(tester, web: true);
      await _scrollToEnd(tester);

      final last = tester.getRect(find.byKey(const Key('keep_screen_awake')));
      expect(last.bottom, lessThanOrEqualTo(860 - _bottomInset));
    });

    testWidgets('the switch turns the setting on and off', (tester) async {
      final settings = await _pump(tester, web: true);
      await _scrollToEnd(tester);
      expect(settings.keepScreenAwake, isFalse);

      await tester.tap(find.byKey(const Key('keep_screen_awake')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(settings.keepScreenAwake, isTrue);
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('keep_screen_awake'))).value,
          isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('keepScreenAwake'), isTrue);
    });
  });

  group('on Android', () {
    testWidgets('"Screen" and "Backup" each have their rows, the last clears the inset',
        (tester) async {
      await _pump(tester, web: false);
      await _scrollToEnd(tester);

      _expectRowUnder(tester, 'Screen', find.byKey(const Key('keep_screen_awake')));
      _expectRowUnder(tester, 'Backup', find.text('Export database'));
      final last = tester.getRect(find.ancestor(
        of: find.text('Import database'),
        matching: find.byType(ListTile),
      ));
      expect(last.bottom, lessThanOrEqualTo(860 - _bottomInset));
    });
  });
}
